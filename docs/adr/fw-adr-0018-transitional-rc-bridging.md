---
name: fw-adr-0018-transitional-rc-bridging
description: One transitional in-tree rc bridges currently-deployed downstreams onto the FW-ADR-0015 stub model. Last in-tree rc; last pre-bootstrap class instance. Consolidates the legacy three-file project state into TEMPLATE_STATE.json, atomic-installs the new stub, retires the legacy artefacts. Required follow-up to FW-ADR-0015 / 0016 / 0017.
status: accepted
date: 2026-05-15
accepted: 2026-05-15
---


# FW-ADR-0018 — Transitional rc bridging currently-deployed downstreams onto the stub model

<!-- TOC -->

- [Status](#status)
- [Context and problem statement](#context-and-problem-statement)
- [Decision drivers](#decision-drivers)
- [Considered options (Three-Path Rule, binding)](#considered-options-three-path-rule-binding)
  - [Option M — Minimalist: transitional in-tree rc (chosen)](#option-m--minimalist-transitional-in-tree-rc-chosen)
  - [Option S — Scalable: one-time retrofit script (curl one-liner)](#option-s--scalable-one-time-retrofit-script-curl-one-liner)
  - [Option C — Creative: vNext MAJOR with scaffold-fresh requirement](#option-c--creative-vnext-major-with-scaffold-fresh-requirement)
- [Decision outcome](#decision-outcome)
- [Interface decisions (binding)](#interface-decisions-binding)
  - [1. Transitional rc name and version stamp](#1-transitional-rc-name-and-version-stamp)
  - [2. Source-baseline support range](#2-source-baseline-support-range)
  - [3. Migration shape (five-step atomic sequence)](#3-migration-shape-five-step-atomic-sequence)
  - [4. Idempotency of the bridging migration](#4-idempotency-of-the-bridging-migration)
  - [5. Failure-mode handling](#5-failure-mode-handling)
  - [6. Rollback story](#6-rollback-story)
  - [7. CI / smoke-testing gate (dogfood-vs-this-rc)](#7-ci--smoke-testing-gate-dogfood-vs-this-rc)
  - [8. Coordination with FW-ADR-0019](#8-coordination-with-fw-adr-0019)
  - [9. TEMPLATE_VERSION -> schema_version mapping](#9-template_version---schema_version-mapping)
- [Consequences](#consequences)
  - [Positive](#positive)
  - [Negative / trade-offs accepted](#negative--trade-offs-accepted)
- [Verification](#verification)
- [Implementation notes for software-engineer](#implementation-notes-for-software-engineer)
- [Open questions](#open-questions)
- [Links](#links)

<!-- /TOC -->

Shape per MADR 3.0 + this template's Three-Path Rule
(`docs/templates/adr-template.md`). Fourth in the upgrade-flow
rearchitecture sequence (FW-ADR-0015 foundation, FW-ADR-0016 state
schema, FW-ADR-0017 file-keyed discovery, **FW-ADR-0018 bridging
rc**, FW-ADR-0019 pre-bootstrap retirement). Cap ~600 lines.

---

## Status

- **Proposed: 2026-05-15**
- **Accepted: 2026-05-15** (post-CR revision pass dissolving the
  rc-numbering collision, the §§ 4/5 detector contradiction, and
  the FW-ADR-0019 sequencing deadlock — see CR report at
  `docs/review/fw-adr-0018-transitional-rc-bridging.md`).
- **Deciders:** `architect` + `tech-lead` + customer (cross-cutting
  pattern change to the in-tree upgrade contract; consolidates three
  legacy artefacts and installs a new stub; customer approval per
  CLAUDE.md Hard Rules).
- **Consulted:** FW-ADR-0015 (foundation; this ADR operationalises
  its "migration path forward" section), FW-ADR-0016 (state schema;
  this ADR invokes its migration function shape), FW-ADR-0017
  (discovery; this ADR's migration ships as a discovery-eligible
  file in `migrations/`), FW-ADR-0010 (pre-bootstrap pattern; this
  ADR inherits it for the LAST time), FW-ADR-0013 (rc-to-rc
  pre-bootstrap precedent), `software-engineer` (substantial
  implementation surface: stub body + bridging migration +
  state-consolidation logic), `release-engineer` (rc-cut gating
  per dogfood-vs-this-rc), `qa-engineer` (9-fixture acceptance
  harness shape).

## Context and problem statement

FW-ADR-0015 fixed the upgrade-flow conceptual mistake structurally:
`scripts/upgrade.sh` becomes a sub-100-line stub on the downstream
tree; the real orchestrator (`scripts/upgrade-runner.sh`) is fetched
fresh per invocation from upstream. FW-ADR-0016 collapsed the
three-source-of-truth project-state class onto
`TEMPLATE_STATE.json`. FW-ADR-0017 retired tag-keyed migration
discovery in favour of file-presence enumeration. Together these
three ADRs define the post-bridge state. None of them tells a
currently-deployed downstream how to get there.

Every downstream project shipped to date hosts an in-tree
`scripts/upgrade.sh` that is its own orchestrator, plus the legacy
three-file state (`TEMPLATE_VERSION` + `TEMPLATE_MANIFEST.lock` +
`.template-customizations`). The customer's 2026-05-15 ruling
(`CUSTOMER_NOTES.md` line ~310 — "S — one more in-tree rc bridges
existing downstreams onto the stub model") pins the migration path
to a single in-tree rc that, on first run, atomically installs the
stub, consolidates state, and retires the legacy artefacts. After
that rc runs, the downstream is on the stub model and the in-tree
upgrade-driver era closes.

This ADR is the operational pin for that transitional rc. It is the
LAST in-tree rc the framework will cut; no further rc-cliffs follow.
It is also the LAST pre-bootstrap class instance (FW-ADR-0010
pattern), because the transitional rc's own `scripts/upgrade.sh` is
still self-mutating in-tree at the moment the bridging migration
runs. Both of those "last instances" carry quality constraints: the
rc MUST pass dogfood-vs-itself across the § 7 fixture set (customer's
binding "dogfood before cutting an rc" rule, 2026-05-15) before the
tag cuts, AND the pre-bootstrap MUST be correct on first ship
because there is no second chance — once a downstream lands on the
stub model, the bridging rc is no longer reachable from it.

ADR-trigger rows that fire: major refactor that changes a public
boundary (the in-tree `scripts/upgrade.sh` is replaced by the stub);
data-model change (legacy three-file state collapses into
`TEMPLATE_STATE.json`); cross-cutting pattern change (upgrade-flow
contract); change touching the customer-flagged critical path
(upgrade is "always buggy"); choice that locks the framework into a
one-way migration that is expensive to reverse if it ships broken.

## Decision drivers

- **Bridge existing downstreams onto the stub model without
  stranding them.** Every project currently on v0.x through
  v1.0.0-rc12 must have a single, documented upgrade step that
  lands it on the FW-ADR-0015 stub model. No "scaffold fresh"
  fallback is acceptable for projects with accumulated
  customisations.
- **Customer's "dogfood before cutting an rc" rule (binding,
  2026-05-15) applies to THIS rc.** The transitional rc itself
  must pass dogfood against the § 7 fixture set (12 total per § 7
  arithmetic) before its tag cuts. The dogfood failure
  data this rc has to handle is in
  `docs/pm/dogfood-2026-05-15-results.md` — 0/9 PASS against
  v1.0.0-rc12 today, with three distinct upgrade-class root
  causes the post-bridge model dissolves.
- **LAST in-tree rc.** After this rc, `scripts/upgrade.sh` IS
  the FW-ADR-0015 stub; no future rc ships a project-managed
  orchestrator. The rc-cliff cost retires to zero. This is the
  one-way door.
- **LAST pre-bootstrap class instance.** The transitional rc's
  bridging migration is the LAST migration that needs the
  FW-ADR-0010 pre-bootstrap pattern (because it overwrites
  `scripts/upgrade.sh` while the old `scripts/upgrade.sh` is
  running). FW-ADR-0019 retires the pre-bootstrap class as a
  whole on the strength of this ADR completing. The pre-bootstrap
  on this rc has no second chances — if it ships broken, the
  fix vehicle is "another transitional rc," which contradicts
  this ADR's "LAST" commitment.
- **Idempotent re-run is mandatory.** Per FW-ADR-0017 § 5, every
  migration is idempotent. The bridging migration must be a
  no-op when re-run against an already-bridged project; the
  detection rule is `TEMPLATE_STATE.json` presence with
  `schema_version >= 1.0.0`.
- **Atomic state-file transition.** Legacy files must persist
  until `TEMPLATE_STATE.json` is fully written and schema-
  validated; ONLY THEN does the bridging migration remove them.
  Crash mid-migration leaves a recoverable state.
- **Single-direction migration; no formal rollback.** A
  downstream that runs the transitional rc and dislikes the new
  model rolls back via `git` (the operator's existing version-
  control practice), not via a framework-supplied rollback path.
  This is a deliberate trade-off; the rollback story is "git
  history is your rollback story."

## Considered options (Three-Path Rule, binding)

### Option M — Minimalist: transitional in-tree rc (chosen)

One additional in-tree rc is cut. Its `scripts/upgrade.sh` carries
the legacy upgrade body plus, as a discovery-eligible migration
file (`migrations/v1.0.0-rc15.sh`), the bridging sequence: synth
`TEMPLATE_STATE.json` from the legacy trio, atomic-install the new
stub over `scripts/upgrade.sh`, atomic-remove the legacy trio.
Operators who run that rc transition through it once; afterwards
they are on the stub model.

- **Sketch:** Ship rc15 with two co-shipped pieces — (a) the new
  stub at `template-files/scripts/upgrade.sh.stub` (or equivalent
  staging path in the runner's tree, not directly at
  `scripts/upgrade.sh` in the project until the bridge runs);
  (b) the bridging migration at
  `migrations/v1.0.0-rc15.sh` per the FW-ADR-0017 discovery
  convention. The rc15 `scripts/upgrade.sh` is the LAST in-tree
  upgrade.sh the framework ships; the rc15 bridging migration is
  the LAST FW-ADR-0010-pattern pre-bootstrap.
- **Pros:**
  - Inherits the entire FW-ADR-0010 pre-bootstrap atomic-rename
    machinery already implemented in `migrations/v0.14.0.sh`
    (lines 42-90+) — no new pre-bootstrap design surface.
  - Discoverable through the existing in-tree
    `scripts/upgrade.sh` enumeration — operators run
    `scripts/upgrade.sh` exactly as they always have; the
    framework does the rest.
  - Idempotent via FW-ADR-0016 migration-function shape
    (`TEMPLATE_STATE.json` present with valid schema → no-op);
    repeat runs are safe.
  - Maps cleanly onto the FW-ADR-0015 § "Migration path forward"
    sketch.
  - The customer ruled S (2026-05-15) which corresponds to this
    transitional-runner path. Decision is already taken; this
    ADR formalises the shape.
- **Cons:**
  - Requires cutting one more in-tree rc with all the legacy
    quality bar (rc-cut ritual + dogfood across the § 7 fixture set).
  - The LAST pre-bootstrap MUST be perfect; no remediation
    path for a broken pre-bootstrap on this rc other than
    asking operators to hand-restore from `git` and skip ahead.
  - Carries the entire legacy `scripts/upgrade.sh` body for
    one more release — a frozen feature set with one new
    migration appended.
- **When M wins:** when the deployed-downstream population is
  non-trivial (it is, even at "customer is the only user" — every
  fixture in the dogfood harness corresponds to a real downstream
  shape) AND the existing pre-bootstrap pattern is well-understood
  (it is — FW-ADR-0010 + `migrations/v0.14.0.sh` ship it).

### Option S — Scalable: one-time retrofit script (curl one-liner)

The framework ships no transitional rc. Instead it publishes a
one-time retrofit script (`scripts/retrofit-to-stub.sh` upstream).
Operators run `curl -fsSL <upstream>/scripts/retrofit-to-stub.sh |
bash` once; the retrofit reads the local legacy trio, writes
`TEMPLATE_STATE.json`, atomic-installs the stub, removes the
legacy artefacts. The retrofit is not a regular upgrade — it does
not run migrations, does not advance versions, only changes the
upgrade-flow shape.

- **Sketch:** Standalone bash script. Operator runs it once per
  downstream. Internally it does what the bridging migration in
  Option M does, but it is invoked directly by the operator,
  not by `scripts/upgrade.sh`.
- **Pros:**
  - No in-tree rc cut required; no dogfood-vs-this-rc gate.
  - Decouples the bridge from the upgrade-flow CLI surface;
    `scripts/upgrade.sh --whatever` muscle-memory is irrelevant
    until after retrofit.
  - The retrofit script's failure modes are bounded — it does
    only one thing.
- **Cons:**
  - Operators have to learn a new one-time command that diverges
    from the framework's existing `scripts/upgrade.sh` muscle
    memory. The "you ran upgrade.sh and it just worked" story
    breaks for one event.
  - The retrofit script is essentially the bridging migration
    extracted from `scripts/upgrade.sh` execution context;
    duplicating the logic into a standalone script means TWO
    places that have to be correct (the script and the
    discovery-eligible migration file other downstreams would
    need anyway for re-bridge of partial states). Two-source-of-
    truth class re-emerges.
  - `curl | bash` is a culture cost the framework already paid
    in FW-ADR-0015's Option C and rejected for the same reasons
    (operator trust posture is harder to argue; CI / dogfood
    harnesses lose the familiar entrypoint).
  - The customer ruled M (2026-05-15) — "S — one more in-tree
    rc bridges existing downstreams onto the stub model." This
    ADR's Option labelling differs from the customer's M/S
    framing because architect's "transitional in-tree rc" is the
    Minimalist path under this ADR's scope (smallest framework
    surface change given the foundation ADRs); the customer's
    "S" framing was at the FW-ADR-0015 level (transitional
    runner path versus scaffold-fresh). The customer's ruling
    therefore endorses this ADR's Option M.
- **When S wins:** if cutting one more in-tree rc were
  prohibitively expensive (it is not — the rc body is mostly
  inherited from rc12 with one new migration file).

### Option C — Creative: vNext MAJOR with scaffold-fresh requirement

The framework cuts v2.0.0 directly. Existing downstreams are
declared incompatible; the operator scaffolds a fresh v2.0.0
project, hand-copies their customisations across, and discards
the v1.x project tree. No bridging migration exists; the v2.0.0
runner refuses to read the legacy three-file state.

- **Sketch:** No transitional rc. v2.0.0 ships the stub directly
  and assumes a freshly-scaffolded project. Operators who want
  to preserve customisations follow a manual procedure documented
  in a retrofit playbook (per `docs/templates/retrofit-playbook-template.md`).
- **Pros:**
  - Zero framework engineering on the bridging path; the
    framework just ships the stub model and moves on.
  - Clean break — no legacy support tail.
  - Forces operators to engage with their customisations
    explicitly during the migration.
- **Cons:**
  - Customer ruled this out 2026-05-15 (the "C" in the
    customer's M/S/C framing on the FW-ADR-0015-level path
    decision). Not a candidate.
  - High operator cost; existing customisations are migrated
    manually with high error rate.
  - "Scaffold fresh" loses customer-specific git history of
    the project tree's evolution.
- **When C wins:** if the downstream population were nil
  (every project is new) or if the legacy state were so corrupt
  that bridging would be more expensive than rebuilding. Neither
  holds.

## Decision outcome

**Chosen option: M (transitional in-tree rc).**

**Reason:** Option M is the only option the customer's 2026-05-15
S-ruling endorses (at this ADR's granularity, the customer's S
corresponds to architect's M — the transitional-runner path
implemented as one more in-tree rc). Option S re-fragments the
bridging logic into a standalone retrofit script that duplicates
the FW-ADR-0016 migration function shape; the two-source-of-truth
class re-emerges in the very ADR meant to consolidate state.
Option C is customer-rejected.

Option M inherits the entire FW-ADR-0010 pre-bootstrap mechanism
already shipping in `migrations/v0.14.0.sh`, applies it for the
LAST time, and rides FW-ADR-0017's file-keyed discovery for
identification. The cost is one more in-tree rc cut with all
attendant quality gates (dogfood-vs-this-rc across the § 7 fixture set);
that cost is bounded and survivable.

## Interface decisions (binding)

### 1. Transitional rc name and version stamp

**Name: `v1.0.0-rc15`.**

Rationale:

- `v1.0.0-rc13` was already consumed by FW-ADR-0013's now-
  superseded rc-to-rc pre-bootstrap migration
  (`migrations/v1.0.0-rc13.sh`, present in the tree).
- `v1.0.0-rc14` is ALSO already consumed by FW-ADR-0014's
  preservation-prune migration (`migrations/v1.0.0-rc14.sh`,
  117 lines, present on `main`, semantically unrelated to
  bridging). Reusing either filename for a different body
  violates the FW-ADR-0017 § 5 idempotency contract (a
  migration file's identity is its filename; reusing it as a
  different body confuses re-runs).
- The principle "monotonic rc numbers, no skips, no rebrands"
  applied consistently to BOTH already-claimed filenames yields
  `v1.0.0-rc15` as the next-unclaimed semver. rc15 is the right
  number.
- The customer's binding "dogfood before cutting an rc" rule
  (2026-05-15) means the literal tag `v1.0.0-rc15` MUST NOT be
  cut until dogfood-vs-this-rc PASSes across the full fixture
  set (§ 7). No exception. The rc number is the right number;
  the tag is gated on the dogfood result.

**Interaction with the existing rc13.sh / rc14.sh on disk:**
`migrations/v1.0.0-rc14.sh` (FW-ADR-0014 preservation-prune
migration) and `migrations/v1.0.0-rc13.sh` (FW-ADR-0013 rc-to-rc
pre-bootstrap) remain on disk untouched; their disposition is
FW-ADR-0019 territory. The rc15 bridging migration does NOT touch
them. They no-op on already-past projects per FW-ADR-0017 § 5
idempotency.

**Version-stamp behaviour during the bridge:** the rc15 bridging
migration synthesises `TEMPLATE_STATE.json` with
`template.version = "<source baseline version>"` (NOT rc15 — the
project's stamped version when the bridge starts; the bridging
migration itself is not a version-advancing migration). After the
bridging migration completes successfully, the rc15 sync loop
proceeds normally and advances `template.version` to `"v1.0.0-rc15"`
at sync exit. The runner pin records `pinned_by: tofu` against the
rc15 runner SHA (which is the rc15 in-tree `scripts/upgrade.sh`
itself for the bridging run only; post-bridge, the stub-fetched
runner takes over).

### 2. Source-baseline support range

**Inclusive range: any project at `v0.13.0` or later.**

- **Reachable baselines:** v0.13.0, v0.14.0, v0.14.4, v0.15.0,
  v1.0.0-rc2 through v1.0.0-rc12. These are the in-tree
  migration files present in `migrations/` plus the implicit
  "scaffold at vN" starting points.
- **Not supported as source:** pre-v0.13.0 projects (v0.1.0,
  v0.2.0, v0.3.0, v0.6.2, plus the legacy un-prefixed
  `1.1.0.sh` which is a misnomer for a pre-v0.13.0 migration).
  Operators on pre-v0.13.0 must first advance to v0.13.0 via
  a rc12-or-earlier upgrade chain, then run rc15 to bridge.
  Rationale: pre-v0.13.0 projects predate `.template-customizations`
  entirely; the FW-ADR-0016 migration function's input shape
  does not match. The cost of supporting them is a separate
  pre-bridge migration with no realistic consumer (the customer
  confirmed single-user deployment; there are no known pre-v0.13.0
  downstreams in the wild).
- **Detection rule:** if `TEMPLATE_VERSION` line 1 parses to a
  semver `< v0.13.0`, the bridging migration refuses with a
  clear error naming the required intermediate target
  (`v1.0.0-rc12` or `v0.15.0`) and exits non-zero. Idempotency
  rule still applies — re-runs against a refused project keep
  refusing the same way.
- **Air gaps with respect to the 9 dogfood baselines:** the
  fixture set in `docs/pm/dogfood-2026-05-15-results.md`
  spans v1.0.0-rc2 through v1.0.0-rc8 (alpha/beta/gamma x
  scaffold/mid/latest). The v0.13.0 baseline is included via
  beta/scaffold; v0.14.x and v0.15.0 baselines are extrapolated
  but not directly fixtured. `qa-engineer` extends the fixture
  set to include v0.14.0 + v0.15.0 source baselines as part
  of this ADR's acceptance.

### 3. Migration shape (five-step atomic sequence)

The bridging migration body (`migrations/v1.0.0-rc15.sh`)
performs these steps in this order. Each step is atomic;
each step is idempotent.

**(a) Pre-bootstrap (FW-ADR-0010 inheritance).**

Apply the FW-ADR-0010 3-SHA decision matrix to the
bootstrap-critical fileset for the rc15 bridge:

- `scripts/upgrade.sh` — refused-on-local-edit unless
  `SWDT_PREBOOTSTRAP_FORCE=1`.
- `scripts/lib/*.sh` — same.
- **NEW for rc15:** the eventual stub itself is NOT in the
  bootstrap-critical set because it has not yet been installed.
  The pre-bootstrap step runs against the legacy `scripts/upgrade.sh`
  (the rc15 in-tree one being installed over the rc2..rc12 one),
  exactly as `migrations/v0.14.0.sh` does today. After this rc15
  bridging migration completes, the stub takes
  over and the pre-bootstrap concept retires (FW-ADR-0019).

Implementation: inherit the pre-bootstrap block from
`migrations/v0.14.0.sh` verbatim — specifically the
`prebootstrap_sha` helper (line 62), the `prebootstrap_paths`
bootstrap-critical fileset construction (lines 70-82), the 3-SHA
decision-matrix loop (lines 103-149), the refuse/force block
artefact handling (lines 151-241 including
`SWDT_PREBOOTSTRAP_FORCE` audit-log append at lines 162-186), and
the proceed-list atomic install (lines 243-262). The complete
pre-bootstrap block runs lines 42-262 of `migrations/v0.14.0.sh`
in the current 334-line file. The rc15 bridging migration's
pre-bootstrap block IS the FW-ADR-0010 pre-bootstrap class's LAST
instance (subject to the FW-ADR-0019 escape-hatch clause in § 8).
FW-ADR-0019 retires the entire `prebootstrap_*` helper family
on the strength of this rc shipping correctly.

**Block artefact behaviour:** identical to FW-ADR-0010 § "Block
artefact" — write `.template-prebootstrap-blocked.json` on
refuse; remove on success; idempotent re-run produces same
artefact content modulo timestamp.

**(b) State consolidation (FW-ADR-0016 migration function).**

Invoke the FW-ADR-0016 § "Migration function shape" body:

- Read `TEMPLATE_VERSION` (3-line text); fail-fast if missing
  or malformed.
- Read `TEMPLATE_MANIFEST.lock` (manifest rows); tolerate
  absence with the pre-v0.14.0 fallback per FW-ADR-0016.
- Read `.template-customizations` (preserve list); tolerate
  absence with the pre-v0.13.0 fallback per FW-ADR-0016 (but
  remember source-baseline rule § 2 — v0.13.0+ only; in
  practice `.template-customizations` is present on every
  supported baseline).
- Synth `TEMPLATE_STATE.json` per the FW-ADR-0016 schema with:
  - `schema_version: "1.0.0"`
  - `template.version: <TEMPLATE_VERSION line 1, verbatim>`
  - `template.ref: <TEMPLATE_VERSION line 2, verbatim>`
  - `template.scaffolded_at: <TEMPLATE_VERSION line 3, verbatim>`
  - `template.synced_at: <today's date>`
  - `runner_pin: <absent>` — runner pin is recorded by the
    rc15 sync loop's exit step, not by the bridging migration
    itself. See step (e) below.
  - `paths`: per FW-ADR-0016 § "Migration function shape"
    classification rules.
- Write to `TEMPLATE_STATE.json.tmp`, `fsync`, validate against
  `docs/schemas/template-state.schema.json`, atomic-rename
  over `TEMPLATE_STATE.json`. Per FW-ADR-0016 § Concurrency.

**(c) Stub install (atomic-replace `scripts/upgrade.sh`).**

After step (b) verifies the new state file is in place:

- The rc15 in-tree `scripts/upgrade.sh` (the orchestrator
  running this very migration) was already pre-bootstrapped
  in step (a) — the project's `scripts/upgrade.sh` is now
  byte-identical to the rc15 tree's `scripts/upgrade.sh`.
  The migration body must NOT modify that file itself.
- The migration body atomic-replaces `scripts/upgrade.sh`
  ONE MORE TIME — overwriting the rc15 in-tree
  `scripts/upgrade.sh` with the FW-ADR-0015 stub body.
  Source: a co-shipped stub at `template-files/upgrade-stub.sh`
  in the rc15 tree (or whatever staging path
  `software-engineer` picks; the path is rc15-internal). The
  atomic-rename pattern from FW-ADR-0010 applies — the
  running rc15 `scripts/upgrade.sh` keeps reading its
  unlinked inode while the new stub takes the path; the
  next invocation lands on the stub.
- This second atomic-replace is BENIGN against operator
  edits because pre-bootstrap in step (a) already enforced
  "no local edits to `scripts/upgrade.sh`" before reaching
  step (c). Operators who needed `SWDT_PREBOOTSTRAP_FORCE=1`
  in step (a) authorised the stub install at the same time.
- The stub install path goes through the FW-ADR-0010
  audit-log on force; the row's `Gate` column reads
  `pre-bootstrap` (per FW-ADR-0010's existing schema).

**(d) Legacy file removal.**

After step (c) atomic-renames the stub into place:

- `rm TEMPLATE_VERSION` — atomic via `mv` to a tempfile and
  `rm` from tempdir; the project tree's `TEMPLATE_VERSION`
  is unlinked atomically.
- `rm TEMPLATE_MANIFEST.lock` — same.
- `rm .template-customizations` — same.
- Each removal is preceded by a sanity check that
  `TEMPLATE_STATE.json` is on disk and schema-valid; refuse
  to remove the legacy artefacts if the new file is missing
  or invalid (this is the atomicity guard).

**Operator-visible effect:** the project's git status after
the bridging migration shows three deleted files
(`TEMPLATE_VERSION`, `TEMPLATE_MANIFEST.lock`,
`.template-customizations`), one new file
(`TEMPLATE_STATE.json`), one modified file
(`scripts/upgrade.sh` — now the stub). The operator commits
this delta as the bridge transition. Commit message guidance
ships in the rc15 release notes (`tech-writer` work).

**(e) Runner-pin recording.**

The bridging migration body does NOT write `runner_pin`.
Per FW-ADR-0016 § Runner-pin lifecycle, the pin is recorded
on the first successful runner fetch. The rc15 transitional
case is structurally different — the "runner" for the
bridging run IS the rc15 in-tree `scripts/upgrade.sh` itself
(still running at this point in the chain). The pin recording
deferred to the FIRST POST-BRIDGE invocation of
`scripts/upgrade.sh` (now the stub); that invocation fetches
the upstream runner and records the pin per FW-ADR-0015
normal flow.

**Alternative considered and rejected:** synthesising a pin
record during the bridging migration that names the rc15 tag
as the pinned target. Rejected because (a) the rc15 tag does
not yet exist at the time the bridging migration runs
(dogfood-before-rc-cut rule); (b) the rc15 in-tree
`scripts/upgrade.sh` is being retired in step (c), so pinning
to it pins to a runner the project will never invoke; (c)
post-bridge runner fetches will TOFU naturally on first run.

**(f) Interaction with existing in-tree migrations.**

Under FW-ADR-0017 file-keyed discovery, a project at `v1.0.0-rc13`
upgrading via the rc15-bridge will see `migrations/v1.0.0-rc14.sh`
(FW-ADR-0014 preservation-prune) fire BEFORE
`migrations/v1.0.0-rc15.sh` (file-sort order). The rc14-prune
migration is a no-op on projects that have never used
`.template-customizations` (the common case), or runs harmlessly
on those that have — its mutations are bounded to opt-in
preservation-prune semantics that do not affect the bridging
preconditions. After rc14-prune returns, the rc15-bridge runs and
consolidates state. Not a load-bearing interaction; documented
here so SE / qa-engineer do not treat the ordering as a defect.

### 4. Idempotency of the bridging migration

Per FW-ADR-0017 § 5, every migration is idempotent. The
bridging migration is no exception.

**Detection shape — naive form (NOT binding; see § 5 for the
binding refinement):**

```
if [[ -f "$PROJECT_ROOT/TEMPLATE_STATE.json" ]]; then
    if jq -e '.schema_version | startswith("1.")' \
         "$PROJECT_ROOT/TEMPLATE_STATE.json" >/dev/null 2>&1; then
        echo "v1.0.0-rc15.sh: no-op (already applied)" >&2  # NAIVE — do not implement this form
        return 0
    fi
fi
```

The naive single-condition form (state-file presence alone) is
shown here to anchor the no-op signature line shape — the
FW-ADR-0017 § 5 binding shape (`<filename>: no-op (already
applied)`). It is NOT the binding detector. The naive form
mis-handles partial-completion states: a crash between
step (b) and step (c) leaves `TEMPLATE_STATE.json` present
AND the legacy files present, and the naive detector would no-op
without finishing the bridge. **The binding detector lives in § 5;
implementers MUST use the § 5 quad form, not this naive shape.**

### 5. Failure-mode handling

The bridging migration is sequenced atomically:

- **Failure in step (a) pre-bootstrap refused:** operator
  resolves local edits or sets `SWDT_PREBOOTSTRAP_FORCE=1`
  per FW-ADR-0010. Re-run from scratch.
- **Failure in step (b) state consolidation:**
  `TEMPLATE_STATE.json` is not written (atomic-rename is the
  commit point; failure before the rename means no file).
  Legacy trio remains intact. Per FW-ADR-0017 § 4 source-bound
  invariant, the project's `template.version` does not advance.
  Re-run from scratch.
- **Failure in step (c) stub install (after step (b) wrote
  the new state file):** `TEMPLATE_STATE.json` exists on disk
  but the stub is not in place. The detection rule in § 4
  fires on re-run — the bridging migration no-ops because it
  sees the state file. BUT the stub is still the rc15 in-tree
  `scripts/upgrade.sh`, not the new stub. Recovery: the rc15
  in-tree `scripts/upgrade.sh`'s normal sync loop runs after
  the bridging migration; the sync loop encounters
  `scripts/upgrade.sh` in the project tree, computes its
  hash against the FW-ADR-0014 / FW-ADR-0002 manifest, finds
  it matches the rc15 in-tree shape, and does nothing — the
  stub install is therefore not retried by the normal sync.
  **Mitigation:** the bridging migration's step (c) is
  bracketed by an explicit success marker; on idempotent
  re-run, if `TEMPLATE_STATE.json` exists AND the on-disk
  `scripts/upgrade.sh` hash matches the rc15 in-tree
  version (NOT the stub), the bridging migration's no-op
  detector is REFINED to "state file present AND stub
  installed" rather than just "state file present." On a
  partial-state re-run, the bridging migration completes
  steps (c) and (d) and emits a recovery-success log line.
- **Failure in step (d) legacy file removal:** the new state
  file is in place AND the stub is installed; legacy files
  are still on disk. The bridging migration's no-op detector
  recognises this state (orphan legacy files alongside valid
  state file + installed stub) and completes the removal on
  re-run, then emits a recovery-success log line.

**Refined idempotency detection (BINDING — single source of
truth, supersedes § 4's naive shape):**

The binding detector is a **quad** check: state file valid AND
stub installed AND **all three** legacy files absent. Checking only
`TEMPLATE_VERSION` absence (the prior triplet form) would leave the
detector ambiguous if step (d) crashes between the three `rm` calls
(e.g., `TEMPLATE_VERSION` gone but `TEMPLATE_MANIFEST.lock` still
present).

```
state_file_valid=$(test -f TEMPLATE_STATE.json && \
                   jq -e '.schema_version | startswith("1.")' \
                   TEMPLATE_STATE.json >/dev/null 2>&1; echo $?)
stub_installed=$(sha256sum scripts/upgrade.sh | awk '{print $1}')
expected_stub_sha=<pinned at rc15 build time>

if [[ $state_file_valid -eq 0 ]] && \
   [[ "$stub_installed" == "$expected_stub_sha" ]] && \
   [[ ! -f TEMPLATE_VERSION ]] && \
   [[ ! -f TEMPLATE_MANIFEST.lock ]] && \
   [[ ! -f .template-customizations ]]; then
    echo "v1.0.0-rc15.sh: no-op (already applied)" >&2
    return 0
fi

# Partial-state recovery: complete missing steps.
# (Concrete shell shape is software-engineer scope.)
```

### 6. Rollback story

**No formal rollback.** Operator's existing `git` history is
the rollback story.

Rationale:

- The bridging migration's mutations are all in the project
  tree, all committable to git, and all reversible by
  `git checkout <pre-bridge-commit> -- TEMPLATE_VERSION
  TEMPLATE_MANIFEST.lock .template-customizations scripts/upgrade.sh`
  followed by `git rm TEMPLATE_STATE.json`.
- A framework-supplied rollback path would have to invert
  step (b)'s migration function shape (re-derive the legacy
  trio from the new state file). The inverse is straightforward
  (the migration is information-preserving) but ships as a
  long-tail maintenance burden for a one-time event the
  customer accepts as a one-way door.
- The transitional rc is by design the LAST in-tree rc. After
  the bridge runs, the framework has no path to re-enter the
  in-tree-orchestrator era; supplying a rollback path that
  briefly re-creates that era contradicts FW-ADR-0015's
  intent.

**Operator recovery documentation (release-engineer + tech-writer
work):** the rc15 release notes include a "if you hate the
new model" section with the exact `git` commands and a note
that re-running the bridging migration is supported (it
no-ops on already-bridged state; re-runs to recover from a
git-restored legacy state by re-bridging).

### 7. CI / smoke-testing gate (dogfood-vs-this-rc)

**Fixture-count arithmetic (single source of truth):** the dogfood
gate for rc15 comprises **12 fixtures total**, computed as:

- **9 existing fixtures** (3 codenames {alpha, beta, gamma} x 3
  states {scaffold, mid, latest}; harness:
  `tests/release-gate/dogfood-downstream.sh` or its successor;
  see `docs/pm/dogfood-2026-05-15-results.md`).
- **+ 2 added source-baseline fixtures** for v0.14.0 and v0.15.0
  (qa-engineer adds these to cover § 2's full source-baseline range
  beyond what the existing rc2..rc8 fixtures provide).
- **+ 1 `SWDT_PREBOOTSTRAP_FORCE` coverage fixture** (qa-engineer
  adds a fixture exercising the forced-pre-bootstrap audit-log
  path).
- **= 12 total.**

**Gate: 12/12 dogfood PASS against the rc15 candidate before the
`v1.0.0-rc15` tag is cut.** All downstream sections and the §
Verification cross-references derive from this 12-total count.

**PASS criteria for each fixture:**

- **`upgrade` exit 0.** The rc15 `scripts/upgrade.sh` runs the
  bridging migration successfully; the project transitions to
  the stub model.
- **`verify` exit 0** (post-bridge `scripts/upgrade.sh --verify`,
  which is now the stub forwarding to a fetched runner). The
  runner's manifest verification passes against the project's
  `TEMPLATE_STATE.json`.
- **State-file presence.** `TEMPLATE_STATE.json` exists at
  project root, schema-valid per FW-ADR-0016.
- **Legacy artefact absence.** `TEMPLATE_VERSION`,
  `TEMPLATE_MANIFEST.lock`, `.template-customizations` are
  not present in the project tree.
- **Stub installed.** `scripts/upgrade.sh` is the FW-ADR-0015
  stub (sub-100 lines; expected sha256 matches the rc15 build
  output).
- **No conflicts on customisation paths.** Files declared
  `customised` in the synthesised `TEMPLATE_STATE.json` are
  byte-identical to their pre-bridge state.
- **AI-TUI interaction check** (per the
  `feedback_dogfood_needs_tui_check` memory). A scripted
  Claude Code session against the post-bridge project performs
  a representative operation (commit, edit, dispatch a
  specialist) without harness errors.

**FAIL → re-iterate (with carve-out criterion).** 12/12 PASS is the
floor; any FAIL blocks the rc15 tag cut UNLESS the failing fixture
corresponds to a customer-acknowledged out-of-scope baseline
(specifically the pre-v0.13.0 refusal cases per § 2) AND the
refusal is the expected behaviour (clear error naming the required
intermediate target, exit non-zero). A "refusal-as-expected"
fixture is counted as PASS for gate purposes. Any other FAIL
keeps the rc15 branch on `main` (or a release branch) under
continued iteration until the gate clears. The customer's
"dogfood before rc" rule is the gate.

### 8. Coordination with FW-ADR-0019

This ADR ends the in-tree-rc era. FW-ADR-0019 retires the
pre-bootstrap class.

**Framing: rc15 is the intended-LAST pre-bootstrap instance, with
a documented escape hatch.** The original "LAST" framing is not
strictly enforceable against the customer's binding "dogfood
before cutting an rc" rule (2026-05-15) — if a defect surfaces
post-tag-cut by a real-world fixture the 12/12 harness missed,
the only honest fix vehicle is another in-tree rc.

**Escape hatch (binding clause):** if rc15 ships broken (defect
surfaced post-tag-cut by a real-world fixture the 12/12 harness
missed), the framework's escape hatch is `v1.0.0-rc15.1` under the
same 12/12 + AI-TUI dogfood gate. rc15.x follow-ups are permitted
under this clause only; each follow-up resets the FW-ADR-0019
unblock condition. FW-ADR-0019 stays blocked until the rc15
lineage actually lands clean (rc15 PASS OR rc15.x PASS for
highest-x in the lineage). The "LAST pre-bootstrap" property is
asserted of the rc15 LINEAGE as a whole, not of the rc15 tag in
isolation.

**Dependency: FW-ADR-0019 CANNOT ship until FW-ADR-0018's
transitional rc15 lineage has cut successfully and at least one
downstream has run it.** The reasons:

- The rc15 bridging migration is the LAST pre-bootstrap
  instance (or the rc15.x lineage's terminal member if the
  escape hatch fires). FW-ADR-0019 retires the entire
  `prebootstrap_*` helper family on the strength of the rc15
  lineage having shipped correctly.
- If rc15 ships broken and a follow-up rc15.1 is required,
  FW-ADR-0019's "pre-bootstrap is retired" claim is false
  until the rc15 lineage finally lands.
- FW-ADR-0019's status field reads "blocked on FW-ADR-0018
  ship" until the highest-x rc15.x tag is cut AND at least one
  dogfood-vs-rc15.x PASS confirms the bridge works on a
  representative baseline.

**Non-pre-bootstrap-class follow-ups (out of scope for this clause):**
post-rc15 fixes that do NOT touch the pre-bootstrap or bridging
machinery — runner-side bugs, stub fetch logic, downstream-tree
content — are normal upstream-side fixes against the post-bridge
stub model; they do not require an in-tree rc and do not affect
the "LAST pre-bootstrap" property. Operators re-fetch the runner
via the stub's normal flow.

**FW-ADR-0019's content (forward-referenced; not pinned here):**
formal supersession of FW-ADR-0010 and FW-ADR-0013;
deprecation tail for `SWDT_PREBOOTSTRAP_FORCE` env var (becomes
documented no-op); deprecation tail for
`.template-prebootstrap-blocked.json` artefact (becomes
documented no-op); audit-log column `Gate=pre-bootstrap`
becomes append-only (no new rows after the rc15-lineage terminal
ship date).

### 9. TEMPLATE_VERSION -> schema_version mapping

The bridging migration reads `TEMPLATE_VERSION` line 1 to
determine the source-baseline version. After migration,
`TEMPLATE_STATE.json.template.version` carries that value.

**Mapping: identity. Be explicit.**

| `TEMPLATE_VERSION` line 1 | `TEMPLATE_STATE.json.template.version` |
|---------------------------|----------------------------------------|
| `v0.13.0`                 | `v0.13.0`                              |
| `v0.14.0`                 | `v0.14.0`                              |
| `v0.14.4`                 | `v0.14.4`                              |
| `v0.15.0`                 | `v0.15.0`                              |
| `v1.0.0-rc2`              | `v1.0.0-rc2`                           |
| `v1.0.0-rc12`             | `v1.0.0-rc12`                          |
| (anything else)           | (verbatim copy)                        |

`TEMPLATE_VERSION` line 1 is a free string per FW-ADR-0016 § "Top-level
shape and field names" ("Schema v1.0.0 leaves `template.version`
as a free string by intent — no format constraint"). The
bridging migration preserves operator-edited values verbatim
(e.g., an SHA pinned by the operator instead of a tag).
Format validation is a future MINOR concern, not this ADR's.

**Note: `schema_version` and `template.version` are independent
fields.** `schema_version` is the schema's own version
(`1.0.0` at this ADR's acceptance; FW-ADR-0016 owns its
evolution). `template.version` is the project's last-synced
template version. The two are decoupled — a future schema
v1.1.0 would still carry projects on `template.version =
v1.0.0-rc15` or `v1.0.0` or `v1.1.0` independently.

After the bridging migration completes and the rc15 sync loop
proceeds, `template.version` advances to `"v1.0.0-rc15"` at
sync exit (this is the normal sync-loop behaviour; the
bridging migration itself only synthesises the initial state
file, it does not advance the version).

## Consequences

### Positive

- **Existing downstreams are not stranded.** Every project
  in the supported source-baseline range (§ 2) has a documented
  single-step transition onto the stub model.
- **Operator UX is unchanged for the transition.** Operators
  run `scripts/upgrade.sh` exactly as they always have; the
  framework does the rest. No new operator command, no new
  invocation pattern.
- **Pre-bootstrap class retires.** FW-ADR-0019 lands on the
  strength of this ADR shipping. After FW-ADR-0019, the
  framework no longer carries the FW-ADR-0010 pattern.
- **In-tree-rc era ends.** After rc15, `scripts/upgrade.sh`
  IS the stub. Future structural changes to the upgrade flow
  happen in the runner; no per-cliff in-tree rc is required.
- **State-file consolidation completes.** Post-rc15, every
  downstream has `TEMPLATE_STATE.json` as the single source
  of truth; the FW-ADR-0014 Q1 race is behind us.
- **Three-Path Rule is honoured in this ADR's own scope.**
  Customer ruled S at the FW-ADR-0015 level (transitional
  runner path); this ADR's Option M = the customer's S. No
  loss of three-alternative discipline.
- **Dogfood gate aligns with customer rule.** The 12/12 PASS
  requirement (per § 7 arithmetic) before rc15 cuts is the
  binding "dogfood before rc" rule applied to this transitional
  rc.

### Negative / trade-offs accepted

- **One more in-tree rc to cut + dogfood.** Engineering and
  release cost. Bounded; non-recurring.
- **The LAST pre-bootstrap MUST be perfect.** If rc15 ships
  with a broken pre-bootstrap, the fix vehicle is "yet another
  in-tree rc" — contradicting this ADR's "LAST" commitment.
  The dogfood gate (§ 7) is the structural defence; the
  customer's "dogfood before rc" rule is the cultural defence.
- **Pre-v0.13.0 baselines unsupported.** Operators (if any) on
  pre-v0.13.0 projects must first advance to v0.13.0+ via a
  rc12-or-earlier upgrade chain, then run rc15. Customer
  confirmed no known pre-v0.13.0 downstreams exist; cost is
  hypothetical.
- **No formal rollback.** Operator's git history IS the
  rollback story (§ 6). Operators who don't commit before
  running the bridge accept that risk.
- **rc15 carries the full legacy `scripts/upgrade.sh` body
  one more time.** Frozen feature set, one new migration
  appended. The carry cost is bounded to one release.
- **Runner-pin recording deferred to first post-bridge sync.**
  Minor UX wrinkle — the first post-bridge `scripts/upgrade.sh`
  invocation does a network fetch and records the TOFU pin.
  Operators expecting the bridge to "fully complete" without
  network access on first post-bridge run are surprised.
  Release notes (`tech-writer` work) call this out.
- **Idempotency detection is more complex than FW-ADR-0017's
  baseline shape.** The refined detection rule (§ 5) tracks
  state-file presence AND stub installation AND legacy file
  absence to catch partial-bridge states. The complexity is
  bounded; the rationale (graceful recovery from mid-bridge
  crashes) justifies it.

## Verification

How we know FW-ADR-0018 is correctly landed:

- **Success signal A — dogfood-vs-rc15 = 12/12 PASS** (per § 7
  arithmetic: 9 existing + 2 added baselines + 1
  `SWDT_PREBOOTSTRAP_FORCE` coverage) before tag cut. The
  customer's "dogfood before rc" rule is honoured by construction.
  Any FAIL blocks the cut except under the § 7 refusal-as-expected
  carve-out.
- **Success signal B — every supported source-baseline
  bridges in a single `scripts/upgrade.sh` run.** No operator
  manual step required between source and target other than
  running `scripts/upgrade.sh`.
- **Success signal C — bridging migration is idempotent.**
  Running rc15 twice in sequence against the same fixture
  produces identical project state; the second run emits the
  no-op signature line.
- **Success signal D — partial-state recovery.** A fixture
  with the migration killed mid-step (b) (state file written
  but stub not yet installed) recovers on re-run; the bridging
  migration completes the remaining steps and emits a
  recovery-success log line.
- **Success signal E — FW-ADR-0019 unblocks.** After rc15
  ships AND at least one downstream PASSes dogfood against
  it (the customer's own project counts), FW-ADR-0019's
  status moves from `proposed/blocked` to `proposed/unblocked`
  and the pre-bootstrap retirement work begins.
- **Failure signal — pre-bootstrap-class regression.** If
  the rc15 bridging migration's pre-bootstrap fails on a
  fixture that the same FW-ADR-0010 pattern handled
  correctly in `migrations/v0.14.0.sh`, the regression IS
  the failure signal. Routes to `architect` for re-review.
- **Failure signal — schema-validation false positive on
  legitimate state.** If the migration function's output
  fails the FW-ADR-0016 schema validator on a legitimate
  legacy-state shape, the schema is wrong (mirrors
  FW-ADR-0016 § Verification). Routes to FW-ADR-0016 for
  schema revision; not a bypass.
- **Review cadence:** at rc15 tag cut (with the 12/12
  dogfood evidence attached), and again at the first stable
  release (v1.0.0 or v1.1.0) post-bridge. Re-open if any
  failure signal fires within 6 months.

## Implementation notes for software-engineer

Scope for FW-ADR-0018-impl. The architect describes the
contract; the SE implements. This is **substantial work** —
three co-shipping pieces, each non-trivial.

**Piece 1: The FW-ADR-0015 stub itself.** Per FW-ADR-0015
§ "Implementation notes for software-engineer." Sub-100-line
budget; `--target` / `--dry-run` / `--verify` / `--help` /
`--no-verify` / `--` CLI surface; fetch-via-curl; checksum-
verify; exec the runner. No dependency on
`scripts/lib/`. Shipped in the rc15 tree at a staging path
(SE's choice; `template-files/upgrade-stub.sh` is a
suggestion); the bridging migration's step (c) atomic-renames
it into `scripts/upgrade.sh`.

**Piece 2: The runner itself.** Per FW-ADR-0015 + FW-ADR-0016
+ FW-ADR-0017. The rc15 tree ships
`scripts/upgrade-runner.sh` as the runner; the stub fetches
this file by ref from upstream. The runner is what the
post-bridge upgrade flow lands on; its full implementation is
the FW-ADR-0015-impl scope, not this ADR's. This ADR's
constraint: the runner ships in the rc15 tree at the
upstream-fetchable path so post-bridge `scripts/upgrade.sh`
(now the stub) can pull it.

**Piece 3: The bridging migration itself.**
`migrations/v1.0.0-rc15.sh`. Per § 3 above. Inherits
`migrations/v0.14.0.sh` lines 42-262 (named functions:
`prebootstrap_sha` + the 3-SHA decision-matrix loop + the
refuse/force block-artefact handling + the proceed-list atomic
install) pre-bootstrap atomic-rename machinery verbatim for the
bootstrap-critical fileset; adds the FW-ADR-0016 state
consolidation; adds the second-atomic-rename for the stub install;
adds the legacy file removal; the runner-pin recording is deferred
per § 3(e).

**Co-ship sequencing:**

- The stub (Piece 1) and the runner (Piece 2) must be in
  the rc15 tree before the bridging migration (Piece 3) is
  authored — the migration references both.
- All three pieces co-ship in rc15; the tag cut is gated on
  12/12 dogfood-vs-rc15 PASS per § 7.

**Specific implementation notes:**

- The bridging migration's `expected_stub_sha` (§ 5 detection
  rule) is computed at rc15 build time from Piece 1's
  shipped content; bake into the migration body as a constant.
- The migration's pre-bootstrap block uses
  `migrations/v0.14.0.sh` lines 42-262 as the prior art (named
  functions: `prebootstrap_sha`, the 3-SHA decision-matrix loop,
  the refuse/force block-artefact handler, and the proceed-list
  atomic install); the bootstrap-critical fileset is
  `scripts/upgrade.sh` plus `scripts/lib/*.sh` exactly as v0.14.0
  has it. The rc15 stub itself is NOT in the bootstrap-critical
  fileset during the pre-bootstrap step — it has not yet been
  installed.
- The migration's state consolidation invokes the FW-ADR-0016
  migration function; SE may implement that function as a
  helper in `scripts/lib/template-state.sh` and source it
  from the migration. The helper lives in the rc15 tree
  (it must — the post-bridge runner also needs it).
- The migration's stub install is a second atomic-rename
  pattern on `scripts/upgrade.sh`. Care: the rc15
  `scripts/upgrade.sh` is the process running the migration.
  The `mv` + `fsync` pattern works (the running process
  keeps its open fd on the unlinked inode); SE verifies
  on the test bench.
- The migration's legacy-file removal is `rm` (atomic);
  preceded by a sanity check that `TEMPLATE_STATE.json` is
  on disk and schema-valid.
- The migration's idempotency-detection helper checks state
  file presence AND stub installation AND legacy file
  absence per § 5; partial-state recovery completes the
  missing steps.

**Unit tests (`qa-engineer` scope):**

- (a) Fresh bridge from each supported source-baseline
  (v0.13.0, v0.14.0, v0.14.4, v0.15.0, v1.0.0-rc2..rc12) —
  9 paths plus the 2 additional baselines per § 7.
- (b) Idempotent re-run on already-bridged state — emits
  no-op signature, exit 0.
- (c) Partial-bridge recovery: state file written but stub
  not installed → re-run completes; stub installed but
  legacy files not removed → re-run completes.
- (d) Pre-bootstrap refusal: project with local edit to
  `scripts/upgrade.sh` → migration refuses; re-run with
  `SWDT_PREBOOTSTRAP_FORCE=1` → migration proceeds; audit
  row appended.
- (e) Pre-v0.13.0 baseline refusal: project with
  `TEMPLATE_VERSION` line 1 = `v0.6.2` → migration refuses
  with clear error naming required intermediate target.
- (f) Schema-validation failure on synthesised
  `TEMPLATE_STATE.json` — migration aborts, legacy files
  remain intact, project state unchanged.
- (g) Post-bridge runner fetch: stub (now installed)
  fetches runner from upstream; TOFU pin recorded in
  `runner_pin`.

`code-reviewer` reviews; `security-engineer` reviews the
pre-bootstrap inheritance and the atomic-rename sequencing
for race conditions.

## Open questions

None blocking ADR acceptance. The customer's 2026-05-15 S-ruling
endorses this ADR's Option M (architect's Minimalist path = the
transitional-runner path the customer chose at the FW-ADR-0015
level). The nine decision axes in § Interface decisions are pinned
by this ADR.

**Items deferred to FW-ADR-0018-impl (software-engineer scope, not
customer-facing):**

- The exact staging path for the stub in the rc15 tree
  (`template-files/upgrade-stub.sh` is a suggestion; SE picks).
- The exact location of the `TEMPLATE_STATE.json` migration helper
  (`scripts/lib/template-state.sh` is a suggestion; SE picks).
- The exact text of the rc15 release notes' "if you hate the new
  model" rollback section (`tech-writer` scope, not architect).

**Items routed to FW-ADR-0019 (sequenced after this ADR ships):**

- Formal supersession status-line updates on FW-ADR-0010 and
  FW-ADR-0013.
- Deprecation-tail handling for `SWDT_PREBOOTSTRAP_FORCE`,
  `.template-prebootstrap-blocked.json`, and the audit-log
  `Gate=pre-bootstrap` column.

## Links

- Foundation ADRs:
  - `docs/adr/fw-adr-0015-upgrade-orchestrator-stub-model.md`
    (stub model; this ADR operationalises its "Migration path
    forward" section).
  - `docs/adr/fw-adr-0016-template-state-json-schema.md`
    (state schema; this ADR invokes its migration function
    shape).
  - `docs/adr/fw-adr-0017-file-keyed-migration-discovery.md`
    (discovery; this ADR's migration ships as
    `migrations/v1.0.0-rc15.sh` per the discovery convention).
- Inherited pattern:
  - `docs/adr/fw-adr-0010-pre-bootstrap-local-edit-safety.md`
    (LAST instance of the pre-bootstrap class; FW-ADR-0019
    formally retires it post-rc15-ship).
  - `docs/adr/fw-adr-0013-rc-to-rc-pre-bootstrap.md` (rc-to-rc
    precedent; superseded by this ADR's structural fix).
- Reference implementation:
  - `migrations/v0.14.0.sh` lines 42-262 (pre-bootstrap pattern
    this ADR inherits verbatim; named functions:
    `prebootstrap_sha`, the 3-SHA decision-matrix loop, the
    refuse/force block-artefact handler, and the proceed-list
    atomic install).
- Forward-referenced:
  - FW-ADR-0019 — pre-bootstrap retirement (depends on this
    ADR shipping successfully).
- Customer rulings (CUSTOMER_NOTES.md, 2026-05-15):
  - "S — one more in-tree rc bridges existing downstreams
    onto the stub model" (migration-path ruling endorsing
    this ADR's Option M).
  - "dogfood before cutting an rc" (binding gate per § 7).
- Dogfood evidence:
  - `docs/pm/dogfood-2026-05-15-results.md` (the 0/9 PASS
    against rc12 baseline; the failure data this ADR's
    transitional rc dissolves).
  - `docs/pm/upgrade-flow-conceptual-mistake-2026-05-15.md`.
  - `docs/pm/upgrade-flow-process-debt-2026-05-15.md`.
- External references:
  - MADR 3.0 (`https://adr.github.io/madr/`).
  - SemVer 2.0 (`https://semver.org/spec/v2.0.0.html`) — for
    the source-baseline range comparisons in § 2.
