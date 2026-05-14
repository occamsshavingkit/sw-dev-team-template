#!/usr/bin/env sh
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# scripts/hooks/role-routing-reminder.sh — SessionStart hook that prints
# CLAUDE.md Hard Rule #8 (role routing / no direct tech-lead authoring) to
# the session start banner so the assistant reads it before the first tool
# call.
#
# Informational only; does not fail or modify session state. Part of the
# Hard Rule #8 reinforcement triad: (A) this SessionStart reminder;
# (B) scripts/lint-routing.sh CI lint; (C) FW-ADR on Routed-Through trailers.

cat <<'EOF'
==========================================================================
HARD RULE #8 — Role routing (binding)

`tech-lead` orchestrates; it does not author production artifacts
directly. Code, scripts, schemas, prose deliverables, requirements,
ADRs, release notes, and customer-truth records route to the owning
specialist (`software-engineer`, `tech-writer`, `researcher`,
`project-manager`, `architect`, etc.). Direct `tech-lead` writes are
limited to orchestration artifacts (`OPEN_QUESTIONS.md`,
intake-log rows, dispatch/task stubs, Turn Ledger / decision-log
entries) and tool-bridge work a specialist cannot perform in its
sandbox. When unsure, dispatch.

Before authoring: classify the artifact (code / ADR / CHANGELOG / customer-notes / etc.), identify the owning specialist from the roster, dispatch. The `tech-lead-authoring-guard` PreToolUse hook (FW-ADR-0012) will block writes to paths outside the orchestration allow-list. The `Routed-Through:` commit trailer + `scripts/lint-routing.sh` audit (FW-ADR-0011) remain as defense-in-depth — they don't block, they record.
==========================================================================
EOF
