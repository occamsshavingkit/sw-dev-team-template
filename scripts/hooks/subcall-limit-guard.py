#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors

import json
import os
import sys
from pathlib import Path

def main() -> int:
    try:
        event = json.load(sys.stdin)
    except json.JSONDecodeError:
        return 0

    if not isinstance(event, dict):
        return 0

    project_dir = Path(os.environ.get("CLAUDE_PROJECT_DIR") or os.getcwd())
    state_file = project_dir / ".claude" / "tmp" / "subcalls-left.json"

    # If the state file doesn't exist, initialize it with 3
    if not state_file.exists():
        state_file.parent.mkdir(parents=True, exist_ok=True)
        try:
            with open(state_file, "w", encoding="utf-8") as f:
                json.dump({"subcalls_left": 3}, f)
        except Exception:
            pass

    try:
        with open(state_file, "r", encoding="utf-8") as f:
            data = json.load(f)
        subcalls_left = data.get("subcalls_left", 3)
    except Exception:
        subcalls_left = 3

    if subcalls_left <= 0:
        # Block subagent spawning
        reason = "Subagent spawn blocked: subcall budget exhausted (0 subcalls left in this session)."
        decision = {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": reason,
            }
		}
        print(json.dumps(decision))
        return 0

    # Decrement and save
    subcalls_left -= 1
    try:
        with open(state_file, "w", encoding="utf-8") as f:
            json.dump({"subcalls_left": subcalls_left}, f)
    except Exception:
        pass

    # Allow the tool call
    decision = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "allow",
        }
    }
    print(json.dumps(decision))
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
