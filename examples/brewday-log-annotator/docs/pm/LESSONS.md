# Lessons Learned — BrewDay Log Annotator

Continuous journal. Milestone syntheses appended at each milestone
close. Final synthesis at project closure feeds back into the upstream
template per `docs/ISSUE_FILING.md`.

## Journal

### 2026-04-19 — dry-run of the template scoping flow itself

**Context.** This project was initiated as a *dry-run* of the
`sw-dev-team-template v0.1.0` scoping flow (milestone scope (c) of
the template-improvement project). The "customer" Alex Keller is a
simulated craft brewer; this is not a real engagement.

**Event.** `tech-lead` (simulated) walked Steps 1–4 of FIRST
ACTIONS. Scoping questions from
`docs/templates/scoping-questions-template.md` were asked one at a
time; six scoping questions answered + closed into
`docs/OPEN_QUESTIONS.md` and mirrored into `CUSTOMER_NOTES.md`.
Step 3 naming picked "classical composers" with 3 women / 7 men
reflecting the category's natural gender distribution, with
personality matches (Bach → architect, Mahler → PM, Stravinsky →
SRE, etc.). Step 0 opt-in not exercised in this dry-run (the dry-
run is not a real upstream-feedback candidate).

**What went well.**
- One-question-per-turn rule held; no multi-question MC bundles.
- Personality-match rule produced legible, defensible picks
  (Mahler → project-manager is the strongest match in this set).
- PM artifact templates (CHARTER, STAKEHOLDERS, SCHEDULE, COST,
  RISKS, CHANGES, LESSONS) had enough shape to fill without
  re-inventing.
- DoD checklist caught the lack of a project charter before any
  work subagent was dispatched — the milestone structure kept us
  honest.

**What did not.**
- Copying the template to `dryrun-project/` carried the template-
  repo's own Q-0001..Q-0012 rows in `docs/OPEN_QUESTIONS.md` and
  had to be manually stripped. Three `Write` tool failures before
  the replacements went through because the files existed but had
  not been Read first. Filed upstream as
  [#1](https://github.com/occamsshavingkit/sw-dev-team-template/issues/1).
- No explicit pronoun-verification procedure. Picks for
  contemporary composers (e.g., Caroline Shaw) were taken on
  general knowledge without a sourced citation in the
  `docs/AGENT_NAMES.md` Source column. Filed upstream as
  [#2](https://github.com/occamsshavingkit/sw-dev-team-template/issues/2).
- The template's `docs/OPEN_QUESTIONS.md` was seeded at scaffold
  time with the template's own questions instead of an empty
  register; conceptually the file should be empty-but-shaped on
  scaffold.

**Contributing factors.**
- The template is a copy of a live project rather than a clean
  scaffold; files like OPEN_QUESTIONS.md were treated as artifacts
  of the template instead of empty-shells-plus-conventions.
- The workflow (me, as tech-lead) failed to Read files before
  Writing them three separate times in one turn — a process
  discipline issue orthogonal to the template.

**Recommendation.** Land issue #1 as the top scaffold-script change.
Once that lands, a dry-run becomes a one-command action instead of a
multi-file manual cleanup.

**Category.** process / tooling / template-structure.

**References.**
- `docs/OPEN_QUESTIONS.md` (dry-run) Q-0001..Q-0006
- `CUSTOMER_NOTES.md` (dry-run) 2026-04-19 scoping entries
- Upstream issues #1 and #2
- Template CHANGELOG.md § v0.1.0 "Known gaps"

## Milestone syntheses

*(added at each milestone close — none yet for this dry-run since no
real work beyond scoping has been performed)*
