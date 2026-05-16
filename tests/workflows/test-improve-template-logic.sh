#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# test-improve-template-logic.sh
#
# Local structural dry-run of the safety pipeline embedded in
# .github/workflows/improve-template.yml (M7 self-improvement workflow).
# Validates SC-010 (T072) without triggering the live GitHub Actions run.
#
# Scope:
#   - size-cap check  (lines <=400, files <=10)
#   - protected-files + customer-truth check (paired-proposal escape valve)
#
# SYNC NOTE
# ---------
# The two shell logic blocks below MUST stay in lockstep with the matching
# `run:` blocks in .github/workflows/improve-template.yml ("Size cap
# enforcement" and "Protected-files / customer-truth check" steps). If you
# change one, change both in the same PR. The workflow itself is NOT edited
# by this test; we only mirror its logic against fixture diffs.
#
# Usage:  tests/workflows/test-improve-template-logic.sh
# Exits 0 iff every fixture produces its expected outcome.

set -eu

# shellcheck disable=SC1007  # deliberate: empty CDPATH assignment scopes to the cd call
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
FIXTURE_DIR="${SCRIPT_DIR}/fixtures"

# ----- size_cap_check ------------------------------------------------------
# Mirrors workflow "Size cap enforcement" step.
# Returns 0 = within cap, 1 = exceeds cap.
size_cap_check() {
    diff_file=$1
    lines=$(wc -l < "${diff_file}" || echo 0)
    files=$(grep -c '^diff --git' "${diff_file}" || echo 0)
    if [ "${lines}" -gt 400 ] || [ "${files}" -gt 10 ]; then
        return 1
    fi
    return 0
}

# ----- protected_check -----------------------------------------------------
# Mirrors workflow "Protected-files / customer-truth check" step.
# Returns 0 = OK, 1 = violation.
protected_check() {
    _orig_dir="$(pwd)"
    cd "$(git rev-parse --show-toplevel)"
    diff_file=$1
    protected_paths='^(CLAUDE\.md|AGENTS\.md|VERSION|TEMPLATE_MANIFEST\.lock|\.claude/agents/|docs/adr/|docs/framework-project-boundary\.md|docs/model-routing-guidelines\.md|\.github/workflows/|migrations/)'
    customer_truth='^(CUSTOMER_NOTES\.md|docs/OPEN_QUESTIONS\.md|docs/intake-log\.md)$'
    hard_rule_pattern='(## Hard [Rr]ules?|Hard Rule #|MUST not|MUST NOT)'
    changed_paths=$(grep '^diff --git' "${diff_file}" | awk '{print $4}' | sed 's|^b/||' || true)
    violations=""
    for p in ${changed_paths}; do
        if echo "${p}" | grep -Eq "${protected_paths}"; then
            if ! echo "${changed_paths}" | grep -Eq '^docs/proposals/.+\.md$'; then
                violations="${violations} ${p}"
            fi
        fi
        if echo "${p}" | grep -Eq "${customer_truth}"; then
            if ! echo "${changed_paths}" | grep -Eq '^docs/proposals/.+\.md$'; then
                violations="${violations} ${p}"
            fi
        fi
        # Content check: flag any file (not already caught by path) that
        # adds Hard-Rule-bearing text in the diff (FR-027 anchor 11, issue #144).
        # Grep only diff +lines to avoid false-positives from unchanged HR text.
        if ! echo "${p}" | grep -Eq "${protected_paths}" && \
           ! echo "${p}" | grep -Eq "${customer_truth}"; then
            added_lines=$(grep -E '^\+[^+]' "${diff_file}" | sed 's/^+//')
            if echo "${added_lines}" | grep -Eq "${hard_rule_pattern}"; then
                if ! echo "${changed_paths}" | grep -Eq '^docs/proposals/.+\.md$'; then
                    violations="${violations} ${p}(hard-rule-content)"
                fi
            fi
        fi
    done
    if [ -n "${violations}" ]; then
        cd "${_orig_dir}"
        return 1
    fi
    cd "${_orig_dir}"
    return 0
}

# ----- numeric_validator_check ---------------------------------------------
# Mirrors workflow "Identify target issue" numeric validation (issue #149).
# Returns 0 = valid (positive integer or empty), 1 = invalid.
numeric_validator_check() {
    issue_number=$1
    if [ -n "${issue_number}" ]; then
        case "${issue_number}" in
            *[!0-9]*)
                return 1
                ;;
        esac
    fi
    return 0
}

# ----- run_numeric ---------------------------------------------------------
# Args: label input-string expected (PASS|FAIL)
run_numeric() {
    label=$1
    input=$2
    expected=$3
    if numeric_validator_check "${input}"; then
        actual="PASS"
    else
        actual="FAIL"
    fi
    if [ "${expected}" = "${actual}" ]; then
        verdict="OK"
        pass_count=$((pass_count + 1))
    else
        verdict="MISMATCH"
        fail_count=$((fail_count + 1))
    fi
    printf 'numeric[%s]: input="%s" expected=%s actual=%s | %s\n' \
        "${label}" "${input}" "${expected}" "${actual}" "${verdict}"
}

# ----- run_one -------------------------------------------------------------
# Args: fixture-name expected-size-cap expected-protected
#   expected values: PASS or FAIL
# Combined verdict: PASS iff BOTH checks match expectations.
run_one() {
    name=$1
    exp_size=$2
    exp_prot=$3
    fixture="${FIXTURE_DIR}/${name}.diff"

    if size_cap_check "${fixture}"; then
        act_size="PASS"
    else
        act_size="FAIL"
    fi
    if protected_check "${fixture}"; then
        act_prot="PASS"
    else
        act_prot="FAIL"
    fi

    if [ "${exp_size}" = "${act_size}" ] && [ "${exp_prot}" = "${act_prot}" ]; then
        verdict="OK"
        pass_count=$((pass_count + 1))
    else
        verdict="MISMATCH"
        fail_count=$((fail_count + 1))
    fi

    printf '%s: expected size=%s prot=%s | actual size=%s prot=%s | %s\n' \
        "${name}" "${exp_size}" "${exp_prot}" "${act_size}" "${act_prot}" "${verdict}"
}

pass_count=0
fail_count=0

# Fixture expectation table (matches T072 spec).
#   name                              size  protected
run_one "small-clean"                 PASS  PASS
run_one "oversize-lines"              FAIL  PASS
run_one "oversize-files"              FAIL  PASS
run_one "protected-no-proposal"       PASS  FAIL
run_one "protected-with-proposal"     PASS  PASS
run_one "customer-truth-no-proposal"  PASS  FAIL
run_one "customer-truth-with-proposal" PASS PASS
run_one "hard-rule-content-no-proposal"  PASS FAIL
run_one "hard-rule-content-with-proposal" PASS PASS
# W2 fix: file already has HR text in unchanged lines; diff adds non-HR content -> PASS
run_one "hard-rule-unchanged-no-proposal" PASS PASS

# Numeric validator tests (issue #149)
run_numeric "valid-integer"   "123"          PASS
run_numeric "zero"            "0"            PASS
run_numeric "empty"           ""             PASS
run_numeric "alpha"           "abc"          FAIL
run_numeric "inject-newline"  "12
extra"        FAIL
run_numeric "semicolon"       "12;rm -rf /" FAIL

printf 'test-improve-template-logic: %d pass, %d fail\n' "${pass_count}" "${fail_count}"

if [ "${fail_count}" -ne 0 ]; then
    exit 1
fi
exit 0
