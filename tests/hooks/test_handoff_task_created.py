#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# Unit / smoke tests for handoff-task-created-gate.py (T033 / US4).
# IEEE 1008-1987 §3.2: features under test —
#   F1.  Valid owner_role + matching active handoff citation → no output (allowed).
#   F2.  Missing owner_role (empty string) → deny (enforce) / warn (warn).
#   F3.  Non-canonical owner_role string → deny (enforce) / warn (warn).
#   F4.  Missing handoff citation field → deny / warn.
#   F5.  Handoff citation does not match active handoff task_id → deny / warn.
#   F6.  No/invalid active handoff file → fail-safe per mode.
#   F7.  SWDT_HANDOFF_GATES absent → no output (gate is silent).
#   F8.  Event hook_event_name != TaskCreated → no output (ignored).
#   F9.  sme-<slug> dynamic role accepted as canonical.
#   F10. active_handoff_task_id field accepted as alternate citation key.

from __future__ import annotations

import importlib.util
import json
import os
import sys
import types
from pathlib import Path
from typing import Any

import pytest

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT))

# ---------------------------------------------------------------------------
# Helpers to invoke the gate through its main() function with controlled stdin
# ---------------------------------------------------------------------------

def _load_gate_module() -> types.ModuleType:
    gate_path = REPO_ROOT / "scripts" / "hooks" / "handoff-task-created-gate.py"
    spec = importlib.util.spec_from_file_location("handoff_task_created_gate", gate_path)
    mod = importlib.util.module_from_spec(spec)  # type: ignore[arg-type]
    spec.loader.exec_module(mod)  # type: ignore[union-attr]
    return mod


_GATE = _load_gate_module()


def _run_gate(
    event: dict,
    *,
    mode: str,
    handoff: dict | None,
    tmp_path: Path,
) -> dict | None:
    """
    Invoke gate.main() with the given event on stdin.
    Returns parsed hookSpecificOutput dict, or None if gate produced no output.
    """
    # Build sandbox
    if handoff is not None:
        devteam = tmp_path / ".devteam"
        devteam.mkdir(parents=True, exist_ok=True)
        handoffs_dir = tmp_path / "docs" / "handoffs"
        handoffs_dir.mkdir(parents=True, exist_ok=True)
        fname = f"{handoff.get('task_id', 'test-handoff')}.json"
        (handoffs_dir / fname).write_text(json.dumps(handoff), encoding="utf-8")
        (devteam / "active-handoff.json").write_text(
            json.dumps({"handoff_path": f"docs/handoffs/{fname}"}),
            encoding="utf-8",
        )

    import io

    old_stdin = sys.stdin
    old_stdout = sys.stdout
    old_env = os.environ.copy()
    captured = io.StringIO()

    try:
        sys.stdin = io.TextIOWrapper(
            io.BytesIO(json.dumps(event).encode()), encoding="utf-8"
        )
        sys.stdout = captured
        os.environ["SWDT_HANDOFF_GATES"] = mode
        if handoff is not None:
            os.environ["CLAUDE_PROJECT_DIR"] = str(tmp_path)
        elif "CLAUDE_PROJECT_DIR" in os.environ:
            # Remove so the gate falls back to cwd (which has no active-handoff.json)
            del os.environ["CLAUDE_PROJECT_DIR"]

        rc = _GATE.main()
    finally:
        sys.stdin = old_stdin
        sys.stdout = old_stdout
        os.environ.clear()
        os.environ.update(old_env)

    assert rc == 0, f"gate exited non-zero: {rc}"
    output = captured.getvalue().strip()
    if not output:
        return None
    payload = json.loads(output)
    return payload.get("hookSpecificOutput")


def _make_handoff(task_id: str = "active-task-001") -> dict:
    """Minimal valid handoff fixture for sandbox."""
    return {
        "schema": "https://example.invalid/sw-dev-team-template/handoff.schema.json",
        "task_id": task_id,
        "status": "active",
        "mode": {
            "execution": "standard",
            "codex_allowed": False,
            "codex_server": "none",
        },
        "owner_role": "software-engineer",
        "review_roles": ["code-reviewer"],
        "security_roles": [],
        "objective": "Test active handoff for task-created gate.",
        "allowed_paths": ["scripts/**", "tests/**"],
        "forbidden_paths": [".claude/**"],
        "framework_scope": "framework-maintenance",
        "requires": {
            "tests": [],
            "review": False,
            "security_review": False,
            "human_approval": False,
        },
        "acceptance_criteria": ["Gate rejects tasks without role citation."],
        "hard_rule_traces": [],
        "activity": [],
        "verification": {
            "tests": [],
            "reviews": [],
            "security": [],
            "human_approval": [],
        },
        "completion": {"claimed_by": None, "completed_at": None, "evidence": []},
    }


def _task_created_event(
    owner_role: str | None = "software-engineer",
    handoff_task_id: str | None = "active-task-001",
    use_alternate_key: bool = False,
) -> dict:
    event: dict[str, Any] = {"hook_event_name": "TaskCreated"}
    if owner_role is not None:
        event["owner_role"] = owner_role
    if handoff_task_id is not None:
        key = "active_handoff_task_id" if use_alternate_key else "handoff_task_id"
        event[key] = handoff_task_id
    return event


# ---------------------------------------------------------------------------
# F1: valid owner_role + matching citation → no output
# ---------------------------------------------------------------------------


def test_f1_valid_event_allowed_enforce(tmp_path: Path) -> None:
    handoff = _make_handoff("active-task-001")
    event = _task_created_event("software-engineer", "active-task-001")
    result = _run_gate(event, mode="enforce", handoff=handoff, tmp_path=tmp_path)
    assert result is None, f"expected no output (allowed), got {result}"


def test_f1_valid_event_allowed_warn(tmp_path: Path) -> None:
    handoff = _make_handoff("active-task-001")
    event = _task_created_event("architect", "active-task-001")
    result = _run_gate(event, mode="warn", handoff=handoff, tmp_path=tmp_path)
    assert result is None


# ---------------------------------------------------------------------------
# F2: missing owner_role → deny (enforce) / warn (warn)
# ---------------------------------------------------------------------------


def test_f2_missing_owner_role_enforce(tmp_path: Path) -> None:
    handoff = _make_handoff("active-task-001")
    event = _task_created_event(owner_role=None, handoff_task_id="active-task-001")
    result = _run_gate(event, mode="enforce", handoff=handoff, tmp_path=tmp_path)
    assert result is not None
    assert result["permissionDecision"] == "deny"
    assert "canonical owner role" in result["permissionDecisionReason"]


def test_f2_missing_owner_role_warn(tmp_path: Path) -> None:
    handoff = _make_handoff("active-task-001")
    event = _task_created_event(owner_role=None, handoff_task_id="active-task-001")
    result = _run_gate(event, mode="warn", handoff=handoff, tmp_path=tmp_path)
    assert result is not None
    assert result["permissionDecision"] == "allow"
    assert "warning" in result


# ---------------------------------------------------------------------------
# F3: non-canonical owner_role → deny / warn
# ---------------------------------------------------------------------------


def test_f3_non_canonical_role_enforce(tmp_path: Path) -> None:
    handoff = _make_handoff("active-task-001")
    event = _task_created_event(owner_role="random-made-up-role", handoff_task_id="active-task-001")
    result = _run_gate(event, mode="enforce", handoff=handoff, tmp_path=tmp_path)
    assert result is not None
    assert result["permissionDecision"] == "deny"


def test_f3_non_canonical_role_warn(tmp_path: Path) -> None:
    handoff = _make_handoff("active-task-001")
    event = _task_created_event(owner_role="customer", handoff_task_id="active-task-001")
    result = _run_gate(event, mode="warn", handoff=handoff, tmp_path=tmp_path)
    assert result is not None
    assert result["permissionDecision"] == "allow"
    assert "warning" in result


# ---------------------------------------------------------------------------
# F4: missing handoff citation field → deny / warn
# ---------------------------------------------------------------------------


def test_f4_missing_handoff_citation_enforce(tmp_path: Path) -> None:
    handoff = _make_handoff("active-task-001")
    event = _task_created_event("software-engineer", handoff_task_id=None)
    result = _run_gate(event, mode="enforce", handoff=handoff, tmp_path=tmp_path)
    assert result is not None
    assert result["permissionDecision"] == "deny"
    assert "active handoff" in result["permissionDecisionReason"]


def test_f4_missing_handoff_citation_warn(tmp_path: Path) -> None:
    handoff = _make_handoff("active-task-001")
    event = _task_created_event("tech-lead", handoff_task_id=None)
    result = _run_gate(event, mode="warn", handoff=handoff, tmp_path=tmp_path)
    assert result is not None
    assert result["permissionDecision"] == "allow"
    assert "warning" in result


# ---------------------------------------------------------------------------
# F5: handoff citation mismatch → deny / warn
# ---------------------------------------------------------------------------


def test_f5_handoff_citation_mismatch_enforce(tmp_path: Path) -> None:
    handoff = _make_handoff("active-task-001")
    event = _task_created_event("software-engineer", handoff_task_id="some-other-task")
    result = _run_gate(event, mode="enforce", handoff=handoff, tmp_path=tmp_path)
    assert result is not None
    assert result["permissionDecision"] == "deny"
    assert "active-task-001" in result["permissionDecisionReason"]


def test_f5_handoff_citation_mismatch_warn(tmp_path: Path) -> None:
    handoff = _make_handoff("active-task-001")
    event = _task_created_event("qa-engineer", handoff_task_id="wrong-task-id")
    result = _run_gate(event, mode="warn", handoff=handoff, tmp_path=tmp_path)
    assert result is not None
    assert result["permissionDecision"] == "allow"
    assert "warning" in result


# ---------------------------------------------------------------------------
# F6: no/invalid active handoff → fail-safe per mode
# ---------------------------------------------------------------------------


def test_f6_no_active_handoff_enforce(tmp_path: Path) -> None:
    # No handoff written to sandbox
    event = _task_created_event("software-engineer", "nonexistent-task")
    result = _run_gate(event, mode="enforce", handoff=None, tmp_path=tmp_path)
    # enforce: should deny with load-failure reason
    assert result is not None
    assert result["permissionDecision"] == "deny"


def test_f6_no_active_handoff_warn(tmp_path: Path) -> None:
    event = _task_created_event("software-engineer", "nonexistent-task")
    result = _run_gate(event, mode="warn", handoff=None, tmp_path=tmp_path)
    # warn: should allow but with warning
    assert result is not None
    assert result["permissionDecision"] == "allow"
    assert "warning" in result


# ---------------------------------------------------------------------------
# F7: SWDT_HANDOFF_GATES absent → silent (no output)
# ---------------------------------------------------------------------------


def test_f7_gate_inactive_when_env_unset(tmp_path: Path) -> None:
    handoff = _make_handoff("active-task-001")
    # Build valid event that would normally trigger a violation
    event = _task_created_event(owner_role=None, handoff_task_id=None)

    devteam = tmp_path / ".devteam"
    devteam.mkdir(parents=True, exist_ok=True)
    handoffs_dir = tmp_path / "docs" / "handoffs"
    handoffs_dir.mkdir(parents=True, exist_ok=True)
    fname = "active-task-001.json"
    (handoffs_dir / fname).write_text(json.dumps(handoff), encoding="utf-8")
    (devteam / "active-handoff.json").write_text(
        json.dumps({"handoff_path": f"docs/handoffs/{fname}"}), encoding="utf-8"
    )

    import io

    old_stdin = sys.stdin
    old_stdout = sys.stdout
    old_env = os.environ.copy()
    captured = io.StringIO()
    try:
        sys.stdin = io.TextIOWrapper(
            io.BytesIO(json.dumps(event).encode()), encoding="utf-8"
        )
        sys.stdout = captured
        os.environ.pop("SWDT_HANDOFF_GATES", None)
        os.environ["CLAUDE_PROJECT_DIR"] = str(tmp_path)
        rc = _GATE.main()
    finally:
        sys.stdin = old_stdin
        sys.stdout = old_stdout
        os.environ.clear()
        os.environ.update(old_env)

    assert rc == 0
    assert captured.getvalue().strip() == ""


# ---------------------------------------------------------------------------
# F8: non-TaskCreated event → silent
# ---------------------------------------------------------------------------


def test_f8_non_task_created_event_ignored(tmp_path: Path) -> None:
    handoff = _make_handoff("active-task-001")
    event = {
        "hook_event_name": "PreToolUse",
        "owner_role": "random-role",
    }
    result = _run_gate(event, mode="enforce", handoff=handoff, tmp_path=tmp_path)
    assert result is None


# ---------------------------------------------------------------------------
# F9: sme-<slug> dynamic role accepted
# ---------------------------------------------------------------------------


def test_f9_sme_slug_role_accepted(tmp_path: Path) -> None:
    handoff = _make_handoff("active-task-001")
    event = _task_created_event("sme-brewing", "active-task-001")
    result = _run_gate(event, mode="enforce", handoff=handoff, tmp_path=tmp_path)
    assert result is None


# ---------------------------------------------------------------------------
# F10: active_handoff_task_id alternate key accepted
# ---------------------------------------------------------------------------


def test_f10_alternate_citation_key_accepted(tmp_path: Path) -> None:
    handoff = _make_handoff("active-task-001")
    event = _task_created_event("researcher", "active-task-001", use_alternate_key=True)
    result = _run_gate(event, mode="enforce", handoff=handoff, tmp_path=tmp_path)
    assert result is None


# ---------------------------------------------------------------------------
# hookEventName field is always "TaskCreated" in output
# ---------------------------------------------------------------------------


def test_deny_output_declares_task_created_event_name(tmp_path: Path) -> None:
    handoff = _make_handoff("active-task-001")
    event = _task_created_event(owner_role=None, handoff_task_id="active-task-001")
    result = _run_gate(event, mode="enforce", handoff=handoff, tmp_path=tmp_path)
    assert result is not None
    assert result.get("hookEventName") == "TaskCreated"


def test_warn_output_declares_task_created_event_name(tmp_path: Path) -> None:
    handoff = _make_handoff("active-task-001")
    event = _task_created_event(owner_role=None, handoff_task_id="active-task-001")
    result = _run_gate(event, mode="warn", handoff=handoff, tmp_path=tmp_path)
    assert result is not None
    assert result.get("hookEventName") == "TaskCreated"
