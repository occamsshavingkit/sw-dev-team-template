#!/usr/bin/env sh
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# scripts/hooks/post-compact-refresh.sh — SessionStart:compact hook that
# directs Claude to re-read three live working-state files after context
# auto-compaction. The auto-compaction summary may have abstracted away
# binding rules (CLAUDE.md Hard Rules), recent customer rulings
# (CUSTOMER_NOTES.md), or queued customer questions
# (docs/OPEN_QUESTIONS.md); re-reading the live files restores ground
# truth before the next turn.
#
# Customer ruling 2026-05-14: option (ii) — directive-only, not
# content-injection. This hook prints a banner; Claude calls Read on the
# named files at the start of its next turn. Wired in
# .claude/settings.json under SessionStart with matcher "compact".

cat <<EOF
========================================================================
POST-COMPACTION REFRESH

Context compaction just occurred. Before continuing the session, Read
the following three files to restore live working state (the
auto-compaction summary may have abstracted away binding rules,
recent customer rulings, or queued questions):

  1. ${CLAUDE_PROJECT_DIR}/CLAUDE.md
  2. ${CLAUDE_PROJECT_DIR}/docs/OPEN_QUESTIONS.md
  3. ${CLAUDE_PROJECT_DIR}/CUSTOMER_NOTES.md

Skip files that don't exist. Re-read happens at the start of the next
turn, before answering the user or dispatching agents.
========================================================================
EOF
