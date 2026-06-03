#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# Unit tests for evidence-lookup helpers in scripts/hooks/lib/handoff.py (T018).
# IEEE 1008-1987 §3.2: features under test —
#   F1.  verified_test_names: absent evidence_kind does NOT satisfy (FR-006/S-1).
#   F1b. verified_test_names: evidence_kind="accepted" explicit satisfies.
#   F2.  verified_test_names: worker_report evidence does NOT satisfy.
#   F3.  verified_test_names: failed test does not satisfy.
#   F4.  missing_evidence_gates: empty verification → all required gates listed.
#   F5.  has_review_evidence: correct actor_role + result → True.
#   F6.  has_review_evidence: wrong actor_role (not code-reviewer) → False.
#   F7.  has_review_evidence: worker_report → False.
#   F8.  has_security_evidence: security-engineer approved → True.
#   F9.  has_security_evidence: wrong actor_role → False.
#   F10. has_human_approval_evidence: librarian + CUSTOMER_NOTES.md → True.
#   F10b.has_human_approval_evidence: researcher + CUSTOMER_NOTES.md → True (back-compat).
#   F11. has_human_approval_evidence: source != CUSTOMER_NOTES.md → False.
#   F12. has_human_approval_evidence: actor_role not in {librarian,researcher} → False.
#   F13. has_human_approval_evidence: worker_report → False.
#   F14. missing_evidence_gates: all gates satisfied → empty list.
#   F15. missing_evidence_gates: only required=False gates absent → empty list.

from __future__ import annotations

import sys
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT))

from scripts.hooks.lib.handoff import (  # noqa: E402
    has_human_approval_evidence,
    has_review_evidence,
    has_security_evidence,
    missing_evidence_gates,
    verified_test_names,
)


# ---------------------------------------------------------------------------
# Helpers to build minimal handoff dicts without requiring schema validation.
# ---------------------------------------------------------------------------

def _make_handoff(
    *,
    requires: dict | None = None,
    tests: list | None = None,
    reviews: list | None = None,
    security: list | None = None,
    human_approval: list | None = None,
) -> dict:
    return {
        "requires": requires or {"tests": [], "review": False, "security_review": False, "human_approval": False},
        "verification": {
            "tests": tests or [],
            "reviews": reviews or [],
            "security": security or [],
            "human_approval": human_approval or [],
        },
    }


def _test_entry(name: str, result: str = "passed", actor_role: str = "qa-engineer", evidence_kind: str | None = None) -> dict:
    entry: dict = {"name": name, "result": result, "actor_role": actor_role}
    if evidence_kind is not None:
        entry["evidence_kind"] = evidence_kind
    return entry


def _review_entry(actor_role: str = "code-reviewer", result: str = "approved", evidence_kind: str | None = None) -> dict:
    entry: dict = {"actor_role": actor_role, "result": result, "artifact": "docs/reviews/review.md"}
    if evidence_kind is not None:
        entry["evidence_kind"] = evidence_kind
    return entry


def _security_entry(actor_role: str = "security-engineer", result: str = "approved", evidence_kind: str | None = None) -> dict:
    entry: dict = {"actor_role": actor_role, "result": result}
    if evidence_kind is not None:
        entry["evidence_kind"] = evidence_kind
    return entry


def _human_approval_entry(
    actor_role: str = "librarian",
    result: str = "approved",
    source: str = "CUSTOMER_NOTES.md",
    evidence_kind: str | None = None,
) -> dict:
    entry: dict = {"actor_role": actor_role, "result": result, "source": source}
    if evidence_kind is not None:
        entry["evidence_kind"] = evidence_kind
    return entry


# ---------------------------------------------------------------------------
# F1 — verified_test_names: absent evidence_kind does NOT satisfy (FR-006
#       conformance: explicit "accepted" is required for the test gate;
#       legacy absent-kind entries are treated as insufficiently attested).
# ---------------------------------------------------------------------------
def test_verified_test_names_absent_kind_does_not_satisfy() -> None:
    """Absent evidence_kind is no longer accepted for the test gate (S-1 / FR-006)."""
    handoff = _make_handoff(tests=[_test_entry("suite-a")])
    assert "suite-a" not in verified_test_names(handoff)


# F1b — verified_test_names: evidence_kind="accepted" satisfies
def test_verified_test_names_accepted_explicit() -> None:
    handoff = _make_handoff(tests=[_test_entry("suite-b", evidence_kind="accepted")])
    assert "suite-b" in verified_test_names(handoff)


# F2 — verified_test_names: worker_report does NOT satisfy
def test_verified_test_names_worker_report_does_not_satisfy() -> None:
    handoff = _make_handoff(tests=[_test_entry("suite-c", evidence_kind="worker_report")])
    assert "suite-c" not in verified_test_names(handoff)


# F3 — verified_test_names: failed test does not satisfy
def test_verified_test_names_failed_result_does_not_satisfy() -> None:
    handoff = _make_handoff(tests=[_test_entry("suite-d", result="failed")])
    assert "suite-d" not in verified_test_names(handoff)


# F4 — missing_evidence_gates: empty verification, required tests + review
def test_missing_evidence_gates_all_missing() -> None:
    handoff = _make_handoff(
        requires={"tests": ["suite-x"], "review": True, "security_review": False, "human_approval": False},
    )
    missing = missing_evidence_gates(handoff)
    assert "test:suite-x" in missing
    assert "review" in missing
    assert "security_review" not in missing
    assert "human_approval" not in missing


# F5 — has_review_evidence: correct role + result
def test_has_review_evidence_satisfied() -> None:
    handoff = _make_handoff(reviews=[_review_entry()])
    assert has_review_evidence(handoff) is True


# F6 — has_review_evidence: wrong actor_role
def test_has_review_evidence_wrong_role() -> None:
    handoff = _make_handoff(reviews=[_review_entry(actor_role="qa-engineer")])
    assert has_review_evidence(handoff) is False


# F7 — has_review_evidence: worker_report does not satisfy
def test_has_review_evidence_worker_report() -> None:
    handoff = _make_handoff(reviews=[_review_entry(evidence_kind="worker_report")])
    assert has_review_evidence(handoff) is False


# F8 — has_security_evidence: security-engineer approved
def test_has_security_evidence_satisfied() -> None:
    handoff = _make_handoff(security=[_security_entry()])
    assert has_security_evidence(handoff) is True


# F8b — has_security_evidence: "passed" result also satisfies
def test_has_security_evidence_passed_result() -> None:
    handoff = _make_handoff(security=[_security_entry(result="passed")])
    assert has_security_evidence(handoff) is True


# F9 — has_security_evidence: wrong actor_role
def test_has_security_evidence_wrong_role() -> None:
    handoff = _make_handoff(security=[_security_entry(actor_role="code-reviewer")])
    assert has_security_evidence(handoff) is False


# F10 — has_human_approval_evidence: librarian + CUSTOMER_NOTES.md (primary)
def test_has_human_approval_evidence_satisfied() -> None:
    handoff = _make_handoff(human_approval=[_human_approval_entry()])  # default: librarian
    assert has_human_approval_evidence(handoff) is True


# F10b — has_human_approval_evidence: researcher + CUSTOMER_NOTES.md (back-compat)
def test_has_human_approval_evidence_researcher_backcompat() -> None:
    handoff = _make_handoff(human_approval=[_human_approval_entry(actor_role="researcher")])
    assert has_human_approval_evidence(handoff) is True


# F11 — has_human_approval_evidence: wrong source
def test_has_human_approval_evidence_wrong_source() -> None:
    handoff = _make_handoff(human_approval=[_human_approval_entry(source="ad-hoc-chat")])
    assert has_human_approval_evidence(handoff) is False


# F12 — has_human_approval_evidence: actor_role not in {librarian, researcher}
def test_has_human_approval_evidence_wrong_role() -> None:
    handoff = _make_handoff(human_approval=[_human_approval_entry(actor_role="project-manager")])
    assert has_human_approval_evidence(handoff) is False


# F13 — has_human_approval_evidence: worker_report does not satisfy
def test_has_human_approval_evidence_worker_report() -> None:
    handoff = _make_handoff(human_approval=[_human_approval_entry(evidence_kind="worker_report")])
    assert has_human_approval_evidence(handoff) is False


# F14 — missing_evidence_gates: all required gates satisfied → empty list
def test_missing_evidence_gates_all_satisfied() -> None:
    handoff = _make_handoff(
        requires={"tests": ["suite-a"], "review": True, "security_review": True, "human_approval": True},
        tests=[_test_entry("suite-a", evidence_kind="accepted")],
        reviews=[_review_entry()],
        security=[_security_entry()],
        human_approval=[_human_approval_entry()],
    )
    assert missing_evidence_gates(handoff) == []


# F15 — missing_evidence_gates: required=False gates absent → still empty list
def test_missing_evidence_gates_optional_absent_not_reported() -> None:
    handoff = _make_handoff(
        requires={"tests": [], "review": False, "security_review": False, "human_approval": False},
    )
    assert missing_evidence_gates(handoff) == []


# ---------------------------------------------------------------------------
# S-1 gap-closure cases (FR-006 conformance): worker self-attestation on the
# test gate.  These cases verify that the gap described in S-1 is closed.
# ---------------------------------------------------------------------------

# S1-NEG — worker self-attested test entry (absent evidence_kind, worker
# actor_role, result=passed) does NOT satisfy the test gate in enforce/warn
# mode (missing_evidence_gates reports test as missing).
def test_worker_self_attested_test_absent_kind_does_not_satisfy_gate() -> None:
    """Absent evidence_kind + worker actor_role = gate not satisfied (S-1/FR-006)."""
    handoff = _make_handoff(
        requires={"tests": ["suite-x"], "review": False, "security_review": False, "human_approval": False},
        tests=[_test_entry("suite-x", actor_role="software-engineer")],  # absent kind
    )
    missing = missing_evidence_gates(handoff)
    assert "test:suite-x" in missing


# S1-NEG-2 — worker_report evidence_kind + worker actor_role also does not satisfy.
def test_worker_self_attested_test_worker_report_kind_does_not_satisfy_gate() -> None:
    """worker_report evidence_kind cannot satisfy the test gate (S-1/FR-006)."""
    handoff = _make_handoff(
        requires={"tests": ["suite-x"], "review": False, "security_review": False, "human_approval": False},
        tests=[_test_entry("suite-x", actor_role="software-engineer", evidence_kind="worker_report")],
    )
    missing = missing_evidence_gates(handoff)
    assert "test:suite-x" in missing


# S1-POS — explicit accepted / hook-captured test entry satisfies the gate.
def test_hook_captured_test_accepted_kind_satisfies_gate() -> None:
    """evidence_kind='accepted' + actor_role='hook' (hook-captured) satisfies the test gate (S-1/FR-006)."""
    handoff = _make_handoff(
        requires={"tests": ["suite-x"], "review": False, "security_review": False, "human_approval": False},
        tests=[_test_entry("suite-x", actor_role="hook", evidence_kind="accepted")],
    )
    missing = missing_evidence_gates(handoff)
    assert "test:suite-x" not in missing
