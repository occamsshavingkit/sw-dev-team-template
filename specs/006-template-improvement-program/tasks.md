---

description: "Task list for the sw-dev-team-template improvement program (M0–M9)"
---

# Tasks: sw-dev-team-template improvement program (M0–M9)

**Input**: Design documents from `/specs/006-template-improvement-program/`
**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/](./contracts/)

**Verification**: Tests are required for this program — prompt-regression (FR-024), question-lint fixture corpus (FR-012), scaffold/upgrade smoke (FR-031), schema validation (FR-022). They are interleaved within each user story phase, not deferred to a separate testing pass.

**Organization**: Tasks are grouped by the eight user stories from [spec.md](./spec.md). User stories in this program are **sequential**, not parallel (per source-plan §1 enabling-first sequencing): US1 (M0+M1) → US2 (M2+M3) → US3 (M4) → US4 (M5) → US5 (M6) → US6 (M7) → US7 (M8) → US8 (M9). Within each story, parallel-eligible tasks are marked `[P]`.

**Path convention**: All implementation paths are relative to the sub-repo at `./sw-dev-team-template` (e.g., `sw-dev-team-template/scripts/foo.sh`). Spec/plan/research paths are relative to the meta-project root.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Different files, no in-flight dependency
- **[Story]**: US1..US8 maps to the user-story phase in spec.md
- Setup / Foundational / Polish phases carry no story label

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Pre-flight, directory scaffolding, dev-environment tooling

- [X] T001 Verify pre-flight per `specs/006-template-improvement-program/quickstart.md` §0 (branch, working tree, sub-repo tag); read-only check producing a green/red console line
- [X] T002 Create new directory scaffold in the sub-repo at `sw-dev-team-template/docs/runtime/agents/`, `sw-dev-team-template/docs/agents/manual/`, `sw-dev-team-template/docs/proposals/`, `sw-dev-team-template/docs/pm/token-ledger/prompts/`, `sw-dev-team-template/schemas/`, `sw-dev-team-template/tests/prompt-regression/`, `sw-dev-team-template/tests/lint-questions/` (each with a README.md stub describing the directory's purpose)
- [X] T003 [P] Confirm `check-jsonschema` CLI is installed locally and pin a version in `sw-dev-team-template/scripts/lib/check-jsonschema-version` per research.md R-6

**Checkpoint**: Working tree ready; new directories present; dev-env can validate JSON Schemas.

---

## Phase 2: Foundational (Blocking Prerequisites — M0 baseline)

**Purpose**: Produce the token-economy baseline that anchors SC-001 / SC-002 measurement; open M0/M1 PM rows; G0 sign-off.

**⚠️ CRITICAL**: No US1 work can begin until T008 (G0 sign-off) is recorded.

- [X] T004 Author `sw-dev-team-template/scripts/baseline-token-economy.sh` per FR-002 + research.md R-4 — idempotent, POSIX-sh, takes `BASELINE_DOWNSTREAM_ROOTS` env var; emits `sw-dev-team-template/docs/pm/token-economy-baseline.md`
- [X] T005 Run `baseline-token-economy.sh` against the sub-repo and the four reference downstream repos (QuackDCS, QuackPLC, QuackS7, QuackSim) per FR-002; commit `sw-dev-team-template/docs/pm/token-economy-baseline.md`
- [X] T006 [P] Add M0 + M1 rows to `sw-dev-team-template/docs/pm/SCHEDULE.md`; record this program as the active sprint
- [X] T007 [P] Add four canonical risks (context bloat, authority drift, prompt compiler drift, model-routing volatility) to `sw-dev-team-template/docs/pm/RISKS.md`
- [X] T008 `code-reviewer` audit; record G0 sign-off in `sw-dev-team-template/docs/pm/SCHEDULE.md` M0 row. Sign-off MUST include confirming the PR's slot in source plan §5 (PR-1) per FR-033, recorded in the SCHEDULE.md row

**Checkpoint**: M0 baseline accepted; US1 can begin.

---

## Phase 3: User Story 1 — Token economy quick wins (M0+M1, Priority: P1) 🎯 MVP

**Goal**: Compact runtime agent contracts (M1.1), archive live registers (M1.2), refactor token ledger (M1.3), split PM schedule (M1.4) — produce the first measurable token reductions.

**Independent Test**: Re-run `baseline-token-economy.sh` after M1 lands; verify ≥30% token reduction on `tech-lead` runtime contract (SC-001) and ≥20% on other core agents (SC-002); confirm prompt-regression set passes against compiled runtime contracts; confirm live registers contain only open + recently-answered rows per live-bound rule.

### Schemas, fixtures, and tests for US1 (write/run before generators)

- [X] T009 [P] [US1] Copy `specs/006-template-improvement-program/contracts/agent-contract.schema.json` to `sw-dev-team-template/schemas/agent-contract.schema.json` (M1.1 prep; full lint coverage arrives at M6)
- [X] T010 [P] [US1] Author initial prompt-regression fixture set covering compound customer question, specialist-owned work, queued agent slot, ADR conflict, missing tests, traceability gap, restricted source, missing source under `sw-dev-team-template/tests/prompt-regression/<agent>/<case>.yaml` per research.md R-11
- [X] T011 [P] [US1] Author a minimal prompt-regression harness `sw-dev-team-template/tests/prompt-regression/run.sh` that loads fixtures, dispatches to the team's standard test config (N=3 majority-vote where seed is unsupported), and writes `results-<YYYY-MM-DD>.md`

### Implementation for US1 — M1.1 (compact runtime contracts)

- [X] T012 [US1] Author `sw-dev-team-template/scripts/compile-runtime-agents.sh` per FR-003 + research.md R-1 (compact-runtime mode only; OpenCode adapter generation lands at US4) — POSIX-sh, deterministic, emits `canonical_sha` in frontmatter, validates output against the eventual generated-artifact schema (stub validator OK at this point)
- [X] T013 [P] [US1] Generate compact runtime contracts for `tech-lead`, `researcher`, `code-reviewer`, `qa-engineer` into `sw-dev-team-template/docs/runtime/agents/<role>.md` per FR-003
- [X] T014 [P] [US1] Split rationale, examples, and historical context out of `sw-dev-team-template/.claude/agents/tech-lead.md` into `sw-dev-team-template/docs/agents/manual/tech-lead-manual.md` (canonical) per FR-003
- [X] T015 [P] [US1] Same split for `researcher` → `sw-dev-team-template/docs/agents/manual/researcher-manual.md` per FR-003
- [X] T016 [P] [US1] Same split for `code-reviewer` → `sw-dev-team-template/docs/agents/manual/code-reviewer-manual.md` per FR-003
- [X] T017 [P] [US1] Same split for `qa-engineer` → `sw-dev-team-template/docs/agents/manual/qa-engineer-manual.md` per FR-003
- [X] T018 [US1] Run `tests/prompt-regression/run.sh` against canonical and compiled contracts for the four roles; verify no hard rule lost; record `sw-dev-team-template/tests/prompt-regression/results-<YYYY-MM-DD>.md`
- [X] T019 [US1] Measure per-role word-count deltas; append before/after table to `sw-dev-team-template/docs/pm/token-economy-baseline.md` (or a paired evidence appendix); verify SC-001 (≥30% tech-lead) and SC-002 (≥20% others)
- [X] T020 [US1] `code-reviewer` audit per M1.1 acceptance — confirms runtime contracts preserve role authority

### Implementation for US1 — M1.2 (archive live registers)

- [X] T021 [US1] Author `sw-dev-team-template/scripts/archive-registers.sh` per FR-004 + SC-003 and the live-bound rule (spec clarification 1) — POSIX-sh, append-only writes, tombstone-plus-archive-pointer pattern in live files
- [X] T022 [US1] Dry-run `archive-registers.sh` against `sw-dev-team-template/docs/OPEN_QUESTIONS.md`, `sw-dev-team-template/docs/intake-log.md`, `sw-dev-team-template/docs/pm/RISKS.md`, `sw-dev-team-template/docs/pm/LESSONS.md`, `sw-dev-team-template/CUSTOMER_NOTES.md` where safe per FR-004; commit dry-run output for review
- [X] T023 [US1] Apply `archive-registers.sh` to the sub-repo per SC-003; commit `sw-dev-team-template/docs/OPEN_QUESTIONS-ARCHIVE.md`, `sw-dev-team-template/docs/customer-notes-archive.md`, `sw-dev-team-template/docs/intake-log-ARCHIVE.md`, `sw-dev-team-template/docs/pm/RISKS-ARCHIVE.md`, `sw-dev-team-template/docs/pm/LESSONS-ARCHIVE.md`
- [X] T024 [US1] Update `sw-dev-team-template/.claude/agents/researcher.md` to point at `scripts/archive-registers.sh` for memory-policy consistency (M1.2 acceptance)

### Implementation for US1 — M1.3 (token ledger refactor)

- [X] T025 [US1] Refactor `sw-dev-team-template/docs/pm/token-ledger.md` to the eight-column schema (Date | Task ID | Agent | Prompt hash | Prompt class | Token budget | Token actual | Notes) per FR-005
- [X] T026 [US1] Create `sw-dev-team-template/docs/pm/token-ledger/prompts/README.md` describing the per-task archive contract; relocate any verbatim prompts already in the live ledger

### Implementation for US1 — M1.4 (PM schedule split)

- [X] T027 [US1] Create `sw-dev-team-template/docs/pm/SCHEDULE-EVIDENCE.md` and `sw-dev-team-template/docs/pm/SCHEDULE-ARCHIVE.md` with header stubs per FR-006
- [X] T028 [US1] Move closure evidence and historical reconciliations out of `sw-dev-team-template/docs/pm/SCHEDULE.md` into the evidence/archive files per FR-006 + SC-004; verify live file carries current plan only

### US1 close

- [X] T029 [US1] `code-reviewer` + `qa-engineer` + `project-manager` review for G1; record G1 sign-off in `sw-dev-team-template/docs/pm/SCHEDULE.md` M1 row. Sign-off MUST include confirming the PRs' slots in source plan §5 (PR-2a for M1.1 compact contracts, PR-2 for archive, PR-3 for token ledger, PR-4 for PM split) per FR-033 and the binding §5 map at the bottom of this file

**Checkpoint**: US1 complete; SC-001 and SC-002 verifiable; live-bound rule enforced; PM split applied; G1 passed. MVP shippable here.

---

## Phase 4: User Story 2 — Token operating model + atomic-question repair (M2+M3, Priority: P2)

**Goal**: Make token economy ongoing (task-template budgets, PM delta pass, memory-first patterns — M2) and repair the atomic-question protocol plus intake logging (M3).

**Independent Test**: A fresh scaffold includes `docs/intake-log.md`; sample task template carries `Token budget` / `JIT file list` / `Token actual` fields; question linter flags known-bad historical patterns (warning-only); `tech-lead.md` carries Customer Question Gate; binding docs carry memory-first query patterns.

### M2 — token operating model

- [X] T030 [P] [US2] Add `Token budget` (tiny/small/medium/large/xl), `JIT file list`, and `Token actual` fields to `sw-dev-team-template/docs/templates/task-template.md` with R-2 band-numbers table per FR-007
- [X] T031 [US2] Document PM delta-pass procedure in `sw-dev-team-template/.claude/agents/project-manager.md` per FR-008 + M2.2
- [X] T032 [P] [US2] Add memory-first query patterns to `sw-dev-team-template/docs/MEMORY_POLICY.md` per FR-009 + M2.3
- [X] T033 [P] [US2] Add memory-first query patterns to `sw-dev-team-template/.claude/agents/tech-lead.md` per FR-009 + M2.3
- [X] T034 [P] [US2] Add memory-first query patterns to `sw-dev-team-template/.claude/agents/researcher.md` per FR-009 + M2.3

### M3 — atomic questions and intake

- [X] T035 [US2] Rewrite seed scoping questions in `sw-dev-team-template/docs/FIRST_ACTIONS.md` to atomic form (one decision axis per row) per FR-010 + M3.1
- [X] T036 [US2] Unify atomic-question batching language verbatim across `sw-dev-team-template/CLAUDE.md`, `sw-dev-team-template/docs/FIRST_ACTIONS.md`, `sw-dev-team-template/.claude/agents/tech-lead.md`, the OPEN_QUESTIONS template form, and `sw-dev-team-template/docs/templates/intake-log-template.md` per M3.2
- [X] T037 [US2] Add Customer Question Gate near the top of `sw-dev-team-template/.claude/agents/tech-lead.md` (four checks: customer-owned / atomic / all idle / final line; queue-if-fail action) per FR-011 + M3.3
- [X] T038 [P] [US2] Author `sw-dev-team-template/scripts/lint-questions.sh` per research.md R-8 — five patterns; `HARDGATE_AFTER_SHA` constant set to the commit SHA of this PR; warning-only initially
- [X] T039 [P] [US2] Author fixture corpus in `sw-dev-team-template/tests/lint-questions/` (one good + one bad row per pattern × 5)
- [X] T040 [US2] Run `lint-questions.sh` against the template repo at warning level; verify no false positives on grandfathered legacy rows; record known-bad rows in `sw-dev-team-template/docs/pm/LESSONS.md` (informational)
- [X] T041 [US2] Update `sw-dev-team-template/scripts/scaffold.sh` (and the upgrade.sh repair path) so fresh scaffolds and retrofits create `docs/intake-log.md` from `sw-dev-team-template/docs/templates/intake-log-template.md` per FR-013 + M3.5 (the downstream-side verification for SC-006 lands at G8 via T076–T079)
- [X] T042 [US2] Verify scaffold/upgrade smoke tests (`sw-dev-team-template/tests/stepwise-smoke.sh` or successor) cover the intake-log creation path per FR-013
- [X] T043 [US2] `code-reviewer` + `qa-engineer` review for G2 + G3; record G2 and G3 sign-offs in `sw-dev-team-template/docs/pm/SCHEDULE.md`. Sign-off MUST include: (a) running `sw-dev-team-template/scripts/lint-questions.sh --since HARDGATE_AFTER_SHA` and asserting an empty violations list to verify SC-005; (b) confirming the PR's slot in source plan §5 (PR-5, PR-6, PR-7) per FR-033

**Checkpoint**: US2 complete; token-economy ongoing discipline shipped; question protocol repaired; intake-log seeded everywhere.

---

## Phase 5: User Story 3 — Documentation authority + drift control (M4, Priority: P3)

**Goal**: Add Documentation Authority Policy; fix downstream roadmap leakage; resolve binding-status of `model-routing-guidelines.md`; move binding workflow-pipeline rules out of the excluded proposal doc.

**Independent Test**: Fresh scaffold does not expose upstream-template release planning as the project's root roadmap; `model-routing-guidelines.md` is unambiguously binding (or unambiguously not); no downstream-shipped file references an excluded proposal doc for binding rules.

- [X] T044 [P] [US3] Insert Documentation Authority Policy (three-sentence form per research.md R-12) into `sw-dev-team-template/docs/framework-project-boundary.md` per FR-001 + FR-014 + M4.1
- [X] T045 [P] [US3] Resolve root-`ROADMAP.md` leakage per FR-015 + M4.2 — implement the chosen sub-option (remove from ship-set OR move upstream roadmap to `sw-dev-team-template/docs/template/ROADMAP.md` OR replace with project-local stub); update retrofit guidance in `sw-dev-team-template/docs/TEMPLATE_UPGRADE.md`
- [X] T046 [US3] Flip binding-status flag on `sw-dev-team-template/docs/model-routing-guidelines.md` per FR-016 + M4.3 (binding default; exact model IDs marked runtime-reverifiable)
- [X] T047 [US3] Create `sw-dev-team-template/docs/workflow-pipeline.md` and move binding workflow rules out of `sw-dev-team-template/docs/proposals/workflow-redesign-v0.12.md` per FR-017 + M4.4
- [X] T048 [US3] Update any shipped-downstream file that referenced the excluded proposal doc to instead reference `docs/workflow-pipeline.md`
- [X] T049 [US3] `code-reviewer` + `tech-writer` review for G4; record G4 sign-off. Sign-off MUST include confirming the PRs' slots in source plan §5 (PR-8, PR-9) per FR-033

**Checkpoint**: US3 complete; authority model clear; downstream scaffolds clean.

---

## Phase 6: User Story 4 — Cross-AI / OpenCode / Gemini routing as adapter (M5, Priority: P4)

**Goal**: Add OpenCode harness support, Gemini and OpenAI model routing, thin generated adapters — strictly as an adapter over the canonical role roster.

**Independent Test**: ADR is accepted; `model-routing-guidelines.md` carries the full per-agent default-class table plus fallback rules; fallback-log entries record all six required fields; generated `.opencode/agents/*.md` adapters contain no duplicated role text; manual edit to an adapter fails lint via `canonical_sha` mismatch.

- [X] T050 [P] [US4] Author `sw-dev-team-template/docs/adr/fw-adr-0009-opencode-harness-adapter.md` per FR-018 + M5.1 (adapter-only; configures models/providers/commands/thin wrappers; MUST NOT redefine roles/escalation/customer-interface)
- [X] T051 [P] [US4] Copy `specs/006-template-improvement-program/contracts/model-routing.schema.json` to `sw-dev-team-template/schemas/model-routing.schema.json`
- [X] T052 [US4] Extend `sw-dev-team-template/docs/model-routing-guidelines.md` with OpenCode provider/model ID convention, Gemini classes, fallback policy (spec clarification 8), frontier-only escalation rules, and the per-agent default-class table (binding default + override-supplement rule per spec clarification 5) per FR-019 + M5.2
- [X] T053 [US4] Author `sw-dev-team-template/scripts/log-fallback.sh` per research.md R-10 + FR-020 — JSONL append to `sw-dev-team-template/docs/pm/fallback-log.jsonl` with six required fields and substitution policy (closest-peer-then-one-tier-down). MUST include a self-exercise step that simulates a `provider_unavailable_5xx` against a sandbox call and asserts one new row appears in `docs/pm/fallback-log.jsonl` carrying all six FR-020 fields, to verify SC-008 is testable rather than vacuous
- [X] T054 [US4] Extend `sw-dev-team-template/scripts/compile-runtime-agents.sh` to also generate `sw-dev-team-template/.opencode/agents/<role>.md` per research.md R-7 + FR-021 (single-file stub; frontmatter carries `canonical_source`, `canonical_sha`, optional `local_supplement`, `generator`, `generator_version`)
- [X] T055 [US4] Generate adapters for every canonical role in `sw-dev-team-template/.claude/agents/*.md`; commit `sw-dev-team-template/.opencode/agents/<role>.md` set
- [X] T056 [US4] Manual-edit lint test: hand-edit one adapter's body, run the lint, confirm failure (proves FR-021 enforcement + SC-007)
- [X] T057 [US4] `code-reviewer` + `release-engineer` + `researcher` (for external/OpenCode source provenance) review for G5; record G5 sign-off. Sign-off MUST include confirming the PRs' slots in source plan §5 (PR-10, PR-11) per FR-033

**Checkpoint**: US4 complete; cross-AI routing is adapter-only; fallback logged; no parallel orchestration.

---

## Phase 7: User Story 5 — Markdown compiler / runtime contract pipeline (M6, Priority: P5)

**Goal**: Schemas + agent-contract lint + reproducible compiler + full prompt-regression set, against both canonical and compiled contracts.

**Independent Test**: `scripts/lint-agent-contracts.sh` rejects an agent file with malformed frontmatter or missing required section; `scripts/compile-runtime-agents.sh` run twice produces byte-identical output; prompt-regression cases listed in source plan §M6.3 pass against both canonical and compiled contracts.

- [X] T058 [P] [US5] Replace the M1-era stub schema with the final `sw-dev-team-template/schemas/agent-contract.schema.json` per `specs/006-template-improvement-program/contracts/agent-contract.schema.json`
- [X] T059 [P] [US5] Copy `specs/006-template-improvement-program/contracts/generated-artifact.schema.json` to `sw-dev-team-template/schemas/generated-artifact.schema.json`
- [X] T060 [US5] Author `sw-dev-team-template/scripts/lint-agent-contracts.sh` per FR-023 + SC-007 — extracts JSON representation from each `sw-dev-team-template/.claude/agents/*.md` and validates it with `check-jsonschema` against `agent-contract.schema.json`; reports per-file diagnostics on failure; also validates `sw-dev-team-template/tests/prompt-regression/<agent>/<case>.yaml` fixtures against an inline YAML schema requiring keys `agent / case / input.user_message / input.context / expected_behavior / assertions` (data-model.md VR-9)
- [X] T061 [US5] Extend `sw-dev-team-template/scripts/compile-runtime-agents.sh` to validate every generated artifact against `generated-artifact.schema.json` before exit per SC-007; emit non-zero on schema failure; record byte-for-byte reproducibility test as a CI assertion
- [X] T062 [US5] Author the full prompt-regression case set under `sw-dev-team-template/tests/prompt-regression/` covering all source plan §M6.3 entries (compound customer question, specialist-owned work, queued agent slot, ADR conflict, missing tests, traceability gap, missing regression test, acceptance ambiguity, restricted source, missing source, customer-note stewardship, stale schedule delta, no-op PM pass) per FR-024
- [X] T063 [US5] Run the full prompt-regression set against canonical AND compiled contracts for all core agents per SC-013; record `sw-dev-team-template/tests/prompt-regression/results-<YYYY-MM-DD>.md`
- [X] T064 [US5] `code-reviewer` + `qa-engineer` review for G6; record G6 sign-off. Sign-off MUST include confirming the PRs' slots in source plan §5 (PR-12, PR-13) per FR-033

**Checkpoint**: US5 complete; compiler pipeline locked in; prompt-regression authoritative.

---

## Phase 8: User Story 6 — Self-improvement loop and issue-driven evolution (M7, Priority: P6)

**Goal**: GitHub issue taxonomy, framework-gap issue template with redaction discipline, AI-improvement workflow scoped to non-customer-truth surfaces with hard patch-size limits, and four hardened CI workflows.

**Independent Test**: All FR-025 labels exist on `sw-dev-team-template`; the framework-gap issue template requires the seven listed fields; a workflow run with mock issues opens exactly one PR per run, respects size limits, leaves protected files and customer-truth files untouched (or paired-proposal-only), and degrades to no-op or new issue on failure rather than a broken commit.

- [X] T065 [P] [US6] Create the FR-025 taxonomy labels on `sw-dev-team-template` via `gh label create` (`template-gap`, `template-friction`, `authority-drift`, `docs-drift`, `agent-contract`, `atomic-question`, `model-routing`, `token-economy`, `process-breakdown`, `traceability-gap`, `generalization-risk`, `ai-behavior`, plus `m8-waiver` for FR-029)
- [X] T066 [P] [US6] Author `sw-dev-team-template/.github/ISSUE_TEMPLATE/framework-gap.yml` per FR-026 — seven required fields including the redaction-confirmation tied to the mandatory enumerated sensitive-content set
- [X] T067 [P] [US6] Author `sw-dev-team-template/docs/IP_POLICY.md` (or extend if present) with the FR-026 mandatory enumerated set plus the per-repo extension marker per spec clarification 10
- [X] T068 [P] [US6] Author `sw-dev-team-template/.github/workflows/agent-contract-check.yml` per FR-028 — runs `lint-agent-contracts.sh` and the canonical-only prompt-regression pass on every PR
- [X] T069 [P] [US6] Author `sw-dev-team-template/.github/workflows/question-lint.yml` per FR-028 — runs `lint-questions.sh` on every PR
- [X] T070 [P] [US6] Author `sw-dev-team-template/.github/workflows/template-contract-smoke.yml` per FR-028 + SC-011 — runs the scaffold + upgrade smoke test on every PR
- [X] T071 [US6] Author `sw-dev-team-template/.github/workflows/improve-template.yml` per FR-027 + FR-028 + research.md R-3 — manual or scheduled trigger; one improvement per run; size cap (≤400 lines / ≤10 files / 1 commit); aborts to framework-gap issue on oversize; never pushes to `main`; PR-only; protected-files set (CLAUDE.md, AGENTS.md, .claude/agents/*.md, docs/adr/*.md, docs/framework-project-boundary.md, docs/model-routing-guidelines.md, .github/workflows/*.yml, migrations/, VERSION, TEMPLATE_MANIFEST.lock, files containing a Hard Rule) is read-only; customer-truth set (CUSTOMER_NOTES.md, docs/OPEN_QUESTIONS.md, docs/intake-log.md) is read-only; both sets require paired Markdown proposal under `sw-dev-team-template/docs/proposals/`
- [X] T072 [US6] Mock-issue dry-run: dispatch the workflow against a fixture issue per SC-010; verify it produces one PR with the size invariants met and no protected/customer-truth edits
- [X] T073 [US6] `security-engineer` review of the self-improvement loop blast radius (Hard Rule #7); record decision in `sw-dev-team-template/CUSTOMER_NOTES.md` (security sign-off) and `sw-dev-team-template/docs/pm/RISKS.md` (residual-risk note)
- [X] T074 [US6] `code-reviewer` + `release-engineer` + `security-engineer` review for G7; record G7 sign-off. Sign-off MUST include confirming the PRs' slots in source plan §5 (PR-14, PR-15) per FR-033

**Checkpoint**: US6 complete; self-improvement automation safe to enable.

---

## Phase 9: User Story 7 — Downstream rollout and retrofit repair (M8, Priority: P7)

**Goal**: Repair `QuackDCS`, `QuackPLC`, `QuackS7`, `QuackSim` one repo at a time; deferred deliverables file framework-gap issues against the upstream template.

**Independent Test**: For each repo, either the M8.2 repair sequence completes (intake-log seeded, large registers archived, root ROADMAP cleaned, PM schedule split if oversized, question lint passes within grandfathering window, product/framework boundary respected) or an open framework-gap issue against `sw-dev-team-template` names the deliverable and the downstream repo.

- [ ] T075 [US7] Author `sw-dev-team-template/scripts/m8-boundary-check.sh` per research.md R-9 + FR-029 + FR-030 + SC-009 — two checks (product/framework boundary via `## Mixed-PR authorizations` grep; deferred-deliverable waiver via `gh issue list --repo sw-dev-team-template --label m8-waiver --search "..."` query)
- [ ] T076 [P] [US7] Repair `QuackDCS` per source plan §M8.2 + SC-006 + SC-009 + SC-012 — seed intake-log, run `archive-registers.sh`, fix/quarantine root ROADMAP, split SCHEDULE if oversized, run question lint, record upgrade in the repo's PM change log
- [ ] T077 [P] [US7] Repair `QuackPLC` per source plan §M8.2 + SC-006 + SC-009 + SC-012 (same sequence)
- [ ] T078 [P] [US7] Repair `QuackS7` per source plan §M8.2 + SC-006 + SC-009 + SC-012 (same sequence)
- [ ] T079 [P] [US7] Repair `QuackSim` per source plan §M8.2 + SC-006 + SC-009 + SC-012 (same sequence)
- [ ] T080 [US7] For each repo, file framework-gap issues against `sw-dev-team-template` (label `m8-waiver`) for any deliverable that cannot be completed in this program; each issue names the deliverable and the downstream repo (per spec clarification 12)
- [ ] T081 [US7] Capture rollout lessons in `sw-dev-team-template/docs/pm/LESSONS.md`; update `sw-dev-team-template/tests/stepwise-smoke.sh` (or successor scaffold smoke) to reflect the lessons (M8.3)
- [ ] T082 [US7] `code-reviewer` + `project-manager` review for G8; record G8 sign-off. Sign-off MUST include confirming the PRs' slots in source plan §5 (PR-16+, one per repaired downstream repo) per FR-033

**Checkpoint**: US7 complete; the four reference downstream repos are repaired or have open documented waivers.

---

## Phase 10: User Story 8 — v1.0 readiness and release gate (M9, Priority: P8)

**Goal**: Full conformance audit (four canonical + two advisory roles); meet M9.2 release criteria; tag v1.0.0 with customer sign-off.

**Independent Test**: Each release criterion verifies (fresh-scaffold smoke, retrofit smoke, agent-contract lint, question lint, generated artifacts up-to-date, no unresolved high-priority authority-drift issues, model-routing currentness with runtime-verifiable IDs); the four canonical audit roles produce sign-off or a blocking-issue list; advisory findings route to customer for decision; release notes classify every ship-set file per SC-014.

- [ ] T083 [P] [US8] Dispatch `code-reviewer` for agent/ADR/template conformance audit; produce blocking-or-pass report under `sw-dev-team-template/docs/pm/audits/g9-code-reviewer.md`
- [ ] T084 [P] [US8] Dispatch `qa-engineer` for scaffold/upgrade/retrofit test plan execution; produce report at `sw-dev-team-template/docs/pm/audits/g9-qa-engineer.md`
- [ ] T085 [P] [US8] Dispatch `release-engineer` for packaging / versioning / release-notes draft; produce report at `sw-dev-team-template/docs/pm/audits/g9-release-engineer.md`
- [ ] T086 [P] [US8] Dispatch `project-manager` for final risk/schedule/change/lessons update; produce report at `sw-dev-team-template/docs/pm/audits/g9-project-manager.md`
- [ ] T087 [P] [US8] Dispatch `onboarding-auditor` (advisory per spec clarification 14); produce findings at `sw-dev-team-template/docs/pm/audits/g9-onboarding-auditor.md`; `tech-lead` routes findings to customer for decision (non-blocking)
- [ ] T088 [P] [US8] Dispatch `process-auditor` (advisory per spec clarification 14); produce findings at `sw-dev-team-template/docs/pm/audits/g9-process-auditor.md`; `tech-lead` routes findings to customer for decision (non-blocking)
- [ ] T089 [US8] Verify M9.2 release criteria checklist in `sw-dev-team-template/docs/pm/audits/g9-release-criteria.md` per FR-031 + SC-011 (fresh-scaffold smoke, retrofit smoke, agent-contract lint, question lint, generated artifacts up-to-date, no unresolved high-priority authority-drift, model-routing currentness, runtime-verifiable IDs)
- [ ] T090 [US8] Generate release notes at `sw-dev-team-template/RELEASE-NOTES.md` classifying every file in the downstream ship-set (per `sw-dev-team-template/TEMPLATE_MANIFEST.lock` + upgrade.sh ship-files list) as canonical / generated / ephemeral per FR-001 + SC-014 + spec clarification 9
- [ ] T091 [US8] `tech-lead` obtains customer sign-off for v1.0.0 final tag; record in `sw-dev-team-template/CUSTOMER_NOTES.md` per FR-032 + spec clarification 2
- [ ] T092 [US8] `release-engineer` cuts v1.0.0 tag and GitHub Release; the four canonical G9 sign-offs are recorded in `sw-dev-team-template/docs/pm/SCHEDULE.md` M9 row. M9 close MUST verify the full PR-1 → PR-16+ sequence in source plan §5 is reflected in `SCHEDULE.md` history per FR-033, with no out-of-order entries

**Checkpoint**: US8 complete; v1.0.0 released; advisory findings open as issues for post-release follow-up.

---

## Phase 11: Polish & Cross-Cutting Concerns

**Purpose**: Validation and retro after release; no scope additions.

- [ ] T093 [P] Run `specs/006-template-improvement-program/quickstart.md` validation end-to-end against the v1.0.0 state; record pass/fail
- [ ] T094 [P] Run constitution alignment check against `specs/006-template-improvement-program/plan.md` and every file touched in M0–M9; record `sw-dev-team-template/docs/pm/audits/post-release-constitution-check.md`
- [ ] T095 [P] Dispatch `onboarding-auditor` for zero-context regression on the released v1.0.0 template; produce report at `sw-dev-team-template/docs/pm/audits/post-release-onboarding.md`
- [ ] T096 [P] Append cross-milestone retro to `sw-dev-team-template/docs/pm/LESSONS.md` (one bullet per milestone with the surprise or non-obvious win)
- [ ] T097 Final PM SCHEDULE pass — archive M0..M9 rows into `sw-dev-team-template/docs/pm/SCHEDULE-ARCHIVE.md`; live `SCHEDULE.md` reflects post-release plan only

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No deps; start immediately.
- **Foundational (Phase 2)**: Depends on Setup; BLOCKS US1 until T008 (G0).
- **US1 (Phase 3)**: Depends on Foundational; BLOCKS all later stories. Within US1, tests (T009–T011) precede generator work (T012+); schemas precede generator; archive script precedes archival; ledger and PM split run in parallel after their own deps.
- **US2 (Phase 4)**: Depends on US1 close (G1) — uses M1.1 manuals, M1.2 archive script, and M1.4 schedule split as foundations.
- **US3 (Phase 5)**: Depends on US2 close (G3) — authority work follows question-protocol repair so Documentation Authority Policy lands in a clean docs context.
- **US4 (Phase 6)**: Depends on US3 close (G4) — model-routing extensions live in a binding `model-routing-guidelines.md`.
- **US5 (Phase 7)**: Depends on US4 close (G5) — compiler's first non-trivial generated target (`.opencode/`) is defined.
- **US6 (Phase 8)**: Depends on US5 close (G6) — self-improvement loop gates on `lint-agent-contracts.sh` + prompt-regression.
- **US7 (Phase 9)**: Depends on US6 close (G7) — M8 waiver path uses the framework-gap issue infrastructure (FR-026) and the `m8-waiver` label (FR-025).
- **US8 (Phase 10)**: Depends on US7 close (G8).
- **Polish (Phase 11)**: Depends on US8 close (G9).

### User-story sequencing rationale

The source plan §1 is explicit: enabling work first. US1 → US8 is a strict chain, NOT a parallel set of stories (overriding the speckit template's default). Within a story, tasks with `[P]` are parallel-eligible; across stories they are not.

### Parallel opportunities

- **Setup**: T002 and T003 in parallel after T001.
- **Foundational**: T006 and T007 in parallel after T005.
- **US1 — tests/fixtures**: T009, T010, T011 in parallel.
- **US1 — manual splits**: T014, T015, T016, T017 in parallel (different files).
- **US1 — runtime-contract generation**: T013 is naturally parallel across roles within a single script invocation.
- **US2 — memory patterns**: T032, T033, T034 in parallel (different files).
- **US2 — lint scaffolding**: T038 and T039 in parallel (script vs fixtures).
- **US3 — independent edits**: T044 and T045 in parallel.
- **US4 — ADR + schema**: T050 and T051 in parallel.
- **US5 — schemas**: T058 and T059 in parallel.
- **US6 — issue infra and workflows**: T065, T066, T067, T068, T069, T070 in parallel (each touches its own file).
- **US7 — downstream repairs**: T076, T077, T078, T079 in parallel (different repos).
- **US8 — audit dispatches**: T083, T084, T085, T086, T087, T088 in parallel (six dispatch calls).
- **Polish**: T093, T094, T095, T096 in parallel.

---

## Parallel Example: US1 manual splits + runtime generation

```bash
# After T012 (compiler) and T009 (schema), launch in parallel:
Task: T013 [P] [US1] Generate compact runtime contracts for tech-lead, researcher, code-reviewer, qa-engineer
Task: T014 [P] [US1] Split rationale into sw-dev-team-template/docs/agents/manual/tech-lead-manual.md
Task: T015 [P] [US1] Split rationale into sw-dev-team-template/docs/agents/manual/researcher-manual.md
Task: T016 [P] [US1] Split rationale into sw-dev-team-template/docs/agents/manual/code-reviewer-manual.md
Task: T017 [P] [US1] Split rationale into sw-dev-team-template/docs/agents/manual/qa-engineer-manual.md
```

---

## Implementation Strategy

### MVP First (US1 only)

1. Phase 1 Setup → Phase 2 Foundational (G0 sign-off) → Phase 3 US1 (G1 sign-off).
2. **STOP and VALIDATE**: SC-001 ≥30% on `tech-lead`, SC-002 ≥20% on other core agents, live-bound rule enforced everywhere, PM split applied. This is the customer-visible MVP — token economy materially better with no new feature surface.
3. Demo metrics from `docs/pm/token-economy-baseline.md` before/after table.

### Incremental delivery

Each story-phase passes its gate (G2, G3, … G9) and is independently demoable:

- After G3: question protocol is repaired; downstream repos can adopt the linter in warning mode and observe immediate signal.
- After G4: authority model clear; downstream scaffolds no longer leak upstream roadmap.
- After G5: cross-AI routing works across Claude, Codex, OpenCode, Gemini, OpenAI without changing role authority.
- After G6: contracts are reproducible from canonical sources; compaction is auditable.
- After G7: self-improvement loop is safe to leave running.
- After G8: four reference downstream repos visibly improved.
- After G9: v1.0.0 stable release.

### Team strategy (single-team)

This is a small-team or single-orchestrator program. `tech-lead` (main session) routes each phase to the owning specialists per plan.md § Role routing. Within a phase, parallel-eligible tasks dispatch concurrently from `tech-lead` via the Agent tool; sequential tasks queue.

### Owner map (specialist routing)

| Phase | Primary specialist | Supporting |
|---|---|---|
| 1 Setup | software-engineer | tech-lead |
| 2 Foundational | software-engineer | project-manager, code-reviewer |
| 3 US1 | software-engineer + architect | qa-engineer, code-reviewer, project-manager |
| 4 US2 | software-engineer + tech-writer | qa-engineer, code-reviewer |
| 5 US3 | tech-writer | code-reviewer |
| 6 US4 | architect + release-engineer | researcher, code-reviewer, software-engineer |
| 7 US5 | software-engineer | qa-engineer, code-reviewer |
| 8 US6 | release-engineer | security-engineer, code-reviewer |
| 9 US7 | project-manager + release-engineer | software-engineer, code-reviewer |
| 10 US8 | code-reviewer + qa-engineer + release-engineer + project-manager | onboarding-auditor, process-auditor (advisory); tech-lead for customer sign-off |
| 11 Polish | project-manager | onboarding-auditor |

---

## Notes

- `[P]` tasks operate on different files with no in-flight dependency. Parallelism is in the *dispatch* (multiple specialist agents at once), not in serialized writes.
- `[Story]` labels (US1..US8) map each task to a spec.md user-story phase for traceability.
- Tests are required (FR-024, FR-012, FR-031) and are interleaved within the story they belong to.
- Every PR ends with `code-reviewer` review before commit (Constitution V, Hard Rule #3).
- Framework-managed file edits in the sub-repo are authorized for this program (Constitution VI; customer accepted the program by selecting this sprint).
- Customer-policy decisions are settled across three rounds of `/speckit-clarify` (14 bullets in spec.md § Clarifications); new customer-policy questions during implementation route through `tech-lead` as atomic single-question turns.
- After each task or logical group, commit.

### Source-plan §5 PR slicing — binding map (FR-033)

Every gate sign-off task (T008, T029, T043, T049, T057, T064, T074, T082, T092) MUST confirm the PRs landed map to the slots below before recording the gate. Out-of-order PR sequencing fails the sign-off.

| PR # | Source-plan §5 scope | Maps to phase / tasks | Gate |
|---|---|---|---|
| PR-1 | Baseline report + token metrics tooling | Phase 2 (T004–T008) | G0 |
| PR-2 | Archive-register script + live register policy | Phase 3 US1 (T021–T024) | G1 |
| PR-3 | Token ledger schema + task-template token fields | Phase 3 US1 (T025–T026) + Phase 4 US2 (T030) | G1/G2 |
| PR-4 | PM schedule live/evidence/archive split | Phase 3 US1 (T027–T028) | G1/G2 |
| PR-5 | Atomic scoping questions + batching wording cleanup | Phase 4 US2 (T035–T036) | G3 |
| PR-6 | Customer Question Gate + question linter | Phase 4 US2 (T037–T040) | G3 |
| PR-7 | Intake-log scaffold/repair support | Phase 4 US2 (T041–T042) | G3 |
| PR-8 | Documentation Authority Policy + roadmap leakage fix | Phase 5 US3 (T044–T045) | G4 |
| PR-9 | Workflow-pipeline canonical doc move + binding-status flip | Phase 5 US3 (T046–T048) | G4 |
| PR-10 | Model-routing Gemini/OpenCode update | Phase 6 US4 (T051–T053) | G5 |
| PR-11 | OpenCode adapter ADR + generated thin adapters | Phase 6 US4 (T050, T054–T056) | G5 |
| PR-12 | Agent contract schemas + lint | Phase 7 US5 (T058–T060) | G6 |
| PR-13 | Runtime contract compiler + full prompt-regression | Phase 7 US5 (T061–T063) | G6 |
| PR-14 | Issue taxonomy + framework-gap issue template | Phase 8 US6 (T065–T067) | G7 |
| PR-15 | GitHub Actions self-improvement loop + 3 hardened workflows | Phase 8 US6 (T068–T073) | G7 |
| PR-16+ | Downstream rollout, one repo at a time | Phase 9 US7 (T076 → T077 → T078 → T079, each its own PR) | G8 |

**Note**: Source plan §5 does not separately enumerate the M1.1 compact-runtime-contract work (T009–T020). By team convention, M1.1 ships as the lead M1 PR (treat as `PR-2a`), before PR-2 archive work and PR-3 token-ledger work; the G1 sign-off (T029) records the PR-2a slot explicitly.
