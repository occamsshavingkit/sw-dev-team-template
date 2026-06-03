#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# Unit / smoke tests for scripts/hooks/handoff-record-activity.py (T019).
# Updated for fw-adr-0023 D2 Option S (v1.2.0): hook now writes to sidecar
# JSONL, not the durable handoff JSON.
#
# IEEE 1008-1987 §3.2: features under test —
#   F1.  No-op when SWDT_HANDOFF_GATES is unset or unrecognised.
#   F2.  No-op when stdin is not valid JSON.
#   F3.  Warm-mode non-blocking when active handoff cannot be loaded.
#   F4.  Activity entry appended to sidecar JSONL with correct fields.
#   F5.  evidence_kind is "accepted".
#   F6.  Durable handoff JSON is NOT mutated (byte-stable after hook call).
#   F7.  Sidecar JSONL accumulates entries across multiple calls.
#   F8.  Path containment: absolute handoff_path in pointer is rejected (S-1);
#        sidecar is NOT written outside the repo.

from __future__ import annotations

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


def _sidecar_path(sandbox: Path, fixture_name: str) -> Path:
    """Return the expected sidecar path for a fixture.

    The hook derives task_id from the active-handoff pointer:
      1. pointer["task_id"] if present
      2. else stem of pointer["handoff_path"]
    The sandbox's pointer only has handoff_path, so the stem of the fixture
    filename is used — matching the hook's fallback branch.
    """
    stem = Path(fixture_name).stem
    return sandbox / "docs" / "handoffs" / f"{stem}.activity.jsonl"


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
    assert result.stdout == ""


def test_nonblocking_no_active_handoff_enforce(tmp_path: Path) -> None:
    result = _run_hook(_sample_event(), sandbox=tmp_path, mode="enforce")
    assert result.returncode == 0
    assert result.stdout == ""


# ---------------------------------------------------------------------------
# F4 — activity entry appended to sidecar JSONL with correct fields
# ---------------------------------------------------------------------------
def test_appends_to_sidecar() -> None:
    sandbox = _make_sandbox("completion-evidence-satisfied.json")
    try:
        event = _sample_event(tool_name="Bash", command="pytest tests/hooks/")
        result = _run_hook(event, sandbox=sandbox, mode="warn")
        assert result.returncode == 0

        sidecar = _sidecar_path(sandbox, "completion-evidence-satisfied.json")
        assert sidecar.exists(), f"sidecar not created at {sidecar}"

        lines = sidecar.read_text(encoding="utf-8").splitlines()
        assert len(lines) >= 1, "expected at least one JSONL line"

        entry = json.loads(lines[-1])
        assert entry["result"] == "passed"
        assert entry["source"] == "PostToolUse"
        assert "Bash" in entry["name"]
        assert entry["actor_role"] == "hook"
        assert "timestamp" in entry
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

        sidecar = _sidecar_path(sandbox, "completion-evidence-satisfied.json")
        assert sidecar.exists()

        entry = json.loads(sidecar.read_text(encoding="utf-8").splitlines()[-1])
        assert entry["evidence_kind"] == "accepted"
    finally:
        import shutil
        shutil.rmtree(sandbox)


# ---------------------------------------------------------------------------
# F6 — durable handoff JSON is NOT mutated (byte-stable)
# ---------------------------------------------------------------------------
def test_handoff_json_not_mutated() -> None:
    sandbox = _make_sandbox("completion-evidence-satisfied.json")
    try:
        handoff_path = sandbox / "docs" / "handoffs" / "completion-evidence-satisfied.json"
        before_bytes = handoff_path.read_bytes()

        result = _run_hook(_sample_event(), sandbox=sandbox, mode="warn")
        assert result.returncode == 0

        after_bytes = handoff_path.read_bytes()
        assert before_bytes == after_bytes, (
            "Durable handoff JSON was mutated by the hook — fw-adr-0023 requires it to be static"
        )
    finally:
        import shutil
        shutil.rmtree(sandbox)


def test_no_tmp_file_left_after_write() -> None:
    """No stale .tmp files in the handoffs dir (sidecar write is direct append)."""
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
# F7 — sidecar JSONL accumulates entries across multiple calls
# ---------------------------------------------------------------------------
def test_sidecar_accumulates_entries() -> None:
    sandbox = _make_sandbox("completion-evidence-satisfied.json")
    try:
        for _ in range(3):
            result = _run_hook(_sample_event(), sandbox=sandbox, mode="warn")
            assert result.returncode == 0

        sidecar = _sidecar_path(sandbox, "completion-evidence-satisfied.json")
        assert sidecar.exists()
        lines = sidecar.read_text(encoding="utf-8").splitlines()
        assert len(lines) == 3, f"expected 3 JSONL lines, got {len(lines)}"

        # All lines must be valid JSON.
        for line in lines:
            entry = json.loads(line)
            assert entry["actor_role"] == "hook"
    finally:
        import shutil
        shutil.rmtree(sandbox)


# ---------------------------------------------------------------------------
# F8 — path containment: absolute handoff_path in pointer is rejected (S-1)
# ---------------------------------------------------------------------------


def test_absolute_handoff_path_rejected_exits_zero(tmp_path: Path) -> None:
    """S-1: pointer with an absolute handoff_path must not write outside repo."""
    outside_dir = Path(tempfile.mkdtemp())
    try:
        outside_handoff = outside_dir / "outside-handoff.json"
        outside_handoff.write_text(
            (FIXTURE_DIR / "completion-evidence-satisfied.json").read_text(encoding="utf-8"),
            encoding="utf-8",
        )

        (tmp_path / ".devteam").mkdir(exist_ok=True)
        (tmp_path / ".devteam" / "active-handoff.json").write_text(
            json.dumps({"handoff_path": str(outside_handoff)}),
            encoding="utf-8",
        )

        result = _run_hook(_sample_event(), sandbox=tmp_path, mode="warn")

        # Must not block (exit 0).
        assert result.returncode == 0, f"expected exit 0, got {result.returncode}"

        # No sidecar should appear under tmp_path/docs/handoffs/.
        sidecars = list((tmp_path / "docs").rglob("*.activity.jsonl")) if (tmp_path / "docs").exists() else []
        assert sidecars == [], f"unexpected sidecar(s) written: {sidecars}"

        # No sidecar in outside_dir either.
        outside_sidecars = list(outside_dir.glob("*.activity.jsonl"))
        assert outside_sidecars == [], f"sidecar written outside repo: {outside_sidecars}"
    finally:
        import shutil
        shutil.rmtree(outside_dir)


def test_traversal_handoff_path_rejected_exits_zero(tmp_path: Path) -> None:
    """S-1: pointer with a repo-relative but escaping handoff_path exits 0."""
    (tmp_path / ".devteam").mkdir(exist_ok=True)
    (tmp_path / ".devteam" / "active-handoff.json").write_text(
        json.dumps({"handoff_path": "../../etc/passwd"}),
        encoding="utf-8",
    )

    result = _run_hook(_sample_event(), sandbox=tmp_path, mode="warn")

    assert result.returncode == 0, f"expected exit 0, got {result.returncode}"
    assert result.stderr != "", "expected a stderr warning on containment violation"
