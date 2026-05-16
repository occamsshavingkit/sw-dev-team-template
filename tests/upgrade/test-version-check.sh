#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# tests/upgrade/test-version-check.sh — cluster-B coverage for
# scripts/version-check.sh. Closes:
#
#   * #161 — rc9 < rc10 < rc11 ordering (numeric, not lexicographic).
#            Already fixed by commit 04be3a3 (canonical lib sourcing);
#            this file pins the behaviour with a dedicated end-to-end
#            fixture so any future regression in the URL/version path
#            of version-check.sh is caught by the upgrade test suite,
#            not only by the lib self-test.
#
#   * #199 — TEMPLATE_VERSION read from HEAD, not the working tree.
#            Half-applied upgrade (uncommitted edit) must surface a
#            WARN and the comparison must use HEAD.
#
#   * #154 — rc-target Release URL suppression. rc tags have no
#            GitHub Release object (Releases are cut at MINOR
#            boundaries only). For rc targets, output must NOT emit
#            .../releases/tag/<rc-tag>; an alternative link form
#            (here: .../commits/<rc-tag>) is acceptable.
#
# Fixture shape mirrors tests/upgrade/test-branch-guard.sh: each case
# stands up a throwaway downstream project and a throwaway upstream
# bare-ish repo, points SWDT_UPSTREAM_URL at the upstream, and
# inspects version-check.sh stdout / stderr.

set -u

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
vc="$repo_root/scripts/version-check.sh"

tmp="$(mktemp -d -t version-check-XXXXXX)"
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

# Build a downstream-project fixture: a git repo with TEMPLATE_VERSION
# stamped to <version> and committed. Argument 2 is the committed value.
# Optional argument 3, if non-empty, is the working-tree value that
# replaces TEMPLATE_VERSION AFTER the commit — used to simulate
# half-applied-upgrade drift for issue #199.
make_project() {
  local dir="$1" committed="$2" working="${3:-}"
  rm -rf "$dir"
  mkdir -p "$dir"
  (
    cd "$dir"
    git init -b main -q
    git config user.email version-check-test@example.invalid
    git config user.name "Version Check Test"
    printf '%s\nunknown\n2026-01-01\n' "$committed" > TEMPLATE_VERSION
    git add TEMPLATE_VERSION
    git commit -q -m "stamp $committed"
    if [[ -n "$working" ]]; then
      printf '%s\nunknown\n2026-01-01\n' "$working" > TEMPLATE_VERSION
    fi
  )
}

# Build an upstream fixture exposing the listed tags. Each tag points
# at a commit that bumps a synthetic VERSION marker so the tags are
# distinguishable in git; only the tag names matter for ls-remote.
make_upstream() {
  local dir="$1"; shift
  rm -rf "$dir"
  mkdir -p "$dir"
  (
    cd "$dir"
    git init -b main -q
    git config user.email version-check-upstream@example.invalid
    git config user.name "Version Check Upstream"
    : > .gitkeep
    git add .gitkeep
    git commit -q -m "init"
    for tag in "$@"; do
      printf '%s\n' "$tag" > VERSION
      git add VERSION
      git commit -q -m "$tag"
      git tag "$tag"
    done
  )
}

run_vc() {
  # Args: <project_dir> <upstream_dir> <out_log>
  local proj="$1" up="$2" log="$3" rc=0
  ( cd "$proj" && SWDT_UPSTREAM_URL="$up" GH_TOKEN="" bash "$vc" ) > "$log" 2>&1 || rc=$?
  echo "$rc"
}

echo "-- issue #161: rc9 < rc10 < rc11 (numeric ordering) --"

# Case A: project at rc10, upstream has rc8..rc11 → "up to date" is
# WRONG (rc11 is the latest); banner must point at rc11.
upstream_rc="$tmp/upstream-rc"
make_upstream "$upstream_rc" \
  v1.0.0-rc8 v1.0.0-rc9 v1.0.0-rc10 v1.0.0-rc11

proj_rc10="$tmp/proj-rc10"
make_project "$proj_rc10" "v1.0.0-rc10"
rc_a=$(run_vc "$proj_rc10" "$upstream_rc" "$tmp/rc10-out.log")
check "rc10 → run exits 0" \
  bash -c "[ '$rc_a' = '0' ]"
check "rc10 → banner names rc11 as target (NOT rc9)" \
  bash -c "grep -q 'Template upgrade available: v1.0.0-rc10 .* v1.0.0-rc11' '$tmp/rc10-out.log'"
check "rc10 → banner does not advertise rc9 as newer (issue #161)" \
  bash -c "! grep -q 'Template upgrade available: v1.0.0-rc10 .* v1.0.0-rc9' '$tmp/rc10-out.log'"

# Case B: project at rc11, upstream has rc8..rc11 → "up to date".
proj_rc11="$tmp/proj-rc11"
make_project "$proj_rc11" "v1.0.0-rc11"
rc_b=$(run_vc "$proj_rc11" "$upstream_rc" "$tmp/rc11-out.log")
check "rc11 (latest) → run exits 0" \
  bash -c "[ '$rc_b' = '0' ]"
check "rc11 (latest) → reports up to date" \
  bash -c "grep -q 'Template up to date: v1.0.0-rc11' '$tmp/rc11-out.log'"

# Case C: project at rc9, upstream has rc8..rc11 → upgrade to rc11.
proj_rc9="$tmp/proj-rc9"
make_project "$proj_rc9" "v1.0.0-rc9"
rc_c=$(run_vc "$proj_rc9" "$upstream_rc" "$tmp/rc9-out.log")
check "rc9 → run exits 0" \
  bash -c "[ '$rc_c' = '0' ]"
check "rc9 → banner names rc11 (not rc10 as latest text-sort glitch)" \
  bash -c "grep -q 'Template upgrade available: v1.0.0-rc9 .* v1.0.0-rc11' '$tmp/rc9-out.log'"

echo "-- issue #199: HEAD vs working-tree TEMPLATE_VERSION --"

# Case D: HEAD=rc8, working tree=rc9, upstream latest=rc11. Expect:
#   * version comparison uses HEAD (rc8), so banner is rc8 → rc11
#     (NOT "up to date" at rc9, NOT rc9 → rc11).
#   * WARN line on stderr names both HEAD=rc8 and working tree=rc9.
proj_drift="$tmp/proj-drift"
make_project "$proj_drift" "v1.0.0-rc8" "v1.0.0-rc9"
rc_d=$(run_vc "$proj_drift" "$upstream_rc" "$tmp/drift-out.log")
check "HEAD-vs-working drift → run exits 0" \
  bash -c "[ '$rc_d' = '0' ]"
check "HEAD-vs-working drift → WARN line names uncommitted TEMPLATE_VERSION" \
  bash -c "grep -q 'WARN: uncommitted change to TEMPLATE_VERSION' '$tmp/drift-out.log'"
check "HEAD-vs-working drift → WARN names HEAD=rc8 and working tree=rc9" \
  bash -c "grep -q 'HEAD=v1.0.0-rc8' '$tmp/drift-out.log' && grep -q 'working tree=v1.0.0-rc9' '$tmp/drift-out.log'"
check "HEAD-vs-working drift → banner uses HEAD value (rc8), not working tree (rc9)" \
  bash -c "grep -q 'Template upgrade available: v1.0.0-rc8 .* v1.0.0-rc11' '$tmp/drift-out.log'"
check "HEAD-vs-working drift → banner does NOT use working-tree value rc9" \
  bash -c "! grep -q 'Template upgrade available: v1.0.0-rc9' '$tmp/drift-out.log'"

# Case E: HEAD == working tree (the common case). No WARN.
proj_clean="$tmp/proj-clean"
make_project "$proj_clean" "v1.0.0-rc8"
rc_e=$(run_vc "$proj_clean" "$upstream_rc" "$tmp/clean-out.log")
check "no drift → run exits 0" \
  bash -c "[ '$rc_e' = '0' ]"
check "no drift → no WARN about uncommitted TEMPLATE_VERSION" \
  bash -c "! grep -q 'WARN: uncommitted change to TEMPLATE_VERSION' '$tmp/clean-out.log'"
check "no drift → banner uses the (matching) HEAD value" \
  bash -c "grep -q 'Template upgrade available: v1.0.0-rc8 .* v1.0.0-rc11' '$tmp/clean-out.log'"

# Case F: not a git repo at all → silently fall back to working tree
# value (no WARN, no crash).
proj_nongit="$tmp/proj-nongit"
rm -rf "$proj_nongit"
mkdir -p "$proj_nongit"
printf '%s\nunknown\n2026-01-01\n' "v1.0.0-rc8" > "$proj_nongit/TEMPLATE_VERSION"
rc_f=$(run_vc "$proj_nongit" "$upstream_rc" "$tmp/nongit-out.log")
check "non-git project → run exits 0" \
  bash -c "[ '$rc_f' = '0' ]"
check "non-git project → no WARN about uncommitted TEMPLATE_VERSION" \
  bash -c "! grep -q 'WARN: uncommitted change to TEMPLATE_VERSION' '$tmp/nongit-out.log'"
check "non-git project → banner uses working-tree value" \
  bash -c "grep -q 'Template upgrade available: v1.0.0-rc8 .* v1.0.0-rc11' '$tmp/nongit-out.log'"

echo "-- issue #154: rc target → no Release-page URL --"

# Case G: rc target → banner must NOT link releases/tag/<rc-tag>.
# Project at rc8, upstream latest rc11.
check "rc target → banner does NOT emit /releases/tag/v1.0.0-rc11" \
  bash -c "! grep -q '/releases/tag/v1.0.0-rc11' '$tmp/clean-out.log'"
check "rc target → banner emits alternative link (commits/<tag>)" \
  bash -c "grep -q '/commits/v1.0.0-rc11' '$tmp/clean-out.log'"
check "rc target → banner still emits CHANGELOG link" \
  bash -c "grep -q '/blob/main/CHANGELOG.md' '$tmp/clean-out.log'"

# Case H: stable target → banner KEEPS releases/tag link (regression
# guard against over-broad suppression).
upstream_stable="$tmp/upstream-stable"
make_upstream "$upstream_stable" v1.0.0 v1.1.0
proj_v100="$tmp/proj-v100"
make_project "$proj_v100" "v1.0.0"
rc_h=$(run_vc "$proj_v100" "$upstream_stable" "$tmp/stable-out.log")
check "stable target → run exits 0" \
  bash -c "[ '$rc_h' = '0' ]"
check "stable target → banner emits /releases/tag/v1.1.0" \
  bash -c "grep -q '/releases/tag/v1.1.0' '$tmp/stable-out.log'"
check "stable target → banner does NOT use the rc commits-form fallback" \
  bash -c "! grep -q '/commits/v1.1.0' '$tmp/stable-out.log'"

echo
echo "PASS: $pass"
echo "FAIL: $fail"
if [[ $fail -gt 0 ]]; then
  exit 1
fi
exit 0
