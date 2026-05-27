#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# scripts/lib/gate-runner.sh — pre-release gate sub-gate registry, dispatcher,
# and built-in sub-gates.
#
# Owns: data-model.md E-1 (orchestrator) + E-2 (sub-gate) + per-sub-gate
# implementations for the v1 roster except upgrade-paths / advisory-pointers /
# migrations-standalone which live in dedicated scripts/lib/gate-*.sh files
# sourced from here at registration time.
#
# Contract surfaces:
#   - GATE_CANDIDATE_TREE  — absolute path to the candidate worktree root
#   - GATE_TEMP_ROOT       — orchestrator's per-run tempdir
#   - GATE_FIXTURES_DIR    — tests/release-gate/fixtures (read-only)
#   - GATE_ONLY            — single sub-gate name, or empty
#   - GATE_SKIP_LIST       — newline-separated names to exclude, or empty
#   - GATE_STRICT          — 1 when invoked by hook in strict mode (ignores ONLY/SKIP)
#
# Sub-gate entrypoint convention: gate_subgate_<name>()
# Sub-gate exit codes: 0 = PASS; non-zero = FAIL (propagated unchanged).
#
# Registration order determines display order within category. Categories run
# in fixed order: precondition first, regression second.

set -u

# Registry (parallel arrays).
GATE_NAMES=()
GATE_CATEGORIES=()
GATE_DESCRIPTIONS=()

# Per-run results (parallel arrays in execution order).
GATE_RESULT_NAMES=()
GATE_RESULT_EXITS=()
GATE_RESULT_DURATIONS=()
GATE_RESULT_DIAGNOSTICS=()

gate_register() {
    GATE_NAMES+=("$1")
    GATE_CATEGORIES+=("$2")
    GATE_DESCRIPTIONS+=("$3")
}

# gate_should_run <name> — honours --only / --skip. Strict mode ignores both.
gate_should_run() {
    name="$1"
    if [ "${GATE_STRICT:-0}" = "1" ]; then
        return 0
    fi
    if [ -n "${GATE_ONLY:-}" ]; then
        [ "$name" = "$GATE_ONLY" ] && return 0 || return 1
    fi
    if [ -n "${GATE_SKIP_LIST:-}" ]; then
        printf '%s\n' "$GATE_SKIP_LIST" | grep -Fxq "$name" && return 1
    fi
    return 0
}

# gate_run_one <name> — invoke a registered sub-gate. Captures BOTH stdout
# and stderr from the sub-gate into the per-run diagnostic file so the
# orchestrator owns the stdout/stderr contract (FR-009: gate writes nothing
# to stdout; per-sub-gate stderr is buffered and only emitted on FAIL).
gate_run_one() {
    name="$1"
    diag_file="$GATE_TEMP_ROOT/$name.log"
    : > "$diag_file"
    start_ms=$(date +%s%N 2>/dev/null || echo 0)
    if [ "$start_ms" = "0" ]; then
        # Arithmetic expansion $((...)) cannot word-split inner $(date +%s); false positive.
        # nosemgrep: bash.lang.correctness.unquoted-expansion.unquoted-command-substitution-in-command
        start_ms=$(($(date +%s) * 1000000000))
    fi
    rc=0
    # Subshell so a misbehaving sub-gate cannot leak globals or trip set -e on
    # our outer runner. Capture stdout+stderr both into the diag file.
    ( "gate_subgate_${name}" ) >"$diag_file" 2>&1 || rc=$?
    end_ms=$(date +%s%N 2>/dev/null || echo 0)
    if [ "$end_ms" = "0" ]; then
        # Arithmetic expansion $((...)) cannot word-split inner $(date +%s); false positive.
        # nosemgrep: bash.lang.correctness.unquoted-expansion.unquoted-command-substitution-in-command
        end_ms=$(($(date +%s) * 1000000000))
    fi
    dur_ms=$(( (end_ms - start_ms) / 1000000 ))
    GATE_RESULT_NAMES+=("$name")
    GATE_RESULT_EXITS+=("$rc")
    GATE_RESULT_DURATIONS+=("$dur_ms")
    GATE_RESULT_DIAGNOSTICS+=("$diag_file")
    return "$rc"
}

# gate_run_all — fail-all dispatcher.
# Returns the maximum of every executed sub-gate's exit code.
gate_run_all() {
    overall_rc=0
    total_start=$(date +%s)

    # Print header.
    version=$(cat "$GATE_CANDIDATE_TREE/VERSION" 2>/dev/null || echo "unknown")
    sha_short=$(git -C "$GATE_CANDIDATE_TREE" rev-parse --short HEAD 2>/dev/null || echo "unknown")
    printf 'pre-release-gate %s (candidate %s)\n' "$version" "$sha_short" >&2

    # Build the to-run list honouring --only/--skip, preserving registration
    # order, preconditions first.
    to_run=""
    for cat_filter in precondition regression; do
        i=0
        for n in "${GATE_NAMES[@]}"; do
            c="${GATE_CATEGORIES[$i]}"
            i=$((i + 1))
            [ "$c" = "$cat_filter" ] || continue
            gate_should_run "$n" || continue
            to_run="$to_run$n
"
        done
    done

    # Empty to_run is valid (e.g., --only <unknown> would have been caught by caller).
    n_running=$(printf '%s' "$to_run" | grep -c .)
    if [ "$n_running" -gt 0 ]; then
        printf 'running %d sub-gates: %s\n\n' "$n_running" "$(printf '%s' "$to_run" | tr '\n' ',' | sed 's/,$//;s/,/, /g')" >&2
    fi

    # Real run (sequential). Print progress + result inline per sub-gate.
    pass=0
    fail=0
    failing_list=""
    while IFS= read -r name; do
        [ -z "$name" ] && continue
        rc=0
        gate_run_one "$name" || rc=$?
        if [ "$rc" -gt "$overall_rc" ]; then
            overall_rc=$rc
        fi
        # Lookup the just-recorded duration + diag from the parallel arrays.
        last_idx=$((${#GATE_RESULT_NAMES[@]} - 1))
        dur="${GATE_RESULT_DURATIONS[$last_idx]}"
        diag="${GATE_RESULT_DIAGNOSTICS[$last_idx]}"
        sec=$(awk -v ms="$dur" 'BEGIN{printf "%.1f", ms/1000.0}')
        if [ "$rc" -eq 0 ]; then
            printf '[%s] PASS (%ss)\n' "$name" "$sec" >&2
            pass=$((pass + 1))
        else
            printf '[%s] FAIL (%ss)\n' "$name" "$sec" >&2
            if [ -s "$diag" ]; then
                sed 's/^/  /' "$diag" >&2
            fi
            fail=$((fail + 1))
            failing_list="$failing_list$name,"
        fi
    done <<EOF
$to_run
EOF

    total_end=$(date +%s)
    total_sec=$((total_end - total_start))

    if [ "$fail" -eq 0 ]; then
        printf '\nPASS  — %d/%d sub-gates green, total %ds\n' "$pass" "$((pass + fail))" "$total_sec" >&2
    else
        printf '\nFAIL  — %d/%d sub-gates green, %d failed, total %ds\n' \
            "$pass" "$((pass + fail))" "$fail" "$total_sec" >&2
        printf '  failing sub-gates: %s\n' "$(printf '%s' "$failing_list" | sed 's/,$//')" >&2
        printf '  rerun with --only <name> to iterate on one sub-gate\n' >&2
    fi

    return "$overall_rc"
}

# gate_help — emit --help output naming every registered sub-gate.
gate_help() {
    cat <<'USAGE'
Usage: scripts/pre-release-gate.sh [--only <subgate>] [--skip <subgate>...] [--help]

Runs every release-blocking sub-gate sequentially with fail-all semantics.
Exits 0 iff every executed sub-gate exited 0; otherwise exits non-zero
with a per-sub-gate detail block.

Flags:
  --only <subgate>   Run only the named sub-gate. Mutually exclusive with --skip.
  --skip <subgate>   Exclude one sub-gate (repeatable). Mutually exclusive with --only.
  --help             Print this help (including registered sub-gates) and exit 0.

USAGE
    printf 'Registered sub-gates:\n'
    i=0
    for n in "${GATE_NAMES[@]}"; do
        c="${GATE_CATEGORIES[$i]}"
        d="${GATE_DESCRIPTIONS[$i]}"
        printf '  %-22s  [%s]  %s\n' "$n" "$c" "$d"
        i=$((i + 1))
    done
}

# ----- Built-in sub-gates -----------------------------------------------------

# T009 — worktree-clean (precondition). FR-008.
# Fails if `git status --porcelain` against $GATE_CANDIDATE_TREE is non-empty,
# excluding tests/prompt-regression/results-*.md (generated on demand, not
# committed). docs/pm/token-ledger.md is now gitignored (#160) and no longer
# needs an explicit filter here.
gate_subgate_worktree-clean() {
    cd "$GATE_CANDIDATE_TREE" || return 1
    dirty=$(git status --porcelain 2>&1 \
        | grep -vE '^\?\? tests/prompt-regression/results-' \
        || true)
    if [ -z "$dirty" ]; then
        return 0
    fi
    printf 'worktree-clean: uncommitted changes / untracked files present:\n' >&2
    printf '%s\n' "$dirty" >&2
    return 1
}

# T014 — lint-contracts (regression). FR-004.
# Reuses scripts/lint-agent-contracts.sh --canonical-only; propagates exit.
gate_subgate_lint-contracts() {
    cd "$GATE_CANDIDATE_TREE" || return 1
    ./scripts/lint-agent-contracts.sh --canonical-only
}

# T015 — check-spdx (regression). FR-005.
# Reuses scripts/check-spdx.sh --summary; propagates exit.
gate_subgate_check-spdx() {
    cd "$GATE_CANDIDATE_TREE" || return 1
    ./scripts/check-spdx.sh --summary
}

# readme-current (regression). Added per customer ask 2026-05-14: README.md
# must be updated for every release. The gate enforces this by requiring
# that README.md either (a) literally contains the candidate's VERSION
# string, OR (b) has been modified since the most recent release tag
# reachable from HEAD. Either signal is taken as "the maintainer remembered."
gate_subgate_readme-current() {
    cd "$GATE_CANDIDATE_TREE" || return 1
    if [ ! -f README.md ]; then
        echo "readme-current: README.md missing"
        return 1
    fi
    version=$(cat VERSION 2>/dev/null)
    if [ -z "$version" ]; then
        echo "readme-current: VERSION file missing or empty"
        return 1
    fi
    # Signal (a): README mentions current VERSION.
    if grep -qF "$version" README.md; then
        return 0
    fi
    # Signal (b): README touched since most recent v* tag reachable from HEAD.
    last_tag=$(git describe --tags --abbrev=0 --match 'v*' HEAD 2>/dev/null)
    if [ -n "$last_tag" ]; then
        if git diff --name-only "$last_tag" -- README.md 2>/dev/null | grep -q '^README\.md$'; then
            return 0
        fi
    fi
    echo "readme-current: README.md neither mentions $version nor was modified since ${last_tag:-<no prior tag>}"
    echo "Update README.md with release notes / version stamp before tagging."
    return 1
}

# mirror-current (regression). Per spec 010 D-6: runs
# `scripts/strip-toc.sh --all --dry-run`, which walks every in-scope
# Markdown file and verifies every `<!-- TOC --> ... <!-- /TOC -->`
# fence pair parses without writing any mirror. Fails on unpaired
# fences (FATAL exit 2) or unreadable in-scope files. CI does not
# inspect the on-disk gitignored mirror; per-operator staleness is
# caught by the post-commit / post-checkout hooks (D-1, D-8).
gate_subgate_mirror-current() {
    cd "$GATE_CANDIDATE_TREE" || return 1
    if [ ! -x ./scripts/strip-toc.sh ]; then
        echo "mirror-current: scripts/strip-toc.sh missing or not executable" >&2
        return 1
    fi
    ./scripts/strip-toc.sh --all --dry-run --quiet
}

# version-stamp (precondition). Verifies that the VERSION file at HEAD
# exactly equals the intended tag name (the git-describe --exact-match
# output), with no pre-release suffix and no stale rc stamp.
#
# Rationale: v1.0.0 was tagged from a commit whose VERSION file still
# read "v1.0.0-rc15" — the release was published with a stale stamp.
# That tag is intentionally left immutable (customer ruling 2026-05-27).
# This gate exists to catch the same class of mismatch before any future
# tag is cut.  See docs/versioning.md § "Known issues" for the v1.0.0
# incident record.
#
# Pass condition: git describe --exact-match --tags HEAD produces a tag
# name that equals the content of VERSION (trimmed).
# Fail condition (at tag time): the two differ, or VERSION contains a
# pre-release suffix when the tag does not.
# Behaviour when HEAD is not at an exact tag: emits an advisory warning
# (not a failure) — the gate is meaningful only when called from the
# release-tagging workflow, i.e. when HEAD == intended release commit.
gate_subgate_version-stamp() {
    cd "$GATE_CANDIDATE_TREE" || return 1

    if [ ! -f VERSION ]; then
        echo "version-stamp: VERSION file missing"
        return 1
    fi
    version_file="$(cat VERSION | tr -d '[:space:]')"
    if [ -z "$version_file" ]; then
        echo "version-stamp: VERSION file is empty"
        return 1
    fi

    # Resolve the exact tag at HEAD, if any.
    exact_tag="$(git -C "$GATE_CANDIDATE_TREE" describe --exact-match --tags HEAD 2>/dev/null || true)"

    if [ -z "$exact_tag" ]; then
        # HEAD is not at an exact tag.  This is normal during development;
        # emit an advisory so the engineer knows the check was skipped, but
        # do not block — the gate is only meaningful at tag-cut time.
        echo "version-stamp: HEAD is not at an exact tag; skipping stamp check (advisory only)"
        echo "  VERSION=$version_file  HEAD=$(git -C "$GATE_CANDIDATE_TREE" rev-parse --short HEAD 2>/dev/null)"
        echo "  Before cutting a release tag, ensure VERSION equals the intended tag name."
        return 0
    fi

    # NIT-3: verify the tag is annotated, not lightweight.
    # git cat-file -t refs/tags/<name> returns "tag" for annotated objects,
    # "commit" for lightweight tags (which point directly at the commit).
    # Project policy (docs/versioning.md, rc tag procedure): lightweight tags
    # are not acceptable for public releases.
    tag_obj_type="$(git -C "$GATE_CANDIDATE_TREE" cat-file -t "refs/tags/$exact_tag" 2>/dev/null || true)"
    if [ "$tag_obj_type" != "tag" ]; then
        echo "version-stamp: LIGHTWEIGHT TAG — '$exact_tag' is not an annotated tag (cat-file returned '${tag_obj_type:-<unknown>}')"
        echo "  Public releases must use annotated tags: git tag -a $exact_tag -m '<message>'"
        echo "  Do NOT re-tag a published tag. If '$exact_tag' was already pushed, retract it"
        echo "  and cut a new annotated tag at the same commit."
        return 1
    fi

    if [ "$version_file" = "$exact_tag" ]; then
        echo "version-stamp: VERSION ($version_file) matches annotated tag ($exact_tag)"
        return 0
    fi

    # Mismatch: VERSION file does not match the tag that would be pushed.
    echo "version-stamp: MISMATCH — VERSION=$version_file  tag=$exact_tag"
    echo "  Bump VERSION to match the tag before pushing.  Do NOT tag first"
    echo "  and patch afterward — that leaves a published tag with a stale stamp."
    echo "  (Incident record: v1.0.0 was published with VERSION=v1.0.0-rc15;"
    echo "   that tag is intentionally immutable. See docs/versioning.md § Known issues.)"
    return 1
}

# ----- Registration -----------------------------------------------------------

gate_register worktree-clean   precondition  "Worktree clean against git status (FR-008)."
gate_register version-stamp    precondition  "VERSION file at HEAD matches the exact git tag (prevents stale-stamp releases; see v1.0.0 incident in docs/versioning.md)."
gate_register lint-contracts   regression    "Canonical agent contracts schema (FR-004)."
gate_register check-spdx       regression    "SPDX-License-Identifier headers (FR-005)."
gate_register readme-current   regression    "README.md mentions current VERSION or was modified since last v* tag (customer ask 2026-05-14)."
gate_register mirror-current   regression    "TOC fence pairs in in-scope Markdown sources parse cleanly (spec 010 D-6)."

# Sub-gates contributed by US2 / US3 are sourced from their dedicated libraries
# when those phases land; the source lines below are guarded so the file can
# still be sourced before those libraries exist.
if [ -f "${GATE_LIB_DIR:-$(dirname "$0")}/gate-tags.sh" ]; then
    # shellcheck disable=SC1090,SC1091
    . "${GATE_LIB_DIR:-$(dirname "$0")}/gate-tags.sh"
fi
if [ -f "${GATE_LIB_DIR:-$(dirname "$0")}/gate-advisory-scan.sh" ]; then
    # shellcheck disable=SC1090,SC1091
    . "${GATE_LIB_DIR:-$(dirname "$0")}/gate-advisory-scan.sh"
fi
if [ -f "${GATE_LIB_DIR:-$(dirname "$0")}/gate-migrations.sh" ]; then
    # shellcheck disable=SC1090,SC1091
    . "${GATE_LIB_DIR:-$(dirname "$0")}/gate-migrations.sh"
fi
if [ -f "${GATE_LIB_DIR:-$(dirname "$0")}/gate-hook-negative-corpus.sh" ]; then
    # shellcheck disable=SC1090,SC1091
    . "${GATE_LIB_DIR:-$(dirname "$0")}/gate-hook-negative-corpus.sh"
fi
