#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# RED tests for the v1.1 active-handoff loader and PreToolUse path gate.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HOOK="$REPO_ROOT/scripts/hooks/handoff-pre-tool-gate.py"
FIXTURE="$REPO_ROOT/tests/hooks/fixtures/handoff/active-path-scope-handoff.json"

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
    sandbox=$(mktemp -d)
    SANDBOXES+=("$sandbox")
    mkdir -p "$sandbox/.devteam" "$sandbox/docs/handoffs" "$sandbox/docs/allowed" "$sandbox/docs/private"
    cp "$FIXTURE" "$sandbox/docs/handoffs/active-path-scope-handoff.json"
    printf '{"handoff_path":"docs/handoffs/active-path-scope-handoff.json"}\n' \
        >"$sandbox/.devteam/active-handoff.json"
}

allow_all_paths_in_sandbox() {
    python3 - "$sandbox/docs/handoffs/active-path-scope-handoff.json" <<'PY'
import json
import sys

path = sys.argv[1]
handoff = json.loads(open(path, encoding="utf-8").read())
handoff["allowed_paths"] = ["**"]
handoff["forbidden_paths"] = []
open(path, "w", encoding="utf-8").write(json.dumps(handoff))
PY
}

allow_all_paths_preserving_forbidden_in_sandbox() {
    python3 - "$sandbox/docs/handoffs/active-path-scope-handoff.json" <<'PY'
import json
import sys

path = sys.argv[1]
handoff = json.loads(open(path, encoding="utf-8").read())
handoff["allowed_paths"] = ["**"]
open(path, "w", encoding="utf-8").write(json.dumps(handoff))
PY
}

# Sets allowed_paths to ["docs/**"] while preserving existing forbidden_paths.
# Used for nested parent/child precedence tests.
allow_parent_dir_preserving_forbidden_in_sandbox() {
    python3 - "$sandbox/docs/handoffs/active-path-scope-handoff.json" <<'PY'
import json
import sys

path = sys.argv[1]
handoff = json.loads(open(path, encoding="utf-8").read())
handoff["allowed_paths"] = ["docs/**"]
open(path, "w", encoding="utf-8").write(json.dumps(handoff))
PY
}

mkpayload_file() {
    python3 -c 'import json,sys; print(json.dumps({"tool_input":{"file_path":sys.argv[1],"content":"x"}}))' "$1"
}

mkpayload_command() {
    python3 -c 'import json,sys; print(json.dumps({"tool_input":{"command":sys.argv[1]}}))' "$1"
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
if decision == "deny":
    print("deny")
elif decision == "allow" and "warning" in json.dumps(hook_output).lower():
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

run_loader_case() {
    local name=$1
    local sandbox tmp_out rc output
    make_sandbox
    tmp_out=$(mktemp)

    PYTHONPATH="$REPO_ROOT" python3 - "$sandbox" >"$tmp_out" 2>&1 <<'PY'
import sys
from pathlib import Path

from scripts.hooks.lib.handoff import load_active_handoff

repo_root = Path(sys.argv[1])
handoff = load_active_handoff(repo_root)

assert handoff["task_id"] == "v1.1-handoff-active-path-scope"
assert handoff["allowed_paths"] == ["docs/allowed/**"]
assert handoff["forbidden_paths"] == ["docs/private/**"]
PY
    rc=$?
    output=$(cat "$tmp_out")
    rm -f "$tmp_out"

    if [ "$rc" -eq 0 ]; then
        record_pass "$name"
    else
        record_fail "$name" "rc=$rc output=$output"
    fi
}

run_invalid_loader_case() {
    local name=$1
    local sandbox tmp_out rc output
    make_sandbox
    tmp_out=$(mktemp)

    PYTHONPATH="$REPO_ROOT" python3 - "$sandbox" >"$tmp_out" 2>&1 <<'PY'
import json
import sys
from pathlib import Path

from scripts.hooks.lib.handoff import load_active_handoff

repo_root = Path(sys.argv[1])
handoff_path = repo_root / "docs/handoffs/active-path-scope-handoff.json"
handoff = json.loads(handoff_path.read_text(encoding="utf-8"))
del handoff["owner_role"]
handoff_path.write_text(json.dumps(handoff), encoding="utf-8")

load_active_handoff(repo_root)
PY
    rc=$?
    output=$(cat "$tmp_out")
    rm -f "$tmp_out"

    if [ "$rc" -ne 0 ]; then
        record_pass "$name"
    else
        record_fail "$name" "expected schema validation failure for missing owner_role; rc=$rc output=$output"
    fi
}

run_gate_case() {
    local name=$1
    local mode=$2
    local path=$3
    local expect=$4
    local sandbox payload tmp_out tmp_err rc stdout stderr actual
    make_sandbox
    payload=$(mkpayload_file "$path")
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
    local expect=$3
    local sandbox payload tmp_out tmp_err rc stdout stderr actual
    make_sandbox
    python3 - "$sandbox/docs/handoffs/active-path-scope-handoff.json" <<'PY'
import json
import sys

path = sys.argv[1]
handoff = json.loads(open(path, encoding="utf-8").read())
del handoff["owner_role"]
open(path, "w", encoding="utf-8").write(json.dumps(handoff))
PY
    payload=$(mkpayload_file "docs/allowed/notes.md")
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

run_broad_scope_escape_case() {
    local name=$1
    local path=$2
    local expect=$3
    local sandbox payload tmp_out tmp_err rc stdout stderr actual
    make_sandbox
    allow_all_paths_in_sandbox
    payload=$(mkpayload_file "$path")
    tmp_out=$(mktemp)
    tmp_err=$(mktemp)

    printf '%s' "$payload" | CLAUDE_PROJECT_DIR="$sandbox" SWDT_HANDOFF_GATES="enforce" \
        python3 "$HOOK" >"$tmp_out" 2>"$tmp_err"
    rc=$?
    stdout=$(cat "$tmp_out")
    stderr=$(cat "$tmp_err")
    rm -f "$tmp_out" "$tmp_err"
    actual=$(printf '%s' "$stdout" | classify_decision)

    if [ "$actual" = "$expect" ] && [ "$rc" -eq 0 ]; then
        record_pass "$name"
    else
        record_fail "$name" "expected=$expect actual=$actual rc=$rc stdout=$stdout stderr=$stderr path=$path"
    fi
}

run_broad_allowed_forbidden_command_case() {
    local name=$1
    local command=$2
    local expect=$3
    local sandbox payload tmp_out tmp_err rc stdout stderr actual
    make_sandbox
    allow_all_paths_preserving_forbidden_in_sandbox
    payload=$(mkpayload_command "$command")
    tmp_out=$(mktemp)
    tmp_err=$(mktemp)

    printf '%s' "$payload" | CLAUDE_PROJECT_DIR="$sandbox" SWDT_HANDOFF_GATES="enforce" \
        python3 "$HOOK" >"$tmp_out" 2>"$tmp_err"
    rc=$?
    stdout=$(cat "$tmp_out")
    stderr=$(cat "$tmp_err")
    rm -f "$tmp_out" "$tmp_err"
    actual=$(printf '%s' "$stdout" | classify_decision)

    if [ "$actual" = "$expect" ] && [ "$rc" -eq 0 ]; then
        record_pass "$name"
    else
        record_fail "$name" "expected=$expect actual=$actual rc=$rc stdout=$stdout stderr=$stderr command=$command"
    fi
}

run_gate_event_name_case() {
    local name=$1
    local mode=$2
    local path=$3
    local sandbox payload tmp_out tmp_err rc stdout stderr actual
    make_sandbox
    payload=$(mkpayload_file "$path")
    tmp_out=$(mktemp)
    tmp_err=$(mktemp)

    printf '%s' "$payload" | CLAUDE_PROJECT_DIR="$sandbox" SWDT_HANDOFF_GATES="$mode" \
        python3 "$HOOK" >"$tmp_out" 2>"$tmp_err"
    rc=$?
    stdout=$(cat "$tmp_out")
    stderr=$(cat "$tmp_err")
    rm -f "$tmp_out" "$tmp_err"
    actual=$(printf '%s' "$stdout" | extract_hook_event_name)

    if [ "$actual" = "PreToolUse" ] && [ "$rc" -eq 0 ]; then
        record_pass "$name"
    else
        record_fail "$name" "expected hookEventName=PreToolUse actual=$actual rc=$rc stdout=$stdout stderr=$stderr"
    fi
}

# Runner: Write/Edit tool target matches BOTH a broad allowed glob AND a forbidden glob.
# Uses allow_all_paths_preserving_forbidden_in_sandbox so allowed_paths=["**"].
run_both_match_file_enforce_case() {
    local name=$1
    local path=$2
    local expect=$3
    local sandbox payload tmp_out tmp_err rc stdout stderr actual
    make_sandbox
    allow_all_paths_preserving_forbidden_in_sandbox
    payload=$(mkpayload_file "$path")
    tmp_out=$(mktemp)
    tmp_err=$(mktemp)

    printf '%s' "$payload" | CLAUDE_PROJECT_DIR="$sandbox" SWDT_HANDOFF_GATES="enforce" \
        python3 "$HOOK" >"$tmp_out" 2>"$tmp_err"
    rc=$?
    stdout=$(cat "$tmp_out")
    stderr=$(cat "$tmp_err")
    rm -f "$tmp_out" "$tmp_err"
    actual=$(printf '%s' "$stdout" | classify_decision)

    if [ "$actual" = "$expect" ] && [ "$rc" -eq 0 ]; then
        record_pass "$name"
    else
        record_fail "$name" "expected=$expect actual=$actual rc=$rc stdout=$stdout stderr=$stderr path=$path"
    fi
}

# Runner: Write/Edit tool target matches BOTH a broad allowed glob AND a forbidden glob in warn mode.
run_both_match_file_warn_case() {
    local name=$1
    local path=$2
    local expect=$3
    local sandbox payload tmp_out tmp_err rc stdout stderr actual
    make_sandbox
    allow_all_paths_preserving_forbidden_in_sandbox
    payload=$(mkpayload_file "$path")
    tmp_out=$(mktemp)
    tmp_err=$(mktemp)

    printf '%s' "$payload" | CLAUDE_PROJECT_DIR="$sandbox" SWDT_HANDOFF_GATES="warn" \
        python3 "$HOOK" >"$tmp_out" 2>"$tmp_err"
    rc=$?
    stdout=$(cat "$tmp_out")
    stderr=$(cat "$tmp_err")
    rm -f "$tmp_out" "$tmp_err"
    actual=$(printf '%s' "$stdout" | classify_decision)

    if [ "$actual" = "$expect" ] && [ "$rc" -eq 0 ]; then
        record_pass "$name"
    else
        record_fail "$name" "expected=$expect actual=$actual rc=$rc stdout=$stdout stderr=$stderr path=$path"
    fi
}

# Runner: allowed_paths=["docs/**"], forbidden_paths=["docs/private/**"].
# Validates nested child (forbidden subpath) → deny; sibling subpath (not forbidden) → allow.
run_nested_precedence_case() {
    local name=$1
    local path=$2
    local expect=$3
    local sandbox payload tmp_out tmp_err rc stdout stderr actual
    make_sandbox
    allow_parent_dir_preserving_forbidden_in_sandbox
    payload=$(mkpayload_file "$path")
    tmp_out=$(mktemp)
    tmp_err=$(mktemp)

    printf '%s' "$payload" | CLAUDE_PROJECT_DIR="$sandbox" SWDT_HANDOFF_GATES="enforce" \
        python3 "$HOOK" >"$tmp_out" 2>"$tmp_err"
    rc=$?
    stdout=$(cat "$tmp_out")
    stderr=$(cat "$tmp_err")
    rm -f "$tmp_out" "$tmp_err"
    actual=$(printf '%s' "$stdout" | classify_decision)

    if [ "$actual" = "$expect" ] && [ "$rc" -eq 0 ]; then
        record_pass "$name"
    else
        record_fail "$name" "expected=$expect actual=$actual rc=$rc stdout=$stdout stderr=$stderr path=$path"
    fi
}

run_command_gate_case() {
    local name=$1
    local mode=$2
    local command=$3
    local expect=$4
    local sandbox payload tmp_out tmp_err rc stdout stderr actual
    make_sandbox
    payload=$(mkpayload_command "$command")
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
        record_fail "$name" "expected=$expect actual=$actual rc=$rc stdout=$stdout stderr=$stderr command=$command"
    fi
}

run_loader_case "active handoff loader follows .devteam pointer into docs/handoffs"

run_invalid_loader_case "active handoff loader rejects schema-invalid pointed handoff"

run_gate_case "enforce: allows writes inside active handoff allowed_paths" \
    enforce "docs/allowed/notes.md" proceed

run_gate_case "enforce: denies writes matching active handoff forbidden_paths" \
    enforce "docs/private/secret.md" deny

run_schema_invalid_gate_case "enforce: denies when active handoff is schema-invalid" \
    enforce deny

run_broad_scope_escape_case "enforce: denies relative write escaping repo even with broad allowed_paths" \
    "../outside.txt" deny

run_broad_scope_escape_case "enforce: denies absolute write outside CLAUDE_PROJECT_DIR even with broad allowed_paths" \
    "$(mktemp -d)/outside.txt" deny

run_broad_allowed_forbidden_command_case "enforce: denies rm -rf forbidden directory even with broad allowed_paths" \
    "rm -rf docs/private" deny

run_gate_case "warn: warns but proceeds for writes matching forbidden_paths" \
    warn "docs/private/secret.md" warn

run_gate_event_name_case "enforce: deny output declares PreToolUse hook event name" \
    enforce "docs/private/secret.md"

run_gate_event_name_case "warn: warning output declares PreToolUse hook event name" \
    warn "docs/private/secret.md"

run_command_gate_case "enforce: allows bash redirect inside active handoff allowed_paths" \
    enforce "printf '%s\\n' ok > docs/allowed/notes.md" proceed

run_command_gate_case "enforce: denies bash redirect outside active handoff allowed_paths" \
    enforce "printf '%s\\n' no > docs/private/secret.md" deny

run_command_gate_case "enforce: denies bash tee target outside active handoff allowed_paths" \
    enforce "printf '%s\\n' no | tee docs/private/secret.md" deny

run_command_gate_case "enforce: denies rm mutation outside active handoff allowed_paths" \
    enforce "rm docs/private/secret.md" deny

run_command_gate_case "enforce: denies sed -i mutation outside active handoff allowed_paths" \
    enforce "sed -i 's/no/yes/' docs/private/secret.md" deny

run_command_gate_case "enforce: denies python open write outside active handoff allowed_paths" \
    enforce "python3 -c \"open('docs/private/secret.md', 'w').write('x')\"" deny

run_command_gate_case "enforce: denies python open kwarg mode write outside active handoff allowed_paths" \
    enforce "python3 -c 'open(\"docs/private/secret.md\", mode=\"w\").write(\"x\")'" deny

run_command_gate_case "enforce: denies python pathlib write_text outside active handoff allowed_paths" \
    enforce "python3 -c 'from pathlib import Path; Path(\"docs/private/secret.md\").write_text(\"x\")'" deny

run_command_gate_case "enforce: denies dd of target outside active handoff allowed_paths" \
    enforce "dd if=/dev/zero of=docs/private/secret.md bs=1 count=1" deny

run_command_gate_case "enforce: denies cp destination outside active handoff allowed_paths" \
    enforce "cp docs/allowed/notes.md docs/private/secret.md" deny

run_command_gate_case "enforce: denies mv destination outside active handoff allowed_paths" \
    enforce "mv docs/allowed/notes.md docs/private/secret.md" deny

run_command_gate_case "enforce: denies install destination outside active handoff allowed_paths" \
    enforce "install docs/allowed/notes.md docs/private/secret.md" deny

run_command_gate_case "enforce: denies truncate target outside active handoff allowed_paths" \
    enforce "truncate -s 0 docs/private/secret.md" deny

run_command_gate_case "enforce: denies touch target outside active handoff allowed_paths" \
    enforce "touch docs/private/secret.md" deny

run_command_gate_case "enforce: allows read-only command mentioning forbidden path" \
    enforce "grep -R secret docs/private/secret.md" proceed

# Forbidden-path precedence: forbidden_paths ALWAYS wins over a broader allowed_paths match.

# Case P1: Write tool target matches both allowed_paths=["**"] and forbidden_paths=["docs/private/**"].
# Forbidden wins → enforce mode must deny.
run_both_match_file_enforce_case \
    "precedence: enforce denies Write target matching both broad allowed glob and forbidden glob" \
    "docs/private/secret.md" deny

# Case P2: Bash redirect target matches both allowed_paths=["**"] and forbidden_paths=["docs/private/**"].
# Forbidden wins → enforce mode must deny.
run_broad_allowed_forbidden_command_case \
    "precedence: enforce denies bash redirect to target matching both broad allowed glob and forbidden glob" \
    "printf '%s\n' x > docs/private/secret.md" deny

# Case P3 (nested child): allowed_paths=["docs/**"], forbidden_paths=["docs/private/**"].
# Write to forbidden child subpath docs/private/secret.md → deny (parent allowed does not override forbidden child).
run_nested_precedence_case \
    "precedence: enforce denies write to forbidden child subpath even when parent dir is in allowed_paths" \
    "docs/private/secret.md" deny

# Case P4 (nested sibling): allowed_paths=["docs/**"], forbidden_paths=["docs/private/**"].
# Write to sibling subpath docs/allowed/notes.md (not forbidden) → proceed.
run_nested_precedence_case \
    "precedence: enforce allows write to sibling subpath under parent allowed dir when sibling is not forbidden" \
    "docs/allowed/notes.md" proceed

# Case P5: Warn mode, target matches both allowed_paths=["**"] and forbidden_paths=["docs/private/**"].
# In warn mode: non-blocking (proceeds) but must flag the forbidden match → classify as warn.
run_both_match_file_warn_case \
    "precedence: warn mode warns-and-proceeds for Write target matching both broad allowed glob and forbidden glob" \
    "docs/private/secret.md" warn

printf '\nSummary: %s passed, %s failed\n' "$pass" "$fail"
if [ "$fail" -ne 0 ]; then
    printf 'Failures:\n'
    printf ' - %s\n' "${failures[@]}"
    exit 1
fi

exit 0
