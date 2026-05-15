#!/usr/bin/env bash
#
# migrations/v1.0.0-rc14.sh — upgrade TO v1.0.0-rc14.
#
# FW-ADR-0014 opt-in pruning migration. The preservation-vs-manifest
# gate (landed in rc14 via FW-ADR-0014) silently drops inert
# preserve-list entries from the in-memory preserve set at sync time
# — but it does NOT rewrite .template-customizations. This migration
# is the only writer that prunes the on-disk file.
#
# Two-pass shape:
#
#   Pass 1 (default — dry-run). Walks .template-customizations and
#   prints the list of entries that match the upstream baseline
#   byte-for-byte (no divergence) and are therefore inert. No file is
#   rewritten. Operator inspects the list.
#
#   Pass 2 (apply). Operator re-runs with SWDT_PRESERVATION_PRUNE_APPLY=1
#   in the environment. Rewrites .template-customizations atomically
#   (mktemp + mv), removing the inert lines, preserving comments,
#   blank lines, and entries that diverge from baseline or whose
#   baseline is unreachable (conservative — keep what we cannot prove
#   inert).
#
# Idempotent. Re-running after a successful apply pass is a no-op
# because all remaining entries diverge (or baseline-unreachable
# entries are conservatively kept).
#
# Env vars from scripts/upgrade.sh:
#   PROJECT_ROOT                       — absolute path to project root
#   WORKDIR_NEW                        — clone of upstream at NEW_VERSION
#   WORKDIR_OLD                        — clone of upstream at baseline
#                                        SHA (set when reachable)
#   SWDT_PRESERVATION_PRUNE_APPLY=1    — opt-in: apply the rewrite
#                                        instead of dry-run-printing.

set -u
LANG=C
LC_ALL=C
export LANG LC_ALL

: "${PROJECT_ROOT:?PROJECT_ROOT is required}"

cust="$PROJECT_ROOT/.template-customizations"
if [ ! -f "$cust" ]; then
  echo "  v1.0.0-rc14 prune: no .template-customizations file; nothing to do."
  exit 0
fi

# Baseline reachable? Without WORKDIR_OLD we cannot prove inertness;
# conservative posture: skip the rewrite entirely and warn.
if [ -z "${WORKDIR_OLD:-}" ] || [ ! -d "${WORKDIR_OLD:-}" ]; then
  echo "  v1.0.0-rc14 prune: WORKDIR_OLD unset/unreachable — cannot compute" >&2
  echo "    divergence. Skipping. (Conservative posture: nothing pruned.)" >&2
  exit 0
fi

# Pass 1: identify inert entries.
inert_entries=()
while IFS= read -r raw; do
  trimmed="${raw%%#*}"
  trimmed="$(printf '%s' "$trimmed" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  [ -z "$trimmed" ] && continue
  proj="$PROJECT_ROOT/$trimmed"
  base="$WORKDIR_OLD/$trimmed"
  [ -f "$proj" ] || continue
  [ -f "$base" ] || continue
  if cmp -s "$base" "$proj"; then
    inert_entries+=("$trimmed")
  fi
done < "$cust"

if [ ${#inert_entries[@]} -eq 0 ]; then
  echo "  v1.0.0-rc14 prune: no inert preserve-list entries found; nothing to do."
  exit 0
fi

# Dry-run by default.
if [ "${SWDT_PRESERVATION_PRUNE_APPLY:-}" != "1" ]; then
  echo "  v1.0.0-rc14 prune (dry-run): ${#inert_entries[@]} inert entry/entries identified:"
  for e in "${inert_entries[@]}"; do
    echo "    - $e"
  done
  echo "  To rewrite .template-customizations, re-run with:"
  echo "    SWDT_PRESERVATION_PRUNE_APPLY=1 scripts/upgrade.sh ..."
  exit 0
fi

# Apply pass. Build the new file: keep comments, blanks, and any line
# whose trimmed value is not in the inert set. Rewrite atomically.
tmp="$(mktemp "$cust.tmp.XXXXXX")"
while IFS= read -r raw; do
  trimmed="${raw%%#*}"
  trimmed="$(printf '%s' "$trimmed" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  if [ -z "$trimmed" ]; then
    # Comment-only or blank line — keep verbatim.
    printf '%s\n' "$raw" >> "$tmp"
    continue
  fi
  drop=0
  for inert in "${inert_entries[@]}"; do
    if [ "$inert" = "$trimmed" ]; then
      drop=1
      break
    fi
  done
  if [ "$drop" -eq 0 ]; then
    printf '%s\n' "$raw" >> "$tmp"
  fi
done < "$cust"
mv "$tmp" "$cust"

echo "  v1.0.0-rc14 prune (apply): rewrote .template-customizations, dropping ${#inert_entries[@]} inert entry/entries."
for e in "${inert_entries[@]}"; do
  echo "    - $e"
done
