# Versioning policy

The template is versioned under **SemVer 2.0.0**
([https://semver.org/](https://semver.org/)) on the template
artifact: `MAJOR.MINOR.PATCH`, with SemVer pre-release suffixes for
release candidates.

**Normative reference.** Semantic Versioning 2.0.0,
<https://semver.org/spec/v2.0.0.html>. All version-number semantics
in this document (MAJOR / MINOR / PATCH, pre-release tags, `0.y.z`
initial-development rules, and pre-release ordering) are as defined
there.

## Current track: `v1.0.0-rc6`

As of 2026-05-04, the template is on the `v1.0.0-rc6` release-candidate
track. `v1.0.0-rc6` is the focused release-governance candidate after
rc5 follow-up fixes for issues #84, #104, and #105.

Issue #84 does not rewrite `v1.0.0-rc3` in place. Public rc tags are
immutable; rc3 cannot be changed in place. The supported mitigation is
the current/future bootstrap behavior in `scripts/upgrade.sh`, plus the
documented one-time workaround for already-affected rc3-era downstream
trees: if a `--dry-run` unexpectedly performed the upgrade, inspect the
worktree diff, keep and commit only after review or restore the worktree
from VCS, then use the current rc6 `scripts/upgrade.sh --dry-run` from a
clean branch/worktree for future previews.

Release candidates are not final stability promises. They are tagged
candidate builds for downstream validation before `v1.0.0` final.
Breaking changes are still permitted between rc tags when downstream
use finds a release-blocking contract, safety, upgrade, or retrofit
gap. Those changes must be documented in the changelog, covered by the
appropriate migration or smoke path, and reviewed before tagging.

## Historical `0.y.z` track

The template returned from early `v1.0.0-rc` tags to `0.y.z` at
`v0.10.0` on 2026-04-20. Under SemVer, `0.y` explicitly permits
breaking changes in minor bumps; `0.y.z` signalled that the public
contract was still forming.

That period is now historical, not the current release track:

- `v1.0.0-rc1` and `v1.0.0-rc2` were cut on 2026-04-19.
- Gate-3 engagement surfaced contract-breaking issues against those
  tags.
- The template resumed `0.y.z` at `v0.10.0` instead of compressing
  active contract discovery into multiple `v2.0.0`, `v3.0.0`, and
  later major bumps.
- `v0.10.0` through `v0.17.0` remain valid historical stable tags.
- The `v1.0.0-rc3`, `v1.0.0-rc4`, and `v1.0.0-rc5` tags mark
  re-entry to the `v1.0.0` candidate track.
- `v1.0.0-rc6` is the current candidate staged for that same track.

Documentation or issue bodies that cite older tags remain valid
point-in-time references and are not edited retroactively.

## rc and final semantics

`v1.0.0-rcN` means:

- The candidate is intended to become `v1.0.0` final if downstream
  validation finds no release-blocking gap.
- A later rc may break compatibility with an earlier rc if that is
  necessary to fix a release-blocking contract, safety, upgrade, or
  retrofit issue before final.
- Downstream projects already on an rc track follow the latest rc by
  default when running `scripts/upgrade.sh`.
- Stable-track downstream projects do **not** move to an rc by default.
  They can opt in explicitly with `scripts/upgrade.sh --target
  v1.0.0-rc6`.

`v1.0.0` final means:

- The public template contract is stable for the `v1` major line.
- Later `v1.y.z` releases must preserve backwards compatibility for
  stamped `v1.x` downstream projects.
- Breaking public-contract changes require `v2.0.0` or later, with an
  explicit migration path.
- Stable-track projects default to the latest stable tag, not to
  pre-release tags that may exist on upstream `main`.

## Tag and GitHub Release policy

Every public release, including rc tags, uses an **annotated git tag**
named exactly like `VERSION`, for example `v1.0.0-rc6`.

GitHub Release objects are created only for stable/final releases. For
this cycle, the first GitHub Release object is `v1.0.0` final. Do not
create GitHub Release objects for `v1.0.0-rcN` tags unless a future
recorded decision changes this policy.

The annotated tag is the source-control identity for the release. The
GitHub Release object is the public distribution and release-note
surface for stable/final releases. When a GitHub Release object exists,
it must agree with the annotated tag on the version name and commit.

Do not use lightweight tags for public releases. Do not create a GitHub
Release from a moving branch or from an rc tag under the current policy.
Do not move a public release tag; if a candidate is wrong, cut a later
tag.

## Post-1.0 breaking-change semantics

After `v1.0.0` final, the following are public-contract surfaces for
the `v1` line:

- Binding files: `AGENTS.md`, `CLAUDE.md`,
  `SW_DEV_ROLE_TAXONOMY.md`, `docs/glossary/*.md`,
  `docs/agent-health-contract.md`, and templates under
  `docs/templates/`.
- Agent roster shape: file names under `.claude/agents/`, tool grants,
  local-supplement conventions, and escalation contracts.
- Script contracts: `scripts/scaffold.sh`, `scripts/upgrade.sh`, and
  `scripts/repair-in-place.sh` command-line behaviour.
- Upgrade promise: downstream projects stamped at any `v1.x` release
  can upgrade to any later `v1.y` through `scripts/upgrade.sh` and the
  migration scripts it runs, without manual intervention beyond
  reviewing reported local customization conflicts.

Anything that renames, removes, or substantively reshapes those
surfaces in an incompatible way is a MAJOR change. It must be released
as `v2.0.0` or later and include a migration path.
