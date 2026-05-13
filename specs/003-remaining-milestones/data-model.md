# Data Model: Remaining Milestones M3-M9

## Remaining Milestone

**Purpose**: Represents one planned milestone from M3 through M9.

**Fields**:
- `id`: Milestone identifier, one of `M3` through `M9`.
- `objective`: Concise outcome from the source plan.
- `scope`: Included work areas for the milestone.
- `gate_id`: Matching acceptance gate, one of `G3` through `G9`.
- `owner_roles`: Canonical specialist roles expected to own implementation, validation, or review.
- `pr_slices`: Later implementation PR groupings, when known from the source plan.
- `dependencies`: Prior gates or artifacts that must be accepted first.
- `excluded_work`: Work explicitly out of scope for the milestone.

**Relationships**:
- Belongs to one `Delivery Tranche`.
- Is accepted by one `Milestone Gate`.
- May produce or update one or more `Framework Maintenance Change` records.
- May depend on `Spec Kit Candidate Artifact` outputs that have been governed by `tech-lead`.

**Validation**:
- `id` and `gate_id` must match numerically.
- No milestone may implement or accept a later gate.
- Each milestone must preserve canonical role routing and quality gates.

**Lifecycle**:
- `planned` -> `tasks-generated` -> `in-implementation` -> `under-review` -> `gate-accepted` or `blocked`.

## Milestone Gate

**Purpose**: Defines the separate acceptance boundary for each milestone.

**Fields**:
- `id`: Gate identifier, one of `G3` through `G9`.
- `pass_criteria`: Testable criteria from the source plan and spec.
- `required_evidence`: Validation outputs, diffs, reports, approvals, or documented exceptions.
- `required_roles`: Specialist roles that must review or approve the gate.
- `blocking_risks`: Open risks that prevent acceptance.

**Relationships**:
- Accepts exactly one `Remaining Milestone`.
- May require one or more `Release Readiness Evidence` records for G9.

**Validation**:
- Criteria must be independently reviewable.
- Later milestones may not claim readiness when earlier gates remain blocked.

**Lifecycle**:
- `not-started` -> `evidence-gathering` -> `review-ready` -> `accepted` or `blocked`.

## Delivery Tranche

**Purpose**: Groups related milestones for reviewable planning and execution.

**Fields**:
- `name`: Tranche name.
- `milestones`: Included milestone IDs.
- `purpose`: Why the milestones belong together.
- `entry_conditions`: Required prior gates.
- `exit_conditions`: Gates or evidence needed before the next tranche.

**Relationships**:
- Contains one or more `Remaining Milestone` records.

**Validation**:
- Must not combine implementation of multiple gates into one unreviewable task.
- Must support at least the four tranches required by the spec: M3-M5 foundations, M6 runtime generation, M7 self-improvement, and M8-M9 rollout/release.

## Spec Kit Candidate Artifact

**Purpose**: Captures draft output created by Spec Kit before it is governed by the sw-dev team process.

**Fields**:
- `artifact_path`: Repository path to the candidate output.
- `artifact_type`: `spec`, `plan`, `research`, `data-model`, `quickstart`, `tasks`, `checklist`, `analysis`, or `issues`.
- `canonical_inputs`: Source files or recorded customer notes used to generate it.
- `governance_status`: `candidate`, `routed`, `reviewed`, `accepted`, or `rejected`.
- `governing_role`: Usually `tech-lead`, with specialist owners for artifact review.
- `customer_question_status`: `none`, `assumption-recorded`, or `atomic-question-queued`.

**Relationships**:
- May inform `Remaining Milestone` planning.
- Must be reviewed before it creates or changes `Framework Maintenance Change` scope.

**Validation**:
- Cannot be treated as final authority while `governance_status` is `candidate`.
- Customer-owned content must cite a recorded answer, assumption, or queued atomic question.

**Lifecycle**:
- `candidate` -> `routed` -> `reviewed` -> `accepted` or `rejected`.

## Framework Maintenance Change

**Purpose**: Represents planned changes to framework-managed guidance, scripts, schemas, adapters, workflows, or release artifacts.

**Fields**:
- `change_id`: Stable identifier assigned during later task generation or PR planning.
- `milestone_id`: Owning milestone.
- `paths`: Framework-managed paths expected to change.
- `authority_class`: `canonical`, `generated`, or `ephemeral`.
- `change_type`: `documentation`, `script`, `schema`, `adapter`, `workflow`, `template`, `pm-register`, or `release-artifact`.
- `review_roles`: Required specialist reviewers.
- `boundary_status`: `framework-only`, `downstream-framework-repair`, or `exception-required`.

**Relationships**:
- Implements part of one `Remaining Milestone`.
- May produce `Release Readiness Evidence` in M9.

**Validation**:
- Product files must not be included unless explicitly authorized for that later task.
- Generated paths must identify canonical inputs and regeneration checks.
- Protected-branch or direct-release changes are not allowed.

## Reference Downstream Repository

**Purpose**: Represents a downstream repository used to validate rollout and retrofit behavior.

**Fields**:
- `name`: `QuackDCS`, `QuackPLC`, `QuackS7`, or `QuackSim`.
- `scaffold_mode`: `retrofitted` or `from-template`.
- `known_observations`: Source-plan notes such as intake-log presence, roadmap staleness, large live registers, or atomic-question violations.
- `rollout_status`: `not-started`, `classified`, `repairing`, `repaired`, `excepted`, or `blocked`.
- `exceptions`: Documented reasons a repo cannot be fully repaired during M8.
- `lessons_upstreamed`: Whether rollout lessons have been captured upstream.

**Relationships**:
- Is evaluated during M8.
- May produce upstream `Framework Maintenance Change` candidates or scaffold smoke-test updates.

**Validation**:
- Each reference repo must end M8 as `repaired` or `excepted`.
- Product/framework boundary status must be explicit before repair work.

## Release Readiness Evidence

**Purpose**: Captures evidence needed for G9 release-candidate acceptance.

**Fields**:
- `evidence_id`: Stable evidence identifier.
- `source`: Report, validation command, review note, PM register update, or release artifact.
- `covered_criteria`: M9 release criteria addressed by the evidence.
- `approving_role`: `code-reviewer`, `qa-engineer`, `release-engineer`, `project-manager`, `onboarding-auditor`, `process-auditor`, or `tech-lead`.
- `status`: `pending`, `passed`, `failed`, `waived`, or `blocked`.
- `customer_approval_required`: Boolean or policy-derived unknown resolved before release.
- `customer_approval_status`: `not-required`, `queued`, `received`, or `blocked`.

**Relationships**:
- Supports G9 `Milestone Gate` acceptance.
- May cite earlier `Milestone Gate` evidence.

**Validation**:
- G9 cannot pass with unresolved high-priority authority-drift issues or open release-blocking PM risks.
- Customer approval must be obtained if required by release policy.

**Lifecycle**:
- `pending` -> `passed` or `failed`; failures become `blocked` until fixed, waived, or converted into a release-blocking risk.
