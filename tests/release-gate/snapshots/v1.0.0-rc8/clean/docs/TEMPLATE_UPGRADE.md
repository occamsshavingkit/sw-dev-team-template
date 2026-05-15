# Template scaffold + upgrade

> Source: extracted from CLAUDE.md (v1.0.0-rc7) per issue #120.

## Scaffolding a new project

A new downstream project is created by running the template's
scaffold script from the template repo root:

    scripts/scaffold.sh <target-dir> [<project-display-name>]

The script copies the template into `<target-dir>`, resets project-
specific registers (`docs/OPEN_QUESTIONS.md`, `CUSTOMER_NOTES.md`,
`docs/AGENT_NAMES.md`) to empty-but-shaped stubs, strips template-only
files (`VERSION`, `CHANGELOG.md`, `CONTRIBUTING.md`, `LICENSE`,
`dryrun-project/`, `examples/`, `.github/`, `migrations/`,
`scripts/smoke-test.sh`, `ROADMAP.md`, `docs/audits/`, `docs/v2/`,
`docs/proposals/`, `docs/v1.0-rc3-checklist.md`,
`docs/v1.0-rc4-stabilization.md`,
`docs/v1.0.0-final-checklist.md`, runtime `docs/pm/` artifacts, and
role-local `.claude/agents/*-local.md` supplements), stamps
`TEMPLATE_VERSION` at the project root (SemVer + git SHA + date),
replaces `README.md` with a project stub, seeds an empty
`.template-customizations`, and runs `git init -b main` in the
target (no initial commit — the project owner makes that). Issues
filed against the upstream cite the `TEMPLATE_VERSION` so the
maintainer can tell whether a reported gap is still current.

**License of the template and of downstream projects.** The template
itself is **MIT** (see `LICENSE`). That license is intentionally not
copied into scaffolded projects — each downstream project picks its
own license. Downstream projects are free to be closed-source,
proprietary, or licensed under any terms the project owner chooses;
the MIT grant on the template does not infect them.

## Template version check + upgrade

At every session start, `scripts/version-check.sh` runs (via the
`SessionStart` hook in `.claude/settings.json`) and compares the
project's `TEMPLATE_VERSION` against the upstream repo's latest
tag. If an upgrade is available, it prints a banner to the session
transcript; otherwise it says "up to date" and stays out of the way.
If the network is unreachable or the upstream returns nothing, the
script is silent — it never stalls a session.

To actually upgrade:

    scripts/upgrade.sh [--dry-run]

**If the upgrade adds new agents under `.claude/agents/`, restart
Claude Code before dispatching them.** The agent registry is
initialized at session start and does not rescan the agents
directory mid-session; dispatches via `subagent_type` will fail
with "Agent type not found" on newly-added agents until restart.
`scripts/upgrade.sh` prints a loud `ACTION REQUIRED` line listing
the new agents when this applies. (Upstream issue #36.)

Upgrade strategy, per template-shipped file:

1. **Not present in the project** → added from upstream.
2. **Unchanged since scaffold** → overwritten with the new upstream
   version.
3. **Customized since scaffold, upstream unchanged** → left alone
   (your customization wins).
4. **Customized since scaffold AND upstream also changed** → flagged
   as a conflict; the file is **not** overwritten. You diff manually
   and decide per-file: keep local, take upstream, or merge.

User-added agents (any `.md` in `.claude/agents/` that is not in the
template's standard roster, i.e. `sme-<domain>.md` agents created
per-project) are never touched. Project-filled PMBOK artifacts under
`docs/pm/` are never touched. Any other file the project added that
the template does not ship is left alone.

**Permanent customizations.** Files the project has **permanently**
customized (e.g., a `.gitignore` with project-specific entries, a
rewritten `README.md`, or adapted templates) can be listed one-per-
line in `.template-customizations` at the project root. Listed paths
are never overwritten and never flagged as conflicts; they appear as
`preserved` in the upgrade summary. The scaffold seeds this file
empty; populate it the first time an upgrade flags a legitimate
customization you want to keep.

**Volatile shipped files.** Avoid editing template-shipped scripts,
`.claude/settings.json`, and append-only governance logs in place
unless the project intentionally accepts the merge cost. Prefer
project-local wrappers (`scripts/project-*.sh`), project-owned config,
or append-only entries below existing markers. If an upgrade does
flag a conflict, `upgrade.sh` prints a per-file heat-map showing the
upstream delta and local delta since scaffold; use that to decide
whether to take upstream, preserve local, or merge manually.

**Project-specific agent routing.** Do not edit template-shipped
`.claude/agents/<role>.md` files just to add project language,
framework, domain, or tool-routing rules. Instead create
`.claude/agents/<role>-local.md` beside the canonical role file.
Every shipped agent contract checks for its local supplement before
starting role work and treats it as project-specific routing layered
on top of the canonical contract. Local supplements are project-owned:
they are not shipped by the template, are excluded from manifests, and
are preserved across upgrades without `.template-customizations`.
If a local supplement conflicts with a canonical role contract or with
Hard Rules, the agent escalates to `tech-lead`.

`--dry-run` prints the plan without writing. Use it before the real
upgrade on any project where the conflict set is non-trivial.

### Per-version migrations

Some releases change the **shape** of downstream content (moves,
renames, splits, reformats). Those releases ship a migration script
at `migrations/<target-version>.sh` in the template repo. `upgrade.sh`
runs every migration whose target version is strictly greater than
the project's current `TEMPLATE_VERSION` and less-than-or-equal-to
the new target, in ascending order, **before** the file-sync step.

Most releases have no migration (purely additive changes). Each
migration is idempotent — re-running it is safe. If a project's
`TEMPLATE_VERSION` does not match any upstream tag (hand-stamped or
pre-release), `upgrade.sh` runs every migration up to the target
with idempotency guards handling the rest.

See `migrations/README.md` for the contract and `migrations/TEMPLATE.sh`
for the scaffold a new migration starts from.
