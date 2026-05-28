# Label taxonomy

<!-- TOC -->

- [Overview](#overview)
- [Status labels](#status-labels)
- [Role labels](#role-labels)
- [Priority labels](#priority-labels)
- [Meta labels](#meta-labels)
- [Milestones](#milestones)
- [Structured comment types](#structured-comment-types)
- [Rules](#rules)

<!-- /TOC -->

Shared coordination vocabulary for the issues-based multi-machine
coordination interface. Downstream repos create these labels via
`gh label create` (see the setup guide). The interface is opt-in — a
repo with none of these labels runs the normal single-operator workflow
unchanged.

---

## Status labels

Status is **single-valued**: a coordination issue carries exactly one
`status:*` label at a time. Transitions follow the claim-protocol
state machine.

| Label | Meaning |
|---|---|
| `status:queued` | Available to claim. No operator holds it. |
| `status:claimed` | Advisory checkout posted; claim sequence ran. Operator is self-assigned. |
| `status:in-progress` | Claimed and actively being worked. |
| `status:in-review` | Handed to review (typically `role:code-reviewer` or the relevant role). |
| `status:blocked` | Cannot proceed. Pair with `meta:blocked-external` or a BLOCKED comment. |
| `status:done` | Completed. Evidence gates satisfied via the durable handoff, not a comment. |

## Role labels

One label per canonical roster role. Attach the label that matches the
role responsible for the current work. Missing or conflicting
`role:*` labels trigger needs-triage handling.

`role:tech-lead`, `role:project-manager`, `role:architect`,
`role:software-engineer`, `role:researcher`, `role:qa-engineer`,
`role:sre`, `role:tech-writer`, `role:code-reviewer`,
`role:release-engineer`, `role:security-engineer`.

Note: `onboarding-auditor`, `process-auditor`, and `sme-<domain>`
agents are per-project and one-shot; route issues for them through
the owning canonical role per the agent roster.

## Priority labels

| Label | Meaning |
|---|---|
| `priority:p0` | Drop everything. Immediate action required. |
| `priority:p1` | High — current sprint / next available slot. |
| `priority:p2` | Normal — scheduled work. |
| `priority:p3` | Whenever — low urgency, no schedule pressure. |

## Meta labels

Additive — multiple meta labels may apply simultaneously.

| Label | Meaning |
|---|---|
| `meta:framework-maintenance` | Work targets the template framework, not a downstream product. |
| `meta:customer-approval-required` | Hard Rule #4 applies; live customer sign-off required before completion. |
| `meta:security-review-required` | Hard Rule #7 applies; `security-engineer` sign-off required. |
| `meta:blocked-external` | Blocker is outside the team (vendor, external dependency, customer delay). Pair with `status:blocked`. |

## Milestones

One milestone per release semver tag. Issues targeted at a release
carry that milestone. Milestone names match the version tag exactly
(e.g., `v1.1.0`).

## Structured comment types

Every structured comment carries: actor (operator id), role, and a
UTC timestamp. The payload fields below are in addition to those
common fields.

| Type | Payload |
|---|---|
| `CLAIM` | `operator`, `machine`, `session` — the tie-break key for concurrent claims. |
| `YIELD` | `reason` — why the claim was released (lost tie-break, voluntary release, or reclaim). |
| `PROGRESS` | Short status note — keeps the claim non-stale within the activity window. |
| `HANDBACK` | `target_role`; summary of what was completed and what remains. |
| `GATE-PASSED` | Which gate + pointer to the binding evidence. Observational only — see rules below. |
| `BLOCKED` | Blocker description. Pairs with `status:blocked`. |

## Rules

- **Status is single-valued.** Remove the old `status:*` label before
  applying the new one.
- **Role and priority labels are additive.** Multiple may coexist.
- **No comment satisfies an evidence gate.** A `GATE-PASSED` comment
  is an observation only. The binding evidence is the
  hook-captured `verification.*` record or the role-owned artifact on
  the durable handoff (`docs/handoffs/<task_id>.json`). The issue is
  authoritative for coordination state; the durable handoff is
  authoritative for scope, paths, role ownership, evidence gates, and
  completion state.
- **Opt-in.** All labels are downstream-creatable via `gh label create`.
  A repo without these labels runs the normal single-operator workflow.
