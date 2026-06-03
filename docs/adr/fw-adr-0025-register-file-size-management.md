---
name: fw-adr-0025-register-file-size-management
description: >
  Size-management strategy for the five durable flat-file registers
  (CUSTOMER_NOTES.md, docs/OPEN_QUESTIONS.md, docs/intake-log.md,
  docs/pm/RISKS.md, docs/pm/LESSONS.md) that grow unbounded across a
  project lifetime and can exceed agent context windows: archival-gate
  discipline, date-quarter sharding, or a content-addressable per-entry
  store.
status: accepted
date: 2026-06-03
---


# FW-ADR-0025 — Register file size management

<!-- TOC -->

- [Status](#status)
- [Scaffold placement note](#scaffold-placement-note)
- [Context and problem statement](#context-and-problem-statement)
- [Decision drivers](#decision-drivers)
- [Considered options (Three-Path Rule, binding)](#considered-options-three-path-rule-binding)
  - [Option M — Minimalist: archival-gate + editorial discipline](#option-m--minimalist-archival-gate--editorial-discipline)
  - [Option S — Scalable: date-quarter sharding](#option-s--scalable-date-quarter-sharding)
  - [Option C — Creative: content-addressable per-entry store](#option-c--creative-content-addressable-per-entry-store)
- [Decision outcome](#decision-outcome)
- [Customer ruling](#customer-ruling)
- [Design: date-quarter sharding (Option S)](#design-date-quarter-sharding-option-s)
  - [1. File topology](#1-file-topology)
  - [2. Quarter-roll driver: scripts/archive-registers.sh](#2-quarter-roll-driver-scriptsarchive-registerssh)
  - [3. Index generation: scripts/gen-register-index.sh](#3-index-generation-scriptsgen-register-indexsh)
  - [4. Consumer-script impact](#4-consumer-script-impact)
  - [5. CI size-gate backstop](#5-ci-size-gate-backstop)
  - [6. Migration](#6-migration)
  - [7. Co-delivery with #292](#7-co-delivery-with-292)
- [Consequences](#consequences)
  - [Positive](#positive)
  - [Negative / trade-offs accepted](#negative--trade-offs-accepted)
  - [Follow-up ADRs](#follow-up-adrs)
- [Verification](#verification)
- [Links](#links)
- [Change log](#change-log)

<!-- /TOC -->

Shape per MADR 3.0 + this template's Three-Path Rule
(`docs/templates/adr-template.md`).

---

## Status

- **Proposed** — 2026-06-03
- **Accepted** — 2026-06-03. Option S (date-quarter sharding) adopted per
  customer ruling 2026-06-03.
- **Deciders:** `architect` (proposed); `tech-lead` + customer (accepted
  2026-06-03)
- **Consulted:** issue #295 (register bloat report); issue #292
  (CUSTOMER_NOTES.md structural integrity); downstream project size
  measurements (CUSTOMER_NOTES.md 531 KB, docs/OPEN_QUESTIONS.md 232 KB,
  docs/intake-log.md 221 KB); `scripts/customer-notes-guard.py`;
  `scripts/lint-questions.sh`; `scripts/check-duplicate-ids.sh`;
  `scripts/reserve-number.sh`; `scripts/intake-show.sh`

## Scaffold placement note

Drafted in the meta-project (`docs/adr/`) per the PLAN/DO convention
(`CLAUDE.md` § "Project Identity / Working Tree"). Migrated into the
scaffold's `docs/adr/` as part of the `feat/register-sharding`
implementation PR so the rationale travels with the script and
consumer-contract changes, matching the pattern established by FW-ADR-0001
through FW-ADR-0024. The meta-project draft copy is retained as the team's
working reference; this scaffold copy is canonical from the implementation
PR forward.

---

## Context and problem statement

Five flat-file registers accumulate entries across the full lifetime of a
downstream project:

| Register | Role | Observed size (downstream) |
|---|---|---|
| `CUSTOMER_NOTES.md` | Customer-truth record; entries headed `## YYYY-MM-DD` | 531 KB |
| `docs/OPEN_QUESTIONS.md` | Question queue; Markdown table rows with a Date column | 232 KB |
| `docs/intake-log.md` | Intake log; Markdown table rows with a Date column | 221 KB |
| `docs/pm/RISKS.md` | Risk register; Markdown table rows with a Date column | (growing) |
| `docs/pm/LESSONS.md` | Lessons learned; Markdown table rows with a Date column | (growing) |

These files have no structural upper bound. As a project matures the
registers become too large for agent context windows, causing truncated
reads, missed entries, and degraded quality of librarian record-keeping.
The problem is tracked in issue #295 and overlaps issue #292 (CUSTOMER_NOTES.md
structural integrity).

Standing constraints that govern every considered option:

- **Flat files are canonical.** A relational database or search index is
  at most a derived cache; it does not replace the authoritative flat file.
- **Canonical paths must be stable.** Agent contracts, guard scripts, and
  downstream project operators reference the register by its well-known
  path. Changing or removing canonical paths breaks the existing contract.
- **Librarian owns archival.** Only `librarian` initiates a quarter roll
  or archival action. Automated scripts may execute the mechanics but must
  not fire without librarian initiation.

---

## Decision drivers

- **Agent context overflow is a correctness failure.** An agent that
  cannot read all entries in a register will silently miss prior rulings,
  open questions, or risk items. This is not a performance concern — it
  produces wrong outputs.
- **Canonical paths must be preserved.** Consumer scripts (`customer-notes-guard.py`,
  `lint-questions.sh`, `check-duplicate-ids.sh`, `reserve-number.sh`,
  `intake-show.sh`) reference register paths by name; changing a canonical
  path requires simultaneous consumer updates and is a breaking change.
- **ID uniqueness must span shards.** `check-duplicate-ids.sh` and
  `reserve-number.sh` enforce no-duplicate IDs within a register.
  After sharding, uniqueness must be verified across the active file
  and all historical shards.
- **Migration must be automatable.** Two distinct entry shapes exist
  across the five registers (date-headed sections in CUSTOMER_NOTES.md;
  date-columned table rows in the other four). A migration script must
  handle both shapes without manual entry-by-entry work.
- **Context load per read should trend toward small.** The active
  rolling file (current quarter) must remain small enough that a single
  context read is reliable. A 150 KB CI gate enforces this.

---

## Considered options (Three-Path Rule, binding)

### Option M — Minimalist: archival-gate + editorial discipline

Introduce a CI size-gate that fails when any register exceeds a threshold
(e.g., 150 KB), paired with an archival procedure run by `librarian` when
the gate is near. `librarian` moves resolved/closed entries to a dated
archive file (e.g., `docs/OPEN_QUESTIONS-archive-2026-Q1.md`) on an
as-needed basis. No structural change to the active file's format or path.

- **Sketch:** A new `scripts/check-register-sizes.sh` lints file sizes in
  CI. When a file approaches the gate, `librarian` runs a procedure to
  relocate resolved entries (answered questions, closed risks, post-dated
  rulings) to an adjacent archive file. The canonical path never changes.
  Structure within the active file is unchanged; the archive file format
  is unspecified.
- **Pros:** Zero structural change to active files or existing consumer
  scripts. Lowest implementation cost. No migration required.
- **Cons:** Archive file format is ad-hoc; no index, no cross-file lookup
  tooling. "Resolved" vs. "active" classification for CUSTOMER_NOTES.md
  entries is ambiguous (all rulings are permanent record, none are
  meaningfully "resolved"). Requires librarian judgment on every archival
  event; the CI gate provides a backstop but not a structural bound. In
  practice, registers grew to 531 KB without such a gate; adding only
  discipline without structure does not solve the root problem.
- **When M wins:** registers are small (< 50 KB), project lifetime is
  short (< 3 months), or team has demonstrated archival discipline without
  tooling support. None hold for the observed downstream project sizes.

### Option S — Scalable: date-quarter sharding

Divide each register into a rolling active file at the canonical path
(holding the current quarter's entries only) plus immutable per-quarter
shard files (`<register>-YYYY-QN.md`) and a generated index
(`<register>-INDEX.md`). A script rolls the active file into a new shard
at quarter boundaries.

- **Sketch:** At any time, the canonical path (e.g., `docs/OPEN_QUESTIONS.md`)
  holds only entries from the current calendar quarter, targeting < 150 KB.
  At quarter end, `librarian` runs `scripts/archive-registers.sh`, which
  renames the current active file to `docs/OPEN_QUESTIONS-YYYY-QN.md` and
  creates a fresh empty active file. `scripts/gen-register-index.sh`
  regenerates `docs/OPEN_QUESTIONS-INDEX.md` — a table of all shards with
  date range, entry count, and notes. Consumer scripts that do ID lookups
  or duplicate checks are extended with a `--all-shards` flag that reads
  the index and checks each shard in addition to the active file.
- **Pros:** Canonical paths are preserved; agent context load per read is
  bounded by quarter volume; shards are immutable once rolled; index
  provides O(1) shard discovery; the format within each shard is identical
  to the pre-shard format (no parser changes); quarter granularity matches
  the typical project reporting cadence.
- **Cons:** Consumer scripts need cross-shard awareness for ID-uniqueness
  and cross-shard lookup operations; migration must handle two distinct
  entry shapes; `gen-register-index.sh` must be kept in sync when shards
  are added.
- **When S wins:** registers grow continuously across multi-month projects,
  canonical paths must be stable, and the team needs structured tooling
  support rather than editorial discipline. All hold here.

### Option C — Creative: content-addressable per-entry store

Replace the Markdown flat-file format with a per-entry content-addressable
store: each entry is a small standalone file named by a hash or sequential
ID (e.g., `docs/register/customer-notes/<hash>.md`), with a generated
index Markdown file assembled for agent reads. The canonical register path
becomes a symlink or alias to the generated index.

- **Sketch:** A `scripts/register-add.sh` tool writes a new entry to its
  own file; `scripts/register-index.sh` assembles the full register view
  (sorted by date) as a Markdown file at the canonical path. Agents and
  operators read the assembled view; the store is the authoritative source.
  Entries are individually addressable, diffable, and linkable.
- **Pros:** Entries never need to be moved or re-parsed during archival.
  Any subset of the store can be assembled on demand (e.g., "last 90 days
  of CUSTOMER_NOTES.md"). IDs are inherently unique if hash-based.
  Excellent long-term model for a register that grows indefinitely.
- **Cons:** All five existing registers must be migrated to the new
  per-entry layout; every existing consumer script must be rewritten to
  call the new store tooling rather than reading a flat file. The canonical
  path becomes a generated artifact rather than an authoritative source,
  which inverts the current flat-file-is-canonical constraint. Migration
  risk is high and the assembly pipeline introduces a new failure mode
  (stale generated view). Agent and operator mental model changes
  significantly.
- **When C wins:** the project has accepted that flat files are not the
  long-term authoritative format, tooling investment is explicitly in
  scope, and the team has bandwidth for a full per-entry migration.
  The standing constraint ("flat files canonical") explicitly rejects this
  model.

---

## Decision outcome

**Chosen option: S — Date-quarter sharding**

Option M provides no structural bound; it relies on discipline that has
already failed in practice (observed register sizes up to 531 KB). Option C
inverts the flat-file-canonical standing constraint and requires full
migration of all consumers; the constraint is binding and Option C is
therefore out of scope. Option S preserves canonical paths, provides a
structural bound on the active file's size, is consistent with the
flat-file-canonical constraint (shards and index are still plain Markdown
flat files), and requires only additive changes to consumer scripts.

---

## Customer ruling

**2026-06-03 — Option S (date-quarter sharding) adopted** for issue #295.

This is the sole ruling recorded in this ADR. The ruling covers the choice
of sharding approach (S over M). Implementation details within Option S
(script interfaces, index schema, CI gate threshold) are design
decisions within the adopted option and do not require separate rulings.

---

## Design: date-quarter sharding (Option S)

### 1. File topology

For each of the five registers:

```
<register>.md                   ← active rolling file; current quarter only; CANONICAL PATH UNCHANGED
<register>-YYYY-QN.md           ← immutable shard for one closed quarter
<register>-INDEX.md             ← generated; table of all shards + active file
```

Examples for `docs/OPEN_QUESTIONS.md`:

```
docs/OPEN_QUESTIONS.md                ← active (2026-Q3 and later)
docs/OPEN_QUESTIONS-2025-Q4.md        ← closed shard
docs/OPEN_QUESTIONS-2026-Q1.md        ← closed shard
docs/OPEN_QUESTIONS-2026-Q2.md        ← closed shard
docs/OPEN_QUESTIONS-INDEX.md          ← generated index
```

The index schema (same for all five registers):

| Shard | Date range | Entry count | Notes |
|---|---|---|---|
| `OPEN_QUESTIONS-2025-Q4.md` | 2025-10-01 – 2025-12-31 | 47 | Initial backlog |
| `OPEN_QUESTIONS-2026-Q1.md` | 2026-01-01 – 2026-03-31 | 63 | |
| `OPEN_QUESTIONS-INDEX.md` is excluded from the table (it is the table). |

The active file (`<register>.md`) always appears as the final row:

| Shard | Date range | Entry count | Notes |
|---|---|---|---|
| `OPEN_QUESTIONS.md` *(active)* | 2026-Q3 – present | (live count) | Current quarter |

Shard files are immutable once rolled: no entries are added to or
removed from a closed shard. All new entries go to the active file.

### 2. Quarter-roll driver: scripts/archive-registers.sh

`scripts/archive-registers.sh` is extended (from its prior archival
purpose) to serve as the quarter-roll driver. Invoked by `librarian` at
quarter end:

1. For each register: rename `<register>.md` to `<register>-YYYY-QN.md`
   (using the quarter just ended).
2. Create a fresh empty `<register>.md` with the appropriate header for
   the new quarter.
3. Call `scripts/gen-register-index.sh` to regenerate all index files.

The script is idempotent: re-running after a partial failure produces the
same result. It does not auto-fire; `librarian` must invoke it explicitly.

### 3. Index generation: scripts/gen-register-index.sh

`scripts/gen-register-index.sh` reads the shard files in date order and
writes (or overwrites) each `<register>-INDEX.md`. It:

- Counts entries in each shard (by heading count for CUSTOMER_NOTES.md,
  by non-header table-row count for the other four).
- Determines the date range from entry content.
- Writes the index table.

The index is a derived artifact; it is checked in but regenerated on every
quarter roll and can be regenerated at any time without data loss.

### 4. Consumer-script impact

The following scripts interact with registers and are affected by sharding:

| Script | Impact | Change required |
|---|---|---|
| `scripts/customer-notes-guard.py` | Reads `CUSTOMER_NOTES.md` by canonical name | **No change.** The canonical path is preserved; guard reads only the active file, which is always at the canonical path. Cross-shard coverage is not required for this guard's function (it enforces structural format, not historical completeness). |
| `scripts/lint-questions.sh` | Reads `docs/OPEN_QUESTIONS.md` for format/atomicity lint | **No change** for current-turn linting. If a future requirement mandates cross-shard atomicity checking, a `--all-shards` flag is added then. |
| `scripts/check-duplicate-ids.sh` | Checks IDs for uniqueness within a register | **Must be extended** with cross-shard awareness. After sharding, uniqueness must be verified across all shards plus the active file. The script reads the index to discover shard paths, then checks each. |
| `scripts/reserve-number.sh` | Claims the next available sequential ID | **Must be extended** with cross-shard awareness. The highest existing ID across all shards determines the next available number. Script reads the index, scans all shards, then writes the new placeholder to the active file. |
| `scripts/intake-show.sh` | Looks up a specific intake-log entry by ID or date | **Must be extended** with cross-shard lookup. After sharding, the target entry may be in any shard. Script reads the index to identify the candidate shard (by date range), then searches that shard. |

The three scripts requiring cross-shard extension (`check-duplicate-ids.sh`,
`reserve-number.sh`, `intake-show.sh`) must be updated before the first
quarter roll is performed. `customer-notes-guard.py` and
`lint-questions.sh` require no changes.

### 5. CI size-gate backstop

A CI check (`scripts/check-register-sizes.sh`) fails the build if any
active register file exceeds **150 KB**. This is a backstop: in a healthy
sharding regime the active file stays well below 150 KB throughout the
quarter. If it approaches the gate before quarter end, `librarian` may
perform a mid-quarter roll (creating a `YYYY-Q1a` / `YYYY-Q1b` pair) or
selectively move resolved-and-stable entries to a shard early.

The 150 KB gate applies only to the active `<register>.md`. Shard files
and index files are exempt (they are immutable or derived).

### 6. Migration

Existing downstream projects with bloated registers run a one-time
migration before adopting quarter sharding:

**Shape A — CUSTOMER_NOTES.md** (entries are `## YYYY-MM-DD` heading sections):

The migration script identifies the date of each heading, groups headings
into calendar-quarter buckets, and writes each bucket to its corresponding
`CUSTOMER_NOTES-YYYY-QN.md` shard. The active file receives only entries
from the current calendar quarter.

**Shape B — OPEN_QUESTIONS.md, intake-log.md, RISKS.md, LESSONS.md**
(entries are Markdown table rows with a `Date` column):

The migration script reads the Date column of each row, groups rows into
calendar-quarter buckets, and writes each bucket (with the table header) to
its corresponding `<register>-YYYY-QN.md` shard. The active file receives
only rows from the current calendar quarter.

Both shapes are handled by `scripts/migrate-registers.sh`. The migration
is idempotent and dry-run safe (`--dry-run` flag prints the proposed
shard layout without writing). After migration, `gen-register-index.sh`
generates all index files.

### 7. Co-delivery with #292

Issue #292 addresses CUSTOMER_NOTES.md structural integrity (heading
format validation, malformed-entry detection). The migration script for
Shape A is designed to share its heading-parser with the integrity check
introduced in #292. Where the two changes touch the same code paths,
they are co-delivered in a single PR to avoid duplicating the parser
logic.

---

## Consequences

### Positive

- Active register files are bounded to a single calendar quarter's entries;
  context-window overflow from register reads is eliminated for any project
  that runs its quarter rolls on schedule.
- Canonical paths are unchanged; no agent contract or operator procedure
  needs updating for the path rename.
- Shard files are plain Markdown and remain readable without tooling; the
  index provides structured discovery.
- The CI 150 KB gate provides an objective early-warning signal before
  context overflow occurs.
- The Shape A / Shape B parser split in the migration script covers all
  five registers without a bespoke per-register approach.
- Co-delivery with #292 eliminates parser duplication for CUSTOMER_NOTES.md.

### Negative / trade-offs accepted

- Cross-shard ID-uniqueness and lookup require changes to three consumer
  scripts before the first quarter roll. If those changes are incomplete
  at roll time, duplicate IDs become possible (a correctness defect, not
  merely a hygiene issue).
- The `gen-register-index.sh` index is a derived artifact that must be
  regenerated after every roll. A stale index causes `check-duplicate-ids.sh`
  and `reserve-number.sh` to miss historical shards. Mitigation: the
  quarter-roll driver always calls `gen-register-index.sh` as its final step.
- Mid-quarter manual rolls (triggered by the CI gate) produce non-standard
  shard names (`YYYY-Q1a`). These are valid but outside the standard naming
  convention; `gen-register-index.sh` must accept them.
- Migration of a 531 KB CUSTOMER_NOTES.md with hundreds of dated headings
  is mechanical but potentially slow for very large files. The dry-run
  flag and idempotency mitigate migration risk.

### Follow-up ADRs

- No immediate follow-up ADR is triggered. If the 150 KB gate proves too
  coarse (e.g., a single quarter's entries consistently approach it), a
  follow-up ADR may evaluate monthly sharding.

---

## Verification

- **Success signal:** After one complete quarter roll on a downstream
  project, the active `<register>.md` files are below 50 KB. `git log
  --stat` on the post-roll commit shows the new shard files and a
  truncated (small) active file. `check-duplicate-ids.sh --all-shards`
  exits 0. `gen-register-index.sh` produces a correct index table for
  all five registers.
- **Failure signal (size):** The CI 150 KB gate fires on a post-roll
  branch, indicating the current quarter's volume exceeds the target
  and a mid-quarter split is needed.
- **Failure signal (uniqueness):** `check-duplicate-ids.sh --all-shards`
  finds an ID in a closed shard that also appears in the active file.
  This indicates the cross-shard extension was missing at roll time.
- **Failure signal (lookup):** `intake-show.sh` returns not-found for
  an ID that exists in a closed shard. This indicates the cross-shard
  lookup extension was missing.
- **Failure signal (index drift):** `gen-register-index.sh` reports a
  shard file on disk whose entry count does not match the index. This
  indicates the index was not regenerated after a roll.
- **Review cadence:** Re-examine after the first two quarter rolls on an
  active downstream project. If the 150 KB gate fires before quarter end
  on two consecutive quarters, open a follow-up ADR on monthly sharding
  or a tighter gate.

---

## Links

- Issue #295 — register bloat report (root trigger for this ADR)
- Issue #292 — CUSTOMER_NOTES.md structural integrity (co-delivery overlap;
  heading parser shared with migration Shape A)
- `scripts/archive-registers.sh` — quarter-roll driver (extended by this ADR)
- `scripts/gen-register-index.sh` — index generator (new; introduced by this ADR)
- `scripts/migrate-registers.sh` — one-time migration script for Shape A/B
- `scripts/check-register-sizes.sh` — CI 150 KB size-gate (new)
- `scripts/check-duplicate-ids.sh` — cross-shard extension required
- `scripts/reserve-number.sh` — cross-shard extension required
- `scripts/intake-show.sh` — cross-shard lookup extension required
- `scripts/customer-notes-guard.py` — no change required
- `scripts/lint-questions.sh` — no change required

---

## Change log

- 2026-06-03 — Initial draft and acceptance (architect); Option S adopted per customer ruling.
