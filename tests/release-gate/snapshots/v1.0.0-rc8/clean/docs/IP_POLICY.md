# IP policy (non-negotiable)

> Source: extracted from CLAUDE.md (v1.0.0-rc7) per issue #120.

**Assumption by default: any material not created within this project
is copyrighted.** This holds unless the customer explicitly overrides
it for a specific item in `CUSTOMER_NOTES.md`.

- Project-created work → may be committed under the project's license.
- External material → stays in `docs/sme/<domain>/local/` (gitignored)
  or equivalent local-only location. Cited in an inventory with enough
  detail for a third party to obtain the item independently.
- Paraphrases of external material → may be committed if the
  transformation is substantive and the source is cited by row ID in
  the domain's inventory.
- When in doubt, assume copyrighted.
- **Restricted-source clauses beyond default copyright.** Some external
  materials carry explicit prohibitions on top of ordinary copyright —
  most notably prohibitions on use of the material to train, fine-tune,
  or embed into retrieval-augmented generation corpora for generative
  AI. Example: PMI's PMBOK Guide 8th Edition (library row `LIB-0001`)
  copyright page contains an explicit "NO AI TRAINING" clause.
  `researcher` MUST NOT feed such materials into AI training,
  fine-tuning, or persistent embedding / vector stores for retrieval.
  Paraphrase-and-cite handling only; source text stays under the local
  gitignored path (e.g., `docs/library/local/`, `docs/sme/<domain>/local/`).
  Per-item restrictions are recorded in the relevant inventory row.

  **Scope of "AI training" (customer ruling, 2026-04-23, narrow
  interpretation):** the clause covers (a) updates to model weights
  via training / fine-tuning / RLHF on the material, and (b)
  persistent embedding / vector-store ingestion that retains the
  source text across sessions for retrieval. It does **not** cover
  transient in-context reading / inference — passing the text to a
  model for immediate paraphrase or summarization within a single
  session, after which the text does not persist in the model. This
  is the reading under which `researcher` may read the `.txt`
  extraction of a restricted source to produce a paraphrased audit.
  Revisit this interpretation if PMI or another publisher issues
  guidance narrowing or broadening the clause.

  A `.txt` extraction produced from a local-only PDF inherits the same
  IP posture as the source PDF: keep it in the same gitignored
  `local/` directory, cite it by inventory row + line range, and do not
  commit raw extracted text.

Every `docs/sme/<domain>/` directory MUST have an `INVENTORY.md` based
on `docs/sme/INVENTORY-template.md`. `researcher` maintains it.

See `docs/glossary/ENGINEERING.md` § "Intellectual property" for the
binding definitions of *project-created work*, *external material*,
*derivative work*, and *citation*.
