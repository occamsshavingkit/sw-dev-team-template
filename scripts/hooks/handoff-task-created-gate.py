#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# TaskCreated gate: ensures newly created specialist tasks cite a canonical
# owner role (from the roster in CLAUDE.md § Agent roster) and the active
# durable handoff.  Implements FR-021..FR-023 / SC-007.
#
# Environment:
#   SWDT_HANDOFF_GATES  warn | enforce  (absent / other value → no-op)
#   CLAUDE_PROJECT_DIR  repo root (falls back to cwd)
#
# Reads hook event JSON from stdin.
# Emits a single JSON line on stdout when a violation is detected;
# silent (no output) when the task passes all checks.

from __future__ import annotations

import json
import os
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from scripts.hooks.lib.handoff import load_active_handoff, resolve_gate_mode
from scripts.hooks.lib.roles import is_canonical_role

_HOOK_EVENT_NAME = "TaskCreated"


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

    active_task_id: str = handoff.get("task_id", "")

    # --- Check 1: owner_role must cite a canonical role --------------------
    owner_role = event.get("owner_role") or ""
    if not isinstance(owner_role, str) or not is_canonical_role(owner_role.strip()):
        reason = (
            f"TaskCreated event does not cite a canonical owner role "
            f"(got {owner_role!r}). "
            "The task must identify one of the canonical roster roles "
            "(e.g. software-engineer, qa-engineer, architect, …) as owner_role."
        )
        print(json.dumps(_violation(mode, reason)))
        return 0

    # --- Check 2: handoff citation must match the active handoff -----------
    cited_handoff = event.get("handoff_task_id") or event.get("active_handoff_task_id") or ""
    if not isinstance(cited_handoff, str) or not cited_handoff.strip():
        reason = (
            "TaskCreated event does not cite the active handoff "
            "(expected handoff_task_id or active_handoff_task_id field "
            f"with value {active_task_id!r}). "
            "Speckit-derived or manually created tasks must anchor to the "
            "active durable handoff before becoming active work."
        )
        print(json.dumps(_violation(mode, reason)))
        return 0

    if cited_handoff.strip() != active_task_id:
        reason = (
            f"TaskCreated event cites handoff {cited_handoff!r} but the "
            f"active handoff is {active_task_id!r}. "
            "Tasks must cite the currently active durable handoff."
        )
        print(json.dumps(_violation(mode, reason)))
        return 0

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
