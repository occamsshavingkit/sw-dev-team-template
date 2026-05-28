# Multi-operator model

<!-- TOC -->

- [Overview](#overview)
- [One issue, one handoff](#one-issue-one-handoff)
- [Authority split](#authority-split)
- [Bidirectional link](#bidirectional-link)
- [Structured comment types and the gate-safety invariant](#structured-comment-types-and-the-gate-safety-invariant)
- [Operating model](#operating-model)
  - [Opt-in and additive](#opt-in-and-additive)
  - [One issue per coherent task](#one-issue-per-coherent-task)
  - [Comments as handoff records](#comments-as-handoff-records)
  - [Labels for specialist routing](#labels-for-specialist-routing)
  - [Milestones for release grouping](#milestones-for-release-grouping)
  - [Only tech-lead talks to the customer](#only-tech-lead-talks-to-the-customer)
  - [Degraded-state behavior](#degraded-state-behavior)
  - [Cross-references](#cross-references)

<!-- /TOC -->

This document covers the structural mapping between GitHub coordination
issues and durable handoff records (FR-006), the authority split governing
which artifact is definitive for which kind of state, the structured
comment types and gate-safety invariant (FR-007, FR-008), and the
multi-machine operating model and playbook (FR-009, FR-014).

---

## Overview

The multi-operator coordination interface layers on top of the
durable-handoff spine. GitHub issues provide a shared, at-a-glance
work queue readable from any machine. Durable handoffs remain the
binding source for task scope, evidence, and completion state.

The interface is opt-in. A downstream project that does not adopt it
runs the normal single-operator workflow without any required changes.
See `label-taxonomy.md` for the label vocabulary and `claim-protocol.md`
for the advisory checkout sequence.

---

## One issue, one handoff

One coherent task corresponds to exactly one GitHub coordination issue
and exactly one durable handoff record (`docs/handoffs/<task_id>.json`).

A coherent task is a bounded unit of work with a single owning role, a
defined scope, and identifiable completion criteria. If a candidate task
spans multiple distinct scopes or owning roles, split it before creating
the issue and handoff.

Violations of the one-to-one rule — one issue covering multiple tasks,
or multiple issues pointing at the same handoff — require resolution
before the issue can advance past `status:queued`. The procedure is:
split or merge as needed, then re-file.

---

## Authority split

Each kind of state has exactly one authoritative record. The two
artifacts do not duplicate authority; they complement it.

| State kind | Authoritative record |
|---|---|
| Scope, file paths, role ownership | Durable handoff (`docs/handoffs/<task_id>.json`) |
| Evidence gates and completion state | Durable handoff |
| Human-readable task description | GitHub issue body |
| Label-visible status (`status:*`) | GitHub issue labels |
| Milestone grouping | GitHub issue milestone |
| Claim and comment audit trail | GitHub issue comment stream |

The durable handoff is the binding record for everything agents act on:
what the task covers, which paths it touches, which role owns it, and
whether it is done. Evidence gates are never satisfied by an issue
comment; see `claim-protocol.md` invariant I5 and `label-taxonomy.md`
Rules for the no-comment-gate invariant.

The GitHub issue is authoritative for coordination-visible state only.
Its labels show current status at a glance; its milestone groups the
task into a release; its comment stream records the claim, progress, and
handoff history reconstructable across machines. None of that state
overrides or duplicates what is recorded in the handoff.

---

## Bidirectional link

The issue-to-handoff link runs in both directions.

The issue body references the durable handoff by `task_id` — operators
reading the issue can locate the binding record immediately.

The durable handoff carries an optional `github_issue` field. When
present, `github_issue` holds the issue number or URL of the
coordination issue. Absence of `github_issue` is valid: handoffs
created before the coordination interface was adopted, or in a project
that does not opt in, remain valid without it.

When `github_issue` is set, automated tooling can traverse the link in
either direction — from the issue to the handoff via `task_id`, or from
the handoff to the issue via `github_issue` — making the mapping
machine-checkable (FR-017).

---

## Structured comment types and the gate-safety invariant

*FR-007, FR-008.*

Every coordination issue carries a comment stream. The six structured
comment types, together, let any operator reconstruct the full
claim → progress → handback history for a task from the issue alone —
without consulting any other artifact.

### Comment types

Each structured comment records a common header: actor (operator id),
role, and a UTC timestamp. The payload fields specific to each type are
defined in `label-taxonomy.md` under "Structured comment types"; this
section describes what each type means in the coordination sequence
rather than repeating those field tables.

**CLAIM** — records that an operator has taken advisory checkout of the
task. The claim payload identifies the operator, the machine, and the
session. This comment is the starting point of a task's coordination
thread; it is mirrored by self-assignment and the `status:claimed`
label. When a tie-break is needed (two near-simultaneous claims), the
CLAIM comments are the evidence used to resolve it.

**YIELD** — records that an operator released the claim. The payload
states why: lost a tie-break, voluntary release, or reclaim by another
party. YIELD closes a claim span in the history. A reader reconstructing
the timeline can pair each YIELD with the CLAIM it closes.

**PROGRESS** — a lightweight status note confirming the operator is
still active. It does not change task state but keeps the claim from
going stale within the documented activity window. A sequence of
PROGRESS comments with timestamps shows continuous ownership through a
long work session.

**HANDBACK** — records the transition of responsibility to another role.
The payload names the target role and summarizes what was completed and
what remains. HANDBACK is the structured marker that separates one
ownership span from the next; it drives the label change (typically to
`status:in-review` or back to `status:queued`).

**GATE-PASSED** — observational record that a named evidence gate
appears satisfied, with a pointer to where the binding evidence lives.
See the invariant below for the strict constraint on what this comment
does and does not mean.

**BLOCKED** — records that the task cannot proceed, with a description
of the blocker. Pairs with the `status:blocked` label and, where
applicable, `meta:blocked-external`. A subsequent PROGRESS or CLAIM
comment (after the blocker is resolved) resumes the thread.

### Reconstructing task history

Reading the comment stream in order gives the full coordination
timeline. A CLAIM opens an ownership span; PROGRESS entries extend it;
a YIELD or HANDBACK closes it; a new CLAIM (by the same or a different
operator) opens the next span. GATE-PASSED comments mark checkpoints
in the sequence. BLOCKED comments mark pauses and their causes.

This reconstruction is self-contained within the issue. It does not
require access to any in-repo file — which is the property that makes
the interface useful across machines and operators who may not share a
local working tree.

### Gate-safety invariant (CRITICAL)

No comment type — including GATE-PASSED — satisfies an evidence gate.
A GATE-PASSED comment is observational only. The binding evidence
remains the hook-captured `verification.*` records and the role-owned
artifacts recorded on the durable handoff (`docs/handoffs/<task_id>.json`).

To state this without ambiguity: a GATE-PASSED comment does not satisfy
the gate it names. It is a pointer to where the binding evidence lives,
not a substitute for it. The authority split established in the
[Authority split](#authority-split) section above applies in full:
evidence gates and completion state are authoritative in the durable
handoff, not in any issue comment.

This invariant holds even if the GATE-PASSED comment appears correct
and timely. The comment may be stale, incorrect, or posted without the
underlying hook having run. Tooling and reviewers checking gate
satisfaction MUST read the `verification.*` records and role-owned
artifacts on the handoff directly; the comment stream is not a
substitute for that check.

See also: `claim-protocol.md` invariant I5 and the "Rules" section of
`label-taxonomy.md` for the matching constraints at the label and
protocol level.

---

## Operating model

*FR-009, FR-014.*

This section is the operator playbook for running the agent set across
multiple machines with GitHub Issues as the shared work queue.

### Opt-in and additive

The coordination interface is opt-in. A downstream project that does not
create the label set, milestones, or issue templates runs the normal
single-operator workflow without any required changes. Nothing in the
framework requires GitHub Issues to be present. Absence of the
coordination surface is always valid — for solo-operator projects, offline
projects, or projects that have not yet adopted it.

When a downstream project does opt in, the interface is additive. It does
not replace the in-repo registers (`CUSTOMER_NOTES.md`,
`docs/OPEN_QUESTIONS.md`, `docs/DECISIONS.md`, `docs/pm/*`). Those
registers remain the binding records. GitHub Issues carry coordination
state only; they are not authoritative for customer truth, open questions,
decisions, or completion evidence.

### One issue per coherent task

Each unit of work has exactly one coordination issue and one durable
handoff record (`docs/handoffs/<task_id>.json`). The issue links to the
handoff by `task_id`; the handoff optionally links back via the
`github_issue` field. The authority split — which artifact is definitive
for which kind of state — is established in the [Authority
split](#authority-split) section above and in `register-authority.md`.

When a candidate task spans multiple scopes or owning roles, split it
before creating the issue. When two issues cover the same task, merge or
re-file before the issue advances past `status:queued`.

### Comments as handoff records

The issue comment stream is the coordination audit trail. Operators post
structured comments at each transition: CLAIM when picking up work,
PROGRESS to keep the claim current, HANDBACK when transferring to another
role, YIELD when stepping back, BLOCKED when a blocker stops progress, and
GATE-PASSED as an observational pointer to where binding evidence lives.

The comment stream is self-contained. Any operator on any machine can
reconstruct the full ownership history — who claimed the task, when, what
happened, and who holds it now — from the issue alone, without reading
local working trees or in-repo files.

The gate-safety invariant is absolute: no comment type satisfies an
evidence gate. See the [Structured comment types and the gate-safety
invariant](#structured-comment-types-and-the-gate-safety-invariant)
section above and claim-protocol.md invariant I5.

### Labels for specialist routing

Labels provide at-a-glance routing state visible from any machine.

A `role:*` label identifies which canonical roster role owns the current
work. When an issue is ready for a different specialist, the HANDBACK
comment names the `target_role` and the operator updates the `role:*`
label. An issue with no role label, or with conflicting role labels, is
unrouted and enters needs-triage handling until a `role:*` label is
applied.

A `status:*` label tracks the task through its lifecycle (queued →
claimed → in-progress → in-review → done, with blocked as a pause state).
Status is single-valued: remove the current `status:*` label before
applying the next one.

`priority:*` and `meta:*` labels carry supplemental routing signals. In
particular, `meta:customer-approval-required` flags that Hard Rule #4
applies and live customer approval is required before completion;
`meta:security-review-required` flags that Hard Rule #7 applies and
`security-engineer` sign-off is required.

For the full label vocabulary, see `label-taxonomy.md`.

### Milestones for release grouping

One milestone per release semver tag. Issues targeted at a release carry
that milestone. The milestone name matches the version tag exactly
(example: `v1.1.0`). Milestone grouping is the only release-coordination
primitive in this interface; schedule and scope authority remain in
`docs/pm/SCHEDULE.md` and `ROADMAP.md`.

### Only tech-lead talks to the customer

The coordination interface does not create a second customer-interface
path. The rule from the framework's core routing model is preserved
without exception: only `tech-lead` interfaces with the customer.

GitHub Issues are a coordination surface for the operator team. An issue
comment is never a channel to the customer. Questions that require a
customer ruling follow the escalation protocol: the asking agent routes to
`tech-lead`; `tech-lead` batches questions in `docs/OPEN_QUESTIONS.md`
and asks one at a time, as the final line of the turn, only when all
agents and tools are idle. Customer rulings land in `CUSTOMER_NOTES.md`
via `researcher` — not in issue comments.

`meta:customer-approval-required` signals that a customer ruling is
needed before an issue can reach `status:done`. That label is set by the
operator; the ruling itself is obtained through the standard escalation
path, not by commenting on the issue.

### Degraded-state behavior

The interface is advisory. Several degraded conditions have defined
handling rather than silent failure:

- **Missing role label**: the issue is unrouted; apply needs-triage
  handling (add the correct `role:*` label before proceeding).
- **Stale claim**: no PROGRESS or HANDBACK comment within the project's
  documented staleness window; reclaimable via the stale-claim recovery
  sequence in `claim-protocol.md`.
- **One issue covering multiple tasks**: violates the one-to-one rule;
  split and re-file before the issue can advance past `status:queued`.
- **Label deleted or renamed downstream**: routing degrades to manual
  inspection; the operating model documents the expected label set so
  gaps are detectable. Re-create the missing labels via `gh label create`
  following `setup-guide.md`.

### Cross-references

- Claim sequence and tie-break: `claim-protocol.md`.
- Full label vocabulary: `label-taxonomy.md`.
- Register-vs-issue authority table: `register-authority.md`.
- Setup transcript (creating labels, milestones, and templates in a fresh
  repo): `setup-guide.md`.
