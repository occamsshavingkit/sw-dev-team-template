#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# Claude Code PreToolUse hook: require explicit confirmation before
# CUSTOMER_NOTES.md writes. The hook input does not provide a stable role
# identity, so this is an approval gate rather than a role detector.

import json
import os
import sys


def main() -> int:
    try:
        event = json.load(sys.stdin)
    except json.JSONDecodeError:
        return 0

    tool_input = event.get("tool_input") or {}
    file_path = tool_input.get("file_path") or tool_input.get("path") or ""
    command = tool_input.get("command") or ""

    touches_customer_notes = False
    if file_path:
        touches_customer_notes = os.path.basename(file_path) == "CUSTOMER_NOTES.md"
    if command:
        touches_customer_notes = touches_customer_notes or "CUSTOMER_NOTES.md" in command

    if not touches_customer_notes:
        return 0

    reason = (
        "CUSTOMER_NOTES.md is the verbatim customer-truth record. "
        "Per the template contract, tech-lead must route customer-answer "
        "entries to researcher; approve only for researcher-owned notes "
        "maintenance or an intentional human edit."
    )
    print(
        json.dumps(
            {
                "hookSpecificOutput": {
                    "hookEventName": "PreToolUse",
                    "permissionDecision": "ask",
                    "permissionDecisionReason": reason,
                }
            }
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
