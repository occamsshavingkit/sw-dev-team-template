#!/usr/bin/env bash
#
# migrations/<VERSION>.sh — template.
#
# Copy this file to migrations/<target-version>.sh and fill in the
# transformations needed when upgrading TO that version.
#
# Env vars from scripts/upgrade.sh:
#   PROJECT_ROOT   — absolute path to the downstream project root
#   OLD_VERSION    — version the project is coming from
#   NEW_VERSION    — version the project is going to
#   TARGET_VERSION — this migration's attached version
#   WORKDIR_NEW    — clone of upstream at NEW_VERSION
#   WORKDIR_OLD    — clone of upstream at OLD_VERSION (optional)
#
# Requirements:
#   - idempotent (safe to re-run)
#   - no network
#   - do not touch user-added agents (sme-<domain>.md) or docs/pm/*.md
#   - print a one-line summary per action to stdout

set -euo pipefail

: "${PROJECT_ROOT:?PROJECT_ROOT is required}"

# ---- Example: rename a file that was moved in this release ------------------
# if [[ -f "$PROJECT_ROOT/docs/OLD_NAME.md" && ! -f "$PROJECT_ROOT/docs/new/NEW_NAME.md" ]]; then
#   mkdir -p "$PROJECT_ROOT/docs/new"
#   mv "$PROJECT_ROOT/docs/OLD_NAME.md" "$PROJECT_ROOT/docs/new/NEW_NAME.md"
#   echo "  rename: docs/OLD_NAME.md → docs/new/NEW_NAME.md"
# fi

# ---- Example: split a single file into two ---------------------------------
# if [[ -f "$PROJECT_ROOT/docs/COMBINED.md" && ! -f "$PROJECT_ROOT/docs/PART_A.md" ]]; then
#   # extract part A (bash-portable; sed/awk as appropriate)
#   awk '/^## Part A/,/^## Part B/' "$PROJECT_ROOT/docs/COMBINED.md" > "$PROJECT_ROOT/docs/PART_A.md"
#   awk '/^## Part B/,0' "$PROJECT_ROOT/docs/COMBINED.md" > "$PROJECT_ROOT/docs/PART_B.md"
#   rm "$PROJECT_ROOT/docs/COMBINED.md"
#   echo "  split: docs/COMBINED.md → docs/{PART_A,PART_B}.md"
# fi

# ---- Example: rewrite a line inside a file, idempotently --------------------
# file="$PROJECT_ROOT/CLAUDE.md"
# if [[ -f "$file" ]] && grep -q '^OLD_RULE$' "$file"; then
#   sed -i 's|^OLD_RULE$|NEW_RULE|' "$file"
#   echo "  rewrote OLD_RULE → NEW_RULE in CLAUDE.md"
# fi

echo "  (no migration actions required for this version)"
