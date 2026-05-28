# Contract: Label / Milestone / Comment-Type Vocabulary

The shared coordination vocabulary. Created in a downstream repo via `gh label create` (setup guide). Minimal and stable.

## Status labels (single-valued — one at a time)

| Label | Meaning |
|---|---|
| `status:queued` | Available to claim. |
| `status:claimed` | Advisory checkout posted (claim sequence ran). |
| `status:in-progress` | Claimed and being worked. |
| `status:in-review` | Handed to review (code-reviewer / role). |
| `status:blocked` | Blocked (see `meta:blocked-external` or a BLOCKED comment). |
| `status:done` | Completed (evidence gates satisfied via the handoff, not the comment). |

## Role labels (routing — one per canonical roster role)

`role:tech-lead`, `role:project-manager`, `role:architect`, `role:software-engineer`, `role:researcher`, `role:qa-engineer`, `role:sre`, `role:tech-writer`, `role:code-reviewer`, `role:release-engineer`, `role:security-engineer` (auditor/SME routing per roster). Missing/conflicting role → needs-triage.

## Priority labels

`priority:p0` (drop-everything) … `priority:p3` (whenever).

## Meta labels

`meta:framework-maintenance`, `meta:customer-approval-required`, `meta:security-review-required`, `meta:blocked-external`.

## Milestones

One milestone per release semver tag; issues targeted at a release carry that milestone.

## Structured comment types

| Type | Payload (beyond actor/role + UTC ts) |
|---|---|
| `CLAIM` | operator, machine, session (claim sequence; tie-break key). |
| `YIELD` | reason (lost tie-break / voluntary release / reclaim). |
| `PROGRESS` | short status note; keeps the claim non-stale. |
| `HANDBACK` | target role; what's done / what's next. |
| `GATE-PASSED` | which gate + pointer to the binding evidence — observational ONLY; does NOT satisfy the gate. |
| `BLOCKED` | blocker description; pairs with `status:blocked`. |

## Rules

- Status is single-valued; transitions follow the claim-protocol state machine.
- Role/priority/meta are additive.
- No comment (incl. `GATE-PASSED`) satisfies an evidence gate; the binding evidence is the hook-captured `verification.*` / role-owned artifacts on the durable handoff.
- All labels are downstream-creatable via `gh label create`; the interface is opt-in (a repo with none of these labels runs the normal single-operator workflow).
