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
# `-c` invocation that names the file (ambiguous; err on the side of
# asking).
#
# Read-only commands (`grep`, `rg`, `sed -n`, `head`, `tail`, `cat`,
# `less`, `more`, `view`, `wc`, `diff`, `cmp`, plain `awk` without
# `-i inplace`, `find ... -print`, `ls`) do NOT trigger the gate.
def _command_writes_customer_notes(command: str) -> bool:
    if "CUSTOMER_NOTES.md" not in command:
        return False

    # Shell redirection into the file. Forms covered:
    #   `> FILE`, `>> FILE`         — plain stdout redirect/append
    #   `1> FILE`, `2> FILE`, `2>&1 > FILE`  — fd-prefixed redirect
    #   `&> FILE`, `&>> FILE`       — bash combined stdout+stderr
    #   `>| FILE`                   — clobber-redirect (set -C bypass)
    # Pattern: optional fd digits OR `&`, then `>` (optional second `>`
    # for append, optional `|` for clobber), optional whitespace, then
    # any non-separator chars, then the filename.
    if re.search(r"(?:[0-9]+|&)?>>?\|?\s*[^|;&\s]*CUSTOMER_NOTES\.md", command):
        return True

    # `tee` with the file as an argument (`tee FILE`, `tee -a FILE`).
    # Conservative-bias false positive: `tee /tmp/log < CUSTOMER_NOTES.md`
    # uses the file as a read source rather than a tee target, but is
    # rare enough that a stray prompt is acceptable.
    if re.search(r"\btee\b[^|;&]*CUSTOMER_NOTES\.md", command):
        return True

    # `dd of=FILE` writes; `dd if=FILE` reads, so we test specifically
    # for the `of=` operand paired with the filename.
    if re.search(r"\bdd\b[^|;&]*\bof=[^|;&\s]*CUSTOMER_NOTES\.md", command):
        return True

    # In-place edit flags.
    if re.search(r"\bsed\b[^|;&]*-i\b", command) and "CUSTOMER_NOTES.md" in command:
        return True
    if re.search(r"\bg?awk\b[^|;&]*-i\s+inplace\b", command) and "CUSTOMER_NOTES.md" in command:
        return True
    if re.search(r"\bperl\b[^|;&]*-i\b", command) and "CUSTOMER_NOTES.md" in command:
        return True
    if re.search(r"\bruby\b[^|;&]*-i\b", command) and "CUSTOMER_NOTES.md" in command:
        return True

    # Obvious mutation commands. For mv/cp the file may be source OR
    # destination; we cannot reliably parse, so flag any mention with
    # these verbs. rm / truncate are unambiguous.
    if re.search(r"\b(mv|cp|rm|truncate|install)\b[^|;&]*CUSTOMER_NOTES\.md", command):
        return True

    # Interpreter -c with the file mentioned — could read or write;
    # ask to be safe.
    if re.search(r"\b(python|python3|perl|ruby|bash|sh)\b[^|;&]*-c\b", command):
        return True

    return False


def main() -> int:
    try:
        event = json.load(sys.stdin)
    except json.JSONDecodeError:
        return 0

    tool_input = event.get("tool_input") or {}
    file_path = tool_input.get("file_path") or tool_input.get("path") or ""
    command = tool_input.get("command") or ""

    touches_customer_notes = False
    if file_path:
        touches_customer_notes = os.path.basename(file_path) == "CUSTOMER_NOTES.md"
    if command:
        touches_customer_notes = touches_customer_notes or _command_writes_customer_notes(command)

    if not touches_customer_notes:
        return 0

    reason = (
        "CUSTOMER_NOTES.md is the verbatim customer-truth record. "
        "Per the template contract, tech-lead must route customer-answer "
        "entries to researcher; approve only for researcher-owned notes "
        "maintenance or an intentional human edit."
    )
    print(
        json.dumps(
            {
                "hookSpecificOutput": {
                    "hookEventName": "PreToolUse",
                    "permissionDecision": "ask",
                    "permissionDecisionReason": reason,
                }
            }
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
