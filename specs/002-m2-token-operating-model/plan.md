# Implementation Plan: M2 Token Operating Model

**Branch**: `002-m2-token-operating-model` | **Date**: 2026-05-12 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-m2-token-operating-model/spec.md`

**Note**: This plan is the `/speckit.plan` output for the active feature. It scopes implementation to M2 only; generated runtime candidates from M0/M1 and M3-M9 remain future scope unless separately planned.

## Summary

Implement M2 as framework-maintenance work that makes token economy an ongoing operating discipline. The slice updates only canonical docs/templates for task token budget bands, just-in-time file lists, token actual closure fields, project-manager delta-pass guidance, AGENTS.md Spec Kit plan-pointer maintenance, and pointer-only memory-query patterns; it introduces no app source tree, external API, service, database, package dependency, generated runtime synchronization, or later-milestone implementation.

## Technical Context

**Language/Version**: Markdown for canonical framework guidance and Spec Kit planning artifacts.
**Primary Dependencies**: Existing repository documentation conventions, Git, Spec Kit scripts, and static Markdown/diff checks; no new package dependency is required.
**Storage**: Repository file-system storage only: Markdown plans, templates, role contracts, and policy documents.
**Testing**: Static marker checks, `git diff --check`, scoped grep-based validation, diff inspection, and required specialist review gates.
**Target Platform**: Linux/macOS-compatible development shells for the template repository and downstream scaffold/upgrade consumers.
**Project Type**: Documentation/framework-maintenance feature for a multi-agent software-development template.
**Performance Goals**: Make token budget information visible in 100% of new task-planning entries, ensure 100% of XL tasks are split or explicitly accepted, and allow routine PM refreshes to avoid broad rereads when delta inputs are sufficient.
**Constraints**: M2 only; update canonical docs/templates only: `docs/templates/task-template.md`, project-manager guidance, `docs/MEMORY_POLICY.md`, `.claude/agents/tech-lead.md`, `.claude/agents/researcher.md`, and the AGENTS.md Spec Kit plan-pointer block; preserve project-manager, researcher, and tech-lead role routing; no generated runtime candidate synchronization, M3-M9 implementation, external service, database, package dependency, app source tree, or `contracts/` directory.
**Scale/Scope**: Template repository canonical guidance surfaces for task planning, PM cadence, and memory-query behavior; generated M0/M1 runtime candidates and downstream product files are excluded.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Role routing**: PASS. Planning ownership is `project-manager`; implementation of template and policy wording should route to the appropriate owning specialists, customer-truth stewardship remains `researcher`, and `tech-lead` remains the sole customer interface.
- **Token/context economy**: PASS. The feature exists to reduce recurring context cost by adding explicit task token bands, first-read file lists, closure actuals, PM delta passes, and memory-first pointer guidance. Required live reads are limited to `spec.md`, this `plan.md`, `research.md`, `data-model.md`, `quickstart.md`, the M2 source section, constitution, and directly affected canonical surfaces.
- **Source authority**: PASS. `spec.md`, the constitution, `CLAUDE.md`, `AGENTS.md`, canonical role files, `docs/MEMORY_POLICY.md`, and `docs/templates/task-template.md` remain canonical. Memory results are pointer-only and generated runtime candidates remain out of scope.
- **Customer intake**: PASS. The accepted clarification in `spec.md` fixes M2 artifact scope. No new customer-owned question is required; any future ambiguity must be queued as one atomic question through `tech-lead` and captured by `researcher`.
- **Quality gates**: PASS. Before implementation completion, verify no unresolved planning markers remain, run static/diff checks, inspect scoped diffs, validate token-budget/PM-delta/memory-query requirements, and obtain role-appropriate review for role-contract and source-authority preservation.
- **Framework/project boundary**: PASS. This is explicitly framework-maintenance/template-maintenance work. Product files, downstream repositories, generated runtime candidates, and release/version files are not M2 implementation targets.
- **Adapter discipline**: PASS. M2 memory and role guidance adapts the existing role model. It must not introduce a parallel role roster, escalation chain, source hierarchy, customer interface, or cross-AI adapter implementation. In a scaffolded `sw-dev-team-template` project, Spec Kit is a subordinate draft-planning/specification workflow invoked by `tech-lead`; slash commands, skills, and wrappers are acceptable harness-specific invocation surfaces. Spec Kit output returns to `tech-lead` for routing, atomization, specialist gates, and authority enforcement: Spec Kit may generate; tech-lead must govern.

## Project Structure

### Documentation (this feature)

```text
specs/002-m2-token-operating-model/
├── plan.md
├── research.md
├── data-model.md
└── quickstart.md
```

No `contracts/` directory or `tasks.md` is created by `/speckit.plan` for M2.

### Source Code / Framework Artifacts (repository root)

```text
AGENTS.md                         # Codex adapter; Spec Kit plan pointer updated here
docs/templates/task-template.md   # canonical task planning template target
docs/MEMORY_POLICY.md             # canonical memory policy target
.claude/agents/project-manager.md # PM operating guidance target
.claude/agents/tech-lead.md       # customer-interface and memory-query guidance target
.claude/agents/researcher.md      # customer-truth and memory-query guidance target
```

**Structure Decision**: Use the existing documentation/framework layout. M2 modifies canonical Markdown guidance in place; it does not introduce application `src/`, tests, external contracts, database schemas, services, APIs, package dependencies, or generated runtime synchronization.

## Phase 0: Research Findings

See [research.md](./research.md). All planning unknowns are resolved for M2. Contracts are skipped because M2 exposes no external API, CLI command, protocol, service, database schema, or package interface.

## Phase 1: Design Artifacts

See [data-model.md](./data-model.md) and [quickstart.md](./quickstart.md). The design models M2 planning, PM-delta, memory-query, and guidance-surface entities plus operator validation steps. No `contracts/` directory is created because all interfaces are internal governance guidance.

## Post-Design Constitution Check

- **Role routing**: PASS. The data model preserves `project-manager` ownership for PM discipline, `researcher` stewardship for customer truth, and `tech-lead` as sole customer interface.
- **Token/context economy**: PASS. M2 entities make expected token cost, first-read scope, and closure actuals visible while defining PM and memory shortcuts that avoid broad rereads.
- **Source authority**: PASS. Guidance surfaces are canonical, memory pointers are non-authoritative, and generated runtime candidates remain excluded.
- **Customer intake**: PASS. No new customer question remains open from planning; the existing clarification records canonical-doc scope.
- **Quality gates**: PASS. Quickstart validation covers planning marker cleanup, runtime pointer correctness, token fields, PM delta guidance, memory query patterns, scope exclusions, static checks, and specialist review gates.
- **Framework/project boundary**: PASS. M2 is framework-maintenance work limited to approved canonical docs/templates and planning artifacts.
- **Adapter discipline**: PASS. AGENTS receives only a Spec Kit plan-pointer update; no adapter behavior or parallel authority is introduced.

## Complexity Tracking

No constitutional violations or complexity exceptions are required for M2.
