#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors

from __future__ import annotations

import json
import os
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from scripts.hooks.lib.handoff import load_active_handoff
from scripts.hooks.lib.path_scope import is_framework_scope_satisfied, is_path_allowed
from scripts.hooks.lib.write_targets import extract_write_targets


def _normalise(path: str, repo_root: Path) -> str:
    candidate = Path(path)
    if candidate.is_absolute():
        try:
            return candidate.resolve().relative_to(repo_root.resolve()).as_posix()
        except ValueError:
            return candidate.as_posix()
    return os.path.normpath(path).replace(os.sep, "/")


def _is_inside_project(path: str, repo_root: Path) -> bool:
    candidate = Path(path)
    if not candidate.is_absolute():
        candidate = repo_root / candidate
    try:
        candidate.resolve().relative_to(repo_root.resolve())
    except ValueError:
        return False
    return True


def _collect_target_paths(tool_input: dict) -> list[str]:
    paths = []
    top = tool_input.get("file_path") or tool_input.get("path") or ""
    if isinstance(top, str) and top:
        paths.append(top)
    command = tool_input.get("command") or ""
    if isinstance(command, str) and command:
        paths.extend(extract_write_targets(command))
    return paths


def _decision(path: str, mode: str) -> dict:
    reason = f"Active handoff path scope does not allow write to '{path}'."
    if mode == "warn":
        return {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "allow",
                "warning": reason,
            }
        }
    return {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }


def _framework_scope_decision(path: str, mode: str) -> dict:
    reason = (
        f"Write to framework-managed path '{path}' requires "
        "framework_scope == 'framework-maintenance' on the active handoff."
    )
    if mode == "warn":
        return {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "allow",
                "warning": reason,
            }
        }
    return {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }


def _load_failure_decision(error: Exception) -> dict:
    reason = f"Active handoff cannot be loaded or validated: {error}"
    return {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }


def _codex_no_permission_decision(mode: str) -> dict:
    reason = (
        "Bounded-Codex action detected but the active handoff has no "
        "bounded_codex_exception with codex_permission_flag: true. "
        "Bounded-Codex execution is not permitted for this handoff."
    )
    if mode == "warn":
        return {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "allow",
                "warning": reason,
            }
        }
    return {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }


def _codex_scope_decision(path: str, mode: str) -> dict:
    reason = (
        f"Bounded-Codex action denied: path '{path}' is not permitted by "
        "the active handoff's bounded_codex_exception scope "
        "(intersection of handoff path scope and exception allowed/forbidden paths)."
    )
    if mode == "warn":
        return {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "allow",
                "warning": reason,
            }
        }
    return {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }


_BOUNDED_CODEX_EXECUTION_MODES = {"bounded-codex"}


def _is_bounded_codex_event(event: dict, handoff: dict) -> bool:
    """Return True when the incoming PreToolUse event is a bounded-Codex action.

    Detection uses two signals, either of which triggers the bounded-Codex gate:
    1. The event payload carries an ``execution_mode`` field whose value is in
       the set of bounded-Codex mode identifiers (e.g. ``"bounded-codex"``).
       This is the primary in-event signal described in hook-events.md.
    2. The active handoff declares a ``bounded_codex_exception`` object.
       When a handoff has this block, every PreToolUse action in the session
       is a bounded-Codex action regardless of whether the event carries the
       field (covers cases where the harness does not inject the marker).

    The ``mode.execution`` field on the handoff describes the session class
    but does NOT alone trigger the gate; only the presence of a
    ``bounded_codex_exception`` block or an event-level ``execution_mode``
    marker does.
    """
    # Signal 1: event-level execution_mode field.
    event_mode = event.get("execution_mode")
    if isinstance(event_mode, str) and event_mode in _BOUNDED_CODEX_EXECUTION_MODES:
        return True

    # Signal 2: handoff declares a bounded_codex_exception block.
    bce = handoff.get("bounded_codex_exception")
    if isinstance(bce, dict):
        return True

    return False


def _codex_permission_granted(handoff: dict) -> bool:
    """Return True iff the handoff has an explicit bounded_codex_exception with
    codex_permission_flag == True.

    Absence of bounded_codex_exception or codex_permission_flag != True are
    both denials per schema description.
    """
    bce = handoff.get("bounded_codex_exception")
    if not isinstance(bce, dict):
        return False
    return bce.get("codex_permission_flag") is True


def _check_codex_path_scope(
    path: str,
    handoff: dict,
) -> bool:
    """Return True iff path passes the composed bounded-Codex scope check.

    Scope is the intersection of:
    1. Handoff-level allowed/forbidden paths (handoff.allowed_paths / .forbidden_paths)
    2. Exception-level allowed/forbidden paths (bounded_codex_exception.allowed_paths /
       .forbidden_paths)

    Forbidden paths at either level override allowed paths at both levels.
    The handoff-level scope check (is_path_allowed) is the primary gate; the
    exception adds a narrower sub-scope on top.
    """
    bce = handoff.get("bounded_codex_exception", {})
    exc_allowed = bce.get("allowed_paths", [])
    exc_forbidden = bce.get("forbidden_paths", [])

    # Must satisfy handoff-level scope first.
    handoff_allowed = handoff.get("allowed_paths", [])
    handoff_forbidden = handoff.get("forbidden_paths", [])
    if not is_path_allowed(
        path,
        allowed_paths=handoff_allowed,
        forbidden_paths=handoff_forbidden,
    ):
        return False

    # Must also satisfy exception-level scope (narrower sub-scope).
    # Exception forbidden_paths override exception allowed_paths and also
    # override the handoff allowed_paths for bounded-Codex actions.
    if not is_path_allowed(
        path,
        allowed_paths=exc_allowed,
        forbidden_paths=exc_forbidden,
    ):
        return False

    return True


def main() -> int:
    mode = os.environ.get("SWDT_HANDOFF_GATES", "").strip().lower()
    if mode not in {"warn", "enforce"}:
        return 0

    try:
        event = json.load(sys.stdin)
    except json.JSONDecodeError:
        return 0
    if not isinstance(event, dict):
        return 0

    tool_input = event.get("tool_input") or {}
    if not isinstance(tool_input, dict):
        return 0

    repo_root = Path(os.environ.get("CLAUDE_PROJECT_DIR") or os.getcwd())
    try:
        handoff = load_active_handoff(repo_root)
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        if mode == "enforce":
            print(json.dumps(_load_failure_decision(exc)))
        return 0

    # Bounded-Codex session detection: when the event carries execution_mode
    # "bounded-codex" OR the active handoff declares a bounded_codex_exception
    # block, apply the bounded-Codex gate in addition to (not instead of) the
    # normal path-scope and framework gates.
    is_codex = _is_bounded_codex_event(event, handoff)

    if is_codex and not _codex_permission_granted(handoff):
        # No explicit permission for bounded-Codex execution on this handoff.
        # Deny (or warn) immediately; do not proceed to path-scope checks.
        print(json.dumps(_codex_no_permission_decision(mode)))
        return 0

    allowed_paths = handoff["allowed_paths"]
    forbidden_paths = handoff["forbidden_paths"]
    framework_scope = handoff.get("framework_scope", "")
    for raw_path in _collect_target_paths(tool_input):
        if not _is_inside_project(raw_path, repo_root):
            print(json.dumps(_decision(raw_path, mode)))
            return 0
        path = _normalise(raw_path, repo_root)

        if is_codex:
            # Bounded-Codex path-scope: intersection of handoff scope and
            # exception scope.  Forbidden paths at either level always win.
            if not _check_codex_path_scope(path, handoff):
                print(json.dumps(_codex_scope_decision(path, mode)))
                return 0
        else:
            if not is_path_allowed(
                path,
                allowed_paths=allowed_paths,
                forbidden_paths=forbidden_paths,
            ):
                print(json.dumps(_decision(path, mode)))
                return 0

        # Framework-scope check applies regardless of Codex vs non-Codex session.
        if not is_framework_scope_satisfied(path, framework_scope):
            print(json.dumps(_framework_scope_decision(path, mode)))
            return 0

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
