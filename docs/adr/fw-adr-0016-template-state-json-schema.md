---
name: fw-adr-0016-template-state-json-schema
description: Defines TEMPLATE_STATE.json — the single project-owned state artefact that consolidates TEMPLATE_VERSION, TEMPLATE_MANIFEST.lock, .template-customizations, and the per-ref runner checksum pin into one declarative file. Schema, classes, migration shape, validation posture, and lifecycle rules. Required follow-up to FW-ADR-0015.
status: accepted
date: 2026-05-15
---


# FW-ADR-0016 — `TEMPLATE_STATE.json` schema (single project-owned state artefact)

<!-- TOC -->

- [Status](#status)
- [Context and problem statement](#context-and-problem-statement)
- [Decision drivers](#decision-drivers)
- [Considered options (Three-Path Rule, binding)](#considered-options-three-path-rule-binding)
  - [Option M — Minimalist: single JSON file](#option-m--minimalist-single-json-file)
  - [Option S — Scalable: retain three files with a stronger invariant gate](#option-s--scalable-retain-three-files-with-a-stronger-invariant-gate)
  - [Option C — Creative: no project state — recompute every upgrade](#option-c--creative-no-project-state--recompute-every-upgrade)
- [Decision outcome](#decision-outcome)
- [Interface decisions (binding)](#interface-decisions-binding)
  - [Top-level shape and field names](#top-level-shape-and-field-names)
  - [Schema-version field semantics](#schema-version-field-semantics)
  - [Path-class enum](#path-class-enum)
  - [Per-path declaration shape](#per-path-declaration-shape)
  - [Runner-pin lifecycle](#runner-pin-lifecycle)
  - [Migration function shape (from the three legacy artefacts)](#migration-function-shape-from-the-three-legacy-artefacts)
  - [Schema validation contract](#schema-validation-contract)
  - [Concurrency and atomic-write semantics](#concurrency-and-atomic-write-semantics)
  - [Backwards-compat read window](#backwards-compat-read-window)
- [Consequences](#consequences)
  - [Positive](#positive)
  - [Negative / trade-offs accepted](#negative--trade-offs-accepted)
  - [Follow-up ADRs](#follow-up-adrs)
- [Verification](#verification)
- [Implementation notes for software-engineer](#implementation-notes-for-software-engineer)
- [Open questions](#open-questions)
- [Links](#links)

<!-- /TOC -->

Shape per MADR 3.0 + this template's Three-Path Rule
(`docs/templates/adr-template.md`). This ADR sits directly under
FW-ADR-0015 in the upgrade-flow rearchitecture sequence; its
acceptance unblocks FW-ADR-0017 (file-keyed migration discovery)
and FW-ADR-0018 (migration path for deployed downstreams). Cap
~500 lines.

---

## Status

- **Proposed: 2026-05-15**
- **Accepted: 2026-05-15**
- **Deciders:** `architect` + `tech-lead` + customer (data-model
  change to the upgrade contract; consolidates two existing public
  artefacts and one operator-managed file; customer approval per
  CLAUDE.md Hard Rules).
- **Consulted:** FW-ADR-0015 (foundation; this ADR completes the
  state-artefact half of that foundation), FW-ADR-0002 (manifest
  verification contract this ADR inherits), FW-ADR-0014 (Q1
  preservation gate this ADR retires; Q2 two-phase exit unchanged),
  `security-engineer` (runner-pin lifecycle is a security-posture
  surface), `qa-engineer` (schema validation tests),
  `software-engineer` (migration-function implementation).

## Context and problem statement

FW-ADR-0015 pivoted the framework to a stub-and-runner model and
named `TEMPLATE_STATE.json` as the single project-owned state
artefact the runner reads at sync entry and writes at sync exit.
That foundation ADR declared the artefact's existence and named
its consumers; this ADR defines its **schema** — field names,
types, classes, lifecycle, validation, migration.

The current model splits project state across three files:

- `TEMPLATE_VERSION` — three-line text (semver / SHA / scaffold-date),
  human-edited freely.
- `TEMPLATE_MANIFEST.lock` — FW-ADR-0002 hash manifest, machine-written.
- `.template-customizations` — operator-managed preserve list.

These three files cannot be guaranteed consistent at runtime. The
manifest writer and the preserve-list writer are different code
paths invoked at different times; the stamp is hand-editable.
FW-ADR-0014 added a runtime preservation classifier to arbitrate
manifest-vs-preserve disagreement, but the arbitration is an
emergent property of three independent inputs — when one drifts,
the gate fires unreliably. The 2026-05-15 dogfood evidence
(`docs/pm/dogfood-2026-05-15-results.md`) showed the rule firing
on legitimate state as well as on bug state; the gate's signal-to-
noise dropped to the point where operators reflexively bypassed it.

The conceptual fix is structural: one declaration of project
state, indexed by path. A path's class (managed / customised /
project-owned) and its content hash live on the same row;
"customised path with a manifest entry" becomes syntactically
impossible. Additionally, FW-ADR-0015 NB-2/NB-4 require a per-ref
runner-checksum pin (TOFU on first observation; re-pin on
operator action); the natural home for that pin is also project
state. Consolidating onto one file removes the three-source-of-
truth class entirely.

ADR-trigger rows that fire: data-model change (schema replaces
three artefacts); cross-cutting pattern change (preservation
becomes a per-path declaration class, not a runtime arbitration);
public-API change (FW-ADR-0002 manifest contract evolves);
choice that locks the framework into a JSON-parsing dependency
in the runner.

## Decision drivers

- **Single source of truth.** Eliminate the manifest-vs-preserve
  race FW-ADR-0014 Q1 papered over. State lives in one file or it
  is not state.
- **Forward compatibility.** The schema must support clean v2.0+
  migration without invalidating v1.x downstreams. Schema-version
  field is the carrier.
- **Runner-pin lifecycle is part of project state.** FW-ADR-0015
  NB-2 (TOFU) and NB-4 (re-pin path) require a durable pin
  artefact; the natural home is `TEMPLATE_STATE.json`. A separate
  `RUNNER_PINS` file was rejected in FW-ADR-0015 § Integrity
  verification posture; that rejection lands here as the
  inclusion of the pin in the consolidated file.
- **Customisation-overrides-manifest invariant becomes
  syntactic.** Per-path declaration carries both class and hash;
  a path cannot be both classes at once. The "customisation wins"
  commitment in `docs/framework-project-boundary.md` is preserved
  by construction, not by runtime arbitration.
- **Idempotent migration.** Transitional rc (FW-ADR-0018) writes
  the new file once; re-runs are no-ops. The migration function
  must be definable independent of the bridging-rc body.
- **JSON parsing dependency in the runner.** The runner takes a
  dependency on a JSON parser (`jq` or `python3 -m json.tool`,
  with feature-detection). The stub does not parse the file;
  reading/writing is runner-owned. Stays consistent with
  FW-ADR-0015's sub-100-line stub budget.

## Considered options (Three-Path Rule, binding)

### Option M — Minimalist: single JSON file

A single project-root JSON file (`TEMPLATE_STATE.json`)
consolidating template version, runner pin, and per-path
declarations. The runner reads it at sync entry, writes it
atomically at sync exit. Preservation, manifest, and stamp
collapse into one structured artefact. The three legacy files
are removed after the bridging-rc migration (FW-ADR-0018)
completes; backwards-compat reading of the legacy trio is
supported only during the transitional rc.

- **Sketch:** Top-level fields `schema_version`, `template`
  (version/ref/dates), `runner_pin` (target_ref / sha256 /
  pinned_at / pinned_by), `paths` (array of per-path
  declarations with `path` / `class` / `hash` / `source_ref`).
  Migration function reads existing `TEMPLATE_VERSION` +
  `TEMPLATE_MANIFEST.lock` + `.template-customizations` and
  emits the consolidated file; idempotent.
- **Pros:**
  - Eliminates the three-source-of-truth class
    (manifest-vs-preserve-vs-stamp).
  - "Customisation wins" becomes syntactically enforced —
    a path's row carries class + hash on the same record.
  - Forward-compat: `schema_version` field allows clean v2.0
    bump without invalidating v1.x readers.
  - Runner-pin lifecycle (TOFU + re-pin) has a natural home.
  - JSON is parser-rich (jq, python3, awk-with-care); operators
    can read it without framework tooling.
  - Audit trail: a single `git diff TEMPLATE_STATE.json` answers
    "what template-managed files moved between these two
    upgrades?" at a glance.
- **Cons:**
  - One-time migration cost (FW-ADR-0018 bridging rc); every
    currently-deployed downstream retrofits.
  - Runner takes a JSON-parser dependency. Mitigated by jq +
    python3 feature-detection; both are present on operator
    machines that already host bash and curl. Air-gapped /
    minimal-system operators ruled out of scope per customer
    2026-05-15.
  - "JSON in bash" has a culture cost; the runner-side parsing
    code grows a small helper layer. Acceptable: the runner is
    the right place for that complexity (see FW-ADR-0015 § stub
    budget — the stub does not parse, the runner does).
- **When M wins:** when the failure pattern's root cause is
  multiple-source-of-truth (it is) and the consolidation is
  reversible at acceptable cost if the schema decision is
  wrong (it is — re-emitting the three legacy files from the
  consolidated file is a trivial inverse). Customer's FW-ADR-0015
  ruling implicitly authorises this path — the foundation ADR
  names this artefact as load-bearing.

### Option S — Scalable: retain three files with a stronger invariant gate

Keep the three legacy files; harden the runtime gate that
arbitrates them. Add a fourth file (`RUNNER_PINS`) for the
checksum-pin lifecycle. The invariant gate is implemented as a
mandatory pre-sync verification step that aborts on any
detected inconsistency; operator-actionable error messages
direct repair.

- **Sketch:** Pre-sync invariant check walks the three files,
  flags any path appearing in both manifest and preserve-list,
  any path on disk not represented, any stamp/manifest version
  mismatch. The check is the gate; failure aborts the upgrade
  with an actionable diff. `RUNNER_PINS` is parsed separately.
- **Pros:**
  - Zero migration cost — three legacy artefacts remain.
  - Smaller blast radius if the new shape is wrong.
  - Operators familiar with the legacy artefacts keep their
    muscle memory.
- **Cons:**
  - The "stronger invariant gate" is what FW-ADR-0014 Q1 already
    is. The dogfood evidence is that the gate's signal-to-noise
    drops below operator-trust thresholds when it fires on
    legitimate state. Strengthening it raises the false-positive
    cost; weakening it returns to FW-ADR-0014's failure mode.
  - Three files (now four with `RUNNER_PINS`) is more surface to
    keep consistent, not less.
  - "Customisation wins" remains a runtime arbitration; structural
    invariants are weaker.
  - The FW-ADR-0015 NB-4 re-pin path adds operator-facing
    machinery on a fourth file with its own concurrency
    semantics.
- **When S wins:** if the migration cost (FW-ADR-0018) is
  prohibitively high and the runtime gate can be tuned to
  acceptable false-positive rates. The 2026-05-15 evidence
  argues neither holds.

### Option C — Creative: no project state — recompute every upgrade

The project stores no template-state at all. Every upgrade run
recomputes the answers it needs from the project tree itself:
manifest hashes are recomputed live, customisation is inferred
from `git diff` against a recomputed baseline, runner pin is
derived from cross-referencing the operator's `--target` with a
fresh upstream fetch (no local pin).

- **Sketch:** `TEMPLATE_VERSION` survives as a one-line ref
  pointer (informational only). All other state is derived per
  upgrade. The runner fetches the target's baseline tree,
  hashes it, diffs against the project tree, classifies each
  path by diff presence.
- **Pros:**
  - Zero schema surface; nothing to maintain, nothing to
    migrate.
  - "What is this project's state?" becomes a pure function of
    `(project_tree, upstream_ref)`.
  - Survives accidental state-file deletion gracefully.
- **Cons:**
  - O(2 × network fetch + full-tree-hash) per upgrade. CI cost
    rises sharply.
  - Customisation inference is heuristic — "the operator
    edited this file vs the file was generated this way" is
    not reliably distinguishable without an intent declaration.
    The preserve-list exists precisely to declare intent.
  - Runner-pin lifecycle has no durable home; TOFU and re-pin
    cannot survive between sessions without a pin file. Falls
    back to a per-invocation trust decision — strictly weaker
    than FW-ADR-0015's NB-2/NB-4 posture.
  - Customer's recorded posture (`CUSTOMER_NOTES.md` 2026-05-15
    L348) requires per-ref checksum pinning persisted in
    `TEMPLATE_STATE.json`. Option C contradicts the customer
    ruling directly.
- **When C wins:** if the customer's security posture were
  weaker (no pin required) and the network cost were acceptable.
  Neither holds.

## Decision outcome

**Chosen option: M (single JSON file, `TEMPLATE_STATE.json`).**

**Reason:** Option M is the only option that consolidates the
three-source-of-truth class into one declaration AND honours the
customer's runner-pin posture (FW-ADR-0015 NB-2/NB-4) by giving
the pin a durable home. The FW-ADR-0015 foundation already names
this artefact as load-bearing; this ADR completes the foundation
by defining the schema. Option S preserves the failure pattern
the dogfood evidence identified (signal-to-noise on the runtime
gate). Option C contradicts the customer's pin-persistence
ruling directly. Migration cost (one transitional rc per
FW-ADR-0018) is bounded; the schema-version field carries
forward compatibility cleanly.

## Interface decisions (binding)

### Top-level shape and field names

The artefact is a single JSON object at project root
(`TEMPLATE_STATE.json`). UTF-8 encoded, LF line endings, trailing
newline. Field names use `snake_case`. Top-level keys are
ordered for human readability (writers MUST emit them in this
order; readers MUST NOT depend on order):

```json
{
  "schema_version": "1.0.0",
  "template": {
    "version": "v1.0.0-rc14",
    "ref": "<40-char-commit-sha>",
    "scaffolded_at": "2026-05-15",
    "synced_at": "2026-05-15"
  },
  "runner_pin": {
    "target_ref": "v1.0.0-rc14",
    "runner_sha256": "<64-hex-char-sha256>",
    "pinned_at": "2026-05-15",
    "pinned_by": "tofu"
  },
  "paths": [
    {
      "path": "scripts/upgrade.sh",
      "class": "managed",
      "hash": "<64-hex-char-sha256>",
      "source_ref": "<40-char-commit-sha>"
    },
    {
      "path": "AGENTS.md",
      "class": "customised",
      "hash": "<64-hex-char-sha256>",
      "source_ref": "<40-char-commit-sha>"
    }
  ]
}
```

Field semantics:

- `schema_version` (string, semver) — see § Schema-version field
  semantics. Required.
- `template.version` (string) — human-readable template version
  the project last synced to. Mirrors the v1.0.x stamp's first
  line. Required. **Schema v1.0.0 leaves `template.version` as a
  free string by intent — no format constraint (semver, rc tag,
  branch name are all accepted). `template.ref` carries identity;
  `template.version` is a label for operator readability. A future
  MINOR may add format validation if a constraint becomes useful.**
- `template.ref` (string, 40-char hex SHA) — the upstream commit
  SHA the project last synced to. Authoritative; `template.version`
  is a label, `template.ref` is the identity. Required.
- `template.scaffolded_at` (string, ISO-8601 date) — date the
  project was originally scaffolded. Set once at scaffold time;
  never rewritten. Required.
- `template.synced_at` (string, ISO-8601 date) — date of the most
  recent successful sync. Rewritten on every successful upgrade.
  Required.
- `runner_pin` (object) — present after the first successful
  runner fetch; absent on a freshly-scaffolded project before
  the first upgrade. Optional at scaffold time; required after
  first sync. See § Runner-pin lifecycle.
- `paths` (array of objects) — per-path declarations. Sorted
  ascending by `path` for deterministic diffs. Empty array is
  valid (a project tree with no managed paths is degenerate but
  representable). Required.

### Schema-version field semantics

- `schema_version` is a string holding a semver value
  (`MAJOR.MINOR.PATCH`).
- Readers MUST parse the field and:
  - Accept any version where MAJOR matches the reader's
    supported MAJOR.
  - Reject (abort with a clear error) any version where MAJOR
    is greater than the reader's supported MAJOR.
  - Accept-with-`WARN` any version where MAJOR is less than the
    reader's supported MAJOR. (A reader for v2 schema can read
    v1 data via the migration function defined here.)
- Writers MUST emit the highest MAJOR.MINOR they support.
- MINOR bumps add fields; readers MUST tolerate unknown fields
  (forward-compat through additive evolution).
- **Silent MINOR upgrade on next state-mutating sync.** When a
  runner at schema v1.x reads a file at an older v1 MINOR, it
  silently upgrades the file by re-emitting it at the runner's
  highest supported MINOR on the next state-mutating sync. No
  WARN log; no operator action required. The only schema-version
  event that surfaces to the operator is the MAJOR-reject case
  above. (Customer ruling, 2026-05-15.)
- PATCH bumps are reserved for documentation / clarification
  changes that do not alter the wire format. Readers MUST NOT
  `WARN` on PATCH-only differences (in either direction);
  PATCH mismatches are accepted silently. The MAJOR-reject rule
  does not propagate to PATCH by analogy.
- A clean v2.0 migration ships with a new ADR (FW-ADR-NNNN)
  that defines the v1 → v2 migration function. The runner for
  the v2 cliff carries both readers and writes v2; older
  runners reject v2 with `schema_version > supported`. This is
  the same migration pattern FW-ADR-0018 establishes for
  v0/legacy → v1.

Initial value at this ADR's acceptance: `"1.0.0"`.

### Path-class enum

`class` is a string from a closed enum:

| Value           | Meaning                                                                                   |
|-----------------|-------------------------------------------------------------------------------------------|
| `managed`       | Path ships from upstream. Upgrades overwrite it. Hash MUST match upstream-at-`source_ref`.|
| `customised`    | Path was originally template-shipped but the project has declared permanent customisation. Upgrades preserve it. Hash records on-disk state at the customise transition; `source_ref` records the ref at which the path was last classified `managed`. |
| `project-owned` | Path is not template-shipped and never has been. Project owns it entirely; upgrades ignore it. Recorded in state for audit completeness, not for upgrade logic. |

A path has exactly one class at any time. Transition `managed →
customised` is a deliberate operator action (see FW-ADR-0018 for
the transition mechanic). Transition in the other direction is
not supported in v1.x; an operator who wants to give up
customisation rolls the path back manually and removes the row
or re-classifies it via a documented procedure (defined in
FW-ADR-0018, not here).

Class transitions involving `project-owned` (i.e., `managed →
project-owned` when an operator renames or repurposes a
previously-template-shipped path, and `customised →
project-owned` for the same rename / repurpose case) are
deferred to FW-ADR-0018's transition mechanic. The v1.0.0
migration function does not synthesise `project-owned` rows
(see § Migration function shape), so these transitions are
benign for v1.0.0 acceptance but must be addressed when
FW-ADR-0018 pins the transition mechanic.

`project-owned` is **new** relative to the legacy three-file
model and is **opt-in** in schema v1.0.0 (customer ruling,
2026-05-15). The runner emits ONLY `managed` and `customised`
rows in `paths`. The runner does not walk the project tree and
does not synthesise `project-owned` rows. Operators MAY manually
add `project-owned` rows for paths they want covered by audit;
the runner preserves operator-added `project-owned` rows on
subsequent syncs but never synthesises them. Sync-time
complexity is bounded by manifest size, not project-tree size
(O(manifest), not O(project-tree)); the state file stays bounded.
A future MINOR bump (1.x.0) may promote `project-owned` rows to
runner-emitted if the audit benefit justifies the file-size and
tree-walk cost.

### Per-path declaration shape

Each element of `paths` is an object:

- `path` (string) — project-root-relative POSIX path. Forward
  slashes; no leading `./`; no trailing slash. Required.
- `class` (string, enum above) — required.
- `hash` (string, 64-hex-char sha256) — sha256 of the on-disk
  file content at the last sync. Required for `managed` and
  `customised`; OMITTED for `project-owned` (the framework does
  not track project-owned content).
- `source_ref` (string, 40-char hex SHA) — the upstream commit
  SHA where this path was last `managed`-class. For `managed`
  rows: the ref the hash matches. For `customised` rows: the
  ref at the customisation transition. OMITTED for
  `project-owned`. Required where present.

Validators MUST reject:

- Two rows with identical `path`.
- A row where `class` is outside the enum.
- A row where `hash` or `source_ref` is the wrong length / wrong
  character set.
- A `managed` or `customised` row missing `hash` or `source_ref`.
- A `project-owned` row carrying `hash` or `source_ref`.
- A `runner_pin.pinned_by` value outside the closed enum
  `{tofu, explicit}`. A typo such as `manual` or `ci` MUST fail
  validation, not be silently accepted as an opaque string.

### Runner-pin lifecycle

Implements FW-ADR-0015 NB-2 (TOFU) + NB-4 (re-pin path) +
customer ruling 2026-05-15 (`CUSTOMER_NOTES.md` L348, "TLS and
checksum will be plenty").

- `runner_pin.target_ref` (string) — the `--target` value at
  which the pin was recorded. May be a tag, branch name, or
  short/full SHA, exactly as the operator supplied. Required.
- `runner_pin.runner_sha256` (string, 64-hex-char sha256) —
  sha256 of the runner content fetched at `target_ref`.
  Required.
- `runner_pin.pinned_at` (string, ISO-8601 date) — the date the
  pin was recorded. Required.
- `runner_pin.pinned_by` (string, enum) — provenance of this
  pin record. Enum:
  - `tofu` — first observation of this `target_ref`; pinned
    automatically per FW-ADR-0015 NB-2.
  - `explicit` — operator ran `scripts/upgrade.sh --refresh-pin
    <target>` (or equivalent) to re-pin against newly-fetched
    content per NB-4.

**Lifecycle rules:**

1. First-ever upgrade after scaffold: `runner_pin` may be
   absent. The runner records it on first successful fetch
   with `pinned_by="tofu"`.
2. Subsequent upgrades against the same `target_ref`: the
   fetched content's sha256 MUST match `runner_pin.runner_sha256`.
   Mismatch fails with stub exit 10 (per FW-ADR-0015).
3. Subsequent upgrades against a different `target_ref`:
   TOFU applies again — the new ref's first observation pins
   automatically; the old pin is replaced (overwritten in
   place, single-`runner_pin` object). The new pin's
   `pinned_by` is `tofu`.
4. Operator re-pin (`--refresh-pin`): the new pin's
   `pinned_by` is `explicit`. Used when an upstream re-publish
   at a moving ref is legitimate (operator chose to accept the
   new content).

**CLI ownership of `--refresh-pin`:** this flag is
**runner-owned**, not stub-owned. The stub's frozen surface
(FW-ADR-0015 § stub freeze table) is not extended by this
ADR. The stub forwards `--refresh-pin` to the runner under
the FW-ADR-0015 unknown-flag-forwards rule; the runner parses
the flag, performs the fetch, validates the new content, and
rewrites `runner_pin` with `pinned_by="explicit"`. Mechanics
beyond this ownership boundary are pinned in
FW-ADR-0015-impl / FW-ADR-0016-impl, not in this ADR.

**Audit-trail decision:** the file carries the **current**
pin only. Historical pin moves are NOT retained in
`TEMPLATE_STATE.json`. Operators who want pin history rely on
`git log TEMPLATE_STATE.json`, which gives a per-commit
delta-readable audit trail for free. A separate pin-history
log is rejected as duplicate state and as a vector for
pin-history-vs-current-pin drift (the same class of bug this
whole ADR exists to retire).

### Migration function shape (from the three legacy artefacts)

The migration function is invoked by the FW-ADR-0018 bridging
rc on first run. Its shape is defined here so FW-ADR-0017 and
FW-ADR-0018 can build on it without re-deriving classification
logic.

**Inputs:**

- `TEMPLATE_VERSION` (existing 3-line text file at project root):
  semver, SHA, scaffold date.
- `TEMPLATE_MANIFEST.lock` (existing FW-ADR-0002 manifest at
  project root): line-oriented `<sha256>  <path>` rows.
- `.template-customizations` (existing preserve list at project
  root): line-oriented paths; `#` comments; blank lines.

**Output:** a single `TEMPLATE_STATE.json` at project root
conforming to schema v1.0.0.

**Classification rules:**

- A path appears in `TEMPLATE_MANIFEST.lock` AND NOT in
  `.template-customizations` → class `managed`. `hash` from the
  manifest row; `source_ref` from `TEMPLATE_VERSION` line 2.
- A path appears in `.template-customizations` → class
  `customised`. `hash` computed from on-disk content at
  migration time; `source_ref` from `TEMPLATE_VERSION` line 2
  (the ref at which it was last managed before the operator
  declared it customised). For paths appearing in BOTH the
  manifest and the preserve list (the FW-ADR-0014 Q1 race
  state — a legitimate input shape), `customised` wins. This
  cements the "customisation overrides manifest" rule the
  legacy gate arbitrated at runtime.
- `project-owned` rows are NOT synthesised by the migration
  function. The migration does not walk the project tree; it
  only translates the existing declarative inputs. Operators
  who want `project-owned` rows for audit completeness add
  them in a follow-up MINOR bump or via a separate tool.

**Idempotency:** re-running the migration function on a
project that already has a valid `TEMPLATE_STATE.json` is a
no-op (the function detects the file's presence and exits 0
without writing). Re-running on a project with both the new
file AND the legacy trio cleans up the legacy trio (the
bridging-rc behaviour; see FW-ADR-0018). This ADR specifies
the migration shape; FW-ADR-0018 owns the bridging-rc
operator UX. Idempotency in this ADR's scope is
**single-input-class** (either the legacy trio xor the new
file is present). The **dual-input-class** state (both the
new file and the legacy trio present on disk simultaneously)
is FW-ADR-0018's bridging-rc concern; its semantics — which
inputs to trust when they disagree — are pinned there, not
here.

**Failure modes the migration MUST handle:**

- `TEMPLATE_VERSION` missing or malformed: abort with clear
  error; do not synthesise a state file. Operator follows the
  scaffold-from-scratch path.
- `TEMPLATE_MANIFEST.lock` missing: legitimate for pre-v0.14.0
  projects. Migration writes a `paths` array with only
  `customised` rows (from `.template-customizations`); next
  successful upgrade re-bakes `managed` rows from the upstream
  tree. The runner's post-migration sync step handles the
  re-bake (analogous to FW-ADR-0002's pre-v0.14.0 case).
- `.template-customizations` missing: legitimate for pre-v0.13.0
  projects. Migration writes a `paths` array with only
  `managed` rows.
- Conflicting input (path appears in BOTH manifest and
  preserve list): `customised` wins, no warning. The race
  state was the bug; promoting `customised` is the fix.
- Malformed `.template-customizations` entries: the current
  format is line-oriented paths plus `#` comments plus blank
  lines. The migration MUST tolerate-with-`WARN` the following
  noise shapes: UTF-8 BOM at file head, CRLF line endings,
  trailing whitespace on otherwise valid path lines, comment
  and blank lines. The migration MUST abort with a clear error
  on unparseable lines that look like paths but cannot be
  cleanly resolved: lines containing embedded whitespace that
  is not trailing, lines containing shell metacharacters (`$`,
  `` ` ``, `;`, `&`, `|`, `>`, `<`, `*`, `?`, `[`), and lines
  naming a path that resolves to a directory rather than a
  file. Rationale: the migration runs ONCE per downstream
  during the FW-ADR-0018 bridging rc; tolerant-of-noise plus
  fail-fast-on-ambiguity is the posture that preserves operator
  trust without silently misclassifying paths.

### Schema validation contract

The runner ships a JSON Schema document at
`docs/schemas/template-state.schema.json` (project-relative,
template-managed path). The runner validates
`TEMPLATE_STATE.json` against this schema on read; validation
failure is a fatal runner error (exit code owned by the runner
per FW-ADR-0015 § Failure modes; not the stub's exit 10/11/12).
Writes pass through the same validator before atomic rename
(see § Concurrency).

The schema document is itself schema-versioned. The runner at
a given upstream ref carries the schema for the MAJOR version
it supports plus the migration function for the previous MAJOR.

`software-engineer` implements the schema file as part of the
FW-ADR-0016 implementation work; this ADR specifies the
content (the prose above), not the JSON Schema body. A
follow-up FW-ADR or a directly-included `software-engineer`
artefact captures the wire shape.

**Rejected alternative:** schema-as-prose-only (no machine
validator). Rejected because the failure mode this ADR retires
(silent state drift) is exactly the failure mode a missing
machine validator preserves. The validator IS the gate.

### Concurrency and atomic-write semantics

- Single writer: only the runner writes `TEMPLATE_STATE.json`.
  Operators do not hand-edit it. (Operators MAY read it freely;
  `jq '.template.version' TEMPLATE_STATE.json` is a valid
  operator command.)
- The runner holds a sync session lock for the duration of the
  upgrade. Lock primitive: `flock` on a sibling lockfile
  (`.template-state.lock`, gitignored at scaffold). Two parallel
  runner invocations on the same project tree are detected and
  the second refuses with a clear error.
- Writes are atomic: write to `TEMPLATE_STATE.json.tmp` (same
  directory, for atomic-rename guarantees), `fsync`, then
  `mv -f` over the live file. Crash mid-write leaves the
  previous good state on disk. Crash after rename but before
  sync-session completion leaves the new state visible but the
  sync still incomplete — the next runner invocation detects
  the inconsistency via the lockfile + post-sync verification
  step (FW-ADR-0014 Q2 two-phase exit, which moves into the
  runner unchanged per FW-ADR-0015 § Inherits).

Sync-session step order (binding):

1. Acquire flock; refuse on contention.
2. Read `TEMPLATE_STATE.json`; validate against schema. Refuse
   on validation failure.
3. Perform the sync (file copy, manifest re-bake, customisation
   preservation per declarations).
4. Compute new state; validate against schema; refuse on
   validation failure (programmer-error guard).
5. Atomic-rename the new state into place.
6. Run phase-B verification (FW-ADR-0014 Q2; inherited into
   runner).
7. Release flock.

### Backwards-compat read window

The transitional rc (FW-ADR-0018) is the **only** release that
reads BOTH the legacy trio (`TEMPLATE_VERSION` +
`TEMPLATE_MANIFEST.lock` + `.template-customizations`) AND the
new `TEMPLATE_STATE.json`. Its sync writes the new file and
removes the legacy trio atomically (same rename window). After
the bridging rc, the runner reads only `TEMPLATE_STATE.json`;
legacy artefacts on disk after that point are operator-owned
project-state (no framework meaning).

This ADR does NOT specify how the transitional-rc behaves
operationally; that is FW-ADR-0018's mandate. The constraint
this ADR pins is: the new schema is reachable from the legacy
state via a single deterministic migration step.

## Consequences

### Positive

- The manifest-vs-preserve-list race retires. `class` is a per-
  path field; two-source-of-truth is structurally impossible.
- The customisation-overrides-manifest commitment becomes
  syntactic, not arbitrated.
- Runner-pin lifecycle has a durable home, satisfying
  FW-ADR-0015 NB-2/NB-4.
- One file to diff in `git log` for "what changed in this
  project's template state between commits X and Y".
- Forward-compat schema bumps are clean (FW-ADR-NNNN for v2.0).
- Operator audit: `jq '.paths[] | select(.class == "customised")
  | .path' TEMPLATE_STATE.json` answers "what is this project
  permanently overriding?" without framework tooling.
- FW-ADR-0014 Q1 (preservation gate) retires; FW-ADR-0002
  (manifest verification) folds inward — the manifest contract
  survives as the `paths` array, the verification semantics
  unchanged.

### Negative / trade-offs accepted

- One-time migration cost. Every currently-deployed downstream
  retrofits via FW-ADR-0018's bridging rc. Bounded at one
  upgrade cycle per downstream.
- Runner takes a JSON-parser dependency (`jq` or `python3`).
  Detected at runtime; clear error on absence. The stub's
  sub-100-line budget is preserved by keeping all parsing in
  the runner.
- "JSON in bash" growth in the runner's helper layer. Acceptable
  consolidation against the surface area being removed (three
  text-file parsers).
- `project-owned` rows are a new audit surface absent in the
  legacy model. Opt-in in v1.0.0 to bound the diff; promotable
  to required in a future MINOR if value emerges.
- Schema-version v2.0 migration story exists but is not
  pinned. Future architects ship FW-ADR-NNNN with the v1→v2
  migration function; the schema-version field is the carrier,
  not the answer. Symmetric to FW-ADR-0015's "stub v2 migration
  is deferred" trade-off.
- Single-current-pin (no in-file pin history) costs operators
  any pin-audit beyond `git log`. Accepted: `git log` is the
  durable audit; adding a second pin-history surface would
  reproduce the multi-source-of-truth bug this ADR retires.
- Operators who run `jq -i` or otherwise hand-edit
  `TEMPLATE_STATE.json` will fight the validator. The validator
  is the deliberate friction; operators who want to disable it
  use the FW-ADR-0015 `--no-verify` opt-out at their own risk.

### Follow-up ADRs

- **FW-ADR-0017 — File-keyed migration discovery.** Uses
  `template.ref` and the `paths` array's `source_ref` values to
  drive semver-ordered migration replay without consulting
  `git tag -l`. Depends on this ADR's schema.
- **FW-ADR-0018 — Migration path for currently-deployed
  downstreams.** Operationalises the migration function defined
  here as the bridging rc's first-run body. Depends on this
  ADR's schema + migration shape.
- **FW-ADR-0019 — Pre-bootstrap retirement.** Removes the
  legacy preservation gate (FW-ADR-0014 Q1) and the pre-bootstrap
  surfaces. Depends on this ADR landing first so the new state
  file is the single read target.

## Verification

How we know FW-ADR-0016 is correctly landed (after the bridging
rc per FW-ADR-0018 cuts):

- **Success signal A — file presence and schema conformance.**
  Every project upgraded through the bridging rc has a
  `TEMPLATE_STATE.json` at its root that passes
  `docs/schemas/template-state.schema.json` validation. The
  three legacy files (`TEMPLATE_VERSION`,
  `TEMPLATE_MANIFEST.lock`, `.template-customizations`) are
  absent or empty.
- **Success signal B — migration round-trip.** A test fixture
  representing each legacy state (clean, customised,
  accepted-local — fixtures already exist at
  `tests/release-gate/snapshots/v1.0.0-rc12/*`) migrates to a
  deterministic `TEMPLATE_STATE.json`; the result is identical
  across runs (idempotent); the synthesised content classifies
  every path the legacy artefacts implied.
- **Success signal C — pin lifecycle.** Sequential upgrades
  against the same `--target` reuse the pin without re-fetch
  noise; an upgrade against a new `--target` pins TOFU; an
  `--refresh-pin` invocation rewrites the pin with
  `pinned_by="explicit"`.
- **Success signal D — validator catches drift.** A
  hand-corrupted `TEMPLATE_STATE.json` (an operator runs
  `sed -i` against it) is rejected by the runner with a clear
  message and exits non-zero before any sync work.
- **Success signal E — git-log audit.** `git log
  TEMPLATE_STATE.json` on a project across three upgrade cycles
  shows three commit deltas; each delta is human-readable
  (jq-pretty-printed in commit messages, or readable from raw
  JSON).
- **Failure signal — schema validation fires on a legitimate
  project state.** A false positive of the validator is
  identical in shape to FW-ADR-0014 Q1's failure mode (gate
  loses operator trust). Routes to `architect` for schema
  revision; not a bypass.
- **Failure signal — operators report needing to hand-edit
  `TEMPLATE_STATE.json` regularly.** Indicates a missing
  declarative surface; promotes to a schema-MINOR addition (new
  field, new class) rather than tolerating hand-edits.
- **Review cadence:** at the first MINOR release after
  FW-ADR-0018 ships (when bridging-rc data accumulates from
  real downstreams), and again at six months post-bridge.

## Implementation notes for software-engineer

Scope for FW-ADR-0016-impl. The architect describes the
contract; the SE implements.

- **State-file location:** `TEMPLATE_STATE.json` at project
  root. UTF-8, LF, trailing newline. Sorted-keys at the
  top-level object are NOT required (writers MUST emit in the
  order specified above; readers MUST NOT depend on order);
  inner objects use insertion order. `paths` array is
  sorted ascending by `path`.
- **Schema file location:** `docs/schemas/template-state.schema.json`
  (template-managed; shipped to every project). JSON Schema
  draft-07 or later (SE picks the draft based on validator
  availability; `jq --slurpfile` + a small validator helper is
  acceptable; pure-`python3 -c` is acceptable; do not take a
  network-fetched validator dependency).
- **Validator pickup order:** prefer `jq`-based validation
  where the check is jq-expressible; fall back to
  `python3 -m jsonschema` for structural checks that exceed jq's
  practical reach; refuse with a clear error if neither is
  present (matches FW-ADR-0015's runtime-dependency posture).
  - **jq-expressible** (preferred path): `schema_version`
    semver-string shape, enum membership (`class`, `pinned_by`),
    length / charset of sha256 hashes (64 hex chars) and ref
    SHAs (40 hex chars), required-field presence on a single
    object, simple type checks.
  - **`jsonschema`-required** (fallback path): structural checks
    that need true JSON Schema semantics — uniqueness invariants
    across the `paths` array (no two rows with identical
    `path`), conditional-required-field rules (`hash` and
    `source_ref` required iff `class` is `managed` or
    `customised`; forbidden iff `project-owned`).
  - **Refusal message MUST name BOTH dependencies.** When
    neither `jq` nor `python3 -m jsonschema` is available, the
    runner exits with a clear error naming both candidates and
    pointing at the install path on common platforms; it does
    NOT name only one and leave the operator guessing about the
    other.
- **Migration function:** lives in the runner, not the stub
  (per FW-ADR-0015 stub budget). The migration function is
  pure: input (three legacy files), output (one new file). No
  network calls. Idempotent. Bridging-rc invocation per
  FW-ADR-0018.
- **Atomic-write helper:** the runner's existing `safe_write`
  helper (or equivalent) handles `tmp + fsync + rename`. SE
  reuses; no new primitive.
- **Lock primitive:** `flock` on `.template-state.lock` at
  project root. The lockfile is `.gitignore`d at scaffold;
  add to the scaffold's gitignore template if not present.
  POSIX-portable; macOS `flock` ships via Homebrew util-linux
  or `lockfile` from procmail; SE feature-detects and refuses
  with a clear error on absence.
- **Schema-version reader:** the runner carries a constant
  `SUPPORTED_SCHEMA_MAJOR=1` and implements the reject-on-newer-MAJOR
  / silent-upgrade-on-older-MINOR / silent-on-PATCH /
  accept-on-match logic in § Schema-version field semantics. The
  silent-MINOR-upgrade path is a write side-effect on the next
  state-mutating sync (no separate "migrate" command); the reader
  records the in-memory upgraded shape and the writer emits at
  `SUPPORTED_SCHEMA_MAJOR.<highest-supported-MINOR>.0`. No WARN
  log, no operator-visible event.
- **Runner emits only `managed` and `customised` rows.** The
  runner does not walk the project tree; it does not synthesise
  `project-owned` rows. On read, the runner preserves any
  operator-added `project-owned` rows verbatim (passing them
  through the schema validator) and re-emits them on write.
  Validation rules in § Per-path declaration shape still apply
  to operator-added `project-owned` rows (no `hash` /
  `source_ref`; class-enum membership; unique `path`).
- **No backwards-compat read of the legacy trio in the
  runner.** Only the bridging-rc's migration body reads them.
  Post-bridge runners read `TEMPLATE_STATE.json` only.
- **Unit tests (`qa-engineer` scope):**
  - (a) Round-trip migration from each legacy-state fixture.
  - (b) Schema validation rejects each invalid shape enumerated
    in § Per-path declaration shape.
  - (c) Atomic-write survives a SIGKILL between rename and lock
    release (the lock file lingers; next invocation detects
    and clears).
  - (d) Pin lifecycle: TOFU on first observation, match on
    reuse, replace on different target, `--refresh-pin`
    rewrites.
  - (e) Idempotent re-run of migration on a project already
    on the new schema is a no-op.

The implementation ADR (FW-ADR-0016-impl) covers code-level
details beyond this contract. `security-engineer` reviews the
pin-lifecycle section before implementation lands.

## Open questions

All decision axes that this ADR raised are closed.

- **Q1 (schema-version upgrade-on-read semantics)** and **Q2
  (`project-owned` class promotion scope)** — closed by customer
  rulings 2026-05-15 (see `CUSTOMER_NOTES.md`). Q1: silent MINOR
  upgrade on next state-mutating sync (no WARN, no operator
  action). Q2: `project-owned` is opt-in; runner never emits one;
  operators may manually add `project-owned` rows for audit
  coverage. Both rulings are baked into the binding interface
  decisions above (§ Schema-version field semantics, § Path-class
  enum, § Implementation notes for software-engineer).

The dispatch brief's questions 3 (pin-history surface) and 4
(lockfile location) are **closed** by this ADR's prose:

- Pin-history surface (§ Runner-pin lifecycle → Audit-trail
  decision): the file carries the current pin only;
  pin history rides on `git log TEMPLATE_STATE.json`. No queue
  entry needed.
- Lockfile location (§ Concurrency and atomic-write semantics +
  § Implementation notes for software-engineer): `flock` on
  `.template-state.lock` at project root, gitignored at
  scaffold. No queue entry needed.

## Links

- Foundation ADR: `docs/adr/fw-adr-0015-upgrade-orchestrator-stub-model.md`.
- Inherited contract: `docs/adr/fw-adr-0002-upgrade-content-verification.md`.
- Partially superseded: `docs/adr/fw-adr-0014-preservation-vs-manifest.md`
  (Q1 retires; Q2 inherits unchanged through the runner).
- Customer rulings (CUSTOMER_NOTES.md, 2026-05-15):
  out-of-tree orchestrator ("yes, let's make it a stub"),
  migration-path-S ("S"), air-gap out of scope ("air gapped
  operators will have to figure it out on their own"),
  security floor ("TLS and checksum will be plenty").
- Dogfood evidence: `docs/pm/dogfood-2026-05-15-results.md`,
  `docs/pm/upgrade-flow-conceptual-mistake-2026-05-15.md`,
  `docs/pm/upgrade-flow-process-debt-2026-05-15.md`.
- Fixtures: `tests/release-gate/snapshots/v1.0.0-rc12/`
  (clean / with-customizations / with-accepted-local — the
  three legacy-state shapes the migration function must
  handle).
- Forward-referenced ADRs:
  - FW-ADR-0017 — file-keyed migration discovery (uses this
    schema).
  - FW-ADR-0018 — bridging-rc migration path (uses this
    schema's migration function shape).
  - FW-ADR-0019 — pre-bootstrap retirement (depends on this
    ADR for state-file authority).
- External references:
  - MADR 3.0 (`https://adr.github.io/madr/`).
  - JSON Schema draft-07
    (`https://json-schema.org/draft-07/json-schema-release-notes.html`).
  - SemVer 2.0 (`https://semver.org/spec/v2.0.0.html`) — for
    the `schema_version` field's parse rules.
