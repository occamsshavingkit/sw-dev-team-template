#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# RED tests for the v1.1 TaskCompleted evidence gate.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HOOK="$REPO_ROOT/scripts/hooks/handoff-task-completed-gate.py"
FIXTURES="$REPO_ROOT/tests/hooks/fixtures/handoff"

pass=0
fail=0
failures=()
SANDBOXES=()

record_pass() {
    pass=$((pass + 1))
    printf 'PASS  %s\n' "$1"
}

record_fail() {
    fail=$((fail + 1))
    failures+=("$1")
    printf 'FAIL  %s\n' "$1"
    if [ -n "${2:-}" ]; then
        printf '      %s\n' "$2"
    fi
}

cleanup() {
    local sandbox
    for sandbox in "${SANDBOXES[@]}"; do
        rm -rf "$sandbox"
    done
}
trap cleanup EXIT

make_sandbox() {
    local fixture=$1
    sandbox=$(mktemp -d)
    SANDBOXES+=("$sandbox")
    mkdir -p "$sandbox/.devteam" "$sandbox/docs/handoffs"
    cp "$FIXTURES/$fixture" "$sandbox/docs/handoffs/$fixture"
    printf '{"handoff_path":"docs/handoffs/%s"}\n' "$fixture" \
        >"$sandbox/.devteam/active-handoff.json"
}

mkpayload() {
    python3 -c '
import json
print(json.dumps({
    "hook_event_name": "TaskCompleted",
    "task_id": "v1.1-completion-evidence-gate",
    "actor_role": "software-engineer",
    "completion": {
        "claimed_by": "software-engineer",
        "evidence": [
            {"type": "test", "name": "tests/hooks/test-handoff-task-completed-gate.sh", "actor_role": "software-engineer"},
            {"type": "review", "artifact": "docs/reviews/self-review.md", "actor_role": "software-engineer"}
        ]
    }
}))
'
}

classify_decision() {
    python3 -c '
import json, sys
text = sys.stdin.read()
if not text:
    print("proceed")
    raise SystemExit
try:
    payload = json.loads(text)
except json.JSONDecodeError:
    print("unknown")
    raise SystemExit
hook_output = payload.get("hookSpecificOutput")
if not isinstance(hook_output, dict):
    print("unknown")
    raise SystemExit
decision = hook_output.get("permissionDecision")
serialized = json.dumps(hook_output).lower()
if decision == "deny":
    print("deny")
elif decision == "allow" and "warning" in serialized:
    print("warn")
elif decision == "allow" or decision is None:
    print("proceed")
else:
    print("unknown")
'
}

extract_hook_event_name() {
    python3 -c '
import json, sys
text = sys.stdin.read()
try:
    payload = json.loads(text)
except json.JSONDecodeError:
    print("")
    raise SystemExit
hook_output = payload.get("hookSpecificOutput")
if not isinstance(hook_output, dict):
    print("")
    raise SystemExit
print(hook_output.get("hookEventName", ""))
'
}

run_gate_case() {
    local name=$1
    local mode=$2
    local fixture=$3
    local expect=$4
    local sandbox payload tmp_out tmp_err rc stdout stderr actual
    make_sandbox "$fixture"
    payload=$(mkpayload)
    tmp_out=$(mktemp)
    tmp_err=$(mktemp)

    printf '%s' "$payload" | CLAUDE_PROJECT_DIR="$sandbox" SWDT_HANDOFF_GATES="$mode" \
        python3 "$HOOK" >"$tmp_out" 2>"$tmp_err"
    rc=$?
    stdout=$(cat "$tmp_out")
    stderr=$(cat "$tmp_err")
    rm -f "$tmp_out" "$tmp_err"
    actual=$(printf '%s' "$stdout" | classify_decision)

    if [ "$actual" = "$expect" ] && [ "$rc" -eq 0 ]; then
        record_pass "$name"
    else
        record_fail "$name" "expected=$expect actual=$actual rc=$rc stdout=$stdout stderr=$stderr"
    fi
}

run_schema_invalid_gate_case() {
    local name=$1
    local mode=$2
    local fixture=$3
    local expect=$4
    local sandbox payload tmp_out tmp_err rc stdout stderr actual
    make_sandbox "$fixture"
    python3 - "$sandbox/docs/handoffs/$fixture" <<'PY'
import json
import sys

path = sys.argv[1]
handoff = json.loads(open(path, encoding="utf-8").read())
del handoff["owner_role"]
open(path, "w", encoding="utf-8").write(json.dumps(handoff))
PY
    payload=$(mkpayload)
    tmp_out=$(mktemp)
    tmp_err=$(mktemp)

    printf '%s' "$payload" | CLAUDE_PROJECT_DIR="$sandbox" SWDT_HANDOFF_GATES="$mode" \
        python3 "$HOOK" >"$tmp_out" 2>"$tmp_err"
    rc=$?
    stdout=$(cat "$tmp_out")
    stderr=$(cat "$tmp_err")
    rm -f "$tmp_out" "$tmp_err"
    actual=$(printf '%s' "$stdout" | classify_decision)

    if [ "$actual" = "$expect" ] && [ "$rc" -eq 0 ]; then
        record_pass "$name"
    else
        record_fail "$name" "expected=$expect actual=$actual rc=$rc stdout=$stdout stderr=$stderr"
    fi
}

run_gate_event_name_case() {
    local name=$1
    local mode=$2
    local fixture=$3
    local sandbox payload tmp_out tmp_err rc stdout stderr actual
    make_sandbox "$fixture"
    payload=$(mkpayload)
    tmp_out=$(mktemp)
    tmp_err=$(mktemp)

    printf '%s' "$payload" | CLAUDE_PROJECT_DIR="$sandbox" SWDT_HANDOFF_GATES="$mode" \
        python3 "$HOOK" >"$tmp_out" 2>"$tmp_err"
    rc=$?
    stdout=$(cat "$tmp_out")
    stderr=$(cat "$tmp_err")
    rm -f "$tmp_out" "$tmp_err"
    actual=$(printf '%s' "$stdout" | extract_hook_event_name)

    if [ "$actual" = "TaskCompleted" ] && [ "$rc" -eq 0 ]; then
        record_pass "$name"
    else
        record_fail "$name" "expected hookEventName=TaskCompleted actual=$actual rc=$rc stdout=$stdout stderr=$stderr"
    fi
}

run_gate_case "enforce: denies completion when required tests and review evidence are missing" \
    enforce "completion-evidence-missing.json" deny

run_gate_case "enforce: allows completion when required tests and review evidence are present" \
    enforce "completion-evidence-satisfied.json" proceed

run_schema_invalid_gate_case "enforce: denies completion when active handoff is schema-invalid" \
    enforce "completion-evidence-satisfied.json" deny

run_schema_invalid_gate_case "warn: warns but allows completion when active handoff is schema-invalid" \
    warn "completion-evidence-satisfied.json" warn

run_gate_case "warn: warns but allows completion when required evidence is missing" \
    warn "completion-evidence-missing.json" warn

run_gate_event_name_case "enforce: deny output declares TaskCompleted hook event name" \
    enforce "completion-evidence-missing.json"

run_gate_event_name_case "warn: warning output declares TaskCompleted hook event name" \
    warn "completion-evidence-missing.json"

run_gate_case "enforce: ignores worker self-attested completion evidence for required tests and review" \
    enforce "completion-evidence-self-attested.json" deny

run_gate_case "enforce: denies completion when required security review evidence is missing" \
    enforce "completion-evidence-security-review-missing.json" deny

run_gate_case "enforce: denies completion when required human approval evidence is missing" \
    enforce "completion-evidence-human-approval-missing.json" deny

run_gate_case "enforce: denies completion when required test evidence failed" \
    enforce "completion-evidence-failed-test.json" deny

run_gate_case "enforce: denies completion when required review evidence is self-authored" \
    enforce "completion-evidence-self-authored-review.json" deny

run_gate_case "enforce: denies completion when required review evidence is not from code-reviewer" \
    enforce "completion-evidence-review-wrong-role.json" deny

run_gate_case "enforce: denies completion when required security review evidence is not from security-engineer" \
    enforce "completion-evidence-security-review-wrong-role.json" deny

run_gate_case "enforce: denies completion when human approval lacks researcher-stewarded customer truth" \
    enforce "completion-evidence-human-approval-unstewarded.json" deny

# Self-attestation rejection: evidence_kind worker_report never satisfies any gate type
run_gate_case "enforce: denies completion when test evidence is worker_report kind" \
    enforce "completion-evidence-worker-report-test.json" deny

run_gate_case "enforce: denies completion when review evidence is worker_report kind" \
    enforce "completion-evidence-worker-report-review.json" deny

run_gate_case "enforce: denies completion when security evidence is worker_report kind" \
    enforce "completion-evidence-worker-report-security.json" deny

run_gate_case "enforce: denies completion when human_approval evidence is worker_report kind" \
    enforce "completion-evidence-worker-report-human-approval.json" deny

run_gate_case "warn: warns but allows completion when review evidence is worker_report kind" \
    warn "completion-evidence-worker-report-review-warn.json" warn

# Self-attestation rejection: implementing worker's own actor_role cannot satisfy security/customer-truth gates
run_gate_case "enforce: denies completion when implementing worker self-attests security gate" \
    enforce "completion-evidence-sw-eng-attests-security.json" deny

run_gate_case "enforce: denies completion when implementing worker self-attests human_approval gate" \
    enforce "completion-evidence-sw-eng-attests-human-approval.json" deny

# Positive contrast: evidence_kind accepted explicitly set passes all gates
run_gate_case "enforce: allows completion when all evidence carries evidence_kind accepted" \
    enforce "completion-evidence-accepted-kind-passes.json" proceed

# Customer-truth / human-approval stewardship gate cases (Hard Rules #2/#4/#6)
# Positive: researcher + CUSTOMER_NOTES.md satisfies human_approval gate
run_gate_case "enforce: allows completion when human_approval has researcher-stewarded CUSTOMER_NOTES.md evidence" \
    enforce "completion-evidence-human-approval-stewarded.json" proceed

# Negative: tech-lead actor (obtains approval but does not steward) does not satisfy gate
run_gate_case "enforce: denies completion when human_approval actor is tech-lead not researcher" \
    enforce "completion-evidence-human-approval-tech-lead-actor.json" deny

# Negative: researcher actor but source is not the stewarded record
run_gate_case "enforce: denies completion when human_approval researcher source is not CUSTOMER_NOTES.md" \
    enforce "completion-evidence-human-approval-wrong-source.json" deny

# Warn-mode: researcher with wrong source warns and proceeds rather than denying
run_gate_case "warn: warns but allows completion when human_approval researcher source is not CUSTOMER_NOTES.md" \
    warn "completion-evidence-human-approval-wrong-source-warn.json" warn

# US4 / FR-018..FR-023 / SC-007: external_tool_activity cannot satisfy final evidence gates
# Case 1: tool activity present, required test+review evidence absent → enforce denies
run_gate_case "enforce: denies completion when only external_tool_activity present and required evidence absent" \
    enforce "completion-evidence-tool-activity-only-deny.json" deny

# Case 2 (specificity): same handoff shape but WITH proper accepted evidence → enforce proceeds
# Proves the deny above is caused by absent evidence, not mere presence of tool-activity entries
run_gate_case "enforce: allows completion when external_tool_activity present AND proper accepted evidence satisfies gates" \
    enforce "completion-evidence-tool-activity-with-proper-evidence.json" proceed

# Case 3: attempt to smuggle tool output into verification arrays via tool actor_role + worker_report kind → enforce denies
run_gate_case "enforce: denies completion when tool/hook actor_role and worker_report kind are smuggled into verification arrays" \
    enforce "completion-evidence-tool-actor-smuggled.json" deny

# Case 4 (warn-mode variant of case 1): tool activity only, evidence absent → warn mode warns and allows
run_gate_case "warn: warns but allows completion when only external_tool_activity present and required evidence absent" \
    warn "completion-evidence-tool-activity-only-warn.json" warn

# S-1 gap-closure (FR-006 conformance): worker self-attestation on test gate
# NEG: absent evidence_kind + worker actor_role → test gate not satisfied → deny
run_gate_case "enforce: denies completion when test entry has absent evidence_kind and worker actor_role (S-1/FR-006)" \
    enforce "completion-evidence-test-worker-self-attested-absent-kind.json" deny
run_gate_case "warn: warns but allows when test entry has absent evidence_kind and worker actor_role (S-1/FR-006)" \
    warn "completion-evidence-test-worker-self-attested-absent-kind.json" warn

# POS contrast: explicit accepted / hook-captured test entry passes
# (uses completion-evidence-satisfied.json which now carries evidence_kind="accepted")
run_gate_case "enforce: allows completion when test entry carries explicit evidence_kind accepted (S-1/FR-006 positive contrast)" \
    enforce "completion-evidence-satisfied.json" proceed

printf '\nSummary: %s passed, %s failed\n' "$pass" "$fail"
if [ "$fail" -ne 0 ]; then
    printf 'Failures:\n'
    printf ' - %s\n' "${failures[@]}"
    exit 1
fi

exit 0
