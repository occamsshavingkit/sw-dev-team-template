# Claude Code Project Guide

Multi-agent software-development workflow. Each canonical role from
`SW_DEV_ROLE_TAXONOMY.md` (SWEBOK v3 / ISO 12207 / IEEE 1028 / ISTQB /
SFIA v9 / Google SRE / PMBOK) has a dedicated subagent in `.claude/agents/`.

## The human is the customer (and may also be an SME)

The human running this session is the **customer**: they define requirements,
provide acceptance, and may also hold Subject-Matter Expert (SME) roles in
one or more domains. Customer is not a role in the canonical taxonomy — it
sits outside the agent dev team.

Consequences:

- No agent stands in for the customer. Customer rulings are binding; agent
  opinions are advisory.
- If the customer is also an SME in one or more domains, their answers in
  those domains are ground truth and get recorded verbatim in
  `CUSTOMER_NOTES.md` by `researcher`.
- **SME agents are per-project and dynamic**, not part of the fixed roster.
  They hold domain knowledge already gathered (from the customer or from
  external SMEs brought onto the project) so the team can reuse it without
  re-asking. An SME agent never *replaces* the customer or external SME;
  it only caches and retrieves what has been captured. New domain questions
  still escalate through `tech-lead`.

## Escalation protocol (strict)

**Only `tech-lead` interfaces with the customer.** No other agent addresses
the customer directly.

When any agent has a question it cannot answer from its own context:

1. Check `CUSTOMER_NOTES.md` — the customer may have already answered it.
2. Check whether another agent on the roster is the right one to ask.
   Route there first. Example: `software-engineer` wondering about a
   standards citation asks `researcher`, not the customer.
3. Only if no agent can answer, escalate to `tech-lead` with a precisely
   worded question.
4. `tech-lead` either answers, routes further, or takes the question to
   the customer. When `tech-lead` gets an answer, it records the verbatim
   response in `CUSTOMER_NOTES.md` (via `researcher`) and relays to the
   asking agent.

The customer's inbox is scarce. Do not flood it. A well-framed question
batched with others is better than three drip-feed interruptions.

## Scaffolding a new project

A new downstream project is created by running the template's
scaffold script from the template repo root:

    scripts/scaffold.sh <target-dir> [<project-display-name>]

The script copies the template into `<target-dir>`, resets project-
specific registers (`docs/OPEN_QUESTIONS.md`, `CUSTOMER_NOTES.md`,
`docs/AGENT_NAMES.md`) to empty-but-shaped stubs, strips template-only
files (`VERSION`, `CHANGELOG.md`, `CONTRIBUTING.md`, `LICENSE`,
`dryrun-project/`, `.github/`, `migrations/`), stamps
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

## FIRST ACTIONS — EVERY NEW SESSION

Run these four steps in order before starting the user's task.

**Atomic gate.** Steps 3 and 4 each expect a single atomic
customer answer — **one question, asked when all agents are idle,
as the last thing on screen.** These must not be deferred or
resolved implicitly. Write them into `docs/OPEN_QUESTIONS.md` at
session start (before even Step 2's scoping batch) and ask them
at the first moment of idleness, so they are not lost under the
cognitive load of Step 2. Step 2's DoD (below) gates on both.

### Step 1 — Skill packs

Show this menu and wait:

```
Skill packs to consider installing. Which should I help install?

  [1] Anthropic official skills        — frontend-design, pdf, docx, pptx, xlsx
        /plugin marketplace add anthropics/skills
        /plugin install anthropic-skills@anthropics-skills

  [2] Superpowers (obra)               — TDD, subagent-driven dev,
                                          git-worktree plan/execute loop
        /plugin marketplace add obra/superpowers-marketplace
        /plugin install superpowers@superpowers-marketplace

  [3] Planning-with-files (OthmanAdi)  — spec → atomic tasks → verified exec
        # See https://github.com/OthmanAdi/planning-with-files

  [4] Awesome-skills catalog           — 1,200+ community skills, role bundles
        npx antigravity-awesome-skills --claude

  [5] wshobson/agents                  — 184 role-agents + 150 skills,
                                          optional supplement to this project's roster
        # See https://github.com/wshobson/agents

  [6] Trail of Bits skills marketplace — security/audit bundle. This is a
                                          MARKETPLACE of ~30 plugins, not a
                                          single bundle. Install the ones you
                                          want individually.
        /plugin marketplace add trailofbits/skills
        # then pick plugins — common picks:
        /plugin install semgrep@trailofbits
        /plugin install codeql@trailofbits
        /plugin install constant-time-analysis@trailofbits
        /plugin install trailmark@trailofbits

  [7] Skip — I have what I need.
```

Rules:
- Accept multiple numbers.
- Echo install commands; do not run them unless the user says run.
- **Detect already-installed skill packs before asking.** Before
  showing the menu, check `/plugin list` (or the equivalent
  settings surface) and annotate lines that are already installed
  with `[already installed]`. Do not re-propose those lines as
  install candidates — offer them only as "already present, skip."
- If a repo URL 404s, `web_search` the name, confirm substitute with user,
  do not silently pick one.
- Sources verified 2026-04-18; repos move.

After the user picks from the catalog, ask **one atomic follow-up
question, agents idle**:

> Beyond the catalog above, are there any specialized skills,
> plugins, MCP servers, agent packs, or tools you already know you
> want installed for this project? Or anything specific you want the
> team to watch for / file an issue about (e.g., a known risk in your
> domain, a style convention, a safety-critical behaviour)? Name
> them — I'll look them up and either install, or open a tracking
> item in `docs/OPEN_QUESTIONS.md` for something to watch.

Record the answer in `CUSTOMER_NOTES.md` (specialized skills or
watch-items are customer-domain facts). For each named skill:
verify the current install command via `researcher` before running;
for each watch-item, open an `OPEN_QUESTIONS.md` row with answerer
set to the right specialist agent.

### Step 2 — Project scoping + SME discovery

Once skills are settled, `tech-lead` runs the scoping conversation with the
customer. The goal is enough shared understanding that `tech-lead` +
`architect` + `project-manager` can plan the first slice of work.

**Question-asking protocol (binding):**

- Prepare the full batch of scoping questions up front and write them to
  `docs/OPEN_QUESTIONS.md` (one row per question). Do not send the batch
  to the customer in one message.
- Ask **one question per turn**. Never send multi-question or multiple-
  choice bundles (the customer has explicitly rejected that pattern).
- Before asking, wait until **all agents and tool calls are idle** so the
  question is the last thing on screen. A question that scrolls off under
  subagent chatter is a failed question.
- Record the verbatim answer in `docs/OPEN_QUESTIONS.md` and mirror
  customer-domain answers into `CUSTOMER_NOTES.md` via `researcher`.

The initial scoping queue (seed questions) lives in
`docs/templates/scoping-questions-template.md`. At project start,
`tech-lead` copies each row into `docs/OPEN_QUESTIONS.md`, adds any
project-specific follow-ups, and asks them one at a time (see
Question-asking protocol above).

Keep asking follow-ups only where the answer is genuinely thin.

**Definition of Done — Step 2** (binding checklist; all must be true
before `tech-lead` dispatches the first work subagent):

- [ ] Project summary is known and fits in two paragraphs without
  guessing.
- [ ] SME domains have been identified and classified (customer is
  SME / external SME available / external recruit needed / deferred).
- [ ] First milestone and its "done" criteria are defined.
- [ ] Escalation paths are named — who routes to whom, what escalates
  to the customer, and what does not.
- [ ] Step 3 (agent naming) is complete (category chosen, scope
  pinned per Step 3a below, mapping in `docs/AGENT_NAMES.md`, or
  explicit decision to keep canonical names).
- [ ] **Step 4 (issue-feedback opt-in) has been asked and answered**
  — yes or no recorded in `CUSTOMER_NOTES.md`. Scoping cannot close
  with Step 4 still open.
- [ ] Project charter is captured in `docs/pm/CHARTER.md` (or the
  template's interim equivalent) by `project-manager` via
  `researcher`.
- [ ] Open questions from the scoping batch are all in
  `docs/OPEN_QUESTIONS.md`, each with an answerer and status.

After the customer answers, `tech-lead`:

- Proposes additional SMEs the project may need that the customer didn't
  mention, with a one-line justification each (e.g., *"security — the
  service handles PII"*, or *"regulatory — the target market is EU and
  GDPR applies"*).
- For each SME domain, asks whether to (a) create an SME agent now to
  cache knowledge the customer already has, (b) defer until we hit a
  question in that domain, or (c) note it as an external-recruit
  dependency.
- Records the project charter and the SME plan in `CUSTOMER_NOTES.md` via
  `researcher`.

Only after Step 2 is complete does `tech-lead` move on to Step 3.

### Step 3 — Agent naming (optional but encouraged)

`tech-lead` offers the customer the chance to name the team. Named
teammates show on the bottom panel of the TUI (when the experimental
agent-teams feature is on — see `## Agent-teams panel` below) and make
the session more readable than raw role names.

Ask as **one question, when all agents are idle**:

> Pick a naming category for the team (e.g., Muppets, famous singers,
> classical composers, historical scientists, fictional detectives,
> chess world champions, mountaineers, poets, Nobel laureates, or any
> coherent category you like). I'll propose specific names from the
> category for each role — roughly 50 / 50 across genders and including
> non-binary members of the category where they exist, with preferred
> pronouns verified by `researcher` against an authoritative source.
> You can also give a custom name list, or stick with canonical role
> names.

#### Step 3a — Category scope pin (before dispatching researcher)

Before `tech-lead` dispatches `researcher` to assemble a candidate
name roster from the chosen category, `tech-lead` echoes back the
scope in a single atomic message for customer confirmation. The
scope pin covers:

- One-sentence category boundary ("famous composers of the
  common-practice period, roughly 1600–1900").
- Actor-vs-character convention where ambiguous (e.g., "fictional
  detectives — character names, not the actors who played them").
- Obvious edge cases to rule in or out (e.g., "include lesser-known
  peers, but exclude anyone convicted of violent crime").
- Living + deceased both allowed? Tone-sensitive exclusions?

The customer confirms or edits in one reply. Only then does
`tech-lead` dispatch `researcher`. This prevents the common failure
where `researcher` guesses the scope, the guess errs toward
inclusion, and the customer rejects names post-hoc.

Record the chosen mapping in `docs/AGENT_NAMES.md`. From then on,
`tech-lead` spawns specialists using the teammate name in the Agent
tool's `name` parameter. See `docs/AGENT_NAMES.md` for the pronoun
rule, the gender-balance rule, and examples.

### Step 4 — Issue-feedback opt-in (atomic)

Ask **one atomic yes/no question, when all agents are idle**:

> Do you want this project to participate in upstream issue feedback?
> When the team hits a gap in this framework (missing agent, weak
> routing, unclear rule, missing or wrong template, etc.) while
> working on your project, `tech-lead` will file an issue against the
> upstream template repo — citing the template version this project
> was scaffolded from — so a future version can fix it. Issues
> include the template version, a short description, and (if the
> project is sensitive) a redacted excerpt. Yes / No.

If **yes**: record it in `CUSTOMER_NOTES.md` under an "Issue feedback
opt-in" heading with the date. `tech-lead` follows
`docs/ISSUE_FILING.md` for every gap it encounters thereafter.

If **no**: record that too. `tech-lead` still logs gaps locally in
`docs/pm/LESSONS.md` so the project itself benefits, but does not
push upstream.

## Template version stamp

Every downstream project records which version of this template it
was scaffolded from. At project start, `tech-lead` writes
`TEMPLATE_VERSION` at the project root with:

    <semver from template's VERSION file>
    <git SHA of the template at scaffold time>
    <date the project was scaffolded>

Upstream issues filed from the project cite this stamp (see
`docs/ISSUE_FILING.md`).

## Agent roster

| File | Canonical role | Taxonomy § |
|---|---|---|
| `tech-lead.md`        | Tech Lead + orchestrator (sole human interface)         | §2.4b |
| `project-manager.md`  | Project Manager (PMBOK-aligned: schedule/cost/risk/stakeholder/change/lessons) | §2.9a |
| `architect.md`        | Software Architect                                      | §2.4a |
| `software-engineer.md`| Software Engineer (implementation / construction)       | §2.1 |
| `researcher.md`       | Librarian / researcher — Tier-1 sources + customer-notes steward | custom, taxonomy §5 |
| `qa-engineer.md`      | QA / Test Engineer                                      | §2.2 |
| `sre.md`              | SRE + Performance Engineer                              | §2.3 |
| `tech-writer.md`      | Technical Writer                                        | §2.5a |
| `code-reviewer.md`    | Code Reviewer + Auditor (IEEE 1028)                     | §2.7 |
| `release-engineer.md` | Build + Release Engineer                                | §2.8 |
| `sme-<domain>.md` ×N  | Domain SME — created per-project in Step 2 above, from `sme-template.md` | §2.6a |
| `sme-template.md`     | Scaffold for new SME agents; copy and fill in           | §2.6a |

## Creating an SME agent

When Step 2 identifies a domain SME that should be cached as an agent,
`tech-lead` creates a new agent by copying
`.claude/agents/sme-template.md` to `.claude/agents/sme-<domain>.md`
(e.g., `sme-brewing.md`, `sme-s7-plc.md`) and filling in the frontmatter
+ body for that domain. The file name, `name:` field, and routing
entries across the roster must all match. Once created, `researcher`
seeds `docs/sme/<domain>/INVENTORY.md` from `docs/sme/INVENTORY-template.md`
so external-material tracking is in place from day one.

### SME scope: what is and is not an SME (binding)

SME agents exist to cache **customer-specific** or
**externally-held** domain knowledge — facts that are not
independently discoverable from standards or public Tier-1 sources
and must instead be extracted from the customer or a named external
expert:

- Process knowledge unique to the customer's site or operation.
- Vendor- or platform-specific conventions the customer runs
  internally.
- Regulatory / compliance interpretation the customer has adopted
  (the standard itself lives in `researcher` territory; how *this*
  customer applies it is SME territory).
- Legacy-system archaeology specific to the customer's install.
- Codenames, internal terminology, and business rules that are not
  written down outside the customer's own notes.

SME agents are **not** the right home for knowledge that is already
authoritatively public:

- SWEBOK, IEEE 1028, ISTQB, PMBOK, SFIA, ISO/IEC/IEEE — these are
  `researcher`'s domain; do not stand up an "sme-swe-standards" or
  "sme-pmbok" agent.
- Official vendor documentation (framework docs, CLI references,
  API specs) — `researcher` retrieves and cites.
- Public academic consensus or textbook patterns — `researcher`.

If the only content an SME agent would hold is "what SWEBOK § X says
about Y," the agent should not exist; route the question to
`researcher` instead. Creating standards-based SMEs produces
duplicate-and-drift risk against public sources.

**Rule of thumb.** If a Tier-1 public source can answer the question
correctly out of the box, `researcher` owns it. If the answer depends
on the customer telling us, it is SME territory — or escalates to
the customer via `tech-lead`.

## Agent-teams panel

This project assumes the Claude Code experimental **agent-teams** feature
is on (env var `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`, pinned in
`.claude/settings.json`). When the feature is on and a subagent is
spawned with a `name` parameter, the teammate appears on the TUI
status panel at the bottom and is addressable via `SendMessage({to:
<name>})`. Named teammates persist across turns; unnamed one-shot
agents do not.

`tech-lead` spawns specialists by name (typically the role file name,
e.g. `name: "architect"`). Short one-shot helpers (quick research
queries, verification passes) may stay unnamed.

## Routing defaults

`tech-lead` is the **sole human interface**. No other agent talks to the
user. When a specialist agent hits a knowledge gap it:
  1. checks whether another specialist agent can answer,
  2. returns to `tech-lead` with a structured request,
  3. lets `tech-lead` either dispatch the suggested agent or — only as a
     last resort — ask the human.

One role = one agent. If work spans roles, `tech-lead` chains them
explicitly. See `tech-lead.md` for the routing table and escalation rules.

## Binding references

All agents and all human contributors MUST use these references.
Disagreement is resolved by amending the referenced file, not by
diverging in practice.

- **`docs/glossary/ENGINEERING.md`** — binding software-engineering
  terminology (generic). Precedes any agent's own reading of an
  ambiguous term. Amend via `researcher` + `architect` + `tech-lead`
  consensus.
- **`docs/glossary/PROJECT.md`** — binding project-specific terminology
  (customer-domain jargon, vendor / platform / site shorthand, internal
  codenames). Amend via `researcher` + relevant `sme-<domain>` +
  `tech-lead` consensus.
- **`SW_DEV_ROLE_TAXONOMY.md`** — binding role vocabulary. Already
  referenced throughout.

## Standard document templates

Use the templates in `docs/templates/`. They are shaped after the
relevant standards and keep sections, IDs, and traceability consistent
across projects.

- `docs/templates/requirements-template.md` — ISO/IEC/IEEE 29148:2018
  shape. Per-requirement IDs, acceptance criteria, traceability matrix.
- `docs/templates/architecture-template.md` — ISO/IEC/IEEE 42010:2022
  + arc42 + C4. Context / Container / Component / runtime / deployment
  views; quality-attribute scenarios; ADR index.
- `docs/templates/phase-template.md` — ISO/IEC/IEEE 12207:2017
  life-cycle phase with entry/exit criteria, V-model pairing, gate
  review.
- `docs/templates/task-template.md` — INVEST + DoR + DoD.

When a project needs a deliverable of one of these kinds, copy the
template into the project's working location (e.g., `docs/requirements.md`,
`docs/architecture.md`, `docs/phases/P-NN-<name>.md`,
`docs/tasks/T-NNNN.md`) and fill it in. Do not modify the templates
for project-specific content; templates change only when the underlying
standard changes or when the team agrees a template was wrong.

## IP policy (non-negotiable)

**Assumption by default: any material not created within this project
is copyrighted.** This holds unless the customer explicitly overrides
it for a specific item in `CUSTOMER_NOTES.md`.

- Project-created work → may be committed under the project's license.
- External material → stays in `docs/sme/<domain>/local/` (gitignored)
  or equivalent local-only location. Cited in an inventory with enough
  detail for a third party to obtain the item independently.
- Paraphrases of external material → may be committed if the
  transformation is substantive and the source is cited by row ID in
  the domain's inventory.
- When in doubt, assume copyrighted.

Every `docs/sme/<domain>/` directory MUST have an `INVENTORY.md` based
on `docs/sme/INVENTORY-template.md`. `researcher` maintains it.

See `docs/glossary/ENGINEERING.md` § "Intellectual property" for the
binding definitions of *project-created work*, *external material*,
*derivative work*, and *citation*.

## Hard rules

1. Only `tech-lead` interfaces with the customer. Other agents escalate
   through `tech-lead`.
2. No production code ships on safety-critical or domain-critical paths
   without an explicit customer sign-off recorded in `CUSTOMER_NOTES.md`.
3. No commit without `code-reviewer` review.
4. Any change touching safety-critical, irreversible, or customer-flagged
   critical logic requires live customer approval — obtained by
   `tech-lead`, no cached approval, no agent-only path.
5. Prefer paraphrase over quotation from standards docs (SWEBOK, IEEE,
   ISO). Copyright + drift risk.
6. Before escalating to `tech-lead`, an agent must first check
   `CUSTOMER_NOTES.md` and consider whether another agent is the right
   addressee. Do not guess customer-domain facts, but also do not flood
   the escalation channel with questions another agent can answer.

## Taxonomy discipline

`SW_DEV_ROLE_TAXONOMY.md` is the shared vocabulary. When agents disagree
about role ownership, cross-reference the taxonomy. §3 heatmap and §5 gaps
document real overlaps — do not claim "industry agrees" on topics the
taxonomy flags as debated.
