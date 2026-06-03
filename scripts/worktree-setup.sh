#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# scripts/worktree-setup.sh — create a throwaway reader worktree in /tmp
#   (fw-adr-0024 §3 / §6, item 8 of the contract changes list)
#
# Usage:
#   scripts/worktree-setup.sh <scaffold-path>
#
# Creates a git worktree at /tmp/agent-XXXXXX checked out at the current
# canonical HEAD (detached). Prints the absolute worktree path to stdout
# and exits 0. Exits nonzero on bad args, non-git-repo, or worktree-add
# failure.
#
# Reader worktrees live in /tmp (outside the scaffold) per §6: "Reader
# worktrees are always created in /tmp/ (outside the repo), not under
# .worktrees/ inside the scaffold. This prevents accidental git add of
# worktree state by a writer operating on the canonical checkout."

set -euo pipefail

if [[ $# -ne 1 ]]; then
  printf 'Usage: %s <scaffold-path>\n' "$0" >&2
  exit 2
fi

SCAFFOLD_PATH="$1"

# Resolve to absolute path and verify it's a git repo.
if [[ ! -d "$SCAFFOLD_PATH" ]]; then
  printf 'worktree-setup: not a directory: %s\n' "$SCAFFOLD_PATH" >&2
  exit 1
fi

SCAFFOLD_PATH="$(cd "$SCAFFOLD_PATH" && pwd)"

if ! git -C "$SCAFFOLD_PATH" rev-parse --git-dir >/dev/null 2>&1; then
  printf 'worktree-setup: not a git repository: %s\n' "$SCAFFOLD_PATH" >&2
  exit 1
fi

# Create the temporary worktree directory first so mktemp controls the name,
# then hand it to git worktree add. git requires the target to not exist or
# to be empty — mktemp -d creates it, so we pass it directly and git populates
# it (git worktree add accepts an existing empty dir).
WDIR="$(mktemp -d /tmp/agent-XXXXXX)"

# Route git's informational stdout to stderr so the only line on stdout
# is the worktree path (callers capture stdout to get the path cleanly).
if ! git -C "$SCAFFOLD_PATH" worktree add "$WDIR" HEAD 1>&2; then
  rm -rf "$WDIR"
  printf 'worktree-setup: git worktree add failed for scaffold: %s\n' "$SCAFFOLD_PATH" >&2
  exit 1
fi

printf '%s\n' "$WDIR"
