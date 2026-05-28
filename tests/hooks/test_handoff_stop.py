#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# Unit tests for handoff-stop-gate.py (T036 / US5).
# IEEE 1008-1987 §3.2: features under test —
#   F1.  No active handoff pointer → silent allow (no output).
#   F2.  Consistent + complete handoff (all evidence present) → silent allow.
#   F3.  Active handoff, evidence missing → INCOMPLETE block (enforce).
#   F4.  Active handoff, evidence missing → INCOMPLETE warn (warn).
#   F5.  Status "completed", evidence missing → FALSELY_COMPLETED block (enforce).
#   F6.  Status "completed", evidence missing → FALSELY_COMPLETED warn (warn).
#   F7.  Status "completed", all evidence present → silent allow.
#   F8.  Schema validation failure → INCONSISTENT block (enforce).
#   F9.  Schema validation failure → INCONSISTENT warn (warn).
#   F10. Pointer file present but JSON is malformed → INCONSISTENT.
#   F11. Pointer references missing target file → INCONSISTENT.
#   F12. Pointer has non-"active" / non-completed status → INCONSISTENT.
#   F13. SWDT_HANDOFF_GATES absent → gate silent (off mode).
#   F14. Event hook_event_name != Stop → gate silent.
#   F15. Output is valid Stop-hook shape: top-level keys only, no hookSpecificOutput.
#   F16. INCONSISTENT (missing-field) handoff with mode.gate_mode=enforce
#        under env=warn → reported as block (enforce tightening), not warn.

from __future__ import annotations

import importlib.util
import io
import json
import os
import sys
import types
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT))


# ---------------------------------------------------------------------------
# Load gate module
# ---------------------------------------------------------------------------


def _load_gate_module() -> types.ModuleType:
    gate_path = REPO_ROOT / "scripts" / "hooks" / "handoff-stop-gate.py"
    spec = importlib.util.spec_from_file_location("handoff_stop_gate", gate_path)
    mod = importlib.util.module_from_spec(spec)  # type: ignore[arg-type]
    spec.loader.exec_module(mod)  # type: ignore[union-attr]
    return mod


_GATE = _load_gate_module()

# Allowed top-level keys for Stop-hook output per Claude Code schema.
_STOP_HOOK_ALLOWED_KEYS = {
    "continue",
    "suppressOutput",
    "stopReason",
    "decision",
    "reason",
    "systemMessage",
    "terminalSequence",
    "permissionDecision",
    "hookSpecificOutput",
}


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _run_gate(
    event: dict,
    *,
    mode: str,
    handoff: dict | None,
    tmp_path: Path,
    write_pointer: bool = True,
) -> dict | None:
    """Invoke gate.main() with the given event on stdin.

    Returns the parsed top-level JSON dict, or None when gate produced no output.

    When handoff is not None and write_pointer is True, writes the pointer
    and durable handoff files to tmp_path.
    When handoff is None and write_pointer is False, no files are written
    (simulates absent active handoff pointer).
    """
    if handoff is not None and write_pointer:
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
        os.environ["CLAUDE_PROJECT_DIR"] = str(tmp_path)
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
    return json.loads(output)


def _stop_event() -> dict:
    return {"hook_event_name": "Stop"}


def _make_handoff(
    task_id: str = "stop-gate-task-001",
    *,
    status: str = "active",
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
        "status": status,
        "mode": {
            "execution": "standard",
            "codex_allowed": False,
            "codex_server": "none",
        },
        "owner_role": "software-engineer",
        "review_roles": ["code-reviewer"],
        "security_roles": [],
        "objective": "Test stop gate.",
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


_ACCEPTED_REVIEW = {
    "artifact": "docs/reviews/review-001.md",
    "result": "approved",
    "actor_role": "code-reviewer",
    "evidence_kind": "accepted",
}

_ACCEPTED_TEST = {
    "name": "tests/hooks/test-suite.sh",
    "result": "passed",
    "actor_role": "hook",
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


# ---------------------------------------------------------------------------
# F1: no active handoff pointer → silent allow
# ---------------------------------------------------------------------------


def test_f1_no_pointer_silent_allow_enforce(tmp_path: Path) -> None:
    result = _run_gate(
        _stop_event(), mode="enforce", handoff=None, tmp_path=tmp_path, write_pointer=False
    )
    assert result is None, f"expected silent allow (no output), got {result}"


def test_f1_no_pointer_silent_allow_warn(tmp_path: Path) -> None:
    result = _run_gate(
        _stop_event(), mode="warn", handoff=None, tmp_path=tmp_path, write_pointer=False
    )
    assert result is None


# ---------------------------------------------------------------------------
# F2: consistent + complete handoff → silent allow
# ---------------------------------------------------------------------------


def test_f2_complete_handoff_allowed_no_requires(tmp_path: Path) -> None:
    handoff = _make_handoff()  # active, no required gates
    result = _run_gate(_stop_event(), mode="enforce", handoff=handoff, tmp_path=tmp_path)
    assert result is None


def test_f2_complete_handoff_all_evidence_present(tmp_path: Path) -> None:
    handoff = _make_handoff(
        require_review=True,
        review_evidence=[_ACCEPTED_REVIEW],
    )
    result = _run_gate(_stop_event(), mode="enforce", handoff=handoff, tmp_path=tmp_path)
    assert result is None


# ---------------------------------------------------------------------------
# F3/F4: INCOMPLETE — active, evidence missing
# ---------------------------------------------------------------------------


def test_f3_incomplete_review_missing_enforce(tmp_path: Path) -> None:
    handoff = _make_handoff(require_review=True)
    result = _run_gate(_stop_event(), mode="enforce", handoff=handoff, tmp_path=tmp_path)
    assert result is not None
    assert result.get("continue") is False
    assert result.get("decision") == "block"
    assert "INCOMPLETE" in result.get("reason", "")
    assert "review" in result.get("reason", "")


def test_f4_incomplete_review_missing_warn(tmp_path: Path) -> None:
    handoff = _make_handoff(require_review=True)
    result = _run_gate(_stop_event(), mode="warn", handoff=handoff, tmp_path=tmp_path)
    assert result is not None
    assert result.get("continue") is True
    assert "INCOMPLETE" in result.get("systemMessage", "")
    assert "review" in result.get("systemMessage", "")


def test_f3_incomplete_test_missing_enforce(tmp_path: Path) -> None:
    handoff = _make_handoff(require_tests=["tests/hooks/test-suite.sh"])
    result = _run_gate(_stop_event(), mode="enforce", handoff=handoff, tmp_path=tmp_path)
    assert result is not None
    assert result.get("continue") is False
    assert result.get("decision") == "block"
    assert "INCOMPLETE" in result.get("reason", "")


# ---------------------------------------------------------------------------
# F5/F6: FALSELY_COMPLETED — status "completed", evidence missing
# ---------------------------------------------------------------------------


def test_f5_falsely_completed_review_missing_enforce(tmp_path: Path) -> None:
    handoff = _make_handoff(status="completed", require_review=True)
    result = _run_gate(_stop_event(), mode="enforce", handoff=handoff, tmp_path=tmp_path)
    assert result is not None
    assert result.get("continue") is False
    assert result.get("decision") == "block"
    assert "FALSELY_COMPLETED" in result.get("reason", "")
    assert "review" in result.get("reason", "")


def test_f6_falsely_completed_review_missing_warn(tmp_path: Path) -> None:
    handoff = _make_handoff(status="completed", require_review=True)
    result = _run_gate(_stop_event(), mode="warn", handoff=handoff, tmp_path=tmp_path)
    assert result is not None
    assert result.get("continue") is True
    assert "FALSELY_COMPLETED" in result.get("systemMessage", "")
    assert "review" in result.get("systemMessage", "")


def test_f5_falsely_completed_multi_gate_missing(tmp_path: Path) -> None:
    handoff = _make_handoff(
        status="completed",
        require_review=True,
        require_tests=["tests/hooks/test-suite.sh"],
    )
    result = _run_gate(_stop_event(), mode="enforce", handoff=handoff, tmp_path=tmp_path)
    assert result is not None
    assert result.get("continue") is False
    assert result.get("decision") == "block"
    assert "FALSELY_COMPLETED" in result.get("reason", "")


# ---------------------------------------------------------------------------
# F7: status "completed", all evidence present → silent allow
# ---------------------------------------------------------------------------


def test_f7_completed_with_all_evidence_allowed(tmp_path: Path) -> None:
    handoff = _make_handoff(
        status="completed",
        require_review=True,
        review_evidence=[_ACCEPTED_REVIEW],
    )
    result = _run_gate(_stop_event(), mode="enforce", handoff=handoff, tmp_path=tmp_path)
    assert result is None


def test_f7_completed_no_requires_allowed(tmp_path: Path) -> None:
    handoff = _make_handoff(status="completed")
    result = _run_gate(_stop_event(), mode="enforce", handoff=handoff, tmp_path=tmp_path)
    assert result is None


# ---------------------------------------------------------------------------
# F8/F9: schema validation failure → INCONSISTENT
# ---------------------------------------------------------------------------


def test_f8_schema_invalid_missing_owner_enforce(tmp_path: Path) -> None:
    handoff = _make_handoff()
    del handoff["owner_role"]
    result = _run_gate(_stop_event(), mode="enforce", handoff=handoff, tmp_path=tmp_path)
    assert result is not None
    assert result.get("continue") is False
    assert result.get("decision") == "block"
    assert "INCONSISTENT" in result.get("reason", "")


def test_f9_schema_invalid_missing_owner_warn(tmp_path: Path) -> None:
    handoff = _make_handoff()
    del handoff["owner_role"]
    result = _run_gate(_stop_event(), mode="warn", handoff=handoff, tmp_path=tmp_path)
    assert result is not None
    assert result.get("continue") is True
    assert "INCONSISTENT" in result.get("systemMessage", "")


# ---------------------------------------------------------------------------
# F10: pointer file malformed → INCONSISTENT
# ---------------------------------------------------------------------------


def test_f10_pointer_malformed_enforce(tmp_path: Path) -> None:
    devteam = tmp_path / ".devteam"
    devteam.mkdir(parents=True, exist_ok=True)
    (devteam / "active-handoff.json").write_text("not-json{{{", encoding="utf-8")
    result = _run_gate(
        _stop_event(), mode="enforce", handoff=None, tmp_path=tmp_path, write_pointer=False
    )
    assert result is not None
    assert result.get("continue") is False
    assert result.get("decision") == "block"
    assert "INCONSISTENT" in result.get("reason", "")


def test_f10_pointer_malformed_warn(tmp_path: Path) -> None:
    devteam = tmp_path / ".devteam"
    devteam.mkdir(parents=True, exist_ok=True)
    (devteam / "active-handoff.json").write_text("not-json{{{", encoding="utf-8")
    result = _run_gate(
        _stop_event(), mode="warn", handoff=None, tmp_path=tmp_path, write_pointer=False
    )
    assert result is not None
    assert result.get("continue") is True
    assert "INCONSISTENT" in result.get("systemMessage", "")


# ---------------------------------------------------------------------------
# F11: pointer references missing target file → INCONSISTENT
# ---------------------------------------------------------------------------


def test_f11_pointer_missing_target_enforce(tmp_path: Path) -> None:
    devteam = tmp_path / ".devteam"
    devteam.mkdir(parents=True, exist_ok=True)
    (devteam / "active-handoff.json").write_text(
        json.dumps({"handoff_path": "docs/handoffs/nonexistent.json"}),
        encoding="utf-8",
    )
    result = _run_gate(
        _stop_event(), mode="enforce", handoff=None, tmp_path=tmp_path, write_pointer=False
    )
    assert result is not None
    assert result.get("continue") is False
    assert result.get("decision") == "block"
    assert "INCONSISTENT" in result.get("reason", "")


# ---------------------------------------------------------------------------
# F12: non-"active"/non-completed status (e.g. "draft") → INCONSISTENT
# ---------------------------------------------------------------------------


def test_f12_draft_status_inconsistent_enforce(tmp_path: Path) -> None:
    handoff = _make_handoff(status="draft")
    result = _run_gate(_stop_event(), mode="enforce", handoff=handoff, tmp_path=tmp_path)
    assert result is not None
    assert result.get("continue") is False
    assert result.get("decision") == "block"
    assert "INCONSISTENT" in result.get("reason", "")
    assert "draft" in result.get("reason", "")


def test_f12_cancelled_status_inconsistent_warn(tmp_path: Path) -> None:
    handoff = _make_handoff(status="cancelled")
    result = _run_gate(_stop_event(), mode="warn", handoff=handoff, tmp_path=tmp_path)
    assert result is not None
    assert result.get("continue") is True
    assert "INCONSISTENT" in result.get("systemMessage", "")


# ---------------------------------------------------------------------------
# F13: SWDT_HANDOFF_GATES absent → gate silent
# ---------------------------------------------------------------------------


def test_f13_gate_inactive_when_env_unset(tmp_path: Path) -> None:
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

    old_stdin = sys.stdin
    old_stdout = sys.stdout
    old_env = os.environ.copy()
    captured = io.StringIO()
    try:
        sys.stdin = io.TextIOWrapper(
            io.BytesIO(json.dumps(_stop_event()).encode()), encoding="utf-8"
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
# F14: wrong event name → gate silent
# ---------------------------------------------------------------------------


def test_f14_wrong_event_name_silent(tmp_path: Path) -> None:
    handoff = _make_handoff(require_review=True)
    event = {"hook_event_name": "TaskCompleted"}
    result = _run_gate(event, mode="enforce", handoff=handoff, tmp_path=tmp_path)
    assert result is None


def test_f14_subagent_stop_event_silent(tmp_path: Path) -> None:
    handoff = _make_handoff(require_review=True)
    event = {"hook_event_name": "SubagentStop"}
    result = _run_gate(event, mode="enforce", handoff=handoff, tmp_path=tmp_path)
    assert result is None


# ---------------------------------------------------------------------------
# F15: output is a valid Stop-hook top-level shape — no hookSpecificOutput
# ---------------------------------------------------------------------------


def test_f15_enforce_output_valid_stop_hook_shape(tmp_path: Path) -> None:
    handoff = _make_handoff(require_review=True)
    result = _run_gate(_stop_event(), mode="enforce", handoff=handoff, tmp_path=tmp_path)
    assert result is not None
    # All keys must be in the allowed Stop-hook set.
    extra = set(result.keys()) - _STOP_HOOK_ALLOWED_KEYS
    assert not extra, f"unexpected keys in Stop-hook output: {extra}"
    # hookSpecificOutput must NOT be present.
    assert "hookSpecificOutput" not in result, (
        "hookSpecificOutput must not appear in Stop-hook output"
    )


def test_f15_warn_output_valid_stop_hook_shape(tmp_path: Path) -> None:
    handoff = _make_handoff(require_review=True)
    result = _run_gate(_stop_event(), mode="warn", handoff=handoff, tmp_path=tmp_path)
    assert result is not None
    extra = set(result.keys()) - _STOP_HOOK_ALLOWED_KEYS
    assert not extra, f"unexpected keys in Stop-hook output: {extra}"
    assert "hookSpecificOutput" not in result, (
        "hookSpecificOutput must not appear in Stop-hook output"
    )


def test_f15_enforce_uses_continue_false_and_decision_block(tmp_path: Path) -> None:
    handoff = _make_handoff(require_review=True)
    result = _run_gate(_stop_event(), mode="enforce", handoff=handoff, tmp_path=tmp_path)
    assert result is not None
    assert result.get("continue") is False
    assert result.get("decision") == "block"
    assert isinstance(result.get("reason"), str) and result["reason"]


def test_f15_warn_uses_continue_true_and_system_message(tmp_path: Path) -> None:
    handoff = _make_handoff(require_review=True)
    result = _run_gate(_stop_event(), mode="warn", handoff=handoff, tmp_path=tmp_path)
    assert result is not None
    assert result.get("continue") is True
    assert isinstance(result.get("systemMessage"), str) and result["systemMessage"]


# ---------------------------------------------------------------------------
# F16: INCONSISTENT (missing-field) handoff with mode.gate_mode=enforce
#      under env=warn → reported as block (enforce tightening), not warn.
#      Proves resolve_gate_mode(raw_handoff) is called at missing-field branches.
#      These branches are only reachable when jsonschema is absent.
# ---------------------------------------------------------------------------


def test_f16_inconsistent_missing_field_enforce_override_under_warn(
    tmp_path: Path,
) -> None:
    """SHOULD-FIX-1 proof: INCONSISTENT missing-field handoff with
    mode.gate_mode=enforce under env=warn is reported as block (deny)."""
    import unittest.mock as mock

    # Build a handoff that has mode.gate_mode=enforce and lacks allowed_paths.
    # We need to bypass schema validation (which requires allowed_paths) so
    # that the Step-6 structural-integrity check is reached.
    handoff = _make_handoff(require_review=True)
    handoff["mode"]["gate_mode"] = "enforce"
    del handoff["allowed_paths"]

    devteam = tmp_path / ".devteam"
    devteam.mkdir(parents=True, exist_ok=True)
    handoffs_dir = tmp_path / "docs" / "handoffs"
    handoffs_dir.mkdir(parents=True, exist_ok=True)
    fname = f"{handoff['task_id']}.json"
    (handoffs_dir / fname).write_text(json.dumps(handoff), encoding="utf-8")
    (devteam / "active-handoff.json").write_text(
        json.dumps({"handoff_path": f"docs/handoffs/{fname}"}),
        encoding="utf-8",
    )

    old_stdin = sys.stdin
    old_stdout = sys.stdout
    old_env = os.environ.copy()
    captured = io.StringIO()

    # Patch jsonschema.validate at the gate module level so Step 4 is skipped,
    # allowing execution to reach the Step-6 missing-field check.
    try:
        sys.stdin = io.TextIOWrapper(
            io.BytesIO(json.dumps(_stop_event()).encode()), encoding="utf-8"
        )
        sys.stdout = captured
        os.environ["SWDT_HANDOFF_GATES"] = "warn"
        os.environ["CLAUDE_PROJECT_DIR"] = str(tmp_path)
        import jsonschema as _jsonschema_mod
        with mock.patch.object(_jsonschema_mod, "validate", return_value=None):
            rc = _GATE.main()
    finally:
        sys.stdin = old_stdin
        sys.stdout = old_stdout
        os.environ.clear()
        os.environ.update(old_env)

    assert rc == 0
    output = captured.getvalue().strip()
    assert output, "expected gate output for INCONSISTENT missing-field handoff"
    result = json.loads(output)
    # hookSpecificOutput must not be present.
    assert "hookSpecificOutput" not in result, (
        "hookSpecificOutput must not appear in Stop-hook output"
    )
    # mode.gate_mode=enforce must tighten warn→enforce: result must be block.
    assert result.get("continue") is False, (
        f"expected continue=false (enforce tightening), got: {result}"
    )
    assert result.get("decision") == "block", (
        f"expected decision=block (enforce tightening), got: {result}"
    )
    assert "INCONSISTENT" in result.get("reason", "")
