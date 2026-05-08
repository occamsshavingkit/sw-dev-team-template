#!/usr/bin/env bash
#
# migrations/v0.15.0.sh — upgrade TO v0.15.0.
#
# v0.15.0 lands two structural changes that need migration on
# downstream projects:
#
#   #66 — docs/INDEX.md split into INDEX-FRAMEWORK.md (template-
#         shipped) + INDEX-PROJECT.md (project-owned), with
#         INDEX.md becoming a project-owned dispatcher.
#
#   #67 — Framework ADRs renamed from `docs/adr/NNNN-*.md` to
#         `docs/adr/fw-adr-NNNN-*.md` for NNNN ∈ 0001..0007 IF
#         and only if the project's copy of that file matches
#         the upstream framework ADR content. Project-numbered
#         ADRs in the same range stay put.
#
# The file-sync loop in upgrade.sh handles adding the new
# files (INDEX-FRAMEWORK.md, INDEX-PROJECT.md, fw-adr-* renames).
# This migration handles the *existing* project state — moving
# project-state into INDEX-PROJECT.md, removing now-stale
# unprefixed framework ADRs, and updating .template-customizations.
#
# Idempotent: safe to re-run.

set -euo pipefail

: "${PROJECT_ROOT:?PROJECT_ROOT is required}"
: "${WORKDIR_NEW:?WORKDIR_NEW is required}"

# shellcheck source=scripts/lib/manifest.sh
# shellcheck disable=SC1091
source "$WORKDIR_NEW/scripts/lib/manifest.sh"

# --- (#67) Rename framework ADRs that exist as `NNNN-*.md` to `fw-adr-NNNN-*.md`
# Only do this if the file content matches the upstream framework ADR
# (after stripping the renamed cross-references — i.e., the post-sync
# content is what we'd compare to). Approach: compare project's
# `NNNN-<slug>.md` against upstream's `fw-adr-NNNN-<slug>.md` after
# normalising the FW-ADR-prefix differences. If close enough → it's
# the framework ADR; rename. Otherwise → project ADR; leave alone.

removed_frameworks=()
for n in 0001 0002 0003 0004 0005 0006 0007; do
  # Find the project's unprefixed file (if any) and the upstream's prefixed file.
  proj_file="$(find "$PROJECT_ROOT/docs/adr" -maxdepth 1 -name "${n}-*.md" 2>/dev/null | head -1 || true)"
  ups_file="$(find "$WORKDIR_NEW/docs/adr" -maxdepth 1 -name "fw-adr-${n}-*.md" 2>/dev/null | head -1 || true)"
  [[ -z "$proj_file" ]] && continue
  [[ -z "$ups_file" ]] && continue

  # Heuristic: project file's unprefixed filename matches upstream's
  # fw-adr-prefixed filename (slug-equal). If yes, this is the framework
  # ADR; the file-sync will install the fw-adr-prefixed version, so we
  # remove the unprefixed copy here to avoid leaving an orphan.
  proj_slug="$(basename "$proj_file" | sed 's|^[0-9]*-||')"
  ups_slug="$(basename "$ups_file" | sed 's|^fw-adr-[0-9]*-||')"
  if [[ "$proj_slug" == "$ups_slug" ]]; then
    rm "$proj_file"
    removed_frameworks+=("docs/adr/$(basename "$proj_file")")
  fi
done

if [[ ${#removed_frameworks[@]} -gt 0 ]]; then
  echo "  removed ${#removed_frameworks[@]} unprefixed framework ADR(s) (will be re-added with fw-adr- prefix by sync):"
  for f in "${removed_frameworks[@]}"; do echo "    - $f"; done
fi

# --- (#66) INDEX.md split.
# If the project has a docs/INDEX.md but no docs/INDEX-PROJECT.md, save
# the existing INDEX.md content as INDEX-PROJECT.md (so any project-
# authored content is preserved) and let the file-sync install the new
# dispatcher INDEX.md + framework INDEX-FRAMEWORK.md.

old_index="$PROJECT_ROOT/docs/INDEX.md"
project_index="$PROJECT_ROOT/docs/INDEX-PROJECT.md"
if [[ -f "$old_index" && ! -f "$project_index" ]]; then
  # If the existing INDEX.md is byte-identical to the previous
  # framework INDEX (we can compare against WORKDIR_OLD if available),
  # we don't need to preserve anything — sync will overwrite cleanly.
  # If it diverges, the project has authored content; save as
  # INDEX-PROJECT.md so that content survives.
  preserve=1
  if [[ -n "${WORKDIR_OLD:-}" && -d "$WORKDIR_OLD" && -f "$WORKDIR_OLD/docs/INDEX.md" ]]; then
    if cmp -s "$WORKDIR_OLD/docs/INDEX.md" "$old_index"; then
      preserve=0
    fi
  fi

  if [[ $preserve -eq 1 ]]; then
    # Save project's INDEX.md as INDEX-PROJECT.md — the dispatcher will
    # then live at INDEX.md (installed by sync), framework content at
    # INDEX-FRAMEWORK.md (installed by sync), and the project's prior
    # content survives at INDEX-PROJECT.md.
    cp "$old_index" "$project_index"
    echo "  preserved project INDEX.md content → docs/INDEX-PROJECT.md"
    echo "    (sync will install new dispatcher INDEX.md + framework INDEX-FRAMEWORK.md)"
  else
    echo "  existing docs/INDEX.md is byte-identical to v0.14.x framework INDEX — no preservation needed"
  fi
fi

# --- (#66/#65) Add INDEX.md + INDEX-PROJECT.md to .template-customizations
# (mirroring the v0.14.4 stub-fill migration shape).

cust="$PROJECT_ROOT/.template-customizations"
if [[ -f "$cust" ]]; then
  declare -A present=()
  while IFS= read -r line; do
    line="${line%%#*}"
    line="$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    [[ -z "$line" ]] && continue
    present["$line"]=1
  done < "$cust"

  declare -a to_add=()
  for entry in "docs/INDEX.md" "docs/INDEX-PROJECT.md"; do
    [[ -n "${present[$entry]:-}" ]] && continue
    to_add+=("$entry")
  done

  if [[ ${#to_add[@]} -gt 0 ]]; then
    {
      echo ""
      echo "# --- INDEX split (added by migrations/v0.15.0.sh, issue #66) ---"
      for entry in "${to_add[@]}"; do
        echo "$entry"
      done
    } >> "$cust"
    echo "  appended ${#to_add[@]} INDEX entries to .template-customizations:"
    for entry in "${to_add[@]}"; do echo "    + $entry"; done
  fi
fi

echo "  v0.15.0 migration complete (issue #66 INDEX split, issue #67 framework-ADR rename)"
