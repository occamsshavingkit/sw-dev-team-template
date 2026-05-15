---
name: task-template
description: INVEST plus DoR plus DoD task template for per-task work units.
template_class: task
---


# Task — <ID> — <one-line title>

<!-- TOC -->

- [Identification](#identification)
- [Statement](#statement)
- [Acceptance criteria](#acceptance-criteria)
- [INVEST check (stories only)](#invest-check-stories-only)
- [Definition of Ready (DoR)](#definition-of-ready-dor)
- [Token budget](#token-budget)
- [Definition of Done (DoD)](#definition-of-done-dod)
- [Dependencies and risks](#dependencies-and-risks)
- [Change / execution log](#change--execution-log)

<!-- /TOC -->

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
- **Tier:** tiny | standard | regulated/safety | release
- **Assignee (agent):** `software-engineer` | `qa-engineer` | `sre` | …
- **Estimate:** ≤ 2 days of one person's effort, else split.
- **Trigger:** `<comma-separated clauses, or "none">` (annotated by
  `tech-lead` at dispatch — see DoR).
- **Boundary:** Product work | Project-filled register | Template
  upgrade | Framework maintenance (see
  `docs/framework-project-boundary.md`).
- **Artifact scope before writing:** <state the concrete product,
  register, template-upgrade, or framework-maintenance paths in scope;
  release/version audits also classify downstream product artifact vs
  project-filled template register vs upstream framework/template
  artifact>.

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
- [ ] Boundary classified. If this is product work, framework-managed
      paths are excluded from the task unless explicitly authorized.
- [ ] Audit/fix prompt requires the assignee to state artifact scope
      before writing. For product-only release audits, `TEMPLATE_VERSION`,
      template versioning docs, rc stabilization docs, scaffold / upgrade
      scripts, and other framework-managed release files are explicitly
      out of write scope.
- [ ] Required `CUSTOMER_NOTES.md` entries exist or are explicitly
      not needed.
- [ ] Estimate assigned.
- [ ] For safety-critical or customer-flagged critical paths: customer
      sign-off referenced.
- [ ] **Workflow-pipeline trigger annotated.** `tech-lead` has
      recorded `Trigger: <clauses|none>` in the Identification
      block (see top of this file) per
      `docs/workflow-pipeline.md` § Trigger threshold. Trigger
      clauses are: (1) new external dependency, (2) public-API
      change, (3) cross-module boundary, (4) safety-critical /
      Hard-Rule-#4 path, (5) Hard-Rule-#7 path (auth / authz /
      secrets / PII / network-exposed), (6) data-model change.
- [ ] **Pipeline artifacts present if trigger fires.** If trigger
      is not `none`, the following exist and are linked from
      this task (unless an escape hatch under
      `docs/workflow-pipeline.md` § Escape hatches is invoked and
      recorded):
      - `docs/prior-art/<task-id>.md` (`researcher`, stage 1)
      - ADR with three alternatives, OR no-ADR justification
        (`architect`, stage 2) — Phase 3 item, optional until
        v0.13.0
      - `docs/proposals/<task-id>.md` (`software-engineer`,
        stage 3)
      - Duel section in the proposal, status = closed
        (`qa-engineer` + `software-engineer`, stage 4)

---

## Token budget

Token-budget bands per `specs/006-template-improvement-program/research.md`
R-2; ledger row recorded at closure per FR-005 in
`docs/pm/TOKEN_LEDGER.md`.

- **Token budget:** `tiny` | `small` | `medium` | `large` | `xl`
- **JIT file list:** <concise list of paths the assignee should load
  first; omit files only needed transitively>
- **Token actual:** <filled at closure if material; `wc -w` proxy of
  prompts + load-set at dispatch time>

Bands:

| Band | Words (proxy) | Tokens (approx) | Intended use |
|---|---:|---:|---|
| Tiny | < 1 500 | < ~2 000 | one-file fix, no specialist chain |
| Small | 1 500 – 6 000 | ~2 000 – ~8 000 | one specialist, focused files |
| Medium | 6 000 – 19 000 | ~8 000 – ~25 000 | 2–3 specialists, limited docs |
| Large | 19 000 – 60 000 | ~25 000 – ~80 000 | triggered workflow, multiple artifacts |
| XL | > 60 000 | > ~80 000 | split unless explicitly approved |

---

## Definition of Done (DoD)

Team-wide. Apply the rows that match the task tier and deliverable
shape. Tiny documentation or one-line script fixes still need scope,
owner, relevant verification, and `code-reviewer` before commit; they
do not inherit release or token-ledger ceremony unless the thresholds
below apply. Regulated/safety and release tasks always use the
strictest applicable gates.

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
- [ ] **Token usage recorded when estimation value is material.**
      Required for `standard`, `regulated/safety`, and `release`
      tier tasks, or any task with three or more agent dispatches,
      a context-limit retry, or a PM request for calibration. Tiny
      tasks may record "not logged: below threshold" in this task's
      execution log instead. When required, aggregate tokens consumed
      across all agent dispatches for this task, plus each dispatch's
      prompt (verbatim), are appended to `docs/pm/TOKEN_LEDGER.md`
      by `project-manager`. On first use, copy
      `docs/templates/pm/TOKEN_LEDGER-template.md` to
      `docs/pm/TOKEN_LEDGER.md`; schema columns are
      `Date | Task ID | Agent | Tokens | Prompt (verbatim, fenced) |
      Notes`.
- [ ] Change merged to the integration branch. `release-engineer`
      confirmation is required for release-tier tasks, deployable
      artifacts, packaging changes, tags, migrations, and any change
      whose rollback or distribution path is non-trivial.
- [ ] Commit / PR split matches the boundary: product work is not mixed
      with template upgrade or framework maintenance, unless the task
      records explicit customer authorization for the combined scope.
- [ ] Product-only audit/fix diff contains no accidental edits to
      framework-managed files. Any discovered framework gap was filed or
      queued upstream via `docs/ISSUE_FILING.md` and left unchanged in
      the downstream copy.

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
