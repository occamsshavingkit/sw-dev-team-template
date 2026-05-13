<!--
Sync Impact Report
Version change: 1.0.0 -> 1.1.0
Modified principles: none (titles and rules unchanged)
Added sections: Project Scope (top-of-document scope statement)
Removed sections: none
Templates requiring updates: ✅ .specify/templates/plan-template.md (already references Principle VI framework/project boundary); ✅ .specify/templates/spec-template.md (no changes required); ✅ .specify/templates/tasks-template.md (no changes required); ✅ .specify/templates/checklist-template.md (no changes required)
Follow-up TODOs: none (RATIFICATION_DATE resolved to 2026-05-12)
-->

# SW-dev Team Template Constitution

## Project Scope

This constitution governs the meta-project rooted at `/home/quackdcs/SWEProj`
whose primary working target is the subdirectory `./sw-dev-team-template`
(the active template repository). Sessions start at the meta-project root;
framework and template edits MUST target `./sw-dev-team-template` unless the
task explicitly targets meta-project scaffolding artifacts in the root. Both
the meta-project and the template subdirectory are bound by every principle,
operational constraint, and governance rule below.

## Core Principles

### I. Role-Bound Delegation and Sole Customer Interface

The main session acts as `tech-lead` and is the only interface to the
customer. Specialist-owned work MUST be routed to the canonical owning role,
not authored by `tech-lead`, except for orchestration records and explicit
tool-bridge exceptions. Specialists MUST return findings, blockers, and
escalation requests to `tech-lead`; they MUST NOT contact the customer or
spawn other specialists.

Rationale: one customer interface prevents contradictory answers, preserves
role accountability, and keeps specialist work auditable.

### II. Token and Context Economy

Every recurring runtime instruction, live register, prompt, adapter, and
template addition MUST justify its context cost. Live working surfaces MUST
remain short and current; history belongs in archives, evidence files, or
generated summaries that point back to canonical sources. Work that reduces
recurring context load has priority over feature expansion when both compete
for the same delivery capacity.

Rationale: this template's effectiveness depends on preserving scarce model
context for current decisions rather than stale process text.

### III. Canonical Source Authority

Every artifact MUST be classified in practice as canonical, generated, or
ephemeral. Canonical artifacts are human-maintained sources of truth;
generated artifacts are reproducible outputs from canonical inputs; ephemeral
artifacts are temporary work products until explicitly promoted. Manual mirrors
are prohibited: if two artifacts need the same content, one MUST generate,
link to, or supersede the other.

Rationale: source authority discipline prevents documentation drift, adapter
drift, and generated artifact edits that silently become policy.

### IV. Atomic Customer Questions and Intake Traceability

Customer-facing questions MUST be customer-owned, atomic, and asked only when
tools and specialists needed for that turn are idle. The final customer-facing
line MUST contain the single question when a question is asked. Internal
question queues MAY batch multiple items, but customer-facing messages MUST NOT
bundle independent decision axes. Customer answers and customer-truth records
MUST be routed to `researcher` for verbatim capture in the designated intake or
customer-notes artifact.

Rationale: atomic intake protects the customer's attention and creates a
traceable record for future agents.

### V. Quality Gates Before Commit

No commit is valid without the appropriate specialist review for the changed
artifact type. Code changes require implementation verification and
`code-reviewer` review before commit. Security-sensitive, safety-critical,
irreversible, network-exposed, authentication, authorization, secrets, or PII
changes require the additional approvals defined in the runtime guidance.
Non-code documentation and template changes require alignment checks against
the constitution and affected downstream templates before completion.

Rationale: pre-commit gates catch role violations, stale docs, and missing
verification before they enter project history.

### VI. Framework and Project Boundary Safety

Framework-managed files and downstream product files MUST be classified before
broad edits, review, staging, or commit. Product tasks MUST NOT edit
framework-managed files unless the customer explicitly authorizes template
upgrade or framework maintenance for that task. Framework gaps discovered
during product work MUST be filed or routed upstream instead of patched
opportunistically in the product change. In this meta-project, edits targeting
`./sw-dev-team-template` are framework-scoped by default; edits in the
meta-project root outside that subdirectory are meta-project scaffolding and
MUST be classified explicitly when a change crosses the boundary.

Rationale: separating framework evolution from product delivery prevents
accidental template drift and unsafe mixed-scope releases.

### VII. Harness Adapters, Not Parallel Authority

Claude Code, Codex, OpenCode, Gemini, OpenAI, memory systems, and markdown
compilers MUST adapt to the existing role model. They MUST NOT introduce a
competing role roster, escalation chain, source-of-truth hierarchy, or customer
interface. Cross-harness files MUST remain thin adapters or generated artifacts
unless explicitly promoted to canonical status.

Rationale: cross-AI support is safe only when the team contract remains one
contract with harness-specific adapters.

## Operational Constraints

The binding runtime contract is the combination of `CLAUDE.md`, `AGENTS.md`,
the canonical `.claude/agents/*.md` role files, and any documented local role
supplements. These files govern role ownership, escalation, customer interface,
review gates, and harness-specific behavior.

The project MUST preserve the distinction between canonical, generated, and
ephemeral artifacts when adding adapters, compact runtime prompts, memory
summaries, logs, or compiled markdown. Generated artifacts MUST identify their
canonical inputs or be reproducible by documented tooling before they are used
as operational guidance.

Downstream scaffolds and upgrades MUST preserve the framework/project boundary
model. Release and review work MUST keep framework maintenance, template
upgrades, and product changes split unless an explicit approval records the
reason for combining them.

## Development Workflow and Review Gates

Feature planning MUST include a Constitution Check that verifies role routing,
context cost, source authority, atomic intake, quality gates, boundary safety,
and adapter discipline. Any violation MUST be recorded with a specific reason
and simpler alternative considered before implementation proceeds.

Specifications MUST capture customer-owned requirements as testable statements
with traceable origin or assumption status. If a requirement depends on a
customer answer that is not recorded yet, the work MUST queue one atomic
question instead of guessing.

Task plans MUST group work into independently reviewable increments with clear
owners, file paths, verification steps, and review gates. Tasks that touch
generated or framework-managed artifacts MUST state whether the edit is
canonical, generated, ephemeral, framework, or product scope.

Before closing a non-trivial turn, the responsible orchestrator MUST inspect
the relevant diff, confirm write-scope compliance, confirm customer-truth
stewardship, confirm required specialist routing or explicit exceptions, and
record any spawning limits or unresolved follow-up work.

## Governance

This constitution supersedes conflicting local practice for Spec Kit workflows
in this repository. `CLAUDE.md`, `AGENTS.md`, and canonical role files remain
the detailed runtime authority; if they conflict with this constitution, the
conflict MUST be resolved by amending the relevant artifact rather than by
choosing silently.

Amendments require a documented diff, a Sync Impact Report, and review of the
dependent Spec Kit templates. Version changes use semantic versioning:
MAJOR for incompatible governance or principle changes, MINOR for new or
materially expanded principles or sections, and PATCH for clarifications that
do not change obligations.

Constitution compliance MUST be checked during planning, review, and before
commit. New templates, adapters, generated artifacts, and runtime guidance MUST
state how they preserve role routing, source authority, quality gates, and
framework/project boundaries.

**Version**: 1.1.0 | **Ratified**: 2026-05-12 | **Last Amended**: 2026-05-13
