# Phase 1 Data Model: Pre-release upgrade-regression gate

**Feature**: `007-pre-release-upgrade`
**Plan**: [plan.md](plan.md)
**Date**: 2026-05-14

The gate is a stateless shell orchestrator; data flows are mostly transient (tempfile fixtures, per-run stderr/stdout). The only persistent entity is the override-audit log. Below: every entity the gate produces, consumes, or persists.

---

## E-1: Pre-release gate (orchestrator)

**Role**: single entrypoint. Owns sub-gate registration order, fail-all dispatch, per-sub-gate diagnostic capture, and overall PASS/FAIL summary emission.

**Fields**:

| Field | Type | Notes |
|---|---|---|
| `version` | semver string | matches the template `VERSION` at the gate's commit; printed in the summary line so the gate's own provenance is visible in logs. |
| `subgates[]` | ordered array of Sub-gate references | registered at startup; order is deterministic. |
| `flag_only` | optional string | name of single sub-gate to run; from `--only`. |
| `flag_skip[]` | optional array of strings | names of sub-gates to skip; from `--skip`. |
| `worktree_clean` | bool | precondition gate; if false, all other sub-gates still run but the worktree-clean sub-gate fails. |
| `start_time` / `end_time` | timestamps | wall-clock measurement for SC-002 enforcement. |
| `exit_code` | int | 0 if every executed sub-gate exited 0; non-zero otherwise (typically 1). |

**Lifecycle**: per-invocation, no persistence across runs.

**Invariants**:
- `flag_only` and `flag_skip` MUST NOT both be set (mutual exclusion at flag parse).
- `flag_only` and `flag_skip` are ignored entirely when the orchestrator is invoked from the pre-push hook in strict mode (R-2 / FR-011).
- `exit_code` is the maximum (logically OR-ed; any non-zero wins) of every executed sub-gate's exit code, never reduced by aggregation logic (FR-002).

---

## E-2: Sub-gate

**Role**: one release-blocking check. Each sub-gate is independently runnable, has its own exit-code contract, and produces a diagnostic block on failure.

**Fields**:

| Field | Type | Notes |
|---|---|---|
| `name` | string slug | e.g. `worktree-clean`, `upgrade-paths`, `lint-contracts`, `check-spdx`, `advisory-pointers`, `migrations-standalone`. |
| `description` | one-line string | shown in `--help` output. |
| `entrypoint` | shell function name | invoked by the orchestrator's dispatcher. |
| `category` | enum: `precondition` / `regression` | precondition gates (worktree-clean) gate-keep but don't short-circuit later regression gates per FR-001 fail-all semantics. |
| `exit_code` | int (post-run) | 0 = PASS; non-zero = FAIL. |
| `diagnostic` | string | per-sub-gate FAIL block content; empty on PASS. |
| `duration_ms` | int | per-sub-gate timing for the summary block. |

**Lifecycle**: per-invocation. Each registered sub-gate runs exactly once per orchestrator run (modulo `--only` / `--skip`).

**Invariants**:
- Sub-gate names MUST be unique within the registry.
- No sub-gate may modify the worktree (read-only against the candidate tree); fixtures live in tempdirs.
- A sub-gate's `exit_code` MUST faithfully reflect its sub-process's exit; no remapping.

**Concrete instances** (v1 ship):
1. `worktree-clean` — precondition. Fails if `git status --porcelain` is non-empty.
2. `upgrade-paths` — regression. One round-trip per source tag (E-3).
3. `lint-contracts` — regression. Runs `scripts/lint-agent-contracts.sh --canonical-only`.
4. `check-spdx` — regression. Runs `scripts/check-spdx.sh --summary`.
5. `advisory-pointers` — regression. Path-reference scanner per R-8 / FR-006.
6. `migrations-standalone` — regression. One run per migration per R-7 / FR-007.

---

## E-3: Source tag (formerly "on-track tag")

**Role**: a published release tag the `upgrade-paths` sub-gate uses as an upgrade source. Per Q2 / FR-003: every published tag reachable in the local clone.

**Fields**:

| Field | Type | Notes |
|---|---|---|
| `tag_name` | string | e.g. `v1.0.0-rc3`, `v0.10.0`. |
| `commit_sha` | hex string | resolved via `git rev-parse <tag>^{commit}` at run start (R-9). |
| `track` | enum: `v0` / `v1-rc` / `v1-stable` / `cross-major` / `other` | informational; gate does not branch on this, but reports it in the per-round-trip diagnostic so a cross-MAJOR failure is visible. |
| `is_annotated` | bool | true if `git cat-file -t <tag>` returns `tag` (not `commit`); reported in the diagnostic but does not gate. |
| `round_trip_status` | enum: `pass` / `fail` / `skipped` | per-tag outcome; `skipped` only if the tag is unreachable. |
| `round_trip_log` | tempfile path | captured stdout+stderr of the per-tag scaffold+upgrade+verify chain. |

**Lifecycle**: per-invocation; the source-tag set is enumerated at run start via `git tag` filtered by the FR-003 scope (every reachable published tag).

**Invariants**:
- The set MUST include every tag reachable from the candidate via `git rev-list --tags`.
- The gate MUST NOT silently skip a tag because the round-trip is unsupported (cross-MAJOR is a `fail`, not a `skipped`).
- `skipped` is reserved for unreachable tags only (e.g., a tag pointing at a commit not in the local clone after a shallow fetch).

---

## E-4: Round-trip

**Role**: one scaffold-from-source-tag → upgrade-to-candidate → verify-clean cycle for the `upgrade-paths` sub-gate.

**Fields**:

| Field | Type | Notes |
|---|---|---|
| `source_tag` | Source tag reference | one-to-one. |
| `candidate_sha` | hex string | the commit at gate-invocation HEAD. |
| `fixture_path` | tempdir | created at start of round-trip; destroyed at end. |
| `scaffold_exit` | int | exit code of `scripts/scaffold.sh` from the source tag. |
| `upgrade_exit` | int | exit code of `scripts/upgrade.sh --target <candidate>` from the source tag's tree. |
| `verify_exit` | int | exit code of `scripts/upgrade.sh --verify` post-upgrade. |
| `overall_status` | enum: `pass` / `fail` | `pass` iff all three exits are 0. |
| `diagnostic` | string | on fail, the captured log lines that reveal which of the three steps failed. |

**Lifecycle**: per-source-tag per-invocation. Fixtures cleaned up unconditionally on round-trip end (success or failure).

**Invariants**:
- The candidate tree used during round-trip is read-only.
- The fixture is created via `mktemp -d`; no two round-trips share a fixture.
- A round-trip's `overall_status` is `fail` if any one of its three exits is non-zero; the diagnostic identifies which.

---

## E-5: Advisory pointer

**Role**: a path reference found inside an operator-facing string in a script the gate scans (per R-8 / FR-006).

**Fields**:

| Field | Type | Notes |
|---|---|---|
| `source_file` | string | path to the file containing the reference (e.g., `scripts/upgrade.sh`). |
| `source_line` | int | line number in `source_file`. |
| `path_reference` | string | the extracted candidate path (e.g., `migrations/v1.0.0-rc10.sh`). |
| `exists_in_candidate` | bool | `[ -e "$candidate_tree/$path_reference" ]`; PASS iff true. |

**Lifecycle**: per-invocation. Discovered by the `advisory-pointers` sub-gate's regex scan; not persisted.

**Invariants**:
- Every match contributes one Advisory pointer row.
- Deduplication is on `(source_file, source_line, path_reference)` — duplicate exact lines collapse, but the same path referenced from two lines records two rows so both source lines surface in diagnostics.

---

## E-6: Migration standalone run

**Role**: one invocation of a `migrations/*.sh` script with `PROJECT_ROOT` and `WORKDIR_NEW` set, for the `migrations-standalone` sub-gate (per R-7 / FR-007).

**Fields**:

| Field | Type | Notes |
|---|---|---|
| `migration_path` | string | e.g., `migrations/v1.0.0-rc9.sh`. |
| `target_version` | string | the migration's attached target version, parsed from the filename. |
| `fixture_path` | tempdir | a freshly-scaffolded project tree from one rc-prior tag (the one immediately before `target_version`). |
| `workdir_new` | tempdir | extracted candidate tree (so `WORKDIR_NEW` is well-formed). |
| `exit_code` | int | the migration's exit. |
| `placeholder_files[]` | array of relative paths | files in the fixture that contain the literal placeholder marker post-run. |
| `decisions_log_placeholders` | int | count of `placeholder` source-attribution entries the migration wrote during this run. |
| `overall_status` | enum: `pass` / `fail` | `pass` iff `exit_code == 0` AND `placeholder_files` is empty AND `decisions_log_placeholders == 0`. |

**Lifecycle**: per-migration per-invocation. Both fixture and workdir_new tempdirs are destroyed at end of run.

**Invariants**:
- A migration with `target_version == candidate_version` is exercised against a fixture from `target_version - 1` (the rc immediately prior).
- The placeholder-detection scan runs over the fixture's `.claude/agents/` tree only (where the rc9 migration writes).
- The decisions-log scan reads `<fixture>/docs/DECISIONS.md` lines added during this run (delta via pre/post snapshot).

---

## E-7: Override audit row

**Role**: one persistent record of a bypass at an upgrade-contract gate — either a `SKIP_PRE_RELEASE_GATE=1` bypass at strict-hook invocation time (per R-11 / FR-011) or a `SWDT_PREBOOTSTRAP_FORCE=1` bypass at `scripts/upgrade.sh` self-bootstrap / `migrations/v0.14.0.sh` pre-bootstrap (per FW-ADR-0010).

Schema owner: FW-ADR-0010 §"Override mechanism: SWDT_PREBOOTSTRAP_FORCE=1". Producers: `.git-hooks/pre-push` (pre-release gate, R-11), `scripts/upgrade.sh` (FW-ADR-0010 pre-bootstrap), `migrations/v0.14.0.sh` (FW-ADR-0010 pre-bootstrap migration step).

**Storage**: append-only Markdown table at `docs/pm/pre-release-gate-overrides.md`.

**Fields** (normative shape in FW-ADR-0010; reproduced here for spec-007 traceability. Customer-ruled 2026-05-14; the `Gate` column was added at column 2 to distinguish bypass origin):

| Column | Type | Notes |
|---|---|---|
| `Date` | ISO 8601 date | from `date -u +%Y-%m-%d`. |
| `Gate` | enum: `pre-release` / `pre-bootstrap` | which gate produced the bypass row. `pre-release` rows come from the pre-push hook (`SKIP_PRE_RELEASE_GATE=1`); `pre-bootstrap` rows come from `scripts/upgrade.sh` / `migrations/v0.14.0.sh` (`SWDT_PREBOOTSTRAP_FORCE=1`). Empty in legacy rows that predate the column; back-compat treats empty as `pre-release`. |
| `Commit SHA` | hex string | the HEAD SHA at hook invocation. |
| `Tag pushed` | string | the annotated `v*` tag that triggered strict mode; left empty for `pre-bootstrap` rows. |
| `Operator` | string | `git config user.email` or `${USER}@$(hostname)` fallback. |
| `Reason` | string | content of `PRE_RELEASE_GATE_REASON` env var, or `unspecified`; for `pre-bootstrap` rows, the FW-ADR-0010 matrix-row that fired (`local-edit` / `baseline-unreachable`), optionally with a `SWDT_PREBOOTSTRAP_FORCE_REASON` note. |
| `Sub-gates that would have run` | string | comma-joined sub-gate names from the orchestrator's registry; left empty for `pre-bootstrap` rows. |

**Lifecycle**: persistent. Each row is written exactly once (idempotent guard: if a row for `(Commit SHA, Tag pushed)` already exists, the hook appends a `duplicate` row rather than skipping — so retries are visible).

**Invariants**:
- The file is append-only; rewriting an existing row triggers a `git log -p` audit signal (tamper-evidence via git).
- A row MUST be appended BEFORE the hook returns success in bypass mode (R-11).
- The hook MUST refuse to bypass if the file is unwritable.

---

## E-8: Gate-run timing record (optional / future)

**Role**: per-run wall-clock measurement for SC-002 audit. Not persistent in v1; emitted to stderr only.

**Fields**:

| Field | Type | Notes |
|---|---|---|
| `total_ms` | int | end_time - start_time of the orchestrator. |
| `subgate_ms[]` | map<name, int> | per-sub-gate duration. |
| `tag_count` | int | number of source tags exercised. |

**Lifecycle**: per-invocation; reported in stderr summary; NOT persisted to disk in v1. If SC-002 trends suggest parallelisation (R-4), this becomes a candidate for a persistent log.

---

## Relationships

```text
Pre-release gate (E-1)
├── 1..N Sub-gates (E-2)
│   ├── upgrade-paths → 0..N Round-trips (E-4) → 1 Source tag (E-3)
│   ├── advisory-pointers → 0..N Advisory pointers (E-5)
│   └── migrations-standalone → 0..N Migration standalone runs (E-6)
└── Gate-run timing record (E-8) — emitted only

Pre-push hook (separate adapter)
└── on bypass → 1 Override audit row (E-7) → docs/pm/pre-release-gate-overrides.md
```

---

## State transitions

Only the orchestrator (E-1) and the round-trip (E-4) have meaningful state transitions:

**Orchestrator**:
```
INIT → ENUMERATING-SUBGATES → DISPATCHING (running) → SUMMARISING → EXITING
                                  │
                                  └── per sub-gate: PENDING → RUNNING → PASS|FAIL → recorded
```

**Round-trip**:
```
ALLOC_FIXTURE → SCAFFOLD → UPGRADE → VERIFY → CLEANUP → record(pass|fail)
                  │           │         │
                  └── on any non-zero exit: capture diagnostic, continue to CLEANUP, mark fail
```

Fail-all semantics (FR-001): the orchestrator never short-circuits on sub-gate failure; every registered sub-gate runs to completion. The round-trip itself short-circuits within its own three-step chain (no point running verify if upgrade exited non-zero).

---

## Validation rules

- A round-trip whose source tag is the same SHA as the candidate is skipped (no-op upgrade); status `pass` with reason `same-sha`.
- A migration whose `target_version` matches the candidate is exercised against the rc-prior tag's fixture.
- The override-audit log MUST NOT be edited retroactively; the gate's contribution to the file is only append, never rewrite.
- The sub-gate registry order is deterministic (alphabetical by name within each category, preconditions first); changing order across versions is a breaking change to the diagnostic format and triggers a MAJOR bump of the gate's `version` field.
