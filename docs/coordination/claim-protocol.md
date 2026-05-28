# Claim protocol

<!-- TOC -->

- [Overview](#overview)
- [State machine](#state-machine)
- [Claim sequence](#claim-sequence)
- [Tie-break rule](#tie-break-rule)
- [Yield sequence (loser)](#yield-sequence-loser)
- [Winner actions](#winner-actions)
- [Release and handback](#release-and-handback)
- [Stale-claim recovery](#stale-claim-recovery)
- [Race window and limits](#race-window-and-limits)
- [Invariants](#invariants)

<!-- /TOC -->

The advisory checkout protocol for multi-operator issue coordination.
GitHub has no atomic lock primitive. This protocol bounds the race
window and resolves concurrent claims deterministically — it does not
prevent a race from occurring.

The protocol is **advisory (optimistic)**. Operators who follow it
will not double-claim the same issue under normal conditions. An
operator who ignores the protocol can still touch a claimed issue;
that is a process violation, not a hard barrier.

---

## Overview

An operator picks up a `status:queued` issue, posts a structured
CLAIM comment, re-reads the issue's claim comments, and applies a
deterministic tie-break. The winner proceeds; the loser yields
immediately without writing the local active pointer.

The full sequence completes in approximately three sequential `gh`
calls. The race window is the elapsed time across those calls —
typically a few seconds under normal network conditions.

---

## State machine

```
queued → claimed → in-progress → in-review → done
                      ↓                         ↑
                   blocked ───────────────────→ (resolved)
claimed / in-progress → queued   (yield, release, or stale recovery)
```

Status is single-valued. Remove the current `status:*` label before
applying the next one. See `label-taxonomy.md` for the full label
vocabulary.

---

## Claim sequence

Perform these steps in order. Do not skip the re-read step; it is the
only mechanism that detects a competing claim.

1. **Self-assign** the issue to your operator account.
2. **Apply `status:claimed`** — remove `status:queued` first (status is
   single-valued).
3. **Post a CLAIM comment** with the following fields:

   | Field | Value |
   |---|---|
   | `type` | `CLAIM` |
   | `operator` | your operator id (GitHub username or equivalent) |
   | `machine` | the machine or runner posting the claim |
   | `session` | the session id for this work unit |
   | `ts` | current UTC timestamp, ISO 8601 format |

4. **Re-read the issue's CLAIM comments** — fetch the current comment
   list and collect every CLAIM comment that has no subsequent
   YIELD or release for the same operator. This is the mandatory
   verify step.
5. **Apply the tie-break** (see below) to determine the winner.

---

## Tie-break rule

Among all active CLAIM comments on the issue (those with no
intervening YIELD or release by the same operator):

1. The operator with the **earliest `ts` (UTC)** wins.
2. If two operators posted the exact same timestamp, the operator with
   the **lexicographically lower `operator` id** wins.

This rule is deterministic and observer-independent: any operator
reading the same set of CLAIM comments computes the same winner.

---

## Yield sequence (loser)

If the tie-break identifies another operator as the winner, execute
the yield sequence immediately.

1. **Post a YIELD comment** with fields: `type`, `operator`, `machine`,
   `session`, `ts`, and `reason` (set reason to `lost-tiebreak` for
   an automatic loss, or a descriptive string for a voluntary yield).
2. **Remove `status:claimed`** (or `status:in-progress` if already
   advanced) and **restore `status:queued`**, unless the issue has
   moved to `status:done`.
3. **Un-assign yourself** from the issue.
4. **Do not write** `.devteam/active-handoff.json`. Do not clear a
   pointer written by the winning operator.

The issue is now reclaimable with no residual claim from the yielding
operator.

---

## Winner actions

After the tie-break confirms you are the winner:

1. **Write `.devteam/active-handoff.json`** — the local per-machine
   pointer to the currently-claimed handoff and issue. This file is
   gitignored; it is local state only.
2. **Apply `status:in-progress`** — remove `status:claimed` first.

Proceed with the work.

---

## Release and handback

When work is finished or handed to another role:

1. Post a **HANDBACK comment** (if transferring to another role,
   include `target_role` and a summary of completed and remaining
   work) or advance the issue to `status:done` / `status:in-review`
   as appropriate.
2. **Clear the claim** — un-assign yourself and remove
   `status:claimed` or `status:in-progress`.
3. **Clear the local active pointer** — delete or reset
   `.devteam/active-handoff.json` on your machine.

The issue reflects its new state. If returned to `status:queued`, it
is reclaimable by any operator.

---

## Stale-claim recovery

A `status:claimed` or `status:in-progress` issue is considered stale
when no PROGRESS or HANDBACK comment has appeared within the
documented staleness window for the project.

Recovery is **advisory** — there is no automated hard takeover. The
recovering operator:

1. Posts a typed reclaim note (use a CLAIM comment with `reason:
   stale-recovery` in the payload, or a free-text note referencing
   the original claim timestamp and operator).
2. Clears the prior claim — removes the stale assignee, drops
   `status:claimed` / `status:in-progress`, restores `status:queued`.
3. Runs the full claim sequence from step 1.

Before recovering a stale claim, check whether the original operator
left a PROGRESS comment or is otherwise active. Coordinate out-of-band
if uncertain.

---

## Race window and limits

The race window is the elapsed time between step 1 (self-assign) and
the end of step 4 (re-read complete) — approximately the time required
for three sequential `gh` calls under normal network conditions,
typically a few seconds.

Clock skew across machines can cause near-simultaneous claims to appear
in different orders depending on which machine posted first. The
protocol assumes operator clocks are roughly NTP-synchronized. Under
that assumption, the tie-break produces a consistent winner. Under
extreme clock skew (seconds-level), the lexicographic `operator` id
tiebreaker still resolves the winner deterministically even if the
UTC ordering is ambiguous.

This is optimistic coordination, not mutual exclusion. Operators
who follow the protocol converge on one winner; operators who do not
follow it create a process violation outside the protocol's scope.

---

## Invariants

These invariants are testable (mapped to contract references
SC-001 / I1–I5):

| ID | Statement |
|---|---|
| I1 | After a contested claim resolves, exactly one operator holds the claim: self-assigned, `status:claimed` or `status:in-progress`, winning CLAIM comment. The loser has a YIELD comment and no active assignment. |
| I2 | Any operator reading the same set of active CLAIM comments computes the same winner. The tie-break is observer-independent. |
| I3 | A released or yielded issue returns to a reclaimable state with no residual claim from the departing operator. |
| I4 | No step in this protocol asserts a hard lock. The protocol is advisory, with a bounded race window (approximately seconds; three sequential `gh` calls). |
| I5 | No CLAIM, YIELD, PROGRESS, HANDBACK, or GATE-PASSED comment satisfies an evidence gate. Binding evidence is the hook-captured `verification.*` record or the role-owned artifact in the durable handoff (`docs/handoffs/<task_id>.json`). |
