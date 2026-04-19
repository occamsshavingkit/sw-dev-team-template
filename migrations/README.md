# Migrations

Per-version migration scripts for `scripts/upgrade.sh`.

When a template release changes the **shape** of downstream projects
(moves a file, splits a document, renames a directory, changes the
format of an artifact), a migration script lives here so downstream
projects can be upgraded cleanly instead of being left with stale
content.

Most releases do **not** need a migration. The convention is: if a
release is purely additive (new files, new optional sections, new
scripts) and leaves existing downstream files untouched, no migration
is needed and no file is added here. If a release moves, renames,
reshapes, or reformats existing downstream content, add a migration.

## Naming

`migrations/<TARGET_VERSION>.sh`

`TARGET_VERSION` is the SemVer tag of the release in which the shape
change was introduced (e.g., `v0.5.0.sh` for a change first shipped
in v0.5.0). `upgrade.sh` runs migrations for every tag strictly
greater than the project's current `TEMPLATE_VERSION` and less-than-
or-equal-to the target version, in ascending order.

## Contract

Each migration script is a plain bash script. It receives these env
vars from `scripts/upgrade.sh`:

| Var             | Meaning                                                            |
|---|---|
| `PROJECT_ROOT`   | absolute path to the downstream project root                      |
| `OLD_VERSION`    | version the project is upgrading from                             |
| `NEW_VERSION`    | version the project is upgrading to                               |
| `TARGET_VERSION` | the version this migration is attached to (filename minus `.sh`)  |
| `WORKDIR_NEW`    | absolute path to a clone of the upstream at `NEW_VERSION`         |
| `WORKDIR_OLD`    | absolute path to a clone of the upstream at `OLD_VERSION` (may be unset if the SHA isn't reachable) |

## Required properties

1. **Idempotent.** Running a migration twice must be safe. Guard each
   transformation with a file-state check (e.g.,
   `if [[ -f old-path && ! -f new-path ]]; then …`).
2. **Fail loud.** Use `set -euo pipefail`. A failure aborts the
   upgrade so the user can investigate.
3. **No network.** Migrations work on the local file tree only. If
   upstream content is needed, read from `$WORKDIR_NEW`.
4. **Never touch user-added agents or SMEs.** `.claude/agents/sme-*.md`
   (except `sme-template.md`) and anything under `docs/pm/*.md` are
   out of scope.
5. **Print what you did.** Each action emits a one-liner to stdout so
   the upgrade log shows why the tree changed.

## Writing a new migration

Copy `TEMPLATE.sh` to `<version>.sh` and fill in the transformations.
Test it by running it against a scratch project scaffolded from the
prior release.
