# Feature Specification: Remaining Milestones M3-M9

**Feature Branch**: `003-remaining-milestones`
**Created**: 2026-05-12
**Status**: Draft
**Input**: User description: "the rest of the milestones so you can work while I am asleep."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Prepare Safe Overnight Milestone Plan (Priority: P1)

The customer needs the remaining M3-M9 milestone work translated into a complete Spec Kit specification so `tech-lead` can govern overnight planning without collapsing the rest of the program into one unsafe implementation task.

**Why this priority**: The immediate value is a bounded, reviewable plan for continued work while the customer is unavailable, with clear gates that prevent broad unsupervised implementation.

**Independent Test**: Can be tested by reviewing this specification and confirming it covers M3-M9, preserves milestone gates, and keeps implementation deferred to later `/speckit.plan` and task routing.

**Acceptance Scenarios**:

1. **Given** M0/M1 and M2 are complete, **When** the remaining program is specified, **Then** M3 through M9 are represented as gated planning scope.
2. **Given** agents work while the customer is asleep, **When** the plan encounters customer-owned uncertainty, **Then** work uses assumptions or queues atomic questions rather than asking compound questions or blocking all progress.
3. **Given** the remaining milestones are broad, **When** planning proceeds, **Then** delivery is separated into independently reviewable tranches instead of one combined implementation task.

---

### User Story 2 - Establish Intake, Authority, And Routing Foundations (Priority: P2)

Template maintainers need the next planning tranche to cover atomic customer questions, intake traceability, documentation authority, drift control, and cross-AI routing before compiler or automation work depends on them.

**Why this priority**: M3-M5 define the governance foundations that later runtime compilation, self-improvement, and downstream rollout must obey.

**Independent Test**: Can be tested by confirming the planned scope includes M3 atomic-question/intake repair, M4 documentation authority/drift control, and M5 cross-AI routing as separate gated outcomes.

**Acceptance Scenarios**:

1. **Given** scoping and follow-up questions may contain multiple decision axes, **When** M3 is planned, **Then** seed questions, batching guidance, customer-question gates, linting, and intake logs are covered.
2. **Given** documentation mirrors can drift, **When** M4 is planned, **Then** canonical, generated, and ephemeral authority rules plus roadmap, model-routing, and workflow-pipeline status are covered.
3. **Given** OpenCode, Gemini, Codex, and Claude support is desired, **When** M5 is planned, **Then** they are treated as harness or provider adapters over the existing role model.

---

### User Story 3 - Plan Runtime Generation And Controlled Self-Improvement (Priority: P3)

Template maintainers need compiler, generated-artifact, prompt-regression, issue-taxonomy, and self-improvement work planned only after source authority and routing rules are in place.

**Why this priority**: M6 and M7 can reduce context and improve the template safely only if generated outputs remain non-canonical and automation is constrained to reviewable changes.

**Independent Test**: Can be tested by verifying M6 and M7 requirements preserve source authority, require reproducibility and checks, and prevent direct protected-file or main-branch changes.

**Acceptance Scenarios**:

1. **Given** runtime contracts may be generated from canonical sources, **When** M6 is planned, **Then** schemas, linting, compilation, and prompt-regression checks are required before generated outputs are accepted.
2. **Given** issues may drive template improvement, **When** M7 is planned, **Then** issue taxonomy, framework-gap intake, PR-only improvement flow, and action hardening are required.
3. **Given** generated or automated changes may drift from source, **When** review occurs, **Then** drift produces a failure, no-op, or issue rather than silently changing authority.

---

### User Story 4 - Prepare Downstream Rollout And Release Readiness (Priority: P4)

Template maintainers need downstream rollout and v1.0 release readiness planned as the final tranche, after core template controls have passed their gates.

**Why this priority**: Applying the template to reference repositories and preparing release requires prior controls for intake, authority, routing, generated artifacts, and self-improvement.

**Independent Test**: Can be tested by confirming M8 and M9 define per-repository rollout gates, release criteria, role approvals, and release-blocking risk handling.

**Acceptance Scenarios**:

1. **Given** the reference downstream repositories have different scaffold and retrofit states, **When** M8 is planned, **Then** each repository receives classification, repair sequencing, rollout gates, and documented exceptions where needed.
2. **Given** release readiness depends on multiple role approvals, **When** M9 is planned, **Then** conformance audit, scaffold/upgrade/retrofit validation, generated-artifact freshness, and release mechanics are covered.
3. **Given** release approval may depend on policy, **When** M9 completes, **Then** customer approval is obtained only if required by the template release policy.

### Edge Cases

- If a milestone exposes a customer-owned decision while the customer is unavailable, the team must record an assumption or queue one atomic question and continue only on safe, reversible work.
- If any milestone would require broad edits across unrelated gates, planning must split the work into smaller gated increments.
- If Spec Kit output conflicts with `CLAUDE.md`, `AGENTS.md`, the constitution, or canonical role files, the canonical sw-dev team contract wins and the conflict must be routed for review.
- If generated artifacts are needed before M6 is accepted, they must remain candidate or ephemeral and must not become source of truth.
- If downstream rollout reveals product-specific risks, those risks must be documented per repository rather than patched as framework changes without approval.
- If exact provider model IDs are stale or unavailable, planning may use model classes but release readiness must require runtime verification.
- If automation cannot safely produce a change, it must produce a no-op, issue, or blocked status rather than a broken commit.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The feature MUST specify remaining milestones M3 through M9 from `sw_dev_template_implementation_plan-1.md` as a framework-maintenance program plan.
- **FR-002**: The feature MUST NOT implement M3-M9 directly; it MUST prepare the scope for subsequent `/speckit.plan`, task generation, specialist routing, review, and gated execution.
- **FR-003**: The feature MUST preserve delivery gates G3 through G9 as separate acceptance boundaries.
- **FR-004**: The feature MUST split remaining work into independently reviewable tranches so overnight work can proceed without one unsafe all-in-one implementation task.
- **FR-005**: M3 scope MUST cover atomic scoping seed questions, consistent internal-vs-customer-facing batching guidance, a Customer Question Gate, atomic-question linting, and scaffold/repair intake-log coverage.
- **FR-006**: M3 acceptance MUST require atomic seed questions, an active customer-question gate, linting that flags known bad historical patterns, and `docs/intake-log.md` presence in fresh scaffold and repaired downstream contexts.
- **FR-007**: M4 scope MUST cover documentation authority classification, manual mirror prevention, downstream root roadmap leakage, model-routing binding status, and canonical workflow-pipeline rule placement.
- **FR-008**: M4 acceptance MUST require an authority policy, roadmap leakage resolution, clarified model-routing status, and shipped canonical workflow-pipeline rules where binding rules exist.
- **FR-009**: M5 scope MUST cover cross-AI routing for OpenCode, Gemini, Codex, and Claude as adapters over the existing sw-dev role model.
- **FR-010**: M5 acceptance MUST require an adapter decision record, documented model routing and fallback behavior, fallback logging, thin generated or generator-backed adapters, and no parallel role model.
- **FR-011**: M6 scope MUST cover agent-contract, model-routing, and generated-artifact schema expectations; contract linting; runtime compilation; generated adapter/session-start candidates; token or line reporting; and prompt regression tests.
- **FR-012**: M6 acceptance MUST require schema validation, stable reproducible generated files, passing prompt-regression tests, and canonical source files remaining authoritative.
- **FR-013**: M7 scope MUST cover issue taxonomy, framework-gap issue intake, one-improvement-at-a-time AI workflow, PR-only automation, patch-size limits, generated-artifact drift checks, human review, and CI hardening.
- **FR-014**: M7 acceptance MUST require taxonomy availability, PR-only AI loop behavior, contract checks before PR creation, and safe no-op or issue behavior on failure.
- **FR-015**: M8 scope MUST cover downstream classification and repair sequencing for `QuackDCS`, `QuackPLC`, `QuackS7`, and `QuackSim`.
- **FR-016**: M8 acceptance MUST require all four reference repositories to be repaired or explicitly excepted, rollout lessons captured upstream, and scaffold smoke tests updated from rollout lessons.
- **FR-017**: M9 scope MUST cover final conformance audit, scaffold/upgrade/retrofit validation, release mechanics, final PM risk/schedule/change/lessons updates, zero-context usability review, and process-debt retirement review.
- **FR-018**: M9 acceptance MUST require approvals from code-reviewer, qa-engineer, release-engineer, and project-manager release-risk review, plus customer approval if required by release policy.
- **FR-019**: Spec Kit outputs MUST be treated as candidate artifacts governed by `tech-lead`, not as final authority or direct customer-facing output.
- **FR-020**: Spec Kit-generated implementation, plan, task, checklist, or issue-conversion output MUST be routed through the existing sw-dev role model and quality gates before becoming authoritative.
- **FR-021**: Customer-owned questions arising from planning MUST be atomic, queued when the customer is unavailable, and recorded through the existing intake and researcher stewardship flow.
- **FR-022**: Framework-managed file edits planned by this feature MUST remain marked as framework/template-maintenance work and must not be mixed with downstream product changes unless explicitly authorized.

### Constitution Alignment *(mandatory)*

- **CA-001**: Source authority MUST be classified for affected artifacts as canonical, generated, or ephemeral.
- **CA-002**: Customer-owned requirements MUST cite a recorded customer answer, a documented assumption, or one queued atomic question.
- **CA-003**: Framework-managed file edits MUST be marked as framework work and require explicit authorization unless this feature is a template-maintenance task.
- **CA-004**: Cross-AI or generated-output changes MUST preserve existing role authority and identify canonical inputs.

### Key Entities *(include if feature involves data)*

- **Remaining Milestone**: One of M3 through M9, each with objective, scope, acceptance expectations, and a gate.
- **Milestone Gate**: A pass boundary from G3 through G9 that prevents later work from depending on incomplete governance, routing, compiler, rollout, or release controls.
- **Delivery Tranche**: A group of related milestones that can be planned, reviewed, and executed independently from other tranches.
- **Spec Kit Candidate Artifact**: Draft output from Spec Kit that must return to `tech-lead` for routing, role review, and gate enforcement before becoming authoritative.
- **Framework Maintenance Change**: A change to template-managed guidance, scripts, schemas, adapters, workflows, or release artifacts rather than a downstream product change.
- **Reference Downstream Repository**: One of `QuackDCS`, `QuackPLC`, `QuackS7`, or `QuackSim`, used to validate rollout and retrofit behavior.
- **Release Readiness Evidence**: Role approvals, validation results, generated-artifact freshness, unresolved-risk status, and any required customer approval for v1.0 readiness.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of milestones M3 through M9 are represented with testable scope and acceptance requirements.
- **SC-002**: 100% of gates G3 through G9 remain separate and reviewable before dependent later work proceeds.
- **SC-003**: The resulting plan can be decomposed into at least four independently reviewable delivery tranches: M3-M5 foundations, M6 runtime generation, M7 self-improvement, and M8-M9 rollout/release.
- **SC-004**: 100% of customer-owned uncertainties identified during overnight planning are handled as assumptions or queued atomic questions, not compound customer-facing asks.
- **SC-005**: 100% of cross-AI and generated-output requirements preserve the existing role model and canonical-source authority.
- **SC-006**: Downstream rollout readiness is measurable for all four reference repositories through repaired-or-excepted status.
- **SC-007**: Release readiness is measurable through named role approvals, release-risk status, validation criteria, and required customer approval status.
- **SC-008**: No planned work item requires direct implementation of multiple milestone gates in one unreviewable task.

## Assumptions

- This feature is framework-maintenance/template-maintenance work explicitly authorized by the relayed request to plan the remaining milestones.
- M0/M1 and M2 are complete enough to serve as the baseline for M3-M9 planning.
- `sw_dev_template_implementation_plan-1.md` is the canonical source for M3-M9 milestone scope until superseded by later approved Spec Kit outputs.
- The customer wants agents to continue planning safely while unavailable, so reasonable assumptions are preferred over blocking clarification questions.
- Spec Kit may generate specifications, plans, tasks, analysis, checklists, and issue-conversion candidates, but `tech-lead` must govern all outputs through the sw-dev role model.
- Exact implementation sequencing, file-by-file task assignments, and specialist dispatches will be produced by `/speckit.plan` and later task generation, not this specification.
- Downstream repository names and observations from the source plan are sufficient for planning; repository-specific repair details will be validated during M8 execution.
