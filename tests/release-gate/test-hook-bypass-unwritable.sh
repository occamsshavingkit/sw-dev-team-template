#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# tests/release-gate/test-hook-bypass-unwritable.sh — T023. Strict mode +
# gate failing + SKIP_PRE_RELEASE_GATE=1 + audit log unwritable → hook
# refuses the bypass and exits non-zero.

set -u

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
hook="$repo_root/.git-hooks/pre-push"
log="$repo_root/docs/pm/pre-release-gate-overrides.md"

sentinel="$repo_root/.claude/agents/.hook-unwritable-sentinel-$$"
: > "$sentinel"

# Make the log read-only.
orig_mode=$(stat -c '%a' "$log" 2>/dev/null || stat -f '%Lp' "$log" 2>/dev/null)
chmod 0444 "$log"

cleanup() {
    rm -f "$sentinel"
    [ -n "$orig_mode" ] && chmod "$orig_mode" "$log"
}
trap cleanup EXIT

local_sha=$(git -C "$repo_root" rev-parse v1.0.0-rc10)
out=$(printf 'refs/tags/v1.0.0-rc99 %s refs/tags/v1.0.0-rc99 0000000000000000000000000000000000000000\n' "$local_sha" \
    | SKIP_PRE_RELEASE_GATE=1 \
      "$hook" origin "https://example.invalid/repo.git" 2>&1) || rc=$?
rc="${rc:-0}"

if [ "$rc" -eq 0 ]; then
    echo "FAIL: hook exited 0; expected non-zero (audit log unwritable, bypass refused)"
    printf '%s\n' "$out"
    exit 1
fi

if ! printf '%s' "$out" | grep -q 'is unwritable'; then
    echo "FAIL: stderr missing 'is unwritable' message"
    printf '%s\n' "$out"
    exit 1
fi

echo "PASS: unwritable log refuses bypass + documented stderr"
