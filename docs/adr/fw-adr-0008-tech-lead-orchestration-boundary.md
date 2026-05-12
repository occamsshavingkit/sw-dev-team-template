# FW-ADR-0008 — Tech-Lead Orchestration Boundary

## Status

- **Accepted**
- **Date:** 2026-05-03
- **Deciders:** `architect`, `tech-lead`
- **Consulted:** `project-manager`, `release-engineer`,
  `process-auditor`

## Context and Problem Statement

Downstream use of `v1.0.0-rc3` surfaced related rc4 blockers: issue
#77, where `tech-lead` could write customer-truth entries directly into
`CUSTOMER_NOTES.md`; issue #82, where the main session could author
production artifacts without the owning specialist or `code-reviewer`
gate; and Codex adapter issues #93, #94, #95, #96, #100, and #101,
where hook parity, teammate-name mapping, per-session dispatch
authorization, `reasoning_effort`, specialist-slot queues, and prompt
specialist closure were underspecified. These failures weaken Hard
Rule #1 because the sole customer interface becomes mixed with artifact
production, and they weaken Hard Rule #3 because reviewable ownership
is no longer clear. On safety, security, and release paths this also
risks obscuring the evidence required by Hard Rules #4 and #7.

The template needs a binding framework boundary that works in both
Claude Code and Codex. The main session still plays `tech-lead`
directly, but production artifacts, requirements, release notes,
ADRs, code, scripts, and customer-truth records need specialist
ownership. Customer truth has one steward: `researcher` appends
verbatim entries after `tech-lead` routes or queues the customer's
answer.

## Decision Drivers

- Preserve `tech-lead` as the sole customer interface.
- Preserve `researcher` as steward of customer-truth records.
- Preserve specialist ownership and reviewability of production
  artifacts.
- Keep the rule harness-neutral across Claude Code and Codex.
- Avoid adding a new canonical role during rc4.
- Preserve Hard Rules #1, #3, #4, #7, and #8 without weakening their
  evidence trails.
- Preserve Codex parity when Claude Code hooks or named agent panels are
  unavailable.
- Keep specialist slot pressure from collapsing routed work back into
  local `tech-lead` implementation.

## Considered Options

### Option M — Minimalist

Add explicit prose saying `tech-lead` orchestrates and does not author
production artifacts directly, with a narrow exception for
orchestration records and tool-bridge work. Customer answers are
routed to `researcher` for verbatim `CUSTOMER_NOTES.md` entries.

- **Pros:** small rc4 change, no roster expansion, directly addresses
  #77 and #82.
- **Cons:** relies on review discipline and hook support rather than
  full mechanical enforcement.

### Option S — Scalable

Add the prose boundary, add guardrails where practical, route
customer-truth writes through `researcher`, and require pre-close
self-audit plus `code-reviewer` review before commit. For Codex, mirror
Claude hook safeguards with an explicit pre-close checklist, enforce
`AGENT_NAMES.md` in public text even when worker IDs differ, require
per-session dispatch authorization, queue specialist work when slots are
full, close completed specialists promptly, and record rationale for
non-default `reasoning_effort`.

- **Pros:** improves enforceability without changing the harness or
  canonical roster.
- **Cons:** adds process weight and still cannot prevent every manual
  bypass in every harness.

### Option C — Creative

Split `tech-lead` into separate customer-interface and orchestration
roles, with a new artifact-router role owning all dispatches.

- **Pros:** makes duties maximally explicit.
- **Cons:** breaking roster change during rc4; more ceremony for
  ordinary work; high migration cost.

## Decision Outcome

**Chosen option:** S

`tech-lead` remains the top-level customer interface and orchestrator.
Customer-answer prose is routed by `tech-lead` and stewarded by
`researcher`; production artifacts route to the owning specialist;
`tech-lead` direct writes are limited to orchestration artifacts and
tool-bridge work that a specialist cannot perform in its sandbox.
Pre-close review checks for main-session edits that should have been
routed. Claude Code may enforce some checks through hooks; Codex uses
the binding checklist in `AGENTS.md`. Codex dispatches also require a
per-session authorization record, public names from `docs/AGENT_NAMES.md`,
queued waves when slots are full, prompt closure of accepted
specialists, and documented rationale for non-default
`reasoning_effort`.

## Consequences

### Positive

- Preserves the existing canonical roster for rc4.
- Makes customer-truth stewardship auditable.
- Reduces the chance that a whole session bypasses specialist review.
- Preserves Hard Rule #1 by keeping customer contact in `tech-lead`
  while moving durable customer-truth capture to `researcher`.
- Preserves Hard Rules #3, #4, and #7 by keeping production,
  safety-critical, and security evidence attached to specialist-owned
  artifacts that can be reviewed before commit or release.

### Negative / Trade-Offs Accepted

- Some small edits may require explicit routing or a recorded
  exception.
- Enforcement is partly procedural in harnesses without write-guard
  hooks.
- Queued specialist waves may increase latency when Codex slots are
  full, but preserve ownership and reviewability.

## Verification

- `CLAUDE.md` Hard Rules include the orchestration boundary.
- `.claude/agents/tech-lead.md` describes the same boundary.
- Customer-answer instructions route through `researcher`, who
  appends verbatim `CUSTOMER_NOTES.md` entries.
- `code-reviewer` flags non-trivial direct main-session edits before
  commit.
- Codex turns run the `AGENTS.md` pre-close checklist when Claude hooks
  are unavailable.
- Codex customer-facing text uses `docs/AGENT_NAMES.md` names, not
  arbitrary harness worker IDs.
- Specialist-slot exhaustion creates queued waves unless the customer
  grants an explicit local-implementation exception.
- Non-default `reasoning_effort` has a recorded rationale.

## Links

- `docs/v1.0-rc4-stabilization.md` — WP-2, issues #77 and #82.
- Upstream issues #93, #94, #95, #96, #100, and #101.
- `docs/audits/v1.0.0-rc4-review.md`
