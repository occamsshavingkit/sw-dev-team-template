#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# scripts/gen-register-index.sh — generate <register>-INDEX.md for a register
#   (fw-adr-0025 Option S, issue #295)
#
# For a given register file (e.g. docs/OPEN_QUESTIONS.md), scans:
#   - The active file itself
#   - All quarter shards: <stem>-YYYY-QN.md  (e.g. docs/OPEN_QUESTIONS-2026-Q1.md)
#   - All legacy archives: <stem>-ARCHIVE.md (e.g. docs/OPEN_QUESTIONS-ARCHIVE.md)
# and emits <stem>-INDEX.md: a Markdown table listing each shard, its date
# range (earliest .. latest YYYY-MM-DD found), entry count, and notes.
#
# Usage:
#   scripts/gen-register-index.sh <register-path> [--root PATH] [--dry-run]
#
# <register-path> is project-relative (e.g. docs/OPEN_QUESTIONS.md).
# Idempotent: re-running overwrites the INDEX with fresh data.
#
# PROJECT_ROOT env var (or --root): override repo root.

set -euo pipefail

LANG=C
LC_ALL=C
export LANG LC_ALL

PROG="gen-register-index.sh"

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
REGISTER_REL=""
ROOT=""
DRY_RUN=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --root)
            [[ $# -ge 2 ]] || { printf '%s: --root requires a value\n' "$PROG" >&2; exit 2; }
            ROOT="$2"; shift 2 ;;
        --root=*)
            ROOT="${1#--root=}"; shift ;;
        --dry-run)
            DRY_RUN=1; shift ;;
        -h|--help)
            grep '^#' "$0" | head -30 | sed 's/^# \{0,2\}//'
            exit 0 ;;
        -*)
            printf '%s: unknown flag: %s\n' "$PROG" "$1" >&2; exit 2 ;;
        *)
            if [[ -z "$REGISTER_REL" ]]; then
                REGISTER_REL="$1"; shift
            else
                printf '%s: unexpected argument: %s\n' "$PROG" "$1" >&2; exit 2
            fi ;;
    esac
done

if [[ -z "$REGISTER_REL" ]]; then
    printf '%s: usage: gen-register-index.sh <register-path> [--root PATH] [--dry-run]\n' "$PROG" >&2
    exit 2
fi

# ---------------------------------------------------------------------------
# Resolve root
# ---------------------------------------------------------------------------
if [[ -z "$ROOT" ]]; then
    if [[ -n "${PROJECT_ROOT:-}" ]]; then
        ROOT="$PROJECT_ROOT"
    else
        ROOT="$(cd "$(dirname "$0")/.." && pwd)"
    fi
fi

[[ -d "$ROOT" ]] || { printf '%s: root not a directory: %s\n' "$PROG" "$ROOT" >&2; exit 2; }

# Strip leading ./ from the register path for consistent key construction.
REGISTER_REL="${REGISTER_REL#./}"

REGISTER_ABS="$ROOT/$REGISTER_REL"
REGISTER_DIR="$(dirname "$REGISTER_ABS")"
REGISTER_BASE="$(basename "$REGISTER_REL" .md)"

# The index lives at <dir>/<base>-INDEX.md
INDEX_ABS="$REGISTER_DIR/${REGISTER_BASE}-INDEX.md"
INDEX_REL="$(dirname "$REGISTER_REL")/${REGISTER_BASE}-INDEX.md"

# ---------------------------------------------------------------------------
# Date helpers
# ---------------------------------------------------------------------------

# Extract the first YYYY-MM-DD date from a line (returns empty if none).
# awk is used inline; this function just for documentation.

# ---------------------------------------------------------------------------
# Collect shards in order: active file, quarter shards, legacy archives.
# ---------------------------------------------------------------------------

# Build shard list: active + YYYY-QN shards + ARCHIVE, sorted.
collect_shards() {
    local dir="$1"
    local base="$2"

    # Active file (always first if it exists).
    local active="$dir/${base}.md"
    if [[ -f "$active" ]]; then
        printf '%s\n' "$active"
    fi

    # Quarter shards: <base>-YYYY-QN.md — sorted lexically (year then quarter).
    local shard
    while IFS= read -r shard; do
        [[ -f "$shard" ]] && printf '%s\n' "$shard"
    done < <(find "$dir" -maxdepth 1 -name "${base}-[0-9][0-9][0-9][0-9]-Q[1-4].md" 2>/dev/null | sort)

    # Legacy archives: <base>-ARCHIVE.md
    local arch="$dir/${base}-ARCHIVE.md"
    if [[ -f "$arch" ]]; then
        printf '%s\n' "$arch"
    fi
}

# ---------------------------------------------------------------------------
# Count entries and date-range for a shard file.
#
# "Entry count" definition per register shape:
#   - Table registers (OPEN_QUESTIONS, intake-log, RISKS, LESSONS table):
#     count data rows (lines starting with | that are not the header or ---|).
#   - CUSTOMER_NOTES: count ## YYYY-MM-DD sections.
#   - LESSONS journal: count ### YYYY-MM-DD entries.
#   - ARCHIVE files: same rules applied to their content.
#
# We use a pragmatic heuristic: count lines that contain a YYYY-MM-DD date
# AND start with either | (table row) or ## or ### (section heading).
# This avoids dependency on per-register shape knowledge and is conservative.
# ---------------------------------------------------------------------------
analyze_shard() {
    local f="$1"
    # Returns: <count> <earliest_date> <latest_date>
    awk '
        BEGIN { count=0; earliest=""; latest="" }
        /^[|#]/ {
            # Extract first YYYY-MM-DD from the line.
            s = $0
            while (match(s, /[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/)) {
                d = substr(s, RSTART, RLENGTH)
                count++
                if (earliest == "" || d < earliest) earliest = d
                if (latest == "" || d > latest) latest = d
                break  # one date per line for count
            }
        }
        END {
            printf "%d\t%s\t%s\n", count, earliest, latest
        }
    ' "$f"
}

# Label a shard file relative to ROOT for display.
label_shard() {
    local f="$1"
    local rel="${f#"$ROOT/"}"
    printf '%s' "$rel"
}

# Classify shard type for the Notes column.
classify_shard() {
    local f="$1"
    local base="$2"
    local name
    name="$(basename "$f" .md)"
    if [[ "$name" == "$base" ]]; then
        printf 'active (current quarter)'
    elif [[ "$name" =~ ^${base}-[0-9]{4}-Q[1-4]$ ]]; then
        local quarter="${name#"${base}-"}"
        printf 'quarter shard (%s)' "$quarter"
    elif [[ "$name" == "${base}-ARCHIVE" ]]; then
        printf 'legacy milestone archive'
    else
        printf 'shard'
    fi
}

# ---------------------------------------------------------------------------
# Build INDEX content
# ---------------------------------------------------------------------------
build_index() {
    local dir="$1"
    local base="$2"
    local register_rel="$3"

    printf '# %s — Index\n\n' "$base"
    printf 'Auto-generated by `scripts/gen-register-index.sh`. Do not edit manually.\n'
    printf 'Regenerate with: `scripts/gen-register-index.sh %s`\n\n' "$register_rel"
    printf '| Shard | Date range | Entry count | Notes |\n'
    printf '|---|---|---|---|\n'

    local shards
    shards="$(collect_shards "$dir" "$base")"

    if [[ -z "$shards" ]]; then
        printf '| (none) | — | — | No shards found |\n'
        return
    fi

    local total=0
    while IFS= read -r shard; do
        [[ -f "$shard" ]] || continue
        local label
        label="$(label_shard "$shard")"
        local stats
        stats="$(analyze_shard "$shard")"
        local count earliest latest
        count="$(printf '%s' "$stats" | cut -f1)"
        earliest="$(printf '%s' "$stats" | cut -f2)"
        latest="$(printf '%s' "$stats" | cut -f3)"

        local date_range="—"
        if [[ -n "$earliest" && -n "$latest" ]]; then
            if [[ "$earliest" == "$latest" ]]; then
                date_range="$earliest"
            else
                date_range="${earliest} .. ${latest}"
            fi
        fi

        local notes
        notes="$(classify_shard "$shard" "$base")"
        printf '| `%s` | %s | %s | %s |\n' "$label" "$date_range" "$count" "$notes"
        total=$((total + count))
    done <<< "$shards"

    printf '\n**Total entries across all shards:** %d\n' "$total"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
index_content="$(build_index "$REGISTER_DIR" "$REGISTER_BASE" "$REGISTER_REL")"

if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '%s\n' "$index_content"
    exit 0
fi

tmp="$(mktemp "${INDEX_ABS}.tmp.XXXXXX")"
printf '%s\n' "$index_content" > "$tmp"
mv "$tmp" "$INDEX_ABS"
printf '%s: wrote %s\n' "$PROG" "$INDEX_REL"
