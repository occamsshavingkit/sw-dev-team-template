#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# scripts/lib/gate-migrations.sh — migrations-standalone sub-gate
# (FR-007, US3). Per R-7: exercise each migrations/*.sh with PROJECT_ROOT
# and WORKDIR_NEW set against a freshly-scaffolded rc-prior fixture, and
# fail if the migration emits a placeholder body or writes a
# `placeholder` source-attribution entry to docs/DECISIONS.md.

# Placeholder marker (literal string). Enumerated explicitly per R-7 so
# adding a new migration's marker is a one-line edit.
GATE_MIGRATION_PLACEHOLDER_MARKER='**TODO**: the rc9 agent-contract schema requires this section.'

# gate_migration_prior_tag <target_version>
#   Return the tag immediately preceding the migration's target version,
#   in semver order, that exists in the local clone. Used to scaffold an
#   upgrade-source fixture (E-6 invariant: a migration with target T is
#   exercised against a fixture from the closest predecessor).
#
# Empty stdout means "no viable prior tag" — caller should skip.
gate_migration_prior_tag() {
    target="$1"
    # Try the rc-1 shortcut first: vX.Y.Z-rcN → vX.Y.Z-rc(N-1).
    case "$target" in
        v*-rc*)
            base="${target%-rc*}"
            n="${target##*-rc}"
            if [ "$n" -gt 1 ] 2>/dev/null; then
                prior="${base}-rc$((n - 1))"
                if git -C "$GATE_CANDIDATE_TREE" rev-parse "$prior" >/dev/null 2>&1; then
                    echo "$prior"
                    return 0
                fi
            fi
            ;;
    esac
    # General case: enumerate tags in ascending semver order, find the one
    # immediately before `target`. Empty if `target` is the first tag.
    git -C "$GATE_CANDIDATE_TREE" tag --list 'v*' --merged HEAD --sort=v:refname \
        | awk -v t="$target" '
            $0 == t { if (prev != "") print prev; exit }
            { prev = $0 }
        '
}

# gate_subgate_migrations-standalone (regression). FR-007.
gate_subgate_migrations-standalone() {
    cd "$GATE_CANDIDATE_TREE" || return 1

    if [ ! -d migrations ]; then
        echo "no migrations/ directory; sub-gate vacuously passes"
        return 0
    fi

    failures=0
    for mig in migrations/v*.sh; do
        [ -f "$mig" ] || continue
        target=$(basename "$mig" .sh)
        prior=$(gate_migration_prior_tag "$target")
        if [ -z "$prior" ]; then
            # No viable prior tag — either the target is the earliest tag
            # in the clone or the named target is unreleased. Skip with an
            # advisory note (not a failure).
            echo "migration $mig: no viable prior tag for $target; skipping"
            continue
        fi

        # Setup: each sub-gate runs in its own subshell so we can't rely on
        # upgrade-paths having set GATE_UPSTREAM_FIXTURE. Build a dedicated
        # one for this sub-gate, idempotently removing any prior state.
        if [ -z "${GATE_UPSTREAM_FIXTURE:-}" ] || [ ! -d "${GATE_UPSTREAM_FIXTURE:-/nonexistent}" ]; then
            # Use a sub-gate-specific path so concurrent setups don't collide
            # with upgrade-paths's $GATE_TEMP_ROOT/upstream-fixture.
            GATE_UPSTREAM_FIXTURE="$GATE_TEMP_ROOT/upstream-fixture-mig"
            rm -rf "$GATE_UPSTREAM_FIXTURE"
            git clone --local --quiet "$GATE_CANDIDATE_TREE" "$GATE_UPSTREAM_FIXTURE" >/dev/null 2>&1 || {
                echo "migration $mig: clone for fixture failed"
                failures=$((failures + 1))
                continue
            }
            git -C "$GATE_UPSTREAM_FIXTURE" config user.email "gate@example.invalid"
            git -C "$GATE_UPSTREAM_FIXTURE" config user.name "pre-release gate"
            GATE_CANDIDATE_TAG="gate-candidate-mig"
            candidate_sha=$(git -C "$GATE_CANDIDATE_TREE" rev-parse HEAD)
            git -C "$GATE_UPSTREAM_FIXTURE" tag -a "$GATE_CANDIDATE_TAG" -m "pre-release gate candidate sentinel" "$candidate_sha" 2>/dev/null
        fi

        fixture_dir=$(mktemp -d "$GATE_TEMP_ROOT/mig-fixture-${target}.XXXXXX")
        src_worktree=$(mktemp -d "$GATE_TEMP_ROOT/mig-src-${target}.XXXXXX")
        workdir_new=$(mktemp -d "$GATE_TEMP_ROOT/mig-workdir-${target}.XXXXXX")
        log="$GATE_TEMP_ROOT/mig-${target}.log"

        # Scaffold from rc-prior into fixture_dir.
        git -C "$GATE_UPSTREAM_FIXTURE" worktree add --quiet --detach "$src_worktree" "$prior" >>"$log" 2>&1 || {
            echo "migration $mig: failed to checkout prior tag $prior"
            failures=$((failures + 1))
            rm -rf "$fixture_dir" "$workdir_new"
            continue
        }
        (
            cd "$src_worktree" || exit 1
            ./scripts/scaffold.sh "$fixture_dir" "gate-mig-$target" >/dev/null 2>&1
        ) >>"$log" 2>&1

        # Extract candidate tree to workdir_new for the migration's WORKDIR_NEW env.
        git -C "$GATE_CANDIDATE_TREE" archive --format=tar HEAD | tar -xf - -C "$workdir_new"

        # Snapshot DECISIONS.md pre-run so we can diff.
        decisions_before=""
        if [ -f "$fixture_dir/docs/DECISIONS.md" ]; then
            decisions_before=$(wc -l < "$fixture_dir/docs/DECISIONS.md")
        fi

        # Run the migration with full env.
        #
        # WORKDIR_OLD must be exported alongside WORKDIR_NEW to match production
        # upgrade.sh semantics (scripts/upgrade.sh:858-859 exports both when the
        # baseline is reachable). The migration's pre-bootstrap 3-way compare
        # (FW-ADR-0010) and the v0.14.0 manifest synthesis both consult
        # WORKDIR_OLD to decide whether a bootstrap-critical file's project copy
        # is unchanged-since-scaffold vs. carries a local edit vs. has no
        # reachable baseline. Without WORKDIR_OLD set, every project file falls
        # into the "no baseline" branch and gets flagged baseline-unreachable,
        # which is wrong for the standalone gate because $src_worktree IS the
        # prior-tag checkout (the same role $workdir/old plays in production).
        (
            cd "$fixture_dir" || exit 1
            PROJECT_ROOT="$fixture_dir" \
            WORKDIR_NEW="$workdir_new" \
            WORKDIR_OLD="$src_worktree" \
            OLD_VERSION="$prior" \
            NEW_VERSION="$target" \
            TARGET_VERSION="$target" \
                bash "$GATE_CANDIDATE_TREE/$mig" >>"$log" 2>&1
        )
        mig_rc=$?

        if [ "$mig_rc" -ne 0 ]; then
            echo "$mig: migration exited $mig_rc"
            tail -10 "$log" | sed 's/^/  /'
            failures=$((failures + 1))
        fi

        # Detect placeholder body in any agents file under fixture.
        if grep -rqF "$GATE_MIGRATION_PLACEHOLDER_MARKER" "$fixture_dir/.claude/agents/" 2>/dev/null; then
            echo "$mig: placeholder body landed in scaffolded fixture (.claude/agents/)"
            grep -rlF "$GATE_MIGRATION_PLACEHOLDER_MARKER" "$fixture_dir/.claude/agents/" 2>/dev/null \
                | sed 's|.*/agents/|  - .claude/agents/|'
            failures=$((failures + 1))
        fi

        # Detect "placeholder" attribution in DECISIONS.md diff.
        if [ -n "$decisions_before" ] && [ -f "$fixture_dir/docs/DECISIONS.md" ]; then
            decisions_after=$(wc -l < "$fixture_dir/docs/DECISIONS.md")
            if [ "$decisions_after" -gt "$decisions_before" ]; then
                new_lines=$((decisions_after - decisions_before))
                if tail -n "$new_lines" "$fixture_dir/docs/DECISIONS.md" | grep -qi 'placeholder'; then
                    echo "$mig: 'placeholder' attribution found in DECISIONS.md delta"
                    failures=$((failures + 1))
                fi
            fi
        fi

        # Cleanup.
        git -C "$GATE_UPSTREAM_FIXTURE" worktree remove --force "$src_worktree" >/dev/null 2>&1
        rm -rf "$fixture_dir" "$workdir_new"
    done

    if [ "$failures" -gt 0 ]; then
        echo
        echo "$failures migration sub-gate failure(s)"
        return 1
    fi
    return 0
}

if command -v gate_register >/dev/null 2>&1; then
    gate_register migrations-standalone regression "Standalone migration runs + placeholder detection (FR-007)."
fi
