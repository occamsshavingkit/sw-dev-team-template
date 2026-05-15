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

## Sensitive content for upstream issue filing (FR-026)

**Document classification**: this section is canonical and binding for
the template and every downstream consumer scaffolded from it. It
defines the **tiered sensitive-content model** per FR-026 and spec
clarification 10 of the template improvement program (specs/006).

When an agent or contributor files a framework-gap issue against the
upstream `sw-dev-team-template` repo (per `docs/ISSUE_FILING.md` and
`.github/ISSUE_TEMPLATE/framework-gap.yml`), the report MUST be
redacted before it leaves the downstream repo. The set below is the
floor.

### Mandatory enumerated set (cannot be relaxed locally)

These four items are the MINIMUM redaction scope for any project
scaffolded from `sw-dev-team-template`. Downstream repos cannot
shrink, narrow, or carve exceptions out of this set.

1. **Customer or vendor identities and brand names** — the real name
   of the customer organization, any of its subsidiaries, and the
   brand names of vendors named in customer-truth records. Use
   placeholders such as `Customer XYZ` or `Vendor ACME`.
2. **Downstream project names** — the real name of the downstream
   repo or product (e.g., do not write the actual repo slug into an
   upstream issue body). Use a generic description like "a PLC
   firmware project" or "a brewery automation project."
3. **`CUSTOMER_NOTES.md` content (verbatim or paraphrased)** — no
   row from the customer-truth register travels upstream. Describe
   the *shape* of the framework gap the row exposed, not the row's
   subject. This includes paraphrases close enough that the customer
   would recognize the underlying conversation.
4. **Credentials, secrets, tokens, hostnames, IPs** — operational
   identifiers and authenticators of any kind, including internal
   hostnames, IP addresses, network CIDRs, API tokens, passwords,
   and connection strings.

### Per-repo extension marker

Downstream repos MAY extend the set (never shrink it) by editing
their local `docs/IP_POLICY.md`. The downstream file follows this
two-section shape:

```
## Mandatory enumerated set (inherited from sw-dev-team-template)

See upstream `docs/IP_POLICY.md` § "Mandatory enumerated set". The
four items there are binding here and not restated.

## Project-local additions

- Example: Customer XYZ's process-step names ("Mash-In phase 2",
  internal lot codes) are confidential.
- Example: Project ACME's chiller-tag naming convention is
  proprietary.
```

The upstream framework-gap-template lint scans only the mandatory
set's known downstream project names. Project-local additions are
the downstream's responsibility; if the downstream has its own CI,
it lints additions there. The mandatory floor still applies whether
or not the downstream has CI.

### Cross-links

- Upstream issue filing procedure: `docs/ISSUE_FILING.md`.
- Issue template enforcing the redaction confirmation:
  `.github/ISSUE_TEMPLATE/framework-gap.yml`.
- M0 baseline's "broken internal references" check
  (`scripts/baseline-token-economy.sh` →
  `docs/pm/token-economy-baseline.md`): every cross-link in this
  section MUST resolve under that check.
