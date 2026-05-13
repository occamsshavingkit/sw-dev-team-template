#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# scripts/lib/semver.sh — shared SemVer tag sort.
#
# Sourced by scripts/upgrade.sh and scripts/stepwise-smoke.sh.
# Single source of truth for tag ordering; both call sites must use
# this lib so an upgrade.sh fix can never silently miss stepwise-smoke
# (issue #108 origin).
#
# Exports:
#   semver_sort_tags                - read tags on stdin, sorted on stdout
#   semver_sort_tags_self_test      - regression guard for issue #108
#
# Sort SemVer tags. Issue #108: legacy single-identifier prerelease
# like `rc10` was sorted lexically because awk's /^[0-9]+$/ test
# rejects it (it's alphanumeric). Result: rc10 < rc8 < rc9. Fix:
# special-case identifiers of the form `<alpha><digits>` (e.g.
# `rc10`, `beta3`) by splitting alpha + numeric for sort. Pure
# numeric and pure alpha identifiers behave per SemVer §11.
#
# Future: prefer SemVer-native `rc.N` (numeric prerelease) for new
# release candidates; this special-case handles legacy `rcN` form.
semver_sort_tags() {
  awk '
    function prerelease_key(pre, ids, n, i, id, key, m, alpha, num) {
      if (pre == "") {
        return "1"
      }
      n = split(pre, ids, ".")
      key = "0"
      for (i = 1; i <= n; i++) {
        id = ids[i]
        if (id ~ /^[0-9]+$/) {
          key = key ".1.0." sprintf("%010d", length(id)) "." id
        } else if (match(id, /^[A-Za-z][A-Za-z]*[0-9]+$/)) {
          # Legacy form: rcN, betaN. Split alpha prefix + numeric tail
          # so rc9 < rc10 < rc11. Tier 2 (alphanumeric) but ordered by
          # alpha-then-numeric within the tier.
          m = match(id, /[0-9]+$/)
          alpha = substr(id, 1, m - 1)
          num   = substr(id, m)
          key = key ".1.1." alpha "." sprintf("%010d", length(num)) "." num
        } else {
          key = key ".1.1." id ".0000000000.0"
        }
      }
      return key ".0"
    }
    /^v[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$/ {
      tag = $0
      rest = substr(tag, 2)
      prerelease = ""
      dash = index(rest, "-")
      if (dash > 0) {
        prerelease = substr(rest, dash + 1)
        rest = substr(rest, 1, dash - 1)
      }
      split(rest, parts, ".")
      printf "%010d.%010d.%010d.%s\t%s\n", parts[1], parts[2], parts[3], prerelease_key(prerelease), tag
    }
  ' | LC_ALL=C sort -t "$(printf '\t')" -k1,1 | cut -f2-
}

# Self-test for semver_sort_tags. Issue #108 regression guard.
# Invoked via `scripts/upgrade.sh --self-test-semver`.
semver_sort_tags_self_test() {
  local input expected actual rc=0
  input=$'v1.0.0-rc8\nv1.0.0-rc9\nv1.0.0-rc10\nv1.0.0-rc11\nv1.0.0-rc.10\nv1.0.0\nv0.14.4\nv0.14.10'
  # Expected order, per SemVer §11:
  #   v0.14.4 < v0.14.10 (numeric major.minor.patch components)
  #   <  v1.0.0-rc.10 < rc8 < rc9 < rc10 < rc11 (prereleases) < v1.0.0
  # Reasoning for rc.10 vs rcN ordering:
  #   §11.4.4 "A larger set of pre-release fields has a higher
  #   precedence than a smaller set, if all of the preceding
  #   identifiers are equal." But here the FIRST identifiers differ:
  #   `rc.10` has first identifier `rc`; `rc8` has single identifier
  #   `rc8`. Both alphanumeric → lexical compare. `rc` < `rc8`. So
  #   `rc.10` sorts BEFORE all `rcN` forms.
  # Within the legacy rcN family the issue #108 fix gives us numeric
  # ordering: rc8 < rc9 < rc10 < rc11.
  expected=$'v0.14.4\nv0.14.10\nv1.0.0-rc.10\nv1.0.0-rc8\nv1.0.0-rc9\nv1.0.0-rc10\nv1.0.0-rc11\nv1.0.0'
  actual="$(printf '%s\n' "$input" | semver_sort_tags)"
  if [[ "$actual" == "$expected" ]]; then
    echo "OK: semver_sort_tags self-test passed"
  else
    echo "FAIL: semver_sort_tags self-test"
    echo "expected:"; printf '%s\n' "$expected" | sed 's/^/  /'
    echo "actual:"; printf '%s\n' "$actual" | sed 's/^/  /'
    rc=1
  fi
  return "$rc"
}
