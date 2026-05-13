# Research: M8-M10 Plan

## Source Authority

**Decision**: Treat `sw_dev_template_implementation_plan-2.md` as the canonical source for M8 and M9 milestone scope, with `specs/004-m8-m10-plan/spec.md` and `plan.md` as derived planning artifacts.

**Rationale**: The feature input explicitly requests planning from the new source plan, and the spec assumptions identify that file as the canonical source for M8 and M9.

**Alternatives considered**: Inventing scope from prior conversations was rejected because it would create undocumented authority drift. Treating the Spec Kit spec as the only source was rejected because the spec itself depends on the source plan for milestone content.

## M10 Absence

**Decision**: Record M10 as absent from the authoritative source plan and do not define M10 objectives, deliverables, or gates in this feature.

**Rationale**: The source plan contains M8 and M9 sections but no M10 section, and the feature specification requires honest bounded gap handling.

**Alternatives considered**: Creating a speculative M10 milestone was rejected because it would violate source authority. Ignoring M10 was rejected because the user explicitly requested M8, M9, and M10, so the absence must be documented.

## Downstream Rollout Sequencing

**Decision**: Plan M8 as a per-repository rollout sequence for `QuackDCS`, `QuackPLC`, `QuackS7`, and `QuackSim`, followed by the aggregate G8 acceptance gate.

**Rationale**: The source plan requires classifying each downstream repository, applying the repair sequence per repo, and accepting G8 only when all four are repaired or exceptioned and rollout lessons are captured upstream.

**Alternatives considered**: A single batch rollout was rejected because failures or waivers must be reviewable per repository. Deferring downstream specifics to tasks only was rejected because the plan must preserve the source-plan classifications and gate expectations.

## Exception Handling

**Decision**: Allow documented exceptions or waivers for inaccessible repositories, live context surfaces above soft caps, historical question-lint warnings, and repositories that cannot immediately satisfy a rollout gate.

**Rationale**: M8 gate criteria explicitly allow waivers for live context soft caps and documented historical exceptions for atomic-question lint warnings; the feature edge cases require honest exception handling for unavailable or partially compliant repositories.

**Alternatives considered**: Hard-failing any incomplete downstream repository was rejected because the source plan permits documented exceptions. Silently passing exceptions was rejected because G8 requires auditable evidence.

## Release Gate Evidence

**Decision**: Plan M9 evidence around fresh scaffold smoke tests, retrofit repair evidence, agent-contract lint, question lint, generated-artifact freshness, authority-drift status, model-routing guidance currency, release-note classification, and named specialist approvals.

**Rationale**: These evidence categories are listed directly in M9.2 and G9 and align with the constitution's quality-gate principle.

**Alternatives considered**: A lightweight release checklist was rejected because it would omit required audit perspectives. Treating customer approval as unconditional was rejected because G9 makes it conditional on release policy.

## Contracts Decision

**Decision**: Do not define external API or product contracts for this feature during Phase 0; if Phase 1 artifacts are generated later, contracts should be limited to planning/gate evidence formats only when a public interface is explicitly identified.

**Rationale**: The feature is planning and documentation work, not an application or service with external runtime interfaces. The observable contract is the milestone/gate evidence required by the spec and source plan.

**Alternatives considered**: Creating API-style contracts was rejected as irrelevant. Creating no contract guidance at all was rejected because later task planning may still need a clear evidence-format decision.
