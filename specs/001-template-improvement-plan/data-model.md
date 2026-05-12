# Data Model: Template Improvement Program M0/M1

## Improvement Program

Represents the ordered framework-maintenance effort to reduce context cost before later authority, routing, compiler, automation, and rollout work.

**Fields**: `name`, `branch`, `source_plan`, `scope_milestones`, `future_context_milestones`, `success_metrics`, `owners`, `status`.

**Validation rules**: `scope_milestones` must be exactly `M0` and `M1` for this plan. M2-M9 may be referenced only as future context. Framework maintenance must remain separate from product work.

**Relationships**: Owns many Milestone Gates, Context Surfaces, and Generated Runtime Artifacts.

## Milestone Gate

Represents a pass/fail decision that controls when later work may start.

**Fields**: `id`, `milestone`, `objective`, `pass_criteria`, `evidence_paths`, `decision`, `accepted_exceptions`, `review_roles`.

**Validation rules**: G0 must pass before M1 implementation is accepted. G1 must pass before cross-AI routing, Markdown compiler, self-improvement automation, or downstream rollout begins.

**State transitions**: `planned` -> `evidence-collected` -> `passed` or `failed`; `failed` -> `evidence-collected` after remediation.

**Relationships**: Gates Improvement Program progression and references Context Surface measurements and review evidence.

## Context Surface

Represents a live file or artifact that recurring sessions may read and that therefore carries token cost.

**Fields**: `path`, `surface_type`, `authority_class`, `baseline_line_count`, `baseline_token_proxy`, `post_change_line_count`, `post_change_token_proxy`, `reduction_target`, `archive_path`, `evidence_path`, `owner_role`.

**Validation rules**: Live surfaces must remain short and current. Terminal history must move to archives or evidence while preserving traceability. Reduction cannot remove hard rules, escalation formats, customer-interface rules, or source-authority boundaries.

**Relationships**: Has one Artifact Authority Class and may produce one or more Generated Runtime Artifacts.

## Artifact Authority Class

Represents whether an artifact is a source of truth, derived output, or temporary work product.

**Fields**: `class`, `definition`, `canonical_inputs`, `manual_edit_policy`, `review_gate`.

**Allowed values**: `canonical`, `generated`, `ephemeral`.

**Validation rules**: Manual mirrors are prohibited. Generated artifacts must identify canonical inputs and must not be manually edited as authority. Ephemeral artifacts must not govern runtime behavior unless promoted through review.

**Relationships**: Classifies Context Surfaces, Generated Runtime Artifacts, baseline reports, archives, and evidence files.

## Customer Question

Represents a customer-owned decision request under the template question-flow rules.

**Fields**: `id`, `question_text`, `decision_axis`, `status`, `owner`, `asked_at`, `answered_at`, `source_artifact`, `researcher_capture_path`.

**Validation rules**: A customer-facing question must be atomic, customer-owned, asked only when internal work is idle, and placed as the final line of the response. Internal queues may hold many questions, but external asks may not batch independent decision axes.

**Relationships**: May resolve planning ambiguity. For this M0/M1 plan, no new Customer Question is open.

## Generated Runtime Artifact

Represents a compact role/runtime candidate generated from canonical sources to reduce recurring context cost.

**Fields**: `path`, `source_paths`, `generation_method`, `baseline_size`, `generated_size`, `reduction_percent`, `preserved_rules`, `review_status`, `accepted_exceptions`.

**Validation rules**: Must preserve hard rules, role authority, escalation formats, output formats, local supplement checks, and customer-interface rules. Must remain subordinate to canonical role files until a later approved process changes authority.

**Relationships**: Derived from Context Surfaces with canonical Artifact Authority Class; reviewed by `code-reviewer` and validated by `qa-engineer` prompt-regression tests.

## Downstream Reference Repository

Represents QuackDCS, QuackPLC, QuackS7, or QuackSim as reference scope for baseline and future rollout.

**Fields**: `name`, `scaffold_mode`, `baseline_checked`, `intake_log_present`, `live_register_observations`, `template_version`, `exceptions`, `rollout_status`.

**Validation rules**: M0/M1 may record baseline/reference observations only. Product or retrofit edits are out of scope until downstream rollout gates are approved.

**Relationships**: Supplies baseline evidence to the Improvement Program and future M8 rollout planning.

## M0/M1 Artifact Set

Represents the required MVP deliverables for this plan.

**Fields**: `baseline_report`, `schedule_entries`, `risk_entries`, `runtime_contract_candidates`, `register_archive_script`, `token_ledger_schema`, `schedule_split_artifacts`, `pr_split`, `review_evidence`.

**Validation rules**: All M1 token quick-win artifacts must be implemented, not only baseline, schedule, risk, or PR-split planning outputs. Each artifact must state whether it is canonical, generated, or support/evidence.

**Relationships**: Provides evidence for G0 and G1 Milestone Gates.
