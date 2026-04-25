#!/usr/bin/env bash
#
# migrations/v0.14.4.sh — upgrade TO v0.14.4.
#
# v0.14.4 fixes issue #65 by pre-populating .template-customizations
# with the canonical stub-fill paths at scaffold time. Existing
# projects that scaffolded under v0.14.3 or earlier have the
# old empty stub and will keep hitting false-positive conflicts on
# CUSTOMER_NOTES.md, OPEN_QUESTIONS.md, AGENT_NAMES.md,
# glossary/PROJECT.md, .gitignore, and README.md until those paths
# are listed.
#
# This migration appends the canonical stub-fill paths to the
# project's .template-customizations if they are not already
# present. Existing entries are left alone. Idempotent.

set -euo pipefail

: "${PROJECT_ROOT:?PROJECT_ROOT is required}"

cust="$PROJECT_ROOT/.template-customizations"

# Canonical stub-fill paths (issue #65).
declare -a stubs=(
  "CUSTOMER_NOTES.md"
  "docs/OPEN_QUESTIONS.md"
  "docs/AGENT_NAMES.md"
  "docs/glossary/PROJECT.md"
  ".gitignore"
  "README.md"
)

if [[ ! -f "$cust" ]]; then
  # Project predates .template-customizations entirely (very old
  # scaffold). Create one with the stub-fills.
  cat > "$cust" <<'HEADEOF'
# .template-customizations — one path per line (project-root-relative).
# (Created by migrations/v0.14.4.sh per issue #65.)

# --- Canonical stub-fills (pre-populated, issue #65) ---
HEADEOF
  for s in "${stubs[@]}"; do
    echo "$s" >> "$cust"
  done
  echo "  created .template-customizations with ${#stubs[@]} canonical stub-fill entries"
  exit 0
fi

# Check which stub-fills are already listed (active, non-comment lines).
declare -A present=()
while IFS= read -r line; do
  line="${line%%#*}"
  line="$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  [[ -z "$line" ]] && continue
  present["$line"]=1
done < "$cust"

declare -a to_add=()
for s in "${stubs[@]}"; do
  [[ -n "${present[$s]:-}" ]] && continue
  to_add+=("$s")
done

if [[ ${#to_add[@]} -eq 0 ]]; then
  echo "  .template-customizations already contains all canonical stub-fills — no change"
  exit 0
fi

# Append the missing entries with a header comment so it's clear they
# came from the migration.
{
  echo ""
  echo "# --- Canonical stub-fills (added by migrations/v0.14.4.sh, issue #65) ---"
  for s in "${to_add[@]}"; do
    echo "$s"
  done
} >> "$cust"

echo "  appended ${#to_add[@]} canonical stub-fill entries to .template-customizations:"
for s in "${to_add[@]}"; do
  echo "    + $s"
done
