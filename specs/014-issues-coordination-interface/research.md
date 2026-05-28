# Research: Issues-Based Multi-Machine Coordination Interface

Most decisions are inherited from FW-ADR-0020 (the accepted design); this file records the implementation-relevant choices and the few open mechanics.

## R1 — Advisory claim ("checkout") mechanics

- **Decision**: Three-step optimistic claim — self-assign → apply `status:claimed` → post a structured CLAIM comment (operator id, machine, session id, UTC timestamp) — followed by a MANDATORY re-read of the issue's claim comments to detect a competing claim. No atomic lock is used or implied.
- **Rationale**: GitHub Issues expose no compare-and-swap/lock primitive; assignees and labels both race. Post-then-re-read bounds the race to the time between the three sequential `gh` calls (~seconds) and makes collisions detectable.
- **Alternatives considered**: assignee-only (not exclusive, no audit trail); label-only (races, no operator/machine identity); `gh issue lock` (locks comments, not work) — all rejected.

## R2 — Collision tie-break

- **Decision**: Earliest CLAIM-comment UTC timestamp wins; ties broken lexicographically on the `operator` id. The loser posts a YIELD comment, removes its assignment + `status:claimed`, and does not write `.devteam/active-handoff.json`. The winner proceeds and writes the local active pointer.
- **Rationale**: Deterministic and observer-independent — any operator reading the issue computes the same winner. Lexical operator tiebreak removes residual ambiguity on equal timestamps.
- **Open risk (documented, not blocking)**: clock skew across machines can misorder near-simultaneous claims; mitigation is the short race window + a documented assumption that operator clocks are roughly NTP-synced. Recorded as an edge case/assumption, not solved with a coordination server (out of scope).

## R3 — Stale-claim recovery

- **Decision**: A claim with no PROGRESS/HANDBACK activity past a documented staleness window is reclaimable: a new operator posts a (typed) reclaim note, clears the prior claim, and re-claims. Advisory — no hard takeover; the convention documents the courtesy/escalation order.
- **Rationale**: Operators crash; without recovery a claimed-but-abandoned issue blocks the queue forever. Keeps it convention-level (no daemon).

## R4 — Issue templates format

- **Decision**: GitHub issue-form YAML (`.github/ISSUE_TEMPLATE/*.yml`) for `agent-task` and `agent-review-request`, with fields for role routing, acceptance criteria, prior-art/proposal links, review owner, and release-note impact; default labels applied via the template's `labels:` key.
- **Rationale**: Issue forms render structured fields and can auto-apply labels, matching the agent-routed intake→review need. Existing `.github/ISSUE_TEMPLATE/` already uses `.yml` forms (feature-request.yml, framework-gap.yml) — match that style.

## R5 — Label/milestone bootstrap

- **Decision**: Provide a `gh label create` transcript (and `gh api` for milestones) in the setup guide; do NOT require a custom script — a copy-pasteable transcript keeps it transparent and editable. Optionally a thin idempotent helper if the transcript proves unwieldy.
- **Rationale**: A fresh downstream project must stand the labels up "without hand-editing template internals"; a transcript is the lowest-friction, most auditable form.

## R6 — Optional `github_issue` handoff-schema field (Q-0017)

- **Decision**: Add an OPTIONAL `github_issue` property to `schemas/handoff.schema.json` (and document it on the durable handoff record) — a reference to the coordination issue (number or URL). Optional so existing handoffs and single-operator/offline projects validate without it.
- **Rationale**: Makes the issue↔handoff link bidirectional and machine-checkable (FR-006/FR-017) without forcing GitHub on anyone.
- **Alternatives considered**: required field (rejected — breaks opt-in/offline + existing fixtures); issue-body-only link (rejected per Q-0017 ruling).

## R7 — Validating the claim protocol without a second machine (Q-0018)

- **Decision**: A shell smoke that drives the claim/collision/yield/release flows with SIMULATED concurrency on one machine — e.g. construct two CLAIM records with controlled timestamps and assert the tie-break selects the deterministic winner and the loser yields; assert release makes the issue reclaimable. Where `gh`/network is unavailable in the environment, exercise the tie-break/decision logic against fixture claim records (pure-function level) rather than live issues.
- **Rationale**: The hard part is the deterministic decision logic, which is fully testable offline; the live two-machine test is deferred (Q-0018) with this single-operator smoke as the recorded validation.
- **Alternatives considered**: requiring live two-machine (deferred per ruling); no test (rejected — SC-001 needs the 0-double-claim proof).

## R8 — Scaffold gitignore (Q-0019)

- **Decision**: Amend `scripts/scaffold.sh` so scaffolded downstream projects' `.gitignore` excludes `.devteam/active-handoff.json` (per-machine/per-session local pointer). The template repo's own committed example handoff is untouched.
- **Rationale**: The active pointer is local state; tracking it causes cross-machine churn/conflicts (FR-018).

## R9 — Comments never satisfy evidence gates

- **Decision**: Documented invariant + a smoke assertion: a `gate-passed` issue comment does not pass the completion gate; only the hook-captured `verification.*` / role-owned evidence does. The coordination layer is observational, not authoritative for gates.
- **Rationale**: Preserves the v1.1 Half-A evidence model and role ownership (FR-008, Principle VII).
