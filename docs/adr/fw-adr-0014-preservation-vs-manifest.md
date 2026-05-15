---
name: fw-adr-0014-preservation-vs-manifest
description: Preservation is honoured only on divergence-AND-non-manifest-fresh-write paths (refuse-on-uncertain on conflict); upgrade's tail emits a two-phase exit replacing the single-line "Done." with migration-complete + verification.
status: proposed
date: 2026-05-15
---


# FW-ADR-0014 — Preservation vs manifest (divergence-only + two-phase exit)

<!-- TOC -->

- [Status](#status)
- [Context and problem statement](#context-and-problem-statement)
- [Decision drivers](#decision-drivers)
- [Considered options (Three-Path Rule, binding)](#considered-options-three-path-rule-binding)
  - [Q1 — Preservation rule](#q1--preservation-rule)
    - [Option M — Minimalist: trust `.template-customizations` verbatim](#option-m--minimalist-trust-template-customizations-verbatim)
    - [Option S — Scalable: divergence-only AND manifest-respecting (refuse-on-uncertain)](#option-s--scalable-divergence-only-and-manifest-respecting-refuse-on-uncertain)
    - [Option C — Creative: drop the preservation list; derive preservation from divergence alone](#option-c--creative-drop-the-preservation-list-derive-preservation-from-divergence-alone)
  - [Q2 — Upgrade tail shape](#q2--upgrade-tail-shape)
    - [Option M — Minimalist: keep the single-line "Done." tail](#option-m--minimalist-keep-the-single-line-done-tail)
    - [Option S — Scalable: two-phase exit (migration complete + verification)](#option-s--scalable-two-phase-exit-migration-complete--verification)
    - [Option C — Creative: structured JSON tail with embedded verification report](#option-c--creative-structured-json-tail-with-embedded-verification-report)
- [Decision outcome](#decision-outcome)
  - [Q1 decision — divergence-only AND manifest-respecting (Option S)](#q1-decision--divergence-only-and-manifest-respecting-option-s)
  - [Back-compat for already-polluted downstreams](#back-compat-for-already-polluted-downstreams)
  - [Q2 decision — two-phase exit (Option S)](#q2-decision--two-phase-exit-option-s)
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
(`docs/templates/adr-template.md`). Two coupled decisions (Q1
preservation rule, Q2 tail shape) are recorded in a single ADR because
they share the same triggering blocker and the same audit-log /
exit-code surface.

---

## Status

- **Proposed: 2026-05-15**
- **Deciders:** `architect` + `tech-lead` + customer (cross-cutting
  pattern change to upgrade preservation semantics and to the upgrade
  exit contract; customer approval required per CLAUDE.md Hard Rules)
- **Consulted:** `software-engineer` (implementation), `qa-engineer`
  (smoke coverage on already-polluted fixtures), `release-engineer`
  (CI / dogfood pipeline; `Done\.` greps in fixtures), FW-ADR-0010
  (pre-bootstrap interface, inherited for the preservation refusal
  surface), FW-ADR-0002 (manifest verification, the `--verify`
  formatter reused for phase B output).

## Context and problem statement

The upgrade flow carries a `preserve_list` derived from
`.template-customizations` (path patterns the operator has declared
project-customised). The current behaviour treats the preserve list
as authoritative: a path listed there is left alone by the sync
loop, regardless of whether the project's content actually diverges
from the baseline at that path, and regardless of whether the
destination manifest declares the path as a fresh-write the upgrade
is supposed to install. This produces two failure modes:

1. **Pollution.** Operators add entries to `.template-customizations`
   defensively, then forget to remove them after the customisation
   is upstreamed. Subsequent upgrades silently skip paths that have
   no actual divergence, leaving the project pinned to stale
   framework content the operator does not realise they have opted
   out of.
2. **Manifest contradiction.** A new release may declare a path as a
   fresh-write (e.g., a new `scripts/lib/*.sh` helper, a renamed
   template file). If that path is matched by a stale preserve-list
   pattern, the fresh-write is skipped and the upgrade leaves the
   project in a half-installed state — manifest-verify then flags
   drift the operator did not introduce.

The customer's 2026-05-15 ruling (Blocker #4) addresses both modes
and additionally calls for the upgrade tail to stop conflating
"migration queue done" with "project is in a clean post-upgrade
state". Today the tail prints a single line: `Done. TEMPLATE_VERSION
now <ver>.` Whether the project is clean, drifted, or carries a
preservation refusal is not visible from the exit signal. ADR-trigger
rows that fire: cross-cutting pattern change (upgrade contract +
preservation semantics), new exit code path (preservation refusal),
new env var (`SWDT_PRESERVATION_FORCE`), new artefact
(`.template-preservation-blocked.json`), audit-log column extension.
Dogfood evidence sits in `docs/pm/dogfood-2026-05-15-results.md`.

## Decision drivers

- **Customisation wins, but only on real customisation.** The
  framework's "customisation wins" rule (FW-ADR-0002,
  `docs/framework-project-boundary.md`) must extend to preservation
  — but only when there is actual divergence to preserve. An inert
  preserve-list entry is not a customisation, it is pollution.
- **Manifest declarations are load-bearing.** A path the destination
  manifest declares as a fresh-write is part of the release's
  intended state. Letting a stale preserve-list pattern override
  that declaration breaks the manifest's contract with `--verify`
  and produces unexplained drift.
- **Refuse-on-uncertain on genuine conflict.** When divergence AND
  fresh-write declaration both fire on the same path, the framework
  cannot decide unambiguously which the operator wants. Same posture
  as FW-ADR-0010 and FW-ADR-0002: refuse, surface the conflict,
  provide an audit-evident override.
- **Back-compat for already-polluted downstreams.** Existing
  projects carry inert preserve-list entries today. A flag day that
  refuses every polluted project is unacceptable; the migration path
  must absorb the pollution without operator surgery.
- **Exit signal must distinguish clean from drift from refusal.**
  Today's single-line tail collapses three distinct post-conditions
  into one exit code. CI gates and operators both need the
  distinction.
- **Don't re-invent the verify formatter.** `scripts/lib/manifest.sh`
  already carries a `--verify` formatter with a tested output shape.
  The two-phase tail's phase B must reuse it rather than spawning a
  parallel formatter.
- **Audit-log surface reuse.** FW-ADR-0010 added a `Gate` column to
  `docs/pm/pre-release-gate-overrides.md` distinguishing
  `pre-release` from `pre-bootstrap` rows. Preservation refusal
  needs the same kind of audit trail; extending the `Gate` column
  with a third value is cheaper than spawning a sibling register.

## Considered options (Three-Path Rule, binding)

### Q1 — Preservation rule

#### Option M — Minimalist: trust `.template-customizations` verbatim

Keep today's behaviour. Document the pollution risk in release notes
and operator-facing guidance; rely on operators to prune stale
entries themselves.

- **Sketch:** No code change. A new section in
  `docs/TEMPLATE_UPGRADE.md` warns about pollution and recommends
  periodic `.template-customizations` review.
- **Pros:**
  - Zero implementation cost.
  - No back-compat work.
- **Cons:**
  - Pollution mode persists. Operators continue to silently skip
    paths they no longer customise.
  - Manifest-contradiction mode persists. Fresh-write declarations
    on a polluted path silently lose to the preserve list.
  - Discovery is via `--verify` drift reports that the operator
    must investigate manually; the framework offers no
    self-healing.
- **When M wins:** if preserve-list pollution were rare in practice
  and manifest-contradiction conflicts had no measurable rate. The
  customer's 2026-05-15 ruling establishes that they are not.

#### Option S — Scalable: divergence-only AND manifest-respecting (refuse-on-uncertain)

Preservation is honoured only when *both* conditions hold:

- (a) The project's content diverges from the baseline at the
  stamped version for that path, AND
- (b) The destination manifest does not declare the path as a
  fresh-write.

When both rules conflict on a genuinely-customised path (i.e., the
path diverges AND the destination manifest declares it as a
fresh-write the new release intends to install over the
customisation): refuse-on-uncertain. Write
`.template-preservation-blocked.json`, exit 2. Override via
`SWDT_PRESERVATION_FORCE=1`; audit row appended to
`docs/pm/pre-release-gate-overrides.md` with a new `Gate` column
value `preservation`.

- **Sketch:** Replace the bare `preserve_list` membership check in
  the sync loop with a function that consults the baseline SHA
  (divergence check) and the destination manifest
  (fresh-write check). Decision matrix:
  - no-divergence: drop the path from `preserve_list` (inert
    entry; sync loop proceeds with the upstream content).
  - divergence + path not declared fresh-write: preserve.
  - divergence + path declared fresh-write: refuse, write
    block artefact, exit 2 unless `SWDT_PRESERVATION_FORCE=1`.
- **Pros:**
  - Pollution mode closes: inert preserve-list entries silently
    drop at sync time without operator surgery.
  - Manifest-contradiction mode surfaces explicitly: the conflict
    is named, the artefact carries the per-path detail, the
    operator decides.
  - Maps cleanly onto FW-ADR-0010's refuse-on-uncertain posture and
    onto FW-ADR-0002's customisation-wins-on-divergence rule.
  - Override is auditable via the existing pre-release-gate-overrides
    register, extended with a new `Gate` column value.
  - Self-healing path (drop inert entries at runtime) handles
    already-polluted downstreams without a flag day.
- **Cons:**
  - New exit code path on preservation refusal (exit 2, shared with
    FW-ADR-0010's pre-bootstrap refusal; operators must read the
    block-artefact filename to distinguish).
  - New env var (`SWDT_PRESERVATION_FORCE`); new artefact
    (`.template-preservation-blocked.json`); third `Gate` column
    value (`preservation`). All three are additive surface that
    future releases must keep backward-compatible.
  - Requires the destination manifest to be populated and trusted
    before the sync loop hits the preservation check — the
    implementation must order things so manifest read precedes
    preserve-list consultation.
  - Operators carrying genuine customisation on a path the new
    release wants to fresh-write will see a refusal where today
    they saw silent preservation. This is the intended
    customer-visible behaviour change; release notes must call it
    out.
- **When S wins:** the framework's actual use case — long-lived
  projects, occasional stale preserve-list entries, occasional
  fresh-write declarations on previously-customised paths, audit
  requirements on overrides. Maps cleanly to FW-ADR-0002 and
  FW-ADR-0010.

#### Option C — Creative: drop the preservation list; derive preservation from divergence alone

Stop reading `.template-customizations` entirely. Compute the
preserve set per upgrade run from baseline vs project SHA
divergence. A path is preserved iff its current SHA differs from the
baseline SHA at the stamped version.

- **Sketch:** Delete the `preserve_list` plumbing. The sync loop
  consults baseline / project / upstream SHAs (the same triple
  FW-ADR-0010 uses) and decides per-path: equal-to-baseline →
  overwrite; diverged-from-baseline → preserve. Manifest declarations
  are layered on as a refuse-on-conflict guard, same as Option S.
- **Pros:**
  - Single source of truth (the baseline SHA) replaces a
    user-maintained register.
  - Pollution mode cannot exist — there is no list to pollute.
  - Manifest declarations layer on as a refuse guard, same as
    Option S, with simpler upstream semantics.
  - The `.template-customizations` file becomes documentation-only
    or is retired entirely.
- **Cons:**
  - **Loses operator intent signal.** Today's preserve list lets the
    operator declare "this path is intentionally customised, keep
    it customised even if the divergence is accidental (e.g., a
    line-ending normalisation)". Divergence-alone treats every
    diff as intentional, which is wrong for cases like
    SPDX-header drift, auto-formatter churn, or editor whitespace.
  - **Migration cost.** Retiring `.template-customizations` is a
    breaking change to every downstream project; the operator
    interface that the existing customer ruling 2026-05-14 just
    extended (the `Gate` column work) gets pulled out from under
    that ruling.
  - **Discovery is implicit.** With no register, the operator
    cannot see at a glance which paths the framework considers
    customised — they have to run `--verify` and read SHA diffs.
- **When C wins:** if the operator intent signal had no value (every
  divergence is genuinely intentional) and the migration cost of
  retiring `.template-customizations` were near-free. Neither holds.

### Q2 — Upgrade tail shape

#### Option M — Minimalist: keep the single-line "Done." tail

Keep `Done. TEMPLATE_VERSION now <ver>.` Document that operators
should run `./scripts/upgrade.sh --verify` separately to confirm
clean state.

- **Sketch:** No code change. Release notes add a "run `--verify`
  after upgrade" recommendation.
- **Pros:**
  - Zero implementation cost.
  - No fixture / playbook updates needed.
- **Cons:**
  - Conflates three distinct post-conditions (clean, drift,
    refusal) under a single exit signal.
  - CI gates cannot distinguish "migration succeeded but project
    has drift" from "migration succeeded and project is clean"
    without a second invocation.
  - The preservation-refusal path (from Q1's Option S) would have
    no native tail surface — refusals would need a parallel
    formatter.
- **When M wins:** if preserve-list refusal were impossible and CI
  gates were happy to run `--verify` twice. Neither holds.

#### Option S — Scalable: two-phase exit (migration complete + verification)

Replace `Done. TEMPLATE_VERSION now <ver>.` with a two-phase tail:

- **Phase A** prints `Migration chain complete (TEMPLATE_VERSION
  now <ver>).` This signals the migration queue's success
  independent of project state.
- **Phase B** prints either `Verification: clean.` (no drift, no
  refusal) or a per-path drift summary (the existing `--verify`
  formatter's output, reused verbatim).
- **Exit code** follows phase B: `0` on clean, `1` on drift, `2`
  on preservation-refusal (shared with pre-bootstrap refusal per
  FW-ADR-0010; distinguished by the block-artefact filename
  present in the project root).

- **Sketch:** At the end of `scripts/upgrade.sh`, after the manifest
  is written, call the existing `manifest.sh` verify entry point.
  Format its output through the same `--verify` formatter operators
  already see. Map verify's internal status to the exit code.
- **Pros:**
  - CI gates and operators see the three post-conditions
    distinctly via exit code AND via the formatted phase B output.
  - Reuses the existing `--verify` formatter from
    `scripts/lib/manifest.sh` for output-shape consistency.
  - The preservation-refusal path from Q1 has a native tail
    surface — phase B reports the refusal alongside its
    block-artefact pointer.
  - The new exit semantics are additive on the existing exit code
    space; FW-ADR-0010's exit 2 stays consistent.
- **Cons:**
  - Repo-wide audit needed for `Done\.` greps in CI scripts,
    fixtures, playbooks, and downstream documentation. Existing
    consumers may parse the literal "Done." line as a success
    signal.
  - The phase B output adds verbose lines on every successful
    upgrade, where today the tail is one line. Mitigation: the
    clean-state output is a single line (`Verification: clean.`),
    only the drift / refusal cases expand.
  - Phase B runs `--verify`, which adds work to every upgrade
    (one SHA pass over the project tree). Cost is bounded by the
    existing `--verify` runtime, which is already tolerated as a
    standalone invocation.
- **When S wins:** when operators and CI gates both need the
  three-way distinction and the `--verify` formatter is already
  trusted upstream. Both hold.

#### Option C — Creative: structured JSON tail with embedded verification report

Replace the prose tail with a single JSON blob: `{"template_version":
"<ver>", "verification": <verify report>, "preservation_refusal":
<artefact or null>}`. Operators pipe it through `jq`; CI gates
parse it directly.

- **Sketch:** Final stdout of `scripts/upgrade.sh` is a JSON
  document. Prose status lines are routed to stderr only.
- **Pros:**
  - Machine-parseable.
  - Embeds the verification report inline; no separate file read
    required.
  - Forward-compatible with future post-upgrade signals
    (security-scan results, schema-version checks).
- **Cons:**
  - **Human-readability regression.** Operators running upgrade
    interactively today see a clear prose tail; a JSON blob is a
    significant UX downgrade. Mitigation (a separate human-readable
    tail to stderr) introduces two surfaces that must stay in sync.
  - Repo-wide audit for `Done\.` greps still needed, plus a second
    audit for any consumer parsing stdout as prose.
  - The `--verify` formatter would have to grow a JSON output
    mode, which is real implementation work that FW-ADR-0002 has
    not yet sanctioned.
  - Locks the tail surface into JSON; future additions become
    schema-bump events rather than prose extensions.
- **When C wins:** if the upgrade UI were exclusively CI-driven and
  human invocation were vanishingly rare. The framework explicitly
  supports both modes.

## Decision outcome

### Q1 decision — divergence-only AND manifest-respecting (Option S)

**Chosen option: S.** Option M leaves both pollution and
manifest-contradiction modes live. Option C retires the operator
intent signal `.template-customizations` carries (the operator's
declared-customised assertion), losing real information. Option S
preserves the operator's intent signal AND adds two structural
guards (divergence required, manifest declaration respected) that
close the two failure modes. The refuse-on-uncertain posture
matches FW-ADR-0010 and FW-ADR-0002.

The decision matrix:

| project vs baseline | manifest declaration | action |
|---------------------|---------------------|--------|
| equal (no divergence) | any | **drop from preserve_list** (inert entry; sync proceeds with upstream content) |
| diverged | not declared fresh-write | **preserve** (genuine customisation; sync leaves project content alone) |
| diverged | declared fresh-write | **refuse** (write block artefact, exit 2 unless `SWDT_PRESERVATION_FORCE=1`) |

The "refuse" row writes `.template-preservation-blocked.json` at
project root with one entry per affected path
(`path`, `project_sha`, `baseline_sha`, `manifest_declared_sha`,
`reason=manifest-fresh-write-vs-customisation`). The escape hatch is
`SWDT_PRESERVATION_FORCE=1`; an audit row is appended to
`docs/pm/pre-release-gate-overrides.md` with `Gate=preservation` in
the column FW-ADR-0010 introduced.

### Back-compat for already-polluted downstreams

The "drop from preserve_list" row is structurally self-healing — no
operator action is required for a project carrying inert entries.
The implementation must additionally provide:

- **Runtime self-healing.** At sync time, every preserve-list entry
  is evaluated against (a) divergence and (b) manifest declaration.
  Inert entries (no-divergence OR declared-fresh-write-with-no-
  divergence) are dropped from the in-memory `preserve_list` before
  the sync loop reads it. The on-disk `.template-customizations`
  file is **not** rewritten in this pass — the operator opts into
  the rewrite via the migration below.
- **Opt-in one-shot pruning migration.** A new migration step
  surfaces the planned prune list to the operator before rewriting
  `.template-customizations`. Behaviour: dry-run by default
  (prints the prune list, exits with the candidate edits printed
  but the file untouched); operator re-runs with an explicit
  acknowledgement env var to apply. This migration is opt-in
  because rewriting `.template-customizations` is a project-owned
  file change that the framework should not perform silently.
- **`migrations/v0.15.0.sh` divergence pre-check.** Add a
  divergence pre-check at the top of `v0.15.0.sh` so future runs
  do not seed the same pollution pattern. The pre-check identifies
  preserve-list entries that have no divergence and warns (without
  refusing) at migration time, pointing the operator at the
  one-shot pruning migration.

### Q2 decision — two-phase exit (Option S)

**Chosen option: S.** Option M conflates three post-conditions
under one exit signal, which the Q1 preservation-refusal path
exposes as a real problem. Option C optimises for the CI-only case
at the cost of human readability and locks the surface into JSON
prematurely. Option S splits the tail into migration-complete
(phase A) and verification (phase B), reuses the existing
`--verify` formatter for phase B output, and maps the verify result
onto exit codes (0 clean / 1 drift / 2 preservation-refusal).

Phase A line (literal, for grep-stability):

```
Migration chain complete (TEMPLATE_VERSION now <ver>).
```

Phase B line on clean state (literal):

```
Verification: clean.
```

Phase B output on drift or preservation-refusal: the existing
`scripts/lib/manifest.sh --verify` formatter's output verbatim
(per-path drift summary; preservation-refusal entries flagged with
the block-artefact filename).

Exit code mapping:

- `0` — phase B reports clean (no drift, no preservation-refusal).
- `1` — phase B reports drift (one or more paths' on-disk SHA
  differs from the manifest-declared SHA without a preservation
  reason).
- `2` — phase B reports preservation-refusal (one or more paths
  hit the Q1 refuse row; `.template-preservation-blocked.json`
  exists at project root). Shared with FW-ADR-0010's pre-bootstrap
  refusal exit; the two block-artefact filenames
  (`.template-prebootstrap-blocked.json` vs
  `.template-preservation-blocked.json`) are the discriminator.

### Inherited FW-ADR-0010 interface (binding)

The preservation refusal path inherits FW-ADR-0010's interface
shape with one extension:

- **`SWDT_PRESERVATION_FORCE=1`** — new env var; same operator
  self-service override semantics as `SWDT_PREBOOTSTRAP_FORCE=1`.
  Overrides the Q1 refuse row and proceeds with the manifest's
  fresh-write declaration (i.e., overwrites the divergent project
  content with the upstream content). Audit row appended before
  any file is touched.
- **Exit code 2** — shared with pre-bootstrap refusal (same exit
  semantics class: refuse-on-uncertain).
- **`.template-preservation-blocked.json`** — new artefact, schema
  parallel to `.template-prebootstrap-blocked.json` (version,
  generated, reason_summary, blocked array with per-path entries).
  See implementation notes for the schema.
- **Audit-log row** — same surface
  (`docs/pm/pre-release-gate-overrides.md`); the `Gate` column
  FW-ADR-0010 added gains a third value `preservation` alongside
  `pre-release` and `pre-bootstrap`.

### Implementation notes for software-engineer

Eight concrete change points:

1. **`scripts/upgrade.sh` (sync-loop preservation check, ~line 540).**
   Replace the bare `preserve_list` membership check with a call to
   a new `should_preserve()` function that consults baseline SHA
   (divergence) and the destination manifest (fresh-write
   declaration). Returns one of `preserve` / `drop-inert` /
   `refuse-conflict`. Sync loop honours `preserve` and `drop-inert`
   silently; `refuse-conflict` triggers the block-artefact writer.

2. **`scripts/lib/manifest.sh` (manifest-declaration query, new
   function).** Add `manifest_declares_fresh_write(path)` that
   returns 0 if the destination manifest carries an entry for
   `path` whose `source` field is `fresh-write` (or the
   manifest-format equivalent the implementation lands on),
   non-zero otherwise. Used by `should_preserve()` in change point 1.

3. **`scripts/upgrade.sh` (block-artefact writer, ~line 720).** New
   function `write_preservation_block_artefact()` that emits
   `.template-preservation-blocked.json` at project root. Schema:
   ```json
   {
     "version": 1,
     "generated": "<ISO-8601 UTC>",
     "reason_summary": "manifest-fresh-write-vs-customisation",
     "blocked": [
       {
         "path": "<path>",
         "project_sha": "<sha>",
         "baseline_sha": "<sha>",
         "manifest_declared_sha": "<sha>",
         "reason": "manifest-fresh-write-vs-customisation"
       }
     ]
   }
   ```
   `blocked` sorted by `path` for determinism; `generated` is the
   only field expected to vary between idempotent re-runs.

4. **`scripts/upgrade.sh` (env-var override + audit-row writer,
   near the block-artefact writer).** Honour
   `SWDT_PRESERVATION_FORCE=1`: append a row to
   `docs/pm/pre-release-gate-overrides.md` with
   `Gate=preservation` before any file is touched. If the audit
   log is unwritable, refuse the override (same posture as
   FW-ADR-0010).

5. **`scripts/upgrade.sh` (two-phase tail, end of script).**
   Replace the single `echo "Done. TEMPLATE_VERSION now $ver."`
   with the phase A literal `Migration chain complete
   (TEMPLATE_VERSION now $ver).`, then invoke
   `manifest.sh`'s verify entry point. Format its output via the
   existing `--verify` formatter. Map verify's internal status to
   exit codes 0 / 1 / 2 per the Q2 decision. On clean state, emit
   the literal `Verification: clean.` as phase B.

6. **`migrations/v0.15.0.sh` (divergence pre-check, near the top
   of the script).** Add a block that walks the project's
   `.template-customizations` entries and identifies inert ones
   (no divergence vs baseline). Emit a WARN per inert entry
   pointing the operator at the opt-in pruning migration. Does
   not refuse, does not edit `.template-customizations` (the
   pruning migration is opt-in).

7. **New migration `migrations/v1.0.0-rc14.sh` (opt-in
   `.template-customizations` pruning).** Dry-run by default:
   prints the prune list, exits without rewriting. Operator
   re-runs with `SWDT_PRESERVATION_PRUNE_APPLY=1` (or equivalent
   acknowledgement env var; final name pinned during
   implementation) to apply the rewrite. Migration follows
   FW-ADR-0004's immutability rule once released.

8. **Repo-wide `Done\.` audit (release-engineer + qa-engineer).**
   Grep CI scripts, fixtures, playbooks, and downstream
   documentation for the literal `Done.` parse pattern. Document
   every site in the implementation notes and migrate consumers to
   the new phase A literal `Migration chain complete
   (TEMPLATE_VERSION now <ver>).`. Audit-output recorded in the
   release notes for rc-to-rc upgraders.

## Consequences

### Positive

- Pollution mode closes structurally: inert preserve-list entries
  silently drop at sync time without operator surgery. Already-
  polluted downstreams self-heal on next upgrade.
- Manifest-contradiction mode surfaces explicitly via the refuse
  path; the conflict is named, the artefact is machine-parseable,
  and the operator decides via the documented force env var.
- The framework now carries one consistent refuse-on-uncertain
  posture across all three windows: pre-bootstrap (FW-ADR-0010 +
  FW-ADR-0013), preservation (this ADR), regular sync
  (FW-ADR-0002).
- Two-phase exit gives CI gates and operators the three-way
  distinction (clean / drift / refusal) that today's tail collapses.
- `--verify` formatter reuse keeps output shape consistent across
  the upgrade tail and the standalone `--verify` invocation.
- Audit-log surface stays single-file: the `Gate` column FW-ADR-0010
  introduced absorbs the third event type.

### Negative / trade-offs accepted

- New env var (`SWDT_PRESERVATION_FORCE`), new artefact
  (`.template-preservation-blocked.json`), third `Gate` column
  value (`preservation`). All three are additive surface that
  future releases must keep backward-compatible.
- Exit code 2 is now shared between pre-bootstrap refusal
  (FW-ADR-0010) and preservation refusal (this ADR). Operators
  and CI gates distinguish by block-artefact filename. Acceptable
  because both are refuse-on-uncertain events at semantic parity.
- The two-phase tail adds a `--verify` pass to every upgrade run.
  Cost is bounded by the existing standalone-verify runtime,
  already tolerated.
- Repo-wide `Done\.` audit is real work and will touch fixtures,
  playbooks, and downstream documentation. Mitigation: the audit
  is bounded to one release cycle (rc13/rc14) and the new phase A
  literal is grep-stable.
- Opt-in pruning migration adds one more file to the migrations
  directory. Honours FW-ADR-0004 immutability.
- Operators carrying genuine customisation on a path the new
  release wants to fresh-write will see a refusal where today they
  saw silent preservation. Customer-visible behaviour change;
  release notes must call it out.

### Follow-up ADRs

- None required for this ADR's scope. A future ADR may revisit the
  exit-code sharing if a third refuse-on-uncertain event type lands
  and per-event exit codes become useful (e.g., exit codes 3 / 4 /
  5 for distinct refuse classes).

## Relationship to other ADRs and issues

- **FW-ADR-0010 (pre-bootstrap local-edit safety).** This ADR
  inherits FW-ADR-0010's interface shape (force env var, exit code 2,
  block-artefact filename pattern, audit-log column) and extends the
  `Gate` column with the `preservation` value. The two ADRs share
  exit code 2 by design — both are refuse-on-uncertain events at
  semantic parity.
- **FW-ADR-0002 (upgrade content verification).** This ADR reuses
  the `--verify` formatter from `scripts/lib/manifest.sh` for the
  two-phase tail's phase B output. FW-ADR-0002's drift-reporting
  shape is the same shape phase B emits.
- **FW-ADR-0013 (rc-to-rc pre-bootstrap).** Sibling ADR landing in
  the same blocker batch (2026-05-15). Same dogfood evidence file
  (`docs/pm/dogfood-2026-05-15-results.md`); both inherit FW-ADR-0010.
  No direct technical coupling beyond the shared exit code 2.
- **FW-ADR-0004 (per-item file breakout).** The opt-in pruning
  migration and the `v0.15.0.sh` divergence pre-check both honour
  FW-ADR-0004's immutability rule for released migrations.

## Verification

- **Success signal:** dogfood fixtures in
  `docs/pm/dogfood-2026-05-15-results.md` PASS for: (a) a project
  with inert preserve-list entries upgrades cleanly, the inert
  entries silently drop, the post-upgrade `--verify` reports clean,
  exit 0; (b) a project with genuine customisation on a non-
  fresh-write path upgrades cleanly, customisation preserved, exit
  0; (c) a project with genuine customisation on a fresh-write-
  declared path refuses with exit 2 and writes
  `.template-preservation-blocked.json`; (d) re-running (c) with
  `SWDT_PRESERVATION_FORCE=1` proceeds, writes the audit row,
  removes the block artefact, completes the upgrade with exit 0;
  (e) the opt-in pruning migration in dry-run mode prints the
  prune list without rewriting `.template-customizations`; (f) the
  pruning migration with the apply env var rewrites the file
  idempotently. Phase A and phase B literals appear in the
  expected order in every successful run.
- **Failure signal:** an upstream issue reports (i) a fresh-write
  declaration silently lost to a stale preserve-list entry, (ii)
  inert preserve-list entries still blocking sync after the
  self-healing pass, (iii) the two-phase tail emitting a stale
  `Done.` line in any code path, (iv) a `Done\.` grep in CI /
  fixtures / playbooks missed by the audit and parsing the new
  phase A literal incorrectly, or (v) exit code 2 ambiguity
  causing a CI gate to misclassify pre-bootstrap-refusal as
  preservation-refusal or vice versa.
- **Review cadence:** at the next MINOR release that touches
  `.template-customizations` semantics or the upgrade tail.
  Reconsider if any failure signal fires, or if a third
  refuse-on-uncertain event class lands and per-event exit codes
  become preferable.

## Links

- Upstream issues:
  - Blocker #4 (this ADR; preservation vs manifest)
- Related ADRs:
  - `FW-ADR-0010 — pre-bootstrap local-edit safety` (interface
    shape inherited; `Gate` column extended)
  - `FW-ADR-0013 — rc-to-rc pre-bootstrap` (sibling blocker ADR;
    same dogfood evidence; shared exit code 2)
  - `FW-ADR-0002 — upgrade content verification` (`--verify`
    formatter reused for phase B output)
  - `FW-ADR-0004 — per-item file breakout` (migration immutability
    rule honoured by the opt-in pruning migration)
- Related artefacts:
  - `scripts/upgrade.sh` (preservation check, block-artefact
    writer, two-phase tail)
  - `scripts/lib/manifest.sh` (`manifest_declares_fresh_write`
    query, `--verify` formatter reused for phase B)
  - `migrations/v0.15.0.sh` (divergence pre-check)
  - `migrations/v1.0.0-rc14.sh` (opt-in pruning migration; new file)
  - `.template-customizations` (project-owned register the
    preservation logic consults; the opt-in pruning migration
    rewrites it)
  - `.template-preservation-blocked.json` (new block artefact at
    project root)
  - `docs/pm/pre-release-gate-overrides.md` (audit-log surface;
    `Gate` column gains `preservation` value)
  - `docs/pm/dogfood-2026-05-15-results.md` (dogfood evidence)
- External references: MADR 3.0 (`https://adr.github.io/madr/`).
