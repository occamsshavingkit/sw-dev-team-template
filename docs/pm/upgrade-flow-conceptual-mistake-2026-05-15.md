# Upgrade flow — conceptual mistake (2026-05-15)

Author: `architect` (dispatched 2026-05-15 by tech-lead after customer
ruling: "there is a conceptual mistake here that is causing these
failures").
Scope: re-examination of the upgrade flow's foundations, not a route
between options A/B. Pair-think dispatch: `process-auditor` (parallel).

## The pattern

Every "fix" landed for an upgrade-class regression in 2026-05 has
patched the layer one step deeper than the framework's structure
naturally supports. Q-0017 fixed self-overwrite in
`migrations/v0.14.0.sh`; the failure recurred on rc2 → rc12. FW-ADR-0013
added `migrations/v1.0.0-rc13.sh` with the same body; the migration is
**unreachable** because discovery walks `git tag -l 'v*'` and no rc13
tag exists. FW-ADR-0014 patched the runtime preservation classifier,
but the failing manifest was synthesised earlier by v0.14.0 and never
re-baked. PR #186 taught the new upgrade.sh about untagged `--target`,
but the upgrade.sh on disk in the field is still the rc3..rc11 version
that does not know the new flag. Four merged blockers, zero PASSes on
re-dogfood, and the new failure modes are not the same as the old ones.
This is the signature of a category error, not a list of bugs.

## The conceptual mistake

**The framework treats `scripts/upgrade.sh` as a *file* that the
template ships, when structurally it is a *runtime* that the project
hosts.** Every other shipped file (agent contracts, ADRs, templates,
docs, hooks) can be upgraded by the running upgrade.sh because the
running upgrade.sh is not the one being upgraded. `scripts/upgrade.sh`
is the one file whose old version on disk is doing the work of
replacing itself with the new version on disk — and that work is being
driven by exactly the version we are trying to retire. The pre-bootstrap
migration concept is a workaround for this: we ship the new driver
*via the old driver's migration runner*, on the theory that the old
driver will reach the migration runner before its sync loop touches
upgrade.sh. But the migration runner itself lives in the old driver,
uses the old driver's enumeration logic (`git tag -l 'v*'` bounded by
the upstream `VERSION` file), the old driver's target-resolution flag
set (no untagged `--target`), and the old driver's structural
assumptions about the file format. We do not control any of those at
the moment the upgrade starts. We only control them after the upgrade
has finished — and the upgrade cannot finish until they cooperate.

The second-order mistake is that the framework keeps trying to make
the *new* release responsible for the *old* driver's correctness.
FW-ADR-0013 was an architect-side commitment that every future
structural cliff in upgrade.sh would spawn a new pre-bootstrap
migration. That promise is unkeepable: the new migration is added to
the *new* tree, but the rc2 driver's enumeration only sees tags that
exist at run time. We cannot retroactively make rc2's enumerator know
about rc13.sh by writing rc13.sh into main; rc2 will not see it unless
a v1.0.0-rc13 *tag* is published. The customer's "no tag before
PASS" rule (binding) makes the tag pre-condition impossible to satisfy
inside the dogfood loop. The frame "ship the fix as a migration" is
in direct tension with "do not publish a tag until dogfood passes" —
they cannot both hold while migration discovery is tag-keyed.

The third-order mistake — and the one that explains why each new patch
makes the next regression worse — is that `.template-customizations`,
`TEMPLATE_MANIFEST.lock`, and the migration queue have grown into
**three independent sources of truth about which files the framework
manages**, and the framework keeps adding gates that ask one of them
to defer to another. The v0.14.0 migration bakes a manifest. The
v0.14.4 / v0.15.0 migrations move paths into the preserve-list. The
rc14 prune migration tries to drop inert preserve-list entries. The
new preservation gate in upgrade.sh asks at sync time whether the
manifest contradicts the preserve-list. Each of these reasoned about
a snapshot of the other two that no longer holds by the time the next
component reads it. The system is not "wrong"; it is *racy across
versions*, and no patch to any one component closes the race.

## Proposed structurally-simpler form

Separate the **upgrade driver** from the **project-state contract**.
Treat upgrade.sh as a host-supplied runtime (like git, or python) that
the template can *recommend* a version of but cannot ship as
project-owned content. Concretely, the project hosts a *stable stub*
(a thin shim, sub-100 lines, that has not structurally changed in the
v1.x line and will not) whose only job is to fetch and exec the
current upstream's `scripts/upgrade-runner.sh` from the requested ref.
The runner itself is a fresh-each-run download that the project does
not own and does not store on disk between invocations. The
self-overwrite problem dissolves: nothing is overwriting itself,
because the running runner came from the network for this invocation
only. The migration-discovery problem dissolves: the runner that
discovered the migrations is the same runner that knows the full
target's migration set, by file presence, not by tag enumeration. The
untagged-target problem dissolves: the runner's CLI surface is the
new surface, because the runner is current by construction.

The project-state contract becomes a single artefact:
**`TEMPLATE_STATE.json`** at project root, owned by the project,
schema-versioned, carrying (a) the upstream ref the project is
synced against, (b) per-path declarations of `{managed, customised,
project-owned}`, and (c) the per-managed-path content hash at the
last sync. `TEMPLATE_MANIFEST.lock` and `.template-customizations`
fold into this one file. The runner reads it at sync entry, writes it
at sync exit; downstream `--verify` is "does this project's tree
match its own TEMPLATE_STATE?" — a question the project owns
unambiguously. There is no synthesised manifest because there is no
moment at which the runner has to predict the result of another
runner. There is no preservation-vs-manifest gate because preservation
*is* a per-path declaration in the same artefact the manifest lives
in; contradictions are syntactically impossible. The "customisation
wins" rule becomes a property of the declaration class, not an
emergent consequence of three subsystems agreeing.

## Outline of follow-up architecture work

Order matters. Each ADR must close before the next opens. ADR titles
are working titles for the architect's drafting; tech-lead routes
implementation after each is accepted.

- **FW-ADR-0015 — Upgrade driver / project-state boundary** (architect
  owner; this is the foundational ADR; must precede any code).
  Establishes that `scripts/upgrade.sh` on the project is a stub, not
  a runtime; the runtime is fetched fresh per invocation; the
  project-owned state is a single file. Three-Path: M = stable stub +
  network runner (the proposed form), S = current model with content-
  addressed migration discovery and a separate downloaded runner per
  cliff, C = no driver shipped at all (project invokes upstream's
  runner directly via curl|bash with a pinned-checksum gate).
- **FW-ADR-0016 — TEMPLATE_STATE.json schema** (architect drafts; QA
  consulted; tech-writer for prose). Defines the single project-owned
  state artefact, the migration shape from
  `(TEMPLATE_VERSION, TEMPLATE_MANIFEST.lock, .template-customizations)`
  into it, schema-version field, forward-compat rules.
- **FW-ADR-0017 — Migration discovery is file-keyed, not tag-keyed**
  (architect owner; depends on FW-ADR-0015 because the runner is the
  enumerator). Migrations live in the fetched runner's
  `migrations/v*.sh`; discovery is by file presence and semver
  ordering against the project's stamped state, never against
  `git tag -l`. Customer's "no tag before PASS" rule is honoured by
  construction.
- **FW-ADR-0018 — Migration path for currently-deployed downstreams**
  (architect + release-engineer; depends on FW-ADR-0015 and 0016).
  Three-Path: M = one-time hand retrofit documented in the playbook
  (any v1.0.0-rc* project runs a one-liner curl that installs the new
  stub, atomically, exactly once); S = transitional runner that
  detects the old layout and writes the new state file from it; C =
  cut a vNext MAJOR that explicitly drops upgrade-from-rc and ships
  only scaffold-fresh.
- **FW-ADR-0019 — Deprecation and removal of the pre-bootstrap
  migration class** (architect owner; depends on FW-ADR-0015). Once
  the driver is not project-shipped, the entire pre-bootstrap concept
  retires. FW-ADR-0010 and FW-ADR-0013 supersede; their interface
  surfaces (`SWDT_PREBOOTSTRAP_FORCE`, `.template-prebootstrap-blocked.json`,
  pre-release-gate-overrides `Gate=pre-bootstrap`) become no-ops with
  back-compat shims that log a one-time deprecation note.

Open questions for the customer below; do not draft any of these
ADRs until the foundation question is answered.

## Open questions for customer

(One per turn, via tech-lead; queued atomically in
`docs/OPEN_QUESTIONS.md`. The first question is the foundation question
— FW-ADR-0015 cannot be drafted without it.)

- Q-0019 (foundation, blocks all follow-up ADRs): Is the framework
  willing to commit that `scripts/upgrade.sh` on a downstream project
  becomes a stable stub that fetches a fresh runner per invocation,
  rather than being a project-shipped file that can structurally
  rewrite itself? This is the one decision that determines whether
  the proposed structurally-simpler form is reachable. If no, the
  follow-up question is whether the customer wants the architect to
  propose a less-deep alternative (e.g., keep upgrade.sh project-
  shipped, but make migration discovery content-addressed and freeze
  the structural shape of upgrade.sh for the v1.x line — strictly
  weaker, with caveats).

(Queue-only, do not ask yet: Q-0020 — disposition of currently-
deployed rc2..rc12 downstreams; Q-0021 — whether TEMPLATE_STATE.json
ships as a single file or remains split for back-compat.)

## Disagreement surface with parallel `process-auditor` dispatch

`process-auditor` is running concurrently on the same evidence. If
their conclusion is "the mistake is process / decision-rhythm, not
structure" (e.g., we keep landing fixes without dogfooding the fix
itself, or we keep accepting ADRs against fixtures we have not
actually validated), that is **compatible** with this report — they
diagnose the upstream cause of the symptoms this report addresses
structurally. If their conclusion is "the structural model is fine
and the fixes were merely insufficiently tested", that is
**incompatible**: this report holds that the structural model is the
problem and more testing of the same model will not converge.
Tech-lead routes the customer to arbitrate if incompatibility surfaces.
