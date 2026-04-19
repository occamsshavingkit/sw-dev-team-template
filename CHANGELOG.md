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
