#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# Smoke tests for the framework-managed path boundary gate.
# Reference: scripts/hooks/lib/path_scope.py
#            (is_framework_managed / is_framework_scope_satisfied)
# Contract:  specs/012-v1-1-handoff-contracts/contracts/hook-events.md
#            "PreToolUse Gate" section; framework/project boundary rules
#
# T011: scaffold only — sanity assertions that lib exists and the two
# boundary functions import and return expected types.
# Full authorization case matrix added by T015.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LIB="$REPO_ROOT/scripts/hooks/lib/path_scope.py"

pass=0
fail=0
failures=()

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

# ---------------------------------------------------------------------------
# Sanity: lib/path_scope.py exists
# ---------------------------------------------------------------------------
if [ -f "$LIB" ]; then
    record_pass "framework path-scope lib exists: $LIB"
else
    record_fail "framework path-scope lib exists: $LIB" \
        "file missing at $LIB"
fi

# ---------------------------------------------------------------------------
# Sanity: is_framework_managed and is_framework_scope_satisfied importable
# ---------------------------------------------------------------------------
tmp_out=$(mktemp)
PYTHONPATH="$REPO_ROOT" python3 -c "
from scripts.hooks.lib.path_scope import is_framework_managed, is_framework_scope_satisfied
" >"$tmp_out" 2>&1
rc=$?
output=$(cat "$tmp_out")
rm -f "$tmp_out"

if [ "$rc" -eq 0 ]; then
    record_pass "is_framework_managed and is_framework_scope_satisfied import cleanly"
else
    record_fail "is_framework_managed and is_framework_scope_satisfied import cleanly" \
        "rc=$rc output=$output"
fi

# ---------------------------------------------------------------------------
# Sanity: is_framework_managed returns bool for a known framework-managed path
# ---------------------------------------------------------------------------
tmp_out=$(mktemp)
PYTHONPATH="$REPO_ROOT" python3 -c "
from scripts.hooks.lib.path_scope import is_framework_managed
result = is_framework_managed('scripts/hooks/handoff-pre-tool-gate.py')
assert isinstance(result, bool), f'expected bool, got {type(result)}'
assert result is True, f'scripts/hooks/* should be framework-managed, got {result}'
" >"$tmp_out" 2>&1
rc=$?
output=$(cat "$tmp_out")
rm -f "$tmp_out"

if [ "$rc" -eq 0 ]; then
    record_pass "is_framework_managed returns True for scripts/hooks/* path"
else
    record_fail "is_framework_managed returns True for scripts/hooks/* path" \
        "rc=$rc output=$output"
fi

# ---------------------------------------------------------------------------
# Sanity: is_framework_scope_satisfied returns True for non-framework path
# regardless of scope value
# ---------------------------------------------------------------------------
tmp_out=$(mktemp)
PYTHONPATH="$REPO_ROOT" python3 -c "
from scripts.hooks.lib.path_scope import is_framework_scope_satisfied
result = is_framework_scope_satisfied('docs/requirements.md', 'product')
assert isinstance(result, bool), f'expected bool, got {type(result)}'
assert result is True, 'non-framework-managed path should always pass scope check'
" >"$tmp_out" 2>&1
rc=$?
output=$(cat "$tmp_out")
rm -f "$tmp_out"

if [ "$rc" -eq 0 ]; then
    record_pass "is_framework_scope_satisfied returns True for non-framework-managed path with any scope"
else
    record_fail "is_framework_scope_satisfied returns True for non-framework-managed path with any scope" \
        "rc=$rc output=$output"
fi

# ===========================================================================
# T015: Authorization case matrix
# ===========================================================================

# ---------------------------------------------------------------------------
# Helper: run a python assertion inline and record pass/fail
# Usage: run_py_case "label" "python code that raises on failure"
# ---------------------------------------------------------------------------
run_py_case() {
    local label="$1"
    local code="$2"
    local tmp
    tmp=$(mktemp)
    PYTHONPATH="$REPO_ROOT" python3 -c "$code" >"$tmp" 2>&1
    local rc=$?
    local out
    out=$(cat "$tmp")
    rm -f "$tmp"
    if [ "$rc" -eq 0 ]; then
        record_pass "$label"
    else
        record_fail "$label" "rc=$rc output=$out"
    fi
}

# ---------------------------------------------------------------------------
# A1: framework-managed path + framework_scope == "framework-maintenance"
#     → is_framework_scope_satisfied returns True (allowed)
# ---------------------------------------------------------------------------
run_py_case \
    "A1: framework-managed + framework-maintenance scope → satisfied" \
    "
from scripts.hooks.lib.path_scope import is_framework_scope_satisfied
result = is_framework_scope_satisfied('scripts/hooks/handoff-pre-tool-gate.py', 'framework-maintenance')
assert result is True, f'expected True, got {result}'
"

# ---------------------------------------------------------------------------
# A2: framework-managed path + framework_scope absent (empty string)
#     → is_framework_scope_satisfied returns False (blocked)
# ---------------------------------------------------------------------------
run_py_case \
    "A2: framework-managed + absent scope (empty string) → not satisfied" \
    "
from scripts.hooks.lib.path_scope import is_framework_scope_satisfied
result = is_framework_scope_satisfied('scripts/hooks/handoff-pre-tool-gate.py', '')
assert result is False, f'expected False, got {result}'
"

# ---------------------------------------------------------------------------
# A3: framework-managed path + framework_scope == "product"
#     → is_framework_scope_satisfied returns False (blocked)
# ---------------------------------------------------------------------------
run_py_case \
    "A3: framework-managed + product scope → not satisfied" \
    "
from scripts.hooks.lib.path_scope import is_framework_scope_satisfied
result = is_framework_scope_satisfied('docs/templates/task-template.md', 'product')
assert result is False, f'expected False, got {result}'
"

# ---------------------------------------------------------------------------
# A4: framework-managed path + framework_scope == "some-other-value"
#     → is_framework_scope_satisfied returns False (blocked)
# ---------------------------------------------------------------------------
run_py_case \
    "A4: framework-managed + arbitrary non-framework scope → not satisfied" \
    "
from scripts.hooks.lib.path_scope import is_framework_scope_satisfied
result = is_framework_scope_satisfied('CLAUDE.md', 'template-upgrade')
assert result is False, f'expected False, got {result}'
"

# ---------------------------------------------------------------------------
# A5: non-framework path + framework_scope == "product" → satisfied
# ---------------------------------------------------------------------------
run_py_case \
    "A5: non-framework path + product scope → satisfied" \
    "
from scripts.hooks.lib.path_scope import is_framework_scope_satisfied
result = is_framework_scope_satisfied('src/main.py', 'product')
assert result is True, f'expected True, got {result}'
"

# ---------------------------------------------------------------------------
# A6: non-framework path + framework_scope == "framework-maintenance"
#     → still satisfied (rule doesn't restrict non-framework paths)
# ---------------------------------------------------------------------------
run_py_case \
    "A6: non-framework path + framework-maintenance scope → satisfied" \
    "
from scripts.hooks.lib.path_scope import is_framework_scope_satisfied
result = is_framework_scope_satisfied('src/main.py', 'framework-maintenance')
assert result is True, f'expected True, got {result}'
"

# ---------------------------------------------------------------------------
# A7: non-framework path + empty scope → satisfied
# ---------------------------------------------------------------------------
run_py_case \
    "A7: non-framework path + empty scope → satisfied" \
    "
from scripts.hooks.lib.path_scope import is_framework_scope_satisfied
result = is_framework_scope_satisfied('docs/requirements.md', '')
assert result is True, f'expected True, got {result}'
"

# ---------------------------------------------------------------------------
# A8: schemas/handoff.schema.json + framework_scope == "product" → not satisfied
# ---------------------------------------------------------------------------
run_py_case \
    "A8: schemas/handoff.schema.json + product scope → not satisfied" \
    "
from scripts.hooks.lib.path_scope import is_framework_scope_satisfied
result = is_framework_scope_satisfied('schemas/handoff.schema.json', 'product')
assert result is False, f'expected False, got {result}'
"

# ---------------------------------------------------------------------------
# A9: schemas/handoff.schema.json + framework_scope == "framework-maintenance"
#     → satisfied
# ---------------------------------------------------------------------------
run_py_case \
    "A9: schemas/handoff.schema.json + framework-maintenance scope → satisfied" \
    "
from scripts.hooks.lib.path_scope import is_framework_scope_satisfied
result = is_framework_scope_satisfied('schemas/handoff.schema.json', 'framework-maintenance')
assert result is True, f'expected True, got {result}'
"

# ---------------------------------------------------------------------------
# B-series: representative framework-managed patterns → is_framework_managed True
# ---------------------------------------------------------------------------

run_py_case \
    "B1: CLAUDE.md is framework-managed" \
    "
from scripts.hooks.lib.path_scope import is_framework_managed
assert is_framework_managed('CLAUDE.md') is True, 'expected True'
"

run_py_case \
    "B2: AGENTS.md is framework-managed" \
    "
from scripts.hooks.lib.path_scope import is_framework_managed
assert is_framework_managed('AGENTS.md') is True, 'expected True'
"

run_py_case \
    "B3: .claude/agents/tech-lead.md is framework-managed" \
    "
from scripts.hooks.lib.path_scope import is_framework_managed
assert is_framework_managed('.claude/agents/tech-lead.md') is True, 'expected True'
"

run_py_case \
    "B4: scripts/hooks/handoff-pre-tool-gate.py is framework-managed" \
    "
from scripts.hooks.lib.path_scope import is_framework_managed
assert is_framework_managed('scripts/hooks/handoff-pre-tool-gate.py') is True, 'expected True'
"

run_py_case \
    "B5: migrations/0001-init.sql is framework-managed" \
    "
from scripts.hooks.lib.path_scope import is_framework_managed
assert is_framework_managed('migrations/0001-init.sql') is True, 'expected True'
"

run_py_case \
    "B6: docs/templates/task-template.md is framework-managed" \
    "
from scripts.hooks.lib.path_scope import is_framework_managed
assert is_framework_managed('docs/templates/task-template.md') is True, 'expected True'
"

run_py_case \
    "B7: docs/INDEX-FRAMEWORK.md is framework-managed" \
    "
from scripts.hooks.lib.path_scope import is_framework_managed
assert is_framework_managed('docs/INDEX-FRAMEWORK.md') is True, 'expected True'
"

run_py_case \
    "B8: docs/adr/fw-adr-0001-context-memory-strategy.md is framework-managed" \
    "
from scripts.hooks.lib.path_scope import is_framework_managed
assert is_framework_managed('docs/adr/fw-adr-0001-context-memory-strategy.md') is True, 'expected True'
"

run_py_case \
    "B9: TEMPLATE_MANIFEST.lock is framework-managed" \
    "
from scripts.hooks.lib.path_scope import is_framework_managed
assert is_framework_managed('TEMPLATE_MANIFEST.lock') is True, 'expected True'
"

run_py_case \
    "B10: schemas/handoff.schema.json is framework-managed" \
    "
from scripts.hooks.lib.path_scope import is_framework_managed
assert is_framework_managed('schemas/handoff.schema.json') is True, 'expected True'
"

run_py_case \
    "B11: TEMPLATE_VERSION is framework-managed" \
    "
from scripts.hooks.lib.path_scope import is_framework_managed
assert is_framework_managed('TEMPLATE_VERSION') is True, 'expected True'
"

run_py_case \
    "B12: schemas/README.md is framework-managed" \
    "
from scripts.hooks.lib.path_scope import is_framework_managed
assert is_framework_managed('schemas/README.md') is True, 'expected True'
"

# ---------------------------------------------------------------------------
# C-series: clearly non-framework paths → is_framework_managed False
# ---------------------------------------------------------------------------

run_py_case \
    "C1: src/main.py is NOT framework-managed" \
    "
from scripts.hooks.lib.path_scope import is_framework_managed
assert is_framework_managed('src/main.py') is False, 'expected False'
"

run_py_case \
    "C2: docs/requirements.md is NOT framework-managed" \
    "
from scripts.hooks.lib.path_scope import is_framework_managed
assert is_framework_managed('docs/requirements.md') is False, 'expected False'
"

run_py_case \
    "C3: README.md is NOT framework-managed" \
    "
from scripts.hooks.lib.path_scope import is_framework_managed
assert is_framework_managed('README.md') is False, 'expected False'
"

run_py_case \
    "C4: docs/adr/0001-use-postgres.md (project ADR) is NOT framework-managed" \
    "
from scripts.hooks.lib.path_scope import is_framework_managed
assert is_framework_managed('docs/adr/0001-use-postgres.md') is False, 'expected False'
"

run_py_case \
    "C5: CUSTOMER_NOTES.md is NOT framework-managed" \
    "
from scripts.hooks.lib.path_scope import is_framework_managed
assert is_framework_managed('CUSTOMER_NOTES.md') is False, 'expected False'
"

run_py_case \
    "C6: src/schemas/foo.json is NOT framework-managed (root-anchoring: non-root schemas/ segment)" \
    "
from scripts.hooks.lib.path_scope import is_framework_managed
assert is_framework_managed('src/schemas/foo.json') is False, 'expected False — schemas/** must not match non-root segments'
"

run_py_case \
    "C7: app/schemas/user.json is NOT framework-managed (root-anchoring)" \
    "
from scripts.hooks.lib.path_scope import is_framework_managed
assert is_framework_managed('app/schemas/user.json') is False, 'expected False — schemas/** must not match non-root segments'
"

# ===========================================================================
# Gate-level tests: framework-scope enforcement through handoff-pre-tool-gate
# (FR-004 / US1 scenario 3)
# ===========================================================================

HOOK="$REPO_ROOT/scripts/hooks/handoff-pre-tool-gate.py"
PRODUCT_FIXTURE="$REPO_ROOT/tests/hooks/fixtures/handoff/framework-scope-product-handoff.json"
MAINTENANCE_FIXTURE="$REPO_ROOT/tests/hooks/fixtures/handoff/framework-scope-maintenance-handoff.json"

GATE_SANDBOXES=()

make_gate_sandbox() {
    local fixture="$1"
    local gsandbox
    gsandbox=$(mktemp -d)
    GATE_SANDBOXES+=("$gsandbox")
    mkdir -p "$gsandbox/.devteam" "$gsandbox/docs/handoffs"
    local fname
    fname="$(basename "$fixture")"
    cp "$fixture" "$gsandbox/docs/handoffs/$fname"
    printf '{"handoff_path":"docs/handoffs/%s"}\n' "$fname" \
        >"$gsandbox/.devteam/active-handoff.json"
    echo "$gsandbox"
}

cleanup_gate_sandboxes() {
    local s
    for s in "${GATE_SANDBOXES[@]}"; do
        rm -rf "$s"
    done
}
trap cleanup_gate_sandboxes EXIT

mkpayload_gate_file() {
    python3 -c 'import json,sys; print(json.dumps({"tool_input":{"file_path":sys.argv[1],"content":"x"}}))' "$1"
}

classify_gate_decision() {
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

run_framework_gate_case() {
    local name="$1"
    local fixture="$2"
    local target_path="$3"
    local mode="$4"
    local expect="$5"
    local gsandbox payload tmp_out tmp_err rc stdout stderr actual
    gsandbox=$(make_gate_sandbox "$fixture")
    payload=$(mkpayload_gate_file "$target_path")
    tmp_out=$(mktemp)
    tmp_err=$(mktemp)

    printf '%s' "$payload" | CLAUDE_PROJECT_DIR="$gsandbox" SWDT_HANDOFF_GATES="$mode" \
        PYTHONPATH="$REPO_ROOT" python3 "$HOOK" >"$tmp_out" 2>"$tmp_err"
    rc=$?
    stdout=$(cat "$tmp_out")
    stderr=$(cat "$tmp_err")
    rm -f "$tmp_out" "$tmp_err"
    actual=$(printf '%s' "$stdout" | classify_gate_decision)

    if [ "$actual" = "$expect" ] && [ "$rc" -eq 0 ]; then
        record_pass "$name"
    else
        record_fail "$name" "expected=$expect actual=$actual rc=$rc stdout=$stdout stderr=$stderr"
    fi
}

# G1: framework-managed path + product scope + enforce → deny
run_framework_gate_case \
    "G1: enforce blocks framework-managed write when handoff scope is product (not framework-maintenance)" \
    "$PRODUCT_FIXTURE" \
    "scripts/hooks/handoff-pre-tool-gate.py" \
    "enforce" \
    "deny"

# G2: framework-managed path + product scope + warn → warn (non-blocking)
run_framework_gate_case \
    "G2: warn mode warns-but-proceeds for framework-managed write when handoff scope is product" \
    "$PRODUCT_FIXTURE" \
    "scripts/hooks/handoff-pre-tool-gate.py" \
    "warn" \
    "warn"

# G3: framework-managed path + framework-maintenance scope + enforce → proceed
run_framework_gate_case \
    "G3: enforce allows framework-managed write when handoff scope is framework-maintenance" \
    "$MAINTENANCE_FIXTURE" \
    "scripts/hooks/handoff-pre-tool-gate.py" \
    "enforce" \
    "proceed"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
printf '\nSummary: %s passed, %s failed\n' "$pass" "$fail"
if [ "$fail" -ne 0 ]; then
    printf 'Failures:\n'
    printf ' - %s\n' "${failures[@]}"
    exit 1
fi

exit 0
