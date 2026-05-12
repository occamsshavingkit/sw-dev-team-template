# Data Model: M2 Token Operating Model

## Token Budget Band

Represents the expected context-cost category assigned to a planned task.

**Fields**: `band`, `intended_use`, `review_expectation`, `split_required`, `accepted_oversize_rationale`.

**Allowed values**: `tiny`, `small`, `medium`, `large`, `XL`.

**Validation rules**: Every planned task must choose exactly one band. `XL` tasks must be split or explicitly accepted as oversized before work proceeds. If the band is unclear, the task chooses the smallest defensible band and notes the uncertainty for review.

**Relationships**: Attached to a Task Planning Entry and calibrated by Token Actual records.

## Just-in-Time File List

Represents the focused set of files an assignee should read first before expanding context.

**Fields**: `task_id`, `file_paths`, `purpose`, `expansion_conditions`, `owner_role`.

**Validation rules**: Must name concrete first-read files or state why no first-read file exists. Must not become an exhaustive speculative file inventory. Expansion beyond the list should be driven by discovered need.

**Relationships**: Belongs to a Task Planning Entry and supports Token Budget Band review.

## Token Actual

Represents closure-time context-cost evidence for material work.

**Fields**: `task_id`, `measured_token_count`, `actual_budget_band`, `captured_at_closure`, `not_captured_reason`, `calibration_notes`.

**Validation rules**: Material task closure must include one accepted token actual format: measured token count, actual budget band, or an explicit reason the actual was not captured. The field must not be left ambiguous.

**State transitions**: `pending` -> `captured-measured-count`, `captured-actual-band`, or `not-captured-with-reason`; captured values may inform future band calibration.

**Relationships**: Completes the Task Planning Entry and calibrates future Token Budget Band decisions.

## Task Planning Entry

Represents a planned implementation or documentation task under the M2 operating model.

**Fields**: `task_id`, `description`, `owner_role`, `token_budget_band`, `jit_file_list`, `token_actual`, `review_status`, `oversize_decision`.

**Validation rules**: Must include a token budget band, just-in-time file list, and closure field for token actuals. Role ownership must follow canonical routing. Token information must be visible before work starts and at closure.

**Relationships**: Contains one Token Budget Band, one Just-in-Time File List, and one Token Actual closure field.

## PM Delta Pass

Represents a lightweight project-manager refresh based on current deltas instead of default full PM artifact rereads.

**Fields**: `pass_id`, `since_reference`, `changed_files`, `merged_pr_titles`, `current_milestone_rows`, `changed_open_question_rows`, `risk_change_deltas`, `fallback_reads`, `output_type`, `affected_registers`, `no_op_confirmation`.

**Validation rules**: Must prefer delta inputs when sufficient. Must produce either a no-op confirmation or minimal edits to affected PM registers. Targeted fallback reads are allowed only when delta inputs are insufficient, stale, or conflicting.

**State transitions**: `planned` -> `delta-collected` -> `no-op-recorded` or `registers-updated`; `delta-collected` -> `targeted-fallback` when inputs are insufficient.

**Relationships**: Reads PM Delta Inputs and may update PM Registers.

## PM Register

Represents a project-management artifact affected by a PM Delta Pass.

**Fields**: `path`, `register_type`, `authority_class`, `affected_section`, `update_reason`, `last_delta_reference`.

**Validation rules**: Only affected register content should change. If no register needs an update, the PM pass records a no-op instead of editing unrelated files.

**Relationships**: May be updated by a PM Delta Pass. Includes schedule, risk, change, lessons, and open-question surfaces where applicable.

## Memory Query Pattern

Represents a prescribed lookup used before broad old-context reads or customer escalation.

**Fields**: `trigger_situation`, `query_text`, `paired_repository_check`, `owner_role`, `conflict_handling`.

**Validation rules**: Must cover old customer notes, old schedules, customer escalation or prior-answer checks, and reopened ADR topics. Must state that memory is pointer-only and repository artifacts remain authoritative.

**Relationships**: Produces Memory Result Pointers that must be verified against Repository Sources of Truth.

## Memory Result Pointer

Represents a memory hit that points toward evidence but does not itself govern behavior.

**Fields**: `query_pattern`, `memory_result`, `candidate_path_or_issue`, `verification_status`, `stale_memory_flag`.

**Validation rules**: Must be verified against repository evidence before use. If memory conflicts with repository evidence, repository evidence wins and the conflict is recorded or escalated through the existing role model.

**State transitions**: `candidate` -> `verified` or `stale/rejected`.

**Relationships**: Derived from a Memory Query Pattern and checked against a Repository Source of Truth.

## Repository Source of Truth

Represents the canonical project artifact that confirms or overrides memory results.

**Fields**: `path`, `authority_class`, `owned_by_role`, `decision_or_evidence_type`, `verification_notes`.

**Validation rules**: Canonical repository artifacts override memory. Customer-truth records remain routed through `researcher`; customer interface remains routed through `tech-lead`.

**Relationships**: Verifies Memory Result Pointers and anchors task, PM, and customer-truth decisions.

## M2 Guidance Surface

Represents one canonical file in the allowed M2 implementation scope.

**Fields**: `path`, `guidance_type`, `authority_class`, `required_m2_content`, `excluded_content`, `review_roles`.

**Validation rules**: Paths are limited to `docs/templates/task-template.md`, project-manager guidance, `docs/MEMORY_POLICY.md`, `.claude/agents/tech-lead.md`, `.claude/agents/researcher.md`, and the AGENTS.md Spec Kit plan-pointer block. Generated runtime candidates, product files, M3-M9 implementation, external services, and new dependencies are excluded.

**Relationships**: Implements requirements from the M2 spec and must preserve the canonical role model.
