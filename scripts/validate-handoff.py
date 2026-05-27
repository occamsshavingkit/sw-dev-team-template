#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors

from __future__ import annotations

import json
import sys
from pathlib import Path

import jsonschema


def check_model_fallback_tier(handoff: dict) -> list[str]:
    """Enforce the data-model rule: model_fallback is acceptable only when
    capability_tier_comparison is 'same' or 'higher'.  A 'lower' value means
    the actual model is a downgrade; work must pause or escalate.

    No authoritative tier ordering is present in the repo schemas, so this
    check relies solely on the declared capability_tier_comparison field.

    Returns a list of error messages; empty list means no violation.
    """
    fallback = handoff.get("model_fallback")
    if fallback is None:
        return []

    # Schema validation already records the type error; do not double-report.
    if not isinstance(fallback, dict):
        return []

    comparison = fallback.get("capability_tier_comparison")
    if comparison == "lower":
        requested = fallback.get("requested_model_class", "<unknown>")
        actual = fallback.get("actual_model_class", "<unknown>")
        return [
            f"model_fallback capability_tier_comparison is 'lower' "
            f"(requested={requested!r}, actual={actual!r}): "
            "lower-tier fallback requires pause/escalation, not same-or-higher — "
            "work must not proceed automatically"
        ]
    return []


def validate_file(handoff_path: Path, schema: dict) -> list[str]:
    """Validate a single handoff file against the schema.

    Returns a list of error messages; empty list means valid.
    """
    errors: list[str] = []
    try:
        with handoff_path.open(encoding="utf-8") as fh:
            handoff = json.load(fh)
    except FileNotFoundError:
        errors.append(f"file not found: {handoff_path}")
        return errors
    except json.JSONDecodeError as exc:
        errors.append(f"JSON parse error: {exc}")
        return errors

    try:
        jsonschema.validate(handoff, schema)
    except jsonschema.ValidationError as exc:
        errors.append(exc.message)

    errors.extend(check_model_fallback_tier(handoff))

    return errors


def check_unique_task_ids(
    files: list[Path], schema: dict
) -> dict[str, list[str]]:
    """Check that task_id values are unique across all provided files.

    Returns a mapping of file path -> list of error messages for duplicates.
    Only files that parse and validate successfully contribute their task_id.
    Files with duplicate task_ids receive an error entry.
    """
    seen: dict[str, Path] = {}
    dup_errors: dict[str, list[str]] = {}

    for path in files:
        try:
            with path.open(encoding="utf-8") as fh:
                handoff = json.load(fh)
        except (FileNotFoundError, json.JSONDecodeError):
            continue

        task_id = handoff.get("task_id")
        if task_id is None:
            continue

        if task_id in seen:
            msg = (
                f"duplicate task_id '{task_id}' also found in {seen[task_id]}"
            )
            dup_errors.setdefault(str(path), []).append(msg)
            # Also flag the first occurrence if not already flagged
            first = str(seen[task_id])
            if first not in dup_errors:
                dup_errors[first] = []
            dup_errors[first].append(
                f"duplicate task_id '{task_id}' also found in {path}"
            )
        else:
            seen[task_id] = path

    return dup_errors


def main() -> int:
    if len(sys.argv) < 2:
        print(
            "usage: validate-handoff.py <handoff.json> [<handoff.json> ...]",
            file=sys.stderr,
        )
        return 2

    repo_root = Path(__file__).resolve().parents[1]
    schema_path = repo_root / "schemas" / "handoff.schema.json"

    try:
        with schema_path.open(encoding="utf-8") as schema_file:
            schema = json.load(schema_file)
    except FileNotFoundError:
        print(f"schema not found: {schema_path}", file=sys.stderr)
        return 2

    paths = [Path(arg) for arg in sys.argv[1:]]

    # Per-file schema validation
    per_file_errors: dict[str, list[str]] = {}
    for path in paths:
        errs = validate_file(path, schema)
        per_file_errors[str(path)] = errs

    # Repository-level: unique task_id within docs/handoffs/
    # Only enforce across files that are all under docs/handoffs/.
    docs_handoffs = repo_root / "docs" / "handoffs"
    handoffs_dir_files = [
        p for p in paths if p.resolve().parent == docs_handoffs.resolve()
    ]
    dup_errors: dict[str, list[str]] = {}
    if len(handoffs_dir_files) > 1:
        dup_errors = check_unique_task_ids(handoffs_dir_files, schema)

    # Merge duplicate errors into per-file errors
    for path_str, errs in dup_errors.items():
        per_file_errors.setdefault(path_str, []).extend(errs)

    # Report and determine exit code
    any_fail = False
    for path in paths:
        path_str = str(path)
        errs = per_file_errors.get(path_str, [])
        if errs:
            any_fail = True
            for msg in errs:
                print(f"FAIL  {path_str}: {msg}", file=sys.stderr)
        else:
            print(f"PASS  {path_str}")

    return 1 if any_fail else 0


if __name__ == "__main__":
    raise SystemExit(main())
