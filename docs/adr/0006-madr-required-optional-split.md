# ADR-0006 — MADR required-vs-optional split in adr-template.md

Shape per MADR 3.0 + this template's Three-Path Rule
(`docs/templates/adr-template.md`).

---

## Status

- **Accepted**
- **Date:** 2026-04-25
- **Deciders:** `architect` + `tech-lead` + customer
- **Consulted:** `docs/research/sw-dev-repos-survey-2026-04-25.md`
  (Recommendation 4); MADR 3.0 spec at `https://adr.github.io/madr/`
  (LIB-0018 candidate per ADR-0007); the project's Three-Path Rule
  (issue #33) which is layered on top of MADR.

## Context and problem statement

This template's `docs/templates/adr-template.md` requires every ADR
section: Status, Context+Problem, Decision drivers, Considered
options (Three-Path Rule), Decision outcome, Consequences,
Verification, Links. All eight sections must be filled even when an
ADR is small (e.g., a single-line tooling choice) or when sections
are genuinely n/a (e.g., Verification on a documentation-only ADR).

Realised ADR sizes in the upstream tree:
- ADR-0001 (orchestration stance): 239 lines
- ADR-0002 (upgrade content verification): 364 lines

MADR 3.0 itself separates **required** from **optional** sections:
- Required: title, status, context+problem, considered options,
  decision outcome.
- Optional: decision drivers, consequences, pros/cons of options,
  more information, confirmation/verification, links.

A minimal MADR fits in ~40 lines (status + context + 3 options +
decision); a full MADR runs 200+. The current template forces full
shape every time, even on decisions whose substance fits in 40
lines.

**The decision is whether to keep the full-shape requirement or
adopt MADR's required/optional split.**

ADR trigger row: cross-cutting concern (changes the ADR-authoring
contract that `architect` follows).

## Decision drivers

- **Token economy.** Smaller ADRs cost less per write *and* per
  re-read. The framework writes 5+ ADRs per major release.
- **Decision quality.** Some sections (Verification, Decision
  drivers) materially improve decision quality and should not be
  skippable. Others (Pros/Cons of options) can be wrapped into the
  Sketch field without loss.
- **MADR alignment.** Aligning with MADR 3.0's required/optional
  split keeps the project's ADRs interoperable with external
  tooling (log4brains, adr-tools, MADR validators).
- **Three-Path Rule.** This project's binding rule (one of the
  required sections) overlays MADR; the Three-Path requirement
  must remain in the *required* set, regardless of MADR's stance.
- **Audit traceability.** `code-reviewer` audits compare ADRs
  against shipping code; an ADR with `Verification: n/a` is harder
  to audit than one with explicit success/failure signals. The
  rule should make Verification *recommended-strongly* but not
  hard-required.

## Considered options (Three-Path Rule, binding)

### Option M — Minimalist: keep full-shape requirement

Status quo. Every section required. Authors fill `n/a` where
genuinely inapplicable.

- **Sketch:** No template change. Add a binding note that `n/a`
  with a one-line reason is acceptable for sections that genuinely
  don't apply.
- **Pros:** No template churn. Existing ADRs (0001, 0002) match.
  No author-judgement required for "is this section needed?"
- **Cons:** Token cost is unchanged on small decisions; authors
  end up writing `n/a` in three sections for a 40-line decision.
  Visual signal of "this ADR is small" is lost — the file looks
  the same length as a major decision.
- **When M wins:** a project with very few ADRs whose content is
  always substantial.

### Option S — Scalable: MADR required + project required + optional

Adopt MADR's split, with this template's Three-Path Rule layered
into the *required* set:

- **Required (always present):** Status, Context and problem
  statement, Considered options (Three-Path Rule, binding),
  Decision outcome.
- **Recommended (default present, may be omitted with one-line
  rationale):** Decision drivers, Consequences, Verification.
- **Optional (present when useful):** Links to prior-art /
  proposals, Follow-up ADRs.

- **Sketch:** Update `docs/templates/adr-template.md` to mark each
  section as Required / Recommended / Optional. Provide a 40-line
  minimal-shape example and a 200+-line full-shape example as
  inline reference. Add `code-reviewer` audit-mode rule: ADRs
  missing a Required section are findings; ADRs missing a
  Recommended section without a one-line rationale are findings.
- **Pros:** Small decisions stay small (~40 lines instead of
  ~200). Decision-quality sections (Drivers, Verification) remain
  recommended; not omitted casually. Three-Path Rule preserved.
  MADR-aligned for external tooling.
- **Cons:** Author judgement required for Recommended sections.
  Two-shape ADR set in the upstream tree (small + full), which
  is itself a token saving.
- **When S wins:** the framework's primary use case — multiple
  ADRs per release at varied substance levels.

### Option C — Creative: ADR severity tiers

Three ADR severity tiers with distinct templates:
- **Tier-1 (decision):** Full MADR + Three-Path. For
  architecturally-significant decisions (ADR triggers fire).
- **Tier-2 (clarification):** Status + Context + Decision +
  Verification only. For tooling choices, naming conventions,
  small process decisions.
- **Tier-3 (record):** Status + Decision + one-paragraph
  rationale. For decisions that just need a permanent record
  (e.g., "we are using `pytest` not `unittest`").

Each tier ships its own template; ADR filename includes the tier
(e.g., `0007-T2-naming-convention.md`).

- **Sketch:** Three template files; ADR filenames carry tier
  marker. `code-reviewer` audit checks the marker matches the
  template used.
- **Pros:** Strong visual signal of decision weight. Tier-3 ADRs
  could be one-paragraph entries instead of files — extreme token
  saving on small decisions.
- **Cons:** Author judgement on tier classification is itself a
  decision. Three-Path Rule's binding nature gets weaker for
  Tier-2/3. Filename convention churn. Diverges from MADR.
- **When C wins:** a project with very high ADR volume where the
  Tier-3 decisions dominate count.

## Decision outcome

**Chosen option: S — Scalable: required + recommended + optional split.**

**Reason:** Option S delivers the token-economy win on small ADRs
without tier-system complexity. Option M leaves the per-ADR cost
unchanged. Option C trades MADR alignment + Three-Path-Rule
universality for a tier system whose decision-quality dynamic is
worse than S (Tier-2/3 ADRs would skip Drivers and Verification
casually). MADR's own normative split is well-tested by the wider
ADR-writing community; aligning preserves interoperability and
gains a structural improvement at low maintenance cost.

The Three-Path Rule stays in the **Required** set. That is binding
and non-negotiable. Recommended sections (Drivers, Consequences,
Verification) may be omitted with a one-line rationale; the rationale
is enforceable by `code-reviewer` audit.

## Consequences

### Positive

- Small ADRs ~40 lines; full ADRs ~200+. Token cost scales with
  decision substance.
- MADR alignment opens the door to external tooling reuse
  (log4brains, adr-tools, MADR validators).
- Three-Path Rule preserved as required.
- Decision-quality sections (Drivers, Verification) discouraged-
  but-not-forbidden as omittable, preserving the "explicit n/a is
  fine" pattern with structure.

### Negative / trade-offs accepted

- Author judgement required on Recommended sections. Mitigated by
  the audit rule: omitted Recommended needs a one-line rationale.
- Two ADR shapes in the upstream tree (small + full). Mitigated
  by the structural similarity — both follow the same Required
  set in the same order.
- ADR-0001 and ADR-0002 retain full-shape; not back-migrated.
  Existing ADRs grandfathered.

### Follow-up ADRs

- None required immediately. A future ADR may revisit if external
  MADR tooling adoption surfaces structural mismatches.

## Verification

- **Success signal:** by v0.14.0 release, the updated template ships
  with Required/Recommended/Optional markers; at least one new ADR
  uses the Recommended-omitted shape (~40 lines) cleanly.
  Per-ADR token-ledger entries show small-ADR cost ~30% of full-ADR.
- **Failure signal:** small-ADR shape is rare in practice (authors
  default to full-shape habit); review cadence forced.
- **Review cadence:** at v0.15.0 release planning.

## Links

- Survey: `docs/research/sw-dev-repos-survey-2026-04-25.md` (Recommendation 4)
- External references: MADR 3.0 spec at
  `https://adr.github.io/madr/` (LIB-0018 candidate per ADR-0007).
- Related ADRs: ADR-0003 (bare variants — different decision,
  similar shape), ADR-0007 (reference adoption catalogue).
- Standards: project Three-Path Rule per upstream issue #33.
