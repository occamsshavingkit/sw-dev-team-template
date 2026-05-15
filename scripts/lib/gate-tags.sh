#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# scripts/lib/gate-tags.sh — prior-tag enumeration + upgrade-paths sub-gate
# (FR-003, US2).
#
# Sourced from gate-runner.sh when present.

# gate_enumerate_source_tags
#   stdout: one tag name per line. Every published tag reachable from HEAD
#           whose scripts/upgrade.sh honours the SWDT_UPSTREAM_URL env var
#           (added in v0.16.0 and v1.0.0-rc3). Pre-v0.16.0 and v1.0.0-rc1/rc2
#           tags hardcode the GitHub URL and therefore cannot be exercised
#           against a local candidate fixture — they would always clone from
#           the published remote, bypassing the gate's local fixture. Those
#           tags are out-of-scope for the gate by technical constraint
#           (Q-0017 / customer answer A on 2026-05-14, supersedes the
#           Clarifications Session 2026-05-14 Q2=D "every published tag"
#           ruling for this specific class of pre-SWDT_UPSTREAM_URL tags).
#
#   The scope cap is implemented by enumerating every reachable v* tag and
#   inspecting each tag's scripts/upgrade.sh for the SWDT_UPSTREAM_URL
#   literal — robust to any future regression that drops the env-var
#   support, and self-correcting if a missing tag is added back.
#
#   Tags resolved to their current commit SHA at run start (R-9 force-move-safe).
gate_enumerate_source_tags() {
    cd "$GATE_CANDIDATE_TREE" || return 1
    git tag --list 'v*' --merged HEAD 2>/dev/null | while IFS= read -r tag; do
        [ -z "$tag" ] && continue
        # Inspect each tag's upgrade.sh; skip tags that don't honour
        # SWDT_UPSTREAM_URL.
        if git show "$tag:scripts/upgrade.sh" 2>/dev/null \
            | grep -q 'SWDT_UPSTREAM_URL'; then
            printf '%s\n' "$tag"
        fi
    done
}

# gate_setup_upgrade_fixture
#   Build the shared upstream fixture: a synthetic git repo carrying every
#   reachable tag PLUS the candidate state tagged as a sentinel. The fixture
#   is reused across every per-tag round-trip in the upgrade-paths sub-gate
#   (cuts setup cost from per-tag to once).
#
# Globals set on success:
#   GATE_UPSTREAM_FIXTURE   — path to the shared upstream-fixture git repo
#   GATE_CANDIDATE_TAG      — name of the synthetic tag at candidate state
gate_setup_upgrade_fixture() {
    cd "$GATE_CANDIDATE_TREE" || return 1
    GATE_UPSTREAM_FIXTURE="$GATE_TEMP_ROOT/upstream-fixture"
    GATE_CANDIDATE_TAG="gate-candidate"
    mkdir -p "$GATE_UPSTREAM_FIXTURE"

    # Clone candidate (shallow on tags only) into the fixture so every
    # published tag is reachable. Use `git clone --local` since we own the
    # working repo.
    git clone --local --quiet "$GATE_CANDIDATE_TREE" "$GATE_UPSTREAM_FIXTURE" >/dev/null 2>&1 || return 2
    git -C "$GATE_UPSTREAM_FIXTURE" config user.email "gate@example.invalid"
    git -C "$GATE_UPSTREAM_FIXTURE" config user.name "pre-release gate"

    # Synthetic tag at the candidate's HEAD so the gate exercises
    # rc-prior → candidate (HEAD), not rc-prior → real rc tag.
    candidate_sha=$(git -C "$GATE_CANDIDATE_TREE" rev-parse HEAD)
    git -C "$GATE_UPSTREAM_FIXTURE" tag -a "$GATE_CANDIDATE_TAG" -m "pre-release gate candidate sentinel" "$candidate_sha" 2>/dev/null
    return 0
}

# gate_enumerate_matrix_pairs
#   stdout: one "<source-rc>\t<variant>" line per pair in scope.
#
#   Default-on matrix (FR-005 spec 008):
#     - clean: every source-rc enumerated by gate_enumerate_source_tags.
#     - with-customizations: latest two v1.0.0-* source-rcs.
#     - with-accepted-local: latest two v1.0.0-* source-rcs.
#
#   GATE_EXTENDED_MATRIX=1 widens the non-baseline variants to the full
#   eligible source-rc set, AND admits the optional variants
#   (with-pre-bootstrap-conflict, with-mid-version-sha) when their
#   mutation scripts exist. Optional-variant mutation scripts are NOT
#   shipped in v1; under extended matrix they are silently skipped if
#   absent so adding them later requires no gate code change.
gate_enumerate_matrix_pairs() {
    cd "$GATE_CANDIDATE_TREE" || return 1
    all_tags=$(gate_enumerate_source_tags)
    [ -z "$all_tags" ] && return 0

    # Compute latest-two v1 tags (POSIX awk; mirrors generate-fixture-snapshots.sh).
    latest_two=$(
        printf '%s\n' "$all_tags" | awk '
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
                        alpha = substr(id, 1, m - 1); num = substr(id, m)
                        key = key ".1.1." alpha "." sprintf("%010d", length(num)) "." num
                    } else {
                        key = key ".1.1." id ".0000000000.0"
                    }
                }
                return key ".0"
            }
            /^v1\.0\.0(-[0-9A-Za-z.-]+)?$/ {
                tag = $0; rest = substr(tag, 2); pre = ""
                dash = index(rest, "-")
                if (dash > 0) { pre = substr(rest, dash + 1); rest = substr(rest, 1, dash - 1) }
                split(rest, parts, ".")
                printf "%010d.%010d.%010d.%s\t%s\n", parts[1], parts[2], parts[3], prerelease_key(pre), tag
            }
        ' | LC_ALL=C sort -t"$(printf '\t')" -k1,1 | tail -2 | awk -F'\t' '{print $2}' | tr '\n' ' '
    )

    # Emit pairs.
    printf '%s\n' "$all_tags" | while IFS= read -r tag; do
        [ -z "$tag" ] && continue
        # clean always applies.
        printf '%s\t%s\n' "$tag" "clean"

        # with-customizations + with-accepted-local: latest-two by default,
        # full range under extended matrix.
        non_baseline_match=0
        if [ "${GATE_EXTENDED_MATRIX:-0}" = "1" ]; then
            non_baseline_match=1
        else
            case " $latest_two " in
                *" $tag "*) non_baseline_match=1 ;;
            esac
        fi
        if [ "$non_baseline_match" = "1" ]; then
            printf '%s\t%s\n' "$tag" "with-customizations"
            printf '%s\t%s\n' "$tag" "with-accepted-local"
        fi

        # Optional variants — only under extended matrix, only if the
        # mutation script exists. (v1 ships none; default-off per FR-005.)
        if [ "${GATE_EXTENDED_MATRIX:-0}" = "1" ]; then
            for v in with-pre-bootstrap-conflict with-mid-version-sha; do
                if [ -x "$GATE_CANDIDATE_TREE/tests/release-gate/mutations/$v.mutation.sh" ]; then
                    printf '%s\t%s\n' "$tag" "$v"
                fi
            done
        fi
    done
}

# gate_pair_in_list <pair-key> <listfile>
#   Returns 0 if the pair (or its bare-tag form) is listed in the file.
#   Handles two row shapes:
#     <tag>             — matches every variant of that tag
#     <tag>:<variant>   — matches just that pair
gate_pair_in_list() {
    pair_key="$1"
    listfile="$2"
    [ -f "$listfile" ] || return 1
    tag_only="${pair_key%%:*}"
    # Strip comments + blank lines + leading/trailing whitespace.
    matches=$(grep -v '^[[:space:]]*#' "$listfile" 2>/dev/null \
        | sed 's/[[:space:]]*$//' \
        | grep -Fx -e "$pair_key" -e "$tag_only" 2>/dev/null \
        || true)
    [ -n "$matches" ]
}

# gate_run_one_round_trip <source_tag> <variant>
#   Run one snapshot-load + upgrade + verify cycle.
#   Returns 0 on success, non-zero on any step failure.
#   stderr captures the diagnostic.
#
#   Snapshot-based: copies tests/release-gate/snapshots/<src>/<variant>/
#   into the round-trip dir instead of running scripts/scaffold.sh fresh.
#   Snapshots are produced by scripts/generate-fixture-snapshots.sh and
#   committed to the repo (spec 008 FR-003 + Q-008d ruling).
gate_run_one_round_trip() {
    src_tag="$1"
    variant="$2"
    safe_pair=$(printf '%s' "${src_tag}__${variant}" | tr '/' '_')
    target_dir="$GATE_TEMP_ROOT/upgrade-paths/$safe_pair"
    log="$target_dir.log"
    mkdir -p "$target_dir"

    snapshot_dir="$GATE_CANDIDATE_TREE/tests/release-gate/snapshots/$src_tag/$variant"
    if [ ! -d "$snapshot_dir" ]; then
        # Snapshots are gitignored (per customer ruling 2026-05-15); regenerate
        # locally via the generator. Emit a clear diagnostic so the failure
        # mode is self-explanatory.
        {
            echo "ERROR: tests/release-gate/snapshots/$src_tag/$variant/ is missing."
            echo "Snapshots are gitignored; regenerate with:"
            echo "  bash scripts/generate-fixture-snapshots.sh --all"
            echo "(See tests/release-gate/snapshots/README.md.)"
        } | tee -a "$log" >&2
        rm -rf "$target_dir"
        return 1
    fi

    # Copy snapshot into the round-trip dir. cp -a preserves modes;
    # we want a writable tree so upgrade.sh can mutate it.
    cp -a "$snapshot_dir/." "$target_dir/" >>"$log" 2>&1 || {
        echo "round-trip $src_tag/$variant: cp snapshot failed" >>"$log"
        cat "$log" >&2
        rm -rf "$target_dir"
        return 1
    }

    # Initialise a git repo inside the fixture so upgrade.sh's
    # manifest-and-merge logic has a real worktree to operate on
    # (scaffold.sh would normally do this; the generator strips .git
    # to keep snapshots deterministic, so re-initialise here).
    (
        cd "$target_dir" || exit 1
        git init -b main -q
        git config user.email "gate@example.invalid"
        git config user.name "pre-release gate"
        git add . >/dev/null 2>&1
        git commit -q -m "fixture" --allow-empty >/dev/null 2>&1
    ) >>"$log" 2>&1 || {
        echo "round-trip $src_tag/$variant: git-init failed" >>"$log"
        cat "$log" >&2
        rm -rf "$target_dir"
        return 1
    }

    # Step 2: upgrade from the fixture to the candidate sentinel.
    # Detect whether the source's upgrade.sh honours --target (added in
    # v0.17.0 and v1.0.0-rc3). If not, omit the flag.
    upgrade_args=()
    if grep -q -- '--target' "$target_dir/scripts/upgrade.sh" 2>/dev/null; then
        upgrade_args=(--target "$GATE_CANDIDATE_TAG")
    fi
    (
        cd "$target_dir" || exit 1
        SWDT_UPSTREAM_URL="$GATE_UPSTREAM_FIXTURE" ./scripts/upgrade.sh "${upgrade_args[@]}" >/dev/null 2>&1
    ) >>"$log" 2>&1
    upgrade_rc=$?
    if [ "$upgrade_rc" -ne 0 ]; then
        echo "round-trip $src_tag/$variant: upgrade exit $upgrade_rc" >>"$log"
        tail -20 "$log" >&2
        rm -rf "$target_dir"
        return 1
    fi

    # Step 3: verify clean immediately after upgrade.
    (
        cd "$target_dir" || exit 1
        ./scripts/upgrade.sh --verify >/dev/null 2>&1
    ) >>"$log" 2>&1
    verify_rc=$?

    rm -rf "$target_dir"

    if [ "$verify_rc" -ne 0 ]; then
        echo "round-trip $src_tag/$variant: verify exit $verify_rc" >>"$log"
        tail -20 "$log" >&2
        return 1
    fi

    return 0
}

# gate_subgate_upgrade-paths (regression). FR-003 (spec 007) + FR-004
# (spec 008). Iterates over (source-rc, variant) pairs in the matrix
# instead of just source-rc.
gate_subgate_upgrade-paths() {
    cd "$GATE_CANDIDATE_TREE" || return 1

    # Enumerate matrix pairs.
    pairs=$(gate_enumerate_matrix_pairs)
    n_pairs=$(printf '%s' "$pairs" | grep -c .)

    if [ "$n_pairs" -eq 0 ]; then
        # FR-003 edge case "Brand-new rc with no prior tags": clean pass.
        echo "0 rounds (no prior tags)"
        return 0
    fi

    # Setup shared upstream fixture once.
    gate_setup_upgrade_fixture || {
        echo "upgrade-paths: setup_upgrade_fixture failed (rc=$?)"
        return 1
    }

    allowlist="$GATE_CANDIDATE_TREE/tests/release-gate/upgrade-paths-allowlist.txt"
    skipfile="$GATE_CANDIDATE_TREE/tests/release-gate/upgrade-matrix-skip.txt"
    results="$GATE_TEMP_ROOT/upgrade-paths.results"
    : > "$results"

    # Iterate over each (source-rc, variant) pair.
    printf '%s\n' "$pairs" | while IFS='	' read -r src_tag variant; do
        [ -z "$src_tag" ] && continue
        pair_key="$src_tag:$variant"

        # FR-006: skip-file excludes pairs from execution entirely.
        if gate_pair_in_list "$pair_key" "$skipfile"; then
            printf '%s\n' "SKIP:$pair_key" >> "$results"
            continue
        fi

        # Same-SHA shortcut: source tag at HEAD is a no-op upgrade.
        src_sha=$(git -C "$GATE_CANDIDATE_TREE" rev-parse "$src_tag^{commit}" 2>/dev/null || echo "")
        candidate_sha=$(git -C "$GATE_CANDIDATE_TREE" rev-parse HEAD 2>/dev/null || echo "")
        if [ -n "$src_sha" ] && [ "$src_sha" = "$candidate_sha" ]; then
            printf '%s\n' "PASS:$pair_key" >> "$results"
            continue
        fi

        gate_run_one_round_trip "$src_tag" "$variant"
        rt_rc=$?
        if [ "$rt_rc" -eq 0 ]; then
            printf '%s\n' "PASS:$pair_key" >> "$results"
        else
            printf '%s\n' "FAIL:$pair_key" >> "$results"
        fi
    done

    pass=0
    skipped=0
    failing_pairs=""
    if [ -f "$results" ]; then
        pass=$(grep -c '^PASS:' "$results" || true)
        skipped=$(grep -c '^SKIP:' "$results" || true)
        failing_pairs=$(grep '^FAIL:' "$results" | sed 's/^FAIL://' | tr '\n' ' ')
    fi

    # Partition failing pairs by allowlist (extended to <tag>:<variant>
    # rows; bare <tag> rows still allowlist every variant — FR-004).
    blocking_fail=0
    blocking_pairs=""
    allowlisted_pairs=""
    for p in $failing_pairs; do
        [ -z "$p" ] && continue
        if gate_pair_in_list "$p" "$allowlist"; then
            allowlisted_pairs="$allowlisted_pairs $p"
        else
            blocking_pairs="$blocking_pairs $p"
            blocking_fail=$((blocking_fail + 1))
        fi
    done

    n_attempted=$((n_pairs - skipped))
    echo "$pass/$n_attempted round-trips passed (matrix: $n_pairs pairs, $skipped skipped)"
    if [ -n "$allowlisted_pairs" ]; then
        echo "  allowlisted failures (logged, not blocking):$allowlisted_pairs"
    fi
    if [ "$blocking_fail" -gt 0 ]; then
        echo "  failing pairs:$blocking_pairs"
        return 1
    fi
    return 0
}

# gate_subgate_upgrade-matrix-fresh (regression). Spec 008 FR-007.
#   Recovery procedure: re-run the generator in --check mode and fail
#   the gate if any committed snapshot diverges from a fresh regen.
#   Bounded by upgrade-paths' ~8 min budget (FR-005); the --check path
#   uses the same scaffold-and-mutate pipeline as a generation run.
gate_subgate_upgrade-matrix-fresh() {
    cd "$GATE_CANDIDATE_TREE" || return 1
    generator="$GATE_CANDIDATE_TREE/scripts/generate-fixture-snapshots.sh"
    if [ ! -x "$generator" ]; then
        echo "upgrade-matrix-fresh: $generator missing or not executable"
        return 1
    fi
    # Run --check; capture stderr (the generator's diagnostic surface).
    if "$generator" --check 2>&1; then
        return 0
    fi
    echo "  Snapshot drift detected. Classify each pair as:"
    echo "    (a) legitimate generator fix — regenerate + commit affected snapshots;"
    echo "    (b) accidental drift (hand-edit / force-pushed tag) — revert, investigate."
    echo "  See spec 008 FR-007."
    return 1
}

# Register the sub-gates. The runner's source-time guard ensures we only
# register if gate-runner.sh's gate_register function is defined.
if command -v gate_register >/dev/null 2>&1; then
    gate_register upgrade-paths regression "Scaffold+upgrade+verify round-trip from every (source-rc, variant) pair (spec 007 FR-003 + spec 008 FR-004)."
    gate_register upgrade-matrix-fresh regression "Verify on-disk upgrade-matrix snapshots match a fresh generator run (spec 008 FR-007)."
fi
