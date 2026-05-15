#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
#
# scripts/agent-health.sh — assemble a health-check packet for a named
# teammate. Ground-truth based: the packet contains the fixed prompt
# (§3.1 of docs/agent-health-contract.md) plus a snapshot of the
# project's register state, so tech-lead (or project-manager when
# auditing tech-lead) can grade the agent's response against files
# rather than vibes.
#
# Usage:
#   scripts/agent-health.sh <teammate-name>
#
# Emits the packet on stdout. The packet is intended to be pasted into
# the agent's prompt (or piped to a subagent dispatcher); the agent's
# response is then scored by the human (or a peer agent) against the
# ground-truth section at the end of the packet.

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <teammate-name>" >&2
  exit 2
fi

name="$1"
project_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# --- Ground truth ------------------------------------------------------------
tv_line="(no TEMPLATE_VERSION file)"
[[ -f "$project_root/TEMPLATE_VERSION" ]] && tv_line="$(head -1 "$project_root/TEMPLATE_VERSION" | tr -d '[:space:]')"

charter_milestone="(no docs/pm/CHARTER.md)"
if [[ -f "$project_root/docs/pm/CHARTER.md" ]]; then
  charter_milestone="$(grep -A 20 '## 5. Summary milestones' "$project_root/docs/pm/CHARTER.md" 2>/dev/null | head -10 || true)"
fi

open_q_count="(no docs/OPEN_QUESTIONS.md)"
if [[ -f "$project_root/docs/OPEN_QUESTIONS.md" ]]; then
  open_q_count="$(grep -cE '^\| Q-[0-9]+ .* \| open \|' "$project_root/docs/OPEN_QUESTIONS.md" 2>/dev/null || echo 0)"
fi

last_customer_entry="(no CUSTOMER_NOTES.md)"
if [[ -f "$project_root/CUSTOMER_NOTES.md" ]]; then
  last_customer_entry="$(grep -nE '^## [0-9]{4}-[0-9]{2}-[0-9]{2} ' "$project_root/CUSTOMER_NOTES.md" 2>/dev/null | tail -1 || echo "(no dated entry found)")"
fi

last_commit="$(git -C "$project_root" log -1 --format='%h %s' 2>/dev/null || echo '(no git history)')"

# --- Emit the packet ---------------------------------------------------------
cat <<EOF
===============================================================
AGENT HEALTH-CHECK PACKET
Teammate: $name
Generated: $(date -u +%Y-%m-%dT%H:%MZ)
Project root: $project_root
===============================================================

-- PROMPT TO SEND THE AGENT --

Before continuing your current work, run a self-check. Answer the
following, and for every claim cite the source — file path, and
if applicable section or line. If you cannot cite a source, say
"no source" rather than guessing.

1. Who are you (role), and what is the specific project you are
   working on?
2. What are the three highest-priority open items right now?
3. What is the most recent customer decision recorded in
   CUSTOMER_NOTES.md?
4. What milestone is this project currently in, and what are its
   exit criteria?
5. What is the current TEMPLATE_VERSION of this project?
6. Which agent last handed work off to you, and what was the ask?

Keep each answer to one or two sentences. Citations are required
on every factual claim.

-- GROUND-TRUTH SNAPSHOT (for the grader — do NOT share with the agent) --

TEMPLATE_VERSION:
  $tv_line

Last recorded customer entry (CUSTOMER_NOTES.md):
  $last_customer_entry

Open question count (docs/OPEN_QUESTIONS.md, status=open):
  $open_q_count

Charter milestone summary (docs/pm/CHARTER.md §5):
$(echo "$charter_milestone" | sed 's/^/  /')

Last git commit:
  $last_commit

-- GRADING RUBRIC --

Per docs/agent-health-contract.md § 3.2. Score each of the six
answers: green / yellow / red. Record the overall result in
docs/pm/LESSONS.md under "Agent-health check" with today's date,
teammate name, and grade.

Red on ANY answer (or ≥ 2 yellows) = trigger respawn per § 4.

Note: for tech-lead self-audits, the grader must be project-manager
(not tech-lead itself). See § 5 of the contract.

===============================================================
EOF
