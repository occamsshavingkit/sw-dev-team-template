---
name: fw-adr-0013-rc-to-rc-pre-bootstrap
description: Add a versioned pre-bootstrap migration (v1.0.0-rc13.sh) cloned from v0.14.0.sh so rc-to-rc upgrades on pre-v0.15.0 upgrade.sh drivers self-bootstrap safely; FW-ADR-0010 interface inherits unchanged.
status: accepted
date: 2026-05-15
---


# FW-ADR-0013 — rc-to-rc pre-bootstrap via cloned migration

<!-- TOC -->

- [Status](#status)
- [Context and problem statement](#context-and-problem-statement)
- [Decision drivers](#decision-drivers)
- [Considered options (Three-Path Rule, binding)](#considered-options-three-path-rule-binding)
  - [Option M — Minimalist: clone the pre-bootstrap block into a new versioned migration](#option-m--minimalist-clone-the-pre-bootstrap-block-into-a-new-versioned-migration)
  - [Option S — Scalable: extract the pre-bootstrap block into a sourced helper used by every cliff migration](#option-s--scalable-extract-the-pre-bootstrap-block-into-a-sourced-helper-used-by-every-cliff-migration)
  - [Option C — Creative: drop pre-bootstrap entirely; require operators on pre-v0.15.0 drivers to retrofit `scripts/upgrade.sh` by hand](#option-c--creative-drop-pre-bootstrap-entirely-require-operators-on-pre-v0150-drivers-to-retrofit-scriptsupgradesh-by-hand)
- [Decision outcome](#decision-outcome)
  - [Out-of-range refusal (hybrid clause)](#out-of-range-refusal-hybrid-clause)
  - [Inherited FW-ADR-0010 interface (binding)](#inherited-fw-adr-0010-interface-binding)
  - [Implementation notes for software-engineer](#implementation-notes-for-software-engineer)
- [Consequences](#consequences)
  - [Positive](#positive)
  - [Negative / trade-offs accepted](#negative--trade-offs-accepted)
  - [Follow-up ADRs](#follow-up-adrs)
- [Relationship to other ADRs and issues](#relationship-to-other-adrs-and-issues)
- [Verification](#verification)
- [Links](#links)

<!-- /TOC -->

Shape per MADR 3.0 + this template's Three-Path Rule
(`docs/templates/adr-template.md`).

---

## Status

- **Proposed: 2026-05-15**
- **Accepted: 2026-05-15**
- **Deciders:** `architect` + `tech-lead` + customer (cross-cutting
  pattern change to the migration queue; customer approval required
  per CLAUDE.md Hard Rules)
- **Consulted:** `software-engineer` (implementation on branch
  `fix/blocker-1-rc-to-rc-prebootstrap`, commit `c7599b5`),
  `release-engineer` (CI dogfood follow-up), `qa-engineer` (smoke
  coverage for rc-to-rc upgrade fixtures), FW-ADR-0010 (pre-bootstrap
  interface contract this ADR inherits verbatim).

## Context and problem statement

FW-ADR-0010 added a pre-bootstrap step to `scripts/upgrade.sh` and
to `migrations/v0.14.0.sh` so that pre-v0.15.0 upgrade drivers atomic-
replace bootstrap-critical files (`scripts/upgrade.sh`,
`scripts/lib/*.sh`) **before** the in-place-cp bug at line ~417 of the
old driver can corrupt the running shell. That fix works for the
cross-MAJOR cliff (v0.14.0). It does not cover the rc-to-rc cliff: a
project stamped at v1.0.0-rc2 whose `scripts/upgrade.sh` predates
v0.15.0's self-bootstrap block, upgrading toward v1.0.0-rc13. The
v0.14.0 migration's pre-bootstrap block only runs when the migration
queue elects v0.14.0; on the rc-to-rc path the queue jumps past it
and pre-bootstrap never executes. The rc2-era driver then hits the
in-place-cp bug mid-loop, exactly the failure mode FW-ADR-0010 was
shaped to prevent.

The customer's 2026-05-15 ruling (Blocker #1) accepts that future
rc-to-rc structural cliffs in `upgrade.sh` may each require a fresh
pre-bootstrap migration — the architect-side check on
structural-rewrite ADRs is to spawn one. ADR-trigger rows that fire:
cross-cutting pattern change (the migration queue now carries a
shape-class of "pre-bootstrap migration"), choice that locks future
releases into a per-cliff migration obligation, and a public-API
surface change (a new versioned migration shipped to every downstream
upgrade). Dogfood evidence sits in
`docs/pm/dogfood-2026-05-15-results.md`.

## Decision drivers

- **Cross-rc safety must survive.** The original FW-ADR-0010 fix
  closes the in-place-cp inode bug on the v0.14.0 cliff; the same bug
  is live on the rc2-era driver every time the migration queue jumps
  past v0.14.0 toward a later rc. Whatever we ship must keep
  pre-v0.15.0 → rc13+ upgrades from crashing mid-loop.
- **No edits to `scripts/upgrade.sh`.** The old rc2-era driver is the
  *running* file we are trying to protect; the fix must arrive on a
  path the old driver already exercises reliably. The pre-sync
  migration runner is that path — the old driver runs migrations
  before its sync loop touches `scripts/upgrade.sh`.
- **FW-ADR-0010 interface stays intact.** Operators and CI gates
  already key off `SWDT_PREBOOTSTRAP_FORCE=1`, exit code 2,
  `.template-prebootstrap-blocked.json`, and the `Gate=pre-bootstrap`
  audit row. A second pre-bootstrap migration must use the same
  surface, not a parallel one.
- **De-dup catch-22 is real.** The natural urge is to extract the
  shared pre-bootstrap logic into `scripts/lib/prebootstrap.sh` and
  have every migration source it. But that helper would itself be a
  bootstrap-critical file — and pre-bootstrap is the thing protecting
  bootstrap-critical files from in-place clobber. The helper is not
  yet trustworthy at the moment pre-bootstrap must run; sourcing it
  from a migration that runs before pre-bootstrap is a re-entrant
  bootstrap loop with no fixed point.
- **Idempotency.** Re-running upgrade after the operator resolves a
  refusal must converge, the same invariant FW-ADR-0010 carries.
- **Out-of-range safety.** A pre-bootstrap migration whose runner
  conditions are not met (e.g., the rc13 migration triggers on a
  stamped version it cannot reason about) must refuse, not silently
  no-op. Silent no-op on the wrong stamped range reintroduces the
  in-place-cp bug under conditions the migration was supposed to
  cover.

## Considered options (Three-Path Rule, binding)

### Option M — Minimalist: clone the pre-bootstrap block into a new versioned migration

Ship `migrations/v1.0.0-rc13.sh` as a near-verbatim clone of
`migrations/v0.14.0.sh` lines 42–277 — the pre-bootstrap block, minus
the v0.14.0-specific manifest-synthesis tail. The cloned migration
runs from the pre-sync migration runner, which the rc2-era driver
reliably exercises before its sync loop touches `scripts/upgrade.sh`.

- **Sketch:** New file at `migrations/v1.0.0-rc13.sh`. Header rewritten
  for the rc-to-rc context, with a comment block citing FW-ADR-0013
  and the de-dup catch-22. Pre-bootstrap body is the v0.14.0 clone:
  `prebootstrap_sha`, the bootstrap-critical path list build, the
  3-SHA matrix per FW-ADR-0010, the atomic-mv replacement loop, the
  block-artefact writer, and the audit-row appender. No
  manifest-synthesis tail — that was v0.14.0-specific.
- **Pros:**
  - Zero risk of breaking the de-dup helper that pre-bootstrap is
    supposed to protect — the helper does not exist.
  - The cloned migration is read-once at queue time; once
    `scripts/upgrade.sh` is atomic-replaced, future runs use the new
    driver's own self-bootstrap.
  - Implementation cost is bounded: the v0.14.0 block already passed
    FW-ADR-0010 review; cloning it carries forward that scrutiny.
  - No new public-API surface beyond what FW-ADR-0010 already
    committed to (exit 2, env var, block artefact, audit-log column).
  - Future structural cliffs in `upgrade.sh` get the same fix shape —
    one more cloned migration, one more architect-side check on the
    triggering ADR.
- **Cons:**
  - ~235 lines duplicated between `v0.14.0.sh` and `v1.0.0-rc13.sh`.
    A bug in the pre-bootstrap matrix has to be fixed in N+1 places.
  - Drift risk: a maintainer fixes one and forgets the other. The
    mitigation is structural — the cloned migrations are immutable
    after release (per FW-ADR-0004's per-migration-version rule); the
    only realistic drift is in the comments.
  - Each new cliff is a new migration file. The migrations directory
    grows linearly with structural rewrites of `upgrade.sh`. Cost is
    bounded by the rate of structural rewrites, which is low.
- **When M wins:** when the alternative is a helper that itself lives
  in the file class pre-bootstrap protects (the catch-22). M wins
  here.

### Option S — Scalable: extract the pre-bootstrap block into a sourced helper used by every cliff migration

Move the pre-bootstrap body into `scripts/lib/prebootstrap.sh`. Each
cliff migration becomes a thin wrapper that sources the helper and
invokes its main function with the bootstrap-critical path list. The
helper is unit-tested once; every cliff migration is < 30 lines.

- **Sketch:** Three files instead of one. `scripts/lib/prebootstrap.sh`
  carries the logic. `migrations/v0.14.0.sh` is rewritten to source
  it (post-hoc; FW-ADR-0004 says we should not, but ignore that for
  this option). `migrations/v1.0.0-rc13.sh` is the new thin wrapper.
- **Pros:**
  - Single source of truth for pre-bootstrap logic; bug-fix-once.
  - Migrations directory stays small.
  - Helper is unit-testable.
  - Matches the framework's general preference for shared
    `scripts/lib/*` over per-call clones.
- **Cons:**
  - **De-dup catch-22 (fatal).** `scripts/lib/prebootstrap.sh` is
    itself a bootstrap-critical file: it sits in `scripts/lib/*.sh`,
    which is exactly the path class FW-ADR-0010's matrix protects.
    For pre-bootstrap to source it, the file must already be in
    place on disk. But pre-bootstrap is the thing that puts the
    correct version on disk. If the project's stamped version
    predates the helper, sourcing it pulls in either an absent file
    (sync error) or the project's customised/old version (defeats
    the protection). If the project's stamped version has the
    helper, the in-memory bash is reading whichever version was on
    disk at process start — which may differ from
    `$WORKDIR_NEW`'s version. Re-entrant bootstrap; no fixed point.
  - FW-ADR-0004 commits to immutability of released migrations.
    Rewriting `v0.14.0.sh` to source the helper post-release breaks
    that invariant.
  - Helper sourcing in a migration that runs before pre-bootstrap is
    a contradiction in terms — pre-bootstrap *is* the trust gate for
    `scripts/lib/*.sh`.
- **When S wins:** if `scripts/lib/prebootstrap.sh` could be
  guaranteed-correct on disk at the moment the migration starts,
  independent of pre-bootstrap. It cannot. S loses on the catch-22.

### Option C — Creative: drop pre-bootstrap entirely; require operators on pre-v0.15.0 drivers to retrofit `scripts/upgrade.sh` by hand

Accept that pre-v0.15.0 drivers are end-of-life. Publish a retrofit
procedure: the operator manually `cp $WORKDIR_NEW/scripts/upgrade.sh
$PROJECT_ROOT/scripts/upgrade.sh` from a separate checkout, then re-
runs `upgrade.sh` from the now-current driver. No pre-bootstrap
migration ships at all.

- **Sketch:** Migration queue ignores the rc-to-rc cliff. Release
  notes for rc13 carry a "Retrofit required for projects stamped at
  pre-v0.15.0" section pointing at the retrofit playbook. FW-ADR-0010
  still applies to the v0.14.0 cliff and to v0.15.0+ drivers; the
  rc-to-rc gap is closed by procedure, not by code.
- **Pros:**
  - Zero new migration to maintain.
  - Forces the framework to commit to a minimum-supported driver
    version, which has documentation value.
  - The retrofit playbook is already a load-bearing path under
    FW-ADR-0010 for the baseline-unreachable case; reusing it for
    pre-v0.15.0 drivers is dimension-consistent.
- **Cons:**
  - **Operator-load cost is large.** Every downstream project stamped
    at v1.0.0-rc2..rc12 (a substantial install base by 2026-05-15)
    must perform a manual retrofit before upgrading. The customer's
    framework/project boundary commitment is "the upgrade just works
    on a vanilla project"; this option breaks that for a known cliff.
  - **Discovery is too late.** The operator runs `./scripts/upgrade.sh`,
    sees the in-place-cp crash, *then* reads the release notes. The
    fail-loud-on-cliff fix arrives after the corruption.
  - Pre-empts a customer ruling that we should not be making
    unilaterally — declaring rc2-era projects unsupported is a
    customer-facing scope call, not an architectural one.
- **When C wins:** if the install base of pre-v0.15.0 projects were
  zero, or if the operator-load cost of the retrofit playbook were
  near-free. Neither holds.

## Decision outcome

**Chosen option: M (clone the pre-bootstrap block into a new versioned
migration), with the out-of-range refusal hybrid clause below.**

**Reason:** Option S is the textbook answer (single source of truth)
and fails on the de-dup catch-22 — the helper would itself be a
bootstrap-critical file, sourcing it before pre-bootstrap runs is a
re-entrant bootstrap loop. Option C punts the cost onto every
downstream operator carrying a pre-v0.15.0 driver, breaking the
framework's "upgrade just works on a vanilla project" commitment.
Option M cleanly preserves FW-ADR-0010's interface contract, runs on
a path the old driver already exercises (the pre-sync migration
runner), and accepts ~235 lines of intentional duplication as the
price of structural correctness. The architect-side obligation —
every future structural cliff in `upgrade.sh` spawns one more
pre-bootstrap migration of this shape — is small, bounded, and
already implicit in FW-ADR-0010's per-cliff posture.

### Out-of-range refusal (hybrid clause)

Pre-bootstrap migrations must NOT silently no-op when their target
range is mis-applied. If `migrations/v1.0.0-rc13.sh` runs against a
stamped version it cannot reason about (e.g., the migration queue
is misconfigured, or the stamped version is newer than the
migration's own target), the migration:

- Logs an explicit `ERROR` line naming the stamped version, the
  migration's intended range, and the FW-ADR-0013 reference.
- Exits 2 with `.template-prebootstrap-blocked.json` written and
  `reason=migration-out-of-range`. The block-artefact schema from
  FW-ADR-0010 absorbs this new reason value as an additive entry
  on the enumerated `reason` field.
- Does not attempt the atomic-replace.

Rationale: silent no-op on an out-of-range invocation reintroduces
the in-place-cp bug under exactly the conditions this migration was
supposed to cover. Refuse-on-uncertain matches FW-ADR-0010 and
FW-ADR-0002 posture.

### Inherited FW-ADR-0010 interface (binding)

This ADR inherits FW-ADR-0010's interface verbatim. No new public-API
surface beyond the new migration filename:

- **`SWDT_PREBOOTSTRAP_FORCE=1`** — same env var; overrides both the
  local-edit case and the baseline-unreachable case in this
  migration's pre-bootstrap pass.
- **Exit code 2** — same semantic (pre-bootstrap refused). The
  out-of-range refusal clause above shares this exit code.
- **`.template-prebootstrap-blocked.json`** — same artefact, same
  schema. The enumerated `reason` field gains the additive value
  `migration-out-of-range` (back-compatible: pre-rc13 readers see
  an unknown reason string but the surrounding object shape
  unchanged).
- **Audit-log row** — same surface
  (`docs/pm/pre-release-gate-overrides.md`); same `Gate=pre-bootstrap`
  value in the `Gate` column FW-ADR-0010 added.
- **Retrofit routing on unreachable-baseline** — same playbook
  (`docs/templates/retrofit-playbook-template.md`-shaped procedure);
  same `reason=baseline-unreachable` block-artefact value.

Operators and CI gates that already key off FW-ADR-0010's surface
need no behavioural updates for this migration.

### Implementation notes for software-engineer

The migration is already implemented on branch
`fix/blocker-1-rc-to-rc-prebootstrap`, commit `c7599b5`, at 285
lines. Cross-check against this ADR:

1. **Filename.** `migrations/v1.0.0-rc13.sh` (versioned per
   FW-ADR-0004; migration queue picks it up via the existing
   semver-ordered glob).
2. **Body.** Near-verbatim clone of `migrations/v0.14.0.sh` lines
   42–277. Pre-bootstrap body identical; manifest-synthesis tail
   (lines 278–end of v0.14.0) **omitted** — that step is
   v0.14.0-specific and would re-write a manifest that the rc13
   driver's post-sync `manifest_write` is already authoritative for.
3. **Header.** Rewritten for rc-to-rc context. Comment block cites
   FW-ADR-0013 by ID, names the de-dup catch-22 in one sentence,
   and explicitly notes the FW-ADR-0010 interface inheritance.
4. **No edits to `scripts/upgrade.sh`.** The whole point of this
   migration is to atomic-replace `scripts/upgrade.sh` before the
   old driver's sync loop touches it. Editing the driver itself
   would defeat the structure.
5. **Atomic-replace target set.** Same as FW-ADR-0010:
   `scripts/upgrade.sh` plus every `scripts/lib/*.sh` the candidate
   ships. Source is `$WORKDIR_NEW`; destination is `$PROJECT_ROOT`.
6. **Old driver's sync `cmp -s` post-condition.** After the
   atomic-replace, the OLD driver's sync loop reaches its `cmp -s`
   on `scripts/upgrade.sh` and sees equality (the file on disk now
   matches `$WORKDIR_NEW/scripts/upgrade.sh`), skipping the
   in-place-cp. This is the load-bearing property; the QA fixture
   must assert it.
7. **Out-of-range refusal.** Add the guard block at the top of the
   migration: read the project's stamped version from
   `TEMPLATE_VERSION`, compare against the migration's intended
   range, refuse with `reason=migration-out-of-range` on mismatch.
   Cite FW-ADR-0013 § "Out-of-range refusal" in the ERROR line.
8. **Audit-row writer.** Identical to v0.14.0's: append to
   `docs/pm/pre-release-gate-overrides.md` with `Gate=pre-bootstrap`
   before any atomic-mv. Refuses the override if the audit log is
   unwritable (same posture as FW-ADR-0010).

## Consequences

### Positive

- The rc-to-rc upgrade cliff closes structurally: projects stamped at
  v1.0.0-rc2..rc12 upgrading toward rc13+ get the same pre-bootstrap
  protection the v0.14.0 cliff already enjoys.
- FW-ADR-0010's interface stays the single public-API surface for
  pre-bootstrap; operators and CI gates need no behavioural updates.
- The cloned migration is read-once and immutable per FW-ADR-0004;
  drift risk reduces to the comment block.
- Future structural cliffs in `upgrade.sh` get a known pattern:
  spawn one more cloned migration; that obligation lives as an
  architect-side check on the triggering structural-rewrite ADR.
- Out-of-range refusal closes the silent-no-op failure mode that
  would have re-introduced the in-place-cp bug under exactly the
  conditions this migration covers.

### Negative / trade-offs accepted

- ~235 lines of pre-bootstrap body duplicated between
  `migrations/v0.14.0.sh` and `migrations/v1.0.0-rc13.sh`. A logic
  bug must be fixed in N+1 places. Mitigation is structural
  immutability (FW-ADR-0004) and the bounded growth rate of
  structural rewrites.
- The migrations directory grows by one file per future structural
  cliff in `upgrade.sh`. Cost scales linearly with rewrite cadence,
  which is low and architect-gated.
- The architect-side obligation to spawn a pre-bootstrap migration
  on every future structural rewrite is implicit; it must be
  cross-referenced from the structural-rewrite ADR's checklist
  rather than enforced by tooling.
- Adds `migration-out-of-range` to the enumerated `reason` field of
  `.template-prebootstrap-blocked.json`. Back-compatible (pre-rc13
  readers see an unknown reason string; the surrounding object
  shape is unchanged) but future schema readers must accept the
  additive value.

### Follow-up ADRs

- None required for this ADR's scope. A future ADR may revisit the
  per-cliff cloning posture if the `scripts/lib/*` surface gains a
  trust-pinned bootstrap mechanism (e.g., a content-addressed
  shipping artefact verifiable independently of the running shell)
  that resolves the de-dup catch-22.

## Relationship to other ADRs and issues

- **FW-ADR-0010 (pre-bootstrap local-edit safety).** This ADR
  inherits FW-ADR-0010's interface verbatim and extends its coverage
  from the v0.14.0 cliff to the rc-to-rc cliff. No interface
  change; one new artefact (the cloned migration) and one additive
  `reason` value (`migration-out-of-range`).
- **FW-ADR-0004 (per-item file breakout).** This ADR honours
  FW-ADR-0004's immutability rule for released migrations: the
  cloned migration is shipped once at rc13 and never edited
  post-release. Drift mitigation rests on that immutability.
- **FW-ADR-0002 (upgrade content verification).** The cloned
  migration's refuse-on-uncertain posture (matrix from FW-ADR-0010
  + out-of-range refusal here) is the same shape FW-ADR-0002
  carries for the regular sync loop. The framework now has one
  consistent posture across all three windows: pre-bootstrap
  (FW-ADR-0010 + this ADR), regular sync (FW-ADR-0002), and
  post-sync manifest verify (FW-ADR-0002).

## Verification

- **Success signal:** rc-to-rc dogfood fixture in
  `docs/pm/dogfood-2026-05-15-results.md` PASSes; a project stamped
  at v1.0.0-rc2 with a vanilla `scripts/upgrade.sh` upgrades to rc13
  without the in-place-cp crash and with no block artefact written.
  A second fixture (project stamped at rc2 with an SPDX header on
  `scripts/upgrade.sh`) refuses with exit 2, writes the block
  artefact with `reason=local-edit`, and proceeds correctly on a
  re-run with `SWDT_PREBOOTSTRAP_FORCE=1`. An out-of-range fixture
  (migration invoked against an unstamped or mis-stamped project)
  refuses with `reason=migration-out-of-range`.
- **Failure signal:** an upstream issue reports either (i) the
  in-place-cp crash recurring on the rc-to-rc cliff, (ii) the cloned
  migration writing a block artefact with a `reason` value pre-rc13
  schema readers cannot tolerate, (iii) the cloned migration silently
  no-op-ing on an out-of-range invocation, or (iv) drift between
  v0.14.0 and v1.0.0-rc13's pre-bootstrap matrix producing divergent
  refusal decisions on the same fixture.
- **Review cadence:** at the next MINOR release that introduces a
  structural rewrite of `scripts/upgrade.sh`. Reconsider if any
  failure signal fires, or if the `scripts/lib/*` shipping mechanism
  gains content-addressed trust pinning that resolves the de-dup
  catch-22.

## Links

- Upstream issues:
  - `#170 — pre-bootstrap respects local edits` (FW-ADR-0010,
    inherited)
  - Blocker #1 (this ADR; rc-to-rc pre-bootstrap gap)
- Related ADRs:
  - `FW-ADR-0010 — pre-bootstrap local-edit safety` (interface
    inherited verbatim)
  - `FW-ADR-0004 — per-item file breakout` (immutability rule for
    released migrations)
  - `FW-ADR-0002 — upgrade content verification` (refuse-on-uncertain
    posture this ADR extends)
- Related artefacts:
  - `migrations/v1.0.0-rc13.sh` (this ADR's deliverable; implemented
    on branch `fix/blocker-1-rc-to-rc-prebootstrap`, commit `c7599b5`,
    285 lines)
  - `migrations/v0.14.0.sh` (lines 42–277 — the cloned source)
  - `scripts/upgrade.sh` (NOT edited by this ADR; the file the
    pre-bootstrap protects from in-place-cp)
  - `docs/pm/pre-release-gate-overrides.md` (audit-log surface
    inherited from FW-ADR-0010)
  - `docs/pm/dogfood-2026-05-15-results.md` (rc-to-rc dogfood
    evidence)
- External references: MADR 3.0 (`https://adr.github.io/madr/`).
