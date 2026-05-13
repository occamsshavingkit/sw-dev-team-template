# Tasks: Remaining Milestones M3-M9

**Input**: Design documents from `/specs/003-remaining-milestones/`
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `quickstart.md`, `sw_dev_template_implementation_plan-1.md`

**Verification**: Each milestone gate requires reviewable evidence before dependent work proceeds. Automated tests are included only where the specification or source plan calls for lint, schema, prompt-regression, scaffold, workflow, or rollout validation.

**Organization**: Tasks are grouped by user story and preserve M3 through M9 as independently reviewable gated increments. Task metadata is embedded in each task line as Owner, Scope, Authority, Evidence, Review, and Trigger.

**Scope labels**: `framework` means template/framework-maintenance work; `downstream-reference` means evidence about reference repositories without product edits; `candidate` means Spec Kit planning output; `generated` means reproducible generated output.

**Requirement coverage map**: T001 covers FR-001, FR-002, FR-003, FR-004, SC-001, SC-002, SC-003, and SC-008; T002-T003 cover FR-019, FR-020, FR-022, and CA-003; T013-T023 cover FR-005, FR-006, FR-021, CA-002, and SC-004; T024-T029 cover FR-007, FR-008, and CA-001; T030-T035 cover FR-009, FR-010, CA-004, and SC-005; T036-T042 cover FR-011 and FR-012; T043-T052 cover FR-013 and FR-014; T053-T057 cover FR-015, FR-016, and SC-006; T058-T068 cover FR-017, FR-018, and SC-007.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel because it touches different files and does not depend on incomplete tasks.
- **[Story]**: User story label used only in user-story phases.
- **Trigger**: `none`, or workflow-pipeline clause numbers from `.claude/agents/tech-lead.md`: 1 external dependency, 2 public API, 3 cross-module boundary, 4 safety-critical/Hard-Rule-#4, 5 auth/authz/secrets/PII/network-exposed, 6 data-model change.

## Phase 1: Setup (Shared Planning Controls)

**Purpose**: Establish objective evidence for this candidate task artifact without implementing M3-M9 directly.

- [X] T001 Verify M3-M9 source-scope coverage against `sw_dev_template_implementation_plan-1.md` and record the coverage matrix in `docs/pm/LESSONS.md` (Owner: project-manager; Scope: framework; Authority: canonical-source-to-candidate; Evidence: docs/pm/LESSONS.md; Review: tech-lead; Trigger: none)
- [X] T002 Verify no `contracts/`, `src/`, generic `tests/`, downstream product edits, release execution, or protected-branch automation are introduced by this planning slice and record results in `docs/pm/LESSONS.md` (Owner: project-manager; Scope: candidate; Authority: candidate; Evidence: docs/pm/LESSONS.md; Review: tech-lead; Trigger: none)
- [X] T003 [P] Validate candidate-artifact governance against `specs/003-remaining-milestones/plan.md` and record acceptance criteria in `docs/pm/LESSONS.md` (Owner: project-manager; Scope: candidate; Authority: candidate; Evidence: docs/pm/LESSONS.md; Review: tech-lead; Trigger: none)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Define shared gate discipline, role routing, artifact authority, and acceptance evidence before any milestone implementation task is dispatched.

**Critical**: No user-story milestone work starts until this phase is complete.

- [X] T004 Create the G3-G9 dependency and acceptance map in `docs/pm/SCHEDULE.md`, naming each gate accepter and required evidence artifact (Owner: project-manager; Scope: framework; Authority: canonical; Evidence: docs/pm/SCHEDULE.md; Review: tech-lead; Trigger: none)
- [X] T005 [P] Record M3-M9 owner routing in `docs/pm/SCHEDULE.md` using `specs/003-remaining-milestones/quickstart.md` as the planning source (Owner: project-manager; Scope: framework; Authority: canonical; Evidence: docs/pm/SCHEDULE.md; Review: tech-lead; Trigger: none)
- [X] T006 [P] Record framework/project boundary handling for template and downstream-reference work in `docs/pm/CHANGES.md` (Owner: project-manager; Scope: framework/downstream-reference; Authority: canonical; Evidence: docs/pm/CHANGES.md; Review: code-reviewer; Trigger: none)
- [X] T007 Define the shared gate-review checklist in `docs/pm/LESSONS.md` with required owner sign-off, validation command output, diff evidence, and next-gate release decision (Owner: project-manager; Scope: framework; Authority: canonical; Evidence: docs/pm/LESSONS.md; Review: tech-lead; Trigger: none)

**Gate acceptance map**: G3 accepted by `tech-lead` after `qa-engineer` lint evidence and `researcher` intake evidence; G4 accepted by `architect` and `code-reviewer`; G5 accepted by `architect`, `release-engineer`, and `code-reviewer`; G6 accepted by `qa-engineer` and `code-reviewer`; G7 accepted by `release-engineer`, `security-engineer`, and `code-reviewer`; G8 accepted by `project-manager`, `release-engineer`, and `qa-engineer`; G9 accepted by `code-reviewer`, `qa-engineer`, `release-engineer`, and `project-manager`, plus customer approval only if release policy requires it.

**Checkpoint**: M3-M9 tasks are routable by gate, role, authority, evidence, and framework boundary.

---

## Phase 3: User Story 1 - Prepare Safe Overnight Milestone Plan (Priority: P1) MVP

**Goal**: Make the Spec Kit task artifact reviewable, gated, and safe for overnight orchestration.

**Independent Test**: Review `specs/003-remaining-milestones/tasks.md` and confirm every M3-M9 gate is represented, no milestone is collapsed into an all-in-one implementation task, and customer-owned uncertainty is handled by assumptions or queued atomic questions.

### Implementation for User Story 1

- [X] T008 [US1] Validate that this task plan represents M3-M9 as separate setup, foundation, US1, US2, US3, US4, and polish phases and record the result in `docs/pm/LESSONS.md` (Owner: project-manager; Scope: candidate; Authority: candidate; Evidence: docs/pm/LESSONS.md; Review: tech-lead; Trigger: none)
- [X] T009 [P] [US1] Validate task-count and gate-coverage totals for this task plan and record the result in `docs/pm/LESSONS.md` (Owner: project-manager; Scope: candidate; Authority: candidate; Evidence: docs/pm/LESSONS.md; Review: tech-lead; Trigger: none)
- [X] T010 [P] [US1] Validate US1 through US4 independent test criteria against `specs/003-remaining-milestones/spec.md` and record the trace in `docs/pm/LESSONS.md` (Owner: project-manager; Scope: candidate; Authority: candidate; Evidence: docs/pm/LESSONS.md; Review: tech-lead; Trigger: none)
- [X] T011 [US1] Validate strict checklist formatting for all task lines in `specs/003-remaining-milestones/tasks.md` and record the command output in `docs/pm/LESSONS.md` (Owner: qa-engineer; Scope: candidate; Authority: candidate; Evidence: docs/pm/LESSONS.md; Review: project-manager; Trigger: none)
- [X] T012 [US1] Validate that no unresolved template markers remain in `specs/003-remaining-milestones/tasks.md` and record the scan output in `docs/pm/LESSONS.md` (Owner: qa-engineer; Scope: candidate; Authority: candidate; Evidence: docs/pm/LESSONS.md; Review: project-manager; Trigger: none)

**Checkpoint**: User Story 1 is complete when the task artifact can govern overnight planning without direct M3-M9 implementation.

---

## Phase 4: User Story 2 - Establish Intake, Authority, And Routing Foundations (Priority: P2)

**Goal**: Implement planning tasks for M3, M4, and M5 as separate gates covering atomic questions, documentation authority, drift control, and cross-AI routing.

**Independent Test**: G3, G4, and G5 can each be reviewed independently with their own evidence, and M5 does not start until G4 is accepted.

### M3 - Atomic-Question And Intake Repair

- [X] T013 [P] [US2] Rewrite scoping seed questions into one-decision-axis rows in `docs/FIRST_ACTIONS.md` (Owner: tech-writer; Scope: framework; Authority: canonical; Evidence: docs/pm/LESSONS.md; Review: tech-lead; Trigger: none)
- [X] T014 [P] [US2] Update customer-question batching guidance in `CLAUDE.md` (Owner: tech-writer; Scope: framework; Authority: canonical; Evidence: docs/pm/LESSONS.md; Review: tech-lead; Trigger: none)
- [X] T015 [P] [US2] Update customer-question batching guidance in `docs/FIRST_ACTIONS.md` (Owner: tech-writer; Scope: framework; Authority: canonical; Evidence: docs/pm/LESSONS.md; Review: tech-lead; Trigger: none)
- [X] T016 [P] [US2] Update customer-question batching guidance in `.claude/agents/tech-lead.md` (Owner: tech-writer; Scope: framework; Authority: canonical; Evidence: docs/pm/LESSONS.md; Review: tech-lead; Trigger: none)
- [X] T017 [P] [US2] Update customer-question batching guidance in `docs/OPEN_QUESTIONS.md` (Owner: researcher; Scope: framework; Authority: canonical; Evidence: docs/pm/LESSONS.md; Review: tech-lead; Trigger: none)
- [X] T018 [P] [US2] Update customer-question batching guidance in `docs/templates/intake-log-template.md` (Owner: researcher; Scope: framework; Authority: canonical; Evidence: docs/pm/LESSONS.md; Review: tech-lead; Trigger: none)
- [X] T019 [US2] Add the Customer Question Gate near the top of `.claude/agents/tech-lead.md` (Owner: tech-writer; Scope: framework; Authority: canonical; Evidence: docs/pm/LESSONS.md; Review: tech-lead; Trigger: none)
- [X] T020 [US2] Implement warning-only atomic-question lint checks in `scripts/lint-questions.sh` (Owner: software-engineer; Scope: framework; Authority: canonical; Evidence: docs/pm/LESSONS.md; Review: qa-engineer/code-reviewer; Trigger: 3)
- [X] T021 [P] [US2] Ensure fresh scaffold includes `docs/intake-log.md` via the existing scaffold template path documented in `docs/FIRST_ACTIONS.md` (Owner: software-engineer; Scope: framework; Authority: canonical; Evidence: docs/pm/LESSONS.md; Review: qa-engineer/code-reviewer; Trigger: 3)
- [X] T022 [P] [US2] Ensure repair or upgrade guidance creates missing `docs/intake-log.md` in `docs/TEMPLATE_UPGRADE.md` (Owner: tech-writer; Scope: framework; Authority: canonical; Evidence: docs/pm/LESSONS.md; Review: qa-engineer/code-reviewer; Trigger: 3)
- [X] T023 [US2] Validate G3 evidence by running `scripts/lint-questions.sh`, proving intake-log scaffold/repair coverage, and recording `tech-lead` gate acceptance in `docs/pm/LESSONS.md` (Owner: qa-engineer; Scope: framework; Authority: canonical; Evidence: docs/pm/LESSONS.md; Review: tech-lead; Trigger: none)

### M4 - Documentation Authority And Drift Control

- [X] T024 [US2] Add canonical/generated/ephemeral Documentation Authority Policy to `docs/framework-project-boundary.md` (Owner: architect; Scope: framework; Authority: canonical; Evidence: docs/pm/LESSONS.md; Review: code-reviewer; Trigger: 3)
- [X] T025 [US2] Decide and document root roadmap downstream handling in `docs/framework-project-boundary.md` (Owner: architect; Scope: framework/downstream-reference; Authority: canonical; Evidence: docs/pm/LESSONS.md; Review: code-reviewer; Trigger: 3)
- [X] T026 [US2] Update retrofit guidance for existing downstream `ROADMAP.md` handling in `docs/TEMPLATE_UPGRADE.md` (Owner: tech-writer; Scope: framework/downstream-reference; Authority: canonical; Evidence: docs/pm/LESSONS.md; Review: architect/code-reviewer; Trigger: 3)
- [X] T027 [US2] Clarify binding status and release-time model ID verification in `docs/model-routing-guidelines.md` (Owner: architect; Scope: framework; Authority: canonical; Evidence: docs/pm/LESSONS.md; Review: code-reviewer; Trigger: 3)
- [X] T028 [US2] Move binding workflow-pipeline rules into `docs/workflow-pipeline.md` if they are currently sourced from excluded proposal material (Owner: architect; Scope: framework; Authority: canonical; Evidence: docs/pm/LESSONS.md; Review: code-reviewer; Trigger: 3)
- [X] T029 [US2] Validate G4 evidence with a scoped grep proving downstream-shipped files no longer depend on excluded proposal docs and record architect/code-reviewer gate acceptance in `docs/pm/LESSONS.md` (Owner: code-reviewer; Scope: framework; Authority: canonical; Evidence: docs/pm/LESSONS.md; Review: architect; Trigger: none)

### M5 - Cross-AI / OpenCode / Gemini Routing

- [X] T030 [US2] Create OpenCode harness-adapter ADR in `docs/adr/fw-adr-opencode-harness-adapter.md` (Owner: architect; Scope: framework; Authority: canonical; Evidence: docs/pm/LESSONS.md; Review: code-reviewer; Trigger: 3)
- [X] T031 [US2] Extend provider/model ID conventions and Gemini model classes in `docs/model-routing-guidelines.md` (Owner: architect; Scope: framework; Authority: canonical; Evidence: docs/pm/LESSONS.md; Review: release-engineer/code-reviewer; Trigger: 3)
- [X] T032 [US2] Document frontier escalation and fallback behavior in `docs/model-routing-guidelines.md` (Owner: architect; Scope: framework; Authority: canonical; Evidence: docs/pm/LESSONS.md; Review: release-engineer/code-reviewer; Trigger: 3)
- [X] T033 [US2] Add fallback logging format and authority-preservation rule to `docs/model-routing-guidelines.md` (Owner: architect; Scope: framework; Authority: canonical; Evidence: docs/pm/LESSONS.md; Review: release-engineer/code-reviewer; Trigger: 3)
- [X] T034 [US2] Add generated or generator-backed thin OpenCode adapter guidance to `AGENTS.md` (Owner: architect; Scope: framework/generated; Authority: generated-or-generator-backed; Evidence: docs/pm/LESSONS.md; Review: release-engineer/code-reviewer; Trigger: 3)
- [X] T035 [US2] Validate G5 evidence that no parallel role model is introduced across `CLAUDE.md`, `AGENTS.md`, and `.claude/agents/*.md`, then record architect/release-engineer/code-reviewer gate acceptance in `docs/pm/LESSONS.md` (Owner: code-reviewer; Scope: framework; Authority: canonical/generated; Evidence: docs/pm/LESSONS.md; Review: architect/release-engineer; Trigger: none)

**Checkpoint**: User Story 2 is complete when G3, G4, and G5 evidence is independently reviewable and accepted in order.

---

## Phase 5: User Story 3 - Plan Runtime Generation And Controlled Self-Improvement (Priority: P3)

**Goal**: Implement planning tasks for M6 and M7 after source authority and adapter routing have passed.

**Independent Test**: G6 proves generated outputs are reproducible and non-canonical; G7 proves automation is PR-only, one-improvement-at-a-time, patch-size-limited, human-reviewed, and safe on failure.

### M6 - Markdown Compiler / LLMD / Runtime Contract Pipeline

- [X] T036 [P] [US3] Define agent contract validation schema in `schemas/agent-contract.schema.json` (Owner: software-engineer; Scope: framework; Authority: canonical; Evidence: docs/pm/LESSONS.md; Review: qa-engineer/code-reviewer; Trigger: 6)
- [X] T037 [P] [US3] Define model routing validation schema in `schemas/model-routing.schema.json` (Owner: software-engineer; Scope: framework; Authority: canonical; Evidence: docs/pm/LESSONS.md; Review: qa-engineer/code-reviewer; Trigger: 6)
- [X] T038 [P] [US3] Define generated artifact validation schema in `schemas/generated-artifact.schema.json` (Owner: software-engineer; Scope: framework/generated; Authority: canonical; Evidence: docs/pm/LESSONS.md; Review: qa-engineer/code-reviewer; Trigger: 6)
- [X] T039 [US3] Implement contract linting in `scripts/lint-agent-contracts.sh` (Owner: software-engineer; Scope: framework; Authority: canonical; Evidence: docs/pm/LESSONS.md; Review: qa-engineer/code-reviewer; Trigger: 3,6)
- [X] T040 [US3] Implement runtime compilation and token or line reporting in `scripts/compile-runtime-agents.sh` (Owner: software-engineer; Scope: framework/generated; Authority: canonical-generator; Evidence: docs/pm/LESSONS.md; Review: qa-engineer/code-reviewer; Trigger: 3,6)
- [X] T041 [US3] Add prompt-regression cases for core roles in `docs/prompt-regression.md` (Owner: qa-engineer; Scope: framework; Authority: canonical; Evidence: docs/pm/LESSONS.md; Review: code-reviewer; Trigger: 3)
- [X] T042 [US3] Validate G6 by proving schema validation passes, generated files are stable, prompt regressions pass, and canonical source files remain authoritative, then record qa-engineer/code-reviewer gate acceptance in `docs/pm/LESSONS.md` (Owner: qa-engineer; Scope: framework/generated; Authority: canonical/generated; Evidence: docs/pm/LESSONS.md; Review: code-reviewer; Trigger: none)

### M7 - Self-Improvement Loop And Issue-Driven Evolution

- [X] T043 [US3] Add framework issue taxonomy and label definitions to `docs/ISSUE_FILING.md` (Owner: project-manager; Scope: framework; Authority: canonical; Evidence: docs/pm/LESSONS.md; Review: code-reviewer; Trigger: 3)
- [X] T044 [US3] Add framework-gap issue template fields to `.github/ISSUE_TEMPLATE/framework-gap.yml` (Owner: project-manager; Scope: framework; Authority: canonical; Evidence: docs/pm/LESSONS.md; Review: code-reviewer; Trigger: 3)
- [X] T045 [US3] Document one-improvement-at-a-time AI improvement workflow in `docs/workflow-pipeline.md` (Owner: architect; Scope: framework; Authority: canonical; Evidence: docs/pm/LESSONS.md; Review: release-engineer/code-reviewer; Trigger: 3)
- [X] T046 [P] [US3] Add agent contract check workflow in `.github/workflows/agent-contract-check.yml` (Owner: release-engineer; Scope: framework; Authority: canonical; Evidence: docs/pm/LESSONS.md; Review: security-engineer/code-reviewer; Trigger: 3)
- [X] T047 [P] [US3] Add question lint workflow in `.github/workflows/question-lint.yml` (Owner: release-engineer; Scope: framework; Authority: canonical; Evidence: docs/pm/LESSONS.md; Review: security-engineer/code-reviewer; Trigger: 3)
- [X] T048 [P] [US3] Add template contract smoke workflow in `.github/workflows/template-contract-smoke.yml` (Owner: release-engineer; Scope: framework; Authority: canonical; Evidence: docs/pm/LESSONS.md; Review: security-engineer/code-reviewer; Trigger: 3)
- [X] T049 [US3] Add gated manual or scheduled improvement workflow in `.github/workflows/improve-template.yml` with PR-only behavior and safe no-op or issue output on failure (Owner: release-engineer; Scope: framework; Authority: canonical; Evidence: docs/pm/LESSONS.md; Review: security-engineer/code-reviewer; Trigger: 3)
- [X] T050 [US3] Enforce the M7 patch-size limit in `docs/workflow-pipeline.md` and `.github/workflows/improve-template.yml`, including the maximum changed-file and diff-line threshold used to block oversized automation output (Owner: release-engineer; Scope: framework; Authority: canonical; Evidence: docs/pm/LESSONS.md; Review: security-engineer/code-reviewer; Trigger: 3)
- [X] T051 [US3] Enforce human review for every M7 automation PR before merge and document the required reviewer role sequence in `docs/workflow-pipeline.md` (Owner: project-manager; Scope: framework; Authority: canonical; Evidence: docs/pm/LESSONS.md; Review: release-engineer/code-reviewer; Trigger: 3)
- [X] T052 [US3] Validate G7 evidence that automation opens PRs only, runs contract checks before PR creation, enforces patch-size limits, requires human review, and produces no-op or issue output on failure, then record release-engineer/security-engineer/code-reviewer gate acceptance in `docs/pm/LESSONS.md` (Owner: code-reviewer; Scope: framework; Authority: canonical; Evidence: docs/pm/LESSONS.md; Review: release-engineer/security-engineer; Trigger: none)

**Checkpoint**: User Story 3 is complete when G6 and G7 are accepted and generated or automated outputs remain subordinate to canonical sources.

---

## Phase 6: User Story 4 - Prepare Downstream Rollout And Release Readiness (Priority: P4)

**Goal**: Implement planning tasks for M8 and M9 after template controls have passed.

**Independent Test**: G8 shows each reference repository is repaired or explicitly excepted; G9 shows release readiness evidence and required approvals are complete.

### M8 - Downstream Rollout And Retrofit Repair

- [ ] T053 [US4] Classify `QuackDCS`, `QuackPLC`, `QuackS7`, and `QuackSim` rollout status in `docs/pm/SCHEDULE.md` (Owner: project-manager; Scope: downstream-reference; Authority: canonical; Evidence: docs/pm/SCHEDULE.md; Review: release-engineer/qa-engineer; Trigger: none)
- [ ] T054 [US4] Record per-repository repair sequence, boundary status, and exception criteria in `docs/pm/CHANGES.md` (Owner: project-manager; Scope: downstream-reference; Authority: canonical; Evidence: docs/pm/CHANGES.md; Review: release-engineer/qa-engineer; Trigger: none)
- [ ] T055 [US4] Run or document scaffold/upgrade repair checks for all four reference repositories in `docs/pm/LESSONS.md` (Owner: qa-engineer; Scope: downstream-reference; Authority: canonical; Evidence: docs/pm/LESSONS.md; Review: release-engineer/project-manager; Trigger: 3)
- [ ] T056 [US4] Capture rollout lessons and upstream scaffold smoke-test updates in `docs/TEMPLATE_UPGRADE.md` (Owner: tech-writer; Scope: framework/downstream-reference; Authority: canonical; Evidence: docs/pm/LESSONS.md; Review: release-engineer/qa-engineer; Trigger: 3)
- [ ] T057 [US4] Validate G8 repaired-or-excepted status for all four reference repositories and record project-manager/release-engineer/qa-engineer gate acceptance in `docs/pm/SCHEDULE.md` (Owner: project-manager; Scope: downstream-reference; Authority: canonical; Evidence: docs/pm/SCHEDULE.md; Review: release-engineer/qa-engineer; Trigger: none)

### M9 - v1.0 Readiness And Release Gate

- [ ] T058 [US4] Request and collect code-reviewer conformance approval evidence in `docs/pm/LESSONS.md` (Owner: code-reviewer; Scope: framework; Authority: canonical; Evidence: docs/pm/LESSONS.md; Review: project-manager; Trigger: none)
- [ ] T059 [US4] Request and collect qa-engineer scaffold, upgrade, and retrofit validation evidence in `docs/pm/LESSONS.md` (Owner: qa-engineer; Scope: framework/downstream-reference; Authority: canonical; Evidence: docs/pm/LESSONS.md; Review: project-manager; Trigger: none)
- [ ] T060 [US4] Request and collect release-engineer packaging, versioning, and release-notes approval evidence in `docs/pm/LESSONS.md` (Owner: release-engineer; Scope: framework; Authority: canonical; Evidence: docs/pm/LESSONS.md; Review: project-manager; Trigger: none)
- [ ] T061 [US4] Record project-manager release-risk, schedule, change, and lessons review in `docs/pm/RISKS.md` and link supporting schedule/change/lessons evidence (Owner: project-manager; Scope: framework; Authority: canonical; Evidence: docs/pm/RISKS.md; Review: tech-lead; Trigger: none)
- [ ] T062 [P] [US4] Request zero-context usability review from onboarding-auditor and record evidence in `docs/pm/LESSONS.md` (Owner: onboarding-auditor; Scope: framework; Authority: canonical; Evidence: docs/pm/LESSONS.md; Review: project-manager; Trigger: none)
- [ ] T063 [P] [US4] Request process-debt retirement review from process-auditor and record evidence in `docs/pm/LESSONS.md` (Owner: process-auditor; Scope: framework; Authority: canonical; Evidence: docs/pm/LESSONS.md; Review: project-manager; Trigger: none)
- [ ] T064 [US4] Validate generated-artifact freshness and release criteria in `docs/pm/LESSONS.md` (Owner: qa-engineer; Scope: framework/generated; Authority: canonical/generated; Evidence: docs/pm/LESSONS.md; Review: code-reviewer/release-engineer; Trigger: none)
- [ ] T065 [US4] Resolve whether template release policy requires customer approval and record the policy citation or assumption in `docs/pm/LESSONS.md` (Owner: project-manager; Scope: framework; Authority: canonical; Evidence: docs/pm/LESSONS.md; Review: tech-lead; Trigger: none)
- [ ] T066 [US4] If release policy requires customer approval, queue one atomic approval question in `docs/OPEN_QUESTIONS.md` through `tech-lead` and `researcher` stewardship (Owner: researcher; Scope: framework; Authority: canonical/customer-truth-pending; Evidence: docs/OPEN_QUESTIONS.md; Review: tech-lead; Trigger: none)
- [ ] T067 [US4] If release policy requires customer approval, obtain approval through `tech-lead` and record the accepted answer in `CUSTOMER_NOTES.md` through `researcher`; if not required, record the not-required decision in `docs/pm/LESSONS.md` (Owner: researcher; Scope: framework/customer-truth; Authority: canonical; Evidence: CUSTOMER_NOTES.md or docs/pm/LESSONS.md; Review: tech-lead; Trigger: none)
- [ ] T068 [US4] Validate G9 release-candidate acceptance evidence and record code-reviewer/qa-engineer/release-engineer/project-manager acceptance plus customer-approval status in `docs/pm/LESSONS.md` (Owner: project-manager; Scope: framework; Authority: canonical; Evidence: docs/pm/LESSONS.md; Review: tech-lead; Trigger: none)

**Checkpoint**: User Story 4 is complete when G8 and G9 evidence is accepted and no release-blocking risk remains open.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Validate the task artifact and prepare it for `tech-lead` governance.

- [ ] T069 Run unresolved-marker scan using the marker list from `specs/003-remaining-milestones/quickstart.md` against `specs/003-remaining-milestones/tasks.md` and record output in `docs/pm/LESSONS.md` (Owner: qa-engineer; Scope: candidate; Authority: candidate; Evidence: docs/pm/LESSONS.md; Review: project-manager; Trigger: none)
- [ ] T070 Run strict checklist format validation for all task lines in `specs/003-remaining-milestones/tasks.md` and record output in `docs/pm/LESSONS.md` (Owner: qa-engineer; Scope: candidate; Authority: candidate; Evidence: docs/pm/LESSONS.md; Review: project-manager; Trigger: none)
- [ ] T071 Run M3-M9, G3-G9, FR-001 through FR-022, CA-001 through CA-004, and SC-001 through SC-008 coverage validation in `specs/003-remaining-milestones/tasks.md` and record trace output in `docs/pm/LESSONS.md` (Owner: project-manager; Scope: candidate; Authority: candidate; Evidence: docs/pm/LESSONS.md; Review: tech-lead; Trigger: none)
- [ ] T072 Run whitespace validation with `git diff --check` and, if needed for untracked candidate files, `git diff --check --no-index /dev/null specs/003-remaining-milestones/tasks.md` (Owner: qa-engineer; Scope: candidate; Authority: candidate; Evidence: command output in docs/pm/LESSONS.md; Review: project-manager; Trigger: none)
- [ ] T073 Route `specs/003-remaining-milestones/tasks.md` through `tech-lead` governance before implementation or issue conversion begins and record the acceptance decision in `docs/pm/LESSONS.md` (Owner: project-manager; Scope: candidate; Authority: candidate; Evidence: docs/pm/LESSONS.md; Review: tech-lead; Trigger: none)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies.
- **Foundational (Phase 2)**: Depends on Setup completion and blocks all user-story work.
- **US1 (Phase 3)**: Depends on Foundational completion; provides the MVP task artifact.
- **US2 (Phase 4)**: Depends on US1 acceptance; M3 must pass before M4, and M4 must pass before M5.
- **US3 (Phase 5)**: Depends on G5; M6 must pass before M7.
- **US4 (Phase 6)**: Depends on G7; M8 must pass before M9.
- **Polish (Phase 7)**: Depends on all desired user stories for the current increment.

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational; no dependency on other user stories.
- **User Story 2 (P2)**: Depends on US1 because it uses the accepted task structure and gate model.
- **User Story 3 (P3)**: Depends on US2 because compiler and automation work require accepted authority and routing controls.
- **User Story 4 (P4)**: Depends on US3 because rollout and release readiness require accepted compiler and automation controls.

### Milestone Gate Dependencies

- **G3**: Blocks M4 and later authority cleanup; accepted by `tech-lead` with `qa-engineer` and `researcher` evidence in `docs/pm/LESSONS.md`.
- **G4**: Blocks M5 adapter routing; accepted by `architect` and `code-reviewer` with evidence in `docs/pm/LESSONS.md`.
- **G5**: Blocks M6 compiler/runtime generation; accepted by `architect`, `release-engineer`, and `code-reviewer` with evidence in `docs/pm/LESSONS.md`.
- **G6**: Blocks M7 self-improvement automation; accepted by `qa-engineer` and `code-reviewer` with evidence in `docs/pm/LESSONS.md`.
- **G7**: Blocks M8 downstream rollout; accepted by `release-engineer`, `security-engineer`, and `code-reviewer` with evidence in `docs/pm/LESSONS.md`.
- **G8**: Blocks M9 release readiness; accepted by `project-manager`, `release-engineer`, and `qa-engineer` with status in `docs/pm/SCHEDULE.md`.
- **G9**: Final release-candidate acceptance boundary; accepted by `code-reviewer`, `qa-engineer`, `release-engineer`, and `project-manager`, plus customer approval only if release policy requires it.

---

## Parallel Opportunities

- T003 can run with T001-T002 because it validates governance against `plan.md` only.
- T005-T006 can run in parallel after T004 starts because they update distinct PM evidence artifacts.
- T013-T018 can run in parallel if each file owner coordinates final wording consistency before T019.
- T021-T022 can run in parallel because scaffold and upgrade guidance are separate surfaces.
- T036-T038 can run in parallel because each schema file is independent before T039-T040 integrate them.
- T046-T048 can run in parallel because each workflow file is independent before T049 integrates the improvement loop.
- T062-T063 can run in parallel because onboarding and process audits produce separate evidence.

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup.
2. Complete Phase 2: Foundational.
3. Complete Phase 3: User Story 1.
4. Stop and validate that `specs/003-remaining-milestones/tasks.md` covers M3-M9 with strict task formatting and no unresolved markers.

### Incremental Delivery

1. Deliver US1 as the safe overnight task artifact.
2. Deliver US2 through G3, G4, and G5 in order.
3. Deliver US3 through G6 and G7 in order.
4. Deliver US4 through G8 and G9 in order.
5. Run Polish validation after each accepted tranche before issue conversion or implementation dispatch.

### Independent Test Criteria

- **US1**: `tasks.md` has strict checklist task lines, no unresolved markers, and explicit M3-M9/G3-G9 coverage.
- **US2**: G3, G4, and G5 each have separate evidence paths and accepted gate criteria before the next milestone begins.
- **US3**: G6 proves reproducible generated outputs and prompt regressions; G7 proves PR-only safe automation with patch-size limits, human review, and no broken-commit failure mode.
- **US4**: G8 proves all four reference repos are repaired or excepted; G9 proves required role approvals, release criteria, release-risk status, and customer-approval policy status.

---

## Task Counts

- **Total tasks**: 73
- **Setup**: 3
- **Foundational**: 4
- **US1**: 5
- **US2**: 23
- **US3**: 17
- **US4**: 16
- **Polish**: 5

## Notes

- Spec Kit outputs remain candidate material until governed by `tech-lead`.
- Customer-owned uncertainty must be documented as an assumption or queued as one atomic question.
- Framework-maintenance work must not mix downstream product edits with template changes.
- Trigger annotations are advisory routing inputs for `tech-lead`; non-`none` tasks require the workflow-pipeline handling defined in `.claude/agents/tech-lead.md`.
