# Feature Specification: Upgrade-matrix fixture set for `upgrade-paths` sub-gate

**Feature Branch**: `008-upgrade-matrix-fixtures`
**Created**: 2026-05-14
**Status**: Draft — design only (no implementation)
**Input**: Customer ruling 2026-05-14 — attack Class A (upgrade machinery, 23/66 issues across rc7..rc12) of the recurring-issue surface that `process-auditor` identified. Today's `upgrade-paths` sub-gate exercises one fixture per source tag (clean scaffold, clean worktree); real downstream pain lives in customised, conflict-laden, mid-version trees. Expand the gate's fixture set so the (source-RC × downstream-customisation × upgrade-flag) matrix gets exercised before tag.

## Problem statement

The `upgrade-paths` sub-gate in spec-007 catches *one* failure mode: "scaffold-from-tag + clean-upgrade-to-candidate broke." It cannot catch the failure modes that drove rc7..rc12 issues: customised files conflicting with upstream sync, `.template-conflicts.json` carrying `accepted_local` entries the next RC's machinery doesn't recognise, operators upgrading from a mid-version SHA rather than the tag, pre-bootstrap hooks colliding with project-side equivalents. The fixture is monoculture; the failures are diverse.

Issue #178 (PR for FW-ADR-0012 hook fix, merged 2026-05-14) addressed Class B of the recurring issue surface that `process-auditor` identified; this spec addresses Class A (upgrade machinery, 23/66 issues across rc7..rc12).

## User Scenarios

### US-1 — Catch a customisation-conflict regression before tag (P1)

The maintainer runs `scripts/pre-release-gate.sh`. The `upgrade-paths` sub-gate exercises each `(source-rc, variant)` pair, including a `with-customizations` variant carrying a `.template-customizations` entry on a tracked file. If the candidate's upgrade machinery regresses customisation handling (the rc8→rc9 issue family), the gate fails and the diagnostic names the failing `(rc, variant)` tuple.

**Independent test**: deliberately break customisation merging in a candidate; run the gate; confirm the matrix surfaces the break tagged with the offending `(source-rc, variant)`.

### US-2 — Catch an accepted-local regression before tag (P1)

A `with-accepted-local` variant carries a `.template-conflicts.json` whose entries the next RC's pruning machinery must handle. Regressions in `--resolve` / pruning surface as `(rc, accepted-local)` failures.

### US-3 — Bounded wall-clock cost (P2)

The expanded default-on matrix completes within the sub-gate's wall-clock budget (~8 min per FR-005, waiving spec-007 FR-012's 5-min limit for this sub-gate only) on a typical workstation. The opt-in extended matrix (`GATE_EXTENDED_MATRIX=1`) carries no wall-clock guarantee and is intended for pre-cut manual runs and CI.

## Requirements

### FR-001 — Fixture layout

Fixtures live at `tests/fixtures/downstream-snapshots/<source-rc>/<variant>/` where `<source-rc>` enumerates published-prior tags eligible per FR-003 (spec-007 + Q-0017 cap + rc12 allowlist), and `<variant>` is one of the v1 variant catalog (FR-002).

**Cross-MAJOR scope**: this sub-gate's source-rc enumeration uses `gate_enumerate_source_tags` from `scripts/lib/gate-tags.sh`, which excludes pre-v0.16.0 + rc1/rc2 by design per Q-0017 ans A. Matrix expansion stays v1.0.0-only for all variants (required and optional). No v0.x source tags are admitted, including for the `clean` baseline variant.

### FR-002 — Variant catalog (v1)

Three required variants per source-rc:

- **`clean`** — equivalent to today's behaviour (scaffold-from-tag, no mutations). Baseline; ensures no regression vs. spec-007.
- **`with-customizations`** — one tracked file (e.g., `.claude/agents/researcher.md`) has a local edit AND a `.template-customizations` entry. Exercises the customisation-respect path during upgrade.
- **`with-accepted-local`** — `.template-conflicts.json` carries one `accepted_local` entry from a prior upgrade. Exercises the accumulated-conflict-state path the rc11/rc12 pruning machinery introduced.

Two optional variants (default-off, opt-in via `GATE_EXTENDED_MATRIX=1`):

- **`with-pre-bootstrap-conflict`** — project-side equivalent of an upstream pre-bootstrap helper (covers the rc7-era pre-bootstrap issue family + the v0.16.0 allowlisted case).
- **`with-mid-version-sha`** — fixture scaffolded from a non-tag commit one or two SHAs past the source-rc tag. Exercises the `--target` SHA-drift path.

Each variant has a one-paragraph rationale in `specs/008-upgrade-matrix-fixtures/contracts/variant-catalog.md` citing the rc cycle whose failure it would have caught.

### FR-003 — Generation procedure

Fixtures are generated, not hand-curated. A generator script (out-of-scope here; lives at `tests/fixtures/downstream-snapshots/_generate.sh` in rc13 implementation) runs: `scaffold-from-tag` → apply variant-specific canned mutations (recorded under `<variant>/_mutations.sh`) → snapshot. The generator is **reproducible given fixed inputs**: the generator inputs are `(source-rc tag SHA, variant name, generator version)`, and re-running against the same triple produces equivalent output. Defining the byte-level normalisation set (timestamps, git index ordering, file-mode bits, locale-dependent sort, embedded SHAs / dates in scaffolded files such as `TEMPLATE_VERSION` and intake logs) is deferred to the generator sub-task — the implementation enumerates and applies normalisations; this spec only guarantees input-fixity reproducibility. Snapshots are committed to the repo so the gate doesn't regenerate on every run; the generator is invoked manually at every rc cut to refresh / extend.

Meta-tests: `qa-engineer` owns regression tests for the `_mutations.sh` scripts themselves (e.g., golden-output assertions on each mutation applied to a known source tree). Mutation scripts are code and can regress; the meta-tests are part of the rc13 implementation sub-task.

### FR-004 — Wire-in to `upgrade-paths` sub-gate

`scripts/lib/gate-tags.sh::gate_subgate_upgrade-paths` iterates over `(source-rc, variant)` pairs rather than `source-rc` alone. The inner round-trip uses the snapshot at `tests/fixtures/downstream-snapshots/<rc>/<variant>/` as the upgrade-source tree instead of running `scaffold.sh` fresh. Diagnostic format extends to `FAIL:<rc>:<variant>`. The existing allowlist file (`tests/release-gate/upgrade-paths-allowlist.txt`) accepts `<tag>:<variant>` rows in addition to `<tag>` rows; a `<tag>`-only row allowlists all that tag's variants.

### FR-005 — Wall-clock budget

Wall-clock budget for the default-on matrix is ~8 min (waives spec-007 FR-012's 5-min limit for the `upgrade-paths` sub-gate). All three default-on variants (`clean`, `with-customizations`, `with-accepted-local`) run in full across every source-rc in scope (per FR-001 cross-MAJOR ruling: v1.0.0-only source-rc enumeration via `gate_enumerate_source_tags`).

Note: spec 007 FR-012 (5-min hard gate limit) is waived for the `upgrade-paths` sub-gate when the matrix expansion is active. Other sub-gates retain the 5-min limit.

Spec-007 FR-012 sizing reference: ~15 source tags × 1 fixture = ~20s/round-trip = ~5 min. Tripling to three required variants across the full source-rc range projects to ~45 round-trips × 20s = ~15 min worst case; the ~8 min budget assumes the default-on subset scoping below (latest-two-source-rcs for the two non-baseline variants) plus measured generator-cache reuse.

- **Default-on subset.** Default matrix = `clean` for every source-rc in scope + `with-customizations` and `with-accepted-local` for the latest two source-rcs on the current MAJOR. Estimated wall-clock fits inside the ~8 min budget.
- **Opt-in extended matrix.** `GATE_EXTENDED_MATRIX=1` runs every required variant for every source-rc plus the two optional variants. No wall-clock guarantee; intended for pre-cut manual runs and CI. Optional variants (`with-pre-bootstrap-conflict`, `with-mid-version-sha`) stay default-off in v1 — promoting either to default-on requires a measured wall-clock impact number, deferred until rc14+ once Class A regression frequency is observable against the v1 matrix.

### FR-006 — Per-variant skip mechanism

A skip file `tests/release-gate/upgrade-matrix-skip.txt` (same format as the existing allowlist; `<tag>` or `<tag>:<variant>` rows) excludes named pairs from execution entirely (distinct from allowlist, which runs the pair and logs the failure non-blockingly). Used for permanently-out-of-scope pairs (e.g., cross-MAJOR + extended variant whose generator can't produce a sane fixture). Default empty.

### FR-007 — Recovery procedure when snapshot diverges from generator output

A committed snapshot can drift from current generator output for two reasons:

- **Legitimate generator fix.** Generator was buggy; new output is correct. Action: regenerate affected snapshots, commit, note in CHANGELOG (one line per affected `(rc, variant)` cluster).
- **Accidental drift.** Hand-edited fixture, or the source-rc lineage changed under the snapshot (e.g., force-pushed tag). Action: revert the edit, regenerate from the unmodified generator, investigate the cause.

The generator exposes a `--check` mode that re-runs the pipeline in-memory and compares against each committed snapshot. `scripts/pre-release-gate.sh` invokes `--check` during `upgrade-paths` setup; any divergence fails the gate with a diagnostic naming the `(source-rc, variant)` pair and a truncated diff. The operator classifies legitimate fix vs. drift and acts. Without this check, FR-003's "regenerate at every rc cut" silently masks fixture-corruption bugs. `--check` is bounded by FR-005's wall-clock budget; if it exceeds, split into a default fast hash-compare path and an opt-in full-diff path.

### FR-008 — Migration path (rc13 implementation sequence)

1. rc13 cut: this spec lands; design reviewed.
2. rc13 implementation sub-task: generator script + canned-mutation scripts for the three required variants; snapshots committed for every then-eligible source-rc (currently rc3..rc12 minus excluded).
3. rc13 implementation sub-task: `gate_subgate_upgrade-paths` rewired to iterate the matrix; allowlist + skip formats extended.
4. Canonical: every rc cut from rc14 forward refreshes the snapshot for the newly-published tag before tagging the next rc. Adding a new source-rc to the matrix is a documented step in the rc-cut checklist.

## Resolved decisions

No pending customer-facing decisions remain for this spec.

- **Q-008a (resolved 2026-05-15)** — Wall-clock budget for the default-on matrix. Ruling: LOOSEN to ~8 min. Run all three default-on variants (`clean`, `with-customizations`, `with-accepted-local`) in full across the documented source-rc range. Waives spec-007 FR-012's 5-min limit for the `upgrade-paths` sub-gate only. Reflected in FR-005.
- **Q-008b (resolved 2026-05-15)** — Cross-MAJOR scope. Ruling: STAY v1.0.0-only for all variants. Pre-v0.16.0 + rc1/rc2 remain out-of-scope per Q-0017 ans A; matches existing `gate_enumerate_source_tags` enumeration cap in `scripts/lib/gate-tags.sh`. Reflected in FR-001.

Decisions made in-spec (no customer question): optional-variant default-off in v1 (FR-005, revisit after rc14+ once frequency data exists); snapshots committed to the repo (FR-003, regenerate-on-demand only revisited if fixture trees become too large to git-diff).

## Success criteria

- **SC-001** — Reproducing any rc7..rc12 Class A regression against the matrix fixtures causes the gate to fail with a diagnostic naming the offending `(source-rc, variant)` pair.
- **SC-002** — Default-on matrix run completes within the ~8 min wall-clock budget (FR-005) on a typical Linux workstation.
- **SC-003** — Adding a source-rc or variant requires editing exactly one place (the generator's source-rc list or variant registry); no per-rc copy-paste of round-trip orchestration.

## Out of scope

- Generator implementation (rc13 sub-task; `release-engineer` + `qa-engineer` co-own).
- Migration of existing allowlist semantics (already supports `<tag>` rows; FR-004 extends additively).
- CI mirror of the extended matrix (follow-up if customer requests).
- Cross-template-major fixture generation (deferred until v2.0.0 work begins).
