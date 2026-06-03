#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# Claude Code PreToolUse hook: require explicit confirmation before
# CUSTOMER_NOTES.md writes. The hook input does not provide a stable role
# identity, so this is an approval gate rather than a role detector.

import json
import os
import re
import sys


# Read-vs-write distinction (issues #111, #175, #182).
#
# Earlier versions flagged any shell command that contained the literal
# string "CUSTOMER_NOTES.md", which prompted on every read-only inspection
# (`grep CUSTOMER_NOTES.md`, `cat ...`, `sed -n '1,40p' ...`, `wc -l ...`,
# `diff ... CUSTOMER_NOTES.md`, etc.). That trained the customer to dismiss
# the prompt reflexively, which defeats the gate on actual writes (#111).
#
# Issue #182 widened the same class of false-positives to interpreter
# inline / heredoc bodies — `python3 -c "json.load(open('CUSTOMER_NOTES.md'))"`,
# `python3 <<EOF\nopen('CUSTOMER_NOTES.md').read()\nEOF`,
# `sh -c 'cat CUSTOMER_NOTES.md'`. These are read-only and must pass.
# Tech-lead-authoring-guard.py received the matching read-vs-write
# tightening in PRs #178 (issue #175) and the #179/#180 follow-up
# (heredoc-prose + non-shell-interpreter blanking). #182 mirrors the
# same helpers here so the two sister hooks stay in sync.
#
# A command is treated as a write only when it both (a) mentions
# CUSTOMER_NOTES.md AND (b) carries a write marker that resolves to the
# file. Markers detected:
#
#   - shell redirection (`>`, `>>`, `>|`, `&>`, `2>&1 >`) where the target
#     filename mentions CUSTOMER_NOTES.md, including redirects emitted
#     INSIDE a `bash -c` / `sh -c` body
#   - in-place edit flags (`sed -i`, `gawk -i inplace`, `perl -i`,
#     `ruby -i`) on a CUSTOMER_NOTES.md operand
#   - obvious mutation (`mv`, `cp`, `rm`, `truncate`, `install`) naming
#     the file
#   - tee / dd whose target names the file
#   - interpreter `-c` / `-e` body with `open(path, 'w'|'a'|'x'|'+')`
#     positional-mode or `mode='w'` kwarg-mode where the path mentions
#     the file (#182)
#   - interpreter heredoc body with the same `open(..., write-mode)`
#     pattern (#182)
#
# Read-only commands (`grep`, `rg`, `sed -n`, `head`, `tail`, `cat`,
# `less`, `more`, `view`, `wc`, `diff`, `cmp`, plain `awk` without
# `-i inplace`, `find ... -print`, `ls`, `python3 -c "open(path).read()"`,
# `python3 <<EOF; open(path).read(); EOF`, `sh -c 'cat path'`) do NOT
# trigger the gate.
CUSTOMER_NOTES = "CUSTOMER_NOTES.md"
CUSTOMER_NOTES_RE = r"CUSTOMER_NOTES\.md"
INTERPRETER_RE = r"(?:python|python3|node|ruby|perl|bash|sh|php|lua|Rscript)"


def _mentions_customer_notes(command: str) -> bool:
    return CUSTOMER_NOTES in command


def _redirects_to_customer_notes(command: str) -> bool:
    # Shell redirection into the file. Forms covered:
    #   `> FILE`, `>> FILE`         — plain stdout redirect/append
    #   `1> FILE`, `2> FILE`, `2>&1 > FILE`  — fd-prefixed redirect
    #   `&> FILE`, `&>> FILE`       — bash combined stdout+stderr
    #   `>| FILE`                   — clobber-redirect (set -C bypass)
    # Pattern: optional fd digits OR `&`, then `>` (optional second `>`
    # for append, optional `|` for clobber), optional whitespace, then
    # any non-separator chars, then the filename.
    return bool(
        re.search(rf"(?:[0-9]+|&)?>>?\|?\s*[^|;&\s]*{CUSTOMER_NOTES_RE}", command)
    )


def _tee_writes_customer_notes(command: str) -> bool:
    # Conservative-bias false positive: `tee /tmp/log < CUSTOMER_NOTES.md`
    # uses the file as a read source rather than a tee target, but is
    # rare enough that a stray prompt is acceptable.
    return bool(re.search(rf"\btee\b[^|;&]*{CUSTOMER_NOTES_RE}", command))


def _dd_writes_customer_notes(command: str) -> bool:
    # `dd of=FILE` writes; `dd if=FILE` reads, so we test specifically
    # for the `of=` operand paired with the filename.
    return bool(re.search(rf"\bdd\b[^|;&]*\bof=[^|;&\s]*{CUSTOMER_NOTES_RE}", command))


def _in_place_edits_customer_notes(command: str) -> bool:
    in_place_patterns = (
        r"\bsed\b[^|;&]*-i\b",
        r"\bg?awk\b[^|;&]*-i\s+inplace\b",
        r"\bperl\b[^|;&]*-i\b",
        r"\bruby\b[^|;&]*-i\b",
    )
    return any(re.search(pattern, command) for pattern in in_place_patterns)


def _mutation_command_touches_customer_notes(command: str) -> bool:
    # For mv/cp the file may be source OR destination; we cannot reliably
    # parse, so flag any mention with these verbs. rm/truncate are unambiguous.
    return bool(
        re.search(
            rf"\b(mv|cp|rm|truncate|install)\b[^|;&]*{CUSTOMER_NOTES_RE}",
            command,
        )
    )


# Positional form: ``open('path', 'w')`` / ``open('path', 'wb')`` / etc.
# The mode capture allows any chars (so 'wb', 'rb+', 'a+' all match) as
# long as it contains at least one write-mode char. Mirrors
# tech-lead-authoring-guard.py::_OPEN_WRITE_RE (kept verbatim so the
# sister hooks stay aligned).
_OPEN_WRITE_RE = re.compile(
    r"""open\(\s*['"]([^'"]+)['"]\s*,\s*['"]([^'"]*[waxA+][^'"]*)['"]"""
)

# Kwarg form: ``open('path', mode='w')`` / ``open('path', buffering=0, mode='wb')``.
_OPEN_WRITE_KWARG_RE = re.compile(
    r"""open\(\s*['"]([^'"]+)['"][^)]*\bmode\s*=\s*['"]([^'"]*[waxA+][^'"]*)['"]"""
)

# pathlib write-method coverage (issue #184). Mirrors
# tech-lead-authoring-guard.py::_PATHLIB_* --- kept verbatim so the
# sister hooks stay aligned. write_text / write_bytes are unconditional
# writes; Path(...).open(...) uses the same mode-char set as open().
_PATHLIB_CTOR = r"(?:pathlib\.)?(?:Path|PurePath|PosixPath|WindowsPath)"
_PATHLIB_WRITE_TEXT_RE = re.compile(
    rf"""{_PATHLIB_CTOR}\(\s*['"]([^'"]+)['"]\s*\)\.write_(?:text|bytes)\("""
)
_PATHLIB_OPEN_RE = re.compile(
    rf"""{_PATHLIB_CTOR}\(\s*['"]([^'"]+)['"]\s*\)\.open\(\s*['"]([^'"]*[waxA+][^'"]*)['"]"""
)
_PATHLIB_OPEN_KWARG_RE = re.compile(
    rf"""{_PATHLIB_CTOR}\(\s*['"]([^'"]+)['"]\s*\)\.open\([^)]*\bmode\s*=\s*['"]([^'"]*[waxA+][^'"]*)['"]"""
)


def _extract_open_write_paths(body: str):
    """Return paths opened with a write mode in ``body``.

    Mirrors tech-lead-authoring-guard.py::_extract_write_targets_from_body
    but without redirect detection — the caller decides whether to scan
    the body for redirects (shell `-c` body: yes; non-shell interpreter
    `-c` and heredoc bodies: no, per #180 + #182). Also covers pathlib
    write methods per issue #184: ``Path("x").write_text(...)``,
    ``Path("x").write_bytes(...)``, ``Path("x").open("w")`` and the
    kwarg form ``Path("x").open(mode="w")``.
    """
    if not body:
        return []
    targets = []
    for regex in (_OPEN_WRITE_RE, _OPEN_WRITE_KWARG_RE):
        for m in regex.finditer(body):
            path, mode = m.group(1), m.group(2)
            if any(ch in mode for ch in ("w", "a", "x", "A", "+")):
                targets.append(path)
    # pathlib write-method detection (issue #184).
    for m in _PATHLIB_WRITE_TEXT_RE.finditer(body):
        targets.append(m.group(1))
    for regex in (_PATHLIB_OPEN_RE, _PATHLIB_OPEN_KWARG_RE):
        for m in regex.finditer(body):
            p_path, p_mode = m.group(1), m.group(2)
            if any(ch in p_mode for ch in ("w", "a", "x", "A", "+")):
                targets.append(p_path)
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


def _strip_non_shell_interpreter_bodies(command: str) -> str:
    """Return ``command`` with non-shell ``-c`` / ``-e`` body regions blanked.

    Mirrors tech-lead-authoring-guard.py::_strip_non_shell_interpreter_bodies.
    For interpreters whose ``-c`` / ``-e`` argument is NOT shell syntax
    (python, python3, node, ruby, perl, php, lua, Rscript), the quoted
    body is the interpreter's own language; redirect-like ``>`` tokens
    or quoted path strings inside it are data, not shell. Blank the body
    region so shell-level extractors do not see phantom redirects to
    CUSTOMER_NOTES.md (#182). The body is still scanned separately for
    write-mode ``open(..., 'w'|...)`` calls.

    Shell interpreters (``bash``, ``sh``) are deliberately excluded:
    their ``-c`` body IS shell syntax.
    """
    non_shell = r"(?:python|python3|node|ruby|perl|php|lua|Rscript)"
    pattern = re.compile(rf"\b{non_shell}\b[^|;&]*?(?:-c\b|-e\b)\s*(['\"])")
    out = list(command)
    for m in pattern.finditer(command):
        quote = m.group(1)
        start = m.end()
        end = _find_matching_quote(command, start, quote)
        for k in range(start, end):
            if out[k] != "\n":
                out[k] = " "
    return "".join(out)


def _strip_heredoc_bodies(command: str) -> str:
    """Return ``command`` with heredoc body regions removed.

    Mirrors tech-lead-authoring-guard.py::_strip_heredoc_bodies. Each
    ``<<DELIM`` opener has its body — from the end of the opener line
    up to and including the closing ``DELIM`` line — replaced with a
    single newline. Shell-level write-pattern extractors (redirect,
    tee, dd, in-place, mutation) then run only over actual shell
    syntax, not over heredoc data (#182).

    The opener line itself is preserved so post-opener redirects like
    ``cat <<EOF >> CUSTOMER_NOTES.md`` (a real write) still trip the
    redirect scanner.
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
        nl = command.find("\n", m.end())
        if nl == -1:
            out.append(command[i:])
            break
        # Keep up to and including the newline that ends the opener line.
        out.append(command[i : nl + 1])
        body_start = nl + 1
        end_match = re.search(
            rf"(?m)^\s*{re.escape(delim)}\s*$", command[body_start:]
        )
        if end_match is None:
            break
        skip_to = body_start + end_match.end()
        if skip_to < len(command) and command[skip_to] == "\n":
            skip_to += 1
        i = skip_to
    return "".join(out)


def _interpreter_inline_writes_customer_notes(command: str) -> bool:
    """Detect a write to CUSTOMER_NOTES.md inside an interpreter `-c`/`-e` body
    or any heredoc body.

    A body is a write iff it contains ``open('CUSTOMER_NOTES.md', <write-mode>)``
    or ``open('CUSTOMER_NOTES.md', mode='<write-mode>')``. The path must
    mention the file (basename match); other paths in the body do not
    fire this gate (different file).

    Shell `-c`/`-e` bodies (`bash -c`, `sh -c`) are also scanned for
    shell-redirects into CUSTOMER_NOTES.md. Non-shell interpreters have
    their bodies blanked by ``_strip_non_shell_interpreter_bodies``
    before the outer redirect scan, so a redirect in a python/node
    string does NOT fire the gate.
    """
    targets: list[str] = []

    # 1. Inline `-c` / `-e` arguments. Body is `open(...)`-scanned for
    # every interpreter; for shell interpreters we also scan the body
    # for redirect-style writes.
    shell_interpreters = {"bash", "sh"}
    interp_re = re.compile(
        rf"\b(?P<interp>{INTERPRETER_RE})\b[^|;&]*?(?:-c\b|-e\b)\s*(?P<quote>['\"])"
    )
    for m in interp_re.finditer(command):
        quote = m.group("quote")
        interp = m.group("interp")
        start = m.end()
        end = _find_matching_quote(command, start, quote)
        body = command[start:end]
        targets.extend(_extract_open_write_paths(body))
        if interp in shell_interpreters:
            # Shell body: redirect into CUSTOMER_NOTES.md inside the body
            # is a real write. The non-shell case is blanked at the
            # outer-command level by _strip_non_shell_interpreter_bodies.
            if _redirects_to_customer_notes(body):
                return True

    # 2. Heredocs. Scan body only for write-mode open(); a heredoc body
    # is data, not shell, so we deliberately do NOT scan for redirects
    # (a redirect inside a heredoc body is prose, e.g. "stdout > stderr"
    # or a python `print('a > b')`).
    for m in re.finditer(
        r"<<[-~]?\s*(?P<q>['\"]?)(?P<delim>[A-Za-z_][A-Za-z0-9_]*)(?P=q)",
        command,
    ):
        delim = m.group("delim")
        body_start = m.end()
        end_match = re.search(
            rf"(?m)^\s*{re.escape(delim)}\s*$", command[body_start:]
        )
        body = (
            command[body_start : body_start + end_match.start()]
            if end_match
            else command[body_start:]
        )
        targets.extend(_extract_open_write_paths(body))

    return any(os.path.basename(t) == CUSTOMER_NOTES for t in targets)


def _command_writes_customer_notes(command: str) -> bool:
    if not _mentions_customer_notes(command):
        return False

    # Shell-level extractors must NOT see heredoc body text (prose with
    # `>`) or quoted strings inside non-shell interpreter `-c` bodies
    # (those are interpreter language, not shell). Build the "shell view"
    # by stripping heredoc bodies + blanking non-shell -c bodies; run the
    # shell write checks against that view. The interpreter-inline /
    # heredoc-body write detector still receives the unmodified command
    # so it can find real writes inside those bodies.
    shell_view = _strip_heredoc_bodies(command)
    shell_view = _strip_non_shell_interpreter_bodies(shell_view)

    # If the post-strip view no longer mentions CUSTOMER_NOTES.md, the
    # only remaining mentions live in interpreter / heredoc bodies; the
    # interpreter detector is then the authoritative gate.
    shell_view_has_target = _mentions_customer_notes(shell_view)

    if shell_view_has_target:
        shell_checks = (
            _redirects_to_customer_notes,
            _tee_writes_customer_notes,
            _dd_writes_customer_notes,
            _in_place_edits_customer_notes,
            _mutation_command_touches_customer_notes,
        )
        if any(check(shell_view) for check in shell_checks):
            return True

    return _interpreter_inline_writes_customer_notes(command)


def _path_touches_customer_notes(file_path: str) -> bool:
    return os.path.basename(file_path) == CUSTOMER_NOTES


def _tool_input_touches_customer_notes(tool_input: dict) -> bool:
    file_path = tool_input.get("file_path") or tool_input.get("path") or ""
    command = tool_input.get("command") or ""
    return _path_touches_customer_notes(file_path) or _command_writes_customer_notes(
        command
    )


# ---------------------------------------------------------------------------
# Content-awareness (issue #292 guard half, ruling Q-0031).
#
# When a write to CUSTOMER_NOTES.md is detected we also inspect the candidate
# content for structural and size anomalies and add advisory findings to the
# gate message. This AUGMENTS the approval prompt — it does not silently
# block; the decision remains "ask".
#
# Thresholds / heuristics:
#   ENTRY_MAX_LINES  — maximum lines a single well-formed entry should span.
#                      A canonical entry has ~10 lines; 60 gives generous
#                      headroom for a long verbatim answer before we flag.
#   ENTRY_MAX_CHARS  — maximum characters for a single entry (4 000 ≈ 10×
#                      the ~400-char average entry; covers multi-paragraph
#                      answers without penalizing normal usage).
#
# Conservative-bias is intentional: false-positive findings here re-train
# dismissal (the same lesson that led to the #111 fix), so findings are
# worded as advisories and we prefer under-flagging over over-flagging.
# ---------------------------------------------------------------------------

ENTRY_MAX_LINES = 60   # lines; flag entries longer than this
ENTRY_MAX_CHARS = 4000  # characters; flag entries longer than this

# Required headed sections in a canonical CUSTOMER_NOTES entry.
_REQUIRED_SECTIONS = [
    r"^##\s+\d{4}-\d{2}-\d{2}",          # ## YYYY-MM-DD — ... header
    r"^\*\*Question",                      # **Question (from tech-lead, Q-NNNN):**
    r"^\*\*Customer answer \(verbatim\):", # **Customer answer (verbatim):**
    r"^\*\*Recorded by:",                  # **Recorded by:**
]

# Pattern that identifies the start of a canonical entry heading.
_ENTRY_HEADING_RE = re.compile(r"^##\s+\d{4}-\d{2}-\d{2}", re.MULTILINE)

# A canonical entry must have verbatim-quote lines (lines starting with ">")
# for BOTH the question and the answer.  One blockquote line is not enough —
# require at least two to cover question + answer.
_VERBATIM_QUOTE_RE = re.compile(r"^>", re.MULTILINE)


def _extract_candidate_content(tool_input: dict) -> str | None:
    """Extract the content being written to CUSTOMER_NOTES.md, best-effort.

    For Write/Edit tool inputs, the new content is available directly.
    For Bash command inputs, we try to extract heredoc bodies or the text
    after a redirect for simple ``echo`` / ``printf`` forms.
    Returns None when the content is not inspectable (degrade gracefully).
    """
    # Write tool: tool_input has a "content" field.
    content = tool_input.get("content")
    if content and isinstance(content, str):
        return content

    # Edit tool: "new_string" is the replacement block.
    new_string = tool_input.get("new_string")
    if new_string and isinstance(new_string, str):
        return new_string

    # Bash tool: try to pull heredoc bodies from the command string.
    command = tool_input.get("command") or ""
    if not command:
        return None

    bodies: list[str] = []
    opener_re = re.compile(
        r"<<[-~]?\s*(?P<q>['\"]?)(?P<delim>[A-Za-z_][A-Za-z0-9_]*)(?P=q)"
    )
    for m in opener_re.finditer(command):
        delim = m.group("delim")
        body_start = command.find("\n", m.end())
        if body_start == -1:
            continue
        body_start += 1
        end_match = re.search(
            rf"(?m)^\s*{re.escape(delim)}\s*$", command[body_start:]
        )
        if end_match:
            bodies.append(command[body_start : body_start + end_match.start()])

    if bodies:
        return "\n".join(bodies)

    return None


def _content_findings(content: str) -> list[str]:
    """Return a list of advisory finding strings for the candidate content.

    Returns an empty list when the content looks well-formed.
    Conservative: emit findings only when clearly warranted.
    """
    findings: list[str] = []

    lines = content.splitlines()
    line_count = len(lines)
    char_count = len(content)

    # Detect multi-entry / full-file payloads: the Write tool passes the
    # entire file as `content` when rewriting CUSTOMER_NOTES.md, which is
    # hundreds of lines and contains many entry headings.  OVERSIZED and
    # UNSTRUCTURED are per-entry checks that are meaningless (and produce
    # false-positive #111-style alert fatigue) when applied to a bulk
    # payload.  If the content contains more than one entry heading
    # (^## YYYY-MM-DD), treat it as a multi-entry write and skip those
    # two checks; the gate itself still fires normally.
    entry_heading_count = len(_ENTRY_HEADING_RE.findall(content))
    is_multi_entry = entry_heading_count > 1

    if not is_multi_entry:
        # --- Oversized check (single-entry payloads only) ---
        if line_count > ENTRY_MAX_LINES:
            findings.append(
                f"OVERSIZED: entry is {line_count} lines (threshold {ENTRY_MAX_LINES}). "
                "Confirm this is a single entry, not an accidental multi-entry bulk write."
            )
        if char_count > ENTRY_MAX_CHARS:
            findings.append(
                f"OVERSIZED: entry is {char_count} chars (threshold {ENTRY_MAX_CHARS}). "
                "Confirm this is a single entry."
            )

        # --- Unstructured check: required headed sections (single-entry only) ---
        missing_sections: list[str] = []
        for pattern in _REQUIRED_SECTIONS:
            if not re.search(pattern, content, re.MULTILINE):
                missing_sections.append(pattern)
        if missing_sections:
            findings.append(
                "UNSTRUCTURED: entry is missing required section(s). "
                "Expected: ## YYYY-MM-DD header, **Question …, "
                "**Customer answer (verbatim):, **Recorded by:. "
                f"Absent pattern(s): {missing_sections!r}"
            )

    # --- Off-scope check: verbatim-quote blocks ---
    # The canonical template requires verbatim block-quotes for BOTH the
    # question and the customer answer.  Require at least two ">" lines;
    # a single blockquote line could be present in one section but absent
    # in the other, meaning the entry is still incomplete.
    # Applied to both single- and multi-entry payloads (a full-file write
    # that lacks any blockquotes is a strong signal of non-customer-truth
    # material, and is worth flagging even in that context).
    quote_line_count = len(_VERBATIM_QUOTE_RE.findall(content))
    if quote_line_count < 2:
        findings.append(
            "OFF-SCOPE (advisory): entry has fewer than 2 verbatim-quote lines "
            f"(found {quote_line_count}, lines starting with '>'). "
            "A canonical CUSTOMER_NOTES entry must include block-quoted verbatim "
            "text for both the question and the customer answer. "
            "Approve only if this is intentional maintenance rather than a "
            "new customer-truth entry."
        )

    return findings


def _approval_gate_output(findings: list[str] | None = None) -> dict:
    base_reason = (
        "CUSTOMER_NOTES.md is the verbatim customer-truth record. "
        "Per the template contract, tech-lead must route customer-answer "
        "entries to researcher; approve only for researcher-owned notes "
        "maintenance or an intentional human edit."
    )
    if findings:
        findings_block = "\n\nContent findings:\n" + "\n".join(
            f"  [{i + 1}] {f}" for i, f in enumerate(findings)
        )
        reason = base_reason + findings_block
    else:
        reason = base_reason
    return {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "ask",
            "permissionDecisionReason": reason,
        }
    }


def main() -> int:
    try:
        event = json.load(sys.stdin)
    except json.JSONDecodeError:
        return 0

    # Fail-open if the harness sends syntactically-valid but
    # structurally-unexpected JSON (issue #156). The hook only knows how
    # to inspect dict-shaped payloads; anything else is not a tool
    # invocation we should gate.
    if not isinstance(event, dict):
        return 0

    tool_input = event.get("tool_input") or {}
    if not isinstance(tool_input, dict):
        return 0

    if not _tool_input_touches_customer_notes(tool_input):
        return 0

    # Content-awareness: inspect candidate write content for advisory findings.
    # Degrade gracefully — a failure to extract content produces no findings,
    # not a crash or a silent pass.
    findings: list[str] = []
    try:
        content = _extract_candidate_content(tool_input)
        if content is not None:
            findings = _content_findings(content)
    except Exception:  # noqa: BLE001
        # Never crash on content inspection; the gate still fires.
        pass

    print(json.dumps(_approval_gate_output(findings or None)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
