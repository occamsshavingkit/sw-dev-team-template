# FW-ADR-0002 — Upgrade content verification (hash-based, manifest-primary)

Shape per MADR 3.0 + this template's Three-Path Rule
(`docs/templates/adr-template.md`).

---

## Status

- **Accepted**
- **Date:** 2026-04-25
- **Implementation:** shipped in v0.14.0 — `scripts/lib/manifest.sh`,
  `scripts/upgrade.sh --verify` subcommand, scaffold-time manifest
  write + self-verify, `migrations/v0.14.0.sh`, smoke-test coverage.
- **Deciders:** `architect` + `tech-lead` + customer (public-API change to
  `scripts/upgrade.sh`; customer approval required per CLAUDE.md Hard Rules)
- **Consulted:** upstream issue #61; `software-engineer` (proposal phase
  to follow); `qa-engineer` (duel phase to follow); `release-engineer`
  (CI follow-up).

## Context and problem statement

`scripts/upgrade.sh` short-circuits on `TEMPLATE_VERSION` stamp equality
(line 60–63). Any project whose stamp drifted ahead of file content —
hand-edits to `TEMPLATE_VERSION`, partial upgrades killed mid-run,
botched migrations leaving an inconsistent tree, scaffold-then-edit
flows that bypass the upgrade path — cannot self-heal: the upgrader
declares "already at $local_version — nothing to do" while files on
disk are arbitrarily older than the stamp claims. The trust anchor
is wrong: a stamp is metadata about an intent; the source of truth
is the **file content**.

Trigger: upstream issue #61 step (c). ADR-trigger rows that fire:
public-API change (the `upgrade.sh` CLI surface gets `--verify`),
cross-cutting concern change (the upgrade contract itself), and choice
that locks the project into a verification approach future releases
must respect.

## Decision drivers

- **Detection accuracy.** Must catch silent drift in either direction
  (file ≠ stamped version), with no false negatives on the bug case
  in #61.
- **Offline tolerance.** Verify must degrade gracefully when the
  upstream repo is unreachable, the SHA is gone (force-push,
  org-rename), or the network is firewalled. The framework targets
  air-gapped industrial sites among others.
- **Performance.** Verify-on-every-upgrade is acceptable; verify on
  every session start is not (would compound `version-check.sh`
  latency).
- **`.template-customizations` interaction.** Verify must not generate
  noise on legitimately customized files. The current preserve-list
  contract must extend cleanly to verify.
- **Forward compatibility.** Whatever shape we ship in v0.14.0 has to
  survive future template releases without per-release special cases
  in downstream projects.
- **Idempotency.** Re-running verify or upgrade must converge; no
  oscillation, no spurious diffs from line-ending or permission
  drift on platforms the customer might use (Windows/WSL bind mounts
  in particular).

## Considered options (Three-Path Rule, binding)

### Option M — Minimalist: on-demand re-fetch + per-file diff

On every upgrade run (and `--verify`), clone the upstream tag matching
`TEMPLATE_VERSION`, walk `ship_files`, and `cmp -s` each project file
against the upstream tag. No stored manifest; trust is re-derived
each invocation from a freshly cloned upstream.

- **Sketch:** Extend the existing baseline-clone logic in
  `upgrade.sh` to be the *primary* trust source. `--verify`
  short-circuits after the comparison phase without writing. The
  stamp becomes advisory metadata, not authority.
- **Pros:**
  - Zero new state in the project tree — no `.lock` file to
    maintain, ship, or migrate.
  - Always-correct relative to the upstream-of-record; no manifest
    can go stale.
  - Reuses existing baseline-clone code path almost verbatim.
- **Cons:**
  - Useless when offline / upstream unreachable / SHA force-pushed
    away. `version-check.sh` already documents this failure mode;
    requiring it for *verify* moves it from "warning" to "blocker".
  - O(network) cost on every verify; CI use becomes expensive.
  - `--verify` exit code is meaningless when network fails — must
    distinguish "verified clean" from "could not verify" from
    "verified dirty".
- **When M wins:** projects that always have upstream connectivity;
  short-lived projects where ship-today beats long-term resilience.

### Option S — Scalable: hash manifest at scaffold/upgrade

Ship a `TEMPLATE_MANIFEST.lock` alongside `TEMPLATE_VERSION`,
populated by `scaffold.sh` and overwritten by every successful
`upgrade.sh` run. Each line: `<sha256> <path>` for every file in
`ship_files`. Verify compares on-disk SHA against manifest entry,
no network needed.

- **Sketch:** New artifact `TEMPLATE_MANIFEST.lock` (sorted, line-
  oriented, deterministic, project-root). `scaffold.sh` writes it
  after the tar copy. `upgrade.sh` rewrites it after a successful
  sync. `upgrade.sh --verify` reads it, walks `ship_files`,
  computes SHA per file, reports drift. `.template-customizations`
  paths are *omitted* from the manifest entirely (so they are
  silently honored — no drift report against a file the project
  has declared permanently customized).
- **Pros:**
  - Fully offline. Works in air-gapped sites, behind firewalls,
    after upstream URL changes.
  - O(local I/O) — fast; safe to run in CI on every PR.
  - Manifest doubles as a tamper-evidence record: a git diff on
    `TEMPLATE_MANIFEST.lock` answers "what template-shipped files
    did this branch touch?" at a glance.
  - The manifest survives a force-pushed upstream tag — verify
    still works against the local snapshot of intent.
- **Cons:**
  - New artifact to maintain; new file to think about during
    migrations.
  - If `scaffold.sh`/`upgrade.sh` write the manifest incorrectly,
    every subsequent verify lies confidently. (Mitigation: the
    write step is bounded and testable.)
  - Manifest-vs-stamp can themselves disagree if a project hand-
    edits one and not the other. (Mitigation: the v0.14.0
    migration regenerates both atomically; verify treats the
    manifest as authoritative and re-derives the stamp from it.)
- **When S wins:** the framework's actual use case — long-lived
  industrial projects with intermittent or zero upstream access,
  CI-driven release pipelines, regulated sites where reproducibility
  is auditable.

### Option C — Creative: content-addressed shipping (no separate version)

Drop the SemVer-stamp model entirely. Ship the upstream as a
content-addressed snapshot — every file path in the project is
keyed against a single root tree-hash (the upstream commit SHA at
release time). Verify reduces to "does the project tree's
template-owned subset reproduce the tree-hash?" Migration becomes
a tree-hash transition graph rather than a SemVer queue.

- **Sketch:** `TEMPLATE_VERSION` becomes a single line: the upstream
  commit's tree-hash. Verify reconstructs the tree-hash from on-disk
  files (excluding `.template-customizations` and user-added paths)
  and compares. Drift = hash mismatch; the diff tooling tells you
  which paths drifted.
- **Pros:**
  - Most theoretically clean — Merkle-style integrity.
  - One artifact, one hash, no manifest.
  - Resistant to file-by-file forgery in a way per-file SHAs are
    not (an attacker cannot cherry-pick which files to lie about).
- **Cons:**
  - Hard to explain to a customer reading `TEMPLATE_VERSION`. SemVer
    is human-legible; a tree-hash is not.
  - Requires a stable canonicalization (sort order, line endings,
    permission bits) — this is exactly where Git's index already
    lives, so we'd be reimplementing a piece of Git in bash.
  - Loses the version-skew signal that `version-check.sh` and the
    upgrade banner depend on. Would force a redesign of the whole
    upgrade UX.
  - Migration story is murky — every release becomes a tree-hash
    transition, harder to write a per-version `.sh` against.
- **When C wins:** if the framework had supply-chain-attack threat
  models in scope. It does not (per `SW_DEV_ROLE_TAXONOMY.md` and
  `CUSTOMER_NOTES.md` — this is a developer ergonomics framework,
  not a hardened distribution channel).

## Decision outcome

**Chosen option: S (hash manifest at scaffold/upgrade), with M as
fallback inside `--verify` when the manifest is missing or the
project pre-dates v0.14.0.** This is the "hybrid C" in the customer's
brief, but the manifest is unambiguously primary; on-demand re-fetch
is the recovery path, not a peer.

**Reason:** the framework's binding non-functional context is
intermittent connectivity (industrial sites, air-gapped customers,
firewalled CI). Option M cannot serve that context. Option C buys
threat-model strength the project does not need at the cost of UX
the project does need. Option S delivers offline verification, fast
CI integration, and a tamper-evident artifact, while keeping
SemVer-legible stamping intact. The cost — one new artifact —
is bounded and falls cleanly into the existing `scaffold.sh` /
`upgrade.sh` write paths. The fallback to M when the manifest is
absent is what makes the migration story across pre-v0.14.0
projects tractable.

### Interface decisions (binding)

1. **`upgrade.sh --verify` (new subcommand).**
   - Reads `TEMPLATE_MANIFEST.lock`, walks `ship_files` minus
     preserve-list, reports drift. Writes nothing. No network.
   - Exit codes:
     - `0` — verified clean (every shipped file matches manifest).
     - `1` — drift detected (one or more files differ from manifest).
     - `2` — manifest missing or unreadable; verify could not run.
       Suggests `upgrade.sh` (regenerates manifest) in stderr.
     - `3` — manifest format error (corrupted line, hash length
       wrong). Distinct from "missing" so CI can react differently.
   - Output format (machine-parseable):
     - Default: human-readable report (added/upgraded-style).
     - With `--format=json`: one JSON object per line:
       `{"path": "...", "status": "ok|drift|missing|extra",
       "expected_sha": "...", "actual_sha": "..."}`. Final line is
       a summary object with counts. Choosing JSONL (not a single
       JSON document) so streaming works and partial output is
       parseable on early exit.
   - `--format=json` is added in v0.14.0 with the explicit
     understanding that the JSONL schema is **stable** from
     v0.14.0 onward; field-name changes are MINOR-version events
     with deprecation periods.

2. **Drift behavior when stamp says "current".**
   - **Report-only by default.** Auto-repair is rejected: silently
     overwriting customer-edited files on a verify call violates
     the "customization wins" rule the framework already commits
     to in upgrade flow.
   - The user opts in to repair via `upgrade.sh` (the existing
     command), which now treats manifest drift as a trigger to
     resync regardless of stamp equality. This subsumes the #61
     bug case: if stamp == upstream but manifest drift exists,
     `upgrade.sh` resyncs the drifted paths (same conflict
     handling as the existing flow — overwrites if "unchanged
     since scaffold", flags as conflict if customized).
   - No interactive prompt. The framework's CLI surface stays
     non-interactive (CI-friendly).

3. **Verify at scaffold time.**
   - Yes — `scaffold.sh` writes the manifest, then immediately
     verifies it (fail-fast on a corrupted scaffold). Failure
     aborts the scaffold with a clear error before `git init`.
   - This is internal verification, not a user-facing
     `--verify` invocation.

4. **`.template-customizations` interaction.**
   - Listed paths are **omitted from the manifest entirely** at
     write time. They generate no manifest entries, so verify
     cannot report drift on them.
   - Rationale: the project has explicitly declared the path as
     permanently customized; the framework gives up the right to
     know what's in it. Reporting "drift, customer-acknowledged"
     would be noise on every verify run with no actionable
     content.
   - The verify human-readable output lists preserved paths in a
     trailing "Preserved per .template-customizations (N)"
     section, mirroring the existing upgrade summary, so the
     user can see what was excluded without it being drift.
   - Edge case: a path is added to `.template-customizations`
     after manifest write. Next `upgrade.sh` regenerates the
     manifest with that path omitted. Verify between those two
     events will report it as drift (correctly — the manifest is
     stale until regenerated). Documented as expected behavior.

5. **Stamp authority shift (binding).**
   - From v0.14.0: when stamp and manifest disagree, **manifest
     wins**. The stamp is human-readable metadata. Verify uses
     the manifest. `upgrade.sh` cross-checks stamp against
     manifest and rewrites the stamp from the manifest if they
     disagree, with a `WARN` line.

### Migration `migrations/v0.14.0.sh` design

For each starting state:

1. **Clean v0.13.0 project** (manifest absent, stamp accurate, files
   match upstream v0.13.0).
   - Generate `TEMPLATE_MANIFEST.lock` from `WORKDIR_OLD` (the
     v0.13.0 clone) — every shipped file's SHA at v0.13.0,
     omitting paths in `.template-customizations`.
   - Write the manifest. The subsequent file-sync step in
     `upgrade.sh` will then rewrite the manifest at v0.14.0 once
     the upgrade itself finishes. Both writes are idempotent.

2. **Stamp-ahead-of-content project** (the bug case from #61 —
   stamp says vX, files are some other version).
   - The migration cannot generate a correct manifest from
     `WORKDIR_OLD` because the on-disk files don't match
     `WORKDIR_OLD`. So: the migration generates the manifest
     from on-disk files at their *current* SHAs, and then
     **`upgrade.sh`'s post-migration sync step does the heavy
     lifting** — it sees manifest entries that don't match
     v0.14.0 and resyncs accordingly (Strategy 2 / Strategy 4
     from the existing upgrade contract, file by file).
   - Net effect: the bug self-heals on next upgrade. Customer
     does not have to know they were bitten by it.

3. **Pre-v0.13.0 project** (no `.template-customizations`,
   possibly old shape).
   - Earlier migrations (v0.13.0.sh and below) already ran in
     the migration queue per `upgrade.sh` ordering. By the time
     `v0.14.0.sh` runs, the project has v0.13.0 shape.
   - Migration falls into case (1) above.

**Idempotency invariants:**

- If `TEMPLATE_MANIFEST.lock` already exists and parses cleanly,
  the migration leaves it alone. Subsequent `upgrade.sh` sync
  will rewrite it.
- If the manifest exists but is corrupted, the migration replaces
  it (corrupted state is not a state we preserve).
- The migration writes nothing else. All shape-changing work is
  done by the v0.14.0 release in the regular sync pass.

## Consequences

### Positive

- The #61 bug is structurally impossible from v0.14.0 forward —
  trust shifts from a single-line stamp to a per-file content
  hash.
- Verification works fully offline.
- CI can gate "no template drift on PR" cheaply
  (`upgrade.sh --verify --format=json`).
- Manifest diffs in `git log` give an audit trail of which
  template-shipped files moved when.
- Pre-v0.14.0 projects self-heal on next upgrade without manual
  intervention.

### Negative / trade-offs accepted

- New artifact (`TEMPLATE_MANIFEST.lock`) shipped to every
  downstream project. Adds one row to `docs/INDEX.md` and one
  concept to `CLAUDE.md` § "Template version stamp".
- Manifest-write paths in `scaffold.sh` and `upgrade.sh` are
  new failure modes. Mitigated by scaffold-time self-verify.
- `--verify` adds CLI surface that future releases must keep
  backward-compatible. The JSONL schema is now a public
  contract.
- Force-push or upstream-rename still breaks Option-M fallback;
  pre-v0.14.0 projects without a manifest have no recovery if
  upstream is gone. (Mitigation: documented; the fallback is
  best-effort.)

### Follow-up ADRs

- None required for v0.14.0 itself. A future ADR may revisit the
  Option-C tree-hash model if supply-chain threat surfaces enter
  scope.

## Verification

- **Success signal:** the smoke-test suite (extended in
  `qa-engineer`'s phase) covers (a) a clean v0.13.0 project
  upgrades to v0.14.0 cleanly, manifest present and correct;
  (b) a stamp-ahead-of-content project self-heals on
  `upgrade.sh`; (c) `upgrade.sh --verify` exits 0 on a
  freshly-scaffolded project, exits 1 after an artificial
  drift, exits 2 when the manifest is deleted; (d)
  `.template-customizations` paths are absent from the
  manifest and absent from drift reports.
- **Failure signal:** an upstream issue is filed reporting that
  `upgrade.sh` falsely reports "nothing to do" or that
  `--verify` produces noise on customized files; OR a
  downstream project's CI flakes on the JSONL schema between
  patch releases.
- **Review cadence:** at v0.15.0 release planning. Reconsider
  if any of the failure signals fire, or if a new threat model
  (supply chain, signing) enters scope.

## Links

- Upstream issue: `#61 — upgrade.sh content-trust bug`.
- Related ADRs: FW-ADR-0001 (orchestration stance) — unrelated, but
  establishes the ADR numbering precedent.
- Related artifacts: `scripts/upgrade.sh`, `scripts/scaffold.sh`,
  `scripts/version-check.sh`, `migrations/README.md`,
  `migrations/TEMPLATE.sh`.
- External references: MADR 3.0 (`https://adr.github.io/madr/`).
