---

description: "Tasks for Template Improvement Program M0/M1 implementation"
---

# Tasks: Template Improvement Program

**Input**: Design documents from `specs/001-template-improvement-plan/`
**Prerequisites**: `specs/001-template-improvement-plan/plan.md`, `specs/001-template-improvement-plan/spec.md`, `specs/001-template-improvement-plan/research.md`, `specs/001-template-improvement-plan/data-model.md`, `specs/001-template-improvement-plan/quickstart.md`
**Scope**: M0 and M1 only. M2-M9 remain future context and may only appear as gate checks that prevent premature implementation.
**Verification**: Use repository-file evidence, shell/static checks, Markdown reference review, size measurements, prompt-regression evidence, and required specialist review gates. Do not add application unit tests; this feature has no application runtime.
**Organization**: Tasks are grouped by user story in priority order so the M0/M1 MVP can be independently implemented and reviewed.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel because it touches different files and has no dependency on incomplete tasks.
- **[Story]**: User-story tasks use `[US1]`, `[US2]`, `[US3]`, `[US4]`, or `[US5]`; setup, foundational, and polish tasks have no story label.
- **Path rule**: Every task description names the exact repository file path or paths to edit or verify.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Prepare M0/M1 planning and evidence locations without starting implementation of later milestones.

- [X] T001 Create the M0/M1 artifact index in `specs/001-template-improvement-plan/m0-m1-artifact-index.md` listing each required artifact, owner role, authority class, and acceptance source.
- [X] T002 [P] Create the PM schedule file from `docs/templates/pm/SCHEDULE-template.md` into `docs/pm/SCHEDULE.md` if `docs/pm/SCHEDULE.md` does not already exist.
- [X] T003 [P] Create the PM risk register file from `docs/templates/pm/RISKS-template.md` into `docs/pm/RISKS.md` if `docs/pm/RISKS.md` does not already exist.
- [X] T004 [P] Create the runtime candidate directory marker `docs/runtime/agents/README.md` defining generated-runtime status, canonical inputs, manual-edit prohibition, and review gate.
- [X] T005 [P] Create the human manual directory marker `docs/agents/manual/README.md` defining manual status, intended content, and non-authority relationship to `.claude/agents/*.md`.
- [X] T006 [P] Create the token-ledger prompt archive directory marker `docs/pm/token-ledger/prompts/README.md` defining when full prompts may be archived and how prompt hashes link back to `docs/pm/TOKEN_LEDGER.md`.

**Checkpoint**: Required directories and starting PM surfaces exist before M0/M1 implementation begins.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Establish authority boundaries and baseline measurement rules that all user-story work depends on.

**Critical**: No user-story implementation can begin until this phase is complete.

- [X] T007 Document the M0/M1 gate model in `specs/001-template-improvement-plan/m0-m1-artifact-index.md`, including G0 baseline acceptance and G1 token quick-win acceptance criteria.
- [X] T008 [P] Record the artifact authority classes for `CLAUDE.md`, `AGENTS.md`, `.claude/agents/*.md`, `docs/runtime/agents/*.md`, `docs/agents/manual/*.md`, `docs/pm/*.md`, and `specs/001-template-improvement-plan/*.md` in `specs/001-template-improvement-plan/m0-m1-artifact-index.md`.
- [X] T009 [P] Add the M0/M1 schedule entries, PR slicing plan, G0 gate, and G1 gate to `docs/pm/SCHEDULE.md` using M0/M1 scope only.
- [X] T010 [P] Add initial M0/M1 risks for context bloat, authority drift, prompt-compiler drift, model-routing volatility, archive traceability loss, and runtime-compaction rule loss to `docs/pm/RISKS.md`.
- [X] T011 [P] Define measurement commands and size metrics for live context surfaces in `docs/pm/token-economy-baseline.md` before any compaction or archival changes are accepted.
- [X] T012 [P] Record downstream reference-scope measurement fields for QuackDCS, QuackPLC, QuackS7, and QuackSim in `docs/pm/token-economy-baseline.md` without editing downstream repositories.

**Checkpoint**: G0 evidence collection can start, and later work is blocked until baseline evidence exists.

---

## Phase 3: User Story 1 - Reduce Recurring Context Cost (Priority: P1) MVP

**Goal**: Establish baseline context measurements and fully implement all M1 token quick-win artifacts while preserving auditability and canonical authority.

**Independent Test**: Compare baseline and post-change measurements in `docs/pm/token-economy-baseline.md`, confirm M1 artifacts exist, run `sh -n scripts/archive-registers.sh`, run `git diff --check`, and confirm G0/G1 evidence is recorded before any M2-M9 work begins.

### Implementation for User Story 1

- [X] T013 [US1] Capture baseline line counts and word-count token proxies for `CLAUDE.md`, `AGENTS.md`, `.claude/agents/*.md`, `docs/OPEN_QUESTIONS.md`, `CUSTOMER_NOTES.md`, `docs/pm/SCHEDULE.md`, `docs/pm/CHANGES.md`, `docs/pm/LESSONS.md`, and `docs/pm/TOKEN_LEDGER.md` in `docs/pm/token-economy-baseline.md`.
- [X] T014 [P] [US1] Capture live-register row counts, terminal-row counts, and archive candidates for `docs/OPEN_QUESTIONS.md`, `CUSTOMER_NOTES.md`, `docs/pm/RISKS.md`, and `docs/pm/LESSONS.md` in `docs/pm/token-economy-baseline.md`.
- [X] T015 [P] [US1] Capture downstream reference observations for QuackDCS, QuackPLC, QuackS7, and QuackSim in `docs/pm/token-economy-baseline.md` without changing files outside this repository.
- [X] T016 [US1] Record G0 baseline acceptance evidence and the largest recurring context surfaces in `docs/pm/token-economy-baseline.md`.
- [X] T017 [P] [US1] Create the shared runtime rules candidate in `docs/agents/common-runtime.md` preserving hard rules, local supplement checks, escalation behavior, role authority, and customer-interface ownership.
- [X] T018 [P] [US1] Create the generated runtime candidate for `tech-lead` in `docs/runtime/agents/tech-lead.md` from `.claude/agents/tech-lead.md` with at least a 30% size-reduction target or an explicit exception in `docs/pm/token-economy-baseline.md`.
- [X] T019 [P] [US1] Create the generated runtime candidate for `architect` in `docs/runtime/agents/architect.md` from `.claude/agents/architect.md` with at least a 20% size-reduction target or an explicit exception in `docs/pm/token-economy-baseline.md`.
- [X] T020 [P] [US1] Create the generated runtime candidate for `software-engineer` in `docs/runtime/agents/software-engineer.md` from `.claude/agents/software-engineer.md` with at least a 20% size-reduction target or an explicit exception in `docs/pm/token-economy-baseline.md`.
- [X] T021 [P] [US1] Create the generated runtime candidate for `qa-engineer` in `docs/runtime/agents/qa-engineer.md` from `.claude/agents/qa-engineer.md` with at least a 20% size-reduction target or an explicit exception in `docs/pm/token-economy-baseline.md`.
- [X] T022 [P] [US1] Create the generated runtime candidate for `code-reviewer` in `docs/runtime/agents/code-reviewer.md` from `.claude/agents/code-reviewer.md` with at least a 20% size-reduction target or an explicit exception in `docs/pm/token-economy-baseline.md`.
- [X] T023 [P] [US1] Create the generated runtime candidate for `researcher` in `docs/runtime/agents/researcher.md` from `.claude/agents/researcher.md` with at least a 20% size-reduction target or an explicit exception in `docs/pm/token-economy-baseline.md`.
- [X] T024 [P] [US1] Create the generated runtime candidate for `project-manager` in `docs/runtime/agents/project-manager.md` from `.claude/agents/project-manager.md` with at least a 20% size-reduction target or an explicit exception in `docs/pm/token-economy-baseline.md`.
- [X] T025 [P] [US1] Create the generated runtime candidate for `tech-writer` in `docs/runtime/agents/tech-writer.md` from `.claude/agents/tech-writer.md` with at least a 20% size-reduction target or an explicit exception in `docs/pm/token-economy-baseline.md`.
- [X] T026 [P] [US1] Create the generated runtime candidate for `release-engineer` in `docs/runtime/agents/release-engineer.md` from `.claude/agents/release-engineer.md` with at least a 20% size-reduction target or an explicit exception in `docs/pm/token-economy-baseline.md`.
- [X] T027 [P] [US1] Create the generated runtime candidate for `security-engineer` in `docs/runtime/agents/security-engineer.md` from `.claude/agents/security-engineer.md` with at least a 20% size-reduction target or an explicit exception in `docs/pm/token-economy-baseline.md`.
- [X] T028 [P] [US1] Create the generated runtime candidate for `sre` in `docs/runtime/agents/sre.md` from `.claude/agents/sre.md` with at least a 20% size-reduction target or an explicit exception in `docs/pm/token-economy-baseline.md`.
- [X] T029 [P] [US1] Create the generated runtime candidate for `onboarding-auditor` in `docs/runtime/agents/onboarding-auditor.md` from `.claude/agents/onboarding-auditor.md` with at least a 20% size-reduction target or an explicit exception in `docs/pm/token-economy-baseline.md`.
- [X] T030 [P] [US1] Create the generated runtime candidate for `process-auditor` in `docs/runtime/agents/process-auditor.md` from `.claude/agents/process-auditor.md` with at least a 20% size-reduction target or an explicit exception in `docs/pm/token-economy-baseline.md`.
- [X] T031 [P] [US1] Create the generated runtime candidate for `sme-template` in `docs/runtime/agents/sme-template.md` from `.claude/agents/sme-template.md` with at least a 20% size-reduction target or an explicit exception in `docs/pm/token-economy-baseline.md`.
- [X] T032 [US1] Record before/after line counts, word-count token proxies, reduction percentages, and accepted exceptions for all runtime candidates in `docs/pm/token-economy-baseline.md`.
- [X] T033 [P] [US1] Create human-readable manual extraction guidance for runtime-candidate rationale and examples in `docs/agents/manual/runtime-manual-guidance.md`.
- [X] T034 [P] [US1] Implement append-only live-register archival behavior for `docs/OPEN_QUESTIONS.md`, `CUSTOMER_NOTES.md`, `docs/intake-log.md`, `docs/pm/RISKS.md`, and `docs/pm/LESSONS.md` in `scripts/archive-registers.sh`.
- [X] T035 [US1] Create archive files `docs/OPEN_QUESTIONS-ARCHIVE.md`, `docs/customer-notes-archive.md`, `docs/intake-log-ARCHIVE.md`, `docs/pm/RISKS-ARCHIVE.md`, and `docs/pm/LESSONS-ARCHIVE.md` with source-file headers and append-only usage notes.
- [X] T036 [US1] Add compact tombstone and archive-pointer guidance to `docs/OPEN_QUESTIONS.md`, `CUSTOMER_NOTES.md`, `docs/pm/RISKS.md`, and `docs/pm/LESSONS.md` without removing open or recently answered live rows.
- [X] T037 [US1] Update `.claude/agents/researcher.md` to reference `scripts/archive-registers.sh` as the archival mechanism for `CUSTOMER_NOTES.md`, `docs/OPEN_QUESTIONS.md`, and `docs/intake-log.md` instead of relying only on manual discipline.
- [X] T038 [P] [US1] Refactor `docs/pm/TOKEN_LEDGER.md` to the compact schema `Date | Task ID | Agent | Prompt hash | Prompt class | Token budget | Token actual | Notes`.
- [X] T039 [P] [US1] Update `docs/templates/pm/TOKEN_LEDGER-template.md` to match the compact schema used by `docs/pm/TOKEN_LEDGER.md`.
- [X] T040 [P] [US1] Update `docs/templates/task-template.md` to require token budget, just-in-time file list, and token actual fields as task definition-of-done inputs for future use.
- [X] T041 [US1] Create `docs/pm/SCHEDULE-EVIDENCE.md` for closure evidence, raw references, and G0/G1 acceptance support previously unsuitable for live `docs/pm/SCHEDULE.md`.
- [X] T042 [US1] Create `docs/pm/SCHEDULE-ARCHIVE.md` for old closed schedule rows and historical reconciliations from `docs/pm/SCHEDULE.md`.
- [X] T043 [US1] Reduce `docs/pm/SCHEDULE.md` to current M0/M1 plan content only while cross-linking `docs/pm/SCHEDULE-EVIDENCE.md` and `docs/pm/SCHEDULE-ARCHIVE.md`.
- [X] T044 [US1] Record PM schedule live/evidence/archive split evidence and post-change line counts for `docs/pm/SCHEDULE.md`, `docs/pm/SCHEDULE-EVIDENCE.md`, and `docs/pm/SCHEDULE-ARCHIVE.md` in `docs/pm/token-economy-baseline.md`.
- [X] T045 [US1] Create prompt-regression evidence for `tech-lead`, `researcher`, `code-reviewer`, and `qa-engineer` runtime candidates in `docs/runtime/agents/prompt-regression-evidence.md`.
- [X] T046 [US1] Record code-review preservation evidence for hard rules, role authority, escalation formats, local supplement checks, and customer-interface ownership in `docs/runtime/agents/review-evidence.md`.
- [X] T047 [US1] Record G1 token quick-win acceptance evidence in `docs/pm/token-economy-baseline.md`, including runtime candidates, archival script, compact token ledger, PM split, and explicit prohibition on M2-M9 starts.

**Checkpoint**: User Story 1 is complete when G0 and G1 evidence exists, all M1 token quick-win artifacts are present, static checks pass, and review evidence confirms no hard rule or authority boundary was lost.

---

## Phase 4: User Story 2 - Repair Authority And Customer Question Flow (Priority: P2, Future Scope)

**Goal**: Prevent authority and question-flow implementation from starting during M0/M1 while preserving future gate visibility.

**Independent Test**: Inspect `docs/pm/SCHEDULE.md` and `docs/pm/token-economy-baseline.md` and confirm M3/M4 implementation is explicitly blocked until G1 is accepted.

### Gate Checks for User Story 2

- [X] T048 [US2] Add a future-scope gate row to `docs/pm/SCHEDULE.md` stating that authority-policy, roadmap-leakage, and customer-question-flow implementation in M3/M4 must not start until G1 evidence is accepted in `docs/pm/token-economy-baseline.md`.
- [X] T049 [US2] Confirm `docs/pm/token-economy-baseline.md` contains no M3/M4 implementation evidence beyond future-scope gate notes and G1 prerequisites.

**Checkpoint**: User Story 2 remains non-MVP and gated for future implementation.

---

## Phase 5: User Story 3 - Add Safe Cross-AI Routing As An Adapter (Priority: P3, Future Scope)

**Goal**: Prevent cross-AI adapter implementation from starting during M0/M1 while preserving future gate visibility.

**Independent Test**: Inspect `docs/pm/SCHEDULE.md` and `docs/pm/token-economy-baseline.md` and confirm M5 implementation is explicitly blocked until G1 and later authority gates are accepted.

### Gate Checks for User Story 3

- [X] T050 [US3] Add a future-scope gate row to `docs/pm/SCHEDULE.md` stating that OpenCode, Gemini, OpenAI, Codex, Claude adapter work in M5 must not start during M0/M1.
- [X] T051 [US3] Confirm `docs/pm/token-economy-baseline.md` contains no cross-AI routing implementation evidence, generated adapter files, fallback logging implementation, or provider-specific routing changes.

**Checkpoint**: User Story 3 remains non-MVP and gated for future implementation.

---

## Phase 6: User Story 4 - Generate Runtime Markdown Only After Authority Is Clear (Priority: P4, Future Scope)

**Goal**: Prevent Markdown compiler or generated-authority implementation from starting during M0/M1 while allowing M1 runtime candidates as non-authoritative generated candidates.

**Independent Test**: Inspect `docs/runtime/agents/README.md`, `docs/pm/SCHEDULE.md`, and `docs/pm/token-economy-baseline.md` and confirm runtime candidates remain subordinate to canonical sources and no compiler pipeline is implemented.

### Gate Checks for User Story 4

- [X] T052 [US4] Add a future-scope gate row to `docs/pm/SCHEDULE.md` stating that Markdown compiler, LLMD, schema, and runtime generation pipeline implementation in M6 must not start during M0/M1.
- [X] T053 [US4] Confirm `docs/runtime/agents/README.md` states that `docs/runtime/agents/*.md` files are generated candidates subordinate to `.claude/agents/*.md`, `CLAUDE.md`, and `AGENTS.md`.

**Checkpoint**: User Story 4 remains non-MVP and gated for future implementation.

---

## Phase 7: User Story 5 - Enable Safe Self-Improvement And Downstream Rollout (Priority: P5, Future Scope)

**Goal**: Prevent self-improvement automation and downstream rollout implementation from starting during M0/M1 while preserving reference-scope baseline observations.

**Independent Test**: Inspect `docs/pm/SCHEDULE.md` and `docs/pm/token-economy-baseline.md` and confirm downstream repositories are reference-only and automation work is blocked until later gates.

### Gate Checks for User Story 5

- [X] T054 [US5] Add a future-scope gate row to `docs/pm/SCHEDULE.md` stating that self-improvement automation in M7 and downstream rollout or retrofit work in M8 must not start during M0/M1.
- [X] T055 [US5] Confirm `docs/pm/token-economy-baseline.md` records QuackDCS, QuackPLC, QuackS7, and QuackSim as reference-scope observations only, with no downstream product or retrofit edits.

**Checkpoint**: User Story 5 remains non-MVP and gated for future implementation.

---

## Final Phase: Polish & Cross-Cutting Concerns

**Purpose**: Validate M0/M1 artifacts, preserve reviewability, and prevent accidental future-scope implementation.

- [X] T056 [P] Run the planning-scope quickstart checks from `specs/001-template-improvement-plan/quickstart.md` against `specs/001-template-improvement-plan/plan.md`, `specs/001-template-improvement-plan/research.md`, `specs/001-template-improvement-plan/data-model.md`, `specs/001-template-improvement-plan/quickstart.md`, and `specs/001-template-improvement-plan/contracts`.
- [X] T057 [P] Run unresolved-marker checks from `specs/001-template-improvement-plan/quickstart.md` against `specs/001-template-improvement-plan/` and remove any unresolved planning markers from `specs/001-template-improvement-plan/tasks.md`.
- [X] T058 [P] Run `sh -n scripts/archive-registers.sh` and record the result in `docs/pm/SCHEDULE-EVIDENCE.md`.
- [X] T059 [P] Run `git diff --check` and record the result in `docs/pm/SCHEDULE-EVIDENCE.md`.
- [X] T060 [P] Verify authority and traceability strings from `specs/001-template-improvement-plan/quickstart.md` across `docs/runtime/`, `docs/agents/`, `docs/pm/`, `docs/OPEN_QUESTIONS.md`, `CUSTOMER_NOTES.md`, and `specs/001-template-improvement-plan/`.
- [X] T061 Verify final diffs contain M0/M1 framework-maintenance files only and no downstream product files, recording the review in `docs/pm/SCHEDULE-EVIDENCE.md`.
- [X] T062 Verify `docs/pm/token-economy-baseline.md` contains G0 and G1 pass/fail evidence before any M2-M9 implementation starts.
- [X] T063 Record final M0/M1 review signoffs for `project-manager`, `software-engineer`, `tech-writer`, `architect`, `qa-engineer`, `code-reviewer`, and `release-engineer` in `docs/pm/SCHEDULE-EVIDENCE.md`.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies; can start immediately.
- **Foundational (Phase 2)**: Depends on Setup completion; blocks all user-story work.
- **US1 (Phase 3)**: Depends on Foundational completion; delivers the full M0/M1 MVP.
- **US2-US5 (Phases 4-7)**: Depend on Foundational completion; contain gate checks only and must not implement future-scope milestones.
- **Polish (Final Phase)**: Depends on completion of US1 and all future-scope gate checks.

### User Story Dependencies

- **US1 (P1)**: Starts after Foundational; no dependency on US2-US5.
- **US2 (P2)**: Future-scope gate checks only; depends on G1 being explicitly referenced.
- **US3 (P3)**: Future-scope gate checks only; depends on G1 and later authority gates remaining unstarted.
- **US4 (P4)**: Future-scope gate checks only; depends on runtime candidates remaining non-authoritative.
- **US5 (P5)**: Future-scope gate checks only; depends on downstream references remaining read-only.

### Within User Story 1

- Baseline measurement tasks T013-T016 precede compaction, archival, token-ledger, and PM-split acceptance.
- Runtime candidate tasks T017-T032 can run in parallel by file after baseline measurement rules exist.
- Archival script tasks T034-T037 must preserve append-only archive traceability before live surfaces are shortened.
- Token ledger tasks T038-T040 can run in parallel with PM split tasks T041-T044 because they touch different files.
- Review evidence tasks T045-T047 happen after implementation artifacts exist.

---

## Parallel Opportunities

- Setup tasks T002-T006 can run in parallel after T001 is created.
- Foundational tasks T009-T012 can run in parallel after T007-T008 define gate and authority rules.
- Runtime candidate tasks T018-T031 can run in parallel because each writes a separate `docs/runtime/agents/*.md` file.
- Token ledger tasks T038-T040 can run in parallel with PM split tasks T041-T044.
- Future-scope gate checks T048-T055 can run in parallel after `docs/pm/SCHEDULE.md` and `docs/pm/token-economy-baseline.md` exist.
- Polish checks T056-T060 can run in parallel after all implementation tasks are complete.

---

## Parallel Example: User Story 1

```text
Task: "T018 [US1] Create docs/runtime/agents/tech-lead.md"
Task: "T019 [US1] Create docs/runtime/agents/architect.md"
Task: "T020 [US1] Create docs/runtime/agents/software-engineer.md"
Task: "T021 [US1] Create docs/runtime/agents/qa-engineer.md"
Task: "T022 [US1] Create docs/runtime/agents/code-reviewer.md"
Task: "T023 [US1] Create docs/runtime/agents/researcher.md"
Task: "T024 [US1] Create docs/runtime/agents/project-manager.md"
Task: "T025 [US1] Create docs/runtime/agents/tech-writer.md"
Task: "T026 [US1] Create docs/runtime/agents/release-engineer.md"
Task: "T027 [US1] Create docs/runtime/agents/security-engineer.md"
Task: "T028 [US1] Create docs/runtime/agents/sre.md"
Task: "T029 [US1] Create docs/runtime/agents/onboarding-auditor.md"
Task: "T030 [US1] Create docs/runtime/agents/process-auditor.md"
Task: "T031 [US1] Create docs/runtime/agents/sme-template.md"
```

---

## Implementation Strategy

### MVP First

1. Complete Phase 1 setup tasks T001-T006.
2. Complete Phase 2 foundational tasks T007-T012.
3. Complete US1 tasks T013-T047 to deliver all M0/M1 MVP artifacts.
4. Complete future-scope gate checks T048-T055 to prevent premature M2-M9 starts.
5. Complete polish checks T056-T063 and stop for M0/M1 review.

### Incremental Delivery

1. Deliver G0 baseline evidence first with T013-T016.
2. Deliver M1 runtime candidates with T017-T033.
3. Deliver register archival with T034-T037.
4. Deliver compact token ledger and PM schedule split with T038-T044.
5. Deliver review evidence and G1 acceptance with T045-T047.
6. Deliver future-scope gates and final verification with T048-T063.

### Non-Goals For This Task List

- Do not implement M2 token operating model beyond compact token-ledger and task-template fields explicitly required by M1 acceptance.
- Do not implement M3/M4 authority-policy or customer-question-flow repairs.
- Do not implement M5 cross-AI routing, provider adapters, or fallback logging.
- Do not implement M6 Markdown compiler, schemas, or generation pipeline.
- Do not implement M7 self-improvement automation.
- Do not implement M8 downstream rollout or retrofit edits.
- Do not implement M9 release readiness work.

---

## Independent Test Criteria

- **US1**: `docs/pm/token-economy-baseline.md` shows baseline and post-change measurements; `docs/runtime/agents/*.md`, `scripts/archive-registers.sh`, `docs/pm/TOKEN_LEDGER.md`, `docs/pm/SCHEDULE-EVIDENCE.md`, and `docs/pm/SCHEDULE-ARCHIVE.md` exist; `sh -n scripts/archive-registers.sh` and `git diff --check` pass; G0/G1 evidence exists.
- **US2**: `docs/pm/SCHEDULE.md` and `docs/pm/token-economy-baseline.md` explicitly gate M3/M4 authority and question-flow implementation as future scope.
- **US3**: `docs/pm/SCHEDULE.md` and `docs/pm/token-economy-baseline.md` explicitly gate M5 cross-AI routing as future scope and show no adapter implementation.
- **US4**: `docs/runtime/agents/README.md` marks runtime candidates as subordinate generated candidates and `docs/pm/SCHEDULE.md` gates M6 compiler work as future scope.
- **US5**: `docs/pm/token-economy-baseline.md` records downstream repositories as reference-only and `docs/pm/SCHEDULE.md` gates M7/M8 automation and rollout as future scope.

---

## Task Count Summary

- **Total tasks**: 63
- **Setup**: 6 tasks
- **Foundational**: 6 tasks
- **US1**: 35 tasks
- **US2**: 2 tasks
- **US3**: 2 tasks
- **US4**: 2 tasks
- **US5**: 2 tasks
- **Polish**: 8 tasks
- **Suggested MVP scope**: Setup, Foundational, US1, US2-US5 gate checks, and Polish tasks T001-T063 because the M0/M1 MVP requires all M1 token quick-win artifacts plus explicit gates preventing later milestone starts.
