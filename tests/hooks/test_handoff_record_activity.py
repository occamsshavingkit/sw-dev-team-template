#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# Unit / smoke tests for scripts/hooks/handoff-record-activity.py (T019).
# IEEE 1008-1987 §3.2: features under test —
#   F1.  No-op when SWDT_HANDOFF_GATES is unset or unrecognised.
#   F2.  No-op when stdin is not valid JSON.
#   F3.  Warm-mode non-blocking when active handoff cannot be loaded.
#   F4.  Evidence entry appended to verification.tests with correct fields.
#   F5.  evidence_kind is "accepted" (hook-captured, not worker_report).
#   F6.  Atomic write: original file is replaced, not left as .tmp.
#   F7.  Existing verification.tests entries are preserved after append.
#   F8.  Path containment: absolute handoff_path in pointer is rejected (S-1).

from __future__ import annotations

import copy
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parents[2]
HOOK = REPO_ROOT / "scripts" / "hooks" / "handoff-record-activity.py"
FIXTURE_DIR = REPO_ROOT / "tests" / "hooks" / "fixtures" / "handoff"


# ---------------------------------------------------------------------------
# Fixture helpers
# ---------------------------------------------------------------------------


def _make_sandbox(fixture_name: str) -> Path:
    """Return a temp directory wired up as a minimal repo sandbox."""
    tmp = Path(tempfile.mkdtemp())
    (tmp / ".devteam").mkdir()
    (tmp / "docs" / "handoffs").mkdir(parents=True)
    src = FIXTURE_DIR / fixture_name
    dst = tmp / "docs" / "handoffs" / fixture_name
    dst.write_text(src.read_text(encoding="utf-8"), encoding="utf-8")
    (tmp / ".devteam" / "active-handoff.json").write_text(
        json.dumps({"handoff_path": f"docs/handoffs/{fixture_name}"}),
        encoding="utf-8",
    )
    return tmp


def _run_hook(event: dict, sandbox: Path, mode: str = "warn") -> subprocess.CompletedProcess:
    env = {**os.environ, "SWDT_HANDOFF_GATES": mode, "CLAUDE_PROJECT_DIR": str(sandbox)}
    return subprocess.run(
        [sys.executable, str(HOOK)],
        input=json.dumps(event),
        capture_output=True,
        text=True,
        env=env,
    )


def _sample_event(tool_name: str = "Bash", command: str = "pytest tests/") -> dict:
    return {
        "hook_event_name": "PostToolUse",
        "tool_name": tool_name,
        "tool_input": {"command": command},
    }


# ---------------------------------------------------------------------------
# F1 — no-op when gate mode unset or unrecognised
# ---------------------------------------------------------------------------
def test_noop_when_mode_unset(tmp_path: Path) -> None:
    env = {**os.environ}
    env.pop("SWDT_HANDOFF_GATES", None)
    env["CLAUDE_PROJECT_DIR"] = str(tmp_path)
    result = subprocess.run(
        [sys.executable, str(HOOK)],
        input=json.dumps(_sample_event()),
        capture_output=True,
        text=True,
        env=env,
    )
    assert result.returncode == 0
    assert result.stdout == ""


def test_noop_when_mode_unknown(tmp_path: Path) -> None:
    env = {**os.environ, "SWDT_HANDOFF_GATES": "off", "CLAUDE_PROJECT_DIR": str(tmp_path)}
    result = subprocess.run(
        [sys.executable, str(HOOK)],
        input=json.dumps(_sample_event()),
        capture_output=True,
        text=True,
        env=env,
    )
    assert result.returncode == 0
    assert result.stdout == ""


# ---------------------------------------------------------------------------
# F2 — no-op when stdin is not valid JSON
# ---------------------------------------------------------------------------
def test_noop_invalid_stdin_json(tmp_path: Path) -> None:
    env = {**os.environ, "SWDT_HANDOFF_GATES": "warn", "CLAUDE_PROJECT_DIR": str(tmp_path)}
    result = subprocess.run(
        [sys.executable, str(HOOK)],
        input="not json",
        capture_output=True,
        text=True,
        env=env,
    )
    assert result.returncode == 0
    assert result.stdout == ""


# ---------------------------------------------------------------------------
# F3 — non-blocking when no active handoff (missing .devteam dir)
# ---------------------------------------------------------------------------
def test_nonblocking_no_active_handoff(tmp_path: Path) -> None:
    result = _run_hook(_sample_event(), sandbox=tmp_path, mode="warn")
    assert result.returncode == 0
    # No stdout JSON (no permission decision emitted)
    assert result.stdout == ""


def test_nonblocking_no_active_handoff_enforce(tmp_path: Path) -> None:
    result = _run_hook(_sample_event(), sandbox=tmp_path, mode="enforce")
    assert result.returncode == 0
    assert result.stdout == ""


# ---------------------------------------------------------------------------
# F4 — evidence entry appended with correct fields
# ---------------------------------------------------------------------------
def test_appends_evidence_entry() -> None:
    sandbox = _make_sandbox("completion-evidence-satisfied.json")
    try:
        event = _sample_event(tool_name="Bash", command="pytest tests/hooks/")
        result = _run_hook(event, sandbox=sandbox, mode="warn")
        assert result.returncode == 0

        handoff_path = sandbox / "docs" / "handoffs" / "completion-evidence-satisfied.json"
        updated = json.loads(handoff_path.read_text(encoding="utf-8"))
        tests = updated["verification"]["tests"]

        # At least one new entry added
        new_entries = [e for e in tests if e.get("actor_role") == "hook"]
        assert len(new_entries) == 1, f"expected 1 hook entry, got {new_entries}"
        entry = new_entries[0]
        assert entry["result"] == "passed"
        assert entry["source"] == "PostToolUse"
        assert "Bash" in entry["name"]
    finally:
        import shutil
        shutil.rmtree(sandbox)


# ---------------------------------------------------------------------------
# F5 — evidence_kind is "accepted"
# ---------------------------------------------------------------------------
def test_evidence_kind_is_accepted() -> None:
    sandbox = _make_sandbox("completion-evidence-satisfied.json")
    try:
        result = _run_hook(_sample_event(), sandbox=sandbox, mode="warn")
        assert result.returncode == 0

        handoff_path = sandbox / "docs" / "handoffs" / "completion-evidence-satisfied.json"
        updated = json.loads(handoff_path.read_text(encoding="utf-8"))
        hook_entries = [e for e in updated["verification"]["tests"] if e.get("actor_role") == "hook"]
        assert hook_entries, "no hook entry found"
        assert hook_entries[0]["evidence_kind"] == "accepted"
    finally:
        import shutil
        shutil.rmtree(sandbox)


# ---------------------------------------------------------------------------
# F6 — atomic write: no .tmp file left behind
# ---------------------------------------------------------------------------
def test_no_tmp_file_left_after_write() -> None:
    sandbox = _make_sandbox("completion-evidence-satisfied.json")
    try:
        result = _run_hook(_sample_event(), sandbox=sandbox, mode="warn")
        assert result.returncode == 0

        handoffs_dir = sandbox / "docs" / "handoffs"
        tmp_files = list(handoffs_dir.glob(".tmp-*"))
        assert tmp_files == [], f"unexpected .tmp files left: {tmp_files}"
    finally:
        import shutil
        shutil.rmtree(sandbox)


# ---------------------------------------------------------------------------
# F7 — existing tests entries are preserved after append
# ---------------------------------------------------------------------------
def test_existing_entries_preserved() -> None:
    sandbox = _make_sandbox("completion-evidence-satisfied.json")
    try:
        handoff_path = sandbox / "docs" / "handoffs" / "completion-evidence-satisfied.json"
        before = json.loads(handoff_path.read_text(encoding="utf-8"))
        original_tests = copy.deepcopy(before["verification"]["tests"])
        original_count = len(original_tests)

        result = _run_hook(_sample_event(), sandbox=sandbox, mode="warn")
        assert result.returncode == 0

        updated = json.loads(handoff_path.read_text(encoding="utf-8"))
        updated_tests = updated["verification"]["tests"]
        assert len(updated_tests) == original_count + 1

        # All original entries still present (by identity comparison)
        for orig in original_tests:
            assert orig in updated_tests
    finally:
        import shutil
        shutil.rmtree(sandbox)


# ---------------------------------------------------------------------------
# F8 — path containment: absolute handoff_path is rejected (S-1)
# ---------------------------------------------------------------------------


def test_absolute_handoff_path_rejected_exits_zero(tmp_path: Path) -> None:
    """S-1: pointer with an absolute handoff_path must not write outside repo and must exit 0."""
    # Set up a real handoff file at an absolute path OUTSIDE the sandbox.
    outside_dir = Path(tempfile.mkdtemp())
    try:
        # Copy a valid handoff fixture to the outside location.
        outside_handoff = outside_dir / "outside-handoff.json"
        outside_handoff.write_text(
            (FIXTURE_DIR / "completion-evidence-satisfied.json").read_text(encoding="utf-8"),
            encoding="utf-8",
        )
        before_text = outside_handoff.read_text(encoding="utf-8")

        # Wire up the sandbox with a pointer referencing the absolute outside path.
        (tmp_path / ".devteam").mkdir(exist_ok=True)
        (tmp_path / ".devteam" / "active-handoff.json").write_text(
            json.dumps({"handoff_path": str(outside_handoff)}),
            encoding="utf-8",
        )

        result = _run_hook(_sample_event(), sandbox=tmp_path, mode="warn")

        # Must not block (exit 0) — recording must never gate a tool call.
        assert result.returncode == 0, f"expected exit 0, got {result.returncode}"
        # Must not have written to the outside file.
        assert outside_handoff.read_text(encoding="utf-8") == before_text, (
            "absolute handoff_path was written outside the repo — containment guard failed"
        )
    finally:
        import shutil
        shutil.rmtree(outside_dir)


def test_traversal_handoff_path_rejected_exits_zero(tmp_path: Path) -> None:
    """S-1: pointer with a repo-relative but escaping handoff_path must not write outside and exits 0."""
    # Wire sandbox with a pointer that uses ../ to escape the repo root.
    (tmp_path / ".devteam").mkdir(exist_ok=True)
    (tmp_path / ".devteam" / "active-handoff.json").write_text(
        json.dumps({"handoff_path": "../../etc/passwd"}),
        encoding="utf-8",
    )

    result = _run_hook(_sample_event(), sandbox=tmp_path, mode="warn")

    assert result.returncode == 0, f"expected exit 0, got {result.returncode}"
    # stderr should carry a diagnostic warning.
    assert result.stderr != "", "expected a stderr warning on containment violation"
