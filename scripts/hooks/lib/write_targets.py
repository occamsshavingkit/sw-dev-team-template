#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors

from __future__ import annotations

import re
import shlex

_PATH_TOKEN = r"['\"]?([^|;&\s<>'\"]+)['\"]?"  # nosec B105 - regex path token, not a secret
_PY_WRITE_MODE = r"[^'\"]*[waxA+][^'\"]*"
_PATHLIB_CTOR = r"(?:pathlib\.)?(?:Path|PurePath|PosixPath|WindowsPath)"


def extract_write_targets(command: str) -> list[str]:
    """Return simple shell write targets from redirects and tee commands."""
    if not command:
        return []

    redirect_re = rf"(?:[0-9]+|&)?>>?\|?\s*{_PATH_TOKEN}"
    targets = [m.group(1) for m in re.finditer(redirect_re, command)]

    for match in re.finditer(r"\btee\b(?:\s+-[a-zA-Z]+)*\s+([^|;&]+)", command):
        for token in match.group(1).split():
            if token.startswith("-"):
                continue
            token = token.strip("'\"")
            if token and not re.match(r"^[|;&<>]", token):
                targets.append(token)

    for match in re.finditer(
        rf"\bopen\(\s*['\"]([^'\"]+)['\"]\s*,\s*['\"]{_PY_WRITE_MODE}['\"]",
        command,
    ):
        targets.append(match.group(1))

    for match in re.finditer(
        rf"\bopen\(\s*['\"]([^'\"]+)['\"][^)]*\bmode\s*=\s*['\"]{_PY_WRITE_MODE}['\"]",
        command,
    ):
        targets.append(match.group(1))

    for match in re.finditer(
        rf"{_PATHLIB_CTOR}\(\s*['\"]([^'\"]+)['\"]\s*\)\.write_(?:text|bytes)\(",
        command,
    ):
        targets.append(match.group(1))

    for segment in re.split(r"[|;&]", command):
        try:
            tokens = shlex.split(segment)
        except ValueError:
            continue
        if not tokens:
            continue

        if tokens[0] == "rm":
            targets.extend(token for token in tokens[1:] if not token.startswith("-"))

        if tokens[0] == "sed" and any(token == "-i" or token.startswith("-i") for token in tokens[1:]):
            operands = [token for token in tokens[1:] if not token.startswith("-")]
            targets.extend(operands[1:])

        if tokens[0] == "dd":
            for token in tokens[1:]:
                if token.startswith("of=") and len(token) > 3:
                    targets.append(token[3:])

        if tokens[0] == "cp":
            operands = [token for token in tokens[1:] if not token.startswith("-")]
            if operands:
                targets.append(operands[-1])

        if tokens[0] == "mv":
            targets.extend(token for token in tokens[1:] if not token.startswith("-"))

        if tokens[0] == "install":
            operands = [token for token in tokens[1:] if not token.startswith("-")]
            if "-d" in tokens[1:] or "--directory" in tokens[1:]:
                targets.extend(operands)
            elif operands:
                targets.append(operands[-1])

        if tokens[0] == "truncate":
            skip_next = False
            for token in tokens[1:]:
                if skip_next:
                    skip_next = False
                    continue
                if token in {"-s", "--size"}:
                    skip_next = True
                    continue
                if token.startswith("-"):
                    continue
                targets.append(token)

        if tokens[0] == "touch":
            for token in tokens[1:]:
                if token.startswith("-"):
                    continue
                targets.append(token)

    return targets
