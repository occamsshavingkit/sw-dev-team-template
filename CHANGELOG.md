# Changelog

Versioning: **SemVer** on the template artifact — `MAJOR.MINOR.PATCH`.

- **MAJOR** — breaking change to the template contract (renamed or
  removed binding file, moved `.claude/agents/` layout, binding-rule
  reversal, etc.). Downstream projects must migrate.
- **MINOR** — additive change that is backward-compatible for existing
  projects (new agent role, new template, new optional section).
- **PATCH** — fixes and non-structural clarifications (typo, rule
  wording, example update) that do not change semantics.

Every downstream project records the template version it was
scaffolded from (see `CLAUDE.md` "Template version stamp"). Issues
filed upstream include that version.

---

## v1.0.0-rc3 — 2026-04-25

Third release candidate. Closes the C-4 empirical-usage criterion on
the workflow pipeline (≥5 prior-art docs, reviewed proposals, Solution
Duels, three-path ADRs across two real downstream projects), lands the
formal IEEE 1028 readiness audit with recommendation **SHIP**, and
clears the rc3 tech-writer pass (17 findings, none blocker). Also
hardens scaffold/upgrade strip-set parity (F-002), the gen-toc
frontmatter contract (TW-001), and scrubs leaked downstream-project
context from the binding docs (F-001, F-003 through F-006, F-008,
TW-008, TW-009, TW-017).

### Added

- **C-4 evidence — workflow-pipeline empirical-usage closure.** Five
  prior-art memos across two downstream projects (three in one downstream project, two in another, both at
  `docs/prior-art/` after the
  relocation noted under *Changed*), four reviewed proposals, three
  Solution Duels, and ten three-path ADRs — over the ≥5 bar that
  C-4 sets for the workflow pipeline's empirical-usage criterion.
- **`docs/audits/v1.0.0-rc3-readiness-audit.md`** — formal IEEE 1028
  sign-off document for the rc3 cut. Recommendation: **SHIP**. Major
  condition (A-001 dirty-tree at audit time) was resolved by the
  four commits in this wave.
- **`docs/audits/v1.0.0-rc3-tech-writer-pass.md`** — prose / link /
  glossary / agent-contract style audit. Seventeen findings, none
  blocker; the in-scope subset (TW-001, TW-008, TW-009, TW-017) is
  fixed in this wave.
- **Revised `docs/audits/c4-evidence-tracker.md`** — reflects the now-
  closed C-4 stages.
- **`ROADMAP.md`** — rewritten for the v0.17 → rc3 era (was
  structurally stale by ~5 MINORs).

### Fixed

- **TW-001 (`9124d3b`).** `scripts/gen-toc.sh` now preserves YAML
  frontmatter when regenerating in-file tables of contents. Nine of
  fourteen agent contracts re-sequenced so the opening `---` is on
  line 1, restoring the loader contract.
- **F-002 (`d1238c6`).** `scripts/scaffold.sh` and `scripts/upgrade.sh`
  strip-set parity. Added `ROADMAP.md`, `docs/audits/`, `docs/v2/`,
  `docs/proposals/`, `docs/v1.0-rc3-checklist.md`, and
  `docs/pm/process-audit-*.md` to both filters in lockstep. Closes
  the upgrade-contract-hardening gap. *Note: this fix only takes
  effect for downstream projects after this tag is published, since
  `upgrade.sh` self-bootstraps from upstream's committed copy.*
- **F-001 (`0aae060`).** Scrubbed leaked downstream-project context
  from the body of `SW_DEV_ROLE_TAXONOMY.md`.
- **F-003 / F-004 / F-005 / F-006 / F-008 (`0aae060`).** README
  version stamp + step-numbering alignment + roster-count alignment
  + scaffolding-narrative alignment + scaffold-banner step-numbering.
- **TW-008 (`0aae060`).** `ROADMAP.md` rewritten (see *Added*).
- **TW-009 / TW-017 (`0aae060`).** `SW_DEV_ROLE_TAXONOMY.md` header
  status + attribution corrected.

### Changed

- **Pipeline location convention.** Prior-art memos canonically live
  at `docs/prior-art/<task-id>.md` (per workflow-redesign-v0.12 § 1).
  Downstream prior-session memos relocated from `docs/research/` to
  `docs/prior-art/` to match (downstream-side commit, separate tree).
- **`VERSION`:** `v0.17.0` → `v1.0.0-rc3`.

### Notes for downstream

- This is the **v1.0.0-rc3 release candidate**. Downstream projects
  should NOT bump `TEMPLATE_VERSION` to v1.0.0-rc3 unless they want
  to ride the rc track. The v1.0.0 final tag will follow if rc3
  sign-off holds without breakage.
- The F-002 strip-set fix only takes effect for downstream upgrades
  against this tag once it has been pushed to upstream's GitHub
  remote. Until then, downstream `scripts/upgrade.sh` runs continue
  to ship the older (leak-y) strip-set.

### Notes for upstream (carried into v1.0.0)

- Credit-gated follow-ups: file the C-3 upstream-attestation issue
  citing the downstream retrofit summary; close the two `v2-proposal`
  GitHub issues (#3, #27) that reference the existing
  `docs/v2/*.md` placeholders; publish a GitHub Release object at
  v1.0.0 final (rc cycles skip Release objects per the
  MINOR-only-Releases rule).

---

## v0.17.0 — 2026-04-25 (MINOR bundle)

Three downstream-reported issues addressed.

### Added

- **`scripts/upgrade.sh --target <version>` flag (#68).** Pin the
  upgrade to a specific upstream tag (e.g.
  `--target v0.14.4`) instead of always taking the latest. The
  script validates the tag exists in the upstream repo, checks it
  out in the upstream clone, runs migrations only up to and
  including the target, and stamps the target's tag. Without the
  flag, behaviour is unchanged — latest stable tag wins. Use case:
  pin to a known-stable mid-cycle version when a later release has
  a regression that needs evaluation.
- **SPDX headers on all `scripts/*.sh` (#69).** Each shipped script
  now carries the two-line `SPDX-License-Identifier: MIT` +
  copyright header. Eliminates per-project back-fill on downstream
  CI gates that enforce SPDX presence (a common NFR-0005 shape).
- **`docs/templates/github-actions-ci.yml` (#70).** Reference CI
  workflow for downstream projects with `paths-ignore`-style
  filtering on heavy jobs (test, miri, cross-compile) so doc-only
  pushes don't burn full CI minutes. Documented as a reference,
  not an active workflow — projects copy it to their own
  `.github/workflows/ci.yml` and adapt. The diff-detection step
  is preferred over `on.push.paths-ignore` because the latter
  filters the entire workflow rather than per-job.

### Notes

- v0.17.0 is `MINOR` because the `--target` flag is a feature
  add (new public CLI surface). #69 + #70 alone would be `PATCH`;
  bundled with #68 they ship together.
- All three issues filed mid-v0.16.0 release window. The triage
  bar from earlier in the v0.15.0 / v0.16.0 cycle holds: rc3
  shouldn't have known bugs. After v0.17.0 the only open items
  are aggregate trackers (#3 v2-proposal, #27 v2-proposal, #59 RC
  backlog) — none are bug-class.

Closes #68, #69, #70.

---

## v0.16.0 — 2026-04-25 (MINOR bundle)

Issue-clearing release ahead of v1.0.0-rc3 entry. Lands the v2
deferral placeholders, addresses 16 retrofit-playbook items in
one revision pass, ships the stepwise-upgrade smoke (re-entry
checklist criterion C-7), and adds the `SWDT_UPSTREAM_URL`
override that makes the smoke possible.

### Added

- **`scripts/stepwise-smoke.sh`** — walks every stable tag from
  v0.14.4 forward, runs `scripts/upgrade.sh` against a local
  clone with each tag checked out at the matching hop. Verifies
  exit code, `TEMPLATE_VERSION` stamping, `--verify` clean, and
  no stale `.tmp.*` files at every hop. Direct deliverable for
  v1.0.0-rc3 re-entry checklist C-7. Default start v0.14.4 (the
  bootstrap-enabled minimum); pre-v0.14.4 hops cannot be made
  cleanly stepwise because the in-place cp pattern in v0.13.0
  through v0.14.2 mutates the running upgrade.sh's inode mid-
  execution. Projects on those versions need the one-time curl
  recovery from v0.14.3's CHANGELOG to land v0.14.4's upgrade.sh,
  from which point they are stepwise-clean.
- **`SWDT_UPSTREAM_URL` env override on `scripts/upgrade.sh`** —
  redirects the upstream clone to a custom path. Used by
  `stepwise-smoke.sh` to point at a local clone with specific
  tags checked out per hop. Falls back to the canonical GitHub
  URL when unset; existing flows are unaffected.
- **`docs/v2/triage-repair-agent.md`** — v2-proposal placeholder
  for issue #3 (project triage + repair agent for retrofit
  adoption). Reserves the slot; v2.0 picks it up.
- **`docs/v2/claude-mem-hybrid-ledger.md`** — v2-proposal
  placeholder for issue #27 (claude-mem / SQLite hybrid ledger).
  Reserves the slot; v0.15.x ships only the design memo, v2.0
  picks up the implementation.

### Fixed (retrofit-playbook revision pass — 16 issues)

A single revision pass on `docs/templates/retrofit-playbook-template.md`
addresses every retrofit-playbook issue filed against v0.13.x:

- **#40** § 12.1 stall signal — agent-observable: ">3
  OPEN_QUESTIONS rows with `answerer: customer status: open` for
  >5 days" (N, M tunable).
- **#41** § 12.3 pivot — explicit artifact-survival list (Stage A
  / B / C reports kept; Stage D registers kept; Stage E commits
  reverted).
- **#42** § 4.2 — "Stage A seeds, Stage C resolves" clarification
  for convention-conflict register.
- **#43** § 4.6 — stale plan-row evidence escalates to architect
  rather than software-engineer deciding locally.
- **#44** § 7.2 — pinning ADRs require cost citation; >3 pins
  triggers a meta-ADR.
- **#45** § 1.2 — N→1 multi-source deferred-reshape note (per-
  source subdirs, inception-date tie-breaker, CHANGES numbering).
- **#46** § 2.4 — interstitial case for retrofit-and-upgrade-
  simultaneously.
- **#47** § 12.4 — default carry-out path for retrofit-lessons
  file (`<tgt-path>/../retrofit-lessons-YYYY-MM-DD.md`).
- **#49** § 4.1 — exact hash recipe for no-VCS source-drift check
  (`find -type f -print0 | sort -z | xargs -0 sha256sum | sha256sum`).
- **#50** § 4.3 — Hard-Rule-#7 wording split (binding obligation
  to loop in vs non-binding advisory).
- **#51** § 1.3 — FIRST-ACTIONS Step 0/1 absorption path so
  retrofit-first invocation doesn't stall on a menu.
- **#52** § 4.6 — scaffold baseline commit allowed without
  code-reviewer review; retrofit audit-artifact commits are
  Hard-Rule-#3 with narrowed scope (evidence-traceability,
  redaction hygiene, no committed sensitive content).
- **#53** new § 8.1 — nested sibling git repos (meta-repo +
  sibling-fork pattern) treated as out-of-scope artifacts.
- **#54** § 4.5 — inherited naming category from
  `<src-path>/.claude/agents/`; Step 3 becomes confirmation,
  not fresh conversation.
- **#55** § 4.7 + § 9 — versioned-doc governance (contract files,
  decision logs) recognised as a tracker-equivalent shape; Stage
  F handles row-by-row work-queue migration without assuming an
  external tracker.
- **#56** § 4.1 + § 4.3 — customer / employer / third-party
  identifying content as a pre-flight row (distribution-posture
  ruling); new Stage B disposition "project-authored,
  distribution-restricted" with target-posture-dependent landing.

### Issue-tracker triage (closes / labels, not code)

- **Closed (already-resolved)**: #5 (v0.11.0 unzipped detector),
  #13 (v0.12.0 agent-health-contract + v0.13.0 liveness rules),
  #16 (v0.13.0 scoping-transcript dump), #21 (partially across
  v0.5.x–v0.13.x; remaining as v0.15.x carry-over), #25 (v0.12.0
  process-auditor + onboarding-auditor), #33 (v0.13.0 Three-Path
  Rule), #36 (Claude Code harness limitation, documented),
  #38 (v0.12.0 agent-health-contract liveness), #48 (DoD
  checkbox shipped in v0.13.0; Stage-G promotion deferred per
  customer ruling).
- **Labelled `v2-proposal`**: #27 (claude-mem hybrid ledger).
  #3 (triage-repair agent) was already so labelled; both now
  have placeholders in `docs/v2/`.

### Smoke-test additions

`scripts/smoke-test.sh` already at 76 / 0 from v0.15.x; this
release adds `scripts/stepwise-smoke.sh` as a separate
deliverable for the v1.0.0-rc3 re-entry checklist (C-7). The
stepwise smoke is invoked manually for now; future release-CI
work would invoke it on every release tag.

### v1.0.0-rc3 re-entry checklist progress

After v0.16.0:

- C-1 (contract stability) — clean (no contract-break labels).
- C-2 (migration infra proven) — under test through the v0.14.x
  release window; zero customer escalations through v0.16.0.
- C-3 (retrofit field-tested) — pending real retrofit attempt
  with DoD met; needs downstream evidence.
- C-4 (workflow-pipeline empirical usage) — partial; three-path
  green (7 framework ADRs ratified); other three stages need
  downstream evidence.
- C-5 (audit agents exercised) — pending; needs at least two
  runs of `onboarding-auditor` + `process-auditor` against the
  template repo or representative downstream.
- C-6 (v2-proposal queue cleared) — clean (#3 + #27 labelled
  with placeholders).
- C-7 (stepwise upgrade smoke) — script lands; first run from
  v0.14.4 forward green.

C-3, C-4, C-5 need downstream-time evidence accumulation.
v0.16.0 is **issue-clean**: the only open items are aggregate
trackers (#3 + #27 with placeholders, #59 RC backlog tracker)
and the v0.15.0 deferred carry-overs (#21 contributor workflow
polish, #27 claude-mem implementation — both v2-proposal
labelled). No bug-class issues remain.

---

## v0.15.1 — 2026-04-25 (PATCH bundle)

### Fixed

- **`scripts/upgrade.sh` exit code 1 on clean upgrades.** The
  final summary block ended with `[[ ${#conflicts[@]} -gt 0 ]]
  && echo "..."`. When `conflicts` was empty (the happy path)
  the test failed, the `&&` short-circuited, and the script's
  last-command exit status was 1 — even though the upgrade itself
  completed cleanly and printed `Done.`. Replaced with an
  explicit `if`-block + `exit 0` at end. Closes a smoke-test
  failure introduced by v0.15.0's flow.

---

## v0.15.0 — 2026-04-25 (MINOR bundle)

Two structural fixes for upgrade-flow ergonomics + the
v1.0.0-rc3 re-entry checklist as a binding artefact.

### Added

- **`docs/v1.0-rc3-checklist.md`** — binding 7-point criteria
  list (C-1 through C-7) for re-entering the v1.0.0-rc track.
  Drafted now; ratification by customer is the gate before any
  v1.0.0-rc cut. Per ROADMAP.md § v0.15.0.
- **`docs/INDEX-PROJECT.md`** — project-authored content index,
  paired with `docs/INDEX-FRAMEWORK.md` (renamed from the old
  `docs/INDEX.md`). Top-level `docs/INDEX.md` becomes a tiny
  dispatcher pointing at both. Both INDEX.md and
  INDEX-PROJECT.md are pre-populated in
  `.template-customizations` at scaffold time.
- **`migrations/v0.15.0.sh`** — handles the structural
  changes for existing projects: rename framework ADRs from
  `docs/adr/NNNN-*.md` → `docs/adr/fw-adr-NNNN-*.md` (slug-
  comparison heuristic); preserve any project content from old
  `docs/INDEX.md` as `docs/INDEX-PROJECT.md`; add INDEX
  customizations entries.

### Fixed

- **#66 — `docs/INDEX.md` hybrid file produces unavoidable merge
  work on every upgrade.** Adopted Option A (split files) per
  the issue's recommendation. Framework content moves to
  `INDEX-FRAMEWORK.md` (replaced by upstream every upgrade);
  project content moves to `INDEX-PROJECT.md` (project-owned,
  never overwritten); top-level `INDEX.md` is a dispatcher
  pointing at both. The two streams are physically separated;
  merge work collapses to zero.
- **#67 — Framework ADR namespace collision with project ADRs.**
  Adopted Option A (separate ID prefix) per the issue. Framework
  ADRs use `FW-ADR-NNNN` IDs and `fw-adr-NNNN-*.md` filenames.
  Project ADRs continue to use the bare `ADR-NNNN` namespace and
  plain `NNNN-*.md` filenames. Renamed framework ADRs:
  `fw-adr-0001-context-memory-strategy.md` ..
  `fw-adr-0007-external-reference-adoption.md`. All cross-
  references updated in the same release (88 references across
  20 files, mass sed-replace from `ADR-000N` → `FW-ADR-000N`
  and `adr/000N-` → `adr/fw-adr-000N-`). `docs/templates/
  adr-template.md` documents the namespace split for future ADR
  authors.

### Smoke-test additions

7 new assertions covering the INDEX split + ADR rename. Total:
**75 passes / 0 failures** (after push — pre-push the simulated
upgrade against origin's lagging content shows one expected
artefact).

### Note for projects upgrading

`migrations/v0.15.0.sh` is automatic; no manual steps. After
the upgrade, prior `docs/INDEX.md` edits surface at
`docs/INDEX-PROJECT.md`. Framework ADRs renamed in-place;
cross-references in framework-shipped files update via the
file-sync.

**Project-authored files** that cite framework ADRs by the old
`ADR-000N` form are NOT auto-rewritten — project owners can
grep + sed for `ADR-000[1-7]\b` if they want consistency.

---

## v0.14.4 — 2026-04-25 (PATCH bundle)

Three fixes for upgrade-flow ergonomics surfaced by
downstream-project reports.

### Fixed

- **#63 root cause — `upgrade.sh` self-bootstrap.** v0.14.3's
  atomic-install only protected v0.14.3+ runs; projects upgrading
  *from* v0.13.x or v0.14.0–v0.14.2 still ran their old buggy
  `upgrade.sh` first and hit the inode mutation. v0.14.4 adds a
  bootstrap step at the top of `upgrade.sh`: clone upstream, check
  if `scripts/upgrade.sh` or `scripts/lib/manifest.sh` differs
  from local, atomically install upstream's versions, and `exec`
  the new script. The old process is replaced before any sync
  runs. After bootstrap (`SWDT_BOOTSTRAPPED=1` env var), the
  re-execed instance reuses the already-cloned `WORKDIR_NEW`
  via `SWDT_PRESTAGED_WORKDIR`. Note: this fix takes effect
  *from v0.14.4 forward*. Projects on older versions still need
  the one-time recovery procedure documented in v0.14.3's
  CHANGELOG (curl + replace `scripts/upgrade.sh`); after that one
  manual upgrade lands v0.14.4's `upgrade.sh`, every subsequent
  upgrade self-bootstraps cleanly.
- **#64 — agent `name:` rename produces false-positive
  conflicts.** Step 3 of FIRST ACTIONS encourages projects to
  give each agent a teammate name (`name: kermit`, etc.). The
  3-way file compare in `upgrade.sh` treated this as a
  customization, so every standard agent got flagged as a
  conflict on every upgrade — even when 12/13 agent files were
  byte-identical to upstream. **Fix:** `agent_cmp` helper
  ignores the `name:` line for `.claude/agents/<canonical>.md`
  files; `agent_splice_name` re-applies the project's name line
  after an in-place upgrade so the rename survives. Projects
  with muppet-named teammates now see only the agents that
  actually changed in upstream as conflicts.
- **#65 — project-content stubs flagged forever.**
  `scripts/scaffold.sh` now pre-populates `.template-customizations`
  with the canonical stub-fill paths (`CUSTOMER_NOTES.md`,
  `docs/OPEN_QUESTIONS.md`, `docs/AGENT_NAMES.md`,
  `docs/glossary/PROJECT.md`, `.gitignore`, `README.md`). New
  projects get the right behaviour from first scaffold; existing
  projects upgrading to v0.14.4 get a `migrations/v0.14.4.sh`
  that appends any missing canonical entries to their existing
  `.template-customizations` (idempotent — skips entries already
  present).

### Smoke-test additions

6 new assertions verify each stub-fill is in the scaffolded
project's `.template-customizations`. Total: **69 passes / 0
failures**.

### Note for projects on v0.13.x / v0.14.0–v0.14.2

The recovery procedure from v0.14.3's CHANGELOG still applies for
the first upgrade hop:

```
curl -fsSL https://raw.githubusercontent.com/occamsshavingkit/sw-dev-team-template/v0.14.4/scripts/upgrade.sh \
  -o scripts/upgrade.sh
bash scripts/upgrade.sh
```

After that one manual upgrade, the project lands v0.14.4's
self-bootstrapping `upgrade.sh`. Every future upgrade self-
bootstraps cleanly — no further manual intervention.

### Deferred

- **#66 — `docs/INDEX.md` hybrid template/project content.**
  Design decision (split files vs HTML fences) — v0.15.0.
- **#67 — Framework ADR namespace collision.** Design decision
  (FW-ADR-NNNN prefix vs separate directory vs reserved range)
  — v0.15.0.

---

## v0.14.3 — 2026-04-25 (PATCH bundle)

`scripts/upgrade.sh` now syncs files atomically (stage to `.tmp.$$`,
then `mv`), eliminating the in-place inode mutation that corrupted
the running `upgrade.sh` mid-execution.

### Fixed

- **#63 — `scripts/upgrade.sh`: in-place sync overwrites the running
  upgrade.sh mid-execution.** `cp src dst` truncates and rewrites
  `dst` in place, mutating the inode. When `dst` is the running
  `scripts/upgrade.sh` (or any other script bash is reading from),
  bash's open fd flips to new content mid-parse, producing arbitrary
  parse errors at random offsets and aborting the sync loop before
  `TEMPLATE_VERSION` is stamped — leaving the project in a partial-
  upgrade state. **Fix:** new `atomic_install` helper stages each
  file to `<dst>.tmp.<pid>` then renames atomically. `mv` on the
  same filesystem changes the inode rather than mutating the in-use
  file; bash continues reading the original inode (now unlinked but
  still resident) until the script ends.
- **Smoke-test additions:** new assertion that no stale `.tmp.*`
  files remain after a simulated upgrade. The post-upgrade verify
  assertion already added in v0.14.2 indirectly catches script
  corruption (a corrupted `upgrade.sh --verify` would fail to run
  cleanly).

### Recovery for projects in a partial-upgrade state

A project bitten by issue #63 (file-sync landed but
`TEMPLATE_VERSION` not stamped, manifest possibly stale or absent):

1. Confirm partial state: `cat TEMPLATE_VERSION` shows the *old*
   version even though new files like `scripts/lib/manifest.sh`
   exist on disk.
2. Manually replace the corrupted `scripts/upgrade.sh` with the
   v0.14.3 fixed version:
   ```
   curl -fsSL https://raw.githubusercontent.com/occamsshavingkit/sw-dev-team-template/v0.14.3/scripts/upgrade.sh \
     -o scripts/upgrade.sh
   ```
3. Run `bash scripts/upgrade.sh` — the v0.14.3 stamp-with-drift
   handler resyncs (atomically this time), stamps
   `TEMPLATE_VERSION`, and rewrites the manifest.

After step 3 the project is at v0.14.3 cleanly.

### Why earlier syncs didn't always trigger this

Pre-v0.14.0 syncs typically shifted `upgrade.sh` line counts only
slightly — bash's mid-parse offset usually landed on whitespace or
a duplicated comment, no parse error. The v0.14.0 release added the
manifest helper (`scripts/lib/manifest.sh`), bumped line counts,
and shifted everything down — so the same sync pattern that worked
silently on smaller diffs now exposes the latent bug. The atomic
fix removes the latency entirely.

### Note on v0.14.0 → v0.14.3 path

Projects on v0.14.0 / v0.14.1 / v0.14.2 may also have been bitten
by this latent bug on prior upgrades. Recovery is the same as
above: pull v0.14.3's `upgrade.sh`, then run.

Reported by a downstream project — issue #63.

---

## v0.14.2 — 2026-04-25 (PATCH bundle)

`migrations/v0.14.0.sh` now writes a **predicted post-sync manifest**
so a single `scripts/upgrade.sh` run from any starting version
produces a manifest that `--verify` reports clean. Removes the
two-run requirement that v0.14.1 introduced for projects upgrading
from v0.13.x (whose `upgrade.sh` predates the post-sync
`manifest_write` step).

### Fixed

- **`migrations/v0.14.0.sh`** — synthesises the manifest by
  predicting the post-sync state via the same 3-way compare
  `upgrade.sh`'s sync loop performs:
  - File in upstream but not in project → predicted SHA = upstream
    SHA (sync will add it).
  - File in both, baseline available, project SHA == baseline SHA
    (unchanged since scaffold) → predicted SHA = upstream SHA
    (sync will overwrite).
  - File in both, baseline available, project SHA != baseline SHA
    (customisation since scaffold) → predicted SHA = project's
    current SHA (sync will leave it alone, "kept").
  - File in both, baseline unavailable → conservative: treat as
    customisation; predicted SHA = project's current SHA.
  Output reports counts by category (`+added ~upgraded !kept`).
- **Single-run clean upgrade.** v0.13.x → v0.14.2 in one shot
  produces a correct manifest; `--verify` exits 0 immediately
  after, no manual regeneration step needed.

### Smoke-test additions

2 new assertions:

- `TEMPLATE_MANIFEST.lock` exists after the simulated v0.1.0 →
  vCURRENT upgrade.
- `upgrade.sh --verify` exits 0 after that single upgrade run —
  confirms the migration's prediction matches actual post-sync
  state.

Total smoke coverage: **62 passes / 0 failures**.

### Note on v0.14.0 → v0.14.2 path

Projects already on v0.14.0 (whose `upgrade.sh` has the
broken-signature post-sync `manifest_write` call) may still need
a second run, since the running v0.14.0 process invokes
v0.14.0's broken helper after sync. The migration writes a
correct manifest first; the v0.14.0 post-sync write may then
clobber it with a broken one. Workaround: after the v0.14.0 →
v0.14.2 upgrade, run `bash scripts/upgrade.sh --verify`; if
drift is reported, a second `bash scripts/upgrade.sh` run
self-heals via the v0.14.2 stamp-with-drift handler.

Projects on **v0.13.x or earlier** have no such issue —
single-run clean. v0.14.0 was a brief release; if the only
deployed users of it are the maintainer's own projects, they
self-heal in one extra run.

---

## v0.14.1 — 2026-04-25 (PATCH bundle)

`TEMPLATE_MANIFEST.lock` correctness fix. v0.14.0's manifest helpers
enumerated paths from the **project tree**, which produced bloated
manifests on projects that contain non-template content (nested
clones, operator notes, gitignored secrets). On non-git-initialised
projects the bug was worse: a `find`-fallback walked the entire tree
unfiltered, capturing 400+ paths instead of the ~95 template-shipped
files.

### Fixed

- **`scripts/lib/manifest.sh`** — path enumeration and SHA
  computation are now decoupled. `manifest_write` takes
  `<paths-repo> <project-repo> <out>`: paths come from the upstream
  clone or template source (which MUST be git-controlled);
  SHA256 hashes are computed from the project tree. The
  `find`-fallback is gone — `manifest_ship_files` now errors out
  with a clear message if `paths-repo` is not a git repository.
- **`scripts/upgrade.sh`** — post-sync `manifest_write` call now
  passes `WORKDIR_NEW` (upstream clone) for paths and
  `project_root` for SHAs. Manifest contains only files the
  upstream v0.14.x ships, with project-tree SHAs.
- **`scripts/scaffold.sh`** — `manifest_write` call passes
  `repo_root` (template source) for paths and the scaffolded
  `target` for SHAs.
- **`migrations/v0.14.0.sh`** — synthesis path now uses
  `WORKDIR_OLD` for both paths and SHAs in the baseline-available
  case; falls back to `WORKDIR_NEW` paths × `PROJECT_ROOT` SHAs
  when the baseline SHA is unreachable. Migration's manifest is
  transient (rewritten by upgrade's post-sync write) so the
  fallback's correctness only matters for projects that abort
  the sync mid-flow.
- **`manifest_verify`** simplified — walks manifest entries
  directly; no longer enumerates the project tree (which on a
  non-git project would have hit the same `find`-fallback bug).
  "Extra" detection at verify time is dropped: under v0.14.1's
  design, the manifest IS the canonical list of template-shipped
  paths; project-added files are out of scope by definition.

### Smoke-test additions

3 new assertions cover the regression specifically:

- Manifest excludes project-added `wg0.conf`-style secrets.
- Manifest excludes user-added `sme-*.md` agents.
- Manifest excludes project `docs/pm/*` PMBOK artefacts.

These are written by adding the synthetic files, regenerating the
manifest via the lib helpers, asserting absence, then cleaning
up. Total smoke coverage: **60 passes / 0 failures**.

### Backwards compatibility

This is a PATCH-level fix; no migration needed. Projects already
upgraded to v0.14.0 with bloated manifests can run
`scripts/upgrade.sh` again to get the corrected manifest written
post-sync; alternatively, `scripts/upgrade.sh --verify` will now
work cleanly on the next regeneration.

The v0.14.0 manifest format is unchanged (still
`<sha256>  <project-relative path>` lines after a comment header);
only the **selection** of which paths land in the manifest is
changed.

### Note for projects holding off

Downstream projects that paused at v0.13.0 waiting for v0.14.x to
stabilise can now proceed straight to v0.14.1 — no need to install
v0.14.0 first. The `migrations/v0.14.0.sh` script still runs and
produces the correct shape under v0.14.1's helpers.

---

## v0.14.0 — 2026-04-25 (MINOR bundle)

Upgrade-flow content verification, leaner template variants per the
jam01 pattern, MADR required/optional split, and a binding
"inspire, don't paste" rule. No breaking changes; existing v0.13.x
projects upgrade cleanly via `scripts/upgrade.sh` (which now runs
`migrations/v0.14.0.sh` to synthesise an initial manifest before
the file-sync step).

### Added

- **FW-ADR-0002 implementation — `TEMPLATE_MANIFEST.lock` content
  verification.** Per-file SHA256 manifest at project root, written
  by `scripts/scaffold.sh` at scaffold time and rewritten by
  `scripts/upgrade.sh` after every successful sync. New
  `scripts/upgrade.sh --verify` subcommand checks project files
  against the manifest with no network access. Exit codes:
  `0` clean, `1` drift, `2` missing manifest, `3` corrupt manifest.
  Closes the upstream issue #61 trust-the-stamp bug:
  `upgrade.sh` no longer short-circuits on `TEMPLATE_VERSION`
  equality alone — if the stamp matches but the manifest disagrees,
  it falls through to the sync flow and reconciles. Helpers live in
  `scripts/lib/manifest.sh`; sourced by both `scaffold.sh` and
  `upgrade.sh`.
- **FW-ADR-0003 — bare variants of `architecture-template.md` and
  `requirements-template.md`.** New
  `docs/templates/architecture-template-bare.md` and
  `docs/templates/requirements-template-bare.md` ship the same
  structural shape as the guided variants without the explanatory
  prose, ~50% smaller. Authors and agents pick the variant that
  matches their fluency. Synchronisation rule: structural changes
  land in bare first; guided is regenerated or hand-updated to
  match.
- **FW-ADR-0004 — per-item / per-view file templates.** New
  `docs/templates/req-item-template.md` (+ bare variant) for
  per-FR/NFR files at `docs/req/<ID>.md`; new
  `docs/templates/architecture-view-template.md` (+ bare variant)
  for per-IEEE-1016-viewpoint files at
  `docs/views/<viewpoint>-<name>.md`. Lets agents load only the
  requirement or view in scope, not the whole monolithic doc.
- **FW-ADR-0006 — MADR required/optional split in
  `docs/templates/adr-template.md`.** Each section now tagged
  **REQUIRED**, **RECOMMENDED**, or **OPTIONAL** with a top-of-file
  Section discipline note. Minimal ADR ~40 lines; full ADR ~200+.
  The Three-Path Rule remains binding (Required, never omitted).
- **FW-ADR-0007 binding rule — "Inspire, don't paste"** added to
  `docs/glossary/ENGINEERING.md` § Intellectual property. Borrowing
  a structural pattern is fine; copying prose / headings / table
  content is not, regardless of source license.
- **FW-ADR-0005 (Accepted, implementation deferred to v0.15.0).**
  `docs/standards/paraphrase-cards.md` — single source for IEEE/ISO
  paraphrase content cited from agent contracts. Deferred because
  the extraction touches five agent files and three templates; not
  bundling with v0.14.0's upgrade-flow work. The citation pattern
  (LIB-NNNN row IDs) is already in place so v0.15.0's extraction
  has nothing to invent.
- **`migrations/v0.14.0.sh`** — synthesises an initial
  `TEMPLATE_MANIFEST.lock` for projects upgrading from v0.13.x.
  Uses `WORKDIR_OLD` (baseline clone) when available; falls back
  to current on-disk SHAs otherwise. Idempotent.

### Fixed

- **#60 `scripts/version-check.sh` false-positive on withdrawn
  pre-release.** Stable-track projects (no `-suffix` in
  `TEMPLATE_VERSION`) now consider only stable tags as upgrade
  candidates; pre-release tags like `v1.0.0-rc2` are no longer
  surfaced as upgrade prompts. Pre-release-track projects continue
  to see all tags. Closes the stale-banner annoyance discovered
  this session.
- **#58 `scripts/upgrade.sh --help` and unknown flags.** Argument
  parser now handles `--help` / `-h` (prints usage, exits 0) and
  unknown flags (prints `ERROR: unknown flag: <X>` + usage to stderr,
  exits 2). Previously, `--help` and unknown flags fell through to a
  full upgrade.

### Smoke-test additions (`scripts/smoke-test.sh`)

11 new assertions covering the v0.14.0 contract:

- `TEMPLATE_MANIFEST.lock` exists after scaffold; carries the
  FW-ADR-0002 marker; non-empty (≥10 entries); excludes itself and
  `TEMPLATE_VERSION` by design.
- `upgrade.sh --verify` on fresh scaffold exits 0 and reports OK.
- After perturbation: drift detected (exit 1) with file-level
  report. After restore: clean (exit 0).
- Missing manifest: exit 2 with helpful message.
- Corrupt manifest: exit 3.
- `upgrade.sh --help` exits 0 and prints Usage; unknown flag
  exits 2 and prints ERROR.

Total smoke coverage: **57 passes / 0 failures** end-to-end.

### Closed (carried over from earlier review)

- **#62** (architect agent tools gap) — closed in v0.13.1 with
  corrected analysis: not a frontmatter bug, runtime divergence at
  the harness layer.

### Deferred to v0.15.0

- FW-ADR-0005 implementation (extract paraphrases from agent files).
- LIB-0015..0018 inventory rows in downstream library inventories
  (per FW-ADR-0007, applied per project on-demand).
- `--verify --format=json` machine-parseable output (FW-ADR-0002 marks
  it as a public CLI contract; not v0.14.0-mandatory).

### Notes for downstream projects

After upgrading, you'll have a new `TEMPLATE_MANIFEST.lock` at the
project root (committed). `scripts/upgrade.sh --verify` provides
offline drift detection; useful as a CI gate. Existing local
customisations are preserved per `.template-customizations` and the
existing per-file customisation-vs-upgrade resolution rules.

---

## v0.13.1 — 2026-04-25 (PATCH bundle)

Doc + agent-frontmatter PATCH. No behavior changes.

### Added
- **FW-ADR-0002 — Upgrade content verification (hash-based, manifest-primary).**
  New `docs/adr/fw-adr-0002-upgrade-content-verification.md` documenting the
  v0.14.0 design fix for `scripts/upgrade.sh`'s content-trust bug
  (issue #61). MADR 3.0 shape with three alternatives
  (Minimalist on-demand re-fetch / Scalable hash manifest / Creative
  tree-hash). Decision: hash manifest at scaffold/upgrade with
  on-demand re-fetch as `--verify` fallback. Implementation lands in
  v0.14.0; the ADR ships now so downstream projects can review the
  approach before the implementation.

### Fixed
- **#57 — `security-engineer` agent frontmatter.** Tool surface was
  `Read, Grep, Glob, SendMessage`, missing `Write` and `Edit`. The
  role contract assigns advisory-note authoring, threat-model
  authoring, and SBOM stewardship docs to this agent; without write
  tools it could not persist its own deliverables. Fixed to
  `Read, Write, Edit, Grep, Glob, SendMessage`. One-line frontmatter
  change; no body or behaviour rewrite.

### Closed (no code change)
- **#62 — `architect` agent tool gap.** Filed during this session
  based on the architect subagent's runtime self-report ("I only have
  Read available"). Investigation found the v0.13.0 frontmatter is
  already correct (`Read, Grep, Glob, Write, Edit, SendMessage`); the
  runtime divergence is a harness-layer behaviour to investigate
  separately. Closed as not-a-frontmatter-bug. Same pattern observed
  in subagent Edit denials despite project allowlist; will be tracked
  as a Claude Code harness issue on next investigation.

### Notes
- v0.13.1 is a doc-and-frontmatter PATCH; the upgrade.sh
  content-verify implementation, version-check.sh pre-release
  gating fix (#60), and upgrade.sh --help fix (#58) all stay in the
  v0.14.0 queue.

---

## v0.13.0 — 2026-04-24 (MINOR bundle)

Additive features. Placeholder; entries fill in as items land.

### Added
- **#33 Three-Path Rule (Phase 3 of workflow redesign).** New
  `docs/templates/adr-template.md` — MADR 3.0-shaped ADR template
  with § "Considered options" binding three named alternatives
  (Minimalist / Scalable / Creative), not a single recommendation
  with variations narrated in passing. Rationale from the
  workflow-redesign memo: LLMs converge on the "average" solution;
  naming Creative explicitly bypasses that bias. Creative's
  function is to make the team name the constraint that rejects
  it, not to be seriously considered every time.
    - New `docs/templates/adr-template.md` (MADR-based, Three-Path
      in Considered-options).
    - `.claude/agents/architect.md` gains "Three-Path Rule
      (binding, v0.13.0)" subsection in the ADR trigger list.
    - `docs/templates/architecture-template.md` § 10 "Architecture
      decisions (index)" cross-references the new ADR template and
      names the filename convention.
  Prior to this, ADRs were referenced throughout the template but
  no template existed for them — this lands both at once.

- **#3 Retrofit Playbook — adopting the template into an existing
  codebase.** New `docs/templates/retrofit-playbook-template.md`
  — agent workflow (not a script) for migrating an existing,
  non-scaffolded codebase into a freshly scaffolded target. Shape
  pinned by customer ruling 2026-04-23 (`CUSTOMER_NOTES.md`):
  scaffold-first, agent-discovers flow. Covers pre-flight readiness
  triage; Path-A-vs-Path-B decision record (scaffold-into-sibling
  wins over in-place by default, with Path B ADR-able per project);
  six stages (Pre-flight → A onboarding-auditor inventory → B
  researcher IP triage → C architect migration plan → D
  project-manager charter reconstruction from git log + README +
  interview → E software-engineer execution under code-reviewer →
  F optional ticket migration); decision matrix for per-artifact
  outcomes; convention-conflict protocol (§ 7 — migrate-to-template
  by default, ADR-pin exceptions, Hard-Rule invariants never
  overridable); IP triage aligned with CLAUDE.md § IP policy;
  rollback plan with stall detection and three outcomes (continue /
  pivot / roll back); register-population summary;
  `docs/retrofit/` directory shape; 10 anti-patterns; 12-item
  Definition of Done. Also amended:
    - `.claude/agents/tech-lead.md` routing table gains a
      "Migrate from an existing (non-scaffolded) codebase" row.
    - Scripts section of `CLAUDE.md` continues to cover the
      other three adjacent cases (`scaffold.sh`,
      `repair-in-place.sh`, `upgrade.sh`); `repair-in-place.sh`
      is **not** a retrofit tool and the playbook § 2.3 says so
      explicitly.
  Deliverable: `docs/templates/retrofit-playbook-template.md`
  (16 sections; revised after code-reviewer + architect review).
  Revision pass on 2026-04-24 landed 5 blocking findings:
    - New § 2.4 *Interstitial cases* routing (half-scaffolded,
      hand-edited scaffold, imported codebase, partial upgrade).
    - Hard Rules § 3 extended with **#7 security** binding
      (`security-engineer` sign-off on auth / secrets / PII /
      network-endpoint rows) and clarified **#4** to cover
      audit-discovered safety-critical surface, not only
      customer-pre-flagged rows.
    - § 4 stage table + § 4.6 Stage E + § 5 stage-gates table
      + § 6 decision-matrix note updated to name
      `security-engineer` as conditional Stage E gate with
      cross-stage Hard-Rule gates documented.
    - § 12.4 rollback now mandates write-before-delete:
      `retrofit-summary.md` finalized and carry-out
      `retrofit-lessons-YYYY-MM-DD.md` preserved outside
      `<tgt-path>` before deletion.
    - § 13 anti-patterns grew from 10 to 14: mid-stage
      abandonment without § 12 decision; undetected source
      drift (SHA compared at pre-flight vs Stage E start);
      stale Stage-D approvals invoked at Stage E; unratified
      escalations treated as ratified.
    - § 14 DoD gains: customer sign-off on retrofit completion;
      TEMPLATE_VERSION integrity check (matches scaffold-stamp,
      not just "unchanged"); `docs/INDEX.md` cross-link;
      Hard-Rule-#7 and Hard-Rule-#4 sign-off checkboxes.
    - § 15 cross-refs gain `.claude/agents/security-engineer.md`
      and `docs/templates/security-template.md`.
  Six non-blocking findings filed as #40–#45 for v0.13.1.

- **#39 Context-memory strategy — default guidance (adopt
  `claude-mem`, do not adopt orchestration frameworks).** New
  `docs/adr/fw-adr-0001-context-memory-strategy.md` — first template
  ADR, also the canonical worked example for the v0.13.0
  Three-Path ADR template. Evaluates `claude-mem` (thedotmack —
  passive memory layer) vs. `ruflo` / ex-"claude-flow"
  (ruvnet/ruflo — full multi-agent orchestration framework) in
  Three-Path shape (M: no tooling / S: claude-mem / C: ruflo),
  chooses S. Binding rationale: Option C's Q-learning router,
  autonomous swarms, and shadow roster collide with Hard Rules #1
  (only `tech-lead` talks to the customer) and #4 (live customer
  approval on safety-critical changes). Amendments to ship the
  decision:
    - `CLAUDE.md` § "Escalation protocol" — memory-first lookup
      becomes step 1 (before `CUSTOMER_NOTES.md`); explicit
      guardrail "memory is a lookup, not a source of truth."
    - `CLAUDE.md` new § "Memory and orchestration tooling" —
      records the stance and names the ADR. Orchestration
      frameworks require a superseding ADR before adoption;
      customer sign-off required.
    - `CLAUDE.md` FIRST ACTIONS Step 1 skill-pack menu — new
      entry [9] `claude-mem` (recommended default), with an
      explicit note that orchestration frameworks are off-menu
      by design.
    - `.claude/agents/tech-lead.md` — new binding § "Memory-first
      lookup" above § "Escalation protocol".
    - `.claude/agents/researcher.md` — prior-art scans check
      `claude-mem` first.
  Graceful fallback preserved: projects that cannot install
  `claude-mem` (air-gapped, policy restriction) skip the memory
  step and read artifacts directly; the rest of the escalation
  protocol is unaffected.

### Pending

---

## v0.12.1 — 2026-04-24 (PATCH)

Two-part PATCH for issue #37 (tech-lead orchestration gap).

### Fixed

- **#37 tech-lead has no spawn capability — two-part fix.**

  **Part 1 (belt-and-braces declaration).** `.claude/agents/tech-lead.md`
  frontmatter `tools:` line extended from
  `Read, Grep, Glob, Bash, Write, Edit, SendMessage` to
  `Read, Grep, Glob, Bash, Write, Edit, SendMessage, Agent` — adding
  the agent-spawn tool. Matches what `tech-lead.md` has always
  described itself as doing.

  **Part 2 (main-session-persona rule — the actual supported path).**
  `CLAUDE.md` gains a new binding section "Tech-lead is the
  main-session persona (binding)" immediately before § "Routing
  defaults", and `tech-lead.md` gains a "Usage model (binding)"
  paragraph at the top of its body. Both state explicitly: the
  main Claude Code session IS `tech-lead`; do not spawn
  `subagent_type: tech-lead`. The main session plays the role
  directly because only the main session has the `Agent` tool
  needed to spawn specialists. Subagents can only `SendMessage`
  already-running teammates; they cannot bring new specialists
  into being. Tech-lead-as-subagent is a passthrough, not an
  orchestrator, so don't use it.

  Part 1 is correctness; part 2 is the documentation that makes
  the intended usage model unambiguous. Future harness improvements
  (subagents being granted the tools their frontmatter declares)
  would make the Part-1 declaration functionally meaningful;
  Part-2 is independent of harness behaviour.

  **Harness-trust caveat (upstream).** A diagnostic dispatch of the
  patched `tech-lead` confirmed that the Claude Code harness in use
  when this PATCH was cut drops 6 of the 8 declared tools from
  subagent grants — not just `Agent` but also `Grep`, `Glob`, `Write`,
  `Edit`, `SendMessage`. The diagnosed `tech-lead` received only
  `Read, Bash`. Same class of anomaly as the `architect` case
  flagged in v0.12.0. **Open interpretation:** could be a real
  upstream bug, or could be registration-timing (harness loaded the
  pre-edit frontmatter at session start and doesn't pick up in-
  session edits — same pattern as #36 for new-agent registration).
  A post-session-restart diagnostic will disambiguate. Regardless,
  Part 2 of this PATCH is the supported path either way — the
  declaration is belt-and-braces for the day the harness honors it.

  If the repo owner confirms post-restart that declared tools are
  still dropped, file upstream at
  `https://github.com/anthropics/claude-code/issues`.

---

## v0.12.0 — 2026-04-23 (MINOR bundle)

Additive features. Placeholder; entries fill in as items land.

### Added
- **#36 new-agent registration warning.** `scripts/upgrade.sh`
  detects newly-added `.claude/agents/*.md` in the upgrade's "Added
  from upstream" set and prints a loud `ACTION REQUIRED` line
  naming the restart requirement. `CLAUDE.md` § "Template version
  check + upgrade" gains a one-paragraph warning to the same
  effect. Harness limitation (Claude Code initializes its agent
  registry at session start and does not rescan mid-session); this
  change documents the requirement rather than working around it.
  Closes #36 (part); upstream question #36 ¶3 (runtime agent
  registration) stays open pending Claude Code guidance.
- **#6 SME contract decision memo.** New
  `docs/sme/CONTRACT.md` — consolidated reference for the two-mode
  SME contract (primary-source vs derivative) from the 2026-04-19
  customer ruling. Replaces prior scattered references in CHANGELOG
  + `CUSTOMER_NOTES.md` with one durable memo. Closes #6.
- **#5 option 2 — repair-script pointer in unzipped-state warning.**
  `scripts/version-check.sh` already detected the unzipped-in-place
  state (VERSION present + TEMPLATE_VERSION absent + `.git` absent)
  in v0.10.x. Updated the user-facing message to point at
  `scripts/repair-in-place.sh` (new in v0.11.0) as option (a); the
  previous text said "if an in-place repair script ships later…".
  Closes #5 option 2.

### Pending
- (none — all v0.12.0 scope items landed or deferred)

### Added (continued)
- **#25 Cultural-disruptor / process-auditor agent.** New
  `.claude/agents/process-auditor.md` — one-shot auditor spawned
  every 2–3 milestone closes to challenge unspoken process
  conventions, find Process Debt (rituals whose justification is
  gone), ceremony without payoff, redundant checks. Counterpart to
  `onboarding-auditor` (which is zero-context by design — this one
  needs full project history). Findings route to `tech-lead` for
  customer decision; agent never removes rules unilaterally. Closes
  second half of #25.
- **#32/#33/#34/#35 design memo.** New
  `docs/proposals/workflow-redesign-v0.12.md` — architect-authored
  recommendation memo composing the four pre-code thinking
  proposals into one pipeline (prior-art → three-path → proposal →
  duel → code) gated by a mechanical OR-set trigger. Recommends
  phased rollout (Phase 1 = #34 + #32 in v0.12.0; Phase 2 = #35;
  Phase 3 = #33 last). **Recommendation only — implementation is
  the next cycle after customer review.** Flagged tool-grant
  anomaly: architect spawn did not receive its declared `Write`
  tool; tech-lead persisted memo manually. Auditor script
  `scripts/audit-agent-tools.sh` checks declared tools, not
  dispatched tools — if this is a harness pattern, file upstream.
- **Agent tool-grant fix (pre-flight).** `onboarding-auditor` and
  `process-auditor` gained `Write` in their tools grants — both
  write durable report files (FRICTION_REPORT / PROCESS_AUDIT)
  under `docs/pm/`. `scripts/audit-agent-tools.sh` flagged the
  missing grant; fix verified clean.
- **Claude Code harness anomaly — architect spawns not inheriting
  declared tools (2026-04-23).** Confirmed via a trivial diagnostic
  dispatch: architect agent spawns in this harness receive only
  `Read`, not the `Read, Grep, Glob, Write, Edit, SendMessage` set
  declared in `architect.md` frontmatter. Pattern, not one-off.
  This is an upstream Claude Code runtime issue, not a template
  defect. Reported in the workflow-redesign memo
  (`docs/proposals/workflow-redesign-v0.12.md` §Note). **To file:**
  the customer (repo owner) should report at
  `https://github.com/anthropics/claude-code/issues` if they want
  it fixed upstream. Template-side workaround: `tech-lead` persists
  architect-authored artifacts manually when the architect spawn
  reports missing tools (as was done for the workflow-redesign
  memo itself). No template change required; this entry is
  provenance.
- **Workflow redesign — Phase 1+2 implementation (customer bundled
  them per 2026-04-23 ruling).** The composed pre-code pipeline
  per `docs/proposals/workflow-redesign-v0.12.md` §1–§6. Lands
  #34 Researcher-First, #32 Options Before Actions, #35 Solution
  Duel. Phase 3 (#33 Three-Path) defers to v0.13.0.
    - New `docs/templates/prior-art-template.md` — `researcher`-
      owned durable artifact at workflow-pipeline stage 1.
    - New `docs/templates/proposal-template.md` — `software-
      engineer`-owned at stage 3; ships with the §Duel section
      attached so the stage-4 Solution Duel is an annex, not a
      separate file.
    - `.claude/agents/researcher.md` §Job item 5 gains the
      "Durable artifact required on triggered tasks" binding rule
      plus re-verification cadence (major-version bumps + 30-day
      stale check at milestone close).
    - `.claude/agents/software-engineer.md` gains a "Pre-code
      workflow (binding, workflow-pipeline stage 3+4)" section:
      produce proposal before code on triggered tasks; respond to
      every Duel finding; one round limit; escalate disputes to
      `tech-lead`.
    - `.claude/agents/qa-engineer.md` gains a "Solution Duel
      (binding, workflow-pipeline stage 4)" section: write three
      failure scenarios into proposal §Duel; one-round limit with
      tech-lead escalation on disputes; Hard-Rule-#7 paths pull
      `security-engineer` in as joint duelist. Composes with the
      existing Adversarial stance (diff-time) — same posture,
      applied earlier on the design artifact.
    - `.claude/agents/security-engineer.md` gains "Solution Duel
      participation (Hard-Rule-#7 paths)" — design-time duelist
      on auth / authz / secrets / PII / network-exposed triggers;
      release-time sign-off per Hard Rule #7 is distinct and
      unchanged.
    - `.claude/agents/tech-lead.md` §Job item 2 gains "Trigger
      annotation (binding, workflow-pipeline gate)" — annotate
      every task's `Trigger: <clauses|none>`, dispatch the
      pipeline on non-none triggers, escape hatches per memo §7.
      Routing table gains three new rows: prior-art,
      implementation proposal, Solution Duel.
    - `docs/templates/task-template.md` DoR gains two new rows:
      workflow-pipeline trigger annotated, and pipeline artifacts
      present if trigger fires. Identification block gains a
      `Trigger:` field.

---

## v0.11.0 — 2026-04-23 (MINOR bundle)

Additive features + allowed breaking changes (0.y convention).
Ships with `migrations/0.11.0.sh` when a breaking item lands.
See `V0_10_RELEASE_PLAN.md` §"Consolidated release queue" for
scope. Placeholder; entries below will be filled as items land.

### Added
- `docs/templates/pm/TOKEN_LEDGER-template.md` — PM token ledger
  scaffold. Append-only schema (`Date | Task ID | Agent | Tokens |
  Prompt (verbatim, fenced) | Notes`), example row, conventions.
  `task-template.md` DoD row now points at it; first task closure
  per project copies it to `docs/pm/TOKEN_LEDGER.md`. (Issues
  #17, #26.)
- **SWEBOK V4 / PMBOK 8 audit-pass-2 P1 remediation (2026-04-23).**
  Eight P1 gaps landed from `docs/audits/P1-REMEDIATION-PLAN.md`
  (downstream project audit; plan superseded by these edits).
    - `.claude/agents/security-engineer.md` — new agent, SWEBOK V4
      ch. 13 "Software Security" owner. Joint review with
      `code-reviewer` on auth / authz / secrets / PII / network-
      exposed changes. (SWEBOK V4 audit §2.1.)
    - `docs/templates/security-template.md` — new. Threat model
      + security requirements + assurance case shape per SWEBOK V4
      ch. 13 §§1–6.
    - `docs/templates/operations-plan-template.md` — new. CONOPS,
      supplier mgmt, IaC/PaC environments, capacity, DR pointer,
      DevSecOps touchpoints per SWEBOK V4 ch. 6 §2.
    - `docs/templates/dr-plan-template.md` — new. RTO/RPO,
      backup strategy, failover, restore-rehearsal schedule per
      SWEBOK V4 ch. 6 §2.5.
    - `docs/templates/pm/TEAM-CHARTER-template.md` — new. PMBOK 8
      §2.6 output; covers human + agent team norms.
    - `docs/templates/pm/RESOURCES-template.md` — new. PMBOK 8
      §2.6 Resources Performance Domain; human + physical +
      virtual tracking.
    - `docs/templates/pm/AI-USE-POLICY-template.md` — new. PMBOK 8
      Appendix X3; three adoption strategies + eight ethical factors.
    - `SW_DEV_ROLE_TAXONOMY.md` — new §2.4c "Security engineer";
      §2.3 SRE + §2.8 release-engineer gain SWEBOK V4 ch. 6
      operations-split citations.
    - `docs/glossary/ENGINEERING.md` — ISO/IEC 27001:2022 binding;
      "Restricted-source clause" binding.
    - `.claude/agents/project-manager.md` — three new PMBOK 8
      artifact rows (AI Use Policy, Team Charter, Resources) +
      expanded Responsibilities for sustainability, AI-use policy,
      team-charter stewardship, PMBOK 8 §2.6 resource management.
    - `.claude/agents/sre.md` + `.claude/agents/release-engineer.md`
      — SWEBOK V4 ch. 6 operations-split responsibilities.
    - `.claude/agents/architect.md` — security-engineer hand-off
      + operations trade-off arbitration.
    - `.claude/agents/code-reviewer.md` — security-engineer joint-
      review hand-off.
    - `.claude/agents/tech-lead.md` — routing-table row for
      `security-engineer`.
    - `.claude/agents/researcher.md` — new "Cite hygiene for
      restricted sources" section + source-handling matrix.
    - `docs/templates/pm/CHARTER-template.md` — §1 renamed
      "Purpose, justification, and value proposition"; new §11
      Sustainability considerations.
    - `docs/templates/pm/RISKS-template.md` + `LESSONS-template.md`
      — `sustainability` and `AI-use` added to category enums.
    - `CLAUDE.md` — new Hard Rule #7 (security-engineer sign-off
      for auth/secrets/PII/network-exposed releases); new Step-2
      DoD rows (Team Charter, AI Use Policy); new "Operations KA
      ownership" routing section; IP-policy bullet for
      restricted-source clauses (PMBOK 8 "NO AI TRAINING")
      + customer's narrow-interpretation ruling; roster gains
      `security-engineer.md`.
- **#5 part C — `scripts/repair-in-place.sh`.** New. Converts an
  unzipped-in-place template directory into a scaffolded project
  without copying to a new path: strips template-only files, resets
  the three project registers, stamps `TEMPLATE_VERSION`, seeds
  `.template-customizations`, `git init -b main`. `--dry-run` for
  preview; `--force` skips the interactive confirmation; refuses
  to run if `TEMPLATE_VERSION` is already present (already
  scaffolded) or if the current directory does not look like an
  unzipped template (sanity checks on `CLAUDE.md`,
  `.claude/agents/`, `docs/templates/`, `VERSION`). `README.md`
  Quickstart §"I already unzipped into my working directory"
  updated to point at it. Closes upstream issue #5 part C.
- **#25 Zero-context onboarding auditor.** New
  `.claude/agents/onboarding-auditor.md` — one-shot, deliberately
  context-constrained agent (no `CUSTOMER_NOTES.md`, no LESSONS /
  CHANGES / handovers / intake-log). Reads only public docs +
  source + scripts + tests. Produces `docs/pm/FRICTION_REPORT-
  <date>.md` enumerating doc gaps that block a notional new hire.
  Dispatched at milestone close (by `qa-engineer`) or ad-hoc (by
  `tech-lead`); does not escalate — stuck points are findings.
  Added to roster in `CLAUDE.md` and `tech-lead.md` routing table.
- **V2 roadmap §2 — QA outlines (7 templates).** New
  `docs/templates/qa/`:
    - `test-strategy-template.md` — master test plan, ISTQB + IEEE 829 shape
    - `unit-test-plan-template.md`
    - `integration-test-plan-template.md`
    - `system-test-plan-template.md`
    - `acceptance-test-plan-template.md` — customer sign-off protocol
    - `regression-test-plan-template.md` — three-tier suite + flaky-test policy
    - `performance-test-plan-template.md` — co-owned by `sre`
  (Plus `intake-conformance-template.md` from #16 fix — the 8th
  QA template, listed separately under #16.)
- **V2 roadmap §3 — Style-guide seeds (5 templates).** New
  `docs/style-guides/`:
    - `python.md` — PEP 8/257/484 + ruff + mypy
    - `typescript.md` — tsconfig strict + eslint + prettier
    - `rust.md` — rustfmt + clippy pedantic + unsafe-block SAFETY comments
    - `go.md` — gofmt + staticcheck + golangci-lint + context rules
    - `bash.md` — shellcheck + shfmt + mandatory `set -euo pipefail` header
  Cross-referenced from `.claude/agents/software-engineer.md` (follow
  the guide) and `.claude/agents/code-reviewer.md` (cite it in
  findings).
- **Premature-close drift fix (2026-04-23).** Issues #11, #13, #16
  were batch-closed on 2026-04-21 but the work had not all landed.
  Reopened and fixed:
    - `scripts/audit-agent-tools.sh` — new. Pre-flight keyword audit
      of `.claude/agents/*.md` frontmatter `tools:` grants against
      description / Job body. `--strict` exits non-zero for CI /
      pre-commit. Closes #11 secondary ask.
    - `docs/agent-health-contract.md` — new "Heartbeat convention
      (binding for long-running agents)" section; long-running
      agents SHOULD emit a one-line heartbeat at least every
      10 minutes, accepted forms: file write / `TaskUpdate` /
      `SendMessage`. `tech-lead.md` §Job item 3 adds a liveness-
      expectation bullet pointing at the contract. Closes #13.
    - `docs/templates/intake-log-template.md` — new. Append-only
      YAML-block log per customer question; `agents-running-at-ask:`
      invariant enforces atomic-question rule.
      `scripts/intake-show.sh` renders the log;
      `--violations-only` exits non-zero on violations.
      `docs/templates/qa/intake-conformance-template.md` — qa-
      engineer-owned checklist (C1–C10 per-entry + S1–S4 session-
      scope). `tech-lead.md` Step-2 now requires appending an
      intake-log entry per customer question. `researcher.md` now
      requires every `CUSTOMER_NOTES.md` entry to cite the matching
      intake-log `turn:`. Closes #16.

### Changed
- **SME contract — Fix-C hybrid ruling (issue #6).** Per
  customer ruling 2026-04-19, SME agents now come in two modes
  chosen at creation:
  - `primary-source` — has a non-public knowledge source
    (human expert or proprietary doc); cites that first, may
    consult public web on top; authoritative voice for the
    domain.
  - `derivative` — no primary source; consumes `researcher`'s
    paraphrases and public citations, adds domain-specialist
    framing / opinions explicitly flagged as judgment. Exists
    for context segmentation so `researcher` does not carry
    every vendor ecosystem in one context window.

  Rewritten: `CLAUDE.md` § "SME scope: what is and is not an
  SME (binding)" replaces the single-mode text with the two-mode
  formulation plus rule of thumb. `.claude/agents/sme-template.md`
  gains a "Mode (pick one at creation; binding)" section and a
  `Mode:` metadata field. `CUSTOMER_NOTES.md` captures the
  ruling verbatim.

  Gate 5 (no open contract-breaking themes) cleared by this
  ruling. Not breaking in practice — existing primary-source-
  only projects continue to work.
- `docs/templates/task-template.md` — DoD token-usage row
  references the new template file instead of embedding the
  schema inline.

### Pending (from the release plan)
- #6 SME contract decision memo + customer ruling
- #15 customer → product owner rename (breaking; needs `migrations/0.12.0.sh`; MAJOR-track when the rest of the v1 contract is re-stabilised)
- #21 GitHub contributor workflow (v2 scope — deferred)
- #25 cultural-disruptor half (zero-context half landed this cycle)

### Advisor recommendations landed (roll-up)

- **§5.4 Adversarial QA stance** (qa-engineer agent). Added to
  `.claude/agents/qa-engineer.md` as "## Adversarial stance
  (binding)" §24–54. QA's default posture is to try to break the
  work under review, not to affirm it; works with the test-pass
  gating row in `docs/templates/task-template.md` DoD.
- **§5.5 Archival + size budgets** (researcher agent). Added to
  `.claude/agents/researcher.md` §Job item 7 "Archival + size
  budgets (binding)" §107–135. Append-only `ARCHIVE.md` peers for
  every register that accumulates closed rows; soft line-caps on
  docs loaded into agent context (`CUSTOMER_NOTES.md` — 500 lines;
  `OPEN_QUESTIONS.md` — 200 open rows; glossaries — 300 lines;
  SME inventories — 200 rows). 80 %-cap librarian warning to
  `tech-lead`; caps are guidance not gates.

---

## v0.10.1 — **rolled into v0.11.0** (2026-04-23)

Non-breaking doc / wording / routing fixes from the Gate-3
engagement. **This bundle was never tagged independently — its
contents landed in the v0.11.0 commit (ee9729d) alongside the
v0.11.0 MINOR bundle.** Kept below for historical traceability; if
you are reading an `scripts/upgrade.sh` summary or a `git log` entry
and see a reference to v0.10.1, check the v0.11.0 tag for the actual
merge point.

### Changed (rolled into v0.11.0)
- `CLAUDE.md` FIRST ACTIONS — issue-feedback opt-in promoted
  from Step 4 to Step 0 (asked first, before skill menu and
  scoping). Step 2 DoD references Step 0 as backstop. (Issue
  #7.)
- `CLAUDE.md` Step 1 menu — `[6]` rewritten to reflect that
  `trailofbits/skills` is a marketplace, not a bundle, with
  per-plugin install syntax. (Issue #4.)
- `CLAUDE.md` Step 1 menu — `[7] context-optimization` and
  `[8] token-usage` entries added; `Skip` renumbered to `[9]`;
  verification date bumped to 2026-04-21. (Issue #29a.)
- `CLAUDE.md` — new `## Time-based cadences` section
  establishing session-anchored, run-once semantics.
  (Issue #31.)
- `CLAUDE.md` Step 3 — new Step 3a "Category scope pin"
  before dispatching `researcher` for naming. (Issue #9.)
- `.claude/agents/tech-lead.md` — customer-facing output
  discipline consolidated (R-1 idleness check as numbered
  procedure, R-2 Turn Ledger with formatting spec + DECISIONS
  handshake, R-3 teammate-naming discipline with pre-Step-3
  fallback); parallelism default with anti-pattern bullet and
  "dispatch now when inputs on disk" clause; scoping-transcript
  debug dump at Step 2 close. (Issues #10, #12, #18, #23,
  #28.)
- `.claude/agents/qa-engineer.md` — new "Adversarial stance
  (binding)" section. (Advisor §5.4 / issue #24.)
- `.claude/agents/researcher.md` — new "Archival + size
  budgets (binding)" item with soft caps and `ARCHIVE.md`
  rule. (Issue #20 / advisor §5.5 partial.)
- `docs/agent-health-contract.md` — signal 11 "Silent hang /
  lost heartbeat" added with default windows (3 / 10 / 20 /
  30 min) and liveness protocol (`SendMessage` ping, 60 s
  deadline, partial-artifact preservation). (Issue #13
  partial.)
- `docs/ISSUE_FILING.md` — "Rule 0 — redact project identity"
  added to "What to include"; Step 4 → Step 0 cross-reference
  updated. (Issue #8.)
- `docs/templates/task-template.md` — DoD token-usage row
  strengthened (schema inline; later replaced by reference to
  v0.11.0 template). (Issues #17 / #26 partial; full scope is
  v0.11.0.)
- `docs/templates/task-template.md` — DoD test-pass
  verification row strengthened (raw runner output required;
  `qa-engineer` re-runs). (Advisor §5.3.)
- `docs/templates/pm/RISKS-template.md`,
  `docs/templates/pm/STAKEHOLDERS-template.md` — cadence
  wording replaced with session-anchored / locale-agnostic
  phrasing. (Issue #31.)
- `docs/versioning.md` — SemVer 2.0.0 normative reference
  added. (Issue #30.)
- Step 4 → Step 0 rename swept through `README.md`,
  `scripts/scaffold.sh`, `docs/templates/scoping-questions-template.md`,
  `docs/ISSUE_FILING.md`, `docs/OPEN_QUESTIONS.md`, and the
  `brewday-log-annotator` example. (Issue #7 follow-through.)
- `.claude/agents/architect.md` — ADR trigger list +
  role-conflict tie-break. (Advisor §5.1 / §5.2.)
- `scripts/version-check.sh` — unzipped-in-place detector. Warns
  on stderr when `VERSION` is present but `TEMPLATE_VERSION` and
  `.git` are absent (user unzipped the template release into a
  working directory without running `scaffold.sh`). Points at the
  supported re-scaffold path. (Issue #5 part B.)
- `.claude/agents/tech-lead.md` — frontmatter `tools:` now
  includes `Write, Edit`. `tech-lead` writes
  `OPEN_QUESTIONS.md` rows, `AGENT_NAMES.md`, `TEMPLATE_VERSION`,
  and the Step-2 scoping-transcript dump. The audit pass against
  every agent's description confirmed the rest of the roster
  (including `researcher` `SendMessage` for #14) was already
  correct. (Issues #11 / #14, roster `tools:` audit pass 1.)
- `CLAUDE.md` Step 1 menu — "Detect already-installed skill
  packs before asking" rule in place; installed lines annotated
  `[already installed]` and not re-proposed. (Issue #22.)
- **Fix B for `tech-lead` respawn announcement (issue #19).**
  Verified consistent across three files:
  `docs/agent-health-contract.md` § 5.4 defines the rule
  (announcement comes from the newly-spawned `tech-lead` on its
  own first turn, quoting the handover brief's "First-turn
  customer message" section; `project-manager` does not contact
  the customer directly); `.claude/agents/project-manager.md` §
  "Tech-lead health audits + respawn" enforces it on the PM
  side; `.claude/agents/tech-lead.md` § "Agent health + respawn"
  mirrors it on the tech-lead side. Sole-human-interface
  invariant preserved without carve-outs.

### Pending
- (none — v0.10.1 scope complete pending release notes)

---

## v0.10.0 — 2026-04-20

**Release-track reset.** The template is withdrawing from the
`v1.0.0-rc` track and returning to `0.y.z` minor iteration.
Rationale: the Gate-3 engagement continues to surface rc-class
issues (#4–#29), including at least two breaking themes
(terminology rename in #15, memory architecture in #27) that
cannot honestly ship under a MINOR or PATCH bump once 1.0 is
claimed. Under SemVer, `0.y` permits breaking changes in minor
bumps, which matches where the template actually is. The criteria
for returning to `v1.0.0-rc` are recorded in `docs/versioning.md`.

### Changed
- `VERSION`: `v1.0.0-rc2` → `v0.10.0`. This is a renumbering, not
  a downgrade of content; everything shipped under `v1.0.0-rc1`
  and `v1.0.0-rc2` remains in place.
- The two `v1.0.0-rc*` tags stay in git history; they are not
  deleted. They mark the point at which the rc track was paused.

### Added
- `docs/versioning.md` — stating the 0.y iteration policy and the
  explicit criteria for returning to a `v1.0.0-rc` track.

### Notes
- No migration required for downstream projects. `upgrade.sh`
  handles the version stamp change. No file shapes changed.
- The `V1_RELEASE_PLAN.md` in the private workspace is renamed
  to `V0_10_RELEASE_PLAN.md`; rc-cycle issue triage continues
  under the new minor series.

---

## v1.0.0-rc2 — 2026-04-19

Second release candidate. Adds the agent-health and respawn
protocol that the rc cycle surfaced as a gap once named
teammates became a first-class concept.

### Added
- `docs/agent-health-contract.md` — binding. Failure modes,
  ten-signal detection taxonomy (passive + mechanical),
  ground-truth health-check protocol with fixed prompt and
  grading rubric, respawn protocol, and a three-layer
  self-diagnosis for `tech-lead` (scheduled by `project-manager`
  at milestone close; peer-triggered by `architect` /
  `researcher` / `project-manager`; customer as ultimate
  backstop at milestone close).
- `docs/templates/handover-template.md` — shape of a respawn
  handover brief. Every claim cites file + line; a brief with
  unresolved citations is not respawnable.
- `scripts/agent-health.sh` — assembles a health-check packet
  (fixed prompt + filesystem ground-truth snapshot). Delegates
  grading to the auditor per § 3.2.
- `scripts/respawn.sh` — stubs a handover-brief file pre-filled
  with filesystem context, prints the respawn checklist.
- `.claude/agents/tech-lead.md` § "Agent health + respawn" —
  tech-lead orchestrates health checks on other agents; its own
  health is audited by project-manager (chain of custody
  enforced).
- `.claude/agents/project-manager.md` § "Tech-lead health
  audits + respawn" — project-manager is the designated auditor
  and respawn orchestrator for tech-lead.
- `docs/INDEX.md` lists the new contract, scripts, and handover
  template.

### Changed
- `VERSION`: `v1.0.0-rc1` → `v1.0.0-rc2`.

### Notes
- Still pre-release. Gate 3 (one real-project engagement end to
  end) remains open; this rc2 tightens the template before that
  gate closes.
- Additive change set — no migration required. Existing projects
  receive the new files on next upgrade; no existing file is
  moved or reshaped.

---

## v1.0.0-rc1 — 2026-04-19

First release candidate for v1.0.0. **Stability candidate pending
field validation.** Field validation on an actual customer
engagement promotes this to `v1.0.0`; issues surfaced during that
engagement may produce additional `rcN` cuts or a later `v1.0.0`
directly.

### Gate status at rc1

- **Agent-file audit** — green. All ten role agents plus
  `sme-template` review as sufficient; no rewrites needed.
- **SME scope boundary** — green (v0.7.1).
- **Zero open framework-gap issues** — green.
- **Smoke-test across the version span** — green; 41 checks across
  scaffold + version-check + upgrade.
- **One real project end-to-end** — pending. This rc is explicitly
  the artifact that meets reality; the rc designation honors the
  open gate.

### Changed
- `scripts/version-check.sh` and `scripts/upgrade.sh` now accept
  pre-release tags (`vX.Y.Z-suffix`) in their tag-recognition
  regex, so projects stamped at an rc version can be upgraded
  across rc boundaries without falling through the pattern.
- `VERSION`: `v0.7.1` → `v1.0.0-rc1`.

### Notes
- No new migration required — the rc is a relabel of v0.7.1
  behaviour plus the regex widening.
- Downstream projects currently stamped at `v0.7.1` may upgrade to
  `v1.0.0-rc1` if they want the pre-release cut; most should stay
  on `v0.7.1` until `v1.0.0` final.

---

## v0.7.1 — 2026-04-19

### Added
- `CLAUDE.md` § "SME scope: what is and is not an SME (binding)" —
  draws the boundary between SME agents (customer-specific or
  externally-held knowledge) and `researcher` (standards-based +
  public Tier-1 retrieval). Stops the template from spawning
  redundant "sme-swe-standards" or "sme-pmbok" agents that would
  duplicate and drift from their upstream sources.
- `sme-template.md` front-matter gained a pointer to the scope
  boundary so every new SME agent makes the check before creation.

### Notes
- Gate 2 on the path to v1.0.0-rc1 now closed. Agent-file audit
  (gate 1) was reviewed and the existing agent files already meet
  the bar; no rewrites needed.

### Changed
- `VERSION`: `v0.7.0` → `v0.7.1`.

---

## v0.7.0 — 2026-04-19

### Added
- `examples/` directory: fully-filled-in reference projects that
  illustrate how the registers and PM artifacts look when actually
  populated. `examples/README.md` catalogs them.
- `examples/brewday-log-annotator/`: promoted from the v0.1.0
  dry-run (`dryrun-project/` in the template-dev workspace). Shows
  scoping flow end-to-end, classical-composers naming, and a filled
  project charter.

### Changed
- `scripts/scaffold.sh`, `scripts/upgrade.sh`, `scripts/smoke-test.sh`
  all exclude `examples/` from downstream scaffolding / upgrading
  (it is reference material for the template repo, not content
  shipped to new projects). Smoke-test grew two new exclusion
  checks (scaffold and upgrade); 41 checks total.
- `VERSION`: `v0.6.2` → `v0.7.0`.

### Notes
- Additive. No migration needed.

---

## v0.6.2 — 2026-04-19

### Added
- `migrations/v0.6.2.sh` — cleans up `LICENSE` and
  `scripts/smoke-test.sh` from downstream trees that leaked during
  pre-v0.6.1 upgrades. Honors `.template-customizations` (if a
  project has explicitly pinned `LICENSE` as a customization, it is
  left alone).
- `scripts/smoke-test.sh` now covers the **upgrade** flow in
  addition to scaffold: stamps `TEMPLATE_VERSION` back to v0.1.0,
  runs `upgrade.sh`, asserts no template-only files leaked and that
  the stamp matches current VERSION. 39 checks total (up from 31).

### Changed
- `VERSION`: `v0.6.1` → `v0.6.2`.

### Notes
- Downstream projects with leaked `LICENSE` / `smoke-test.sh` will
  see them auto-removed on next `scripts/upgrade.sh` run (unless
  explicitly preserved).

---

## v0.6.1 — 2026-04-19

### Fixed
- `scripts/upgrade.sh`'s ship-file exclusion list now matches
  `scripts/scaffold.sh`'s. Previous releases drifted: v0.5.1 added
  `LICENSE` with a scaffold exclusion but not an upgrade exclusion;
  v0.6.0 did the same for `scripts/smoke-test.sh`. Result: running
  `upgrade.sh` on a pre-v0.6.1 project added both template-only
  files to the downstream tree. This release stops new upgrades
  from doing so.

### Known residue
- Projects that already ran `upgrade.sh` before v0.6.1 may have a
  stray `LICENSE` and/or `scripts/smoke-test.sh` in their tree.
  Safe to delete manually; neither file is load-bearing for the
  template flow. A future migration may clean these up.

### Changed
- `VERSION`: `v0.6.0` → `v0.6.1`.

### Notes
- Patch. No downstream shape change; no migration added.

---

## v0.6.0 — 2026-04-19

### Added
- `scripts/smoke-test.sh` — end-to-end sanity test for the
  scaffold + version-check flow. Scaffolds a throwaway project,
  asserts 30+ layout/content properties (expected-present,
  expected-absent, version-stamp match, empty-register shape), and
  runs `version-check.sh` in the scaffolded project to confirm it
  reports "up to date". `--keep` preserves the temp dir for
  inspection. Template-maintenance only; not shipped downstream.

### Fixed
- `scripts/scaffold.sh` now excludes `scripts/smoke-test.sh` — it
  was being carried into downstream scaffolds. Caught by the new
  smoke test. (Downstream projects are maintenance-free; they do
  not need to run smoke-test on themselves.)

### Changed
- `VERSION`: `v0.5.2` → `v0.6.0`.
- `docs/INDEX.md` lists `scripts/smoke-test.sh`.

### Notes
- The fix and the test land together, which is the reason this is
  MINOR: a new downstream-visible exclusion plus a new template-
  maintenance tool. No migration needed.

---

## v0.5.2 — 2026-04-19

### Changed
- `scripts/version-check.sh` — the upgrade-available banner now
  includes direct links to the GitHub release page for the new
  version and to `CHANGELOG.md` on `main`, so the customer can read
  what changed before deciding to run `upgrade.sh`.
- Banner copy mentions `.template-customizations` as a preserve
  mechanism alongside user-added agents and PMBOK artifacts.
- `VERSION`: `v0.5.1` → `v0.5.2`.

### Notes
- Pure message-copy change. No behaviour or file change.

---

## v0.5.1 — 2026-04-19

### Added
- `LICENSE` — MIT, applied to the template artifact itself.
  Permissive; explicitly allows closed-source, proprietary, and
  commercially-licensed downstream projects built from this template.
- `CLAUDE.md` § "License of the template and of downstream projects"
  and `README.md` note the MIT license, the closed-source
  allowability, and the scaffold's decision to not carry the
  template's LICENSE into downstream projects (each project picks
  its own license).

### Changed
- `scripts/scaffold.sh` excludes `LICENSE` so downstream projects
  are not defaulted to MIT. Each project owner picks.
- `VERSION`: `v0.5.0` → `v0.5.1`.

### Notes
- Pure license / documentation addition; no behaviour change. No
  migration needed.

---

## v0.5.0 — 2026-04-19

### Added
- `.template-customizations` mechanism: downstream projects can list
  paths (one per line, project-root-relative) that are permanently
  customized. `scripts/upgrade.sh` skips listed paths entirely —
  never overwrites, never flags as a conflict — and reports them as
  `preserved` in the upgrade summary. `scripts/scaffold.sh` seeds
  the file empty with a header documenting the convention.
- `CLAUDE.md` § "Permanent customizations" documents the mechanism.

### Changed
- `scripts/upgrade.sh` reads `.template-customizations` before the
  file-sync loop and routes listed paths into a new `preserved`
  category. No behaviour change for projects without the file.
- `VERSION`: `v0.4.1` → `v0.5.0`.

### Notes
- Additive. Existing projects continue to work; they opt in to the
  preserve-list by creating the file. Legitimate repeated conflicts
  like a project-specific `.gitignore`, `README.md`, or a rewritten
  standard template can go in the list and stop nagging on every
  upgrade.

---

## v0.4.1 — 2026-04-19

### Fixed
- `migrations/v0.1.0.sh` no longer recurses into nested git repos
  (e.g., a `sw-dev-team-template` working copy that lives inside the
  downstream project directory). Rewrites of `docs/GLOSSARY.md` →
  `docs/glossary/ENGINEERING.md` were over-reaching into sibling
  projects and touching log-entry strings where both the old and new
  path legitimately appear. The reference-rewrite now skips files
  inside any subtree that contains its own `.git/`, skips files
  inside `docs/glossary/`, and only rewrites lines that reference
  **only** the old path (not lines that document the transition).

### Added
- `CLAUDE.md` Step 1 follow-up: after the skill-pack catalog, ask an
  atomic question for specialized skills / plugins / MCP servers /
  tools the user already knows they need, or watch-items for the
  team to flag (domain risks, style conventions, safety-critical
  behaviours). Scoping-questions template carries the seed row.

### Changed
- `VERSION`: `v0.4.0` → `v0.4.1`.

### Notes
- No downstream shape change; no migration needed for this release.

---

## v0.4.0 — 2026-04-19

### Added
- `migrations/` directory: per-version migration scripts that run
  during `scripts/upgrade.sh` when a release changes downstream
  content shape (moves, renames, splits, reformats). Most releases
  ship no migration; when they do, `upgrade.sh` runs every
  applicable migration in ascending SemVer order **before** the
  file-sync.
- `migrations/README.md`: contract, naming, idempotency rule, env-var
  interface.
- `migrations/TEMPLATE.sh`: starter scaffold for new migrations.
- `migrations/v0.1.0.sh`: retroactive glossary-split migration for
  pre-v0.1.0 projects that still have `docs/GLOSSARY.md` at the
  single-file path. Also rewrites references in markdown files.
- `migrations/v0.2.0.sh`, `v0.3.0.sh`: explicit no-op migrations
  documenting that those releases required no shape changes.
- `CLAUDE.md` § "Per-version migrations" — documents the contract.

### Changed
- `scripts/upgrade.sh` runs migrations before file-sync. Edge case
  handled: if the project's `TEMPLATE_VERSION` does not match any
  upstream tag, the script falls back to running every migration
  ≤ target, relying on idempotency guards.
- `scripts/scaffold.sh` excludes `migrations/` — downstream projects
  do not carry migration scripts locally; `upgrade.sh` sources them
  from the upstream clone at upgrade time.
- `VERSION`: `v0.3.0` → `v0.4.0`.

### Notes
- Adding `migrations/` is additive — existing projects continue to
  work. On their next upgrade, applicable migrations run
  automatically.

---

## v0.3.0 — 2026-04-19

### Added
- `scripts/version-check.sh` — compares the project's
  `TEMPLATE_VERSION` against the upstream's latest tag and prints a
  banner if an upgrade is available. Wired as a `SessionStart` hook
  in `.claude/settings.json`; silent on network failure.
- `scripts/upgrade.sh` (with `--dry-run`) — upgrades a scaffolded
  project to the latest template version. Per-file strategy: add
  missing, overwrite unchanged-since-scaffold, **never overwrite
  customized standard files** (flagged as conflicts for human
  review), never touch user-added files (SME agents, PMBOK artifacts,
  anything else the project created). Supports `GH_TOKEN` env var
  for private-upstream clones.
- `.claude/settings.json`: new `SessionStart` hook entry.
- `CLAUDE.md` § "Template version check + upgrade" — documents the
  flow and the customized-file conflict rule.

### Changed
- `VERSION`: `v0.2.0` → `v0.3.0`.

### Notes
- Running `scripts/upgrade.sh` requires access to the upstream repo.
  Private-upstream clones work via the `GH_TOKEN` env var (scope:
  `repo`).
- Conflicts (customized standard files that the upstream also
  changed) are surfaced but not resolved automatically. The project
  owner decides per-file.

---

## v0.2.0 — 2026-04-19

### Added
- `scripts/scaffold.sh` — creates a new project from the template,
  resets project-specific registers to empty stubs, stamps
  `TEMPLATE_VERSION`, initializes git. Smoke-tested. Closes upstream
  issue #1.
- `researcher.md` § Job #6 — pronoun-verification procedure with
  source hierarchy (living persons → agency bios → encyclopedias
  that cite primaries; historical figures → reference biographies;
  fictional characters → canon), explicit citation format, and
  re-verification cadence. Closes upstream issue #2.
- `CLAUDE.md` § "Scaffolding a new project" — documents the
  `scripts/scaffold.sh` entry point.
- `docs/AGENT_NAMES.md` § "Pronoun verification procedure" —
  cross-references `researcher.md`.

### Changed
- `VERSION`: `v0.1.0` → `v0.2.0`.

### Notes
- The change is additive (new file + new job bullet + new section).
  Existing projects continue to work without migration; they may
  adopt the scaffold script on their next new-project scaffold.

---

## v0.1.0 — 2026-04-19

Initial cut.

### Added
- Agent roster: `tech-lead`, `project-manager`, `architect`,
  `software-engineer`, `researcher`, `qa-engineer`, `sre`, `tech-writer`,
  `code-reviewer`, `release-engineer`, plus `sme-template.md`.
- FIRST ACTIONS: Step 1 (skill packs — six bundles incl. Trail of
  Bits), Step 2 (scoping + SME discovery with binding Definition of
  Done checklist), Step 3 (agent naming with personality-match and
  gender-representation rules), Step 4 (issue-feedback opt-in).
- `docs/glossary/ENGINEERING.md` (binding, generic SWE terminology)
  and `docs/glossary/PROJECT.md` (binding, project-specific jargon).
- `docs/AGENT_NAMES.md` mapping file with pronoun rule,
  gender-representation rule, personality-match rule, two worked
  examples (Muppets, famous singers).
- `docs/OPEN_QUESTIONS.md` register with columns (ID, date, question,
  blocked-on, answerer, status, resolution). Stewarded by
  `researcher`.
- `docs/INDEX.md` table of contents.
- PMBOK-aligned `project-manager.md` agent and
  `docs/templates/pm/` artifact templates (charter, stakeholders,
  schedule, cost, risks, changes, lessons-learned).
- `docs/templates/scoping-questions-template.md` seed queue.
- `docs/ISSUE_FILING.md` convention for filing gaps against upstream.
- Agent-teams panel support: env var pinned in
  `.claude/settings.json`; `tech-lead` spawns named teammates.
- Question-asking protocol (binding): one question per turn, wait
  for all agents idle.

### Not yet included (tracked in `docs/OPEN_QUESTIONS.md` or upstream
issues)
- Dry-run on a throwaway new project (scope (c) of v0.1 milestone);
  in progress at release.
- Upstream GitHub repo URL: `https://github.com/occamsshavingkit/sw-dev-team-template`
  (private; created 2026-04-19).

### Known gaps (filed as issues)

- [#1](https://github.com/occamsshavingkit/sw-dev-team-template/issues/1)
  No scaffold script; template-repo state leaks into new projects
  that copy the template manually.
- [#2](https://github.com/occamsshavingkit/sw-dev-team-template/issues/2)
  Pronoun-verification procedure for `researcher` is undefined.
