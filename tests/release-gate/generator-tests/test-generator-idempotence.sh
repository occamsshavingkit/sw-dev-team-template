#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# tests/release-gate/generator-tests/test-generator-idempotence.sh —
# meta-test for scripts/generate-fixture-snapshots.sh (spec 008 FR-003).
#
# Asserts: re-running the generator against an unchanged repo state
# produces byte-identical output. Idempotence is the load-bearing
# invariant of the generator-versus-on-disk recovery procedure (FR-007).
#
# Strategy: regenerate one (source-rc, variant) pair, snapshot bytes,
# regenerate again, snapshot bytes, diff. Repeat for each default-on
# variant against the newest source-rc (cheapest pair).
#
# Owned by qa-engineer per variant-catalog.md "Meta-tests".

set -eu

repo_root="$(cd "$(dirname "$0")/../../.." && pwd)"
generator="$repo_root/scripts/generate-fixture-snapshots.sh"

# Find newest v1 tag from the eligible set.
newest_tag=$(
    cd "$repo_root" || exit 1
    git tag --list 'v1.0.0*' --merged HEAD 2>/dev/null \
        | awk '
            function key(tag, rest, dash, pre, m, alpha, num) {
                rest = substr(tag, 2)
                dash = index(rest, "-")
                pre = dash > 0 ? substr(rest, dash + 1) : ""
                if (match(pre, /^[A-Za-z][A-Za-z]*[0-9]+$/)) {
                    m = match(pre, /[0-9]+$/)
                    alpha = substr(pre, 1, m - 1)
                    num = substr(pre, m)
                    return alpha "." sprintf("%010d", num)
                }
                return pre == "" ? "z" : pre
            }
            { printf "%s\t%s\n", key($0), $0 }
        ' | LC_ALL=C sort -t"$(printf '\t')" -k1,1 | tail -1 | awk -F'\t' '{print $2}'
)

if [ -z "$newest_tag" ]; then
    echo "  SKIP: no v1.0.0* tag merged to HEAD"
    exit 0
fi

rc=0
fail() {
    echo "  FAIL: $*" >&2
    rc=1
}

for variant in clean with-customizations with-accepted-local; do
    target="$repo_root/tests/release-gate/snapshots/$newest_tag/$variant"

    # First regen.
    "$generator" --source-rc "$newest_tag" --variant "$variant" >/dev/null 2>&1 \
        || { fail "first regen failed for $newest_tag/$variant"; continue; }

    snap_a=$(mktemp -d)
    cp -a "$target/." "$snap_a/"

    # Second regen.
    "$generator" --source-rc "$newest_tag" --variant "$variant" >/dev/null 2>&1 \
        || { fail "second regen failed for $newest_tag/$variant"; rm -rf "$snap_a"; continue; }

    if ! diff -rq "$snap_a" "$target" >/dev/null 2>&1; then
        fail "$newest_tag/$variant: bytes changed between regenerations"
        diff -rq "$snap_a" "$target" 2>&1 | head -5 | sed 's/^/      /' >&2
    fi
    rm -rf "$snap_a"
done

if [ "$rc" -eq 0 ]; then
    echo "  PASS: generator idempotent against $newest_tag for all 3 default-on variants"
fi

exit "$rc"
