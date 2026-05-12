# Implementation Plan: Template Improvement Program

**Branch**: `001-template-improvement-plan` | **Date**: 2026-05-12 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-template-improvement-plan/spec.md`

**Note**: This plan is the `/speckit.plan` output for the active feature. It scopes the next implementation phase to M0 and M1 only; M2-M9 remain program context and future gating.

## Summary

Implement the M0/M1 MVP for the template improvement program by establishing token/context baselines, then delivering all M1 token quick-win artifacts: compact runtime-agent candidates, scripted live-register archival, compact token-ledger design, and PM live/evidence/archive schedule separation. The work is documentation/framework maintenance in this repository, using Markdown, shell scripts, Spec Kit artifacts, and repository file-system storage; no application database, web service, or external API is introduced.

## Technical Context

**Language/Version**: Markdown for governance and planning artifacts; POSIX-compatible shell where scripts are required; JSON/YAML only for existing repository metadata if touched by later tasks.  
**Primary Dependencies**: Existing repository shell utilities, Git, Markdown static checks, Spec Kit scripts, and role-governance documents; no new package dependency is required for planning.  
**Storage**: Repository file-system storage only: Markdown files, scripts, archives, evidence files, and generated runtime candidates.  
**Testing**: Shell/static checks where applicable, Markdown link/reference review, line-count and word-count/token-proxy measurements, diff inspection, and required specialist review gates.  
**Target Platform**: Linux/macOS-compatible development shells for the template repository and downstream reference repositories.  
**Project Type**: Documentation/framework-maintenance feature for a multi-agent software-development template.  
**Performance Goals**: Establish baseline measurements before change; support at least 30% reduction target for generated/runtime `tech-lead` contract candidates and at least 20% reduction target for other generated/runtime role candidates where safe.  
**Constraints**: Preserve hard rules, escalation formats, customer-interface ownership, source authority, auditability, and framework/project boundary discipline; M0/M1 only; no cross-AI routing, Markdown compiler, self-improvement automation, or downstream rollout implementation begins in this plan.  
**Scale/Scope**: Template repository plus baseline/reference checks for QuackDCS, QuackPLC, QuackS7, and QuackSim; M0 baseline and all M1 token quick-win artifacts.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Role routing**: PASS. Planning ownership is `project-manager`; implementation tasks will route PM artifacts to `project-manager`, shell scripts to `software-engineer`, documentation/manual separation to `tech-writer`, architecture of canonical/generated separation to `architect`, static/prompt regression to `qa-engineer`, conformance review to `code-reviewer`, release wiring to `release-engineer`, customer-truth capture to `researcher`, and security-sensitive automation is out of M0/M1 scope.
- **Token/context economy**: PASS. The feature exists to reduce recurring live context. Required live reads are limited to `spec.md`, this `plan.md`, `research.md`, `data-model.md`, `quickstart.md`, source plan, constitution, and directly affected runtime surfaces; archives and evidence files must not become default session reads.
- **Source authority**: PASS. `spec.md`, constitution, `CLAUDE.md`, `AGENTS.md`, and canonical role files remain authoritative. M0/M1 runtime compaction outputs are generated candidates subordinate to canonical sources. Baseline reports, archives, and evidence files are support artifacts, not policy authority.
- **Customer intake**: PASS. Existing clarifications in `spec.md` are sufficient for M0/M1. No new customer-owned question is required; any future ambiguity must be queued as one atomic question through `tech-lead` and captured by `researcher`.
- **Quality gates**: PASS. Before implementation completion, run shell/static checks for changed scripts and docs, verify token/context measurements, verify archival traceability, inspect relevant diffs, and obtain `code-reviewer`/`qa-engineer` review for role-contract preservation and prompt-regression coverage.
- **Framework/project boundary**: PASS. This is explicitly framework-maintenance work. Product files in downstream repositories are not implementation targets for M0/M1; downstream checks are baseline/reference only unless a later gated rollout authorizes edits.
- **Adapter discipline**: PASS. No cross-AI adapter implementation is in M0/M1. Generated runtime candidates must adapt the existing role model and must not introduce a parallel role roster, escalation chain, source hierarchy, or customer interface.

## Project Structure

### Documentation (this feature)

```text
specs/001-template-improvement-plan/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── checklists/
│   └── requirements.md
└── tasks.md              # Phase 2 output, not created by /speckit.plan
```

### Source Code / Framework Artifacts (repository root)

```text
CLAUDE.md                         # canonical shared runtime authority
AGENTS.md                         # Codex adapter; Speckit plan pointer updated here
.claude/agents/*.md               # canonical role contracts
docs/pm/                          # M0/M1 PM baseline, schedule, risk, evidence, and archive artifacts
docs/agents/manual/               # proposed human-readable manuals for role rationale/examples
docs/runtime/agents/              # proposed generated compact runtime candidates
docs/OPEN_QUESTIONS.md            # live question register candidate for archival policy
CUSTOMER_NOTES.md                 # customer-truth surface; archival only where safe and role-routed
docs/intake-log.md                # intake traceability surface
scripts/archive-registers.sh      # M1 live-register archival script target
```

**Structure Decision**: Use the existing documentation/framework layout. M0/M1 adds or modifies Markdown and shell-script artifacts in-place; it does not introduce an application `src/`, database, service endpoint, or packaged library structure.

## Phase 0: Research Findings

See [research.md](./research.md). All planning unknowns are resolved for M0/M1. Contracts are skipped because M0/M1 exposes no external user-facing API or command surface beyond internal repository scripts and documentation.

## Phase 1: Design Artifacts

See [data-model.md](./data-model.md) and [quickstart.md](./quickstart.md). The design models M0/M1 entities and operator validation steps. No `contracts/` directory is created because external interfaces are out of scope for this phase.

## Post-Design Constitution Check

- **Role routing**: PASS. The data model preserves specialist ownership and keeps `tech-lead` as sole customer interface.
- **Token/context economy**: PASS. M0/M1 entities explicitly separate live surfaces from archives, evidence, generated candidates, and future-scope artifacts.
- **Source authority**: PASS. Artifact authority classes and generated runtime artifacts are modeled separately, preventing generated candidates from becoming source authority.
- **Customer intake**: PASS. Customer questions are modeled as atomic and externally gated; no new customer question remains open from planning.
- **Quality gates**: PASS. Quickstart validation includes baseline existence, artifact completeness, static/shell checks, diff review, and required review gates.
- **Framework/project boundary**: PASS. Downstream repositories are reference scope during M0/M1; product edits are excluded.
- **Adapter discipline**: PASS. Cross-AI routing and generated adapters remain future-scope context only; M1 compaction candidates preserve the canonical role model.

## Complexity Tracking

No constitutional violations or complexity exceptions are required for M0/M1.
