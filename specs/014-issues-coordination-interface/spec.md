# Feature Specification: Issues-Based Multi-Machine Coordination Interface

**Feature Branch**: `014-issues-coordination-interface`  
**Created**: 2026-05-27  
**Status**: Draft  
**Input**: User description: "Issues-based multi-machine coordination interface — the v1.1.0 'Half B' deliverable, per FW-ADR-0020, adopted by the customer 2026-05-27. An opt-in, additive GitHub-Issues-native coordination layer (not GitHub Projects) so multiple operators can run the agent set from different machines while staying aligned on bounded task scope, evidence, and issue-backed work queues."

## Clarifications

### Session 2026-05-27

- Q: Add the optional `github_issue` field to the handoff record/schema in v1.1.0, or defer to a patch? (Q-0017) → A: **Add now** — an optional `github_issue` field on the durable handoff record and `handoff.schema.json`, making the issue↔handoff link bidirectional and machine-checkable.
- Q: Require a live two-operator/two-machine smoke before v1.1.0 exit, or pre-authorize single-operator deferral? (Q-0018) → A: **Deferral pre-authorized** — a single-operator + simulated-concurrency smoke (claim/collision/yield/release) satisfies v1.1.0 exit; the live two-operator/two-machine test is a recorded, deferred follow-up.
- Q: Amend `scaffold.sh` to gitignore `.devteam/active-handoff.json` in v1.1.0, or leave unchanged? (Q-0019) → A: **Amend scaffold** — scaffolded downstream projects gitignore `.devteam/active-handoff.json` (per-machine/per-session local pointer; not shared truth). The template's own committed example handoff is unaffected.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Claim a task across machines without collisions (Priority: P1)

Two operators running the agent set on different machines need to pick up work from a shared queue of GitHub issues without both grabbing the same task. An operator "checks out" an issue, and a second operator can see it is taken; if both try at nearly the same instant, a deterministic rule decides the winner and the loser steps back cleanly.

**Why this priority**: This is the core value and the hardest part — GitHub has no atomic lock, so a safe, deterministic claim/checkout convention is what makes multi-machine coordination usable at all. Without it the rest is just labels.

**Independent Test**: Simulate two claim attempts on the same issue; confirm exactly one ends up holding the claim (self-assign + claimed status + claim record), the other yields and re-queues, and the resolution is deterministic and reproducible.

**Acceptance Scenarios**:

1. **Given** an unclaimed issue, **When** an operator claims it, **Then** the issue is self-assigned, carries the claimed status, and has a structured claim record (operator, machine, session, UTC timestamp), and other operators can see it is claimed.
2. **Given** two operators claim the same issue near-simultaneously, **When** the tie-break rule is applied, **Then** exactly one operator holds the claim and the other records a yield and returns the issue to the queue — and the outcome is the same regardless of which operator's view is inspected.
3. **Given** an operator finishes or hands back a claimed task, **When** they release it, **Then** the claim is cleared (status/assignment/record) so the issue is reclaimable, with the release recorded.
4. **Given** the claim convention, **When** documented, **Then** it is explicitly described as advisory/optimistic (best-effort), not a hard lock, with the residual race window bounded and stated.

---

### User Story 2 - Coordinate work via issues, labels, and milestones (Priority: P2)

Operators need shared, at-a-glance state for each task: what it is, who owns it (which specialist role), its status, priority, blocked state, and which release it belongs to — using GitHub-native primitives any downstream repo already has.

**Why this priority**: The label/milestone convention is the shared vocabulary the claim mechanism and the work queue ride on. It is second because it is meaningful only once tasks can be claimed (US1), but it is broad and reused by every later story.

**Independent Test**: Apply the documented label taxonomy + milestone convention to a set of issues and confirm status, role routing, priority, blocked state, and release grouping are each unambiguously readable from the issue, and that one issue maps to exactly one durable handoff.

**Acceptance Scenarios**:

1. **Given** the documented label taxonomy, **When** an issue is labeled, **Then** its status, owning specialist role, priority, and any blocked/meta state are each derivable from labels alone.
2. **Given** a coherent task, **When** it is represented, **Then** it maps to exactly one GitHub issue and one durable handoff record, with a defined rule for which artifact is authoritative for which kind of state.
3. **Given** a release, **When** issues are grouped, **Then** a milestone collects the issues targeted at that release.

---

### User Story 3 - Record progress and handoffs as issue comments without weakening evidence gates (Priority: P3)

Operators record progress, blockers, and handbacks as structured issue comments so anyone on any machine can reconstruct the task history — but these comments must never substitute for the real evidence gates.

**Why this priority**: Comments make the coordination auditable across machines, but they layer on top of US1/US2 and must explicitly preserve the existing evidence model, so they come after the queue and claim mechanics exist.

**Independent Test**: Record the structured comment types on an issue and confirm the task history is reconstructable from comments alone, AND confirm that no comment satisfies a completion/review/security/customer-truth evidence gate (the hook-captured evidence remains the binding source).

**Acceptance Scenarios**:

1. **Given** the structured comment types (claim, yield, progress, handback, gate-passed, blocked), **When** used on an issue, **Then** the task's claim/progress/handback history is reconstructable from the issue alone.
2. **Given** a "gate-passed" comment, **When** completion is evaluated, **Then** it does not by itself satisfy any evidence gate; the binding evidence remains the hook-captured verification record and role-owned artifacts.

---

### User Story 4 - A fresh downstream project can adopt the interface opt-in (Priority: P4)

A new downstream project's operator can stand up the coordination interface (labels, milestones, issue/task templates) from a setup guide without hand-editing template internals — and a single-operator or offline project can ignore it entirely with no penalty.

**Why this priority**: Adoptability is what makes the convention reusable beyond this repo, but it depends on the taxonomy/templates/operating-model from the earlier stories existing first.

**Independent Test**: Following the setup guide on a fresh repo produces the full label set, milestone convention, and issue/task templates with no manual template-internal edits; and a project that skips setup operates normally with no errors or required coordination state.

**Acceptance Scenarios**:

1. **Given** the setup guide, **When** a fresh project follows it, **Then** the documented labels, milestone convention, and at least the agent-task and agent-review-request issue templates exist, created via standard GitHub CLI commands.
2. **Given** a single-operator or offline project, **When** it does not adopt the interface, **Then** the agent workflow operates normally and nothing requires GitHub issues, labels, or the claim convention.
3. **Given** the in-repo registers (open-questions, decisions, PM artifacts), **When** the interface is in use, **Then** a documented authority table states which artifact is authoritative for which state, and the registers remain the binding records (not replaced by issues).

---

### Edge Cases

- Two operators with identical claim timestamps → deterministic secondary tie-break (no ambiguity).
- A claim is posted but the operator crashes before working → the stale claim is detectable and reclaimable (documented recovery), without a hard lock.
- An operator on a machine with a skewed clock posts a claim timestamp → the tie-break must not silently let clock skew hand a contested claim to the wrong operator (documented mitigation/assumption).
- An issue with no role label, or conflicting role labels → defined handling (unrouted/needs-triage).
- A downstream project deletes or renames a status/role label → the operating model degrades gracefully (documented), not silently mis-routes.
- A task spans multiple issues, or one issue covers multiple tasks → the one-issue-per-task rule and what to do when it is violated.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The interface MUST define an advisory issue claim ("checkout") convention combining self-assignment, a claimed status indicator, and a structured claim record (operator id, machine, session id, UTC timestamp) that doubles as the first handoff record.
- **FR-002**: The claim convention MUST define a deterministic collision tie-break for near-simultaneous claims (a primary rule plus a secondary rule for equal primary keys) such that exactly one operator holds the claim and the resolution is identical from any observer's view.
- **FR-003**: The claim convention MUST define the loser's behavior on collision: record a yield, clear its assignment/status, and return the issue to the queue; and MUST tie the held claim to the local active-handoff pointer.
- **FR-004**: The claim convention MUST define a release/handback sequence that clears the claim so the issue is reclaimable, and MUST be documented as advisory (best-effort), not a hard lock, with the residual race window bounded and stated.
- **FR-005**: The interface MUST define a minimal label taxonomy covering status (queued, claimed, in-progress, in-review, blocked, done), specialist-role routing (one per canonical roster role), priority, and meta states (e.g. framework-maintenance, customer-approval-required, security-review-required, blocked-external), plus a milestone convention for release grouping.
- **FR-006**: The interface MUST define a one-issue-per-coherent-task ↔ one-durable-handoff mapping and state which artifact is authoritative for which kind of state.
- **FR-007**: The interface MUST define structured issue-comment types for claim, yield, progress, handback, gate-passed, and blocked, sufficient to reconstruct a task's coordination history from the issue alone.
- **FR-008**: Issue comments (including a "gate-passed" comment) MUST NOT satisfy any evidence gate; the binding evidence remains the hook-captured verification record and role-owned artifacts, and role ownership / the sole-customer-interface rule are preserved.
- **FR-009**: The interface MUST provide a multi-machine operating-model document (one issue per task, comments as handoff records, labels for routing, milestones for release; only the lead interface talks to the customer; opt-in/additive).
- **FR-010**: The interface MUST provide a register-sync authority table mapping each kind of state to its authoritative record across the in-repo registers and the GitHub issues/labels/milestones, preserving that the in-repo registers are not replaced as binding records.
- **FR-011**: The interface MUST provide at least two agent-routed issue/task templates (an agent-task template and an agent-review-request template) supporting intake→review: trigger annotation, prior-art/proposal links, acceptance criteria, review owner, release-note impact, and role routing.
- **FR-012**: The interface MUST integrate the model-routing guidance into the multi-operator playbook (when to use plan mode, raise model tier, or increase reasoning effort) and map it to labels/fields where useful.
- **FR-013**: A fresh downstream project MUST be able to create the full label set, milestone convention, and issue/task templates by following a setup guide / command transcript without hand-editing template internals.
- **FR-014**: The interface MUST be opt-in and additive: single-operator and offline downstream projects MUST be able to operate normally without adopting any of it.
- **FR-015**: Governance — FW-ADR-0020 MUST be moved from Proposed to Accepted and the ROADMAP v1.1.0 "Half B" exit criteria MUST be amended from the GitHub Projects framing to the issues-based framing per the ADR's recorded before/after wording.
- **FR-016**: The coordination model MUST be validated by a smoke covering the claim, collision/yield, and release flows. For v1.1.0 a single-operator + simulated-concurrency smoke satisfies this exit criterion; the live two-operator/two-machine test is deferred as a recorded follow-up (customer ruling Q-0018, 2026-05-27).
- **FR-017**: The durable handoff record and `handoff.schema.json` MUST gain an OPTIONAL `github_issue` field that links a handoff to its coordination issue, making the issue↔handoff mapping (FR-006) bidirectional and machine-checkable. The field is optional so existing handoffs and single-operator/offline projects remain valid without it (customer ruling Q-0017, 2026-05-27).
- **FR-018**: `scripts/scaffold.sh` MUST be amended so scaffolded downstream projects gitignore `.devteam/active-handoff.json` (a per-machine/per-session local pointer, not shared truth), preventing cross-machine churn/conflicts. The template repository's own committed example handoff is unaffected (customer ruling Q-0019, 2026-05-27).

### Constitution Alignment *(mandatory)*

- **CA-001**: Source authority — `ROADMAP.md`, `docs/adr/fw-adr-0020-*.md`, `.github/ISSUE_TEMPLATE/*`, the operating-model/setup docs, and any `scripts/` setup transcript are canonical framework-managed artifacts; this spec/plan/tasks are generated planning artifacts; GitHub issues/labels are runtime coordination state, not binding repo records.
- **CA-002**: Customer-owned requirements — adoption was ruled by the customer 2026-05-27 (OPEN_QUESTIONS Q-0016). Three sub-rulings remain open and are flagged as the three `[NEEDS CLARIFICATION]` markers (Q-0017/Q-0018/Q-0019) to be resolved in `/speckit-clarify`; no other customer-owned requirement is unresolved.
- **CA-003**: Framework-managed edits — this is template-maintenance work in `sw-dev-team-template` (`.github/ISSUE_TEMPLATE/`, `docs/`, `ROADMAP.md`, the FW-ADR, `schemas/handoff.schema.json` if Q-0017=yes, `scripts/scaffold.sh` if Q-0019=yes), authorized by the customer's v1.1.0 Half-B decision.
- **CA-004**: Adapter discipline — GitHub Issues/labels are an additive coordination surface; they MUST NOT create a parallel authority or a second customer-interface path, and MUST preserve the canonical role model and the sole-customer-interface rule.

### Key Entities

- **Coordination issue**: a GitHub issue representing one coherent task; carries status/role/priority/meta labels, a milestone, an issue↔handoff link, and a comment trail.
- **Claim record**: the structured claim (operator, machine, session, UTC timestamp) asserting an advisory checkout of an issue; basis for the tie-break.
- **Label taxonomy**: the status / role / priority / meta label set and milestone convention.
- **Structured comment**: a typed issue comment (claim/yield/progress/handback/gate-passed/blocked) forming the reconstructable coordination history.
- **Register-authority mapping**: the table of which artifact (in-repo register vs GitHub issue/label/milestone) is authoritative for which state.
- **Setup surface**: the labels/milestones/templates a fresh project creates to adopt the interface.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In a contested-claim scenario, exactly one operator holds the claim and the other yields, with a deterministic, reproducible outcome independent of which operator's view is inspected (0 double-claims across the smoke).
- **SC-002**: An operator can determine a task's status, owning role, priority, blocked state, and target release from its issue's labels/milestone alone, without reading the issue body or external docs.
- **SC-003**: A task's claim → progress → handback/release history is fully reconstructable from the issue's structured comments alone.
- **SC-004**: No issue comment can satisfy an evidence gate — completion still requires the hook-captured/role-owned evidence — demonstrated by a check that a "gate-passed" comment alone does not pass the completion gate.
- **SC-005**: Following the setup guide on a fresh repository produces the complete label set, milestone convention, and the two issue templates with zero hand-edits of template internals; and a project that skips setup runs the normal workflow with zero coordination-state requirements.
- **SC-006**: The v1.1.0 Half-B exit criteria in ROADMAP.md and FW-ADR-0020's status reflect the issues-based model (governance recorded), and the coordination smoke (claim/collision/release) passes at the agreed validation threshold.

## Assumptions

- The coordination layer is GitHub-Issues-native (labels, milestones, assignees, comments) via the GitHub CLI; GitHub Projects boards are explicitly out of scope (superseded by FW-ADR-0020).
- The claim mechanism is advisory/optimistic by necessity (no atomic lock primitive exists in GitHub Issues); "correctness" means a deterministic tie-break and bounded race window, not a hard mutual-exclusion guarantee.
- Operator/machine/session identifiers are available to label a claim record; exact identity sourcing is an implementation detail for the plan.
- The interface is additive and opt-in; the handoff-contract spine (feature 012, v1.1.0 Half A) is the binding mechanism and is unchanged by this feature except for the optional `github_issue` link pending Q-0017.
- The in-repo registers (open-questions, decisions, PM artifacts) remain the binding project records; GitHub issues never become the authoritative store for customer truth, decisions, or open questions.
- Live two-operator/two-machine testing may not be feasible in the current environment; FR-016 carries the deferral question (Q-0018).
