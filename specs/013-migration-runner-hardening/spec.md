# Feature Specification: Migration Runner Hardening

**Feature Branch**: `013-migration-runner-hardening`  
**Created**: 2026-05-27  
**Status**: Draft  
**Input**: User description: "Harden the migrations runner in sw-dev-team-template/scripts/upgrade.sh so a migration that exits non-zero is caught and reported with actionable chain context, per FW-ADR-0017 §4, instead of aborting upgrade.sh silently under `set -euo pipefail`."

## Clarifications

### Session 2026-05-27

- Q: Success/failure detection contract — exit code, explicit sentinel, or hybrid? → A: Non-zero exit = failure, zero = success; each migration must exit 0 explicitly on success; the runner captures each migration's true exit status reliably (no pipeline / `set -e` masking).
- Q: Failure recovery model — forward-only, rollback, or snapshot/restore? → A: Forward-only — already-applied migrations stay applied; the runner reports the stopping point; the operator fixes the failing migration and re-runs (resume forward). No rollback / no down-migrations.
- Q: Failure report — human-readable only, machine-readable only, or both? → A: Both — a human-readable stderr summary AND a structured failure artifact mirroring the existing `.template-*-blocked.json` convention.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Actionable failure report when a migration fails (Priority: P1)

An operator runs the template upgrade. One migration in the chain exits non-zero. Instead of the upgrade dying with only the migration's own stderr (or nothing), the operator receives a clear summary that names the failing migration, where it sits in the chain, what already ran, and what did not — enough to diagnose and recover without reading the runner's source.

**Why this priority**: This is the core value. Today a migration failure aborts the upgrade with no chain context, leaving the operator and downstream automation unable to tell which migration failed or what state the project is in. It is the reason the feature exists.

**Independent Test**: Run the upgrade against a project whose chain includes a deliberately-failing fixture migration; confirm the upgrade stops with a non-zero exit and emits a summary naming the failing migration, its chain position, the already-applied migrations, and the not-yet-run migrations.

**Acceptance Scenarios**:

1. **Given** a migration chain where the migration at position N exits non-zero, **When** the runner executes it, **Then** the upgrade fails with a non-zero exit and a stderr summary that names the failing migration file, states its position as "N of M", lists the migrations that already ran successfully, and lists the migrations that were not run.
2. **Given** a migration that completes successfully, **When** the runner executes it, **Then** the migration is recorded as applied and the chain advances to the next migration with no spurious failure report.
3. **Given** a failed migration, **When** the runner stops the upgrade, **Then** no stale temporary files remain and the project is not left in a silently corrupted partial state.

---

### User Story 2 - Failure detection independent of a migration's last-statement exit code (Priority: P2)

The runner must decide success or failure based on the migration's actual outcome, not be fooled by a migration whose final statement happens to return non-zero on a benign path, nor mask a genuine error whose final statement happens to return zero.

**Why this priority**: The triggering incident was a benign no-op path returning exit 1 as the script's last statement. While individual migrations are being written defensively, the runner must not be brittle to this class of footgun, and must still surface genuine failures. Secondary to US1 because US1 delivers the operator-facing value; this story makes the detection trustworthy.

**Independent Test**: Run the runner against (a) a fixture migration that does benign work but whose last statement returns non-zero, and (b) a fixture migration that fails partway but whose last statement returns zero; confirm the runner classifies each correctly per the agreed contract and reports accordingly.

**Acceptance Scenarios**:

1. **Given** a migration that performs its work successfully, **When** its execution is evaluated, **Then** it is treated as applied (the result reflects the migration's real outcome, per the runner's defined success contract).
2. **Given** a migration that genuinely errors, **When** its execution is evaluated, **Then** it is treated as failed and triggers the US1 failure summary.

---

### Edge Cases

- A migration that emits no output but exits non-zero — still reported as failed with full chain context.
- The first migration in the chain fails — summary shows "1 of M", empty already-applied list, remaining list correct.
- The last migration in the chain fails — summary shows "M of M", remaining list empty.
- An empty migration chain (nothing to run) — runner is a clean no-op, no summary, exit zero.
- A migration that writes temporary artifacts and then fails — no stale temporary files survive the aborted run.
- A migration emitting a large volume of stderr — the runner's summary is still clearly distinguishable from the migration's own output.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The migration runner MUST treat a non-zero exit status from a migration as failure and a zero exit status as success; each migration is required to exit 0 explicitly on success. The runner MUST capture each migration's true exit status reliably, with no pipeline or `set -e` masking/misattribution of that status.
- **FR-002**: On a migration failure, the runner MUST emit a human-readable summary to standard error that names the failing migration file.
- **FR-003**: The failure summary MUST state the failing migration's position within the ordered chain (for example, "3 of 7").
- **FR-004**: The failure summary MUST list the migrations that already ran successfully before the failure.
- **FR-005**: The failure summary MUST list the migrations that were not run because of the failure.
- **FR-006**: On a migration failure, the upgrade MUST stop with a non-zero exit code (a controlled, reported failure — not a silent abort).
- **FR-007**: On a migration failure, the runner MUST NOT leave stale temporary files and MUST NOT leave the project in a silently corrupted partial state; the stopping point MUST be observable.
- **FR-008**: A migration that completes successfully MUST be recorded as applied and MUST NOT produce a spurious failure report.
- **FR-009**: The runner MUST preserve the existing ordered migration-chain behavior so that the published rc-to-rc and stable upgrade walks continue to succeed (no regression to the chain currently exercised by the stepwise upgrade smoke).
- **FR-010**: The hardened behavior MUST be covered by automated tests, including at least one fixture migration that fails, asserting both the failure report content and the non-zero exit, plus a success/no-op case asserting no false failure.
- **FR-011**: Failure recovery MUST be forward-only: migrations applied before the failure remain applied (no rollback / no down-migrations), and the operator's recovery path is to fix the failing migration and re-run the upgrade, which resumes from the reported stopping point. The runner MUST NOT attempt to revert previously-applied migrations.
- **FR-012**: On a migration failure, in addition to the stderr summary (FR-002), the runner MUST write a structured, machine-readable failure artifact that records the failing migration filename, its chain position, the already-applied migrations, and the not-run migrations — using a naming/shape consistent with the existing `.template-*-blocked.json` block-artifact convention so automation/CI can detect and parse the failure deterministically.

### Constitution Alignment *(mandatory)*

- **CA-001**: Source authority — `scripts/upgrade.sh` and `migrations/` are canonical framework-managed artifacts; this spec and its plan/tasks are generated planning artifacts; test fixtures added for the failing-migration case are test assets. Documentation/ADR updates (FW-ADR-0017) are canonical.
- **CA-002**: Customer-owned requirements — the customer directed this hardening; behavior is derived from FW-ADR-0017 §4 and the dogfooding incident. No customer-owned requirement is unresolved; no queued atomic question blocks specification.
- **CA-003**: Framework-managed edits — this is explicitly template-maintenance work in `sw-dev-team-template` (`scripts/upgrade.sh` migration runner, tests, and FW-ADR-0017 / upgrade docs). Authorization: customer-directed framework-maintenance.
- **CA-004**: No cross-AI/role-authority changes; the runner remains a deterministic shell mechanism with no new authority surface.

### Key Entities

- **Migration chain**: the ordered set of migration scripts selected for a given upgrade hop, each identified by filename and position.
- **Migration outcome**: the success/failure classification the runner assigns to each migration, based on the migration's exit status (FR-001).
- **Failure report**: emitted on the first failing migration in two forms — a human-readable stderr summary (FR-002–FR-005) and a structured machine-readable artifact (FR-012) carrying the failing filename, chain position, already-applied list, and not-run list.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: For 100% of migration-failure cases, the upgrade stops with a non-zero exit and produces both a human-readable stderr summary and a structured failure artifact naming the failing migration, its chain position, the already-applied migrations, and the not-run migrations.
- **SC-002**: An operator can identify which migration failed and the upgrade's stopping point from the runner's output alone, without reading the runner's source code.
- **SC-003**: Zero false failures: across the full published upgrade walk currently exercised by the stepwise smoke, no successful migration is reported as failed and the walk's pass/known-cliff outcomes are unchanged.
- **SC-004**: The hardened behavior is verified by an automated test that injects a failing migration and asserts the stderr summary content, the structured failure artifact, and the non-zero exit, and this test runs as part of the framework's test surface.

## Assumptions

- The scope is the existing migration runner inside `sw-dev-team-template/scripts/upgrade.sh` and its supporting tests/docs; redesigning the migration format or the chain-selection logic is out of scope.
- The migration chain remains an ordered sequence of shell scripts invoked by the runner; this feature changes how the runner invokes/evaluates them and reports failures, not the migrations' own contract beyond defining the success/failure signal.
- "Deterministic detection" (FR-001) will be realized through the runner's invocation/evaluation contract; the exact mechanism is an implementation/plan decision and is intentionally not fixed here.
- Existing migrations already conform (or will be made to conform) to the runner's success/failure contract; the separately-fixed `migrations/v0.1.0.sh` no-op exit-code bug is not part of this feature.
- FW-ADR-0017 §4 is the governing reference for the required failure-report content and is authoritative if its wording is more specific than this spec.
