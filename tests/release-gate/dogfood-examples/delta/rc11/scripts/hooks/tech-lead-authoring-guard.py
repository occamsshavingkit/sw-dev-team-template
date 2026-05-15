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
    except (ImportError, SyntaxError, AttributeError, OSError) as exc:
        # Fail-safe-allow: log the captured exception to stderr so a broken
        # neighbour module is visible rather than silently disabling the
        # vendored helpers. Codacy PR #173 HIGH-RISK finding: broad except
        # with no logging hides parse/import regressions.
        sys.stderr.write(
            "tech-lead-authoring-guard: failed to load customer-notes-guard "
            f"({type(exc).__name__}: {exc}); continuing without it.\n"
        )
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
    # `tee [-a] FILE [FILE ...]` — ALL non-option tokens after `tee` are
    # write targets (tee fans output to every listed file). Do NOT break
    # after the first match; an attacker can otherwise stage
    # `tee <allow-listed> <off-list>` and bypass the guard on the trailing
    # targets (HIGH-RISK bypass — Codacy PR #173 finding).
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


# Positional form: ``open('path', 'w')`` / ``open('path', 'wb')`` / etc.
# The mode capture allows any chars (so 'wb', 'rb+', 'a+' all match) as long
# as it contains at least one write-mode char.
_OPEN_WRITE_RE = re.compile(
    r"""open\(\s*['"]([^'"]+)['"]\s*,\s*['"]([^'"]*[waxA+][^'"]*)['"]"""
)

# Kwarg form: ``open('path', mode='w')`` / ``open('path', buffering=0, mode='wb')``.
# Path captured from first positional; mode captured from the kwarg. The gap
# between the path and the ``mode=`` token allows any non-paren chars (so
# additional kwargs like ``buffering=`` or ``encoding=`` don't block the
# match). Code-reviewer tightening #4: positional form alone let the kwarg
# spelling slip through as a read-only call.
_OPEN_WRITE_KWARG_RE = re.compile(
    r"""open\(\s*['"]([^'"]+)['"][^)]*\bmode\s*=\s*['"]([^'"]*[waxA+][^'"]*)['"]"""
)


def _extract_write_targets_from_body(body: str, *, scan_redirects: bool = True):
    """Extract write-target paths from an interpreter / heredoc body.

    Only flags paths that appear in a real write context:

      - ``open('path', 'w'|'a'|'x'|'+'...)`` — positional mode contains
        a write char (covers binary ``'wb'`` / ``'ab'`` too).
      - ``open('path', mode='w')`` — kwarg mode contains a write char.
      - shell-style redirects ``> path`` / ``>> path`` inside the body
        (covers ``-c "... > file"`` and shell heredocs) — only when
        ``scan_redirects=True``.

    Read-only ``open('foo.json')``, ``open('foo','r')``, and
    ``open('foo', mode='r')`` do NOT match. Quoted path tokens that are
    not the first arg of a write-mode open do NOT match. This is the
    core fix for issue #175; the kwarg branch closes the bypass flagged
    in code-reviewer tightening #4.

    ``scan_redirects=False`` is used for heredoc bodies (issue #180):
    a heredoc body is data, not shell syntax. Lines like prose with
    ``stdout > stderr`` or quoted strings containing ``>`` previously
    tripped the redirect regex on phantom path targets. Real writes
    via shell-redirect inside a heredoc body would require the body
    to be re-executed as a subshell command, which is unusual; the
    ``open(..., mode)`` detector still catches the common case of an
    interpreter-fed heredoc that opens a file for write. The top-level
    ``cat > FILE <<EOF`` redirect is caught by the command-level
    extractor independently of the heredoc-body scan.
    """
    if not body:
        return []
    targets = []
    for regex in (_OPEN_WRITE_RE, _OPEN_WRITE_KWARG_RE):
        for m in regex.finditer(body):
            path, mode = m.group(1), m.group(2)
            # Require an actual write-mode char (not just '+' which could
            # theoretically appear in a weird mode; but 'r+' is a write so
            # '+' alone is a write signal too).
            if any(ch in mode for ch in ("w", "a", "x", "A", "+")):
                targets.append(path)
    # Shell redirects inside the body. Skipped for heredoc bodies — see
    # docstring (issue #180 false-positive on prose containing ``>``).
    if scan_redirects:
        targets.extend(_extract_redirect_targets(body))
    return targets


def _find_matching_quote(command: str, start: int, quote: str) -> int:
    """Return the index of the closing quote, or len(command) if unterminated."""
    i = start
    while i < len(command):
        c = command[i]
        if c == "\\" and i + 1 < len(command):
            i += 2
            continue
        if c == quote:
            return i
        i += 1
    return len(command)


def _extract_interpreter_inline_targets(command: str):
    """Extract write targets from `-c` / `-e` inline arguments and heredocs.

    Issue #175 fix shape:

      - For ``-c`` / ``-e`` inline strings: parse the quoted body and only
        flag paths in write-context (``open(..., 'w')`` or shell redirect).
        Read-only ``open('foo.json')`` no longer trips.
      - For heredoc forms (``<<EOF ... EOF``): the heredoc DELIMITER token
        (``EOF`` etc.) is never a path. Apply the same write-context
        detector to the heredoc body. A ``cat <<EOF`` body containing a
        quoted path token is data, not a write — the redirect / open
        detector finds no match and proceeds. A ``python <<EOF`` body that
        actually opens a file for write is still caught.

    Heredoc form is intentionally permissive: only the body is scanned,
    never the trigger line itself or the rest of the command. The real
    ``cat > FILE <<EOF`` write case is caught by the top-level redirect
    extractor independently of this function.
    """
    targets = []

    # 1. Inline `-c` / `-e` arguments. For shell interpreters (bash, sh),
    # the body IS shell syntax — keep redirect detection. For other
    # interpreters (python, node, ruby, perl, php, lua, Rscript), the body
    # is the interpreter's own language, not shell; quoted strings or
    # comments containing ``>`` are data, not redirects (issue #180).
    # Rely on ``open(..., 'w'|'a'|...)`` patterns there instead.
    shell_interpreters = {"bash", "sh"}
    interp_re = re.compile(
        rf"\b(?P<interp>{_INTERPRETER_RE})\b[^|;&]*?(?:-c\b|-e\b)\s*(?P<quote>['\"])"
    )
    for m in interp_re.finditer(command):
        quote = m.group("quote")
        interp = m.group("interp")
        start = m.end()
        end = _find_matching_quote(command, start, quote)
        body = command[start:end]
        scan = interp in shell_interpreters
        targets.extend(
            _extract_write_targets_from_body(body, scan_redirects=scan)
        )

    # 2. Heredocs (any command, not just `_INTERPRETER_RE`). Capture the
    # delimiter, then scan the body up to the matching delimiter line.
    # Delimiter quoting and the `-`/`~` prefix affect how the shell
    # processes the body but not where it ends.
    #
    # Issue #180: heredoc bodies are DATA, not shell syntax. Prose lines
    # containing `>` (e.g. "If x > y then we win", "stdout > stderr.log",
    # a python `print('a > b')`) previously tripped the shell-redirect
    # regex on phantom path targets. Skip redirect detection for heredoc
    # bodies; rely on the `open(..., mode)` detector for real writes.
    for m in re.finditer(
        r"<<[-~]?\s*(?P<q>['\"]?)(?P<delim>[A-Za-z_][A-Za-z0-9_]*)(?P=q)",
        command,
    ):
        delim = m.group("delim")
        body_start = m.end()
        # End is the delimiter on its own line (or at end-of-string).
        end_match = re.search(
            rf"(?m)^\s*{re.escape(delim)}\s*$", command[body_start:]
        )
        if end_match:
            body = command[body_start : body_start + end_match.start()]
        else:
            body = command[body_start:]
        targets.extend(_extract_write_targets_from_body(body, scan_redirects=False))

    return targets


def _strip_non_shell_interpreter_bodies(command: str) -> str:
    """Return ``command`` with non-shell ``-c`` / ``-e`` body regions blanked.

    For interpreters whose ``-c`` / ``-e`` argument is NOT shell syntax
    (python, python3, node, ruby, perl, php, lua, Rscript), the quoted
    body is the interpreter's own language. Quoted strings or prose
    inside that body containing ``>`` would otherwise trip the top-level
    shell-redirect scanner (issue #180: ``python3 -c "print('a > b')"``
    flagged ``b`` as a redirect target).

    The body region between the opening quote and its matching close
    is replaced with same-length space padding so byte offsets are
    preserved (in case any caller relies on them) and so the surrounding
    shell syntax remains scannable. The body itself is still scanned
    for write-mode ``open()`` calls by
    ``_extract_interpreter_inline_targets`` which sees the unmodified
    command.

    Shell interpreters (``bash``, ``sh``) are deliberately excluded:
    their ``-c`` body IS shell syntax, so e.g.
    ``bash -c "echo x > scripts/foo.sh"`` must still trip the redirect
    scanner.
    """
    non_shell = r"(?:python|python3|node|ruby|perl|php|lua|Rscript)"
    pattern = re.compile(rf"\b{non_shell}\b[^|;&]*?(?:-c\b|-e\b)\s*(['\"])")
    out = list(command)
    for m in pattern.finditer(command):
        quote = m.group(1)
        start = m.end()
        end = _find_matching_quote(command, start, quote)
        # Blank the body chars (preserve any newlines so line-anchored
        # regex elsewhere don't get confused).
        for k in range(start, end):
            if out[k] != "\n":
                out[k] = " "
    return "".join(out)


def _strip_heredoc_bodies(command: str) -> str:
    """Return ``command`` with heredoc body regions removed.

    Each ``<<DELIM`` (or ``<<-DELIM`` / ``<<~DELIM`` / ``<<"DELIM"``)
    opener has its body — from the end of the opener line up to and
    including the closing ``DELIM`` line — replaced with a single
    newline. Shell-level write-pattern extractors (redirect, tee, dd,
    in-place, mutation) then run only over actual shell syntax, not
    over heredoc data.

    Issue #180: prose inside a heredoc body containing ``>`` previously
    tripped the top-level ``_extract_redirect_targets`` on phantom
    targets (``> y``, ``> stderr.log``, ``> stderr``). Stripping the
    body region before shell-level scans removes the false positive
    while leaving real writes intact: the ``cat > FILE <<EOF`` form
    still has its ``> FILE`` before the stripped body, and any
    interpreter-fed heredoc that performs real I/O via ``open(..., 'w')``
    is still caught by ``_extract_interpreter_inline_targets`` which
    scans the body separately for write-mode open() calls.
    """
    if "<<" not in command:
        return command
    out = []
    i = 0
    opener_re = re.compile(
        r"<<[-~]?\s*(?P<q>['\"]?)(?P<delim>[A-Za-z_][A-Za-z0-9_]*)(?P=q)"
    )
    while i < len(command):
        m = opener_re.search(command, i)
        if m is None:
            out.append(command[i:])
            break
        delim = m.group("delim")
        # The body starts at the next newline after the opener (the rest
        # of the opener line — including any post-opener redirect like
        # `<<EOF >> path` — is still real shell and must be preserved
        # for the redirect scanner). If there is no newline, the heredoc
        # is malformed / single-line; preserve everything up to and
        # including the opener match and stop.
        nl = command.find("\n", m.end())
        if nl == -1:
            out.append(command[i:])
            break
        # Keep up to and including the newline that ends the opener line
        # (so `cat <<EOF >> scripts/foo.sh\n...` still has `>> scripts/foo.sh`
        # visible, and `cat > FILE <<EOF\n...` still has `> FILE` visible).
        out.append(command[i : nl + 1])
        body_start = nl + 1
        end_match = re.search(
            rf"(?m)^\s*{re.escape(delim)}\s*$", command[body_start:]
        )
        if end_match is None:
            # Unterminated heredoc — drop the rest.
            break
        # Skip past the closing-delimiter line.
        # `end_match.end()` is the offset just after the delimiter token
        # within the body slice; advance one more to consume the newline
        # if present, so subsequent shell text (e.g. `)`) is preserved.
        skip_to = body_start + end_match.end()
        if skip_to < len(command) and command[skip_to] == "\n":
            skip_to += 1
        i = skip_to
    return "".join(out)


def _extract_write_targets_from_command(command: str):
    """Return all candidate write-target paths found in a shell command.

    The list may include duplicates and unrelated tokens; the caller filters
    against the allow-list. Empty list means "no detectable writes".

    Shell-level extractors run over a heredoc-body-stripped AND
    non-shell-interpreter-body-blanked copy of the command (issue #180:
    prose inside a heredoc body or quoted python/node/ruby/perl/lua/Rscript
    string containing ``>`` previously tripped phantom redirect targets).
    The interpreter-inline-targets extractor still sees the full command
    so it can scan heredoc bodies and ``-c`` / ``-e`` bodies for
    write-mode ``open()`` calls.
    """
    targets = []
    shell_view = _strip_heredoc_bodies(command)
    shell_view = _strip_non_shell_interpreter_bodies(shell_view)
    targets.extend(_extract_redirect_targets(shell_view))
    targets.extend(_extract_tee_targets(shell_view))
    targets.extend(_extract_dd_targets(shell_view))
    targets.extend(_extract_in_place_targets(shell_view))
    targets.extend(_extract_mutation_targets(shell_view))
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


# Table-driven path-to-role mapping. Order is significant: the first
# matching rule wins, so more-specific prefixes (e.g. `docs/adr/`,
# `docs/security/`) MUST precede the broader `docs/` fallback. Each
# entry is (predicate, role); the predicate is a callable taking the
# normalised path. Refactored from a long if/elif chain (Codacy
# cyclomatic-complexity finding on PR #173); behaviour and role mapping
# are unchanged.
_OWNERSHIP_RULES = (
    (lambda p: p.startswith("docs/adr/"), "architect"),
    (lambda p: p.startswith("tests/"), "qa-engineer"),
    (lambda p: p.startswith(".github/workflows/"), "release-engineer"),
    (lambda p: p.startswith("docs/security/"), "security-engineer"),
    (lambda p: p.startswith("scripts/") or p.startswith("src/"), "software-engineer"),
    (lambda p: p == "CHANGELOG.md" or p.startswith("docs/"), "tech-writer"),
)


def _owning_specialist(path: str) -> str:
    norm = _normalise(path)
    for predicate, role in _OWNERSHIP_RULES:
        if predicate(norm):
            return role
    return "the appropriate specialist"


# ---------------------------------------------------------------------------
# Escape-hatch parsing.
# ---------------------------------------------------------------------------


def _validate_role(value: str):
    """Return value if it is a canonical role or matches sme-*, else None.

    Semantic note: the escape hatch is tool-bridge work *on behalf of a
    different specialist*. A ``tech-lead`` self-push defeats the entire
    guard (the guard exists to keep tech-lead from authoring production
    artifacts), so it is rejected explicitly before the canonical-roles
    check — even though ``tech-lead`` is itself in CANONICAL_ROLES for
    other vocabulary purposes. Code-reviewer tightening #2.
    """
    if not value:
        return None
    if value == "tech-lead":
        # Self-push is never legitimate: the role this guard exists to
        # restrain cannot widen its own allow-list.
        return None
    if value in CANONICAL_ROLES:
        return value
    if SME_ROLE_RE.match(value):
        return value
    return None


def _agent_push_role():
    """Return the SWDT_AGENT_PUSH role if valid, else None.

    None means "no escape hatch in effect" (either unset, empty, or
    unrecognised). Unrecognised values are treated as absent rather than
    raising — the hook fails closed by applying the allow-list.
    """
    value = os.environ.get("SWDT_AGENT_PUSH", "").strip()
    return _validate_role(value)


# Inline form of the escape hatch: a user (or wrapper) may prefix a Bash
# command with `SWDT_AGENT_PUSH=<role>` or `export SWDT_AGENT_PUSH=<role>;`.
# Upstream issue #176: the natural reading of the deny message is that
# setting the env var inline should work, but Claude Code's Bash tool
# spawns a fresh shell so HARNESS env is required. Behavioural fix:
# detect the inline assignment and honour it as an escape hatch for that
# invocation. We accept the role only if it validates; unrecognised
# values fall through to the harness-env check (and ultimately deny).
#
# Issue #179: the inline form MUST be the leading command. A pattern
# like ``cd foo && SWDT_AGENT_PUSH=architect echo y > docs/adr/foo.md``
# previously matched (env-var-prefix after `&&`) and silently widened
# the allow-list, which is not the natural reading of the deny
# diagnostic. Strict anchor: the assignment is the first non-whitespace
# token of the command, OR it is preceded only by ``export\s+``. Forms
# after ``&&``, ``||``, ``;``, ``|`` no longer match.
_INLINE_AGENT_PUSH_RE = re.compile(
    r"\A\s*(?:export\s+)?SWDT_AGENT_PUSH=(['\"]?)([a-zA-Z][a-zA-Z0-9_-]*)\1"
)


def _inline_agent_push_role(command: str):
    """Return the inline SWDT_AGENT_PUSH role from a Bash command, else None.

    Only honours the assignment when it is the leading command (issue
    #179). The regex is anchored to the start of the string with
    optional leading whitespace and an optional ``export`` prefix.
    Assignments after ``&&``/``||``/``;``/``|`` do not widen the
    allow-list — they would only take effect for the subshell the
    operator chains them into, and naming a post-chain assignment as
    an escape hatch for the whole command is misleading.
    """
    if not command:
        return None
    m = _INLINE_AGENT_PUSH_RE.match(command)
    if m is None:
        return None
    return _validate_role(m.group(2).strip())


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
    role = _agent_push_role() or _inline_agent_push_role(command)
    if role is not None:
        return None, lambda: _audit_override(first, role, "Bash target")

    return _deny_output(first, "Bash target"), None


def _collect_target_paths(tool_input: dict):
    """Collect every file-target path the tool invocation may write to.

    Per the Claude Code tool spec, ``MultiEdit`` carries a single
    top-level ``file_path`` plus an ``edits`` array applying multiple
    edits to that one file — so a strict reading says only ``file_path``
    matters. Codacy PR #173 nonetheless flagged a HIGH-RISK bypass on
    the assumption that ``edits`` (or a ``files``/``changes`` array)
    might carry per-entry ``file_path`` fields on some tools or future
    revisions. We close the door defensively: collect the top-level
    ``file_path``/``path`` AND walk any list value under ``tool_input``
    for per-entry ``file_path``/``path`` strings. If ANY collected path
    is off the allow-list, the call is denied.
    """
    paths = []
    top = tool_input.get("file_path") or tool_input.get("path") or ""
    if isinstance(top, str) and top:
        paths.append(top)

    # Iterate every list value under tool_input and pull file_path/path
    # entries. Arrays we have seen named: edits, changes, files.
    for value in tool_input.values():
        if not isinstance(value, list):
            continue
        for entry in value:
            if not isinstance(entry, dict):
                continue
            candidate = entry.get("file_path") or entry.get("path") or ""
            if isinstance(candidate, str) and candidate:
                paths.append(candidate)
    return paths


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

    target_paths = _collect_target_paths(tool_input)
    command = tool_input.get("command") or ""

    decision = None
    audit = None

    # Check EVERY collected target path. If any one denies, deny the call.
    # The first matching decision (deny or audited-override) wins so the
    # surfaced diagnostic names a concrete path; the loop short-circuits on
    # deny but continues past silent proceeds to find any off-list entry.
    for path in target_paths:
        path_decision, path_audit = _decide_for_path(path)
        if path_decision is not None:
            decision, audit = path_decision, path_audit
            break
        if path_audit is not None and audit is None:
            # Remember the first override-audit so we still log it even if
            # later paths are silently allowed.
            audit = path_audit

    if decision is None and isinstance(command, str) and command:
        cmd_decision, cmd_audit = _decide_for_command(command)
        if cmd_decision is not None:
            decision = cmd_decision
            audit = cmd_audit
        elif cmd_audit is not None and audit is None:
            audit = cmd_audit

    if audit is not None:
        audit()

    if decision is not None:
        print(json.dumps(decision))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
