# Research: Template Improvement Program M0/M1

## Decision: Scope M0/M1 as the MVP implementation phase

**Rationale**: The spec clarifies that the next planning phase and MVP cover M0 and M1 only, and that all M1 token quick-win artifacts must be fully implemented. This keeps the work reviewable and prevents high-risk later capabilities from starting before token/context controls exist.

**Alternatives considered**: Planning M0-M9 as one implementation phase was rejected because it would mix enabling work with routing, compiler, automation, and rollout work. Planning only M0 was rejected because it would not satisfy the MVP requirement for all M1 artifacts.

## Decision: Treat M2-M9 as broader program context only

**Rationale**: Later milestones define prerequisite order and future gates but are not implementation scope for this plan. They remain useful for preventing premature cross-AI routing, Markdown compilation, self-improvement automation, and downstream rollout.

**Alternatives considered**: Removing later milestones from consideration was rejected because their gates explain why M0/M1 must finish first. Implementing later milestones now was rejected by the explicit scope constraint.

## Decision: Use repository files as the only storage model

**Rationale**: The feature is a documentation/framework-maintenance effort. Baselines, schedules, risk entries, runtime candidates, archives, and evidence are all Markdown or shell-script artifacts in the repository.

**Alternatives considered**: A database, hosted service, or separate state store was rejected because M0/M1 needs auditable file-based changes and no application runtime.

## Decision: Use shell/static validation for M0/M1

**Rationale**: The planned implementation touches Markdown documents and shell scripts. Appropriate validation is line/word-count measurement, shell syntax/static checks, Markdown reference review, generated-candidate comparison, traceability checks, and specialist review.

**Alternatives considered**: Application unit/integration tests were rejected because no application code or external API is introduced. Full prompt-regression automation is retained as an M1 acceptance requirement for selected role candidates but does not require a new external service.

## Decision: Classify artifacts before changing or generating them

**Rationale**: The constitution and source plan require every artifact to be canonical, generated, or ephemeral. M1 runtime candidates must be generated and subordinate to canonical role files, while manuals and policies must have clear authority.

**Alternatives considered**: Maintaining manual mirrors was rejected because duplicated binding text drifts. Treating generated runtime content as canonical was rejected because it could silently change hard rules.

## Decision: Skip external contracts for this phase

**Rationale**: M0/M1 exposes no public API, protocol, CLI command contract for external consumers, or user-facing integration. The only script target, `scripts/archive-registers.sh`, is an internal repository maintenance tool whose behavior should be specified in tasks and verified by shell/static checks.

**Alternatives considered**: Creating placeholder contracts was rejected because it would add non-authoritative surface area. Defining future OpenCode/LLMD contracts was rejected because those are M5/M6 scope.

## Decision: Keep downstream repositories as reference/baseline scope only

**Rationale**: M0 includes baseline checks against QuackDCS, QuackPLC, QuackS7, and QuackSim, but downstream repair is M8. This preserves the framework/project boundary and avoids mixing product or retrofit edits into M0/M1.

**Alternatives considered**: Editing downstream repositories during M0/M1 was rejected because rollout has its own future gate. Ignoring downstream repositories entirely was rejected because the baseline needs reference-scope measurements.

## Decision: Update `AGENTS.md` only as a thin Spec Kit plan pointer

**Rationale**: The requested runtime context change is limited to the text between `<!-- SPECKIT START -->` and `<!-- SPECKIT END -->`, pointing to this plan. This keeps Codex adapter content thin and avoids duplicating plan details in live runtime guidance.

**Alternatives considered**: Copying plan excerpts into `AGENTS.md` was rejected because it would increase recurring context cost. Updating `CLAUDE.md` instead was rejected because the dispatch specifically targets `AGENTS.md`.
