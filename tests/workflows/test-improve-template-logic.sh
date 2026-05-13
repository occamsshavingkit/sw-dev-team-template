#!/bin/sh
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
    diff_file=$1
    protected_paths='^(CLAUDE\.md|AGENTS\.md|VERSION|TEMPLATE_MANIFEST\.lock|\.claude/agents/|docs/adr/|docs/framework-project-boundary\.md|docs/model-routing-guidelines\.md|\.github/workflows/|migrations/)'
    customer_truth='^(CUSTOMER_NOTES\.md|docs/OPEN_QUESTIONS\.md|docs/intake-log\.md)$'
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
    done
    if [ -n "${violations}" ]; then
        return 1
    fi
    return 0
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

printf 'test-improve-template-logic: %d pass, %d fail\n' "${pass_count}" "${fail_count}"

if [ "${fail_count}" -ne 0 ]; then
    exit 1
fi
exit 0
