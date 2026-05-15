---
name: fw-adr-0010-pre-bootstrap-local-edit-safety
description: Pre-bootstrap uses a 3-SHA decision matrix with refuse-on-uncertain semantics and an explicit override env var.
status: accepted
date: 2026-05-14
---


# FW-ADR-0010 — Pre-bootstrap respects local edits (refuse-on-uncertain)

<!-- TOC -->

- [Status](#status)
- [Context and problem statement](#context-and-problem-statement)
- [Decision drivers](#decision-drivers)
- [Considered options (Three-Path Rule, binding)](#considered-options-three-path-rule-binding)
  - [Option M — Minimalist: warn-then-overwrite (status quo + louder log)](#option-m--minimalist-warn-then-overwrite-status-quo--louder-log)
  - [Option S — Scalable: 3-SHA decision matrix with refuse-on-uncertain + explicit override](#option-s--scalable-3-sha-decision-matrix-with-refuse-on-uncertain--explicit-override)
  - [Option C — Creative: pre-bootstrap as a structured 3-way merge](#option-c--creative-pre-bootstrap-as-a-structured-3-way-merge)
- [Decision outcome](#decision-outcome)
  - [3-SHA decision matrix (binding)](#3-sha-decision-matrix-binding)
  - [Interface decisions (binding)](#interface-decisions-binding)
  - [Override mechanism: `SWDT_PREBOOTSTRAP_FORCE=1`](#override-mechanism-swdt_prebootstrap_force1)
  - [Unreachable-baseline behaviour: refuse + retrofit](#unreachable-baseline-behaviour-refuse--retrofit)
  - [Block artefact: `.template-prebootstrap-blocked.json`](#block-artefact-template-prebootstrap-blockedjson)
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

- **Accepted: 2026-05-14**
- **Deciders:** `architect` + `tech-lead` + customer (public-API change
  to `scripts/upgrade.sh` and to `migrations/v0.14.0.sh`'s
  pre-bootstrap step; customer approval required per CLAUDE.md
  Hard Rules)
- **Consulted:** upstream issue #170 (the regression), upstream issue
  #163 (customisation-marker, sequenced after this ADR), upstream
  issue #172 (rc9 schema-backfill widening, cross-referenced),
  `software-engineer` (proposal phase to follow), `qa-engineer`
  (smoke-test coverage to follow), `release-engineer` (CI follow-up).

## Context and problem statement

Commit `19e39bc` ("pre-bootstrap fix for cross-MAJOR upgrades") added
an atomic pre-bootstrap step to `migrations/v0.14.0.sh` (lines 42–79)
and to the equivalent self-bootstrap block in `scripts/upgrade.sh`
(lines 406–460). The fix solved a real bug — pre-v0.15.0 upgrade.sh
versions performed an in-place `cp` over the running script, mutating
the inode bash was reading from and producing arbitrary mid-loop
crashes. Atomic mv-rename leaves the parent's open fd on the original
inode and is correct in the unedited case.

The regression filed as issue #170: the pre-bootstrap step makes a
binary decision — `cmp -s` returns non-zero → atomic-replace. It does
not distinguish between (a) the project file is the stock baseline
that the upgrade is meant to update, and (b) the project file carries
local edits — SPDX headers, project-specific customisations, local
hot-fixes — that the operator made deliberately. Today's path silently
overwrites case (b) with at most a stderr `WARN`, violating the
framework's "customisation wins" rule that
`docs/framework-project-boundary.md` and FW-ADR-0002 both commit to.
The damage is structural: pre-bootstrap runs *before* the regular
sync loop's 3-way compare, so the manifest-based safeguards from
FW-ADR-0002 never see the file in its edited state. The customer
flagged the regression on 2026-05-14 and ruled on the fix shape
(rulings recorded below). ADR-trigger rows that fire: cross-cutting
pattern change (the upgrade contract itself), new exit code on a
public CLI surface, new env var, new artefact written to the project
tree, choice that locks future releases into a refuse-on-uncertain
posture for bootstrap-critical files.

## Decision drivers

- **Customisation wins.** Bootstrap-critical files (`scripts/upgrade.sh`,
  `scripts/lib/*.sh`) are framework-managed *and* legitimately edited
  in the wild — SPDX headers stamped by downstream legal review,
  project hot-fixes back-ported during incident response, customer
  trials of unreleased patches. Silent clobber breaks downstream
  trust.
- **Cross-MAJOR safety must survive.** The original `19e39bc` fix
  exists for a real reason. Whatever we ship here must keep
  pre-v0.15.0 → v0.15.0+ upgrades from crashing mid-loop on the
  in-place-cp bug.
- **Self-service override for power users.** Some operators *will*
  want to force the bootstrap (e.g., they have audited the candidate
  and know their local edits are obsolete). They should not need to
  `rm` files, hand-edit the migration script, or invoke a hidden
  flag.
- **Refuse-on-uncertain over clobber.** Where the framework cannot
  decide unambiguously, the safe default is to refuse and surface the
  decision to the operator. This is the same posture FW-ADR-0002
  takes for manifest drift (`--verify` reports; `upgrade.sh` resyncs
  unchanged-since-scaffold but flags customised paths).
- **Audit-evident overrides.** When the operator does force, the
  bypass needs a tamper-evident record, matching the existing
  `docs/pm/pre-release-gate-overrides.md` audit-log pattern.
- **Baseline-may-be-unreachable.** The `WORKDIR_OLD` clone exists in
  the upgrade flow but may be empty when the project's stamped tag
  was force-pushed away or the upstream URL changed. Today's path
  has no graceful behaviour here; we must define one.
- **Idempotency.** Re-running upgrade after the operator resolves a
  block must converge without oscillation, the same invariant
  FW-ADR-0002 carries.

## Considered options (Three-Path Rule, binding)

### Option M — Minimalist: warn-then-overwrite (status quo + louder log)

Keep the existing atomic-replace path. Raise the stderr `WARN` to
ERROR-loudness, document that operators carrying local edits to
bootstrap-critical files MUST list them in
`.template-customizations` before running `upgrade.sh`.

- **Sketch:** No code change to the decision logic; only the log
  level changes. The `.template-customizations` mechanism already
  exists and is the documented way to declare permanent
  customisations.
- **Pros:**
  - Zero new state in the project tree.
  - Zero new exit code, env var, or artefact.
  - Cheapest implementation.
- **Cons:**
  - Pushes the discovery burden onto the operator at exactly the
    wrong moment: by the time the `WARN` fires, the file has
    already been overwritten and the local edit is gone (the
    `mv` is atomic; there is no rollback).
  - `.template-customizations` is not currently honoured by the
    pre-bootstrap path (it short-circuits before the sync loop
    that reads it); fixing that requires the same work as Option S
    minus the override mechanism.
  - Issue #170's reporter explicitly stated they had no warning the
    file was about to be replaced. "Louder log" does not satisfy
    the framework/project boundary commitment.
- **When M wins:** if pre-bootstrap-critical files were never
  customised in practice. The customer's 2026-05-14 ruling
  establishes that they are.

### Option S — Scalable: 3-SHA decision matrix with refuse-on-uncertain + explicit override

Pre-bootstrap computes three SHAs per bootstrap-critical file —
*project* (on-disk now), *baseline* (`WORKDIR_OLD/<path>`, the
stamped-version content), *upstream* (`WORKDIR_NEW/<path>`, the
candidate). Decide per the matrix in
[3-SHA decision matrix (binding)](#3-sha-decision-matrix-binding)
below. Refuse-with-artefact on the ambiguous case; provide
`SWDT_PREBOOTSTRAP_FORCE=1` as the operator's self-service override.
If the baseline is unreachable, refuse outright and direct the
operator to the retrofit playbook.

- **Sketch:** Replace the bare `cmp -s` check in
  `scripts/upgrade.sh` (~line 417) and `migrations/v0.14.0.sh`
  (~line 57) with a function that does the 3-SHA compare, applies
  the matrix, and either proceeds (no edit detected; safe to
  atomic-replace), no-ops (project already matches upstream), or
  refuses (block artefact written, exit 2). The retrofit path
  is the public escape hatch for the unreachable-baseline case
  and for force-overrides that need a paper trail.
- **Pros:**
  - Preserves the cross-MAJOR safety the original `19e39bc` patch
    delivered.
  - Honours customisation in the bootstrap window, closing the
    framework/project boundary gap.
  - Refuse-on-uncertain matches FW-ADR-0002's posture; the
    upgrade contract gets a consistent rule across both windows.
  - Override is auditable: a forced run leaves a row in the
    override audit log, no different from
    `SKIP_PRE_RELEASE_GATE=1`.
  - The block artefact is machine-parseable; CI gates and
    follow-up tooling can react.
- **Cons:**
  - New exit code (2) on `scripts/upgrade.sh`; new env var
    (`SWDT_PREBOOTSTRAP_FORCE`); new artefact
    (`.template-prebootstrap-blocked.json`). All three are
    additive surface that future releases must keep
    backward-compatible.
  - Pre-bootstrap now requires `WORKDIR_OLD` to be populated to
    distinguish the safe overwrite case from the customised case.
    Today the bootstrap path runs before the baseline clone in
    some flows; the implementation must hoist the baseline clone
    earlier or accept refusal as the default when the baseline
    is unavailable.
  - Refuse-on-uncertain shifts work onto the operator in the
    unreachable-baseline case; the retrofit playbook becomes
    load-bearing.
- **When S wins:** the framework's actual use case — long-lived
  projects with local edits, intermittent upstream connectivity,
  audit requirements on overrides. Maps cleanly to FW-ADR-0002.

### Option C — Creative: pre-bootstrap as a structured 3-way merge

Drop the atomic-replace model entirely. Pre-bootstrap performs a
real 3-way merge (`git merge-file -p` or equivalent) between
project / baseline / upstream for each bootstrap-critical file. If
the merge is clean, write the merged result atomically. If conflict
markers appear, refuse with the conflicted file written for the
operator to resolve.

- **Sketch:** Treat the bootstrap window as the same problem-space
  as the regular sync loop, just earlier. `git merge-file` already
  exists in the upgrade environment (git is a hard dependency).
  The merge produces a single output, conflict markers and all.
- **Pros:**
  - Most theoretically correct — preserves additive customisations
    (an SPDX header at the top of `upgrade.sh` would survive a
    cross-MAJOR upgrade automatically because it has no upstream
    conflict).
  - One concept (3-way merge) governs both bootstrap and sync.
  - No new exit code: a conflicted file is itself the signal.
- **Cons:**
  - `scripts/upgrade.sh` mid-execution would now potentially be
    rewritten with merge markers in it. The atomic-mv inode trick
    still works for the running process, but the on-disk state
    after the run is "shell script with conflict markers", which
    won't run.
  - Conflict resolution in shell-script files is fragile; a
    merge marker inside a heredoc or case branch silently
    breaks future runs.
  - Loses the binary "did the operator approve this" signal that
    the customer's ruling specifically asked for. A merged file
    is *neither* the operator's edit nor the upstream — it's a
    new artifact nobody reviewed.
  - The override semantics get murky: `SWDT_PREBOOTSTRAP_FORCE=1`
    has no good meaning against a merge — `take-ours`, `take-theirs`,
    and `accept-conflict-markers` are all wrong in a different real
    scenario.
- **When C wins:** if the bootstrap-critical fileset were prose or
  data, not executable shell. It is shell. C loses on the
  conflict-marker-in-executable failure mode alone.

## Decision outcome

**Chosen option: S (3-SHA decision matrix with refuse-on-uncertain +
explicit override).**

**Reason:** Option M cannot satisfy the customer's 2026-05-14 ruling
that today's silent-overwrite-with-warning behaviour is rejected.
Option C trades a known-good binary decision for an unsafe merge
output in executable files; the conflict-markers-in-shell failure
mode is worse than the bug we're fixing. Option S maps cleanly onto
FW-ADR-0002's refuse-on-uncertain posture, keeps the cross-MAJOR
safety of `19e39bc`, gives operators a self-service override the
customer's ruling explicitly preferred over `rm`-then-re-run, and
provides an audit-evident record of every force. The cost — one
new exit code, one new env var, one new artefact — is bounded and
falls into the existing CLI/audit-log surface.

### 3-SHA decision matrix (binding)

For each bootstrap-critical file (`scripts/upgrade.sh` and every
`scripts/lib/*.sh` shipped by the candidate), pre-bootstrap
computes:

- `project_sha` — SHA-256 of `$PROJECT_ROOT/<path>` (current
  on-disk state).
- `baseline_sha` — SHA-256 of `$WORKDIR_OLD/<path>` (the
  project's stamped-version content as cloned at upgrade
  start). Empty / absent if `WORKDIR_OLD` is unavailable or
  the path is missing in the baseline tree.
- `upstream_sha` — SHA-256 of `$WORKDIR_NEW/<path>` (the
  candidate's content).

Decision:

| project | baseline | upstream | action |
|---------|----------|----------|--------|
| `=` baseline | present | `=` project | **no-op** (project already at upstream; nothing to do) |
| `=` baseline | present | `≠` project | **proceed** (atomic-replace; project is unedited baseline, candidate is the intended update) |
| `≠` baseline | present | `=` project | **no-op** (operator already advanced to the candidate content by other means) |
| `≠` baseline | present | `≠` project | **refuse** (local edit detected; write block artefact; exit 2 unless `SWDT_PREBOOTSTRAP_FORCE=1`) |
| any           | absent  | `=` project | **no-op** (cannot distinguish edited vs baseline; but project already matches candidate so no action needed) |
| any           | absent  | `≠` project | **refuse + retrofit** (unreachable baseline; cannot decide safely; write block artefact citing the retrofit playbook; exit 2 unless `SWDT_PREBOOTSTRAP_FORCE=1`) |

"Refuse" means: write `.template-prebootstrap-blocked.json` with one
entry per affected path, print an actionable summary to stderr
naming the env-var override and the retrofit playbook, exit 2.
`upgrade.sh --dry-run` does the same check but does not write the
block artefact; it prints what *would* be blocked.

### Interface decisions (binding)

1. **New exit code on `scripts/upgrade.sh`.**
   - `0` — upgrade completed (manifest written, files synced).
   - `1` — upgrade failed (existing semantics).
   - **`2` — pre-bootstrap refused** (new). One or more
     bootstrap-critical files carry local edits or the baseline
     is unreachable. `.template-prebootstrap-blocked.json` is
     present at the project root and lists every affected path.
   - Exit codes `3+` reserved for future use; do not assign
     without a follow-up ADR.

2. **New env var: `SWDT_PREBOOTSTRAP_FORCE`.**
   - `SWDT_PREBOOTSTRAP_FORCE=1` — operator has acknowledged the
     block and explicitly authorises atomic-replace of every
     bootstrap-critical file, including those with local edits.
     Pre-bootstrap proceeds; no block artefact is written; an
     audit row is appended to `docs/pm/pre-release-gate-overrides.md`
     before any file is touched.
   - Unset / `0` / any-other-value — pre-bootstrap refuses on the
     local-edit case (matrix above).
   - Naming follows the `SWDT_` prefix already used for
     `SWDT_BOOTSTRAPPED` and `SWDT_PRESTAGED_WORKDIR`.

3. **New artefact: `.template-prebootstrap-blocked.json`.**
   - Written at project root by `scripts/upgrade.sh` and by
     `migrations/v0.14.0.sh`'s pre-bootstrap block when the
     decision matrix returns "refuse".
   - Schema: top-level object with `version`, `generated`,
     `reason_summary`, and `blocked` (an array of per-path
     entries). Per the customer's ruling, each entry carries
     `path`, `project_sha`, `baseline_sha`, `upstream_sha`,
     `reason`. See
     [Block artefact: `.template-prebootstrap-blocked.json`](#block-artefact-template-prebootstrap-blockedjson)
     below for the full shape.
   - Idempotent: re-running pre-bootstrap on the same project
     state overwrites the artefact with identical content (the
     timestamp field is the only line that may change).
   - Cleared when a subsequent run succeeds (the file is
     removed atomically at the end of a successful pre-bootstrap
     pass). Stale-after-success is an issue #170-regression
     signal.
   - Added to the upgrader's "do not commit" guidance in
     `docs/TEMPLATE_UPGRADE.md` (follow-up work; not part of
     this ADR's mandate).

4. **Logging contract.**
   - On refuse: stderr `ERROR` line per blocked path, plus a
     summary block naming `SWDT_PREBOOTSTRAP_FORCE=1` and the
     retrofit playbook path. Machine-parseable: each ERROR
     line carries the path and the matrix row that fired
     (`reason=local-edit` or `reason=baseline-unreachable`).
   - On override: `WARN` line per overridden path before the
     atomic-replace, plus a single `WARN` confirming the audit
     row was appended.
   - On no-op / proceed: existing log shape, no new lines.

### Override mechanism: `SWDT_PREBOOTSTRAP_FORCE=1`

Per the customer's 2026-05-14 ruling, the env-var override IS the
self-service knowing-override path. The `rm`-then-re-run
alternative was rejected.

**Audit-log surface.** Override rows append to the existing
`docs/pm/pre-release-gate-overrides.md` audit log. Rationale for
re-using the existing file rather than spinning up a sibling:

- The existing file already commits to "append-only;
  tamper-evidence is `git log -p` on this path", which is exactly
  the contract this ADR needs.
- Cross-cutting overrides (someone forces past pre-bootstrap, then
  forces past pre-release-gate on the same release) end up in one
  scrollable history rather than two.
- The cost of overloading: the existing table header
  (`Date | Commit SHA | Tag pushed | Operator | Reason | Sub-gates`)
  does not exactly fit a pre-bootstrap event (no `Tag pushed`, no
  `Sub-gates`). Mitigation per customer ruling 2026-05-14 (option A,
  "overload one register with a discriminator column"): extend the
  table with a `Gate` column placed immediately after `Date`,
  distinguishing `pre-release` from `pre-bootstrap` rows; leave
  `Tag pushed` and `Sub-gates that would have run` empty for
  pre-bootstrap rows; document the column extension in the file's
  header block. The new schema header is:

  ```
  | Date | Gate | Commit SHA | Tag pushed | Operator | Reason | Sub-gates that would have run |
  ```

  This is a schema bump (v2) on a single project-filled register
  file, not a framework-managed file, so the change is in-scope for
  the rc12 follow-up branch. Rows that predate the schema bump have
  an empty `Gate` cell; readers MUST treat empty as `pre-release` for
  back-compat. `.git-hooks/pre-push` writes `pre-release` into the
  new column for `SKIP_PRE_RELEASE_GATE=1` bypasses;
  `scripts/upgrade.sh` and `migrations/v0.14.0.sh` write
  `pre-bootstrap` for `SWDT_PREBOOTSTRAP_FORCE=1` bypasses. Rejected
  alternatives — option B "two registers" (splits the tamper-evidence
  surface across two files) and option C "single register, no
  discriminator column" (relies on free-text `Reason` to disambiguate
  event type, fragile to machine-parse) — were considered and
  rejected.

If the audit log is unwritable, pre-bootstrap refuses the override
(same posture as the pre-release-gate hook). The operator's
recovery is to fix permissions, not to bypass the audit
requirement.

`SWDT_PREBOOTSTRAP_FORCE=1` overrides the local-edit case AND the
baseline-unreachable case. Both write an audit row with the
matrix-row reason recorded.

### Unreachable-baseline behaviour: refuse + retrofit

Per the customer's 2026-05-14 ruling, when `WORKDIR_OLD` is
unavailable (force-pushed tag, upstream URL changed, baseline
clone failed, network down), pre-bootstrap refuses the upgrade
outright. Today's silent-overwrite-with-warning fallback is
rejected. The operator's recovery path is to follow the retrofit
playbook (`docs/templates/retrofit-playbook-template.md`-shaped
procedure), which walks them through:

1. Confirming the local edits to bootstrap-critical files.
2. Capturing those edits in `.template-customizations` or in a
   project-owned overlay before re-running.
3. Re-running `upgrade.sh` once the baseline situation is
   resolved (or with `SWDT_PREBOOTSTRAP_FORCE=1` if they have
   accepted that the local edits will be overwritten).

The block artefact's `reason` field for these rows is
`baseline-unreachable`. The stderr summary names the retrofit
playbook by path.

### Block artefact: `.template-prebootstrap-blocked.json`

Schema (v1):

```json
{
  "version": 1,
  "generated": "<ISO-8601 UTC timestamp>",
  "reason_summary": "local-edit | baseline-unreachable | mixed",
  "blocked": [
    {
      "path": "scripts/upgrade.sh",
      "project_sha": "<sha256 of on-disk file>",
      "baseline_sha": "<sha256 of WORKDIR_OLD/<path>, or empty>",
      "upstream_sha": "<sha256 of WORKDIR_NEW/<path>>",
      "reason": "local-edit | baseline-unreachable"
    }
  ]
}
```

Field rules:

- `version` is an integer; future schema bumps are MINOR-version
  events with a deprecation window, matching the JSONL contract
  FW-ADR-0002 set for `--verify --format=json`.
- `generated` is the only field expected to vary between
  idempotent re-runs.
- `reason_summary` is `local-edit` if every entry is `local-edit`,
  `baseline-unreachable` if every entry is `baseline-unreachable`,
  `mixed` otherwise.
- `baseline_sha` is the empty string (not the SHA-256 of an empty
  file) when the baseline is unreachable for that path.
- `blocked` is sorted by `path` for determinism.

The artefact is added to a recommended `.gitignore` entry shipped
with the template (follow-up `software-engineer` work; not in
this ADR's mandate). It is project-local state, not a framework
register.

## Consequences

### Positive

- The issue #170 regression closes structurally: silent overwrite of
  bootstrap-critical files becomes impossible from this ADR's
  implementation forward.
- The "customisation wins" rule the framework already commits to in
  the regular sync loop now extends into the pre-bootstrap window.
- Cross-MAJOR safety from `19e39bc` is preserved: the atomic-replace
  path still runs in the unedited case, which is the case the
  original fix was for.
- Operators have a documented, self-service knowing-override path
  (`SWDT_PREBOOTSTRAP_FORCE=1`) that the customer's ruling
  preferred over `rm`-then-re-run.
- Forced overrides are tamper-evident via the existing audit-log
  surface; no parallel audit mechanism to maintain.
- The unreachable-baseline case routes operators to a procedure
  rather than a guess.

### Negative / trade-offs accepted

- New exit code (2), new env var (`SWDT_PREBOOTSTRAP_FORCE`), new
  artefact (`.template-prebootstrap-blocked.json`) on the public
  surface of `scripts/upgrade.sh`. All three are backward-
  compatible additions (no existing exit code is repurposed) but
  future releases must keep them.
- Pre-bootstrap now depends on `WORKDIR_OLD` being populated for
  the non-refuse case. The implementation must ensure the baseline
  clone runs before pre-bootstrap, or accept refusal as the
  default when the baseline is absent.
- Refuse-on-uncertain shifts work onto the operator in the
  baseline-unreachable case. The retrofit playbook becomes
  load-bearing for that recovery path.
- The override-audit-log file
  (`docs/pm/pre-release-gate-overrides.md`) takes on a second event
  type. Schema extension (new `Gate` column) is a small
  in-scope change to a project-filled register.
- Operators who carry local edits without declaring them in
  `.template-customizations` will see refusals where today they
  saw silent overwrites. This is the intended customer-visible
  behaviour change; release notes must call it out.

### Follow-up ADRs

- None required for this ADR's scope. A future ADR may revisit the
  3-SHA matrix if the bootstrap-critical fileset grows beyond
  shell scripts (e.g., binary helpers, generated Python modules)
  where SHA comparison is too coarse.

## Relationship to other ADRs and issues

- **FW-ADR-0002 (manifest verification).** This ADR extends
  FW-ADR-0002's manifest-verification contract — refuse-on-
  uncertain, no silent clobber, customisation wins — into the
  pre-bootstrap window. FW-ADR-0002 covered the regular sync loop;
  this ADR closes the bootstrap-window gap. The 3-SHA decision is
  philosophically the same shape as FW-ADR-0002's
  unchanged-since-scaffold vs customised-since-scaffold check; the
  difference is that pre-bootstrap runs before the manifest is
  consulted, so it has to recompute the SHAs against `WORKDIR_OLD`
  directly.
- **Issue #163 (customisation-marker for `scripts/upgrade.sh` +
  `scripts/lib/*.sh`).** Sequenced *after* this ADR per the
  customer's 2026-05-14 ruling. Without this ADR's
  refuse-on-uncertain behaviour, the customisation marker would
  silently mislead operators: a project could declare a file
  customised and *still* see it overwritten in pre-bootstrap.
  With this ADR shipped, the marker is safe to add because the
  pre-bootstrap path will refuse on edit regardless. #163 can be
  scoped narrowly to the marker UX and to the regular sync loop's
  handling of bootstrap-critical paths; it does not need to
  reopen the pre-bootstrap decision.
- **Issue #172 (rc9 schema-backfill widening to `*-local.md`
  supplements).** Independent work track. The rc9 migration's
  widened scope and this ADR both involve the framework/project
  boundary; both are customer-accepted boundary crossings for
  specific, bounded reasons. Cross-referenced because future
  auditors reading either change will likely look for the other.
  No technical coupling.

## Verification

- **Success signal:** smoke-test suite (extended in `qa-engineer`'s
  phase) covers (a) a project with no edits to bootstrap-critical
  files upgrades cleanly (no block artefact, exit 0); (b) a
  project with a stamped SPDX header on `scripts/upgrade.sh`
  refuses with exit 2 and writes the block artefact;
  (c) re-running with `SWDT_PREBOOTSTRAP_FORCE=1` proceeds, writes
  the audit row, removes the block artefact, completes the
  upgrade; (d) a deliberately-broken baseline (empty
  `WORKDIR_OLD`) refuses with exit 2 and `reason=baseline-unreachable`;
  (e) idempotent re-run produces an identical block artefact
  (timestamp aside); (f) the block artefact is cleared on the
  next successful run.
- **Failure signal:** an upstream issue reports either (i) a
  bootstrap-critical local edit was overwritten on a non-force
  run, or (ii) `SWDT_PREBOOTSTRAP_FORCE=1` failed to write an
  audit row, or (iii) the JSON schema for
  `.template-prebootstrap-blocked.json` shifted between patch
  releases.
- **Review cadence:** at the next MINOR release that touches
  `scripts/upgrade.sh` or the migration queue. Reconsider if any
  failure signal fires, or if the bootstrap-critical fileset
  grows to include non-shell artefacts.

## Links

- Upstream issues:
  - `#170 — pre-bootstrap respects local edits` (this ADR)
  - `#163 — customisation-marker for bootstrap-critical files`
    (sequenced after this ADR)
  - `#172 — rc9 schema-backfill widened to *-local.md`
    (independent; cross-referenced)
- Related ADRs:
  - `FW-ADR-0002 — upgrade content verification` (extends its
    refuse-on-uncertain posture into the pre-bootstrap window)
- Related artefacts:
  - `scripts/upgrade.sh` (lines 406–460 — self-bootstrap block)
  - `migrations/v0.14.0.sh` (lines 42–79 — pre-bootstrap block)
  - `docs/framework-project-boundary.md` (path ownership;
    customisation-wins commitment)
  - `docs/pm/pre-release-gate-overrides.md` (audit-log surface
    extended by this ADR)
  - `docs/templates/retrofit-playbook-template.md` (procedure
    operators follow on baseline-unreachable refusal)
- Original change introducing the regression: commit `19e39bc`
  (pre-bootstrap fix for cross-MAJOR upgrades).
- External references: MADR 3.0 (`https://adr.github.io/madr/`).
