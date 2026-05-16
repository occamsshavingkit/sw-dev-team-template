# release-engineer — manual (rationale, examples, history)

**Canonical contract**: [.claude/agents/release-engineer.md](../../../.claude/agents/release-engineer.md)
**Generated runtime contract**: [docs/runtime/agents/release-engineer.md](../../runtime/agents/release-engineer.md)
**Classification**: canonical (manual; rationale companion to canonical agent contract)

This file holds rationale, historical context, and binding operational
guidance for `release-engineer`. The canonical contract carries only the
schema-allowlisted sections. The runtime compiler strips everything else;
this manual is the durable home for the displaced content.

## Pre-release gate operation

The single entry point is `scripts/pre-release-gate.sh`. Its exit
contract is binary: exit 0 iff every registered sub-gate exited 0
(spec 007 FR-001 / FR-002). The gate runs all sub-gates to completion
even when one fails ("fail-all" semantics), then emits a single PASS or
FAIL summary line (FR-009).

**PASS exit contract.** A PASS is only valid when:

- The worktree has zero uncommitted changes (FR-008 / `worktree-clean`
  sub-gate). The gate refuses to report PASS on a dirty worktree.
- All seven v1 sub-gates exit 0: `worktree-clean`, `lint-contracts`,
  `check-spdx`, `upgrade-paths`, `advisory-pointers`, `migrations`,
  `readme-current`.
- The run was against the **same SHA** that will be tagged. A PASS
  against a SHA other than the commit being tagged is not release
  evidence.

**SKIP_PRE_RELEASE_GATE bypass.** Set `SKIP_PRE_RELEASE_GATE=1` only
as a last resort and only when `docs/pm/pre-release-gate-overrides.md`
is writable. The pre-push hook will refuse the bypass if the override
log is unwritable. When the bypass fires, the hook appends one audit
row to that file containing: date, gate context (`pre-release`), short
SHA, tag name, operator email, the value of `PRE_RELEASE_GATE_REASON`,
and the sub-gate list. Set `PRE_RELEASE_GATE_REASON` to a precise,
single-line reason before the push; `unspecified` is the default and
is not acceptable for a production override. The override log is
tamper-evident by design — do not edit or delete rows.

**Cross-references.** Spec 007 / T042 / PR #162 define the gate's
contract. `specs/007-pre-release-upgrade/contracts/pre-release-gate.cli.md`
is the canonical CLI reference. `docs/pm/pre-release-gate-overrides.md`
is the audit log.

## rc tag procedure

Every public release — including rc tags — uses an **annotated** git
tag named exactly like the `VERSION` file at that commit
(`docs/versioning.md` § "Tag and GitHub Release policy"). Lightweight
tags are not acceptable for public releases.

**Pre-push hook install.** The hook ships at `.git-hooks/pre-push`.
One-time install:

```
git config core.hooksPath .git-hooks
```

Or symlink manually: `ln -sf ../../.git-hooks/pre-push .git/hooks/pre-push`.
Confirm with `git config core.hooksPath`.

**Hook behaviour.** In strict mode (push includes an annotated `v*`
tag), the hook runs `scripts/pre-release-gate.sh` with no flags (R-2
in the spec — `--only` / `--skip` are ignored in strict mode) and
blocks the push unless the gate exits 0. On any other push (feature
branch, `main` without a tag), the hook is advisory: it emits a
warning but does not block. See
`specs/007-pre-release-upgrade/contracts/pre-push-hook.contract.md`
for the full contract.

**Canonical tag sequence (binding per CUSTOMER_NOTES.md 2026-05-15
ruling 1):**

1. Fixes land on `main` after `code-reviewer` review (Hard Rule #3).
2. Run the dogfood harness against `main` via
   `scripts/upgrade.sh --target main`.
3. Only after dogfood PASSes is the rc tag cut — at the same SHA that
   passed dogfood.
4. A smoke dogfood run against the cut tag confirms identity.

**Override audit log.** Any push that bypasses the gate with
`SKIP_PRE_RELEASE_GATE=1` appends a row to
`docs/pm/pre-release-gate-overrides.md`. Review this log at every
release boundary; two or more override rows in a single rc window is a
process signal that the gate is either too slow or discovering real
regressions that should block the tag.

## Wrapper-masking failure mode (spec 007 R-5)

**The rc10 footgun.** During the rc8–rc10 release window, a local
CI-gates wrapper invoked the smoke test via a pipe to `tail`:

```sh
./scripts/smoke-test.sh | tail -5; echo "EXIT=$?"
```

The smoke test exited 1 (one failure), but `echo "EXIT=$?"` printed
the exit code of `tail`, not of `smoke-test.sh`. The wrapper reported
`EXIT=0`. The regression was only caught when PR CI ran the unwrapped
smoke test. Spec 007 FR-013 (`readme-current` sub-gate) and FR-013
were introduced in response to the rc8–rc10 evidence.

**The fundamental rule.** The gate's exit code is the release signal.
Any wrapper that captures only the last command's exit — rather than
using `${PIPESTATUS[0]}` in bash or `set -o pipefail` — will silently
mask a gate failure. The gate itself is designed never to consume its
own non-zero exit (FR-002), but the gate cannot prevent an outer
wrapper from ignoring it.

**Before tagging: run unwrapped.** Always invoke the gate directly
in a shell where its exit code is the final word:

```sh
scripts/pre-release-gate.sh
echo "gate exit: $?"
```

Do not pipe, redirect, or wrap it inside command substitution for the
authoritative pre-tag run. CI may use `set -eo pipefail` to be safe,
but the manual pre-tag check should be a naked invocation.

**The five wrapper compositions tested.** `tests/release-gate/test-gate-wrapper.sh`
verifies the gate propagates a non-zero exit through: (1) direct
invocation, (2) pipe to `tail`, (3) pipe to `tee`, (4) command
substitution, (5) redirect to file. All five must pass before
a gate version ships.

## VERSION-bump discipline

**Bump `VERSION` BEFORE tagging, not after.** The `VERSION` file at
the tagged commit must equal the tag name. A tag pushed against a
commit where `VERSION` still reads the previous rc value creates a
mismatch between `git describe` output, the `readme-current` sub-gate's
check, and downstream `TEMPLATE_VERSION` stamps.

The canonical bump order at rc-cut (per `docs/pm/SCHEDULE-EVIDENCE.md`
M8 owners ledger, release-engineer row):

1. Bump `VERSION` to the new rc string (e.g., `v1.0.0-rc13`).
2. Touch `README.md` if it does not already mention the new version
   string (satisfies the `readme-current` sub-gate FR-013).
3. Commit both files as the "tag-cut step 1" commit.
4. Run `scripts/pre-release-gate.sh` against that commit.
5. If PASS: `git tag -a v1.0.0-rcN -m "v1.0.0-rcN"` at that commit.
6. `git push origin main && git push origin v1.0.0-rcN`.

Post-tag `VERSION` bumps to the next development version are correct
only for stable/final releases where the next commit starts a new MINOR
or MAJOR. Do not bump `VERSION` to a future value before the current
tag is cut — the gate's `readme-current` sub-gate will see the future
string and potentially flag a mismatch.

**Historical lesson.** The rc10/rc11 window surfaced mismatches between
the tag name and the `VERSION` content at the tagged commit. The
`readme-current` sub-gate (FR-013) was introduced explicitly because
the rc8–rc10 cycle shipped stale README content when the version bump
and the tag were not kept in lockstep.

**Cross-reference.** `docs/versioning.md` § "Tag and GitHub Release
policy" is the canonical tag-naming rule. LESSONS.md 2026-05-03 entry
"Do not repair historical rc tags in place" documents why VERSION
mismatches at a public tag are permanent.

## GitHub Release object policy

**MINOR boundaries only (post-1.0).** After `v1.0.0` final ships,
GitHub Release objects are created only at MINOR (or MAJOR) version
boundaries — not for every PATCH. PATCH release notes fold into the
next MINOR Release object. Per the auto-memory entry
`project_releases_at_minor_only`:

> Tags every change; Release objects MINOR-only; PATCH notes fold into
> next MINOR. Don't propose backfill.

**Current-cycle rule (rc track).** Under the active `v1.0.0-rcN`
candidate track, GitHub Release objects are created only for
`v1.0.0` final. Do not create GitHub Release objects for any `v1.0.0-rcN`
tag unless a recorded customer decision changes this policy. The
authoritative statement is `docs/versioning.md` § "Tag and GitHub
Release policy":

> GitHub Release objects are created only for stable/final releases.
> For this cycle, the first GitHub Release object is `v1.0.0` final.

**When creating a Release object (post-1.0 MINOR+).** The Release
object's body must match the `CHANGELOG.md` section for that version
plus the upgrade instructions from the release notes. It must agree
with the annotated tag on version name and commit SHA. The Release
object body is coordinated with `tech-writer` for prose; the pipeline
integration and artifact attachment are owned here.

**No Release from a moving target.** Do not create a GitHub Release
object from a branch tip or from an rc tag. The source of truth is the
immutable annotated tag at the commit that passed the pre-release gate.
