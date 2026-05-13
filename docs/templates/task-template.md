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
- **Trigger:** `<comma-separated clauses, or "none">` (annotated by
  `tech-lead` at dispatch — see DoR).
- **Token budget (estimate):** tiny | small | medium | large | XL. Set
  by `tech-lead` at dispatch. See `tech-lead.md` § "Token economy".
- **Just-in-time file list:** `<focused paths the assignee must load
  first before expanding context>`.
- **Token actual:** filled at close by the assignee as a measured token
  count, an actual budget band, or an explicit not-captured reason. Flag
  at DoD if > 2× budget — triggers a renegotiation note in the change
  log.

---

## Token Budget

Use the smallest defensible band. Reviewers compare the selected band,
the JIT file list, and the task statement before work starts.

| Band | Intended use | Review expectation |
|---|---|---|
| tiny | One narrow lookup, confirmation, or wording-only change with one or two first-read files. | Should be directly dispatchable; challenge if the task needs broad context or multiple roles. |
| small | Single-file or tightly scoped work with a short just-in-time file list. | Should fit one specialist without background reading; challenge vague file lists. |
| medium | Moderate task with several related files or one clear cross-reference chain. | Should still have bounded first reads; reviewer checks that expansion points are explicit. |
| large | Complex task with many related files, review evidence, or multi-step verification. | Should justify why it is not split; reviewer checks that scope and closure evidence remain bounded. |
| XL | Oversized or high-context task expected to strain one dispatch. | Must be split before work starts or explicitly accepted as oversized in review. |

XL is a split candidate by default. If it remains XL, record the
explicit oversized acceptance in the task or review notes before
dispatch.

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
- [ ] **Token budget assigned** (tiny/small/medium/large/XL) and the
      focused just-in-time file list the assignee must load before any
      context expansion is named in the task spec (JIT context loading
      per `tech-lead.md` § "Token economy").
- [ ] **XL split-or-accept reviewed.** If the token budget is XL, the
      task is split or the reviewer explicitly accepts it as oversized
      before dispatch.
- [ ] For safety-critical or customer-flagged critical paths: customer
      sign-off referenced.
- [ ] **Workflow-pipeline trigger annotated.** `tech-lead` has
      recorded `Trigger: <clauses|none>` in the Identification
      block (see top of this file) per
      `docs/workflow-pipeline.md`. Trigger
      clauses are: (1) new external dependency, (2) public-API
      change, (3) cross-module boundary, (4) safety-critical /
      Hard-Rule-#4 path, (5) Hard-Rule-#7 path (auth / authz /
      secrets / PII / network-exposed), (6) data-model change.
- [ ] **Pipeline artifacts present if trigger fires.** If trigger
      is not `none`, the following exist and are linked from
      this task (unless an escape hatch under
      `docs/workflow-pipeline.md` is invoked and recorded):
      - `docs/prior-art/<task-id>.md` (`researcher`, stage 1)
      - ADR with three alternatives, OR no-ADR justification
        (`architect`, stage 2) — Phase 3 item, optional until
        v0.13.0
      - `docs/proposals/<task-id>.md` (`software-engineer`,
        stage 3)
      - Duel section in the proposal, status = closed
        (`qa-engineer` + `software-engineer`, stage 4)

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
- [ ] **Token budget, just-in-time file list, and token actual recorded**
      in Identification for future estimation use. Token actual uses a
      measured token count, actual budget band, or explicit not-captured
      reason. If actual > 2× budget, a one-line note appears in the
      Change/execution log.
- [ ] **Token usage recorded.** Aggregate tokens consumed across all
      agent dispatches for this task, with prompt hash and prompt class
      rather than full prompt text, appended to `docs/pm/TOKEN_LEDGER.md`
      by `project-manager`. Archive full prompts only when needed per
      `docs/pm/token-ledger/prompts/README.md`. On first use, copy
      `docs/templates/pm/TOKEN_LEDGER-template.md` to
      `docs/pm/TOKEN_LEDGER.md`; schema columns are `Date | Task ID |
      Agent | Prompt hash | Prompt class | Token budget | Token actual |
      Notes`.
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
