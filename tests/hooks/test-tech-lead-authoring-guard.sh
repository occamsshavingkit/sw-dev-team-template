#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# Self-test for scripts/hooks/tech-lead-authoring-guard.py (FW-ADR-0012).
# Mirrors the customer-notes-guard.py harness pattern: feed crafted JSON
# tool-input payloads on stdin, assert exit code 0 (the hook always exits
# 0 — the harness reads permissionDecision from stdout) and inspect
# stdout for the expected decision shape.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HOOK="$REPO_ROOT/scripts/hooks/tech-lead-authoring-guard.py"
export CLAUDE_PROJECT_DIR="$REPO_ROOT"

pass=0
fail=0
failures=()

# run_case <name> <env-line> <stdin-json> <expect-decision: proceed|deny> [<expect-stderr-substr>]
run_case() {
    local name=$1
    local env_line=$2
    local stdin=$3
    local expect=$4
    local stderr_substr=${5:-}

    local stdout stderr rc
    local tmp_out tmp_err
    tmp_out=$(mktemp)
    tmp_err=$(mktemp)

    if [ -n "$env_line" ]; then
        # shellcheck disable=SC2086
        printf '%s' "$stdin" | env $env_line python3 "$HOOK" >"$tmp_out" 2>"$tmp_err"
    else
        # Explicitly clear the escape hatch so it can't leak in from the
        # caller's environment.
        printf '%s' "$stdin" | env -u SWDT_AGENT_PUSH python3 "$HOOK" >"$tmp_out" 2>"$tmp_err"
    fi
    rc=$?
    stdout=$(cat "$tmp_out")
    stderr=$(cat "$tmp_err")
    rm -f "$tmp_out" "$tmp_err"

    local actual
    if [ -z "$stdout" ]; then
        actual="proceed"
    elif printf '%s' "$stdout" | grep -q '"permissionDecision": "deny"'; then
        actual="deny"
    elif printf '%s' "$stdout" | grep -q '"permissionDecision": "ask"'; then
        actual="ask"
    else
        actual="unknown"
    fi

    local ok=1
    if [ "$actual" != "$expect" ]; then
        ok=0
    fi
    if [ "$rc" -ne 0 ]; then
        ok=0
    fi
    if [ -n "$stderr_substr" ] && ! printf '%s' "$stderr" | grep -q "$stderr_substr"; then
        ok=0
    fi

    if [ "$ok" -eq 1 ]; then
        pass=$((pass + 1))
        echo "PASS  $name"
    else
        fail=$((fail + 1))
        failures+=("$name (expected=$expect actual=$actual rc=$rc stderr=$stderr stdout=$stdout)")
        echo "FAIL  $name"
        echo "      expected=$expect actual=$actual rc=$rc"
        [ -n "$stderr" ] && echo "      stderr: $stderr"
        [ -n "$stdout" ] && echo "      stdout: $stdout"
    fi
}

# ---------------------------------------------------------------------------
# Allow-list paths — proceed.
# ---------------------------------------------------------------------------

run_case "allow: docs/OPEN_QUESTIONS.md" "" \
    '{"tool_input":{"file_path":"docs/OPEN_QUESTIONS.md","content":"x"}}' \
    proceed

run_case "allow: docs/intake-log.md" "" \
    '{"tool_input":{"file_path":"docs/intake-log.md","content":"x"}}' \
    proceed

run_case "allow: docs/DECISIONS.md" "" \
    '{"tool_input":{"file_path":"docs/DECISIONS.md","content":"x"}}' \
    proceed

run_case "allow: docs/pm/dispatch-log.md" "" \
    '{"tool_input":{"file_path":"docs/pm/dispatch-log.md","content":"x"}}' \
    proceed

run_case "allow: TEMPLATE_VERSION" "" \
    '{"tool_input":{"file_path":"TEMPLATE_VERSION","content":"x"}}' \
    proceed

run_case "allow: docs/AGENT_NAMES.md" "" \
    '{"tool_input":{"file_path":"docs/AGENT_NAMES.md","content":"x"}}' \
    proceed

run_case "allow: docs/pm/intake-foo.md (glob)" "" \
    '{"tool_input":{"file_path":"docs/pm/intake-foo.md","content":"x"}}' \
    proceed

run_case "allow: docs/pm/intake-foo.local.md (glob)" "" \
    '{"tool_input":{"file_path":"docs/pm/intake-foo.local.md","content":"x"}}' \
    proceed

run_case "allow: docs/tech-lead/anything.md" "" \
    '{"tool_input":{"file_path":"docs/tech-lead/anything.md","content":"x"}}' \
    proceed

run_case "allow: docs/tech-lead/nested/deep.md" "" \
    '{"tool_input":{"file_path":"docs/tech-lead/nested/deep.md","content":"x"}}' \
    proceed

run_case "allow: docs/tasks/T-0042.md" "" \
    '{"tool_input":{"file_path":"docs/tasks/T-0042.md","content":"x"}}' \
    proceed

# ---------------------------------------------------------------------------
# Off-list paths — deny with specialist hint.
# ---------------------------------------------------------------------------

run_case "deny: scripts/foo.sh → software-engineer" "" \
    '{"tool_input":{"file_path":"scripts/foo.sh","content":"#!/bin/sh"}}' \
    deny

# Inspect the deny payload for the routing hint explicitly.
hint_out=$(printf '%s' '{"tool_input":{"file_path":"scripts/foo.sh","content":"x"}}' \
    | env -u SWDT_AGENT_PUSH python3 "$HOOK")
if printf '%s' "$hint_out" | grep -q "software-engineer"; then
    pass=$((pass + 1))
    echo "PASS  deny payload names software-engineer for scripts/foo.sh"
else
    fail=$((fail + 1))
    failures+=("deny payload missing software-engineer hint")
    echo "FAIL  deny payload missing software-engineer hint: $hint_out"
fi

run_case "deny: docs/adr/fw-adr-XXXX.md → architect" "" \
    '{"tool_input":{"file_path":"docs/adr/fw-adr-XXXX.md","content":"x"}}' \
    deny

hint_out=$(printf '%s' '{"tool_input":{"file_path":"docs/adr/fw-adr-XXXX.md","content":"x"}}' \
    | env -u SWDT_AGENT_PUSH python3 "$HOOK")
if printf '%s' "$hint_out" | grep -q "architect"; then
    pass=$((pass + 1))
    echo "PASS  deny payload names architect for docs/adr/..."
else
    fail=$((fail + 1))
    failures+=("deny payload missing architect hint")
    echo "FAIL  deny payload missing architect hint: $hint_out"
fi

run_case "deny: src/foo.py → software-engineer" "" \
    '{"tool_input":{"file_path":"src/foo.py","content":"print(1)"}}' \
    deny

run_case "deny: CHANGELOG.md → tech-writer" "" \
    '{"tool_input":{"file_path":"CHANGELOG.md","content":"x"}}' \
    deny

run_case "deny: tests/foo.sh → qa-engineer" "" \
    '{"tool_input":{"file_path":"tests/foo.sh","content":"x"}}' \
    deny

run_case "deny: .github/workflows/ci.yml → release-engineer" "" \
    '{"tool_input":{"file_path":".github/workflows/ci.yml","content":"x"}}' \
    deny

run_case "deny: docs/security/threat-model.md → security-engineer" "" \
    '{"tool_input":{"file_path":"docs/security/threat-model.md","content":"x"}}' \
    deny

# ---------------------------------------------------------------------------
# Escape hatch — SWDT_AGENT_PUSH widens, proceed + audit log line.
# ---------------------------------------------------------------------------

run_case "escape: scripts/foo.sh with SWDT_AGENT_PUSH=software-engineer" \
    "SWDT_AGENT_PUSH=software-engineer" \
    '{"tool_input":{"file_path":"scripts/foo.sh","content":"x"}}' \
    proceed \
    "SWDT_AGENT_PUSH=software-engineer"

run_case "escape: docs/adr/foo.md with SWDT_AGENT_PUSH=architect" \
    "SWDT_AGENT_PUSH=architect" \
    '{"tool_input":{"file_path":"docs/adr/foo.md","content":"x"}}' \
    proceed \
    "SWDT_AGENT_PUSH=architect"

run_case "escape: unrecognised role falls back to deny" \
    "SWDT_AGENT_PUSH=not-a-role" \
    '{"tool_input":{"file_path":"scripts/foo.sh","content":"x"}}' \
    deny

run_case "escape: sme-brewing role accepted" \
    "SWDT_AGENT_PUSH=sme-brewing" \
    '{"tool_input":{"file_path":"src/foo.py","content":"x"}}' \
    proceed \
    "SWDT_AGENT_PUSH=sme-brewing"

# ---------------------------------------------------------------------------
# Bash write-pattern detection.
# ---------------------------------------------------------------------------

run_case "deny: bash heredoc to src/foo.py" "" \
    '{"tool_input":{"command":"python3 <<EOF\nopen(\"src/foo.py\",\"w\").write(\"x\")\nEOF"}}' \
    deny

run_case "deny: bash redirect to src/foo.py" "" \
    '{"tool_input":{"command":"echo bad > src/foo.py"}}' \
    deny

run_case "deny: bash append to scripts/foo.sh" "" \
    '{"tool_input":{"command":"echo more >> scripts/foo.sh"}}' \
    deny

run_case "deny: tee to src/foo.py" "" \
    '{"tool_input":{"command":"echo bad | tee src/foo.py"}}' \
    deny

run_case "deny: sed -i on src/foo.py" "" \
    '{"tool_input":{"command":"sed -i s/x/y/ src/foo.py"}}' \
    deny

run_case "deny: rm on src/foo.py" "" \
    '{"tool_input":{"command":"rm src/foo.py"}}' \
    deny

run_case "proceed: bash redirect to docs/OPEN_QUESTIONS.md" "" \
    '{"tool_input":{"command":"echo q >> docs/OPEN_QUESTIONS.md"}}' \
    proceed

run_case "proceed: bash redirect to docs/tech-lead/notes.md" "" \
    '{"tool_input":{"command":"echo note >> docs/tech-lead/notes.md"}}' \
    proceed

run_case "proceed: read-only bash (grep) does not trigger" "" \
    '{"tool_input":{"command":"grep -r foo src/"}}' \
    proceed

run_case "escape: bash heredoc with SWDT_AGENT_PUSH=software-engineer" \
    "SWDT_AGENT_PUSH=software-engineer" \
    '{"tool_input":{"command":"cat > src/foo.py <<EOF\nx=1\nEOF"}}' \
    proceed \
    "SWDT_AGENT_PUSH=software-engineer"

# ---------------------------------------------------------------------------
# CUSTOMER_NOTES.md handling — defer to customer-notes-guard.
# ---------------------------------------------------------------------------

run_case "defer: CUSTOMER_NOTES.md path (no escape hatch)" "" \
    '{"tool_input":{"file_path":"CUSTOMER_NOTES.md","content":"x"}}' \
    proceed

run_case "defer: CUSTOMER_NOTES.md with SWDT_AGENT_PUSH=architect" \
    "SWDT_AGENT_PUSH=architect" \
    '{"tool_input":{"file_path":"CUSTOMER_NOTES.md","content":"x"}}' \
    proceed

run_case "defer: CUSTOMER_NOTES.md bash write" "" \
    '{"tool_input":{"command":"echo x >> CUSTOMER_NOTES.md"}}' \
    proceed

# ---------------------------------------------------------------------------
# Malformed payloads — fail open.
# ---------------------------------------------------------------------------

run_case "fail-open: malformed JSON" "" "not json" proceed
run_case "fail-open: empty stdin" "" "" proceed
run_case "fail-open: non-dict event" "" '[]' proceed
run_case "fail-open: missing tool_input" "" '{}' proceed

# ---------------------------------------------------------------------------
# Summary.
# ---------------------------------------------------------------------------

echo
echo "tech-lead-authoring-guard self-test: $pass passed, $fail failed."
if [ "$fail" -gt 0 ]; then
    echo
    echo "Failures:"
    for f in "${failures[@]}"; do
        echo "  - $f"
    done
    exit 1
fi
exit 0
