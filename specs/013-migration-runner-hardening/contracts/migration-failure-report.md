# Contract: Migration Failure Report

Two parallel surfaces emitted by the runner on the first failing migration.
Both carry the same facts; the artifact is the machine-readable form.

## A. stderr summary (human-readable)

On a migration failure the runner writes to standard error a summary that includes,
at minimum and unambiguously distinguishable from the migration's own output:

- the failing migration's filename;
- its position in the ordered chain, expressed as "N of M";
- the migrations already applied (in order) before the failure;
- the migrations not run (in order) because of the failure.

Example (illustrative shape, not fixed wording):

```
ERROR: migration failed — fix and re-run to resume.
  failing : migrations/v0.1.0.sh  (3 of 7)
  applied : migrations/v0.0.1.sh, migrations/v0.0.2.sh
  not run : migrations/v0.2.0.sh, migrations/v0.3.0.sh, migrations/v0.14.0.sh, migrations/v0.14.4.sh
  artifact: .template-migration-failed.json
```

## B. structured artifact `.template-migration-failed.json`

Written at the project root, schema-parallel to `.template-prebootstrap-blocked.json`.

```json
{
  "schema": "template-migration-failed/1",
  "failing_migration": "migrations/v0.1.0.sh",
  "position": { "index": 3, "total": 7 },
  "exit_status": 1,
  "applied": [
    "migrations/v0.0.1.sh",
    "migrations/v0.0.2.sh"
  ],
  "not_run": [
    "migrations/v0.2.0.sh",
    "migrations/v0.3.0.sh",
    "migrations/v0.14.0.sh",
    "migrations/v0.14.4.sh"
  ],
  "timestamp": "2026-05-27T00:00:00Z",
  "stderr_tail": "…optional bounded tail of the failing migration's stderr…"
}
```

### Invariants

- `len(applied) == index - 1`; `len(not_run) == total - index`.
- `applied + [failing_migration] + not_run` equals the full ordered chain.
- `exit_status` is the failing migration's true exit status (non-zero).
- The artifact is written atomically (no stale `.tmp.*` on success or failure).
- Field names/shape stay consistent with the existing `.template-*-blocked.json` block-artifact family.

## C. process contract

- Runner stops at the first failing migration (does not continue the chain).
- Runner exits non-zero (controlled, reported — not a silent `set -e` abort).
- A successful migration produces no failure report and no artifact; an all-success run leaves no `.template-migration-failed.json`.
- Recovery is forward-only: applied migrations are not reverted; re-running after a fix resumes forward.
