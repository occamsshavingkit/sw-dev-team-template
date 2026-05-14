#!/usr/bin/env sh
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# scripts/hooks/atomic-question-reminder.sh — SessionStart hook that prints
# CLAUDE.md Hard Rule #11 (atomic customer questions) to the session start
# banner so the assistant reads it before the first tool call.
#
# Customer ruling 2026-05-14: the prior placement (distributed references
# without a numbered Hard Rule entry) was not strong enough; bundled-
# question violations recurred. This hook is part of a three-way reinforcement:
# (A) scripts/lint-questions.sh hard-gate (after HARDGATE_AFTER_SHA);
# (B) this SessionStart reminder; (C) Hard Rule #11 in CLAUDE.md.

cat <<'EOF'
==========================================================================
HARD RULE #11 — Atomic customer questions (strict reading, binding)

Each customer-facing question MUST cover exactly ONE decision axis.

A "multi-select" or "pick multiple — they're independent" framing
bundling N axes into one prompt IS the violation, regardless of whether
the customer could answer "all of the above."

- Batch independent questions internally in docs/OPEN_QUESTIONS.md.
- Ask one queued customer question per turn.
- Only when all agents and tools are idle.
- Place the question as the FINAL line of the turn.

Enforcement: scripts/lint-questions.sh runs hard-gate (CI-blocking) for
commits after the HARDGATE_AFTER_SHA recorded in that script.
==========================================================================
EOF
