# Data Model: Issues-Based Multi-Machine Coordination Interface

The "data" is mostly GitHub-native coordination state plus one optional schema field. Nothing here replaces the binding in-repo registers.

## Coordination Issue

- **Fields**: GitHub issue number/URL; title (task summary); body (from the agent-task template); labels (status/role/priority/meta); milestone (release); assignee(s); linked durable-handoff `task_id`.
- **Relationships**: 1 issue ↔ 1 coherent task ↔ 1 durable handoff (`docs/handoffs/<task_id>.json`).
- **Authority**: issue is authoritative for human-readable description, label-visible status, milestone grouping, and the claim/comment audit trail; the durable handoff is authoritative for scope, paths, role ownership, evidence gates, and completion state.
- **State**: reflected by the `status:*` label — queued → claimed → in-progress → in-review → (blocked) → done.

## Claim Record

- **Fields**: operator id, machine, session id, UTC timestamp, issue ref. Posted as a structured CLAIM comment; mirrored by self-assignment + `status:claimed`.
- **Relationships**: belongs to one issue; ties to the local `.devteam/active-handoff.json` pointer for the winning operator.
- **Validation/tie-break**: earliest UTC timestamp wins; equal timestamps → lexical `operator` id. Advisory only (no hard lock).
- **State transitions**: (none) → claimed → released/yielded → reclaimable. Stale (no activity past the documented window) → reclaimable.

## Label Taxonomy

- **status**: `status:queued`, `status:claimed`, `status:in-progress`, `status:in-review`, `status:blocked`, `status:done`.
- **role** (routing): one `role:<canonical-role>` per roster entry (tech-lead, project-manager, architect, software-engineer, researcher, qa-engineer, sre, tech-writer, code-reviewer, release-engineer, security-engineer, + the auditors/SME pattern as applicable).
- **priority**: `priority:p0`..`priority:p3`.
- **meta**: e.g. `meta:framework-maintenance`, `meta:customer-approval-required`, `meta:security-review-required`, `meta:blocked-external`.
- **milestone**: one per release semver tag (release grouping).
- **Validation**: status is single-valued (one `status:*` at a time); missing/conflicting `role:*` → needs-triage handling.

## Structured Comment

- **Types**: CLAIM, YIELD, PROGRESS, HANDBACK, GATE-PASSED, BLOCKED — each with defined fields (actor/role, timestamp, and type-specific payload).
- **Relationships**: ordered comment stream on an issue; reconstructs the coordination history.
- **Rule**: NO comment type (incl. GATE-PASSED) satisfies an evidence gate; the binding evidence stays the hook-captured `verification.*` / role-owned artifacts.

## Register-Authority Mapping

- **Fields**: state-kind → authoritative record → GitHub-issue role.
- **Examples**: customer truth → `CUSTOMER_NOTES.md` (issues never authoritative); open questions → `docs/OPEN_QUESTIONS.md`; decisions → `docs/DECISIONS.md`; schedule/risk/lessons → `docs/pm/*`; task claim/status/work-queue → GitHub issue+labels (authoritative for coordination state only).
- **Rule**: in-repo registers are NOT replaced as binding records; GitHub holds coordination state only.

## Durable Handoff — `github_issue` field (NEW, optional)

- **Field**: `github_issue` (optional) on the durable handoff record + `schemas/handoff.schema.json` — a reference (issue number or URL) to the coordination issue.
- **Validation**: optional; absence keeps the handoff valid (single-operator/offline). When present, it links the handoff to its issue (bidirectional with the issue's `task_id` reference).
- **Relationships**: completes the issue↔handoff mapping (FR-006/FR-017).

## Active-Handoff Pointer (scaffold change)

- **Field**: `.devteam/active-handoff.json` — per-machine/per-session local pointer to the operator's currently-claimed handoff/issue.
- **Rule (FR-018)**: scaffolded downstream projects gitignore this file (local state, not shared truth). Template repo's own example handoff is unaffected.
