#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
"""handoff-record-activity.py — Capture hook-observed activity as evidence.

Design notes
------------
**What it does**
    Reads a hook event from stdin (PostToolUse shape or any hook envelope)
    and appends one evidence entry to the active handoff's
    ``verification.tests`` list so the TaskCompleted gate can treat the
    observed activity as ACCEPTED (hook-captured, not worker self-attestation).

**Where evidence is written**
    Directly into the durable handoff file that the active-handoff pointer
    resolves to (same file ``load_active_handoff`` reads).  The write is
    *atomic*: the updated JSON is written to a sibling ``.tmp`` file first,
    then renamed over the original.  This prevents corruption if the process
    is interrupted between write and close, and preserves schema validity
    because we (a) append only, never delete or mutate existing fields, and
    (b) build the new evidence entry to match ``$defs/evidence_gate`` in
    handoff.schema.json.

    We do NOT write to a separate activity-log file because the gate helpers
    (``lib/handoff.py``) read ``verification.tests`` (and the other sub-lists)
    directly; a separate log would require gate changes.  The atomic-append
    approach keeps the single source of truth.

**Schema safety**
    The appended entry has:
      - ``evidence_kind`` = ``"accepted"``  (not ``"worker_report"``)
      - ``source``        = hook event name (e.g. ``"PostToolUse"``)
      - ``name``          = tool/command summary derived from the event
      - ``result``        = ``"passed"``
      - ``actor_role``    = ``"hook"``  (distinguishes from any human role)
    All fields are present in ``$defs/evidence_gate``; none are required by
    the schema so omitting extras is also valid.

**Gate mode**
    Mirrors the other hooks: inactive (exit 0 silently) unless
    ``SWDT_HANDOFF_GATES`` is ``"warn"`` or ``"enforce"``.
    On load failure: warn-mode is non-blocking (logs to stderr, exits 0);
    enforce-mode also exits 0 (recording activity should not block a tool
    call — only the completion gate blocks).

**Output**
    No stdout JSON is emitted (this hook does not make a permission
    decision).  Diagnostic messages go to stderr.
"""

from __future__ import annotations

import json
import os
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from scripts.hooks.lib.handoff import (  # noqa: E402
    load_active_handoff,
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
            # Truncate long commands; strip newlines.
            cmd_summary = command.replace("\n", " ").strip()[:80]
            return f"{tool_name}: {cmd_summary}" if tool_name else cmd_summary
    if tool_name:
        return tool_name
    return event.get("hook_event_name") or "unknown"


def _build_evidence_entry(event: dict) -> dict:
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


def _resolve_handoff_path(repo_root: Path) -> Path:
    """Return the resolved path of the durable handoff file.

    Applies the same containment guards as lib/handoff._resolve_repo_relative:
    rejects absolute handoff_path values and requires the resolved path to be
    contained under repo_root.  Raises ValueError on violation so the caller
    can treat it as a non-blocking load failure.
    """
    pointer_path = repo_root / ".devteam" / "active-handoff.json"
    with pointer_path.open(encoding="utf-8") as f:
        pointer = json.load(f)

    handoff_path_str = pointer.get("handoff_path")
    task_id = pointer.get("task_id")

    if isinstance(handoff_path_str, str) and handoff_path_str:
        # Delegate to the shared guard: raises ValueError if absolute or
        # if the resolved path escapes the repo root.
        return _resolve_repo_relative(repo_root, handoff_path_str)

    if isinstance(task_id, str) and task_id:
        handoffs_dir = repo_root / "docs" / "handoffs"
        for p in sorted(handoffs_dir.glob("*.json")):
            try:
                with p.open(encoding="utf-8") as f:
                    payload = json.load(f)
                if isinstance(payload, dict) and payload.get("task_id") == task_id:
                    # task_id branch scans only within docs/handoffs/; verify
                    # containment for defence-in-depth.
                    p.relative_to(repo_root.resolve())
                    return p
            except (OSError, json.JSONDecodeError):
                continue

    raise ValueError("Cannot resolve active handoff path from pointer")


def _atomic_append_evidence(handoff_file: Path, entry: dict) -> None:
    """Atomically append *entry* to handoff[verification][tests].

    Write order: load → mutate → write to .tmp → rename over original.
    The rename is atomic on POSIX (same filesystem).  The handoff is
    re-validated by load_active_handoff before we modify it, so the
    pre-mutation state is already known-valid; we only append a
    schema-valid evidence entry, keeping the document valid.
    """
    with handoff_file.open(encoding="utf-8") as f:
        handoff = json.load(f)

    tests_list = handoff.get("verification", {}).get("tests")
    if not isinstance(tests_list, list):
        raise ValueError("handoff.verification.tests is not a list; cannot append")

    tests_list.append(entry)

    tmp_fd, tmp_path = tempfile.mkstemp(
        dir=handoff_file.parent,
        prefix=".tmp-" + handoff_file.name + "-",
    )
    try:
        with os.fdopen(tmp_fd, "w", encoding="utf-8") as f:
            json.dump(handoff, f, indent=2)
            f.write("\n")
        os.replace(tmp_path, handoff_file)
    except Exception:
        try:
            os.unlink(tmp_path)
        except OSError:
            pass
        raise


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def main() -> int:
    mode = os.environ.get("SWDT_HANDOFF_GATES", "").strip().lower()
    if mode not in {"warn", "enforce"}:
        return 0

    try:
        event = json.load(sys.stdin)
    except json.JSONDecodeError:
        return 0
    if not isinstance(event, dict):
        return 0

    repo_root = Path(os.environ.get("CLAUDE_PROJECT_DIR") or os.getcwd())

    try:
        handoff = load_active_handoff(repo_root)
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        # Non-blocking in both modes: recording activity should not gate a tool.
        print(f"handoff-record-activity: warn: cannot load active handoff: {exc}", file=sys.stderr)
        return 0

    entry = _build_evidence_entry(event)

    try:
        handoff_file = _resolve_handoff_path(repo_root)
        _atomic_append_evidence(handoff_file, entry)
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"handoff-record-activity: warn: cannot record activity evidence: {exc}", file=sys.stderr)
        return 0

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
