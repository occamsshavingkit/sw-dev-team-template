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

## M2 — Token operating model

Gate sign-off: G2 signed by `code-reviewer` (audit T043) + `project-manager` (this row) on 2026-05-13.

Acceptance criteria evidence (per source plan §M2):

- M2.1 task-template token-budget fields landed → `docs/templates/task-template.md` § Token budget (commit `c947f13`, FR-007).
- M2.2 PM delta-pass procedure documented → `.claude/agents/project-manager.md` § PM delta pass (commit `c947f13`, FR-008).
- M2.3 memory-first query patterns added to three binding docs → `docs/MEMORY_POLICY.md` § Query patterns (binding) + `.claude/agents/tech-lead.md` ### Memory-first lookups + `.claude/agents/researcher.md` Memory-first-lookups sentence (commit `c947f13`, FR-009).

SC status:
- SC-002 PASS for tech-lead, code-reviewer ("where safe"), qa-engineer.
- SC-002 EXCEPTION on researcher: runtime 1653 / floor 1597 (17.2% reduction vs 20% target). Justified under the "where safe / any exception is justified and recorded" clause; durable record at `docs/pm/LESSONS.md` §M2.3 researcher SC-002 exception (2026-05-13). Deferral plan names the pronoun-verification block as the future trim candidate.

Cross-references: PR-3 (commit `c947f13`), runtime re-stamp (`acd6ca4`), LESSONS entry (`a37165c`).

## M3 — Atomic-question + intake repair

Gate sign-off: G3 signed by `code-reviewer` (audit T043) + `project-manager` (this row) on 2026-05-13.

Acceptance criteria evidence (per source plan §M3):

- M3.1 seed scoping questions atomicized → `docs/FIRST_ACTIONS.md` (commit `c947f13`, FR-010). Step 1 follow-up: 1 compound → 2 atomic; Step 3a: 1 compound → 3 atomic. Atomic-gate preamble at top.
- M3.2 batching language unified verbatim across 5 files → `CLAUDE.md`, `docs/FIRST_ACTIONS.md`, `.claude/agents/tech-lead.md`, `docs/OPEN_QUESTIONS.md`, `docs/templates/intake-log-template.md` (commit `8e5dd17`). Constitution III observation: manual-mirror with cross-link declared; ADR-class exception captured for a future compile-from-canonical solve.
- M3.3 Customer Question Gate added near top of `.claude/agents/tech-lead.md` (commit `c947f13`, FR-011). Four checks (customer-owned / atomic / all idle / final line) with queue-if-fail action.
- M3.4 `scripts/lint-questions.sh` shipped (435 lines, POSIX-sh, warning-only via `HARDGATE_AFTER_SHA="DEFERRED_SET_AT_HARDGATE_PR"`) with `tests/lint-questions/` fixture corpus covering all 5 patterns (commit `8e5dd17`, FR-012). First dry-run: 3 warnings, all classified false-positive in LESSONS §M3.4 (one downgraded on re-read to "genuine compound" → recorded as OBS-G3-1 follow-up in LESSONS §M3.5).
- M3.5 scaffold/upgrade pipeline seeds `docs/intake-log.md` → `scripts/scaffold.sh` + `scripts/upgrade.sh` + `scripts/smoke-test.sh` (commit `8e5dd17`, FR-013). Smoke run: 158 passed / 0 failed.

SC status:
- SC-005 (zero atomic-question violations in new entries) — lint is warning-only at G3; hard-gate engages at the next MINOR-boundary Release per spec clarification 13. Current warnings classified as false positives or deferred follow-ups.
- SC-006 (zero downstream repos missing intake-log) — TOOLING ready at G3; the four downstream repos get repaired at M8 per spec clarification 3.

Cross-references: PR-5 + PR-6 + PR-7 (commit `8e5dd17`), runtime re-stamp (`acd6ca4`), LESSONS entries (`a37165c`).

Non-blocking observations (LESSONS):
- §M3.4 — pattern-2 regex needs tightening before hard-gate cutover (3 false-positive warnings).
- §M3.5 — scoping-questions-template.md still carries compound seed forms; T035 scope didn't reach it. Follow-up issue recommended.
- Constitution III observation — five-file verbatim repetition with cross-links; defensible for governance text but an ADR/compile-from-canonical solve is the longer-term answer.
