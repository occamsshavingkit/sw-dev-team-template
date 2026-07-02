#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors

set -u

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HOOK="$REPO_ROOT/scripts/hooks/subcall-limit-guard.py"
RESET="$REPO_ROOT/scripts/hooks/subcall-limit-reset.py"

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
    local sandbox tmp_file
    for sandbox in "${SANDBOXES[@]}"; do
        rm -rf "$sandbox"
    done
    for tmp_file in "${TMP_FILES[@]:-}"; do
        rm -f "$tmp_file"
    done
}
trap cleanup EXIT

make_sandbox() {
    sandbox=$(mktemp -d)
    SANDBOXES+=("$sandbox")
    mkdir -p "$sandbox/docs/pm"
}

run_guard() {
    local sandbox=$1
    local env_line=$2
    local payload=$3
    local tmp_out tmp_err
    tmp_out=$(mktemp)
    tmp_err=$(mktemp)
    TMP_FILES+=("$tmp_out" "$tmp_err")

    if [ -n "$env_line" ]; then
        local -a env_args=()
        local _old_ifs=$IFS
        IFS=' 	'
        # shellcheck disable=SC2206
        env_args=( $env_line )
        IFS=$_old_ifs
        printf '%s' "$payload" \
            | env CLAUDE_PROJECT_DIR="$sandbox" "${env_args[@]}" python3 "$HOOK" >"$tmp_out" 2>"$tmp_err"
    else
        printf '%s' "$payload" \
            | env CLAUDE_PROJECT_DIR="$sandbox" python3 "$HOOK" >"$tmp_out" 2>"$tmp_err"
    fi

    RUN_RC=$?
    RUN_STDOUT=$(cat "$tmp_out")
    RUN_STDERR=$(cat "$tmp_err")
}

run_reset() {
    local sandbox=$1
    local env_line=$2
    local tmp_out tmp_err
    tmp_out=$(mktemp)
    tmp_err=$(mktemp)
    TMP_FILES+=("$tmp_out" "$tmp_err")

    if [ -n "$env_line" ]; then
        local -a env_args=()
        local _old_ifs=$IFS
        IFS=' 	'
        # shellcheck disable=SC2206
        env_args=( $env_line )
        IFS=$_old_ifs
        env CLAUDE_PROJECT_DIR="$sandbox" "${env_args[@]}" python3 "$RESET" >"$tmp_out" 2>"$tmp_err"
    else
        env CLAUDE_PROJECT_DIR="$sandbox" python3 "$RESET" >"$tmp_out" 2>"$tmp_err"
    fi

    RUN_RC=$?
    RUN_STDOUT=$(cat "$tmp_out")
    RUN_STDERR=$(cat "$tmp_err")
}

read_budget() {
    local sandbox=$1
    python3 - "$sandbox" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1]) / ".claude" / "tmp" / "subcalls-left.json"
if not path.exists():
    print("missing")
else:
    data = json.loads(path.read_text(encoding="utf-8"))
    print(data.get("subcalls_left", "missing-key"))
PY
}

write_budget() {
    local sandbox=$1
    local value=$2
    mkdir -p "$sandbox/.claude/tmp"
    python3 - "$sandbox" "$value" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1]) / ".claude" / "tmp" / "subcalls-left.json"
path.write_text(json.dumps({"subcalls_left": int(sys.argv[2])}), encoding="utf-8")
PY
}

assert_case() {
    local name=$1
    local actual_decision=$2
    local expect_decision=$3
    local actual_budget=$4
    local expect_budget=$5

    if [ "$RUN_RC" -eq 0 ] && [ "$actual_decision" = "$expect_decision" ] && [ "$actual_budget" = "$expect_budget" ]; then
        record_pass "$name"
    else
        record_fail "$name" \
            "expected decision=$expect_decision budget=$expect_budget; got decision=$actual_decision budget=$actual_budget rc=$RUN_RC stdout=$RUN_STDOUT stderr=$RUN_STDERR"
    fi
}

classify_decision() {
    if [ -z "$RUN_STDOUT" ]; then
        printf 'proceed'
    elif printf '%s' "$RUN_STDOUT" | grep -q '"permissionDecision": "deny"'; then
        printf 'deny'
    elif printf '%s' "$RUN_STDOUT" | grep -q '"permissionDecision": "allow"'; then
        printf 'allow'
    else
        printf 'unknown'
    fi
}

make_sandbox
run_guard "$sandbox" "" '{"tool_name":"Agent","tool_input":{"subagent_type":"software-engineer"}}'
assert_case \
    "missing state initializes from default budget" \
    "$(classify_decision)" \
    "allow" \
    "$(read_budget "$sandbox")" \
    "99"

make_sandbox
run_guard "$sandbox" "SWDT_SUBCALL_BUDGET=7" '{"tool_name":"Agent","tool_input":{"subagent_type":"software-engineer"}}'
assert_case \
    "env override initializes from override budget" \
    "$(classify_decision)" \
    "allow" \
    "$(read_budget "$sandbox")" \
    "6"

make_sandbox
write_budget "$sandbox" 0
run_guard "$sandbox" "" '{"tool_name":"Agent","tool_input":{"subagent_type":"qa-engineer"}}'
assert_case \
    "exhausted budget denies agent spawn" \
    "$(classify_decision)" \
    "deny" \
    "$(read_budget "$sandbox")" \
    "0"

make_sandbox
run_guard "$sandbox" "SWDT_SUBCALL_BUDGET=bogus" '{"tool_name":"Agent","tool_input":{"subagent_type":"qa-engineer"}}'
assert_case \
    "invalid env value falls back to default budget" \
    "$(classify_decision)" \
    "allow" \
    "$(read_budget "$sandbox")" \
    "99"

make_sandbox
run_guard "$sandbox" "SWDT_SUBCALL_BUDGET=0" '{"tool_name":"Agent","tool_input":{"subagent_type":"qa-engineer"}}'
assert_case \
    "zero env value falls back to default budget" \
    "$(classify_decision)" \
    "allow" \
    "$(read_budget "$sandbox")" \
    "99"

make_sandbox
run_guard "$sandbox" "SWDT_SUBCALL_BUDGET=-1" '{"tool_name":"Agent","tool_input":{"subagent_type":"qa-engineer"}}'
assert_case \
    "negative env value falls back to default budget" \
    "$(classify_decision)" \
    "allow" \
    "$(read_budget "$sandbox")" \
    "99"

make_sandbox
write_budget "$sandbox" 1
run_guard "$sandbox" "SWDT_SUBCALL_BUDGET=5" '{"tool_name":"Agent","tool_input":{"subagent_type":"qa-engineer"}}'
assert_case \
    "existing state is decremented instead of reinitialized" \
    "$(classify_decision)" \
    "allow" \
    "$(read_budget "$sandbox")" \
    "0"

make_sandbox
write_budget "$sandbox" 12
run_reset "$sandbox" "SWDT_SUBCALL_BUDGET=5"
assert_case \
    "reset writes effective env budget" \
    "allow" \
    "allow" \
    "$(read_budget "$sandbox")" \
    "5"

make_sandbox
write_budget "$sandbox" 12
run_reset "$sandbox" "SWDT_SUBCALL_BUDGET=bogus"
assert_case \
    "reset falls back to default budget for invalid env" \
    "allow" \
    "allow" \
    "$(read_budget "$sandbox")" \
    "100"

make_sandbox
write_budget "$sandbox" 0
run_guard "$sandbox" "SWDT_SUBCALL_BUDGET=1" '{"tool_name":"Agent","tool_input":{"subagent_type":"qa-engineer"}}'
actual_decision="$(classify_decision)"
deny_reason_ok="no"
if [ "$actual_decision" = "deny" ] \
    && printf '%s' "$RUN_STDOUT" | grep -q 'effective session budget 1' \
    && printf '%s' "$RUN_STDOUT" | grep -q 'SWDT_SUBCALL_BUDGET' \
    && printf '%s' "$RUN_STDOUT" | grep -q 'direct message/resume'; then
    deny_reason_ok="yes"
fi
if [ "$RUN_RC" -eq 0 ] && [ "$deny_reason_ok" = "yes" ] && [ "$(read_budget "$sandbox")" = "0" ]; then
    record_pass "deny message includes effective budget and operator guidance"
else
    record_fail "deny message includes effective budget and operator guidance" \
        "expected deny message with budget/env/reuse guidance; got rc=$RUN_RC stdout=$RUN_STDOUT stderr=$RUN_STDERR budget=$(read_budget "$sandbox")"
fi

printf '\nSummary: %d passed, %d failed\n' "$pass" "$fail"
if [ "$fail" -ne 0 ]; then
    printf 'Failures:\n'
    printf ' - %s\n' "${failures[@]}"
    exit 1
fi
