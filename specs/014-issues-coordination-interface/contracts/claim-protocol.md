# Contract: Advisory Issue Claim ("Checkout") Protocol

The testable core of the coordination interface. Advisory/optimistic — GitHub has no atomic lock; this protocol bounds and deterministically resolves the race, it does not prevent it.

## States

`queued` → `claimed` → `in-progress` → `in-review` → `done`
(plus `blocked`; and `claimed`/`in-progress` → `queued` on yield/release/stale).

## Claim sequence (operator picks up `queued` issue)

1. Self-assign the issue.
2. Apply `status:claimed` (remove `status:queued`).
3. Post a CLAIM comment: `{ type: CLAIM, operator, machine, session, ts: <UTC ISO8601> }`.
4. **Re-read** the issue's CLAIM comments (the mandatory verify step).
5. Apply the tie-break (below):
   - If this operator WINS → write `.devteam/active-handoff.json` (local), set `status:in-progress`, proceed.
   - If this operator LOSES → execute the yield sequence.

## Tie-break (deterministic, observer-independent)

Among all CLAIM comments on the issue with no intervening YIELD/release:
1. Earliest `ts` (UTC) wins.
2. If `ts` equal → lowest `operator` id lexicographically wins.

Any operator reading the issue computes the same winner.

## Yield sequence (loser, or voluntary release)

1. Post a YIELD comment: `{ type: YIELD, operator, machine, session, ts, reason }`.
2. Remove `status:claimed` / `status:in-progress`; restore `status:queued` (unless done).
3. Un-assign self.
4. Do NOT write (or clear) the local `.devteam/active-handoff.json`.
→ Issue is reclaimable.

## Release / handback (work finished or handed to another role)

1. Post HANDBACK (to another role) or set `status:done` / `status:in-review` as appropriate.
2. Clear the claim (un-assign, drop `status:claimed`).
3. Clear the local active pointer.
→ Issue reflects new state; reclaimable if returned to `queued`.

## Stale-claim recovery (advisory)

A `claimed`/`in-progress` issue with no PROGRESS/HANDBACK comment past the documented staleness window MAY be reclaimed: the new operator posts a typed reclaim note, clears the prior claim, and runs the claim sequence. No hard takeover.

## Invariants (testable)

- **I1**: After a contested claim resolves, exactly ONE operator holds the claim (assignee + `status:claimed`/`in-progress` + winning CLAIM), and the loser has a YIELD. (SC-001 — 0 double-claims.)
- **I2**: The tie-break result is identical regardless of which operator's view computes it.
- **I3**: A released/yielded issue returns to a reclaimable state with no residual claim.
- **I4**: The protocol never asserts a hard lock; it is documented as advisory with a bounded (~seconds, 3 sequential `gh` calls) race window.
- **I5**: No protocol step makes an issue comment satisfy an evidence gate.

## Race window & limits (documented)

- Window = time between steps 1–4 (~seconds). Clock skew across machines can misorder near-simultaneous claims; assumption: operator clocks are roughly NTP-synced. This is advisory coordination, not mutual exclusion.
