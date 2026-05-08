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


# Read-vs-write distinction (issue #111).
#
# Earlier versions flagged any shell command that contained the literal
# string "CUSTOMER_NOTES.md", which prompted on every read-only inspection
# (`grep CUSTOMER_NOTES.md`, `cat ...`, `sed -n '1,40p' ...`, `wc -l ...`,
# `diff ... CUSTOMER_NOTES.md`, etc.). That trained the customer to dismiss
# the prompt reflexively, which defeats the gate on actual writes.
#
# A command is treated as a write only when it both (a) mentions
# CUSTOMER_NOTES.md AND (b) carries a write marker — shell redirection
# into the file, an in-place edit flag (`sed -i`, `gawk -i inplace`,
# `perl -i`, `ruby -i`), an obvious mutation command (`mv`, `cp` with
# the file as destination, `rm`, `truncate`), or an interpreter
# inline/stdin invocation that names the file (ambiguous; err on the
# side of asking).
#
# Read-only commands (`grep`, `rg`, `sed -n`, `head`, `tail`, `cat`,
# `less`, `more`, `view`, `wc`, `diff`, `cmp`, plain `awk` without
# `-i inplace`, `find ... -print`, `ls`) do NOT trigger the gate.
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


def _interpreter_may_write_customer_notes(command: str) -> bool:
    # Interpreter -c or stdin/heredoc with the file mentioned could read or
    # write; ask to be safe.
    interpreter_patterns = (
        rf"\b{INTERPRETER_RE}\b[^|;&]*-c\b",
        rf"\b{INTERPRETER_RE}\b[^|;&]*(?:\s-\s*)?<<[-~]?\s*['\"]?\w+",
        rf"\|[^|;&]*\b{INTERPRETER_RE}\b[^|;&]*(?:\s-\b|$)",
    )
    return any(re.search(pattern, command) for pattern in interpreter_patterns)


def _command_writes_customer_notes(command: str) -> bool:
    if not _mentions_customer_notes(command):
        return False

    write_checks = (
        _redirects_to_customer_notes,
        _tee_writes_customer_notes,
        _dd_writes_customer_notes,
        _in_place_edits_customer_notes,
        _mutation_command_touches_customer_notes,
        _interpreter_may_write_customer_notes,
    )
    return any(check(command) for check in write_checks)


def _path_touches_customer_notes(file_path: str) -> bool:
    return os.path.basename(file_path) == CUSTOMER_NOTES


def _tool_input_touches_customer_notes(tool_input: dict) -> bool:
    file_path = tool_input.get("file_path") or tool_input.get("path") or ""
    command = tool_input.get("command") or ""
    return _path_touches_customer_notes(file_path) or _command_writes_customer_notes(
        command
    )


def _approval_gate_output() -> dict:
    reason = (
        "CUSTOMER_NOTES.md is the verbatim customer-truth record. "
        "Per the template contract, tech-lead must route customer-answer "
        "entries to researcher; approve only for researcher-owned notes "
        "maintenance or an intentional human edit."
    )
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

    tool_input = event.get("tool_input") or {}
    if not _tool_input_touches_customer_notes(tool_input):
        return 0

    print(json.dumps(_approval_gate_output()))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
