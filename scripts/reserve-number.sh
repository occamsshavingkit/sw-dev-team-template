#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# scripts/reserve-number.sh — claim-first numbering reservation helper
#   (specs/015-claim-first-numbering/, contracts/reservation-helper.md)
#
# Usage:
#   scripts/reserve-number.sh <artifact-type> [--slug <s>] [--title <t>] [--dry-run]
#
# artifact-type: adr | spec | open-question | decision
#
# Behavior:
#   1. Compute next(family) = max(existing numbered artifacts, including reserved stubs) + 1
#   2. --dry-run: print "family NNNN <would-be-path>" and exit 0, write nothing (I7/FR-013)
#   3. Otherwise: write the claiming stub, print "family NNNN <path>", exit 0
#   4. Exit nonzero: unknown type, or would-overwrite an existing file (I2/FR-006)
#
# PROJECT_ROOT env var: override repo root (used by tests; default = script's repo root).

set -euo pipefail

# ---------------------------------------------------------------------------
# Resolve repo root
# ---------------------------------------------------------------------------
if [[ -n "${PROJECT_ROOT:-}" ]]; then
    ROOT="$PROJECT_ROOT"
else
    ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fi

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
ARTIFACT_TYPE=""
SLUG=""
TITLE=""
DRY_RUN=0

if [[ $# -eq 0 ]]; then
    printf 'Usage: %s <artifact-type> [--slug <s>] [--title <t>] [--dry-run]\n' "$0" >&2
    exit 1
fi

ARTIFACT_TYPE="$1"
shift

while [[ $# -gt 0 ]]; do
    case "$1" in
        --slug)
            [[ $# -ge 2 ]] || { printf 'ERROR: --slug requires a value\n' >&2; exit 1; }
            SLUG="$2"
            shift 2
            ;;
        --title)
            [[ $# -ge 2 ]] || { printf 'ERROR: --title requires a value\n' >&2; exit 1; }
            TITLE="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        *)
            printf 'ERROR: unknown option: %s\n' "$1" >&2
            exit 1
            ;;
    esac
done

# ---------------------------------------------------------------------------
# Helper: zero-pad a number to N digits
# ---------------------------------------------------------------------------
pad() {
    local num="$1" width="$2"
    printf "%0${width}d" "$num"
}

# ---------------------------------------------------------------------------
# Dispatch by artifact type
# ---------------------------------------------------------------------------
case "$ARTIFACT_TYPE" in

    # -----------------------------------------------------------------------
    adr)
        ADR_DIR="$ROOT/docs/adr"
        WIDTH=4
        SLUG="${SLUG:-reserved-placeholder}"
        TITLE="${TITLE:-Reserved placeholder}"

        # Compute next number: scan fw-adr-NNNN-*.md filenames
        max=0
        if [[ -d "$ADR_DIR" ]]; then
            while IFS= read -r fname; do
                base="$(basename "$fname")"
                # Extract the 4-digit number from fw-adr-NNNN-...
                if [[ "$base" =~ ^fw-adr-([0-9]{4})- ]]; then
                    n="${BASH_REMATCH[1]}"
                    # Strip leading zeros for arithmetic
                    n_dec=$((10#$n))
                    if [[ $n_dec -gt $max ]]; then
                        max=$n_dec
                    fi
                fi
            done < <(find "$ADR_DIR" -maxdepth 1 -name 'fw-adr-[0-9][0-9][0-9][0-9]-*.md' 2>/dev/null)
        fi

        next=$((max + 1))
        num="$(pad "$next" "$WIDTH")"
        stub_path="$ADR_DIR/fw-adr-${num}-${SLUG}.md"
        rel_path="docs/adr/fw-adr-${num}-${SLUG}.md"

        if [[ "$DRY_RUN" -eq 1 ]]; then
            printf 'adr %s %s\n' "$num" "$rel_path"
            exit 0
        fi

        # No-overwrite guard (I2/FR-006)
        if [[ -e "$stub_path" ]]; then
            printf 'ERROR: would overwrite existing file: %s\n' "$stub_path" >&2
            exit 1
        fi

        # Dir may not exist yet (empty family → max=0 → first number); mkdir is intentional.
        mkdir -p "$ADR_DIR"
        printf -- '---\nstatus: reserved\ntitle: "%s"\n---\n\n# %s\n\n(Reserved — fill in at authoring time.)\n' \
            "$TITLE" "$TITLE" > "$stub_path"

        printf 'adr %s %s\n' "$num" "$rel_path"
        exit 0
        ;;

    # -----------------------------------------------------------------------
    spec)
        SPECS_DIR="$ROOT/specs"
        WIDTH=3
        SLUG="${SLUG:-reserved-placeholder}"
        TITLE="${TITLE:-Reserved placeholder}"

        # Compute next number: scan specs/NNN-* directory names
        max=0
        if [[ -d "$SPECS_DIR" ]]; then
            while IFS= read -r dname; do
                base="$(basename "$dname")"
                # Extract the 3-digit number from NNN-...
                if [[ "$base" =~ ^([0-9]{3})- ]]; then
                    n="${BASH_REMATCH[1]}"
                    n_dec=$((10#$n))
                    if [[ $n_dec -gt $max ]]; then
                        max=$n_dec
                    fi
                fi
            done < <(find "$SPECS_DIR" -maxdepth 1 -mindepth 1 -type d -name '[0-9][0-9][0-9]-*' 2>/dev/null)
        fi

        next=$((max + 1))
        num="$(pad "$next" "$WIDTH")"
        spec_dir="$SPECS_DIR/${num}-${SLUG}"
        stub_path="$spec_dir/spec.md"
        rel_path="specs/${num}-${SLUG}/spec.md"

        if [[ "$DRY_RUN" -eq 1 ]]; then
            printf 'spec %s %s\n' "$num" "$rel_path"
            exit 0
        fi

        # No-overwrite guard — check both the directory and the stub file
        if [[ -e "$spec_dir" || -e "$stub_path" ]]; then
            printf 'ERROR: would overwrite existing path: %s\n' "$spec_dir" >&2
            exit 1
        fi

        mkdir -p "$spec_dir"
        printf 'Status: Reserved\n\n# %s\n\n(Reserved — fill in at authoring time.)\n' \
            "$TITLE" > "$stub_path"

        printf 'spec %s %s\n' "$num" "$rel_path"
        exit 0
        ;;

    # -----------------------------------------------------------------------
    open-question)
        OQ_FILE="$ROOT/docs/OPEN_QUESTIONS.md"
        OQ_DIR="$ROOT/docs"
        WIDTH=4

        # Malformed-register guard: file must exist
        if [[ ! -f "$OQ_FILE" ]]; then
            printf 'ERROR: register not found: %s\n' "$OQ_FILE" >&2
            exit 1
        fi

        # Compute next number: scan Q-NNNN IDs across the active file,
        # all quarter shards (OPEN_QUESTIONS-YYYY-QN.md), and any legacy
        # archive (OPEN_QUESTIONS-ARCHIVE.md). Glob covers all of them.
        # This prevents ID reuse across shards (fw-adr-0025 cross-shard
        # correctness requirement).
        max=0
        while IFS= read -r scan_file; do
            [[ -f "$scan_file" ]] || continue
            while IFS= read -r line; do
                if [[ "$line" =~ Q-([0-9]{4}) ]]; then
                    n="${BASH_REMATCH[1]}"
                    n_dec=$((10#$n))
                    if [[ $n_dec -gt $max ]]; then
                        max=$n_dec
                    fi
                fi
            done < "$scan_file"
        done < <(
            printf '%s\n' "$OQ_FILE"
            find "$OQ_DIR" -maxdepth 1 \
                -name 'OPEN_QUESTIONS-[0-9][0-9][0-9][0-9]-Q[1-4].md' \
                -o -name 'OPEN_QUESTIONS-ARCHIVE.md' \
                2>/dev/null | sort
        )

        next=$((max + 1))
        num="$(pad "$next" "$WIDTH")"

        if [[ "$DRY_RUN" -eq 1 ]]; then
            printf 'open-question %s docs/OPEN_QUESTIONS.md\n' "Q-${num}"
            exit 0
        fi

        # Append a reserved row — no customer-facing question (lint-clean)
        printf '| Q-%s | reserved | (reserved) | — | — | reserved | — |\n' \
            "$num" >> "$OQ_FILE"

        printf 'open-question Q-%s docs/OPEN_QUESTIONS.md\n' "$num"
        exit 0
        ;;

    # -----------------------------------------------------------------------
    decision)
        DEC_FILE="$ROOT/docs/DECISIONS.md"
        WIDTH=4

        # Malformed-register guard: file must exist
        if [[ ! -f "$DEC_FILE" ]]; then
            printf 'ERROR: register not found: %s\n' "$DEC_FILE" >&2
            exit 1
        fi

        # Compute next number: scan ## D-NNNN headings
        max=0
        while IFS= read -r line; do
            if [[ "$line" =~ ^##[[:space:]]+D-([0-9]{4}) ]]; then
                n="${BASH_REMATCH[1]}"
                n_dec=$((10#$n))
                if [[ $n_dec -gt $max ]]; then
                    max=$n_dec
                fi
            fi
        done < "$DEC_FILE"

        next=$((max + 1))
        num="$(pad "$next" "$WIDTH")"
        TODAY="$(date +%Y-%m-%d)"

        if [[ "$DRY_RUN" -eq 1 ]]; then
            printf 'decision D-%s docs/DECISIONS.md\n' "$num"
            exit 0
        fi

        # Append a reserved entry matching the ## D-NNNN heading format (append-only)
        printf '\n## D-%s — %s — reserved\n\n**Who decided:** reserved\n**Options considered:** —\n**Chose:** —\n**Why:** —\n**Files touched:** —\n**Customer visibility:** —\n**Supersedes:** —\n**Notes:** reserved (claim-first placeholder)\n' \
            "$num" "$TODAY" >> "$DEC_FILE"

        printf 'decision D-%s docs/DECISIONS.md\n' "$num"
        exit 0
        ;;

    # -----------------------------------------------------------------------
    *)
        printf 'ERROR: unknown artifact type: %s\n' "$ARTIFACT_TYPE" >&2
        printf 'Supported: adr | spec | open-question | decision\n' >&2
        exit 1
        ;;
esac
