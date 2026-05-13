# FW-ADR-0005 — Standards paraphrase cards (single source for IEEE/ISO citations)

<!-- TOC -->

- [Status](#status)
- [Context and problem statement](#context-and-problem-statement)
- [Decision drivers](#decision-drivers)
- [Considered options (Three-Path Rule, binding)](#considered-options-three-path-rule-binding)
  - [Option M — Minimalist: status quo, accept duplication](#option-m--minimalist-status-quo-accept-duplication)
  - [Option S — Scalable: extract paraphrases into a single cards file](#option-s--scalable-extract-paraphrases-into-a-single-cards-file)
  - [Option C — Creative: paraphrase-as-code with structured frontmatter](#option-c--creative-paraphrase-as-code-with-structured-frontmatter)
- [Decision outcome](#decision-outcome)
- [Consequences](#consequences)
  - [Positive](#positive)
  - [Negative / trade-offs accepted](#negative--trade-offs-accepted)
  - [Follow-up ADRs](#follow-up-adrs)
- [Verification](#verification)
- [Links](#links)

<!-- /TOC -->

Shape per MADR 3.0 + this template's Three-Path Rule
(`docs/templates/adr-template.md`).

---

## Status

- **Accepted (implementation deferred to v0.15.0)**
- **Date accepted:** 2026-04-25
- **Implementation target:** v0.15.0 — paraphrase extraction from
  five agent files (`architect.md`, `qa-engineer.md`,
  `code-reviewer.md`, `release-engineer.md`,
  `software-engineer.md`) and three templates
  (`architecture-template.md`, `phase-template.md`,
  `requirements-template.md`) into a single
  `docs/standards/paraphrase-cards.md` is a substantial refactor;
  scoped to its own milestone to avoid bundling with v0.14.0's
  upgrade-content-verification work. v0.14.0 ships the citation
  pattern (LIB-NNNN row IDs already used inline) so v0.15.0's
  extraction has nothing to invent.
- **Deciders:** `architect` + `tech-lead` + `researcher` + customer
- **Consulted:** `docs/research/sw-dev-repos-survey-2026-04-25.md`
  (Recommendation 3); `docs/library/INVENTORY.md` rows LIB-0003
  through LIB-0011 (the eight already-paraphrased standards).

## Context and problem statement

Across this session, eight IEEE / ISO standards have been paraphrased
into agent contracts and templates:

- IEEE 1044 (LIB-0003) → `qa-engineer.md`
- IEEE 730 (LIB-0004) → `code-reviewer.md`
- IEEE 1012 (LIB-0005) → `qa-engineer.md` + `phase-template.md`
- IEEE 1028 (LIB-0006) → `code-reviewer.md`
- IEEE 829 (LIB-0007) → `qa-engineer.md`
- IEEE 828 (LIB-0008) → `release-engineer.md`
- IEEE 1016 (LIB-0009) → `architect.md` + `architecture-template.md`
- ISO/IEC/IEEE 29148 (LIB-0010) → `requirements-template.md`
- IEEE 1008 (LIB-0011) → `software-engineer.md`

Each paraphrase runs ~50–150 lines of binding language anchored on
the specific standard's clauses. **The same paraphrase content lands
in multiple files** — IEEE 1012 in `qa-engineer.md` *and*
`phase-template.md`; IEEE 1016 in `architect.md` *and*
`architecture-template.md`. When two agents need to coordinate on a
shared standard (e.g., `qa-engineer` and `release-engineer` both
referencing IEEE 1012 integrity levels), they each carry their own
paraphrase, and those paraphrases can drift over time.

Total duplication footprint across the current set: estimated ~5–10
KB per agent definition that loads it. With ~10 agent definitions
and ~5 templates that touch standards material, the per-session
context cost compounds.

**The decision is whether to keep the per-agent-file paraphrase
shape, or extract paraphrases into a single source that agents cite
rather than embed.**

ADR trigger row: cross-cutting concern (changes how every agent
contract carries standards material).

## Decision drivers

- **Token economy.** Per-agent-file paraphrase content is loaded on
  every dispatch of that agent. A single source loaded only when
  the standard is in scope reduces baseline.
- **Drift control.** A single source eliminates the risk of two
  agent files diverging on the same standard's content over time.
- **Citation discipline.** The `LIB-NNNN` row ID system already
  provides authoritative citation; the paraphrase content
  effectively duplicates what the row ID points to.
- **Agent contract clarity.** An agent contract that says "I follow
  IEEE 730 § 5.4" is shorter, and clearer, than one that includes
  the paraphrase of § 5.4 inline. The paraphrase is reference
  material, not contract language.
- **First-time vs Nth-time author.** Same dynamic as FW-ADR-0003: the
  paraphrase content helps a first-time reader; it's overhead for
  fluent agents.

## Considered options (Three-Path Rule, binding)

### Option M — Minimalist: status quo, accept duplication

Keep paraphrase content in each agent file. Add a binding rule that
when a standard is paraphrased into more than one file, the
paraphrases must be identical (verified by a smoke check that
extracts paraphrase blocks and compares).

- **Sketch:** No file restructuring. Add a heading-anchored
  paraphrase-block convention so the smoke check can extract them.
  `scripts/smoke-test.sh` fails if the same `LIB-NNNN`-tagged
  paraphrase differs between files.
- **Pros:** Zero structural change. Agents continue to carry their
  own paraphrase content; readers get it inline.
- **Cons:** Token duplication unchanged. Smoke check enforces
  consistency but does not reduce the per-dispatch cost. Drift
  prevention only; not a cost reduction.
- **When M wins:** if duplication footprint is modest (<2 KB) and
  fluency is rare in the agent population.

### Option S — Scalable: extract paraphrases into a single cards file

Create `docs/standards/paraphrase-cards.md` (or `docs/standards/`
directory of one file per standard) with the binding paraphrase per
standard. Each agent contract that depends on a standard cites the
card by anchor, e.g., "see `docs/standards/paraphrase-cards.md`
§ IEEE-730". The agent file no longer carries the prose; it carries
the role-specific *application* of the standard (which sections fire
when, who owns what).

- **Sketch:** New file `docs/standards/paraphrase-cards.md` with
  one section per standard, anchored on the LIB-NNNN row. Each
  card: standard name + version, scope summary, key clauses
  cited project-wide, role-ownership table for each clause.
  Agent files keep their *role-specific* sections (e.g.,
  `qa-engineer.md` § "What QA owns from IEEE 1012") but stop
  carrying the standard's intro / overview prose. A migration step
  in v0.14.0 sweeps the existing duplication.
- **Pros:** Single source of truth per standard. Agents load the
  card only when actually engaging the standard, not on every
  dispatch. Drift impossible by construction. Aligns with `LIB-NNNN`
  citation discipline. Estimated cross-agent savings: 5–10 KB.
- **Cons:** Extra file to load when a standard is in scope (one-
  time per dispatch where it matters). Agents that previously
  found the paraphrase inline now follow a citation. Initial
  migration effort to extract the existing eight paraphrases.
- **When S wins:** the framework's primary use case — multiple
  agents engaging multiple standards, with paraphrase content
  growing as new standards are catalogued.

### Option C — Creative: paraphrase-as-code with structured frontmatter

Each standard gets a YAML+Markdown file at
`docs/standards/<std-id>.yml.md` with structured fields (scope,
clauses, role-ownership, version-history) plus a prose body. A
build script renders these into Markdown blocks that get inlined
into agent files at scaffold / build time.

- **Sketch:** Authoritative source `docs/standards/_src/IEEE-1012.md`
  with frontmatter. `scripts/render-standards.sh` produces
  per-agent inlined markdown blocks. CI verifies output matches
  source.
- **Pros:** Single source + per-agent inlined experience. Drift
  impossible by construction.
- **Cons:** Build step the framework currently doesn't have.
  Agents and authors edit rendered output but the source-of-truth
  is elsewhere — easy to forget. Higher cognitive overhead than
  Option S for a marginal experience gain.
- **When C wins:** if the standards catalogue grows to 20+ items
  *and* agent count grows to ~20+, justifying transform-layer
  overhead.

## Decision outcome

**Chosen option: S — Scalable: paraphrase cards file.**

**Reason:** Option S delivers the duplication elimination at one new
file's cost, with no build step. Option M's smoke check addresses
drift but not the token cost. Option C's build step is over-
engineering for the current standards count (eight) and agent count
(thirteen — including the four added across v0.11–v0.13). The Option
S migration is a one-time sweep of eight paraphrases; ongoing
maintenance is "edit one file when a standard moves" instead of
"edit two-or-more files in lockstep."

The cards file is canonical for paraphrase content. Agent files
carry the *role-specific application* (which clauses fire, who owns
what, when) but cite the card for the underlying paraphrase.

## Consequences

### Positive

- ~5–10 KB cross-agent context savings per typical session.
- Drift between agent paraphrases of the same standard is
  structurally impossible.
- Agent contracts get shorter and read more clearly as role
  contracts (fluent reader can skip the paraphrase entirely).
- New standards added once, cited many times — same shape as
  `INVENTORY.md` already establishes for citation.

### Negative / trade-offs accepted

- One extra file to load when a standard is in scope (mitigated by
  the fact that most dispatches don't touch standards directly).
- Migration: move eight existing paraphrases out of agent files
  into the cards file. ~4 hours work per the survey estimate.
- Documentation cross-references increase by one indirection (agent
  file → cards file → INVENTORY.md row). Indirection is recognised
  in `code-reviewer` audit finding format.

### Follow-up ADRs

- A future ADR if the cards file grows past ~30 KB and per-standard
  files become preferable.
- Possible interaction with FW-ADR-0004 (per-item file breakout):
  per-standard files would mirror that pattern.

## Verification

- **Success signal:** by v0.14.0 release, `docs/standards/
  paraphrase-cards.md` exists; the eight paraphrases are extracted;
  agent files cite by anchor; per-session token-ledger entries
  show measurable reduction on dispatches that don't touch
  standards.
- **Failure signal:** agents start re-inlining paraphrase content
  for "convenience"; `code-reviewer` audit findings cite the
  practice. If lapse rate > ~10% of new agent edits, supersede
  with Option C.
- **Review cadence:** at v0.15.0 release planning.

## Links

- Survey: `docs/research/sw-dev-repos-survey-2026-04-25.md` (Recommendation 3)
- Related ADRs: FW-ADR-0003, FW-ADR-0004, FW-ADR-0007.
- INVENTORY rows directly affected: LIB-0003 through LIB-0011.
- Existing agent files affected: `architect.md`, `qa-engineer.md`,
  `code-reviewer.md`, `release-engineer.md`,
  `software-engineer.md`, plus templates `architecture-template.md`,
  `requirements-template.md`, `phase-template.md`,
  `task-template.md`.
