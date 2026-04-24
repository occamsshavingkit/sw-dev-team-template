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

## v0.13.0 — unreleased (MINOR bundle)

Additive features. Placeholder.

### Pending
- **retrofit-playbook (#3)** — agent workflow (not a script) for
  migrating an existing project into a freshly-scaffolded target.
  Shape pinned by customer ruling 2026-04-23
  (`CUSTOMER_NOTES.md`); implementation awaits `/ultraplan` output
  + review. Deliverable: `docs/templates/retrofit-playbook-template.md`.
- **#33 Three-Path Rule** (Phase 3 of workflow redesign) — expand
  `docs/templates/architecture-template.md` Alternatives-considered
  guidance to require three named alternatives (Minimalist /
  Scalable / Creative). Deferred from v0.12.0 per architect's
  phased-rollout recommendation in
  `docs/proposals/workflow-redesign-v0.12.md` §10.

---

## v0.12.1 — 2026-04-24 (PATCH)

Two-part PATCH for issue #37 (tech-lead orchestration gap).

### Fixed

- **#37 tech-lead has no spawn capability — two-part fix.**

  **Part 1 (belt-and-braces declaration).** `.claude/agents/tech-lead.md`
  frontmatter `tools:` line extended from
  `Read, Grep, Glob, Bash, Write, Edit, SendMessage` to
  `Read, Grep, Glob, Bash, Write, Edit, SendMessage, Agent` — adding
  the agent-spawn tool. Matches what `tech-lead.md` has always
  described itself as doing.

  **Part 2 (main-session-persona rule — the actual supported path).**
  `CLAUDE.md` gains a new binding section "Tech-lead is the
  main-session persona (binding)" immediately before § "Routing
  defaults", and `tech-lead.md` gains a "Usage model (binding)"
  paragraph at the top of its body. Both state explicitly: the
  main Claude Code session IS `tech-lead`; do not spawn
  `subagent_type: tech-lead`. The main session plays the role
  directly because only the main session has the `Agent` tool
  needed to spawn specialists. Subagents can only `SendMessage`
  already-running teammates; they cannot bring new specialists
  into being. Tech-lead-as-subagent is a passthrough, not an
  orchestrator, so don't use it.

  Part 1 is correctness; part 2 is the documentation that makes
  the intended usage model unambiguous. Future harness improvements
  (subagents being granted the tools their frontmatter declares)
  would make the Part-1 declaration functionally meaningful;
  Part-2 is independent of harness behaviour.

  **Harness-trust caveat (upstream).** A diagnostic dispatch of the
  patched `tech-lead` confirmed that the Claude Code harness in use
  when this PATCH was cut drops 6 of the 8 declared tools from
  subagent grants — not just `Agent` but also `Grep`, `Glob`, `Write`,
  `Edit`, `SendMessage`. The diagnosed `tech-lead` received only
  `Read, Bash`. Same class of anomaly as the `architect` case
  flagged in v0.12.0. **Open interpretation:** could be a real
  upstream bug, or could be registration-timing (harness loaded the
  pre-edit frontmatter at session start and doesn't pick up in-
  session edits — same pattern as #36 for new-agent registration).
  A post-session-restart diagnostic will disambiguate. Regardless,
  Part 2 of this PATCH is the supported path either way — the
  declaration is belt-and-braces for the day the harness honors it.

  If the repo owner confirms post-restart that declared tools are
  still dropped, file upstream at
  `https://github.com/anthropics/claude-code/issues`.

---

## v0.12.0 — 2026-04-23 (MINOR bundle)

Additive features. Placeholder; entries fill in as items land.

### Added
- **#36 new-agent registration warning.** `scripts/upgrade.sh`
  detects newly-added `.claude/agents/*.md` in the upgrade's "Added
  from upstream" set and prints a loud `ACTION REQUIRED` line
  naming the restart requirement. `CLAUDE.md` § "Template version
  check + upgrade" gains a one-paragraph warning to the same
  effect. Harness limitation (Claude Code initializes its agent
  registry at session start and does not rescan mid-session); this
  change documents the requirement rather than working around it.
  Closes #36 (part); upstream question #36 ¶3 (runtime agent
  registration) stays open pending Claude Code guidance.
- **#6 SME contract decision memo.** New
  `docs/sme/CONTRACT.md` — consolidated reference for the two-mode
  SME contract (primary-source vs derivative) from the 2026-04-19
  customer ruling. Replaces prior scattered references in CHANGELOG
  + `CUSTOMER_NOTES.md` with one durable memo. Closes #6.
- **#5 option 2 — repair-script pointer in unzipped-state warning.**
  `scripts/version-check.sh` already detected the unzipped-in-place
  state (VERSION present + TEMPLATE_VERSION absent + `.git` absent)
  in v0.10.x. Updated the user-facing message to point at
  `scripts/repair-in-place.sh` (new in v0.11.0) as option (a); the
  previous text said "if an in-place repair script ships later…".
  Closes #5 option 2.

### Pending
- (none — all v0.12.0 scope items landed or deferred)

### Added (continued)
- **#25 Cultural-disruptor / process-auditor agent.** New
  `.claude/agents/process-auditor.md` — one-shot auditor spawned
  every 2–3 milestone closes to challenge unspoken process
  conventions, find Process Debt (rituals whose justification is
  gone), ceremony without payoff, redundant checks. Counterpart to
  `onboarding-auditor` (which is zero-context by design — this one
  needs full project history). Findings route to `tech-lead` for
  customer decision; agent never removes rules unilaterally. Closes
  second half of #25.
- **#32/#33/#34/#35 design memo.** New
  `docs/proposals/workflow-redesign-v0.12.md` — architect-authored
  recommendation memo composing the four pre-code thinking
  proposals into one pipeline (prior-art → three-path → proposal →
  duel → code) gated by a mechanical OR-set trigger. Recommends
  phased rollout (Phase 1 = #34 + #32 in v0.12.0; Phase 2 = #35;
  Phase 3 = #33 last). **Recommendation only — implementation is
  the next cycle after customer review.** Flagged tool-grant
  anomaly: architect spawn did not receive its declared `Write`
  tool; tech-lead persisted memo manually. Auditor script
  `scripts/audit-agent-tools.sh` checks declared tools, not
  dispatched tools — if this is a harness pattern, file upstream.
- **Agent tool-grant fix (pre-flight).** `onboarding-auditor` and
  `process-auditor` gained `Write` in their tools grants — both
  write durable report files (FRICTION_REPORT / PROCESS_AUDIT)
  under `docs/pm/`. `scripts/audit-agent-tools.sh` flagged the
  missing grant; fix verified clean.
- **Claude Code harness anomaly — architect spawns not inheriting
  declared tools (2026-04-23).** Confirmed via a trivial diagnostic
  dispatch: architect agent spawns in this harness receive only
  `Read`, not the `Read, Grep, Glob, Write, Edit, SendMessage` set
  declared in `architect.md` frontmatter. Pattern, not one-off.
  This is an upstream Claude Code runtime issue, not a template
  defect. Reported in the workflow-redesign memo
  (`docs/proposals/workflow-redesign-v0.12.md` §Note). **To file:**
  the customer (repo owner) should report at
  `https://github.com/anthropics/claude-code/issues` if they want
  it fixed upstream. Template-side workaround: `tech-lead` persists
  architect-authored artifacts manually when the architect spawn
  reports missing tools (as was done for the workflow-redesign
  memo itself). No template change required; this entry is
  provenance.
- **Workflow redesign — Phase 1+2 implementation (customer bundled
  them per 2026-04-23 ruling).** The composed pre-code pipeline
  per `docs/proposals/workflow-redesign-v0.12.md` §1–§6. Lands
  #34 Researcher-First, #32 Options Before Actions, #35 Solution
  Duel. Phase 3 (#33 Three-Path) defers to v0.13.0.
    - New `docs/templates/prior-art-template.md` — `researcher`-
      owned durable artifact at workflow-pipeline stage 1.
    - New `docs/templates/proposal-template.md` — `software-
      engineer`-owned at stage 3; ships with the §Duel section
      attached so the stage-4 Solution Duel is an annex, not a
      separate file.
    - `.claude/agents/researcher.md` §Job item 5 gains the
      "Durable artifact required on triggered tasks" binding rule
      plus re-verification cadence (major-version bumps + 30-day
      stale check at milestone close).
    - `.claude/agents/software-engineer.md` gains a "Pre-code
      workflow (binding, workflow-pipeline stage 3+4)" section:
      produce proposal before code on triggered tasks; respond to
      every Duel finding; one round limit; escalate disputes to
      `tech-lead`.
    - `.claude/agents/qa-engineer.md` gains a "Solution Duel
      (binding, workflow-pipeline stage 4)" section: write three
      failure scenarios into proposal §Duel; one-round limit with
      tech-lead escalation on disputes; Hard-Rule-#7 paths pull
      `security-engineer` in as joint duelist. Composes with the
      existing Adversarial stance (diff-time) — same posture,
      applied earlier on the design artifact.
    - `.claude/agents/security-engineer.md` gains "Solution Duel
      participation (Hard-Rule-#7 paths)" — design-time duelist
      on auth / authz / secrets / PII / network-exposed triggers;
      release-time sign-off per Hard Rule #7 is distinct and
      unchanged.
    - `.claude/agents/tech-lead.md` §Job item 2 gains "Trigger
      annotation (binding, workflow-pipeline gate)" — annotate
      every task's `Trigger: <clauses|none>`, dispatch the
      pipeline on non-none triggers, escape hatches per memo §7.
      Routing table gains three new rows: prior-art,
      implementation proposal, Solution Duel.
    - `docs/templates/task-template.md` DoR gains two new rows:
      workflow-pipeline trigger annotated, and pipeline artifacts
      present if trigger fires. Identification block gains a
      `Trigger:` field.

---

## v0.11.0 — 2026-04-23 (MINOR bundle)

Additive features + allowed breaking changes (0.y convention).
Ships with `migrations/0.11.0.sh` when a breaking item lands.
See `V0_10_RELEASE_PLAN.md` §"Consolidated release queue" for
scope. Placeholder; entries below will be filled as items land.

### Added
- `docs/templates/pm/TOKEN_LEDGER-template.md` — PM token ledger
  scaffold. Append-only schema (`Date | Task ID | Agent | Tokens |
  Prompt (verbatim, fenced) | Notes`), example row, conventions.
  `task-template.md` DoD row now points at it; first task closure
  per project copies it to `docs/pm/TOKEN_LEDGER.md`. (Issues
  #17, #26.)
- **SWEBOK V4 / PMBOK 8 audit-pass-2 P1 remediation (2026-04-23).**
  Eight P1 gaps landed from `docs/audits/P1-REMEDIATION-PLAN.md`
  (downstream project audit; plan superseded by these edits).
    - `.claude/agents/security-engineer.md` — new agent, SWEBOK V4
      ch. 13 "Software Security" owner. Joint review with
      `code-reviewer` on auth / authz / secrets / PII / network-
      exposed changes. (SWEBOK V4 audit §2.1.)
    - `docs/templates/security-template.md` — new. Threat model
      + security requirements + assurance case shape per SWEBOK V4
      ch. 13 §§1–6.
    - `docs/templates/operations-plan-template.md` — new. CONOPS,
      supplier mgmt, IaC/PaC environments, capacity, DR pointer,
      DevSecOps touchpoints per SWEBOK V4 ch. 6 §2.
    - `docs/templates/dr-plan-template.md` — new. RTO/RPO,
      backup strategy, failover, restore-rehearsal schedule per
      SWEBOK V4 ch. 6 §2.5.
    - `docs/templates/pm/TEAM-CHARTER-template.md` — new. PMBOK 8
      §2.6 output; covers human + agent team norms.
    - `docs/templates/pm/RESOURCES-template.md` — new. PMBOK 8
      §2.6 Resources Performance Domain; human + physical +
      virtual tracking.
    - `docs/templates/pm/AI-USE-POLICY-template.md` — new. PMBOK 8
      Appendix X3; three adoption strategies + eight ethical factors.
    - `SW_DEV_ROLE_TAXONOMY.md` — new §2.4c "Security engineer";
      §2.3 SRE + §2.8 release-engineer gain SWEBOK V4 ch. 6
      operations-split citations.
    - `docs/glossary/ENGINEERING.md` — ISO/IEC 27001:2022 binding;
      "Restricted-source clause" binding.
    - `.claude/agents/project-manager.md` — three new PMBOK 8
      artifact rows (AI Use Policy, Team Charter, Resources) +
      expanded Responsibilities for sustainability, AI-use policy,
      team-charter stewardship, PMBOK 8 §2.6 resource management.
    - `.claude/agents/sre.md` + `.claude/agents/release-engineer.md`
      — SWEBOK V4 ch. 6 operations-split responsibilities.
    - `.claude/agents/architect.md` — security-engineer hand-off
      + operations trade-off arbitration.
    - `.claude/agents/code-reviewer.md` — security-engineer joint-
      review hand-off.
    - `.claude/agents/tech-lead.md` — routing-table row for
      `security-engineer`.
    - `.claude/agents/researcher.md` — new "Cite hygiene for
      restricted sources" section + source-handling matrix.
    - `docs/templates/pm/CHARTER-template.md` — §1 renamed
      "Purpose, justification, and value proposition"; new §11
      Sustainability considerations.
    - `docs/templates/pm/RISKS-template.md` + `LESSONS-template.md`
      — `sustainability` and `AI-use` added to category enums.
    - `CLAUDE.md` — new Hard Rule #7 (security-engineer sign-off
      for auth/secrets/PII/network-exposed releases); new Step-2
      DoD rows (Team Charter, AI Use Policy); new "Operations KA
      ownership" routing section; IP-policy bullet for
      restricted-source clauses (PMBOK 8 "NO AI TRAINING")
      + customer's narrow-interpretation ruling; roster gains
      `security-engineer.md`.
- **#5 part C — `scripts/repair-in-place.sh`.** New. Converts an
  unzipped-in-place template directory into a scaffolded project
  without copying to a new path: strips template-only files, resets
  the three project registers, stamps `TEMPLATE_VERSION`, seeds
  `.template-customizations`, `git init -b main`. `--dry-run` for
  preview; `--force` skips the interactive confirmation; refuses
  to run if `TEMPLATE_VERSION` is already present (already
  scaffolded) or if the current directory does not look like an
  unzipped template (sanity checks on `CLAUDE.md`,
  `.claude/agents/`, `docs/templates/`, `VERSION`). `README.md`
  Quickstart §"I already unzipped into my working directory"
  updated to point at it. Closes upstream issue #5 part C.
- **#25 Zero-context onboarding auditor.** New
  `.claude/agents/onboarding-auditor.md` — one-shot, deliberately
  context-constrained agent (no `CUSTOMER_NOTES.md`, no LESSONS /
  CHANGES / handovers / intake-log). Reads only public docs +
  source + scripts + tests. Produces `docs/pm/FRICTION_REPORT-
  <date>.md` enumerating doc gaps that block a notional new hire.
  Dispatched at milestone close (by `qa-engineer`) or ad-hoc (by
  `tech-lead`); does not escalate — stuck points are findings.
  Added to roster in `CLAUDE.md` and `tech-lead.md` routing table.
- **V2 roadmap §2 — QA outlines (7 templates).** New
  `docs/templates/qa/`:
    - `test-strategy-template.md` — master test plan, ISTQB + IEEE 829 shape
    - `unit-test-plan-template.md`
    - `integration-test-plan-template.md`
    - `system-test-plan-template.md`
    - `acceptance-test-plan-template.md` — customer sign-off protocol
    - `regression-test-plan-template.md` — three-tier suite + flaky-test policy
    - `performance-test-plan-template.md` — co-owned by `sre`
  (Plus `intake-conformance-template.md` from #16 fix — the 8th
  QA template, listed separately under #16.)
- **V2 roadmap §3 — Style-guide seeds (5 templates).** New
  `docs/style-guides/`:
    - `python.md` — PEP 8/257/484 + ruff + mypy
    - `typescript.md` — tsconfig strict + eslint + prettier
    - `rust.md` — rustfmt + clippy pedantic + unsafe-block SAFETY comments
    - `go.md` — gofmt + staticcheck + golangci-lint + context rules
    - `bash.md` — shellcheck + shfmt + mandatory `set -euo pipefail` header
  Cross-referenced from `.claude/agents/software-engineer.md` (follow
  the guide) and `.claude/agents/code-reviewer.md` (cite it in
  findings).
- **Premature-close drift fix (2026-04-23).** Issues #11, #13, #16
  were batch-closed on 2026-04-21 but the work had not all landed.
  Reopened and fixed:
    - `scripts/audit-agent-tools.sh` — new. Pre-flight keyword audit
      of `.claude/agents/*.md` frontmatter `tools:` grants against
      description / Job body. `--strict` exits non-zero for CI /
      pre-commit. Closes #11 secondary ask.
    - `docs/agent-health-contract.md` — new "Heartbeat convention
      (binding for long-running agents)" section; long-running
      agents SHOULD emit a one-line heartbeat at least every
      10 minutes, accepted forms: file write / `TaskUpdate` /
      `SendMessage`. `tech-lead.md` §Job item 3 adds a liveness-
      expectation bullet pointing at the contract. Closes #13.
    - `docs/templates/intake-log-template.md` — new. Append-only
      YAML-block log per customer question; `agents-running-at-ask:`
      invariant enforces atomic-question rule.
      `scripts/intake-show.sh` renders the log;
      `--violations-only` exits non-zero on violations.
      `docs/templates/qa/intake-conformance-template.md` — qa-
      engineer-owned checklist (C1–C10 per-entry + S1–S4 session-
      scope). `tech-lead.md` Step-2 now requires appending an
      intake-log entry per customer question. `researcher.md` now
      requires every `CUSTOMER_NOTES.md` entry to cite the matching
      intake-log `turn:`. Closes #16.

### Changed
- **SME contract — Fix-C hybrid ruling (issue #6).** Per
  customer ruling 2026-04-19, SME agents now come in two modes
  chosen at creation:
  - `primary-source` — has a non-public knowledge source
    (human expert or proprietary doc); cites that first, may
    consult public web on top; authoritative voice for the
    domain.
  - `derivative` — no primary source; consumes `researcher`'s
    paraphrases and public citations, adds domain-specialist
    framing / opinions explicitly flagged as judgment. Exists
    for context segmentation so `researcher` does not carry
    every vendor ecosystem in one context window.

  Rewritten: `CLAUDE.md` § "SME scope: what is and is not an
  SME (binding)" replaces the single-mode text with the two-mode
  formulation plus rule of thumb. `.claude/agents/sme-template.md`
  gains a "Mode (pick one at creation; binding)" section and a
  `Mode:` metadata field. `CUSTOMER_NOTES.md` captures the
  ruling verbatim.

  Gate 5 (no open contract-breaking themes) cleared by this
  ruling. Not breaking in practice — existing primary-source-
  only projects continue to work.
- `docs/templates/task-template.md` — DoD token-usage row
  references the new template file instead of embedding the
  schema inline.

### Pending (from the release plan)
- #6 SME contract decision memo + customer ruling
- #15 customer → product owner rename (breaking; needs `migrations/0.12.0.sh`; MAJOR-track when the rest of the v1 contract is re-stabilised)
- #21 GitHub contributor workflow (v2 scope — deferred)
- #25 cultural-disruptor half (zero-context half landed this cycle)

### Advisor recommendations landed (roll-up)

- **§5.4 Adversarial QA stance** (qa-engineer agent). Added to
  `.claude/agents/qa-engineer.md` as "## Adversarial stance
  (binding)" §24–54. QA's default posture is to try to break the
  work under review, not to affirm it; works with the test-pass
  gating row in `docs/templates/task-template.md` DoD.
- **§5.5 Archival + size budgets** (researcher agent). Added to
  `.claude/agents/researcher.md` §Job item 7 "Archival + size
  budgets (binding)" §107–135. Append-only `ARCHIVE.md` peers for
  every register that accumulates closed rows; soft line-caps on
  docs loaded into agent context (`CUSTOMER_NOTES.md` — 500 lines;
  `OPEN_QUESTIONS.md` — 200 open rows; glossaries — 300 lines;
  SME inventories — 200 rows). 80 %-cap librarian warning to
  `tech-lead`; caps are guidance not gates.

---

## v0.10.1 — **rolled into v0.11.0** (2026-04-23)

Non-breaking doc / wording / routing fixes from the Gate-3
engagement. **This bundle was never tagged independently — its
contents landed in the v0.11.0 commit (ee9729d) alongside the
v0.11.0 MINOR bundle.** Kept below for historical traceability; if
you are reading an `scripts/upgrade.sh` summary or a `git log` entry
and see a reference to v0.10.1, check the v0.11.0 tag for the actual
merge point.

### Changed (rolled into v0.11.0)
- `CLAUDE.md` FIRST ACTIONS — issue-feedback opt-in promoted
  from Step 4 to Step 0 (asked first, before skill menu and
  scoping). Step 2 DoD references Step 0 as backstop. (Issue
  #7.)
- `CLAUDE.md` Step 1 menu — `[6]` rewritten to reflect that
  `trailofbits/skills` is a marketplace, not a bundle, with
  per-plugin install syntax. (Issue #4.)
- `CLAUDE.md` Step 1 menu — `[7] context-optimization` and
  `[8] token-usage` entries added; `Skip` renumbered to `[9]`;
  verification date bumped to 2026-04-21. (Issue #29a.)
- `CLAUDE.md` — new `## Time-based cadences` section
  establishing session-anchored, run-once semantics.
  (Issue #31.)
- `CLAUDE.md` Step 3 — new Step 3a "Category scope pin"
  before dispatching `researcher` for naming. (Issue #9.)
- `.claude/agents/tech-lead.md` — customer-facing output
  discipline consolidated (R-1 idleness check as numbered
  procedure, R-2 Turn Ledger with formatting spec + DECISIONS
  handshake, R-3 teammate-naming discipline with pre-Step-3
  fallback); parallelism default with anti-pattern bullet and
  "dispatch now when inputs on disk" clause; scoping-transcript
  debug dump at Step 2 close. (Issues #10, #12, #18, #23,
  #28.)
- `.claude/agents/qa-engineer.md` — new "Adversarial stance
  (binding)" section. (Advisor §5.4 / issue #24.)
- `.claude/agents/researcher.md` — new "Archival + size
  budgets (binding)" item with soft caps and `ARCHIVE.md`
  rule. (Issue #20 / advisor §5.5 partial.)
- `docs/agent-health-contract.md` — signal 11 "Silent hang /
  lost heartbeat" added with default windows (3 / 10 / 20 /
  30 min) and liveness protocol (`SendMessage` ping, 60 s
  deadline, partial-artifact preservation). (Issue #13
  partial.)
- `docs/ISSUE_FILING.md` — "Rule 0 — redact project identity"
  added to "What to include"; Step 4 → Step 0 cross-reference
  updated. (Issue #8.)
- `docs/templates/task-template.md` — DoD token-usage row
  strengthened (schema inline; later replaced by reference to
  v0.11.0 template). (Issues #17 / #26 partial; full scope is
  v0.11.0.)
- `docs/templates/task-template.md` — DoD test-pass
  verification row strengthened (raw runner output required;
  `qa-engineer` re-runs). (Advisor §5.3.)
- `docs/templates/pm/RISKS-template.md`,
  `docs/templates/pm/STAKEHOLDERS-template.md` — cadence
  wording replaced with session-anchored / locale-agnostic
  phrasing. (Issue #31.)
- `docs/versioning.md` — SemVer 2.0.0 normative reference
  added. (Issue #30.)
- Step 4 → Step 0 rename swept through `README.md`,
  `scripts/scaffold.sh`, `docs/templates/scoping-questions-template.md`,
  `docs/ISSUE_FILING.md`, `docs/OPEN_QUESTIONS.md`, and the
  `brewday-log-annotator` example. (Issue #7 follow-through.)
- `.claude/agents/architect.md` — ADR trigger list +
  role-conflict tie-break. (Advisor §5.1 / §5.2.)
- `scripts/version-check.sh` — unzipped-in-place detector. Warns
  on stderr when `VERSION` is present but `TEMPLATE_VERSION` and
  `.git` are absent (user unzipped the template release into a
  working directory without running `scaffold.sh`). Points at the
  supported re-scaffold path. (Issue #5 part B.)
- `.claude/agents/tech-lead.md` — frontmatter `tools:` now
  includes `Write, Edit`. `tech-lead` writes
  `OPEN_QUESTIONS.md` rows, `AGENT_NAMES.md`, `TEMPLATE_VERSION`,
  and the Step-2 scoping-transcript dump. The audit pass against
  every agent's description confirmed the rest of the roster
  (including `researcher` `SendMessage` for #14) was already
  correct. (Issues #11 / #14, roster `tools:` audit pass 1.)
- `CLAUDE.md` Step 1 menu — "Detect already-installed skill
  packs before asking" rule in place; installed lines annotated
  `[already installed]` and not re-proposed. (Issue #22.)
- **Fix B for `tech-lead` respawn announcement (issue #19).**
  Verified consistent across three files:
  `docs/agent-health-contract.md` § 5.4 defines the rule
  (announcement comes from the newly-spawned `tech-lead` on its
  own first turn, quoting the handover brief's "First-turn
  customer message" section; `project-manager` does not contact
  the customer directly); `.claude/agents/project-manager.md` §
  "Tech-lead health audits + respawn" enforces it on the PM
  side; `.claude/agents/tech-lead.md` § "Agent health + respawn"
  mirrors it on the tech-lead side. Sole-human-interface
  invariant preserved without carve-outs.

### Pending
- (none — v0.10.1 scope complete pending release notes)

---

## v0.10.0 — 2026-04-20

**Release-track reset.** The template is withdrawing from the
`v1.0.0-rc` track and returning to `0.y.z` minor iteration.
Rationale: the Gate-3 engagement continues to surface rc-class
issues (#4–#29), including at least two breaking themes
(terminology rename in #15, memory architecture in #27) that
cannot honestly ship under a MINOR or PATCH bump once 1.0 is
claimed. Under SemVer, `0.y` permits breaking changes in minor
bumps, which matches where the template actually is. The criteria
for returning to `v1.0.0-rc` are recorded in `docs/versioning.md`.

### Changed
- `VERSION`: `v1.0.0-rc2` → `v0.10.0`. This is a renumbering, not
  a downgrade of content; everything shipped under `v1.0.0-rc1`
  and `v1.0.0-rc2` remains in place.
- The two `v1.0.0-rc*` tags stay in git history; they are not
  deleted. They mark the point at which the rc track was paused.

### Added
- `docs/versioning.md` — stating the 0.y iteration policy and the
  explicit criteria for returning to a `v1.0.0-rc` track.

### Notes
- No migration required for downstream projects. `upgrade.sh`
  handles the version stamp change. No file shapes changed.
- The `V1_RELEASE_PLAN.md` in the private workspace is renamed
  to `V0_10_RELEASE_PLAN.md`; rc-cycle issue triage continues
  under the new minor series.

---

## v1.0.0-rc2 — 2026-04-19

Second release candidate. Adds the agent-health and respawn
protocol that the rc cycle surfaced as a gap once named
teammates became a first-class concept.

### Added
- `docs/agent-health-contract.md` — binding. Failure modes,
  ten-signal detection taxonomy (passive + mechanical),
  ground-truth health-check protocol with fixed prompt and
  grading rubric, respawn protocol, and a three-layer
  self-diagnosis for `tech-lead` (scheduled by `project-manager`
  at milestone close; peer-triggered by `architect` /
  `researcher` / `project-manager`; customer as ultimate
  backstop at milestone close).
- `docs/templates/handover-template.md` — shape of a respawn
  handover brief. Every claim cites file + line; a brief with
  unresolved citations is not respawnable.
- `scripts/agent-health.sh` — assembles a health-check packet
  (fixed prompt + filesystem ground-truth snapshot). Delegates
  grading to the auditor per § 3.2.
- `scripts/respawn.sh` — stubs a handover-brief file pre-filled
  with filesystem context, prints the respawn checklist.
- `.claude/agents/tech-lead.md` § "Agent health + respawn" —
  tech-lead orchestrates health checks on other agents; its own
  health is audited by project-manager (chain of custody
  enforced).
- `.claude/agents/project-manager.md` § "Tech-lead health
  audits + respawn" — project-manager is the designated auditor
  and respawn orchestrator for tech-lead.
- `docs/INDEX.md` lists the new contract, scripts, and handover
  template.

### Changed
- `VERSION`: `v1.0.0-rc1` → `v1.0.0-rc2`.

### Notes
- Still pre-release. Gate 3 (one real-project engagement end to
  end) remains open; this rc2 tightens the template before that
  gate closes.
- Additive change set — no migration required. Existing projects
  receive the new files on next upgrade; no existing file is
  moved or reshaped.

---

## v1.0.0-rc1 — 2026-04-19

First release candidate for v1.0.0. **Stability candidate pending
field validation.** Field validation on an actual customer
engagement promotes this to `v1.0.0`; issues surfaced during that
engagement may produce additional `rcN` cuts or a later `v1.0.0`
directly.

### Gate status at rc1

- **Agent-file audit** — green. All ten role agents plus
  `sme-template` review as sufficient; no rewrites needed.
- **SME scope boundary** — green (v0.7.1).
- **Zero open framework-gap issues** — green.
- **Smoke-test across the version span** — green; 41 checks across
  scaffold + version-check + upgrade.
- **One real project end-to-end** — pending. This rc is explicitly
  the artifact that meets reality; the rc designation honors the
  open gate.

### Changed
- `scripts/version-check.sh` and `scripts/upgrade.sh` now accept
  pre-release tags (`vX.Y.Z-suffix`) in their tag-recognition
  regex, so projects stamped at an rc version can be upgraded
  across rc boundaries without falling through the pattern.
- `VERSION`: `v0.7.1` → `v1.0.0-rc1`.

### Notes
- No new migration required — the rc is a relabel of v0.7.1
  behaviour plus the regex widening.
- Downstream projects currently stamped at `v0.7.1` may upgrade to
  `v1.0.0-rc1` if they want the pre-release cut; most should stay
  on `v0.7.1` until `v1.0.0` final.

---

## v0.7.1 — 2026-04-19

### Added
- `CLAUDE.md` § "SME scope: what is and is not an SME (binding)" —
  draws the boundary between SME agents (customer-specific or
  externally-held knowledge) and `researcher` (standards-based +
  public Tier-1 retrieval). Stops the template from spawning
  redundant "sme-swe-standards" or "sme-pmbok" agents that would
  duplicate and drift from their upstream sources.
- `sme-template.md` front-matter gained a pointer to the scope
  boundary so every new SME agent makes the check before creation.

### Notes
- Gate 2 on the path to v1.0.0-rc1 now closed. Agent-file audit
  (gate 1) was reviewed and the existing agent files already meet
  the bar; no rewrites needed.

### Changed
- `VERSION`: `v0.7.0` → `v0.7.1`.

---

## v0.7.0 — 2026-04-19

### Added
- `examples/` directory: fully-filled-in reference projects that
  illustrate how the registers and PM artifacts look when actually
  populated. `examples/README.md` catalogs them.
- `examples/brewday-log-annotator/`: promoted from the v0.1.0
  dry-run (`dryrun-project/` in the template-dev workspace). Shows
  scoping flow end-to-end, classical-composers naming, and a filled
  project charter.

### Changed
- `scripts/scaffold.sh`, `scripts/upgrade.sh`, `scripts/smoke-test.sh`
  all exclude `examples/` from downstream scaffolding / upgrading
  (it is reference material for the template repo, not content
  shipped to new projects). Smoke-test grew two new exclusion
  checks (scaffold and upgrade); 41 checks total.
- `VERSION`: `v0.6.2` → `v0.7.0`.

### Notes
- Additive. No migration needed.

---

## v0.6.2 — 2026-04-19

### Added
- `migrations/v0.6.2.sh` — cleans up `LICENSE` and
  `scripts/smoke-test.sh` from downstream trees that leaked during
  pre-v0.6.1 upgrades. Honors `.template-customizations` (if a
  project has explicitly pinned `LICENSE` as a customization, it is
  left alone).
- `scripts/smoke-test.sh` now covers the **upgrade** flow in
  addition to scaffold: stamps `TEMPLATE_VERSION` back to v0.1.0,
  runs `upgrade.sh`, asserts no template-only files leaked and that
  the stamp matches current VERSION. 39 checks total (up from 31).

### Changed
- `VERSION`: `v0.6.1` → `v0.6.2`.

### Notes
- Downstream projects with leaked `LICENSE` / `smoke-test.sh` will
  see them auto-removed on next `scripts/upgrade.sh` run (unless
  explicitly preserved).

---

## v0.6.1 — 2026-04-19

### Fixed
- `scripts/upgrade.sh`'s ship-file exclusion list now matches
  `scripts/scaffold.sh`'s. Previous releases drifted: v0.5.1 added
  `LICENSE` with a scaffold exclusion but not an upgrade exclusion;
  v0.6.0 did the same for `scripts/smoke-test.sh`. Result: running
  `upgrade.sh` on a pre-v0.6.1 project added both template-only
  files to the downstream tree. This release stops new upgrades
  from doing so.

### Known residue
- Projects that already ran `upgrade.sh` before v0.6.1 may have a
  stray `LICENSE` and/or `scripts/smoke-test.sh` in their tree.
  Safe to delete manually; neither file is load-bearing for the
  template flow. A future migration may clean these up.

### Changed
- `VERSION`: `v0.6.0` → `v0.6.1`.

### Notes
- Patch. No downstream shape change; no migration added.

---

## v0.6.0 — 2026-04-19

### Added
- `scripts/smoke-test.sh` — end-to-end sanity test for the
  scaffold + version-check flow. Scaffolds a throwaway project,
  asserts 30+ layout/content properties (expected-present,
  expected-absent, version-stamp match, empty-register shape), and
  runs `version-check.sh` in the scaffolded project to confirm it
  reports "up to date". `--keep` preserves the temp dir for
  inspection. Template-maintenance only; not shipped downstream.

### Fixed
- `scripts/scaffold.sh` now excludes `scripts/smoke-test.sh` — it
  was being carried into downstream scaffolds. Caught by the new
  smoke test. (Downstream projects are maintenance-free; they do
  not need to run smoke-test on themselves.)

### Changed
- `VERSION`: `v0.5.2` → `v0.6.0`.
- `docs/INDEX.md` lists `scripts/smoke-test.sh`.

### Notes
- The fix and the test land together, which is the reason this is
  MINOR: a new downstream-visible exclusion plus a new template-
  maintenance tool. No migration needed.

---

## v0.5.2 — 2026-04-19

### Changed
- `scripts/version-check.sh` — the upgrade-available banner now
  includes direct links to the GitHub release page for the new
  version and to `CHANGELOG.md` on `main`, so the customer can read
  what changed before deciding to run `upgrade.sh`.
- Banner copy mentions `.template-customizations` as a preserve
  mechanism alongside user-added agents and PMBOK artifacts.
- `VERSION`: `v0.5.1` → `v0.5.2`.

### Notes
- Pure message-copy change. No behaviour or file change.

---

## v0.5.1 — 2026-04-19

### Added
- `LICENSE` — MIT, applied to the template artifact itself.
  Permissive; explicitly allows closed-source, proprietary, and
  commercially-licensed downstream projects built from this template.
- `CLAUDE.md` § "License of the template and of downstream projects"
  and `README.md` note the MIT license, the closed-source
  allowability, and the scaffold's decision to not carry the
  template's LICENSE into downstream projects (each project picks
  its own license).

### Changed
- `scripts/scaffold.sh` excludes `LICENSE` so downstream projects
  are not defaulted to MIT. Each project owner picks.
- `VERSION`: `v0.5.0` → `v0.5.1`.

### Notes
- Pure license / documentation addition; no behaviour change. No
  migration needed.

---

## v0.5.0 — 2026-04-19

### Added
- `.template-customizations` mechanism: downstream projects can list
  paths (one per line, project-root-relative) that are permanently
  customized. `scripts/upgrade.sh` skips listed paths entirely —
  never overwrites, never flags as a conflict — and reports them as
  `preserved` in the upgrade summary. `scripts/scaffold.sh` seeds
  the file empty with a header documenting the convention.
- `CLAUDE.md` § "Permanent customizations" documents the mechanism.

### Changed
- `scripts/upgrade.sh` reads `.template-customizations` before the
  file-sync loop and routes listed paths into a new `preserved`
  category. No behaviour change for projects without the file.
- `VERSION`: `v0.4.1` → `v0.5.0`.

### Notes
- Additive. Existing projects continue to work; they opt in to the
  preserve-list by creating the file. Legitimate repeated conflicts
  like a project-specific `.gitignore`, `README.md`, or a rewritten
  standard template can go in the list and stop nagging on every
  upgrade.

---

## v0.4.1 — 2026-04-19

### Fixed
- `migrations/v0.1.0.sh` no longer recurses into nested git repos
  (e.g., a `sw-dev-team-template` working copy that lives inside the
  downstream project directory). Rewrites of `docs/GLOSSARY.md` →
  `docs/glossary/ENGINEERING.md` were over-reaching into sibling
  projects and touching log-entry strings where both the old and new
  path legitimately appear. The reference-rewrite now skips files
  inside any subtree that contains its own `.git/`, skips files
  inside `docs/glossary/`, and only rewrites lines that reference
  **only** the old path (not lines that document the transition).

### Added
- `CLAUDE.md` Step 1 follow-up: after the skill-pack catalog, ask an
  atomic question for specialized skills / plugins / MCP servers /
  tools the user already knows they need, or watch-items for the
  team to flag (domain risks, style conventions, safety-critical
  behaviours). Scoping-questions template carries the seed row.

### Changed
- `VERSION`: `v0.4.0` → `v0.4.1`.

### Notes
- No downstream shape change; no migration needed for this release.

---

## v0.4.0 — 2026-04-19

### Added
- `migrations/` directory: per-version migration scripts that run
  during `scripts/upgrade.sh` when a release changes downstream
  content shape (moves, renames, splits, reformats). Most releases
  ship no migration; when they do, `upgrade.sh` runs every
  applicable migration in ascending SemVer order **before** the
  file-sync.
- `migrations/README.md`: contract, naming, idempotency rule, env-var
  interface.
- `migrations/TEMPLATE.sh`: starter scaffold for new migrations.
- `migrations/v0.1.0.sh`: retroactive glossary-split migration for
  pre-v0.1.0 projects that still have `docs/GLOSSARY.md` at the
  single-file path. Also rewrites references in markdown files.
- `migrations/v0.2.0.sh`, `v0.3.0.sh`: explicit no-op migrations
  documenting that those releases required no shape changes.
- `CLAUDE.md` § "Per-version migrations" — documents the contract.

### Changed
- `scripts/upgrade.sh` runs migrations before file-sync. Edge case
  handled: if the project's `TEMPLATE_VERSION` does not match any
  upstream tag, the script falls back to running every migration
  ≤ target, relying on idempotency guards.
- `scripts/scaffold.sh` excludes `migrations/` — downstream projects
  do not carry migration scripts locally; `upgrade.sh` sources them
  from the upstream clone at upgrade time.
- `VERSION`: `v0.3.0` → `v0.4.0`.

### Notes
- Adding `migrations/` is additive — existing projects continue to
  work. On their next upgrade, applicable migrations run
  automatically.

---

## v0.3.0 — 2026-04-19

### Added
- `scripts/version-check.sh` — compares the project's
  `TEMPLATE_VERSION` against the upstream's latest tag and prints a
  banner if an upgrade is available. Wired as a `SessionStart` hook
  in `.claude/settings.json`; silent on network failure.
- `scripts/upgrade.sh` (with `--dry-run`) — upgrades a scaffolded
  project to the latest template version. Per-file strategy: add
  missing, overwrite unchanged-since-scaffold, **never overwrite
  customized standard files** (flagged as conflicts for human
  review), never touch user-added files (SME agents, PMBOK artifacts,
  anything else the project created). Supports `GH_TOKEN` env var
  for private-upstream clones.
- `.claude/settings.json`: new `SessionStart` hook entry.
- `CLAUDE.md` § "Template version check + upgrade" — documents the
  flow and the customized-file conflict rule.

### Changed
- `VERSION`: `v0.2.0` → `v0.3.0`.

### Notes
- Running `scripts/upgrade.sh` requires access to the upstream repo.
  Private-upstream clones work via the `GH_TOKEN` env var (scope:
  `repo`).
- Conflicts (customized standard files that the upstream also
  changed) are surfaced but not resolved automatically. The project
  owner decides per-file.

---

## v0.2.0 — 2026-04-19

### Added
- `scripts/scaffold.sh` — creates a new project from the template,
  resets project-specific registers to empty stubs, stamps
  `TEMPLATE_VERSION`, initializes git. Smoke-tested. Closes upstream
  issue #1.
- `researcher.md` § Job #6 — pronoun-verification procedure with
  source hierarchy (living persons → agency bios → encyclopedias
  that cite primaries; historical figures → reference biographies;
  fictional characters → canon), explicit citation format, and
  re-verification cadence. Closes upstream issue #2.
- `CLAUDE.md` § "Scaffolding a new project" — documents the
  `scripts/scaffold.sh` entry point.
- `docs/AGENT_NAMES.md` § "Pronoun verification procedure" —
  cross-references `researcher.md`.

### Changed
- `VERSION`: `v0.1.0` → `v0.2.0`.

### Notes
- The change is additive (new file + new job bullet + new section).
  Existing projects continue to work without migration; they may
  adopt the scaffold script on their next new-project scaffold.

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
