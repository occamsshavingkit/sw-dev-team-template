# M0/M1 Artifact Index

This index is a support artifact for T001. It records the required M0/M1 artifacts, their owning role, authority class, acceptance source, and current status. M2-M9 items are included only where M0/M1 tasks require explicit future-scope gate checks.

## Authority Classes

| Class | Use in this index |
|---|---|
| `canonical` | Human-maintained source of truth or binding input for this plan. |
| `generated` | Derived runtime candidate or generated output subordinate to canonical inputs. |
| `ephemeral` | Temporary work product that does not govern runtime behavior unless promoted. |
| `support/evidence` | Measurement, schedule, risk, archive, review, or validation record supporting acceptance but not policy authority. |

## Artifact Register

| Artifact path | Task IDs or source | Owner role | Authority class | Acceptance source | Current status |
|---|---|---|---|---|---|
| `specs/001-template-improvement-plan/m0-m1-artifact-index.md` | T001 | `project-manager` | support/evidence | T001 requires artifact path, task/source, owner role, authority class, acceptance source, and status. | Created by T001. |
| `docs/pm/SCHEDULE.md` | T002, T009, T043, T048, T050, T052, T054 | `project-manager` | support/evidence | Tasks T002/T009/T043 and quickstart checks for M0/M1 schedule entries, PR slicing, G0/G1 gates, live/evidence/archive split, and future-scope gate rows. | Planned; may already exist before T002. |
| `docs/pm/RISKS.md` | T003, T010 | `project-manager` | support/evidence | Tasks T003/T010 and quickstart checks for initial M0/M1 risks covering context, authority, compiler, routing, archive traceability, and runtime compaction. | Planned; may already exist before T003. |
| `docs/runtime/agents/README.md` | T004, T053 | `architect` | support/evidence | T004/T053 require generated-runtime status, canonical inputs, manual-edit prohibition, review gate, and subordination to canonical role sources. | Planned. |
| `docs/agents/manual/README.md` | T005 | `tech-writer` | support/evidence | T005 requires manual status, intended content, and non-authority relationship to `.claude/agents/*.md`. | Planned. |
| `docs/pm/token-ledger/prompts/README.md` | T006 | `project-manager` | support/evidence | T006 requires prompt archive rules and hash linkage to `docs/pm/TOKEN_LEDGER.md`. | Planned. |
| `docs/pm/token-economy-baseline.md` | T011-T016, T032, T044, T047, T049, T051, T055, T062 | `project-manager` | support/evidence | Data model `Context Surface`/`Milestone Gate`; quickstart checks for baseline, post-change metrics, G0/G1 evidence, downstream reference scope, and no premature future-scope implementation. | Planned. |
| `docs/agents/common-runtime.md` | T017 | `architect` | generated | T017 requires shared runtime rules candidate preserving hard rules, local supplement checks, escalation, role authority, and customer-interface ownership. | Planned. |
| `docs/runtime/agents/tech-lead.md` | T018 | `tech-lead` | generated | T018/T032/T045/T046 require canonical-source derivation, 30% reduction target or exception, prompt-regression evidence, and preservation review. | Planned. |
| `docs/runtime/agents/architect.md` | T019 | `architect` | generated | T019/T032/T046 require canonical-source derivation, 20% reduction target or exception, and preservation review. | Planned. |
| `docs/runtime/agents/software-engineer.md` | T020 | `software-engineer` | generated | T020/T032/T046 require canonical-source derivation, 20% reduction target or exception, and preservation review. | Planned. |
| `docs/runtime/agents/qa-engineer.md` | T021 | `qa-engineer` | generated | T021/T032/T045/T046 require canonical-source derivation, 20% reduction target or exception, prompt-regression evidence, and preservation review. | Planned. |
| `docs/runtime/agents/code-reviewer.md` | T022 | `code-reviewer` | generated | T022/T032/T045/T046 require canonical-source derivation, 20% reduction target or exception, prompt-regression evidence, and preservation review. | Planned. |
| `docs/runtime/agents/researcher.md` | T023 | `researcher` | generated | T023/T032/T045/T046 require canonical-source derivation, 20% reduction target or exception, prompt-regression evidence, and preservation review. | Planned. |
| `docs/runtime/agents/project-manager.md` | T024 | `project-manager` | generated | T024/T032/T046 require canonical-source derivation, 20% reduction target or exception, and preservation review. | Planned. |
| `docs/runtime/agents/tech-writer.md` | T025 | `tech-writer` | generated | T025/T032/T046 require canonical-source derivation, 20% reduction target or exception, and preservation review. | Planned. |
| `docs/runtime/agents/release-engineer.md` | T026 | `release-engineer` | generated | T026/T032/T046 require canonical-source derivation, 20% reduction target or exception, and preservation review. | Planned. |
| `docs/runtime/agents/security-engineer.md` | T027 | `security-engineer` | generated | T027/T032/T046 require canonical-source derivation, 20% reduction target or exception, and preservation review. | Planned. |
| `docs/runtime/agents/sre.md` | T028 | `sre` | generated | T028/T032/T046 require canonical-source derivation, 20% reduction target or exception, and preservation review. | Planned. |
| `docs/runtime/agents/onboarding-auditor.md` | T029 | `onboarding-auditor` | generated | T029/T032/T046 require canonical-source derivation, 20% reduction target or exception, and preservation review. | Planned. |
| `docs/runtime/agents/process-auditor.md` | T030 | `process-auditor` | generated | T030/T032/T046 require canonical-source derivation, 20% reduction target or exception, and preservation review. | Planned. |
| `docs/runtime/agents/sme-template.md` | T031 | `sme-template` | generated | T031/T032/T046 require canonical-source derivation, 20% reduction target or exception, and preservation review. | Planned. |
| `docs/agents/manual/runtime-manual-guidance.md` | T033 | `tech-writer` | support/evidence | T033 requires human-readable manual extraction guidance for runtime-candidate rationale and examples. | Planned. |
| `scripts/archive-registers.sh` | T034, T058 | `software-engineer` | support/evidence | T034/T058 and quickstart require append-only archival behavior and `sh -n scripts/archive-registers.sh`. | Planned. |
| `docs/OPEN_QUESTIONS.md` | T013, T014, T034, T036 | `researcher` | canonical | T013/T014/T034/T036 require live-register measurement, archival support, compact tombstone, and archive-pointer guidance without losing open or recent rows. | Existing canonical surface; updates planned. |
| `CUSTOMER_NOTES.md` | T013, T014, T034, T036 | `researcher` | canonical | T013/T014/T034/T036 require live-register measurement, archival support, compact tombstone, and archive-pointer guidance without losing open or recent rows. | Existing canonical surface; updates planned. |
| `docs/intake-log.md` | T034, T035 | `researcher` | canonical | T034/T035 require append-only archival support and archive creation for intake traceability. | Existing canonical surface; updates planned. |
| `docs/OPEN_QUESTIONS-ARCHIVE.md` | T035 | `researcher` | support/evidence | T035 requires source-file header and append-only usage notes. | Planned. |
| `docs/customer-notes-archive.md` | T035 | `researcher` | support/evidence | T035 requires source-file header and append-only usage notes. | Planned. |
| `docs/intake-log-ARCHIVE.md` | T035 | `researcher` | support/evidence | T035 requires source-file header and append-only usage notes. | Planned. |
| `docs/pm/RISKS-ARCHIVE.md` | T035 | `project-manager` | support/evidence | T035 requires source-file header and append-only usage notes. | Planned. |
| `docs/pm/LESSONS-ARCHIVE.md` | T035 | `project-manager` | support/evidence | T035 requires source-file header and append-only usage notes. | Planned. |
| `.claude/agents/researcher.md` | T037 | `researcher` | canonical | T037 requires archival mechanism references for `CUSTOMER_NOTES.md`, `docs/OPEN_QUESTIONS.md`, and `docs/intake-log.md`. | Existing canonical surface; updates planned. |
| `docs/pm/TOKEN_LEDGER.md` | T006, T013, T038 | `project-manager` | support/evidence | T038 requires compact schema `Date | Task ID | Agent | Prompt hash | Prompt class | Token budget | Token actual | Notes`. | Existing or planned support surface; updates planned. |
| `docs/templates/pm/TOKEN_LEDGER-template.md` | T039 | `project-manager` | canonical | T039 requires template alignment with the compact token-ledger schema. | Existing canonical template; updates planned. |
| `docs/templates/task-template.md` | T040 | `project-manager` | canonical | T040 requires token budget, just-in-time file list, and token actual fields as future task definition-of-done inputs. | Existing canonical template; updates planned. |
| `docs/pm/SCHEDULE-EVIDENCE.md` | T041, T044, T058-T061, T063 | `project-manager` | support/evidence | T041 and final validation tasks require closure evidence, raw references, shell/static check results, diff-scope review, and review signoffs. | Planned. |
| `docs/pm/SCHEDULE-ARCHIVE.md` | T042, T044 | `project-manager` | support/evidence | T042/T044 require old closed schedule rows, historical reconciliations, and post-change line counts. | Planned. |
| `docs/runtime/agents/prompt-regression-evidence.md` | T045 | `qa-engineer` | support/evidence | T045 requires prompt-regression evidence for `tech-lead`, `researcher`, `code-reviewer`, and `qa-engineer` runtime candidates. | Planned. |
| `docs/runtime/agents/review-evidence.md` | T046 | `code-reviewer` | support/evidence | T046 requires preservation evidence for hard rules, role authority, escalation formats, local supplement checks, and customer-interface ownership. | Planned. |
| `CLAUDE.md` | plan/source authority | `tech-lead` | canonical | Plan constitution check identifies it as shared runtime authority; M0/M1 generated outputs must remain subordinate. | Existing canonical input; no T001 edit. |
| `AGENTS.md` | plan/source authority | `tech-lead` | canonical | Plan constitution check identifies it as Codex adapter authority and current Speckit plan pointer. | Existing canonical input; no T001 edit. |
| `.claude/agents/*.md` | T018-T031 source inputs | owning canonical role | canonical | Runtime candidate tasks require generated outputs from canonical role contracts while preserving hard rules and authority. | Existing canonical inputs; no T001 edit. |
| `docs/pm/LESSONS.md` | T013, T014, T034, T036 | `project-manager` | support/evidence | T013/T014/T034/T036 require measurement, archival support, compact tombstone, and archive-pointer guidance. | Existing or planned support surface; updates planned. |
| QuackDCS, QuackPLC, QuackS7, QuackSim reference observations | T012, T015, T055 | `project-manager` | support/evidence | T012/T015/T055 require reference-scope measurements only, recorded without downstream product or retrofit edits. | Planned reference-only evidence; no downstream edits. |

## M0/M1 Gate Model

M0/M1 uses two blocking gates. Later milestones M2-M9 may be referenced only as future-scope constraints and must not begin from this artifact.

| Gate | Milestone | Objective | Entry criteria | Acceptance criteria | Evidence path | Review roles | Status |
|---|---|---|---|---|---|---|---|
| G0 | M0 baseline | Accept the current context-cost baseline before compaction, archival, or PM split changes are accepted. | T007-T012 complete; measurement commands and reference-scope fields exist. | Baseline report records live context surface metrics, live-register metrics, downstream reference fields, largest recurring context surfaces, and first M0/M1 PR slices; no OpenCode, LLMD, compiler, self-improvement automation, or downstream edits have started. | `docs/pm/token-economy-baseline.md` | `project-manager`, `qa-engineer`, `code-reviewer` | Planned. |
| G1 | M1 token quick wins | Accept M1 context-reduction artifacts before any later authority, routing, compiler, automation, or rollout implementation starts. | G0 passed; M1 implementation artifacts exist. | Runtime candidates preserve canonical authority, required reduction targets or exceptions are recorded, live-register archival is scripted and traceable, compact token ledger exists, PM schedule live/evidence/archive split exists, prompt-regression and review evidence exist, and M2-M9 work remains blocked. | `docs/pm/token-economy-baseline.md`, `docs/runtime/agents/prompt-regression-evidence.md`, `docs/runtime/agents/review-evidence.md`, `docs/pm/SCHEDULE-EVIDENCE.md` | `project-manager`, `qa-engineer`, `code-reviewer`, `release-engineer` | Planned. |

## Artifact Authority Class Records

| Path pattern | Authority class | Canonical inputs | Manual edit policy | Review gate | M0/M1 note |
|---|---|---|---|---|---|
| `CLAUDE.md` | canonical | Human-maintained shared runtime contract and constitution-aligned governance. | Direct edits require explicit framework-maintenance scope and specialist review. | Role, source-authority, and hard-rule preservation review before commit. | Existing authority; M0/M1 generated outputs stay subordinate. |
| `AGENTS.md` | canonical | Codex adapter contract plus thin Spec Kit plan pointer. | Keep adapter content thin; do not duplicate plan or role contract bodies. | Adapter-discipline and framework-boundary review. | Existing authority; no T007-T012 edit. |
| `.claude/agents/*.md` | canonical | Human-maintained canonical role contracts and local supplement checks. | Role owners may update through approved framework-maintenance tasks; generated candidates must not overwrite. | Role authority, escalation, and customer-interface preservation review. | Source inputs for M1 runtime candidates. |
| `docs/runtime/agents/*.md` | generated | `CLAUDE.md`, `AGENTS.md`, `.claude/agents/*.md`, and shared runtime rules. | Do not manually treat as authority; changes must be reproducible or reviewed as generated candidates. | Prompt-regression and code-review preservation evidence. | M1 runtime candidates only, subordinate to canonical sources. |
| `docs/agents/manual/*.md` | support/evidence | Canonical role files and reviewed rationale/examples. | May explain rationale and examples, but must not introduce binding role rules. | Tech-writer/source-authority review. | Human-readable support, not runtime authority. |
| `docs/pm/*.md` | support/evidence | PMBOK templates, Spec Kit plan, task list, and accepted evidence. | PM-owned project records; avoid turning evidence/archive files into default live reads. | PM schedule/risk/baseline review; code-reviewer/qa gates where required. | M0/M1 planning, baseline, risk, evidence, archive, and token-ledger support surfaces. |
| `specs/001-template-improvement-plan/*.md` | canonical | Spec Kit feature artifacts and approved source plan. | Update only within active feature scope; tasks may be marked complete only after implementation evidence exists. | Constitution and task-scope review. | Active planning authority for M0/M1 implementation. |

## M0/M1 Gate Acceptance Sources

| Gate | Required evidence | Acceptance source | Status |
|---|---|---|---|
| G0 baseline acceptance | Baseline line counts, token proxies, live-register row counts, downstream reference observations, and largest recurring context surfaces. | T011-T016; `data-model.md` Milestone Gate and Context Surface; `quickstart.md` section 4. | Planned. |
| G1 token quick-win acceptance | Runtime candidates, archival script and archives, compact token ledger, PM schedule split, review evidence, prompt-regression evidence, and explicit prohibition on M2-M9 starts. | T017-T047; `quickstart.md` sections 5-9; `data-model.md` M0/M1 Artifact Set. | Planned. |
| Future-scope blocking gates | Schedule/baseline rows proving M3-M8/M6/M5 work is blocked until prerequisite gates pass. | T048-T055; `tasks.md` Phases 4-7. | Planned gate checks only; no future implementation. |
