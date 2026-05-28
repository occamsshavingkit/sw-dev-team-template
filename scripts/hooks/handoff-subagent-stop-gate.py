#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# SubagentStop gate: when a specialist subagent stops, ensure the return
# evidence it is responsible for is present on the active durable handoff.
# Implements FR-027 / US5 (SC-003, SC-004).
#
# A specialist cannot silently "complete" its leg of the work without leaving
# the evidence that downstream completion gates (handoff-task-completed-gate.py)
# will need.
#
# Role-to-evidence mapping (conservative, additive):
#   code-reviewer    → review evidence (has_review_evidence)
#   security-engineer→ security evidence (has_security_evidence)
#   researcher       → human_approval evidence (has_human_approval_evidence)
#   any other role   → all missing_evidence_gates (full set check)
#
# Environment:
#   SWDT_HANDOFF_GATES  warn | enforce  (absent / other value → no-op)
#   CLAUDE_PROJECT_DIR  repo root (falls back to cwd)
#
# Reads hook event JSON from stdin.
# Emits a single JSON line on stdout when a violation is detected;
# silent (no output) when the subagent passes all checks or gate is off.

from __future__ import annotations

import json
import os
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from scripts.hooks.lib.handoff import (
    has_human_approval_evidence,
    has_review_evidence,
    has_security_evidence,
    load_active_handoff,
    missing_evidence_gates,
    resolve_gate_mode,
)

_HOOK_EVENT_NAME = "SubagentStop"

# Roles whose return obligations map to a specific evidence bucket.
_ROLE_EVIDENCE_CHECKS: dict[str, str] = {
    "code-reviewer": "review",
    "security-engineer": "security_review",
    "researcher": "human_approval",
}


# ---------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------


def _violation(mode: str, reason: str) -> dict:
    if mode == "warn":
        return {
            "hookSpecificOutput": {
                "hookEventName": _HOOK_EVENT_NAME,
                "permissionDecision": "allow",
                "warning": reason,
            }
        }
    return {
        "hookSpecificOutput": {
            "hookEventName": _HOOK_EVENT_NAME,
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }


def _load_failure(mode: str, error: Exception) -> dict:
    reason = f"Active handoff cannot be loaded or validated: {error}"
    if mode == "warn":
        return {
            "hookSpecificOutput": {
                "hookEventName": _HOOK_EVENT_NAME,
                "permissionDecision": "allow",
                "warning": reason,
            }
        }
    return {
        "hookSpecificOutput": {
            "hookEventName": _HOOK_EVENT_NAME,
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }


# ---------------------------------------------------------------------------
# Evidence check dispatch
# ---------------------------------------------------------------------------


def _missing_for_role(role: str, handoff: dict) -> list[str]:
    """Return missing evidence labels for the given returning role.

    For roles with a specific evidence bucket (code-reviewer, security-engineer,
    researcher), check only that bucket and only when the handoff requires it.
    For any other role, fall back to the full missing_evidence_gates check.
    """
    requires = handoff.get("requires", {})

    if role == "code-reviewer":
        if requires.get("review") is True and not has_review_evidence(handoff):
            return ["review"]
        return []

    if role == "security-engineer":
        if requires.get("security_review") is True and not has_security_evidence(handoff):
            return ["security_review"]
        return []

    if role == "researcher":
        if requires.get("human_approval") is True and not has_human_approval_evidence(handoff):
            return ["human_approval"]
        return []

    # Generic fallback: check all required gates.
    return missing_evidence_gates(handoff)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def main() -> int:
    if resolve_gate_mode() == "off":
        return 0

    try:
        event = json.load(sys.stdin)
    except json.JSONDecodeError:
        return 0
    if not isinstance(event, dict) or event.get("hook_event_name") != _HOOK_EVENT_NAME:
        return 0

    repo_root = Path(os.environ.get("CLAUDE_PROJECT_DIR") or os.getcwd())
    try:
        handoff = load_active_handoff(repo_root)
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        # Fail-safe: warn mode allows; enforce mode denies.
        mode = resolve_gate_mode()
        print(json.dumps(_load_failure(mode, exc)))
        return 0

    mode = resolve_gate_mode(handoff)

    # Identify returning specialist role from the event payload.
    # Claude Code SubagentStop events carry "subagent_role" when available.
    subagent_role = event.get("subagent_role") or ""
    if isinstance(subagent_role, str):
        subagent_role = subagent_role.strip()

    if subagent_role:
        missing = _missing_for_role(subagent_role, handoff)
    else:
        # No role identified: conservative fallback — check full gate set.
        missing = missing_evidence_gates(handoff)

    if missing:
        role_note = f" (returning role: {subagent_role!r})" if subagent_role else ""
        reason = (
            f"Subagent stop{role_note}: active handoff is missing required "
            "specialist-return evidence: " + ", ".join(missing)
        )
        print(json.dumps(_violation(mode, reason)))

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
