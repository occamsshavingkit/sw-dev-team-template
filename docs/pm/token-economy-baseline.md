# Token Economy Baseline — Template Improvement Program M0/M1

Owned by `project-manager`. This support/evidence artifact defines the measurement commands and fields required before M1 compaction, archival, token-ledger, or PM split changes are accepted. Downstream repositories are reference scope only for M0/M1; do not edit them from this baseline.

## Gate Status

| Gate | Decision | Evidence required before pass |
|---|---|---|
| G0 baseline acceptance | accepted 2026-05-12 | Baseline line counts, word-count token proxies, live-register metrics, downstream reference fields, largest recurring context surfaces, and M0/M1 PR slices captured below. |
| G1 token quick-win acceptance | accepted 2026-05-12 | Runtime candidates, archival script and archives, compact token ledger, PM schedule split, prompt-regression/review evidence, and explicit M2-M9 prohibition recorded below. |

## Measurement Commands

Run commands from repository root unless a downstream reference path is supplied. Record command output in the tables below or in later evidence files; do not accept compaction or archival changes until the pre-change measurements are captured.

| Metric | Scope | Command |
|---|---|---|
| Live surface line count | Single file or glob | `wc -l <path>` |
| Live surface word-count token proxy | Single file or glob | `wc -w <path>` |
| Canonical role contract size | `.claude/agents/*.md` | `wc -l .claude/agents/*.md && wc -w .claude/agents/*.md` |
| PM live surface size | `docs/pm/SCHEDULE.md`, `docs/pm/CHANGES.md`, `docs/pm/LESSONS.md`, `docs/pm/TOKEN_LEDGER.md` | `wc -l docs/pm/SCHEDULE.md docs/pm/CHANGES.md docs/pm/LESSONS.md docs/pm/TOKEN_LEDGER.md && wc -w docs/pm/SCHEDULE.md docs/pm/CHANGES.md docs/pm/LESSONS.md docs/pm/TOKEN_LEDGER.md` |
| Register row-count proxy | Markdown table files | `grep -c '^|' <path>` |
| Terminal-row proxy | Register status terms | `grep -Ei 'closed|done|answered|resolved|terminal' <path>` |
| Archive candidate proxy | Register status terms older than current milestone | `grep -Ei 'closed|done|answered|resolved|terminal' <path>` then manually verify milestone age. |
| Downstream file presence | Reference repo path | `test -e <repo>/<path> && printf 'present\n' || printf 'missing\n'` |
| Downstream template version | Reference repo path | `test -f <repo>/TEMPLATE_VERSION && wc -l <repo>/TEMPLATE_VERSION` then read value manually if present. |

## Live Context Surface Metrics

Capture these fields before accepting M1 changes.

| Surface | Authority class | Owner | Baseline lines | Baseline word proxy | Largest-surface rank | Archive/evidence path | Notes |
|---|---|---|---|---|---|---|---|
| `CLAUDE.md` | canonical | `tech-lead` | 342 | 2,256 | 2 | n/a | Shared runtime authority; largest single top-level policy surface. |
| `AGENTS.md` | canonical | `tech-lead` | 257 | 1,692 | 4 | n/a | Codex adapter authority. |
| `.claude/agents/*.md` | canonical | role owners | 2,840 | 19,057 | 1 | `docs/runtime/agents/` candidates later | Aggregate of 14 canonical role contracts; M1 generated candidates must remain subordinate. |
| `docs/OPEN_QUESTIONS.md` | canonical | `researcher` | 36 | 1,030 | 7 | `docs/OPEN_QUESTIONS-ARCHIVE.md` planned | Live register candidate; all current rows are answered. |
| `CUSTOMER_NOTES.md` | canonical | `researcher` | 321 | 1,890 | 3 | `docs/customer-notes-archive.md` planned | Customer-truth surface; archive only with traceability. |
| `docs/intake-log.md` | canonical | `researcher` | missing | missing | n/a | `docs/intake-log-ARCHIVE.md` planned | Listed in baseline model but absent in this repository at measurement time. |
| `docs/pm/SCHEDULE.md` | support/evidence | `project-manager` | 64 | 696 | 8 | `docs/pm/SCHEDULE-EVIDENCE.md`, `docs/pm/SCHEDULE-ARCHIVE.md` planned | Live plan surface. |
| `docs/pm/CHANGES.md` | support/evidence | `project-manager` | 77 | 1,319 | 5 | TBD | Change-control surface. |
| `docs/pm/LESSONS.md` | support/evidence | `project-manager` | 210 | 1,172 | 6 | `docs/pm/LESSONS-ARCHIVE.md` planned | Lessons surface; recurring context surface with historical content. |
| `docs/pm/TOKEN_LEDGER.md` | support/evidence | `project-manager` | 51 | 306 | 9 | `docs/pm/token-ledger/prompts/` planned | Live token ledger. |

### Canonical Role Contract Detail

| Surface | Baseline lines | Baseline word proxy | Notes |
|---|---:|---:|---|
| `.claude/agents/tech-lead.md` | 444 | 3,150 | Largest individual role contract. |
| `.claude/agents/qa-engineer.md` | 411 | 2,943 | Second-largest individual role contract. |
| `.claude/agents/researcher.md` | 283 | 2,025 | Third-largest individual role contract. |
| `.claude/agents/process-auditor.md` | 225 | 1,274 | Candidate for generated runtime reduction. |
| `.claude/agents/code-reviewer.md` | 208 | 1,536 | Candidate for generated runtime reduction. |
| `.claude/agents/architect.md` | 206 | 1,324 | Candidate for generated runtime reduction. |
| `.claude/agents/project-manager.md` | 184 | 1,149 | Candidate for generated runtime reduction. |
| `.claude/agents/onboarding-auditor.md` | 155 | 958 | Candidate for generated runtime reduction. |
| `.claude/agents/security-engineer.md` | 148 | 881 | Candidate for generated runtime reduction. |
| `.claude/agents/release-engineer.md` | 145 | 1,072 | Candidate for generated runtime reduction. |
| `.claude/agents/software-engineer.md` | 140 | 967 | Candidate for generated runtime reduction. |
| `.claude/agents/sme-template.md` | 128 | 809 | Candidate for generated runtime reduction. |
| `.claude/agents/sre.md` | 101 | 604 | Candidate for generated runtime reduction. |
| `.claude/agents/tech-writer.md` | 62 | 365 | Smallest role contract; reduction may be low-value. |

## Live Register Metrics

| Register | Row-count proxy | Terminal-row proxy | Archive candidates | Notes |
|---|---|---|---|---|
| `docs/OPEN_QUESTIONS.md` | 17 table rows | 15 terminal status rows (`answered`) | 15 answered question rows | Preserve open and recently answered rows live; no open rows observed. |
| `CUSTOMER_NOTES.md` | 0 table rows; 14 dated sections | 0 terminal table rows | Candidate review required; all entries are customer-truth records, not safe for blind archival | Archive only where safe; customer truth must remain traceable. |
| `docs/intake-log.md` | missing | missing | n/a | Preserve intake traceability when present; missing in this repository at measurement time. |
| `docs/pm/RISKS.md` | 8 table rows | 0 terminal status rows; 6 open risk rows | 0 risk rows | Risks are closed, never deleted; all current risks are open. |
| `docs/pm/LESSONS.md` | 0 table rows; 5 dated sections | 0 terminal table rows | 5 historical lesson sections after review | Archive historical lessons after milestone close where safe. |

## Downstream Reference Scope

Record observations only. Do not edit QuackDCS, QuackPLC, QuackS7, or QuackSim during M0/M1 baseline work.

| Repository | Reference path | Baseline checked | Scaffold mode | `TEMPLATE_VERSION` | `docs/intake-log.md` present | Live register observations | Context surface notes | Exceptions | Rollout status |
|---|---|---|---|---|---|---|---|---|---|
| QuackDCS | `/home/quackdcs/QuackDCS` | yes, read-only 2026-05-12 | retrofitted/reference | `v1.0.0-rc8` `7c5c9901e3c366d62ccac4f82a22cb7868590fce` stamped 2026-05-06 | missing | `docs/OPEN_QUESTIONS.md` present, 40 lines; `CUSTOMER_NOTES.md` present, 1,993 lines | Large customer-notes surface compared with this repository; no downstream edits made. | `docs/intake-log.md` missing. | M8 future scope only. |
| QuackPLC | `/home/quackdcs/QuackPLC` | yes, read-only 2026-05-12 | retrofitted/reference | `v1.0.0-rc8` `7c5c9901e3c366d62ccac4f82a22cb7868590fce` stamped 2026-05-06 | missing | `docs/OPEN_QUESTIONS.md` present, 86 lines; `CUSTOMER_NOTES.md` present, 2,678 lines | Largest observed downstream customer-notes surface; no downstream edits made. | `docs/intake-log.md` missing. | M8 future scope only. |
| QuackS7 | `/home/quackdcs/QuackS7` | yes, read-only 2026-05-12 | retrofitted/reference | `v1.0.0-rc8` `7c5c9901e3c366d62ccac4f82a22cb7868590fce` stamped 2026-05-07 | present, 326 lines | `docs/OPEN_QUESTIONS.md` present, 56 lines; `CUSTOMER_NOTES.md` present, 2,189 lines | Large customer-notes and intake surfaces; no downstream edits made. | none observed in checked fields. | M8 future scope only. |
| QuackSim | `/home/quackdcs/QuackSim` | yes, read-only 2026-05-12 | from-template/reference | `v1.0.0-rc8` `7c5c9901e3c366d62ccac4f82a22cb7868590fce` stamped 2026-05-06 | present, 504 lines | `docs/OPEN_QUESTIONS.md` present, 72 lines; `CUSTOMER_NOTES.md` present, 478 lines | Largest observed downstream intake-log surface; no downstream edits made. | none observed in checked fields. | M8 future scope only. |

## G0 Baseline Acceptance Evidence

| Evidence item | Status | Evidence |
|---|---|---|
| Baseline line counts captured | pass | Live context surface table populated for requested files and `.claude/agents/*.md`; `docs/intake-log.md` recorded as missing. |
| Baseline word-count token proxies captured | pass | Live context surface table populated using `wc -w` output from repository root. |
| Live-register row counts captured | pass | `docs/OPEN_QUESTIONS.md`, `CUSTOMER_NOTES.md`, `docs/pm/RISKS.md`, and `docs/pm/LESSONS.md` recorded with table-row or dated-section proxies. |
| Terminal-row counts captured | pass | Terminal status rows recorded; non-table registers have 0 terminal table rows and dated-section counts for archive review. |
| Archive candidates identified | pass | Answered questions, historical lessons, and zero closed risks recorded; customer notes require manual traceability review. |
| Downstream observations captured read-only | pass | QuackDCS, QuackPLC, QuackS7, and QuackSim checked at `/home/quackdcs/*`; no downstream files edited. |
| Largest recurring context surfaces identified | pass | Aggregate role contracts, `CLAUDE.md`, `CUSTOMER_NOTES.md`, `AGENTS.md`, `docs/pm/CHANGES.md`, and `docs/pm/LESSONS.md` are the largest measured recurring surfaces by word proxy. |

## Largest Recurring Context Surfaces

Ranked by baseline word-count token proxy among measured repository surfaces:

| Rank | Surface | Word proxy | Lines | Reduction / split path |
|---:|---|---:|---:|---|
| 1 | `.claude/agents/*.md` aggregate | 19,057 | 2,840 | M1 generated runtime candidates under `docs/runtime/agents/`, subordinate to canonical contracts. |
| 2 | `CLAUDE.md` | 2,256 | 342 | Preserve as canonical; avoid adding support evidence to this live authority surface. |
| 3 | `CUSTOMER_NOTES.md` | 1,890 | 321 | Archive only traceable, safe entries; customer truth remains authoritative. |
| 4 | `AGENTS.md` | 1,692 | 257 | Preserve as Codex adapter; avoid duplicating role-contract prose. |
| 5 | `docs/pm/CHANGES.md` | 1,319 | 77 | Keep append-only; consider evidence/archive split only if growth continues. |
| 6 | `docs/pm/LESSONS.md` | 1,172 | 210 | Candidate for `docs/pm/LESSONS-ARCHIVE.md` after milestone-safe review. |

Within `.claude/agents/*.md`, the largest individual recurring surfaces are `tech-lead` (3,150 words), `qa-engineer` (2,943 words), and `researcher` (2,025 words).

## Runtime Candidate Reduction Metrics

Measured 2026-05-12 from repository root with `wc -l` and `wc -w`. Runtime candidates are generated, non-authoritative support artifacts; canonical role files remain the source of truth.

| Role | Canonical lines | Candidate lines | Line reduction | Canonical word proxy | Candidate word proxy | Word reduction | Target | Exception |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| `tech-lead` | 444 | 40 | 91.0% | 3,150 | 290 | 90.8% | >=30% | none |
| `architect` | 206 | 29 | 85.9% | 1,324 | 177 | 86.6% | >=20% | none |
| `software-engineer` | 140 | 29 | 79.3% | 967 | 181 | 81.3% | >=20% | none |
| `qa-engineer` | 411 | 30 | 92.7% | 2,943 | 197 | 93.3% | >=20% | none |
| `code-reviewer` | 208 | 30 | 85.6% | 1,536 | 183 | 88.1% | >=20% | none |
| `researcher` | 283 | 29 | 89.8% | 2,025 | 211 | 89.6% | >=20% | none |
| `project-manager` | 184 | 25 | 86.4% | 1,149 | 189 | 83.6% | >=20% | none |
| `tech-writer` | 62 | 29 | 53.2% | 365 | 165 | 54.8% | >=20% | none |
| `release-engineer` | 145 | 31 | 78.6% | 1,072 | 178 | 83.4% | >=20% | none |
| `security-engineer` | 148 | 29 | 80.4% | 881 | 176 | 80.0% | >=20% | none |
| `sre` | 101 | 29 | 71.3% | 604 | 174 | 71.2% | >=20% | none |
| `onboarding-auditor` | 155 | 21 | 86.5% | 958 | 150 | 84.3% | >=20% | none |
| `process-auditor` | 225 | 21 | 90.7% | 1,274 | 143 | 88.8% | >=20% | none |
| `sme-template` | 128 | 22 | 82.8% | 809 | 180 | 77.8% | >=20% | none |

Accepted exceptions: none. All runtime candidates meet or exceed the M1 line-count and word-proxy reduction targets while retaining canonical-source pointers and shared runtime-rule references.

## PM Schedule Split Metrics

Measured 2026-05-12 from repository root with `wc -l docs/pm/SCHEDULE.md docs/pm/SCHEDULE-EVIDENCE.md docs/pm/SCHEDULE-ARCHIVE.md` after T041-T044 edits.

| Surface | Post-change lines | Role in split | Evidence |
|---|---:|---|---|
| `docs/pm/SCHEDULE.md` | 70 | Live current M0/M1 plan only | Cross-links evidence and archive files; no closed rows or historical reconciliations present at split time. |
| `docs/pm/SCHEDULE-EVIDENCE.md` | 40 | Closure evidence, raw references, and G0/G1 acceptance support | Records T041-T044 closure evidence and G0/G1 support references. |
| `docs/pm/SCHEDULE-ARCHIVE.md` | 24 | Old closed schedule rows and historical reconciliations | Created with append-only usage notes; records that no old closed rows were present to move. |

PM split status: pass for T041-T044. The live schedule remains the current-plan surface; evidence and archive material is separated and cross-linked without fabricating historical rows.

## G1 Token Quick-Win Acceptance Evidence

G1 status: pass with documented non-blocking compaction gaps. G1 acceptance covers M1 token quick-win artifacts only and does not authorize any M2-M9 implementation start.

| Evidence item | Status | Evidence |
|---|---|---|
| Runtime candidates created and measured | pass | `docs/runtime/agents/*.md` candidates exist for all canonical roles listed in the runtime reduction metrics; all meet target line-count and word-proxy reductions with no accepted exceptions. Candidates remain generated, non-authoritative support artifacts subordinate to `CLAUDE.md`, `AGENTS.md`, and `.claude/agents/*.md`. |
| Prompt-regression evidence recorded | pass with non-blocking gaps | `docs/runtime/agents/prompt-regression-evidence.md` covers `tech-lead`, `researcher`, `code-reviewer`, and `qa-engineer`; overall status is pass with documented gaps for compressed `tech-lead` intake-register naming and `code-reviewer` traceability wording. |
| Code-review preservation evidence recorded | pass with non-blocking gaps | `docs/runtime/agents/review-evidence.md` records pass status for hard rules, role authority, escalation format, local supplement checks, sole customer-interface ownership, and no specialist spawning/customer contact; QA-noted gaps are explicitly non-blocking for G1. |
| Archival script and archive surfaces present | pass | `scripts/archive-registers.sh` implements dry-run default, append-only `--apply`, source/archive pair listing, checksum de-duplication, and optional tombstone rewrite only after archive checksum confirmation; archive surfaces exist for open questions, customer notes, intake log, PM risks, and PM lessons. |
| Compact token ledger accepted | pass | `docs/pm/TOKEN_LEDGER.md` uses the compact `Date | Task ID | Agent | Prompt hash | Prompt class | Token budget | Token actual | Notes` schema and keeps full prompt text out of the live ledger. |
| PM schedule split accepted | pass | `docs/pm/SCHEDULE.md` is the live current-plan surface; `docs/pm/SCHEDULE-EVIDENCE.md` holds closure and acceptance support; `docs/pm/SCHEDULE-ARCHIVE.md` holds historical rows. Post-change line counts are recorded above. |
| M2-M9 implementation prohibition recorded | pass | M2-M9 implementation must not start from this M0/M1 task list. Later milestones may appear only as gate checks that prevent premature implementation until their own authorized scope exists. |

Explicit prohibition: do not begin M2 token operating model, M3/M4 authority or customer-question-flow repairs, M5 cross-AI routing, M6 Markdown compiler/schema/generation pipeline, M7 self-improvement automation, M8 downstream rollout/retrofit, or M9 release-readiness implementation from the M0/M1 task list.

## Acceptance Notes

- G0 accepted 2026-05-12 for baseline evidence collection. Remaining `TBD` fields are limited to later G1 artifacts or non-applicable missing-file cases.
- G1 accepted 2026-05-12 for M1 token quick-win evidence with documented non-blocking compaction gaps.
- M2-M9 implementation remains explicitly blocked from this M0/M1 task list; future-scope rows may only record gates that prevent premature starts.
- Reference-scope downstream observations may inform future M8 planning, but downstream product or retrofit edits are outside M0/M1.

## Future-Scope Gate Confirmations

| Scope | Confirmation |
|---|---|
| M3/M4 authority and question flow | No M3/M4 implementation evidence is recorded beyond future-scope gate notes and G1 prerequisites. |
| M5 cross-AI routing | No cross-AI routing implementation evidence, generated adapter files, fallback logging implementation, or provider-specific routing changes are recorded. |
| M8 downstream references | QuackDCS, QuackPLC, QuackS7, and QuackSim are recorded as reference-scope observations only; no downstream product or retrofit edits are recorded. |
