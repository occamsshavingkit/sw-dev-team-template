# Data Model: Migration Runner Hardening

This feature is shell tooling; the "data model" is the small set of runtime
concepts the runner manipulates and the shape of the failure artifact.

## Migration Chain

- **Fields**: ordered list of selected migration entries, each with `filename` and 1-based `position`; `total` count.
- **Relationships**: produced by the existing migration-discovery/selection logic (FW-ADR-0017 file-keyed discovery); consumed by the runner.
- **Validation rules**: order is deterministic and stable for a given upgrade hop; positions are contiguous `1..total`.
- **State**: each entry is `pending → applied` (on zero exit) or `pending → failed` (on non-zero exit); on a failure all later entries remain `pending` (not run).

## Migration Outcome

- **Fields**: `filename`, `exit_status`, classification (`applied` | `failed`).
- **Relationships**: one per executed migration.
- **Validation rules**: classification derives solely from the migration's true exit status (FR-001) — zero = applied, non-zero = failed. A trailing pipeline stage's status MUST NOT determine this.
- **State transitions**: terminal once recorded; the chain stops at the first `failed`.

## Failure Report

Emitted only on the first failing migration, in two parallel forms carrying the same facts.

- **Human-readable (stderr summary)** — names the failing migration filename, its position as "N of M", the already-applied migrations, and the not-run migrations; distinguishable from the migration's own output.
- **Structured artifact** — `.template-migration-failed.json` at project root. Fields:
  - schema/version marker (parallel to existing `.template-*-blocked.json`)
  - `failing_migration`: filename
  - `position`: `{ "index": N, "total": M }`
  - `applied`: ordered list of migration filenames that ran successfully before the failure
  - `not_run`: ordered list of migration filenames not executed because of the failure
  - `exit_status`: the failing migration's captured exit status
  - `timestamp`: when the failure was recorded
  - (optional) a bounded tail of the failing migration's captured stderr for quick triage
- **Validation rules**: `applied` + `[failing_migration]` + `not_run` reconstruct the full ordered chain; `index`/`total` are consistent with those lists. Written atomically; no stale `.tmp.*` left.
- **Relationships**: machine-readable artifact mirrors the stderr summary; consumed by operators and CI/automation.

## Recovery Semantics (forward-only)

- Applied migrations are not reverted. The project is left at the observable stopping point (the failing migration not applied; later migrations not run).
- The operator's path: fix the failing migration, re-run the upgrade; the chain resumes forward from the stopping point. No down-migrations, no snapshot/restore.
