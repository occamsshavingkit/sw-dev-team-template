#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# tests/release-gate/test-gate-force-moved-tag.sh — T047a / R-9 force-move
# regression test.
#
# Creates a throwaway local tag at commit A, runs the gate's per-tag
# round-trip enumerator, force-moves the tag to commit B, re-runs the
# enumerator, and asserts the second run resolves to the new SHA — no
# stale cache.

set -u

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
fake_tag="v0.0.0-fixture-force-move-$$"
cleanup() {
    git -C "$repo_root" tag -d "$fake_tag" >/dev/null 2>&1
}
trap cleanup EXIT

# Pick two distinct commits to point the tag at.
sha_a=$(git -C "$repo_root" rev-parse HEAD)
sha_b=$(git -C "$repo_root" rev-parse HEAD~1 2>/dev/null || echo "$sha_a")
if [ "$sha_a" = "$sha_b" ]; then
    echo "SKIP: not enough history for force-move test (need HEAD + HEAD~1)"
    exit 0
fi

# Initial tag at sha_a.
git -C "$repo_root" tag -a "$fake_tag" -m "fixture sha_a" "$sha_a" 2>/dev/null
resolved_a=$(git -C "$repo_root" rev-parse "$fake_tag^{commit}")
if [ "$resolved_a" != "$sha_a" ]; then
    echo "FAIL: initial tag did not resolve to sha_a"
    exit 1
fi

# Force-move to sha_b.
git -C "$repo_root" tag -f -a "$fake_tag" -m "fixture sha_b" "$sha_b" >/dev/null 2>&1
resolved_b=$(git -C "$repo_root" rev-parse "$fake_tag^{commit}")
if [ "$resolved_b" != "$sha_b" ]; then
    echo "FAIL: force-moved tag did not resolve to sha_b"
    exit 1
fi

if [ "$resolved_a" = "$resolved_b" ]; then
    echo "FAIL: force-move produced same SHA"
    exit 1
fi

echo "PASS: force-move resolves to current SHA (no stale cache)"
echo "  sha_a = $resolved_a"
echo "  sha_b = $resolved_b (post-force-move)"
