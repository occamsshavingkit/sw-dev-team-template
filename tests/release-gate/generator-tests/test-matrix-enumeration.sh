#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# tests/release-gate/generator-tests/test-matrix-enumeration.sh —
# unit test for gate_enumerate_matrix_pairs (spec 008 FR-005) and the
# allowlist / skipfile membership predicate gate_pair_in_list (FR-004,
# FR-006).
#
# Strategy: load scripts/lib/gate-tags.sh against the live candidate
# worktree, then assert the matrix shape matches the spec.

set -eu

repo_root="$(cd "$(dirname "$0")/../../.." && pwd)"

rc=0
fail() {
    echo "  FAIL: $*" >&2
    rc=1
}

# Source the lib (it expects GATE_CANDIDATE_TREE in env).
export GATE_CANDIDATE_TREE="$repo_root"
# shellcheck disable=SC1091
. "$repo_root/scripts/lib/gate-tags.sh"

# Default matrix: clean × every source-rc, plus with-customizations and
# with-accepted-local restricted to the latest two v1.0.0-* tags.
pairs=$(gate_enumerate_matrix_pairs)
n_pairs=$(printf '%s' "$pairs" | grep -c .)

# Compute expected counts from the live tag set.
n_eligible=$(gate_enumerate_source_tags | grep -c .)
expected=$((n_eligible + 2 + 2))

if [ "$n_pairs" -ne "$expected" ]; then
    fail "default-matrix size: expected $expected (= $n_eligible clean + 2 with-customizations + 2 with-accepted-local), got $n_pairs"
fi

# Every (latest_two_v1_tag, with-customizations) pair must appear, and
# every (latest_two_v1_tag, with-accepted-local) pair must appear.
latest_two=$(
    gate_enumerate_source_tags | awk '
        function prerelease_key(pre, ids, n, i, id, key, m, alpha, num) {
            if (pre == "") return "1"
            n = split(pre, ids, ".")
            key = "0"
            for (i = 1; i <= n; i++) {
                id = ids[i]
                if (id ~ /^[0-9]+$/) key = key ".1.0." sprintf("%010d", length(id)) "." id
                else if (match(id, /^[A-Za-z][A-Za-z]*[0-9]+$/)) {
                    m = match(id, /[0-9]+$/); alpha = substr(id, 1, m - 1); num = substr(id, m)
                    key = key ".1.1." alpha "." sprintf("%010d", length(num)) "." num
                } else key = key ".1.1." id ".0000000000.0"
            }
            return key ".0"
        }
        /^v1\.0\.0(-[0-9A-Za-z.-]+)?$/ {
            tag = $0; rest = substr(tag, 2); pre = ""; dash = index(rest, "-")
            if (dash > 0) { pre = substr(rest, dash + 1); rest = substr(rest, 1, dash - 1) }
            split(rest, parts, ".")
            printf "%010d.%010d.%010d.%s\t%s\n", parts[1], parts[2], parts[3], prerelease_key(pre), tag
        }
    ' | LC_ALL=C sort -t"$(printf '\t')" -k1,1 | tail -2 | awk -F'\t' '{print $2}'
)

for variant in with-customizations with-accepted-local; do
    while IFS= read -r tag; do
        [ -z "$tag" ] && continue
        if ! printf '%s\n' "$pairs" | grep -qE "^${tag}	${variant}\$"; then
            fail "missing pair: $tag/$variant"
        fi
    done <<EOF
$latest_two
EOF
done

# Extended matrix: every non-baseline variant against every eligible source-rc.
extended_pairs=$(GATE_EXTENDED_MATRIX=1 gate_enumerate_matrix_pairs)
n_ext=$(printf '%s' "$extended_pairs" | grep -c .)
# 3 variants × N tags = 3N (optional variants are default-off; their
# mutation scripts do not ship in v1 so the extended count stays at 3N).
expected_ext=$((n_eligible * 3))
if [ "$n_ext" -ne "$expected_ext" ]; then
    fail "extended-matrix size: expected $expected_ext (= $n_eligible × 3 variants), got $n_ext"
fi

# Allowlist + skipfile predicate: bare-tag matches every variant; pair
# form matches only the named variant.
list_tmp=$(mktemp)
{
    echo '# test allowlist'
    echo 'v1.0.0-rc99'
    echo 'v1.0.0-rc100:with-customizations'
} > "$list_tmp"

if ! gate_pair_in_list "v1.0.0-rc99:clean" "$list_tmp"; then
    fail "bare-tag allowlist did not match v1.0.0-rc99:clean"
fi
if ! gate_pair_in_list "v1.0.0-rc99:with-customizations" "$list_tmp"; then
    fail "bare-tag allowlist did not match v1.0.0-rc99:with-customizations"
fi
if ! gate_pair_in_list "v1.0.0-rc100:with-customizations" "$list_tmp"; then
    fail "pair-form allowlist did not match v1.0.0-rc100:with-customizations"
fi
if gate_pair_in_list "v1.0.0-rc100:clean" "$list_tmp"; then
    fail "pair-form allowlist wrongly matched a different variant of the same tag"
fi
if gate_pair_in_list "v1.0.0-rc101:clean" "$list_tmp"; then
    fail "allowlist wrongly matched an unrelated tag"
fi
rm -f "$list_tmp"

if [ "$rc" -eq 0 ]; then
    echo "  PASS: matrix enumeration + allowlist predicate behave per spec 008 FR-004/005/006"
fi

exit "$rc"
