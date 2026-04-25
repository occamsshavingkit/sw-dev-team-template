# FW-ADR-0007 — External reference adoption (LIB-0015 through LIB-0018)

Shape per MADR 3.0 + this template's Three-Path Rule
(`docs/templates/adr-template.md`).

---

## Status

- **Accepted**
- **Date:** 2026-04-25
- **Deciders:** `architect` + `tech-lead` + `researcher` + customer
- **Consulted:** `docs/research/sw-dev-repos-survey-2026-04-25.md`
  (Recommendation 5); existing INVENTORY rows LIB-0001 through
  LIB-0014; the project's IP policy in
  `docs/glossary/ENGINEERING.md` § Intellectual property.

## Context and problem statement

The survey of cached software-development repositories identified
four external resources whose ideas have been (or are about to be)
woven into the template, but which are not yet inventoried:

- **`donnemartin/system-design-primer`** (MIT) — system design
  checklist, useful for `architect` paraphrase reference.
- **`jam01/SDD-Template`** (CC0 1.0) — pattern source for FW-ADR-0003
  (bare variants) and FW-ADR-0004 (per-view file breakout).
- **`jam01/SRS-Template`** (CC0 1.0) — same, for requirements.
- **`adr.github.io/madr`** (MIT for code, CC0 for spec) — MADR 3.0
  spec, basis for this project's ADR template + FW-ADR-0006's
  required/optional split.

All four are URL-only references (no PDF, no local file). All four
are license-compatible with the project's "inspire, don't paste"
posture (CC0 needs nothing; MIT needs attribution if files are
copied — we don't copy files, only paraphrase ideas).

**The decision is whether to add INVENTORY rows for these resources
now (formalising the citation contract) or leave them as informal
references in agent docs.**

ADR trigger row: cross-cutting concern (the citation/inventory
contract is project-wide).

## Decision drivers

- **Citation discipline.** The project's existing rule is "every
  external reference cited in agent contracts has a LIB-NNNN row in
  INVENTORY.md." Maintaining that discipline as new references
  appear is binding.
- **License compatibility.** All four candidates are
  inspire-don't-paste-safe (CC0 + MIT). No copyright concerns.
- **Audit traceability.** When a reviewer asks "where did the bare-
  template idea come from?", the LIB row + URL is the audit answer.
  Without rows, the trail goes through the survey doc only.
- **Inventory scaling.** Each new row adds ~15 lines to
  INVENTORY.md. Four rows is ~60 lines; manageable.
- **Differentiated provenance.** These are URL-only references, not
  remote-only PDFs. The inventory shape needs to accommodate both
  (already does — see LIB-0012 / LIB-0013 / LIB-0014 for the
  remote-only-but-no-PDF pattern; the URL-only pattern is new).

## Considered options (Three-Path Rule, binding)

### Option M — Minimalist: cite by URL inline; no INVENTORY rows

Each agent contract that references one of the four URLs cites the
URL inline. INVENTORY.md remains for PDFs and standards only.

- **Sketch:** ADRs 0003 / 0004 / 0006 cite jam01 / MADR URLs in
  their Links sections. No INVENTORY changes.
- **Pros:** Zero inventory growth. Lighter administrative
  overhead.
- **Cons:** Breaks the project's existing citation discipline
  ("every external reference has a LIB row"). URL-only references
  become a parallel system to the LIB-NNNN system. Audit
  traceability through INVENTORY.md is incomplete.
- **When M wins:** a project with very few external URL references
  and no audit-driven citation discipline.

### Option S — Scalable: add LIB-0015 through LIB-0018 with URL-only shape

Add four INVENTORY rows. Each follows the existing row shape, with
the local-path field marked "URL-only (no local copy needed; cite
the URL directly)" instead of "Remote-only" or a `docs/library/local/`
path. License + paraphrase-policy fields filled per resource.

- **Sketch:** Update `docs/library/INVENTORY.md`:
  - **LIB-0015** — `donnemartin/system-design-primer` (MIT) —
    paraphrase source for `architect`.
  - **LIB-0016** — `jam01/SDD-Template` (CC0 1.0) — pattern source
    for FW-ADR-0003 / FW-ADR-0004.
  - **LIB-0017** — `jam01/SRS-Template` (CC0 1.0) — pattern source
    for FW-ADR-0003 / FW-ADR-0004.
  - **LIB-0018** — MADR 3.0 spec at `adr.github.io/madr`
    (MIT for code, CC0 for spec) — pattern source for FW-ADR-0006.
  Add a paragraph to INVENTORY.md's IP-policy section noting the
  URL-only shape (parallel to the existing remote-only and
  local-copy shapes).
  Add the binding "inspire, don't paste" rule to
  `docs/glossary/ENGINEERING.md` § "Intellectual property" so the
  rule lives in one canonical place; INVENTORY.md cross-
  references.
- **Pros:** Maintains the citation discipline. All external
  references in INVENTORY.md regardless of shape (PDF, remote-
  only, URL-only). Audit traceability complete. The inspire-don't-
  paste rule lands as binding glossary content.
- **Cons:** Four new rows to maintain. URL-only shape is a third
  inventory-row variant (after PDF-local and remote-only).
- **When S wins:** the framework's primary use case — multiple
  external references woven into agent contracts and templates,
  with audit-driven citation discipline.

### Option C — Creative: separate URL-only register

Keep `INVENTORY.md` for PDFs and remote PDFs. Create
`docs/library/REFERENCES.md` for URL-only references with a lighter
row shape. Cross-reference between the two registers.

- **Sketch:** New file `docs/library/REFERENCES.md` with a
  three-column table (REF-NNNN, title, URL). INVENTORY.md keeps
  PDF/remote-PDF rows. Agent contracts cite either by `LIB-NNNN`
  or `REF-NNNN`.
- **Pros:** Each register has a single, coherent shape (no third
  variant). URL references get a lighter ceremony.
- **Cons:** Two registers for the same kind of citation
  obligation. Authors must choose register before adding a row.
  Cross-reference between registers is itself ceremony. The
  inventory contract bifurcates.
- **When C wins:** if URL-only references proliferate (>20) and
  the lighter ceremony pays for itself.

## Decision outcome

**Chosen option: S — Scalable: add LIB-0015 through LIB-0018.**

**Reason:** Option S preserves the project's citation discipline
(one register, one shape per row, one row per external reference)
at four-row cost. Option M lets the citation contract erode as
URL-only references multiply. Option C bifurcates the citation
contract, adding ceremony to choose register; the URL-only shape
is small enough that a third row variant in INVENTORY.md is
cheaper than a parallel register.

The "inspire, don't paste" rule lands binding in
`docs/glossary/ENGINEERING.md` § Intellectual property; INVENTORY.md
cross-references the rule. New rows mark the row's
inspire-don't-paste status explicitly (separate from copyright /
license fields).

## Consequences

### Positive

- Citation discipline preserved as the reference set grows.
- Audit traceability complete — every external idea woven into
  agent contracts has a LIB row.
- "Inspire, don't paste" rule lives in canonical glossary
  location; cited from INVENTORY rows that exercise it.
- URL-only shape opens the path for future awesome-list-style
  references without copying files.

### Negative / trade-offs accepted

- INVENTORY.md grows by ~60 lines.
- Three row variants (PDF-local, remote-only, URL-only). Variant
  selection is mechanical (where does the canonical copy live?),
  not a judgement call.

### Follow-up ADRs

- None required. A future ADR may bifurcate the register if
  URL-only references multiply past ~20 and Option C's ceremony
  starts to pay.

## Verification

- **Success signal:** by v0.14.0 release, INVENTORY.md has rows
  LIB-0015 through LIB-0018 with the URL-only shape. The
  glossary contains the binding "inspire, don't paste" rule.
  FW-ADR-0003, FW-ADR-0004, FW-ADR-0006 cite the new rows by ID.
- **Failure signal:** authors add new external references without
  filing a LIB row; `code-reviewer` audit findings cite the gap.
- **Review cadence:** at v0.15.0 release planning.

## Links

- Survey: `docs/research/sw-dev-repos-survey-2026-04-25.md` (Recommendation 5)
- Related ADRs: FW-ADR-0003, FW-ADR-0004, FW-ADR-0005, FW-ADR-0006 (all cite
  one or more of the new rows).
- Glossary update: `docs/glossary/ENGINEERING.md` § Intellectual
  property (adds "inspire, don't paste" as binding rule).
- Inventory updates: `docs/library/INVENTORY.md` (rows LIB-0015
  through LIB-0018 + URL-only-shape note).
