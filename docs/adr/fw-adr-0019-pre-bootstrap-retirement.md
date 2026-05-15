---
name: fw-adr-0019-pre-bootstrap-retirement
description: Formally retires the pre-bootstrap class. Marks FW-ADR-0010 and FW-ADR-0013 superseded, removes the inert rc13/rc14 migration files, deprecates the SWDT_PREBOOTSTRAP_FORCE env var and .template-prebootstrap-blocked.json artefact, and retires the Gate=pre-bootstrap audit-log value for new rows. Final ADR in the FW-ADR-0015..0019 upgrade-flow rearchitecture sequence; blocked from acceptance until the FW-ADR-0018 rc15 lineage lands clean.
status: proposed
date: 2026-05-15
---


# FW-ADR-0019 — Pre-bootstrap class retirement

<!-- TOC -->

- [Status](#status)
- [Context and problem statement](#context-and-problem-statement)
- [Decision drivers](#decision-drivers)
- [Considered options (Three-Path Rule, binding)](#considered-options-three-path-rule-binding)
  - [Option M — Minimalist: full retirement, sequenced after rc15 lineage lands clean (chosen)](#option-m--minimalist-full-retirement-sequenced-after-rc15-lineage-lands-clean-chosen)
  - [Option S — Scalable: leave inert files in place indefinitely as historical record](#option-s--scalable-leave-inert-files-in-place-indefinitely-as-historical-record)
  - [Option C — Creative: aggressive retirement BEFORE rc15 lineage lands clean](#option-c--creative-aggressive-retirement-before-rc15-lineage-lands-clean)
- [Decision outcome](#decision-outcome)
- [Interface decisions (binding)](#interface-decisions-binding)
  - [1. Trigger condition (when proposed → accepted)](#1-trigger-condition-when-proposed--accepted)
  - [2. Inert migration-file removal timing](#2-inert-migration-file-removal-timing)
  - [3. FW-ADR-0010 + FW-ADR-0013 status transitions](#3-fw-adr-0010--fw-adr-0013-status-transitions)
  - [4. `SWDT_PREBOOTSTRAP_FORCE` env var deprecation curve](#4-swdt_prebootstrap_force-env-var-deprecation-curve)
  - [5. `.template-prebootstrap-blocked.json` artefact deprecation curve](#5-template-prebootstrap-blockedjson-artefact-deprecation-curve)
  - [6. `Gate=pre-bootstrap` audit-log column value](#6-gatepre-bootstrap-audit-log-column-value)
  - [7. Cleanup ordering (binding sequence)](#7-cleanup-ordering-binding-sequence)
- [Consequences](#consequences)
  - [Positive](#positive)
  - [Negative / trade-offs accepted](#negative--trade-offs-accepted)
- [Verification](#verification)
- [Implementation notes for software-engineer](#implementation-notes-for-software-engineer)
- [Open questions](#open-questions)
- [Links](#links)

<!-- /TOC -->

Shape per MADR 3.0 + this template's Three-Path Rule
(`docs/templates/adr-template.md`). Fifth and final in the
upgrade-flow rearchitecture sequence (FW-ADR-0015 foundation,
FW-ADR-0016 state schema, FW-ADR-0017 file-keyed discovery,
FW-ADR-0018 bridging rc, **FW-ADR-0019 pre-bootstrap retirement**).
Cleanup ADR; less structural meat than 0015–0018. Cap ~400 lines.

---

## Status

- **Proposed: 2026-05-15**
- **Blocked from acceptance until the FW-ADR-0018 rc15 lineage lands
  clean.** Per FW-ADR-0018 § 8 "Coordination with FW-ADR-0019":
  FW-ADR-0019 cannot ship until the highest-x rc15.x tag has cut
  with 12/12 dogfood PASS + AI-TUI PASS AND at least one downstream
  has run the bridging migration successfully. See § 1 below for
  the binding trigger condition.
- **Deciders:** `architect` + `tech-lead` + customer (cleanup of a
  cross-cutting pattern this ADR retires; supersession of two
  prior accepted ADRs; customer approval per CLAUDE.md Hard Rules
  because the env var, artefact, and audit-log column value were
  customer-ruled into existence in 2026-05-14).
- **Consulted:** FW-ADR-0015 (stub-model foundation; this ADR
  formalises the FW-ADR-0010 / FW-ADR-0013 supersession FW-ADR-0015
  authorised), FW-ADR-0016 (state schema; consolidates the legacy
  trio that pre-bootstrap protected), FW-ADR-0017 (file-keyed
  discovery; makes the rc13.sh inert by construction), FW-ADR-0018
  (transitional rc bridging; gates this ADR's acceptance),
  FW-ADR-0010 + FW-ADR-0013 (the ADRs being retired),
  `software-engineer` (file moves + status-line edits + deprecation
  WARN wiring), `release-engineer` (release-notes ordering),
  `qa-engineer` (post-bridge fixture verifies no callers of the
  deprecated env var remain), `tech-writer` (release-notes language
  for the deprecation curve).

## Context and problem statement

The pre-bootstrap class was the workaround for a structural mistake:
`scripts/upgrade.sh` was simultaneously a framework-managed file AND
the orchestrator managing other framework files, so its in-place
rewrite mid-execution corrupted the running shell. FW-ADR-0010
(2026-05-14) added the 3-SHA decision matrix, the
`SWDT_PREBOOTSTRAP_FORCE` operator override, the
`.template-prebootstrap-blocked.json` block artefact, and the
`Gate=pre-bootstrap` audit-log surface to make the workaround safe
on the v0.x → v0.15.0 cross-MAJOR cliff. FW-ADR-0013 (2026-05-15)
extended the same machinery to the rc-to-rc cliff with a cloned
`migrations/v1.0.0-rc13.sh`. Both ADRs are accepted; both ship code
in the tree today.

FW-ADR-0015 (2026-05-15) dissolved the structural mistake by making
`scripts/upgrade.sh` a stable sub-100-line stub that fetches the
real runner per invocation. Under the stub model, nothing on the
downstream tree self-mutates; the pre-bootstrap class has no
caller by construction. FW-ADR-0018 (2026-05-15) cuts one
transitional `v1.0.0-rc15` (or `v1.0.0-rc15.x` if the escape
hatch fires) to bridge currently-deployed downstreams onto the
stub model. The rc15-lineage bridging migration is itself the
LAST pre-bootstrap instance; after it runs once per downstream,
no future invocation reaches a pre-bootstrap code path.

FW-ADR-0019 closes the architecture pivot by formally retiring
the pre-bootstrap class. Once rc15 lineage lands clean and every
known operator downstream has bridged, the following cleanup
items have no callers and should be removed or deprecated:

1. **FW-ADR-0010** — status changes from `accepted` to
   `superseded by FW-ADR-0015 / FW-ADR-0019`.
2. **FW-ADR-0013** — same.
3. **`migrations/v1.0.0-rc13.sh`** — inert: rc13 was never tagged
   under FW-ADR-0017's file-keyed discovery; under the stub model
   the rc13.sh body is unreachable from any post-bridge downstream.
4. **`migrations/v1.0.0-rc14.sh`** — partially superseded:
   FW-ADR-0018's bridging migration consolidates state into
   `TEMPLATE_STATE.json`, which absorbs `.template-customizations`;
   the rc14 opt-in preservation-prune migration was a writer of
   that legacy file and has no caller post-bridge.
5. **`SWDT_PREBOOTSTRAP_FORCE` env var** — no caller post-bridge;
   the stub does not pre-bootstrap.
6. **`.template-prebootstrap-blocked.json` artefact** — no writer
   post-bridge; the stub does not produce it.
7. **`Gate=pre-bootstrap` audit-log column value** — no new rows
   land with that value post-bridge; existing rows stay (the audit
   log is append-only per FW-ADR-0010).
8. **`docs/TEMPLATE_UPGRADE.md` and any other doc** mentions of
   "pre-bootstrap" — historical references only.

ADR-trigger rows that fire: cross-cutting pattern change (the
upgrade-flow contract finishes retiring the pre-bootstrap
class); change touching the customer-flagged critical path
(upgrade); supersession of two prior accepted ADRs (interface
contract cleanup). Pure cleanup ADR; no new code surface.

## Decision drivers

- **Complete the architecture pivot.** FW-ADR-0015..0018 changed
  the model; FW-ADR-0019 removes the now-unreachable scaffolding.
  Leaving inert files and deprecated contracts on disk indefinitely
  contradicts the "no dead code in the runner's migration tree"
  hygiene that FW-ADR-0017 § 9 (migration retirement) established.
- **No stale env-var contracts.** Operators who set
  `SWDT_PREBOOTSTRAP_FORCE=1` after the rc15 lineage lands should
  get an explicit one-time WARN that the variable is deprecated
  and ignored, not silent acceptance that the framework no longer
  honours.
- **Clean audit trail.** Append-only is the audit log's tamper-
  evidence mechanism (per FW-ADR-0010 § "Override mechanism"); the
  existing `Gate=pre-bootstrap` rows stay on disk as historical
  record. New rows MUST NOT carry that value (no caller exists),
  but the column itself stays for the surviving `pre-release`
  value.
- **rc15 lineage stability is the gate.** Per FW-ADR-0018 § 8,
  the "LAST pre-bootstrap" property is asserted of the rc15
  LINEAGE as a whole (rc15 OR rc15.x for the highest-x). FW-ADR-0019
  cannot ship until that lineage is known good — otherwise the
  cleanup removes machinery a follow-up rc15.x would need.
- **No breaking change for operators who have already bridged.**
  Post-bridge downstreams should see the deprecation as a WARN at
  most; nothing they did before the deprecation lands should
  start failing.
- **Bounded deprecation tail.** Deprecate-on-read for ~1 major
  version (i.e., through v1.x; remove the WARN at v2.0.0 final).
  Long enough that any straggler operator notices; short enough
  that the deprecation tail does not become its own technical
  debt class.

## Considered options (Three-Path Rule, binding)

### Option M — Minimalist: full retirement, sequenced after rc15 lineage lands clean (chosen)

Once FW-ADR-0018's rc15 lineage cuts clean and at least one
downstream has bridged, FW-ADR-0019 flips to `accepted` and
the following land in a follow-up PR:

- File-system removals: `migrations/v1.0.0-rc13.sh`,
  `migrations/v1.0.0-rc14.sh`.
- Status-line edits: FW-ADR-0010, FW-ADR-0013 status fields
  rewritten to `superseded by FW-ADR-0015 / FW-ADR-0019`.
- Deprecation-on-read WARN wired into the runner for
  `SWDT_PREBOOTSTRAP_FORCE` and `.template-prebootstrap-blocked.json`.
  The variable and artefact become documented no-ops through the
  v1.x line; the WARN itself is removed at v2.0.0.
- Doc cleanup: any remaining "pre-bootstrap" references in
  `docs/TEMPLATE_UPGRADE.md`, runner doc, and the like become
  historical mentions with an `(retired per FW-ADR-0019)` parenthetical.

- **Sketch:** One follow-up PR after the rc15 lineage trigger
  fires. ~50 lines of changes (mostly file deletions and status-
  line edits); ~20 lines of WARN-emit logic added to the
  post-bridge runner.
- **Pros:**
  - Completes the FW-ADR-0015 architecture pivot cleanly. No
    dead code in the migration tree, no zombie env-var contract,
    no stale ADR statuses.
  - The trigger condition (rc15 lineage clean + downstream
    bridged) is observable and binary; no judgment call about
    "when is it safe?" remains at PR time.
  - Deprecation curve (WARN-on-read through v1.x; remove at
    v2.0.0) is conventional and operator-friendly.
  - Audit log stays append-only; historical rows preserved.
- **Cons:**
  - One more PR after the rc15 lineage lands. Bounded cost
    (a few file moves + status-field edits).
  - FW-ADR-0019 has a long `proposed`-window while it waits
    for rc15 lineage to clear. Risk: the proposed ADR drifts
    out of sync with the rc15 implementation. Mitigation:
    this ADR is forward-looking and lists discrete cleanup
    items; it does not pin the rc15 implementation shape.
- **When M wins:** when the prior ADRs in the chain are
  expected to ship correctly and the cleanup is a follow-up,
  not a precondition. FW-ADR-0015..0018 are all accepted;
  M wins by default.

### Option S — Scalable: leave inert files in place indefinitely as historical record

The framework keeps `migrations/v1.0.0-rc13.sh`,
`migrations/v1.0.0-rc14.sh`, the `SWDT_PREBOOTSTRAP_FORCE`
contract, and the `.template-prebootstrap-blocked.json` artefact
contract on disk through v1.x and into v2.x. FW-ADR-0010 and
FW-ADR-0013 stay `accepted` with a note that their callers no
longer fire. No cleanup PR ships.

- **Sketch:** No code changes. Zero file moves. FW-ADR-0019
  documents "we considered cleanup and chose not to."
- **Pros:**
  - Zero PR cost.
  - Maximum historical fidelity: every file the framework
    ever shipped stays in the tree.
  - No deprecation curve to manage.
- **Cons:**
  - Contradicts FW-ADR-0017 § 9 (migration retirement)
    hygiene posture. The runner's migration enumeration would
    keep encountering rc13.sh and rc14.sh on every run, do
    nothing useful with them, and require future readers to
    understand why they exist before realising they don't matter.
  - Stale `SWDT_PREBOOTSTRAP_FORCE` contract invites bug reports
    when an operator sets it expecting framework honouring and
    gets silent ignore.
  - The "LAST pre-bootstrap" promise of FW-ADR-0018 stays
    informally true but unaudited; no structural defence
    against a future maintainer reintroducing the pattern.
- **When S wins:** if the cost of the cleanup PR were
  prohibitively high (it is not — single PR, file moves +
  status edits) OR if the migration files had ongoing utility
  (they do not under the stub model).

### Option C — Creative: aggressive retirement BEFORE rc15 lineage lands clean

The framework ships FW-ADR-0019's cleanup ahead of FW-ADR-0018's
rc15 lineage clearing. The rc13.sh / rc14.sh files are removed,
the env var and artefact are deprecated, and FW-ADR-0010 +
FW-ADR-0013 are marked superseded — all while operators are still
on pre-bridge downstreams that need those files.

- **Sketch:** FW-ADR-0019 lands first; FW-ADR-0018's rc15 ships
  after, into a tree where the inert-but-still-needed-for-pre-bridge
  files are already gone.
- **Pros:**
  - Maximum aggression on the cleanup; no transitional state.
  - Forces FW-ADR-0018 to ship the bridging migration WITHOUT
    depending on any FW-ADR-0010 machinery (since it would
    already be gone). Reveals any hidden dependencies in
    FW-ADR-0018's pre-bootstrap step.
- **Cons:**
  - **Strands pre-bridge downstreams.** Operators who have not
    yet run the bridging migration still need the FW-ADR-0010
    pre-bootstrap pattern (the bridging migration's step (a)
    inherits it per FW-ADR-0018 § 3). Removing the pattern
    before they bridge means they cannot bridge.
  - **Contradicts FW-ADR-0018 § 8 binding sequencing.** That
    section pins FW-ADR-0019 to ship AFTER the rc15 lineage
    clears. Option C reverses the dependency.
  - **No structural benefit.** Aggressive retirement is purely
    rhetorical; the file-system state at v2.0.0 is identical
    under M and C. Only the intermediate timeline differs,
    and C's intermediate timeline is broken.
- **When C wins:** if there were a measurable cost to keeping
  the inert files in place during the rc15-lineage window. There
  is not — the inert files no-op on already-bridged downstreams
  per FW-ADR-0017 § 5 idempotency, and they continue to function
  for not-yet-bridged downstreams.

## Decision outcome

**Chosen option: M (full retirement, sequenced after rc15 lineage
lands clean).**

**Reason:** Option M is the only option that completes the FW-ADR-0015
architecture pivot without stranding pre-bridge downstreams (Option C
fails on that axis) and without leaving dead code + zombie contracts
in the tree indefinitely (Option S fails on that axis). The trigger
condition (§ 1 below) is observable and binary; the cleanup ordering
(§ 7) is sequenced so each step is reversible until its predecessor
is verified. Option M honours FW-ADR-0018 § 8's binding pin
(FW-ADR-0019 ships AFTER rc15 lineage clears) by construction.

## Interface decisions (binding)

### 1. Trigger condition (when proposed → accepted)

FW-ADR-0019 flips from `proposed` to `accepted` when **all** of the
following hold:

- (a) `v1.0.0-rc15` (or `v1.0.0-rc15.N` for the highest N in the
  lineage, per FW-ADR-0018 § 8 escape-hatch clause) tag is cut with
  the FW-ADR-0018 § 7 dogfood harness PASS for the rc15.N tag (count
  authoritative in § 7, not pinned here) AND AI-TUI PASS per the
  `feedback_dogfood_needs_tui_check` memory.
- (b) **At least one downstream project** has run the rc15.N
  bridging migration successfully and is now on the FW-ADR-0015
  stub model. Per the customer's 2026-05-15 ruling 3 (customer
  is the only known operator), the customer's own project is
  the operative downstream; this signal fires when the customer
  confirms their downstream bridged cleanly.
- (c) **No soak period requirement.** "Any time after (a) and (b)
  hold" is the gate; no calendar-based wait. Rationale: customer
  is the only known operator (2026-05-15 ruling 3); a 30-day
  soak adds no information that the customer's single bridged
  downstream does not already provide. If the operator population
  grows during the proposed-window of this ADR, that change
  re-opens the soak question (see Failure signal in § Verification).

When all three conditions hold, `tech-lead` dispatches the
follow-up PR per § 7 cleanup ordering; the PR's LAST commit
flips the status field on this ADR from `proposed` to
`accepted` with the acceptance date.

### 2. Inert migration-file removal timing

Once rc15 lineage lands clean, downstreams that complete the
bridge are at `v1.0.0-rc15` (or `v1.0.0-rc15.N`) and no longer
discover the rc13.sh / rc14.sh files (per FW-ADR-0017 § 6
source-bound resolution: migrations whose semver is `<=`
project's stamped version are skipped). Pre-bridge downstreams
on v1.0.0-rc2..rc12 still need them: rc13.sh closes the rc-to-rc
in-place-cp cliff per FW-ADR-0013; rc14.sh runs the FW-ADR-0014
preservation-prune migration whose write-target file
(`.template-customizations`) still exists on a pre-bridge tree.

**Removal-safe condition:** ALL operator downstreams have
completed the bridge. Given the customer is the only known
operator (2026-05-15 ruling 3), this condition reduces to
"after the customer confirms all of their downstreams bridged."
The customer's confirmation is recorded in `CUSTOMER_NOTES.md`
by `researcher` per Hard Rule #5 and routed to `tech-lead`;
`tech-lead` dispatches the removal PR after the confirmation
lands.

**Sunset:** if 12 months pass after the rc15 lineage tag with no
operator-bridge confirmation, the architect re-opens FW-ADR-0019
to re-examine the removal-safe condition.

**File-system effect:** `git rm migrations/v1.0.0-rc13.sh` and
`git rm migrations/v1.0.0-rc14.sh`. Git history preserves them
as historical record. Future readers `git log -- migrations/`
to see the retired files.

**No removal of `migrations/v0.14.0.sh`.** That migration carries
the v0.x → v0.14.0 cross-MAJOR upgrade body that the rc15 bridging
migration inherits its pre-bootstrap pattern from (per FW-ADR-0018
§ 3 implementation notes). It also remains the prior-art reference
for the pre-bootstrap pattern's verbatim inheritance; removing it
would break that cross-reference. v0.14.0.sh stays in the tree.

### 3. FW-ADR-0010 + FW-ADR-0013 status transitions

Both ADRs stay on disk as historical record. Their status fields
update:

- **FW-ADR-0010**: front-matter `status: accepted` →
  `status: superseded by FW-ADR-0015 / FW-ADR-0019`. The
  in-document Status section updates with a one-line note:
  "Superseded 2026-MM-DD by FW-ADR-0015 (stub model dissolves
  the pre-bootstrap class structurally) and FW-ADR-0019 (formal
  retirement of the env var, artefact, and audit-log column
  value). FW-ADR-0010 stays on disk as historical record." The
  date is pinned when FW-ADR-0019 flips to accepted.
- **FW-ADR-0013**: same shape. The supersession note also names
  the file-keyed discovery (FW-ADR-0017) that made
  `migrations/v1.0.0-rc13.sh` inert by construction.

**No body edits to either ADR.** Status-line update and a single
note paragraph in the Status section; the rest of each ADR stays
as the historical record of the decision shape.

### 4. `SWDT_PREBOOTSTRAP_FORCE` env var deprecation curve

Two-stage deprecation:

- **Stage 1 (post-FW-ADR-0019-acceptance through v1.x):** the
  post-bridge runner inspects the environment on entry. If
  `SWDT_PREBOOTSTRAP_FORCE` is set (to any value other than
  empty / unset), the runner emits a one-time stderr WARN line
  per session naming the deprecation, citing FW-ADR-0019,
  embedding the running framework version (e.g., `v1.x.y`) so
  operator bug reports cite the exact runner version that
  emitted the WARN, and noting that the variable is ignored.
  The runner proceeds normally. The WARN is rate-limited to
  once per session to avoid flooding output.
- **Stage 2 (v2.0.0 final and later):** the WARN-emit logic is
  removed. The variable is fully retired; setting it has no
  effect and produces no output.

**No reverse-compat support for `SWDT_PREBOOTSTRAP_FORCE=0`** or
other "explicit disable" semantics. The variable's original
contract (per FW-ADR-0010 § "Override mechanism") was binary:
set-to-1 means force; unset / 0 / other means refuse. Under
FW-ADR-0019, ALL values become a documented no-op with the
Stage 1 WARN.

**Runner-side wiring location:** the WARN-emit logic lives in
the post-bridge runner (`scripts/upgrade-runner.sh` upstream),
not in the stub. The stub passes the environment through
unmodified per FW-ADR-0015 § "Backward-compat shim contract";
the runner consumes the env var on the way in.

### 5. `.template-prebootstrap-blocked.json` artefact deprecation curve

Same shape as § 4:

- **Stage 1 (post-FW-ADR-0019-acceptance through v1.x):** if
  the post-bridge runner encounters
  `.template-prebootstrap-blocked.json` at project root on
  entry, it emits a one-time stderr WARN per session noting
  that the artefact is a deprecated FW-ADR-0010 surface, citing
  FW-ADR-0019, and noting that the runner does not read or
  write it. The runner proceeds normally; the file is NOT
  auto-removed (operator's choice to clean up).
- **Stage 2 (v2.0.0 final and later):** the WARN-emit logic is
  removed. The artefact is fully retired; if it exists on disk
  it is silently ignored by the runner.

**No auto-removal.** The runner does not delete
`.template-prebootstrap-blocked.json`. Rationale: under
FW-ADR-0010 the file was written by a refused pre-bootstrap run;
deleting it without operator consent erases evidence of a past
refusal. Operators remove the file by hand or via their own
cleanup tooling. Auto-remove would self-terminate the deprecation
cleanly; we accept the operator-action cost in exchange for
evidence preservation.

### 6. `Gate=pre-bootstrap` audit-log column value

The `Gate` column on `docs/pm/pre-release-gate-overrides.md`
(added in FW-ADR-0010 § "Override mechanism") stays. Two event
types lived in that column: `pre-release` (still active via
`.git-hooks/pre-push`'s `SKIP_PRE_RELEASE_GATE=1` flow) and
`pre-bootstrap` (retired by this ADR).

**Post-FW-ADR-0019-acceptance:**

- The `pre-bootstrap` value is retired for new rows. No
  framework code emits it after the cleanup PR lands (the
  emitters — `migrations/v0.14.0.sh`, `migrations/v1.0.0-rc13.sh`,
  the in-tree `scripts/upgrade.sh` pre-bootstrap block — are
  either removed by § 2 or retired by the stub model).
- The `pre-release` value continues unchanged. The column
  stays.
- **Existing `pre-bootstrap` rows are preserved.** Append-only
  is the tamper-evidence mechanism per FW-ADR-0010 §
  "Override mechanism"; retroactive editing is detectable via
  `git log -p`. Existing rows stay on disk as the historical
  record of every force-override the framework ever audited.
- The file's header block (the prose at top of
  `docs/pm/pre-release-gate-overrides.md`) updates to note
  that the `pre-bootstrap` value is retired for new rows per
  FW-ADR-0019; the `pre-release` value continues. The header
  update explicitly preserves FW-ADR-0010's "empty `Gate` cell →
  `pre-release`" back-compat rule (per FW-ADR-0010 § "Audit-log
  surface", rows with empty Gate cell predate the 2026-05-14
  column-introduction and MUST be parsed as `pre-release`).
  Historical `pre-bootstrap` rows are valid and read-only; new
  rows MUST be `pre-release`.

FW-ADR-0010's column-design ADR continues to apply to the
`pre-release` value. The column itself is not removed.

### 7. Cleanup ordering (binding sequence)

The follow-up cleanup PR's commits MUST land in this order:

1. **Inert migration-file removal.** `git rm
   migrations/v1.0.0-rc13.sh`; `git rm migrations/v1.0.0-rc14.sh`.
2. **FW-ADR-0010 + FW-ADR-0013 status-line updates.** Per § 3.
3. **Deprecation WARN wiring.** Add Stage-1 WARN-emit logic for
   `SWDT_PREBOOTSTRAP_FORCE` and `.template-prebootstrap-blocked.json`
   to the post-bridge runner per §§ 4–5.
4. **Audit-log header update.** Update
   `docs/pm/pre-release-gate-overrides.md` header per § 6.
5. **Doc cleanup.** Mentions of "pre-bootstrap" in framework docs
   (`docs/TEMPLATE_UPGRADE.md` if any, runner doc, etc.) become
   historical references with `(retired per FW-ADR-0019)`
   parenthetical.
6. **Status flip on FW-ADR-0019.** Front-matter `status: proposed`
   → `status: accepted`; pin acceptance date. This is the LAST
   commit in the PR.

Each step is reversible until the next step is verified.
`code-reviewer` reviews the full PR; `qa-engineer` confirms post-PR
that no caller of the deprecated env var / artefact remains and
that the post-bridge runner emits the WARN correctly when the
variable is set.

**Sequencing rationale:** the binding signal that FW-ADR-0019 has
landed is the merged PR, not the commit ordering within it. Within
the PR, the status flip lands LAST so that any partial-merge or
mid-PR revert scenario leaves an internally consistent tree: if
steps 1–5 are reverted, the ADR is still `proposed` and the
recovery procedure in § Verification (Failure-signal) applies
cleanly. Reversing the order (e.g., flipping status before the
cleanup edits) would leave a window where the ADR claims
acceptance while the tree has not yet been cleaned, and a
mid-PR failure could leave that inconsistency persisted.

## Consequences

### Positive

- **Architecture pivot completes.** FW-ADR-0015..0019 form a
  five-ADR sequence; FW-ADR-0019 is the closer. After it ships,
  the framework's upgrade-flow contract is fully described by
  FW-ADR-0015 + FW-ADR-0016 + FW-ADR-0017 + FW-ADR-0018 (the
  bridging rc itself) plus the surviving pre-rearchitecture ADRs
  (FW-ADR-0002 verification, FW-ADR-0014 Q2 two-phase exit). No
  pre-bootstrap concept survives.
- **No dead code in the migration tree.** rc13.sh and rc14.sh are
  removed once their last callers (pre-bridge downstreams) have
  bridged. Future readers of `migrations/` see only callable
  files.
- **No zombie env-var contract.** Operators who set
  `SWDT_PREBOOTSTRAP_FORCE` get an explicit WARN that the variable
  is deprecated, not silent acceptance. The deprecation tail
  (through v1.x; removed at v2.0.0) is bounded and conventional.
- **Clean audit trail.** Existing audit-log rows stay; new rows
  carry only the active `pre-release` value; the column itself
  continues for that value. Tamper-evidence is preserved.
- **FW-ADR-0010 + FW-ADR-0013 stay on disk.** Future auditors
  reading either ADR see the supersession note and follow the
  chain forward to FW-ADR-0015 / FW-ADR-0019. The "decisions
  are durable; status reflects current state" discipline holds.

### Negative / trade-offs accepted

- **One more cleanup PR after rc15 lineage lands.** Bounded cost
  (file moves + status-line edits + ~20 lines of WARN-emit
  logic in the runner). Sequenced per § 7 to be straightforward
  to review.
- **FW-ADR-0019 has a long `proposed`-window** while it waits
  for rc15 lineage to clear. Risk: the ADR drifts out of sync
  with the rc15 implementation as it evolves through rc15.x
  escape-hatch iterations. Mitigation: this ADR is forward-
  looking and describes the cleanup in terms of named files /
  contracts / status fields, not in terms of rc15 implementation
  specifics; if rc15.x changes the pre-bootstrap pattern in the
  bridging migration, this ADR's cleanup items do not change.
- **Two-stage deprecation tail.** Operators reading the runner
  source through v1.x see WARN-emit logic for `SWDT_PREBOOTSTRAP_FORCE`
  and `.template-prebootstrap-blocked.json`; the logic adds ~20
  lines of bounded technical debt that retires at v2.0.0. The
  alternative (immediate removal) would leave operators with
  silent no-op semantics that are harder to diagnose.
- **No auto-removal of `.template-prebootstrap-blocked.json`** on
  post-bridge runs. Operators clean up the file by hand. The
  cost (one `rm` per affected downstream) is small; the
  alternative (auto-remove) would erase historical evidence of
  pre-bootstrap refusals operators may want to audit.
- **`migrations/v0.14.0.sh` stays.** Future readers `grep`-ing
  for pre-bootstrap pattern code find it in v0.14.0.sh; the
  comment block + cross-references make clear it is historical.
  Removing it would break FW-ADR-0018 § 3's inheritance
  cross-reference.

## Verification

How we know FW-ADR-0019 is correctly landed (after the trigger
condition § 1 fires and the cleanup PR lands):

- **Success signal A — file-system state.** Post-PR,
  `migrations/v1.0.0-rc13.sh` and `migrations/v1.0.0-rc14.sh` do
  not exist; `git log --diff-filter=D -- migrations/` shows the
  deletions; `git log -- migrations/v0.14.0.sh` shows no
  deletion (v0.14.0.sh stays).
- **Success signal B — ADR status fields.**
  `docs/adr/fw-adr-0010-pre-bootstrap-local-edit-safety.md` and
  `docs/adr/fw-adr-0013-rc-to-rc-pre-bootstrap.md` carry
  `status: superseded by FW-ADR-0015 / FW-ADR-0019` in their
  front matter and a matching supersession-date note in their
  Status sections. `docs/adr/fw-adr-0019-pre-bootstrap-retirement.md`
  carries `status: accepted` with the acceptance date pinned.
- **Success signal C — no callers of deprecated contracts.**
  Exact invocation: `grep -rIn 'SWDT_PREBOOTSTRAP_FORCE'
  --exclude-dir=.git` from the repo root. Expected file-list
  output (deterministic; any other path on a live code path is a
  defect):
  - (a) the deprecation WARN-emit logic in
    `scripts/upgrade-runner.sh` (the only live-code-path emitter),
  - (b) historical ADRs:
    `docs/adr/fw-adr-0010-pre-bootstrap-local-edit-safety.md`,
    `docs/adr/fw-adr-0013-rc-to-rc-pre-bootstrap.md`,
    `docs/adr/fw-adr-0015-upgrade-orchestrator-stub-model.md`,
    `docs/adr/fw-adr-0018-transitional-rc-bridging.md`,
    `docs/adr/fw-adr-0019-pre-bootstrap-retirement.md`,
  - (c) `CUSTOMER_NOTES.md` if any historical entry cites it,
  - (d) `migrations/v0.14.0.sh` as historical record.

  Same shape for `.template-prebootstrap-blocked.json`. Exact
  invocation: `grep -rIn '.template-prebootstrap-blocked.json'
  --exclude-dir=.git`. Expected file-list output: deprecation
  WARN-emit logic in the runner; historical ADRs (same set as
  above); `CUSTOMER_NOTES.md` historical entries if any;
  `migrations/v0.14.0.sh`. No live code-path writer or reader.
- **Success signal D — deprecation WARN fires correctly.**
  `qa-engineer` runs the post-bridge runner with
  `SWDT_PREBOOTSTRAP_FORCE=1` in env; observes the one-time
  stderr WARN line citing FW-ADR-0019; observes the runner
  proceeds normally with no other behaviour change. Same shape
  for the artefact-present case.
- **Success signal E — audit-log header update.** The header
  block of `docs/pm/pre-release-gate-overrides.md` names
  FW-ADR-0019 and notes the `pre-bootstrap` value is retired
  for new rows. Existing `pre-bootstrap` rows are byte-identical
  to their pre-PR content.
- **Failure signal — operator filing reports broken bridge
  caused by missing rc13.sh or rc14.sh.** If a pre-bridge
  downstream surfaces post-cleanup-PR and cannot bridge because
  the inert migration files were removed too early, the trigger
  condition § 1(b) was mis-evaluated. Routes to `tech-lead` for
  re-evaluation; recovery is to restore the files via
  `git revert` of the removal commit, keep the ADR status field
  as-is (the cleanup PR stays merged for the items that don't
  depend on the rc15.x ship state).
- **Failure signal — operator population grew during the
  proposed-window and a new operator's downstream cannot
  bridge.** Per § 1(c), the no-soak gate assumed customer-only
  operator population. If that assumption changes during the
  proposed-window, re-open the soak question before flipping
  to accepted; route to `tech-lead`.
- **Failure signal — post-bridge stub-fetch flow instability
  surfaces after the one bridged downstream confirmation.** A
  single bridged downstream confirms the bridge RAN; it does
  not confirm post-bridge stability of the stub-fetch flow
  across subsequent invocations. If the bridged downstream
  surfaces stub-fetch failures, transient runner errors, or
  any regression attributable to the FW-ADR-0015 stub model
  during the proposed-window, treat trigger condition § 1(b)
  as not yet satisfied: the bridge ran once but post-bridge
  steady-state is not yet demonstrated. Route to `tech-lead`;
  the soak question (Open questions § "Trigger-condition § 1(c)
  no-soak") becomes binding to resolve before flipping the
  status. The soak question remains queued in § Open questions
  for customer review.
- **Failure signal — pre-bootstrap pattern resurfaces in a
  future structural rewrite.** If a post-FW-ADR-0019 ADR
  proposes reintroducing the FW-ADR-0010 pattern (3-SHA matrix,
  block artefact, force env var), this ADR's "pre-bootstrap
  class retires" claim is false. Treat the proposal as a
  superseding ADR for FW-ADR-0015 AND FW-ADR-0019 and
  re-examine.
- **Review cadence:** at v2.0.0 final, when the Stage-2
  deprecation removes the WARN-emit logic. Re-examine if any
  failure signal fires in the interim. Earlier if rc15 lineage
  itself needs more iterations than the escape-hatch clause
  in FW-ADR-0018 § 8 anticipates.

## Implementation notes for software-engineer

Scope for FW-ADR-0019-impl. Architect describes; SE implements.
This is **bounded cleanup work** — most of the substance lives
in FW-ADR-0015..0018; FW-ADR-0019 is mostly file moves + status-
line edits + one small runner-side WARN-emit block.

**Piece 1: File removals.**

- `git rm migrations/v1.0.0-rc13.sh`. Per § 2 removal-safe
  condition.
- `git rm migrations/v1.0.0-rc14.sh`. Same.
- Do NOT remove `migrations/v0.14.0.sh`. Per § 2.

**Piece 2: ADR status-line edits.**

Edits land in this order to match § 7's revised ordering (FW-ADR-0010
and FW-ADR-0013 status edits land BEFORE the FW-ADR-0019 status flip):

- First, edit `docs/adr/fw-adr-0010-pre-bootstrap-local-edit-safety.md`
  front-matter status field from `status: accepted` to
  `status: superseded by FW-ADR-0015 / FW-ADR-0019`. Add the
  one-line supersession note in the Status section per § 3.
- Next, edit `docs/adr/fw-adr-0013-rc-to-rc-pre-bootstrap.md` same
  shape.
- LAST (per § 7 step 6), edit `docs/adr/fw-adr-0019-pre-bootstrap-retirement.md`
  front-matter status field from `status: proposed` to
  `status: accepted`; pin the acceptance date in the front
  matter `date:` field and in the Status section.

**Piece 3: Runner-side WARN-emit logic.**

- Location: `scripts/upgrade-runner.sh` upstream (the
  FW-ADR-0015 post-bridge runner). The WARN-emit logic does
  not ship in the stub.
- Shape: on runner entry, check `${SWDT_PREBOOTSTRAP_FORCE:-}`;
  if non-empty, emit `WARN: SWDT_PREBOOTSTRAP_FORCE is
  deprecated per FW-ADR-0019; the pre-bootstrap class retired
  with v1.0.0-rc15. This variable is ignored.` Rate-limit:
  one WARN per session (set a flag after the first emit).
- Shape: on runner entry, check for
  `${PROJECT_ROOT}/.template-prebootstrap-blocked.json`; if
  present, emit `WARN: .template-prebootstrap-blocked.json is
  a deprecated FW-ADR-0010 artefact per FW-ADR-0019; the
  runner does not read or write it. Remove the file at your
  convenience.` Same rate-limit.
- The WARN-emit logic itself becomes a candidate for removal
  at v2.0.0; mark with a `# FW-ADR-0019 Stage-1 deprecation:
  remove at v2.0.0` comment so future maintainers find it.

**Piece 4: Audit-log header update.**

- Edit `docs/pm/pre-release-gate-overrides.md` header block
  (lines ~1–30 in the current file) per § 6: add a sentence
  noting FW-ADR-0019 retires the `pre-bootstrap` value for
  new rows; the `pre-release` value continues.

**Piece 5: Doc cleanup.**

- `grep -rn 'pre-bootstrap' docs/ scripts/ migrations/` ;
  classify each hit. Hits in historical ADRs (FW-ADR-0010,
  0013, 0015, 0018, 0019) stay verbatim. Hits in
  `migrations/v0.14.0.sh` stay (historical record). Hits in
  forward-looking docs (`docs/TEMPLATE_UPGRADE.md`, runner
  doc, etc.) get an `(retired per FW-ADR-0019)` parenthetical
  or are reworded as "historically, the framework used a
  pre-bootstrap pattern …" prose.
- At the time of this ADR draft, `grep -rn pre-bootstrap
  docs/TEMPLATE_UPGRADE.md` returns no matches; doc cleanup
  scope is correspondingly small. SE re-runs the grep at
  PR time in case the TEMPLATE_UPGRADE.md content has grown
  between draft and acceptance.

**Unit tests (`qa-engineer` scope):**

- (a) Post-PR `grep` for `SWDT_PREBOOTSTRAP_FORCE` callers
  per § Verification Success signal C — no live emitters
  remain.
- (b) Post-PR runner-invocation with
  `SWDT_PREBOOTSTRAP_FORCE=1` in env — observe the one-time
  WARN; observe runner proceeds normally.
- (c) Post-PR runner-invocation with
  `.template-prebootstrap-blocked.json` present at project
  root — observe the one-time WARN; observe runner proceeds
  normally; observe file is NOT auto-removed.
- (d) Pre-bridge fixture refuses to upgrade gracefully after
  rc13.sh / rc14.sh removal — expected behaviour is the
  bridging migration not being reachable for a pre-bridge
  downstream that has skipped rc15.N; document that operators
  who skipped the bridge land at this refusal and recover by
  running rc15.N from a clean checkout. (This is the structural
  cost of the cleanup and matches FW-ADR-0015 § "Downstreams
  that skip the bridging rc are unreachable.")
- (e) Audit-log post-PR: existing `pre-bootstrap` rows
  byte-identical to pre-PR.

`code-reviewer` reviews the cleanup PR; `security-engineer`
does NOT need to re-review (no new security surface; the
deprecation makes the existing security posture more
conservative by removing an operator-facing override).

## Open questions

**Customer-facing trigger-condition confirmation (queued; routed
through `tech-lead` per Hard Rule #1).** Some of the items below
are decision axes the customer may want to weigh in on; this ADR
proposes a default for each and notes the assumption. Per CLAUDE.md
Hard Rule #11 (atomic questions), `tech-lead` asks one decision
axis per turn from the queue; this ADR does not bundle.

- **Trigger-condition § 1(c) no-soak.** This ADR proposes
  "any time after (a) and (b) hold" with no calendar-based wait,
  on the assumption that the customer is the only known operator.
  Customer may want to require a soak period (e.g., 7 days, 30
  days) even at single-operator scale. Queued for later customer
  confirmation if the no-soak default needs to be re-examined.
- **Stage-2 WARN-emit removal timing § 4.** This ADR proposes
  "at v2.0.0 final" for removing the Stage-1 WARN. Customer may
  prefer "at v1.1.0" or "at v2.0.0-rc1" or "never" depending on
  preferred deprecation-tail aggressiveness. Queued.
- **`.template-prebootstrap-blocked.json` auto-removal § 5.**
  This ADR proposes "no auto-removal; operator cleans up." Customer
  may prefer the runner auto-remove on the first post-bridge run
  to fully retire the artefact. Queued.

None of the queued items block FW-ADR-0019 from being drafted in
`proposed` status; defaults stand until customer overrides.

**Items deferred to FW-ADR-0019-impl (software-engineer scope,
not customer-facing):**

- Exact rate-limit mechanism for the one-time WARN
  (env-var flag, pid-file, in-process boolean — SE picks).
- Exact text of the WARN message (`tech-writer` may polish; SE
  proposes; FW-ADR-0019 sketches it in § 4–5 for shape, not
  for final wording).

## Links

- Foundation ADRs (the chain this ADR closes):
  - `docs/adr/fw-adr-0015-upgrade-orchestrator-stub-model.md`
    (structural fix; supersedes FW-ADR-0010 and FW-ADR-0013
    architecturally; this ADR formalises the supersession).
  - `docs/adr/fw-adr-0016-template-state-json-schema.md`
    (state consolidation; absorbs the legacy trio that
    pre-bootstrap protected).
  - `docs/adr/fw-adr-0017-file-keyed-migration-discovery.md`
    (file-keyed discovery; makes `migrations/v1.0.0-rc13.sh`
    inert by construction under the stub model).
  - `docs/adr/fw-adr-0018-transitional-rc-bridging.md`
    (transitional rc15 lineage; this ADR's acceptance is
    gated on its § 8 trigger).
- ADRs being retired:
  - `docs/adr/fw-adr-0010-pre-bootstrap-local-edit-safety.md`
    (status field flips to superseded per § 3).
  - `docs/adr/fw-adr-0013-rc-to-rc-pre-bootstrap.md` (same).
- Inert migration files:
  - `migrations/v1.0.0-rc13.sh` (removed per § 2).
  - `migrations/v1.0.0-rc14.sh` (removed per § 2).
- Surviving historical reference:
  - `migrations/v0.14.0.sh` (stays; pre-bootstrap pattern
    inheritance source for FW-ADR-0018 § 3; historical record).
- Audit-log surface:
  - `docs/pm/pre-release-gate-overrides.md` (header update
    per § 6; existing `pre-bootstrap` rows preserved
    append-only).
- Customer rulings (CUSTOMER_NOTES.md, 2026-05-15):
  - Ruling 3 (customer is the only known operator;
    informs § 1(c) no-soak default and § 2 removal-safe
    condition).
- External references:
  - MADR 3.0 (`https://adr.github.io/madr/`).
