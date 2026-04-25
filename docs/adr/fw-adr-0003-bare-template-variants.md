# FW-ADR-0003 — Bare variants of structural templates

<!-- TOC -->

- [Status](#status)
- [Context and problem statement](#context-and-problem-statement)
- [Decision drivers](#decision-drivers)
- [Considered options (Three-Path Rule, binding)](#considered-options-three-path-rule-binding)
  - [Option M — Minimalist: ship one file, mark prose as collapsible](#option-m-minimalist-ship-one-file-mark-prose-as-collapsible)
  - [Option S — Scalable: ship a guided + bare pair per template family](#option-s-scalable-ship-a-guided-bare-pair-per-template-family)
  - [Option C — Creative: progressive disclosure via a transform layer](#option-c-creative-progressive-disclosure-via-a-transform-layer)
- [Decision outcome](#decision-outcome)
- [Consequences](#consequences)
  - [Positive](#positive)
  - [Negative / trade-offs accepted](#negative-trade-offs-accepted)
  - [Follow-up ADRs](#follow-up-adrs)
- [Verification](#verification)
- [Links](#links)

<!-- /TOC -->

Shape per MADR 3.0 + this template's Three-Path Rule
(`docs/templates/adr-template.md`).

---

## Status

- **Accepted**
- **Date:** 2026-04-25
- **Deciders:** `architect` + `tech-lead` + customer
- **Consulted:** `docs/research/sw-dev-repos-survey-2026-04-25.md`
  (Recommendation 1); upstream-survey reference `jam01/SDD-Template`
  + `jam01/SRS-Template` (CC0 1.0); `LIB-0009` (IEEE 1016 SDD),
  `LIB-0010` (ISO/IEC/IEEE 29148 RE).

## Context and problem statement

`docs/templates/architecture-template.md` (arc42 + C4 + IEEE 1016
viewpoint mapping) and `docs/templates/requirements-template.md`
(ISO/IEC/IEEE 29148 information items) are the project's structural-
artefact spines. Both are **guided** templates: they ship with prose
explaining each section, examples, and tailoring notes inline. The
prose is load-bearing on the *first* time an author uses the template;
on the tenth instantiation, it's pure token cost — both for the
author writing the artefact and for any agent loading the artefact
to reason about it.

Current sizes: `architecture-template.md` ~3.8 KB after today's IEEE
1016 viewpoint additions; `requirements-template.md` ~5.1 KB after the
29148 information-item additions. Each instantiation copies the
template wholesale; tailoring notes about what to omit do not
themselves omit anything by default.

**The decision is which shape to ship for each template family.** The
upstream-survey CC0 reference (`jam01/SDD-Template`,
`jam01/SRS-Template`) demonstrates a "guided full + bare" pair pattern
where the bare file is the same skeleton (headings + structural
markers) without the explanatory prose, sized at roughly 50% of the
guided variant.

ADR trigger row: cross-cutting concern (changes the template-
authoring contract for two of the project's most-used templates); not
a public-API change to scripts or the agent roster.

## Decision drivers

- **Token economy.** Per `tech-lead.md` § "Token economy", reducing
  per-instantiation token cost is binding. Templates are loaded by
  agents reasoning about completed artefacts, not just by humans
  authoring them.
- **First-time vs Nth-time author.** Guided prose helps first-time
  authors; it gets in the way after fluency.
- **Tailoring discipline.** 29148 § 2.5 and 1016 § 4.7 explicitly
  permit tailored conformance; the guided template's tailoring
  *guidance* is itself overhead that doesn't exist in the bare
  variant.
- **Structural drift risk.** Two parallel files (guided + bare) for
  the same template can drift if updated independently. The fix
  must include a synchronisation rule.
- **Backward compatibility.** Existing downstream projects already
  reference `architecture-template.md` and `requirements-template.md`;
  any change must not break those references.

## Considered options (Three-Path Rule, binding)

### Option M — Minimalist: ship one file, mark prose as collapsible

Keep a single template file per family. Mark guidance prose with a
sentinel (e.g., HTML comments or a fenced "guidance" admonition) that
authors can grep-strip when they're fluent. No new files; no two-way
sync.

- **Sketch:** Add `<!-- guidance:start -->` … `<!-- guidance:end -->`
  markers around explanatory prose in the existing templates. Provide
  a `scripts/strip-guidance.sh` one-liner that removes them.
- **Pros:** Zero new files. No drift risk. Existing references
  unchanged. Single source of truth.
- **Cons:** Authors still copy the full file; the savings only land
  if they remember to strip. Sentinel markers add visual noise even
  to first-time readers. No leverage for agents to load the lean
  variant directly without invoking the strip step.
- **When M wins:** if authors and agents always operate on a fresh
  copy where the strip step is part of the scaffold flow.

### Option S — Scalable: ship a guided + bare pair per template family

Adopt the jam01 pattern. Ship two files per family:
`architecture-template.md` (guided) and `architecture-template-bare.md`
(skeleton-only); same for requirements. Bare is the **canonical
structure**; guided is generated or maintained from bare with prose
inserts. Synchronisation rule: structural changes land in bare first;
guided is regenerated or hand-updated to match.

- **Sketch:** New files
  `docs/templates/architecture-template-bare.md` and
  `docs/templates/requirements-template-bare.md`. Both mirror their
  guided counterparts at the heading and table-skeleton level, with
  no inline explanatory prose. The guided files keep their existing
  prose; a one-line cross-reference at the top of each guided
  variant points to the bare counterpart for fluent authors.
- **Pros:** Authors and agents pick the variant that matches their
  fluency. ~50% token savings on the bare variant per instantiation
  (per survey estimate). Aligns with a widely-used CC0 convention so
  external collaborators recognise the pattern. Existing references
  unchanged.
- **Cons:** Two files to keep in sync per family. Drift risk
  mitigated by an explicit synchronisation rule + a smoke check in
  `scripts/smoke-test.sh` (compare heading sets between guided and
  bare; fail if they diverge).
- **When S wins:** the framework's actual use case — long-running
  projects whose authors achieve fluency, where the bare variant
  becomes the default after the first few uses.

### Option C — Creative: progressive disclosure via a transform layer

Ship one template per family, but render two variants from a single
source through a build step. Use a marker syntax (e.g., `# @bare-skip`
on guidance paragraphs) and let `scripts/render-templates.sh` produce
both `*-bare.md` and the guided variant from the same source. Authors
and agents consume the rendered output, never the source.

- **Sketch:** Source files at `docs/templates/_src/architecture.md`
  with markers. A build step in `scripts/smoke-test.sh` renders to
  `docs/templates/architecture-template{,-bare}.md`. CI verifies the
  rendered output is committed.
- **Pros:** Single source of truth; structural drift impossible by
  construction. Build-step infrastructure could be reused for other
  template variants in the future (per-item, per-view).
- **Cons:** Adds a build step the framework currently doesn't have.
  Renders the templates non-editable directly (have to know to edit
  source). Higher cognitive overhead for new contributors.
- **When C wins:** if multiple template variants proliferate (per-
  item, per-view, integrity-level-tailored), justifying a transform
  layer's overhead.

## Decision outcome

**Chosen option: S — Scalable: guided + bare pair.**

**Reason:** Option S delivers the token-economy win (~50% per
instantiation on bare) at a fixed two-file maintenance cost, no
build-step infrastructure, no scaffold-time strip step. Option M's
"strip when fluent" depends on author discipline; the savings
materialise only when authors remember, and agents loading the
artefact don't get the savings at all. Option C's build step is
overkill for two template families and would be the right answer
only if Recommendation 2 (per-item / per-view breakout) materially
increases the variant count beyond two — which is a separate ADR
(FW-ADR-0004), and even there S-shape pairs are tractable.

The S-shape "bare files are canonical; guided is the prose overlay"
synchronisation rule is binding: when the structure changes, bare
is updated first, guided second. A heading-set diff in
`scripts/smoke-test.sh` fails CI if they diverge.

## Consequences

### Positive

- ~50% per-instantiation token reduction for fluent authors / agents
  using the bare variant.
- Explicit signal of when guidance is needed (first-time = guided;
  fluent = bare) instead of hidden in author memory.
- Aligns with a widely-recognised CC0 convention.
- No backward-incompatible change: guided templates remain at their
  existing paths.

### Negative / trade-offs accepted

- Two files to keep in sync per template family (mitigated by the
  smoke-test heading diff).
- A documentation note in each guided template advising "for fluent
  authors, see *-template-bare.md" — small additional reading but no
  structural cost.

### Follow-up ADRs

- FW-ADR-0004 — Per-item / per-view file breakout (separate decision;
  changes how a finished artefact decomposes, not how the template
  itself is shaped).
- FW-ADR-0007 — Reference adoption (catalogues the jam01 templates that
  inspired this ADR; required for the inspire-don't-paste audit
  trail).

## Verification

- **Success signal:** by v0.14.0 release date, both
  `*-template-bare.md` files exist; smoke test passes; at least one
  downstream project (this one) has migrated to the bare variant on
  any new artefact instantiation.
- **Failure signal:** the heading-set diff in `scripts/smoke-test.sh`
  fires repeatedly because authors update guided without bare (or
  vice-versa); review cadence forced. If the lapse rate exceeds
  ~20% of structural changes, supersede with Option C (build step).
- **Review cadence:** at v0.15.0 release planning. Reconsider if
  drift incidents accumulate or if Recommendation 2 (per-item)
  proliferation justifies a transform layer.

## Links

- Survey: `docs/research/sw-dev-repos-survey-2026-04-25.md` (Recommendation 1)
- External references:
  - `https://github.com/jam01/SDD-Template` (CC0 1.0; pattern source)
  - `https://github.com/jam01/SRS-Template` (CC0 1.0; pattern source)
- Related ADRs: FW-ADR-0004 (per-item breakout), FW-ADR-0007 (reference
  adoption catalogue).
- External standards: `LIB-0009` IEEE 1016 § 4.7 (tailoring),
  `LIB-0010` ISO/IEC/IEEE 29148 § 2.5 (tailored conformance).
