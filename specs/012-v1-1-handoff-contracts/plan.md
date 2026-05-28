# Implementation Plan: v1.1 Handoff Contracts

**Branch**: `012-v1-1-handoff-contracts` | **Date**: 2026-05-27 | **Spec**: `specs/012-v1-1-handoff-contracts/spec.md`
**Input**: Feature specification from `specs/012-v1-1-handoff-contracts/spec.md`

## Summary

Implement v1.1 handoff contracts as framework-maintenance work in `sw-dev-team-template`: durable JSON handoffs, a single active pointer, deterministic path/evidence gates, bounded Codex and model-fallback records, llmdc/Speckit integration rules, and warning-to-enforce readiness evidence. The technical approach extends the existing Python hook/test surface, keeps role authority canonical, starts enforcement in warning mode, and promotes only after the specified smoke baseline has zero unresolved false positives.

## Technical Context

**Language/Version**: Python 3.x for validators/hooks; POSIX shell for hook tests and upgrade smoke checks; JSON Schema for handoff contracts.  
**Primary Dependencies**: Python standard library plus existing repository test scripts; JSON Schema validation through the existing `scripts/validate-handoff.py` path where available.  
**Storage**: Repository files: `docs/handoffs/*.json` for durable handoffs, `.devteam/active-handoff.json` for the pointer, schema and hook libraries under `sw-dev-team-template`.  
**Testing**: Shell tests under `sw-dev-team-template/tests/hooks/`, focused on one-test-verifiable schema, path-scope, gate-mode, evidence, bounded-Codex, model-fallback, and settings-merge behavior.  
**Target Platform**: Linux/macOS developer worktrees running Claude Code, Codex, or OpenCode-compatible hook flows.  
**Project Type**: Framework/template repository with deterministic hook scripts and documentation contracts.  
**Performance Goals**: Hook checks remain local, deterministic, and fast enough for interactive `PreToolUse`/completion gates; no network calls or transcript-scale parsing in hook paths.  
**Constraints**: Preserve canonical role ownership; `tech-lead` remains the only customer interface; forbidden paths override allowed paths; bounded Codex and model fallback never waive evidence, path, customer-truth, or framework-boundary gates.  
**Scale/Scope**: Template-level v1.1 contract surface for one active handoff at a time, multiple durable handoff records, and downstream release readiness smoke coverage.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Role routing**: PASS. Implementation belongs to `software-engineer`; schema/design to `architect`; validation to `qa-engineer`; reviews to `code-reviewer`; security-sensitive review to `security-engineer`; release readiness to `release-engineer`; customer-truth capture to `researcher`. This plan is produced through Spec Kit orchestration and does not grant top-level production authoring authority.
- **Token/context economy**: PASS. Live runtime additions are compact JSON contracts, a pointer file, and hook libraries; long planning context remains in `specs/012-v1-1-handoff-contracts/` and `docs/v1.1-handoff-contracts.md` rather than repeated in runtime prompts.
- **Source authority**: PASS. Canonical inputs are `CLAUDE.md`, `AGENTS.md`, `.claude/agents/*.md`, `.specify/memory/constitution.md`, and the feature spec. Generated/planning artifacts are this plan, `research.md`, `data-model.md`, `quickstart.md`, and `contracts/*` until promoted by implementation.
- **Customer intake**: PASS. Clarifications recorded two customer-owned decisions in the spec; no open customer question blocks planning.
- **Quality gates**: PASS. Implementation tasks must include exact verification commands and require role-appropriate review before commit; enforce-mode readiness requires zero unresolved false positives across the clarified workflow set.
- **Framework/project boundary**: PASS. This is explicitly template-maintenance work for `sw-dev-team-template`; framework-managed edits are authorized by feature scope and remain separate from unrelated root scaffolding changes.
- **Adapter discipline**: PASS. Claude Code, Codex, OpenCode, llmdc, and Speckit are treated as adapters or planning inputs, not parallel authority or independent role rosters.

## Project Structure

### Documentation (this feature)

```text
specs/012-v1-1-handoff-contracts/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── handoff-contract.md
│   └── hook-events.md
└── tasks.md
```

### Source Code (repository root)

```text
sw-dev-team-template/
├── schemas/
│   └── handoff.schema.json
├── docs/
│   ├── handoffs/
│   └── v1.1-handoff-contracts.md
├── .devteam/
│   └── active-handoff.json
├── scripts/
│   ├── validate-handoff.py
│   └── hooks/
│       ├── handoff-pre-tool-gate.py
│       ├── handoff-task-completed-gate.py
│       ├── handoff-record-activity.py
│       ├── handoff-task-created-gate.py
│       ├── handoff-subagent-stop-gate.py
│       ├── handoff-stop-gate.py
│       └── lib/
│           ├── handoff.py
│           ├── path_scope.py
│           └── write_targets.py
├── tests/
│   └── hooks/
│       ├── test-handoff-contracts.sh
│       ├── test-handoff-pre-tool-gate.sh
│       ├── test-handoff-task-completed-gate.sh
│       ├── test-codex-handoff-gate.sh
│       └── test-framework-path-boundary.sh
└── .claude/
    └── settings.json
```

**Structure Decision**: Use the existing `sw-dev-team-template` hook/schema/test layout and add only the v1.1 contract files, hook gates, and tests needed by the spec.

## Complexity Tracking

No constitution violations require justification.

## Phase 0: Research

Research decisions are captured in `research.md`. All technical-context unknowns are resolved without further customer clarification.

## Phase 1: Design & Contracts

Design outputs are captured in `data-model.md`, `contracts/handoff-contract.md`, `contracts/hook-events.md`, and `quickstart.md`. The repository has no `.specify/scripts/*agent*` update script, so the Spec Kit pointer in `AGENTS.md` is updated directly.

## Post-Design Constitution Check

- **Role routing**: PASS. Design artifacts preserve canonical role ownership and identify review/security/release owners.
- **Token/context economy**: PASS. New artifacts are feature-local planning outputs and do not add recurring runtime context except the compact `AGENTS.md` plan pointer.
- **Source authority**: PASS. Planning artifacts cite canonical inputs and do not supersede `CLAUDE.md`, `AGENTS.md`, role files, or schema implementation.
- **Customer intake**: PASS. Clarified decisions are already recorded in the spec; no unresolved customer-owned requirement remains.
- **Quality gates**: PASS. Quickstart and contracts define verification surfaces; task generation must preserve one primary verification per task.
- **Framework/project boundary**: PASS. Planned edits stay in `sw-dev-team-template` framework-maintenance paths plus root Spec Kit planning artifacts.
- **Adapter discipline**: PASS. llmdc and Speckit are constrained as inputs/helpers; Codex/model fallback behavior remains bounded by handoffs.
