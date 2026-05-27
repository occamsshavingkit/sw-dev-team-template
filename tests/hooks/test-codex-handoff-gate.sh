#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# Smoke tests for the bounded-Codex handoff gate.
# Reference: scripts/hooks/handoff-pre-tool-gate.py
# Contract:  specs/012-v1-1-handoff-contracts/contracts/hook-events.md
#            "Bounded Codex Gate" section
#
# T011: scaffold only — sanity assertions that gate script and required lib
# exist as importable Python.  Full case matrix added by T024/T025/T041.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HOOK="$REPO_ROOT/scripts/hooks/handoff-pre-tool-gate.py"
FIXTURES="$REPO_ROOT/tests/hooks/fixtures/handoff"

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
# Sanity: gate script exists (invoked via python3, not directly executable)
# ---------------------------------------------------------------------------
if [ -f "$HOOK" ]; then
    record_pass "bounded-Codex gate script exists: $HOOK"
else
    record_fail "bounded-Codex gate script exists: $HOOK" \
        "file missing at $HOOK"
fi

# ---------------------------------------------------------------------------
# Sanity: gate script is importable as a Python module (syntax + import check)
# ---------------------------------------------------------------------------
tmp_out=$(mktemp)
PYTHONPATH="$REPO_ROOT" python3 -c "
import ast, pathlib
src = pathlib.Path('$HOOK').read_text(encoding='utf-8')
ast.parse(src)
" >"$tmp_out" 2>&1
rc=$?
output=$(cat "$tmp_out")
rm -f "$tmp_out"

if [ "$rc" -eq 0 ]; then
    record_pass "bounded-Codex gate script parses without syntax errors"
else
    record_fail "bounded-Codex gate script parses without syntax errors" \
        "rc=$rc output=$output"
fi

# ---------------------------------------------------------------------------
# Sanity: lib/path_scope.py is importable (used by gate for scope enforcement)
# ---------------------------------------------------------------------------
tmp_out=$(mktemp)
PYTHONPATH="$REPO_ROOT" python3 -c "
from scripts.hooks.lib.path_scope import is_path_allowed, is_framework_managed, is_framework_scope_satisfied
" >"$tmp_out" 2>&1
rc=$?
output=$(cat "$tmp_out")
rm -f "$tmp_out"

if [ "$rc" -eq 0 ]; then
    record_pass "scripts.hooks.lib.path_scope imports cleanly (is_path_allowed, is_framework_managed, is_framework_scope_satisfied)"
else
    record_fail "scripts.hooks.lib.path_scope imports cleanly" \
        "rc=$rc output=$output"
fi

# ---------------------------------------------------------------------------
# Gate logic smoke cases (T024)
# These minimal cases prove the gate logic before T025 adds the full matrix.
# ---------------------------------------------------------------------------

SANDBOXES=()
cleanup() {
    local s
    for s in "${SANDBOXES[@]:-}"; do
        rm -rf "$s"
    done
}
trap cleanup EXIT

make_codex_sandbox() {
    # $1 = fixture filename (relative to FIXTURES)
    local fixture="$1"
    local sb
    sb=$(mktemp -d)
    SANDBOXES+=("$sb")
    mkdir -p "$sb/.devteam" "$sb/docs/handoffs" "$sb/schemas" "$sb/.claude"
    cp "$FIXTURES/$fixture" "$sb/docs/handoffs/handoff.json"
    printf '{"handoff_path":"docs/handoffs/handoff.json"}\n' \
        >"$sb/.devteam/active-handoff.json"
    printf '%s' "$sb"
}

classify_decision() {
    python3 -c '
import json, sys
text = sys.stdin.read()
if not text:
    print("proceed"); raise SystemExit
try:
    payload = json.loads(text)
except json.JSONDecodeError:
    print("unknown"); raise SystemExit
hook_output = payload.get("hookSpecificOutput")
if not isinstance(hook_output, dict):
    print("unknown"); raise SystemExit
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

run_codex_gate_case() {
    local name="$1" mode="$2" fixture="$3" path_arg="$4" expect="$5"
    local sb payload tmp_out tmp_err rc stdout stderr actual
    sb=$(make_codex_sandbox "$fixture")
    payload=$(python3 -c 'import json,sys; print(json.dumps({"tool_input":{"file_path":sys.argv[1],"content":"x"}}))' "$path_arg")
    tmp_out=$(mktemp); tmp_err=$(mktemp)
    printf '%s' "$payload" | CLAUDE_PROJECT_DIR="$sb" SWDT_HANDOFF_GATES="$mode" \
        PYTHONPATH="$REPO_ROOT" python3 "$HOOK" >"$tmp_out" 2>"$tmp_err"
    rc=$?
    stdout=$(cat "$tmp_out"); stderr=$(cat "$tmp_err")
    rm -f "$tmp_out" "$tmp_err"
    actual=$(printf '%s' "$stdout" | classify_decision)
    if [ "$actual" = "$expect" ] && [ "$rc" -eq 0 ]; then
        record_pass "$name"
    else
        record_fail "$name" "expected=$expect actual=$actual rc=$rc stdout=$stdout stderr=$stderr"
    fi
}

run_codex_event_mode_case() {
    # Like run_codex_gate_case but injects execution_mode into the event payload.
    local name="$1" mode="$2" fixture="$3" path_arg="$4" expect="$5"
    local sb payload tmp_out tmp_err rc stdout stderr actual
    sb=$(make_codex_sandbox "$fixture")
    payload=$(python3 -c 'import json,sys; print(json.dumps({"execution_mode":"bounded-codex","tool_input":{"file_path":sys.argv[1],"content":"x"}}))' "$path_arg")
    tmp_out=$(mktemp); tmp_err=$(mktemp)
    printf '%s' "$payload" | CLAUDE_PROJECT_DIR="$sb" SWDT_HANDOFF_GATES="$mode" \
        PYTHONPATH="$REPO_ROOT" python3 "$HOOK" >"$tmp_out" 2>"$tmp_err"
    rc=$?
    stdout=$(cat "$tmp_out"); stderr=$(cat "$tmp_err")
    rm -f "$tmp_out" "$tmp_err"
    actual=$(printf '%s' "$stdout" | classify_decision)
    if [ "$actual" = "$expect" ] && [ "$rc" -eq 0 ]; then
        record_pass "$name"
    else
        record_fail "$name" "expected=$expect actual=$actual rc=$rc stdout=$stdout stderr=$stderr"
    fi
}

# T024-C1: handoff with codex_permission_flag=true, path within exception scope → allowed.
run_codex_gate_case \
    "T024-C1: permitted bounded-Codex write within exception allowed_paths proceeds (enforce)" \
    enforce "bounded-codex-permitted-valid.json" "schemas/handoff.schema.json" proceed

# T024-C2: handoff with codex_permission_flag=true, path outside exception allowed_paths → denied.
run_codex_gate_case \
    "T024-C2: permitted bounded-Codex write outside exception allowed_paths is denied (enforce)" \
    enforce "bounded-codex-permitted-valid.json" "docs/README.md" deny

# T024-C3: handoff with codex_permission_flag=false (explicit denial) → denied.
run_codex_gate_case \
    "T024-C3: explicit codex_permission_flag=false is denied regardless of path (enforce)" \
    enforce "bounded-codex-denied-valid.json" "schemas/handoff.schema.json" deny

# T024-C4: same as C3 but warn mode → warns-and-proceeds.
run_codex_gate_case \
    "T024-C4: explicit codex_permission_flag=false warns-and-proceeds in warn mode" \
    warn "bounded-codex-denied-valid.json" "schemas/handoff.schema.json" warn

# T024-C5: codex_permission_flag=true, path in exception allowed_paths but in exception
# forbidden_paths → denied (forbidden overrides allowed at exception level).
run_codex_gate_case \
    "T024-C5: permitted bounded-Codex write blocked by exception forbidden_paths (enforce)" \
    enforce "bounded-codex-permitted-valid.json" ".claude/settings.json" deny

# T024-C6: event carries execution_mode="bounded-codex", handoff has no bounded_codex_exception
# (active-path-scope-handoff uses mode.execution=bounded-codex but no exception block).
# Detection fires via event-level marker; no permission block → denied.
# Use a fixture that has no bounded_codex_exception but does have allowed_paths we can check.
# We use active-path-scope-handoff.json (no bounded_codex_exception, allowed_paths=["docs/allowed/**"]).
run_codex_event_mode_case \
    "T024-C6: event execution_mode=bounded-codex with no handoff exception block is denied (enforce)" \
    enforce "active-path-scope-handoff.json" "docs/allowed/notes.md" deny

# T024-C7: same handoff, same event marker, warn mode → warns-and-proceeds.
run_codex_event_mode_case \
    "T024-C7: event execution_mode=bounded-codex with no handoff exception block warns in warn mode" \
    warn "active-path-scope-handoff.json" "docs/allowed/notes.md" warn

# ---------------------------------------------------------------------------
# T025: Full bounded-Codex case matrix (US3 independent test)
# ---------------------------------------------------------------------------

# T025-C1: Permitted bounded-Codex (flag=true), path forbidden at handoff level
# even though exception allowed_paths would allow it.  Handoff-level forbidden
# wins; intersection scope denies.
run_codex_gate_case \
    "T025-C1: permitted bounded-Codex blocked by handoff-level forbidden_paths (enforce)" \
    enforce "bounded-codex-permitted-handoff-forbidden.json" "docs/private/secret.md" deny

# T025-C2: Same handoff-level forbidden case, warn mode → warns-and-proceeds.
run_codex_gate_case \
    "T025-C2: permitted bounded-Codex blocked by handoff-level forbidden_paths (warn)" \
    warn "bounded-codex-permitted-handoff-forbidden.json" "docs/private/secret.md" warn

# T025-C3: Permitted bounded-Codex (flag=true), path within both handoff and
# exception scopes, but path is framework-managed and framework_scope=product →
# framework-scope gate fires → deny.
run_codex_gate_case \
    "T025-C3: permitted bounded-Codex cannot waive framework-scope gate (enforce)" \
    enforce "bounded-codex-permitted-product-scope.json" "scripts/hooks/handoff-pre-tool-gate.py" deny

# T025-C4: Same framework-scope deny case, warn mode → warns-and-proceeds.
run_codex_gate_case \
    "T025-C4: permitted bounded-Codex framework-scope gate warn mode warns-and-proceeds" \
    warn "bounded-codex-permitted-product-scope.json" "scripts/hooks/handoff-pre-tool-gate.py" warn

# T025-C5: Positive contrast — permitted bounded-Codex with event-level
# execution_mode marker, path within both handoff and exception allowed_paths,
# not forbidden at either level, not framework-managed → proceeds.
run_codex_event_mode_case \
    "T025-C5: permitted bounded-Codex via event_mode marker within scope proceeds (positive contrast)" \
    enforce "bounded-codex-permitted-valid.json" "schemas/handoff.schema.json" proceed

# T025-C6: Negative contrast — permitted bounded-Codex with event-level marker,
# path outside exception allowed_paths → denied (exception sub-scope is narrower).
run_codex_event_mode_case \
    "T025-C6: permitted bounded-Codex via event_mode marker outside exception scope denied (negative contrast)" \
    enforce "bounded-codex-permitted-valid.json" "docs/README.md" deny

# T025-C7: Bounded-Codex event (via handoff bce block, no event marker),
# codex_permission_flag=false → deny without reaching path checks (enforce).
# Detection fires from handoff bce block (signal 2); explicit denial.
run_codex_gate_case \
    "T025-C7: bce block present with flag=false detected via handoff signal is denied (enforce)" \
    enforce "bounded-codex-denied-valid.json" "schemas/handoff.schema.json" deny

# T025-C8: Permitted bounded-Codex, path within both handoff and exception scopes
# AND non-framework-managed (framework_scope=product, path is schemas/test.json) →
# proceeds.  Confirms the gate is specific: product-scope handoff does not blanket-deny
# non-framework-managed writes; only framework-managed paths are gated by scope.
run_codex_gate_case \
    "T025-C8: permitted bounded-Codex to non-framework-managed path with product scope proceeds" \
    enforce "bounded-codex-permitted-handoff-forbidden.json" "schemas/test.json" proceed

# ---------------------------------------------------------------------------
# S-1: Bounded-Codex Signal-2 over-trigger documentation (by-design behavior)
#
# Scenario: handoff HAS a bounded_codex_exception block (Signal 2 fires) with
# codex_permission_flag=true.  The event carries NO execution_mode marker.
# The write target (scripts/validate-handoff.py) is within the handoff's
# allowed_paths ("scripts/**") but OUTSIDE the exception's allowed_paths
# ("schemas/handoff.schema.json" only).
#
# Expected behavior: DENIED in enforce mode, WARNS in warn mode.
# This is intentional defensive over-gating: the presence of a bce block
# makes every PreToolUse in the session a bounded-Codex event (Signal 2),
# so the narrower exception scope applies even without an event-level marker.
# The exception scope (schemas/handoff.schema.json) is narrower than the
# handoff scope (scripts/**), so the path fails the exception sub-scope check.
#
# Cross-reference: docs/v1.1-handoff-contracts.md bounded-Codex known-limitation
# note (Signal-2 over-trigger / S-1 DOC note, added by tech-writer this pass).
# ---------------------------------------------------------------------------

# S-1-enforce: Signal-2 triggers; path in handoff scope but outside exception
# scope → denied (by-design defensive over-gating).
run_codex_gate_case \
    "S-1: Signal-2 bce-block detected, path within handoff scope but outside exception scope is denied (enforce)" \
    enforce "bounded-codex-permitted-valid.json" "scripts/validate-handoff.py" deny

# S-1-warn: same scenario in warn mode → warns-and-proceeds.
run_codex_gate_case \
    "S-1: Signal-2 bce-block detected, path within handoff scope but outside exception scope warns in warn mode" \
    warn "bounded-codex-permitted-valid.json" "scripts/validate-handoff.py" warn

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
