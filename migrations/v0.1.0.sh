#!/usr/bin/env bash
#
# migrations/v0.1.0.sh — upgrade TO v0.1.0.
#
# The v0.1.0 release ships the split glossary (docs/glossary/ENGINEERING.md
# + docs/glossary/PROJECT.md). Projects that were stamped against a
# pre-v0.1.0 working tree may still have a single docs/GLOSSARY.md.
# This migration moves it to docs/glossary/ENGINEERING.md and seeds
# an empty docs/glossary/PROJECT.md stub.
#
# Safe to run on any project: the guards make it a no-op unless the
# old file actually exists and the new layout is absent.

set -euo pipefail

: "${PROJECT_ROOT:?}"

old_glossary="$PROJECT_ROOT/docs/GLOSSARY.md"
new_engineering="$PROJECT_ROOT/docs/glossary/ENGINEERING.md"
new_project="$PROJECT_ROOT/docs/glossary/PROJECT.md"

if [[ -f "$old_glossary" && ! -f "$new_engineering" ]]; then
  mkdir -p "$PROJECT_ROOT/docs/glossary"
  mv "$old_glossary" "$new_engineering"
  echo "  rename: docs/GLOSSARY.md → docs/glossary/ENGINEERING.md"
fi

if [[ ! -f "$new_project" && -d "$PROJECT_ROOT/docs/glossary" ]]; then
  # Seed an empty-but-shaped PROJECT.md from upstream if available.
  upstream_project="$WORKDIR_NEW/docs/glossary/PROJECT.md"
  if [[ -f "$upstream_project" ]]; then
    cp "$upstream_project" "$new_project"
    echo "  added: docs/glossary/PROJECT.md (stub from upstream)"
  fi
fi

# References to the old single-file path are rewritten in the project's
# own markdown tree only. Nested git repos (e.g., a `sw-dev-team-template`
# working copy living inside the project dir) are skipped so we do not
# mutate a sibling project's files.
md_files=$(find "$PROJECT_ROOT" -mindepth 1 \
  \( -name '.git' -type d -prune \) -o \
  \( -type d -exec test -d '{}/.git' ';' -prune \) -o \
  \( -type f -name '*.md' -print \) 2>/dev/null)

# Further filter: skip files inside docs/glossary/ (the new location —
# those files legitimately contain the new path and must not be touched).
rewrote=0
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  case "$f" in
    */docs/glossary/*) continue ;;
  esac
  # Only touch files that actually reference the old path.
  grep -q 'docs/GLOSSARY\.md' "$f" 2>/dev/null || continue
  # And only if what they reference looks like a bare path reference, not a
  # quoted string inside a human-readable log entry. Heuristic: rewrite
  # only lines where the path appears outside a backquoted-string context
  # that also contains `docs/glossary/`. (Cheap: skip lines where both
  # paths appear.)
  if grep -E 'docs/GLOSSARY\.md' "$f" | grep -v 'docs/glossary/' > /dev/null; then
    sed -i.bak -e '/docs\/glossary\//!s|docs/GLOSSARY\.md|docs/glossary/ENGINEERING.md|g' "$f" \
      && rm -f "$f.bak"
    rewrote=1
  fi
done <<< "$md_files"
[[ $rewrote -eq 1 ]] && echo "  rewrote references: docs/GLOSSARY.md → docs/glossary/ENGINEERING.md"
