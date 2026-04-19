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
