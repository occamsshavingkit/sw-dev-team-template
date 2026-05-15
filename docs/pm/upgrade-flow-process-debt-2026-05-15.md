# Process audit — upgrade flow conceptual debt (2026-05-15)

**Auditor:** process-auditor (one-shot, cultural-disruptor frame)
**Scope:** the upgrade flow as a whole — `scripts/upgrade.sh`, the
migration runner, the migration files, the manifest, the
`.template-customizations` list, the rc-cliff pattern, and the
operating ritual around them.
**Trigger:** customer 2026-05-15 — "there is a conceptual mistake
here that is causing these failures" — paired-dispatch with
`architect-conceptual`.
**Framing:** findings below are INVITATIONS TO JUSTIFY. They do
not propose unilateral changes; they route to `tech-lead` for
customer ruling per `CLAUDE.md` Hard Rule #4 (irreversible /
critical paths).

## The unspoken assumptions

A list of conventionalities visible in the upgrade flow that
look like inherited habit rather than current design. Each
deserves a justification or a revision.

1. **The script that performs the upgrade is itself part of the
   thing being upgraded.** Why is `scripts/upgrade.sh` shipped
   inside the downstream project tree at all? Every other
   self-update system the industry has shipped (rustup, asdf,
   nvm, brew, apt, package managers in general) treats the
   updater as out-of-band from the artefacts it manages.

2. **Migration discovery is bounded by git tag enumeration.**
   `git tag -l 'v*'` in the migration runner means a migration
   file's existence in `migrations/` is not enough to make it
   reachable — it needs a corresponding upstream tag. This is
   the proximate cause of the rc13 catch-22. Why is "tag exists
   on upstream" a precondition for "migration runs"?

3. **Pre-bootstrap is a special-case migration class.** The
   framework has invented a category of migration that runs
   BEFORE the migration runner so the migration runner doesn't
   crash. The fact that this category exists is a tell —
   normally you would not need it because the runner itself
   would be evergreen.

4. **`upgrade.sh` is expected to understand its own future
   versions' command-line surface.** rc8's `upgrade.sh` is
   asked to parse `--target main` even though branch-or-SHA
   targets were a feature added later. The rc8 script then
   gates on the new flag, refuses, and never reaches the code
   that would have replaced itself. This is the "old code
   forecasts future code" trap.

5. **One rc tag → one migration file → maybe a cliff.** Cliffs
   accumulate because the granularity of upgrades is the
   release-candidate, not the structural-change. Most rcs do
   not introduce a structural change; some do. The framework
   treats every rc as a potential migration site uniformly,
   which is why we now have rc9, rc13, and (queued) rc14
   migrations and counting.

6. **`.template-customizations` and `TEMPLATE_MANIFEST.lock`
   are co-equal and independently mutable.** Two artefacts,
   two migration paths that touch each, and the contract
   between them is implicit: "preserved paths shall be absent
   from the manifest." Nothing enforces this invariant at
   write time; it is enforced after the fact by `--verify`,
   which is the wrong end of the pipe. Blocker #4 is exactly
   this: v0.14.0 bakes a manifest, then v0.14.4 and v0.15.0
   add paths to the preserve list, and nothing re-bakes.

7. **The framework controls `upgrade.sh` but expects the
   downstream copy to be authoritative.** Customer can edit
   `scripts/upgrade.sh` in their tree. Pre-bootstrap then has
   to consult a 3-SHA matrix to decide whether to overwrite.
   Why is the downstream allowed to hold a divergent copy of
   the updater?

8. **"Dogfood before cutting an rc" + "migrations are
   discovered by tag" are joint axioms.** Each looks
   reasonable alone. Together they are an unsatisfiable
   constraint: the rc-cutting ritual requires running the
   not-yet-tagged migrations against not-yet-existing tags.
   The team has been trying to solve this with cleverer
   migrations rather than asking whether one of the two
   axioms is wrong.

9. **Every fix lands a new migration; no migration ever
   leaves.** `migrations/v0.1.0.sh`, `v0.2.0.sh`, `v0.3.0.sh`,
   `v0.6.2.sh`, `v0.14.0.sh`, `v0.14.4.sh`, `v0.15.0.sh`,
   `v1.0.0-rc9.sh`, `v1.0.0-rc13.sh`, `v1.0.0-rc14.sh`,
   `1.1.0.sh`. Eleven migration files, each one a permanent
   tax on every upgrade that walks past it. There is no
   retirement story.

10. **"Intentional duplication" between
    `migrations/v0.14.0.sh` and `migrations/v1.0.0-rc13.sh`
    is documented as a feature, not a smell.** The rc13
    file's docstring explicitly says it is a near-verbatim
    copy of v0.14.0 and that this duplication is cheaper
    than the abstraction because "neither migration can
    rely on a shared file being present at the moment it
    must run." That argument concedes the conceptual error
    instead of resolving it.

## The conceptual mistake

The upgrade flow has confused two roles that need to be separate:
**(a) the orchestrator of the upgrade — a piece of code that runs
on the operator's machine and knows how to fetch, plan, and apply
a transformation — and (b) the per-version transformation steps
themselves — small idempotent diffs that mutate one project tree
from version X to version X+1.** Today, both roles live in
`scripts/upgrade.sh` and in the downstream tree. The orchestrator
is also one of the things being transformed; the transformations
are discovered by enumerating tags on the very upstream the
orchestrator is supposed to be talking to from the outside. Every
recurring failure class in dogfood-2026-05-15 is a consequence
of that conflation — self-overwrite mid-execution, pre-bootstrap
as a workaround, `--target` semantics fragmenting because old
orchestrators cannot parse new flags, manifest-vs-preserve-list
disagreement persisting because the orchestrator is too far from
the manifest writer, and rc-cliffs spawning more migrations to
patch the orchestrator itself.

Put it another way: the framework is trying to be Theseus's
upgrade-ship, with the planks being replaced while the ship
is at sea, by the ship's own crew, using a plan that the new
captain wrote and that the old captain cannot read. Each fix
in PR #197 was a careful plank-swap, performed in good faith,
and the ship sank anyway because the design forces every
plank-swap to happen mid-voyage. The honest move is to admit
the orchestrator must not be one of the planks.

## Process-debt invitations to architect / tech-lead / customer

For each, the role-of-record is named; the framing is "please
justify, or revise." Customer rules; the audit only invites.

### To architect

- **A-1.** Justify why `scripts/upgrade.sh` lives inside the
  downstream tree at all, given that every recurring upgrade
  failure traces to its dual role as a managed artefact AND
  the manager. Alternative worth weighing: a fetched-fresh
  orchestrator entrypoint (`curl … | sh` or `pip install
  swdt-upgrade` or an out-of-tree `swdt-upgrade` binary)
  that knows nothing about the project's current state
  except what the project tells it.
- **A-2.** Justify the tag-keyed migration enumeration. Why
  not enumerate by file presence in `migrations/` with semver
  comparison against `TEMPLATE_VERSION`? The file-presence
  model would have made rc13 reachable on main without
  cutting a tag.
- **A-3.** Justify pre-bootstrap as a distinct concept rather
  than the default mode. If pre-bootstrap is needed for any
  cross-cliff upgrade, why is "pre-bootstrap first, then run
  migrations" not just "the algorithm"?
- **A-4.** Justify the `.template-customizations` /
  `TEMPLATE_MANIFEST.lock` split as two independent writable
  artefacts. Why not a single source of truth (e.g.,
  preserved paths are an annotation on manifest rows) so
  that the invariant cannot be violated by construction?
- **A-5.** Justify cutting a migration file for every rc that
  ships a structural change, rather than tracking structural
  changes against a separate "framework structural version"
  that increments only on real cliffs and is decoupled from
  the rc-cadence.

### To tech-lead

- **T-1.** The dogfood ritual ran four times in 24 hours
  and produced four different blocker sets that each landed
  fixes that did not resolve the underlying class. Each
  individual fix passed code review and local smoke. Is the
  dogfood-vs-PR-vs-merge loop too tight? The ritual currently
  produces a feeling of "we made progress" because counts of
  conflicts changed, while the recurring failure class
  (orchestrator-self-mutation cliff) has not moved.
- **T-2.** "Customer ruling: dogfood before cutting an rc"
  + "migrations are discovered by tag" is the joint axiom
  that ate today. Recommend surfacing this to the customer
  as one of: (a) loosen the dogfood ruling (allow rc-cut
  before dogfood passes when only an rc-cut would unblock
  dogfood); (b) change migration discovery so it does not
  need the tag; (c) some third option from architect. This
  is the question that needs ruling; the engineering teams
  are coding into a contradiction.
- **T-3.** "Fixes landed in good faith, code-review passed,
  smoke passed" is happening across multiple recurring
  classes. Consider whether `qa-engineer`'s adversarial
  stance is being deployed at the right gate — the gate
  catches in-PR regressions, not "this fix patched the
  wrong layer." Adversarial review of architectural
  premises is currently nobody's job.

### To customer

- **C-1.** The fundamental architectural question: should
  the orchestrator be in-tree or out-of-tree? This is not
  an engineering call; it changes the operator UX. Out-of-
  tree means downstream operators install / update an
  `swdt-upgrade` command separately from the project. In-tree
  is the status quo and the source of the cliff pattern.
  This is the conceptual question architect needs ruling
  on before the next rc cut is meaningful.
- **C-2.** Is preserving project state through upgrades a
  binding requirement, or a default that operators can
  opt out of? If "destroy-state and re-scaffold from latest"
  were offered as a sanctioned upgrade path for the
  bring-up phase (alongside the merge-preserve path), the
  framework would have an escape valve when the merge path
  is wedged. Right now there is no escape valve.

## Areas the audit could not resolve

- **Whether option (a) of A-1 (fetched-fresh orchestrator)
  is consistent with the framework's air-gapped / offline
  operator stance.** Some downstream operators may be on
  segmented networks where `curl github.com | sh` is not
  allowed. The cost analysis needs `sre` + customer input.
- **Whether the rc-cutting ritual itself is the wrong
  granularity.** This audit can see the symptoms but cannot
  judge whether moving to a different release cadence
  (continuous main, monthly rc, structural-version-only
  rc) is right for the operator population. `project-manager`
  + customer call.
- **Whether `.template-customizations` should be retired
  in favour of a manifest annotation.** Architect-class
  call; this audit only flags that the two-artefact
  approach has produced two distinct bugs in 24 hours.
- **The retirement story for old migration files.** If the
  framework adopted "all migrations always run, idempotency
  guards" as the doctrine, eleven migration files times
  every-upgrade is a non-trivial floor. If it adopted
  "migrations retire at the next MAJOR," the customer needs
  to rule on what MAJOR means in pre-1.0 terms. Architect +
  customer.
- **Whether `architect-conceptual` and this audit converge
  on the same conceptual mistake.** By design the two
  dispatches are independent; comparison is for `tech-lead`.
