#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# tests/release-gate/test-hook-bypass.sh — T022. Strict mode + gate failing
# + SKIP_PRE_RELEASE_GATE=1 → hook exits 0 + audit row appended.

set -u

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
hook="$repo_root/.git-hooks/pre-push"
log="$repo_root/docs/pm/pre-release-gate-overrides.md"

sentinel="$repo_root/.claude/agents/.hook-bypass-sentinel-$$"
: > "$sentinel"

# Snapshot the log so we can detect a new row.
log_pre_lines=$(wc -l < "$log")

cleanup() {
    rm -f "$sentinel"
    # Restore log to pre-test state (drop any row we appended).
    log_now_lines=$(wc -l < "$log")
    if [ "$log_now_lines" -gt "$log_pre_lines" ]; then
        head -n "$log_pre_lines" "$log" > "$log.tmp.$$"
        mv "$log.tmp.$$" "$log"
    fi
}
trap cleanup EXIT

local_sha=$(git -C "$repo_root" rev-parse v1.0.0-rc10)
out=$(printf 'refs/tags/v1.0.0-rc99 %s refs/tags/v1.0.0-rc99 0000000000000000000000000000000000000000\n' "$local_sha" \
    | SKIP_PRE_RELEASE_GATE=1 PRE_RELEASE_GATE_REASON="test fixture bypass" \
      "$hook" origin "https://example.invalid/repo.git" 2>&1) || rc=$?
rc="${rc:-0}"

if [ "$rc" -ne 0 ]; then
    echo "FAIL: hook exited $rc; expected 0 in bypass mode"
    printf '%s\n' "$out"
    exit 1
fi

log_post_lines=$(wc -l < "$log")
if [ "$log_post_lines" -le "$log_pre_lines" ]; then
    echo "FAIL: no audit row appended (pre=$log_pre_lines post=$log_post_lines)"
    exit 1
fi

# Spot-check the new row contains the tag name and reason.
new_row=$(tail -n 1 "$log")
if ! printf '%s' "$new_row" | grep -q 'v1.0.0-rc99'; then
    echo "FAIL: new audit row missing tag name"
    printf '%s\n' "$new_row"
    exit 1
fi
if ! printf '%s' "$new_row" | grep -q 'test fixture bypass'; then
    echo "FAIL: new audit row missing PRE_RELEASE_GATE_REASON"
    printf '%s\n' "$new_row"
    exit 1
fi

echo "PASS: bypass exits 0 + audit row appended"
echo "  appended row: $new_row"
