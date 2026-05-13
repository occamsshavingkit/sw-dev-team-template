# Research: Remaining Milestones M3-M9

## Milestone Grouping

**Decision**: Group the remaining program into four independently reviewable delivery tranches: M3-M5 foundations, M6 runtime generation, M7 self-improvement, and M8-M9 downstream rollout/release readiness.

**Rationale**: M3-M5 establish question intake, source authority, and adapter routing before any compiler or automation work depends on them. M6 can then create generated runtime candidates safely, M7 can automate only after generation and checks exist, and M8-M9 can validate rollout and release readiness after controls are in place.

**Alternatives considered**: A single M3-M9 implementation tranche was rejected because it would combine unrelated gates into an unsafe, unreviewable change. One PR per subtask was rejected for planning because it obscures the higher-level dependency chain, though later implementation should still use small PRs.

## Gate Preservation

**Decision**: Preserve G3 through G9 as separate acceptance boundaries and prevent later milestones from treating earlier gates as optional.

**Rationale**: The source plan defines G3-G9 as dependency controls: question discipline before authority cleanup, authority before adapters, adapters before generation, generation before self-improvement, and all controls before downstream rollout/release.

**Alternatives considered**: Collapsing M8 and M9 into one release gate was rejected because downstream rollout can expose repair lessons that must feed upstream before release readiness is judged.

## Spec Kit Governance

**Decision**: Treat Spec Kit as a subordinate draft-generation workflow invoked and governed by `tech-lead`.

**Rationale**: The recorded customer guidance states that Spec Kit may generate specifications, plans, tasks, analysis, checklists, and issue-conversion candidates, but `tech-lead` must adjudicate, route, atomize questions, and enforce sw-dev role gates before outputs become authoritative.

**Alternatives considered**: Allowing Spec Kit output to become final authority was rejected because it bypasses canonical role ownership, researcher stewardship of customer truth, and required specialist review gates.

## Generated Artifacts

**Decision**: Generated runtime contracts, adapters, session-start summaries, and reports must identify canonical inputs, be reproducible, and fail validation on manual drift.

**Rationale**: M6 and M7 depend on generated outputs reducing context without creating a new source of truth. Stable generation plus schema/lint/prompt-regression checks lets generated artifacts serve harnesses while canonical Markdown remains authoritative.

**Alternatives considered**: Manually maintaining full adapter copies was rejected because it creates drift and increases context cost. Making compiler output canonical was rejected because the source plan explicitly keeps compiler/LLMD output subordinate.

## Downstream Rollout

**Decision**: Plan M8 as per-repository rollout with repaired-or-excepted status for `QuackDCS`, `QuackPLC`, `QuackS7`, and `QuackSim`.

**Rationale**: The reference repositories have different scaffold and retrofit histories. Per-repo classification and gates protect product/framework boundaries and allow one repo to expose lessons without blocking safe work in another.

**Alternatives considered**: Applying one broad downstream patch across all repos was rejected because it risks mixing product work with framework repair and obscures repo-specific exceptions.

## Automation

**Decision**: Defer self-improvement automation until after G6 and constrain it to PR-only, one-improvement-at-a-time behavior with patch limits, generated-artifact drift checks, contract checks before PR creation, and safe no-op or issue behavior on failure.

**Rationale**: Automation is useful only after source authority, routing, schema, and regression checks exist. PR-only behavior preserves review and prevents direct protected-branch changes.

**Alternatives considered**: Direct push or broad multi-issue automation was rejected because it can mutate protected files, bury review scope, and turn generated drift into committed policy.

## Release Readiness

**Decision**: Plan M9 as a release-readiness gate requiring conformance audit, scaffold/upgrade/retrofit validation, generated-artifact freshness, release mechanics review, PM release-risk review, zero-context usability review, process-debt review, and customer approval if required by release policy.

**Rationale**: v1.0 readiness depends on evidence from code-reviewer, qa-engineer, release-engineer, project-manager, onboarding-auditor, and process-auditor roles, plus the absence or explicit acceptance of release-blocking risks.

**Alternatives considered**: Treating release as a version bump after downstream rollout was rejected because release criteria include role approvals, generated freshness, model-routing verification posture, and policy-dependent customer approval.

## Contracts Directory

**Decision**: Do not create `contracts/` for this planning slice.

**Rationale**: The feature creates internal governance and planning artifacts only. External interfaces, if any, would arise during later schema, adapter, CLI, or workflow implementation and should be documented in the milestone where introduced.

**Alternatives considered**: Pre-creating placeholder contracts was rejected because it would add empty authority surfaces and contradict the planning-only scope.
