# Schedule - Template Improvement Program M0/M1

PMBOK Planning / Monitoring artifact. Owned by `project-manager`.
Live schedule only: current M0/M1 plan, forecast, gates, and PR slices.
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

## Critical path

A-M0-1 -> A-M0-2 -> A-M0-3 -> G0 -> A-M1-1/A-M1-2/A-M1-3/A-M1-4 -> A-M1-5 -> G1. Any slip before G0 blocks all M1 acceptance; any failed G1 evidence blocks M2-M9 starts.

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
