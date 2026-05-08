# Inventory — `docs/sme/<domain>/`

Every `docs/sme/<domain>/` directory MUST have an `INVENTORY.md` based
on this template. Maintained by `researcher`; updated whenever material
is added, removed, or re-verified.

---

## IP policy (project-wide, non-negotiable)

**Assumption by default: any material not created within this project
is copyrighted.** This holds unless the customer explicitly overrides
it for a specific item in `CUSTOMER_NOTES.md` (e.g., "this vendor has
granted written permission to redistribute," or "this document is in
the public domain / under license X").

Consequences:

- **Project-created work** (our notes, summaries, interviews we
  conducted, diagrams we drew): may be committed to the project
  repository under the project's license. Goes in this directory at the
  top level. Listed in the "Project-created" table below.
- **External material** (vendor manuals, standards documents, books,
  PDFs, screenshots of third-party UIs, downloaded presentations):
  stays in `docs/sme/<domain>/local/`, which is gitignored. NOT
  committed. Listed in the "External (local-only, cited)" table below,
  with enough citation for a third party to independently obtain it.
- **Paraphrases / derivative summaries** of external material: may be
  committed if the transformation is substantive (rewriting in our own
  words, restructuring, selecting relevant parts). Cite the source in
  the note itself. Listed in the "Project-created" table with a source
  reference.

When in doubt, assume copyrighted and route through `local/`. Do not
assume "it was on the web" implies permission to redistribute.

---

## Domain

- **Domain slug:** `<domain-slug>`
- **SME agent file:** `.claude/agents/sme-<domain-slug>.md`
- **Chartered:** YYYY-MM-DD, per `CUSTOMER_NOTES.md` entry YYYY-MM-DD
- **Primary knowledge source:** customer | external SME <name and role>
- **License override on this domain:** none, *or* cite the
  `CUSTOMER_NOTES.md` entry that grants blanket permission.

---

## Project-created material (committed)

| Filename (relative) | Title / topic | Author (agent or contributor) | Date added | Source reference (if derivative) | Covers (SME topic tags) |
|---|---|---|---|---|---|
| `interview-2026-04-22.md` | Customer interview on X | tech-lead | 2026-04-22 | — | <tags> |
| `summary-gmp-annex-11.md` | Summary of GMP Annex 11 applicability | researcher | 2026-04-23 | external item #3 | <tags> |

Rules:
- Every row is committable under the project license.
- Paraphrases: cite the external source by its row ID in the next table.
- Delete: never. Mark rows `SUPERSEDED BY <filename>` or `WITHDRAWN` with
  date and reason.

---

## External material (local-only, cited)

**Not committed. Held in `docs/sme/<domain>/local/`.** Every row must
give a third-party-reproducible citation.

| # | Title | Author / Publisher | Year / version | How to obtain | License / terms | Local filename | Text extraction | Covers | Date added | Last verified accessible |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | <Title of doc> | <Publisher> | 2024 v1.2 | <URL, or ISBN, or DOI, or standard number, or "request from <vendor contact>"> | <e.g., "© Publisher, no redistribution" / "CC BY-SA 4.0"> | `local/<filename>.pdf` | `local/<filename>.txt` via `pdftotext -layout`, YYYY-MM-DD / not needed / blocked: OCR needed | <tags> | YYYY-MM-DD | YYYY-MM-DD |

Rules:
- **"How to obtain" must be enough for someone else to get the item
  independently.** A raw URL alone is brittle; prefer URL + title +
  publisher so the item is findable if the URL rots.
- If the only way to obtain the item is through a specific vendor
  relationship or purchase, say so.
- Re-verify URLs every 6 months. Update the "Last verified accessible"
  date. If broken, search for a current location and update the row —
  do not silently leave a dead URL.
- If a license override is recorded in `CUSTOMER_NOTES.md`, reference
  that entry in the "License / terms" cell.
- For local PDFs over 20 pages or 1 MB, `researcher` creates or
  refreshes a `.txt` sibling in the same `local/` directory (usually
  `pdftotext -layout`) and records the extraction status in the
  "Text extraction" cell. Scanned PDFs that need OCR are marked
  `blocked: OCR needed` until handled.

### Slug vs row ID

The on-disk filename slug is opaque storage. The inventory row ID is
the citation handle.

They may diverge. Do not rename a fetched file only to make its slug
match an inventory row ID.

If a fetched filename's slug or prefix collides with an existing row ID
for a different source, keep the fetched filename, assign the next free
row ID in the inventory sequence, and record the exact path in the
"Local filename" cell.

### Conventions

Copy this into a per-domain inventory after the first slug / row-ID
divergence:

> On-disk filenames under `local/` are opaque storage names.
> Inventory row IDs are the citation handles used by committed notes.
> A row ID and a filename slug may differ.
> On slug collision, keep the fetched filename, assign the next free row
> ID, and record the exact local path in the row.

---

## Topic tag vocabulary (domain-specific)

Short list of the tags used in the "Covers" columns above so they stay
consistent. Defined per domain, not global.

- `<tag>` — <one-line meaning>

---

## Change log

Append-only.

- YYYY-MM-DD — <added/removed/re-verified/corrected> — <row ID or filename> — <one-line note>
