#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors

from __future__ import annotations

import json
import os
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from scripts.hooks.lib.handoff import (
    load_active_handoff,
    missing_evidence_gates,
)


def _decision(mode: str, missing: list[str]) -> dict:
    reason = "Active handoff is missing required completion evidence: " + ", ".join(missing)
    if mode == "warn":
        return {
            "hookSpecificOutput": {
                "hookEventName": "TaskCompleted",
                "permissionDecision": "allow",
                "warning": reason,
            }
        }
    return {
        "hookSpecificOutput": {
            "hookEventName": "TaskCompleted",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }


def _load_failure_decision(mode: str, error: Exception) -> dict:
    reason = f"Active handoff cannot be loaded or validated: {error}"
    if mode == "warn":
        return {
            "hookSpecificOutput": {
                "hookEventName": "TaskCompleted",
                "permissionDecision": "allow",
                "warning": reason,
            }
        }
    return {
        "hookSpecificOutput": {
            "hookEventName": "TaskCompleted",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }


def main() -> int:
    mode = os.environ.get("SWDT_HANDOFF_GATES", "").strip().lower()
    if mode not in {"warn", "enforce"}:
        return 0

    try:
        event = json.load(sys.stdin)
    except json.JSONDecodeError:
        return 0
    if not isinstance(event, dict) or event.get("hook_event_name") != "TaskCompleted":
        return 0

    repo_root = Path(os.environ.get("CLAUDE_PROJECT_DIR") or os.getcwd())
    try:
        handoff = load_active_handoff(repo_root)
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(json.dumps(_load_failure_decision(mode, exc)))
        return 0

    missing = missing_evidence_gates(handoff)
    if missing:
        print(json.dumps(_decision(mode, missing)))

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
