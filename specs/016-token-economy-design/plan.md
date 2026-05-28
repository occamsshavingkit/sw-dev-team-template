# Implementation Plan: Token Economy Design Pass

**Branch**: `016-token-economy-design` | **Date**: 2026-05-28 | **Spec**: `specs/016-token-economy-design/spec.md`

## Summary

Add a binding "Token economy" section to the tech-lead contract surface (Half A), then systematically audit and trim every agent contract to ≤80% of its M0-baseline cap (Half B). Both halves land together as a single composite design pass gating v1.2.0 and v1.3.0 entry per customer ruling Q-0022.

## Decisions

### D-1: A-1 ratification — contract vs. manual placement

**Ratified as stated.** Binding rules (FR-001/FR-002 content) land in
`.claude/agents/tech-lead.md`; explanatory expansions land in
`docs/agents/manual/tech-lead-manual.md`. Rationale: the contract/manual
split already exists and is enforced by the runtime compiler; adding a
new binding section to the manual (not the contract) would break the
invariant that agents must only read the contract surface for binding
rules. If the addition pushes `tech-lead.md` over 80% of its M0 cap
(3909 words × 0.8 = 3127 words; current post-M1.1 canonical is 2320),
the Half B cuts on `tech-lead.md` must be completed first — or in
parallel with the draft — so both halves land within the cap together.

### D-2: Audit method

**Measurement tool**: `wc -w` on each `.claude/agents/<role>.md` (excluding
`sme-template.md`). Run as a one-liner; record output in the before-and-after
tables in this spec directory.

**Cap source**: M0 word counts from
`docs/pm/token-economy-baseline.md` § "Per-agent contract sizes" are the
cap denominators. The 80%-of-cap threshold = `floor(M0_words × 0.80)`.

**Before table** (file: `specs/016-token-economy-design/audit-tables.md`,
section "Baseline"):

| Role | M0 words (cap) | 80% ceiling | Current words | % of cap | Status |
|---|---:|---:|---:|---:|---|

All 13 runtime-eligible contracts appear. "Status" is one of:
`at-or-below-80%` / `above-80%` / `no-op` (already ≤80% with no
proposed cuts).

**After table** (same file, section "Post-cut"):

| Role | M0 words (cap) | 80% ceiling | Post-cut words | % of cap | Delta words | All cuts tagged? |
|---|---:|---:|---:|---:|---:|---|

Column ordering is identical to the before table so diffs are visually scannable.

**Proposals table** (same file, section "Proposals"):

| Role | Span (line range or anchor) | Tag | Before (excerpt) | After (excerpt) | Manual pointer (if `manual-echo`) | tech-writer notes | Status |
|---|---|---|---|---|---|---|---|

One row per proposed cut. `Tag` ∈ {`duplicated-boilerplate`, `behavior-neutral`, `manual-echo`} per D-3. `Status` ∈ {`proposed`, `approved`, `rejected — <reason>`, `applied`}. `tech-writer notes` column is populated during T026 review.

### D-3: Cut rationale tag operational definitions

Three tags, each exclusive:

- **`duplicated-boilerplate`** — prose that states a rule already
  expressed in an earlier section of the same contract or in a
  cross-contract binding source (e.g., `CLAUDE.md` Hard Rules), where
  the duplicate adds no contract-specific nuance. Removing it does not
  change the rule; it only eliminates the echo.

- **`behavior-neutral`** — prose that neither commands the agent to do
  something nor forbids something; it explains, contextualizes, or
  narrates. Typical markers: "this is because…", "historically…",
  "the intent here is…". Moving it to the manual preserves all
  behavioral content in the contract.

- **`manual-echo`** — prose that was already moved to the role's manual
  (e.g., during the M1.1 canonical/manual split) but was not removed
  from the contract at move time; the manual is the durable home and
  the contract now carries a redundant copy.

- **`cross-contract-duplicate`** — prose appearing verbatim or
  near-verbatim in N ≥ 3 contracts where no single contract is the
  designated canonical home and the prose adds no contract-specific
  nuance. The team designates one contract as the surviving home
  (recorded in the Proposals table, "Manual pointer" column reused for
  home pointer); the remaining N-1 instances are cuttable under this
  tag. The surviving copy may be annotated with a `(see also: <home
  contract>)` pointer where helpful. This tag does NOT apply if the
  prose exists in a cross-contract binding source such as `CLAUDE.md`;
  in that case `duplicated-boilerplate` applies instead. Amendment
  ruled by architect 2026-05-28 after T014 surfaced the gap.

A cut is rejected (and documented as rejected) if it cannot be assigned
any of the four tags without stretching the definition — i.e., the
prose is binding, behavioral, or a customer-truth pointer.

### D-4: Review sequence

The spec (A-6) permits architect and tech-writer to work in parallel.
The binding order is:

```
[Gate 0] Baseline audit table complete and word counts verified
    |
    +--[Parallel]--+
    |               |
    v               v
[Half A]        [Half B draft]
architect       tech-writer
reviews         reviews prose
semantic        surgery proposals
correctness     for Half B files
of new          (all roles)
section
    |               |
    +--[Merge]------+
    | Both findings
    | incorporated
    v
[Gate 1] architect sign-off on semantic correctness (Half A)
         tech-writer sign-off on prose quality (Half B)
    |
    v
[code-reviewer diff review]
— confirms no binding-rule drops (FR-008)
— confirms no customer-truth-reference drops (SC-004)
— confirms rationale tags are present on all cuts (FR-004/FR-012)
    |
    v
[Gate 2] code-reviewer sign-off
    |
    v
[Customer sign-off] → CUSTOMER_NOTES.md + release-plan reference
```

The gate between Half A semantics review and Half B prose review is
the parallel merge point above (Gate 1). Code-reviewer is strictly
after Gate 1 — it reviews the post-revision diff, not proposals.

## Technical Context

**Language/Version**: N/A — markdown-only  
**Primary Dependencies**: N/A  
**Storage**: N/A  
**Testing**: Inspection + `wc -w` measurement; `code-reviewer` diff review  
**Target Platform**: N/A  
**Project Type**: Framework maintenance (markdown edits only, FR-013)  
**Performance Goals**: ≥15% aggregate word-count reduction across roster (SC-005); every file ≤80% of M0 cap (SC-001/FR-006)  
**Constraints**: FR-007 (no roster restructuring); FR-013 (no scripts/schemas/hooks/migrations); FR-008/FR-012 (binding-rule and customer-truth preservation with source-traceable cuts)  
**Scale/Scope**: 13 agent contract files + 1 manual section addition

## Constitution Check

- **Role routing**: architect owns Half A semantic review; tech-writer owns Half B prose review; code-reviewer owns diff-level binding-rule audit; tech-lead orchestrates and obtains customer sign-off; researcher writes the CUSTOMER_NOTES.md sign-off entry. No role crosses its boundary (CA-004).
- **Token/context economy**: Live files to read: `.claude/agents/*.md` (13 files, ~8 k words total post-M1.1), `docs/agents/manual/tech-lead-manual.md`, `docs/pm/token-economy-baseline.md`. Audit table (`audit-tables.md`) is a canonical artifact produced by this pass; it is not reloaded on every spawn. No long session-archive files required.
- **Source authority**: `.claude/agents/*.md` and `docs/agents/manual/tech-lead-manual.md` are canonical. `specs/016-token-economy-design/` artifacts (this plan, `audit-tables.md`) are canonical spec artifacts. Generated runtime contracts in `docs/runtime/agents/` are downstream of the canonical contracts and are NOT edited directly (FR-013 scope).
- **Customer intake**: Q-0022 (answered 2026-05-28) is the governing customer ruling. No new customer question is currently open. One design-pass question is queued — see Open Design Questions below.
- **Quality gates**: Gate 0 (baseline measurement), Gate 1 (architect + tech-writer sign-off), Gate 2 (code-reviewer sign-off), Gate 3 (customer sign-off). All four required before v1.2.0/v1.3.0 entry per SC-007 / FR-011.
- **Framework/project boundary**: This is explicit framework-maintenance work. HR-10 authorization satisfied by Q-0022 customer ruling and CA-003. Scope is bounded to `.claude/agents/*.md`, `docs/agents/manual/tech-lead-manual.md`, and `specs/016-token-economy-design/`. No product-work artifacts are touched.
- **Adapter discipline**: No new authority surfaces introduced. Codex adapter prose that duplicates `AGENTS.md` is treated as `duplicated-boilerplate` (A-5); contracts retain a one-line pointer. This is a reduction pass, not an expansion of the authority model.

## Project Structure

### Documentation (this feature)

```text
specs/016-token-economy-design/
├── spec.md                  # Feature spec (input)
├── plan.md                  # This file
├── audit-tables.md          # Before/after word-count tables (produced during Half B)
└── tasks.md                 # Phase 2 output (/speckit-tasks — NOT created here)
```

### Source files (edited by this pass)

```text
sw-dev-team-template/
├── .claude/agents/
│   ├── tech-lead.md         # Half A: add "Token economy (binding)" section
│   ├── architect.md         # Half B: audit + cut candidates
│   ├── code-reviewer.md     # Half B
│   ├── onboarding-auditor.md# Half B
│   ├── process-auditor.md   # Half B
│   ├── project-manager.md   # Half B
│   ├── qa-engineer.md       # Half B
│   ├── release-engineer.md  # Half B
│   ├── researcher.md        # Half B
│   ├── security-engineer.md # Half B
│   ├── software-engineer.md # Half B
│   ├── sre.md               # Half B
│   └── tech-writer.md       # Half B
└── docs/agents/manual/
    └── tech-lead-manual.md  # Half A: receive any explanatory expansion of new section
```

**Structure Decision**: Single framework submodule; no source-code tree applies. Audit table is the only new non-spec artifact produced.

## Open Design Questions

No customer questions are currently queued. One design-level question the next-phase task breakdown should be aware of:

**OQ-1 (internal, not customer-facing)**: The M0 cap for `tech-lead` is 3909 words; its post-M1.1 canonical is 2320 (59% of cap — well under 80%). The new "Token economy (binding)" section is estimated at ~200–300 words of binding rules. This should keep `tech-lead.md` safely under the 3127-word ceiling (80% × 3909). However, Gate 0 should confirm the current word count before Half A is authored, not after. Task authors should sequence accordingly: measure current `tech-lead.md` words → confirm headroom → author new section.

**OQ-2 (internal, not customer-facing)**: The spec defines SC-005 as ≥15% aggregate reduction in total contract word count. The M0 aggregate (excluding `sme-template`) is approximately 12,515 words (sum of the 13 rows in `token-economy-baseline.md`). The 15% floor requires removing ~1,877 words net. Post-M1.1 cuts already landed for tech-lead, researcher, code-reviewer, and qa-engineer. The current post-M1.1 totals are not separately recorded in `token-economy-baseline.md` for all 13 files — the audit table (Gate 0) will establish the real current total. If the current total is already ≤85% of M0 aggregate, SC-005 will be reachable with modest cuts; if several contracts were never trimmed, the margin is thinner. This is a risk to monitor at Gate 0, not a blocker.

## Risks

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| A proposed cut removes a binding rule by accident | Medium | High | code-reviewer diff review is mandatory (Gate 2); rejected cuts are documented in § Proposals with `Status: rejected — <reason>` per FR-008 |
| New section pushes `tech-lead.md` above 80% cap | Low (current: 59% of cap; ~807-word headroom) | Medium | Gate 0 confirms headroom before Half A authors; if margin is thin, Half B cuts on `tech-lead.md` are prioritized first |
| SC-005 (≥15% aggregate) unreachable without unsafe cuts | Low-Medium (depends on untrimmed contracts) | Medium | Gate 0 establishes true current aggregate; if shortfall is visible early, arch + tech-writer agree on scope extension or document the gap for the customer |
| Sizing policy is not explicitly documented in `researcher-manual.md` | Confirmed (cap source is `token-economy-baseline.md` M0 table, not a named policy section) | Low | Plan pins the cap source explicitly (D-2); the absence of a formal "sizing policy" section in `researcher-manual.md` is a framework gap — `researcher` to file upstream (issue number assigned at filing time) after this pass lands |
| Parallel architect / tech-writer reviews produce conflicting edits to the same file | Low | Medium | Architect reviews only `tech-lead.md` Half A (semantic); tech-writer reviews prose across all contracts. No overlap in deliverable unless both touch the same span; task briefs must assign file-section scope explicitly |

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| Gate 0 measurement pass before editing | Ensures headroom for Half A and SC-005 viability before any edits land | Skipping measurement risks over- or under-cutting; too cheap not to do |
| `audit-tables.md` as a separate canonical artifact | Provides auditable before/after delta required by FR-003/FR-009 and SC-002 | Embedding tables inline in the spec would complicate diffs and violate the "spec does not change during execution" norm |
