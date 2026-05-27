#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# Unit tests for handoff-subagent-stop-gate.py (T035 / US5).
# IEEE 1008-1987 §3.2: features under test —
#   F1.  Required specialist evidence present → no output (allowed).
#   F2.  code-reviewer returns, review evidence missing → deny (enforce).
#   F3.  code-reviewer returns, review evidence missing → warn (warn).
#   F4.  security-engineer returns, security evidence missing → deny (enforce).
#   F5.  security-engineer returns, security evidence missing → warn (warn).
#   F6.  researcher returns, human_approval evidence missing → deny (enforce).
#   F7.  researcher returns, human_approval evidence missing → warn (warn).
#   F8.  No subagent_role in event → full gate set checked (fallback).
#   F9.  No/invalid active handoff → fail-safe: enforce denies, warn allows.
#   F10. SWDT_HANDOFF_GATES absent → gate silent (no output).
#   F11. Event hook_event_name != SubagentStop → gate silent.
#   F12. code-reviewer returns, review evidence present → no output.
#   F13. generic role returns, all gates satisfied → no output.
#   F14. hookEventName field in output is always "SubagentStop".

from __future__ import annotations

import importlib.util
import io
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
# Load gate module
# ---------------------------------------------------------------------------


def _load_gate_module() -> types.ModuleType:
    gate_path = REPO_ROOT / "scripts" / "hooks" / "handoff-subagent-stop-gate.py"
    spec = importlib.util.spec_from_file_location("handoff_subagent_stop_gate", gate_path)
    mod = importlib.util.module_from_spec(spec)  # type: ignore[arg-type]
    spec.loader.exec_module(mod)  # type: ignore[union-attr]
    return mod


_GATE = _load_gate_module()


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _run_gate(
    event: dict,
    *,
    mode: str,
    handoff: dict | None,
    tmp_path: Path,
) -> dict | None:
    """Invoke gate.main() with the given event on stdin.
    Returns parsed hookSpecificOutput dict, or None when gate produced no output.
    """
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


def _make_handoff(
    task_id: str = "stop-gate-task-001",
    *,
    require_review: bool = False,
    require_security: bool = False,
    require_human_approval: bool = False,
    require_tests: list[str] | None = None,
    review_evidence: list[dict] | None = None,
    security_evidence: list[dict] | None = None,
    human_approval_evidence: list[dict] | None = None,
    test_evidence: list[dict] | None = None,
) -> dict:
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
        "objective": "Test subagent stop gate.",
        "allowed_paths": ["scripts/**"],
        "forbidden_paths": [],
        "framework_scope": "framework-maintenance",
        "requires": {
            "tests": require_tests or [],
            "review": require_review,
            "security_review": require_security,
            "human_approval": require_human_approval,
        },
        "acceptance_criteria": [],
        "hard_rule_traces": [],
        "activity": [],
        "verification": {
            "tests": test_evidence or [],
            "reviews": review_evidence or [],
            "security": security_evidence or [],
            "human_approval": human_approval_evidence or [],
        },
        "completion": {"claimed_by": None, "completed_at": None, "evidence": []},
    }


def _stop_event(subagent_role: str | None = None) -> dict:
    event: dict[str, Any] = {"hook_event_name": "SubagentStop"}
    if subagent_role is not None:
        event["subagent_role"] = subagent_role
    return event


_ACCEPTED_REVIEW = {
    "artifact": "docs/reviews/review-001.md",
    "result": "approved",
    "actor_role": "code-reviewer",
    "evidence_kind": "accepted",
}

_ACCEPTED_SECURITY = {
    "artifact": "docs/security/sign-off-001.md",
    "result": "approved",
    "actor_role": "security-engineer",
    "evidence_kind": "accepted",
}

_ACCEPTED_HUMAN_APPROVAL = {
    "result": "approved",
    "actor_role": "researcher",
    "source": "CUSTOMER_NOTES.md",
    "evidence_kind": "accepted",
}

_ACCEPTED_TEST = {
    "name": "tests/hooks/test-suite.sh",
    "result": "passed",
    "actor_role": "hook",
    "evidence_kind": "accepted",
}


# ---------------------------------------------------------------------------
# F1: all required evidence present → no output (allowed)
# ---------------------------------------------------------------------------


def test_f1_all_evidence_present_allowed_enforce(tmp_path: Path) -> None:
    handoff = _make_handoff(
        require_review=True,
        require_tests=["tests/hooks/test-suite.sh"],
        review_evidence=[_ACCEPTED_REVIEW],
        test_evidence=[_ACCEPTED_TEST],
    )
    event = _stop_event("software-engineer")
    result = _run_gate(event, mode="enforce", handoff=handoff, tmp_path=tmp_path)
    assert result is None, f"expected no output (allowed), got {result}"


def test_f1_all_evidence_present_allowed_warn(tmp_path: Path) -> None:
    handoff = _make_handoff(
        require_review=True,
        review_evidence=[_ACCEPTED_REVIEW],
    )
    event = _stop_event("software-engineer")
    result = _run_gate(event, mode="warn", handoff=handoff, tmp_path=tmp_path)
    assert result is None


# ---------------------------------------------------------------------------
# F2/F3: code-reviewer returns, review evidence missing
# ---------------------------------------------------------------------------


def test_f2_code_reviewer_missing_review_enforce(tmp_path: Path) -> None:
    handoff = _make_handoff(require_review=True)
    event = _stop_event("code-reviewer")
    result = _run_gate(event, mode="enforce", handoff=handoff, tmp_path=tmp_path)
    assert result is not None
    assert result["permissionDecision"] == "deny"
    assert "review" in result["permissionDecisionReason"]
    assert "code-reviewer" in result["permissionDecisionReason"]


def test_f3_code_reviewer_missing_review_warn(tmp_path: Path) -> None:
    handoff = _make_handoff(require_review=True)
    event = _stop_event("code-reviewer")
    result = _run_gate(event, mode="warn", handoff=handoff, tmp_path=tmp_path)
    assert result is not None
    assert result["permissionDecision"] == "allow"
    assert "warning" in result
    assert "review" in result["warning"]


# ---------------------------------------------------------------------------
# F4/F5: security-engineer returns, security evidence missing
# ---------------------------------------------------------------------------


def test_f4_security_engineer_missing_security_enforce(tmp_path: Path) -> None:
    handoff = _make_handoff(require_security=True)
    event = _stop_event("security-engineer")
    result = _run_gate(event, mode="enforce", handoff=handoff, tmp_path=tmp_path)
    assert result is not None
    assert result["permissionDecision"] == "deny"
    assert "security_review" in result["permissionDecisionReason"]


def test_f5_security_engineer_missing_security_warn(tmp_path: Path) -> None:
    handoff = _make_handoff(require_security=True)
    event = _stop_event("security-engineer")
    result = _run_gate(event, mode="warn", handoff=handoff, tmp_path=tmp_path)
    assert result is not None
    assert result["permissionDecision"] == "allow"
    assert "warning" in result
    assert "security_review" in result["warning"]


# ---------------------------------------------------------------------------
# F6/F7: researcher returns, human_approval evidence missing
# ---------------------------------------------------------------------------


def test_f6_researcher_missing_human_approval_enforce(tmp_path: Path) -> None:
    handoff = _make_handoff(require_human_approval=True)
    event = _stop_event("researcher")
    result = _run_gate(event, mode="enforce", handoff=handoff, tmp_path=tmp_path)
    assert result is not None
    assert result["permissionDecision"] == "deny"
    assert "human_approval" in result["permissionDecisionReason"]


def test_f7_researcher_missing_human_approval_warn(tmp_path: Path) -> None:
    handoff = _make_handoff(require_human_approval=True)
    event = _stop_event("researcher")
    result = _run_gate(event, mode="warn", handoff=handoff, tmp_path=tmp_path)
    assert result is not None
    assert result["permissionDecision"] == "allow"
    assert "warning" in result
    assert "human_approval" in result["warning"]


# ---------------------------------------------------------------------------
# F8: no subagent_role → full gate set checked (conservative fallback)
# ---------------------------------------------------------------------------


def test_f8_no_role_full_gate_check_deny(tmp_path: Path) -> None:
    handoff = _make_handoff(require_review=True)
    event = _stop_event(subagent_role=None)
    result = _run_gate(event, mode="enforce", handoff=handoff, tmp_path=tmp_path)
    assert result is not None
    assert result["permissionDecision"] == "deny"
    assert "review" in result["permissionDecisionReason"]


def test_f8_no_role_full_gate_check_warn(tmp_path: Path) -> None:
    handoff = _make_handoff(require_review=True)
    event = _stop_event(subagent_role=None)
    result = _run_gate(event, mode="warn", handoff=handoff, tmp_path=tmp_path)
    assert result is not None
    assert result["permissionDecision"] == "allow"
    assert "warning" in result


def test_f8_no_role_all_gates_satisfied_allowed(tmp_path: Path) -> None:
    handoff = _make_handoff(
        require_review=True,
        review_evidence=[_ACCEPTED_REVIEW],
    )
    event = _stop_event(subagent_role=None)
    result = _run_gate(event, mode="enforce", handoff=handoff, tmp_path=tmp_path)
    assert result is None


# ---------------------------------------------------------------------------
# F9: no/invalid active handoff → fail-safe
# ---------------------------------------------------------------------------


def test_f9_no_active_handoff_enforce(tmp_path: Path) -> None:
    event = _stop_event("software-engineer")
    result = _run_gate(event, mode="enforce", handoff=None, tmp_path=tmp_path)
    assert result is not None
    assert result["permissionDecision"] == "deny"


def test_f9_no_active_handoff_warn(tmp_path: Path) -> None:
    event = _stop_event("software-engineer")
    result = _run_gate(event, mode="warn", handoff=None, tmp_path=tmp_path)
    assert result is not None
    assert result["permissionDecision"] == "allow"
    assert "warning" in result


# ---------------------------------------------------------------------------
# F10: SWDT_HANDOFF_GATES absent → gate silent
# ---------------------------------------------------------------------------


def test_f10_gate_inactive_when_env_unset(tmp_path: Path) -> None:
    handoff = _make_handoff(require_review=True)
    devteam = tmp_path / ".devteam"
    devteam.mkdir(parents=True, exist_ok=True)
    handoffs_dir = tmp_path / "docs" / "handoffs"
    handoffs_dir.mkdir(parents=True, exist_ok=True)
    fname = f"{handoff['task_id']}.json"
    (handoffs_dir / fname).write_text(json.dumps(handoff), encoding="utf-8")
    (devteam / "active-handoff.json").write_text(
        json.dumps({"handoff_path": f"docs/handoffs/{fname}"}), encoding="utf-8"
    )

    event = _stop_event("code-reviewer")
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
# F11: wrong event name → gate silent
# ---------------------------------------------------------------------------


def test_f11_wrong_event_name_silent(tmp_path: Path) -> None:
    handoff = _make_handoff(require_review=True)
    event = {"hook_event_name": "TaskCompleted", "subagent_role": "code-reviewer"}
    result = _run_gate(event, mode="enforce", handoff=handoff, tmp_path=tmp_path)
    assert result is None


# ---------------------------------------------------------------------------
# F12: code-reviewer returns, review evidence present → no output
# ---------------------------------------------------------------------------


def test_f12_code_reviewer_with_review_evidence_allowed(tmp_path: Path) -> None:
    handoff = _make_handoff(
        require_review=True,
        review_evidence=[_ACCEPTED_REVIEW],
    )
    event = _stop_event("code-reviewer")
    result = _run_gate(event, mode="enforce", handoff=handoff, tmp_path=tmp_path)
    assert result is None


# ---------------------------------------------------------------------------
# F13: generic role returns, all gates satisfied → no output
# ---------------------------------------------------------------------------


def test_f13_generic_role_all_satisfied_allowed(tmp_path: Path) -> None:
    handoff = _make_handoff(
        require_review=True,
        require_tests=["tests/hooks/test-suite.sh"],
        review_evidence=[_ACCEPTED_REVIEW],
        test_evidence=[_ACCEPTED_TEST],
    )
    event = _stop_event("architect")
    result = _run_gate(event, mode="enforce", handoff=handoff, tmp_path=tmp_path)
    assert result is None


# ---------------------------------------------------------------------------
# F14: hookEventName in output is always "SubagentStop"
# ---------------------------------------------------------------------------


def test_f14_hook_event_name_in_deny_output(tmp_path: Path) -> None:
    handoff = _make_handoff(require_review=True)
    event = _stop_event("code-reviewer")
    result = _run_gate(event, mode="enforce", handoff=handoff, tmp_path=tmp_path)
    assert result is not None
    assert result.get("hookEventName") == "SubagentStop"


def test_f14_hook_event_name_in_warn_output(tmp_path: Path) -> None:
    handoff = _make_handoff(require_review=True)
    event = _stop_event("code-reviewer")
    result = _run_gate(event, mode="warn", handoff=handoff, tmp_path=tmp_path)
    assert result is not None
    assert result.get("hookEventName") == "SubagentStop"


# ---------------------------------------------------------------------------
# Role does not own a bucket but no gates are required → no output
# ---------------------------------------------------------------------------


def test_role_specific_no_requirement_allowed(tmp_path: Path) -> None:
    """code-reviewer returns but handoff does not require review → allowed."""
    handoff = _make_handoff(require_review=False)
    event = _stop_event("code-reviewer")
    result = _run_gate(event, mode="enforce", handoff=handoff, tmp_path=tmp_path)
    assert result is None


def test_security_engineer_no_requirement_allowed(tmp_path: Path) -> None:
    handoff = _make_handoff(require_security=False)
    event = _stop_event("security-engineer")
    result = _run_gate(event, mode="enforce", handoff=handoff, tmp_path=tmp_path)
    assert result is None
