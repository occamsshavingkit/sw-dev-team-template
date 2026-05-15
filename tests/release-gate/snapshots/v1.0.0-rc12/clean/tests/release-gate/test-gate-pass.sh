#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# tests/release-gate/test-gate-pass.sh — positive end-to-end. Run the
# pre-release gate against the live candidate (clean worktree expected)
# and assert PASS + exit 0.
#
# Also captures wall-clock duration for SC-002 audit. Soft-warn if > 5 min;
# hard-fail at > 10 min.

set -u

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
gate="$repo_root/scripts/pre-release-gate.sh"

# Verify worktree is clean (otherwise this test isn't meaningful).
dirty=$(git -C "$repo_root" status --porcelain \
    | grep -vE '^\?\? docs/pm/token-ledger\.md$' \
    | grep -vE '^\?\? tests/prompt-regression/results-' \
    || true)
if [ -n "$dirty" ]; then
    echo "  SKIP: test-gate-pass requires a clean worktree (excluding known untracked clutter)"
    printf '%s\n' "$dirty"
    exit 0
fi

start_s=$(date +%s)
rc=0
out=$("$gate" 2>&1) || rc=$?
end_s=$(date +%s)
dur_s=$((end_s - start_s))

if [ "$rc" -ne 0 ]; then
    echo "  FAIL: gate exited $rc on clean candidate; expected 0"
    printf '%s\n' "$out"
    exit 1
fi

if ! printf '%s' "$out" | grep -qE '^PASS  —'; then
    echo "  FAIL: gate output missing PASS summary line"
    printf '%s\n' "$out"
    exit 1
fi

echo "  PASS: gate exits 0 on clean candidate"

# T013 / T027 lightweight positive-coverage assertions (Style A; no
# static fixture dir per architect's amended sub-gate contract
# 2026-05-14). T013's original intent was a positive "clean-tree
# baseline" fixture for the worktree-clean sub-gate; T027's was a
# positive round-trips fixture for upgrade-paths. Both reduce to
# "this sub-gate reports PASS in the orchestrator's per-sub-gate
# detail blocks when run against the live clean candidate." Asserting
# the line shape `[<name>] PASS (<Ns>)` exists is sufficient — it
# catches the failure mode where the orchestrator's overall PASS
# summary fires but a specific sub-gate quietly disappeared from the
# registry (e.g., gate_register call deleted in a refactor).
#
# No static fixture directory needed: the live clean candidate IS the
# positive fixture, by the same Style-A logic the negative-fixture
# contract uses. Style B (static fixture dir) is reserved for future
# sub-gates whose positive-coverage demands a multi-file structural
# tree that the live candidate cannot represent.
for subgate in worktree-clean upgrade-paths; do
    if ! printf '%s' "$out" | grep -qE "^\[${subgate}\] PASS \([0-9.]+s\)$"; then
        echo "  FAIL: expected '[$subgate] PASS (<Ns>)' line missing from gate output"
        echo "       (T013/T027 positive-coverage assertion)"
        printf '%s\n' "$out"
        exit 1
    fi
done
echo "  PASS: worktree-clean + upgrade-paths sub-gates surface as PASS (T013/T027 coverage)"

echo "  duration: ${dur_s}s"

if [ "$dur_s" -gt 600 ]; then
    echo "  FAIL: SC-002 wall-clock budget hard-fail (>600s); investigate before tag"
    exit 1
fi
if [ "$dur_s" -gt 300 ]; then
    echo "  WARN: SC-002 wall-clock budget exceeded (5 min target); soft-warn"
fi

echo
echo "------------------------------------------------------------"
echo "test-gate-pass: 1 passed, 0 failed"
