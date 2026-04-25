# Process Audit — 2026-04-25 — sw-dev-team-template upstream

**Auditor:** process-auditor (one-shot, full-history)
**Scope:** binding rules, ceremonies, and required artefacts shipped
by the template itself as of 2026-04-25 / VERSION v0.17.0.
**Milestone context:** v1.0.0-rc3 re-entry checklist criterion C-5
("audit agents exercised"). Sibling run against QuackPLC happens in
parallel.
**Companion run:** the user noted the QuackPLC run as the second of
the two C-5 runs.

---

## Summary

- Findings total: **9**
  - Process Debt: 2 (F-002, F-009)
  - Ceremony without payoff: 4 (F-001, F-003, F-005, F-007)
  - Redundant check: 3 (F-004, F-006, F-008)
- Disposition proposals span keep / retire / refactor / defer; none
  unilateral. All findings route to `tech-lead` (main session) for
  ratification before any rule change.

The template is at an inflection point. It has just shipped v0.17.0
and is heading into v1.0.0-rc3. Most of the rituals on the books
were written in the v0.11–v0.15 window in response to specific
incidents in *downstream* projects, then back-ported here. Several
of those rituals never had to fire on this repo — the upstream is
maintained by one person plus subagents, with no live customer who
needs the ceremony's safety properties. That is the dominant
audit signature.

A second pattern is visible: the framework has spent the last
seven minor releases reasoning about *itself* (workflow pipeline,
agent-health contract, retrofit playbook, FW-ADRs, this audit).
Internal-loop ratio is healthy when it produces real downstream
fixes (it has, per the v0.14.x recovery work). It is an audit
warning when the only consumer of a new artefact is another
internal artefact.

The findings below are framed as **invitations to justify**. The
default is "rule stays" until the customer rules otherwise.

---

## Findings

### F-001 — Workflow-redesign v0.12 pipeline: empirical-usage gap on this repo

- **Class:** Ceremony without payoff (on the upstream repo
  specifically).
- **Rule:** `docs/proposals/workflow-redesign-v0.12.md` —
  five-stage pre-code pipeline (prior-art → three-path → proposal
  → duel → code), with mechanical §2 trigger and OR-clause set.
  Echoed in `tech-lead.md` Job #2 (lines 42–68) and as binding
  rules in `researcher.md` §5, `software-engineer.md`,
  `qa-engineer.md`.
- **Origin:** v0.12.0 (issues #32 / #33 / #34 / #35 composed by
  `architect` 2026-04-23). Three-Path landed v0.13.0; prior-art and
  proposal stages shipped v0.12.0; duel stage ratification status
  unclear in CHANGELOG.
- **Why added then:** prevent agent hallucination of library APIs
  (#34), force divergent thinking past LLM-mean answers (#33),
  surface design failures before code rather than at review (#35),
  externalise reasoning into reviewable artefacts (#32).
- **Why questioning now:**
  - **Current value unclear on this repo.** Per the v1.0-rc3
    checklist C-4 (line 88–109): "Three-path: green (7 ADRs in
    this repo already, plus the customer's downstream projects).
    Other three: pending downstream evidence." Translation: of
    the four pipeline stages, only one — the cheapest, the ADR
    extension — has fired on the template repo itself. **Zero
    `docs/prior-art/<task-id>.md` files exist** in this repo
    (search the directory tree — `docs/prior-art/` does not
    exist as a directory). **Zero `docs/proposals/<task-id>.md`
    files** exist beyond the meta-proposal that defined the
    pipeline. Zero duels recorded.
  - **Cost material?** The pipeline imposes a 4× pre-code token
    multiplier on triggered tasks per the memo's own §9.1
    estimate. On the template repo's own development this cost
    has been paid implicitly via the bundle of FW-ADRs (which
    *are* pipeline-shaped, just not labelled), but the explicit
    artefact classes (`docs/prior-art/`, `docs/proposals/`) are
    empty drawers.
  - **Redundant?** ADR trigger list in `architect.md` lines 28–43
    overlaps heavily with §2 trigger clauses (1)–(6); the memo
    itself acknowledges this in §3 and collapses three-path into
    the ADR. The proposal artefact partly duplicates a
    well-written ADR's "Decision" + "Consequences" sections.
- **Invitation:** of the four pipeline stages, only Three-Path
  has empirical usage on the upstream itself. Should the
  template publish stages 1, 3, and 4 as **stages downstream
  projects ratify per project**, with the upstream's own work
  exempted because the template is a single-author
  meta-project? Or should we run a deliberate v0.18.0 task
  through the full pipeline (e.g., the next contract-stable
  ADR) to populate the empty drawers and earn the ritual?
- **Proposal:** **defer-to-customer-decision.** Two reasonable
  paths: (a) keep the pipeline as binding for downstream
  projects only, scope-pin the upstream as exempt; (b) walk
  one v0.18.0 work item through the explicit pipeline so
  C-4's "downstream evidence" criterion is partially satisfiable
  from the upstream itself. Customer picks.
- **Route:** `tech-lead` → customer.

### F-002 — `docs/intake-log.md` + intake-conformance audit: never fires on the upstream

- **Class:** Process Debt.
- **Rule:** `tech-lead.md` Job #1 (line 28–38) *"append one entry
  to `docs/intake-log.md` per `docs/templates/intake-log-template.md`
  for every customer question — so `qa-engineer` can audit
  intake-flow conformance later via
  `docs/templates/qa/intake-conformance-template.md`."*
  `intake-log-template.md` carries five binding "hard rules" with
  per-turn YAML and an `agents-running-at-ask: []` invariant.
- **Origin:** intake-log template exists at
  `docs/templates/intake-log-template.md`. Intake-conformance
  audit shape at `docs/templates/qa/intake-conformance-template.md`.
  No `LESSONS.md` row in this repo (none exists yet); attributable
  by file dating to the v0.13–v0.14 window.
- **Why added then:** customer had explicitly rejected
  multi-question bundles; the conformance audit was meant to make
  that rejection mechanically detectable. The
  `agents-running-at-ask: []` invariant is the audit hook.
- **Why questioning now:**
  - **Current value unclear on the upstream.** This repo has no
    customer in the live-question sense — the customer is the
    repo owner, and customer turns are recorded in
    `docs/OPEN_QUESTIONS.md` (12 entries) plus `CUSTOMER_NOTES.md`.
    No `docs/intake-log.md` exists at the repo root. No
    `intake-conformance-<date>.md` audit has been produced.
  - **Cost material?** Maintaining the template + the conformance
    template + the `intake-show.sh` script (in `scripts/`) is
    real ongoing maintenance with no consumer on this repo.
  - **Redundant?** `docs/OPEN_QUESTIONS.md` already records every
    customer ask with answerer / status / verbatim resolution.
    `CUSTOMER_NOTES.md` records verbatim answers. The intake-log's
    only marginal value over those two is the
    `agents-running-at-ask: []` invariant — a single field — and
    the per-turn timestamp.
- **Invitation:** is `docs/intake-log.md` actually meant to be
  populated on the upstream repo, or is it a **downstream-only
  artefact** that the template should clarify is not expected on
  the upstream itself? If downstream-only, the agent contracts
  (tech-lead.md, qa-engineer.md, researcher.md) need a one-line
  scope-pin saying "applies in scaffolded projects, not in the
  template repo's own development."
- **Proposal:** **refactor.** Add a one-line scope-pin to
  `tech-lead.md` Job #1 and `intake-log-template.md` clarifying
  that the live intake-log lives in scaffolded projects; the
  template ships only the schema. Or, alternatively, retire the
  intake-log entirely if `OPEN_QUESTIONS.md` + `CUSTOMER_NOTES.md`
  + the new turn-ledger discipline are doing the same job
  (probability is high; investigate).
- **Route:** `tech-lead` → customer. If retire path chosen,
  `intake-log-template.md`, `qa/intake-conformance-template.md`,
  `scripts/intake-show.sh`, and the references in three agent
  contracts go together.

### F-003 — Agent-health-contract liveness windows + heartbeat: protocol with no incident record

- **Class:** Ceremony without payoff (suspected — verify).
- **Rule:** `docs/agent-health-contract.md` §2 signal 11 lines
  54–62 + §2 Liveness protocol lines 65–82 + §Heartbeat
  convention lines 84–112. Long-lived named teammates emit
  ≥10-minute heartbeats; tech-lead pings if silent past window;
  Red grade triggers respawn.
- **Origin:** v0.12.0 added the contract (closes upstream issue
  #13 per CHANGELOG line 148: *"v0.12.0 agent-health-contract +
  v0.13.0 liveness rules"*). Specific liveness/heartbeat additions
  in v0.13.0.
- **Why added then:** silent backgrounded subagent hangs were
  observed and feared — `tech-lead` would not know the difference
  between "still working" and "crashed."
- **Why questioning now:**
  - **Current value unclear?** No `LESSONS.md` row exists in this
    repo recording an incident where the heartbeat protocol
    caught a hang. No `docs/handovers/` directory exists.
    `docs/pm/LESSONS.md` does not exist as a file. The signal
    threshold ("≥3 in a week") and the windowed-ping ritual are
    detailed enough to be testable; their non-firing is testable
    too.
  - **Cost material?** Modest — adds prompt overhead per
    long-running dispatch. The prompt-overhead cost is per-task,
    cumulative across project lifetime.
  - **Redundant?** Partial — `code-reviewer` audit mode already
    catches role drift on diff outputs; the customer-audit
    backstop in §5.3 (ground-truth "what I believe is true"
    summary at milestone close) catches stale tech-lead state
    independent of liveness pings.
- **Invitation:** has the heartbeat / liveness protocol caught a
  silent hang in this repo's own development since v0.12.0?
  If yes, log the incident in `docs/pm/LESSONS.md` so the next
  process audit has evidence. If no, is the protocol earning
  its keep on the upstream, or is its real audience downstream
  projects with longer-running specialists?
- **Proposal:** **keep, with evidence-bar attached.** The cost is
  small enough that pre-emptive retirement is wrong. But the
  rule should require a `LESSONS.md` row at first fire so the
  next audit can verify earned-keep status. Alternative:
  scope-pin to "applies whenever a dispatch has
  `run_in_background: true` *and* expected runtime ≥10 min;
  silent on shorter dispatches" — which the contract already
  approximately says, but the rule could be tightened further.
- **Route:** `tech-lead` → customer (low-priority; no urgent
  action).

### F-004 — Three-Path Rule + ADR trigger list: redundant trigger surface

- **Class:** Redundant check.
- **Rule:** `architect.md` lines 28–69 — "ADR trigger list
  (binding)" (7 conditions) + "Three-Path Rule (binding,
  v0.13.0)" three-alternative requirement.
  `docs/proposals/workflow-redesign-v0.12.md` §2 "Trigger
  threshold" — six OR-clauses for pipeline trigger.
  `tech-lead.md` Job #2 "Trigger annotation" — six clauses.
- **Origin:** ADR trigger list — predates v0.12.0 (in
  `architect.md` from earlier; exact origin opaque without
  git-blame). Three-Path Rule — issue #33, v0.13.0. Pipeline
  trigger — issue #32+#33+#34+#35 composition memo, v0.12.0.
- **Why added then:** each was added separately to address its
  own observed gap. ADR trigger list predates the workflow
  redesign and has its own job (force ADR before code). Three-
  Path forces divergent options in the existing ADR. Pipeline
  trigger force-fires the prior-art and proposal artefacts.
- **Why questioning now:**
  - **Current value unclear?** No — each rule has a defensible
    purpose individually.
  - **Cost material?** Maintenance — three near-identical trigger
    lists drift independently. ADR trigger has 7 clauses; pipeline
    trigger has 6. The two lists overlap on items 1, 2, 3, 6 of
    the pipeline list (matching ADR triggers 2, 1, 5/6,
    not-quite-3) but are not byte-identical or clearly delta'd
    from each other.
  - **Redundant?** Yes, structurally. The workflow-redesign memo
    §3 acknowledges this and collapses three-path into the ADR.
    But it does NOT collapse the trigger lists themselves into a
    single citable "Trigger condition set" — they remain
    independent prose lists in two different files.
- **Invitation:** the workflow-redesign memo deliberately reused
  ADR trigger semantics (§2: *"each of (1)–(6) is already an
  independent ADR or Hard-Rule trigger elsewhere in the
  template"*). Should the two trigger lists be collapsed into
  a single canonical list (e.g., a `docs/glossary/ENGINEERING.md`
  entry "Trigger conditions, structural change") that both
  documents cite by reference, eliminating drift risk?
- **Proposal:** **refactor.** Single-source the trigger
  condition set. Either as a glossary entry (cleanest), or as a
  numbered list in `docs/proposals/workflow-redesign-v0.12.md`
  §2 with `architect.md` and `tech-lead.md` citing it by
  reference. v0.18.0 candidate.
- **Route:** `tech-lead` → customer (low-stakes refactor).

### F-005 — Step-3 (agent naming) + Step-3a (category scope pin): heavy ceremony for a cosmetic feature

- **Class:** Ceremony without payoff.
- **Rule:** `CLAUDE.md` Step 3 + Step 3a (lines 400–442).
  Step-3a (added per Q-0009 / customer ruling 2026-04-19) requires
  a separate atomic message confirming the category scope before
  `researcher` is dispatched to assemble the name roster.
- **Origin:** Step 3 — original FIRST ACTIONS design (predates
  v0.12.0). Step 3a — explicit customer ruling, captured at
  Q-0009 resolution and codified later. Q-0009 itself was for
  the upstream's own session (Muppets chosen).
- **Why added then:** Step 3a fixes the failure mode where
  `researcher` errs toward inclusion when guessing scope, and
  the customer rejects names post-hoc. Real failure on a real
  past session.
- **Why questioning now:**
  - **Current value unclear?** Step 3a's failure mode is real
    (customer ruling cites it). The cost is one extra atomic
    customer round-trip *per project* on a feature most projects
    use once.
  - **Cost material?** Low — one extra turn — but the question
    is whether the pin is *necessary* given the alternative
    of `researcher` making one *narrow* guess + customer
    reviewing the produced roster.
  - **Redundant?** Mildly. Step 3 itself already has the customer
    pick the category. Step 3a then has the customer confirm the
    scope of that category. The customer is being asked twice.
- **Invitation:** does the explicit Step-3a confirmation step
  prevent enough downstream rejection-loops to justify the
  extra customer turn on every project? Or has the post-hoc
  experience shown that `researcher` with one tightly-worded
  scope guess + customer reviewing the roster works equally
  well in fewer turns?
- **Proposal:** **defer-to-customer-decision.** Customer wrote the
  rule based on a real past failure. Don't unilaterally repeal.
  But ask: how often has the new step prevented the failure
  mode versus just adding a turn?
- **Route:** `tech-lead` → customer.

### F-006 — Memory-first lookup + four-layer escalation protocol: redundant when claude-mem absent

- **Class:** Redundant check.
- **Rule:** `CLAUDE.md` § Escalation protocol (lines 28–56) —
  five-step lookup chain: claude-mem → CUSTOMER_NOTES.md →
  another agent → tech-lead → customer. `tech-lead.md`
  § "Memory-first lookup (binding)" (lines 116–139).
- **Origin:** Memory-first step added per FW-ADR-0001 (claude-mem
  adoption, 2026-04-24). The CUSTOMER_NOTES + agent-roster steps
  predate it. Escalation order is binding.
- **Why added then:** prevent re-asking the customer questions
  already answered (CUSTOMER_NOTES check); prevent re-reading
  long artefacts when memory observations would suffice
  (claude-mem step).
- **Why questioning now:**
  - **Current value unclear?** The memory-first step is binding,
    but the framework also acknowledges projects "that cannot
    install claude-mem (air-gapped, policy restriction) fall
    back gracefully" (CLAUDE.md line 75). On those projects,
    step 1 is a no-op and the protocol is effectively a 4-step
    lookup chain.
  - **Cost material?** Per-question: small. Per-project: the
    customer-facing prose is binding and cited from multiple
    files; if the rule shifts (claude-mem becomes optional vs
    recommended) the cite chain has to update.
  - **Redundant?** The memory-first step has a robust fallback
    rule but the *binding* framing creates ambiguity for
    projects that opt out of claude-mem — is the rule "lookup
    if installed" or "lookup as a binding precondition"? Files
    say both depending on which sentence you read.
- **Invitation:** for projects that don't install claude-mem,
  is the memory-first step (a) a no-op, (b) a should-have-installed
  warning, or (c) a binding precondition that effectively forces
  installation? The current text in `CLAUDE.md` says (a) but the
  word "binding" in `tech-lead.md` § Memory-first lookup says (c).
  Which is intended?
- **Proposal:** **refactor.** Replace "binding" in
  `tech-lead.md` § Memory-first lookup with "binding when
  claude-mem is installed; no-op otherwise." Tightens the contract
  to match `CLAUDE.md` § Memory and orchestration tooling intent.
  PATCH-level fix.
- **Route:** `tech-lead` → customer.

### F-007 — Stepwise smoke test + plain smoke test: two smoke tests, drift risk

- **Class:** Ceremony without payoff (the second smoke; the
  first is earning its keep).
- **Rule:** `scripts/smoke-test.sh` (76/0 passes, runs the v0.1.0
  → vCURRENT one-shot path). `scripts/stepwise-smoke.sh` (added
  v0.16.0, runs every-tag stepwise from v0.14.4 forward). v1.0-rc3
  checklist C-7 requires the stepwise smoke at every release
  candidate hop.
- **Origin:** plain smoke shipped early (predates v0.12.0).
  Stepwise smoke shipped v0.16.0 specifically for C-7 of the
  rc3 checklist. Two distinct files.
- **Why added then:** plain smoke catches "does the latest
  upgrade.sh land on a v0.1.0 project cleanly." Stepwise smoke
  catches "does each migration in sequence land cleanly across
  every intermediate hop" — a different invariant after
  v0.14.x's recovery work proved that intermediate-hop
  regressions exist.
- **Why questioning now:**
  - **Current value unclear?** Both have a defensible purpose.
    Two smoke tests in different files means two CI surfaces,
    two things to maintain, two places where assertions can drift
    between each other.
  - **Cost material?** Modest. The stepwise smoke's runtime is
    much higher (every tag) so it cannot replace the plain
    smoke for fast feedback.
  - **Redundant?** Partly. The plain smoke covers "does it work
    once on the latest"; the stepwise covers "does it work at
    every step." Latest-only + stepwise = strict superset, so
    the plain smoke's assertions should ideally be a subset of
    the stepwise smoke's per-hop assertions. Are they?
- **Invitation:** are the assertion sets of `smoke-test.sh` and
  `stepwise-smoke.sh` deliberately divergent (each catches a
  different failure class) or accidentally divergent (drift
  between two scripts that should agree on the basics)? If
  the latter, fold the plain smoke's assertions into a shared
  helper that both scripts source, so a new assertion only has
  to be added in one place.
- **Proposal:** **refactor.** Extract shared assertions into
  `scripts/lib/smoke-assertions.sh`; both smoke scripts source
  it; per-mode assertions stay in their respective scripts.
  PATCH-level. Eliminates drift risk pre-emptively before the
  rc3 cut, where divergence would be most painful.
- **Route:** `tech-lead` → customer (low priority).

### F-008 — DECISIONS.md (template-shipped, never used)

- **Class:** Redundant check.
- **Rule:** `docs/DECISIONS.md` is shipped as an append-only
  decisions log "for decisions `tech-lead` (or any other agent)
  made on behalf of the customer without live customer input"
  (line 4). Template comment (line 33) says "First entry is
  D-0001."
- **Origin:** No `LESSONS.md` row available. File exists as a
  template-shipped artefact. No CHANGELOG mention found.
- **Why added then:** to record agent-side decisions taken
  without the customer present, so the customer can later audit
  what agents decided in their absence.
- **Why questioning now:**
  - **Current value unclear?** The file in this repo has zero
    entries. The mechanism (D-NNNN row template, supersedes
    field) is in place; it has never fired.
  - **Cost material?** The artefact itself is cheap. The cost
    is conceptual: yet another append-only log alongside
    `OPEN_QUESTIONS.md`, `CUSTOMER_NOTES.md`, `LESSONS.md` (when
    it exists), `CHANGES.md` (per-project), and `intake-log.md`
    (when it exists). Each is supposed to capture a different
    slice of project history; the partition is non-obvious.
  - **Redundant?** Materially. An agent-side decision without
    live customer input would land in `LESSONS.md` (it's a
    learning), or in `CUSTOMER_NOTES.md` as "agent X decided Y
    in customer's absence — flagged for ratification," or in
    a task file as a dispatch decision. DECISIONS.md is the
    fourth target for this content.
- **Invitation:** has any agent ever written a `D-NNNN` row in
  this repo? In a downstream project? If not in either, the
  artefact has not earned its keep. If yes in downstream, the
  upstream's empty file is fine — it's a template stub.
- **Proposal:** **defer.** Probably a template stub for downstream
  use; not actually broken on the upstream. But worth one
  question to the customer: are agent-side decisions actually
  landing in DECISIONS.md anywhere, or has every such decision
  found one of the other logs first?
- **Route:** `tech-lead` → customer.

### F-009 — `docs/v2/` placeholder pattern (issue-clearing artefact, never read after creation)

- **Class:** Process Debt (suspected — verify).
- **Rule:** v1.0-rc3 checklist C-6: "Every issue currently
  labelled `v2-proposal` … is either landed in v0.x, formally
  deferred to v2.0 with a `docs/v2/<topic>.md` placeholder, or
  explicitly rejected with reason in `docs/DECISIONS.md`."
- **Origin:** v0.16.0 release window (CHANGELOG line 64–96).
  Two placeholders exist: `docs/v2/triage-repair-agent.md` (#3),
  `docs/v2/claude-mem-hybrid-ledger.md` (#27).
- **Why added then:** clear the issue tracker without losing
  the deferred ideas. Each `docs/v2/<topic>.md` is supposed to
  carry "what / why-not-now / what-blocks."
- **Why questioning now:**
  - **Current value unclear?** The placeholders satisfy a
    tracker-cleanliness criterion (C-6) and provide a written
    record of deferral rationale. Whether they will actually be
    read at v2.0 entry, versus the team re-deriving the
    rationale from issue history, is unknown.
  - **Cost material?** Per-deferred-item: one short markdown
    file. Per-project: low. Per-template: low.
  - **Redundant?** Partly. GitHub issue body + label
    `v2-proposal` already carries the same rationale. The
    `docs/v2/<topic>.md` file is a duplicate-with-different-
    location.
- **Invitation:** when v2.0 entry comes (post-1.0), will the
  team start from `docs/v2/*.md` files or from the still-open
  issue tracker? If the tracker is the primary source, the
  `docs/v2/` files are write-only artefacts (created at deferral
  time, never read again).
- **Proposal:** **keep, with explicit re-read trigger.** Add a
  one-line rule to C-6 (or to a new ROADMAP section) saying
  "at v2.0 milestone open, the first action is re-read every
  `docs/v2/<topic>.md` and re-classify each as land / re-defer /
  reject." This earns the artefact's keep by giving it a
  scheduled consumer. Without that trigger, F-009 will be a
  stronger Process Debt finding at the next audit (2 milestones
  out).
- **Route:** `tech-lead` → customer.

---

## No-findings list (rules audited and kept)

One-line each, for transparency.

- `CLAUDE.md` § Hard rules (lines 738–759) — all 7 rules
  earning their keep; out of process-auditor scope per agent
  contract.
- `CLAUDE.md` § IP policy (lines 670–714) — out of scope per
  agent contract; also all citations in CHANGELOG show recent
  uses (PMBOK NO AI TRAINING clause, 2026-04-23 narrow-
  interpretation ruling).
- `CLAUDE.md` Step 0 (issue-feedback opt-in) — explicit rationale
  for being asked first (line 218–222) survives challenge.
- `CLAUDE.md` "Time-based cadences" (lines 715–736) — recent
  add (v0.13–v0.14 era) with clear semantics; replaces a
  previously-ambiguous calendar-cadence pattern.
- `CLAUDE.md` § Tech-lead is the main-session persona (lines
  567–595) — incident-driven (issue #37, 2026-04-24); active
  failure-mode prevention; recent fire.
- `tech-lead.md` § Customer-facing output discipline / Turn
  Ledger — heavily-cited recent addition; no signs of debt.
- `tech-lead.md` § Parallelism default (lines 175–198) — explicit
  anti-pattern called out (serializing researcher behind
  architect); the rule's own example is a refutation of an
  earlier failure pattern.
- `architect.md` § Operations trade-offs (SWEBOK V4 ch. 6)
  ownership split — recent addition tied to a specific KA
  ownership question; clear consumer.
- `code-reviewer.md` (not deeply audited per agent-contract
  scope boundaries; Code-review = `code-reviewer` territory).
- `qa-engineer.md` § Adversarial stance (binding) — explicit
  scope boundary noted in agent contract (this auditor's
  scope-boundary §) so not audited.
- `researcher.md` § Source discipline (Tier-1/2/3) — has been
  exercised; clear hits in recent ADRs (FW-ADR-0007 Tier-1
  citation chain).
- `researcher.md` § Source-discipline "no silent source
  substitution" rule — explicit recent rule with binding force;
  acceptance-by-default.
- `release-engineer.md` (not deeply audited; release-process
  artefacts are `release-engineer`'s domain).
- `security-engineer.md` (Hard Rule #7 path) — out of scope
  per the SWEBOK V4 ch. 13 anchoring + Hard Rule #7 binding.
- `sme-template.md` + SME mode split (primary-source vs
  derivative) — recent customer ruling (2026-04-19, issue #6
  Fix-C); active artefact.
- `migrations/*.sh` per-version migration mechanism (CLAUDE.md
  lines 175–192) — fired multiple times in the v0.13.x → v0.14.x
  recovery work; clear earning-keep evidence.
- `scripts/upgrade.sh --verify` + `TEMPLATE_MANIFEST.lock`
  (FW-ADR-0002) — recent, recent fire (issue #61), clear consumer.
- ROADMAP.md — not audited; out of scope (project-state artefact,
  not a binding rule).
- v1.0-rc3 checklist (this very file's commissioning artefact)
  — not audited (per agent contract: cannot audit own
  introduction).
- Three-Path Rule itself — earning keep on this repo (7 ADRs);
  the *companion stages* are the ones flagged in F-001, not
  Three-Path.
- Customer-audit backstop in §5.3 of agent-health-contract —
  recent (2026-04-20 customer ruling, Fix B) — active recent
  fire.

---

## Recommendation to `tech-lead`

- **Batch into a single conversation.** Nine findings, none
  urgent. A drip-feed across multiple sessions would itself be
  a process-audit-induced-friction case study.
- **Suggested order of presentation to customer:**
  1. F-006 (memory-first contract clarity) — tightest, smallest fix.
  2. F-004 (trigger-list collapse) — low-stakes refactor.
  3. F-007 (smoke-test shared assertions) — low-stakes refactor.
  4. F-002 (intake-log scope-pin or retire) — needs ruling.
  5. F-001 (workflow pipeline empirical-usage) — defer-to-decision.
  6. F-008 (DECISIONS.md earning keep) — one-question.
  7. F-009 (docs/v2 re-read trigger) — one-paragraph addition.
  8. F-005 (Step-3a category scope pin) — sensitive (recent
     customer ruling), present as a "since N projects in" check.
  9. F-003 (agent-health heartbeat protocol) — keep with evidence
     bar; smallest action.
- **Per-finding outcome options** (per agent contract):
  - (a) **justify** — rule stays, customer notes the rationale;
    log into `docs/pm/LESSONS.md` under "Process audit response
    2026-04-25" so the next audit (2–3 milestones out) sees the
    justification.
  - (b) **retire** — rule removed; `CHANGES.md` row;
    `CUSTOMER_NOTES.md` entry; downstream migration if applicable.
  - (c) **modify** — rule reworded; `CHANGES.md` row;
    relevant agent contracts updated.
  - (d) **defer** — revisit at next process audit; no change.
- **Log the session in** `docs/pm/LESSONS.md` under "Process
  audit response 2026-04-25" with per-finding outcomes. (The
  file does not yet exist; this audit's response would be the
  first entry — itself a small earning-keep moment for the audit
  pattern.)
- **Do not block C-5 ratification on this report.** The rc3
  checklist's pass condition for C-5 is "no outstanding **major**
  findings." None of F-001 through F-009 reaches major in this
  auditor's grading — they are mostly clarity / earning-keep /
  scope-pin invitations, not structural defects. The companion
  QuackPLC run + this run together exercise the audit-agent
  ritual twice per C-5's "at least twice" requirement.

---

## Auditor's note on scope-respected questions

Per the agent contract's binding scope boundaries, the following
candidates were *considered but not audited*:

- **Hard rules #1–#7.** Out of scope. Each has its own amendment
  path. F-001 brushes against #4 / #7 only via the workflow
  pipeline's interaction with them, not as a challenge to the
  Hard Rules themselves.
- **IP policy** — out of scope.
- **Customer rulings** in CUSTOMER_NOTES.md (the file is empty
  on the upstream; the rulings cited in CHANGELOG / OPEN_QUESTIONS
  are not re-litigated). F-005 explicitly notes Step-3a was a
  customer ruling and treats it as defer-to-customer-decision
  rather than challenge.
- **`code-reviewer` territory** (code drift, individual diffs)
  — out of scope.
- **`qa-engineer` territory** (test coverage, test plans) —
  out of scope.
- **`onboarding-auditor` territory** (documentation completeness)
  — out of scope. Companion onboarding-audit pass is suggested
  separately.

This audit's introduction itself (the process-auditor agent and
its `2–3 milestone` cadence) is also out of scope per the agent
contract's "Cannot audit its own introduction" limit. A future
audit-of-the-audit ritual is the customer's call.

---

## Revision history

| Date | Change | Who |
|---|---|---|
| 2026-04-25 | Initial report; 9 findings; full-history pass over CLAUDE.md, all `.claude/agents/*.md`, workflow-redesign memo, FW-ADR-0001 through FW-ADR-0007, retrofit-playbook template (skim), agent-health-contract, intake-log + intake-conformance templates, OPEN_QUESTIONS, DECISIONS, CHANGELOG (v0.12.0 → v0.17.0), v1.0-rc3 checklist. | `process-auditor` (one-shot) |
