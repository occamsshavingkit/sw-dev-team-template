#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
#
# scripts/respawn.sh — prepare a respawn of a named teammate.
#
# This script does not itself stop or spawn subagents (that is an
# in-session action for tech-lead — or, when respawning tech-lead
# itself, project-manager). What it does:
#
#   1. Generate a dated handover-brief file at
#      docs/handovers/<teammate-name>-<YYYY-MM-DD-HHMM>.md from
#      docs/templates/handover-template.md, pre-filling the fields the
#      filesystem can answer (teammate name, timestamp, current
#      TEMPLATE_VERSION, charter milestone summary).
#   2. Print the remaining steps of the respawn protocol (per
#      docs/agent-health-contract.md § 4) as a checklist.
#
# Usage:
#   scripts/respawn.sh <teammate-name> "<reason for respawn>"
#
# Example:
#   scripts/respawn.sh "Kermit the Frog" "signals #3, #7 over 2 days"

set -euo pipefail

if [[ $# -lt 2 ]]; then
  cat >&2 <<EOF
Usage: $0 <teammate-name> "<reason for respawn>"

Prepares a handover-brief file and prints the respawn checklist.
Does NOT stop or spawn subagents — that is a tech-lead action
(or project-manager, when respawning tech-lead itself).
EOF
  exit 2
fi

name="$1"
reason="$2"
project_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

if [[ ! -f "$project_root/docs/templates/handover-template.md" ]]; then
  echo "ERROR: no docs/templates/handover-template.md in $project_root." >&2
  echo "Is this a scaffolded project, or is TEMPLATE_VERSION older than v1.0.0-rc2?" >&2
  exit 1
fi

# --- Compose the handover brief filename -------------------------------------
stamp="$(date -u +%Y-%m-%d-%H%M)"
slug="$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-//;s/-$//')"
brief="$project_root/docs/handovers/$slug-$stamp.md"

mkdir -p "$project_root/docs/handovers"

# --- Pre-fill from filesystem ------------------------------------------------
tv_line="(no TEMPLATE_VERSION file)"
[[ -f "$project_root/TEMPLATE_VERSION" ]] && tv_line="$(head -1 "$project_root/TEMPLATE_VERSION" | tr -d '[:space:]')"

last_commit="$(git -C "$project_root" log -1 --format='%h %s' 2>/dev/null || echo '(no git history)')"

# --- Write the brief ---------------------------------------------------------
{
  sed \
    -e "s|\`<teammate-name>\`|\`$name\`|g" \
    -e "s|YYYY-MM-DD HH:MM|$(date -u +'%Y-%m-%d %H:%M UTC')|g" \
    -e "s|signal numbers from.*section 2.*|$reason|g" \
    "$project_root/docs/templates/handover-template.md"

  cat <<EOF

---

## Auto-filled filesystem context (verify and cite per-section above)

- TEMPLATE_VERSION: \`$tv_line\`
- Last git commit: \`$last_commit\`
- Brief generated at: \`$brief\`

The brief is a STUB — \`tech-lead\` (or \`project-manager\` if
respawning tech-lead) must fill every section with file + line
citations before the respawn proceeds. Never respawn from an
auto-filled brief.
EOF
} > "$brief"

echo "Handover brief stubbed at: $brief"
echo
echo "Respawn checklist (docs/agent-health-contract.md § 4):"
echo
echo "  [ ] Fill every section of the handover brief."
echo "      Every factual claim cites file + line."
echo "  [ ] Have the brief's author different from the respawn target."
echo "      Respawning $name  → brief author is tech-lead"
echo "      Respawning tech-lead → brief author is project-manager"
echo "  [ ] Stop the current teammate (SendMessage stop, or let turn end)."
echo "  [ ] Spawn fresh teammate: same name ('$name'), same role file."
echo "      Prompt = contents of $brief + next concrete action."
echo "  [ ] Log the respawn in docs/pm/LESSONS.md."
echo "  [ ] If this was a tech-lead respawn: inform the customer."
echo "  [ ] Archive the handover brief in 30 days or at project close."
