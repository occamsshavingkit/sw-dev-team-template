#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# scripts/check-duplicate-ids.sh — CI backstop for duplicate numbered IDs
#   (issue #294, ruling Q-0029)
#
# Checks all four ID families for duplicate numbers. Exits nonzero and lists
# any collisions; exits 0 when clean.
#
# ID families (conventions match scripts/reserve-number.sh exactly):
#   adr          docs/adr/fw-adr-NNNN-*.md             4-digit number
#   spec         specs/NNN-*/                           3-digit number
#   open-question docs/OPEN_QUESTIONS.md Q-NNNN rows   4-digit number
#   decision     docs/DECISIONS.md ## D-NNNN headings  4-digit number
#
# Usage:
#   scripts/check-duplicate-ids.sh
#   scripts/check-duplicate-ids.sh --summary
#
# PROJECT_ROOT env var: override repo root (used by tests; default = script's
# repo root, same convention as reserve-number.sh).

set -euo pipefail

LANG=C
LC_ALL=C
export LANG LC_ALL

# ---------------------------------------------------------------------------
# Resolve repo root
# ---------------------------------------------------------------------------
if [[ -n "${PROJECT_ROOT:-}" ]]; then
    ROOT="$PROJECT_ROOT"
else
    ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fi

SUMMARY=0
for arg in "$@"; do
    case "$arg" in
        --summary) SUMMARY=1 ;;
        *)
            printf 'check-duplicate-ids.sh: unknown argument: %s\n' "$arg" >&2
            printf 'usage: check-duplicate-ids.sh [--summary]\n' >&2
            exit 2
            ;;
    esac
done

collisions=0

# ---------------------------------------------------------------------------
# ADR family — docs/adr/fw-adr-NNNN-*.md
# Convention: 4-digit zero-padded number extracted from filename.
# ---------------------------------------------------------------------------
ADR_DIR="$ROOT/docs/adr"
adr_nums=()
if [[ -d "$ADR_DIR" ]]; then
    while IFS= read -r fname; do
        base="$(basename "$fname")"
        if [[ "$base" =~ ^fw-adr-([0-9]{4})- ]]; then
            adr_nums+=("${BASH_REMATCH[1]}")
        fi
    done < <(find "$ADR_DIR" -maxdepth 1 -name 'fw-adr-[0-9][0-9][0-9][0-9]-*.md' 2>/dev/null | sort)
fi

adr_dupes=""
if [[ ${#adr_nums[@]} -gt 0 ]]; then
    adr_dupes=$(printf '%s\n' "${adr_nums[@]}" | sort | uniq -d)
fi
if [[ -n "$adr_dupes" ]]; then
    printf 'DUPLICATE ADR IDs:\n'
    while IFS= read -r num; do
        occ=$(printf '%s\n' "${adr_nums[@]}" | grep -cxF "$num" || true)
        printf '  adr: fw-adr-%s (found %s files)\n' "$num" "$occ"
    done <<< "$adr_dupes"
    collisions=$((collisions + 1))
fi

# ---------------------------------------------------------------------------
# Spec family — specs/NNN-* directories
# Convention: 3-digit zero-padded number extracted from directory name.
# ---------------------------------------------------------------------------
SPECS_DIR="$ROOT/specs"
spec_nums=()
if [[ -d "$SPECS_DIR" ]]; then
    while IFS= read -r dname; do
        base="$(basename "$dname")"
        if [[ "$base" =~ ^([0-9]{3})- ]]; then
            spec_nums+=("${BASH_REMATCH[1]}")
        fi
    done < <(find "$SPECS_DIR" -maxdepth 1 -mindepth 1 -type d -name '[0-9][0-9][0-9]-*' 2>/dev/null | sort)
fi

spec_dupes=""
if [[ ${#spec_nums[@]} -gt 0 ]]; then
    spec_dupes=$(printf '%s\n' "${spec_nums[@]}" | sort | uniq -d)
fi
if [[ -n "$spec_dupes" ]]; then
    printf 'DUPLICATE spec IDs:\n'
    while IFS= read -r num; do
        occ=$(printf '%s\n' "${spec_nums[@]}" | grep -cxF "$num" || true)
        printf '  spec: %s (found %s directories)\n' "$num" "$occ"
    done <<< "$spec_dupes"
    collisions=$((collisions + 1))
fi

# ---------------------------------------------------------------------------
# Open-question family — docs/OPEN_QUESTIONS.md, Q-NNNN IDs
# Convention: 4-digit zero-padded number, prefix Q-.
# ---------------------------------------------------------------------------
OQ_FILE="$ROOT/docs/OPEN_QUESTIONS.md"
oq_nums=()
if [[ -f "$OQ_FILE" ]]; then
    while IFS= read -r line; do
        # Match only the FIRST Q-NNNN on each line (the canonical ID cell).
        # Additional Q-NNNN tokens on the same line (e.g. anchor hrefs like
        # "#row-Q-0001") are back-references, not new IDs; counting them
        # would produce false duplicate reports.
        if [[ "$line" =~ Q-([0-9]{4}) ]]; then
            oq_nums+=("${BASH_REMATCH[1]}")
        fi
    done < "$OQ_FILE"
fi

oq_dupes=""
if [[ ${#oq_nums[@]} -gt 0 ]]; then
    oq_dupes=$(printf '%s\n' "${oq_nums[@]}" | sort | uniq -d)
fi
if [[ -n "$oq_dupes" ]]; then
    printf 'DUPLICATE open-question IDs:\n'
    while IFS= read -r num; do
        occ=$(printf '%s\n' "${oq_nums[@]}" | grep -cxF "$num" || true)
        printf '  open-question: Q-%s (found %s occurrences)\n' "$num" "$occ"
    done <<< "$oq_dupes"
    collisions=$((collisions + 1))
fi

# ---------------------------------------------------------------------------
# Decision family — docs/DECISIONS.md, ## D-NNNN headings
# Convention: 4-digit zero-padded number, matched on ^## D-NNNN heading lines
# (consistent with reserve-number.sh which matches ^##[[:space:]]+D-NNNN).
# ---------------------------------------------------------------------------
DEC_FILE="$ROOT/docs/DECISIONS.md"
dec_nums=()
if [[ -f "$DEC_FILE" ]]; then
    while IFS= read -r line; do
        if [[ "$line" =~ ^##[[:space:]]+D-([0-9]{4}) ]]; then
            dec_nums+=("${BASH_REMATCH[1]}")
        fi
    done < "$DEC_FILE"
fi

dec_dupes=""
if [[ ${#dec_nums[@]} -gt 0 ]]; then
    dec_dupes=$(printf '%s\n' "${dec_nums[@]}" | sort | uniq -d)
fi
if [[ -n "$dec_dupes" ]]; then
    printf 'DUPLICATE decision IDs:\n'
    while IFS= read -r num; do
        occ=$(printf '%s\n' "${dec_nums[@]}" | grep -cxF "$num" || true)
        printf '  decision: D-%s (found %s headings)\n' "$num" "$occ"
    done <<< "$dec_dupes"
    collisions=$((collisions + 1))
fi

# ---------------------------------------------------------------------------
# Summary and exit
# ---------------------------------------------------------------------------
if [[ "$SUMMARY" -eq 1 ]]; then
    total_ids=$(( ${#adr_nums[@]} + ${#spec_nums[@]} + ${#oq_nums[@]} + ${#dec_nums[@]} ))
    printf 'check-duplicate-ids: %s IDs scanned, %s collision families found\n' \
        "$total_ids" "$collisions"
fi

if [[ "$collisions" -gt 0 ]]; then
    exit 1
fi
exit 0
