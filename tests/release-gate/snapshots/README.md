# tests/release-gate/snapshots/

Fixture snapshots for the `upgrade-paths` and `upgrade-matrix-fresh`
sub-gates of `scripts/pre-release-gate.sh` (spec 008).

## What lives here

16 scaffolded-tree snapshots, one per (source-rc, variant) pair:

- source-rc: every published tag whose `scripts/upgrade.sh` honours
  `SWDT_UPSTREAM_URL` (12 tags as of v1.0.0-rc12 — see
  `scripts/lib/gate-tags.sh::gate_enumerate_source_tags`).
- variant: `clean`, `with-customizations`, `with-accepted-local`,
  expanded per `gate_enumerate_matrix_pairs` (latest-two for the
  non-baseline variants under the default matrix).

Total on-disk size: ~22 MB.

## Gitignored

Everything in this directory except this README is gitignored
(see top-level `.gitignore`). The snapshots are regenerated locally
after every clone.

Rationale: per customer ruling 2026-05-15 evening, the committed
22 MB of fixture trees was ~300x the spec-008 implementation
estimate. Spec FR-007's "revisit trigger" fires at the "too large
to git-diff" scale, which these snapshots had already crossed.
Re-deriving locally from the generator is cheap (~37 s) and
deterministic.

## Regeneration

Full regen (all 16 pairs, ~37 s on a typical workstation):

    bash scripts/generate-fixture-snapshots.sh --all

Partial regen:

    bash scripts/generate-fixture-snapshots.sh --variant clean
    bash scripts/generate-fixture-snapshots.sh --source-rc v1.0.0-rc12

Regeneration is also wired into the opt-in `.git-hooks/post-checkout`
hook (already configured for the spec-010 TOC strip; extending it to
re-run the snapshot generator is the recommended setup for
contributors who run the gate locally).

## If you skip regeneration

The gate's `upgrade-paths` sub-gate fails fast with:

    ERROR: tests/release-gate/snapshots/<rc>/<variant>/ is missing.
    Snapshots are gitignored; regenerate with:
      bash scripts/generate-fixture-snapshots.sh --all
    (See tests/release-gate/snapshots/README.md.)

See `scripts/lib/gate-tags.sh::gate_run_one_round_trip` — that function
emits this diagnostic. The block above is mirrored from there verbatim;
if you change one, change the other. The duplication is deliberate (a
code-side fix shouldn't require a README round-trip).

## References

- Spec 008 §FR-003 (post-amendment) — snapshot scope + storage policy.
- Spec 008 §FR-007 — recovery procedure (drift, regen, classify).
- Customer ruling 2026-05-15 evening — Q-008d reversal.
