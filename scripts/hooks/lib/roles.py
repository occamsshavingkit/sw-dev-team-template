#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# Single authoritative source for the canonical agent-roster role vocabulary,
# sourced from CLAUDE.md § Agent roster.
#
# All gate scripts that need to validate role names import from here rather
# than maintaining independent frozenset literals (S-2: eliminate duplication).

from __future__ import annotations

import re

# ---------------------------------------------------------------------------
# Canonical role set — mirrors CLAUDE.md § Agent roster exactly.
# ---------------------------------------------------------------------------

CANONICAL_ROLES: frozenset[str] = frozenset(
    {
        "tech-lead",
        "project-manager",
        "architect",
        "software-engineer",
        "researcher",
        "qa-engineer",
        "sre",
        "tech-writer",
        "code-reviewer",
        "release-engineer",
        "security-engineer",
        "onboarding-auditor",
        "process-auditor",
    }
)

# sme-<slug> roles are dynamic (per-project).  The regex matches any role
# of the form sme-<slug> where <slug> starts with a lowercase letter and
# contains only lowercase letters, digits, underscores, and hyphens.
# Note: sme-template also matches this pattern by design — the scaffold
# file is considered an in-scope role reference during project setup.
SME_ROLE_RE: re.Pattern[str] = re.compile(r"^sme-[a-z][a-z0-9_-]*$")


def is_canonical_role(role: str) -> bool:
    """Return True when *role* is a known canonical or sme-<slug> role."""
    return role in CANONICAL_ROLES or bool(SME_ROLE_RE.match(role))
