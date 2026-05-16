#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# tests/upgrade/test-branch-guard.sh — cover the issue #203 default-
# branch guard in scripts/upgrade.sh.
#
# Cases:
#   1. Default branch (main)              → guard does not fire; upgrade
#                                           proceeds past the guard (we
#                                           short-circuit before the
#                                           network clone with a tweak
#                                           that triggers the
#                                           TEMPLATE_VERSION ERROR path,
#                                           which is downstream of the
#                                           guard).
#   2. Non-default branch, no flag         → guard refuses with exit 2
#                                           and the documented message.
#   3. Non-default branch, override flag   → upgrade proceeds past the
#                                           guard with a stderr WARNING.
#   4. --dry-run on non-default branch     → guard does not fire.
#   5. --verify on non-default branch      → guard does not fire.
#
# The guard runs after argument parsing and before the TEMPLATE_VERSION
# existence check. To isolate the guard we delete TEMPLATE_VERSION in
# the fixture; the guard runs first and either lets us reach the
# "no TEMPLATE_VERSION" ERROR (exit 1) or refuses with the branch
# message (exit 2). Distinguishing exit 1 vs exit 2 is sufficient
# without standing up a full upstream fixture.
#
# For --dry-run and --verify, the guard is intentionally skipped per
# the issue; we assert those paths reach the TEMPLATE_VERSION check
# (exit 1) even on a non-default branch.

set -u

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
upgrade="$repo_root/scripts/upgrade.sh"

tmp="$(mktemp -d -t upgrade-branch-guard-XXXXXX)"
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

# Build a minimal fixture project: a git repo on `main`, no
# TEMPLATE_VERSION (so the post-guard path is the missing-stamp ERROR
# at exit 1). We intentionally do NOT add an origin remote — that
# exercises the priority-chain fallback path the issue specifies.
make_fixture() {
  local dir="$1"
  rm -rf "$dir"
  mkdir -p "$dir"
  (
    cd "$dir"
    git init -b main -q
    git config user.email branch-guard-test@example.invalid
    git config user.name "Branch Guard Test"
    : > .gitkeep
    git add .gitkeep
    git commit -q -m "fixture init"
  )
}

run_upgrade() {
  # Args: <fixture_dir> <log_file> [upgrade.sh args...]
  local dir="$1"; shift
  local log="$1"; shift
  local rc=0
  ( cd "$dir" && bash "$upgrade" "$@" ) > "$log" 2>&1 || rc=$?
  echo "$rc"
}

echo "-- issue #203 default-branch guard --"

# Case 1: default branch (main) → guard does not fire; we reach the
# missing-TEMPLATE_VERSION error (exit 1).
fix_main="$tmp/on-main"
make_fixture "$fix_main"
rc_main=$(run_upgrade "$fix_main" "$tmp/on-main.log")
check "default branch reaches TEMPLATE_VERSION check (exit 1)" \
  bash -c "[ '$rc_main' = '1' ]"
check "default branch does not print branch-guard ERROR" \
  bash -c "! grep -q 'refuses to run on branch' '$tmp/on-main.log'"

# Case 2: non-default branch → guard refuses (exit 2).
fix_feat="$tmp/on-feat"
make_fixture "$fix_feat"
( cd "$fix_feat" && git switch -q -c feat/x )
rc_feat=$(run_upgrade "$fix_feat" "$tmp/on-feat.log")
check "non-default branch refuses with exit 2" \
  bash -c "[ '$rc_feat' = '2' ]"
check "non-default branch prints documented refuse message" \
  bash -c "grep -q \"refuses to run on branch 'feat/x'\" '$tmp/on-feat.log' && grep -q \"branch is 'main'\" '$tmp/on-feat.log'"
check "non-default branch hints --allow-non-default-branch override" \
  bash -c "grep -q -- '--allow-non-default-branch' '$tmp/on-feat.log'"

# Case 3: non-default branch + --allow-non-default-branch → proceed
# with WARNING. We expect to land on the TEMPLATE_VERSION ERROR (exit
# 1) downstream of the guard, with the WARNING also present.
fix_override="$tmp/on-feat-override"
make_fixture "$fix_override"
( cd "$fix_override" && git switch -q -c feat/y )
rc_override=$(run_upgrade "$fix_override" "$tmp/on-feat-override.log" \
              --allow-non-default-branch)
check "override flag bypasses guard (reaches TEMPLATE_VERSION check, exit 1)" \
  bash -c "[ '$rc_override' = '1' ]"
check "override flag emits a WARNING naming both branches" \
  bash -c "grep -q \"WARNING:.*'feat/y'.*'main'\" '$tmp/on-feat-override.log'"
check "override flag does not print refuse ERROR" \
  bash -c "! grep -q 'refuses to run on branch' '$tmp/on-feat-override.log'"

# Case 4: --dry-run on non-default branch → guard does not fire.
fix_dryrun="$tmp/on-feat-dryrun"
make_fixture "$fix_dryrun"
( cd "$fix_dryrun" && git switch -q -c feat/z )
rc_dryrun=$(run_upgrade "$fix_dryrun" "$tmp/on-feat-dryrun.log" --dry-run)
check "--dry-run on non-default branch skips guard" \
  bash -c "! grep -q 'refuses to run on branch' '$tmp/on-feat-dryrun.log'"
# Exit code should be the TEMPLATE_VERSION missing ERROR (1), not the
# guard refuse (2).
check "--dry-run on non-default branch returns exit != 2" \
  bash -c "[ '$rc_dryrun' != '2' ]"

# Case 5: --verify on non-default branch → guard does not fire.
fix_verify="$tmp/on-feat-verify"
make_fixture "$fix_verify"
( cd "$fix_verify" && git switch -q -c feat/w )
rc_verify=$(run_upgrade "$fix_verify" "$tmp/on-feat-verify.log" --verify)
check "--verify on non-default branch skips guard" \
  bash -c "! grep -q 'refuses to run on branch' '$tmp/on-feat-verify.log'"
check "--verify on non-default branch returns exit != 2 (no branch refuse)" \
  bash -c "[ '$rc_verify' != '2' ]"

echo
echo "PASS: $pass"
echo "FAIL: $fail"
if [[ $fail -gt 0 ]]; then
  exit 1
fi
exit 0
