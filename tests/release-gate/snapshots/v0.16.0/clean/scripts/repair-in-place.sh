#!/usr/bin/env bash
#
# scripts/repair-in-place.sh — convert an unzipped-in-place template
# directory into a scaffolded project WITHOUT copying to a new path.
#
# Motivating case (upstream issue #5): a user unzips a template
# release into their intended project directory and expects
# FIRST ACTIONS to work; instead the project is missing
# TEMPLATE_VERSION, has template-only files that don't belong in a
# downstream project, and has registers (CUSTOMER_NOTES.md,
# OPEN_QUESTIONS.md, AGENT_NAMES.md) full of template boilerplate.
#
# This script fixes that in place, so the user keeps their directory
# path / name. Destructive: deletes template-only files. Run with
# --dry-run first on any directory you care about.
#
# Usage:
#   scripts/repair-in-place.sh [--dry-run] [--force]
#
# Flags:
#   --dry-run  print the plan; make no changes
#   --force    skip the interactive confirmation prompt
#
# Exit codes:
#   0 — repair applied (or dry-run completed)
#   1 — sanity check failed (not an unzipped template, or already scaffolded)
#   2 — usage error

set -euo pipefail

dry_run=0
force=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) dry_run=1; shift ;;
    --force)   force=1;   shift ;;
    -h|--help) sed -n '3,31p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)
      echo "Usage: $0 [--dry-run] [--force]" >&2
      exit 2
      ;;
  esac
done

# --- Sanity: must be an unzipped template, not a scaffolded project ----------
if [[ ! -f CLAUDE.md || ! -d .claude/agents || ! -d docs/templates ]]; then
  echo "ERROR: this does not look like an unzipped template." >&2
  echo "Expected: CLAUDE.md + .claude/agents/ + docs/templates/" >&2
  exit 1
fi

if [[ -f TEMPLATE_VERSION ]]; then
  echo "ERROR: TEMPLATE_VERSION already present — this directory looks scaffolded." >&2
  echo "Repair-in-place is for unzipped-in-place templates, not for re-scaffolding." >&2
  echo "If you want to upgrade, use scripts/upgrade.sh instead." >&2
  exit 1
fi

if [[ ! -f VERSION ]]; then
  echo "ERROR: no VERSION file found — cannot determine template version." >&2
  echo "Is this really a fresh unzip of a template release?" >&2
  exit 1
fi

template_version="$(cat VERSION | tr -d '[:space:]')"
template_sha="$(git rev-parse HEAD 2>/dev/null || echo unknown)"
today="$(date -u +%Y-%m-%d)"

project_name_default="$(basename "$(pwd)")"

# --- Plan --------------------------------------------------------------------
# Template-only files + directories that do not belong in a downstream project.
# Kept in sync with scripts/scaffold.sh tar --exclude list.
to_remove=(
  VERSION
  CHANGELOG.md
  CONTRIBUTING.md
  LICENSE
  dryrun-project
  examples
  .github
  migrations
  scripts/smoke-test.sh
)

# Registers to reset to empty-but-shaped stubs.
to_reset=(
  docs/OPEN_QUESTIONS.md
  CUSTOMER_NOTES.md
  docs/AGENT_NAMES.md
)

echo "============================================================"
echo "repair-in-place.sh — convert unzipped template to scaffolded project"
echo "Current directory: $(pwd)"
echo "Template version:  $template_version  (SHA: $template_sha)"
echo "Project name:      $project_name_default"
echo "============================================================"
echo ""
echo "The following template-only files / directories will be REMOVED:"
for p in "${to_remove[@]}"; do
  if [[ -e "$p" ]]; then
    echo "  - $p"
  else
    echo "  - $p  (not present, skip)"
  fi
done
echo ""
echo "The following project registers will be RESET to empty-but-shaped stubs:"
echo "  WARNING — any project-specific content in these files will be LOST."
for p in "${to_reset[@]}"; do
  if [[ -e "$p" ]]; then
    bytes="$(wc -c < "$p" | tr -d ' ')"
    echo "  - $p  (currently $bytes bytes)"
  else
    echo "  - $p  (will be created)"
  fi
done
echo ""
echo "The following will be CREATED:"
echo "  - TEMPLATE_VERSION"
echo "  - .template-customizations (empty)"
echo "  - README.md (project stub, overwrites current)"
echo "  - .git (if not already a git repo)"
echo ""

if (( dry_run == 1 )); then
  echo "DRY RUN — no changes made. Re-run without --dry-run to apply." >&2
  exit 0
fi

# --- Confirm ---------------------------------------------------------------
if (( force == 0 )); then
  read -r -p "Proceed? This is destructive. [y/N] " reply
  case "$reply" in
    y|Y|yes|YES) : ;;
    *) echo "Aborted." >&2; exit 1 ;;
  esac
fi

# --- Apply -------------------------------------------------------------------
for p in "${to_remove[@]}"; do
  if [[ -e "$p" ]]; then
    rm -rf -- "$p"
    echo "  removed: $p"
  fi
done

# Reset registers
cat > docs/OPEN_QUESTIONS.md <<'EOF'
# Open Questions register

Tracks every open question on the project. Steward: `researcher`.
`tech-lead` opens items; the named answerer closes them.

Columns:

| ID | Date | Question | Blocked on | Answerer | Status | Resolution |
|---|---|---|---|---|---|---|

(Populate as scoping proceeds. Archive closed rows to
`docs/OPEN_QUESTIONS-ARCHIVE.md` at project close.)
EOF

cat > CUSTOMER_NOTES.md <<'EOF'
# Customer notes

Verbatim record of customer rulings, relayed by `tech-lead` and
recorded by `researcher`. Authoritative.

Format per entry:

```
## YYYY-MM-DD — <topic>
Customer said: "<verbatim>"
Context: <what was being discussed>
Asked by: <agent name via tech-lead>
Implications: <optional, only if customer stated them>
```

(No entries yet — populate as scoping proceeds.)
EOF

cat > docs/AGENT_NAMES.md <<'EOF'
# Agent names

Per-project mapping of teammate names (if the customer chose a
naming category in Step 3) to the canonical roles. Populated by
`tech-lead` after `researcher` has verified pronouns per
`.claude/agents/researcher.md` § pronoun verification rules.

If the customer chose to keep canonical role names, record that
decision here and leave the table unfilled.

| Role | Teammate name | Pronouns | Source |
|---|---|---|---|
EOF

# Stamp TEMPLATE_VERSION
cat > TEMPLATE_VERSION <<EOF
$template_version
$template_sha
$today
EOF

# Seed .template-customizations
touch .template-customizations

# Overwrite README with a project stub
cat > README.md <<EOF
# $project_name_default

Scaffolded from sw-dev-team-template $template_version
($template_sha, $today) via scripts/repair-in-place.sh.

See \`CLAUDE.md\` for the agent workflow and
\`scripts/upgrade.sh\` for future template upgrades.
EOF

# git init if not a repo
if [[ ! -d .git ]]; then
  git init -b main >/dev/null 2>&1 || git init >/dev/null 2>&1
  echo "  git init: done"
fi

echo ""
echo "Repair complete. Next:"
echo "  1. Review TEMPLATE_VERSION, README.md, .template-customizations"
echo "  2. git add -A && git commit -m 'Initial scaffold from template $template_version'"
echo "  3. Run claude and proceed with FIRST ACTIONS in CLAUDE.md"
