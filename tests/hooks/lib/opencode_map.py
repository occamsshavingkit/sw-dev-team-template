#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# tests/hooks/lib/opencode_map.py — reference tool/arg-key mapping and
# verdict-translation oracle for the OpenCode enforcement hook bridge
# (fw-adr-0031-opencode-hook-bridge.md).
#
# This module is the QA-owned, INDEPENDENT re-derivation of the bridge's
# binding contract, used to differentially test:
#   (a) scripts/opencode/tool-arg-map.json (software-engineer's checked-in
#       mapping table), once it exists;
#   (b) .opencode/plugin/hook-bridge.js (software-engineer's plugin), once
#       it exists and is invokable (see tests/hooks/lib/opencode-bridge-invoke.mjs);
#   (c) the existing Claude-side hook negative corpus, replayed through a
#       round-trip Claude->OpenCode->Claude translation (see
#       tests/hooks/run-negative-corpus.sh --harness opencode).
#
# Ground truth for the reference tables below:
#   - VERIFIED runtime facts supplied directly to qa-engineer at dispatch
#     time (OpenCode 1.18.4, callable toolset enumerated, arg shapes for
#     write/edit/bash/task, confirmed absence of a `patch` tool).
#   - @opencode-ai/plugin@1.18.4 dist/index.d.ts (Hooks["tool.execute.before"]
#     input/output shape), read directly from .opencode/node_modules at
#     test-authoring time to ground the tool.execute.before contract.
#   - scripts/hooks/*.py source (permissionDecision / warning /
#     permissionDecisionReason field names), read directly.
#
# KNOWN DISCREPANCY (flagged, not silently resolved -- and independently
# confirmed by software-engineer's own artefact): fw-adr-0031's Decision
# section text still states MultiEdit maps to "edit (single-hunk) and patch
# (unified-diff)". The VERIFIED runtime facts given to qa-engineer, AND
# scripts/opencode/tool-arg-map.json's checked-in `unmapped_claude_tools.
# MultiEdit` entry (added by software-engineer after a live runtime spike,
# /tmp/ocspike/proj/.opencode/plugin/probe-full.js), agree that OpenCode
# 1.18.4 has NO `patch` tool at all (callable toolset: bash, edit, glob,
# grep, invalid, question, read, skill, task, todowrite, webfetch, websearch,
# write). This module treats MultiEdit as having NO OpenCode counterpart
# (CLAUDE_TO_OPENCODE_TOOL["MultiEdit"] is None), consistent with the
# verified runtime facts and the shipped mapping table. The ADR's Decision
# prose is stale and should be reconciled by architect; this is a
# documentation-consistency finding, not a code defect (see qa-engineer
# return output for this session).

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[3]

# ---------------------------------------------------------------------------
# Claude tool name -> OpenCode tool name.
# None means "no OpenCode counterpart" (must be recorded as such, not
# silently dropped, in scripts/opencode/tool-arg-map.json).
# ---------------------------------------------------------------------------
# These reference tables mirror scripts/opencode/tool-arg-map.json exactly
# (cross-checked by load_tool_arg_map() / the "map matches reference" test
# in test-opencode-hook-bridge.sh). Claude's Agent/Task tool is recorded as
# "Agent" per the checked-in map's tools.task.claude_tool_name (matching
# .claude/settings.json's PreToolUse "Agent" matcher for subcall-limit-guard.py).
CLAUDE_TO_OPENCODE_TOOL: dict[str, str | None] = {
    "Write": "write",
    "Edit": "edit",
    "MultiEdit": None,
    "Bash": "bash",
    "Agent": "task",
}

OPENCODE_TO_CLAUDE_TOOL: dict[str, str] = {
    "write": "Write",
    "edit": "Edit",
    "bash": "Bash",
    "task": "Agent",
}

# ---------------------------------------------------------------------------
# Per-tool arg-key maps: Claude-side key -> OpenCode-side key.
# subagent_type is deliberately mapped to itself (unchanged casing) — this
# is the fact a blanket camelCase<->snake_case regex transform gets wrong.
# bash.cwd -> workdir is the one Claude-side key that is NOT the OpenCode
# key it corresponds to under a naive identity guess (workdir, not cwd).
# ---------------------------------------------------------------------------
ARG_KEY_MAPS: dict[str, dict[str, str]] = {
    "write": {"file_path": "filePath", "content": "content"},
    "edit": {
        "file_path": "filePath",
        "old_string": "oldString",
        "new_string": "newString",
    },
    "bash": {"command": "command", "cwd": "workdir"},
    "task": {
        "description": "description",
        "prompt": "prompt",
        "subagent_type": "subagent_type",
    },
}


def infer_claude_tool(tool_input: dict) -> str | None:
    """Best-effort inference of the Claude tool name from a tool_input
    shape, mirroring how the existing negative-corpus fixtures encode
    payloads (no explicit tool_name field; shape alone discriminates)."""
    if not isinstance(tool_input, dict):
        return None
    if "command" in tool_input:
        return "Bash"
    if "edits" in tool_input:
        return "MultiEdit"
    if "old_string" in tool_input or "new_string" in tool_input:
        return "Edit"
    if "content" in tool_input:
        return "Write"
    if "subagent_type" in tool_input:
        return "Agent"
    return None


def to_opencode_args(claude_tool: str, claude_tool_input: dict) -> dict | None:
    """Reverse-map a Claude-shaped tool_input into the OpenCode args shape
    a real OpenCode session would have sent. Returns None when the Claude
    tool has no OpenCode counterpart (MultiEdit)."""
    opencode_tool = CLAUDE_TO_OPENCODE_TOOL.get(claude_tool)
    if opencode_tool is None:
        return None
    key_map = ARG_KEY_MAPS.get(opencode_tool, {})
    out = {}
    for claude_key, value in claude_tool_input.items():
        opencode_key = key_map.get(claude_key, claude_key)
        out[opencode_key] = value
    return out


def to_claude_tool_input(opencode_tool: str, opencode_args: dict) -> dict:
    """Forward-map OpenCode args into the Claude-shaped tool_input the
    bridge constructs before piping to scripts/hooks/<hook>.py. This is
    the translation the bridge itself is responsible for."""
    key_map = ARG_KEY_MAPS.get(opencode_tool, {})
    reverse = {v: k for k, v in key_map.items()}
    out = {}
    for opencode_key, value in opencode_args.items():
        claude_key = reverse.get(opencode_key, opencode_key)
        out[claude_key] = value
    return out


def naive_snake_to_camel(key: str) -> str:
    """A plausible-but-WRONG blanket transform an implementer might reach
    for instead of the explicit table. Used only to demonstrate the bug
    class the explicit table exists to avoid (fw-adr-0031 'Tool-name /
    arg-key mapping ownership')."""
    return re.sub(r"_([a-zA-Z])", lambda m: m.group(1).upper(), key)


def naive_camel_to_snake(key: str) -> str:
    return re.sub(r"([A-Z])", lambda m: "_" + m.group(1).lower(), key)


# ---------------------------------------------------------------------------
# Verdict oracle — independent re-derivation of fw-adr-0031's binding
# "Verdict-translation contract" table.
# ---------------------------------------------------------------------------

def _parse_hook_specific_output(text: str) -> dict | None:
    """Parse `text` (already known non-empty) as JSON and extract
    hookSpecificOutput, mirroring the JSON/shape checks the bridge
    itself performs (see hook-bridge.js's parseGuardVerdictOutput).
    Returns the hookSpecificOutput dict, or None when there is nothing
    to classify (invalid JSON, or no hookSpecificOutput dict). Split out
    of verdict_from_hook_stdout (below) purely to keep that function's
    cyclomatic complexity down; behaviour is unchanged."""
    try:
        payload = json.loads(text)
    except json.JSONDecodeError:
        return None
    hso = payload.get("hookSpecificOutput") if isinstance(payload, dict) else None
    return hso if isinstance(hso, dict) else None


def _classify_allow(hso: dict) -> str:
    """Sub-classify an "allow" decision as 'allow_warn' (a reason or
    warning is attached -- Claude's "warn" mode) or plain 'allow'. Split
    out of verdict_from_hook_stdout (below) purely to keep that
    function's cyclomatic complexity down; behaviour is unchanged."""
    if hso.get("permissionDecisionReason") or hso.get("warning"):
        return "allow_warn"
    return "allow"


def verdict_from_hook_stdout(stdout_text: str) -> str:
    """Classify a scripts/hooks/*.py stdout capture into one of:
    'none' | 'deny' | 'ask' | 'allow_warn' | 'allow' | 'malformed'."""
    text = (stdout_text or "").strip()
    if not text:
        return "none"
    hso = _parse_hook_specific_output(text)
    if hso is None:
        return "malformed"
    decision = hso.get("permissionDecision")
    if decision == "deny":
        return "deny"
    if decision == "ask":
        return "ask"
    if decision == "allow":
        return _classify_allow(hso)
    return "malformed"


def bridge_verdict_for(claude_verdict: str) -> str:
    """fw-adr-0031's binding OpenCode-side bridge behaviour for a given
    Claude-side verdict. Returns 'throw' | 'proceed'."""
    return {
        "none": "proceed",
        "allow": "proceed",
        "allow_warn": "proceed",  # reason dropped; accepted parity gap
        "deny": "throw",
        "ask": "throw",  # degrades to deny, not allow (fail-closed)
    }.get(claude_verdict, "unknown")


def load_tool_arg_map(repo_root: Path | None = None) -> dict | None:
    """Load scripts/opencode/tool-arg-map.json if present. Returns None
    (not an error) when the file does not yet exist, so callers can
    skip-with-message rather than fail on a pre-implementation run."""
    root = repo_root or REPO_ROOT
    path = root / "scripts" / "opencode" / "tool-arg-map.json"
    if not path.is_file():
        return None
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def diff_against_checked_in_map(repo_root: Path | None = None) -> list[str]:
    """Cross-check this module's reference tables against the checked-in
    scripts/opencode/tool-arg-map.json. Returns a list of human-readable
    mismatch strings (empty list == full agreement). Returns
    ["<file not found>"] verbatim when the map does not exist yet, so
    callers can distinguish "not yet implemented" (skip) from "implemented
    but wrong" (fail) by checking that exact sentinel."""
    doc = load_tool_arg_map(repo_root)
    if doc is None:
        return ["<file not found>"]

    mismatches = []
    tools = doc.get("tools", {})

    for opencode_tool, claude_tool in OPENCODE_TO_CLAUDE_TOOL.items():
        entry = tools.get(opencode_tool)
        if entry is None:
            mismatches.append(f"tools.{opencode_tool}: missing from checked-in map")
            continue
        got_claude_tool = entry.get("claude_tool_name")
        if got_claude_tool != claude_tool:
            mismatches.append(
                f"tools.{opencode_tool}.claude_tool_name: expected {claude_tool!r}, "
                f"got {got_claude_tool!r}"
            )
        expected_arg_map = {
            opencode_key: claude_key
            for claude_key, opencode_key in ARG_KEY_MAPS[opencode_tool].items()
        }
        got_arg_map = entry.get("arg_map", {})
        if got_arg_map != expected_arg_map:
            mismatches.append(
                f"tools.{opencode_tool}.arg_map: expected {expected_arg_map!r}, "
                f"got {got_arg_map!r}"
            )

    unmapped = doc.get("unmapped_claude_tools", {})
    if "MultiEdit" not in unmapped:
        mismatches.append(
            "unmapped_claude_tools.MultiEdit: MultiEdit must be recorded explicitly "
            "as having no OpenCode source (fw-adr-0031); it must not be silently omitted"
        )

    return mismatches


# ---------------------------------------------------------------------------
# CLI — thin subcommand surface for the bash test drivers.
# ---------------------------------------------------------------------------

def _cmd_roundtrip(argv: list[str]) -> int:
    if len(argv) != 1:
        print("usage: opencode_map.py roundtrip '<claude_tool_input_json>'", file=sys.stderr)
        return 2
    claude_tool_input = json.loads(argv[0])
    claude_tool = infer_claude_tool(claude_tool_input)
    if claude_tool is None:
        print("SKIP: could not infer a Claude tool shape from tool_input", file=sys.stderr)
        return 3
    opencode_tool = CLAUDE_TO_OPENCODE_TOOL.get(claude_tool)
    if opencode_tool is None:
        print(f"SKIP: {claude_tool} has no OpenCode counterpart", file=sys.stderr)
        return 3
    opencode_args = to_opencode_args(claude_tool, claude_tool_input)
    if opencode_args is None:
        # Unreachable today (claude_tool already passed the opencode_tool
        # None-check above, and to_opencode_args() only returns None for
        # the same "no OpenCode counterpart" condition), but the return
        # type is dict | None, so pyright sees a real hole here. Handle it
        # explicitly with the same SKIP pattern used above rather than
        # pass a possibly-None value into to_claude_tool_input(opencode_args: dict).
        print(f"SKIP: {claude_tool} has no OpenCode counterpart", file=sys.stderr)
        return 3
    reconstructed = to_claude_tool_input(opencode_tool, opencode_args)
    print(json.dumps(reconstructed))
    return 0


def _cmd_verdict(argv: list[str]) -> int:
    stdin_text = argv[0] if argv else sys.stdin.read()
    print(verdict_from_hook_stdout(stdin_text))
    return 0


def _cmd_bridge_verdict(argv: list[str]) -> int:
    if len(argv) != 1:
        print("usage: opencode_map.py bridge-verdict <claude_verdict>", file=sys.stderr)
        return 2
    print(bridge_verdict_for(argv[0]))
    return 0


def _cmd_map_diff(argv: list[str]) -> int:
    mismatches = diff_against_checked_in_map()
    if mismatches == ["<file not found>"]:
        print("SKIP: scripts/opencode/tool-arg-map.json not found", file=sys.stderr)
        return 3
    if mismatches:
        for m in mismatches:
            print(m)
        return 1
    return 0


def main() -> int:
    if len(sys.argv) < 2:
        print(
            "usage: opencode_map.py <roundtrip|verdict|bridge-verdict|map-diff> ...",
            file=sys.stderr,
        )
        return 2
    cmd, rest = sys.argv[1], sys.argv[2:]
    if cmd == "roundtrip":
        return _cmd_roundtrip(rest)
    if cmd == "verdict":
        return _cmd_verdict(rest)
    if cmd == "bridge-verdict":
        return _cmd_bridge_verdict(rest)
    if cmd == "map-diff":
        return _cmd_map_diff(rest)
    print(f"unknown subcommand: {cmd}", file=sys.stderr)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
