# Research: Open-Issue Backlog Triage and Burndown

## Status

Empty-research finding: the spec.md quality-checklist passed on first iteration with zero `NEEDS CLARIFICATION` markers; the three /speckit-clarify questions (Q1 rc cadence, Q2 v2 surface, Q3 umbrella split rule) resolved the only spec-level ambiguities. No new technology choices, no new dependency selection, no new architectural patterns are required to execute this plan.

This file exists per /speckit-plan Phase 0 convention; its substance is the absence of unknowns plus a short record of the best-practice patterns applied during plan drafting.

## Best-practice patterns applied

### Decision: One-PR-per-issue (default) with multi-issue PRs only for tight clusters

**Rationale**: each issue gets a dedicated commit + close-comment, which makes the close history auditable per issue. Multi-issue PRs (PR-A through PR-F in `triage.md` § Next dispatches) are reserved for fixes that touch overlapping code regions and would conflict if split (e.g., PR-A: hook-behavior cluster all edits `scripts/hooks/*-guard.py`).

**Alternatives considered**:
- One mega-PR for everything (rejected: irreversible-on-revert, opaque close-history).
- Strict one-PR-per-issue with no multi-issue PRs (rejected: forces redundant edits across cluster issues that share a single file).

### Decision: rc bump at burndown completion only (Q1 ruling)

**Rationale**: per customer ruling (Q1 in spec § Clarifications), one `v1.0.0-rc14` cut at completion. PRs merge against the in-progress rc13 working tree; no per-bucket or per-PR rc bumps. Memory anchor: `feedback_upgrade_reliability_blocks_v1_0_0` — upgrade-flow is the v1.0.0 blocker; rc14 is the dogfood marker for the post-burndown fixture downstream test (SC-007).

**Alternatives considered**: per-bucket bumps (Q1 option B; rejected by customer), per-PR bumps (Q1 option A; rejected by customer).

### Decision: V2 deferrals link to `ROADMAP.md#v2-deferred` (Q2 ruling)

**Rationale**: customer chose Q2 option E. Single file, no new artifact, no new GitHub milestone overhead. Anchor link is stable.

**Alternatives considered**: standalone `ROADMAP-V2.md` (rejected: yet-another-file), GitHub milestone (rejected: out-of-band tracking surface), label-only (rejected: no central narrative for v2 context).

### Decision: Umbrella issue #59 audited child-by-child (Q3 ruling)

**Rationale**: customer chose Q3 option A. Audit before split avoids spawning issues for items already resolved across rc11-rc13 work. Still-relevant items file as new issues outside the 35-baseline (per A-003 + A-009), preserving SC-001 accounting.

**Alternatives considered**: mechanical split before audit (rejected: creates churn), wholesale defer-to-v2 (rejected: loses some still-relevant work), wholesale wontfix (rejected: loses traceable history).

### Decision: Atomic one-test-verifiable task generation

**Rationale**: future `/speckit-tasks` output must produce tasks that each touch one coherent behavior or disposition and cite exactly one primary verification command/test. This keeps dispatches reviewable by one owning specialist and prevents cluster tasks from hiding unrelated behaviors behind a broad test bundle.

**Alternatives considered**: keep broad cluster tasks (rejected: hard to verify and review atomically), require full-suite verification as every task's primary command (rejected: masks the behavior-specific acceptance signal and inflates dispatch cost).

## Out of scope for research

- v2 architectural direction (deferred to v2 work; v2-proposal issues #3, #27, #59-residual close-with-deferral).
- New testing frameworks (existing harness is sufficient).
- New CI infrastructure (existing GitHub Actions cover the verification surface; #143 may add one CI guard but that's a single-step fix).
- Model-routing rework (#145 is a v2 candidate per triage).
