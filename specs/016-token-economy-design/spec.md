# Feature Specification: Token Economy Design Pass (Composite #239 + #245)

**Feature Branch**: `016-token-economy-design`
**Created**: 2026-05-28
**Status**: Draft
**Input**: Composite token-economy design pass that gates v1.2.0 and v1.3.0 implementation entry per `docs/pm/release-plan-v1.x.md` (customer ruling Q-0022 + addendum ratifying PM's wider gate, 2026-05-28). Combines GitHub issues #239 (framework-gap: tech-lead.md missing Token economy (binding) section) and #245 (token-economy: agent contract prose audit AGT-1).

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Tech-lead has binding multi-agent dispatch discipline (Priority: P1)

A `tech-lead` agent — and any human or AI operator playing the tech-lead role — must be able to read its own contract surface and find a single, binding section that codifies the dispatch discipline keeping multi-agent context costs down. Today the discipline is folklore; the contract is silent. After this work, the rules (WIP=1 per specialist, vertical slicing, JIT context, dispatch-brief token-budget hints, DoD-before-next-dispatch, atomic commits) are stated as binding rules and an explicit anti-pattern list calls out the Scrum practices that do NOT transfer to multi-agent work (daily standups, story points, time-boxed sprints, velocity tracking, scrum-master role).

**Why this priority**: P1 because (a) it gates v1.2.0 and v1.3.0 implementation entry per Q-0022 + addendum, and (b) every dispatch the tech-lead makes is governed by these rules whether or not they are written down — making them binding is the difference between consistent dispatch behavior and per-session improvisation.

**Independent Test**: A tech-lead operator (human or agent) opens its contract surface, navigates to the "Token economy (binding)" section between memory-first lookup and escalation, and finds every rule listed above plus the anti-pattern list. A specialist agent can quote the same section verbatim when an operator's behavior drifts from it. Verifiable by inspection of the contract surface and by a targeted regression review of recent dispatches.

**Acceptance Scenarios**:

1. **Given** the v1.1.0 framework with no token-economy section in `tech-lead.md`, **When** a reviewer opens the contract surface (`.claude/agents/tech-lead.md` and/or `docs/agents/manual/tech-lead-manual.md`), **Then** they find a "Token economy (binding)" section positioned between memory-first lookup and escalation, with all rules and the anti-pattern list present.
2. **Given** a tech-lead drafting a dispatch brief, **When** the brief omits a token-budget hint or attempts to dispatch a second specialist before the first one's DoD, **Then** the binding section gives the specialist (or a reviewer) explicit grounds to push back.
3. **Given** a customer or auditor asks why the framework rejects Scrum practices, **When** they read the contract surface, **Then** they find the anti-pattern list with each rejected practice named.

---

### User Story 2 — Agent contracts trimmed to ≤80% of sizing cap (Priority: P1)

Every `.claude/agents/<role>.md` file pays a fresh context cost on each spawn. v0.12.1+ moved explanatory prose to per-role manuals, but several contracts still echo the moved content; some carry duplicated escalation boilerplate; some carry behavior-neutral prose. A systematic word-count baseline followed by source-traceable cuts brings every contract to ≤80% of its sizing cap (per the archival sizing policy in `docs/agents/manual/researcher-manual.md`), preserving all binding rules and customer-truth references.

**Why this priority**: P1 because (a) it shares the same Q-0022 gate as User Story 1, and (b) prose audit results from this story feed back into the binding-section placement decision in User Story 1 (whether to put new content in the contract or the manual) — the two halves are coupled.

**Independent Test**: For every agent contract file, the design pass produces (a) the baseline word count, (b) the proposed cuts with before/after, (c) each cut linked to its rationale tag (duplicated boilerplate / behavior-neutral prose / manual-echo), and (d) the final word count. A code-reviewer reads each diff and confirms binding-rule preservation; a tech-writer reads the consolidated set for prose quality.

**Acceptance Scenarios**:

1. **Given** the agent contract roster (`.claude/agents/*.md` excluding `sme-template.md`), **When** baseline measurement runs, **Then** a table lists each file with its current word count, sizing cap, and percentage of cap.
2. **Given** any contract file currently above the 80%-of-cap threshold, **When** the design pass completes, **Then** that contract is at or below the threshold and every cut is tagged with its rationale.
3. **Given** a code-reviewer compares before / after for each file, **When** they look for binding-rule deltas, **Then** they find none — only boilerplate, manual-echo, or behavior-neutral prose has been cut.
4. **Given** a `tech-writer` reads the consolidated set, **When** they check for orphaned cross-references or prose seams, **Then** they find none.

---

### User Story 3 — Customer sign-off gates v1.2.0 and v1.3.0 entry (Priority: P1)

Per Q-0022 (+ addendum 2026-05-28 ratifying PM's wider gate), the composite design pass — Half A AND Half B together — must land and be reviewed by architect + tech-writer + code-reviewer, then receive explicit customer sign-off, before either v1.2.0 or v1.3.0 implementation may begin. The sign-off becomes a gating record in the release plan.

**Why this priority**: P1 because no v1.2.0 or v1.3.0 work can start without it; this is the explicit customer ruling.

**Independent Test**: `docs/pm/release-plan-v1.x.md` carries a customer-sign-off line referencing this spec; `CUSTOMER_NOTES.md` carries the verbatim sign-off; `OPEN_QUESTIONS.md` Q-0022 closes with a pointer to the sign-off. If any v1.2.0 or v1.3.0 implementation work is found to have started before the sign-off date, the gate has failed.

**Acceptance Scenarios**:

1. **Given** Half A + Half B both landed and reviewed, **When** customer reviews and approves, **Then** the sign-off is recorded in `CUSTOMER_NOTES.md` and the release plan, and v1.2.0 / v1.3.0 entry is unblocked.
2. **Given** the design pass is incomplete (only one half landed), **When** anyone attempts to start v1.2.0 implementation, **Then** the release-plan gate refuses entry until the missing half lands.

---

### Edge Cases

- An agent contract file is already below 80% of its cap — no cuts required; baseline recorded, file marked "no-op" with rationale.
- A proposed cut would remove a binding rule by accident — the cut is rejected; the proposal documents why the prose looked cuttable but isn't.
- The new "Token economy (binding)" section grows tech-lead.md above its own 80% cap — content placement is split between contract (rules only) and manual (explanatory expansion); see Assumption A-1.
- A binding rule already exists elsewhere in tech-lead.md in different words — the audit consolidates rather than duplicates.
- A customer-truth reference is buried in prose that looks behavior-neutral — the reference is preserved verbatim or relocated to the relevant manual with a contract-side pointer.
- A specialist agent contract carries Codex-adapter prose that duplicates `AGENTS.md` — the duplicate is cut; the contract carries a one-line pointer instead.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST add a "Token economy (binding)" section to the tech-lead contract surface, positioned between memory-first lookup and escalation. The section MUST contain, as binding rules: WIP=1 per specialist; vertical slicing; JIT context loading; dispatch-brief token-budget hints; DoD-before-next-dispatch; atomic commits (one logical change per commit).
- **FR-002**: The same section MUST contain an explicit anti-pattern list naming Scrum practices that do NOT transfer to multi-agent work: daily standups, story points, time-boxed sprints, velocity tracking, scrum-master role.
- **FR-003**: System MUST produce a baseline word-count table covering every file in `.claude/agents/*.md` (excluding `sme-template.md`, which is a scaffold), each row showing word count, applicable sizing cap, and percentage of cap.
- **FR-004**: System MUST identify reduction candidates in each contract file and tag each candidate with one of three rationales: duplicated escalation boilerplate; behavior-neutral explanatory prose; manual-echo (content already moved to the role manual but still present in the contract).
- **FR-005**: System MUST publish a proposed-cut diff for every reduction candidate, showing before / after and confirming preservation of all binding rules and customer-truth references.
- **FR-006**: After cuts are applied, every contract file MUST sit at or below 80% of its sizing cap per the archival sizing policy in `docs/agents/manual/researcher-manual.md`.
- **FR-007**: System MUST NOT restructure the agent-roster shape, the escalation protocol, or the manual-extraction pattern.
- **FR-008**: System MUST preserve every binding rule and every customer-truth reference; cuts that would alter behavior or drop a customer-truth pointer MUST be rejected and documented.
- **FR-009**: System MUST produce a post-cut word-count table mirroring FR-003, so the before-and-after delta is auditable per file and in aggregate.
- **FR-010**: System MUST land Half A (FR-001 + FR-002) and Half B (FR-003 through FR-009) together as a single composite design pass — partial completion does not satisfy the v1.2.0 / v1.3.0 entry gate.
- **FR-011**: System MUST record customer sign-off in `CUSTOMER_NOTES.md` and reference that sign-off from `docs/pm/release-plan-v1.x.md` before v1.2.0 or v1.3.0 implementation begins.
- **FR-012**: Every cut MUST be source-traceable: the diff identifies the cut, the rationale tag, and (where applicable) the manual location that already carries the moved content.
- **FR-013**: System MUST NOT modify scripts, schemas, hooks, migrations, or scaffold templates as part of this design pass — pure markdown edits only within `.claude/agents/*.md`, `docs/agents/manual/tech-lead-manual.md`, and the spec directory.

### Constitution Alignment *(mandatory)*

- **CA-001**: Source authority is canonical for all touched files. `.claude/agents/*.md` and `docs/agents/manual/tech-lead-manual.md` are canonical agent contracts; this spec, plan, tasks, and the word-count tables produced during the audit are canonical artifacts. No generated or ephemeral outputs are introduced.
- **CA-002**: Customer-owned requirements cite the recorded customer answer Q-0022 (2026-05-28: "validate full scope") and its 2026-05-28 addendum ratifying PM's widened gate (blocks v1.2.0 in addition to v1.3.0). Both are recorded in `docs/OPEN_QUESTIONS.md`.
- **CA-003**: This is framework-maintenance work touching framework-managed files (`.claude/agents/*.md`, `docs/agents/manual/`). HR #10 authorization is satisfied by the customer's Q-0022 ruling and the release-plan ratification; the work scope is bounded by FR-013.
- **CA-004**: Role authority is preserved — architect signs off on Half A's binding semantics; tech-writer signs off on Half B's prose surgery; code-reviewer signs off on diff-level binding-rule preservation; tech-lead orchestrates and obtains customer sign-off. No agent crosses role boundaries.

### Key Entities

- **Agent contract file**: A `.claude/agents/<role>.md` file. Carries the agent's frontmatter (`name`, `description`, `tools`, `model`) and the binding contract prose. Sized against the archival cap; expected to stay at ≤80% of cap.
- **Role manual**: A `docs/agents/manual/<role>-manual.md` file. Carries explanatory prose that does NOT belong on the per-spawn context path. Receives content extracted from the contract during the audit.
- **Sizing cap**: The per-file size ceiling defined in the archival sizing policy in `docs/agents/manual/researcher-manual.md`. Used as the denominator for the 80%-of-cap target.
- **Cut proposal**: A before/after diff for a contiguous span of prose, tagged with one of {duplicated-boilerplate, behavior-neutral, manual-echo}, optionally referencing the manual section that now carries the moved content.
- **Sign-off record**: A verbatim customer approval written to `CUSTOMER_NOTES.md` and pointed to from `docs/pm/release-plan-v1.x.md`. Unlocks v1.2.0 and v1.3.0 entry.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of `.claude/agents/<role>.md` files (excluding `sme-template.md`) sit at ≤80% of their sizing cap after the design pass lands.
- **SC-002**: 100% of cuts carry a rationale tag and (for manual-echo cuts) a manual-location pointer; reviewer can verify by inspection.
- **SC-003**: Zero binding rules are dropped; verifiable by code-reviewer diff review identifying no semantic regressions.
- **SC-004**: Zero customer-truth references are dropped; verifiable by grepping every `CUSTOMER_NOTES.md` cross-reference against the post-cut files.
- **SC-005**: Aggregate context cost reduction across the roster is ≥15% (measured by total word count of contract files before vs. after), with no single file exceeding 100% of its cap.
- **SC-006**: The "Token economy (binding)" section is present in tech-lead's contract surface (CA-003-permitted location per Assumption A-1) and contains every rule and anti-pattern listed in FR-001 / FR-002.
- **SC-007**: Customer sign-off is recorded in `CUSTOMER_NOTES.md` and referenced from `docs/pm/release-plan-v1.x.md` before any v1.2.0 or v1.3.0 implementation work begins.
- **SC-008**: Time from design-pass landing to customer sign-off is ≤2 sessions (no protracted review cycle), assuming all reviewers' findings are addressed in one revision.

## Assumptions

- **A-1**: Binding-rules content (FR-001/FR-002) lands in the *contract* (`tech-lead.md`); any explanatory expansion lands in the *manual* (`docs/agents/manual/tech-lead-manual.md`). This preserves the manual-extraction pattern: contracts carry rules only; manuals carry explanation. If applying this rule pushes tech-lead.md above its own 80% cap, the audit prioritizes Half B cuts on `tech-lead.md` until both Half A and the cap target are satisfied.
- **A-2**: Word count (`wc -w`) is the proxy for token count; this matches the existing AGT-1 scope language and the archival sizing policy. Token-exact measurement (via tokenizer) is out of scope for this design pass.
- **A-3**: `sme-template.md` is a scaffold for downstream-created SME agents; it is not a runtime contract and is excluded from the audit roster.
- **A-4**: The archival sizing policy in `docs/agents/manual/researcher-manual.md` is the authoritative source of per-file caps; the design pass cites it rather than redefining caps.
- **A-5**: Codex adapter prose duplicated between `.claude/agents/*.md` and `AGENTS.md` is treated as duplicated-boilerplate; the per-agent contract retains a one-line pointer instead of the full adapter prose.
- **A-6**: Reviews proceed in parallel where possible — architect (Half A semantics) and tech-writer (Half B prose) need not serialize, but code-reviewer's diff review runs after both have landed proposed changes.
- **A-7**: This design pass produces only canonical markdown changes inside `.claude/agents/`, `docs/agents/manual/`, and the spec directory; no scripts, schemas, hooks, or migrations are touched (FR-013).
- **A-8**: Customer sign-off may be obtained in any session after both reviewers have signed off; it does not have to be the same session as the implementation landing.
