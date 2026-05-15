#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# scripts/generate-fixture-snapshots.sh — upgrade-matrix fixture
# generator (spec 008 FR-003, FR-007).
#
# Iterates over (source-rc, variant) pairs in the default-on matrix and
# produces snapshot trees at tests/release-gate/snapshots/<rc>/<variant>/.
# Re-running with the same inputs (source-rc tag SHA, variant name,
# generator version) produces equivalent output.
#
# Modes:
#   (default) regenerate matrix in place; existing snapshots are
#             overwritten.
#   --check   re-run pipeline into a tempdir; diff against on-disk
#             snapshots; exit non-zero on divergence (FR-007).
#   --all     regenerate the full default-on matrix (synonym for the
#             default; explicit for orchestrator wiring).
#   --variant <name>     restrict to one variant.
#   --source-rc <tag>    restrict to one source-rc.
#   --help    print usage.
#
# Outputs are deterministic under fixed inputs after byte-level
# normalisation (see normalize_tree below).
#
# Generator version bump rule: when the normalisation set changes or
# the mutation contract changes, bump GENERATOR_VERSION below; the
# bump is the operator's signal that snapshots must be regenerated.

set -eu

GENERATOR_VERSION="1.0.0"

usage() {
    cat <<'USAGE'
Usage: scripts/generate-fixture-snapshots.sh [--check | --all]
                                              [--variant <name>]
                                              [--source-rc <tag>]
                                              [--help]

Generates / verifies the upgrade-matrix fixture snapshots used by the
upgrade-paths sub-gate (spec 008).

Modes:
  --check               Verify on-disk snapshots match a fresh regen.
                        Exit 0 if every snapshot matches; non-zero on
                        any divergence with a per-pair diagnostic.
  --all                 Regenerate the full default-on matrix
                        (synonym for default mode).
  --variant <name>      Restrict to one variant (clean,
                        with-customizations, with-accepted-local).
  --source-rc <tag>     Restrict to one source-rc tag.
  --help, -h            This help.

The matrix is the spec-008 FR-005 default-on subset:
  - clean: every source-rc enumerated by gate_enumerate_source_tags.
  - with-customizations: the latest two source-rcs on the current MAJOR.
  - with-accepted-local: the latest two source-rcs on the current MAJOR.
USAGE
}

MODE="generate"
RESTRICT_VARIANT=""
RESTRICT_SOURCE_RC=""

while [ "$#" -gt 0 ]; do
    case "$1" in
        --help|-h)
            usage
            exit 0
            ;;
        --check)
            MODE="check"
            shift
            ;;
        --all)
            MODE="generate"
            shift
            ;;
        --variant)
            [ -n "${2:-}" ] || { echo "--variant requires an argument" >&2; exit 2; }
            RESTRICT_VARIANT="$2"
            shift 2
            ;;
        --variant=*)
            RESTRICT_VARIANT="${1#--variant=}"
            shift
            ;;
        --source-rc)
            [ -n "${2:-}" ] || { echo "--source-rc requires an argument" >&2; exit 2; }
            RESTRICT_SOURCE_RC="$2"
            shift 2
            ;;
        --source-rc=*)
            RESTRICT_SOURCE_RC="${1#--source-rc=}"
            shift
            ;;
        *)
            echo "unknown flag: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

# Resolve repo root.
script_dir=$(cd "$(dirname "$0")" && pwd)
repo_root=$(cd "$script_dir/.." && pwd)

snapshots_root="$repo_root/tests/release-gate/snapshots"
mutations_dir="$repo_root/tests/release-gate/mutations"

# ----- Helpers ----------------------------------------------------------------

# enumerate_source_tags: mirror gate_enumerate_source_tags from
# scripts/lib/gate-tags.sh. We re-implement here (rather than source)
# because the generator runs against the candidate worktree directly
# without the gate-runner setup. Source the lib too for reuse, but use
# our own definition to avoid harness-coupling. Output is sorted via
# scripts/lib/semver.sh for deterministic ordering.
enumerate_source_tags() {
    cd "$repo_root" || return 1
    git tag --list 'v*' --merged HEAD 2>/dev/null | while IFS= read -r tag; do
        [ -z "$tag" ] && continue
        if git show "$tag:scripts/upgrade.sh" 2>/dev/null \
            | grep -q 'SWDT_UPSTREAM_URL'; then
            printf '%s\n' "$tag"
        fi
    done | LC_ALL=C sort
}

# variants_for_source_rc <tag>: emit the variants in the default-on
# subset that apply to the given source-rc, one per line.
#
# Default-on subset (FR-005):
#   - clean: every source-rc in scope.
#   - with-customizations: latest two source-rcs on the current MAJOR.
#   - with-accepted-local: latest two source-rcs on the current MAJOR.
#
# "Current MAJOR" is v1.0.0 (per Q-008b ruling: v1.0.0-only enumeration).
# "Latest two" is computed once via _LATEST_TWO_V1, set at script start.
variants_for_source_rc() {
    tag="$1"
    # `clean` always applies.
    printf 'clean\n'
    # `with-customizations` and `with-accepted-local` only on latest-two.
    case " $_LATEST_TWO_V1 " in
        *" $tag "*)
            printf 'with-customizations\n'
            printf 'with-accepted-local\n'
            ;;
    esac
}

# compute_latest_two_v1: pick the two newest v1.0.0-* tags from the
# enumerated list. POSIX-safe — reproduces scripts/lib/semver.sh
# ordering for the v1.0.0-rcN family via an inline awk sort key
# (issue #108 fix: legacy single-identifier prereleases rcN sort
# alpha-then-numeric so rc9 < rc10 < rc11).
compute_latest_two_v1() {
    enumerate_source_tags | awk '
        function prerelease_key(pre, ids, n, i, id, key, m, alpha, num) {
            if (pre == "") return "1"
            n = split(pre, ids, ".")
            key = "0"
            for (i = 1; i <= n; i++) {
                id = ids[i]
                if (id ~ /^[0-9]+$/) {
                    key = key ".1.0." sprintf("%010d", length(id)) "." id
                } else if (match(id, /^[A-Za-z][A-Za-z]*[0-9]+$/)) {
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
        /^v1\.0\.0(-[0-9A-Za-z.-]+)?$/ {
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
    ' | LC_ALL=C sort -t"$(printf '\t')" -k1,1 | tail -2 | awk -F'\t' '{print $2}' | tr '\n' ' '
}

# normalize_tree <dir>: apply byte-level normalisations so re-runs are
# reproducible per FR-003.
#
# Normalisations applied:
#   - Remove .git/ (scaffold runs `git init` which produces a
#     non-deterministic index + HEAD-ref).
#   - Pin TEMPLATE_VERSION's third line (the scaffold date) to a fixed
#     marker. The first two lines (semver + SHA) are already
#     deterministic given the source-rc tag SHA.
#   - Pin README.md's "on YYYY-MM-DD" stamp to the same fixed marker.
#   - Strip file mtimes (we use tar with deterministic flags at copy
#     time).
#
# The pinned marker is "GENERATOR-FIXED-DATE" (a non-ISO sentinel so
# downstream tooling that parses dates fails fast on a fixture leak).
normalize_tree() {
    dir="$1"
    rm -rf "$dir/.git"

    if [ -f "$dir/TEMPLATE_VERSION" ]; then
        # Replace line 3 (the date) with the fixed marker.
        awk 'NR==3{print "GENERATOR-FIXED-DATE"; next}{print}' \
            "$dir/TEMPLATE_VERSION" > "$dir/TEMPLATE_VERSION.tmp"
        mv "$dir/TEMPLATE_VERSION.tmp" "$dir/TEMPLATE_VERSION"
    fi

    if [ -f "$dir/README.md" ]; then
        # Replace "on YYYY-MM-DD." with "on GENERATOR-FIXED-DATE."
        sed -e 's/on [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]\./on GENERATOR-FIXED-DATE./g' \
            "$dir/README.md" > "$dir/README.md.tmp"
        mv "$dir/README.md.tmp" "$dir/README.md"
    fi

    if [ -f "$dir/TEMPLATE_MANIFEST.lock" ]; then
        # Manifest carries a wall-clock "# Generated <ISO timestamp>"
        # header line. Pin it to the fixed marker.
        sed -e 's/^# Generated [0-9TZ:.-]*$/# Generated GENERATOR-FIXED-DATE/' \
            "$dir/TEMPLATE_MANIFEST.lock" > "$dir/TEMPLATE_MANIFEST.lock.tmp"
        mv "$dir/TEMPLATE_MANIFEST.lock.tmp" "$dir/TEMPLATE_MANIFEST.lock"
    fi
}

# scaffold_and_mutate <source_rc> <variant> <out_dir>: produce a
# normalised snapshot at <out_dir>.
scaffold_and_mutate() {
    src_tag="$1"
    variant="$2"
    out_dir="$3"

    mutation_script="$mutations_dir/$variant.mutation.sh"
    if [ ! -x "$mutation_script" ]; then
        echo "generator: missing mutation script: $mutation_script" >&2
        return 1
    fi

    tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/gen-fixture-XXXXXX")
    src_worktree="$tmpdir/src-worktree"
    fixture="$tmpdir/fixture"

    # Add a worktree for the source tag.
    if ! git -C "$repo_root" worktree add --quiet --detach "$src_worktree" "$src_tag" >/dev/null 2>&1; then
        echo "generator: git worktree add failed for $src_tag" >&2
        rm -rf "$tmpdir"
        return 1
    fi

    # Scaffold into the fixture dir. The source-rc's own scaffold.sh
    # is used because behaviour differs per rc.
    if ! (
        cd "$src_worktree" || exit 1
        ./scripts/scaffold.sh "$fixture" "gate-fixture-$src_tag" >/dev/null 2>&1
    ); then
        echo "generator: scaffold failed for $src_tag" >&2
        git -C "$repo_root" worktree remove --force "$src_worktree" >/dev/null 2>&1 || true
        rm -rf "$tmpdir"
        return 1
    fi

    # Apply the variant's mutation inside the fixture.
    if ! (
        cd "$fixture" || exit 1
        SWDT_MUTATION_SOURCE_RC="$src_tag" \
            "$mutation_script"
    ); then
        echo "generator: mutation failed for $src_tag/$variant" >&2
        git -C "$repo_root" worktree remove --force "$src_worktree" >/dev/null 2>&1 || true
        rm -rf "$tmpdir"
        return 1
    fi

    # Normalise.
    normalize_tree "$fixture"

    # Move into the out_dir slot. Clear any prior contents.
    rm -rf "$out_dir"
    mkdir -p "$(dirname "$out_dir")"
    mv "$fixture" "$out_dir"

    git -C "$repo_root" worktree remove --force "$src_worktree" >/dev/null 2>&1 || true
    rm -rf "$tmpdir"
    return 0
}

# diff_trees <a> <b>: emit a brief diff, or nothing if identical.
# Returns 0 if identical, 1 if different.
diff_trees() {
    diff -rq "$1" "$2" 2>&1 || return 1
    return 0
}

# ----- Main -------------------------------------------------------------------

# Resolve which tags are eligible.
ALL_TAGS=$(enumerate_source_tags)
if [ -z "$ALL_TAGS" ]; then
    echo "generator: no eligible source tags (gate_enumerate_source_tags returned empty)" >&2
    exit 1
fi

_LATEST_TWO_V1=$(compute_latest_two_v1)
export _LATEST_TWO_V1

if [ -n "$RESTRICT_SOURCE_RC" ]; then
    # Filter to the named tag.
    if ! printf '%s\n' "$ALL_TAGS" | grep -Fxq "$RESTRICT_SOURCE_RC"; then
        echo "generator: --source-rc '$RESTRICT_SOURCE_RC' not in eligible set" >&2
        echo "  eligible: $(printf '%s' "$ALL_TAGS" | tr '\n' ' ')" >&2
        exit 2
    fi
    ALL_TAGS="$RESTRICT_SOURCE_RC"
fi

# Build the (source-rc, variant) pair list.
pairs=""
printf '%s\n' "$ALL_TAGS" | while IFS= read -r tag; do
    [ -z "$tag" ] && continue
    variants_for_source_rc "$tag" | while IFS= read -r variant; do
        [ -z "$variant" ] && continue
        if [ -n "$RESTRICT_VARIANT" ] && [ "$RESTRICT_VARIANT" != "$variant" ]; then
            continue
        fi
        printf '%s\t%s\n' "$tag" "$variant"
    done
done > "${TMPDIR:-/tmp}/gen-pairs.$$"

pair_count=$(wc -l < "${TMPDIR:-/tmp}/gen-pairs.$$" | tr -d ' ')

if [ "$pair_count" -eq 0 ]; then
    echo "generator: no (source-rc, variant) pairs in scope" >&2
    rm -f "${TMPDIR:-/tmp}/gen-pairs.$$"
    exit 0
fi

printf 'generator v%s: matrix has %d pair(s)\n' "$GENERATOR_VERSION" "$pair_count" >&2

overall_rc=0

if [ "$MODE" = "check" ]; then
    # --check: regenerate to a tempdir and diff against on-disk.
    check_tmp=$(mktemp -d "${TMPDIR:-/tmp}/gen-check-XXXXXX")
    diverged=""
    while IFS='	' read -r tag variant; do
        on_disk="$snapshots_root/$tag/$variant"
        regen="$check_tmp/$tag/$variant"
        if ! scaffold_and_mutate "$tag" "$variant" "$regen"; then
            echo "  $tag/$variant: regeneration failed" >&2
            overall_rc=1
            diverged="$diverged $tag/$variant"
            continue
        fi
        if [ ! -d "$on_disk" ]; then
            echo "  $tag/$variant: MISSING on disk (regenerated would create it)" >&2
            overall_rc=1
            diverged="$diverged $tag/$variant"
            continue
        fi
        if ! diff_output=$(diff -rq "$on_disk" "$regen" 2>&1); then
            echo "  $tag/$variant: DIVERGED:" >&2
            printf '%s\n' "$diff_output" | head -10 | sed 's/^/    /' >&2
            overall_rc=1
            diverged="$diverged $tag/$variant"
        elif [ -n "$diff_output" ]; then
            echo "  $tag/$variant: DIVERGED:" >&2
            printf '%s\n' "$diff_output" | head -10 | sed 's/^/    /' >&2
            overall_rc=1
            diverged="$diverged $tag/$variant"
        fi
    done < "${TMPDIR:-/tmp}/gen-pairs.$$"
    rm -rf "$check_tmp"
    rm -f "${TMPDIR:-/tmp}/gen-pairs.$$"
    if [ "$overall_rc" -eq 0 ]; then
        printf 'generator --check: all %d snapshot(s) match on-disk\n' "$pair_count" >&2
    else
        printf 'generator --check: divergence in:%s\n' "$diverged" >&2
        printf '  Operator action: classify each pair as legitimate-fix (regenerate + commit)\n' >&2
        printf '  or drift (investigate, revert hand-edits).\n' >&2
    fi
    exit "$overall_rc"
fi

# --generate (default / --all): build snapshots in place.
generated=0
while IFS='	' read -r tag variant; do
    target="$snapshots_root/$tag/$variant"
    printf '  generating %s/%s ...' "$tag" "$variant" >&2
    if scaffold_and_mutate "$tag" "$variant" "$target"; then
        printf ' ok\n' >&2
        generated=$((generated + 1))
    else
        printf ' FAILED\n' >&2
        overall_rc=1
    fi
done < "${TMPDIR:-/tmp}/gen-pairs.$$"
rm -f "${TMPDIR:-/tmp}/gen-pairs.$$"

printf 'generator: %d/%d snapshot(s) written\n' "$generated" "$pair_count" >&2
exit "$overall_rc"
