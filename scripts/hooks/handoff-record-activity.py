#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
"""handoff-record-activity.py — Capture hook-observed activity as evidence.

Design notes
------------
**What it does**
    Reads a hook event from stdin (PostToolUse shape or any hook envelope)
    and appends one evidence entry to the per-task activity sidecar
    ``docs/handoffs/<task_id>.activity.jsonl`` (one JSON object per line,
    append-only). The sidecar is gitignored so it never mutates the durable
    handoff JSON file (fw-adr-0023 D2 Option S).

**Where evidence is written**
    ``docs/handoffs/<task_id>.activity.jsonl`` — a newline-delimited JSON
    log that lives beside the durable handoff JSON but is never committed.
    Derivation of ``<task_id>``: read from the active-handoff pointer, or
    fall back to extracting it from the resolved handoff file.

    The durable handoff JSON is **never mutated** by this hook. Handoff
    JSON files are now fully static after creation; ``TEMPLATE_MANIFEST.lock``
    can hash them raw without a normalizer (fw-adr-0023 §"Follow-up work").

**Entry shape**
    Each JSONL line is a JSON object with:
      - ``evidence_kind`` = ``"accepted"``  (not ``"worker_report"``)
      - ``source``        = hook event name (e.g. ``"PostToolUse"``)
      - ``name``          = tool/command summary derived from the event
      - ``result``        = ``"passed"``
      - ``actor_role``    = ``"hook"``  (distinguishes from any human role)
      - ``timestamp``     = ISO 8601 UTC
    Matches the ``$defs/evidence_gate`` shape in handoff.schema.json.

**Gate mode**
    Mirrors the other hooks: inactive (exit 0 silently) unless
    ``SWDT_HANDOFF_GATES`` is ``"warn"`` or ``"enforce"``.
    On load failure: warn-mode is non-blocking (logs to stderr, exits 0);
    enforce-mode also exits 0 (recording activity must not block a tool call).

**Output**
    No stdout JSON is emitted (this hook does not make a permission
    decision). Diagnostic messages go to stderr.

**Fail-safe**
    Any write error appends to stderr and returns 0; recording activity
    must never gate or block a tool call.
"""

from __future__ import annotations

import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from scripts.hooks.lib.handoff import (  # noqa: E402
    resolve_gate_mode,
    _resolve_repo_relative,
)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _extract_tool_summary(event: dict) -> str:
    """Derive a compact, human-readable name from the hook event."""
    tool_name = event.get("tool_name") or event.get("tool") or ""
    tool_input = event.get("tool_input") or {}
    if isinstance(tool_input, dict):
        command = tool_input.get("command") or ""
        if isinstance(command, str) and command:
            cmd_summary = command.replace("\n", " ").strip()[:80]
            return f"{tool_name}: {cmd_summary}" if tool_name else cmd_summary
    if tool_name:
        return tool_name
    return event.get("hook_event_name") or "unknown"


def _build_activity_entry(event: dict) -> dict:
    """Return a schema-valid evidence_gate dict for the observed tool event."""
    now = datetime.now(tz=timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    return {
        "name": _extract_tool_summary(event),
        "result": "passed",
        "evidence_kind": "accepted",
        "source": event.get("hook_event_name") or "PostToolUse",
        "actor_role": "hook",
        "timestamp": now,
    }


def _resolve_task_id(repo_root: Path) -> str:
    """Return the task_id from the active-handoff pointer.

    Reads .devteam/active-handoff.json. Raises ValueError when the pointer
    is absent or carries no usable task_id / handoff_path.
    """
    pointer_path = repo_root / ".devteam" / "active-handoff.json"
    with pointer_path.open(encoding="utf-8") as f:
        pointer = json.load(f)

    # Prefer explicit task_id.
    task_id = pointer.get("task_id")
    if isinstance(task_id, str) and task_id:
        return task_id

    # Fall back: derive from handoff_path filename (e.g. "docs/handoffs/foo.json" → "foo").
    handoff_path_str = pointer.get("handoff_path")
    if isinstance(handoff_path_str, str) and handoff_path_str:
        # Containment guard — reject absolute or escaping paths.
        resolved = _resolve_repo_relative(repo_root, handoff_path_str)
        return resolved.stem  # filename without extension

    raise ValueError("Cannot resolve task_id from active-handoff pointer")


def _append_to_sidecar(sidecar_path: Path, entry: dict) -> None:
    """Append *entry* as a single JSON line to the sidecar JSONL file.

    Opens in append mode so concurrent writes are atomic at the OS level
    (on POSIX, O_APPEND writes are atomic up to PIPE_BUF; for our small
    JSON objects this is sufficient). No locking required: this is a
    single-process hook.
    """
    sidecar_path.parent.mkdir(parents=True, exist_ok=True)
    line = json.dumps(entry, ensure_ascii=False) + "\n"
    with sidecar_path.open("a", encoding="utf-8") as f:
        f.write(line)


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
    if not isinstance(event, dict):
        return 0

    repo_root = Path(os.environ.get("CLAUDE_PROJECT_DIR") or os.getcwd())

    try:
        task_id = _resolve_task_id(repo_root)
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        # Non-blocking: recording activity must not gate a tool call.
        print(
            f"handoff-record-activity: warn: cannot resolve task_id: {exc}",
            file=sys.stderr,
        )
        return 0

    entry = _build_activity_entry(event)
    sidecar_path = repo_root / "docs" / "handoffs" / f"{task_id}.activity.jsonl"

    try:
        _append_to_sidecar(sidecar_path, entry)
    except OSError as exc:
        print(
            f"handoff-record-activity: warn: cannot write sidecar {sidecar_path}: {exc}",
            file=sys.stderr,
        )
        return 0

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
