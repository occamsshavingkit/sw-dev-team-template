# Memory and orchestration tooling

> Source: extracted from CLAUDE.md (v1.0.0-rc7) per issue #120.

Sessions accumulate context quickly. The template takes an explicit
stance on two adjacent tool categories: **memory layers** (passive
session summarization + search) and **orchestration frameworks**
(multi-agent coordination with their own rosters, routers, and
escalation models). The reasoning is recorded in
`docs/adr/fw-adr-0001-context-memory-strategy.md` (also the canonical
worked example for the Three-Path ADR template).

**Recommended default: `claude-mem`** (passive memory layer,
thedotmack/claude-mem). Summarizes each session into searchable
observations exposed via MCP. Additive, does not alter agent
design, does not conflict with any Hard Rule. The memory-first
lookup step in § "Escalation protocol" is the binding integration
point; `tech-lead.md` and `researcher.md` cross-reference it.
Projects that cannot install `claude-mem` (air-gapped, policy
restriction) fall back gracefully to reading artifacts directly.

**Orchestration frameworks require a project ADR.** Any tool that
ships its own agent roster, its own router, its own escalation
model, or its own hook chain (examples: `ruflo` / ex-claude-flow,
CrewAI, AutoGen, MetaGPT) is out-of-scope for default adoption
because Hard Rules #1 (only `tech-lead` talks to the customer)
and #4 (live customer approval on safety-critical changes) are
not expressible as a learned-routing reward signal without bolt-
ons that defeat the point. A project that genuinely needs such a
framework records an ADR under `docs/adr/` using
`docs/templates/adr-template.md` (Three-Path shape) that
**explicitly supersedes FW-ADR-0001** and identifies, per Hard Rule,
how the framework preserves the invariant or why the project is
willing to weaken it. Customer sign-off on the ADR is required
before the framework is installed.

**Memory rule-of-thumb.** A recalled memory is a pointer, not a
citation. If a recommendation would act on the recalled fact,
verify against the current file, `git log`, or a fresh read
first. Stale memory that caused a near-miss is worth noting in
`docs/pm/LESSONS.md` for future summarizer tuning.

## Query patterns (binding)

Memory query precedes long-artifact reads, customer escalations,
and ADR-topic reopens. The four canonical patterns:

| When you would otherwise... | Run memory query first | Then verify against |
|---|---|---|
| Read old `CUSTOMER_NOTES.md` entries | `search memory for "<topic> customer decision"` | `CUSTOMER_NOTES.md` |
| Read old schedules | `search memory for "current milestone blocker"` | `docs/pm/SCHEDULE.md` |
| Ask the customer | `search memory + OPEN_QUESTIONS for similar prior answer` | `CUSTOMER_NOTES.md` + `docs/OPEN_QUESTIONS.md` |
| Reopen an ADR topic | `search memory for "<module> accepted ADR"` | the relevant `docs/adr/*.md` file |

These patterns are mandatory before escalating to `tech-lead`
(escalation chain rule, `CLAUDE.md` § Escalation protocol step 1).
The memory layer is pointer-only, not authority: a hit points at
a file / commit / issue to verify against the current repo state.
If memory and repo disagree, the repo wins; flag the stale memory
in `docs/pm/LESSONS.md`.
