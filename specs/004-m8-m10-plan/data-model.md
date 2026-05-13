# Data Model: M8-M10 Plan

## Scope

This model describes planning and status entities for the M8 downstream rollout, M9 release-readiness gate, and the documented M10 source-plan gap. It is technology-agnostic and defines reviewable planning records, not database tables or implementation schemas.

No external API contracts are introduced by this feature.

## Entity: Reference Repository

Represents one downstream repository in the M8 reference rollout set.

### Fields

- `name`: Repository name; one of `QuackDCS`, `QuackPLC`, `QuackS7`, or `QuackSim`.
- `scaffold_mode`: Source-plan classification; expected values are `retrofitted` or `from-template`.
- `known_observations`: Source-plan observations that shape repair expectations.
- `repair_status`: Current repair outcome summary; expected values are `not-started`, `in-progress`, `repaired`, or `exceptioned`.
- `exception_status`: Whether repair or gate completion is covered by a documented exception; expected values are `none`, `proposed`, `accepted`, or `rejected`.
- `rollout_gate_status`: Current M8 per-repository gate status; expected values are `not-evaluated`, `pass`, `fail`, or `exceptioned`.

### Identity And Uniqueness

- Identity is `name`.
- Exactly four Reference Repository records exist unless the authoritative source plan is updated.
- `name` must be unique within the M8 rollout set.

### Relationships

- Has one Repair Outcome.
- Has one per-repository Rollout Gate.
- May contribute lessons to the full-rollout Rollout Gate.

### Validation Rules

- `QuackDCS`, `QuackPLC`, and `QuackS7` must have `scaffold_mode = retrofitted`.
- `QuackSim` must have `scaffold_mode = from-template`.
- A repository cannot have `rollout_gate_status = pass` while `repair_status` is `not-started` or `in-progress`.
- A repository with `rollout_gate_status = exceptioned` must have `exception_status = accepted`.
- Known observations must remain traceable to the source plan and must not invent new downstream facts.

## Entity: Repair Outcome

Represents the observable result of M8 repair planning for one Reference Repository.

### Fields

- `repository_name`: Reference Repository identity.
- `required_file_status`: Required framework-file result; expected values are `not-checked`, `complete`, `missing`, or `exceptioned`.
- `intake_log_status`: `docs/intake-log.md` result; expected values are `not-checked`, `present`, `created-or-planned`, `missing`, or `exceptioned`.
- `live_register_disposition`: Live-register handling; expected values are `not-checked`, `within-soft-cap`, `archived`, `waived`, or `exceptioned`.
- `roadmap_disposition`: Root-roadmap handling; expected values are `not-applicable`, `verified-project-local`, `repaired`, `quarantined`, or `exceptioned`.
- `pm_surface_disposition`: PM live/evidence surface handling; expected values are `not-checked`, `within-envelope`, `split-or-planned`, `waived`, or `exceptioned`.
- `question_lint_disposition`: Atomic-question lint result; expected values are `not-run`, `clean`, `fixed`, `historical-exception`, or `blocking`.
- `pm_change_log_evidence`: Evidence that template upgrade or repair was recorded in the PM change log.
- `outcome_status`: Overall repair outcome; expected values are `not-started`, `in-progress`, `complete`, `blocked`, or `exceptioned`.

### Identity And Uniqueness

- Identity is `repository_name`.
- At most one current Repair Outcome exists per Reference Repository.

### Relationships

- Belongs to one Reference Repository.
- Feeds the corresponding per-repository Rollout Gate.

### Validation Rules

- `outcome_status = complete` requires all repair dimensions to be complete, non-applicable, repaired, quarantined, fixed, clean, within-envelope, or otherwise acceptable under the source plan.
- `outcome_status = exceptioned` requires at least one repair dimension to be `exceptioned` or an accepted historical exception.
- `pm_change_log_evidence` is required before `outcome_status` can be `complete`, unless an accepted exception covers it.
- `question_lint_disposition = blocking` prevents `outcome_status = complete`.
- Repair outcomes must describe externally observable evidence, not implementation commands.

## Entity: Rollout Gate

Represents either a per-repository M8 gate or the full Gate G8 acceptance checkpoint.

### Fields

- `gate_id`: Stable gate identifier, such as `G8-QuackDCS` or `G8`.
- `scope`: Gate scope; expected values are `repository` or `full-rollout`.
- `repository_name`: Reference Repository identity when `scope = repository`.
- `required_framework_files_result`: Gate result for required framework files; expected values are `not-evaluated`, `pass`, `fail`, or `exceptioned`.
- `live_context_result`: Gate result for live context soft caps or waivers; expected values are `not-evaluated`, `pass`, `fail`, or `waived`.
- `question_lint_result`: Gate result for atomic-question lint disposition; expected values are `not-evaluated`, `pass`, `fail`, or `historical-exception`.
- `boundary_compliance_result`: Product/framework boundary result; expected values are `not-evaluated`, `pass`, `fail`, or `exceptioned`.
- `upstream_lesson_capture`: Whether rollout lessons are captured upstream; expected values are `not-required`, `pending`, `captured`, or `exceptioned`.
- `scaffold_smoke_reflection`: Whether new scaffold smoke coverage reflects downstream repair lessons; expected values are `not-required`, `pending`, `reflected`, or `exceptioned`.
- `exceptions_or_waivers`: Documented exceptions or waivers relevant to the gate.
- `gate_status`: Overall gate status; expected values are `not-evaluated`, `pass`, `fail`, or `exceptioned`.

### Identity And Uniqueness

- Identity is `gate_id`.
- For `scope = repository`, `repository_name` must be unique across repository-scope Rollout Gates.
- Exactly one `scope = full-rollout` Rollout Gate represents Gate G8.

### Relationships

- Repository-scope Rollout Gates belong to one Reference Repository and consume its Repair Outcome.
- The full-rollout Gate G8 depends on all four repository-scope Rollout Gates.

### Validation Rules

- A repository-scope gate cannot pass unless required framework files pass, live context passes or is waived, question lint passes or is documented as a historical exception, and boundary compliance passes.
- A repository-scope gate may be `exceptioned` only when its exception or waiver is documented and accepted.
- The full-rollout Gate G8 cannot pass unless all four repository-scope gates pass or are exceptioned, upstream lessons are captured, and scaffold smoke reflection is complete or exceptioned.
- Gate records must preserve source-plan pass criteria and must not silently convert failures into passes.

## Entity: Release Readiness Audit

Represents one M9 audit perspective required before release-candidate acceptance.

### Fields

- `audit_id`: Stable identifier for the audit perspective.
- `perspective`: Required reviewer perspective; expected values are `code-review`, `qa`, `release-engineering`, `project-management`, `onboarding-audit`, or `process-audit`.
- `coverage`: Audit coverage expected from the source plan.
- `audit_outcome`: Current audit outcome; expected values are `not-started`, `in-progress`, `approved`, `approved-with-exceptions`, or `rejected`.
- `blocking_risks`: Release-blocking risks raised by the audit.
- `approval_status`: Approval result; expected values are `not-requested`, `pending`, `approved`, `conditional`, or `rejected`.
- `evidence`: Reviewable evidence supporting the audit outcome.

### Identity And Uniqueness

- Identity is `audit_id`.
- Each required `perspective` must appear exactly once in the current M9 audit set.

### Relationships

- Feeds the Release Candidate Gate.
- May produce blocking risks that prevent Gate G9 acceptance.

### Validation Rules

- Required perspectives are code review, QA, release engineering, project management, onboarding audit, and process audit.
- `audit_outcome = approved` requires `approval_status = approved` and no unresolved blocking risks for that perspective.
- `approved-with-exceptions` requires documented exceptions and cannot satisfy a required G9 approval unless the release policy accepts that exception.
- Audit coverage must include the source-plan concern for the perspective and remain externally reviewable.

## Entity: Release Candidate Gate

Represents Gate G9 for v1.0 release-candidate acceptance.

### Fields

- `gate_id`: Stable gate identifier; expected value is `G9`.
- `fresh_scaffold_smoke_status`: Fresh scaffold smoke-test criterion; expected values are `not-evaluated`, `pass`, `fail`, or `exceptioned`.
- `retrofit_repair_evidence_status`: Retrofit repair evidence criterion; expected values are `not-evaluated`, `pass`, `fail`, or `exceptioned`.
- `agent_contract_lint_status`: Agent-contract lint criterion; expected values are `not-evaluated`, `pass`, or `fail`.
- `question_lint_status`: Template question-lint criterion; expected values are `not-evaluated`, `pass`, or `fail`.
- `generated_artifact_freshness_status`: Generated-artifact freshness criterion; expected values are `not-evaluated`, `current`, `stale`, or `exceptioned`.
- `authority_drift_status`: High-priority authority-drift criterion; expected values are `not-evaluated`, `none-open`, `open-nonblocking`, or `open-blocking`.
- `model_routing_guidance_status`: Model-routing guidance criterion; expected values are `not-evaluated`, `current-runtime-verifiable`, `stale`, or `exceptioned`.
- `release_note_classification_status`: Canonical/generated/ephemeral release-note classification criterion; expected values are `not-evaluated`, `complete`, `incomplete`, or `exceptioned`.
- `required_approvals`: Approval status for code review, QA, release engineering, and project-management release-risk review.
- `customer_approval_applicability`: Whether customer approval is required by the template release policy; expected values are `not-assessed`, `required`, or `not-required`.
- `customer_approval_status`: Customer approval result when applicable; expected values are `not-applicable`, `pending`, `approved`, or `rejected`.
- `unresolved_blocker_status`: Overall release-blocker result; expected values are `none`, `nonblocking-open`, or `blocking-open`.
- `gate_status`: Overall Gate G9 result; expected values are `not-evaluated`, `pass`, `fail`, or `deferred`.

### Identity And Uniqueness

- Identity is `gate_id`.
- Exactly one current Release Candidate Gate exists for the M9 release-candidate decision.

### Relationships

- Depends on all required Release Readiness Audits.
- Depends on M8 rollout evidence being complete or exceptioned.

### Validation Rules

- Gate G9 cannot pass until all required Release Readiness Audits have acceptable approval outcomes.
- Gate G9 cannot pass if any release criterion is failed, stale, incomplete, or open-blocking without an accepted exception where the source plan allows exceptions.
- Gate G9 cannot pass when `customer_approval_applicability = required` unless `customer_approval_status = approved`.
- Gate G9 cannot pass with `unresolved_blocker_status = blocking-open`.
- Customer approval must be conditional on the governing release policy, not assumed unconditionally.

## Entity: M10 Gap

Represents the documented absence of M10 from the authoritative source plan.

### Fields

- `gap_id`: Stable identifier for the gap; expected value is `M10-source-plan-gap`.
- `source_plan_evidence`: Evidence that the authoritative source plan defines M8 and M9 but no M10 milestone.
- `bounded_assumption`: Statement that M10 is a planning gap, not an implied milestone.
- `scope_constraint`: Constraint preventing invented M10 objectives, requirements, deliverables, or gates.
- `required_follow_up`: Required action before any M10 scope can be added; expected values are `source-plan-update-required` or `documented-follow-up-required`.
- `gap_status`: Current gap status; expected values are `open`, `resolved-by-source-update`, or `closed-no-scope`.

### Identity And Uniqueness

- Identity is `gap_id`.
- Exactly one M10 Gap record exists for this feature unless the authoritative source plan is updated.

### Relationships

- Constrains the overall M8-M10 planning scope.
- Does not relate to a Release Candidate Gate as an acceptance dependency, because no M10 gate exists in the source plan.

### Validation Rules

- No M10 objective, acceptance gate, deliverable, or milestone requirement may be modeled while `gap_status = open`.
- `gap_status = resolved-by-source-update` requires an updated authoritative source plan that defines M10 scope.
- `required_follow_up` must remain explicit until the source plan is updated or the requested M10 scope is closed as no-scope.

## State Transitions

### Reference Repository Repair Status

- `not-started` -> `in-progress` when repair planning or verification begins.
- `in-progress` -> `repaired` when the Repair Outcome is complete.
- `in-progress` -> `exceptioned` when an accepted exception covers incomplete repair work.
- `in-progress` -> `not-started` is invalid unless the record is superseded by corrected evidence.

### Repair Outcome Status

- `not-started` -> `in-progress` when any repair dimension is evaluated.
- `in-progress` -> `complete` when all required repair dimensions meet validation rules.
- `in-progress` -> `blocked` when a required repair dimension cannot be satisfied and no exception is accepted.
- `blocked` -> `complete` when the blocker is resolved.
- `blocked` -> `exceptioned` when an accepted exception covers the blocker.

### Rollout Gate Status

- `not-evaluated` -> `pass` when all pass criteria are satisfied.
- `not-evaluated` -> `fail` when any pass criterion fails without accepted exception.
- `not-evaluated` -> `exceptioned` when accepted exceptions cover unmet criteria.
- `fail` -> `pass` when failures are repaired and criteria are re-evaluated.
- `fail` -> `exceptioned` when accepted exceptions cover unresolved failures.

### Release Readiness Audit Outcome

- `not-started` -> `in-progress` when review begins.
- `in-progress` -> `approved` when the perspective approves with no blocking risk.
- `in-progress` -> `approved-with-exceptions` when exceptions are documented and accepted for that perspective.
- `in-progress` -> `rejected` when unresolved blockers remain.
- `rejected` -> `approved` or `approved-with-exceptions` only after re-review.

### Release Candidate Gate Status

- `not-evaluated` -> `pass` when all release criteria and required approvals are satisfied.
- `not-evaluated` -> `fail` when any required criterion, approval, or blocker rule fails.
- `not-evaluated` -> `deferred` when prerequisite rollout evidence or policy applicability remains unresolved.
- `fail` -> `pass` only after failed criteria are resolved and the gate is re-evaluated.
- `deferred` -> `pass` or `fail` after prerequisites are resolved.

### M10 Gap Status

- `open` -> `resolved-by-source-update` when the authoritative source plan defines M10 scope.
- `open` -> `closed-no-scope` when the planning request explicitly accepts that no M10 work is in scope.
- `resolved-by-source-update` -> `open` is invalid unless the source-plan update is withdrawn or superseded.
