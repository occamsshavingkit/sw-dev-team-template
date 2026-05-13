# FW-ADR — OpenCode Harness Adapter

## Status

- **Accepted**
- **Date:** 2026-05-12
- **Deciders:** `architect`
- **Consulted:** `release-engineer` perspective via M5 release-verification requirements; `docs/prior-art/T030.md`; `docs/proposals/T030.md`

## Context and Problem Statement

M5 adds OpenCode, Gemini, OpenAI, and Claude routing support to the
template. The risk is not that another harness can run the work; the
risk is that harness-specific agent definitions introduce a second role
roster, escalation path, source hierarchy, or customer interface.
`CLAUDE.md`, `AGENTS.md`, and `.claude/agents/*.md` already define the
canonical role model, and FW-ADR-0008 keeps `tech-lead` as the top-level
orchestrator while preserving specialist ownership.

## Decision Drivers

- Preserve one canonical role model across Claude Code, Codex, OpenCode,
  and future harnesses.
- Preserve `tech-lead` as the sole customer interface.
- Preserve specialist ownership, output formats, review gates, and source
  hierarchy from the canonical role files.
- Allow provider/model configuration without requiring a specific vendor
  for downstream projects.
- Avoid copied full-role mirrors that drift from `.claude/agents/*.md`.
- Keep model IDs release-verifiable because provider catalogs and aliases
  change.

## Considered Options

### Option M — Minimalist

Document OpenCode only as another harness name in `AGENTS.md`, with no
ADR and no adapter boundary.

- **Pros:** smallest documentation change.
- **Cons:** leaves future OpenCode role files free to become independent
  policy and gives reviewers no durable decision record for rejecting
  parallel role rosters.

### Option S — Scalable

Treat OpenCode as a harness/provider adapter over the existing role
model. OpenCode may configure providers, model classes, commands, and
thin generated or generator-backed role wrappers, but wrappers must read
the canonical role file and any local supplement before acting. The
adapter cannot redefine roles, escalation, customer contact, output
formats, review gates, or canonical inputs.

- **Pros:** supports OpenCode and multi-provider routing while preserving
  the existing role contract and release evidence path.
- **Cons:** requires adapter freshness checks and review discipline until
  a generator/lint path is fully implemented.

### Option C — Creative

Define an OpenCode-native role system, then map it back to the template's
roles during handoff.

- **Pros:** maximizes use of native harness conventions.
- **Cons:** creates a parallel role model, increases drift risk, obscures
  customer-interface ownership, and conflicts with FR-009/FR-010.

## Decision Outcome

**Chosen option:** S.

OpenCode is a harness/provider adapter, not a second orchestration or
role system. It may configure model providers, model classes, commands,
and thin role wrappers. It must not redefine the role roster, escalation
chain, customer interface, source hierarchy, specialist ownership,
required output formats, or review gates.

Canonical roles remain `CLAUDE.md`, `AGENTS.md`, `.claude/agents/*.md`,
and any matching `.claude/agents/*-local.md` supplement. Generated or
generator-backed OpenCode adapters are execution surfaces only and remain
subordinate to those inputs.

## Consequences

### Positive

- Cross-AI routing can include OpenCode without weakening the existing
  role taxonomy.
- Reviewers have a concrete negative check: no OpenCode-native `coder`,
  `reviewer`, or similar role may bypass `software-engineer`,
  `code-reviewer`, or `tech-lead` authority.
- Adapter files can stay small and generated, reducing manual mirror
  drift.
- Release verification can focus on model/provider IDs and adapter
  freshness rather than revalidating a second role model.

### Negative / Trade-Offs Accepted

- OpenCode-specific ergonomics are constrained by the template's existing
  role contract.
- Until M6 generator/lint work lands, adapter freshness is enforced by
  documented review expectations rather than a completed compiler.
- Provider/model fallback records add process overhead when runtime
  routing differs from the requested model.

## Verification

- `docs/model-routing-guidelines.md` documents provider/model ID
  conventions, Gemini classes, frontier escalation, fallback behavior,
  fallback logging, and release-time exact model verification.
- `AGENTS.md` states OpenCode adapters are thin generated or
  generator-backed wrappers over canonical role inputs, not parallel role
  contracts.
- No OpenCode adapter may duplicate full role text or omit matching local
  supplement loading.
- Fallback or provider substitution changes only execution model, not role
  authority, output format, review gate, source hierarchy, or customer
  interface.
- T035 must validate that `CLAUDE.md`, `AGENTS.md`, and
  `.claude/agents/*.md` do not introduce a parallel role model.

## Links

- `docs/prior-art/T030.md`
- `docs/proposals/T030.md`
- `docs/model-routing-guidelines.md`
- `AGENTS.md`
- `CLAUDE.md`
- `.claude/agents/*.md`
- `docs/adr/fw-adr-0008-tech-lead-orchestration-boundary.md`
