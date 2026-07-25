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
# `hooks` object for exec-bit-guard idioms -- `[ -x ... ]`, `[ ! -x ... ]`,
# `test -x ...`, and `[[ -x ... ]]`, each tolerant of single/double/no
# quoting and of the optional `${CLAUDE_PROJECT_DIR:-.}`/`$CLAUDE_PROJECT_DIR`
# prefix -- and asserts each referenced script IS executable in the
# candidate tree.
#
# CR-OPENCODE-HOOK-BRIDGE-0003 (fw-adr-0031 review): the original version
# of this script matched a single literal spelling of the guard idiom, so
# a hook wired via an equally-idiomatic but differently-spelled form (e.g.
# `test -x "<path>" && ...`) was invisible to the parser -- reproducing,
# inside the tool built to catch it, the exact silent-no-op class this
# gate exists to prevent. Fixing the enumerated spellings alone does not
# close that class of bug for good: a FUTURE fifth spelling would be
# equally invisible under a purely allow-list approach. So this script
# does not stop at recognizing more spellings -- it inverts the check:
# every `.py`/`.sh` script path referenced ANYWHERE in `hooks{}` is
# enumerated first, independent of whether it was matched by a guard
# form, and only THEN classified:
#
#   - GUARDED   -- the path appears inside a recognized `-x` test in the
#                  same command string. Must be present + executable.
#   - UNCONDITIONAL -- the command string contains no `-x`-style test at
#                  all (e.g. a bare `python3 "<path>"` invocation). Not
#                  checked here: an unconditional hook that is missing or
#                  not executable fails loudly the first time it fires,
#                  which is a different, already-self-evident failure
#                  mode from the silent-no-op this gate targets.
#   - UNCLASSIFIABLE -- the command string DOES contain something that
#                  looks like a `-x` test (so the author's intent was
#                  plainly "guard this"), but this script's guard forms
#                  could not parse which path it targets. Reported as a
#                  FAILURE, not silently skipped -- a parser that cannot
#                  classify a guarded-looking reference must not be
#                  allowed to fall through to PASS, or this gate
#                  reintroduces its own incident class one syntax
#                  variant at a time. See CR-OPENCODE-HOOK-BRIDGE-0003.
#
# Exit codes:
#   0  every guarded hook script referenced in the settings file is
#      present and executable, and every guarded-looking reference was
#      successfully classified
#   1  at least one such script is missing, not executable, or a
#      guarded-looking reference could not be classified
#   2  usage / environment error (missing input file, malformed JSON,
#      python3 absent, etc.)
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

Checks that every hook script referenced via an exec-bit guard idiom
(`[ -x ... ]`, `[ ! -x ... ]`, `test -x ...`, `[[ -x ... ]]`) in
.claude/settings.json is actually executable, catching the class of bug
where a hook committed at mode 100644 silently no-ops forever. Also
fails on any guarded-looking hook reference it cannot classify, rather
than silently skipping it.
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

# CR-OPENCODE-HOOK-BRIDGE-0004: a malformed settings file is a usage /
# environment error (documented exit 2), not an uncaught traceback that
# happens to also exit non-zero for the wrong reason.
try:
    with open(settings_path, encoding="utf-8") as f:
        settings = json.load(f)
except json.JSONDecodeError as exc:
    print(
        f"verify-hook-executable-bits: {settings_path} is not valid JSON: {exc}",
        file=sys.stderr,
    )
    sys.exit(2)
except OSError as exc:
    print(
        f"verify-hook-executable-bits: could not read {settings_path}: {exc}",
        file=sys.stderr,
    )
    sys.exit(2)

# ---------------------------------------------------------------------------
# Guard-idiom recognition. Four spellings, each tolerant of an optional `!`
# negation, double/single/no quoting, and an optional
# `${CLAUDE_PROJECT_DIR:-.}` / `${CLAUDE_PROJECT_DIR}` / `$CLAUDE_PROJECT_DIR`
# prefix on the path (stripped during classification, not by the regex).
# ---------------------------------------------------------------------------

_QUOTED_OR_BARE = (
    r'(?:"(?P<dq>[^"]+)"'
    r"|'(?P<sq>[^']+)'"
    r'|(?P<bare>[^\s\]&|;)]+))'
)

GUARD_FORMS = [
    # [ -x "<path>" ]  /  [ ! -x "<path>" ]
    re.compile(r'\[\s*(?:!\s*)?-x\s+' + _QUOTED_OR_BARE + r'\s*\]'),
    # [[ -x "<path>" ]]  /  [[ ! -x "<path>" ]]
    re.compile(r'\[\[\s*(?:!\s*)?-x\s+' + _QUOTED_OR_BARE + r'\s*\]\]'),
    # test -x "<path>"  /  test ! -x "<path>"
    re.compile(r'\btest\s+(?:!\s*)?-x\s+' + _QUOTED_OR_BARE),
]

# Presence check: does this command string contain *something* that looks
# like a `-x` exec-bit test, regardless of whether GUARD_FORMS above can
# fully parse its target path? Used to distinguish "unconditional
# invocation" (no -x test anywhere -- skip, per the documented scope
# decision) from "guarded-looking but unparseable" (report, don't skip).
HAS_XTEST_RE = re.compile(r'(?:\[\[|\[|\btest\b)\s*(?:!\s*)?-x\b')

# Broad reference scan: every script-path-shaped token (quoted or bare,
# ending in .py or .sh) appearing anywhere in a command string, guarded or
# not. This is the enumeration CR-OPENCODE-HOOK-BRIDGE-0003 asked for --
# classify every reference, don't just collect what one regex recognizes.
_PATH_CHARS = r'[A-Za-z0-9_./${}:\-]+\.(?:py|sh)'
PATH_REF_RE = re.compile(
    r'"(?P<dq>' + _PATH_CHARS + r')"'
    r"|'(?P<sq>" + _PATH_CHARS + r")'"
    r'|(?<![\w"\'])(?P<bare>' + _PATH_CHARS + r')(?![\w"\'])'
)

_PROJECT_DIR_PREFIX_RE = re.compile(
    r'^\$\{CLAUDE_PROJECT_DIR(?::-\.)?\}/(?P<rest>.+)$'
    r'|^\$CLAUDE_PROJECT_DIR/(?P<rest2>.+)$'
)


def strip_project_dir_prefix(path):
    """Normalize the optional ${CLAUDE_PROJECT_DIR:-.}-style prefix away so
    guarded-path and referenced-path values compare equal regardless of
    whether either occurrence spelled the prefix out."""
    m = _PROJECT_DIR_PREFIX_RE.match(path)
    if m:
        return m.group("rest") or m.group("rest2")
    return path


def _captured(match):
    return match.group("dq") or match.group("sq") or match.group("bare")


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
unconditional_paths = set()
unclassifiable = []  # list of (raw_path, command) for diagnostics

for command in iter_commands(hooks_root):
    referenced_in_command = {
        strip_project_dir_prefix(_captured(m)) for m in PATH_REF_RE.finditer(command)
    }
    if not referenced_in_command:
        continue

    guarded_in_command = set()
    for form in GUARD_FORMS:
        for m in form.finditer(command):
            guarded_in_command.add(strip_project_dir_prefix(_captured(m)))

    guarded_paths |= guarded_in_command & referenced_in_command

    remainder = referenced_in_command - guarded_in_command
    if not remainder:
        continue

    if HAS_XTEST_RE.search(command):
        # This command string is guard-shaped (it has SOME -x test) but at
        # least one referenced path did not resolve to a recognized guard
        # form. Do not silently treat it as unconditional -- that is
        # exactly the fail-open behaviour CR-0003 flagged.
        for rel_path in sorted(remainder):
            unclassifiable.append((rel_path, command))
    else:
        # No -x test anywhere in this command string at all: genuinely
        # unconditional (e.g. `python3 "<path>"`), out of scope by design
        # (see module docstring / header comment).
        unconditional_paths |= remainder

if not guarded_paths and not unclassifiable:
    print(
        "verify-hook-executable-bits: found zero exec-bit-guarded hook "
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

if missing or not_executable or unclassifiable:
    print(
        "verify-hook-executable-bits: FAIL", file=sys.stderr,
    )
    if not_executable or missing:
        print(
            f"  the following hook script(s) are guarded by an exec-bit "
            f"test in {settings_path} but are not reachable that way (a "
            "guard like `[ -x ... ] && ... || true` silently no-ops with "
            "exit 0 instead of running):",
            file=sys.stderr,
        )
        for rel_path in not_executable:
            print(f"    - {rel_path}: exists but is not executable (fix: git update-index --chmod=+x {rel_path})", file=sys.stderr)
        for rel_path in missing:
            print(f"    - {rel_path}: file not found", file=sys.stderr)
    if unclassifiable:
        print(
            "  the following hook reference(s) look exec-bit-guarded "
            f"(some `-x` test is present in the command) but this "
            "script's guard-form parser could not determine which path "
            "they target -- reported rather than silently skipped, since "
            "an unrecognized guard spelling must not fall through to "
            "PASS:",
            file=sys.stderr,
        )
        seen = set()
        for rel_path, command in unclassifiable:
            if (rel_path, command) in seen:
                continue
            seen.add((rel_path, command))
            print(f"    - {rel_path}", file=sys.stderr)
            print(f"      in command: {command}", file=sys.stderr)
        print(
            "    fix: rephrase the guard using one of the recognized "
            "forms ([ -x ... ], [ ! -x ... ], test -x ..., [[ -x ... ]]), "
            "or extend GUARD_FORMS in "
            "scripts/verify-hook-executable-bits.sh to cover this "
            "spelling.",
            file=sys.stderr,
        )
    sys.exit(1)

print(
    "verify-hook-executable-bits: PASS -- "
    f"{len(guarded_paths)} exec-bit-guarded hook script(s) all present and "
    f"executable ({len(unconditional_paths)} unconditional reference(s) "
    "out of scope by design)."
)
PYEOF
