#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# RED tests for the v1.1 handoff contract first slice. These tests define
# the schema, validator CLI, and path-scope behavior before implementation.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SCHEMA="$REPO_ROOT/schemas/handoff.schema.json"
VALIDATOR="$REPO_ROOT/scripts/validate-handoff.py"
FIXTURES="$REPO_ROOT/tests/hooks/fixtures/handoff"
VALID_FIXTURE="$FIXTURES/valid-handoff.json"
INVALID_FIXTURE="$FIXTURES/missing-required-fields.json"

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
    if [ "${2:-}" ]; then
        printf '      %s\n' "$2"
    fi
}

resolve_check_jsonschema() {
    if command -v check-jsonschema >/dev/null 2>&1; then
        printf 'check-jsonschema'
        return 0
    fi
    local fallback="${HOME}/.local/share/check-jsonschema-venv/bin/check-jsonschema"
    if [ -x "$fallback" ]; then
        printf '%s' "$fallback"
        return 0
    fi
    return 1
}

run_schema_case() {
    local name=$1
    local fixture=$2
    local expect=$3
    local checker tmp_out rc output

    if [ ! -f "$SCHEMA" ]; then
        record_fail "$name" "schema not found: $SCHEMA"
        return
    fi

    if ! checker=$(resolve_check_jsonschema); then
        record_fail "$name" "check-jsonschema not found"
        return
    fi

    tmp_out=$(mktemp)
    "$checker" --schemafile "$SCHEMA" "$fixture" >"$tmp_out" 2>&1
    rc=$?
    output=$(cat "$tmp_out")
    rm -f "$tmp_out"

    if [ "$expect" = "valid" ] && [ "$rc" -eq 0 ]; then
        record_pass "$name"
    elif [ "$expect" = "invalid" ] && [ "$rc" -ne 0 ]; then
        record_pass "$name"
    else
        record_fail "$name" "expected=$expect rc=$rc output=$output"
    fi
}

run_validator_case() {
    local name=$1
    local fixture=$2
    local expect=$3
    local tmp_out rc output

    if [ ! -f "$VALIDATOR" ]; then
        record_fail "$name" "validator not found: $VALIDATOR"
        return
    fi

    tmp_out=$(mktemp)
    python3 "$VALIDATOR" "$fixture" >"$tmp_out" 2>&1
    rc=$?
    output=$(cat "$tmp_out")
    rm -f "$tmp_out"

    if [ "$expect" = "valid" ] && [ "$rc" -eq 0 ]; then
        record_pass "$name"
    elif [ "$expect" = "invalid" ] && [ "$rc" -ne 0 ]; then
        record_pass "$name"
    else
        record_fail "$name" "expected=$expect rc=$rc output=$output"
    fi
}

run_path_scope_case() {
    local name=$1
    local path=$2
    local expect=$3
    local tmp_out rc output

    tmp_out=$(mktemp)
    PYTHONPATH="$REPO_ROOT" python3 - "$path" "$expect" >"$tmp_out" 2>&1 <<'PY'
import sys

from scripts.hooks.lib.path_scope import is_path_allowed

path = sys.argv[1]
expect = sys.argv[2] == "allowed"
actual = is_path_allowed(
    path,
    allowed_paths=["docs/**", "scripts/**"],
    forbidden_paths=["docs/private/**", "scripts/secrets/**"],
)
if actual is not expect:
    raise SystemExit(f"expected {expect} for {path}, got {actual}")
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

run_schema_case "schema accepts a complete handoff fixture" "$VALID_FIXTURE" valid
run_schema_case "schema rejects a handoff missing required fields" "$INVALID_FIXTURE" invalid

# Bounded-Codex permission field constraints (T023):
# codex_permission_flag=true requires permitted_role_owned_action; false does not.
run_schema_case "schema accepts bounded_codex_exception with permission=true and scoped action" \
    "$FIXTURES/bounded-codex-permitted-valid.json" valid
run_schema_case "schema rejects bounded_codex_exception with permission=true but no scoped action" \
    "$FIXTURES/bounded-codex-permitted-missing-action.json" invalid
run_schema_case "schema accepts bounded_codex_exception with permission=false and no scoped action" \
    "$FIXTURES/bounded-codex-denied-valid.json" valid

# Model fallback record field constraints (T026):
# All required fields must be present; capability_tier_comparison must be "same", "higher", or "lower".
run_schema_case "schema accepts model_fallback record with valid capability_tier_comparison" \
    "$FIXTURES/model-fallback-valid.json" valid
run_schema_case "schema rejects model_fallback record with invalid capability_tier_comparison" \
    "$FIXTURES/model-fallback-invalid-tier.json" invalid

run_validator_case "validate-handoff.py accepts a valid fixture" "$VALID_FIXTURE" valid
run_validator_case "validate-handoff.py rejects an invalid fixture" "$INVALID_FIXTURE" invalid

# Model fallback tier enforcement (T027):
# validate-handoff.py must PASS same/higher capability_tier_comparison and FAIL lower.
run_validator_case "validate-handoff.py accepts model_fallback with capability_tier_comparison=higher" \
    "$FIXTURES/model-fallback-valid.json" valid
run_validator_case "validate-handoff.py rejects model_fallback with capability_tier_comparison=lower" \
    "$FIXTURES/model-fallback-lower-tier.json" invalid

# S-2: "same" tier coverage (previously untested).
run_validator_case "validate-handoff.py accepts model_fallback with capability_tier_comparison=same" \
    "$FIXTURES/model-fallback-same-tier.json" valid

# B-1 regression: non-dict model_fallback must exit nonzero (schema error) without crashing.
# The type guard in check_model_fallback_tier prevents AttributeError when schema
# has already recorded the type mismatch.
run_validator_case_no_traceback() {
    local name=$1
    local fixture=$2
    local tmp_out rc output
    if [ ! -f "$VALIDATOR" ]; then
        record_fail "$name" "validator not found: $VALIDATOR"
        return
    fi
    tmp_out=$(mktemp)
    python3 "$VALIDATOR" "$fixture" >"$tmp_out" 2>&1
    rc=$?
    output=$(cat "$tmp_out")
    rm -f "$tmp_out"
    if [ "$rc" -ne 0 ] && ! printf '%s' "$output" | grep -q 'Traceback\|AttributeError'; then
        record_pass "$name"
    elif [ "$rc" -eq 0 ]; then
        record_fail "$name" "expected nonzero exit (schema error), got rc=0 output=$output"
    else
        record_fail "$name" "exited nonzero but traceback/AttributeError present: output=$output"
    fi
}
run_validator_case_no_traceback \
    "validate-handoff.py exits nonzero with schema error (no crash) when model_fallback is non-dict (B-1 regression)" \
    "$FIXTURES/model-fallback-non-dict.json"

run_path_scope_case "path scope allows paths matching allowed_paths" "docs/public/readme.md" allowed
run_path_scope_case "path scope lets forbidden_paths override broad allows" "docs/private/secret.md" forbidden

# External-tool activity references (T031):
# Schema must accept a handoff WITH external_tool_activity (llmdc + Speckit entries).
run_schema_case "schema accepts handoff with external_tool_activity references (llmdc + speckit)" \
    "$FIXTURES/external-tool-activity-valid.json" valid
# The structural separation test: external_tool_activity present, evidence gates unsatisfied.
# validate-handoff.py must still accept the schema (separation is structural, not a schema violation)
# but the evidence helpers will report missing gates — proven by the fixture having empty verification.
run_validator_case "validate-handoff.py accepts handoff with external_tool_activity but unsatisfied evidence gates" \
    "$FIXTURES/external-tool-activity-not-evidence.json" valid
# Prove external_tool_activity entries are invisible to evidence helpers:
# a handoff with only external_tool_activity and no verification entries has missing gates.
run_gate_isolation_case() {
    local name=$1
    local fixture=$2
    local repo_root=$3
    local tmp_out rc output
    tmp_out=$(mktemp)
    python3 - "$fixture" "$repo_root" >"$tmp_out" 2>&1 <<'PY'
import sys, json, importlib.util, pathlib

fixture_path = sys.argv[1]
repo_root = pathlib.Path(sys.argv[2])

handoff_lib = repo_root / "scripts" / "hooks" / "lib" / "handoff.py"
spec = importlib.util.spec_from_file_location("handoff", handoff_lib)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

with open(fixture_path) as f:
    handoff = json.load(f)

# external_tool_activity must not satisfy any evidence gate
missing = mod.missing_evidence_gates(handoff)
# requires.review=True and no review evidence => "review" must be in missing
if "review" not in missing:
    raise SystemExit(
        f"FAIL: expected 'review' in missing_evidence_gates but got {missing}; "
        "external_tool_activity must not satisfy the review gate"
    )
# external_tool_activity present => entries are accessible but not read as evidence
eta = handoff.get("external_tool_activity", [])
if not eta:
    raise SystemExit("FAIL: fixture has no external_tool_activity entries")
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
run_gate_isolation_case \
    "external_tool_activity is invisible to evidence helpers (review gate remains unsatisfied)" \
    "$FIXTURES/external-tool-activity-not-evidence.json" \
    "$REPO_ROOT"

printf '\nSummary: %s passed, %s failed\n' "$pass" "$fail"
if [ "$fail" -ne 0 ]; then
    printf 'Failures:\n'
    printf ' - %s\n' "${failures[@]}"
    exit 1
fi
