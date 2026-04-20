# Task — <ID> — <one-line title>

One file per task (or one row per task in a task tracker). Terms are
binding per `docs/glossary/ENGINEERING.md` (and `docs/glossary/PROJECT.md`
for project-specific terms) — note *task* is engineering work under a
story; *story* is the user-visible unit.

Owned by a single agent (the "assignee"). Routed by `tech-lead`.

---

## Identification

- **ID:** T-NNNN (or tracker URL)
- **Parent story:** S-NNNN (or "standalone" / "spike")
- **Type:** Task | Spike | Bug fix | Refactor | Chore
- **Assignee (agent):** `software-engineer` | `qa-engineer` | `sre` | …
- **Estimate:** ≤ 2 days of one person's effort, else split.

---

## Statement

One or two sentences. What this task changes, where.

For stories, use the canonical form:
> As a [role], I want [capability], so that [benefit].

For pure engineering tasks, state the observable change and where:
> Replace the in-memory store in `<path>` with a persistent equivalent
> backed by <storage>. No externally-visible behavior change.

---

## Acceptance criteria

Each criterion is observable and checkable, one per line. A reviewer
can mark each pass/fail without interpretation.

- AC-1: <condition>
- AC-2: <condition>

Acceptance criteria are scoped to *this* task. Team-wide completion
standards live in the Definition of Done below.

---

## INVEST check (stories only)

- [ ] **I**ndependent — can be completed without waiting on other open
      work, or dependencies are listed below.
- [ ] **N**egotiable — scope can shift without invalidating the point.
- [ ] **V**aluable — the customer or a downstream user would pay for
      the outcome (even if indirectly).
- [ ] **E**stimable — the team agrees on an estimate band.
- [ ] **S**mall — fits in one iteration.
- [ ] **T**estable — acceptance criteria are checkable.

If any box is unchecked, the item is not ready.

---

## Definition of Ready (DoR)

- [ ] Acceptance criteria written and reviewed by `tech-lead`.
- [ ] Dependencies listed and either cleared or scheduled.
- [ ] Required `CUSTOMER_NOTES.md` entries exist or are explicitly
      not needed.
- [ ] Estimate assigned.
- [ ] For safety-critical or customer-flagged critical paths: customer
      sign-off referenced.

---

## Definition of Done (DoD)

Team-wide. Applies to every completed task, regardless of type.

- [ ] Code written, compiles / builds clean.
- [ ] Unit tests written alongside code (not after).
- [ ] Integration or acceptance tests updated by `qa-engineer` where
      scope warrants.
- [ ] **Relevant test suite is green, with raw runner output** (exit
      code, pass/fail counts, timestamp) attached to this task
      before closure. `qa-engineer` verifies by re-running the
      suite, not by accepting a summary. A failing suite reverts
      the task to `software-engineer`; closure is blocked until
      re-verified.
- [ ] `code-reviewer` has approved.
- [ ] Documentation updated by `tech-writer` where user-visible.
- [ ] No new open defects of severity ≥ <threshold>.
- [ ] Requirements traceability row updated.
- [ ] Change merged to the integration branch and deployable artifact
      confirmed by `release-engineer`.

---

## Dependencies and risks

- **Depends on:** <task IDs, PRs, external decisions>
- **Blocks:** <what can't start until this is done>
- **Risks / assumptions:** <one line each, with mitigation or trigger>

---

## Change / execution log

Append-only. Short. Timestamped only when the order matters.

- Created: YYYY-MM-DD by <agent>
- Estimate revised: YYYY-MM-DD — reason
- Scope change: YYYY-MM-DD — link to decision or `CUSTOMER_NOTES.md` entry
- Closed: YYYY-MM-DD — result (shipped / dropped / split)
