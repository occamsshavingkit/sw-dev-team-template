# Implementation Plan: sw-dev-team-template improvement program (M0–M9)

**Branch**: `004-m8-m10-plan` | **Date**: 2026-05-13 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `./spec.md`

## Summary

Ship the 10-milestone (M0–M9) improvement program against the template repo at `./sw-dev-team-template`. The sequence is enabling-first: measure (M0) → compact runtime contracts and archive live registers (M1) → make token economy ongoing (M2) → repair atomic-question protocol and intake (M3) → fix documentation authority (M4) → add OpenCode/Gemini/OpenAI routing as adapter (M5) → ship the Markdown contract compiler + schemas + prompt-regression set (M6) → enable safe self-improvement automation (M7) → roll out to four reference downstream repos (M8) → v1.0.0 release gate (M9). Work in this meta-project's specs/ tree only produces planning artifacts; every implementation edit lands inside `./sw-dev-team-template`.

## Technical Context

**Language/Version**: Bash (POSIX sh for shipped scripts, bash 5.x for non-shipped tooling); Python 3.11 for hook scripts and pytest-based guards; JSON Schema 2020-12 for FR-022 schemas; Markdown for canonical content.
**Primary Dependencies**: Standard CLI tools (`bash`, `awk`, `sed`, `grep`, `jq`, `git`, `gh`, `comm`, `find`); `check-jsonschema` (CLI) or `python-jsonschema` for schema validation; Markdown compiler TBD via Phase-0 research; YAML parser for `.specify/extensions.yml` already in place.
**Storage**: Plain Markdown / JSON / shell scripts under git; no database. Token-ledger prompt archive under `docs/pm/token-ledger/prompts/<task-id>-<agent>.md`.
**Testing**: bash test harness (existing `tests/stepwise-smoke.sh` pattern); Python `pytest` for guards (existing `test_customer_notes_guard.py` pattern); prompt-regression set under `tests/prompt-regression/` (new at M6.3); question-lint fixture corpus under `tests/lint-questions/` (new at M3.4).
**Target Platform**: Linux developer workstation and GitHub Actions runner (ubuntu-latest). Scripts in shipped ship-set MUST stay POSIX sh; tooling-only scripts MAY use bash 5.x.
**Project Type**: Documentation + tooling repository (the template itself). Meta-project hosts the workshop and produces planning artifacts only.
**Performance Goals**: Token reduction ≥30% on `tech-lead` runtime contract, ≥20% on other core agents (SC-001, SC-002). CI workflow target ≤2 min wall-clock per run; full conformance audit at G9 target ≤30 min wall-clock end-to-end.
**Constraints**: Strict POSIX `sh` portability for every script in the downstream ship-set; deterministic and reproducible compiler output (byte-identical between successive runs); generated artifacts MUST identify canonical inputs (Constitution III, VII); the AI self-improvement loop MUST NOT push to `main` and MUST NOT directly edit protected-files or customer-truth sets (FR-027).
**Scale/Scope**: ~12 canonical agent contracts; 4 reference downstream repos (`QuackDCS`, `QuackPLC`, `QuackS7`, `QuackSim`); 33 functional requirements; 14 success criteria; 10 milestones with 10 gates; ~16+ PRs per spec §5 (template plan section).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Role routing**: `project-manager` owns this plan and the M0 baseline measurement; `architect` owns the canonical/generated/runtime separation (M1.1, M6.1); `software-engineer` owns scripts, schemas, and the compiler (M1, M3.4, M3.5, M6.2, M7.3); `tech-writer` owns the Documentation Authority Policy, the workflow-pipeline canonical move, and the binding-status flip on `model-routing-guidelines.md` (M4); `code-reviewer` owns pre-commit review on every PR and the agent-contract lint design (M6.1, G9); `qa-engineer` owns prompt-regression set design and question-lint test fixtures (M3.4, M6.3); `release-engineer` owns GitHub Actions workflows, OpenCode adapter packaging, and release mechanics (M5, M7.4, M9); `security-engineer` owns the FR-026 redaction policy and the AI-loop blast-radius review (M7); `researcher` owns memory-first query patterns and external compiler research (M2.3, M6 research). No specialist contacts the customer; all escalation routes through `tech-lead`.
- **Token/context economy**: Plan, research, data-model, contracts, and quickstart are ephemeral planning artifacts and are NOT loaded into runtime context. Live files read at runtime: `CLAUDE.md`, `.claude/agents/<role>.md`, current PM SCHEDULE row, open OPEN_QUESTIONS rows. Generated runtime contracts under `docs/runtime/agents/` replace the live read of the full `.claude/agents/*.md` for compact-context sessions (M1.1). M2.1 token budgets are recorded per task; M2.2 PM delta pass replaces full PM rereads. Net effect: every recurring surface is measured (M0) and bounded (M1.2, M1.4) before new context cost is added.
- **Source authority**: Canonical = `.claude/agents/*.md`, `CLAUDE.md`, `AGENTS.md`, `docs/adr/*.md`, `CUSTOMER_NOTES.md`, the binding policies/guidelines under `docs/`. Generated = `docs/runtime/agents/*.md`, OpenCode adapters under `.opencode/`, compact session-start summaries. Ephemeral = scratch audits, run logs, this `plan.md` and siblings. Every generated artifact identifies its canonical inputs in the schema (`schemas/generated-artifact.schema.json`, FR-022). Manual mirrors prohibited; sharing content means generate-or-link.
- **Customer intake**: 14 customer-policy clarifications already recorded in `spec.md` Session 2026-05-13. Three remaining items (Markdown compiler tool, token-budget band numbers, patch-size limit) are NOT customer-policy decisions — they are tooling choices resolved in Phase-0 research below. Any new customer-policy question that surfaces during implementation queues to `tech-lead` and is asked atomically when all tools are idle (Constitution IV).
- **Quality gates**: Every PR receives `code-reviewer` review before merge. Prompt-regression tests (M6.3) run against canonical and compiled contracts; question-lint runs warning-only after M3.4 and hard-gates at the next MINOR-boundary Release per FR-012. Agent-contract lint hard-gates at M6.1 land. CI workflows from M7.4 gate PR merges: `agent-contract-check.yml`, `question-lint.yml`, `template-contract-smoke.yml`. `security-engineer` signs off on M7 (self-improvement loop) and FR-026 redaction handling per Constitution V and Hard Rule #7. No release ships without G9 audit roles' canonical sign-offs plus customer approval at v1.0.0 final (FR-032).
- **Framework/project boundary**: This program is a framework-maintenance task; the customer has authorized framework edits in `./sw-dev-team-template` by selecting the source plan as the active sprint. The meta-project at `/home/quackdcs/SWEProj` is workshop-only (out of scope per spec clarification 4); every implementation edit MUST target `./sw-dev-team-template`. Downstream rollout at M8 follows the per-repo one-at-a-time policy with the `## Mixed-PR authorizations` mechanism for explicit mixing (FR-030) and the upstream-issue waiver mechanism for deferred deliverables (FR-029).
- **Adapter discipline**: M5 ships ADR `fw-adr-0009-opencode-harness-adapter.md` declaring OpenCode adapter-only; M5.4 generated adapters reference canonical `.claude/agents/<role>.md` plus an optional local supplement and contain no duplicated role text (FR-021). M6 compiler is generator-only — it MUST NOT silently rewrite hard rules, MUST NOT hide harness differences, and MUST NOT become source of truth (FR-023). Memory layer (claude-mem) remains pointer-only per ADR-0001.

**Result**: PASS on all seven principles. No Complexity Tracking entries.

## Project Structure

### Documentation (this feature)

```text
specs/006-template-improvement-program/
├── plan.md              # This file
├── spec.md              # Feature specification (already complete)
├── research.md          # Phase 0 output (resolves implementation-tooling unknowns)
├── data-model.md        # Phase 1 output (entities + state transitions)
├── quickstart.md        # Phase 1 output (program kickoff runbook)
├── contracts/           # Phase 1 output (JSON Schemas for FR-022)
│   ├── agent-contract.schema.json
│   ├── model-routing.schema.json
│   └── generated-artifact.schema.json
├── checklists/
│   └── requirements.md  # Spec quality checklist (already complete)
└── tasks.md             # Phase 2 output (/speckit-tasks command)
```

### Source Code (working tree of the sub-repo `./sw-dev-team-template`)

```text
sw-dev-team-template/
├── .claude/
│   └── agents/                              # canonical (M1: split rationale to manual/)
│       ├── tech-lead.md                     # M3.3 Customer Question Gate
│       ├── researcher.md                    # M2.3 memory-first patterns
│       ├── project-manager.md               # M2.2 PM delta pass
│       └── *.md                             # other canonical role files
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   └── framework-gap.yml                # M7.2 (FR-026, FR-029 waiver path)
│   └── workflows/
│       ├── agent-contract-check.yml         # M7.4 (FR-028)
│       ├── question-lint.yml                # M7.4 (FR-028)
│       ├── template-contract-smoke.yml      # M7.4 (FR-028)
│       └── improve-template.yml             # M7.4 manual/scheduled (FR-027, FR-028)
├── .opencode/                                # generated (M5.4, FR-021)
│   └── agents/
│       └── *.md                             # thin adapters; manual edits fail lint
├── docs/
│   ├── adr/
│   │   └── fw-adr-0009-opencode-harness-adapter.md  # M5.1 (FR-018)
│   ├── agents/
│   │   └── manual/                          # M1.1 expanded rationale (canonical)
│   │       └── *.md
│   ├── framework-project-boundary.md         # M4.1 Documentation Authority Policy
│   ├── model-routing-guidelines.md           # M4.3 binding flip; M5.2 extensions
│   ├── workflow-pipeline.md                  # M4.4 NEW canonical home (FR-017)
│   ├── MEMORY_POLICY.md                      # M2.3 memory-first patterns
│   ├── pm/
│   │   ├── SCHEDULE.md                       # M1.4 live plan only
│   │   ├── SCHEDULE-EVIDENCE.md              # M1.4 NEW
│   │   ├── SCHEDULE-ARCHIVE.md               # M1.4 NEW
│   │   ├── RISKS.md / RISKS-ARCHIVE.md
│   │   ├── LESSONS.md / LESSONS-ARCHIVE.md
│   │   ├── token-economy-baseline.md         # M0 (FR-002)
│   │   ├── audits/                           # generated G9 + post-release audit reports
│   │   └── token-ledger/
│   │       ├── ledger.md                     # M1.3 compact schema (FR-005)
│   │       └── prompts/
│   │           └── <task-id>-<agent>.md      # M1.3 archive
│   ├── proposals/                            # M7 paired Markdown proposals
│   │   └── <topic>.md
│   ├── runtime/                              # generated (M1.1, M6.2)
│   │   └── agents/
│   │       ├── tech-lead.md                  # compact runtime contract
│   │       └── *.md
│   ├── OPEN_QUESTIONS.md / OPEN_QUESTIONS-ARCHIVE.md
│   ├── intake-log.md / intake-log-ARCHIVE.md
│   ├── templates/
│   │   └── task-template.md                  # M2.1 token-budget fields (FR-007)
│   └── IP_POLICY.md                          # FR-026 sensitive-content scope
├── schemas/                                  # M6.1 (FR-022)
│   ├── agent-contract.schema.json
│   ├── model-routing.schema.json
│   └── generated-artifact.schema.json
├── scripts/
│   ├── archive-registers.sh                  # M1.2 (FR-004)
│   ├── lint-questions.sh                     # M3.4 (FR-012)
│   ├── lint-agent-contracts.sh               # M6.2 (FR-023)
│   ├── compile-runtime-agents.sh             # M6.2 (FR-023)
│   ├── baseline-token-economy.sh             # M0 (FR-002)
│   ├── log-fallback.sh                       # M5.3 (FR-020)
│   ├── m8-boundary-check.sh                  # M8.3 (FR-029, FR-030)
│   └── ...                                   # existing scripts preserved
├── tests/
│   ├── prompt-regression/                    # M6.3 (FR-024)
│   ├── lint-questions/                       # M3.4 fixture corpus
│   └── ...                                   # existing tests preserved
├── CUSTOMER_NOTES.md / customer-notes-archive.md
├── CLAUDE.md / AGENTS.md                     # canonical; protected from AI loop
├── VERSION / TEMPLATE_MANIFEST.lock          # canonical; protected from AI loop
└── migrations/                               # canonical; protected from AI loop
    └── v*.refs                               # FR-013 stale-ref scan, prior work
```

**Structure Decision**: Documentation/tooling repository structure. The template repo (`./sw-dev-team-template`) is the implementation surface; the meta-project root carries only this `specs/006-template-improvement-program/` tree. No application source code, no models/services/api layers. Layout above is the concrete target tree after all 10 milestones; per-milestone task slicing happens in `/speckit-tasks`.

## Complexity Tracking

No Constitution Check violations. Table omitted.
