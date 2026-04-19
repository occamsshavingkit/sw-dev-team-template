# Contributing to `sw-dev-team-template`

This repository is the upstream for a multi-agent Claude Code project
template. Downstream projects are scaffolded from it (via
`scripts/scaffold.sh`) and file framework gaps back here as issues.

## Who contributes

- **Customer (repo owner).** Decides binding rules, role roster,
  naming conventions, and release cadence.
- **Downstream projects.** File gaps via the issue template
  (`.github/ISSUE_TEMPLATE/framework-gap.yml`), citing the template
  version they were scaffolded from. Do **not** open PRs against the
  template from a downstream project unless you have customer
  sign-off recorded in the downstream's `CUSTOMER_NOTES.md`.

## How to propose a change

1. **File an issue first.** Even if you have a PR ready, the issue
   establishes the rationale and gets a version tag. Use
   `.github/ISSUE_TEMPLATE/framework-gap.yml`.
2. **Discuss the shape of the fix.** The issue body's "Suggested fix"
   is a starting point, not a design.
3. **Open a PR** that:
   - closes the issue (`Closes #N` in the commit body);
   - updates `CHANGELOG.md` with the appropriate SemVer bump
     (MAJOR / MINOR / PATCH per the `CHANGELOG.md` header);
   - updates `VERSION` when the PR lands a release-worthy change
     (usually the PR itself does this, so the next `git tag` is a
     one-liner for the maintainer).
4. **Tests / smoke.** If the PR changes `scripts/scaffold.sh` or any
   executable, include a smoke-test transcript in the PR body.

## Release semantics

SemVer on the template artifact:

- **MAJOR** — breaking change (renamed / removed binding file, moved
  `.claude/agents/` layout, binding-rule reversal).
- **MINOR** — additive + backward-compatible (new agent role, new
  template, new optional section, new script).
- **PATCH** — fixes / non-structural clarifications (typo, rule
  wording, example update).

Downstream projects record the template version they scaffolded from
in `TEMPLATE_VERSION`. MAJOR bumps carry a migration note in
`CHANGELOG.md`.

## IP policy (binding)

See `CLAUDE.md` § IP policy. Any material not created within this
project is copyrighted by default. Do not paste copyrighted text into
the repository. Paraphrases with citations are fine; direct quotes are
reserved for the short-quotation rule (under 15 words with attribution,
never as sole authority).

## Filing from a downstream project

Use the `scripts/scaffold.sh`-stamped `TEMPLATE_VERSION` as the first
line of every framework-gap issue. Without that, the maintainer
cannot tell whether the reported gap is still current. Redact
customer-sensitive content but keep the pattern intact.

Filing is gated by Step-4 opt-in; projects that opted out log gaps
locally in their own `docs/pm/LESSONS.md` only.
