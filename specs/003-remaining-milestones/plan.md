# Implementation Plan: Remaining Milestones M3-M9

**Branch**: `003-remaining-milestones` | **Date**: 2026-05-12 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/003-remaining-milestones/spec.md`

**Note**: This plan is the `/speckit.plan` output for the remaining milestone feature. At initial plan creation it scoped Phase 0 and Phase 1 planning only; after `/speckit.tasks`, `tasks.md` is an allowed candidate planning artifact, while M3-M9 implementation, issue conversion, downstream repair, automation, and release execution remain future gated work.

## Summary

Plan M3 through M9 as framework-maintenance work that can be decomposed into separately reviewable milestone gates while the customer is unavailable. The slice creates planning artifacts for atomic-question/intake repair, documentation authority and drift control, cross-AI adapter routing, runtime-generation discipline, self-improvement automation constraints, downstream rollout, and v1.0 readiness; it preserves G3-G9 as separate acceptance boundaries and keeps Spec Kit subordinate to `tech-lead` governance.

## Technical Context

**Language/Version**: Markdown for Spec Kit planning artifacts and later canonical framework guidance; later implementation may include POSIX/Bash scripts, JSON schemas, GitHub Actions YAML, and generated Markdown adapters.
**Primary Dependencies**: Existing repository documentation conventions, Git, Spec Kit workflows, canonical sw-dev role contracts, static Markdown/diff checks, shell linting where scripts are introduced later, schema validation where M6 introduces schemas, and GitHub Actions only after the relevant gates.
**Storage**: Repository file-system storage only: planning Markdown, canonical framework documents, templates, scripts, schemas, generated candidates, PM registers, and downstream rollout evidence.
**Testing**: Planning marker checks, `git diff --check`, scoped grep validation, diff inspection, later question lint, scaffold/upgrade smoke tests, schema validation, prompt-regression tests, generated-artifact drift checks, downstream rollout checks, and required specialist review gates.
**Target Platform**: Linux/macOS-compatible development shells for the template repository, Codex/OpenCode/Claude/Gemini-compatible harness adapters, and downstream scaffold/upgrade consumers.
**Project Type**: Documentation/framework-maintenance program plan for a multi-agent software-development template.
**Performance Goals**: Preserve 100% of G3-G9 as separate gates, keep all customer-owned questions atomic, keep generated outputs reproducible and non-canonical unless promoted, achieve repaired-or-excepted status for all four reference repositories, and reach v1.0 readiness only with named role approvals and no release-blocking risk.
**Constraints**: Planning only; do not implement M3-M9, create contracts, edit downstream product files, run release execution, push to protected branches, or mix product and framework changes. `tasks.md` exists only after `/speckit.tasks` as a candidate planning artifact. Spec Kit output is candidate material governed by `tech-lead`; specialist routing and review gates remain binding.
**Scale/Scope**: Remaining framework-maintenance program from M3 through M9 across seven milestone gates, four delivery tranches, canonical template guidance, automation candidates, generated-runtime candidates, and four reference downstream repositories: `QuackDCS`, `QuackPLC`, `QuackS7`, and `QuackSim`.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Role routing**: PASS. Planning ownership is `project-manager`; later documentation policy text routes to `tech-writer`, architecture and adapter decisions to `architect`, scripts/schemas/generators to `software-engineer`, validation to `qa-engineer`, conformance to `code-reviewer`, release mechanics to `release-engineer`, security-sensitive automation to `security-engineer`, customer-truth capture to `researcher`, and final orchestration/customer interface to `tech-lead`.
- **Token/context economy**: PASS. Required planning reads are limited to `spec.md`, this `plan.md`, `research.md`, `data-model.md`, `quickstart.md`, the M3-M9 source-plan sections, constitution, Spec Kit governance note, and directly affected canonical surfaces during later implementation. M6 generated outputs must report line/token impact and avoid becoming live context sinks.
- **Source authority**: PASS. `sw_dev_template_implementation_plan-1.md`, `spec.md`, the constitution, `CLAUDE.md`, `AGENTS.md`, canonical role files, and later approved framework docs remain canonical. Spec Kit artifacts are candidate planning outputs; generated adapters/runtime contracts/session-start files remain generated and reproducible unless explicitly promoted.
- **Customer intake**: PASS. No new customer-owned question is required for planning. If later work exposes uncertainty while the customer is unavailable, it must record a documented assumption or queue one atomic question through `tech-lead` and `researcher` stewardship.
- **Quality gates**: PASS. Before implementation proceeds, validate no planning markers remain, inspect scoped diffs, keep G3-G9 independent, run milestone-specific lint/schema/prompt/downstream checks when introduced, and obtain role-appropriate reviews before commit or release.
- **Framework/project boundary**: PASS. This is explicitly framework-maintenance/template-maintenance planning. Product files, downstream product edits, protected-branch automation, and direct release execution are excluded.
- **Adapter discipline**: PASS. Cross-AI work must adapt the existing sw-dev role model. OpenCode, Gemini, Codex, Claude, compiler, and self-improvement flows must not introduce a parallel role roster, escalation chain, source hierarchy, or customer interface. Spec Kit may generate; `tech-lead` must govern.

## Project Structure

### Documentation (this feature)

```text
specs/003-remaining-milestones/
├── plan.md
├── research.md
├── data-model.md
└── quickstart.md
```

No `contracts/` directory is created for this planning-only slice. During `/speckit.plan`, `tasks.md` does not exist; after `/speckit.tasks`, `tasks.md` is expected and remains a candidate planning artifact until accepted through `tech-lead` governance.

### Source Code / Framework Artifacts (repository root)

```text
AGENTS.md                                      # Codex adapter; Spec Kit plan pointer updated here
CLAUDE.md                                     # later M3 batching/customer-question guidance target
.claude/agents/tech-lead.md                   # later M3 Customer Question Gate target
docs/FIRST_ACTIONS.md                         # later M3 seed/batching guidance target
docs/templates/intake-log-template.md         # later M3 intake repair target
docs/intake-log.md                            # later M3 scaffold/repair coverage target
scripts/lint-questions.sh                     # later M3 question-lint candidate
docs/framework-project-boundary.md            # later M4 authority policy target
docs/model-routing-guidelines.md              # later M4/M5 routing policy target
docs/workflow-pipeline.md                     # later M4 shipped workflow-rule target if needed
docs/adr/                                     # later M5 adapter ADR target
schemas/                                      # later M6 schema targets
scripts/lint-agent-contracts.sh               # later M6 contract-lint candidate
scripts/compile-runtime-agents.sh             # later M6 runtime-generation candidate
.github/workflows/                            # later M7 hardened automation targets
docs/pm/                                      # later M8/M9 schedule, risk, change, lessons evidence
```

**Structure Decision**: Use the existing documentation/framework layout. This plan modifies only planning artifacts and the AGENTS.md Spec Kit pointer; later implementation will touch canonical framework surfaces in milestone-sized PRs, keep generated files reproducible, and keep downstream repository work separated by repo and gate.

## Phase 0: Research Findings

See [research.md](./research.md). All planning unknowns are resolved for M3-M9. Contracts are skipped because this planning slice exposes no external API, CLI command, protocol, service, database schema, package interface, or product integration.

## Phase 1: Design Artifacts

See [data-model.md](./data-model.md) and [quickstart.md](./quickstart.md). The design models remaining milestones, gates, tranches, Spec Kit candidate artifacts, framework-maintenance changes, reference downstream repositories, and release readiness evidence. No `contracts/` directory is created because the current artifacts define internal governance and planning only.

## Post-Design Constitution Check

- **Role routing**: PASS. The design keeps milestone implementation under owning specialists and keeps `tech-lead` as the sole customer interface and Spec Kit governor.
- **Token/context economy**: PASS. Quickstart validation limits planning checks to current artifacts and later milestones require generated-artifact freshness and token/line reporting rather than recurring manual mirrors.
- **Source authority**: PASS. Data-model entities classify Spec Kit output as candidate, generated outputs as reproducible, and canonical framework docs as the source for later changes.
- **Customer intake**: PASS. The plan carries no unresolved customer question; any future ambiguity is handled as an assumption or queued atomic question.
- **Quality gates**: PASS. G3-G9 remain separate acceptance boundaries with milestone-specific validation and review evidence.
- **Framework/project boundary**: PASS. Planning scope is framework-maintenance only and excludes product edits, downstream product changes, direct release execution, and protected-branch automation.
- **Adapter discipline**: PASS. Cross-AI and compiler work remains adapter/generator work over the existing role model and cannot create parallel authority.

## Complexity Tracking

No constitutional violations or complexity exceptions are required for M3-M9 planning.
