#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# tests/release-gate/test-hook-strict-fail.sh — T021. Strict mode + gate
# failing + no bypass → hook exits non-zero with documented stderr.

set -u

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
hook="$repo_root/.git-hooks/pre-push"

# Simulate: an annotated v* tag push with the gate currently failing
# (drop a sentinel untracked file to make worktree-clean fail).
sentinel="$repo_root/.claude/agents/.hook-strict-fail-sentinel-$$"
: > "$sentinel"
cleanup() { rm -f "$sentinel"; }
trap cleanup EXIT

# Use the rc10 tag as a representative annotated v* tag (annotated per repo policy).
local_sha=$(git -C "$repo_root" rev-parse v1.0.0-rc10)

# Feed pre-push refspec on stdin.
out=$(printf 'refs/tags/v1.0.0-rc99 %s refs/tags/v1.0.0-rc99 0000000000000000000000000000000000000000\n' "$local_sha" \
    | env -u SKIP_PRE_RELEASE_GATE "$hook" origin "https://example.invalid/repo.git" 2>&1) || rc=$?
rc="${rc:-0}"

if [ "$rc" -eq 0 ]; then
    echo "FAIL: hook exited 0 in strict mode with failing gate"
    printf '%s\n' "$out"
    exit 1
fi

if ! printf '%s' "$out" | grep -q 'pre-release-gate failed; push blocked'; then
    echo "FAIL: stderr missing documented block message"
    printf '%s\n' "$out"
    exit 1
fi

echo "PASS: strict+failing+no-bypass → exit $rc + documented stderr"
