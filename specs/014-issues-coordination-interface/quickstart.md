# Quickstart: Issues-Based Multi-Machine Coordination Interface

Validates the coordination interface end-to-end. The automated form of the claim/collision checks lives in `tests/coordination/test-claim-protocol.sh` (single-operator + simulated concurrency, per Q-0018).

## 1. Bootstrap a fresh repo (opt-in) — FR-013, SC-005

1. Follow the setup guide: run the `gh label create` transcript to create the status/role/priority/meta labels, create release milestones, and confirm the `agent-task` + `agent-review-request` issue templates are present.
2. Expect: the full label set, milestone convention, and both templates exist with no hand-editing of template internals.

## 2. Opt-out check — FR-014, SC-005

1. In a project that has NOT run setup, run the normal single-operator agent workflow.
2. Expect: nothing requires GitHub issues/labels/claims; the workflow operates normally.

## 3. Claim / collision / yield — US1, FR-001..FR-004, SC-001

1. Create a `status:queued` coordination issue (agent-task template), linked to a durable handoff (`task_id`; optional `github_issue` back-link).
2. Simulate two operators claiming it near-simultaneously (controlled CLAIM records / timestamps).
3. Expect: the tie-break selects exactly one winner (earliest ts; lexical operator on tie); the winner ends `status:in-progress` + assigned + local active pointer written; the loser posts YIELD, clears its claim, issue returns to `status:queued`. 0 double-claims; result identical from either view.

## 4. Release / reclaim — FR-004

1. The winner releases/hands back the issue.
2. Expect: claim cleared, local active pointer cleared, issue reclaimable; a second operator can now claim cleanly.

## 5. Comments don't satisfy gates — FR-008, SC-004

1. Post a `GATE-PASSED` comment on an issue whose durable handoff lacks accepted evidence.
2. Expect: the completion gate still does NOT pass — only the hook-captured `verification.*` / role-owned evidence satisfies it. The comment is observational only.

## 6. Labels carry state — US2, SC-002, SC-003

1. Label an issue with status/role/priority/meta + milestone.
2. Expect: status, owning role, priority, blocked state, and target release are all readable from labels/milestone alone; the claim→progress→handback history is reconstructable from the structured comments alone.

## 7. Governance — FR-015, SC-006

1. Confirm FW-ADR-0020 is `Accepted` and ROADMAP.md v1.1.0 "Half B" exit criteria reflect the issues-based framing (Projects wording removed).
2. Confirm the optional `github_issue` field validates on a handoff (present and absent), and that the scaffold gitignores `.devteam/active-handoff.json` downstream.
