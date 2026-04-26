# SW-dev Team Template for Claude Code

A ready-to-use Claude Code project scaffold that turns a single Claude
session into a 13-role software-development team with a strict escalation
protocol and a per-project SME pattern.

**Status.** Release-candidate track (currently `v1.0.0-rc3`). The
seven binding rc-track criteria in `docs/v1.0-rc3-checklist.md` are
all green; IEEE 1028 readiness audit was held by the upstream
maintainer with recommendation **SHIP** (audit deliverables held
upstream-private per redaction policy; not in this repo). The
public contract becomes stable at `v1.0.0` final; breaking changes
are still permitted on the rc track if a criterion regresses.

---

## Quickstart

> **Read this before anything else.** This repository is the
> **template source**, not a scaffolded project. If you unzip (or
> clone) this and run `claude` directly inside the unzipped directory,
> the session will *appear* to start, but the project will be missing
> every invariant the template relies on (no `TEMPLATE_VERSION`, no
> `git init`, no reset registers, no `.template-customizations`).
> Always scaffold a new directory — see step 2 below.

### 1. Get the template

Either clone the git repo (preferred — lets you `upgrade.sh` later)

```
git clone https://github.com/occamsshavingkit/sw-dev-team-template.git
```

or download the release zip and unzip it. Either way, this lands the
template source on your machine. Do **not** work inside this directory.

### 2. Scaffold your project

From the template source directory, run the scaffold script with a
path to your new project's directory and a display name:

```
scripts/scaffold.sh ~/code/my-new-project "My New Project"
```

This creates `~/code/my-new-project/` as a fresh, template-shaped
directory with `TEMPLATE_VERSION` stamped, registers reset to empty
stubs, template-only files (VERSION, CHANGELOG, LICENSE, migrations)
stripped, and a `git init`'d history. The scaffold script does not
make any commits — the first commit is yours to make so your repo's
git conventions apply.

### 3. Enable the agent-teams panel

The template assumes the Claude Code experimental agent-teams feature
is on. Set the environment variable before running `claude`:

```
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
```

Or pin it in `~/.claude/settings.json`. Without it, named teammates
won't appear in the TUI's bottom panel and `SendMessage` routing
between agents will not work.

### 4. Start the session

```
cd ~/code/my-new-project
claude
```

Claude reads `CLAUDE.md` on session start and runs the **FIRST ACTIONS
flow** (four steps, documented in `CLAUDE.md`):

- **Step 0 — Issue-feedback opt-in (asked first).** `tech-lead` asks
  atomically whether you want framework gaps filed upstream as issues.
  Asked first because Steps 1–2 themselves are prime sources of
  feedback.
- **Step 1 — Skill packs.** Claude shows a catalog of skill packs and
  waits for you to pick any you want installed.
- **Step 2 — Project scoping + SME discovery.** `tech-lead` asks one
  question per turn (never a multi-question bundle) about the project,
  which SME domains it needs, which you hold, and which need external
  recruiting. Only when Step 2's Definition-of-Done checklist is
  complete does `tech-lead` dispatch the first work subagent.
- **Step 3 — Agent naming (optional).** `tech-lead` offers a naming
  category (Muppets, composers, etc.) and maps teammate names onto
  the canonical roles.

## I already unzipped into my working directory — now what?

Two options:

1. **Repair in place** (new in v0.11.0). Run:

   ```
   scripts/repair-in-place.sh --dry-run   # preview first
   scripts/repair-in-place.sh             # apply
   ```

   The script strips template-only files (VERSION, CHANGELOG.md,
   CONTRIBUTING.md, LICENSE, migrations/, examples/, .github/),
   resets the project registers (`docs/OPEN_QUESTIONS.md`,
   `CUSTOMER_NOTES.md`, `docs/AGENT_NAMES.md`) to empty stubs,
   stamps `TEMPLATE_VERSION`, seeds `.template-customizations`,
   and initialises git. Asks for confirmation before acting; won't
   run on a directory that is already scaffolded (has
   `TEMPLATE_VERSION` present).
2. **Scaffold a fresh directory.** Move your work aside, delete the
   unzipped directory, run `scripts/scaffold.sh` into a fresh target,
   then move your work back in. Use this if you want the project in
   a different path than where you unzipped.

Do not proceed with the unzipped-as-project state — the session will
compound the drift.

## Adopting the template into an existing codebase (retrofit)

New in **v0.13.0**. If you already have a real project (git history,
code, docs, issues) and want to bring it under this template without
rewriting from scratch, use the **Retrofit Playbook**:
`docs/templates/retrofit-playbook-template.md`.

There is no retrofit *script* — by design. The retrofit is an
**agent workflow** because every source project is shaped
differently; a script would have to assume a layout that does not
exist. The playbook orchestrates the template's agents to audit the
source, triage IP, plan the migration, reconstruct the charter, and
execute the moves.

### How to run a retrofit

1. **Scaffold a fresh target directory** with `scripts/scaffold.sh`
   (see Quickstart step 2). The target must be a **sibling** of
   your source project, not the source itself — the retrofit is
   scaffold-first, source-read-only by design (customer ruling
   2026-04-23).

   ```
   scripts/scaffold.sh ~/code/my-project-retrofit "My Project"
   ```

2. **Freeze the source project.** Do not edit the source during
   the retrofit; do not return to it afterward. The retrofit
   produces a new project at the target path; the source is
   archival once the retrofit completes.

3. **Start a Claude session in the new scaffolded target:**

   ```
   cd ~/code/my-project-retrofit
   claude
   ```

4. **Run FIRST ACTIONS Steps 0–1** (opt-in + skill packs) normally.
   Step 2 scoping opens the retrofit conversation.

5. **Tell `tech-lead` to run the Retrofit Playbook**, naming the
   source path:

   > "Run the Retrofit Playbook against source `~/code/my-project`."

   `tech-lead` then:
   - Runs **pre-flight** (readiness triage — VCS state, license,
     tests, CI, docs, secrets, issue tracker, size) and records
     a go/no-go.
   - Dispatches **Stage A `onboarding-auditor`** for a
     zero-context inventory of the source.
   - Dispatches **Stage B `researcher`** for IP triage; loops in
     **`security-engineer`** for any auth / secrets / PII /
     network-endpoint row (Hard-Rule-#7 advisory).
   - Dispatches **Stage C `architect`** for the structural
     migration plan; escalates any safety-critical artefact to
     you for live approval (Hard Rule #4).
   - Dispatches **Stage D `project-manager`** to reconstruct the
     charter from `git log` + README + interview.
   - Dispatches **Stage E `software-engineer`** to execute the
     moves commit-by-commit, gated by `code-reviewer` (and
     `security-engineer` on Hard-Rule-#7 rows).
   - Optionally dispatches **Stage F `project-manager`** to
     migrate source issues/tickets into `docs/tasks/` and
     `docs/OPEN_QUESTIONS.md`.

6. **Sign off on retrofit completion** when `tech-lead` presents
   the Definition-of-Done checklist from § 14 of the playbook.
   Your sign-off is recorded in `CUSTOMER_NOTES.md` and is the
   final gate before post-retrofit work begins.

### What if the retrofit stalls?

The playbook's § 12 rollback plan covers three outcomes:
**continue** (re-scope remaining stages), **pivot** (green-rewrite
with the source as a read-only reference), **roll back** (delete
the target; lessons carry-out file survives outside the target).
Rollback is cheap by design — the source is unaffected because of
the read-only freeze.

### What the playbook does *not* do

- **In-place retrofit** (layering the template onto the source
  tree itself). Rejected by design; see playbook § 2.2 for the
  reasoning (reversibility, clean audit surface, IP triage).
- **Multi-source retrofit** (N sources → 1 target). Deferred;
  file issue #45 tracks the reshape work needed.
- **`scripts/repair-in-place.sh` is not a retrofit tool** — it
  normalizes an *unzipped* template directory, nothing more.

Full procedure, decision matrix, anti-patterns, and DoD:
`docs/templates/retrofit-playbook-template.md`.

## Upgrading an existing scaffolded project

From inside your scaffolded project, on a later session:

```
scripts/upgrade.sh --dry-run   # preview the plan
scripts/upgrade.sh             # apply it
```

Upgrade rules: unchanged template files are overwritten with the new
version; project-customized files are left alone when upstream hasn't
changed, or flagged as conflicts when both have changed. Files listed
in `.template-customizations` are always preserved.

See `CLAUDE.md` § "Template version check + upgrade" for the full
contract, including per-version migration scripts under `migrations/`.

## What's in here

| Path | What it is |
|---|---|
| `CLAUDE.md` | Project guide; Claude reads this every session. |
| `CUSTOMER_NOTES.md` | Append-only log of customer answers, stewarded by `researcher`. |
| `SW_DEV_ROLE_TAXONOMY.md` | Reference taxonomy (SWEBOK / ISO 12207 / IEEE 1028 / ISTQB / SFIA v9 / Google SRE / PMBOK) that CLAUDE.md cites. |
| `docs/glossary/ENGINEERING.md` | **Binding** generic software-engineering terminology. All agents use these senses. |
| `docs/glossary/PROJECT.md` | **Binding** project-specific jargon (customer-domain, vendor, site, codenames). |
| `docs/AGENT_NAMES.md` | Canonical role → teammate name → pronouns mapping (agent-teams panel). |
| `docs/OPEN_QUESTIONS.md` | Register of open questions, with answerer and status. |
| `docs/INDEX.md` | Table of contents for everything under `docs/` plus repo-root bindings. |
| `docs/ISSUE_FILING.md` | How to file framework-gap issues upstream; cites the template version. |
| `docs/agent-health-contract.md` | Agent liveness, health-check, and respawn contract. |
| `docs/versioning.md` | Versioning policy; criteria for returning to `v1.0.0-rc`. |
| `VERSION` | Current template version (SemVer). |
| `CHANGELOG.md` | Release history. |
| `LICENSE` | MIT — permissive; downstream projects may be closed-source. Not shipped in scaffolded projects; each project picks its own license. |
| `scripts/scaffold.sh` | Scaffolds a new downstream project from this template. |
| `scripts/upgrade.sh` | Upgrades a scaffolded project to a newer template version. |
| `scripts/version-check.sh` | Runs at session start; compares `TEMPLATE_VERSION` against upstream. |
| `scripts/agent-health.sh` | Assembles a ground-truth health-check packet for an agent. |
| `scripts/respawn.sh` | Stubs a handover brief for respawning a long-running teammate. |
| `docs/templates/` | Document templates shaped after the relevant standards (ISO/IEC/IEEE 29148 / 42010 / 12207, arc42, C4, INVEST). |
| `docs/templates/retrofit-playbook-template.md` | Agent workflow for adopting the template into an existing codebase (v0.13.0+). See README § "Adopting the template into an existing codebase". |
| `docs/templates/adr-template.md` | MADR 3.0-shaped ADR template with the **Three-Path Rule** (Minimalist / Scalable / Creative) (v0.13.0+). |
| `docs/adr/` | Template-level ADRs. `0001-context-memory-strategy.md` is also the canonical worked example for the ADR template. |
| `.claude/agents/*.md` | 13 specialist subagents + 1 SME template. |
| `docs/sme/` | SME reference material, per-domain. `INVENTORY.md` per domain; copyrighted items in `local/` (gitignored). |

### IP policy, in one line

Anything not created within the project is assumed copyrighted unless
the customer overrides that in `CUSTOMER_NOTES.md`. Copyrighted items
stay in `docs/sme/<domain>/local/` and are cited in the domain's
`INVENTORY.md`. See CLAUDE.md § IP policy.

## Agent roster

| Agent | Canonical role |
|---|---|
| `tech-lead` | Tech Lead + orchestrator + **sole human interface** |
| `project-manager` | PMBOK-aligned; owns charter, schedule, risk, stakeholders, change log, lessons |
| `architect` | Software Architect |
| `software-engineer` | Implementation / construction |
| `researcher` | Standards librarian + `CUSTOMER_NOTES.md` steward |
| `qa-engineer` | Test strategy, integration/system/acceptance testing |
| `sre` | Reliability + performance |
| `tech-writer` | User-facing documentation |
| `code-reviewer` | Pre-commit review + IEEE 1028-style audit |
| `release-engineer` | Build pipeline + packaging + releases |
| `security-engineer` | Software-security ownership (SWEBOK V4 ch. 13) |
| `onboarding-auditor` | Zero-context documentation auditor (one-shot, milestone-close) |
| `process-auditor` | Cultural-disruptor process auditor (one-shot, every 2–3 milestones) |
| `sme-<domain>` (×N) | Per-project domain experts, created in Step 2 |

## The escalation model in one line

**`tech-lead` is the only agent that talks to the human.** Every other
agent, when stuck, first checks `CUSTOMER_NOTES.md`, then routes to
another specialist agent, and only escalates to `tech-lead` as a last
resort. Customer answers land in `CUSTOMER_NOTES.md` verbatim so the
team doesn't re-ask.

## Customizing

- **Per-project SMEs:** `tech-lead` proposes these in Step 2. Each SME
  becomes `.claude/agents/sme-<domain>.md` based on `sme-template.md`.
- **Additional specialists:** add a new `.claude/agents/<role>.md` and
  wire it into `tech-lead.md`'s routing table so `tech-lead` knows
  when to delegate to it.
- **Skills:** the Step 1 menu proposes curated skill packs; install
  whatever fits the project's stack. You can add items inline.

## Filing upstream issues

When the team hits a gap in this framework (missing agent, weak
routing, unclear rule, missing or wrong template) while working on
your project, `tech-lead` can file an issue against this upstream
repo — citing the `TEMPLATE_VERSION` your project was scaffolded
from — so a future version can fix it.

See `docs/ISSUE_FILING.md` for the filing protocol. Opt-in is asked
as Step 0 of the FIRST ACTIONS flow; project-identifying information
is **not** included in upstream issue bodies.

## Philosophy

- Claude already knows how to write code. The scaffold's job is to
  give it explicit role boundaries, prevent context drift, and
  protect the customer's attention.
- One role = one agent. Small overlap acknowledged (see
  `SW_DEV_ROLE_TAXONOMY.md` § 3 heatmap); silent overlap is a bug.
- Customer rulings are binding; agent opinions are advisory.

## License

MIT. See `LICENSE`. Downstream projects scaffolded from this template
pick their own license; the MIT grant on the template does not infect
scaffolded projects.
