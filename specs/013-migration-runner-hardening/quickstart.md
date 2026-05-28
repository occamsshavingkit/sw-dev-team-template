# Quickstart: Migration Runner Hardening

Validates the hardened runner end-to-end. Run from the template repo root
(`sw-dev-team-template`). The automated form lives in
`tests/upgrade/test-migration-runner.sh`.

## 1. Failure is caught and reported (US1, FR-001..FR-007, FR-012)

1. Arrange a migration chain that includes a deliberately-failing fixture
   migration at a known position (e.g. position 3 of 7).
2. Run the upgrade so the migration runner executes the chain.
3. Expect:
   - the upgrade stops at the failing migration (later migrations not run);
   - a non-zero exit status (controlled, not a silent abort);
   - an stderr summary naming the failing migration, "3 of 7", the applied
     migrations, and the not-run migrations;
   - a `.template-migration-failed.json` artifact at the project root whose
     `failing_migration`, `position`, `applied`, and `not_run` match the
     stderr summary and satisfy the contract invariants;
   - no stale `.tmp.*` files.

## 2. Success path produces no false failure (US2, FR-008)

1. Run the same chain with all migrations succeeding (each exits 0).
2. Expect: every migration recorded applied, the chain completes, exit 0,
   and NO `.template-migration-failed.json` artifact is written.

## 3. Detection is exit-status based, not last-statement-incidental (FR-001)

1. Include a migration that does benign work and exits 0 explicitly (even if
   its logical last action is a conditional) → treated as applied.
2. Include a migration that genuinely errors and exits non-zero → treated as
   failed and triggers the report.

## 4. Forward-only resume (FR-011)

1. After the failure in step 1, fix the failing fixture migration so it exits 0.
2. Re-run the upgrade.
3. Expect: previously-applied migrations are not re-reverted; the chain resumes
   forward from the stopping point and completes; the failure artifact is gone.

## 5. No regression to the real chain (FR-009, SC-003)

Run `scripts/stepwise-smoke.sh --track rc` and confirm the published walk still
passes (10 pass + 1 known-cliff for rc7→rc8), with the rc14→v1.0.0 VERSION-stamp
item tracked separately. The hardening must not change those outcomes.
