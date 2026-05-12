# Feature Specification: M2 Token Operating Model

**Feature Branch**: `002-m2-token-operating-model`
**Created**: 2026-05-12
**Status**: Draft
**Input**: User description: "M2 for this project"

## Clarifications

### Session 2026-05-12

- Q: Which artifact scope should M2 update? → A: Update canonical docs/templates only: task template, project-manager guidance, memory policy, tech-lead, researcher, and the AGENTS.md Spec Kit plan pointer.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Plan Work With Token Budgets (Priority: P1)

Template maintainers need every planned task to show its expected token cost, first-read file list, and closure actual so token economy becomes visible during planning and review.

**Why this priority**: Token discipline cannot become operational until every task exposes expected cost before work starts and actual cost when material work closes.

**Independent Test**: Can be tested by reviewing a new task plan and confirming each task includes a token budget band, just-in-time file list, and closure field for token actuals.

**Acceptance Scenarios**:

1. **Given** a maintainer prepares a task, **When** the task is recorded, **Then** the task includes one token budget band, a focused just-in-time file list, and a token actual field for closure.
2. **Given** a task is marked XL, **When** the plan is reviewed, **Then** the reviewer can see that the task should be split or explicitly accepted as oversized.
3. **Given** a material task closes, **When** closure evidence is reviewed, **Then** the token actual is visible or the reason it was not material is clear.

---

### User Story 2 - Refresh PM State From Deltas (Priority: P2)

Project managers need a lightweight delta pass that refreshes schedule, risk, change, and open-question state from current changes instead of rereading all PM artifacts by default.

**Why this priority**: PM cadence must stay fresh without turning routine status work into a recurring context sink.

**Independent Test**: Can be tested by performing a PM pass using only changed files, merged PR titles, current milestone rows, changed open-question rows, and risk/change deltas, then confirming only affected registers are updated or a no-op is recorded.

**Acceptance Scenarios**:

1. **Given** a PM pass starts after recent work, **When** changed-file, merged-PR, milestone, open-question, and risk/change deltas are sufficient, **Then** the PM pass completes without broad rereads.
2. **Given** no PM register needs an update, **When** the PM delta pass completes, **Then** it records a no-op confirmation rather than editing unrelated files.
3. **Given** a delta exposes a schedule, risk, or open-question change, **When** the PM pass completes, **Then** only the affected register content is updated.

---

### User Story 3 - Query Memory Before Old Context (Priority: P3)

Maintainers and specialists need prescriptive memory-query guidance before reading old customer notes, old schedules, customer escalation history, or reopened ADR topics, while keeping repository artifacts as the source of truth.

**Why this priority**: Memory can reduce old-context rereads, but it must remain pointer-only so it does not replace canonical repository evidence.

**Independent Test**: Can be tested by reviewing binding guidance and confirming it names the required situations for memory queries and states that memory points to repository evidence rather than becoming authority.

**Acceptance Scenarios**:

1. **Given** an agent considers reading old customer notes, **When** the topic is known, **Then** guidance directs the agent to query memory for prior customer decisions before broad note review.
2. **Given** an agent considers reading old schedules, **When** the current blocker or milestone context is needed, **Then** guidance directs a targeted memory query before broad schedule review.
3. **Given** an ADR topic is reopened, **When** prior rationale may exist, **Then** guidance directs a memory query for accepted ADR context before reopening the decision.
4. **Given** memory returns a candidate answer, **When** the agent acts on it, **Then** repository sources remain the authority and memory is treated as a pointer to verify.

### Edge Cases

- If a task's expected token band is unclear, the task must choose the smallest defensible band and call out the uncertainty for review.
- If a task appears to require XL context, the plan must either split it or record explicit acceptance before work proceeds.
- If delta inputs are incomplete or inconsistent, the PM pass may fall back to targeted affected files, not a default full reread.
- If a memory result conflicts with repository evidence, the repository evidence wins and the conflict is recorded or escalated through the existing role model.
- If memory is unavailable, agents proceed from repository sources and note that the memory-first shortcut could not be used.
- If a token actual is unavailable at closure, the closure must state why it was not captured rather than leaving the field ambiguous.
- Generated runtime candidates from M0/M1 are out of scope for M2 unless a later planning step explicitly chooses synchronization as a separate task.
- If M3-M9 topics surface during M2 work, they remain future-scope unless needed to define an M2 boundary or gate.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Task planning guidance MUST require every planned task to include a token budget band selected from tiny, small, medium, large, or XL.
- **FR-002**: Task planning guidance MUST define the intended use of each token budget band so reviewers can compare task scope against expected context cost.
- **FR-003**: Task planning guidance MUST require a just-in-time file list that names the first files an assignee should read before expanding context.
- **FR-004**: Task closure guidance MUST require a token actual field for material work using one accepted format: measured token count when available, actual budget band when exact count is unavailable, or an explicit not-captured reason.
- **FR-005**: Planning and review guidance MUST make token budget information visible before work starts and at closure.
- **FR-006**: XL tasks MUST be treated as split candidates unless explicitly accepted as oversized.
- **FR-007**: PM operating guidance MUST define a delta pass that prefers changed files, merged PR titles, current milestone rows, changed open-question rows, and risk/change deltas over full PM artifact rereads.
- **FR-008**: The PM delta pass MUST produce either a no-op confirmation or minimal edits to affected PM registers.
- **FR-009**: PM operating guidance MUST state when targeted fallback reads are allowed because delta inputs are insufficient, stale, or conflicting.
- **FR-010**: Binding memory guidance MUST prescribe memory queries before broad reads of old customer notes, old schedules, customer escalation history, or reopened ADR topics.
- **FR-011**: Memory guidance MUST provide concrete query-pattern examples for customer decisions, current milestone blockers, prior customer answers, and accepted ADRs.
- **FR-012**: Memory guidance MUST state that memory is pointer-only and repository artifacts remain the source of truth.
- **FR-013**: M2 guidance MUST preserve the existing role model: PM discipline remains a project-manager concern, customer-truth stewardship remains routed through researcher, and tech-lead remains the sole customer interface.
- **FR-014**: M2 MUST avoid implementing M3-M9 scopes except to document them as out-of-scope dependencies, assumptions, or gates.
- **FR-015**: M2 updates MUST be limited to canonical docs/templates only: task template, project-manager guidance, memory policy, tech-lead guidance, researcher guidance, and Spec Kit plan-pointer updates in AGENTS.md.

### Constitution Alignment *(mandatory)*

- **CA-001**: Source authority MUST be classified for affected artifacts as canonical, generated, or ephemeral.
- **CA-002**: Customer-owned requirements MUST cite a recorded customer answer, a documented assumption, or one queued atomic question.
- **CA-003**: Framework-managed file edits MUST be marked as framework work and require explicit authorization unless this feature is a template-maintenance task.
- **CA-004**: Cross-AI or generated-output changes MUST preserve existing role authority and identify canonical inputs.

### Key Entities *(include if feature involves data)*

- **Token Budget Band**: A planning label that describes expected context cost for a task: tiny, small, medium, large, or XL.
- **Just-in-Time File List**: The focused list of files an assignee should read first before expanding context.
- **Token Actual**: The closure-time record of actual token/context cost for material work, recorded as a measured token count when available, an actual budget band when exact count is unavailable, or an explicit not-captured reason.
- **PM Delta Pass**: A lightweight project-manager refresh based on changed files, merged PRs, current milestone state, open-question changes, and risk/change deltas.
- **PM Register**: A schedule, risk, change, lessons, or open-question artifact that may receive minimal updates from a PM delta pass.
- **Memory Query Pattern**: A prescribed search phrase or situation-specific lookup that points agents toward prior repository evidence.
- **Repository Source of Truth**: The canonical project artifact that confirms or overrides memory results.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of new task-planning entries include a token budget band, just-in-time file list, and token actual closure field.
- **SC-002**: 100% of XL task entries are either split before work starts or explicitly accepted as oversized in review.
- **SC-003**: A PM delta pass can be completed from changed-file, merged-PR, current-milestone, open-question, and risk/change deltas without a full PM artifact reread when those inputs are sufficient.
- **SC-004**: PM delta passes produce either a no-op confirmation or edits limited to affected PM register content.
- **SC-005**: Binding guidance includes memory-query patterns for old customer notes, old schedules, customer escalation or prior-answer checks, and reopened ADR topics.
- **SC-006**: 100% of memory guidance states or preserves that memory is pointer-only and repository artifacts remain authoritative.
- **SC-007**: Token budget information is visible in both planning and review for every material task produced under the M2 operating model.
- **SC-008**: Routine PM refreshes avoid broad rereads whenever delta inputs are sufficient, with fallback rereads limited to affected files and documented when used.

## Assumptions

- M2 applies to the sw-dev-team-template framework as template-maintenance work.
- M0/M1 artifacts from `specs/001-template-improvement-plan/` are complete enough to serve as the baseline for this next slice.
- The source milestone definition is M2 from `sw_dev_template_implementation_plan-1.md`.
- Token budgets are planning and review signals, not exact accounting guarantees.
- Existing binding docs and templates remain the expected home for task planning, project-manager cadence, and memory-query guidance; M2 changes are limited to the canonical task template, project-manager guidance, memory policy, tech-lead guidance, researcher guidance, and the AGENTS.md Spec Kit plan pointer.
- Generated runtime candidates from M0/M1 are excluded from M2 unless a later planning step explicitly chooses synchronization as a separate task.
- Memory systems are available as optional lookup aids but must not become canonical authority.
- M3-M9 remain out of scope for implementation in this feature except where they constrain M2 boundaries or later gates.
