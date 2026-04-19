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
