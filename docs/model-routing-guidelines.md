# Agent Model Routing Guidelines

Guidance for choosing model family, effort level, and planning mode for
the template's agent roles. This file is provider-neutral first, then
maps the tiers to current OpenAI / ChatGPT and Claude / Claude Code
model families.

**Binding status**: This file is the binding default for fresh scaffolds (FR-016 + spec clarification 5). Downstream projects MAY override per-agent default-model assignments in a marked project-local supplement at `docs/model-routing-guidelines.local.md` (or wherever the project keeps local routing supplements), so long as the supplement carries the `project_local_override_marker` per `sw-dev-team-template/schemas/model-routing.schema.json`.

**Model ID currency**: Exact provider/model identifiers in this file are RUNTIME-REVERIFIABLE — they may change between releases. Routing logic should rely on the model-class column (e.g., `claude-sonnet`, `gemini-pro`) rather than literal IDs. Exact IDs are confirmed at each MINOR-boundary Release per spec clarification 8.

Re-verify provider mappings before each tagged release; model catalogs
and aliases change over time.

Sources checked on 2026-05-03:

- OpenAI API model catalog:
  <https://developers.openai.com/api/docs/models>
- Claude Code model configuration:
  <https://code.claude.com/docs/en/model-config>
- Claude model overview:
  <https://platform.claude.com/docs/en/about-claude/models/overview>

## Policy shape

The template should specify capability tiers, not only hard-coded model
IDs. Exact model IDs may be pinned by a project for auditability, cost
control, or provider availability, but the agent contract should remain
portable across ChatGPT / Codex, Claude Code, and future providers.

Use four tiers:

| Tier | Use for | OpenAI / ChatGPT mapping | Claude / Claude Code mapping |
|---|---|---|---|
| `fast` | Mechanical extraction, classification, short summaries, label hygiene | `gpt-5.4-nano` (runtime-reverifiable) or successor nano-class model | `haiku` (runtime-reverifiable) |
| `standard` | Routine documentation, simple project-management updates, narrow test edits | `gpt-5.4-mini` (runtime-reverifiable) or successor mini-class model | `sonnet` (runtime-reverifiable) |
| `strong` | Default for coding agents, QA, release work, non-trivial research synthesis | `gpt-5.4` (runtime-reverifiable) or current affordable frontier-class model | `sonnet` with `high` effort, or `opusplan` (runtime-reverifiable) when planning is important |
| `frontier` | Architecture, security, code review, major tradeoffs, ambiguous cross-system work | `gpt-5.5` (runtime-reverifiable) or current flagship model | `opus`, `best`, or `opusplan` (runtime-reverifiable) |

Provider notes:

- OpenAI currently recommends `gpt-5.5` (runtime-reverifiable) for
  complex reasoning and coding, and `gpt-5.4-mini` / `gpt-5.4-nano`
  (runtime-reverifiable) for lower-latency, lower-cost workloads.
- Claude Code aliases are preferable in template docs because `opus`,
  `sonnet`, `haiku`, and `opusplan` resolve to current recommended
  models for the configured provider. Pin full model IDs only when a
  project needs reproducibility.
- `opusplan` is a good fit for work that benefits from frontier planning
  followed by efficient execution: it uses Opus in plan mode and Sonnet
  outside plan mode.

## Effort levels

Effort controls reasoning spend, not authority. A higher-effort answer
is still subordinate to repo facts, customer decisions, tests, and code
review.

| Effort | Use when | Escalate when |
|---|---|---|
| `low` | The task is short, mechanical, and easy to verify. | The output affects requirements, contracts, code, security, release state, or customer-visible docs. |
| `medium` | The task is routine but needs some judgment: ordinary docs, PM artifact updates, focused test planning. | There are conflicting sources, unclear acceptance criteria, or multi-file consequences. |
| `high` | Default for intelligence-sensitive work: coding, QA, release, research synthesis, review, security triage. | The task is architectural, safety/security-critical, or a failed pass needs a second opinion. |
| `xhigh` | Deep review, architecture, security design, release-blocking bugs, ambiguous cross-system tradeoffs. | The issue remains unresolved after a scoped high-effort pass. |
| `max` | Claude-only one-off emergency/deep reasoning mode. Use sparingly for release blockers or high-stakes design reviews. | Prefer recording why `max` was used; do not make it the project default without an ADR. |

For OpenAI mappings, use the provider's available reasoning effort
values. Current GPT-5.5 / GPT-5.4 family (runtime-reverifiable) docs
list `none`, `low`, `medium`, `high`, and `xhigh`. Treat Claude `max`
as OpenAI `xhigh` plus an explicit prompt asking for a deeper review
pass.

### Codex `reasoning_effort` policy

In Codex, set `reasoning_effort` from the task class, not from personal
preference:

| Task class | Default `reasoning_effort` |
|---|---|
| Mechanical lookup, formatting, deterministic extraction | `low` |
| Routine docs, PM updates, narrow non-code edits | `medium` |
| Coding, QA, release, synthesis, non-trivial review | `high` |
| Architecture, security, code review, safety/privacy/API/data-model work, conflicting-specialist arbitration | `xhigh` |

Using the table default needs no special note. Any non-default effort
requires a one-line rationale in the dispatch brief, Turn Ledger, or
handover, e.g. "lowered to `medium` because this is a reversible
single-file wording edit" or "raised to `xhigh` because the change
affects auth and release gating." Do not lower effort for safety,
security, privacy, public API, data-model, or customer-authorization
work without customer-visible rationale.

## Plan mode

Run plan mode before execution when the work has one or more of these
properties:

- Workflow-pipeline trigger is not `none`: new external dependency,
  public API change, cross-module boundary, safety-critical path,
  auth / authz / secrets / PII / network-exposed path, or data-model
  change.
- The ask changes agent-team operating policy, escalation rules,
  model-routing policy, release procedure, or project coordination.
- The task touches multiple files and the order of edits matters.
- The implementation strategy is not obvious from existing patterns.
- The cost of a wrong first edit is high: destructive migration,
  release tag, security posture, legal/compliance text, or customer
  commitment.
- Multiple operators or machines may act on the same work item and need
  a stable handoff plan.

Skip plan mode for:

- Single-line typos or link fixes.
- Deterministic formatting / TOC generation.
- Read-only lookups where no project decision is made.
- Narrow bug fixes with a clear failing test and no wider contract
  impact.

Plan mode output should be short: goal, affected files, risks, routing,
verification. Do not let plan mode become a substitute for ADRs,
proposals, or issue templates when those are triggered by the workflow
pipeline.

## Class taxonomy

Four capability tiers organize model selection across all agents and harnesses. These tiers are conceptual labels; the binding per-agent assignments are in the canonical table below.

- **`fast`** — mechanical extraction, classification, short summaries. Maps to `claude-haiku`, `openai-mini`, `gemini-flash`.
- **`standard`** — routine documentation, narrow project-management updates, simple lookups. Maps to `claude-sonnet`, `openai-coding`, or `gemini-pro` depending on task affinity.
- **`strong`** — default for coding, QA, release work, and research synthesis. Typically `claude-sonnet` with `high` effort, or `openai-coding`/`gemini-pro` for their respective affinity workloads.
- **`frontier`** — architecture decisions, security, code review, major cross-system tradeoffs. Maps to `claude-opus`, `openai-frontier`, or `gemini-pro` at its ceiling.

Each harness resolves class abstractions to concrete model IDs at runtime. opencode reaches both Gemini and OpenAI providers; Claude Code reaches only Claude; Codex reaches only OpenAI. The binding table below is harness-agnostic; each harness applies the appropriate provider column at runtime.

## Elevation triggers

Raise tier or effort when any of these happen:

- Two failed implementation or review passes on the same issue.
- Specialist disagreement blocks progress.
- The task crosses a workflow-pipeline trigger clause.
- The work affects security, safety, privacy, data model, public API,
  release, migration, or customer-visible acceptance.
- The agent is summarizing or reconciling long context rather than
  reading a small known file.
- The answer will be used by multiple operators as coordination state.
- The agent must decide whether to ask the customer.

Lower tier or effort when all of these are true:

- The task is reversible.
- The expected output is small.
- The source of truth is local and explicit.
- Verification is deterministic.
- The result does not change contracts, requirements, code behavior, or
  customer-facing wording.

## Governance

- Model policy changes are post-v1.0.0 work and should be treated as
  additive unless they alter binding agent behavior.
- Pinning exact provider model IDs in shipped template files requires a
  release note and a "verified on" date.
- Changing default tiers for `architect`, `security-engineer`,
  `code-reviewer`, or `tech-lead` requires code-reviewer review.
- Making GitHub Projects, provider-specific tools, or a specific model
  vendor mandatory for downstream projects requires an ADR.

## Provider/model ID conventions

- **Anthropic**: `anthropic/claude-{opus,sonnet,haiku}-<minor>-<patch>` (e.g., `anthropic/claude-sonnet-4-7`). Per-class fallback uses the closest peer within the same class.
- **OpenAI**: `openai/<model-id>` (e.g., `openai/gpt-5-pro`). The `openai-coding` class is for code-heavy tasks; `openai-frontier` for advanced reasoning; `openai-mini` for cheap interactive use.
- **Google (Gemini)**: `google/gemini-<class>-<minor>` (e.g., `google/gemini-pro-2.5`). `gemini-pro` for substantive synthesis; `gemini-flash` for fast iteration.
- **OpenCode harness**: per ADR-0009, OpenCode is a harness adapter; the model identifier is whichever provider/model OpenCode's adapter resolves to. The routing rule that fires applies to the resolved upstream identifier, not OpenCode itself.

All literal IDs marked `(runtime-reverifiable)` may change between MINOR-boundary Releases. Use the class column for binding routing rules.

## Fallback behavior

Fallback triggers (per spec clarification 8 + FR-020):

- `credit_exhausted` — provider account has insufficient credit for the request.
- `provider_unavailable_5xx` — provider returned HTTP 5xx.
- `provider_timeout` — provider timed out before responding.
- `provider_rate_limit` — provider returned a rate-limit response (HTTP 429 or equivalent).

Substitution policy: **closest peer in the same model class** first (e.g., Sonnet-class request → next available Sonnet-tier model). If no same-class peer is available, substitute **one tier down** and append `; downgraded_one_tier` to `fallback_reason`. Fallback MUST NOT change role authority or output format.

Every fallback event is logged to `docs/pm/fallback-log.jsonl` via `scripts/log-fallback.sh` (FR-020). The log carries six required fields: `agent`, `requested_model`, `actual_model`, `fallback_reason`, `timestamp` (ISO 8601 UTC), `task_id`.

## Frontier-only escalation

Frontier-class models (`claude-opus`, `openai-frontier`, `gemini-pro`) are NOT the default for any agent. They are reserved for the per-agent escalation conditions in the binding canonical table below. Escalation is per-task: when the predicate fires, the routing wrapper selects the frontier model for that task only; subsequent tasks revert to the default.

## Binding per-agent default-class table

The table below is the single canonical binding default for fresh template scaffolds (FR-019 + spec clarification 5). It supersedes the retired `## Role defaults` tier table. Downstream projects MAY override per-agent assignments in a marked project-local supplement; the supplement MUST carry the `project_local_override_marker` per `schemas/model-routing.schema.json`.

Class names use the enum from `schemas/model-routing.schema.json`: `claude-opus`, `claude-sonnet`, `claude-haiku`, `gemini-pro`, `gemini-flash`, `openai-frontier`, `openai-coding`, `openai-mini`.

Provider column key: **Claude equivalent** = fallback used in Claude Code; **OpenAI equivalent** = class used in Codex; **Gemini equivalent** = class used in opencode. Harness adapters resolve these class abstractions to concrete model IDs at runtime.

| Agent | default_class | Claude equivalent | OpenAI equivalent | Gemini equivalent | frontier_only_when |
|---|---|---|---|---|---|
| `tech-lead` | `claude-sonnet` | `sonnet` | `openai-coding` | `gemini-pro` | unresolved conflict, safety/customer-critical routing |
| `architect` | `claude-sonnet` | `sonnet` | `openai-coding` | `gemini-pro` | ADR conflict, major boundary, safety/security architecture |
| `software-engineer` | `openai-coding` | `sonnet` | `openai-coding` | `gemini-pro` | ambiguous design tradeoff |
| `release-engineer` | `openai-coding` | `sonnet` | `openai-coding` | `gemini-pro` | release blocker or cross-harness failure |
| `code-reviewer` | `claude-sonnet` | `sonnet` | `openai-coding` | `gemini-pro` | hard-block, ADR conflict, safety/security |
| `qa-engineer` | `claude-sonnet` | `sonnet` | `openai-coding` | `gemini-pro` | safety/timing-critical validation |
| `researcher` | `gemini-pro` | `sonnet` | `openai-coding` | `gemini-pro` | disputed source synthesis |
| `project-manager` | `gemini-flash` | `haiku` | `openai-mini` | `gemini-flash` | major scope/risk/stakeholder conflict |
| `tech-writer` | `claude-sonnet` | `sonnet` | `openai-coding` | `gemini-pro` | release-critical public docs |
| `security-engineer` | `claude-sonnet` | `sonnet` | `openai-coding` | `gemini-pro` | safety-critical authentication / secrets / network-exposed change |
| `sre` | `claude-sonnet` | `sonnet` | `openai-coding` | `gemini-pro` | DR-tier escalation, performance-critical incident |
| `onboarding-auditor` | `claude-sonnet` | `sonnet` | `openai-coding` | `gemini-pro` | (advisory-only role; frontier escalation not gating) |
| `process-auditor` | `claude-sonnet` | `sonnet` | `openai-coding` | `gemini-pro` | (advisory-only role; frontier escalation not gating) |
| `sme-template` | `claude-sonnet` | `sonnet` | `openai-coding` | `gemini-pro` | (default for SMEs; haiku for tiny lookups) |

## Availability fallback

The binding default-class table above specifies each agent's *preferred* class. When the preferred class is **unavailable** in the active harness — quota exhausted, model retired, provider outage — the routing wrapper (or operator, in harnesses without one) MUST escalate to the next-higher tier **within the same provider** before degrading across providers. Availability fallback does NOT require the per-task escalation predicate in `frontier_only_when` to be satisfied; it is an operator-level concern separate from per-task escalation.

Provider-specific fallback chains:

- **Claude Code** (Claude only): preferred `haiku` → fall up to `sonnet` → fall up to `opus` (frontier).
- **Codex** (OpenAI only): preferred `openai-mini` → fall up to `openai-coding` → fall up to `openai-frontier`.
- **opencode** (Gemini + OpenAI both reachable): preferred `gemini-flash` → fall up to `gemini-pro`. If both Gemini tiers exhausted: cross-provider degrade to the OpenAI equivalent column (`openai-mini` or `openai-coding` as appropriate). Same shape for an OpenAI starting point exhausted.

Note that fallback **up the tier** (toward frontier) is the documented path. Falling **down** (toward `fast`) is only acceptable for non-load-bearing roles where the lower tier is explicitly listed as acceptable in the per-agent row — currently none of the 14 baseline roles have such an exception. The frontier class (`claude-opus`, `openai-frontier`, `gemini-pro` at ceiling) remains the upper bound; if frontier is also unavailable, work pauses or the operator escalates the availability issue to the customer.

CI lint policy (per `scripts/lint-agent-model-routing.sh`): an agent contract's `model:` field MUST equal the preferred Claude equivalent OR the next-higher Claude tier (the availability-fallback). For example, a `sonnet`-defaulted role may declare `model: sonnet` (preferred) or `model: opus` (fallback) and pass the lint; `model: haiku` would fail. The same fallback-permissive rule applies to the Codex-side contract surface.

