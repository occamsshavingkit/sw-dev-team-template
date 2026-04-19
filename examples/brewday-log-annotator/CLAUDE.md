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

## FIRST ACTIONS — EVERY NEW SESSION

Do these two things in order before starting the user's task.

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

  [6] Trail of Bits skills             — security/audit bundle (semgrep, codeql,
                                          trailmark, constant-time-analysis,
                                          zeroize-audit, entry-point-analyzer, …)
        /plugin marketplace add trailofbits/skills
        /plugin install trailofbits-skills@trailofbits-skills

  [7] Skip — I have what I need.
```

Rules:
- Accept multiple numbers.
- Echo install commands; do not run them unless the user says run.
- If a repo URL 404s, `web_search` the name, confirm substitute with user,
  do not silently pick one.
- Sources verified 2026-04-18; repos move.

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
- [ ] Step 3 (agent naming) is complete (category chosen, mapping in
  `docs/AGENT_NAMES.md`, or explicit decision to keep canonical names).
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

Record the chosen mapping in `docs/AGENT_NAMES.md`. From then on,
`tech-lead` spawns specialists using the teammate name in the Agent
tool's `name` parameter. See `docs/AGENT_NAMES.md` for the pronoun
rule, the gender-balance rule, and examples.

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
