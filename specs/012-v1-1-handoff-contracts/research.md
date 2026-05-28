# Research: v1.1 Handoff Contracts

## Durable Handoff Storage

**Decision**: Store durable handoffs as JSON files under `sw-dev-team-template/docs/handoffs/*.json` and store the single active pointer at `sw-dev-team-template/.devteam/active-handoff.json`.

**Rationale**: JSON supports deterministic schema validation and hook consumption, while a pointer prevents duplicate sources of truth.

**Alternatives considered**: Markdown handoffs were rejected because hooks would need brittle parsing. Embedding active state in each handoff was rejected because multiple active records could conflict.

## Handoff Schema and Validation

**Decision**: Use `sw-dev-team-template/schemas/handoff.schema.json` plus `sw-dev-team-template/scripts/validate-handoff.py` for schema and repository consistency checks.

**Rationale**: The schema gives a stable contract for task generation and hook gates; the validator can enforce repo-specific rules such as active-pointer resolution and forbidden-over-allowed path precedence.

**Alternatives considered**: Hook-local validation was rejected because it would duplicate rules across gates. Free-form contracts were rejected because they cannot support enforce mode.

## Hook Gate Rollout

**Decision**: Wire handoff gates in warning mode first and promote to enforce mode only after the clarified smoke baseline has zero unresolved false positives.

**Rationale**: Warning mode protects ordinary workflows while collecting readiness evidence before blocking behavior becomes default.

**Alternatives considered**: Immediate enforcement was rejected due to false-positive risk. Documentation-only rollout was rejected because v1.1 requires deterministic enforcement readiness.

## Evidence Model

**Decision**: Treat worker reports as non-final evidence and require accepted evidence from rerun/hook-captured tests, code-reviewer artifacts, security-engineer artifacts, and researcher-stewarded customer-truth records as applicable.

**Rationale**: This preserves independent verification and prevents completion claims from satisfying their own gates.

**Alternatives considered**: Allowing self-attestation was rejected because it contradicts the role and quality-gate model.

## Bounded Codex and Model Fallback

**Decision**: Permit bounded Codex only through explicit handoff scope, and permit model fallback only to the same-or-higher capability tier with requested/actual model class, capability-tier comparison, and fallback reason recorded.

**Rationale**: Provider availability should not block safe work, but fallback must not downgrade authority, output obligations, or evidence quality.

**Alternatives considered**: Any-model fallback was rejected as too weak. No fallback was rejected as unnecessarily brittle. Production-authoring fallback without handoff permission was rejected as a role violation.

## Speckit and llmdc Integration

**Decision**: Treat Speckit and llmdc as planning, documentation, evidence-input, or coordination helpers that feed canonical roles and handoffs but cannot approve gates, mark work complete, or record customer truth on their own.

**Rationale**: The template supports multiple tools only when they adapt to the same role contract.

**Alternatives considered**: Treating tool outputs as final evidence was rejected because it bypasses role-owned review and customer-truth stewardship.
