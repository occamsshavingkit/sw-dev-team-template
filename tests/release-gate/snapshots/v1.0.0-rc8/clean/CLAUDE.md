# Claude Code Project Guide

- [The human is the customer (and may also be an SME)](#the-human-is-the-customer-and-may-also-be-an-sme)
- [Escalation protocol (strict)](#escalation-protocol-strict)
- [Extracted references](#extracted-references)
- [Template version stamp](#template-version-stamp)
- [Agent roster](#agent-roster)
- [Agent-teams panel](#agent-teams-panel)
- [Tech-lead is the main-session persona (binding)](#tech-lead-is-the-main-session-persona-binding)
- [Routing defaults](#routing-defaults)
  - [Operations KA ownership (SWEBOK V4 ch. 6)](#operations-ka-ownership-swebok-v4-ch-6)
- [Binding references](#binding-references)
- [Standard document templates](#standard-document-templates)
- [Time-based cadences](#time-based-cadences)
- [Hard rules](#hard-rules)
- [Taxonomy discipline](#taxonomy-discipline)

Multi-agent software-development workflow. Each canonical role from
`SW_DEV_ROLE_TAXONOMY.md` (SWEBOK v3 / ISO 12207 / IEEE 1028 / ISTQB /
SFIA v9 / Google SRE / PMBOK) has a dedicated subagent in
`.claude/agents/`.

This file is the Claude Code entrypoint. Codex sessions use root
`AGENTS.md`, which is a thin adapter to this same role contract so
switching between Claude Code and Codex does not change the team model.

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

1. **Check prior-session memory first** (if `claude-mem` is installed;
   see `docs/MEMORY_POLICY.md`). Before reading long
   artifacts (`WORK_LOG.md`, `CHANGELOG.md`, past release reviews) or
   escalating, query memory via `claude-mem:mem-search`,
   `smart_search`, `get_observations([IDs])`, or
   `claude-mem:timeline-report`. Memory is a **lookup**, not a
   source of truth — a hit points you at a file / issue / date to
   verify against the current repo state. If memory and repo
   disagree, the repo wins; flag the stale memory.
2. Check `CUSTOMER_NOTES.md` — the customer may have already answered it.
3. Check whether another agent on the roster is the right one to ask.
   Route there first. Example: `software-engineer` wondering about a
   standards citation asks `researcher`, not the customer.
4. Only if no agent can answer, escalate to `tech-lead` with a precisely
   worded question.
5. `tech-lead` either answers, routes further, or takes the question to
   the customer. When `tech-lead` gets an answer, it routes the verbatim
   response to `researcher`; `researcher` appends the
   `CUSTOMER_NOTES.md` customer-truth entry and `tech-lead` relays the
   answer to the asking agent.

The customer's inbox is scarce. Do not flood it. A well-framed question
batched with others is better than three drip-feed interruptions.

## Extracted references

Detailed procedures live in dedicated docs to keep this entrypoint
small. Read these when the situation matches:

- **Session-1 setup** (Steps 0–3a, skill packs, scoping, naming):
  `docs/FIRST_ACTIONS.md`
- **Template scaffold + upgrade + per-version migrations**:
  `docs/TEMPLATE_UPGRADE.md`
- **Memory layer + orchestration-framework stance**:
  `docs/MEMORY_POLICY.md` (cross-refs `docs/adr/fw-adr-0001-context-memory-strategy.md`)
- **IP policy** (copyright, restricted-source clauses, AI-training
  scope): `docs/IP_POLICY.md`
- **Framework / project boundary** (downstream path ownership):
  `docs/framework-project-boundary.md`
- **SME contract** (modes, creation, researcher interaction):
  `docs/sme/CONTRACT.md`

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
| `security-engineer.md`| Security Engineer — SWEBOK V4 ch. 13 "Software Security" owner | §2.4c |
| `onboarding-auditor.md`| Zero-context documentation auditor (one-shot, milestone-close) | custom, upstream issue #25 first half |
| `process-auditor.md`  | Cultural-disruptor process auditor (one-shot, every 2–3 milestones) | custom, upstream issue #25 second half |
| `sme-<domain>.md` ×N  | Domain SME — created per-project in Step 2 above, from `sme-template.md` | §2.6a |
| `sme-template.md`     | Scaffold for new SME agents; copy and fill in           | §2.6a |

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

Codex adapter rule: `docs/AGENT_NAMES.md` still governs
customer-facing teammate names. If Codex exposes only arbitrary worker
IDs or nicknames, those are internal handles; use the mapped teammate
name, or the canonical role when unmapped, in customer-facing text and
durable records.

## Tech-lead is the main-session persona (binding)

**The main harness session IS `tech-lead`.** In Claude Code this means
the main Claude Code session; in Codex this means the main Codex
session described by `AGENTS.md`. Do not spawn `tech-lead` as a
subagent (`subagent_type: tech-lead`). The main session plays the
tech-lead role directly — orchestration runs at the top level;
specialists spawn from there.

Rationale:

- Only the main harness session owns specialist creation: Claude Code
  exposes this as the `Agent` tool; Codex exposes it through its native
  subagent facility. Subagents can only message or report back through
  the surfaces their harness grants; they cannot be the durable
  orchestrator.
- The "sole human interface" rule below works cleanly under this
  model: the main session talks to the customer, spawns
  specialists, gets answers back.
- `.claude/agents/tech-lead.md` still ships with `Agent` declared
  in its `tools:` line (v0.12.1) for Claude Code compatibility. Codex
  does not consume that frontmatter directly; root `AGENTS.md` maps
  the same canonical roles onto Codex's spawn vocabulary.
- In Codex, specialist spawning requires per-session customer
  authorization. If spawning is unavailable, continue only with
  orchestration or non-specialist work and record that limitation; if the
  customer required agents or the task needs specialist-owned work, stop
  and ask before proceeding. If spawning is available but no specialist
  slot is free, queue the dispatch and wait for a slot unless the
  customer explicitly authorizes local implementation for that queued
  item.

**Upstream issue #37** (2026-04-24) logged a downstream project
that hit this wall by spawning `tech-lead` as a subagent. Fix is
two-part: v0.12.1 added the `Agent` declaration (belt-and-braces),
and the main-session-persona rule above (documentation) makes the
intended usage model explicit.

## Routing defaults

`tech-lead` is the **sole human interface**. No other agent talks to the
user. When a specialist agent hits a knowledge gap it:
  1. checks whether another specialist agent can answer,
  2. returns to `tech-lead` with a structured request,
  3. lets `tech-lead` either dispatch the suggested agent or — only as a
     last resort — ask the human.

One role = one agent. If work spans roles, `tech-lead` chains them
explicitly. See `tech-lead.md` for the routing table and escalation rules.

### Operations KA ownership (SWEBOK V4 ch. 6)

V4's "Software Engineering Operations" KA splits three ways across
this roster:

- **Operations Planning + Control** (ch. 6 §§2, 4) — `sre`. Owns
  CONOPS, Operations Plan, capacity plan, DR / failover plan,
  supplier management for IaaS/PaaS/SaaS, monitoring, alerting,
  incident posture, post-incident review.
- **Operations Delivery** (ch. 6 §3) — `release-engineer`. Owns
  IaC / PaC, deployment pipeline, rollback automation, release
  gating, canary / blue-green / staged-rollout mechanics.
- **DevSecOps** — three-way handshake: `sre` + `release-engineer` +
  `security-engineer`. Security controls in the pipeline, runtime
  security observability, incident-response security touchpoints.

Operations trade-offs that cross cost / schedule / risk thresholds
(DR tier selection, capacity commits, vendor lock-in) are arbitrated
by `architect` with `project-manager` on the cost / schedule side.

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

## Time-based cadences

This framework has no background scheduler. Agents only run when the
customer opens a Claude session. Any cadence expressed in wall-clock
time ("weekly", "every Monday", "monthly", "first of the month") is
interpreted as **session-anchored, run-once**:

- The cadence is a **floor** on review frequency, not a backlog of
  missed ticks.
- "Weekly" means *"in the first session opened on or after the
  calendar-week boundary"*; if no session opens for two weeks, the
  next session runs the review **once**, not twice.
- Missed cycles do not accumulate.
- `Last reviewed` is bumped when the review actually runs; staleness
  is detectable by comparing `Last reviewed` to the current week /
  month boundary.

This rule governs every PM artifact under `docs/pm/` and every
cadence reference in `.claude/agents/*.md`. Templates use phrasing
like "first session of the calendar week" in preference to
"every Monday" to make the semantics explicit.

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
7. No release touching authentication, authorization, secrets, PII, or
   network-exposed endpoints ships without `security-engineer` sign-off
   recorded in `CUSTOMER_NOTES.md` alongside the customer approval
   required by Hard Rule #4. The sign-off references the relevant
   security assurance artefact (shape per `docs/templates/security-template.md`,
   grounded in SWEBOK V4 ch. 13 §§4.1–4.6 and ISO/IEC 15026-2:2022).
8. `tech-lead` orchestrates; it does not author production artifacts
   directly. Code, scripts, schemas, prose deliverables, requirements,
   ADRs, release notes, and customer-truth records route to the owning
   specialist (`software-engineer`, `tech-writer`, `researcher`,
   `project-manager`, `architect`, etc.). Direct `tech-lead` writes are
   limited to orchestration artifacts (`OPEN_QUESTIONS.md`,
   intake-log rows, dispatch/task stubs, Turn Ledger / decision-log
   entries) and tool-bridge work a specialist cannot perform in its
   sandbox. When unsure, dispatch.
9. Before closing a non-trivial turn, `tech-lead` runs the harness-
   appropriate pre-close audit: Claude Code hook output where available,
   or the Codex Pre-Close Checklist in `AGENTS.md`. The audit confirms
   direct writes stayed within Rule #8, customer-truth stewardship
   stayed with `researcher`, required specialist work was dispatched or
   queued, completed specialists were closed after review, and any
   non-default `reasoning_effort` has a recorded rationale.
10. In downstream projects, keep product work separate from framework
   work. Do not edit framework-managed files during a product task
   unless the customer explicitly authorized template upgrade or
   framework maintenance for that task. File discovered framework gaps
   upstream through `docs/ISSUE_FILING.md`; see
   `docs/framework-project-boundary.md` for path ownership and
   review / commit splitting. Product-only release audits must classify
   release/version artifacts before writing and must not edit
   `TEMPLATE_VERSION`, template versioning docs, rc stabilization docs,
   final checklists, scaffold / upgrade scripts, manifest files, or
   other framework-managed files.

## Taxonomy discipline

`SW_DEV_ROLE_TAXONOMY.md` is the shared vocabulary. When agents disagree
about role ownership, cross-reference the taxonomy. §3 heatmap and §5 gaps
document real overlaps — do not claim "industry agrees" on topics the
taxonomy flags as debated.
