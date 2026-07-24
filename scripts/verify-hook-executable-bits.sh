#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# scripts/verify-hook-executable-bits.sh — release-gate sub-gate guarding
# against the class of bug filed as the role-routing-reminder.sh incident:
# a hook script committed at mode 100644 under a `.claude/settings.json`
# wiring of the form
#
#   [ -x "${CLAUDE_PROJECT_DIR:-.}/<path>" ] && "${CLAUDE_PROJECT_DIR:-.}/<path>" ... || true
#
# silently no-ops forever -- `[ -x ... ]` is false, the `&&` short-circuits,
# and `|| true` swallows the non-execution with exit 0. Nothing distinguishes
# "hook intentionally absent" from "hook present but not executable"; both
# look like a clean pass. scripts/hooks/role-routing-reminder.sh shipped at
# 100644 from its introduction and the Hard Rule #8 reminder it carries
# never fired, in any clone or scaffolded project, until this gate was
# added.
#
# This script parses every `command` string under `.claude/settings.json`'s
# `hooks` object for that `[ -x "<path>" ]` guard idiom and asserts each
# referenced script IS executable in the candidate tree. It intentionally
# does NOT touch hooks that are NOT wrapped in this idiom (e.g. the
# `python3 "<path>"` invocations) -- those are unconditional and any
# missing-file / not-executable problem there surfaces as an immediate,
# loud failure the first time the hook fires, which is a different (and
# already self-evident) failure mode than this silent-no-op class.
#
# Exit codes:
#   0  every `[ -x ... ]`-guarded hook script referenced in the settings
#      file is present and executable
#   1  at least one such script is missing or not executable
#   2  usage / environment error (missing input file, python3 absent, etc.)
#
# Usage:
#   scripts/verify-hook-executable-bits.sh [--settings <path>]
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

usage() {
    cat >&2 <<'EOF'
Usage: scripts/verify-hook-executable-bits.sh [--settings <path>]

Checks that every hook script referenced via the
`[ -x "<path>" ] && "<path>" ... || true` guard idiom in
.claude/settings.json is actually executable, catching the class of bug
where a hook committed at mode 100644 silently no-ops forever.
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --settings)
            [ -z "${2:-}" ] && { echo "verify-hook-executable-bits: --settings requires a path" >&2; exit 2; }
            SETTINGS="$2"
            shift 2
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            echo "verify-hook-executable-bits: unknown flag: $1" >&2
            usage
            exit 2
            ;;
    esac
done

if ! command -v python3 >/dev/null 2>&1; then
    echo "verify-hook-executable-bits: python3 not found on PATH" >&2
    exit 2
fi

if [ ! -f "$SETTINGS" ]; then
    echo "verify-hook-executable-bits: settings file not found: $SETTINGS" >&2
    exit 2
fi

python3 - "$SETTINGS" "$REPO_ROOT" << 'PYEOF'
import json
import os
import re
import sys

settings_path, repo_root = sys.argv[1], sys.argv[2]

with open(settings_path, encoding="utf-8") as f:
    settings = json.load(f)

# Matches the `[ -x "${CLAUDE_PROJECT_DIR:-.}/<path>" ]` idiom exactly as
# used throughout .claude/settings.json. <path> is captured relative to
# the repo root.
GUARD_RE = re.compile(
    r'\[\s*-x\s+"\$\{CLAUDE_PROJECT_DIR:-\.\}/([^"]+)"\s*\]'
)


def iter_commands(node):
    """Yield every string value found anywhere under settings["hooks"]."""
    if isinstance(node, dict):
        for value in node.values():
            yield from iter_commands(value)
    elif isinstance(node, list):
        for item in node:
            yield from iter_commands(item)
    elif isinstance(node, str):
        yield node


hooks_root = settings.get("hooks", {})
guarded_paths = set()
for command in iter_commands(hooks_root):
    for match in GUARD_RE.finditer(command):
        guarded_paths.add(match.group(1))

if not guarded_paths:
    print(
        "verify-hook-executable-bits: found zero `[ -x ... ]`-guarded hook "
        f"references in {settings_path}; refusing to pass trivially -- this "
        "almost certainly means the settings shape or guard idiom changed "
        "and this gate's parser needs updating, not that there is nothing "
        "to check.",
        file=sys.stderr,
    )
    sys.exit(1)

missing = []
not_executable = []
for rel_path in sorted(guarded_paths):
    abs_path = os.path.join(repo_root, rel_path)
    if not os.path.isfile(abs_path):
        missing.append(rel_path)
    elif not os.access(abs_path, os.X_OK):
        not_executable.append(rel_path)

if missing or not_executable:
    print(
        "verify-hook-executable-bits: FAIL -- the following hook script(s) "
        f"are guarded by `[ -x ... ]` in {settings_path} but are not "
        "reachable that way (a `[ -x ... ] && ... || true` wiring around "
        "any of these silently no-ops with exit 0 instead of running):",
        file=sys.stderr,
    )
    for rel_path in not_executable:
        print(f"  - {rel_path}: exists but is not executable (fix: git update-index --chmod=+x {rel_path})", file=sys.stderr)
    for rel_path in missing:
        print(f"  - {rel_path}: file not found", file=sys.stderr)
    sys.exit(1)

print(
    "verify-hook-executable-bits: PASS -- "
    f"{len(guarded_paths)} `[ -x ... ]`-guarded hook script(s) all present and executable."
)
PYEOF
