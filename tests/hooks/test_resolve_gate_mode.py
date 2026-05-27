#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# Unit tests for scripts/hooks/lib/handoff.resolve_gate_mode (T034).
# IEEE 1008-1987 §3.2: features under test —
#   F1.  Env var absent / unrecognised → "off".
#   F2.  Env var "warn" → "warn" (no handoff override).
#   F3.  Env var "enforce" → "enforce" (no handoff override).
#   F4.  Env var "off" (explicit) → "off".
#   F5.  Env var "warn" + handoff gate_mode "enforce" → "enforce" (tighten).
#   F6.  Env var "enforce" + handoff gate_mode "warn" → "enforce" (cannot relax).
#   F7.  Env var "warn" + handoff gate_mode "warn" → "warn" (no change).
#   F8.  Env var "off" + handoff gate_mode "enforce" → "off" (cannot re-enable).
#   F9.  Env var "warn" + handoff without mode.gate_mode → "warn".
#   F10. Env var "warn" + handoff mode.gate_mode absent key → "warn".
#   F11. Env var "WARN" (uppercase) → "warn" (case-insensitive).
#   F12. Env var "ENFORCE" (uppercase) → "enforce" (case-insensitive).
#   F13. handoff=None with env "warn" → "warn".
#   F14. handoff=None with env "enforce" → "enforce".

from __future__ import annotations

import sys
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT))

from scripts.hooks.lib.handoff import resolve_gate_mode  # noqa: E402


def _handoff_with_gate_mode(gate_mode: str | None) -> dict:
    """Return a minimal handoff dict with optional mode.gate_mode."""
    mode_block: dict = {"execution": "standard", "codex_allowed": False, "codex_server": "none"}
    if gate_mode is not None:
        mode_block["gate_mode"] = gate_mode
    return {"mode": mode_block, "status": "active"}


# F1 — env absent → "off"
def test_env_absent_returns_off() -> None:
    assert resolve_gate_mode(_env="") == "off"


# F1b — env unrecognised value → "off"
def test_env_unrecognised_returns_off() -> None:
    assert resolve_gate_mode(_env="invalid") == "off"


# F2 — env "warn", no handoff → "warn"
def test_env_warn_no_handoff_returns_warn() -> None:
    assert resolve_gate_mode(_env="warn") == "warn"


# F3 — env "enforce", no handoff → "enforce"
def test_env_enforce_no_handoff_returns_enforce() -> None:
    assert resolve_gate_mode(_env="enforce") == "enforce"


# F4 — env "off" → "off"
def test_env_explicit_off_returns_off() -> None:
    assert resolve_gate_mode(_env="off") == "off"


# F5 — env "warn" + handoff gate_mode "enforce" → "enforce" (tighten allowed)
def test_env_warn_handoff_enforce_tightens_to_enforce() -> None:
    handoff = _handoff_with_gate_mode("enforce")
    assert resolve_gate_mode(handoff, _env="warn") == "enforce"


# F6 — env "enforce" + handoff gate_mode "warn" → "enforce" (cannot relax)
def test_env_enforce_handoff_warn_stays_enforce() -> None:
    handoff = _handoff_with_gate_mode("warn")
    assert resolve_gate_mode(handoff, _env="enforce") == "enforce"


# F7 — env "warn" + handoff gate_mode "warn" → "warn"
def test_env_warn_handoff_warn_returns_warn() -> None:
    handoff = _handoff_with_gate_mode("warn")
    assert resolve_gate_mode(handoff, _env="warn") == "warn"


# F8 — env "off" + handoff gate_mode "enforce" → "off" (cannot re-enable)
def test_env_off_handoff_enforce_stays_off() -> None:
    handoff = _handoff_with_gate_mode("enforce")
    assert resolve_gate_mode(handoff, _env="off") == "off"


# F9 — env "warn" + handoff without gate_mode field → "warn"
def test_env_warn_handoff_no_gate_mode_field_returns_warn() -> None:
    handoff = _handoff_with_gate_mode(None)
    assert resolve_gate_mode(handoff, _env="warn") == "warn"


# F10 — env "warn" + handoff with empty string gate_mode → "warn"
def test_env_warn_handoff_empty_gate_mode_returns_warn() -> None:
    handoff = _handoff_with_gate_mode("")
    assert resolve_gate_mode(handoff, _env="warn") == "warn"


# F11 — env "WARN" uppercase → "warn"
def test_env_warn_uppercase_case_insensitive() -> None:
    assert resolve_gate_mode(_env="WARN") == "warn"


# F12 — env "ENFORCE" uppercase → "enforce"
def test_env_enforce_uppercase_case_insensitive() -> None:
    assert resolve_gate_mode(_env="ENFORCE") == "enforce"


# F13 — handoff=None, env "warn" → "warn"
def test_handoff_none_env_warn_returns_warn() -> None:
    assert resolve_gate_mode(None, _env="warn") == "warn"


# F14 — handoff=None, env "enforce" → "enforce"
def test_handoff_none_env_enforce_returns_enforce() -> None:
    assert resolve_gate_mode(None, _env="enforce") == "enforce"
