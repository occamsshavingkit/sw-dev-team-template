# Data Model: v1.1 Handoff Contracts

## Durable Handoff Contract

- **Fields**: schema identifier, task ID, status, objective, owner role, review roles, security roles, mode, allowed paths, forbidden paths, framework scope, requirements, acceptance criteria, hard-rule traces, verification state, completion state.
- **Relationships**: Referenced by exactly one active handoff pointer when active; may cite evidence artifacts and model fallback records.
- **Validation rules**: Task ID is unique within `docs/handoffs/`; forbidden paths override allowed paths; framework-managed paths require framework-maintenance scope; required evidence gates must be represented before completion can be accepted.
- **State transitions**: draft -> active -> completed or cancelled; active records cannot complete while required gates are unsatisfied.

## Active Handoff Pointer

- **Fields**: handoff path or task ID, pointer metadata, optional gate mode override if supported by implementation.
- **Relationships**: References one durable handoff contract and does not duplicate contract content.
- **Validation rules**: Pointer target must exist, validate against schema, and not contradict the durable handoff status.
- **State transitions**: absent -> points to active handoff -> cleared or updated after completion/cancellation.

## Path Scope

- **Fields**: allowed paths, forbidden paths, framework scope.
- **Relationships**: Embedded in each durable handoff and consumed by pre-tool gates and bounded-Codex checks.
- **Validation rules**: Forbidden path matches always block, even if a broader allowed path matches; framework-managed paths require framework-maintenance scope.

## Evidence Gate

- **Fields**: gate type, required flag, accepted evidence references, source role, verification result, timestamp if available.
- **Relationships**: Belongs to a durable handoff; may cite hook activity, rerun evidence, reviewer artifacts, security artifacts, or researcher-stewarded customer records.
- **Validation rules**: Worker self-attestation cannot satisfy final test, review, security, or customer-truth gates.

## Bounded Codex Exception

- **Fields**: execution mode, permitted role-owned action, Codex permission flag, allowed paths, forbidden paths, required evidence, expiry or completion condition.
- **Relationships**: Embedded in or referenced by a durable handoff.
- **Validation rules**: Valid only when explicitly permitted by the active handoff; cannot waive role ownership, path scope, evidence gates, or customer-truth stewardship.

## Model Fallback Record

- **Fields**: requested role, requested model class, actual model class, capability-tier comparison, fallback reason.
- **Relationships**: Cited by the durable handoff or related evidence record when provider/model assignment fallback is used.
- **Validation rules**: Actual model class must be same-or-higher capability tier than requested; otherwise work pauses or escalates.

## llmdc Activity

- **Fields**: activity type, affected handoff or artifact, role owner, cited active handoff, limitations.
- **Relationships**: May feed planning, documentation, evidence-input, or coordination surfaces.
- **Validation rules**: Cannot mark role-owned work complete, approve evidence gates, or record customer truth independently.

## Speckit Artifact

- **Fields**: artifact type, feature path, role-owner mapping, candidate acceptance criteria, source authority classification.
- **Relationships**: Feeds role-owned work and durable handoff creation.
- **Validation rules**: Analysis/checklist/task output is input only until accepted through the owning role and handoff evidence gates.

## Release Artifact List

- **Fields**: release notes, checklist, review, security, test, migration, and customer-approval artifact references.
- **Relationships**: Required by release handoffs and release-readiness review.
- **Validation rules**: Must be project-specific; no root changelog assumption is allowed.
