# Feature Specification: v1.1 Handoff Contracts

**Feature Branch**: `012-v1-1-handoff-contracts`  
**Created**: 2026-05-27  
**Status**: Draft  
**Input**: User description: "implement v1.1 as laid out in the recently made 1.1 plan."

## Clarifications

### Session 2026-05-27

- Q: What fallback policy should v1.1 require when requested provider/model assignment is unavailable? -> A: Same-or-higher capability tier; otherwise pause/escalate.
- Q: What exact workflow set must pass with zero unresolved false positives before v1.1 gates can move from warning mode to enforce mode? -> A: Handoff create/update, allowed edit, forbidden edit, evidence acceptance, evidence rejection, bounded Codex, and model fallback.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Enforce Handoff and Path Scope (Priority: P1)

A team lead can start framework-maintenance work with a durable handoff that states the task owner, permitted work area, forbidden work area, and active scope so contributors know exactly what work is authorized.

**Why this priority**: This is the minimum viable contract surface. Without enforceable handoff and path scope, the existing role model remains advisory instead of operational.

**Independent Test**: Can be tested by reviewing an active framework-maintenance handoff and confirming it identifies the owner role, objective, allowed paths, forbidden paths, framework scope, and active handoff pointer.

**Acceptance Scenarios**:

1. **Given** a framework-maintenance task is active, **When** a contributor checks the handoff, **Then** they can identify the single durable handoff contract and the active handoff pointer that references it.
2. **Given** a proposed edit targets a forbidden path, **When** the edit is evaluated against the handoff, **Then** the forbidden path takes precedence over any broader allowed path.
3. **Given** product work and framework work have different path ownership rules, **When** the handoff declares its framework scope, **Then** reviewers can determine whether framework-managed paths are authorized for this task.

---

### User Story 2 - Require Evidence-Gated Completion (Priority: P2)

A reviewer can determine whether a task is complete from independent evidence rather than from the worker's self-attestation.

**Why this priority**: Completion claims are only reliable when test, review, security, and customer-truth gates are independently evidenced.

**Independent Test**: Can be tested by inspecting a handoff completion record and verifying that every required gate cites accepted evidence from the correct source.

**Acceptance Scenarios**:

1. **Given** a handoff requires test evidence, **When** completion is claimed, **Then** the completion record cites rerun evidence or hook-captured activity rather than the worker's statement alone.
2. **Given** a handoff requires code review or security review, **When** completion is claimed, **Then** the completion record cites artifacts owned by the required review role.
3. **Given** a handoff requires customer approval, **When** completion is claimed, **Then** the completion record cites a researcher-stewarded customer-truth record.

---

### User Story 3 - Bound Codex and Model Fallbacks (Priority: P3)

A team lead can allow narrowly bounded Codex execution or model fallback without weakening role ownership, path boundaries, evidence gates, or customer-truth rules.

**Why this priority**: Provider or model availability should not block safe work, but fallback behavior must remain traceable and limited.

**Independent Test**: Can be tested by reviewing a bounded-Codex handoff or fallback record and confirming the permitted action, path scope, evidence requirements, actual model class, capability-tier comparison, and fallback reason are recorded.

**Acceptance Scenarios**:

1. **Given** bounded Codex mode is not explicitly permitted, **When** top-level production authoring is attempted, **Then** the role contract still blocks the work.
2. **Given** bounded Codex mode is permitted, **When** work begins, **Then** the handoff identifies the exact role-owned action, allowed paths, forbidden paths, evidence requirements, and expiry or completion condition.
3. **Given** a requested provider or model assignment is unavailable, **When** fallback is used, **Then** the handoff or related record states the requested role, requested model class, actual model class, capability-tier comparison, and fallback reason.

---

### User Story 4 - Integrate llmdc and Speckit Without Bypasses (Priority: P4)

A planner can use llmdc and Speckit outputs as planning, documentation, coordination, or readiness inputs while preserving canonical role ownership and handoff authority.

**Why this priority**: Adjacent planning tools need explicit integration rules so they support the team model instead of bypassing it.

**Independent Test**: Can be tested by tracing llmdc or Speckit output to handoff fields, role ownership, and evidence limitations.

**Acceptance Scenarios**:

1. **Given** llmdc affects scope, path permissions, completion state, or evidence claims, **When** its output is used, **Then** it cites the active handoff and does not approve gates on its own.
2. **Given** Speckit generates specifications, plans, tasks, or readiness findings, **When** those artifacts feed active work, **Then** candidate work maps to canonical owner roles and durable handoff contracts.
3. **Given** Speckit surfaces a customer question, **When** the question is handled, **Then** the tech-lead customer-question rules still govern wording, batching, and customer contact.

---

### User Story 5 - Roll Out Warning to Enforce Readiness (Priority: P5)

A release owner can move v1.1 handoff gates from warning mode to enforce mode only after release readiness evidence shows ordinary workflows are not disrupted.

**Why this priority**: New enforcement must be introduced safely and with release-specific artifact lists rather than assumptions about project layout.

**Independent Test**: Can be tested by reviewing warning-mode evidence, named gate checks, and release handoff artifact lists before enforce mode is approved.

**Acceptance Scenarios**:

1. **Given** warning mode is active, **When** handoff create/update, allowed edit, forbidden edit, evidence acceptance, evidence rejection, bounded Codex, and model fallback workflows run, **Then** false positives are recorded and resolved before enforce mode becomes the default.
2. **Given** a release handoff is prepared, **When** readiness is reviewed, **Then** it cites exact release notes, checklist, review, security, test, migration, and customer-approval artifacts required for that project.
3. **Given** enforce mode is proposed, **When** readiness evidence is incomplete, **Then** the feature remains in warning mode.

### Edge Cases

- An active handoff pointer exists but references a missing, inactive, malformed, or contradictory durable handoff.
- Allowed paths and forbidden paths overlap; forbidden paths must prevail.
- A handoff permits framework-maintenance work but omits required review or evidence gates.
- A worker attempts to satisfy required evidence with their own completion summary.
- A provider or model assignment fails and no acceptable fallback is available.
- llmdc or Speckit output attempts to mark work complete, approve evidence, or record customer truth without the owning role.
- A downstream project lacks a root changelog and requires release handoff artifact lists instead.
- Warning-mode telemetry shows false positives for common workflows.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST define durable handoff contracts for coherent tasks and release handoffs, including objective, owner role, review roles, security roles, status, scope, acceptance criteria, required evidence, verification state, completion state, and gate mode.
- **FR-002**: The system MUST maintain a single active handoff pointer that references the durable handoff contract and is not treated as a second source of truth.
- **FR-003**: The system MUST represent path scope with allowed paths and forbidden paths, and forbidden paths MUST override any broader allowed path.
- **FR-004**: The system MUST preserve framework/product boundary rules and require framework-maintenance scope before framework-managed paths are authorized.
- **FR-005**: The system MUST prevent completion from being accepted unless all required independent evidence gates are satisfied.
- **FR-006**: The system MUST distinguish worker reports from accepted evidence for tests, reviews, security approval, human approval, and customer-truth records.
- **FR-007**: The system MUST require test evidence to come from rerun evidence or hook-captured activity rather than worker self-attestation alone.
- **FR-008**: The system MUST require code-review evidence from code-reviewer-owned artifacts when a handoff requires review.
- **FR-009**: The system MUST require security-review evidence from security-engineer-owned artifacts when a handoff requires security review.
- **FR-010**: The system MUST require human approval and customer-truth evidence to come from researcher-stewarded records.
- **FR-011**: The system MUST preserve traceability from enforceable gates to original hard rules by citing source rules with stable hard-rule identifiers.
- **FR-012**: The system MUST classify each hard rule affected by v1.1 as semantic-only, hook-enforceable, evidence-gated, customer-approval-gated, or a documented combination of those categories.
- **FR-013**: The system MUST allow bounded Codex mode only when the active handoff explicitly permits it.
- **FR-014**: A bounded-Codex handoff MUST state the permitted role-owned action, exact allowed paths, forbidden paths, required evidence, and expiry or completion condition.
- **FR-015**: Bounded Codex mode MUST NOT waive role ownership, evidence gates, path boundaries, customer-truth stewardship, or framework-managed path rules.
- **FR-016**: The system MUST record requested role, requested model class, actual model class, capability-tier comparison, and fallback reason whenever a provider or model assignment fallback is used.
- **FR-017**: The model assignment failsafe MUST preserve role authority and output obligations, and MUST allow fallback only to the same-or-higher capability tier; otherwise it MUST require pause or escalation.
- **FR-018**: The system MUST define llmdc's supported role as a planning, documentation, evidence, or coordination helper before llmdc is treated as a supported coordination surface.
- **FR-019**: llmdc activity that affects task scope, path permissions, completion state, or evidence claims MUST cite the active handoff.
- **FR-020**: llmdc output MUST NOT mark role-owned work complete, approve evidence gates, or record customer truth on its own.
- **FR-021**: The system MUST model Speckit artifacts as planning and specification inputs that feed canonical roles and handoffs rather than bypassing role routing.
- **FR-022**: Speckit-derived tasks MUST map candidate work to canonical owner roles and, when active work starts, to durable handoff contracts.
- **FR-023**: Speckit analysis and checklist findings MAY become acceptance criteria, checklist items, or review inputs, but MUST NOT count as final evidence by themselves.
- **FR-024**: Release handoffs MUST cite project-specific artifact lists for release notes, checklist, review, security, test, migration, and customer-approval evidence instead of assuming a conventional root changelog.
- **FR-025**: The system MUST support warning mode before enforce mode and require downstream smoke evidence with no unresolved false positives across handoff create/update, allowed edit, forbidden edit, evidence acceptance, evidence rejection, bounded Codex, and model fallback workflows before enforce mode becomes the v1.1 default.
- **FR-026**: The release readiness process MUST include named checks for handoff pre-tool gating, task-completion gating, bounded Codex gating, and framework path-boundary behavior.
- **FR-027**: The system MUST reject or flag top-level stop or task completion when the active handoff is internally inconsistent, incomplete, or contradicts recorded gate state.

### Constitution Alignment *(mandatory)*

- **CA-001**: Source authority MUST be classified for affected artifacts as canonical, generated, or ephemeral.
- **CA-002**: Customer-owned requirements MUST cite a recorded customer answer, a documented assumption, or one queued atomic question.
- **CA-003**: Framework-managed file edits MUST be marked as framework work and require explicit authorization unless this feature is a template-maintenance task.
- **CA-004**: Cross-AI or generated-output changes MUST preserve existing role authority and identify canonical inputs.

### Key Entities *(include if feature involves data)*

- **Durable Handoff Contract**: The task or release contract that records ownership, scope, requirements, evidence gates, verification state, and completion state.
- **Active Handoff Pointer**: The current-work pointer that references one durable handoff contract and does not redefine its contents.
- **Role Owner**: The canonical role responsible for the task's primary output.
- **Review Role**: A canonical role required to provide independent review evidence.
- **Security Role**: A canonical role required to provide independent security evidence when security review is required.
- **Path Scope**: The allowed and forbidden path declarations that determine whether work is in bounds.
- **Framework Scope**: The classification that distinguishes framework-maintenance work from downstream product work.
- **Evidence Gate**: A completion requirement that must be satisfied by accepted independent evidence.
- **Hard-Rule Trace**: A stable link from an enforceable gate or requirement back to its source hard-rule identifier.
- **Bounded Codex Exception**: A narrow, handoff-scoped permission for a top-level Codex action that does not change role ownership.
- **Model Fallback Record**: The record of requested role, requested model class, actual model class, capability-tier comparison, and fallback reason when provider or model assignment changes.
- **llmdc Activity**: A planning, documentation, evidence, or coordination output that may affect handoff-related decisions but does not own approvals.
- **Speckit Artifact**: A specification, plan, task list, analysis, or checklist artifact that feeds role-owned work and durable handoffs.
- **Release Artifact List**: The project-specific set of evidence artifacts required for a release handoff.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of active v1.1 framework-maintenance tasks have one durable handoff contract and one active handoff pointer before work is accepted as started.
- **SC-002**: 100% of handoff contracts reviewed for release readiness identify owner role, path scope, forbidden paths, required evidence, and completion criteria.
- **SC-003**: 0 completion records are accepted when required test, review, security, or customer-truth evidence is missing or self-attested by the worker.
- **SC-004**: 100% of enforceable v1.1 gates cite a hard-rule identifier or a documented v1.1 requirement source.
- **SC-005**: 100% of bounded-Codex exceptions expire or close through an explicit completion condition recorded in the handoff.
- **SC-006**: 100% of provider or model fallback events used for specialist work record requested role, requested model class, actual model class, capability-tier comparison, and fallback reason, with no fallback to a lower capability tier.
- **SC-007**: 100% of llmdc and Speckit outputs that affect active scope, completion, or evidence can be traced to a canonical role owner and active handoff.
- **SC-008**: Enforce mode is not enabled until warning-mode evidence shows zero unresolved false positives across handoff create/update, allowed edit, forbidden edit, evidence acceptance, evidence rejection, bounded Codex, and model fallback workflows.
- **SC-009**: 100% of release handoffs reviewed for v1.1 readiness use explicit artifact lists rather than relying on an assumed root changelog.

## Assumptions

- This feature is template-maintenance work for v1.1 handoff contracts.
- The existing role model remains canonical: tech-lead orchestrates, specialists own role-specific production artifacts, and Claude Code and Codex are harnesses rather than roles.
- The v1.1 plan is the authoritative source for this specification's initial scope.
- Open planning questions from the v1.1 plan are treated as planning-phase decisions unless they block the stakeholder-level specification.
- Warning mode precedes enforce mode for new gates.
- Release readiness is project-specific and cannot assume a conventional root changelog.
