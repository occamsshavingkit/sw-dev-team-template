#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# tests/lint/test-lint-questions.sh — regression tests for
# scripts/lint-questions.sh.
#
# Cases:
#   Pattern-2 (multi-numbered customer question):
#     1. bad.md corpus fixture fires -> 1 warning
#     2. good.md corpus fixture clean -> 0 warnings
#     3. CQG procedural enumeration does NOT fire (issue #148 regression)
#     4. Compound ask ending with ? still fires (true-positive guard)
#   Pattern-1 / strip_template_prose:
#     5. Nested sub-bullets under checkbox are suppressed (issue #185 regression)
#     6. Plain bullet at same indent resets checkbox state (true-positive guard)
#   Smoke: default file set stays clean
#     7. Default in-repo file set -> 0 warnings
#
# Exit 0 on all pass, 1 on any failure.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LINT="$REPO_ROOT/scripts/lint-questions.sh"

pass=0
fail=0
failures=""

# ---------------------------------------------------------------------------
# run_case <name> <expected-warning-count> <file-path>
# Runs the linter in --files mode and checks the warning count.
# ---------------------------------------------------------------------------
run_case() {
    local name="$1" expected_count="$2" filepath="$3"
    local out actual_count=0 actual_exit=0

    out=$("$LINT" --files "$filepath" --summary 2>&1) || actual_exit=$?
    # The summary line is: "lint-questions: N warnings, M errors"
    actual_count=$(printf '%s\n' "$out" | grep -o '^lint-questions: [0-9]* warnings' | grep -o '[0-9]*' || echo 0)

    if [ "$actual_count" = "$expected_count" ]; then
        pass=$((pass + 1))
        printf 'PASS  %s\n' "$name"
    else
        fail=$((fail + 1))
        failures=$(printf '%s\n  - %s (expected %s warnings, got %s)' \
            "$failures" "$name" "$expected_count" "$actual_count")
        printf 'FAIL  %s (expected %s warnings, got %s)\n' \
            "$name" "$expected_count" "$actual_count"
    fi
}

# ---------------------------------------------------------------------------
# run_case_exit <name> <expected-exit-code> [lint-args...]
# Runs the linter with arbitrary args and checks exit code.
# ---------------------------------------------------------------------------
run_case_exit() {
    local name="$1" expected_exit="$2"
    shift 2
    local actual_exit=0
    "$LINT" "$@" >/dev/null 2>&1 || actual_exit=$?
    if [ "$actual_exit" = "$expected_exit" ]; then
        pass=$((pass + 1))
        printf 'PASS  %s\n' "$name"
    else
        fail=$((fail + 1))
        failures=$(printf '%s\n  - %s (expected exit=%s, got exit=%s)' \
            "$failures" "$name" "$expected_exit" "$actual_exit")
        printf 'FAIL  %s (expected exit=%s, got exit=%s)\n' \
            "$name" "$expected_exit" "$actual_exit"
    fi
}

FIXTURES="$REPO_ROOT/tests/lint-questions"
TMPDIR_BASE="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_BASE"' EXIT INT TERM HUP

# ===========================================================================
# Case 1: pattern-2 bad.md corpus -> 1 warning
# ===========================================================================
run_case "p2-bad-fixture: compound multi-numbered ask fires" \
    1 "$FIXTURES/pattern-2-multi-numbered/bad.md"

# ===========================================================================
# Case 2: pattern-2 good.md corpus (includes CQG fixture added for #148) -> 0
# ===========================================================================
run_case "p2-good-fixture: single-numbered + CQG enumeration -> clean" \
    0 "$FIXTURES/pattern-2-multi-numbered/good.md"

# ===========================================================================
# Case 3: CQG-style procedural enumeration must NOT fire (issue #148 regression)
# A numbered checklist where each item is a procedural check (may contain
# rhetorical `?` labels) and the paragraph ends with plain prose (no `?`).
# ===========================================================================
CQG_FIXTURE="$TMPDIR_BASE/cqg_checklist.md"
cat > "$CQG_FIXTURE" << 'EOF'
# Agent contract — Customer Question Gate

Before sending any message with a question to the customer:

1. **Customer-owned.** No agent on the roster can answer it.
2. **Is it atomic?** One decision axis only. Compound asks queue internally in `docs/OPEN_QUESTIONS.md`.
3. **Idle.** No specialist dispatches in flight, no Bash/file-reads pending.
4. **Final-line.** Customer-facing turn ends with the question itself.

If any check fails, queue the question in `docs/OPEN_QUESTIONS.md`.
EOF
run_case "p2-cqg-enum-no-fire: CQG procedural checklist suppressed (#148)" \
    0 "$CQG_FIXTURE"

# ===========================================================================
# Case 4: True-positive — compound ask ending with `?` still fires
# A multi-numbered paragraph whose terminal line ends with `?`.
# ===========================================================================
COMPOUND_FIXTURE="$TMPDIR_BASE/compound_ask.md"
cat > "$COMPOUND_FIXTURE" << 'EOF'
# Compound customer ask — must fire

We need to decide three things before milestone:

1. Choose an OAuth provider.
2. Decide on session-storage mechanism.
3. Pick a token-expiry policy. Should we ship all three together?
EOF
run_case "p2-compound-ask-fires: terminal-? paragraph fires (#148 true-positive)" \
    1 "$COMPOUND_FIXTURE"

# ===========================================================================
# Case 5: Nested sub-bullets under checkbox are suppressed (issue #185 regression)
# The outer `- [ ]` starts the checkbox; indented `- ` sub-bullets carry `?`s
# that are UI prompts, not customer-facing questions.
# ===========================================================================
NESTED_CB_FIXTURE="$TMPDIR_BASE/nested_checkbox.md"
cat > "$NESTED_CB_FIXTURE" << 'EOF'
# Retrofit checklist with nested sub-bullets

- [ ] Confirm your deployment target:
  - Is it cloud-hosted?
  - Is it on-prem?
  - Are there air-gap requirements?

- [ ] Review access controls:
  - Is authentication required?
  - Are role mappings defined?
EOF
run_case "p185-nested-subbullets-suppressed: sub-bullets under checkbox clean (#185)" \
    0 "$NESTED_CB_FIXTURE"

# ===========================================================================
# Case 6: Plain bullet at checkbox indent resets state (true-positive guard)
# After a checkbox block, a non-indented `- ` bullet exits the checkbox
# context; a `?` on that plain bullet is no longer suppressed.
# The fixture has a single plain-bullet `?`, which is a simple question —
# pattern-1 only fires on compound (multi-?) or `, and`/`;` forms, so the
# linter stays clean. But we DO verify the checkbox resets by checking that
# a compound-seeded plain bullet WOULD fire.
# ===========================================================================
RESET_CB_FIXTURE="$TMPDIR_BASE/reset_checkbox.md"
cat > "$RESET_CB_FIXTURE" << 'EOF'
# Checkbox resets on same-indent bullet

- [ ] Outer prompt — do you want to proceed?
  - Nested sub-bullet: is this ok?

- Follow-up plain bullet: which option, and what timeline?
EOF
run_case "p185-plain-bullet-resets-checkbox: compound plain bullet fires (#185 guard)" \
    1 "$RESET_CB_FIXTURE"

# ===========================================================================
# Case 7: Default in-repo file set stays clean (smoke)
# ===========================================================================
run_case_exit "default-file-set-clean: smoke 0 warnings" 0 --summary

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
printf '\nResults: %s passed, %s failed\n' "$pass" "$fail"

if [ "$fail" -gt 0 ]; then
    printf 'Failures:%s\n' "$failures"
    exit 1
fi

exit 0
