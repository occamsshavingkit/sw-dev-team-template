# FW-ADR-0001 — Context-memory strategy: adopt `claude-mem`, do not adopt `ruflo`-class orchestration frameworks

<!-- TOC -->

- [Status](#status)
- [Context and problem statement](#context-and-problem-statement)
- [Decision drivers](#decision-drivers)
- [Considered options (Three-Path Rule, binding)](#considered-options-three-path-rule-binding)
  - [Option M — Minimalist](#option-m-minimalist)
  - [Option S — Scalable](#option-s-scalable)
  - [Option C — Creative (experimental)](#option-c-creative-experimental)
- [Decision outcome](#decision-outcome)
- [Consequences](#consequences)
  - [Positive](#positive)
  - [Negative / trade-offs accepted](#negative-trade-offs-accepted)
  - [Follow-up ADRs](#follow-up-adrs)
- [Verification](#verification)
- [Links](#links)

<!-- /TOC -->

Shape per MADR 3.0 adapted to this template's Three-Path Rule
(upstream issue #33). This ADR is also the canonical worked example
for `docs/templates/adr-template.md`.

---

## Status

- **Accepted**
- **Date:** 2026-04-24
- **Deciders:** `architect` + `tech-lead` + customer
- **Consulted:** `researcher` (source evaluation), `code-reviewer`
  (invariant-preservation check), downstream project
  (originating evaluation)

## Context and problem statement

Agent sessions accumulate context rapidly. Without a persistent
memory layer, every session rereads long artifacts (`WORK_LOG.md`,
`CHANGELOG.md`, past release reviews, prior-session transcripts)
to reconstruct state — wasting tokens and inviting hallucinated
state where re-reads are skipped. At the same time, the broader
ecosystem offers tools that combine memory with agent-
orchestration frameworks. Adopting such a framework without
examining its escalation model risks overriding the invariants
this template is built on (Hard Rules #1 and #4 in `CLAUDE.md`).

The template needs to record a default stance on memory /
orchestration tooling so downstream projects do not each re-
discover the trade-off and risk silently disabling the
template's escalation contract in the process.

Cite:
- Upstream issue #39 — "Recommend context-memory strategy by
  default (claude-mem yes, ruflo no)"
- Customer ruling 2026-04-24 (captured in the originating
  downstream project's CUSTOMER_NOTES)
- `CLAUDE.md` § Hard rules — the invariants the decision must
  preserve

## Decision drivers

- **Preserve Hard Rule #1** — only `tech-lead` talks to the
  customer. Any orchestration layer that picks agents by learned
  reward cannot model this invariant without bolt-ons.
- **Preserve Hard Rule #4** — live customer approval on safety-
  critical changes. Autonomous routing / swarm coordination is
  incompatible.
- **Preserve Hard Rule #3** — `code-reviewer` review before
  commit. A non-deterministic router that occasionally skips the
  reviewer breaks this.
- **Preserve the taxonomy-aligned roster** (`SW_DEV_ROLE_TAXONOMY.md`)
  grounded in SWEBOK / PMBOK / IEEE 1028 / ISTQB / SFIA / Google
  SRE. A shadowing roster from a third-party framework
  duplicates or erases that alignment.
- **Preserve the workflow pipeline** (v0.12.0 five-stage pre-code
  gates). Deterministic routing through `tech-lead` is a
  correctness property; non-deterministic routing is not.
- **Save context.** The template has no quantitative budget but
  empirical 90%+ reductions have been reported in downstream use
  of session summarization.
- **Minimize adoption cost.** Anything requiring downstream
  projects to restructure their agent definitions or routing has
  a high bar.

## Considered options (Three-Path Rule, binding)

### Option M — Minimalist

**No memory / orchestration tooling.** Downstream projects rely
on `WORK_LOG.md`, `CHANGELOG.md`, and session-scope context only.
Prior-session state is reconstructed by rereading artifacts.

- **Sketch:** Template ships no memory guidance. Each session
  starts cold; `tech-lead` rereads the relevant files as needed.
- **Pros:** No external dependencies. No new failure modes. No
  drift between memory and repo state (because there is no
  memory layer). Easy to reason about.
- **Cons:** Expensive in tokens — long artifacts reread every
  session. Slower — re-reading is sequential. Invites silent
  hallucination when agents skip rereads under context pressure.
  Does not scale past a few weeks of session history.
- **When M wins:** Short-duration projects (one-to-two sessions,
  throwaway spike, prototype). Projects where downstream cannot
  install plugins (air-gapped environment).

### Option S — Scalable

**Adopt `claude-mem` as a passive memory layer.** Downstream
projects install the plugin; it summarizes each session into
searchable observations exposed via MCP
(`smart_search`, `get_observations`, `timeline`, …). The
template adds a "memory-first lookup" step to the escalation
protocol so agents query memory before rereading long artifacts.
Memory is treated as a lookup, not a source of truth —
verification against the current repo is required before acting
on a recalled fact.

- **Sketch:** One plugin install; four small template edits
  (CLAUDE.md § Escalation protocol, CLAUDE.md new "Memory and
  orchestration tooling" section, `tech-lead.md` binding
  memory-first lookup, `researcher.md` binding memory-first
  prior-art scans). No roster change, no routing change, no
  hook-chain restructuring.
- **Pros:** Passive — does not dictate agent design or routing.
  MCP-native — integrates via existing tool surface. Additive
  — does not conflict with any Hard Rule. Empirically effective
  in downstream use. Verification discipline addresses the
  staleness concern.
- **Cons:** Adds a plugin dependency. Observations can become
  stale; the verification step adds a small overhead per lookup.
  Memory-layer-specific failure modes (index corruption, missed
  summarization) must be handled per `CLAUDE.md` (noted as stale
  memory, not actionable state).
- **When S wins:** Any project beyond a one-to-two-session spike.
  Projects with long-running context. Projects where agents are
  asked "what did we decide about X?" more than once.

### Option C — Creative (experimental)

**Adopt `ruflo` (ex-claude-flow) or an equivalent full multi-
agent orchestration framework.** Ruflo ships its own 100+ agent
roster, 27 hooks, MCP server, Q-learning router, MoE, Raft/BFT
consensus, AgentDB memory (with HNSW, EWC++, LoRA, 9 RL algos),
and "learning loop" — a self-optimizing autonomous swarm over a
fixed hook shape.

- **Sketch:** Install ruflo as a framework; migrate the
  template's roster to fit ruflo's agent conventions
  (`coder`, `tester`, `reviewer`, `architect`, `security`, …);
  replace the template's escalation protocol with ruflo's
  Q-learning-based router; duplicate or replace `claude-mem`
  with AgentDB/RuVector.
- **Pros:** Single tool covers memory + routing + learning.
  Learning loop adapts over time. Includes consensus primitives
  for true multi-agent swarms. Impressive capability envelope.
- **Cons:** Conflicts with Hard Rule #1 (Q-learning router
  cannot model "only tech-lead talks to customer"). Conflicts
  with Hard Rule #4 (autonomous swarms override live-approval
  requirement). Shadows the taxonomy-aligned roster
  (`coder` is not `software-engineer` is not `coder`, but
  close enough to cause drift). Shadows the v0.12.0 workflow
  pipeline (non-deterministic routing vs. deterministic gates).
  Duplicate memory stores if `claude-mem` is retained; data-
  quality risk if it is replaced. Hook chain grows unmanageable
  on top of the template's existing SessionStart hooks. High
  migration cost for uncertain invariant-preservation gain.
- **When C wins:** A project that genuinely needs autonomous
  swarm coordination (e.g., parallel agent work on an
  embarrassingly parallel problem at a scale the template was
  not designed for). A project willing to ADR-supersede Hard
  Rules #1, #3, and #4. A project that can absorb the migration
  cost. These conditions are the exception, not the default.

Ordering note: Minimalist → Scalable → Creative. Creative's
function in this ADR is to make explicit what adopting a full
orchestration framework would cost the template — not to be
seriously considered as a default.

## Decision outcome

**Chosen option:** S (claude-mem as passive memory layer)

**Reason:** Option S achieves the context-savings goal without
compromising any template invariant. Option M leaves measured
savings on the floor for no benefit beyond "fewer dependencies."
Option C buys a more ambitious capability envelope at the cost
of the Hard Rules that make this template trustworthy to
downstream projects in the first place. The verification
discipline in `CLAUDE.md` § Escalation protocol ("memory is a
lookup, not a source of truth") addresses the staleness concern
that is S's only material downside.

## Consequences

### Positive

- Downstream projects get a default memory layer that saves ~90%+
  of re-read tokens in long-running sessions.
- Memory-first lookup (in `tech-lead.md` and `researcher.md`)
  prevents accidental re-asking of the customer or re-reading of
  long artifacts.
- The ADR itself serves as a canonical worked example for the
  v0.13.0 Three-Path ADR template.
- Future framework questions ("should we adopt X?") have a
  precedent: evaluate against Hard Rules first, feature envelope
  second.

### Negative / trade-offs accepted

- A plugin dependency (`claude-mem`). Mitigated: it is passive
  and lightweight; a project that cannot install it falls back
  to Option M gracefully.
- Per-lookup verification overhead. Mitigated: the overhead is
  less than the cost of rereading the primary source every time.
- `ruflo`'s capability envelope (swarm coordination, learning
  loop) is not available by default. Mitigated: a project that
  genuinely needs that capability can write a superseding ADR.

### Follow-up ADRs

- No immediate follow-up. A future ADR would be required to
  adopt any *orchestration framework* (not just `ruflo`) — the
  ADR must explicitly supersede this one and identify how the
  framework preserves (or justifies overriding) each Hard Rule
  it touches.

## Verification

- **Success signal:** downstream projects using `claude-mem`
  report context-window reductions and do not introduce agents
  that bypass `tech-lead` for customer contact.
- **Failure signal 1:** a downstream project's memory layer
  goes stale in a way that causes an agent to act on
  out-of-date state (as distinct from a lookup-and-verify
  miss). If observed, revisit the verification discipline.
- **Failure signal 2:** a compelling case for swarm coordination
  or autonomous routing emerges from downstream usage such that
  the template's five-stage pipeline feels like friction rather
  than scaffolding. If observed, revisit Option C with specific
  preserves-Hard-Rules proposals.
- **Review cadence:** first session of the first calendar month
  six months past this ADR's date (i.e., first session on or
  after 2026-10-01 per `CLAUDE.md` § "Time-based cadences").

## Links

- Upstream issue: #39
- Task: (no task artifact — this is a template-level decision)
- Prior-art: sources evaluated are recorded in the referenced
  originating downstream project's `docs/adr/FW-ADR-0001-context-memory-strategy.md`
- Proposal: (no separate proposal — ADR is the proposal)
- Related ADRs: (none yet; this is the template's first ADR)
- External references:
  - `claude-mem` plugin: https://github.com/thedotmack/claude-mem
  - `ruflo` (ex-claude-flow): https://github.com/ruvnet/ruflo
  - MADR 3.0: https://adr.github.io/madr/
