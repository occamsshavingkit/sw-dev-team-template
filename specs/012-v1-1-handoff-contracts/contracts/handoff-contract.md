# Contract: Durable Handoff and Active Pointer

## Durable Handoff Contract

Durable handoffs are JSON records under `sw-dev-team-template/docs/handoffs/*.json` and validate against `sw-dev-team-template/schemas/handoff.schema.json`.

Required contract capabilities:

- Identify one objective and one canonical owner role.
- Declare review and security roles when required.
- Declare allowed paths, forbidden paths, and framework scope.
- Declare acceptance criteria and required evidence gates.
- Declare gate mode as warning or enforce.
- Record verification and completion state without treating worker self-attestation as accepted evidence.
- Cite hard-rule or v1.1 requirement sources for enforceable gates.
- Record bounded-Codex permission only when explicitly granted.
- Record model fallback fields when fallback is used: requested role, requested model class, actual model class, capability-tier comparison, fallback reason.

## Active Handoff Pointer

The active pointer is a JSON record at `sw-dev-team-template/.devteam/active-handoff.json`.

Required pointer behavior:

- Reference exactly one durable handoff.
- Never redefine durable handoff fields.
- Fail validation if the target is missing, malformed, inactive when active work is claimed, or contradictory.
- Clear or move only through a reviewed handoff lifecycle transition.

## Path Scope Semantics

- A proposed write is in scope only when it matches an allowed path and does not match a forbidden path.
- Forbidden paths override broader allowed paths.
- Framework-managed paths require `framework_scope: framework-maintenance`.
- Bounded Codex receives no broader path authority than the active handoff declares.

## Completion Semantics

- Completion requires all required evidence gates to be satisfied.
- Test evidence requires rerun evidence or hook-captured activity.
- Review evidence requires code-reviewer-owned artifacts when review is required.
- Security evidence requires security-engineer-owned artifacts when security review is required.
- Customer approval requires researcher-stewarded customer-truth records.
