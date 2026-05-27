#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# Stop gate: when the top-level (main) agent session is about to stop,
# inspect the active handoff for bad terminal states.  Implements FR-027 / US5.
#
# Three conditions are detected:
#
#   INCONSISTENT   — the active pointer exists but its target fails schema
#                    validation, the pointer contradicts the durable handoff
#                    status, or required structural fields are incoherent.
#                    (load_active_handoff() raises ValueError / FileNotFoundError
#                    in these cases, so we catch and surface them.)
#
#   INCOMPLETE     — handoff status is "active" and required evidence gates are
#                    unsatisfied (missing_evidence_gates() returns non-empty).
#
#   FALSELY_COMPLETED — handoff status == "completed" but required evidence is
#                    missing or only worker-self-report.
#                    (load_active_handoff() rejects non-"active" status, so we
#                    detect this by loading the raw pointer target directly and
#                    checking completion vs evidence.)
#
# No-active-handoff policy (choice recorded here):
#   When the .devteam/active-handoff.json pointer file is absent, the session
#   is stopping without any active handoff — nothing to check.  The gate exits
#   silently (clean allow, no output).  This matches the "nothing to check"
#   semantics: the Stop gate guards the active handoff; if none exists, there
#   is no contract to enforce.  This differs from SubagentStop (which fails
#   safe on missing handoff) because a top-level session stop after completing
#   or clearing the handoff is the *expected* clean exit path.
#
# Environment:
#   SWDT_HANDOFF_GATES  warn | enforce  (absent / other value → no-op)
#   CLAUDE_PROJECT_DIR  repo root (falls back to cwd)
#
# Reads hook event JSON from stdin.
# Emits a single JSON line on stdout when a violation is detected;
# silent (no output) when the handoff is consistent/complete or gate is off.

from __future__ import annotations

import json
import os
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from scripts.hooks.lib.handoff import (
    missing_evidence_gates,
    resolve_gate_mode,
)

_HOOK_EVENT_NAME = "Stop"

# Status values that indicate a claimed completion.
_COMPLETED_STATUSES = {"completed", "done", "closed"}


# ---------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------


def _violation(mode: str, condition: str, reason: str) -> dict:
    full_reason = f"[{condition}] {reason}"
    if mode == "warn":
        return {
            "hookSpecificOutput": {
                "hookEventName": _HOOK_EVENT_NAME,
                "permissionDecision": "allow",
                "warning": full_reason,
            }
        }
    return {
        "hookSpecificOutput": {
            "hookEventName": _HOOK_EVENT_NAME,
            "permissionDecision": "deny",
            "permissionDecisionReason": full_reason,
        }
    }


# ---------------------------------------------------------------------------
# Low-level helpers (avoid re-importing private symbols from lib)
# ---------------------------------------------------------------------------


def _load_json(path: Path) -> dict:
    with path.open(encoding="utf-8") as handle:
        payload = json.load(handle)
    if not isinstance(payload, dict):
        raise ValueError(f"expected JSON object in {path}")
    return payload


def _resolve_handoff_path(root: Path, pointer: dict) -> Path | None:
    """Resolve the durable handoff file from the pointer dict.

    Returns None when neither handoff_path nor task_id is present (pointer
    is structurally unusable).  Raises FileNotFoundError / ValueError on
    resolution failures.
    """
    handoff_path = pointer.get("handoff_path")
    task_id_ref = pointer.get("task_id")

    if isinstance(handoff_path, str) and handoff_path:
        candidate = Path(handoff_path)
        if candidate.is_absolute():
            raise ValueError("handoff_path must be repo-relative")
        resolved = (root / candidate).resolve()
        try:
            resolved.relative_to(root.resolve())
        except ValueError as exc:
            raise ValueError("handoff_path escapes repo root") from exc
        if not resolved.exists():
            raise FileNotFoundError(f"handoff target not found: {handoff_path!r}")
        return resolved

    if isinstance(task_id_ref, str) and task_id_ref:
        handoffs_dir = root / "docs" / "handoffs"
        if not handoffs_dir.is_dir():
            raise FileNotFoundError(
                f"task_id {task_id_ref!r}: docs/handoffs/ directory not found"
            )
        matches = []
        for candidate in sorted(handoffs_dir.glob("*.json")):
            try:
                payload = _load_json(candidate)
            except (ValueError, OSError):
                continue
            if payload.get("task_id") == task_id_ref:
                matches.append(candidate)
        if not matches:
            raise FileNotFoundError(
                f"task_id {task_id_ref!r}: no matching file in docs/handoffs/"
            )
        if len(matches) > 1:
            paths = ", ".join(str(m) for m in matches)
            raise ValueError(
                f"task_id {task_id_ref!r}: multiple matching files: {paths}"
            )
        return matches[0]

    return None  # pointer lacks both fields


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

    # --- Step 1: load the pointer file -------------------------------------
    pointer_path = repo_root / ".devteam" / "active-handoff.json"
    if not pointer_path.exists():
        # No active handoff — nothing to check.  Clean allow (silent).
        return 0

    try:
        pointer = _load_json(pointer_path)
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        # Pointer file exists but is unreadable/malformed → INCONSISTENT.
        mode = resolve_gate_mode()
        print(json.dumps(_violation(mode, "INCONSISTENT", f"Active handoff pointer is unreadable: {exc}")))
        return 0

    # --- Step 2: resolve the durable handoff file --------------------------
    try:
        resolved_path = _resolve_handoff_path(repo_root, pointer)
    except (OSError, FileNotFoundError, ValueError) as exc:
        mode = resolve_gate_mode()
        print(json.dumps(_violation(mode, "INCONSISTENT", f"Active handoff pointer cannot be resolved: {exc}")))
        return 0

    if resolved_path is None:
        mode = resolve_gate_mode()
        print(json.dumps(_violation(
            mode,
            "INCONSISTENT",
            "Active handoff pointer is missing both handoff_path and task_id.",
        )))
        return 0

    # --- Step 3: load the raw handoff (before status-gated validation) -----
    try:
        raw_handoff = _load_json(resolved_path)
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        mode = resolve_gate_mode()
        print(json.dumps(_violation(mode, "INCONSISTENT", f"Durable handoff file is unreadable: {exc}")))
        return 0

    # --- Step 4: import and run schema validation --------------------------
    # We use the private validator from lib to avoid duplicating schema logic.
    try:
        import jsonschema  # noqa: PLC0415

        schema_path = REPO_ROOT / "schemas" / "handoff.schema.json"
        schema = _load_json(schema_path)
        jsonschema.validate(raw_handoff, schema)
    except Exception as exc:  # jsonschema.ValidationError or import failure
        # Schema-invalid handoff: do not trust its mode.gate_mode override;
        # resolve gate mode from env only — an untrusted handoff cannot tighten itself.
        mode = resolve_gate_mode()
        print(json.dumps(_violation(mode, "INCONSISTENT", f"Active handoff fails schema validation: {exc}")))
        return 0

    status = raw_handoff.get("status", "")

    # --- Step 5: detect FALSELY_COMPLETED ----------------------------------
    # The handoff claims completion but required evidence may be missing.
    if status in _COMPLETED_STATUSES:
        mode = resolve_gate_mode(raw_handoff)
        missing = missing_evidence_gates(raw_handoff)
        if missing:
            reason = (
                f"Handoff status is {status!r} but required evidence gates are "
                "unsatisfied: " + ", ".join(missing)
                + ". Completion was claimed without accepted evidence."
            )
            print(json.dumps(_violation(mode, "FALSELY_COMPLETED", reason)))
        # Completed handoffs with all evidence satisfied are fine — allow silently.
        return 0

    # --- Step 6: detect INCOMPLETE (status == "active") -------------------
    if status == "active":
        # Validate structural integrity (allowed_paths, forbidden_paths).
        # Note: both fields are schema-required, so these branches are only
        # reachable if schema validation was skipped (e.g. jsonschema absent).
        # Pass raw_handoff so the per-handoff gate_mode tightening is honoured
        # consistently with all other resolve_gate_mode call sites.
        if not isinstance(raw_handoff.get("allowed_paths"), list):
            mode = resolve_gate_mode(raw_handoff)
            print(json.dumps(_violation(
                mode,
                "INCONSISTENT",
                "Active handoff is missing required 'allowed_paths' list.",
            )))
            return 0
        if not isinstance(raw_handoff.get("forbidden_paths"), list):
            mode = resolve_gate_mode(raw_handoff)
            print(json.dumps(_violation(
                mode,
                "INCONSISTENT",
                "Active handoff is missing required 'forbidden_paths' list.",
            )))
            return 0

        mode = resolve_gate_mode(raw_handoff)
        missing = missing_evidence_gates(raw_handoff)
        if missing:
            reason = (
                "Session stopping with incomplete handoff — required evidence "
                "gates are unsatisfied: " + ", ".join(missing)
            )
            print(json.dumps(_violation(mode, "INCOMPLETE", reason)))
        return 0

    # --- Step 7: any other status (e.g. "draft", "cancelled") --------------
    # A "draft" handoff with an active pointer is structurally incoherent.
    # "cancelled" with an active pointer is suspicious but not necessarily
    # session-blocking; flag as INCONSISTENT to surface for review.
    mode = resolve_gate_mode(raw_handoff)
    print(json.dumps(_violation(
        mode,
        "INCONSISTENT",
        f"Active handoff pointer references a handoff with status {status!r}; "
        "expected 'active' for a pointer that is in use.",
    )))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
