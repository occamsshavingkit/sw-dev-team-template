---
name: adr-0001-context-memory-strategy
description: Meta-project ADR adopting claude-mem and rejecting ruflo, mirroring FW-ADR-0001 for this repo.
status: accepted
date: 2026-04-24
---


# ADR-0001 — Context-memory strategy: adopt `claude-mem`, do not adopt `ruflo`

- **Status:** Accepted
- **Date:** 2026-04-24
- **Decider:** customer (human) + `tech-lead`
- **Consulted:** `architect`, `researcher`
- **Template version at decision time:** see `TEMPLATE_VERSION`

## Context

The project needs to keep agent context windows small while preserving
continuity across sessions. Two tools were on the table:

1. **`claude-mem`** (thedotmack/claude-mem, v12.3.3 at decision time) —
   a passive plugin that summarizes each session into searchable
   observations and exposes them via MCP (`smart_search`,
   `get_observations`, `timeline`, …). Already installed and running
   on this host; the `SessionStart` recap at the top of each session
   is produced by this plugin and reports on the order of ~95 %
   context savings versus re-reading raw artifacts.

2. **`ruflo`** (ruvnet/ruflo, formerly "claude-flow"; v3.5 at decision
   time) — a full multi-agent orchestration platform. It ships its
   own agent roster (100+ agents, including `coder`, `tester`,
   `reviewer`, `architect`, `security`, …), its own hook system
   (~27 hooks), its own MCP server, its own memory layer (AgentDB +
   RuVector, with HNSW, ReasoningBank, EWC++, LoRA, and 9 RL
   algorithms for a Q-learning router / MoE), and its own swarm
   coordination primitives (Raft / BFT consensus, mesh /
   hierarchical topologies).

## Decision

- **Adopt `claude-mem` as the project's prior-session memory layer.**
  Wire agent behaviour so memory lookup is tried before re-reading
  long artifacts or escalating to the human. Specifically:
  - `CLAUDE.md` § *Escalation protocol* gains a memory-first step.
  - `tech-lead.md` gains a *Memory-first lookup* block binding the
    orchestrator to query memory before dispatching re-reads.
  - `researcher.md` binds in-project prior-art scans to query
    `claude-mem` before external Tier-1 searches.
  - Memory is treated as a **lookup, not a source of truth**:
    hits are pointers to verify against the current repo state.

- **Do not adopt `ruflo` as a framework.** Its design conflicts
  materially with this project's taxonomy-aligned agent architecture.
  Cherry-picking is permitted for individual standalone skills if
  they prove useful, but adopting ruflo's roster, routing, hooks,
  or memory is out of scope and requires a new ADR.

## Rationale

### Why `claude-mem` fits

- **Passive and additive.** It does not dictate agent design, routing,
  or escalation; it only produces and indexes summaries.
- **Already working here.** No migration cost. The `SessionStart`
  recap has been running for weeks and is visibly effective.
- **Honest about staleness.** Observations are point-in-time; the
  project's amended escalation protocol enforces verification
  against current repo state before acting on a hit.
- **Orthogonal to the workflow pipeline** introduced in v0.12.0
  (prior-art gate, proposal gate, solution duel). It feeds the
  prior-art gate, it does not replace it.

### Why `ruflo` does not fit

- **Conflicting roster.** Ruflo's canonical agents (`coder`,
  `tester`, `reviewer`, `architect`, `security`) do not map cleanly
  to this project's SWEBOK v3 / PMBOK / IEEE 1028 / ISTQB / SFIA v9
  / Google-SRE-aligned roster. Adopting it would either shadow the
  canonical roster (creating two sources of truth) or replace it
  (erasing the taxonomy work documented in `SW_DEV_ROLE_TAXONOMY.md`).
- **Conflicting escalation model.** Ruflo's router is a Q-learning
  policy that picks agents by reward. This project's Hard Rule #1
  requires that **only `tech-lead` interfaces with the customer**,
  and Hard Rule #4 requires live customer approval on safety-
  critical changes. Neither invariant is expressible as a reward
  signal without bolt-ons that defeat the point.
- **Conflicting hooks.** Ruflo ships 27 hooks of its own. This
  project already has a curated `SessionStart` hook chain
  (`version-check.sh`, `claude-mem`, the template-upgrade banner,
  and Step 1 / Step 2 scoping flow). Stacking ruflo's hooks on top
  would produce unordered, hard-to-reason-about interactions.
- **Duplicate memory layers.** Ruflo's AgentDB / RuVector overlaps
  with `claude-mem`. Running both doubles write cost, splits the
  index, and produces two different "truth" stores for prior-session
  knowledge.
- **Violates the workflow pipeline.** v0.12.0's five-stage pre-code
  pipeline (intake → prior-art → proposal → solution duel → task)
  assumes deterministic routing through `tech-lead`. Ruflo's MoE
  router and autonomous swarms are non-deterministic by design.
- **Context savings are not where ruflo wins.** The measured
  context savings already come from `claude-mem`. Ruflo would add
  orchestration surface area, not further context compression.

### Consequences

- The project commits to `claude-mem` for memory, with the
  verification discipline recorded in `CLAUDE.md`.
- `ruflo`'s published skills catalogue remains available as a
  source of prior art. Individual skills MAY be installed on a
  case-by-case basis through the same process as any other
  external skill (Step 1 skill-pack flow).
- If the project later outgrows the curated roster and genuinely
  needs learned routing / swarm coordination, this ADR must be
  superseded before ruflo (or equivalent) is adopted.
- Upstream `sw-dev-team-template` should file an issue referencing
  this ADR so downstream projects get a default "memory: yes,
  orchestration framework: no" recommendation unless they opt in.

## Alternatives considered

- **Adopt both.** Rejected: duplicate memory stores, conflicting
  hooks, conflicting escalation models.
- **Adopt ruflo only.** Rejected: erases the taxonomy-aligned
  roster; large migration cost; loses the escalation invariants
  that underpin Hard Rules #1 and #4.
- **Adopt neither.** Rejected: the `claude-mem` savings are
  measured and real; walking away from them is leaving value on
  the floor.
- **Build an in-house memory layer.** Rejected as premature
  optimization: `claude-mem` already works, and the verification
  discipline in this ADR addresses the staleness concern that
  would otherwise motivate a bespoke build.

## Follow-ups

- [ ] Add a CHANGELOG.md entry for v0.12.0 (or v0.13.0, if v0.12.0
      is tagged) referencing this ADR.
- [ ] `researcher` to file the upstream template issue described
      above (subject to the issue-feedback opt-in).
- [ ] Revisit in 6 months (2026-10-24): has the staleness-verification
      discipline held up? Have any projects hit a ruflo-shaped gap?
