#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors

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


def main() -> int:
    project_dir = Path(os.environ.get("CLAUDE_PROJECT_DIR") or os.getcwd())
    tmp_dir = project_dir / ".claude" / "tmp"
    tmp_dir.mkdir(parents=True, exist_ok=True)
    state_file = tmp_dir / "subcalls-left.json"
    try:
        with open(state_file, "w", encoding="utf-8") as f:
            json.dump({"subcalls_left": _effective_budget()}, f)
    except Exception as exc:
        sys.stderr.write(f"Failed to reset subcalls-left: {exc}\n")
        return 1
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
