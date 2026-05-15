---
name: fw-adr-0017-file-keyed-migration-discovery
description: Replaces the runner's tag-keyed migration enumeration (`git tag -l 'v*'`) with file-presence discovery in the runner's `migrations/` tree, semver-ordered against `TEMPLATE_STATE.json`. Dissolves the rc13 catch-22 where unpublished tags hid existing migration files. Required follow-up to FW-ADR-0015 and FW-ADR-0016.
status: accepted
date: 2026-05-15
---


# FW-ADR-0017 — File-keyed migration discovery

<!-- TOC -->

- [Status](#status)
- [Context and problem statement](#context-and-problem-statement)
- [Decision drivers](#decision-drivers)
- [Considered options (Three-Path Rule, binding)](#considered-options-three-path-rule-binding)
  - [Option M — Minimalist: file-keyed enumeration of `migrations/v*.sh`](#option-m--minimalist-file-keyed-enumeration-of-migrationsvsh)
  - [Option S — Scalable: tag-keyed with phantom-tag synthesis](#option-s--scalable-tag-keyed-with-phantom-tag-synthesis)
  - [Option C — Creative: content-addressed migration discovery](#option-c--creative-content-addressed-migration-discovery)
- [Decision outcome](#decision-outcome)
- [Interface decisions (binding)](#interface-decisions-binding)
  - [1. Filename → semver parse rule](#1-filename--semver-parse-rule)
  - [2. Range bounds](#2-range-bounds)
  - [3. Ordering across pre-release identifiers](#3-ordering-across-pre-release-identifiers)
  - [4. Migration failure semantics](#4-migration-failure-semantics)
  - [5. Idempotency contract](#5-idempotency-contract)
  - [6. Source-bound resolution + TEMPLATE_VERSION fallback](#6-source-bound-resolution--template_version-fallback)
  - [7. Verification + discovery log](#7-verification--discovery-log)
  - [8. Migration file eligibility](#8-migration-file-eligibility)
  - [9. Migration retirement](#9-migration-retirement)
  - [10. Import contract — migration content boundaries](#10-import-contract--migration-content-boundaries)
- [Consequences](#consequences)
  - [Positive](#positive)
  - [Negative / trade-offs accepted](#negative--trade-offs-accepted)
- [Verification](#verification)
- [Implementation notes for software-engineer](#implementation-notes-for-software-engineer)
- [Open questions](#open-questions)
- [Links](#links)

<!-- /TOC -->

Shape per MADR 3.0 + this template's Three-Path Rule
(`docs/templates/adr-template.md`). Third in the upgrade-flow
rearchitecture sequence (FW-ADR-0015 foundation, FW-ADR-0016 state
schema, **FW-ADR-0017 discovery**, FW-ADR-0018 bridging rc,
FW-ADR-0019 pre-bootstrap retirement). Cap ~500 lines.

---

## Status

- **Proposed: 2026-05-15**
- **Accepted: 2026-05-15**
- **Deciders:** `architect` + `tech-lead` + customer (cross-cutting
  pattern change to migration discovery; locks the runner into
  file-presence semantics; customer approval per CLAUDE.md Hard
  Rules).
- **Consulted:** FW-ADR-0015 (foundation; this ADR fills in the
  runner-internal migration-discovery slot that FW-ADR-0015 named
  but did not pin), FW-ADR-0016 (state schema; `template.ref` /
  `template.version` carry the source bound), the conceptual-
  mistake report (`docs/pm/upgrade-flow-conceptual-mistake-2026-05-15.md`,
  third-order mistake re: tag-keyed enumeration), the process-debt
  report (`docs/pm/upgrade-flow-process-debt-2026-05-15.md` item 9,
  migration-retirement gap), the 2026-05-15 dogfood RC-2 finding
  (rc13 migration file present on main but unreachable because no
  rc13 tag exists), `software-engineer` (eligibility / failure
  semantics implementability), `qa-engineer` (discovery-set audit
  shape).

## Context and problem statement

The current runner enumerates migrations by walking
`git tag -l 'v*'` on the upstream remote
(`scripts/upgrade.sh:875`), filters that list to the range
`(local_version, new_version]`, and runs
`migrations/<tag>.sh` for each tag in order. This is tag-keyed
discovery: the **tag** is the migration's identity, the file is
its body. A migration file that exists in `migrations/` but whose
tag is not yet published is unreachable — the runner does not
look at the directory, only at the remote's tag set.

The 2026-05-15 dogfood RC-2 surfaced this concretely. FW-ADR-0013
landed `migrations/v1.0.0-rc13.sh` on `main` to fix a rc-to-rc
pre-bootstrap problem. Dogfood vs `main` did not run the
migration because no `v1.0.0-rc13` tag existed. The customer's
binding "dogfood before cutting an rc" rule made the tag
precondition impossible to satisfy: the dogfood must pass before
the tag exists; the tag must exist before the dogfood enumerates
the migration. The structural catch-22 is the rule against itself.

FW-ADR-0015 dissolved the larger orchestrator-self-mutation
problem by moving the runner out of the project tree (fetched
fresh per invocation). FW-ADR-0016 dissolved the
three-source-of-truth state problem by consolidating onto
`TEMPLATE_STATE.json`. The remaining piece is migration discovery
itself: the runner is now current by construction, and it carries
its `migrations/` directory in its own tree. The natural identity
of a migration is the **filename** of the script the runner
actually has on disk at the moment of enumeration; tags become
irrelevant to discovery.

ADR-trigger rows that fire: cross-cutting pattern change
(migration-discovery shape); choice that locks the runner into a
file-presence enumeration model; change touching the
customer-flagged critical path (upgrade is "always buggy" — the
discovery layer is the gate that decides which corrective
migrations apply).

## Decision drivers

- **Dissolve the rc13 catch-22 by construction.** Customer's "no
  tag before PASS" rule must be honoured structurally, not by
  remembering to cut a tag at the right moment.
- **Align with FW-ADR-0015's runner-is-current-by-construction
  principle.** Tag enumeration consults a remote registry; file
  enumeration consults the runner's own tree. The latter matches
  the foundation ADR; the former preserves a vestigial coupling
  to upstream state.
- **Preserve the idempotency invariant.** Migration files are
  already required to be idempotent (per `migrations/TEMPLATE.sh`
  contract). The new discovery model strengthens the requirement —
  re-runs are common during dogfood iteration on a single ref.
- **Keep the source-bound stable across the
  FW-ADR-0018 bridging rc.** The runner must read both
  `TEMPLATE_STATE.json` (post-bridge) and `TEMPLATE_VERSION`
  (pre-bridge, legacy) to determine the source bound. Both are
  supportable.
- **Naturally enable migration retirement.** Once discovery is
  file-keyed, removing a file removes the migration from the
  discovery set; the framework can finally retire old
  migrations rather than carrying them forever (process-debt
  item 9).

## Considered options (Three-Path Rule, binding)

### Option M — Minimalist: file-keyed enumeration of `migrations/v*.sh`

The runner walks `$RUNNER_DIR/migrations/`, takes every file
whose name matches the migration naming convention (§ 8), parses
the filename into a semver, semver-orders the set, filters to
`(project_schema_version, target_schema_version]`, and runs each
in ascending order. Tags become operator-facing labels for
release humans and the version-check loop; they have no role in
migration discovery.

- **Sketch:** Enumeration is `find migrations -maxdepth 1 -type f
  -name 'v*.sh' -o -name '[0-9]*.sh'` (the latter accommodates
  the existing legacy file `1.1.0.sh`). Parsing strips an
  optional leading `v` then runs the result through the existing
  semver helper (`semver_sort_tags` extracted into a library
  function). Range filter compares each parsed semver against
  the bound pair from `TEMPLATE_STATE.json.template.version` (or
  `TEMPLATE_VERSION` line 1 for legacy projects). Ordering is by
  semver (including pre-release rules — § 3).
- **Pros:**
  - Rc-cliff catch-22 dissolves: a migration file on `main`
    runs against `main` even before a tag is cut.
  - Discovery is local to the runner's own tree — no remote
    consultation, no `git tag -l`, no network call beyond the
    runner-fetch FW-ADR-0015 already requires.
  - Semver ordering is well-understood. The existing
    `semver_sort_tags` helper already implements the
    pre-release rules; it is reused.
  - Migration retirement becomes a `git rm` against the
    runner's tree, governed by a documented MIN_SUPPORTED rule
    (§ 9). No mass cleanup required at acceptance.
- **Cons:**
  - Filename typos now silently skip discovery instead of
    silently skipping tag-matching. The blast radius is the
    same (the migration does not run); the diagnostic surface
    differs. Mitigated by the discovery-log requirement (§ 7).
  - Migration files outside the eligibility envelope (§ 8) —
    e.g., `TEMPLATE.sh`, scratch files left in a working tree
    — are skipped silently. The runner ships a clean tree; the
    risk is contained.
- **When M wins:** when the failure mode is "migration files
  exist but tag enumeration cannot see them" (it is) and the
  runner is the authoritative carrier of its own migration set
  (it is, per FW-ADR-0015).

### Option S — Scalable: tag-keyed with phantom-tag synthesis

Retain the current `git tag -l` enumeration but extend it: when
the runner detects a `migrations/<v>.sh` file with no
corresponding tag in the remote, synthesise a "phantom tag"
entry for the discovery loop with the file's parsed version.
Tag enumeration remains the primary mechanism; phantom-tag
fall-in covers the rc13-class case.

- **Sketch:** Existing enumeration walks remote tags. After the
  walk, an additional pass walks `migrations/` files; any file
  whose parsed version is missing from the tag set is added to
  the discovery set with a "phantom" marker. Ordering and range
  bounds are unchanged from current. The phantom marker drives
  a small logging difference but no semantic change.
- **Pros:**
  - Smallest diff against current. Existing `semver_sort_tags`
    + range-filter logic stays.
  - Tags remain primary, which matches operator muscle memory
    on the SE side.
- **Cons:**
  - Preserves two parallel enumeration mechanisms that must
    agree. The dogfood evidence is that "two sources of truth
    that must agree" IS the failure pattern we are dissolving
    (FW-ADR-0014 Q1, FW-ADR-0016 manifest-vs-preserve).
  - Tag enumeration requires a remote consult; the runner is
    fetched fresh per invocation and could already-have-it via
    its `.git/` carry, but adding "the runner reads its own
    `.git` tags" is a fragile coupling that FW-ADR-0015
    explicitly retired.
  - Does not address migration retirement; the tag set is
    immutable upstream, so phantoms accrete indefinitely.
  - "Smarter tag discovery" is what PR #186 attempted; the
    pattern survived the smarter discovery.
- **When S wins:** if the cost of changing the primary
  enumeration mechanism were prohibitive (it is not — the
  current implementation is ~40 lines).

### Option C — Creative: content-addressed migration discovery

Each migration's identity is the sha256 of its content; the
filename's version is purely a sort label. The runner records
each successfully-applied migration's content-hash in
`TEMPLATE_STATE.json` (new `applied_migrations` array). On a
subsequent run, the runner walks `migrations/`, hashes each
file, filters out applied ones, semver-sorts the remainder, and
runs them. A migration's body changing (bug fix to a previously-
shipped migration) creates a new hash; the new hash runs even
though the version did not advance.

- **Sketch:** New top-level `applied_migrations: [{version, sha256,
  applied_at}, ...]` in `TEMPLATE_STATE.json`. Runner enumerates
  `migrations/` files, computes sha256 of each, joins against
  the applied list, semver-sorts the unapplied remainder, runs.
- **Pros:**
  - Captures bug-fix migrations naturally — a migration whose
    body changes runs again automatically.
  - Replay semantics are explicit: the state file knows what
    actually ran, not just what the version label was.
  - Idempotency is no longer a strict requirement — content-
    addressing tolerates re-runs of changed migrations even if
    the migration itself is not idempotent (the runner only
    runs each hash once).
- **Cons:**
  - Adds a new field to `TEMPLATE_STATE.json` (FW-ADR-0016
    schema bump from 1.0.0 to 1.1.0 before this ADR's
    implementation even ships). The schema-version churn is
    avoidable.
  - Bug-fix-to-existing-migration as a re-run pattern is a
    footgun: it tempts authors to ship corrections in the same
    file rather than as a new versioned migration, which loses
    the audit trail entirely. The current "new bug → new
    migration file" rule is desirable.
  - State-file growth is unbounded over project lifetime
    (every applied migration accretes a row).
  - The idempotency relaxation is illusory: a migration that
    fixes a bug another migration introduced still has to
    handle the partially-corrupted state from the buggy
    predecessor, which IS the idempotency problem rebranded.
  - Operator audit "which migration ran when?" becomes
    state-file-only; `git log migrations/` no longer answers
    it.
- **When C wins:** if the framework had a population of
  long-lived projects where bug-fix migrations were a recurring
  cost. The framework's single-user posture (customer 2026-05-15
  `CUSTOMER_NOTES.md` L323) does not justify the schema and
  audit-surface complexity.

## Decision outcome

**Chosen option: M (file-keyed enumeration of `migrations/v*.sh`).**

**Reason:** Option M is the only option that dissolves the
rc13 catch-22 by construction rather than relocating it. Option
S keeps two parallel discovery mechanisms that must agree — the
exact "two sources of truth" pattern FW-ADR-0014 Q1 and
FW-ADR-0016 exist to retire. Option C trades schema simplicity
for a content-addressed model whose value the framework's
operator profile does not justify; it also weakens the
idempotency contract in a way that introduces footguns. Option
M aligns with FW-ADR-0015's runner-is-current-by-construction
principle, reuses the existing `semver_sort_tags` helper,
naturally enables migration retirement (§ 9), and reduces
runtime enumeration to a single local-directory walk.

This decision is conditional on FW-ADR-0016's acceptance (it
is; 2026-05-15). The source-bound resolution in § 6 reads
`TEMPLATE_STATE.json.template.version` post-bridge and falls
back to `TEMPLATE_VERSION` line 1 pre-bridge.

## Interface decisions (binding)

### 1. Filename → semver parse rule

Migration filenames are parsed by the following procedure:

1. Strip the trailing `.sh` extension.
2. If the result starts with `v`, strip the leading `v`.
3. Pass the remainder to the runner's semver parser (the same
   parser used by `semver_sort_tags`, extracted into the runner
   library — see § Implementation notes).
4. If parsing fails, the file is NOT eligible for discovery and
   the runner emits a `WARN` line naming the file and the parse
   failure (see § 8).

Examples (all binding):

| Filename                  | Stripped       | Parses to                        | Eligible? |
|---------------------------|----------------|----------------------------------|-----------|
| `v1.0.0-rc14.sh`          | `1.0.0-rc14`   | `1.0.0` + pre-release `rc14`     | yes       |
| `v0.14.0.sh`              | `0.14.0`       | `0.14.0`                         | yes       |
| `v1.0.0-rc13.sh`          | `1.0.0-rc13`   | `1.0.0` + pre-release `rc13`     | yes       |
| `1.1.0.sh` (legacy)       | `1.1.0`        | `1.1.0`                          | yes       |
| `TEMPLATE.sh`             | `TEMPLATE`     | parse fails                      | no (skip silently — § 8) |
| `v1.0.0-beta1.sh` (hyp.)  | `1.0.0-beta1`  | `1.0.0` + pre-release `beta1`    | yes       |
| `v1.0.0-rc.14.sh` (hyp.)  | `1.0.0-rc.14`  | `1.0.0` + dotted pre-release `rc.14` (SemVer §9) | yes |
| `v1.0.0+build.5.sh` (hyp.)| `1.0.0+build.5`| `1.0.0` + build metadata `build.5` (SemVer §10; ignored for ordering) | yes |
| `v1.0.0.5.sh` (malformed) | `1.0.0.5`      | parse fails (4-segment)          | no (WARN) |

**Tolerance for the `v`-less legacy file (`1.1.0.sh`):** the
runner accepts both `v<semver>.sh` and `<semver>.sh` shapes for
discovery. New migrations (per § 8) MUST use the `v<semver>.sh`
shape; the un-prefixed shape is tolerated for backward
compatibility with the one pre-convention file already in the
tree.

**`TEMPLATE.sh` exclusion:** the file `migrations/TEMPLATE.sh`
is the migration scaffold. It MUST be skipped silently by
discovery (no WARN), recognised by exact filename match before
the parse step.

### 2. Range bounds

Discovery filters parsed migration versions to the range:

**`(project_schema_version, target_schema_version]`**

- **Low end: half-open (exclusive).** A migration whose parsed
  semver equals the project's current `template.version`
  (FW-ADR-0016) does NOT re-run **after that version is recorded
  as the source bound**; it already ran in the upgrade that
  advanced the source to its version. Within a dogfood loop where
  the source bound is held constant, in-range migrations re-run
  on every pass — see § 5 for the idempotency contract that covers
  this. This avoids re-runs that, once the source bound has
  advanced, would generate noise and break the "one new migration
  per upgrade cycle" audit.
- **High end: closed (inclusive).** A migration whose parsed
  semver equals the target version DOES run as the final step.
  This matches the current `[ "$tag" == "$new_version" ] && break`
  behaviour.

Edge cases (binding):

- **Project at scaffold (no prior sync).** Source bound is the
  scaffold-time stamp. All migrations whose semver is greater
  than the scaffold-time version and ≤ target run. (Same as
  current behaviour modulo the discovery-source switch.)
- **Project's current version not parseable.** Source bound
  defaults to `0.0.0` (the runner emits a WARN). All
  migrations ≤ target run. This is the conservative
  full-walk fallback already present in the current runner; it
  survives unchanged.
- **Target version not parseable.** Discovery fails fast with a
  clear error before any migration runs. This is a
  framework-side bug (the target version came from the runner
  itself via FW-ADR-0015) — surface it loudly.

### 3. Ordering across pre-release identifiers

Discovery orders migrations by semver, including pre-release
rules (SemVer 2.0 § 11). The current `semver_sort_tags` helper
already implements these rules and is reused unchanged. The
binding examples:

```
v0.14.0      < v0.15.0
v1.0.0-rc9   < v1.0.0-rc10        (numeric pre-release ID compare)
v1.0.0-rc13  < v1.0.0-rc14
v1.0.0-rc14  < v1.0.0             (pre-release < release; SemVer §11.3)
v1.0.0       < v1.0.1-rc1         (release < next-release-rc; SemVer §11.4)
v1.0.0-beta1 < v1.0.0-rc1         (lexical pre-release ID compare; "beta" < "rc")
v1.0.0-1     < v1.0.0-alpha       (pure-numeric pre-release ID < alphanumeric; SemVer §11.4.4)
```

The rc-number compare is **numeric**, not lexical: `rc9 < rc10`,
not `rc10 < rc9`. The existing helper handles this; the test
suite has a regression guard (`--self-test-semver` flag in the
current `scripts/upgrade.sh`).

### 4. Migration failure semantics

A migration fails when its body exits non-zero.

**Runner behaviour on failure:**

1. Abort the migration chain immediately. Subsequent migrations
   in the discovery set do NOT run.
2. Do NOT write `TEMPLATE_STATE.json` (the sync session lock
   from FW-ADR-0016 holds; the file remains at its pre-upgrade
   state).
3. Exit non-zero with phase-A "Migration chain incomplete"
   (per FW-ADR-0014 Q2, inherited into the runner unchanged).
4. The stderr summary names: (a) the failing migration's
   filename, (b) the position in the chain (`3 of 7`), (c) the
   migrations that did run (and therefore mutated state), and
   (d) the migrations that did not run.
5. Operator recovery is operator-side: fix the migration body
   (if the failure is a bug), or fix the project tree (if the
   failure is environment), then re-run the upgrade. The
   already-applied migrations re-run; their idempotency
   contract (§ 5) MUST cover the re-run.

**Source-bound invariant:** `TEMPLATE_STATE.json.template.version`
advances only on full-chain success. Mid-chain failures leave the
source bound at its pre-upgrade value, ensuring the next upgrade
re-discovers every migration in the original range and the
idempotency contract (§ 5) handles the re-run.

**Runner does NOT:**

- Retry the failing migration automatically.
- Skip the failing migration and continue.
- Rollback applied migrations. Rollback is not supported; the
  idempotency contract is the rollback story.

This matches the current runner's behaviour
(`set -euo pipefail` in each migration body); FW-ADR-0017 makes
the contract explicit.

### 5. Idempotency contract

Every migration file MUST be idempotent. Binding shape for
authors:

- Re-running a migration on already-migrated state is a no-op
  (returns 0, mutates nothing, produces minimal stdout).
- **No-op signature (binding).** On idempotent re-entry, the
  migration MUST emit exactly one line to stderr of the form
  `<filename>: no-op (already applied)` before returning 0.
  This is the signature `qa-engineer`'s acceptance harness
  greps for in Verification signal D; it is the contract the
  signal relies on.
- Detection patterns the runner endorses:
  - `[[ -f "$PROJECT_ROOT/<new-path>" ]] && return 0` (file
    already present from prior run).
  - `grep -q '<marker>' "$PROJECT_ROOT/<file>" && return 0`
    (in-file marker for content-mutation migrations).
  - `[[ ! -f "$PROJECT_ROOT/<old-path>" ]] && return 0` (the
    rename source no longer exists; migration already
    consumed it).
- Mutation order: read source, validate, atomic-write
  destination, then remove source. Crash mid-migration leaves a
  recoverable state for the next run.
- Migrations MUST NOT depend on the absence of state to detect
  "already migrated"; they MUST detect a positive signal of
  prior application. (Negative-evidence detection breaks when
  the operator hand-applies a partial migration.)

Re-runs are common in three situations: (a) FW-ADR-0017's
range-filter accepts the migration on every upgrade until the
project's `template.version` advances past it (currently the
project advances after each successful upgrade, but dogfood
loops iterate on the same source bound); (b) a later migration
in the chain fails and the operator re-runs after fixing it;
(c) the operator manually re-runs an upgrade against the same
target to verify the no-op case. All three are covered by the
idempotency contract.

### 6. Source-bound resolution + TEMPLATE_VERSION fallback

Resolution order:

1. If `TEMPLATE_STATE.json` exists at project root and is
   schema-valid (per FW-ADR-0016), read
   `.template.version` and use it as the low-end bound.
2. Else if `TEMPLATE_VERSION` exists at project root, read
   line 1 (the semver line) and use it as the low-end bound.
3. Else (neither file present): scaffold-fresh case — the
   project has never been upgraded. The low-end bound is
   `0.0.0` (effectively run every migration ≤ target).

The transition window (FW-ADR-0018's bridging rc) is the only
moment both files coexist; the rc's first-run body writes
`TEMPLATE_STATE.json` from the legacy trio and removes
`TEMPLATE_VERSION`. After the bridge, only step 1 fires.

The runner emits a discovery-log line (§ 7) naming which
source it read.

### 7. Verification + discovery log

The runner MUST emit a discovery log on every upgrade
invocation, regardless of `--dry-run`. The log entry contains:

- The source the low-end bound came from
  (`TEMPLATE_STATE.json` / `TEMPLATE_VERSION` / scaffold).
- The low-end and high-end bounds (parsed semver values).
- The full discovered file set (every eligible file in
  `migrations/`, in semver order, with eligibility status —
  in-range / out-of-range / parse-fail / template-scaffold).
- The count of migrations to run.

Log location: stderr (the existing runner's logging
convention). On `--dry-run`, the log is the primary output;
the runner additionally prints "WOULD RUN" prefixes for each
in-range migration and exits 0 without executing any of them.

Format (binding; SE may refine prose):

```
Migration discovery:
  Source bound:  TEMPLATE_STATE.json -> 1.0.0-rc11
  Target bound: 1.0.0-rc14 (inclusive)
  Discovered (8 files):
    v0.14.0.sh       (out-of-range: <= source)
    v0.14.4.sh       (out-of-range: <= source)
    v0.15.0.sh       (out-of-range: <= source)
    v1.0.0-rc9.sh    (out-of-range: <= source)
    v1.0.0-rc13.sh   (IN RANGE)
    v1.0.0-rc14.sh   (IN RANGE)
    1.1.0.sh         (out-of-range: > target)
    TEMPLATE.sh      (scaffold; skipped)
  To run (2): v1.0.0-rc13.sh, v1.0.0-rc14.sh
```

`qa-engineer`'s acceptance harness greps the discovery log to
verify the rc13 file IS in the "to run" set when dogfooding
against `main` from an rc12 baseline. This is the foundational
acceptance test (§ Verification).

### 8. Migration file eligibility

A file in `$RUNNER_DIR/migrations/` is **eligible for discovery**
iff ALL of the following hold:

- **Filename match:** matches `v*.sh` OR matches `[0-9]*.sh`
  (the legacy un-prefixed shape).
- **Not the scaffold:** filename is not exactly `TEMPLATE.sh`.
- **Filename parses to semver:** per § 1.
- **Regular file:** `[[ -f "$file" ]]`. Symlinks are followed;
  directories, FIFOs, devices are skipped silently.
- **Readable:** `[[ -r "$file" ]]`. Unreadable files emit WARN
  and are skipped.

**When discovery rejects a file:**

- `TEMPLATE.sh` exact match → silent skip.
- Filename matches `v*.sh` or `[0-9]*.sh` but parse fails → WARN.
- Unreadable → WARN.
- Not a regular file (directory, FIFO, device) → silent skip.
- Doesn't match either filename pattern → not enumerated at all
  (`find` never sees it).

**Not required:**

- Executable bit. The runner invokes migrations as
  `bash "$mig"`, not via direct exec; the executable bit is
  irrelevant. (`migrations/TEMPLATE.sh` ships without `+x` and
  this MUST continue to work for files copied from it.)
- Shebang line. The runner invokes with `bash`; the migration
  body need not declare its own interpreter. (Convention:
  migrations DO carry `#!/usr/bin/env bash` for operator
  readability and to document intent. Convention is not
  enforced.)
- Header marker. The convention `# migrations/<version>.sh —
  <description>` in line 2 is operator-readable but not
  enforced. The migration's identity is its filename.

New migration files (authored after this ADR's acceptance) MUST
use the `v<semver>.sh` shape. The `[0-9]*.sh` tolerance exists
solely for the existing legacy `1.1.0.sh`; `software-engineer`
may rename that file to `v1.1.0.sh` as a follow-up cleanup, at
which point the legacy-shape tolerance can be removed in a
future MINOR (out of scope for this ADR).

### 9. Migration retirement

Migrations may be retired by `git rm` from the runner's
`migrations/` tree, governed by:

**Rule:** A migration file MAY be removed when its parsed
version is **strictly less than the framework's declared
`MIN_SUPPORTED_VERSION`**. The framework's
`MIN_SUPPORTED_VERSION` is recorded in a separate sibling file
`MIN_SUPPORTED_VERSION` at runner root — a one-line bare-semver
file structurally parallel to `VERSION`. Keeping it separate from
`VERSION` avoids widening `VERSION`'s single-purpose one-line
semver shape to a multi-line `key: value` format that other
readers would have to skip-or-parse. Setting `MIN_SUPPORTED_VERSION`
is an operator-controlled decision; the framework's single-user
posture (customer 2026-05-15 `CUSTOMER_NOTES.md` L323) means the
customer alone decides when to advance it.

**Effect of advancing `MIN_SUPPORTED_VERSION`:** projects
on `template.version < MIN_SUPPORTED_VERSION` cannot upgrade
through the current runner; they must first upgrade through an
older runner ref to a version ≥ `MIN_SUPPORTED_VERSION`, then
re-fetch the current runner. The runner refuses with a clear
error naming the target intermediate version.

**At ADR acceptance:** `MIN_SUPPORTED_VERSION` is unset (treated
as `0.0.0`). All existing migrations remain in the tree. The
customer advances `MIN_SUPPORTED_VERSION` deliberately when
they want to retire migrations. No migrations are retired by
this ADR's acceptance.

**Cleanup batch:** when `MIN_SUPPORTED_VERSION` advances, the
framework MAY remove all migration files whose parsed version
is below it in the same commit. The removal is a routine
maintenance change, not an ADR-trigger event. `software-
engineer` proposes the batch; `code-reviewer` reviews.

This rule resolves the process-debt audit item 9 (no migration
ever retires). The retirement is operator-controlled in name
but ADR-governed in shape.

### 10. Import contract — migration content boundaries

Each migration is a **standalone bash script**. It MAY:

- Source utilities from `$RUNNER_DIR/scripts/lib/` (e.g.,
  `manifest_*` helpers, `safe_write`, semver helpers). The
  runner exports `$RUNNER_DIR` to the migration's environment
  for this purpose.
- Read project-tree files via `$PROJECT_ROOT`.
- Write project-tree files via `$PROJECT_ROOT`.
- Read runner-tree files via `$WORKDIR_NEW` (the existing
  contract; survives unchanged from the legacy runner).
- Call standard POSIX utilities (`sed`, `awk`, `grep`, `mv`,
  `cp`, `mktemp`, `cmp`, `diff`).

A migration MUST NOT:

- Source or invoke other migration files. Each migration is
  independent; cross-migration dependencies are forbidden.
  Rationale: discovery's range filter (§ 2) means earlier
  migrations may not run on a given upgrade; a migration that
  depends on another migration's side effect is broken under
  the filter.
- Mutate `TEMPLATE_STATE.json` directly. The runner owns that
  file (FW-ADR-0016 § Concurrency). Migrations that need to
  declare new managed paths produce the on-disk state; the
  runner re-bakes `paths` from the manifest at sync exit.
- Fetch from the network. Migration bodies are pure-local
  transformations.
- Spawn long-running daemons or background processes that
  outlive the migration's bash invocation.
- Read or write outside `$PROJECT_ROOT` and `$RUNNER_DIR`. The
  migration's filesystem footprint is bounded to those two
  trees plus `$WORKDIR_NEW` and standard temp dirs
  (`mktemp -d`).
- Mutate shell state that outlives the migration's bash process.
  This includes `set +e` / `set +u` toggles that leak past the
  migration body, traps that survive the migration's bash
  invocation, and `export`s of environment variables intended to
  be consumed by later migrations. Each migration is a fresh
  bash process; cross-migration coupling via shell state is a
  variant of the cross-migration-dependency prohibition above.

Violations of the import contract are caught by `code-reviewer`
at migration-author time; the runner does not sandbox them. The
contract is convention enforced by review, not by execution
isolation.

## Consequences

### Positive

- **Rc-cliff catch-22 dissolves.** A migration file shipped to
  `main` runs against `main` immediately; no tag precondition.
  The customer's "no tag before PASS" rule is honoured by
  construction.
- **Dogfood against arbitrary refs works.** The runner fetched
  from `main` (FW-ADR-0015) discovers migrations from its own
  `migrations/` tree, regardless of what tags exist remotely.
- **Discovery is local and deterministic.** No `git tag -l`
  network consult; no dependence on remote registry state. The
  runner's `migrations/` directory IS the discovery surface.
- **Migration retirement becomes possible.** The
  `MIN_SUPPORTED_VERSION` rule (§ 9) gives the framework a
  documented path to drop old migrations; process-debt item 9
  resolves.
- **Discovery log makes the migration set auditable.**
  Operators see the full enumeration before any migration
  runs; `--dry-run` makes verification cheap.
- **Tag identity becomes purely operator-facing.** Tags label
  releases; they do not gate discovery. The conceptual mistake
  the conceptual-mistake report identified (tag as identity)
  retires.

### Negative / trade-offs accepted

- **Filename typos cause silent discovery skips.** A migration
  authored as `migrations/v1.0.0-rc14.sj` (typo) parses as
  unrecognised filename and skips with a WARN. The current
  model has the same blast radius (the migration would not
  run) but the diagnostic shape differs. Mitigated by the
  discovery log (§ 7); `qa-engineer`'s acceptance harness
  asserts every file in `migrations/` is accounted for in the
  discovery log.
- **Operator retirement responsibility.** The framework does
  not auto-retire migrations; the customer advances
  `MIN_SUPPORTED_VERSION` deliberately. The cost is the
  customer must choose when; the value is that retirement
  decisions are not silent.
- **Re-runs more frequent in dogfood loops.** A dogfood
  iteration against the same target re-runs every in-range
  migration on each pass (the source bound does not advance
  between dogfood passes against the same fixture). The
  idempotency contract (§ 5) absorbs this; the cost is
  marginal stdout noise.
- **`MIN_SUPPORTED_VERSION` adds a small new state field.** A
  one-line file at runner root, governed by the framework.
  Project-side cost is zero; runner-side cost is the parse
  and refuse logic.
- **Legacy `1.1.0.sh` tolerance persists indefinitely.** The
  one un-prefixed migration file in the tree requires the
  `[0-9]*.sh` pattern in discovery. The tolerance is removed
  when `software-engineer` renames the file to `v1.1.0.sh` in
  a routine cleanup, but the rename is not blocking this ADR.

## Verification

- **Success signal A — rc13 dogfood.** Running the runner from
  `main` against an rc12-baseline fixture discovers and runs
  `migrations/v1.0.0-rc13.sh` even though no `v1.0.0-rc13` tag
  exists. This is the foundational test; failure here means
  this ADR is not correctly landed.
- **Success signal B — discovery-log audit.**
  `qa-engineer` greps the runner's discovery log against a
  fixture and asserts: (a) every file in
  `migrations/` is named; (b) the in-range set matches the
  expected set; (c) `TEMPLATE.sh` is skipped silently; (d) the
  source-bound annotation names `TEMPLATE_STATE.json` (or
  `TEMPLATE_VERSION` for legacy fixtures).
- **Success signal C — no `git tag -l` in runner.** A
  `grep 'git tag' "$RUNNER_DIR/scripts/upgrade-runner.sh"`
  returns no matches. (The version-check helper may still
  consult tags for "is there a newer release?" — but migration
  discovery does not.)
- **Success signal D — idempotency on re-run.** A fixture
  upgraded twice in sequence against the same target produces
  identical `TEMPLATE_STATE.json` and identical project tree;
  the second run's discovery log shows the same set as the
  first, and every migration emits its no-op signature.
- **Success signal E — migration retirement.** Setting
  `MIN_SUPPORTED_VERSION=v0.15.0` and re-running against a
  fixture at `v0.14.4` produces a clear refusal naming the
  required intermediate version, without running any
  migrations.
- **Failure signal — a migration file present in the tree is
  silently skipped.** Indicates either a filename eligibility
  bug or an unintended exclusion. Routes to `architect` for
  rule review; not a runtime bypass.
- **Failure signal — discovery log absent or unreadable.**
  Indicates a logging regression. The discovery log is part of
  the runner's contract; absence is a release-blocking bug.
- **Review cadence:** at the first MINOR release after
  FW-ADR-0018's bridging rc ships, and again at six months
  post-bridge.

## Implementation notes for software-engineer

Scope for FW-ADR-0017-impl. The architect describes the
contract; the SE implements.

- **Discovery function:** lives in the runner's
  `scripts/lib/migration-discovery.sh` (new file). Pure
  function: input (`$RUNNER_DIR`, source-bound semver,
  target-bound semver), output (ordered array of migration
  paths to run + structured discovery-log lines). No
  side-effects beyond stderr logging.
- **Semver helper reuse:** extract the existing
  `semver_sort_tags` helper from `scripts/upgrade.sh` into
  `scripts/lib/semver.sh` (or refactor in place if the helper
  is already there — SE confirms during implementation). The
  parse function MUST handle the `v` prefix strip + the
  un-prefixed legacy shape.
- **Filename pattern:** discovery enumerates with
  `find "$RUNNER_DIR/migrations" -maxdepth 1 -type f \( -name 'v*.sh' -o -name '[0-9]*.sh' \)`.
  Explicit exclusion of `TEMPLATE.sh` happens after enumeration.
- **Range filter:** the existing `(local_version, new_version]`
  semantics in `scripts/upgrade.sh:875-916` move bodily into
  the discovery function. The implementation transcribes the
  existing logic against the parsed-from-file version list
  rather than the tag list.
- **Migration retirement check:** the runner reads its own
  `MIN_SUPPORTED_VERSION` (file or VERSION-file line); if the
  project's `template.version` is below it, refuse with exit
  code TBD (assigned in FW-ADR-0014 Q2's inherited exit-code
  table) and a message naming the required intermediate
  version.
- **Source-bound resolver:** new helper that implements § 6.
  Three-case: TEMPLATE_STATE.json present → use it;
  TEMPLATE_STATE.json absent but TEMPLATE_VERSION present →
  use TEMPLATE_VERSION line 1; both absent → `0.0.0`.
- **Discovery log:** stderr, one block per invocation. Format
  matches § 7. `--dry-run` adds "WOULD RUN" prefixes and exits
  0 after the log.
- **Unit tests (`qa-engineer` scope):**
  - (a) Filename parse: each row in § 1's table produces the
    expected eligibility and version.
  - (b) Range filter: edge cases (source == filename, target ==
    filename, source == target, source > target).
  - (c) Pre-release ordering: `rc9 < rc10 < rc13 < rc14 < final`.
  - (d) Discovery log: every file accounted for, in-range set
    matches expected, format conforms.
  - (e) Idempotent re-run: same fixture twice → identical
    state, identical discovery log.
  - (f) Migration retirement: `MIN_SUPPORTED_VERSION` refuses
    cleanly.
  - (g) TEMPLATE.sh exclusion: present in `migrations/` but
    never appears in to-run set; logged as "scaffold;
    skipped".
- **Rename of `1.1.0.sh` to `v1.1.0.sh`:** routine cleanup,
  follow-up commit, not blocking this ADR's implementation.
  When done, remove the `[0-9]*.sh` pattern from the discovery
  enumeration.

The implementation ADR (FW-ADR-0017-impl) covers code-level
details beyond this contract. `code-reviewer` reviews; this
ADR's acceptance does not authorise implementation by itself —
FW-ADR-0018's bridging rc is the ship vehicle.

## Open questions

All questions raised by this ADR are closed. Q-F-0017-1
(`MIN_SUPPORTED_VERSION` carrier) was closed during CR
disposition (2026-05-15) in favour of a separate sibling
`MIN_SUPPORTED_VERSION` file at runner root; see § 9 for the
pinned interface. The dispatch brief's other axes (parse rule,
range bounds, ordering, failure semantics, idempotency,
source-bound fallback, verification, eligibility,
retirement-rule shape, import contract) are closed by this
ADR's binding interface decisions above. FW-ADR-0017-impl may
begin without further customer disposition on these axes.

## Links

- Foundation ADRs:
  - `docs/adr/fw-adr-0015-upgrade-orchestrator-stub-model.md`
    (runner-fetch model; this ADR fills its runner-internal
    discovery slot).
  - `docs/adr/fw-adr-0016-template-state-json-schema.md`
    (state schema; source-bound is read from
    `template.version`).
- Superseded interface (partial):
  - `scripts/upgrade.sh` lines 864-916 (current tag-keyed
    enumeration block; moves into the runner with the
    discovery semantics replaced per this ADR).
- Forward-referenced ADRs:
  - FW-ADR-0018 — migration path for currently-deployed
    downstreams (bridging rc; ships this ADR's
    implementation).
  - FW-ADR-0019 — pre-bootstrap retirement (the rc13
    pre-bootstrap migration becomes inert once discovery is
    file-keyed and the runner is current by construction;
    formal supersession lives in FW-ADR-0019).
- PM reports:
  - `docs/pm/upgrade-flow-conceptual-mistake-2026-05-15.md`
    (third-order mistake re: tag-keyed enumeration).
  - `docs/pm/upgrade-flow-process-debt-2026-05-15.md` item 9
    (migration-retirement gap; this ADR's § 9 resolves).
  - `docs/pm/dogfood-2026-05-15-results.md` (rc13 file
    unreachable evidence).
- External references:
  - SemVer 2.0 (`https://semver.org/spec/v2.0.0.html`) — § 11
    pre-release precedence rules.
  - MADR 3.0 (`https://adr.github.io/madr/`).
