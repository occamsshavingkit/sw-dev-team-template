#!/usr/bin/env bash
#
# tests/upgrade/fixtures/fail-migration.sh — deliberately-failing fixture migration.
#
# Used by the migration-runner hardening test (T002/T004) to exercise the
# runner's failure-detection and failure-report paths (FR-001, FR-002–FR-006,
# FR-012 in specs/013-migration-runner-hardening/spec.md).
#
# Contract:
#   - Always exits non-zero (exit 1) — deterministic failure, not flaky.
#   - Shaped like a real migration: same shebang, same set -euo pipefail,
#     same PROJECT_ROOT guard, same stdout/stderr convention.
#   - Does NOT modify PROJECT_ROOT or any other state — safe to run anywhere.
#   - NOT placed in migrations/ — will never be discovered by the real runner.
#
# Env (same as real migrations, per migrations/TEMPLATE.sh):
#   PROJECT_ROOT   — absolute path to the downstream project root (required)
#   OLD_VERSION    — version the project is coming from (optional in fixture)
#   NEW_VERSION    — version the project is going to (optional in fixture)

set -euo pipefail

: "${PROJECT_ROOT:?PROJECT_ROOT is required}"

echo "  fixture: fail-migration.sh — simulating a migration error"
echo "  fixture: PROJECT_ROOT=$PROJECT_ROOT" >&2
echo "ERROR: fail-migration.sh: intentional failure (fixture for runner hardening test)" >&2
exit 1
