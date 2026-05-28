#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# tests/upgrade/fixtures/success-migration.sh — benign success fixture migration.
#
# Used by the migration-runner hardening test (T002/T004) to verify the
# no-false-failure case: a migration that completes its work must be recorded
# as applied with no spurious failure report (FR-008 in
# specs/013-migration-runner-hardening/spec.md).
#
# Contract (illustrates FR-001 "exit 0 explicitly" requirement):
#   - Performs benign, idempotent work (touch a sentinel file in PROJECT_ROOT).
#   - Uses a conditional last action guarded with || true so a benign non-zero
#     from the conditional does not escape as the script's exit status.
#   - Terminates with an explicit `exit 0` — the contract FR-001 requires.
#   - Shaped like a real migration: same shebang, same set -euo pipefail,
#     same PROJECT_ROOT guard, same stdout/stderr convention.
#   - NOT placed in migrations/ — will never be discovered by the real runner.
#
# Idempotency (per FW-ADR-0017 §5):
#   Re-running on already-migrated state is a no-op.  The sentinel file
#   is the positive-signal guard.
#
# Env (same as real migrations, per migrations/TEMPLATE.sh):
#   PROJECT_ROOT   — absolute path to the downstream project root (required)
#   OLD_VERSION    — version the project is coming from (optional in fixture)
#   NEW_VERSION    — version the project is going to (optional in fixture)

set -euo pipefail

: "${PROJECT_ROOT:?PROJECT_ROOT is required}"

sentinel="$PROJECT_ROOT/.fixture-success-migration-applied"

# Idempotency guard: if the sentinel already exists this is a no-op re-run.
if [[ -f "$sentinel" ]]; then
    echo "  success-migration.sh: no-op (already applied)" >&2
    exit 0
fi

# Benign work: write the sentinel file.
echo "  fixture: success-migration.sh — writing sentinel file"
printf '%s\n' "applied by tests/upgrade/fixtures/success-migration.sh" > "$sentinel" || true

echo "  fixture: success-migration.sh — completed successfully"

# FR-001: exit 0 explicitly on success.
exit 0
