#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# tests/upgrade/test-downgrade-from-untagged-to-tag.sh — regression case
# for the inverse of --target=<branch|SHA> introduced by issue #186.
#
# Scenario: a downstream project is currently pinned at an untagged state
# (TEMPLATE_VERSION first line starts with "untagged-"), meaning it was
# upgraded to a branch/SHA tip that is NEWER than the latest upstream tag.
# The operator then invokes upgrade.sh --target=<older-tag>.  This is a
# downgrade: the requested target is semantically earlier than the current
# state.
#
# Desired behavior (issue #191):
#   upgrade.sh MUST NOT silently apply the downgrade.  It must either:
#     (a) refuse outright (non-zero exit) with a diagnostic naming both
#         the current untagged state and the requested older tag, OR
#     (b) warn and require an explicit --allow-downgrade flag.
#   Silent proceed (exit 0 without any downgrade diagnostic) is the
#   regression this test is designed to catch.
#
# Current upgrade.sh behavior (no guard — issue #191 unresolved):
#   upgrade.sh exits 0 and silently applies the downgrade.  Cases A and B
#   below therefore FAIL against the unguarded code.  That is intentional:
#   this test is written test-first to document required behavior; it will
#   turn green once software-engineer implements the guard.
#
# Test cases:
#   #191-static  — upgrade.sh contains a downgrade-guard code path that
#                  names the untagged-to-tag downgrade condition and Issue
#                  #191.  (static code check; fails until guard is
#                  implemented; does not require network.)
#   #191-A       — fixture project at untagged-<sha>, --target=<older-tag>:
#                  upgrade.sh exits non-zero.
#   #191-B       — same fixture, same --target: upgrade.sh output contains
#                  a diagnostic that names both the untagged state and the
#                  requested tag.
#   #191-C       — same fixture, --target=<same untagged tip sha>:
#                  upgrade.sh does NOT fire the downgrade guard (not a
#                  downgrade — same tip re-targeted as commit SHA).
#   #191-D       — fixture project at a KNOWN TAG, --target=<older-tag>:
#                  boundary case; confirms the #191-specific "untagged
#                  state" diagnostic is NOT emitted for a tagged-source
#                  downgrade (guard scoped to untagged-source state).
#
# Regression-injection probe (step 6 from issue brief):
#   Verified by replacing upgrade.sh with a no-guard stub that exits 0
#   for all --target inputs; cases A and B then fail.  Revert restores
#   green.  Documented in commit message.
#
# Pattern: matches test-rerun-safety.sh / test-branch-guard.sh conventions
# (standalone harness, run from repo root or directly).

set -u

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
upgrade="$repo_root/scripts/upgrade.sh"

tmp="$(mktemp -d -t upgrade-downgrade-XXXXXX)"
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

run_capture() {
  local log="$1"; shift
  local rc=0
  "$@" > "$log" 2>&1 || rc=$?
  echo "$rc"
}

# ---------------------------------------------------------------------------
# #191 static checks — guard code presence
# ---------------------------------------------------------------------------
echo "-- #191: static checks (downgrade-guard code presence) --"
check "#191-static-1: upgrade.sh references Issue #191 (guard marker)" \
  grep -q "Issue #191" "$upgrade"
check "#191-static-2: upgrade.sh contains untagged-to-tag downgrade detection" \
  grep -qE "untagged.*downgrade|downgrade.*untagged|downgrade.*tag|cannot downgrade|refuse.*downgrade|downgrade.*refuse" "$upgrade"

# ---------------------------------------------------------------------------
# Fixture factory
# ---------------------------------------------------------------------------
# Build a self-contained local upstream with:
#   old_tag  — an older release (the downgrade target)
#   new_tag  — a newer release (past the project's current state)
#   tip      — an untagged commit past new_tag (the project is pinned here)
#
# upgrade.sh clones SWDT_UPSTREAM_URL; we point it at this local repo so
# no network is required.

old_tag="v0.14.0"
new_tag="v1.0.0-rc14"

make_upstream() {
  local dir="$1"
  rm -rf "$dir"
  mkdir -p "$dir"
  (
    cd "$dir"
    git init -b main -q
    git config user.email downgrade-test-upstream@example.invalid
    git config user.name "Downgrade Test Upstream"

    # Commit 1: old_tag content
    printf '%s\n' "$old_tag" > VERSION
    : > .gitkeep
    git add VERSION .gitkeep
    git commit -q -m "release $old_tag"
    git tag "$old_tag"

    # Commit 2: new_tag content
    printf '%s\n' "$new_tag" > VERSION
    git add VERSION
    git commit -q -m "release $new_tag"
    git tag "$new_tag"

    # Commit 3: untagged tip past new_tag (simulates branch HEAD)
    printf 'untagged-dev-marker\n' > VERSION
    git add VERSION
    git commit -q -m "untagged tip past $new_tag"
  )
}

# Build a downstream project fixture pinned at the untagged upstream tip.
# TEMPLATE_VERSION line 1 must start with "untagged-" per the upgrade.sh
# synthetic-label convention (scripts/upgrade.sh line ~878).
make_downstream_untagged() {
  local dir="$1" upstream_dir="$2"
  rm -rf "$dir"
  mkdir -p "$dir"
  (
    cd "$dir"
    git init -b main -q
    git config user.email downgrade-test-project@example.invalid
    git config user.name "Downgrade Test Project"
    untagged_sha="$(git -C "$upstream_dir" rev-parse --short HEAD)"
    printf 'untagged-%s\n%s\n2026-05-16\n' \
      "$untagged_sha" \
      "$(git -C "$upstream_dir" rev-parse HEAD)" > TEMPLATE_VERSION
    git add TEMPLATE_VERSION
    git commit -q -m "fixture init (untagged tip)"
  )
}

# Build a downstream project fixture pinned at a known tag.
make_downstream_tagged() {
  local dir="$1" tag="$2" upstream_dir="$3"
  rm -rf "$dir"
  mkdir -p "$dir"
  (
    cd "$dir"
    git init -b main -q
    git config user.email downgrade-test-project@example.invalid
    git config user.name "Downgrade Test Project"
    tag_sha="$(git -C "$upstream_dir" rev-parse --verify "refs/tags/$tag^{commit}")"
    printf '%s\n%s\n2026-05-16\n' "$tag" "$tag_sha" > TEMPLATE_VERSION
    git add TEMPLATE_VERSION
    git commit -q -m "fixture init ($tag)"
  )
}

upstream="$tmp/upstream"
make_upstream "$upstream"
upstream_tip_sha="$(git -C "$upstream" rev-parse HEAD)"

# ---------------------------------------------------------------------------
# Case A: untagged project, --target=<older-tag> → must exit non-zero
# ---------------------------------------------------------------------------
echo ""
echo "-- #191-A: untagged project + --target=$old_tag (downgrade) → non-zero exit --"

fix_a="$tmp/proj-untagged-to-old-tag"
make_downstream_untagged "$fix_a" "$upstream"

rc_a=$(run_capture "$tmp/case-a.log" \
       bash -c "cd '$fix_a' && SWDT_UPSTREAM_URL='$upstream' bash '$upgrade' --target '$old_tag'")

check "#191-A: untagged→older-tag exits non-zero (downgrade refused)" \
  bash -c "[ '$rc_a' != '0' ]"

# ---------------------------------------------------------------------------
# Case B: same invocation — output contains a downgrade diagnostic
# ---------------------------------------------------------------------------
echo ""
echo "-- #191-B: untagged project + --target=$old_tag → diagnostic names both states --"

check "#191-B: output mentions 'untagged' state or 'downgrade'" \
  bash -c "grep -qiE 'untagged|downgrade' '$tmp/case-a.log'"
check "#191-B: output references the requested older tag $old_tag" \
  bash -c "grep -q '$old_tag' '$tmp/case-a.log'"

# ---------------------------------------------------------------------------
# Case C: same untagged project, --target=<same tip SHA>
#         Re-targeting the same commit is not a downgrade; guard must not fire.
#         (The upgrade may still fail for unrelated reasons — no manifest,
#         no bootstrap — but the downgrade-refusal diagnostic must be absent.)
# ---------------------------------------------------------------------------
echo ""
echo "-- #191-C: untagged project + --target=<same tip sha> → no downgrade refusal --"

fix_c="$tmp/proj-untagged-same"
make_downstream_untagged "$fix_c" "$upstream"

rc_c=$(run_capture "$tmp/case-c.log" \
       bash -c "cd '$fix_c' && SWDT_UPSTREAM_URL='$upstream' bash '$upgrade' --target '$upstream_tip_sha'")

check "#191-C: same-tip re-target does NOT emit downgrade-refusal diagnostic" \
  bash -c "! grep -qiE 'refuse.*downgrade|downgrade.*refuse|cannot downgrade' '$tmp/case-c.log'"

# ---------------------------------------------------------------------------
# Case D: tagged project + --target=<older-tag> (boundary case)
#         Confirms the #191 untagged-source diagnostic is NOT emitted for a
#         tagged-source downgrade (guard scoped to untagged-source state only).
# ---------------------------------------------------------------------------
echo ""
echo "-- #191-D: tagged project + --target=$old_tag (boundary — not the primary scenario) --"

fix_d="$tmp/proj-tagged-to-old-tag"
make_downstream_tagged "$fix_d" "$new_tag" "$upstream"

rc_d=$(run_capture "$tmp/case-d.log" \
       bash -c "cd '$fix_d' && SWDT_UPSTREAM_URL='$upstream' bash '$upgrade' --target '$old_tag'")

# #191 guard is scoped to untagged-source state. A tagged-source project
# downgrading must NOT trigger the untagged-specific wording.
check "#191-D: tagged-source downgrade does NOT trigger untagged-state diagnostic" \
  bash -c "! grep -qiE 'untagged.*downgrade|downgrade.*untagged' '$tmp/case-d.log'"

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
