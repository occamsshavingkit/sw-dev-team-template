#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# scripts/verify-opencode-hook-parity.sh — release-gate sub-gate for
# fw-adr-0031 (OpenCode enforcement hook bridge).
#
# Parses .claude/settings.json's `PreToolUse` matchers (the "Agent"
# matcher lives under the same `PreToolUse` key, so a single pass covers
# both) to enumerate every Claude tool name any hook currently guards,
# then checks that scripts/opencode/tool-arg-map.json accounts for each
# one -- either mapped to an OpenCode tool id under `tools`, or recorded
# under `unmapped_claude_tools` as a named, accepted gap (e.g. MultiEdit,
# which has no OpenCode source tool per the runtime spike recorded in
# docs/adr/fw-adr-0031-opencode-hook-bridge.md).
#
# This is drift detection for the mapping TABLE, not for OpenCode's own
# tool-id vocabulary: it catches "Claude side grew a new guarded tool and
# nobody updated the map." It cannot detect "OpenCode renamed a tool id
# upstream" without a live OpenCode session to introspect -- that
# direction of drift is a named, accepted residual risk (fw-adr-0031
# Consequences).
#
# Exit codes:
#   0  every guarded Claude tool is accounted for (mapped or recorded-unmapped)
#   1  at least one guarded Claude tool has no entry in either table
#   2  usage / environment error (missing input file, python3 absent, etc.)
#
# Usage:
#   scripts/verify-opencode-hook-parity.sh [--settings <path>] [--map <path>]
#
# POSIX-sh only: no bashisms; LANG=C/LC_ALL=C.
# Requires: python3.

set -eu

LANG=C
LC_ALL=C
export LANG LC_ALL

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

SETTINGS="${REPO_ROOT}/.claude/settings.json"
MAP="${REPO_ROOT}/scripts/opencode/tool-arg-map.json"

usage() {
    cat >&2 <<'EOF'
Usage: scripts/verify-opencode-hook-parity.sh [--settings <path>] [--map <path>]

Checks that every Claude tool name guarded by a PreToolUse hook in
.claude/settings.json has a corresponding entry (mapped or explicitly
recorded as unmapped) in scripts/opencode/tool-arg-map.json.
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --settings)
            [ -z "${2:-}" ] && { echo "verify-opencode-hook-parity: --settings requires a path" >&2; exit 2; }
            SETTINGS="$2"
            shift 2
            ;;
        --map)
            [ -z "${2:-}" ] && { echo "verify-opencode-hook-parity: --map requires a path" >&2; exit 2; }
            MAP="$2"
            shift 2
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            echo "verify-opencode-hook-parity: unknown flag: $1" >&2
            usage
            exit 2
            ;;
    esac
done

if ! command -v python3 >/dev/null 2>&1; then
    echo "verify-opencode-hook-parity: python3 not found on PATH" >&2
    exit 2
fi

if [ ! -f "$SETTINGS" ]; then
    echo "verify-opencode-hook-parity: settings file not found: $SETTINGS" >&2
    exit 2
fi

if [ ! -f "$MAP" ]; then
    echo "verify-opencode-hook-parity: mapping table not found: $MAP" >&2
    exit 2
fi

python3 - "$SETTINGS" "$MAP" << 'PYEOF'
import json
import sys

settings_path, map_path = sys.argv[1], sys.argv[2]

with open(settings_path, encoding="utf-8") as f:
    settings = json.load(f)

with open(map_path, encoding="utf-8") as f:
    tool_map = json.load(f)

# ---- Step 1: enumerate every Claude tool name guarded by PreToolUse. ----
#
# .claude/settings.json's PreToolUse is a list of {matcher, hooks: [...]}
# entries. The "Agent" matcher (subcall-limit-guard.py) lives under the
# same top-level key as Write/Edit/MultiEdit/Bash, so one pass over
# hooks["PreToolUse"] covers fw-adr-0031's "PreToolUse/Agent matchers"
# wording without a separate lookup.
guarded_tools = set()
for entry in settings.get("hooks", {}).get("PreToolUse", []):
    matcher = entry.get("matcher")
    hook_list = entry.get("hooks") or []
    if not matcher or not hook_list:
        continue
    guarded_tools.add(matcher)

if not guarded_tools:
    print(
        "verify-opencode-hook-parity: found zero PreToolUse matchers in "
        f"{settings_path}; refusing to pass trivially (this almost "
        "certainly means the settings shape changed and this gate's "
        "parser needs updating, not that there is nothing to guard).",
        file=sys.stderr,
    )
    sys.exit(1)

# ---- Step 2: collect what the mapping table accounts for. ----
mapped_claude_tools = set()
for entry in (tool_map.get("tools") or {}).values():
    name = entry.get("claude_tool_name")
    if name:
        mapped_claude_tools.add(name)

unmapped_claude_tools = set((tool_map.get("unmapped_claude_tools") or {}).keys())

accounted_for = mapped_claude_tools | unmapped_claude_tools

# ---- Step 3: diff. ----
gaps = sorted(guarded_tools - accounted_for)

if gaps:
    print(
        "verify-opencode-hook-parity: FAIL -- the following Claude tools "
        f"are guarded by a PreToolUse hook in {settings_path} but have no "
        f"entry (mapped or recorded-unmapped) in {map_path}:",
        file=sys.stderr,
    )
    for name in gaps:
        print(f"  - {name}", file=sys.stderr)
    print(
        "Add an OpenCode tool-id mapping under `tools`, or, if the Claude "
        "tool genuinely has no OpenCode source tool, record it under "
        "`unmapped_claude_tools` with a `reason`.",
        file=sys.stderr,
    )
    sys.exit(1)

print(
    "verify-opencode-hook-parity: PASS -- "
    f"{len(guarded_tools)} guarded Claude tool(s) all accounted for "
    f"({len(mapped_claude_tools & guarded_tools)} mapped, "
    f"{len(unmapped_claude_tools & guarded_tools)} recorded-unmapped)."
)
PYEOF
