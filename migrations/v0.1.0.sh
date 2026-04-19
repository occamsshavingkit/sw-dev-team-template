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

# References to the old single-file path should be rewritten in any
# project-root markdown (CLAUDE.md, README.md, docs/templates/*). This
# is a best-effort rewrite — it won't touch hand-written customizations
# that mean to refer to something else.
if grep -rl 'docs/GLOSSARY\.md' "$PROJECT_ROOT" --include='*.md' 2>/dev/null \
   | grep -v '/docs/glossary/' >/dev/null; then
  rewrote=0
  while IFS= read -r f; do
    sed -i.bak 's|docs/GLOSSARY\.md|docs/glossary/ENGINEERING.md|g' "$f" && rm -f "$f.bak"
    rewrote=1
  done < <(grep -rl 'docs/GLOSSARY\.md' "$PROJECT_ROOT" --include='*.md' 2>/dev/null | grep -v '/docs/glossary/' || true)
  [[ $rewrote -eq 1 ]] && echo "  rewrote references: docs/GLOSSARY.md → docs/glossary/ENGINEERING.md"
fi
