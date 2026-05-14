#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# scripts/lib/gate-tags.sh — prior-tag enumeration + upgrade-paths sub-gate
# (FR-003, US2).
#
# Sourced from gate-runner.sh when present.

# gate_enumerate_source_tags
#   stdout: one tag name per line, every published tag reachable from HEAD.
#           Tags are resolved to their current commit SHA (R-9 force-move-safe).
#           No scope cap by track, recency, or MAJOR (Clarifications Session
#           2026-05-14 / FR-003).
gate_enumerate_source_tags() {
    cd "$GATE_CANDIDATE_TREE" || return 1
    # `git tag --merged HEAD` enumerates tags reachable from current HEAD.
    # Filter to v* annotated/lightweight tags; exclude HEAD-equivalent tags
    # only via the per-round-trip same-sha shortcut below, NOT here, so
    # every published tag still produces a row.
    git tag --list 'v*' --merged HEAD 2>/dev/null
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

# gate_run_one_round_trip <source_tag>
#   Run one scaffold + upgrade + verify cycle.
#   Returns 0 on success, non-zero on any step failure.
#   stderr captures the diagnostic.
gate_run_one_round_trip() {
    src_tag="$1"
    target_dir="$GATE_TEMP_ROOT/upgrade-paths/$src_tag"
    log="$target_dir.log"
    mkdir -p "$target_dir"

    # Step 1: scaffold from the source tag's tree using the source tag's scaffold.sh.
    # We have to run scripts/scaffold.sh from the source-tag worktree because
    # different rcs have different scaffold behaviour.
    src_worktree=$(mktemp -d "$GATE_TEMP_ROOT/src-${src_tag//\//_}.XXXXXX")
    git -C "$GATE_UPSTREAM_FIXTURE" worktree add --quiet --detach "$src_worktree" "$src_tag" >>"$log" 2>&1 || {
        echo "round-trip $src_tag: git worktree add failed" >>"$log"
        cat "$log" >&2
        rm -rf "$target_dir"
        return 1
    }

    (
        cd "$src_worktree" || exit 1
        ./scripts/scaffold.sh "$target_dir" "gate-fixture-$src_tag" >/dev/null 2>&1
    ) >>"$log" 2>&1
    scaffold_rc=$?
    if [ "$scaffold_rc" -ne 0 ]; then
        echo "round-trip $src_tag: scaffold exit $scaffold_rc" >>"$log"
        tail -20 "$log" >&2
        git -C "$GATE_UPSTREAM_FIXTURE" worktree remove --force "$src_worktree" >/dev/null 2>&1
        rm -rf "$target_dir"
        return 1
    fi

    # Step 2: upgrade from the scaffolded fixture to the candidate sentinel.
    (
        cd "$target_dir" || exit 1
        SWDT_UPSTREAM_URL="$GATE_UPSTREAM_FIXTURE" ./scripts/upgrade.sh --target "$GATE_CANDIDATE_TAG" >/dev/null 2>&1
    ) >>"$log" 2>&1
    upgrade_rc=$?
    if [ "$upgrade_rc" -ne 0 ]; then
        echo "round-trip $src_tag: upgrade exit $upgrade_rc" >>"$log"
        tail -20 "$log" >&2
        git -C "$GATE_UPSTREAM_FIXTURE" worktree remove --force "$src_worktree" >/dev/null 2>&1
        rm -rf "$target_dir"
        return 1
    fi

    # Step 3: verify clean immediately after upgrade.
    (
        cd "$target_dir" || exit 1
        ./scripts/upgrade.sh --verify >/dev/null 2>&1
    ) >>"$log" 2>&1
    verify_rc=$?

    # Cleanup BEFORE returning (whether pass or fail).
    git -C "$GATE_UPSTREAM_FIXTURE" worktree remove --force "$src_worktree" >/dev/null 2>&1
    rm -rf "$target_dir"

    if [ "$verify_rc" -ne 0 ]; then
        echo "round-trip $src_tag: verify exit $verify_rc" >>"$log"
        tail -20 "$log" >&2
        return 1
    fi

    return 0
}

# gate_subgate_upgrade-paths (regression). FR-003.
gate_subgate_upgrade-paths() {
    cd "$GATE_CANDIDATE_TREE" || return 1

    # Enumerate source tags.
    tags=$(gate_enumerate_source_tags)
    n_tags=$(printf '%s' "$tags" | grep -c .)

    if [ "$n_tags" -eq 0 ]; then
        # FR-003 edge case "Brand-new rc with no prior tags": clean pass.
        echo "0 rounds (no prior tags)"
        return 0
    fi

    # Setup shared upstream fixture once.
    gate_setup_upgrade_fixture || {
        echo "upgrade-paths: setup_upgrade_fixture failed (rc=$?)"
        return 1
    }

    pass=0
    fail=0
    failing_tags=""

    # Iterate over each source tag.
    printf '%s\n' "$tags" | while IFS= read -r src_tag; do
        [ -z "$src_tag" ] && continue
        # Skip same-SHA shortcut: a tag pointing at HEAD is a no-op upgrade.
        src_sha=$(git -C "$GATE_CANDIDATE_TREE" rev-parse "$src_tag^{commit}" 2>/dev/null || echo "")
        candidate_sha=$(git -C "$GATE_CANDIDATE_TREE" rev-parse HEAD 2>/dev/null || echo "")
        if [ -n "$src_sha" ] && [ "$src_sha" = "$candidate_sha" ]; then
            printf '%s\n' "PASS:$src_tag" >> "$GATE_TEMP_ROOT/upgrade-paths.results"
            continue
        fi

        gate_run_one_round_trip "$src_tag"
        rt_rc=$?
        if [ "$rt_rc" -eq 0 ]; then
            printf '%s\n' "PASS:$src_tag" >> "$GATE_TEMP_ROOT/upgrade-paths.results"
        else
            printf '%s\n' "FAIL:$src_tag" >> "$GATE_TEMP_ROOT/upgrade-paths.results"
        fi
    done

    # Aggregate results (subshell-safe by reading the recorded file).
    if [ -f "$GATE_TEMP_ROOT/upgrade-paths.results" ]; then
        pass=$(grep -c '^PASS:' "$GATE_TEMP_ROOT/upgrade-paths.results")
        fail=$(grep -c '^FAIL:' "$GATE_TEMP_ROOT/upgrade-paths.results")
        failing_tags=$(grep '^FAIL:' "$GATE_TEMP_ROOT/upgrade-paths.results" | sed 's/^FAIL://' | tr '\n' ' ')
    fi

    echo "$pass/$n_tags round-trips passed"
    if [ "$fail" -gt 0 ]; then
        echo "  failing source tags: $failing_tags"
        return 1
    fi
    return 0
}

# Register the sub-gate. The runner's source-time guard ensures we only
# register if gate-runner.sh's gate_register function is defined.
if command -v gate_register >/dev/null 2>&1; then
    gate_register upgrade-paths regression "Scaffold+upgrade+verify round-trip from every prior tag (FR-003)."
fi
