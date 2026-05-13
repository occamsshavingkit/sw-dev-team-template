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

## M1 — Token quick wins

Gate sign-off: G1 signed by `code-reviewer` (initial audit T029 BLOCKED with two coupled stamp-staleness defects on researcher; re-audit at `5f96450` PASSED) + `project-manager` (this row) on 2026-05-13.

Acceptance criteria evidence (per source plan §M1):

- M1.1 compact runtime contracts generated for tech-lead, researcher, code-reviewer, qa-engineer → `docs/runtime/agents/*.md` (commit `d48878c`, refreshed for researcher at `5f96450`).
- Token reductions verified in `docs/pm/token-economy-baseline.md` §M1.1 evidence: tech-lead 42.4% (PASS SC-001), researcher 20.3% (PASS SC-002, narrow margin), qa-engineer 37.5% (PASS SC-002), code-reviewer 1.5% (SC-002 "where safe" invoked, documented in LESSONS).
- M1.2 archive-registers.sh shipped (756 lines POSIX-sh, commit `b336594`); 12 OPEN_QUESTIONS rows archived to OPEN_QUESTIONS-ARCHIVE.md with tombstone-pointer pattern.
- M1.3 TOKEN_LEDGER.md migrated to FR-005 eight-column schema; docs/pm/token-ledger/prompts/README.md contract document landed.
- M1.4 SCHEDULE split into live (SCHEDULE.md) / evidence (SCHEDULE-EVIDENCE.md) / archive (SCHEDULE-ARCHIVE.md) per FR-006.

Cross-references: PR-2a (commit `0209c70` + `d48878c`), PR-2 + PR-3 + PR-4 (commit `b336594`), close-out re-stamp (`5f96450`).

Non-blocking observations (all logged to `docs/pm/LESSONS.md`):
- Compiler does not auto-restamp `canonical_sha` when canonical edits land after the initial M1.1 compile; manual two-commit dance fragile. Consider CI guard at M6 or M7.
- Researcher SC-002 margin (20.3%) is 0.3 points above the floor — future researcher edits must re-measure at gate close.
- code-reviewer "where safe" SC-002 — canonical already lean; no further reduction possible without deleting normative content.
- Five small content-fidelity observations from T020 M1.1 audit (researcher Job §1 rationale trim, §6 citation-format trim, qa-engineer HR-5 codification, qa-engineer second escalation-format block silently dropped by singular-slug schema, runtime SHA-from-index semantics).
- Untracked lowercase `docs/pm/token-ledger.md` clutter in working tree; sandbox denied `rm`. Phase-3+ cleanup.
