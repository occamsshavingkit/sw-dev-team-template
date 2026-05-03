# Issue Filing — reporting framework gaps upstream

When, while working on a real project, the team hits a gap in this
framework — a missing agent, a rule that produced a bad outcome, a
template that didn't fit, an ambiguous routing path, a missing
standard reference, a wrong default — `tech-lead` files the gap as an
issue against the upstream template repository, so a future version
can fix it.

This file is kept in every downstream project so the convention
travels with the template.

## When to file

File an issue when **any** of the following happens during project work:

- An agent was missing from the routing table that would have been the
  right addressee.
- A binding rule in `CLAUDE.md` or an agent file produced a worse
  outcome than breaking the rule would have.
- A template did not cover something that a PMBOK / ISO / IEEE /
  ISTQB / SFIA / SWEBOK standard requires at the relevant process
  point.
- A question path was unclear — specifically, who should have
  answered.
- `docs/OPEN_QUESTIONS.md`, `CUSTOMER_NOTES.md`, or an SME inventory
  turned out to be the wrong shape for the real data.
- A skill, plugin, or env var that the template assumes turned out to
  be missing, renamed, or deprecated.

Do **not** file an issue for project-specific content (customer
answers, product decisions, one-off quirks). Those stay in the
project's own notes.

## Opt-in

Filing upstream is per-project opt-in, recorded in
`CUSTOMER_NOTES.md` § "Issue feedback opt-in" and set at Step 0 of
FIRST ACTIONS. If the project is opt-out, `tech-lead` still keeps a
local gap log at `docs/pm/LESSONS.md` — it just does not push
upstream.

Projects that started on an older template version may not have a
Step-0 record yet. Retroactive opt-in is valid: ask the same Step-0
question at the next session start, record the customer's answer in
`CUSTOMER_NOTES.md`, and apply that ruling from that point forward.
Do not file already-discovered gaps upstream until the answer is on
record.

## What to include

**Rule 0 — redact project identity.** Do NOT include the downstream
project name, customer name, product codename, or any identifier
that would let a third party attribute the issue to a specific
downstream project. Describe the project only in enough abstract
terms to make the gap pattern reproducible (e.g., *"a softPLC-in-
Rust project"*, *"a regulated-industry data-pipeline project"*).
`tech-lead` scans every drafted issue body for project / customer /
codename strings before filing; if in doubt, the default phrasing
is "a downstream project."

Every issue includes:

1. **Template version** — the `v…` from the project's
   `TEMPLATE_VERSION` file (or the git SHA recorded there). Without
   this, the maintainer cannot tell whether the gap is still current.
2. **Short title** — what is missing / wrong / unclear.
3. **Where** — specific file + section (e.g., `CLAUDE.md` § "Step 2"
   or `.claude/agents/tech-lead.md` § "Routing table").
4. **What happened on the project** — one paragraph. If customer-
   sensitive content has to be redacted, redact but keep the pattern
   intact.
5. **Why it was a gap** — which rule / standard / PMBOK clause / ISO
   section was not served.
6. **Suggested fix** (optional) — if `tech-lead` and any relevant
   specialist have a concrete proposal, include it. Otherwise just
   file the gap.

## How to file

Assumes the upstream repository has been created and its URL is
recorded in `CHANGELOG.md` § "not yet included" or — once the repo
exists — in this file directly.

Preferred: `gh issue create --repo <upstream> --title "..." --body "..."`.

Fallback: web UI.

The maintainer reviews issues periodically and either amends the
template (MAJOR / MINOR / PATCH per `CHANGELOG.md`) or closes with
rationale.

## Upstream URL

    https://github.com/occamsshavingkit/sw-dev-team-template

Issues: `https://github.com/occamsshavingkit/sw-dev-team-template/issues`.
The repository is private; filing requires collaborator access — coordinate
with the customer before filing from a project owned by a different
GitHub identity.

---

Framework-project itself: see repo-root `README.md` for contribution
conventions.
