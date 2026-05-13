# Schedule evidence — sw-dev-team-template

Closure evidence and raw references for milestones that have passed their
gate. Paired with `SCHEDULE.md` (live current plan only). Per FR-006 +
spec clarification 1 live-bound rule.

## Format

For each closed milestone, an entry under `## M<N> — <name>` containing:
- Gate sign-off line (signers + date)
- Acceptance criteria evidence (per criterion → artifact path / commit SHA / measurement)
- Non-blocking observations routed to `LESSONS.md`
- Cross-references to PR slots (source plan §5)

## Closures

## M0 — Mobilize and baseline

Gate sign-off: G0 signed by `code-reviewer` (audit, T008) + `project-manager` (this row) on 2026-05-13.

Acceptance criteria evidence (per source plan §M0):

- Baseline report exists → `docs/pm/token-economy-baseline.md` (E-14 snapshot at template SHA `eb4fdac` for M0 + post-T013 evidence appendix).
- Largest recurring context surfaces named → tech-lead 565 lines / 3909 words; researcher 283 lines / 1996 words.
- First implementation PRs are sliced by workstream → §5 binding map in `specs/006-template-improvement-program/tasks.md`.
- No OpenCode / LLMD / GitHub Actions automation started → confirmed by code-reviewer in T008.

Cross-references: PR-1 (sub-repo commit `781d9ae`), Phase 1 scaffolding (`7e93bb5`).

Non-blocking observations: see `docs/pm/LESSONS.md` §M0 baseline.
