# Schedule - Template Improvement Program M0-M9

PMBOK Planning / Monitoring artifact. Owned by `project-manager`.
Live schedule only: current M0-M9 plan, forecast, gates, and PR slices.
Closure evidence, raw references, and historical rows live outside this
file to preserve recurring-context economy.

Related files:

- Evidence and acceptance support: [`docs/pm/SCHEDULE-EVIDENCE.md`](./SCHEDULE-EVIDENCE.md)
- Closed rows and historical reconciliations: [`docs/pm/SCHEDULE-ARCHIVE.md`](./SCHEDULE-ARCHIVE.md)

## Milestone list

| ID | Milestone | Baseline date | Forecast date | Status | Exit criterion |
|---|---|---|---|---|---|
| M0 | Mobilize and baseline | 2026-05-12 | TBD | on track | G0 baseline accepted in `docs/pm/token-economy-baseline.md`; no compaction, archival, compiler, cross-AI routing, automation, or downstream edits accepted before baseline evidence exists. |
| M1 | Token quick wins | 2026-05-12 | TBD | not started | G1 token quick-win evidence accepted: runtime candidates, register archival, compact token ledger, PM split, prompt-regression/review evidence, and explicit M2-M9 block. |
| M3 | Atomic-question and intake repair | TBD | TBD | planned | G3 accepted by `tech-lead` after `qa-engineer` lint evidence and `researcher` intake evidence in `docs/pm/LESSONS.md`. |
| M4 | Documentation authority and drift control | TBD | TBD | planned | G4 accepted by `architect` and `code-reviewer` with authority, roadmap, model-routing, and workflow-pipeline evidence in `docs/pm/LESSONS.md`. |
| M5 | Cross-AI / OpenCode / Gemini routing | TBD | TBD | planned | G5 accepted by `architect`, `release-engineer`, and `code-reviewer` with adapter-routing and no-parallel-role-model evidence in `docs/pm/LESSONS.md`. |
| M6 | Runtime generation and contract validation | TBD | TBD | planned | G6 accepted by `qa-engineer` and `code-reviewer` with schema, generated-stability, prompt-regression, and source-authority evidence in `docs/pm/LESSONS.md`. |
| M7 | Self-improvement automation hardening | TBD | TBD | planned | G7 accepted by `release-engineer`, `security-engineer`, and `code-reviewer` with PR-only, patch-limit, human-review, and safe-failure evidence in `docs/pm/LESSONS.md`. |
| M8 | Downstream rollout and retrofit repair | TBD | TBD | planned | G8 accepted by `project-manager`, `release-engineer`, and `qa-engineer` with repaired-or-excepted reference-repo status in this schedule. |
| M9 | v1.0 readiness and release gate | TBD | TBD | planned | G9 accepted by `code-reviewer`, `qa-engineer`, `release-engineer`, and `project-manager`, plus customer approval only if release policy requires it, with evidence in `docs/pm/LESSONS.md`. |

## Activities

Activities roll up to milestones. Keep at the size one specialist can
own end-to-end.

| ID | Activity | Owner (teammate) | Predecessors | Duration | Start | Finish | Status |
|---|---|---|---|---|---|---|---|
| A-M0-1 | Define M0/M1 gate model and artifact authority classes. | `project-manager` | T001-T006 | TBD | 2026-05-12 | TBD | in progress |
| A-M0-2 | Define live context surface measurement commands and downstream reference-scope fields. | `project-manager` | A-M0-1 | TBD | 2026-05-12 | TBD | in progress |
| A-M0-3 | Capture baseline metrics and largest recurring context surfaces. | `project-manager` | A-M0-2 | TBD | TBD | TBD | not started |
| A-M1-1 | Create generated runtime candidates and manual guidance without changing canonical role authority. | role owners | G0 | TBD | TBD | TBD | not started |
| A-M1-2 | Script append-only live-register archival and archive pointers. | `software-engineer`, `researcher`, `project-manager` | G0 | TBD | TBD | TBD | not started |
| A-M1-3 | Compact token ledger and task-token fields. | `project-manager` | G0 | TBD | TBD | TBD | not started |
| A-M1-4 | Split PM schedule live/evidence/archive surfaces. | `project-manager` | G0 | TBD | 2026-05-12 | 2026-05-12 | complete |
| A-M1-5 | Record prompt-regression, review evidence, and G1 acceptance. | `qa-engineer`, `code-reviewer`, `project-manager` | A-M1-1, A-M1-2, A-M1-3, A-M1-4 | TBD | TBD | TBD | not started |
| A-M3-1 | Repair atomic questions, batching guidance, customer-question gate, linting, and intake-log scaffold/repair coverage. | `tech-writer`, `researcher`, `software-engineer`, `qa-engineer`, `tech-lead` | G1, US1 acceptance | TBD | TBD | TBD | planned |
| A-M4-1 | Establish documentation authority, roadmap leakage handling, model-routing status, and workflow-pipeline authority. | `architect`, `tech-writer`, `code-reviewer` | G3 | TBD | TBD | TBD | planned |
| A-M5-1 | Document cross-AI harness/provider adapters, fallback behavior, fallback logging, and thin adapter guidance. | `architect`, `release-engineer`, `code-reviewer` | G4 | TBD | TBD | TBD | planned |
| A-M6-1 | Define schemas, contract linting, runtime compilation, generated-artifact stability, and prompt-regression evidence. | `software-engineer`, `qa-engineer`, `code-reviewer` | G5 | TBD | TBD | TBD | planned |
| A-M7-1 | Harden issue-driven self-improvement workflow with PR-only behavior, patch-size limits, human review, and safe failure. | `project-manager`, `architect`, `release-engineer`, `security-engineer`, `code-reviewer` | G6 | TBD | TBD | TBD | planned |
| A-M8-1 | Classify and repair or except QuackDCS, QuackPLC, QuackS7, and QuackSim rollout status. | `project-manager`, `release-engineer`, `qa-engineer`, `tech-writer` | G7 | TBD | TBD | TBD | planned |
| A-M9-1 | Collect final conformance, QA, release, PM, onboarding, process, generated-artifact, and customer-approval-policy evidence. | `code-reviewer`, `qa-engineer`, `release-engineer`, `project-manager`, `onboarding-auditor`, `process-auditor`, `researcher` | G8 | TBD | TBD | TBD | planned |

## Critical path

A-M0-1 -> A-M0-2 -> A-M0-3 -> G0 -> A-M1-1/A-M1-2/A-M1-3/A-M1-4 -> A-M1-5 -> G1 -> US1 acceptance -> A-M3-1 -> G3 -> A-M4-1 -> G4 -> A-M5-1 -> G5 -> A-M6-1 -> G6 -> A-M7-1 -> G7 -> A-M8-1 -> G8 -> A-M9-1 -> G9. Any slip before G0 blocks all M1 acceptance; any failed G1 evidence blocks M2-M9 starts; any failed G3-G9 gate blocks its dependent successor gate.

## PR slicing plan

| PR slice | Scope | Gate | Notes |
|---|---|---|---|
| PR-M0-1 | Baseline report structure, measurement commands, authority/gate records, initial schedule and risk entries. | G0 | M0/M1 planning and evidence only; no downstream edits. |
| PR-M0-2 | Baseline measurements for live context surfaces and reference-scope downstream observations. | G0 | Must land before compaction or archival acceptance. |
| PR-M1-1 | Runtime candidate compaction plus manual/runtime separation evidence. | G1 | Generated candidates only; canonical role files remain authoritative. |
| PR-M1-2 | Live-register archival script, archives, tombstones, and traceability evidence. | G1 | Append-only archive behavior required. |
| PR-M1-3 | Compact token ledger and task token-budget fields. | G1 | No verbatim prompts in live ledger except hash-linked references. |
| PR-M1-4 | PM schedule live/evidence/archive split and acceptance evidence. | G1 | Keep `docs/pm/SCHEDULE.md` current-plan only after split. |

## Gate checks

| Gate | Blocking rule | Acceptance evidence | Status |
|---|---|---|---|
| G0 baseline | No M1 compaction, archival, or PM split acceptance before baseline evidence is recorded. | `docs/pm/token-economy-baseline.md` contains measurement commands, baseline metrics, downstream reference fields, largest live surfaces, and PR slices. | Planned. |
| G1 token quick wins | No M2-M9 authority, routing, compiler, automation, or downstream rollout work starts until G1 passes. | `docs/pm/token-economy-baseline.md`, `docs/runtime/agents/prompt-regression-evidence.md`, `docs/runtime/agents/review-evidence.md`, and `docs/pm/SCHEDULE-EVIDENCE.md` show accepted M1 artifacts and reviews. | Planned. |
| G3 atomic-question and intake repair | M4 authority cleanup and later gates do not start until atomic-question, batching, question-gate, lint, and intake-log evidence is accepted. | `docs/pm/LESSONS.md` records `qa-engineer` lint output, `researcher` intake-log scaffold/repair evidence, and `tech-lead` acceptance. | Planned; accepter: `tech-lead`. |
| G4 documentation authority and drift control | M5 adapter routing does not start until source-authority and shipped-rule placement are accepted. | `docs/pm/LESSONS.md` records authority policy, roadmap handling, model-routing binding status, workflow-pipeline authority, scoped grep output, and `architect`/`code-reviewer` acceptance. | Planned; accepters: `architect`, `code-reviewer`. |
| G5 cross-AI adapter routing | M6 compiler/runtime generation does not start until adapter routing preserves the existing role model. | `docs/pm/LESSONS.md` records adapter ADR, model/provider routing, fallback behavior/logging, thin adapter guidance, no-parallel-role-model validation, and `architect`/`release-engineer`/`code-reviewer` acceptance. | Planned; accepters: `architect`, `release-engineer`, `code-reviewer`. |
| G6 runtime generation and contract validation | M7 automation hardening does not start until generated outputs are reproducible and non-canonical. | `docs/pm/LESSONS.md` records schema validation, contract lint, runtime compilation stability, prompt-regression output, source-authority evidence, and `qa-engineer`/`code-reviewer` acceptance. | Planned; accepters: `qa-engineer`, `code-reviewer`. |
| G7 self-improvement automation hardening | M8 downstream rollout does not start until automation is PR-only, bounded, reviewed, and safe on failure. | `docs/pm/LESSONS.md` records issue taxonomy, workflow evidence, PR-only behavior, contract checks before PR creation, patch-size limits, human-review sequence, safe no-op/issue output, and `release-engineer`/`security-engineer`/`code-reviewer` acceptance. | Planned; accepters: `release-engineer`, `security-engineer`, `code-reviewer`. |
| G8 downstream rollout and retrofit repair | M9 release readiness does not start until all four reference repositories are repaired or explicitly excepted. | `docs/pm/SCHEDULE.md` records QuackDCS, QuackPLC, QuackS7, and QuackSim repaired-or-excepted status; `docs/pm/CHANGES.md` records repair sequence and exceptions; `docs/pm/LESSONS.md` records repair checks; `project-manager`/`release-engineer`/`qa-engineer` accept. | Planned; accepters: `project-manager`, `release-engineer`, `qa-engineer`. |
| G9 v1.0 readiness and release gate | No release-candidate acceptance until all role approvals, validation evidence, release-risk status, and customer-approval-policy status are complete. | `docs/pm/LESSONS.md` records conformance, QA, release, generated-artifact freshness, onboarding/process audit, customer-approval-policy status, and final `code-reviewer`/`qa-engineer`/`release-engineer`/`project-manager` acceptance; `docs/pm/RISKS.md` links release-risk review. | Planned; accepters: `code-reviewer`, `qa-engineer`, `release-engineer`, `project-manager`; customer only if release policy requires it. |
| Future M3/M4 authority and question flow | M3/M4 authority-policy, roadmap-leakage, and customer-question-flow implementation must not start until G1 evidence is accepted in `docs/pm/token-economy-baseline.md`. | `docs/pm/token-economy-baseline.md` records G1 acceptance and contains no M3/M4 implementation evidence beyond future-scope gate notes and prerequisites. | Gated; no M3/M4 implementation started. |
| Future M5 cross-AI adapters | OpenCode, Gemini, OpenAI, Codex, and Claude adapter work in M5 must not start during M0/M1. | `docs/pm/token-economy-baseline.md` contains no cross-AI routing implementation evidence, generated adapter files, fallback logging implementation, or provider-specific routing changes. | Gated; no M5 implementation started. |
| Future M6 generation pipeline | Markdown compiler, LLMD, schema, and runtime generation pipeline implementation in M6 must not start during M0/M1. | `docs/runtime/agents/README.md` keeps runtime candidates generated and subordinate to canonical inputs; no compiler pipeline is accepted in M0/M1. | Gated; no M6 implementation started. |
| Future M7/M8 automation and rollout | Self-improvement automation in M7 and downstream rollout or retrofit work in M8 must not start during M0/M1. | `docs/pm/token-economy-baseline.md` records QuackDCS, QuackPLC, QuackS7, and QuackSim as reference-scope observations only with no downstream product or retrofit edits. | Gated; no M7/M8 implementation started. |

## Baseline Snapshot

Record the baseline date and the milestone dates at baseline. Do not
edit once baselined — re-baseline with a change log row.

| Baseline | Date set | Milestones at baseline |
|---|---|---|
| B-0 | 2026-05-12 | M0/M1 only; dates forecast as TBD until G0 baseline evidence is captured. |

## Variance Log

| Date | Milestone | Baseline | Forecast | Variance | Cause | Response |
|---|---|---|---|---|---|---|
