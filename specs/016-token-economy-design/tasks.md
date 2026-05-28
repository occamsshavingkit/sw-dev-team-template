---
description: "Task list for spec 016 — token economy design pass (composite #239 + #245)"
---

# Tasks: Token Economy Design Pass (Composite #239 + #245)

**Input**: Design documents from `/home/quackdcs/SWEProj/specs/016-token-economy-design/`
**Prerequisites**: spec.md (required, user stories), plan.md (required, decisions D-1..D-4 + gate model)

**Verification**: This is a framework-maintenance, markdown-only design pass. No automated test suite applies; verification is inspection-driven (`wc -w` measurement, `code-reviewer` diff review, architect/tech-writer reviews per D-4). FR-013 bounds scope to markdown edits inside `.claude/agents/*.md`, `docs/agents/manual/tech-lead-manual.md`, and the spec directory.

**Organization**: Tasks are grouped by user story (US1 = Half A binding section; US2 = Half B audit + cuts; US3 = customer sign-off). The plan's four gates (Gate 0 baseline → Gate 1 reviewer sign-off → Gate 2 code-reviewer → Gate 3 customer) mark phase boundaries.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (US1, US2, US3). Required for US-phase tasks; omitted in Setup, Foundational, and Polish phases.
- Include exact file paths in descriptions.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Stand up the design-pass artifact that the gates and reviews reference.

- [ ] T001 Create scaffold for `specs/016-token-economy-design/audit-tables.md` with three empty sections: `## Baseline` (columns: Role / M0 words (cap) / 80% ceiling / Current words / % of cap / Status), `## Proposals` (columns: Role / Span / Tag / Before / After / Manual pointer / tech-writer notes / Status), `## Post-cut` (columns: Role / M0 words (cap) / 80% ceiling / Post-cut words / % of cap / Delta words / All cuts tagged?). Schemas pinned in plan D-2.

---

## Phase 2: Foundational (Gate 0 — blocking prerequisites)

**Purpose**: Establish the cap-vs-current baseline that every cut decision and the SC-001 / SC-005 verification depend on. **No US1 or US2 work may start until Gate 0 closes.**

**⚠️ CRITICAL**: Per plan OQ-1, `tech-lead.md` headroom must be confirmed in T004 before Half A is authored (US1).

- [ ] T002 Run `wc -w` on every `.claude/agents/<role>.md` file in `sw-dev-team-template/.claude/agents/` excluding `sme-template.md`; record raw counts in `specs/016-token-economy-design/audit-tables.md` § Baseline `Current words` column for all 13 runtime-eligible contracts.
- [ ] T003 [P] Copy M0 word counts from `sw-dev-team-template/docs/pm/token-economy-baseline.md` § "Per-agent contract sizes" into `audit-tables.md` § Baseline `M0 words (cap)` column for all 13 rows.
- [ ] T004 [P] Compute `floor(M0 × 0.80)` for each of the 13 rows and populate `audit-tables.md` § Baseline `80% ceiling` and `% of cap` columns; set `Status` to `at-or-below-80%` / `above-80%` / `no-op` per D-2.
- [ ] T005 Verify `tech-lead.md` row in Baseline shows ≥250 words of headroom under its 80% ceiling (plan OQ-1 estimate for the new section is ~200–300 words). If headroom is < 250 words, flag in plan Risks row 2 and prioritize US2 cuts on `tech-lead.md` (T020 below) before US1 authoring begins.
- [ ] T006 Verify SC-005 aggregate reachability per plan OQ-2: sum `Current words` column in Baseline; compare to `0.85 × Σ M0`. If Σ Current ≤ Σ M0 × 0.85, mark "SC-005 reachable with modest cuts" in audit-tables.md notes; otherwise mark "thin margin — monitor".
- [ ] T007 Gate 0 sign-off — `architect` confirms Baseline table is complete (13 rows, every column populated, T005/T006 results recorded). Record sign-off line in `audit-tables.md` § Baseline footer with date + reviewer.

**Checkpoint (Gate 0)**: Baseline published and verified. US1 and US2 may now proceed.

---

## Phase 3: User Story 1 — Tech-lead has binding multi-agent dispatch discipline (Priority: P1) 🎯 MVP-companion-to-US2

**Goal**: A new "Token economy (binding)" section sits in `.claude/agents/tech-lead.md` between memory-first lookup and escalation, codifying WIP=1, vertical slicing, JIT context, dispatch-brief token-budget hints, DoD-before-next-dispatch, atomic commits, and the explicit Scrum anti-pattern list (FR-001 + FR-002).

**Independent Test**: Open `.claude/agents/tech-lead.md`; locate the new section in the prescribed position; verify all six binding rules and all five anti-pattern items are present and read as binding.

### Implementation for User Story 1

- [ ] T008 [US1] Draft "Token economy (binding)" section in `sw-dev-team-template/.claude/agents/tech-lead.md`, positioned between memory-first lookup and escalation; include the six binding rules (WIP=1, vertical slicing, JIT context, dispatch-brief token-budget hints, DoD-before-next-dispatch, atomic commits) per FR-001 and the five-item Scrum anti-pattern list per FR-002. Owner: `software-engineer` authoring under `architect` direction (D-1 ratification — rules in contract).
- [ ] T009 [US1] If the new section calls for explanatory material that does not fit the contract's binding-rules style, add a corresponding "Token economy" section to `sw-dev-team-template/docs/agents/manual/tech-lead-manual.md` carrying the explanatory expansion only. Keep the contract surface lean per D-1.
- [ ] T010 [US1] `architect` semantic review of T008 + T009 — confirm the binding-rules content correctly reflects multi-agent dispatch discipline; flag any rules that read as descriptive rather than binding; flag any duplication of existing tech-lead.md content. Also confirm US1 acceptance scenario 2 (the section reads such that a specialist can quote it to push back when a dispatch brief omits a token-budget hint or violates DoD).
- [ ] T011 [US1] Apply architect findings from T010 to `tech-lead.md` and/or `tech-lead-manual.md`.
- [ ] T012 [US1] Re-measure `wc -w` on `tech-lead.md` after T011; confirm the file remains at ≤80% of its M0 cap (recorded against `audit-tables.md` § Baseline row). Confirm SC-006: the "Token economy (binding)" section is present in `.claude/agents/tech-lead.md` with every FR-001 rule and FR-002 anti-pattern item — grep for each item.

**Checkpoint (US1 done)**: The binding section is present, architect-approved, and `tech-lead.md` is still ≤80% of cap.

---

## Phase 4: User Story 2 — Agent contracts trimmed to ≤80% of sizing cap (Priority: P1)

**Goal**: Every `.claude/agents/<role>.md` file (excluding `sme-template.md`) sits at ≤80% of its M0 cap with all cuts source-traceable (rationale tag + optional manual pointer).

**Independent Test**: Re-run `wc -w` on every contract file; every row in `audit-tables.md` § Post-cut shows `% of cap ≤ 80`; every cut listed in § Proposals carries a `duplicated-boilerplate` / `behavior-neutral` / `manual-echo` tag.

### Cut-proposal phase — one task per contract (parallelizable per D-4)

For each task: read the file, identify candidate spans, tag each with one of the three D-3 rationales, record the proposed before/after in `audit-tables.md` § Proposals (do NOT apply edits yet). If the contract is already ≤80% per Baseline and no behavior-neutral / manual-echo / duplicated-boilerplate spans are visible, mark the row `no-op` with a one-line justification.

- [ ] T013 [P] [US2] Propose cuts for `sw-dev-team-template/.claude/agents/architect.md`; tag per D-3; record in `audit-tables.md` § Proposals.
- [ ] T014 [P] [US2] Propose cuts for `sw-dev-team-template/.claude/agents/code-reviewer.md`; tag per D-3; record.
- [ ] T015 [P] [US2] Propose cuts for `sw-dev-team-template/.claude/agents/onboarding-auditor.md`; tag per D-3; record.
- [ ] T016 [P] [US2] Propose cuts for `sw-dev-team-template/.claude/agents/process-auditor.md`; tag per D-3; record.
- [ ] T017 [P] [US2] Propose cuts for `sw-dev-team-template/.claude/agents/project-manager.md`; tag per D-3; record.
- [ ] T018 [P] [US2] Propose cuts for `sw-dev-team-template/.claude/agents/qa-engineer.md`; tag per D-3; record.
- [ ] T019 [P] [US2] Propose cuts for `sw-dev-team-template/.claude/agents/release-engineer.md`; tag per D-3; record.
- [ ] T020 [P] [US2] Propose cuts for `sw-dev-team-template/.claude/agents/researcher.md`; tag per D-3; record.
- [ ] T021 [P] [US2] Propose cuts for `sw-dev-team-template/.claude/agents/security-engineer.md`; tag per D-3; record.
- [ ] T022 [P] [US2] Propose cuts for `sw-dev-team-template/.claude/agents/software-engineer.md`; tag per D-3; record.
- [ ] T023 [P] [US2] Propose cuts for `sw-dev-team-template/.claude/agents/sre.md`; tag per D-3; record.
- [ ] T024 [P] [US2] Propose cuts for `sw-dev-team-template/.claude/agents/tech-writer.md`; tag per D-3; record.
- [ ] T025 [US2] Propose cuts for `sw-dev-team-template/.claude/agents/tech-lead.md`. NOT parallel — sequence after US1 T011 to avoid editing in the middle of Half A authoring. Task authors should sequence accordingly.

### Review-and-apply phase

- [ ] T026 [US2] `tech-writer` prose-quality review of all proposals in `audit-tables.md` § Proposals: confirm cuts are tagged correctly (D-3 operational tests); flag any proposal that looks behavior-bearing or drops a customer-truth reference (FR-008 / SC-003 / SC-004). Record findings in `audit-tables.md` § Proposals "tech-writer notes" column.
- [ ] T027 [US2] Apply approved cuts to all 13 contract files in one atomic pass per file (one logical change per commit per the new D-1 binding "atomic commits" rule). Rejected proposals stay in § Proposals with a "rejected — <reason>" annotation.
- [ ] T028 [US2] Re-run `wc -w` on every edited contract file; populate `audit-tables.md` § Post-cut with `Post-cut words`, `% of cap`, `Delta words`, and `All cuts tagged?` columns for all 13 rows.
- [ ] T029 [US2] Verify SC-001 (every row `% of cap ≤ 80`) and SC-005 (Σ Delta ≥ 0.15 × Σ M0) against § Post-cut. If SC-005 falls short, escalate to `architect` for scope-extension or document the gap per plan Risks row 3.

**Checkpoint (US2 done)**: All 13 contracts ≤80% of cap; cuts are source-traceable; aggregate ≥15% reduction (or a documented gap).

---

## Phase 5: Gate 1 — Reviewer sign-off (architect + tech-writer)

**Purpose**: Lock the design-pass content for `code-reviewer` diff review.

- [ ] T030 `architect` sign-off on Half A semantic correctness — records "Half A signed off: <date>" in `audit-tables.md` footer. Pre-sign-off: confirm FR-010 composite landing — both T012 (Half A complete) AND T029 (Half B complete) are checked off.
- [ ] T031 `tech-writer` sign-off on Half B prose surgery — records "Half B signed off: <date>" in `audit-tables.md` footer. Pre-sign-off: confirm FR-010 composite landing as in T030.

**Checkpoint (Gate 1)**: Both reviewer sign-offs present. Code-reviewer diff review may proceed.

---

## Phase 6: Gate 2 — Code-reviewer diff review

**Purpose**: Confirm no binding-rule drops, no customer-truth-reference drops, all cuts tagged. Post-revision diff only (D-4: code-reviewer reviews the result, not proposals).

- [ ] T032 Dispatch `code-reviewer` to diff-review the full set of edited contract files (`.claude/agents/*.md` + `docs/agents/manual/tech-lead-manual.md`) against their pre-pass state. Confirm: no binding rules dropped (FR-008); no customer-truth references dropped (SC-004); every cut carries a D-3 rationale tag (FR-004 / FR-012); the new "Token economy (binding)" section is present in the contract surface (SC-006); no restructuring of the agent-roster shape, the escalation protocol, or the manual-extraction pattern (FR-007); no out-of-scope files touched — scripts, schemas, hooks, migrations, scaffold templates all unchanged (FR-013).
- [ ] T033 Apply any code-reviewer findings from T032; re-run T028 (post-cut word counts) if any further cuts land.
- [ ] T034 `code-reviewer` sign-off — records "Code-reviewer signed off: <date>" in `audit-tables.md` footer.

**Checkpoint (Gate 2)**: Code-reviewer signed off; design-pass content is locked.

---

## Phase 7: Gate 3 — Customer sign-off

**Purpose**: Customer sign-off unlocks v1.2.0 and v1.3.0 implementation entry per Q-0022 + addendum (FR-011 / SC-007).

- [ ] T035 [US3] `tech-lead` brings the design-pass artifacts to the customer for sign-off: spec, plan, audit-tables, the new "Token economy (binding)" section, and the diff summary.
- [ ] T036 [US3] `researcher` records the verbatim customer sign-off in `sw-dev-team-template/CUSTOMER_NOTES.md` with the date.
- [ ] T037 [US3] Update `sw-dev-team-template/docs/pm/release-plan-v1.x.md` to reference the CUSTOMER_NOTES sign-off entry from the v1.2.0 and v1.3.0 entry-gate prose.
- [ ] T038 [US3] Close Q-0022 in `sw-dev-team-template/docs/OPEN_QUESTIONS.md` Resolution column with a pointer to the CUSTOMER_NOTES sign-off entry.

**Checkpoint (Gate 3)**: Customer sign-off recorded. v1.2.0 and v1.3.0 entry unblocked.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Close out the design-pass and discharge follow-ups.

- [ ] T039 [P] `researcher` files the upstream framework gap on the missing "archival sizing policy" section in `researcher-manual.md` (plan Risks row 4); record the issue number in `audit-tables.md` Notes.
- [ ] T040 [P] Update the GitHub issues: close #239 and #245 with a pointer to the merged design-pass commit set and the customer sign-off date.
- [ ] T041 Push the framework chore branch `chore/release-plan-v1.x` + the spec branch `016-token-economy-design`; open PRs at PR time — framework PR targets `sw-dev-team-template@main`; meta-project PR target chosen by task-author at PR time (default `origin/main`). Per customer ruling (2026-05-28), the PR round happens after implementation, not before.
- [ ] T042 Mark spec 016 `Status: Complete` in `specs/016-token-economy-design/spec.md` after PR merges.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)** — no dependencies, runs first.
- **Foundational / Gate 0 (Phase 2)** — depends on Setup; blocks US1 and US2.
- **US1 (Phase 3)** — depends on Gate 0 T007 (specifically T005's headroom verification).
- **US2 (Phase 4)** — depends on Gate 0 T007. Most US2 proposal tasks run in parallel (T013–T024 [P]); T025 (`tech-lead.md` cuts) sequences after US1 T011.
- **Gate 1 (Phase 5)** — depends on US1 T012 + US2 T029 both complete.
- **Gate 2 (Phase 6)** — depends on Gate 1 T030 + T031.
- **Gate 3 / US3 (Phase 7)** — depends on Gate 2 T034.
- **Polish (Phase 8)** — depends on Gate 3.

### User Story Dependencies

- **US1**: depends on Gate 0; produces input for T025 (the `tech-lead.md` Half B cut).
- **US2**: depends on Gate 0 AND on US1 for T025 only. T013–T024 may proceed in parallel with US1 T008–T012.
- **US3**: depends on Gate 2 completion.

### Within Each User Story

- US1 sequential: T008 → T009 → T010 → T011 → T012.
- US2 parallel block: T013 through T024 in parallel. T025 strictly after US1 T011. T026 after all proposal tasks (T013–T025) complete. T027 → T028 → T029 strictly sequential.
- US3 sequential: T035 → T036 → T037 → T038.

### Parallel Opportunities

- T003 and T004 in parallel within Foundational.
- T013–T024 (12 proposal tasks) in parallel within US2.
- T039 and T040 in parallel within Polish.

---

## Parallel Example: User Story 2 proposal block

```bash
# After Gate 0 closes (T007), launch the 12 parallelizable proposal tasks together:
Task: "Propose cuts for sw-dev-team-template/.claude/agents/architect.md"
Task: "Propose cuts for sw-dev-team-template/.claude/agents/code-reviewer.md"
Task: "Propose cuts for sw-dev-team-template/.claude/agents/onboarding-auditor.md"
Task: "Propose cuts for sw-dev-team-template/.claude/agents/process-auditor.md"
Task: "Propose cuts for sw-dev-team-template/.claude/agents/project-manager.md"
Task: "Propose cuts for sw-dev-team-template/.claude/agents/qa-engineer.md"
Task: "Propose cuts for sw-dev-team-template/.claude/agents/release-engineer.md"
Task: "Propose cuts for sw-dev-team-template/.claude/agents/researcher.md"
Task: "Propose cuts for sw-dev-team-template/.claude/agents/security-engineer.md"
Task: "Propose cuts for sw-dev-team-template/.claude/agents/software-engineer.md"
Task: "Propose cuts for sw-dev-team-template/.claude/agents/sre.md"
Task: "Propose cuts for sw-dev-team-template/.claude/agents/tech-writer.md"

# T025 (tech-lead.md cuts) runs after US1 T011 — NOT in this parallel block.
```

---

## Implementation Strategy

### Gate-driven, not story-driven

This design pass differs from a feature MVP — both halves must land together for the composite gate to clear (FR-010). There is no "ship US1 alone" path. The gate model is the implementation strategy:

1. **Gate 0** — measure first. Cheap, blocks expensive mistakes. (Phase 2)
2. **Half A + Half B in parallel** — author the new section while proposing cuts on the other 12 files; `tech-lead.md` cuts wait for Half A. (Phases 3 + 4)
3. **Gate 1** — reviewers sign off independently. (Phase 5)
4. **Gate 2** — code-reviewer confirms no binding-rule loss. (Phase 6)
5. **Gate 3** — customer sign-off unlocks v1.2.0 / v1.3.0. (Phase 7)

### Parallel Team Strategy

- One specialist drives US1 sequence (T008 → T012).
- A second specialist drives the US2 proposal block (T013 → T024 in parallel where the engine supports it; T025 last).
- Reviewers serialize after each gate.

---

## Notes

- [P] tasks = different files, no dependencies on incomplete tasks.
- [Story] labels (US1/US2/US3) map tasks to the spec.md user stories for traceability.
- Commit cadence: one logical change per commit per the new D-1 atomic-commits rule (which the Half A section itself introduces — this design pass is the first work bound by it). Suggested commit groups: Gate-0 baseline; Half A authoring; per-file US2 cuts; Gate-1 sign-offs; Gate-2 diff fixes; Gate-3 sign-off + release-plan update; Polish.
- The `audit-tables.md` artifact is canonical and committed; do not gitignore it.
- Do NOT edit `.claude/agents/sme-template.md` — it is a scaffold, not a runtime contract (A-3).
- FR-013 boundary: no scripts / schemas / hooks / migrations touched. Any deviation requires re-opening the customer gate.
