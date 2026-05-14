#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# scripts/pre-release-gate.sh — pre-release upgrade-regression gate
# orchestrator entrypoint.
#
# Spec:      specs/007-pre-release-upgrade/spec.md
# Contracts: specs/007-pre-release-upgrade/contracts/pre-release-gate.cli.md
# Plan:      specs/007-pre-release-upgrade/plan.md
#
# Runs every registered sub-gate against the candidate tree at HEAD with
# fail-all semantics (FR-001). Exits 0 iff every executed sub-gate exited 0
# (FR-002). On FAIL emits a per-sub-gate detail block (FR-009). Honours
# --only / --skip for iteration (R-2); the pre-push hook in strict mode
# ignores both (R-2 / FR-011).

set -u

# Resolve script dir and source the runner library.
script_dir="$(cd "$(dirname "$0")" && pwd)"
candidate_tree="$(cd "$script_dir/.." && pwd)"

GATE_LIB_DIR="$script_dir/lib"
export GATE_LIB_DIR
# shellcheck disable=SC1091
. "$GATE_LIB_DIR/gate-runner.sh"

# ----- Flag parsing -----------------------------------------------------------

GATE_ONLY=""
GATE_SKIP_LIST=""
show_help=0

while [ "$#" -gt 0 ]; do
    case "$1" in
        --help|-h)
            show_help=1
            shift
            ;;
        --only)
            [ -z "${2:-}" ] && { echo "pre-release-gate: --only requires a sub-gate name" >&2; exit 2; }
            GATE_ONLY="$2"
            shift 2
            ;;
        --only=*)
            GATE_ONLY="${1#--only=}"
            shift
            ;;
        --skip)
            [ -z "${2:-}" ] && { echo "pre-release-gate: --skip requires a sub-gate name" >&2; exit 2; }
            GATE_SKIP_LIST="$GATE_SKIP_LIST$2
"
            shift 2
            ;;
        --skip=*)
            GATE_SKIP_LIST="$GATE_SKIP_LIST${1#--skip=}
"
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "pre-release-gate: unknown flag: $1" >&2
            echo "Run with --help for usage." >&2
            exit 2
            ;;
    esac
done

if [ "$show_help" -eq 1 ]; then
    gate_help
    exit 0
fi

# Mutual exclusion of --only and --skip.
if [ -n "$GATE_ONLY" ] && [ -n "$GATE_SKIP_LIST" ]; then
    echo "pre-release-gate: --only and --skip are mutually exclusive (exit 2)" >&2
    exit 2
fi

# Validate --only names a registered sub-gate.
if [ -n "$GATE_ONLY" ]; then
    found=0
    for n in "${GATE_NAMES[@]}"; do
        [ "$n" = "$GATE_ONLY" ] && { found=1; break; }
    done
    if [ "$found" -eq 0 ]; then
        echo "pre-release-gate: --only '$GATE_ONLY' is not a registered sub-gate" >&2
        printf 'Known sub-gates: %s\n' "$(IFS=,; printf '%s' "${GATE_NAMES[*]}")" >&2
        exit 2
    fi
fi

# Validate --skip names are all registered.
if [ -n "$GATE_SKIP_LIST" ]; then
    printf '%s' "$GATE_SKIP_LIST" | while IFS= read -r skipname; do
        [ -z "$skipname" ] && continue
        found=0
        for n in "${GATE_NAMES[@]}"; do
            [ "$n" = "$skipname" ] && { found=1; break; }
        done
        if [ "$found" -eq 0 ]; then
            echo "pre-release-gate: --skip '$skipname' is not a registered sub-gate" >&2
            exit 2
        fi
    done || exit 2
fi

# ----- Run-time setup ---------------------------------------------------------

GATE_CANDIDATE_TREE="$candidate_tree"
GATE_TEMP_ROOT="$(mktemp -d -t pre-release-gate.XXXXXX)"
GATE_FIXTURES_DIR="$candidate_tree/tests/release-gate/fixtures"
export GATE_CANDIDATE_TREE GATE_TEMP_ROOT GATE_FIXTURES_DIR GATE_ONLY GATE_SKIP_LIST

# Always clean up the tempdir on exit, including on FAIL.
trap 'rm -rf "$GATE_TEMP_ROOT"' EXIT

# Dispatch.
gate_run_all
exit "$?"
