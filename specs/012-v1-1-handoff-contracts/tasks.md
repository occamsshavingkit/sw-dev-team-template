# Tasks: v1.1 Handoff Contracts

**Input**: Design documents from `specs/012-v1-1-handoff-contracts/`
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`

**Verification**: Each task has exactly one `Primary verification:` command or review check.
**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Establish directories, fixture surfaces, and shared validation entry points.

- [X] T001 Create durable handoff and active-pointer directories in `sw-dev-team-template/docs/handoffs/` and `sw-dev-team-template/.devteam/`. Primary verification: `test -d sw-dev-team-template/docs/handoffs && test -d sw-dev-team-template/.devteam`
- [X] T002 [P] Add minimal valid and invalid handoff fixtures under `sw-dev-team-template/tests/fixtures/handoffs/`. Primary verification: `test -f sw-dev-team-template/tests/fixtures/handoffs/valid-minimal.json && test -f sw-dev-team-template/tests/fixtures/handoffs/invalid-missing-owner.json`
- [X] T003 [P] Add active-pointer fixtures under `sw-dev-team-template/tests/fixtures/active-handoff/`. Primary verification: `test -f sw-dev-team-template/tests/fixtures/active-handoff/valid-pointer.json && test -f sw-dev-team-template/tests/fixtures/active-handoff/missing-target.json`
- [X] T004 Update `sw-dev-team-template/.claude/settings.json` with warning-mode handoff hook wiring. Primary verification: `cd sw-dev-team-template && tests/hooks/test-settings-merge.sh`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core schema, validation, and shared hook libraries required by all stories.

- [X] T005 Define required durable handoff, evidence, path-scope, bounded-Codex, hard-rule trace, and model-fallback fields in `sw-dev-team-template/schemas/handoff.schema.json`. Primary verification: `cd sw-dev-team-template && tests/hooks/test-handoff-contracts.sh`
- [X] T006 Implement active handoff loading and schema validation in `sw-dev-team-template/scripts/hooks/lib/handoff.py`. Primary verification: `cd sw-dev-team-template && tests/hooks/test-handoff-contracts.sh`
- [X] T007 Implement forbidden-over-allowed path matching and framework-scope checks in `sw-dev-team-template/scripts/hooks/lib/path_scope.py`. Primary verification: `cd sw-dev-team-template && tests/hooks/test-handoff-contracts.sh`
- [X] T008 Implement Bash/Python write-target extraction in `sw-dev-team-template/scripts/hooks/lib/write_targets.py`. Primary verification: `cd sw-dev-team-template && tests/hooks/test-handoff-pre-tool-gate.sh`
- [X] T009 Implement repository-level handoff validation in `sw-dev-team-template/scripts/validate-handoff.py`. Primary verification: `cd sw-dev-team-template && tests/hooks/test-handoff-contracts.sh`
- [X] T010 Document hard-rule trace classifications in `sw-dev-team-template/docs/v1.1-handoff-contracts.md`. Primary verification: `grep -q 'HR-' sw-dev-team-template/docs/v1.1-handoff-contracts.md`
- [X] T011 Create executable smoke test files for bounded-Codex and framework-boundary gates in `sw-dev-team-template/tests/hooks/test-codex-handoff-gate.sh` and `sw-dev-team-template/tests/hooks/test-framework-path-boundary.sh`. Primary verification: `test -x sw-dev-team-template/tests/hooks/test-codex-handoff-gate.sh && test -x sw-dev-team-template/tests/hooks/test-framework-path-boundary.sh`

**Checkpoint**: Foundation ready; user story implementation can begin.

---

## Phase 3: User Story 1 - Enforce Handoff and Path Scope (Priority: P1)

**Goal**: A framework-maintenance task has one durable handoff, one active pointer, and deterministic path-scope enforcement.

**Independent Test**: A valid active handoff authorizes allowed framework-maintenance paths and blocks forbidden paths.

### Implementation for User Story 1

- [X] T012 [US1] Implement active-pointer resolution in `sw-dev-team-template/scripts/hooks/lib/handoff.py`. Primary verification: `cd sw-dev-team-template && tests/hooks/test-handoff-contracts.sh`
- [X] T013 [US1] Implement `sw-dev-team-template/scripts/hooks/handoff-pre-tool-gate.py` for write-capable `PreToolUse` events. Primary verification: `cd sw-dev-team-template && tests/hooks/test-handoff-pre-tool-gate.sh`
- [X] T014 [US1] Add forbidden-path precedence cases to `sw-dev-team-template/tests/hooks/test-handoff-pre-tool-gate.sh`. Primary verification: `cd sw-dev-team-template && tests/hooks/test-handoff-pre-tool-gate.sh`
- [X] T015 [US1] Add framework-managed path authorization cases to `sw-dev-team-template/tests/hooks/test-framework-path-boundary.sh`. Primary verification: `cd sw-dev-team-template && tests/hooks/test-framework-path-boundary.sh`
- [X] T016 [US1] Add active handoff examples to `sw-dev-team-template/docs/handoffs/` and `sw-dev-team-template/.devteam/active-handoff.json`. Primary verification: `cd sw-dev-team-template && scripts/validate-handoff.py docs/handoffs/*.json`

**Checkpoint**: User Story 1 is independently testable.

---

## Phase 4: User Story 2 - Require Evidence-Gated Completion (Priority: P2)

**Goal**: Completion is accepted only when independent evidence gates are satisfied.

**Independent Test**: Completion with accepted evidence passes and completion with self-attestation or missing evidence is blocked or warned according to gate mode.

### Implementation for User Story 2

- [X] T017 [US2] Model accepted evidence and worker-report distinctions in `sw-dev-team-template/schemas/handoff.schema.json`. Primary verification: `cd sw-dev-team-template && tests/hooks/test-handoff-contracts.sh`
- [X] T018 [US2] Implement evidence lookup helpers in `sw-dev-team-template/scripts/hooks/lib/handoff.py`. Primary verification: `cd sw-dev-team-template && tests/hooks/test-handoff-task-completed-gate.sh`
- [X] T019 [US2] Implement `sw-dev-team-template/scripts/hooks/handoff-record-activity.py` for hook-captured activity evidence. Primary verification: `test -f sw-dev-team-template/scripts/hooks/handoff-record-activity.py && grep -q 'handoff-record-activity' sw-dev-team-template/docs/v1.1-handoff-contracts.md`
- [X] T020 [US2] Implement `sw-dev-team-template/scripts/hooks/handoff-task-completed-gate.py` for required evidence gates. Primary verification: `cd sw-dev-team-template && tests/hooks/test-handoff-task-completed-gate.sh`
- [X] T021 [US2] Add self-attestation rejection coverage to `sw-dev-team-template/tests/hooks/test-handoff-task-completed-gate.sh`. Primary verification: `cd sw-dev-team-template && tests/hooks/test-handoff-task-completed-gate.sh`
- [X] T022 [US2] Add researcher-stewarded customer-truth evidence cases to `sw-dev-team-template/tests/hooks/test-handoff-task-completed-gate.sh`. Primary verification: `cd sw-dev-team-template && tests/hooks/test-handoff-task-completed-gate.sh`

**Checkpoint**: User Story 2 is independently testable.

---

## Phase 5: User Story 3 - Bound Codex and Model Fallbacks (Priority: P3)

**Goal**: Bounded Codex and model fallback are allowed only when explicitly scoped and recorded without lowering capability tier.

**Independent Test**: Bounded Codex without permission is blocked, scoped bounded Codex is allowed, and lower-tier model fallback requires pause/escalation.

### Implementation for User Story 3

- [X] T023 [US3] Add bounded-Codex permission fields to `sw-dev-team-template/schemas/handoff.schema.json`. Primary verification: `cd sw-dev-team-template && tests/hooks/test-handoff-contracts.sh`
- [X] T024 [US3] Implement bounded-Codex event checks in `sw-dev-team-template/scripts/hooks/handoff-pre-tool-gate.py`. Primary verification: `cd sw-dev-team-template && tests/hooks/test-codex-handoff-gate.sh`
- [X] T025 [US3] Add bounded-Codex fixtures and cases to `sw-dev-team-template/tests/hooks/test-codex-handoff-gate.sh`. Primary verification: `cd sw-dev-team-template && tests/hooks/test-codex-handoff-gate.sh`
- [X] T026 [US3] Add model fallback record validation to `sw-dev-team-template/schemas/handoff.schema.json`. Primary verification: `cd sw-dev-team-template && tests/hooks/test-handoff-contracts.sh`
- [X] T027 [US3] Add same-or-higher capability-tier fallback validation to `sw-dev-team-template/scripts/validate-handoff.py`. Primary verification: `cd sw-dev-team-template && tests/hooks/test-handoff-contracts.sh`
- [X] T028 [US3] Document provider/model fallback behavior in `sw-dev-team-template/docs/v1.1-handoff-contracts.md`. Primary verification: `grep -q 'same-or-higher capability tier' sw-dev-team-template/docs/v1.1-handoff-contracts.md`

**Checkpoint**: User Story 3 is independently testable.

---

## Phase 6: User Story 4 - Integrate llmdc and Speckit Without Bypasses (Priority: P4)

**Goal**: llmdc and Speckit outputs feed canonical roles and handoffs without approving gates or customer truth.

**Independent Test**: Integration guidance maps llmdc and Speckit outputs to handoff fields and states their evidence limitations.

### Implementation for User Story 4

- [X] T029 [US4] Document llmdc role, owner, allowed surfaces, and evidence limits in `sw-dev-team-template/docs/v1.1-handoff-contracts.md`. Primary verification: `grep -q 'llmdc' sw-dev-team-template/docs/v1.1-handoff-contracts.md`
- [X] T030 [US4] Document Speckit artifact mapping to handoff fields in `sw-dev-team-template/docs/v1.1-handoff-contracts.md`. Primary verification: `grep -q 'Speckit artifacts map to handoff fields' sw-dev-team-template/docs/v1.1-handoff-contracts.md`
- [X] T031 [US4] Add schema support for external tool activity references in `sw-dev-team-template/schemas/handoff.schema.json`. Primary verification: `cd sw-dev-team-template && tests/hooks/test-handoff-contracts.sh`
- [X] T032 [US4] Add validation cases preventing tool output from satisfying final evidence in `sw-dev-team-template/tests/hooks/test-handoff-task-completed-gate.sh`. Primary verification: `cd sw-dev-team-template && tests/hooks/test-handoff-task-completed-gate.sh`
- [X] T033 [US4] Implement `sw-dev-team-template/scripts/hooks/handoff-task-created-gate.py` so Speckit-derived active work cites canonical owner roles and durable handoffs. Primary verification: `test -f sw-dev-team-template/scripts/hooks/handoff-task-created-gate.py && grep -q 'handoff-task-created-gate' sw-dev-team-template/docs/v1.1-handoff-contracts.md`

**Checkpoint**: User Story 4 is independently testable.

---

## Phase 7: User Story 5 - Roll Out Warning to Enforce Readiness (Priority: P5)

**Goal**: Enforce mode is enabled only after warning-mode evidence shows zero unresolved false positives across the clarified smoke baseline.

**Independent Test**: Readiness evidence covers handoff create/update, allowed edit, forbidden edit, evidence acceptance, evidence rejection, bounded Codex, and model fallback.

### Implementation for User Story 5

- [X] T034 [US5] Implement warning/enforce gate-mode behavior in `sw-dev-team-template/scripts/hooks/lib/handoff.py`. Primary verification: `cd sw-dev-team-template && tests/hooks/test-handoff-contracts.sh`
- [X] T035 [US5] Implement `sw-dev-team-template/scripts/hooks/handoff-subagent-stop-gate.py` for required specialist return evidence. Primary verification: `test -f sw-dev-team-template/scripts/hooks/handoff-subagent-stop-gate.py && grep -q 'handoff-subagent-stop-gate' sw-dev-team-template/docs/v1.1-handoff-contracts.md`
- [X] T036 [US5] Implement `sw-dev-team-template/scripts/hooks/handoff-stop-gate.py` for inconsistent, incomplete, or falsely completed active handoffs. Primary verification: `test -f sw-dev-team-template/scripts/hooks/handoff-stop-gate.py && grep -q 'handoff-stop-gate' sw-dev-team-template/docs/v1.1-handoff-contracts.md`
- [X] T037 [US5] Add settings merge support for warning-mode hooks in `sw-dev-team-template/scripts/upgrade.sh`. Primary verification: `cd sw-dev-team-template && tests/hooks/test-settings-merge.sh`
- [X] T038 [US5] Add release-readiness artifact-list guidance to `sw-dev-team-template/docs/v1.1-handoff-contracts.md`. Primary verification: `grep -q 'release notes, checklist, review, security, test, migration, and customer-approval' sw-dev-team-template/docs/v1.1-handoff-contracts.md`
- [X] T039 [US5] Add smoke coverage for handoff create/update, allowed edit, and forbidden edit in `sw-dev-team-template/tests/hooks/test-handoff-pre-tool-gate.sh`. Primary verification: `cd sw-dev-team-template && tests/hooks/test-handoff-pre-tool-gate.sh`
- [X] T040 [US5] Add smoke coverage for evidence acceptance and evidence rejection in `sw-dev-team-template/tests/hooks/test-handoff-task-completed-gate.sh`. Primary verification: `cd sw-dev-team-template && tests/hooks/test-handoff-task-completed-gate.sh`
- [X] T041 [US5] Add smoke coverage for bounded Codex and model fallback in `sw-dev-team-template/tests/hooks/test-codex-handoff-gate.sh`. Primary verification: `cd sw-dev-team-template && tests/hooks/test-codex-handoff-gate.sh`

**Checkpoint**: User Story 5 is independently testable.

---

## Final Phase: Polish & Cross-Cutting Concerns

**Purpose**: Cross-story validation, review, and release readiness.

- [X] T042 Run all handoff hook tests from `sw-dev-team-template/tests/hooks/`. Primary verification: `cd sw-dev-team-template && tests/hooks/test-handoff-contracts.sh && tests/hooks/test-handoff-pre-tool-gate.sh && tests/hooks/test-handoff-task-completed-gate.sh && tests/hooks/test-codex-handoff-gate.sh && tests/hooks/test-framework-path-boundary.sh && tests/hooks/test-settings-merge.sh`
- [X] T043 Run quickstart validation for `specs/012-v1-1-handoff-contracts/quickstart.md`. Primary verification: `test -f specs/012-v1-1-handoff-contracts/quickstart.md && grep -q 'Enforce-Readiness Smoke Baseline' specs/012-v1-1-handoff-contracts/quickstart.md`
- [X] T044 Perform constitution alignment review against `specs/012-v1-1-handoff-contracts/plan.md` and touched framework paths. Primary verification: `grep -q 'Post-Design Constitution Check' specs/012-v1-1-handoff-contracts/plan.md`
- [X] T045 Obtain role-appropriate review evidence before commit for changed `sw-dev-team-template/` schema, hook, settings, test, and docs paths. Primary verification: `grep -q 'code-reviewer' specs/012-v1-1-handoff-contracts/plan.md`

---

## Dependencies & Execution Order

### Requirement Coverage

- **FR-001, FR-002, FR-003, FR-004, SC-001, SC-002**: T001-T016.
- **FR-005, FR-006, FR-007, FR-008, FR-009, FR-010, SC-003**: T017-T022, T040, T042.
- **FR-011, FR-012, SC-004**: T005, T010, T044.
- **FR-013, FR-014, FR-015, SC-005**: T023-T025, T041.
- **FR-016, FR-017, SC-006**: T026-T028, T041.
- **FR-018, FR-019, FR-020, FR-021, FR-022, FR-023, SC-007**: T029-T033.
- **FR-024, FR-025, FR-026, SC-008, SC-009**: T034, T037-T043.
- **FR-027**: T020, T035, T036, T042.

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies.
- **Foundational (Phase 2)**: Depends on Setup; blocks all user stories.
- **User Stories (Phase 3+)**: Depend on Foundational; may proceed in priority order or parallel if specialists are available.
- **Polish**: Depends on selected user stories being complete.

### User Story Dependencies

- **US1 (P1)**: Starts after Foundation; MVP.
- **US2 (P2)**: Starts after Foundation; can run after or alongside US1 but completion semantics depend on handoff loading/schema foundation.
- **US3 (P3)**: Starts after Foundation; bounded-Codex pre-tool behavior benefits from US1 gate implementation.
- **US4 (P4)**: Starts after Foundation; documentation/schema additions can run alongside US2/US3.
- **US5 (P5)**: Starts after US1-US3 smoke surfaces exist.

### Parallel Opportunities

- T002 and T003 can run in parallel after T001.
- T029 and T030 can run in parallel with schema/test work once Phase 2 is complete.
- US2 evidence tasks and US4 integration-limit tasks can run in parallel when they edit distinct sections/files.

---

## Implementation Strategy

### MVP First

1. Complete Phase 1 and Phase 2.
2. Complete US1 path-scope enforcement.
3. Stop and validate with `cd sw-dev-team-template && tests/hooks/test-handoff-contracts.sh && tests/hooks/test-handoff-pre-tool-gate.sh`.

### Incremental Delivery

1. Deliver US1 to establish handoff and path scope.
2. Deliver US2 to gate completion evidence.
3. Deliver US3 to bound Codex/model fallback.
4. Deliver US4 to document llmdc/Speckit integration limits.
5. Deliver US5 to prove warning-to-enforce readiness.

### Task Ownership

- `software-engineer`: implementation and tests.
- `qa-engineer`: smoke coverage and verification checks.
- `code-reviewer`: review before commit.
- `security-engineer`: security-sensitive gate semantics.
- `release-engineer`: warning-to-enforce readiness and release artifact list.
