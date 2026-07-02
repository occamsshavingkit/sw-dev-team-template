#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors

from __future__ import annotations

import json
import os
import sys
from pathlib import Path

DEFAULT_SUBCALL_BUDGET = 100
SUBCALL_BUDGET_ENV = "SWDT_SUBCALL_BUDGET"


def _effective_budget() -> int:
    raw_value = os.environ.get(SUBCALL_BUDGET_ENV, "").strip()
    try:
        budget = int(raw_value)
    except ValueError:
        return DEFAULT_SUBCALL_BUDGET
    if budget <= 0:
        return DEFAULT_SUBCALL_BUDGET
    return budget


def _allow_output() -> dict:
    return {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "allow",
        }
    }


def _deny_output(effective_budget: int) -> dict:
    reason = (
        "Subagent spawn blocked: subcall budget exhausted "
        f"(0 subcalls left; effective session budget {effective_budget}). "
        f"Raise {SUBCALL_BUDGET_ENV} or reuse an existing named teammate via "
        "direct message/resume where supported."
    )
    return {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }


def main() -> int:
    try:
        event = json.load(sys.stdin)
    except json.JSONDecodeError:
        return 0

    if not isinstance(event, dict):
        return 0

    project_dir = Path(os.environ.get("CLAUDE_PROJECT_DIR") or os.getcwd())
    effective_budget = _effective_budget()
    state_file = project_dir / ".claude" / "tmp" / "subcalls-left.json"
    if not state_file.exists():
        state_file.parent.mkdir(parents=True, exist_ok=True)
        try:
            with open(state_file, "w", encoding="utf-8") as f:
                json.dump({"subcalls_left": effective_budget}, f)
        except Exception:
            pass

    try:
        with open(state_file, "r", encoding="utf-8") as f:
            data = json.load(f)
        subcalls_left = int(data.get("subcalls_left", effective_budget))
    except Exception:
        subcalls_left = effective_budget

    if subcalls_left <= 0:
        print(json.dumps(_deny_output(effective_budget)))
        return 0

    subcalls_left -= 1
    try:
        with open(state_file, "w", encoding="utf-8") as f:
            json.dump({"subcalls_left": subcalls_left}, f)
    except Exception:
        pass

    print(json.dumps(_allow_output()))
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
