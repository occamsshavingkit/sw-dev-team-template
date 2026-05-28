#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# tests/upgrade/test-branch-guard-fallback-issue-257.sh — regression for
# issue #257: when origin/HEAD is absent AND init.defaultBranch is unset,
# the branch-guard must NOT hard-code 'main' as the fallback.
#
# Background:
#   upgrade.sh resolves the "default branch" via a priority chain:
#     1. refs/remotes/origin/HEAD (symbolic-ref)
#     2. init.defaultBranch (git config)
#     3. fallback (was: "main", fixed to: current branch)
#
#   For history-stripped fixtures or any downstream whose actual default is
#   'master', the old hard-coded 'main' fallback caused a spurious refusal
#   when current_branch == 'master' (current != 'main' -> guard fires).
#
#   Fix (Path A, issue #257): use "$current_branch" as the fallback so
#   `current == current` always passes when no authoritative signal exists.
#
# Cases:
#   #257-A  -- history-stripped fixture, branch 'master', no origin/HEAD,
#              no init.defaultBranch -> upgrade proceeds past the guard
#              (must NOT exit 2 / print branch-guard ERROR).
#   #257-B  -- same fixture, but origin/HEAD points to 'main' while current
#              branch is 'master' -> guard DOES fire (exit 2), preserving
#              intended behavior when a real signal disagrees with current.
#
# Pattern: matches test-branch-guard.sh conventions (standalone harness,
# run from repo root or directly).

set -u

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
upgrade="$repo_root/scripts/upgrade.sh"

tmp="$(mktemp -d -t upgrade-issue-257-XXXXXX)"
keep=0
[[ "${1:-}" == "--keep" ]] && keep=1
trap 'if [[ $keep -eq 0 ]]; then rm -rf "$tmp"; else echo "(kept $tmp for inspection)" >&2; fi' EXIT

fail=0
pass=0

check() {
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "  PASS: $label"
    pass=$((pass + 1))
  else
    echo "  FAIL: $label" >&2
    fail=$((fail + 1))
  fi
}

run_upgrade() {
  local dir="$1"; shift
  local log="$1"; shift
  local rc=0
  ( cd "$dir" && bash "$upgrade" "$@" ) > "$log" 2>&1 || rc=$?
  echo "$rc"
}

# ---------------------------------------------------------------------------
# Fixture factory: history-stripped repo on 'master'
#
# Characteristics that reproduce the issue #257 scenario:
#   - Branch name: master (not main)
#   - No remote (no origin/HEAD)
#   - git config init.defaultBranch is explicitly unset for the fixture
#   - No TEMPLATE_VERSION (so post-guard path is the missing-stamp ERROR
#     at exit 1; we distinguish exit 1 vs exit 2)
# ---------------------------------------------------------------------------
make_master_fixture() {
  local dir="$1"
  rm -rf "$dir"
  mkdir -p "$dir"
  (
    cd "$dir"
    git init -b master -q
    git config user.email issue-257-test@example.invalid
    git config user.name "Issue 257 Test"
    # Explicitly clear init.defaultBranch so the fallback fires.
    git config --unset init.defaultBranch 2>/dev/null || true
    : > .gitkeep
    git add .gitkeep
    git commit -q -m "fixture init (master, no remote)"
  )
}

# ---------------------------------------------------------------------------
# Case A: no authoritative signal -> fallback to current branch -> no spurious
#         refusal. Upgrade reaches the missing-TEMPLATE_VERSION check (exit 1).
# ---------------------------------------------------------------------------
echo "-- #257-A: master branch, no origin/HEAD, no init.defaultBranch -> no spurious refusal --"

fix_a="$tmp/master-no-remote"
make_master_fixture "$fix_a"

rc_a=$(run_upgrade "$fix_a" "$tmp/case-a.log")

check "#257-A: guard does not refuse (exit must not be 2)" \
  bash -c "[ '$rc_a' != '2' ]"
check "#257-A: guard does not print branch-guard ERROR" \
  bash -c "! grep -q 'refuses to run on branch' '$tmp/case-a.log'"
check "#257-A: NOTE log line says 'falling back to current branch'" \
  bash -c "grep -q \"falling back to current branch 'master'\" '$tmp/case-a.log'"
# Post-guard: missing TEMPLATE_VERSION -> exit 1 (proves guard was passed).
check "#257-A: reaches TEMPLATE_VERSION check (exit 1)" \
  bash -c "[ '$rc_a' = '1' ]"

# ---------------------------------------------------------------------------
# Case B: origin/HEAD points to 'main', current branch is 'master' -> guard
#         DOES fire (exit 2). This confirms the guard still uses the
#         authoritative signal when one is present.
# ---------------------------------------------------------------------------
echo ""
echo "-- #257-B: master branch, origin/HEAD=main -> guard still fires (exit 2) --"

# Build a remote whose HEAD points to main.
remote_b="$tmp/remote-b"
rm -rf "$remote_b"
mkdir -p "$remote_b"
(
  cd "$remote_b"
  git init -b main -q
  git config user.email issue-257-remote@example.invalid
  git config user.name "Issue 257 Remote"
  : > .gitkeep
  git add .gitkeep
  git commit -q -m "remote init (main)"
)

fix_b="$tmp/master-with-remote"
rm -rf "$fix_b"
mkdir -p "$fix_b"
(
  cd "$fix_b"
  git init -b master -q
  git config user.email issue-257-test@example.invalid
  git config user.name "Issue 257 Test"
  git config --unset init.defaultBranch 2>/dev/null || true
  # Add remote and fetch so refs/remotes/origin/HEAD is set.
  git remote add origin "$remote_b"
  git fetch -q origin
  git remote set-head origin main
  : > .gitkeep
  git add .gitkeep
  git commit -q -m "fixture init (master, origin/HEAD=main)"
)

rc_b=$(run_upgrade "$fix_b" "$tmp/case-b.log")

check "#257-B: guard fires (exit 2) when origin/HEAD disagrees with current" \
  bash -c "[ '$rc_b' = '2' ]"
check "#257-B: guard prints branch-guard ERROR naming 'master'" \
  bash -c "grep -q \"refuses to run on branch 'master'\" '$tmp/case-b.log'"
check "#257-B: guard names 'main' as the default branch" \
  bash -c "grep -q \"branch is 'main'\" '$tmp/case-b.log'"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "PASS: $pass"
echo "FAIL: $fail"
if [[ $fail -gt 0 ]]; then
  exit 1
fi
exit 0
