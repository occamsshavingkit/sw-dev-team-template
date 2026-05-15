---
name: variant-catalog-contract
description: Variant-catalog contract; names each customisation shape, its canned mutations, and the rc-cycle failure it would catch.
status: active
created_date: 2026-05-14
---


# Contract: Upgrade-matrix variant catalog

**Owner**: `qa-engineer` (variants); `release-engineer` (generator integration).
**Status**: design (Phase 1)
**Spec**: [../spec.md](../spec.md) — FR-002.

## Purpose

Every variant in the matrix represents one downstream-customisation shape the gate must exercise. This contract names each variant, the canned mutations that produce it, and the rc-cycle failure it would have caught (the "justify each variant" requirement).

## v1 required variants (default-on subset of FR-005)

### `clean`

**Mutations**: none. Tree is the output of `scripts/scaffold.sh` against the source tag, nothing else.

**Catches**: regressions in the bare scaffold→upgrade→verify path. Equivalent to today's `upgrade-paths` behaviour; serves as a baseline so the matrix expansion doesn't lose coverage.

**Source-rc range**: all eligible source-rcs (FR-003).

### `with-customizations`

**Mutations**:
- Edit one tracked file (`.claude/agents/researcher.md`) — append a single line marker (`# fixture-customization-marker`).
- Append the file's relative path to `.template-customizations`.
- Commit both changes as one fixture-internal commit.

**Catches**: the rc8→rc9 issue family — upgrade machinery overwriting customised files because `.template-customizations` parsing regressed, or because the upgrade path stopped honouring the customisation manifest after a refactor.

**Source-rc range**: latest two source-rcs on the current MAJOR (default-on); full range under `GATE_EXTENDED_MATRIX=1`.

### `with-accepted-local`

**Mutations**:
- Run one prior upgrade (e.g., source-rc N-1 → source-rc N) to populate `.template-conflicts.json` with a synthetic `accepted_local` entry, OR
- Directly write a hand-shaped `.template-conflicts.json` with one `accepted_local` and one `local_only_kept` entry (faster; deterministic).
- Choice of synthesis-vs-replay is per-variant generator decision; replay is preferred when the source-rc supports it.

**Catches**: rc11/rc12 issue family — accepted-local pruning, `--resolve` regressions, accumulated-state handling. The auditor's "every RC adds machinery, every NEXT RC finds a new edge case" loop lives almost entirely in this variant.

**Source-rc range**: latest two source-rcs on the current MAJOR (default-on); full range under `GATE_EXTENDED_MATRIX=1`.

## v1 optional variants (default-off; `GATE_EXTENDED_MATRIX=1`)

### `with-pre-bootstrap-conflict`

**Mutations**:
- For source-rcs ≥ v0.14.0 (when pre-bootstrap landed): leave the project's pre-bootstrap helper in place at its scaffolded location.
- Edit the upstream-equivalent helper in the candidate tree so the upgrade triggers a 3-way conflict between baseline, upstream, and project copy.

**Catches**: the v0.16.0-class issue (currently allowlisted) and the rc7-era pre-bootstrap conflict family. Default-off in v1; promotion to default-on is deferred until rc14+ when Class A regression frequency against the v1 matrix gives a wall-clock-impact basis to decide.

**Source-rc range**: v0.14.0 onward only; not applicable to source-rcs without pre-bootstrap.

### `with-mid-version-sha`

**Mutations**:
- Scaffold from a commit one or two commits past the source-rc tag (still on the rc's lineage; not at the next tag yet).
- Set the fixture's `TEMPLATE_VERSION` to the tag's SHA, not the tag name.

**Catches**: the `--target` SHA-drift family — operators who upgraded from `rc4.commit_abc` rather than `rc4` exact. Auditor explicitly named this as an uncovered axis.

**Source-rc range**: any source-rc with ≥2 commits between it and the next tag.

## Variant registration

The generator script (rc13 implementation) reads a registry at `tests/fixtures/downstream-snapshots/_variants.list` with one variant name per line. Each variant has a corresponding `_mutations.sh` co-located under `<source-rc>/<variant>/_mutations.sh` that the generator invokes inside the freshly-scaffolded fixture tree. The variant registry is the single source of truth for which variants exist; the gate iterates whatever the registry lists.

## Adding a new variant

1. Append the variant name to `_variants.list`.
2. Author the mutation script (`_mutations.sh`) — deterministic, idempotent, uses no external network.
3. Run the generator against every eligible source-rc to materialise snapshots locally; snapshots are gitignored (spec FR-003), so nothing snapshot-side is committed — only the mutation scripts and registry entry.
4. Add a row to this catalog naming the mutation, the rc-cycle issue it catches, and the source-rc range.
5. Document the wall-clock impact; if it pushes the default-on matrix past the FR-005 ~8 min budget, mark default-off.

## Removing a variant

Removing a variant deletes its row here and its mutation scripts. Snapshots are gitignored (spec FR-003), so removal does not touch committed snapshot trees; existing local snapshots become orphaned and are cleared on the next `--all` run. Removal is a breaking change to the diagnostic format (one less `(rc, variant)` pair); record in the rc's CHANGELOG.
