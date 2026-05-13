# Feature Specification: M8-M10 Plan

**Feature Branch**: `004-m8-m10-plan`  
**Created**: 2026-05-13  
**Status**: Draft  
**Input**: User description: "use the new sw_dev_template_implementation_plan-2.md to plan the milestones M8, M9 and M10"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Plan Downstream Rollout (Priority: P1)

As the template maintainer, I need a milestone plan for safely applying the improved template to `QuackDCS`, `QuackPLC`, `QuackS7`, and `QuackSim`, so downstream repositories can be repaired without losing product/framework boundaries or live context hygiene.

**Why this priority**: M8 is the next source-plan milestone and is required before release readiness can be evaluated.

**Independent Test**: Review the plan for each named downstream repository and confirm it identifies classification, required repair outcomes, rollout gate outcomes, and accepted exception handling.

**Acceptance Scenarios**:

1. **Given** the four reference downstream repositories, **When** the M8 plan is reviewed, **Then** each repository is classified by scaffold mode and known rollout observations.
2. **Given** a downstream repository requiring repair, **When** the M8 plan is followed, **Then** the expected outcomes cover required framework file presence, intake-log availability, live-register archiving, roadmap quarantine or repair, PM surface sizing, question lint handling, and PM change-log recording.
3. **Given** a downstream repository cannot meet a rollout gate immediately, **When** the M8 plan is reviewed, **Then** the plan allows a documented exception or waiver rather than silently passing the gate.

---

### User Story 2 - Plan Release Readiness (Priority: P2)

As the template maintainer, I need a milestone plan for v1.0 readiness and release-candidate acceptance, so the template is released only after conformance, test, packaging, risk, onboarding, and process-readiness checks are complete.

**Why this priority**: M9 depends on M8 rollout evidence and defines the final release gate for the stable candidate.

**Independent Test**: Review the M9 plan and confirm it names all required audit perspectives, release criteria, and release-candidate approvals from the source plan.

**Acceptance Scenarios**:

1. **Given** rollout work is complete or exceptioned, **When** the M9 plan is reviewed, **Then** it includes conformance, scaffold/upgrade/retrofit testing, packaging/versioning/release notes, risk/schedule/change/lessons, zero-context usability, and process-debt audit perspectives.
2. **Given** a release candidate is proposed, **When** release criteria are evaluated, **Then** smoke tests, retrofit repair evidence, agent-contract lint, question lint, generated-artifact freshness, authority-drift status, model-routing guidance, and release-note classification are all covered.
3. **Given** release approval is evaluated, **When** the M9 gate is reviewed, **Then** code-review, QA, release mechanics, release-blocking risk, and customer approval requirements are explicitly represented.

---

### User Story 3 - Bound Undefined M10 Scope (Priority: P3)

As the template maintainer, I need the spec to handle the requested M10 scope honestly, so planning does not invent milestones absent from the authoritative source plan.

**Why this priority**: The user requested M8, M9, and M10, but the source plan defines M8 and M9 only; the spec must preserve source authority while keeping the planning request actionable.

**Independent Test**: Review the spec and confirm M10 is recorded as absent from the source plan and bounded to follow-up gap handling only.

**Acceptance Scenarios**:

1. **Given** the authoritative source plan has no M10 milestone, **When** the feature spec is reviewed, **Then** no invented M10 objectives, requirements, or acceptance gates appear.
2. **Given** later planning requires an M10 milestone, **When** the gap is evaluated, **Then** the plan requires a source-plan update or documented follow-up before adding M10 scope.

---

### Edge Cases

- A downstream repository may be inaccessible, moved, or otherwise unavailable during rollout planning; the plan must allow a documented exception with enough evidence to keep G8 review honest.
- A downstream repository may already satisfy some repair checks; the plan must allow verification without requiring unnecessary changes.
- Live context surfaces may exceed soft caps for historical reasons; the plan must require remediation, waiver, or documented historical exception.
- Atomic-question lint warnings may be historical rather than newly introduced; the plan must distinguish fixed warnings from documented historical exceptions.
- Customer approval may or may not be required by the release policy; the plan must treat that approval as conditional on the governing policy rather than unconditional.
- M10 is absent from the source plan; the spec must not define a new milestone without a later authoritative update.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The specification MUST define M8 as downstream rollout and retrofit repair for `QuackDCS`, `QuackPLC`, `QuackS7`, and `QuackSim`.
- **FR-002**: The specification MUST preserve the source-plan classification inputs for each reference repository, including scaffold mode and known observations.
- **FR-003**: The specification MUST require a per-repository repair sequence that covers repair checks, `docs/intake-log.md`, live-register archiving, upstream-template roadmap repair or quarantine, PM live/evidence surface sizing, question lint, and PM change-log recording.
- **FR-004**: The specification MUST require a per-repository rollout gate covering required framework files, live context soft caps or waivers, atomic-question lint disposition, and product/framework boundary compliance.
- **FR-005**: The specification MUST define G8 acceptance as all four reference repositories being repaired or explicitly exceptioned, rollout lessons being captured upstream, and scaffold smoke coverage reflecting downstream repair lessons.
- **FR-006**: The specification MUST define M9 as v1.0 readiness and release-candidate gate planning after prerequisite token, authority, question, routing, compiler, and rollout work is complete.
- **FR-007**: The specification MUST require release-readiness review coverage from code review, QA, release engineering, project management, onboarding audit, and process audit perspectives.
- **FR-008**: The specification MUST require release criteria covering fresh scaffold smoke tests, retrofit repair evidence, agent-contract lint, question lint, generated-artifact freshness, high-priority authority-drift status, current model-routing guidance, and release-note artifact classification.
- **FR-009**: The specification MUST define G9 acceptance as approval from code review, QA, release engineering, project management risk review, and customer approval when required by release policy.
- **FR-010**: The specification MUST record that M10 is not present in the authoritative source plan and MUST NOT add M10 milestone requirements without a later source-plan update.
- **FR-011**: The specification MUST express requirements and acceptance outcomes in terms of externally observable planning and gate outcomes, not implementation commands or tool-specific mechanics.

### Constitution Alignment *(mandatory)*

- **CA-001**: Source authority MUST be classified for affected artifacts as canonical, generated, or ephemeral.
- **CA-002**: Customer-owned requirements MUST cite a recorded customer answer, a documented assumption, or one queued atomic question.
- **CA-003**: Framework-managed file edits MUST be marked as framework work and require explicit authorization unless this feature is a template-maintenance task.
- **CA-004**: Cross-AI or generated-output changes MUST preserve existing role authority and identify canonical inputs.

### Key Entities *(include if feature involves data)*

- **Reference Repository**: One of the downstream repositories named in M8; key attributes are repository name, scaffold mode, known rollout observations, repair status, exception status, and rollout gate status.
- **Repair Outcome**: The observable result of downstream repair planning for one repository; key attributes are required-file status, intake-log status, live-register disposition, roadmap disposition, PM surface disposition, question-lint disposition, and PM change-log evidence.
- **Rollout Gate**: The acceptance checkpoint for one repository or the full downstream rollout; key attributes are pass criteria, exceptions or waivers, boundary compliance, and upstream lesson capture.
- **Release Readiness Audit**: The M9 review set for release-candidate acceptance; key attributes are reviewer perspective, audit outcome, blocking risks, and approval status.
- **Release Candidate Gate**: The final M9 acceptance checkpoint; key attributes are release criteria status, required approvals, customer-approval applicability, and unresolved blocker status.
- **M10 Gap**: The documented absence of an M10 milestone in the authoritative source plan; key attributes are source-plan evidence, bounded assumption, and required follow-up before scope can be added.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The completed spec contains zero template-stub markers and zero unresolved clarification markers.
- **SC-002**: All four reference downstream repositories from M8 are named and have testable rollout-planning expectations.
- **SC-003**: Every M8 rollout gate pass criterion from the source plan is represented by at least one requirement or acceptance scenario.
- **SC-004**: Every M9 release criterion and Gate G9 pass criterion from the source plan is represented by at least one requirement or acceptance scenario.
- **SC-005**: The spec records M10 absence exactly as a bounded source-plan gap and defines no invented M10 objective, gate, or deliverable.
- **SC-006**: A reviewer can determine pass, fail, or documented exception status for M8 and M9 without needing implementation-specific tooling knowledge.

## Assumptions

- `sw_dev_template_implementation_plan-2.md` is the canonical source for M8 and M9 planning scope.
- M10 is absent from the current source plan; this feature treats M10 as a documented planning gap, not an unstated milestone.
- This feature is template-maintenance planning work, so framework-managed artifact references are in scope when derived from the source plan.
- The named downstream repositories are the complete reference set for M8 unless the source plan is updated.
- Customer approval for G9 is required only if the template release policy requires it.
