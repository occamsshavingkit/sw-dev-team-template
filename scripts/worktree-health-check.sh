#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# scripts/worktree-health-check.sh — warn about stale reader worktrees
#   (fw-adr-0024 §6, item 10 of the contract changes list)
#
# Usage:
#   scripts/worktree-health-check.sh <scaffold-path>
#
# Runs `git worktree list --porcelain` on the scaffold and warns (stderr)
# for any /tmp/agent-* worktree paths found. These indicate potential
# stale reader worktrees from a previous session that was not cleanly torn
# down. Suggests `git worktree prune` for cleanup.
#
# Always exits 0 — this is an advisory check, not a gate.

set -euo pipefail

if [[ $# -ne 1 ]]; then
  printf 'Usage: %s <scaffold-path>\n' "$0" >&2
  exit 2
fi

SCAFFOLD_PATH="$1"

if [[ ! -d "$SCAFFOLD_PATH" ]]; then
  printf 'worktree-health-check: not a directory: %s\n' "$SCAFFOLD_PATH" >&2
  exit 0
fi

SCAFFOLD_PATH="$(cd "$SCAFFOLD_PATH" && pwd)"

if ! git -C "$SCAFFOLD_PATH" rev-parse --git-dir >/dev/null 2>&1; then
  printf 'worktree-health-check: not a git repository: %s -- skipping worktree check\n' \
    "$SCAFFOLD_PATH" >&2
  exit 0
fi

# Parse `git worktree list --porcelain` output. Each worktree block starts
# with a `worktree <path>` line. Collect any paths matching /tmp/agent-*.
stale_count=0
while IFS= read -r line; do
  if [[ "$line" =~ ^worktree[[:space:]]+(.*) ]]; then
    wt_path="${BASH_REMATCH[1]}"
    if [[ "$wt_path" =~ ^/tmp/agent- ]]; then
      printf 'worktree-health-check: WARN: stale reader worktree detected: %s\n' \
        "$wt_path" >&2
      stale_count=$((stale_count + 1))
    fi
  fi
done < <(git -C "$SCAFFOLD_PATH" worktree list --porcelain 2>/dev/null)

if [[ $stale_count -gt 0 ]]; then
  printf 'worktree-health-check: %d stale /tmp/agent-* worktree(s) found.\n' \
    "$stale_count" >&2
  printf '  Run: git -C %s worktree prune\n' "$SCAFFOLD_PATH" >&2
  printf '  Then manually remove any lingering /tmp/agent-* directories.\n' >&2
  printf '  See fw-adr-0024 §6 for the cleanup procedure.\n' >&2
else
  printf 'worktree-health-check: no stale reader worktrees detected.\n'
fi

exit 0
