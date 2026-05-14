#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# tests/release-gate/test-gate-fail-each.sh — one row per sub-gate, each
# row drops a deliberate break and asserts the orchestrator surfaces that
# sub-gate in the failing list.
#
# Each "fixture" is a small in-test perturbation of the live tree (creating
# a stray file, mutating one canonical agent, etc.), reverted on exit so
# the worktree returns to its pre-test state. This avoids the maintenance
# cost of static fixtures while still proving each sub-gate triggers
# correctly.

set -u

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
gate="$repo_root/scripts/pre-release-gate.sh"
pass=0
fail=0

# stash dirtying files so we can roll back atomically.
revert_actions=()
register_revert() { revert_actions+=("$1"); }
do_revert() {
    for action in "${revert_actions[@]}"; do
        eval "$action"
    done
    revert_actions=()
}
trap do_revert EXIT

# Helper: run gate and assert (a) non-zero exit AND (b) named sub-gate appears
# in the failing list.
assert_subgate_fails() {
    label="$1"
    target_subgate="$2"
    rc=0
    out=$("$gate" 2>&1) || rc=$?
    if [ "$rc" -eq 0 ]; then
        echo "  FAIL: [$label] gate exited 0 (expected non-zero)"
        fail=$((fail + 1))
        return
    fi
    if printf '%s' "$out" | grep -qE "failing sub-gates:.*${target_subgate}"; then
        echo "  PASS: [$label] sub-gate '$target_subgate' surfaces in failing list (rc=$rc)"
        pass=$((pass + 1))
    else
        echo "  FAIL: [$label] '$target_subgate' not in failing list"
        echo "       output: $(printf '%s' "$out" | grep 'failing sub-gates' || echo '<no failing line>')"
        fail=$((fail + 1))
    fi
}

# ----- Fixture 01: dirty worktree → worktree-clean -----------------------
sentinel="$repo_root/.claude/agents/.fixture-01-stray-$$"
: > "$sentinel"
register_revert "rm -f '$sentinel'"
assert_subgate_fails "01-dirty-worktree" "worktree-clean"
rm -f "$sentinel"
revert_actions=()

# ----- Fixture 04: missing SPDX header → check-spdx ---------------------
target_script="$repo_root/scripts/.fixture-04-no-spdx-$$.sh"
{
    echo "#!/bin/sh"
    echo "# (deliberately missing SPDX-License-Identifier; fixture 04)"
    echo ": # no-op"
} > "$target_script"
chmod +x "$target_script"
register_revert "rm -f '$target_script'"
assert_subgate_fails "04-spdx-missing" "check-spdx"
rm -f "$target_script"
revert_actions=()

# ----- Fixture 05: canonical agent missing Hard rules → lint-contracts --
# Pick a canonical agent that DOES have a ## Hard rules section; strip it;
# run gate; restore. sre.md is a stable canonical role with ## Hard rules
# present at rc10.
victim="$repo_root/.claude/agents/sre.md"
backup="$victim.bak-$$"
if [ -f "$victim" ] && grep -q '^## Hard rules' "$victim"; then
    cp "$victim" "$backup"
    register_revert "mv '$backup' '$victim'"
    # Delete every line from the "## Hard rules" heading through to (but not
    # including) the next "## " heading.
    awk '
        BEGIN { skip = 0 }
        /^## Hard rules/ { skip = 1; next }
        skip && /^## / { skip = 0 }
        !skip { print }
    ' "$backup" > "$victim"
    assert_subgate_fails "05-lint-fail" "lint-contracts"
    mv "$backup" "$victim"
    revert_actions=()
else
    echo "  SKIP: 05-lint-fail — $victim missing or lacks ## Hard rules"
fi

echo
echo "------------------------------------------------------------"
echo "test-gate-fail-each: $pass passed, $fail failed"
if [ "$fail" -gt 0 ]; then
    exit 1
fi
