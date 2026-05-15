# Proposal — <task-id>

Owned by `software-engineer`. Produced at workflow-pipeline stage 3
for tasks whose trigger annotation fires any of the six clauses in
`docs/proposals/workflow-redesign-v0.12.md` §2. The proposal is the
"think-in-workspace" gate — the engineer records the intended
implementation shape before writing production code. Solution Duel
(§Duel below) is the adversarial review of this proposal before code
starts.

---

## 1. Task reference

- **Task ID:** T-NNNN
- **One-line task statement:** copy from `docs/tasks/T-NNNN.md`.
- **Trigger clauses that fire:** `<list>`.
- **Prior-art reference:** `docs/prior-art/T-NNNN.md`.
- **ADR reference (if §2 trigger also required ADR):**
  `docs/adr/ADR-NNN-<slug>.md`.

## 2. Chosen ADR path

If the task produced an ADR with Minimalist / Scalable / Creative
alternatives, name which alternative this proposal implements and
why. If no ADR was produced (trigger fired only on clauses that
don't require an ADR), state that and justify.

- **Alternative chosen:** M | S | C | (none — no ADR)
- **Reason:** one sentence.

## 3. Implementation sketch

Interface-level or pseudocode. **Not production code.** The point
is to let `qa-engineer` find three ways this will fail in
production *before* the engineer spends tokens on implementation.

- Module / file set touched.
- Public interfaces introduced or modified.
- Key internal data shapes.
- Control flow in broad strokes.

## 4. Dependencies touched

- Libraries added or version-bumped. Each cites the prior-art
  row for its candidate.
- Internal modules whose interfaces are consumed.
- External services / APIs.

## 5. Test plan outline

Not full test code — outline of coverage `qa-engineer` will
expect. Cross-references `docs/qa/*-test-plan.md` levels.

- Unit: named units + coverage approach.
- Integration: named interfaces + stub strategy.
- System / acceptance: named scenarios where applicable.
- Performance / security: where warranted by trigger clauses (4)
  or (5), pointer to the relevant plan.

## 6. Risks and mitigations

Two-column. Risks the engineer already sees; mitigations planned.
The Duel section below is where `qa-engineer` surfaces the risks
the engineer missed.

| Risk | Mitigation |
|---|---|

## 7. Open questions

Anything the engineer needs resolved before code starts. Each
question routed explicitly:

- Q: <question> — **Route:** `architect` / `researcher` /
  `security-engineer` / customer via `tech-lead`.

## 8. Duel

**Solution Duel** — pre-code adversarial review (workflow-pipeline
stage 4). `qa-engineer` writes three ways-to-fail; engineer either
revises the proposal above in-place or writes a rebuttal here.
One round only; unresolved findings escalate to `tech-lead` per
`qa-engineer.md` round-limit rule.

On Hard-Rule-#7 paths (trigger clause 5), `security-engineer`
participates as a joint duelist alongside `qa-engineer`.

### 8.1 Findings (`qa-engineer`)

Three findings, concrete failure modes that could occur in
production against this proposal. Numbered so rebuttals can cite.

- **F-1:** <failure mode> — **How it fails:** <one line> —
  **Severity if unaddressed:** blocker / major / minor.
- **F-2:** ...
- **F-3:** ...

### 8.2 Rebuttals / revisions (`software-engineer`)

One entry per finding. Either:
- **Revised.** The proposal above was updated to address the
  finding (cite the section number that changed).
- **Accepted risk.** The finding is acknowledged but the
  engineer argues it is acceptable as-stated. Requires
  `tech-lead` ratification — cite the ratification (link to
  `docs/intake-log.md` turn, or `CUSTOMER_NOTES.md` entry if the
  risk was escalated to the customer).
- **Disputed.** Engineer believes the finding is wrong. Escalate
  to `tech-lead` for resolution per round-limit rule.

### 8.3 Status

- Round: 1 (default) / escalated to tech-lead after round 1
- Outcome: all addressed | some accepted-risk | escalated to customer
- Date closed: YYYY-MM-DD

## 9. Post-close

Retention: durable for non-trivial tasks; transient (archive after
next milestone close) below threshold. Move to
`docs/proposals/ARCHIVE/` when archived.
