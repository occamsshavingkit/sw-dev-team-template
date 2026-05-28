# Tasks: Migration Runner Hardening

**Input**: Design documents from `specs/013-migration-runner-hardening/`
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`

**Verification**: Each task has exactly one `Primary verification:` command or review check.
**Organization**: Tasks are grouped by user story to enable independent implementation and testing. All paths are under `sw-dev-team-template/`.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Establish the test fixtures and harness the runner behavior will be verified against.

- [X] T001 [P] Add a deliberately-failing fixture migration and a benign success fixture migration under `sw-dev-team-template/tests/upgrade/fixtures/`. Primary verification: `ls sw-dev-team-template/tests/upgrade/fixtures/*.sh | wc -l | grep -q 2`
- [X] T002 Create executable test harness `sw-dev-team-template/tests/upgrade/test-migration-runner.sh` (record_pass/record_fail style per existing test scripts; exits 0 with a sanity assertion). Primary verification: `test -x sw-dev-team-template/tests/upgrade/test-migration-runner.sh && sw-dev-team-template/tests/upgrade/test-migration-runner.sh`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: The shared mechanism — capture each migration's true exit status — that both user stories build on.

- [X] T003 Refactor the migration-running block in `sw-dev-team-template/scripts/upgrade.sh` to capture each migration's true exit status decoupled from any trailing pipeline stage and from `set -e` masking (FR-001). Primary verification: `cd sw-dev-team-template && tests/upgrade/test-migration-runner.sh`

**Checkpoint**: Failure of a migration is now deterministically detectable; user story implementation can begin.

---

## Phase 3: User Story 1 - Actionable failure report (Priority: P1)

**Goal**: A migration failure stops the upgrade with a non-zero exit and an actionable report (stderr summary + structured artifact) naming the failing migration, its chain position, the applied migrations, and the not-run migrations; recovery is forward-only.

**Independent Test**: Run the runner against a chain containing the failing fixture migration; confirm controlled non-zero exit, a correct stderr summary, and a `.template-migration-failed.json` matching the contract.

### Implementation for User Story 1

- [X] T004 [US1] Author the US1 failure-path test cases (test-first / red) in `sw-dev-team-template/tests/upgrade/test-migration-runner.sh`: drive the failing fixture migration and assert (a) controlled non-zero exit, (b) stderr summary fields per `contracts/migration-failure-report.md` §A, (c) `.template-migration-failed.json` contents/invariants per §B, (d) no stale `.tmp.*`. Include the boundary edge cases from spec.md "Edge Cases": failure at the FIRST position ("1 of M", empty `applied` list) and at the LAST position (empty `not_run` list), confirming the artifact invariants hold at both. Cases are expected to FAIL until T005–T008 land (FR-010, SC-004). Primary verification: the US1 cases are present in the harness — `grep -q 'US1:' sw-dev-team-template/tests/upgrade/test-migration-runner.sh`
- [X] T005 [US1] Implement stop-at-first-failure and a controlled non-zero exit (no silent `set -e` abort) in the `sw-dev-team-template/scripts/upgrade.sh` migration runner (FR-006). Primary verification: the US1 controlled-non-zero-exit case now passes — `cd sw-dev-team-template && tests/upgrade/test-migration-runner.sh 2>&1 | grep -q 'PASS.*US1: non-zero exit'`
- [X] T006 [US1] Emit the human-readable stderr summary (failing filename, position "N of M", applied list, not-run list) per `contracts/migration-failure-report.md` §A (FR-002–FR-005). Primary verification: the US1 stderr-summary case now passes — `cd sw-dev-team-template && tests/upgrade/test-migration-runner.sh 2>&1 | grep -q 'PASS.*US1: stderr summary'`
- [X] T007 [US1] Write the structured `.template-migration-failed.json` artifact at project root (atomic write, schema-parallel to `.template-*-blocked.json`, satisfying the contract invariants) per `contracts/migration-failure-report.md` §B (FR-012). Primary verification: the US1 artifact case now passes — `cd sw-dev-team-template && tests/upgrade/test-migration-runner.sh 2>&1 | grep -q 'PASS.*US1: artifact'`
- [X] T008 [US1] Guarantee no stale `.tmp.*` files and forward-only semantics (applied migrations remain applied; observable stopping point; no rollback) on the failure path (FR-007, FR-011), then confirm the full US1 suite is green. Primary verification: `cd sw-dev-team-template && tests/upgrade/test-migration-runner.sh`

**Checkpoint**: User Story 1 is independently testable.

---

## Phase 4: User Story 2 - Deterministic detection independent of last-statement (Priority: P2)

**Goal**: Success/failure classification reflects the migration's real exit status, not the incidental result of its final statement; successful migrations never produce a false failure.

**Independent Test**: A benign migration that exits 0 (even with a conditional last action) is applied with no artifact; a genuinely erroring migration is reported.

### Implementation for User Story 2

- [X] T009 [US2] Add a success/no-op case to `sw-dev-team-template/tests/upgrade/test-migration-runner.sh` asserting a zero-exit migration is recorded applied, the chain completes, exit 0, and NO `.template-migration-failed.json` is written; also assert the empty-chain edge case (no migrations to run → clean no-op, exit 0, no artifact) (FR-008). Primary verification: `cd sw-dev-team-template && tests/upgrade/test-migration-runner.sh`
- [X] T010 [US2] Add detection-contract cases to `sw-dev-team-template/tests/upgrade/test-migration-runner.sh`: a migration doing benign work that exits 0 explicitly is applied; a migration that genuinely errors (non-zero) is failed and triggers the report (FR-001). Primary verification: `cd sw-dev-team-template && tests/upgrade/test-migration-runner.sh`

**Checkpoint**: User Story 2 is independently testable.

---

## Final Phase: Polish & Cross-Cutting Concerns

**Purpose**: Non-regression, ADR alignment, and review before commit.

- [X] T011 Confirm no regression to the real chain by running the stepwise upgrade smoke (expect 10 pass + 1 known-cliff for rc7→rc8; rc14→v1.0.0 VERSION item tracked separately) (FR-009, SC-003). Primary verification: `cd sw-dev-team-template && scripts/stepwise-smoke.sh --track rc`
- [X] T012 Align FW-ADR-0017 §4 wording with the implemented failure report (stderr summary + structured artifact) in `sw-dev-team-template/docs/adr/fw-adr-0017-file-keyed-migration-discovery.md`. Primary verification: `grep -qi 'migration-failed' sw-dev-team-template/docs/adr/fw-adr-0017-file-keyed-migration-discovery.md`
- [X] T013 Obtain `code-reviewer` review of the changed runner, test, and docs paths before commit. Primary verification: code-reviewer SHIP verdict recorded for the 013 change set.

---

## Dependencies & Execution Order

### Requirement Coverage

- **FR-001**: T003 (exit-status capture), T004 (test), T010 (detection-contract tests).
- **FR-002, FR-003, FR-004, FR-005**: T006 (stderr summary impl), T004 (test).
- **FR-006**: T005 (stop + controlled non-zero exit), T004 (test).
- **FR-007, FR-011**: T008 (no stale tmp + forward-only), T004 (test).
- **FR-008**: T009.
- **FR-009**: T011.
- **FR-010**: T004, T009, T010.
- **FR-012**: T007 (artifact impl), T004 (test).
- **SC-001**: T005, T006, T007, T008.
- **SC-002** (operator identifies the failed migration from output alone): T006 (stderr summary), T007 (artifact).
- **SC-003**: T011.
- **SC-004**: T004 (test authored), T008 (full US1 suite green).

Process/infrastructure tasks intentionally not mapped to a single FR/SC: T002 (test harness — enables FR-010 coverage), T012 (FW-ADR-0017 §4 governance alignment), T013 (Principle V pre-commit review gate).

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies.
- **Foundational (Phase 2)**: Depends on Setup; blocks both user stories (T003 is the detection mechanism).
- **US1 (Phase 3)**: Depends on Foundational; MVP.
- **US2 (Phase 4)**: Depends on Foundational; test-only, can run after or alongside US1 (shares the test file — sequence edits to avoid collisions).
- **Polish (Final)**: Depends on US1 (and US2) being complete.

### Parallel Opportunities

- T001 (fixtures) is independent of T002 (harness) and can run in parallel.
- T004 authors the US1 tests first (red); US1 implementation tasks T005–T008 touch the same `upgrade.sh` block and must run sequentially, each turning its specific T004 case green.
- US2 test cases (T009, T010) edit the same test file as T004 and each other — sequence them.

---

## Implementation Strategy

### MVP First

1. Complete Phase 1 + Phase 2 (fixtures, harness, exit-status capture).
2. Complete US1 (report + artifact + forward-only).
3. Stop and validate: `cd sw-dev-team-template && tests/upgrade/test-migration-runner.sh`.

### Incremental Delivery

1. US1 establishes the operator-facing failure report (the core value).
2. US2 hardens detection trustworthiness (success/no-op and exit-contract cases).
3. Polish proves no regression (stepwise smoke), aligns the ADR, and gates on review.

### Task Ownership

- `software-engineer`: runner exit-status refactor and failure-report/artifact implementation (T003, T005–T008).
- `qa-engineer`: fixtures, harness, and test cases (T001, T002, T004, T009, T010).
- `release-engineer`: stepwise-smoke non-regression (T011).
- `architect`: FW-ADR-0017 §4 alignment (T012).
- `code-reviewer`: review before commit (T013).
