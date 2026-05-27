#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors

from __future__ import annotations

import json
import os
from pathlib import Path
from typing import Any

import jsonschema


_HANDOFF_SCHEMA_PATH = Path(__file__).resolve().parents[3] / "schemas" / "handoff.schema.json"

_VALID_GATE_MODES = {"warn", "enforce"}


def resolve_gate_mode(
    handoff: dict | None = None,
    *,
    _env: str | None = None,
) -> str:
    """Return the effective gate mode for the current invocation.

    Precedence (rollout-safe — env var is the deployment control):

    1. Read SWDT_HANDOFF_GATES from the environment (or *_env* in tests).
       If the value is not "warn" or "enforce", return "off" immediately;
       the handoff override cannot re-enable a gate that the operator has
       not enrolled.

    2. When env_mode is "warn" and the active handoff supplies
       ``mode.gate_mode == "enforce"``, return "enforce" (the handoff may
       *tighten* a warn deployment to enforce, but never relax it).

    3. When env_mode is "enforce", always return "enforce" regardless of
       any handoff override (the operator cannot be overridden downward by
       the handoff).

    The ``mode.gate_mode`` field in the handoff schema is the per-handoff
    optional override (Active Handoff Pointer data-model, "optional gate
    mode override if supported by implementation").  It is honoured only
    within the range already permitted by the env var so that the env var
    remains the authoritative rollout switch.

    Args:
        handoff: Loaded handoff dict (output of load_active_handoff), or
            None when the handoff is unavailable.  When None, only the env
            var is consulted.
        _env: Override for SWDT_HANDOFF_GATES used in unit tests.
            Production callers should leave this as None.

    Returns:
        One of "off", "warn", or "enforce".
    """
    raw = (_env if _env is not None else os.environ.get("SWDT_HANDOFF_GATES", "")).strip().lower()
    env_mode = raw if raw in _VALID_GATE_MODES else "off"

    if env_mode == "off":
        return "off"

    if env_mode == "enforce":
        return "enforce"

    # env_mode == "warn": allow handoff to tighten to "enforce"
    if isinstance(handoff, dict):
        handoff_override = handoff.get("mode", {}).get("gate_mode", "")
        if isinstance(handoff_override, str) and handoff_override.strip().lower() == "enforce":
            return "enforce"

    return "warn"


def _resolve_repo_relative(repo_root: Path, value: str) -> Path:
    candidate = Path(value)
    if candidate.is_absolute():
        raise ValueError("handoff_path must be repo-relative")

    resolved = (repo_root / candidate).resolve()
    try:
        resolved.relative_to(repo_root.resolve())
    except ValueError as exc:
        raise ValueError("handoff_path escapes repo root") from exc
    return resolved


def _load_json(path: Path) -> dict:
    with path.open(encoding="utf-8") as handle:
        payload = json.load(handle)
    if not isinstance(payload, dict):
        raise ValueError(f"expected object in {path}")
    return payload


def _validate_handoff(handoff: dict) -> None:
    schema = _load_json(_HANDOFF_SCHEMA_PATH)
    try:
        jsonschema.validate(handoff, schema)
    except jsonschema.ValidationError as exc:
        raise ValueError(f"active handoff schema invalid: {exc.message}") from exc


def _resolve_by_task_id(root: Path, task_id: str) -> Path:
    """Scan docs/handoffs/ for a JSON file whose task_id field matches."""
    handoffs_dir = root / "docs" / "handoffs"
    if not handoffs_dir.is_dir():
        raise FileNotFoundError(
            f"active handoff pointer task_id {task_id!r}: "
            f"docs/handoffs/ directory not found"
        )
    matches = []
    for candidate in sorted(handoffs_dir.glob("*.json")):
        try:
            payload = _load_json(candidate)
        except (ValueError, OSError):
            continue
        if payload.get("task_id") == task_id:
            matches.append(candidate)
    if not matches:
        raise FileNotFoundError(
            f"active handoff pointer task_id {task_id!r}: "
            f"no matching file found in docs/handoffs/"
        )
    if len(matches) > 1:
        paths = ", ".join(str(m) for m in matches)
        raise ValueError(
            f"active handoff pointer task_id {task_id!r}: "
            f"multiple matching files found: {paths}"
        )
    return matches[0]


def load_active_handoff(repo_root: Path | str) -> dict:
    root = Path(repo_root)
    pointer = _load_json(root / ".devteam" / "active-handoff.json")

    handoff_path = pointer.get("handoff_path")
    task_id_ref = pointer.get("task_id")

    if isinstance(handoff_path, str) and handoff_path:
        resolved_path = _resolve_repo_relative(root, handoff_path)
    elif isinstance(task_id_ref, str) and task_id_ref:
        resolved_path = _resolve_by_task_id(root, task_id_ref)
    else:
        raise ValueError(
            "active handoff pointer must supply handoff_path or task_id"
        )
    if not resolved_path.exists():
        raise FileNotFoundError(
            f"active handoff pointer target not found: {handoff_path!r}"
        )
    handoff = _load_json(resolved_path)
    _validate_handoff(handoff)
    if handoff.get("status") != "active":
        raise ValueError("active handoff pointer does not reference an active handoff")
    if not isinstance(handoff.get("allowed_paths"), list):
        raise ValueError("active handoff missing allowed_paths")
    if not isinstance(handoff.get("forbidden_paths"), list):
        raise ValueError("active handoff missing forbidden_paths")
    return handoff


# ---------------------------------------------------------------------------
# Evidence-gate helpers (IEEE 1008-1987 §3.2: F1–F15)
# ---------------------------------------------------------------------------
# These mirror the semantics enforced by handoff-task-completed-gate.py so
# callers (gate scripts, tests) can share a single authoritative source.
# ---------------------------------------------------------------------------


def _is_accepted_evidence(item: Any) -> bool:
    """Return True when item carries independently-accepted (non-worker-report) status.

    An item is accepted when its evidence_kind is explicitly "accepted", OR
    when evidence_kind is absent (legacy items without the field).  A value
    of "worker_report" is never accepted regardless of other fields.
    """
    if not isinstance(item, dict):
        return False
    kind = item.get("evidence_kind")
    return kind != "worker_report"


def verified_test_names(handoff: dict) -> set[str]:
    """Return the set of test names that have passed AND carry explicitly accepted evidence.

    A test entry satisfies a required test gate when:
    - ``result == "passed"``
    - ``evidence_kind == "accepted"`` EXPLICITLY (FR-006 conformance: absent
      evidence_kind and "worker_report" both do NOT satisfy the test gate;
      worker self-attestation cannot satisfy the test gate regardless of
      actor_role).

    Hook-captured evidence (written by handoff-record-activity.py) always
    carries ``evidence_kind="accepted"`` and ``actor_role="hook"``, so it
    satisfies this gate.  Absent-kind legacy entries in verification.tests
    no longer satisfy the gate.
    """
    tests = handoff.get("verification", {}).get("tests", [])
    if not isinstance(tests, list):
        return set()
    return {
        item.get("name")
        for item in tests
        if (
            isinstance(item, dict)
            and item.get("name")
            and item.get("result") == "passed"
            and item.get("evidence_kind") == "accepted"
        )
    }


def has_review_evidence(handoff: dict) -> bool:
    """Return True when the handoff has an accepted code-reviewer approval.

    Requirements:
    - ``actor_role == "code-reviewer"``
    - ``result == "approved"``
    - evidence is accepted (not worker_report)
    """
    reviews = handoff.get("verification", {}).get("reviews", [])
    return isinstance(reviews, list) and any(
        isinstance(item, dict)
        and item.get("result") == "approved"
        and item.get("actor_role") == "code-reviewer"
        and _is_accepted_evidence(item)
        for item in reviews
    )


def has_security_evidence(handoff: dict) -> bool:
    """Return True when the handoff has an accepted security-engineer sign-off.

    Requirements:
    - ``actor_role == "security-engineer"``
    - ``result in {"approved", "passed"}``
    - evidence is accepted (not worker_report)
    """
    evidence = handoff.get("verification", {}).get("security", [])
    return isinstance(evidence, list) and any(
        isinstance(item, dict)
        and item.get("result") in {"approved", "passed"}
        and item.get("actor_role") == "security-engineer"
        and _is_accepted_evidence(item)
        for item in evidence
    )


def has_human_approval_evidence(handoff: dict) -> bool:
    """Return True when the handoff has researcher-stewarded human approval.

    Requirements:
    - ``actor_role == "researcher"``
    - ``result == "approved"``
    - ``source == "CUSTOMER_NOTES.md"``
    - evidence is accepted (not worker_report)
    """
    evidence = handoff.get("verification", {}).get("human_approval", [])
    return isinstance(evidence, list) and any(
        isinstance(item, dict)
        and item.get("result") == "approved"
        and item.get("actor_role") == "researcher"
        and item.get("source") == "CUSTOMER_NOTES.md"
        and _is_accepted_evidence(item)
        for item in evidence
    )


def missing_evidence_gates(handoff: dict) -> list[str]:
    """Return the list of required evidence gate labels that are not yet satisfied.

    Labels follow the pattern used by the completion gate:
    - ``"test:<name>"`` for each required test not yet passed with accepted evidence
    - ``"review"`` when ``requires.review`` is True but no accepted review exists
    - ``"security_review"`` when ``requires.security_review`` is True but no accepted
      security evidence exists
    - ``"human_approval"`` when ``requires.human_approval`` is True but no accepted
      researcher-stewarded approval exists

    Returns an empty list when all required gates are satisfied.
    """
    requires = handoff.get("requires", {})
    missing: list[str] = []

    required_tests = requires.get("tests", [])
    if isinstance(required_tests, list):
        verified = verified_test_names(handoff)
        missing.extend(
            f"test:{name}"
            for name in required_tests
            if isinstance(name, str) and name not in verified
        )

    if requires.get("review") is True and not has_review_evidence(handoff):
        missing.append("review")
    if requires.get("security_review") is True and not has_security_evidence(handoff):
        missing.append("security_review")
    if requires.get("human_approval") is True and not has_human_approval_evidence(handoff):
        missing.append("human_approval")

    return missing
