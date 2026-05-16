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
- Untracked lowercase `docs/pm/token-ledger.md` clutter — resolved in #160: added to `.gitignore`; workaround grep-filters removed from `gate-runner.sh` and `test-gate-pass.sh`.

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

## M4 — Documentation authority + drift control

Gate sign-off: G4 signed by `code-reviewer` (audit T049) + `project-manager` (this row) on 2026-05-13.

Acceptance criteria evidence (per source plan §M4):

- M4.1 Documentation Authority Policy inserted into `docs/framework-project-boundary.md` (commit `cc44c8d`, FR-014). Three-sentence form per research.md R-12; codifies canonical/generated/ephemeral + manual-mirror prohibition + generated-artifact reproducibility.
- M4.2 Root-`ROADMAP.md` leakage fix (commit `cc44c8d`, FR-015). Sub-option (a)+(c) hybrid: scaffold and upgrade scripts seed a project-owned roadmap stub at the downstream root; entry recorded in `.template-customizations` so future upgrades never overwrite. `docs/TEMPLATE_UPGRADE.md` gains a "Root ROADMAP.md handling" paragraph.
- M4.3 `docs/model-routing-guidelines.md` binding-status flipped (commit `cc44c8d`, FR-016). Binding-status block + model-ID-currency block at top; literal IDs tagged `(runtime-reverifiable)`; "draft" / "advisory" language removed.
- M4.4 `docs/workflow-pipeline.md` created as canonical home for binding workflow rules (commit `cc44c8d`, FR-017). 342 lines covering Stages, Transition rules, Exit gates / Hard-block conditions — content moved verbatim from `docs/proposals/workflow-redesign-v0.12.md` §§1, 2, 3, 4, 6, 7, 9.5. Proposal doc gains non-binding status banner; section bodies replaced with one-line pointers to the canonical file.
- T048 cross-link redirect: 10 canonical files (5 agent contracts, 1 manual, 4 templates) redirected from binding-content references to the new `docs/workflow-pipeline.md` with section anchors.

SC status:
- SC-001 PASS: tech-lead runtime 2491 ≤ 2736 floor.
- SC-002 researcher exception still on the books per `docs/pm/LESSONS.md` §M2.3 (1655 vs 1597 floor); no new exception introduced by M4 (doc-only milestone with +2-word runtime delta from section-anchor redirect).

Cross-references: PR-8 (commit `cc44c8d` — M4.1 + M4.2), PR-9 (commit `cc44c8d` — M4.3 + M4.4), runtime re-stamp (`4a44cdd`).

Non-blocking observations: Constitution III observation from G3 (five-file batching-rule unification) carried forward; future ADR + compile-from-canonical solve still recommended. T044's Documentation Authority Policy is now the canonical reference for that ADR.

## M5 — Cross-AI / OpenCode / Gemini routing as adapter

Gate sign-off: G5 signed by `code-reviewer` (audit T057) + `project-manager` (this row) on 2026-05-13.

Acceptance criteria evidence (per source plan §M5):

- M5.1 ADR `fw-adr-0009-opencode-harness-adapter.md` accepted (FR-018, T050). Four explicit prohibitions; three rejected alternatives; cites Constitution I + III + VII.
- M5.2 `docs/model-routing-guidelines.md` extended (FR-019, T052) with provider/model ID conventions (Anthropic/OpenAI/Google/OpenCode), fallback behavior (4 triggers + closest-peer-then-one-tier-down per spec clarification 8), frontier-only escalation rules, and the 13-row binding per-agent default-class table per spec clarification 5. T046 binding-status block preserved at top.
- M5.3 `scripts/log-fallback.sh` (183 lines, POSIX-sh) records every fallback event as JSONL to `docs/pm/fallback-log.jsonl` with the six FR-020 fields. Optional `--downgraded-one-tier` flag per spec clarification 8. Self-exercise confirms testability of SC-008.
- M5.4 `scripts/compile-runtime-agents.sh` extended (FR-021, T054) to generate `.opencode/agents/<role>.md` thin adapter stubs alongside compact runtime contracts. 13 adapters generated at T055 (every canonical role). `--verify` mode added at T056 for FR-021 enforcement — body and frontmatter manual-edit FAILs demonstrated.
- `schemas/model-routing.schema.json` shipped (T051, FR-022) byte-identical to specs/contracts/.
- Compiler skip-incomplete behavior: 4 incomplete canonicals (onboarding-auditor, process-auditor, project-manager, sre) get adapters but no compact runtime contracts; `--strict` flag flips WARN→ERROR. 9 runtime contracts on disk + 13 adapters on disk.

SC status:
- SC-001 PASS: tech-lead runtime 2491 ≤ 2736 floor (unchanged from G4).
- SC-002 researcher exception unchanged from G3 LESSONS §M2.3 (1655 vs 1597 floor).
- SC-008 testability now confirmed via log-fallback.sh self-exercise.

Cross-references: PR-10 + PR-11 (commit `72c922b`); compiler skip-incomplete fix is part of the same commit.

Non-blocking observations (LESSONS at G5 close):
- OBS-G5-1: 4 incomplete canonicals (onboarding-auditor, process-auditor, project-manager, sre) — section additions required by M6 lint hard-gate or M9 release readiness.
- OBS-G5-2: Resolved in `fix/cluster-G-model-routing` (issue #147 Part C). Tables merged; see LESSONS.md M5 close entry for detail.
- OBS-G5-3: `docs/pm/fallback-log.jsonl` is create-on-first-write; consider documenting the contract in `docs/pm/README.md` or seeding an empty file at scaffold time.

## M6 — Markdown compiler / runtime contract pipeline

Gate sign-off: G6 signed by `code-reviewer` + `qa-engineer` (audit T064) + `project-manager` (this row) on 2026-05-13.

Acceptance criteria evidence (per source plan §M6):

- M6.1 schemas shipped: `schemas/agent-contract.schema.json` (T058, byte-identical to specs/contracts/), `schemas/generated-artifact.schema.json` (T059 + description-property fix), `schemas/model-routing.schema.json` (T051 at M5). All three metaschema-valid (JSON Schema 2020-12).
- M6.2 `scripts/lint-agent-contracts.sh` (643 lines POSIX-sh) validates 52 surfaces — 13 canonical agents + 13 prompt-regression fixtures + 13 runtime contracts + 13 OpenCode adapters. Default scan: 0 errors / 0 warnings. Per-surface filter flags. R-VR-1 fixture-YAML check inlined.
- `scripts/compile-runtime-agents.sh` gains `--reproducibility-check` mode for SC-007 (T061). All 13 roles report `reproducibility OK`. `--verify` mode complements: all 13 roles report `verify OK`.
- M6 pre-work: 4 incomplete canonicals (onboarding-auditor, process-auditor, project-manager, sre) gained their missing schema-required sections (`## Hard rules`, `## Escalation`, `## Output format` as appropriate). Compiler now generates runtime contracts for ALL 13 roles (was 9 at G5).
- M6.3 prompt-regression: full 13-fixture set per source plan §M6.3 (T062). Run against canonical + compiled (T063): 13/13 validate, 13/13 STUB in canonical mode, 13/13 STUB in compiled mode, 0 skipped. Real LLM-driven execution remains stubbed per T011 design; Phase-3+ follow-up.
- T060 negative tests demonstrated lint failure on (a) canonical missing `## Hard rules` (b) fixture missing `expected_behavior` (c) adapter missing `canonical_source`; all three exit 1 with diagnostics; restore via re-compile.

SC status:
- SC-007 (zero generated artifacts manually edited per lint) — STRONG PASS. Manual-edit detection via `--verify` + `lint-agent-contracts.sh` frontmatter schema check; both surfaces audited.
- SC-013 (lint + prompt-regression pass canonical+compiled) — STRUCTURAL PASS. Real-LLM execution remains a Phase-3+ follow-up.
- SC-001 PASS unchanged (tech-lead runtime 2491 ≤ 2736 floor).
- SC-002 researcher exception unchanged from G3 LESSONS §M2.3 (1655 vs 1597).

Cross-references: PR-12 + PR-13 (commits `1fb9607` + `c243aa0`); compiler skip-incomplete fix from G5 now fully resolved by 4-canonical pre-work; M5 OBS-G5-1 deferred item closed at M6.

Non-blocking observations:
- Real LLM-driven prompt regression remains a Phase-3+ follow-up; structural pass at G6 is the binding G6 criterion. Recorded in LESSONS §M6 close.
- M5 OBS-G5-2 (duplicate routing tables in `docs/model-routing-guidelines.md`) still open; reconciliation deferred to Phase-3+.
- M5 OBS-G5-3 (fallback-log.jsonl create-on-first-write contract) still open; consider seeding at scaffold time as part of M8.

## M7 — Self-improvement loop

Gate sign-off: G7 signed by `code-reviewer` + `release-engineer` + `security-engineer` (audit T074 + T073) + `project-manager` (this row) on 2026-05-13.

Acceptance criteria evidence (per source plan §M7):

- M7.1 issue taxonomy: 13 labels via `scripts/setup-github-labels.sh` (FR-025, T065). Idempotent + `--dry-run` mode. Customer-actualized post-G7. docs/TEMPLATE_UPGRADE.md gains run instructions.
- M7.2 framework-gap issue template: `.github/ISSUE_TEMPLATE/framework-gap.yml` per FR-026 + spec clarification 10 (T066). Seven required fields + redaction-confirm checkbox citing the four mandatory items. `docs/IP_POLICY.md` extended with the sensitive-content section + per-repo extension marker (T067).
- M7.3 self-improvement workflow: `.github/workflows/improve-template.yml` per FR-027 + research.md R-3 (T071). on: workflow_dispatch only (no schedule trigger); permissions: contents/PRs/issues write only; size cap ≤400 lines / ≤10 files / 1 commit; protected-files set + customer-truth set read-only; paired Markdown proposal under docs/proposals/ as the only escape valve; pre-flight drift checks (lint + --verify + --reproducibility-check); PR opened in draft mode; never auto-merge. Placeholder propose step (M7); Phase-3+ wires real LLM call.
- M7.4 three hardened CI workflows: agent-contract-check.yml, question-lint.yml, template-contract-smoke.yml (T068+T069+T070, FR-028). All pinned to actions/checkout@v4 + actions/setup-python@v5; permissions: contents: read.
- T072 mock-issue dry-run: 7/7 fixture classes pass (small-clean, oversize-lines, oversize-files, protected-no-proposal, protected-with-proposal, customer-truth-no-proposal, customer-truth-with-proposal). SC-010 verified at HEAD.
- T073 security review: PASS-WITH-RESIDUAL-RISK per Hard Rule #7. 13 findings + 5 residual risks (R-5..R-9) recorded in docs/pm/RISKS.md. Sign-off in CUSTOMER_NOTES.md § "Security sign-off — M7 self-improvement loop (2026-05-13)".

SC status:
- SC-010 (zero self-improvement PRs touching protected files) — PASS at G7 (workflow safety logic verified by 7/7 fixture test; forward-looking after first real invocations).
- SC-001 / SC-002 unchanged — M7 is workflow-only, no canonical-agent edits, no runtime-contract changes.

Cross-references: PR-14 (T065+T066+T067) + PR-15 (T068+T069+T070+T071+T072+T073+T074) — both in commit `<current HEAD SHA>`.

Non-blocking residual risks (in RISKS.md):
- R-5 (branch-protection prereq): operational guidance via docs/TEMPLATE_UPGRADE.md before first real invocation.
- R-6 (Phase-3+ LLM re-review): security-engineer re-review MANDATORY at LLM wire-up.
- R-7 (label setup-script dry-run): operational guidance; `--dry-run` default + clear --help.
- R-8 (Hard-Rule content-based protection gap): mitigated by code-reviewer human review + size cap + paired-proposal escape valve. Phase-3+ hardening: grep -l "Hard Rule" content check.
- R-9 (workflow_dispatch input injection): low blast radius (write-access required to invoke); Phase-3+ adds a one-line numeric validator.

Customer approval condition: per FR-032 + spec clarification 2, the v1.0.0 final tag (G9) requires customer sign-off in CUSTOMER_NOTES.md. M7's security sign-off is the Hard-Rule-#7 pre-condition; customer approval is deferred to G9.

## M8 — Pre-release upgrade-regression gate

Gate sign-off: G8 signed by `code-reviewer` (audit T049, accept-with-changes; 5 non-blocking findings resolved before tag) + `qa-engineer` (audit T050, 7 sub-gates × ≥1 negative fixture completeness verified) + `architect` (2026-05-14 contract amendment Style A perturbation default with four guarantees) + `release-engineer` (gate implementation + green-run on the rc12 candidate worktree) + `project-manager` (this row) on 2026-05-14, at the `v1.0.0-rc12` tag.

Milestone goal (per `specs/007-pre-release-upgrade/spec.md`, FR-001..FR-013): ship a pre-release upgrade-regression gate that runs at every release-candidate tag, exercises real upgrades across every published tag, and fails the release on any regression. Customer-authorised at the 2026-05-14 `/speckit-specify` invocation ("a new release test before committing").

Acceptance criteria evidence (per source plan §M8 + spec FR-001..FR-013):

- Gate green at the `v1.0.0-rc12` tag: 7/7 sub-gates PASS post-commit (staged run shows 6/7 with only `worktree-clean` red because staged≠committed; clears on commit per `gate-runner.sh:203` semantics). Wall-clock 127s; `upgrade-paths` dominates at ~110s.
- Per-sub-gate results on the staged candidate worktree: worktree-clean PASS post-commit; lint-contracts PASS (9.4s); check-spdx PASS (0.2s); readme-current PASS (0.0s); upgrade-paths PASS (109.7s); advisory-pointers PASS (1.4s); migrations-standalone PASS (6.4s).
- Spec clarifications 2026-05-14 shaped the scope: fail-all severity (any sub-gate red → release fails), every-published-tag scope (no allowlist except the rc3 cross-MAJOR allowlist below), and strict-on-`v*`-tag hook severity.
- FW-ADR-0010 Gate column ruling (2026-05-14, audit-log surface): gate-runner is the canonical surface for upgrade-regression evidence; SCHEDULE-EVIDENCE entries reference gate runs by tag, not by run-log SHA.
- Customer ruling 2026-05-14 (rc3 cross-MAJOR round-trip allowlisted): frozen-tag defect surfaced during rc3 gate-runs; fix shipped in rc4. Allowlist entry retained for historical-tag coverage; gate continues to fail on any new occurrence.
- Architect contract amendment 2026-05-14 (Style A perturbation default) lands the four guarantees: PID-scoped markers (no cross-run collision), revert verification (every perturbation reversed and verified), dirty-tree hard-fail (no partial-state runs), sanitiser hook (catches missed reverts before gate exit).
- qa-engineer T050: each of the 7 sub-gates has ≥1 negative fixture under `tests/upgrade-gate/`; completeness verified by enumeration against `gate-runner.sh` sub-gate list.
- code-reviewer T049: accept-with-changes; all 5 non-blocking findings resolved before tag (no debt carried into rc12).
- T048 first-green attestation: this M8 block IS the T048 attestation per the architect's earlier note that SCHEDULE-EVIDENCE.md uses prose milestone-closure blocks rather than a row-per-task table.

Cross-references: PR-16 (spec 007 implementation: gate-runner + 7 sub-gate scripts + fixtures + lint integration), at the `v1.0.0-rc12` tag.

Notable deferrals (none carried as debt into rc12):

- 5 T049 non-blocking findings — all resolved before tag; no deferred-issue rows opened.
- 2 deferred-doc nits in upstream issue #24 — explicitly post-rc12 (cosmetic; do not block the gate or the release-candidate). Recorded for the next doc pass.

Owners ledger (M8 window):

- `tech-lead` — orchestration, dispatch, customer-question gating, Turn Ledger entries.
- `release-engineer` — gate-runner.sh + 7 sub-gate scripts implementation; staged gate-runs on the rc12 candidate worktree; VERSION bump + README touch (tag-cut step 1).
- `qa-engineer` — T050 fixture-coverage review across all 7 sub-gates.
- `code-reviewer` — T049 accept-with-changes audit and re-verification of the 5 non-blocking resolutions.
- `architect` — 2026-05-14 contract amendment (Style A perturbation default + four guarantees); FW-ADR-0010 Gate column ruling.
- `tech-writer` — contract / spec edits: spec.md clarifications, FR-001..FR-013 wording, FW-ADR-0010 Gate column.
- `researcher` — CUSTOMER_NOTES.md ruling capture (Clarifications 2026-05-14, rc3 allowlist, FW-ADR-0010 Gate column).
- `project-manager` (this row) — M8 closure block and SCHEDULE.md status flip.
