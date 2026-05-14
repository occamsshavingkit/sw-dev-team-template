#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# Claude Code PreToolUse hook: enforce Hard Rule #8 at the tool layer.
#
# The main session (tech-lead) may only write to a small enumerated set of
# orchestration artefacts. All other paths route to the owning specialist.
# Off-allow-list writes return permissionDecision: "deny" with a message
# naming the right specialist to dispatch.
#
# Escape hatch: env var SWDT_AGENT_PUSH=<role> widens the allow-list for a
# single tool invocation to cover legitimate tool-bridge cases where a
# specialist's sandbox cannot write its own output. CUSTOMER_NOTES.md is
# handled by the separate customer-notes-guard.py and is passed through
# here (its gate is authoritative; this guard does not double-block).
#
# Hook ordering invariant (FW-ADR-0012 § ADR-internal follow-ups):
#   customer-notes-guard.py runs BEFORE this hook on the same matchers.
#   That ordering must be preserved in .claude/settings.json.

import fnmatch
import importlib.util
import json
import os
import pathlib
import re
import sys


# ---------------------------------------------------------------------------
# Allow-list (binding from FW-ADR-0012 § Allow-list specification).
# ---------------------------------------------------------------------------

ALLOW_EXACT = frozenset(
    {
        "docs/OPEN_QUESTIONS.md",
        "docs/intake-log.md",
        "docs/DECISIONS.md",
        "docs/pm/dispatch-log.md",
        "TEMPLATE_VERSION",
        "docs/AGENT_NAMES.md",
    }
)

# Glob patterns. fnmatch is used for `*` matches; `**` is expanded to recursive
# via pathlib.PurePath.match.
ALLOW_GLOBS_SHALLOW = (
    "docs/pm/intake-*.md",
    "docs/pm/intake-*.local.md",
    "docs/tasks/T-*.md",
)
ALLOW_GLOBS_RECURSIVE = ("docs/tech-lead/**",)


# ---------------------------------------------------------------------------
# Role vocabulary (binding from CLAUDE.md § Agent roster).
# ---------------------------------------------------------------------------

CANONICAL_ROLES = frozenset(
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
SME_ROLE_RE = re.compile(r"^sme-[a-z][a-z0-9_-]*$")


CUSTOMER_NOTES_BASENAME = "CUSTOMER_NOTES.md"
CUSTOMER_NOTES_DIR_PREFIX = "docs/customer-notes/"


# ---------------------------------------------------------------------------
# Vendor the Bash write-pattern detection helpers from customer-notes-guard.
# The neighbour module is loaded by path because its filename contains a
# hyphen (not importable as a regular module name).
# ---------------------------------------------------------------------------

_HOOKS_DIR = pathlib.Path(__file__).resolve().parent
_GUARD_PATH = _HOOKS_DIR / "customer-notes-guard.py"


def _load_customer_notes_guard():
    spec = importlib.util.spec_from_file_location("customer_notes_guard", _GUARD_PATH)
    if spec is None or spec.loader is None:
        return None
    module = importlib.util.module_from_spec(spec)
    try:
        spec.loader.exec_module(module)
    except Exception:
        return None
    return module


_CNG = _load_customer_notes_guard()


# Regex set mirroring customer-notes-guard's pattern shape, parameterised on
# a capture for the target path. The neighbour module uses fixed literals for
# CUSTOMER_NOTES.md; here we capture the candidate path so the caller can
# allow-list-check it.
#
# Path token: any non-separator chars that don't look like a shell op. We
# allow quoted forms with simple single/double quotes.
_PATH_TOKEN = r"['\"]?([^|;&\s<>'\"]+)['\"]?"
_INTERPRETER_RE = r"(?:python|python3|node|ruby|perl|bash|sh|php|lua|Rscript)"


def _extract_redirect_targets(command: str):
    # `> FILE`, `>> FILE`, `1> FILE`, `2>&1 > FILE`, `&> FILE`, `&>> FILE`,
    # `>| FILE`.
    pattern = rf"(?:[0-9]+|&)?>>?\|?\s*{_PATH_TOKEN}"
    return [m.group(1) for m in re.finditer(pattern, command)]


def _extract_tee_targets(command: str):
    # `tee [-a] FILE [FILE ...]` — first non-option token after `tee`.
    targets = []
    for m in re.finditer(r"\btee\b((?:\s+-[a-zA-Z]+)*)\s+([^|;&]+)", command):
        tail = m.group(2).strip()
        # Split on whitespace; filter shell ops.
        for token in tail.split():
            if token.startswith("-"):
                continue
            token = token.strip("'\"")
            if token and not re.match(r"^[|;&<>]", token):
                targets.append(token)
            break
    return targets


def _extract_dd_targets(command: str):
    return [
        m.group(1)
        for m in re.finditer(rf"\bdd\b[^|;&]*\bof={_PATH_TOKEN}", command)
    ]


def _extract_in_place_targets(command: str):
    # sed -i / gawk -i inplace / perl -i / ruby -i — file is the last
    # non-option positional arg on the same command segment.
    targets = []
    in_place_patterns = (
        r"\bsed\b[^|;&]*-i\b[^|;&]*",
        r"\bg?awk\b[^|;&]*-i\s+inplace\b[^|;&]*",
        r"\bperl\b[^|;&]*-i\b[^|;&]*",
        r"\bruby\b[^|;&]*-i\b[^|;&]*",
    )
    for pattern in in_place_patterns:
        for m in re.finditer(pattern, command):
            segment = m.group(0)
            tokens = [t.strip("'\"") for t in segment.split() if t]
            # Pick trailing tokens that look like paths.
            for token in reversed(tokens):
                if token.startswith("-") or token in {"sed", "awk", "gawk", "perl", "ruby", "inplace"}:
                    continue
                # Skip the -i argument's quoted backup-suffix value if any.
                if "/" in token or "." in token or not token.startswith("'"):
                    targets.append(token)
                    break
    return targets


def _extract_mutation_targets(command: str):
    # mv/cp/rm/truncate/install — flag any path-looking argument.
    targets = []
    for m in re.finditer(
        r"\b(mv|cp|rm|truncate|install)\b([^|;&]+)", command
    ):
        tail = m.group(2)
        for token in tail.split():
            if token.startswith("-"):
                continue
            token = token.strip("'\"")
            if token:
                targets.append(token)
    return targets


def _extract_interpreter_inline_targets(command: str):
    # python -c '...', node -e '...', ruby -e, perl -e, bash <<EOF, etc.
    # We scan the entire command string for path-looking tokens inside the
    # interpreter argument. Conservative: extract any path-looking token
    # from the whole command when an interpreter inline is detected, and
    # let the caller's allow-list filter pick the off-list ones.
    if not re.search(
        rf"\b{_INTERPRETER_RE}\b[^|;&]*(?:-c\b|-e\b|<<[-~]?\s*['\"]?\w+)",
        command,
    ):
        return []
    # Find string-literal-looking path tokens: anything containing '/' or
    # ending in a common file extension.
    targets = []
    for token_match in re.finditer(
        r"""['"]([^'"|;&<>\s]+\.(?:md|py|sh|json|yaml|yml|toml|txt|js|ts|rs|go|html|css))['"]""",
        command,
    ):
        targets.append(token_match.group(1))
    # Also bare paths with a slash.
    for token_match in re.finditer(
        r"""['"]([^'"|;&<>\s]*/[^'"|;&<>\s]+)['"]""", command
    ):
        targets.append(token_match.group(1))
    return targets


def _extract_write_targets_from_command(command: str):
    """Return all candidate write-target paths found in a shell command.

    The list may include duplicates and unrelated tokens; the caller filters
    against the allow-list. Empty list means "no detectable writes".
    """
    targets = []
    targets.extend(_extract_redirect_targets(command))
    targets.extend(_extract_tee_targets(command))
    targets.extend(_extract_dd_targets(command))
    targets.extend(_extract_in_place_targets(command))
    targets.extend(_extract_mutation_targets(command))
    targets.extend(_extract_interpreter_inline_targets(command))
    return targets


# ---------------------------------------------------------------------------
# Path handling.
# ---------------------------------------------------------------------------


def _normalise(path: str) -> str:
    """Normalise to a repo-root-relative POSIX-style path.

    - Strips leading `./`.
    - Resolves `..` segments lexically.
    - If absolute and inside CLAUDE_PROJECT_DIR, makes it relative.
    - Otherwise returns the cleaned absolute path (which will not match the
      allow-list and will be denied).
    """
    if not path:
        return ""
    p = path.strip()
    project_dir = os.environ.get("CLAUDE_PROJECT_DIR") or os.getcwd()
    project_dir = os.path.abspath(project_dir)

    if os.path.isabs(p):
        try:
            rel = os.path.relpath(p, project_dir)
        except ValueError:
            rel = p
        if rel.startswith(".."):
            # Outside the project tree; preserve absolute form.
            return os.path.normpath(p)
        return rel.replace(os.sep, "/")

    # Relative: lexically normalise.
    cleaned = os.path.normpath(p).replace(os.sep, "/")
    if cleaned.startswith("./"):
        cleaned = cleaned[2:]
    return cleaned


def _matches_recursive_glob(path: str, glob: str) -> bool:
    # glob like "docs/tech-lead/**". A path matches if it's exactly the
    # prefix directory or strictly under it.
    if not glob.endswith("/**"):
        return False
    prefix = glob[:-3]  # strip "/**"
    return path == prefix or path.startswith(prefix + "/")


def is_on_allow_list(path: str) -> bool:
    norm = _normalise(path)
    if not norm:
        return False
    if norm in ALLOW_EXACT:
        return True
    for glob in ALLOW_GLOBS_SHALLOW:
        if fnmatch.fnmatchcase(norm, glob):
            return True
    for glob in ALLOW_GLOBS_RECURSIVE:
        if _matches_recursive_glob(norm, glob):
            return True
    return False


def _is_customer_notes_path(path: str) -> bool:
    norm = _normalise(path)
    if not norm:
        return False
    if os.path.basename(norm) == CUSTOMER_NOTES_BASENAME:
        return True
    if norm.startswith(CUSTOMER_NOTES_DIR_PREFIX):
        return True
    return False


# ---------------------------------------------------------------------------
# Specialist routing for diagnostic message.
# ---------------------------------------------------------------------------


def _owning_specialist(path: str) -> str:
    norm = _normalise(path)
    if norm.startswith("docs/adr/"):
        return "architect"
    if norm.startswith("tests/"):
        return "qa-engineer"
    if norm.startswith(".github/workflows/"):
        return "release-engineer"
    if norm.startswith("docs/security/"):
        return "security-engineer"
    if norm.startswith("scripts/") or norm.startswith("src/"):
        return "software-engineer"
    if norm == "CHANGELOG.md" or norm.startswith("docs/"):
        return "tech-writer"
    return "the appropriate specialist"


# ---------------------------------------------------------------------------
# Escape-hatch parsing.
# ---------------------------------------------------------------------------


def _agent_push_role():
    """Return the SWDT_AGENT_PUSH role if valid, else None.

    None means "no escape hatch in effect" (either unset, empty, or
    unrecognised). Unrecognised values are treated as absent rather than
    raising — the hook fails closed by applying the allow-list.
    """
    value = os.environ.get("SWDT_AGENT_PUSH", "").strip()
    if not value:
        return None
    if value in CANONICAL_ROLES:
        return value
    if SME_ROLE_RE.match(value):
        return value
    return None


# ---------------------------------------------------------------------------
# Decision construction.
# ---------------------------------------------------------------------------


def _deny_output(path: str, kind: str) -> dict:
    specialist = _owning_specialist(path)
    reason = (
        f"FW-ADR-0012: tech-lead may not write {kind} '{path}' directly. "
        f"Dispatch '{specialist}' to author this file, or set "
        "SWDT_AGENT_PUSH=<role> if this is tool-bridge work on behalf of a "
        "specialist whose sandbox cannot write. Allow-list lives in "
        "docs/adr/fw-adr-0012-tech-lead-authoring-guard.md."
    )
    return {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }


def _audit_override(path: str, role: str, kind: str) -> None:
    sys.stderr.write(
        f"tech-lead-authoring-guard: SWDT_AGENT_PUSH={role} override permitted "
        f"write to {kind} '{path}'.\n"
    )


# ---------------------------------------------------------------------------
# Main decision logic.
# ---------------------------------------------------------------------------


def _decide_for_path(path: str):
    """Return (decision, audit_callable) for a single target path.

    decision is one of:
      - None: proceed silently (path on allow-list or deferred to
        customer-notes-guard).
      - dict: a hookSpecificOutput payload (deny).

    audit_callable, when not None, is invoked after the decision is
    finalised to emit the override audit-log line on stderr.
    """
    if not path:
        return None, None

    # Customer-notes paths defer to customer-notes-guard. We do not
    # double-block here regardless of the escape-hatch role.
    if _is_customer_notes_path(path):
        return None, None

    if is_on_allow_list(path):
        return None, None

    role = _agent_push_role()
    if role is not None:
        return None, lambda: _audit_override(_normalise(path), role, "path")

    return _deny_output(_normalise(path), "path"), None


def _decide_for_command(command: str):
    if not command:
        return None, None

    targets = _extract_write_targets_from_command(command)
    if not targets:
        return None, None

    off_list = []
    for t in targets:
        norm = _normalise(t)
        if not norm:
            continue
        if _is_customer_notes_path(norm):
            # Defer to customer-notes-guard.
            continue
        if is_on_allow_list(norm):
            continue
        off_list.append(norm)

    if not off_list:
        return None, None

    first = off_list[0]
    role = _agent_push_role()
    if role is not None:
        return None, lambda: _audit_override(first, role, "Bash target")

    return _deny_output(first, "Bash target"), None


def main() -> int:
    try:
        event = json.load(sys.stdin)
    except json.JSONDecodeError:
        return 0

    if not isinstance(event, dict):
        return 0

    tool_input = event.get("tool_input") or {}
    if not isinstance(tool_input, dict):
        return 0

    file_path = tool_input.get("file_path") or tool_input.get("path") or ""
    command = tool_input.get("command") or ""

    decision = None
    audit = None

    if isinstance(file_path, str) and file_path:
        decision, audit = _decide_for_path(file_path)

    if decision is None and isinstance(command, str) and command:
        decision, audit = _decide_for_command(command)

    if audit is not None:
        audit()

    if decision is not None:
        print(json.dumps(decision))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
