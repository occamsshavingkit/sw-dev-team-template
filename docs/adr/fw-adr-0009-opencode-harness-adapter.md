---
name: fw-adr-0009-opencode-harness-adapter
description: Classify OpenCode as a harness/provider adapter; it must not redefine roles, escalation, source-of-truth, or customer interface.
status: accepted
date: 2026-05-13
---


# ADR fw-adr-0009: OpenCode harness-adapter

**Status**: Accepted
**Date**: 2026-05-13
**Owner**: architect
**Reviewers**: code-reviewer, release-engineer, tech-lead
**Supersedes**: none
**Superseded by**: none

## Context

The framework now runs across a cross-AI ecosystem: Claude Code is the primary harness, Codex is the established second harness via the `AGENTS.md` adapter, and OpenCode, Gemini, and OpenAI-class harnesses are arriving as additional substrates. Each harness ships its own agent-configuration surface, command vocabulary, and provider-routing affordances. Without a binding classification, every new harness risks introducing a parallel role roster, escalation chain, and customer interface — collapsing the single source-of-truth the framework depends on.

FR-022 already constrains the canonical role files (`schemas/agent-contract.schema.json`) and generated-artifact frontmatter (`schemas/generated-artifact.schema.json`, T059), and M4.3 promoted `docs/model-routing-guidelines.md` to binding-status with a `binding` flag plus a `project_local_override_marker`. M1.1 established the pattern of compact runtime contracts under `docs/runtime/agents/` compiled from canonical sources. The M0 RISKS register flags R-2 (authority drift across harnesses) and R-4 (model-routing volatility) as the dominant failure modes; OpenCode's native agent-file format makes both risks acute unless the adapter boundary is named now.

This ADR resolves the open M5.1 question — is OpenCode a peer orchestrator or an adapter? — before FR-021 (thin adapter form) and FR-019 (extended model-routing) build on top of an unstated assumption.

## Decision

OpenCode is classified as a **HARNESS/PROVIDER ADAPTER**. It MAY configure models, providers, and commands and MAY ship thin agent wrappers that point at `.claude/agents/<role>.md` plus an optional local supplement; it MUST NOT redefine the role roster, escalation chain, source-of-truth hierarchy, or customer interface.

The four explicit prohibitions are binding from this ADR's acceptance date:

1. **No competing role roster.** OpenCode MUST NOT define a parallel set of canonical roles; the roster in `CLAUDE.md` "Agent roster" remains authoritative.
2. **No competing escalation chain.** The strict escalation protocol in `CLAUDE.md` (tech-lead as sole customer interface, researcher as customer-truth steward) applies inside OpenCode unchanged.
3. **No competing source-of-truth hierarchy.** Canonical authority remains in `.claude/agents/*.md`, `CLAUDE.md`, `AGENTS.md`, `docs/adr/*.md`, and `docs/workflow-pipeline.md` (M4.4 canonical). OpenCode-native files are derived artifacts.
4. **No competing customer interface.** Only `tech-lead` (the main harness session) talks to the customer, regardless of which harness hosts the session.

What OpenCode MAY do: configure models, providers, and commands per Constitution VII; supply thin agent wrappers under `.opencode/agents/<role>.md` that reference `.claude/agents/<role>.md` plus an optional local-supplement field; and serve as the harness over which model fallback (FR-020) and routing (FR-019) operate.

## Consequences

**Positive**:
- Single role model preserved across Claude Code, Codex, OpenCode, Gemini, and OpenAI — agents behave consistently regardless of harness.
- Adapter pattern is auditable: a manual edit to `.opencode/agents/<role>.md` fails lint via the `canonical_sha` mismatch (FR-022 generated-artifact schema + FR-021 thin-adapter rule).
- The M5.4 generated adapters can be re-compiled deterministically from `.claude/agents/*.md`; no risk of drift.

**Negative**:
- OpenCode-specific features (e.g., per-provider tool configurations, harness-specific commands) require careful classification: are they adapter configuration (allowed) or role behavior (forbidden)? The default answer is "adapter configuration"; close cases route to `tech-lead` for ruling.
- Downstream operators can't extend a role by editing `.opencode/agents/<role>.md`; the path is via the canonical `.claude/agents/<role>.md` plus the optional local supplement field.

**Neutral**:
- Codex (the existing cross-harness adapter via `AGENTS.md`) is structurally similar; this ADR formalizes the same pattern for OpenCode.

## Alternatives considered

1. **OpenCode as parallel orchestrator** (rejected): two role rosters, two escalation chains, two customer interfaces — violates Constitution I (sole customer interface) and Constitution III (source authority). Drift is inevitable.
2. **OpenCode-native role files** (rejected): a separate `.opencode/agents/<role>.md` set as canonical would require manual sync with `.claude/agents/<role>.md`. Per Constitution III "manual mirrors are prohibited", this fails before it starts.
3. **OpenCode as workflow-only tool** (rejected as too narrow): leaves the role-routing question unanswered. Routing must be solved alongside the adapter classification.

The chosen path (harness adapter only; canonical role files remain `.claude/agents/*.md`) is the simplest classification compatible with Constitution I + III + VII.

## Enforcement

- `scripts/lint-agent-contracts.sh` (T060, FR-023) validates canonical agent files against `schemas/agent-contract.schema.json` (T009/T058, FR-022).
- `scripts/compile-runtime-agents.sh` (T012; extended at T054 to also generate `.opencode/agents/<role>.md`) emits generated artifacts with `canonical_sha` frontmatter; manual edits to adapters fail the SHA check (FR-021).
- This ADR is binding; any future OpenCode-related ADR that conflicts requires explicit supersession.

## References

- FR-018 + M5.1 in `specs/006-template-improvement-program/spec.md`
- Spec clarification 5 (binding default + project-local override path for model-routing)
- Constitution I (sole customer interface), III (source authority), VII (adapter discipline)
- `docs/adr/fw-adr-0008-tech-lead-orchestration-boundary.md` (precedent — Codex pattern)
- `docs/model-routing-guidelines.md` (M4.3 binding-status + M5.2 extensions)
- `schemas/model-routing.schema.json` (`binding` + `project_local_override_marker` fields)
- `schemas/generated-artifact.schema.json` (canonical_sha + classification: generated; T059)
