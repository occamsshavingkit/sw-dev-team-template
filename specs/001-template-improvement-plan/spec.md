# Feature Specification: Template Improvement Program

**Feature Branch**: `001-template-improvement-plan`  
**Created**: 2026-05-12  
**Status**: Draft  
**Input**: User description: "check out the plan in sw_dev_template_implementation_plan-1.md"

## Clarifications

### Session 2026-05-12

- Q: What scope should the MVP planning phase cover? → A: M0 and M1 only.
- Q: What deliverables define the M0/M1 MVP? → A: All M1 artifacts fully implemented.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Reduce Recurring Context Cost (Priority: P1)

Template maintainers need the improvement program to first reduce recurring token and context cost so future work does not make every session slower, more expensive, or harder to keep synchronized.

**Why this priority**: Context reduction is the enabling work for every later milestone and prevents new capabilities from increasing baseline operating cost.

**Independent Test**: Can be tested by comparing baseline and post-change context-surface measurements and confirming the largest live surfaces are reduced or have accepted reduction paths.

**Acceptance Scenarios**:

1. **Given** the current template context surfaces, **When** the program baseline is accepted, **Then** maintainers know the largest recurring context costs and can prioritize reductions.
2. **Given** live registers and role contracts with accumulated history or repeated prose, **When** the M0/M1 MVP is accepted, **Then** all M1 token quick-win artifacts are fully implemented, live surfaces are shorter, and audit trails remain available.

---

### User Story 2 - Repair Authority And Customer Question Flow (Priority: P2)

Template maintainers need clear source authority and enforceable customer-question behavior so agents do not rely on stale mirrors, leak upstream roadmap content downstream, or ask compound questions before internal work is idle.

**Why this priority**: Authority drift and poor question flow can cause incorrect decisions, customer friction, and conflicting agent behavior.

**Independent Test**: Can be tested by reviewing updated authority classifications and question-flow rules against known failure patterns from the plan.

**Acceptance Scenarios**:

1. **Given** artifacts that repeat the same guidance, **When** the authority model is accepted, **Then** each artifact is classified as canonical, generated, or ephemeral, and manual mirrors are not permitted.
2. **Given** multiple unresolved customer-facing questions, **When** an agent prepares a response, **Then** questions are queued internally and only one atomic customer-owned question may be asked externally at the end of the turn.
3. **Given** a downstream project created from the template, **When** roadmap and workflow guidance is inspected, **Then** upstream template planning does not appear as project-local authority.

---

### User Story 3 - Add Safe Cross-AI Routing As An Adapter (Priority: P3)

Template maintainers need OpenCode, Gemini, OpenAI, Codex, and Claude routing to extend the existing role model without creating parallel authority, duplicated roles, or inconsistent escalation paths.

**Why this priority**: Cross-AI routing is valuable only after token and authority risks are controlled; otherwise it amplifies drift.

**Independent Test**: Can be tested by confirming that all cross-AI behavior preserves the canonical role roster, role authority, customer interface, and fallback logging expectations.

**Acceptance Scenarios**:

1. **Given** a task routed through a non-default AI provider, **When** fallback occurs, **Then** the role authority and output expectations remain unchanged and the fallback is auditable.
2. **Given** generated provider-specific adapter content, **When** it is reviewed, **Then** it references the canonical role contract instead of duplicating full role text.

---

### User Story 4 - Generate Runtime Markdown Only After Authority Is Clear (Priority: P4)

Template maintainers need Markdown compilation to reduce runtime surface area and improve consistency without making generated content the source of truth.

**Why this priority**: Compilation can reduce context cost, but only after canonical sources and generated outputs are clearly separated.

**Independent Test**: Can be tested by confirming generated runtime outputs are reproducible, traceable to canonical sources, and fail review when hard rules or authority boundaries change unexpectedly.

**Acceptance Scenarios**:

1. **Given** canonical role and routing guidance, **When** runtime content is generated, **Then** generated content is stable, smaller where targeted, and does not silently change source meaning.
2. **Given** a hard rule or escalation format in canonical guidance, **When** generated runtime content is checked, **Then** the required behavior is preserved.

---

### User Story 5 - Enable Safe Self-Improvement And Downstream Rollout (Priority: P5)

Template maintainers need issue-driven self-improvement and downstream retrofit work to occur only after gates are satisfied, with human review and safe rollout to reference repositories.

**Why this priority**: Automation and rollout are high-leverage but high-risk unless earlier gates prove token economy, authority, routing, and generated-artifact discipline.

**Independent Test**: Can be tested by verifying self-improvement proposals open reviewable changes only after required gates, and each downstream reference repository is repaired or has documented exceptions.

**Acceptance Scenarios**:

1. **Given** an issue describing a template gap, **When** self-improvement automation is allowed, **Then** it proposes one bounded reviewable change rather than directly changing protected branches.
2. **Given** a reference downstream repository, **When** rollout is assessed, **Then** required framework files, live context limits, intake logs, and product/framework boundaries are verified.

### Edge Cases

- If token reduction conflicts with preserving a hard rule, the hard rule wins and the reduction requires an explicit accepted path or waiver.
- If an artifact appears both canonical and generated, the program must resolve authority before relying on either copy.
- If a customer question has multiple decision axes, it must be split and queued internally before any external ask.
- If a cross-AI provider is unavailable or falls back, role authority and customer-interface rules must remain unchanged.
- If generated Markdown differs semantically from source authority, generated output must not be accepted as authoritative.
- If self-improvement automation would touch protected or high-risk areas unexpectedly, it must produce no change or a reviewable issue rather than an unsafe update.
- If a downstream repository cannot be fully repaired in one pass, the exception must be documented without mixing unrelated product work into framework maintenance.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The program MUST prioritize token and context reduction before cross-AI routing, Markdown compilation, self-improvement automation, or downstream rollout work.
- **FR-002**: The program MUST establish baseline measurements for live context surfaces before accepting token-reduction changes.
- **FR-003**: The program MUST keep live working surfaces short while preserving auditability through archives, evidence records, or equivalent traceable history.
- **FR-003a**: The M0/M1 MVP MUST fully implement all M1 token quick-win artifacts, not only baseline report, schedule entries, risk entries, or PR-split planning outputs.
- **FR-004**: The program MUST classify relevant artifacts as canonical, generated, or ephemeral before relying on duplicated or derived content.
- **FR-005**: The program MUST prohibit manual mirrors where the same binding content is maintained in more than one place.
- **FR-006**: The program MUST ensure customer-facing questions are customer-owned, atomic, asked only when internal work is idle, and placed as the final line of a response.
- **FR-007**: The program MUST repair or prevent downstream leakage of upstream template planning, especially roadmap or workflow guidance that could be mistaken for project-local authority.
- **FR-008**: The program MUST treat OpenCode, Gemini, OpenAI, Codex, Claude, and similar providers as adapters over the existing role model, not as competing orchestration systems.
- **FR-009**: The program MUST require fallback events in cross-AI routing to be auditable and to preserve role authority, escalation paths, and output expectations.
- **FR-010**: The program MUST allow Markdown compilation or runtime contract generation only after source authority is explicit.
- **FR-011**: The program MUST ensure generated artifacts are reproducible, marked or understood as generated, and not accepted as source authority.
- **FR-012**: The program MUST verify that hard rules, escalation formats, customer-interface rules, and role authority survive any compacted or generated runtime form.
- **FR-013**: The program MUST defer self-improvement automation until prior gates for token economy, authority, routing, generated artifacts, and quality checks are satisfied.
- **FR-014**: The program MUST constrain self-improvement automation to bounded, reviewable proposals with human review before protected changes are accepted.
- **FR-015**: The program MUST support downstream rollout to QuackDCS, QuackPLC, QuackS7, and QuackSim, with each repository repaired or given documented exceptions.
- **FR-016**: The program MUST keep product work and framework maintenance separate unless explicitly authorized.
- **FR-017**: The program MUST define milestone gates that prevent later workstreams from starting before prerequisite evidence is accepted.
- **FR-018**: The program MUST provide measurable acceptance criteria for token economy, question quality, authority clarity, generated-artifact discipline, routing fallback logging, automation safety, and downstream rollout.

### Key Entities *(include if feature involves data)*

- **Improvement Program**: The overall template improvement effort, including ordered milestones, gates, success metrics, risks, and rollout expectations.
- **Milestone Gate**: A decision point that states whether prerequisite evidence is sufficient to start later work.
- **Context Surface**: A live file, role contract, register, schedule, ledger, or other artifact that recurring sessions may read and that therefore carries token cost.
- **Artifact Authority Class**: The classification of an artifact as canonical, generated, or ephemeral.
- **Customer Question**: A customer-owned decision request that must be atomic and externally asked only under the program's question-flow rules.
- **Cross-AI Adapter**: Provider-specific routing behavior that maps to existing roles without redefining authority or customer interaction.
- **Generated Runtime Artifact**: Derived content intended to reduce runtime context or standardize adapters while remaining subordinate to canonical sources.
- **Self-Improvement Proposal**: A bounded issue-driven change candidate that must be reviewable and gated before acceptance.
- **Downstream Reference Repository**: One of QuackDCS, QuackPLC, QuackS7, or QuackSim used to validate rollout and retrofit behavior.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The generated or runtime form of the tech-lead contract is reduced by at least 30% without losing hard rules, authority boundaries, or escalation behavior.
- **SC-002**: Other generated or runtime role contracts are reduced by at least 20% where safe, or each exception has an accepted rationale.
- **SC-003**: Live question registers contain only open and recently answered rows, with older terminal history still traceable.
- **SC-004**: Live PM planning surfaces contain current plan content only, with closure evidence and historical material separated from routine reading paths.
- **SC-005**: New customer-question entries have zero atomic-question violations after the question-flow repair is accepted.
- **SC-006**: The four reference downstream repositories have zero missing intake logs after repair, or documented exceptions accepted by the program gate.
- **SC-007**: Generated artifacts have zero accepted manual edits outside the defined source-authority process.
- **SC-008**: Cross-AI fallback events without an audit record are reduced to zero after routing acceptance.
- **SC-009**: Product tasks modify framework-managed files zero times unless explicitly authorized.
- **SC-010**: Self-improvement automation produces zero direct protected-branch changes and zero unexpected protected-file edits.
- **SC-011**: All milestone gates from baseline through release readiness have explicit pass/fail evidence before the program is considered complete.
- **SC-012**: QuackDCS, QuackPLC, QuackS7, and QuackSim are repaired or have documented rollout exceptions before final release readiness.

## Assumptions

- The improvement program applies to the sw-dev-team-template framework, not to unrelated product features.
- The closest matching plan file, `sw_dev_template_implementation_plan-1.md`, is the intended source for this feature specification.
- The program may be delivered as multiple independently reviewable changes rather than one large change.
- The next planning phase and MVP scope cover M0 and M1 only; the M0/M1 MVP requires full implementation of all M1 token quick-win artifacts, while later milestones remain part of the broader improvement program.
- Existing role authority, customer-interface ownership, and specialist routing remain the baseline operating model.
- Token and context savings are valuable only when hard rules and auditability are preserved.
- Generated content is derived from canonical sources and is not manually edited as authority.
- Downstream rollout includes QuackDCS, QuackPLC, QuackS7, and QuackSim as reference repositories.
- Self-improvement automation is out of scope until prerequisite gates prove safety and generated-artifact discipline.
