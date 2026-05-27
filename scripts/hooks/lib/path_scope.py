# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors

from __future__ import annotations

from fnmatch import fnmatch

# Framework-managed path patterns per docs/framework-project-boundary.md (layer 1).
# These paths require framework_scope == "framework-maintenance" on the handoff.
_FRAMEWORK_MANAGED_PATTERNS: list[str] = [
    "CLAUDE.md",
    "AGENTS.md",
    ".claude/agents/*.md",
    "scripts/**",
    "migrations/**",
    "docs/templates/**",
    "docs/INDEX-FRAMEWORK.md",
    "docs/adr/fw-adr-*.md",
    "docs/v*-stabilization.md",
    "docs/v*-checklist.md",
    "TEMPLATE_MANIFEST.lock",
]

FRAMEWORK_MAINTENANCE_SCOPE = "framework-maintenance"


def _matches_scope(path: str, pattern: str) -> bool:
    if fnmatch(path, pattern):
        return True
    if pattern.endswith("/**") and path == pattern[:-3]:
        return True
    return False


def is_path_allowed(
    path: str,
    *,
    allowed_paths: list[str],
    forbidden_paths: list[str],
) -> bool:
    """Return True iff path is allowed by allowed_paths and not blocked by forbidden_paths.

    forbidden_paths always takes precedence: a match there blocks the path even
    when a broader allowed_paths entry also matches.
    """
    if any(_matches_scope(path, pattern) for pattern in forbidden_paths):
        return False
    return any(_matches_scope(path, pattern) for pattern in allowed_paths)


def is_framework_managed(path: str) -> bool:
    """Return True iff path matches a framework-managed pattern.

    Framework-managed paths are defined in docs/framework-project-boundary.md
    (layer 1) and require framework_scope == "framework-maintenance" on the
    active handoff.
    """
    return any(_matches_scope(path, pattern) for pattern in _FRAMEWORK_MANAGED_PATTERNS)


def is_framework_scope_satisfied(path: str, framework_scope: str) -> bool:
    """Return True iff the framework-scope constraint for path is satisfied.

    A framework-managed path is only satisfied when framework_scope is
    "framework-maintenance".  Non-framework-managed paths always pass this
    check regardless of scope value.
    """
    if is_framework_managed(path):
        return framework_scope == FRAMEWORK_MAINTENANCE_SCOPE
    return True
