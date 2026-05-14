#!/usr/bin/env bash
#
# migrations/v0.14.0.sh — upgrade TO v0.14.0 (or any v0.14.x).
#
# v0.14.0 introduces TEMPLATE_MANIFEST.lock (per FW-ADR-0002): a per-file
# SHA256 manifest at project root, used by `scripts/upgrade.sh
# --verify` for offline drift / tamper detection.
#
# This migration synthesises the manifest by **predicting the post-sync
# state** using the same 3-way compare upgrade.sh's sync loop performs.
# That way a single upgrade run produces a correct manifest regardless
# of the version of upgrade.sh the project starts with — including
# v0.13.x projects whose upgrade.sh has no post-sync manifest_write
# step.
#
# Prediction per file:
#   - file in WORKDIR_NEW but not in PROJECT_ROOT       → sync will
#     add it; predicted SHA = WORKDIR_NEW SHA.
#   - file in both, baseline available, project SHA ==
#     WORKDIR_OLD SHA (unchanged since scaffold)        → sync will
#     overwrite; predicted SHA = WORKDIR_NEW SHA.
#   - file in both, baseline available, project SHA !=
#     WORKDIR_OLD SHA (customisation since scaffold)    → sync will
#     leave alone (conflict / kept); predicted SHA =
#     project's current SHA.
#   - file in both, no baseline                          → conservative:
#     treat as customisation; predicted SHA = project's current SHA.
#
# After the actual sync, real on-disk SHAs match these predictions, so
# `scripts/upgrade.sh --verify` exits 0 even on projects whose
# upgrade.sh predates v0.14.0's post-sync manifest_write step.
# v0.14.x+ upgrade.sh's post-sync manifest_write rewrites the manifest
# with the real post-sync SHAs — same result, double-checked.
#
# Idempotency: if the manifest already exists, leave it alone.

set -euo pipefail

: "${PROJECT_ROOT:?PROJECT_ROOT is required}"
: "${WORKDIR_NEW:?WORKDIR_NEW is required}"

# Pre-bootstrap: atomic-replace project's scripts/upgrade.sh + scripts/lib/*
# with the candidate's versions BEFORE the calling v0.x upgrade.sh's sync
# loop runs. Pre-v0.15.0 upgrade.sh lacks self-bootstrap, so its sync loop
# would otherwise `cp` over scripts/upgrade.sh while bash is reading it —
# corrupting the running script and producing arbitrary crashes mid-loop
# (observed as `line N: y: command not found`-style errors picked up from
# the byte offset of a comment in the candidate). Atomic mv-rename leaves
# the parent bash's open fd on the original (now-unlinked) inode, so the
# running v0.x script reads its original content to EOF without seeing the
# replacement; the sync loop then sees cmp-equal between $new_path and
# $proj_path and skips the cp altogether.
#
# Idempotent: runs every time this migration runs, no harm if the files
# are already identical.
if [ -f "$WORKDIR_NEW/scripts/upgrade.sh" ] && [ -f "$PROJECT_ROOT/scripts/upgrade.sh" ]; then
    if ! cmp -s "$WORKDIR_NEW/scripts/upgrade.sh" "$PROJECT_ROOT/scripts/upgrade.sh"; then
        install -m 0755 "$WORKDIR_NEW/scripts/upgrade.sh" "$PROJECT_ROOT/scripts/upgrade.sh"
        echo "  pre-bootstrapped scripts/upgrade.sh to candidate (cross-MAJOR safe)"
    fi
fi
if [ -d "$WORKDIR_NEW/scripts/lib" ]; then
    mkdir -p "$PROJECT_ROOT/scripts/lib"
    for lib in "$WORKDIR_NEW/scripts/lib"/*.sh; do
        [ -f "$lib" ] || continue
        lib_name=$(basename "$lib")
        proj_lib="$PROJECT_ROOT/scripts/lib/$lib_name"
        if [ ! -f "$proj_lib" ] || ! cmp -s "$lib" "$proj_lib"; then
            # Preserve the source's mode bits (executable scripts stay
            # executable; sourced libs stay 0644) so candidate intent
            # carries through the bootstrap.
            if [ -x "$lib" ]; then
                install -m 0755 "$lib" "$proj_lib"
            else
                install -m 0644 "$lib" "$proj_lib"
            fi
        fi
    done
fi

manifest="$PROJECT_ROOT/TEMPLATE_MANIFEST.lock"

if [[ -f "$manifest" ]]; then
  echo "  TEMPLATE_MANIFEST.lock exists — leaving it (will be rewritten post-sync)"
  exit 0
fi

# v0.14.0 ships scripts/lib/manifest.sh; pre-v0.14.0 projects don't
# have it locally yet, so we source from the upgrade-time clone of
# upstream.
# shellcheck source=scripts/lib/manifest.sh
# shellcheck disable=SC1091
source "$WORKDIR_NEW/scripts/lib/manifest.sh"

# Collect baseline SHAs if WORKDIR_OLD is available.
declare -A baseline_sha=()
baseline_label="(unavailable)"
if [[ -n "${WORKDIR_OLD:-}" && -d "$WORKDIR_OLD" ]]; then
  baseline_label="WORKDIR_OLD ($OLD_VERSION)"
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    baseline_sha["$f"]="$(manifest_file_sha "$WORKDIR_OLD/$f")"
  done < <(manifest_ship_files "$WORKDIR_OLD")
fi

added=0
upgraded=0
kept=0
total=0

{
  echo "# TEMPLATE_MANIFEST.lock — per FW-ADR-0002"
  echo "# Generated $(date -u +%Y-%m-%dT%H:%M:%SZ) by migrations/v0.14.0.sh"
  echo "# Format: <sha256>  <project-relative path>"
  echo "# Predicted post-sync state (3-way compare against baseline=$baseline_label)."
  echo "# Files in .template-customizations are omitted by design."
  echo "#"
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    total=$((total+1))
    new_sha="$(manifest_file_sha "$WORKDIR_NEW/$f")"
    if [[ ! -f "$PROJECT_ROOT/$f" ]]; then
      # Sync will add this file from upstream.
      printf '%s  %s\n' "$new_sha" "$f"
      added=$((added+1))
    elif [[ -n "${baseline_sha[$f]:-}" ]]; then
      proj_sha="$(manifest_file_sha "$PROJECT_ROOT/$f")"
      if [[ "$proj_sha" == "${baseline_sha[$f]}" ]]; then
        # Unchanged since scaffold — sync will overwrite.
        printf '%s  %s\n' "$new_sha" "$f"
        upgraded=$((upgraded+1))
      else
        # Customised — sync will leave the project file alone.
        printf '%s  %s\n' "$proj_sha" "$f"
        kept=$((kept+1))
      fi
    else
      # No baseline — conservative: treat as customisation.
      proj_sha="$(manifest_file_sha "$PROJECT_ROOT/$f")"
      printf '%s  %s\n' "$proj_sha" "$f"
      kept=$((kept+1))
    fi
  done < <(manifest_ship_files "$WORKDIR_NEW" "$PROJECT_ROOT")
} > "$manifest"

echo "  synthesised TEMPLATE_MANIFEST.lock — predicted post-sync state ($total entries)"
echo "    +$added (will be added) ~$upgraded (will be upgraded) !$kept (customisations kept)"
echo "    baseline: $baseline_label"
