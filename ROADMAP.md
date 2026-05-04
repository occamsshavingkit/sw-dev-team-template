# Roadmap — sw-dev-team-template

<!-- TOC -->

- [What shipped in v0.13.0 → v0.17.0](#what-shipped-in-v0130-v0170)
- [Path to v1.0.0-rc3](#path-to-v100-rc3)
  - [Credit-free vs credit-gated](#credit-free-vs-credit-gated)
  - [Final binding step — IEEE 1028 readiness audit](#final-binding-step-ieee-1028-readiness-audit)
- [Post-rc4 / rc7](#post-rc4--rc7)
  - [v1.0.0-rc4](#v100-rc4)
  - [v1.0.0-rc5](#v100-rc5)
  - [v1.0.0-rc6](#v100-rc6)
  - [v1.0.0-rc7](#v100-rc7)
  - [v1.0.0 final](#v100-final)
  - [v1.1.0 — GitHub Projects coordination interface](#v110-github-projects-coordination-interface)
  - [v2 work](#v2-work)
- [Cross-release dependencies](#cross-release-dependencies)
- [Out-of-band items](#out-of-band-items)
- [Revision log](#revision-log)

<!-- /TOC -->

Forward-looking release plan. Authoritative source for what is
scheduled into the path to v1.0.0 final and beyond.

This file is a **living document**, amended whenever a customer
ruling changes scope. It is not a contract — the `CHANGELOG.md`
of a tagged release is the contract for what actually shipped.

SemVer rules (see `CHANGELOG.md` header for the binding wording):

- **MAJOR** — breaking change to the template contract.
- **MINOR** — additive, backward-compatible (0.y convention still
  permits breaking changes inside MINOR while we are pre-1.0).
- **PATCH** — non-structural clarifications.

Version currently staged in this worktree: **v1.0.0-rc7**. The
annotated `v1.0.0-rc6` tag is pushed and dereferences to
`dc2df300d77145ef4d2fe5d30033570bc64127a1`; GitHub Release object
publication waits for v1.0.0 final per the MINOR-only-Releases
convention, and the rc cycle is tag-only. `v1.0.0-rc7` is in candidate
tag-prep and is not tagged yet.

Release-state vocabulary for the active rc7-to-final path:

- `draft` — plan is still being shaped and has not completed
  specialist review.
- `release-prep` — release files are being updated for the rc tag, but
  the candidate has not completed final review or tagging.
- `review-complete` — in-tree rc7 work has passed recorded review and
  smoke evidence, but the release candidate is not tagged.
- `tagged` — the annotated `v1.0.0-rc7` git tag exists on the reviewed
  commit.
- `final-ready` — every gate in `docs/v1.0.0-final-checklist.md` is
  green.

Current state: **rc7 release-prep / not tagged / not final-ready**.

---

## What shipped in v0.13.0 → v0.17.0

The original v0.13/v0.14/v0.15 forward-plan sections of this file
are now history. `CHANGELOG.md` is the authoritative record. Brief
inventory:

- **v0.13.0** — retrofit playbook + Three-Path Rule landed.
- **v0.14.0–v0.14.4** — atomic-install / self-bootstrap / agent-name
  splice / `.template-customizations` stub-fill (issues #63–#67
  surfaced and closed).
- **v0.15.0–v0.15.1** — `docs/v1.0-rc3-checklist.md` drafted as a
  binding artefact, INDEX split (`INDEX-FRAMEWORK.md` /
  `INDEX-PROJECT.md`), `FW-ADR-NNNN` namespace separation,
  `upgrade.sh` clean-exit fix.
- **v0.16.0** — `scripts/stepwise-smoke.sh` + `SWDT_UPSTREAM_URL`
  override (rc3 C-7 deliverable), 16-issue retrofit-playbook
  revision pass, `docs/v2/triage-repair-agent.md` and
  `docs/v2/claude-mem-hybrid-ledger.md` placeholders.
- **v0.17.0** — `scripts/upgrade.sh --target <version>`, SPDX
  headers across `scripts/*.sh`, `docs/templates/github-actions-ci.yml`
  reference workflow.

The customer→product-owner rename (`#15`) forecast in the prior
roadmap **did not ship**. It is not scheduled for the v1.0 line;
re-evaluate post-1.0 if downstream evidence demands it.

---

## v1.0.0-rc3 — shipped 2026-04-26

Binding criteria are recorded in `docs/v1.0-rc3-checklist.md`
(C-1 through C-7). All seven were green at the rc3 cut; IEEE
1028 readiness audit recommended **SHIP**. The audit deliverable
itself is held upstream-private per redaction policy and is not
in this repo.

| # | Criterion | Standing | Remaining work |
|---|---|---|---|
| C-1 | Contract stability | green | label sweep at rc cut |
| C-2 | Migration infra (two major hops) | green | hold open through v0.14.x escalation window |
| C-3 | Retrofit playbook field-tested | green (substantively) | upstream attestation issue (credit-gated) |
| C-4 | Workflow-pipeline empirical usage | green (this session) | none — bar met |
| C-5 | Audit agents exercised | green | none — 18 findings logged, 0 major |
| C-6 | `v2-proposal` queue cleared | green (locally) | push placeholders + close issues (credit-gated) |
| C-7 | Stepwise upgrade smoke (v0.14.4 → rc3) | green | re-capture log at rc3 cut |

### Credit-free vs credit-gated

Credit-free items are local-only and unblocked. Credit-gated items
wait on the GitHub-credit policy decision recorded in the status
audit (#779: hold until 2026-05-01 or next milestone cut).

- **Credit-gated:** C-3 upstream attestation issue, C-6 v2-placeholder
  push + GitHub-side issue close, the v0.15.x..v0.17.x tag and
  Release push.
- **Credit-free:** all in-tree work — script runs, doc drafts,
  re-capture of the C-7 log at the rc cut.

### Audit + sign-off — held upstream-private

Per `docs/v1.0-rc3-checklist.md` § Audit + sign-off, after every
row is green `code-reviewer` runs an IEEE 1028-style audit pass.
`tech-lead` presents the audit summary; the customer ratifies
(or returns specific rows). Only on ratification does
`release-engineer` cut the rc tag. The audit deliverable is held
upstream-private per redaction policy because it cites concrete
downstream-project evidence files; it is not committed to this
repo.

---

## Post-rc4 / rc7

### v1.0.0-rc4

Integrated-feedback release candidate. Downstream use of
`v1.0.0-rc3` surfaced multiple framework gaps in issues #71 through
#83, including first-session onboarding, post-upgrade Step-0 drift,
tech-lead specialist-bypass drift, subagent reliability, deliverable-
shape scoping, upgrade-conflict churn, and retrofit redaction /
close-out gaps.

The rc4 stabilization queue is owned by `tech-lead`, with issue triage
and work packages recorded in `docs/v1.0-rc4-stabilization.md`.
`v1.0.0` final is blocked until every P0 item in that plan is closed
or explicitly downgraded by customer ruling.

Current rc4 state is `tagged`: the in-tree candidate has a recorded
review pass and the annotated tag exists. It is not `final-ready`;
downstream rc4 validation opened issues #84 through #103, so final now
goes through rc5.

### v1.0.0-rc5

Release-boundary candidate for issues #84 through #103. This rc folds
post-rc4 downstream feedback into one validation target: upgrade
bootstrap safety, Codex adapter parity, local-supplement conflict
handling, evidence-backed final gates, framework / project boundary
rules, release-audit scoping, specialist queue / closure discipline,
and missing Codex completion/status recovery.

Current rc5 state is `tagged`: the annotated `v1.0.0-rc5` tag exists,
but rc5 did not close the whole final boundary. Follow-up fixes for
#104 and #105, plus the required immutable-history wording for #84,
moved the release path to rc6 instead of promoting rc5 directly to
final.

### v1.0.0-rc6

Focused release-governance candidate for issues #84, #104, and #105.
This rc lands the remaining Codex dispatch-policy binding, post-copy
manifest verification evidence, and the release-history correction that
keeps `v1.0.0-rc3` immutable. rc6 mitigation for #84 is current/future
script behavior plus documented workaround/evidence for already-affected
rc3-era downstream trees; it is not a retroactive rc3 rewrite.

Current rc6 state is `tagged`: the annotated `v1.0.0-rc6` tag exists
on reviewed commit `dc2df300d77145ef4d2fe5d30033570bc64127a1`.
`v1.0.0` final is blocked until rc7 is cut, downstream validation
completes, and every gate in `docs/v1.0.0-final-checklist.md` is green
or has an explicit customer-approved exception.

### v1.0.0-rc7

Release-candidate tag-prep boundary for issue #116 concise specialist
briefs, the no-full-context-fork rule, and cross-harness validation. The
template claims Claude Code / Codex parity, so final cannot rely on
evidence from only one AI; rc7 must record overlapping release-relevant
validation from both Claude Code and Codex, or an explicit
customer-approved exception for any unavailable harness capability.

Current rc7 state is `release-prep`: it is the in-tree candidate for
tag preparation, but it is not tagged and is not final-ready.

### v1.0.0 final

Cut only after every objective gate in
`docs/v1.0.0-final-checklist.md` is green or has an explicit
customer-approved exception. This includes the downstream clean-window
/ sample gate, zero final-blocking issues, smoke and upgrade evidence,
Claude Code / Codex parity evidence, release / review sign-offs,
customer ratification, GitHub Release object steps, and rollback /
upgrade notes. Final freezes the binding-rule surface: any post-1.0
change to `CLAUDE.md` § Hard rules or the canonical-role roster
requires an ADR and customer sign-off. The v0.y MINOR-as-breaking
convention ends; from 1.0.0 onward, MAJOR is reserved for actual
breaking changes.

Objective final-readiness gates live in
`docs/v1.0.0-final-checklist.md`. At minimum, final needs a downstream
clean-window/sample, zero final-blocking issues, smoke and upgrade
evidence, cross-harness parity evidence, release-engineer and
code-reviewer sign-offs, customer ratification, GitHub Release object
creation steps, and rollback / upgrade notes.

### v1.1.0 — GitHub Projects coordination interface

Add a GitHub-native coordination layer so multiple people can run the
agent set from different machines while staying aligned on one task
list, Kanban board, and issue-backed work queue.

Planned scope:

- Define a project-board convention for template-driven work:
  statuses, ownership, priority, milestone/release, blocked state,
  and agent-role routing fields.
- Add issue / task templates that map cleanly to the current workflow
  pipeline: trigger annotation, prior-art / proposal / duel links,
  acceptance criteria, review owner, and release note impact.
- Document the operating model for multi-machine agent sessions:
  one GitHub issue per coherent task, comments as handoff records,
  labels for specialist routing, and no direct customer escalation
  except through the active `tech-lead`.
- Provide a lightweight setup guide, and optionally a script or `gh`
  command transcript, for creating the GitHub Project, labels, saved
  views, and default fields.
- Define sync expectations between in-repo registers
  (`docs/OPEN_QUESTIONS.md`, `docs/DECISIONS.md`, PMBOK artifacts)
  and GitHub issues/projects, including which artifact is authoritative
  for each kind of state.
- Integrate `docs/model-routing-guidelines.md` into the multi-operator
  playbook so teams know when agents should use plan mode, raise model
  tier, or increase reasoning effort across OpenAI / ChatGPT and
  Claude / Claude Code deployments.

Non-goals for v1.1.0:

- Do not replace `docs/OPEN_QUESTIONS.md`, `CUSTOMER_NOTES.md`, or
  `docs/DECISIONS.md` as binding project records.
- Do not weaken the rule that only `tech-lead` talks to the customer.
- Do not require GitHub Projects for single-operator or offline
  downstream projects; the interface is additive and opt-in.

Exit criteria:

- A documented GitHub Projects field/status schema exists.
- At least one issue/task template supports agent-routed work from
  intake through review.
- Agent model-routing guidelines are reviewed against current provider
  docs and mapped to issue labels or fields where useful.
- A fresh downstream project can follow the setup guide and produce a
  usable board without hand-editing the template internals.
- The coordination model has been smoke-tested with at least two
  concurrent agent operators on separate machines, or explicitly
  deferred with a narrower single-operator validation note.

### v2 work

The v2 line is reserved for items that require a contract break
beyond what `migrations/*.sh` can automate. Current placeholders:

- `docs/v2/triage-repair-agent.md` — project triage + repair agent
  for retrofit adoption (issue #3).
- `docs/v2/claude-mem-hybrid-ledger.md` — claude-mem / SQLite
  hybrid ledger (issue #27).

Both are deferred-with-rationale, not scheduled. v2.0 picks them up
when (a) v1.0 has shipped and (b) a customer ruling promotes one
or both into a v2 milestone.

---

## Cross-release dependencies

```
v0.17.0 (local tag; public Release at v0.16.0)
   │
   │  depends on: rc3 checklist all green + IEEE 1028 audit
   ▼
v1.0.0-rc3 ◄── re-entry checklist signed off, field-use candidate
   │
   │  depends on: issues #71-#83 triaged + P0 fixes integrated
   ▼
v1.0.0-rc4
   │
   │  depends on: issues #84-#103 triaged + release-boundary fixes integrated
   ▼
v1.0.0-rc5
   │
   │  depends on: #84 / #104 / #105 follow-up fixes integrated
   ▼
v1.0.0-rc6
   │
   │  depends on: issue #116 concise specialist-brief/no-full-context-fork rule
   │              + Claude Code / Codex validation evidence
   ▼
v1.0.0-rc7
   │
   │  depends on: rc7 downstream-clean window + final checklist gates
   ▼
v1.0.0 (GA)
```

The dependency chain is one-way: each release's exit criteria
must pass before the next is cut. v1.0.0-rc3 is gated on the
checklist + audit, not on the calendar.

---

## Out-of-band items

Things that may interrupt the linear plan:

- **Upstream Claude Code harness issues.** A breaking harness
  behavioural change that affects template contracts can force a
  PATCH or MINOR ahead of the rc cut.
- **Customer-initiated scope additions.** A new binding requirement
  (new hard rule, new role, regulatory constraint) is triaged by
  `tech-lead`; reshuffles are recorded in `docs/pm/CHANGES.md` +
  this file.
- **Real downstream incidents.** A downstream production incident
  traceable to a template rule failure takes priority over planned
  scope; ships as a PATCH between MINOR bumps. Precedent: issue
  #63 (atomic-install) surfaced from a downstream project and
  shipped in v0.14.3.

---

## Revision log

| Date | Change | Who |
|---|---|---|
| 2026-04-23 | Roadmap created after v0.12.0 tag; customer ruled path to v1.0.0-rc3 via v0.13.0 / v0.14.0 / v0.15.0. | `tech-lead` |
| 2026-04-26 | Rewrite for the rc3 era; v1.0.0-rc3 cut and pushed; audit deliverables held upstream-private per redaction policy. | `tech-writer` + `tech-lead` |
| 2026-05-03 | Added post-v1.0.0 GitHub Projects coordination interface to the v1.1.0 plan. | `tech-lead` |
| 2026-05-03 | Added model-routing guideline deliverable to the post-v1.0.0 coordination plan. | `tech-lead` |
| 2026-05-03 | Made v1.0.0-rc4 mandatory after downstream rc3 issues #71-#83; added stabilization-plan pointer. | `tech-lead` |
| 2026-05-03 | Normalized rc4 release-state vocabulary and linked final readiness gates. | `project-manager` |
| 2026-05-03 | Made v1.0.0-rc5 mandatory after downstream rc4 issues #84-#103; final now depends on rc5 validation. | `release-engineer` |
| 2026-05-04 | Tagged and pushed v1.0.0-rc6 for #84, #104, and #105; final remains blocked on downstream validation and the checklist gates. | `release-engineer` |
| 2026-05-04 | Prepared v1.0.0-rc7 candidate/tag-prep files for issue #116 concise specialist-brief/no-full-context-fork scope and Claude Code / Codex parity evidence; no tag yet. | `release-engineer` |
