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
