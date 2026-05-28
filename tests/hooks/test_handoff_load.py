#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# Unit tests for scripts/hooks/lib/handoff.py (T006, T012).
# IEEE 1008-1987 §3.2: features under test —
#   F1. load_active_handoff loads a valid pointer + handoff.
#   F2. Missing pointer file raises ValueError (clear message).
#   F3. Pointer with missing handoff_path field raises ValueError.
#   F4. Pointer target file not found raises FileNotFoundError with clear message.
#   F5. Handoff that fails schema validation raises ValueError with clear message.
#   F6. Handoff with status != "active" raises ValueError.
#   F7. Absolute handoff_path is rejected.
#   F8. Path-traversal handoff_path is rejected.
#   F9. task_id reference resolves to matching file in docs/handoffs/.
#   F10. task_id with no matching file raises FileNotFoundError.
#   F11. Pointer with neither handoff_path nor task_id raises ValueError.

from __future__ import annotations

import json
import sys
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT))

from scripts.hooks.lib.handoff import load_active_handoff  # noqa: E402

VALID_MINIMAL = REPO_ROOT / "tests" / "fixtures" / "handoffs" / "valid-minimal.json"


def _write_pointer(tmp_path: Path, payload: object) -> Path:
    devteam = tmp_path / ".devteam"
    devteam.mkdir(exist_ok=True)
    ptr = devteam / "active-handoff.json"
    ptr.write_text(json.dumps(payload), encoding="utf-8")
    return tmp_path


def _install_handoff(tmp_path: Path, rel: str, content: dict) -> None:
    target = tmp_path / rel
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(json.dumps(content), encoding="utf-8")


def _valid_handoff_content() -> dict:
    return json.loads(VALID_MINIMAL.read_text(encoding="utf-8"))


# F1 — happy path
def test_load_valid_pointer_and_handoff(tmp_path: Path) -> None:
    rel = "tests/fixtures/handoffs/valid-minimal.json"
    _install_handoff(tmp_path, rel, _valid_handoff_content())
    _write_pointer(tmp_path, {"handoff_path": rel})
    result = load_active_handoff(tmp_path)
    assert result["task_id"] == "v1.1-valid-minimal"
    assert result["status"] == "active"


# F2 — pointer file itself missing
def test_missing_pointer_file_raises(tmp_path: Path) -> None:
    with pytest.raises((FileNotFoundError, ValueError)):
        load_active_handoff(tmp_path)


# F3 — pointer present but handoff_path field absent
def test_pointer_missing_handoff_path_field(tmp_path: Path) -> None:
    _write_pointer(tmp_path, {"note": "no handoff_path"})
    with pytest.raises(ValueError, match="handoff_path"):
        load_active_handoff(tmp_path)


# F4 — pointer target file does not exist
def test_pointer_target_not_found(tmp_path: Path) -> None:
    _write_pointer(tmp_path, {"handoff_path": "tests/fixtures/handoffs/does-not-exist.json"})
    with pytest.raises(FileNotFoundError, match="active handoff pointer target not found"):
        load_active_handoff(tmp_path)


# F5 — handoff fails schema validation
def test_invalid_handoff_schema_raises(tmp_path: Path) -> None:
    rel = "tests/fixtures/handoffs/invalid.json"
    _install_handoff(tmp_path, rel, {"status": "active"})  # missing required fields
    _write_pointer(tmp_path, {"handoff_path": rel})
    with pytest.raises(ValueError, match="schema invalid"):
        load_active_handoff(tmp_path)


# F6 — handoff status is not "active"
def test_non_active_status_raises(tmp_path: Path) -> None:
    rel = "tests/fixtures/handoffs/completed.json"
    content = _valid_handoff_content()
    content["status"] = "completed"
    _install_handoff(tmp_path, rel, content)
    _write_pointer(tmp_path, {"handoff_path": rel})
    with pytest.raises(ValueError, match="active"):
        load_active_handoff(tmp_path)


# F7 — absolute handoff_path rejected
def test_absolute_handoff_path_rejected(tmp_path: Path) -> None:
    _write_pointer(tmp_path, {"handoff_path": "/etc/passwd"})
    with pytest.raises(ValueError, match="repo-relative"):
        load_active_handoff(tmp_path)


# F8 — path traversal rejected
def test_path_traversal_rejected(tmp_path: Path) -> None:
    _write_pointer(tmp_path, {"handoff_path": "../../etc/passwd"})
    with pytest.raises(ValueError, match="escapes repo root"):
        load_active_handoff(tmp_path)


# F9 — task_id reference resolves to matching file in docs/handoffs/
def test_task_id_resolves_to_matching_handoff(tmp_path: Path) -> None:
    content = _valid_handoff_content()
    content["task_id"] = "my-task-001"
    _install_handoff(tmp_path, "docs/handoffs/my-task-001.json", content)
    _write_pointer(tmp_path, {"task_id": "my-task-001"})
    result = load_active_handoff(tmp_path)
    assert result["task_id"] == "my-task-001"
    assert result["status"] == "active"


# F10 — task_id with no matching file raises FileNotFoundError
def test_task_id_no_match_raises(tmp_path: Path) -> None:
    handoffs_dir = tmp_path / "docs" / "handoffs"
    handoffs_dir.mkdir(parents=True)
    _write_pointer(tmp_path, {"task_id": "nonexistent-task"})
    with pytest.raises(FileNotFoundError, match="nonexistent-task"):
        load_active_handoff(tmp_path)


# F11 — pointer with neither handoff_path nor task_id raises ValueError
def test_pointer_missing_both_fields_raises(tmp_path: Path) -> None:
    _write_pointer(tmp_path, {"note": "no reference fields"})
    with pytest.raises(ValueError, match="handoff_path or task_id"):
        load_active_handoff(tmp_path)
