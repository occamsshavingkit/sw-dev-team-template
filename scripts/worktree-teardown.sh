#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# scripts/worktree-teardown.sh — remove a reader worktree created by worktree-setup.sh
#   (fw-adr-0024 §3 / §6, item 9 of the contract changes list)
#
# Usage:
#   scripts/worktree-teardown.sh <worktree-path> <scaffold-path>
#
# Runs `git -C <scaffold-path> worktree remove <worktree-path> --force`
# then `rm -rf <worktree-path>`. Idempotent: exits 0 if the worktree is
# already gone.
#
# Safety: rejects any <worktree-path> that does not match /tmp/agent-*
# to prevent accidental `rm -rf` of an arbitrary path. This mirrors the
# /tmp/agent-XXXXXX pattern enforced by worktree-setup.sh.

set -euo pipefail

if [[ $# -ne 2 ]]; then
  printf 'Usage: %s <worktree-path> <scaffold-path>\n' "$0" >&2
  exit 2
fi

WORKTREE_PATH="$1"
SCAFFOLD_PATH="$2"

# Safety guard: only operate on paths that look like /tmp/agent-*.
# This prevents `rm -rf` from being misdirected at arbitrary paths.
if [[ ! "$WORKTREE_PATH" =~ ^/tmp/agent-[^/]+$ ]]; then
  printf 'worktree-teardown: refusing to remove path that does not match /tmp/agent-*: %s\n' \
    "$WORKTREE_PATH" >&2
  printf '  Only worktrees created by worktree-setup.sh (in /tmp/agent-XXXXXX) may be removed.\n' >&2
  exit 1
fi

# Verify scaffold is a git repo.
if [[ ! -d "$SCAFFOLD_PATH" ]]; then
  printf 'worktree-teardown: scaffold path not a directory: %s\n' "$SCAFFOLD_PATH" >&2
  exit 1
fi

SCAFFOLD_PATH="$(cd "$SCAFFOLD_PATH" && pwd)"

if ! git -C "$SCAFFOLD_PATH" rev-parse --git-dir >/dev/null 2>&1; then
  printf 'worktree-teardown: not a git repository: %s\n' "$SCAFFOLD_PATH" >&2
  exit 1
fi

# Idempotent: if the worktree directory is already gone, skip git removal.
if [[ ! -d "$WORKTREE_PATH" ]]; then
  printf 'worktree-teardown: worktree already absent, running git worktree prune\n' >&2
  git -C "$SCAFFOLD_PATH" worktree prune 2>/dev/null || true
  exit 0
fi

# Remove from git's worktree list. --force handles the case where the
# worktree has uncommitted changes (readers should not, but --force is safe
# here because the worktree is throwaway by design).
git -C "$SCAFFOLD_PATH" worktree remove "$WORKTREE_PATH" --force 2>/dev/null || true

# Physical removal. The guard above ensures this path matches /tmp/agent-*.
rm -rf "$WORKTREE_PATH"
