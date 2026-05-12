# Tasks: M2 Token Operating Model

**Input**: Design documents from `/specs/002-m2-token-operating-model/`
**Prerequisites**: `spec.md`, `plan.md`, `research.md`, `data-model.md`, `quickstart.md`

**Verification**: No automated test tasks are included because the feature is documentation/framework-maintenance guidance. Verification uses scoped review, marker checks, static Markdown/diff checks, and the independent review criteria listed per user story.

**Organization**: Tasks are grouped by user story in priority order so each story can be implemented and reviewed independently.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel because it touches different files or only reads files
- **[Story]**: User story label; setup, foundational, and polish tasks intentionally omit story labels
- Every task line includes an exact file path and uses the strict checklist format

## Phase 1: Setup (Shared Scope Confirmation)

**Purpose**: Confirm the allowed M2 framework-maintenance scope before editing canonical guidance.

**Owner/Scope**: `tech-lead` coordinates; setup is framework-maintenance planning for `specs/002-m2-token-operating-model/` only.

- [x] T001 Confirm M2 scope and exclusions from specs/002-m2-token-operating-model/plan.md before editing canonical guidance files.
- [x] T002 [P] Confirm user-story priority order and acceptance scenarios from specs/002-m2-token-operating-model/spec.md before assigning story tasks.
- [x] T003 [P] Confirm validation commands and review gates from specs/002-m2-token-operating-model/quickstart.md before implementation begins.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Establish the shared terminology and boundary checks that all user stories depend on.

**Owner/Scope**: `tech-lead` coordinates source extraction and Spec Kit pointer maintenance; foundational work is framework-maintenance preparation for canonical guidance edits only.

**Critical**: No user story implementation should begin until this phase is complete.

- [x] T004 Extract M2 entity and validation terms from specs/002-m2-token-operating-model/data-model.md for use in all guidance edits.
- [x] T005 [P] Extract accepted M2 decisions from specs/002-m2-token-operating-model/research.md for use in all guidance edits.
- [x] T006 [P] Inspect existing token-economy guidance in .claude/agents/tech-lead.md to avoid duplicating or weakening role routing.
- [x] T007 [P] Inspect existing pointer-only memory guidance in docs/MEMORY_POLICY.md to preserve repository source-of-truth language.
- [x] T008 Update the Spec Kit plan pointer to specs/002-m2-token-operating-model/plan.md in AGENTS.md. Trigger: none

**Checkpoint**: Shared M2 terminology, scope exclusions, and source-authority constraints are ready for story work.

---

## Phase 3: User Story 1 - Plan Work With Token Budgets (Priority: P1) MVP

**Goal**: Every planned task exposes expected token cost, a focused first-read file list, and token actual closure evidence.

**Owner/Scope**: `tech-lead` owns dispatch guidance and task-template maintainers own `docs/templates/task-template.md`; scope is canonical framework guidance only.

**Independent Test**: Review a new task plan and confirm each task includes one token budget band, a just-in-time file list, and a token actual closure field, with XL tasks split or explicitly accepted as oversized.

### Implementation for User Story 1

- [x] T009 [US1] Update allowed token budget bands to tiny, small, medium, large, and XL in docs/templates/task-template.md. Trigger: none
- [x] T010 [US1] Define intended use and review expectations for each token budget band in docs/templates/task-template.md. Trigger: none
- [x] T011 [US1] Require XL tasks to be split or explicitly accepted as oversized in docs/templates/task-template.md. Trigger: none
- [x] T012 [US1] Require a focused just-in-time file list before context expansion in docs/templates/task-template.md. Trigger: none
- [x] T013 [US1] Document accepted token actual formats: measured token count, actual budget band, or explicit not-captured reason in docs/templates/task-template.md. Trigger: none
- [x] T014 [US1] Align tech-lead dispatch guidance with tiny, small, medium, large, and XL token bands in .claude/agents/tech-lead.md. Trigger: none
- [x] T015 [US1] Verify token budget visibility and XL split-or-accept behavior against specs/002-m2-token-operating-model/spec.md in docs/templates/task-template.md.

**Checkpoint**: User Story 1 is independently reviewable through `docs/templates/task-template.md` and `.claude/agents/tech-lead.md`.

---

## Phase 4: User Story 2 - Refresh PM State From Deltas (Priority: P2)

**Goal**: Project-manager guidance supports lightweight delta passes that refresh only affected PM state instead of default broad rereads.

**Owner/Scope**: `project-manager` owns `.claude/agents/project-manager.md`; scope is canonical project-manager guidance only.

**Independent Test**: Perform a PM pass from changed files, merged PR titles, current milestone rows, changed open-question rows, and risk/change deltas, then confirm the pass records either a no-op or minimal affected-register edits.

### Implementation for User Story 2

- [x] T016 [US2] Add PM delta-pass input guidance for changed files, merged PR titles, current milestone rows, changed open-question rows, and risk/change deltas in .claude/agents/project-manager.md. Trigger: none
- [x] T017 [US2] Define no-op confirmation behavior when PM delta inputs require no register updates in .claude/agents/project-manager.md. Trigger: none
- [x] T018 [US2] Define minimal affected-register update behavior for schedule, risk, change, lessons, and open-question surfaces in .claude/agents/project-manager.md. Trigger: none
- [x] T019 [US2] Define targeted fallback reads for insufficient, stale, or conflicting delta inputs in .claude/agents/project-manager.md. Trigger: none
- [x] T020 [US2] Verify PM delta-pass guidance against specs/002-m2-token-operating-model/spec.md in .claude/agents/project-manager.md.

**Checkpoint**: User Story 2 is independently reviewable through `.claude/agents/project-manager.md`.

---

## Phase 5: User Story 3 - Query Memory Before Old Context (Priority: P3)

**Goal**: Binding guidance prescribes memory queries before broad old-context reads while keeping repository artifacts authoritative.

**Owner/Scope**: `researcher` owns customer-truth routing guidance, `tech-lead` owns customer-interface guidance, and memory-policy maintainers own `docs/MEMORY_POLICY.md`; scope is canonical framework guidance only.

**Independent Test**: Review binding guidance and confirm it names memory-query situations for old customer notes, old schedules, customer escalation history, and reopened ADR topics, with repository evidence remaining authoritative.

### Implementation for User Story 3

- [x] T021 [US3] Add concrete memory-query patterns for customer decisions, current milestone blockers, prior customer answers, and accepted ADRs in docs/MEMORY_POLICY.md. Trigger: none
- [x] T022 [US3] Preserve pointer-only memory language and repository source-of-truth precedence in docs/MEMORY_POLICY.md. Trigger: none
- [x] T023 [US3] Add memory-before-broad-read guidance for old schedules, customer escalation history, and reopened ADR topics in .claude/agents/tech-lead.md. Trigger: none
- [x] T024 [US3] Add memory-before-customer-truth-review guidance for old customer notes and prior customer answers in .claude/agents/researcher.md. Trigger: none
- [x] T025 [US3] Verify customer-truth stewardship remains routed through researcher in .claude/agents/researcher.md.
- [x] T026 [US3] Verify sole customer-interface routing remains routed through tech-lead in .claude/agents/tech-lead.md.
- [x] T027 [US3] Verify pointer-only memory behavior against specs/002-m2-token-operating-model/spec.md in docs/MEMORY_POLICY.md.

**Checkpoint**: User Story 3 is independently reviewable through `docs/MEMORY_POLICY.md`, `.claude/agents/tech-lead.md`, and `.claude/agents/researcher.md`.

---

## Phase 6: Polish & Cross-Cutting Verification

**Purpose**: Validate M2 scope, static cleanliness, and role/source-authority preservation across all changed canonical guidance.

- [x] T028 Run unresolved-marker validation from specs/002-m2-token-operating-model/quickstart.md against explicit M2 planning artifacts only.
- [x] T029 Verify task-template token fields with the quickstart grep checks in docs/templates/task-template.md.
- [x] T030 Verify PM delta-pass guidance with the quickstart grep checks in .claude/agents/project-manager.md.
- [x] T031 Verify memory query patterns and pointer-only language with the quickstart grep checks in docs/MEMORY_POLICY.md, .claude/agents/tech-lead.md, and .claude/agents/researcher.md.
- [x] T032 Verify the intended M2 implementation file list is limited to approved M2 paths listed in specs/002-m2-token-operating-model/plan.md, ignoring unrelated pre-existing dirty-worktree files.
- [x] T033 Run git diff --check for whitespace validation in specs/002-m2-token-operating-model/quickstart.md.
- [x] T034 Obtain project-manager review of token-budget planning fields and PM delta-pass guidance in docs/templates/task-template.md and .claude/agents/project-manager.md.
- [x] T035 Obtain researcher review of customer-truth stewardship and pointer-only memory language in docs/MEMORY_POLICY.md and .claude/agents/researcher.md.
- [x] T036 Obtain tech-lead review of sole customer-interface routing and dispatch token guidance in .claude/agents/tech-lead.md.
- [x] T037 Obtain code-reviewer review of role authority, source authority, and framework/project boundary preservation across AGENTS.md, specs/002-m2-token-operating-model/, docs/templates/task-template.md, docs/MEMORY_POLICY.md, .claude/agents/project-manager.md, .claude/agents/tech-lead.md, and .claude/agents/researcher.md.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies; can start immediately.
- **Foundational (Phase 2)**: Depends on Setup completion; blocks all user stories.
- **User Stories (Phases 3-5)**: Depend on Foundational completion; can proceed independently by file ownership if staffed.
- **Polish (Phase 6)**: Depends on the desired user stories being complete.

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational; no dependency on US2 or US3.
- **User Story 2 (P2)**: Can start after Foundational; no dependency on US1 or US3.
- **User Story 3 (P3)**: Can start after Foundational; no dependency on US1 or US2.

### Within Each User Story

- Implementation tasks should precede that story's verification task.
- Same-file edits should be serialized to avoid merge conflicts.
- Verification tasks can run after the relevant story files are edited.

---

## Parallel Opportunities

- T002 and T003 can run in parallel after T001 starts because they read different planning artifacts.
- T005, T006, and T007 can run in parallel after T004 because they inspect different source files; T008 can run after T005 confirms the accepted plan-pointer decision.
- After Phase 2, US1, US2, and US3 can run in parallel if separate assignees own `docs/templates/task-template.md`, `.claude/agents/project-manager.md`, and memory guidance files.
- T021 and T023 can run in parallel because they edit different files; T022 should follow T021 in `docs/MEMORY_POLICY.md`.
- T034, T035, T036, and T037 can run in parallel after T028 through T033 complete.

## Parallel Example: User Story 1

```text
Task: "T009 [US1] Update allowed token budget bands to tiny, small, medium, large, and XL in docs/templates/task-template.md. Trigger: none"
Task: "T014 [US1] Align tech-lead dispatch guidance with tiny, small, medium, large, and XL token bands in .claude/agents/tech-lead.md. Trigger: none"
```

## Parallel Example: User Story 2

```text
Task: "T016 [US2] Add PM delta-pass input guidance for changed files, merged PR titles, current milestone rows, changed open-question rows, and risk/change deltas in .claude/agents/project-manager.md. Trigger: none"
Task: "T020 [US2] Verify PM delta-pass guidance against specs/002-m2-token-operating-model/spec.md in .claude/agents/project-manager.md"
```

## Parallel Example: User Story 3

```text
Task: "T021 [US3] Add concrete memory-query patterns for customer decisions, current milestone blockers, prior customer answers, and accepted ADRs in docs/MEMORY_POLICY.md. Trigger: none"
Task: "T023 [US3] Add memory-before-broad-read guidance for old schedules, customer escalation history, and reopened ADR topics in .claude/agents/tech-lead.md. Trigger: none"
Task: "T024 [US3] Add memory-before-customer-truth-review guidance for old customer notes and prior customer answers in .claude/agents/researcher.md. Trigger: none"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 and Phase 2.
2. Complete Phase 3 for User Story 1.
3. Stop and validate that `docs/templates/task-template.md` and `.claude/agents/tech-lead.md` expose token budget, just-in-time file list, token actual, and XL split-or-accept guidance.

### Incremental Delivery

1. Deliver US1 to make task token economy visible in planning and closure.
2. Deliver US2 to reduce recurring PM context cost through delta passes.
3. Deliver US3 to reduce old-context rereads through pointer-only memory queries.
4. Run Phase 6 verification and specialist review gates before accepting M2.

### Parallel Team Strategy

1. One assignee owns US1 edits in `docs/templates/task-template.md` and `.claude/agents/tech-lead.md`.
2. One assignee owns US2 edits in `.claude/agents/project-manager.md`.
3. One assignee owns US3 edits in `docs/MEMORY_POLICY.md`, `.claude/agents/tech-lead.md`, and `.claude/agents/researcher.md`.
4. Coordinate `.claude/agents/tech-lead.md` edits between US1 and US3 to avoid same-file conflicts.

---

## Task Count Summary

- **Total tasks**: 37
- **Setup**: 3
- **Foundational**: 5
- **US1**: 7
- **US2**: 5
- **US3**: 7
- **Polish and cross-cutting verification**: 10

## Notes

- No automated test tasks are included; each story uses independent review criteria and quickstart validation.
- No product files, application source, runtime candidates, external APIs, package dependencies, or later milestone implementation are in scope.
- All implementation triggers are `none` because M2 changes canonical Markdown guidance only and introduces no dependency, public API, cross-module implementation boundary, safety-critical path, security-sensitive path, or data-model implementation.
