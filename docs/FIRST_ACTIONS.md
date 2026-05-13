# FIRST ACTIONS — EVERY NEW SESSION

> Source: extracted from CLAUDE.md (v1.0.0-rc7) per issue #120.

Run these steps in order before starting the user's task.

**Atomic gate.** Every seed scoping question in this document holds to
**one decision axis per question** (FR-010). Compound forms like "what
are we building, for whom, on what stack, and what counts as done?" are
decomposed into separate atomic questions before they reach the
customer. The canonical question-batching rule (binding, identical
wording in `CLAUDE.md`, `.claude/agents/tech-lead.md`,
`docs/OPEN_QUESTIONS.md`, and `docs/templates/intake-log-template.md`):

> Batch questions internally in docs/OPEN_QUESTIONS.md.
> Do not batch customer-facing questions.
> Ask one queued customer question per turn, only when all agents and tools are idle, with the question as the final line.

The Customer Question Gate (FR-011) in `.claude/agents/tech-lead.md`
serialises delivery against that rule. Step 0 and Step 3 each expect a
single atomic customer answer and must not be deferred or resolved
implicitly. Step 2's DoD (below) gates on both.

## Step 0 — Issue-feedback opt-in (atomic, asked FIRST)

Before the skill-pack menu, before scoping, before anything else,
ask **one atomic yes/no question**:

> Do you want this project to participate in upstream issue feedback?
> When the team hits a gap in this framework (missing agent, weak
> routing, unclear rule, missing or wrong template, etc.) while
> working on your project, `tech-lead` will file an issue against
> the upstream template repo — citing the template version this
> project was scaffolded from — so a future version can fix it.
> Issues include the template version, a short description, and
> (if the project is sensitive) a redacted excerpt. Yes / No.

This is Step 0 specifically because the **earliest** steps
(Step 1 skills menu, Step 2 scoping) are themselves prime
sources of feedback. Asking opt-in at the end would miss any
gap the team hits while running the first steps.

If **yes**: route the verbatim answer to `researcher`, who appends
it to `CUSTOMER_NOTES.md` under an "Issue feedback opt-in" heading
with the date. `tech-lead` follows `docs/ISSUE_FILING.md` for every
gap it encounters thereafter, including gaps in Steps 1–3.

If **no**: route that verbatim answer to `researcher` too.
`tech-lead` still logs gaps locally in `docs/pm/LESSONS.md` so the
project itself benefits, but does not push upstream.

## Step 1 — Skill packs

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
        /plugin install semgrep-rule-creator@trailofbits
        /plugin install semgrep-rule-variant-creator@trailofbits
        /plugin install static-analysis@trailofbits
        /plugin install constant-time-analysis@trailofbits
        /plugin install trailmark@trailofbits

  [7] context-optimization            — keep context necessary and sufficient
        npx skillfish add jbdamask/john-claude-skills context-optimization

  [8] token-usage                      — report per-turn token usage so PM can
                                          budget and estimate
        npx skillfish add kmylpenter/kfg-ccv2-installer-stable token-usage

  [9] claude-mem (thedotmack)          — RECOMMENDED default memory layer.
                                          Passive session summarization +
                                          searchable observations via MCP.
                                          Binding integration points in
                                          CLAUDE.md § Escalation protocol,
                                          tech-lead.md, and researcher.md
                                          already assume it is installed.
                                          See docs/adr/fw-adr-0001-context-memory-strategy.md.
        /plugin marketplace add thedotmack/claude-mem
        /plugin install claude-mem@thedotmack

       **Known caveat (issue #113):** claude-mem currently appends a
       `<claude-mem-context>` block to `AGENTS.md` on each session.
       `AGENTS.md` is now a framework-shipped file (Codex adapter) and
       the appended block creates manifest drift on every template
       upgrade. Workaround until upstream adds a redirect knob: add
       `AGENTS.md` to `.template-customizations` after first install.
       The next `scripts/upgrade.sh` will preserve your local version.
       Track upstream feature request:
       https://github.com/thedotmack/claude-mem/issues/2333

       Note on orchestration frameworks (ruflo / ex-claude-flow,
       CrewAI, AutoGen, MetaGPT, etc.): NOT on this menu by design.
       They ship their own agent roster, router, and escalation
       model, which collide with Hard Rules #1 and #4. If a project
       genuinely needs one, record a superseding ADR first per
       `docs/MEMORY_POLICY.md`.

  [10] Skip — I have what I need.
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
- Sources verified 2026-05-06; repos move.

After the user picks from the catalog, queue these atomic follow-ups
into `docs/OPEN_QUESTIONS.md` and ask them **one at a time, agents
idle**:

> Beyond the catalog above, are there specialized skills, plugins,
> MCP servers, agent packs, or tools you already know you want
> installed for this project? Name them — I'll look them up and
> either install or open a tracking item.

> Is there anything specific you want the team to watch for or file
> an issue about (e.g., a known risk in your domain, a style
> convention, a safety-critical behaviour)? Name it — I'll open a
> tracking item in `docs/OPEN_QUESTIONS.md`.

Route each verbatim answer to `researcher` for a `CUSTOMER_NOTES.md`
entry (specialized skills and watch-items are customer-domain facts).
For each named skill: verify the current install command via
`researcher` before running; for each watch-item, open an
`OPEN_QUESTIONS.md` row with answerer set to the right specialist
agent.

## Step 2 — Project scoping + SME discovery

Once skills are settled, `tech-lead` runs the scoping conversation with the
customer. The goal is enough shared understanding that `tech-lead` +
`architect` + `project-manager` can plan the first slice of work.

### Question-asking protocol (binding)

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
- [ ] Deliverable shape is defined and customer-ratified: code
  (library / CLI / service / agent), data (dataset / model / corpus),
  artefact (document, skill, playbook, prompt, runbook), process
  (procedure humans or AI follow), or hybrid. Every named deliverable
  has an owner role and target path or repository location.
- [ ] Customer-domain terms used in the deliverable definition are
  defined in `docs/glossary/PROJECT.md` before any agent designs
  against them.
- [ ] SME domains have been identified and classified (customer is
  SME / external SME available / external recruit needed / deferred).
- [ ] First milestone and its "done" criteria are defined.
- [ ] Escalation paths are named — who routes to whom, what escalates
  to the customer, and what does not.
- [ ] Step 3 (agent naming) is complete (category chosen, scope
  pinned per Step 3a below, mapping in `docs/AGENT_NAMES.md`, or
  explicit decision to keep canonical names).
- [ ] **Step 0 (issue-feedback opt-in) has been asked and answered**
  — yes or no routed to `researcher` and appended to
  `CUSTOMER_NOTES.md`. Scoping cannot close with Step 0 still open.
  (Step 0 runs at session start, before the Step 1 skill menu, so
  this row is normally already satisfied by the time Step 2 reaches
  DoD; it remains in the DoD as a backstop against accidentally
  skipping it.)
- [ ] Project charter is captured in `docs/pm/CHARTER.md` (or the
  template's interim equivalent) by `project-manager` via
  `researcher`.
- [ ] Team charter is captured in `docs/pm/TEAM-CHARTER.md` (PMBOK 8
  §2.6 Plan Resource Management output). Captures team values,
  decision-making, conflict resolution, communication cadence.
- [ ] AI use policy is captured in `docs/pm/AI-USE-POLICY.md` (PMBOK
  8 Appendix X3). Customer has ratified the strategy (Automation /
  Assistance / Augmentation) for each AI-involved task class before
  any AI-mediated work begins.
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
- Echoes back the ratified deliverable shape and glossary entries in
  the project charter or scoping transcript so later `code-reviewer`
  passes can check output-vs-intent conformance.

Only after Step 2 is complete does `tech-lead` move on to Step 3.

## Step 3 — Agent naming (optional but encouraged)

`tech-lead` offers the customer the chance to name the team. Named
teammates show on the bottom panel of the TUI (when the experimental
agent-teams feature is on — see `CLAUDE.md` § "Agent-teams panel") and make
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

### Step 3a — Category scope pin (before dispatching researcher)

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
- Are living members of the category allowed?
- Are deceased members of the category allowed?
- Are there tone-sensitive exclusions to apply?

The customer confirms or edits in one reply. Only then does
`tech-lead` dispatch `researcher`. This prevents the common failure
where `researcher` guesses the scope, the guess errs toward
inclusion, and the customer rejects names post-hoc.

Record the chosen mapping in `docs/AGENT_NAMES.md`. From then on,
`tech-lead` spawns specialists using the teammate name in the Agent
tool's `name` parameter. See `docs/AGENT_NAMES.md` for the pronoun
rule, the gender-balance rule, and examples.
