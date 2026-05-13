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

## Role defaults

| Role | Default tier | Default effort | Plan mode default | Escalation rule |
|---|---|---|---|---|
| `tech-lead` | `frontier` for scoping / orchestration; `strong` for routine turns | `high` | On for multi-step tasks and customer-impacting decisions | Escalate to `frontier` / `xhigh` for policy, architecture, release, or conflicting-specialist arbitration. |
| `architect` | `frontier` | `xhigh` | On by default | Do not downgrade for ADRs, cross-boundary decisions, or technology selection. |
| `software-engineer` | `strong` | `high` | On for triggered or multi-file work | Escalate to `frontier` for unfamiliar codebases, cross-module refactors, or repeated failed tests. |
| `code-reviewer` | `frontier` | `xhigh` | Usually off; review stance is enough | Use plan mode for full release audits or large diff review strategy. |
| `security-engineer` | `frontier` | `xhigh` | On for threat models and Rule #7 paths | Never use `fast`; escalate for auth, secrets, PII, network exposure, or supply-chain risk. |
| `qa-engineer` | `strong` | `high` | On for test strategy, off for small test edits | Escalate for system/acceptance strategy or defect isolation after one failed pass. |
| `researcher` | `standard` for lookup; `strong` for synthesis | `medium` lookup, `high` synthesis | Off for lookup, on for prior-art surveys | Escalate for conflicting official sources or standards interpretation. |
| `project-manager` | `standard` | `medium` | On for milestone planning or change control | Escalate to `strong` for risk tradeoffs, multi-operator coordination, or release-scope decisions. |
| `release-engineer` | `strong` | `high` | On for tagging, migration, packaging, CI changes | Escalate to `frontier` for failed release smoke, migration conflicts, or reproducibility gaps. |
| `sre` | `strong` | `high` | On for production-impacting work | Escalate for SLO/capacity tradeoffs or incident-response policy. |
| `tech-writer` | `standard` | `medium` | Off for ordinary docs, on for information architecture | Escalate to `strong` for release notes, binding docs, or cross-doc rewrites. |
| `onboarding-auditor` | `strong` | `high` | Off; audit prompt defines the pass | Escalate only if the audit scope spans multiple product surfaces or release readiness. |
| `process-auditor` | `strong` | `high` | Off; audit prompt defines the pass | Escalate for recommendations that would alter hard rules or agent contracts. |
| `sme-<domain>` | `standard` | `medium` | Off unless asked to structure a domain decision | Escalate to `strong` for high-stakes domain ambiguity; never replace the customer or external SME. |

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
