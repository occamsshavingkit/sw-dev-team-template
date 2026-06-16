#!/usr/bin/env sh
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# scripts/agent-teams-revisit-check.sh — SessionStart hook that checks
# whether upstream Claude Code bugs #355 and #356 (tracked in
# occamsshavingkit/sw-dev-team-template) are both closed.
#
# Per FW-ADR-0029, CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS was dropped at
# v1.5.3 because bug #356 (subagents don't inherit permission mode) caused
# a Hard Rule #1 violation and bug #355 (subagent prompts silent under
# remote control) broke headless invocations.  The revisit trigger is
# explicit: both bugs must be CLOSED before re-enabling the flag.
#
# Behaviour:
#   - BOTH bugs CLOSED  → print a prominent multi-line alert.
#   - EITHER bug OPEN   → print one brief "still watching" line.
#   - gh missing / not authed / offline / rate-limited → stay silent,
#     exit 0.  A short per-call timeout (7 s) is applied via the
#     timeout(1) utility so a hung network call cannot stall session start.
# Always exits 0 — never blocks session start.

REPO="occamsshavingkit/sw-dev-team-template"
TIMEOUT_SECS=7

# Require gh to be available and authenticated; bail silently if not.
if ! command -v gh > /dev/null 2>&1; then
    exit 0
fi
if ! gh auth status > /dev/null 2>&1; then
    exit 0
fi

# Require timeout(1) for the network guard; fall back gracefully if absent.
_run() {
    if command -v timeout > /dev/null 2>&1; then
        timeout "${TIMEOUT_SECS}" "$@"
    else
        "$@"
    fi
}

# Query each issue state.  On any error (network, rate-limit, 404, etc.)
# treat it as UNKNOWN and bail silently.
STATE_355=$( _run gh issue view 355 -R "${REPO}" --json state -q .state 2>/dev/null ) || true
STATE_356=$( _run gh issue view 356 -R "${REPO}" --json state -q .state 2>/dev/null ) || true

# If we got no data for either (empty string), skip silently.
if [ -z "${STATE_355}" ] || [ -z "${STATE_356}" ]; then
    exit 0
fi

if [ "${STATE_355}" = "CLOSED" ] && [ "${STATE_356}" = "CLOSED" ]; then
    cat <<'EOF'

===========================================================================
AGENT-TEAMS REVISIT — ACTION REQUIRED (FW-ADR-0029)

Upstream bugs #355 and #356 are now CLOSED.

Per the binding revisit trigger in fw-adr-0029-drop-experimental-agent-
teams-flag.md, the first session after this confirmation must open a
superseding ADR (Three-Path Rule).  That ADR must document:

  1. The confirmed fix for each bug (link to upstream resolution).
  2. A verification step: re-run the original diagnosis test
     (subagent inherits permission mode and writes silently, this time
     with CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 also passing).
  3. The migration scope to re-enable — inverse of the table in
     FW-ADR-0029 § "Migration scope":
       • Add CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 back to
         .claude/settings.json env block (scaffold + meta).
       • Restore SendMessage to all 16 agent tools: lines.
       • Revert push-escalation instructions in agent bodies.
       • Regenerate runtime mirrors, OpenCode, Gemini, Antigravity
         adapters via scripts/compile-runtime-agents.sh.
       • Restore "Agent-teams panel" section in CLAUDE.md / AGENTS.md.
       • Revert the one-shot migration where appropriate.
       • Update SW_DEV_ROLE_TAXONOMY.md and agent-contract schema.

Drive the re-enable now.
===========================================================================
EOF
else
    printf 'agent-teams revisit pending: #355=%s #356=%s (still watching)\n' \
        "${STATE_355}" "${STATE_356}"
fi

exit 0
