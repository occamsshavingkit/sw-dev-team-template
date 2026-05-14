#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# tests/release-gate/test-hook-advisory.sh — T024. Advisory mode: pushing a
# branch (not an annotated v* tag) → hook emits WARN to stderr but exits 0
# regardless of gate state.

set -u

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
hook="$repo_root/.git-hooks/pre-push"

# Drop a sentinel so the gate WOULD fail if invoked; advisory mode should
# not even invoke it, but if it did the gate would fail.
sentinel="$repo_root/.claude/agents/.hook-advisory-sentinel-$$"
: > "$sentinel"
cleanup() { rm -f "$sentinel"; }
trap cleanup EXIT

local_sha=$(git -C "$repo_root" rev-parse HEAD)
out=$(printf 'refs/heads/main %s refs/heads/main 0000000000000000000000000000000000000000\n' "$local_sha" \
    | env -u SKIP_PRE_RELEASE_GATE "$hook" origin "https://example.invalid/repo.git" 2>&1) || rc=$?
rc="${rc:-0}"

if [ "$rc" -ne 0 ]; then
    echo "FAIL: hook exited $rc; expected 0 in advisory mode"
    printf '%s\n' "$out"
    exit 1
fi

if ! printf '%s' "$out" | grep -qi 'advisory mode'; then
    echo "FAIL: advisory WARN message missing"
    printf '%s\n' "$out"
    exit 1
fi

echo "PASS: branch push exits 0 + advisory WARN"
