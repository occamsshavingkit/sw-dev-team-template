#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# tests/upgrade/fixtures/nonzero-last-statement-migration.sh — TEST FIXTURE ONLY.
#
# Used by T010 (US2 detection-contract tests) to prove FR-001 from the
# non-zero direction: a migration that does benign work but whose FINAL
# STATEMENT returns non-zero (no trailing `|| true`, no explicit `exit 0`)
# exits non-zero, and the runner classifies it as FAILED.
#
# Contract:
#   - Performs benign, non-destructive work (writes a sentinel file).
#   - The final statement is a bare falsy conditional — `[[ -f /nonexistent ]]`
#     — that always returns non-zero.  There is NO `|| true` guard and NO
#     explicit `exit 0` after it.  `set -euo pipefail` is active, so the
#     non-zero return from that final conditional causes `set -e` to fire and
#     terminate the script with a non-zero exit status.
#   - Always exits non-zero — deterministic, not flaky.
#   - Shaped like a real migration: same shebang, same set -euo pipefail,
#     same PROJECT_ROOT guard.
#   - NOT placed in migrations/ — will never be discovered by the real runner.
#   - NOT named to match the real runner's discovery glob pattern.
#
# Purpose: proves the runner keys on TRUE exit status, not on whether the
# migration's work was benign.  Contrast with success-migration.sh, which
# guards its last conditional with `|| true` and then calls `exit 0` — the
# pattern that correctly yields exit 0.
#
# Env (same as real migrations, per migrations/TEMPLATE.sh):
#   PROJECT_ROOT   — absolute path to the downstream project root (required)
#   OLD_VERSION    — version the project is coming from (optional in fixture)
#   NEW_VERSION    — version the project is going to (optional in fixture)

set -euo pipefail

: "${PROJECT_ROOT:?PROJECT_ROOT is required}"

sentinel="$PROJECT_ROOT/.fixture-nonzero-last-statement-migration-ran"

# Benign work: write a sentinel so the test can confirm the migration did run.
echo "  fixture: nonzero-last-statement-migration.sh — doing benign work"
printf '%s\n' "ran by tests/upgrade/fixtures/nonzero-last-statement-migration.sh" \
    > "$sentinel" || true

echo "  fixture: nonzero-last-statement-migration.sh — about to execute bare falsy conditional (no exit 0)"

# Final statement: a bare falsy conditional with NO `|| true` and NO `exit 0`.
# This always returns non-zero, making the script exit non-zero despite the
# preceding work having succeeded.  This is the footgun FR-001 guards against:
# the runner must surface this non-zero, not ignore it.
[[ -f /nonexistent ]]
