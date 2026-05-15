# SME Contract (binding)

Consolidated reference for what an SME agent is, what it is not, and
how it interacts with `researcher`. Closes upstream issue #6.

**Ruling source.** Customer ruling 2026-04-19 (Fix-C hybrid). Verbatim
capture lives in `CUSTOMER_NOTES.md`; this document paraphrases and
integrates. Binding precedence: the ruling > this document > agent
files > this document's examples.

---

## 1. Why this document exists

Upstream issue #6 flagged ambiguity in the original SME contract:

- Did an SME agent require a *primary source* (a human expert, or
  proprietary docs not elsewhere public)?
- If yes, what about domains where the project needed specialist
  judgment but no non-public source existed — e.g., "TypeScript
  type-level programming" on a project with no external TS expert?
- How did SMEs interact with `researcher` — separate lanes, or
  overlapping mandates with potential for duplicate-and-drift?

The original contract assumed a primary-source SME only, which
pushed teams either (a) to stand up SMEs with fabricated authority
("we need a brewing expert; customer says they're a master brewer
— SME!" but the knowledge was publicly available anyway), or (b)
to dump specialist context onto `researcher`, inflating its context
window.

## 2. The two modes (binding)

Every `sme-<domain>.md` agent declares its mode in frontmatter:
`mode: primary-source` or `mode: derivative`. Chosen at creation
time. Mode is durable — changing mode is effectively a new SME,
files the old one supersedes the new.

### 2.1 Primary-source SME

**Has a non-public knowledge source** and speaks as the
authoritative voice for the domain.

Qualifying sources:

- A named human expert (the customer, or an external SME the
  customer has introduced) whose knowledge has been captured in the
  agent's notes + `CUSTOMER_NOTES.md` entries.
- Proprietary documentation licenced to the project and held in
  `docs/sme/<domain>/local/` with an inventory row.
- Site / install archaeology specific to the customer's physical or
  virtual plant — configurations, undocumented quirks, legacy
  behaviours.
- Regulatory / compliance *application* specific to the customer
  (the standard itself is `researcher` territory; how *this*
  customer interprets and implements it is SME territory).
- Internal terminology, codenames, business rules.

Output style: cites the non-public source first; may cite public
Tier-1 material on top for reinforcement. Speaks with authority.

### 2.2 Derivative SME

**No primary source.** Consumes `researcher`'s paraphrases + public
Tier-1 citations, adds domain-specialist framing / opinion /
trade-off narration.

Exists for **context segmentation** — so `researcher` doesn't hold
every vendor ecosystem in a single context window when a project
juggles N domains.

Output style: every fact carries a `researcher`-sourced citation
pointing at Tier-1 material. The SME's added value is *judgment /
framing / opinion*, explicitly flagged as such, not as new fact.
A derivative SME that asserts a fact without a citation is misusing
the mode — the underlying question should route back through
`researcher`.

### 2.3 Not an SME (either mode)

- **Pure standards lookups** with no project-specific framing —
  SWEBOK, IEEE, ISO, ISTQB, PMBOK, SFIA. These are `researcher`'s
  domain; do not stand up `sme-swebok` or `sme-pmbok`.
- **Official vendor documentation lookups** with no customer
  framing — `researcher` retrieves and cites.
- **A derivative SME is fine** even in a domain that frequently
  cites a standard (e.g., `sme-brewing` citing plant-iT vendor
  docs), as long as the SME adds judgment on top.

## 3. Rule of thumb (for `tech-lead` at routing time)

| Question shape | Route to |
|---|---|
| "What does SWEBOK V4 say about X?" | `researcher` |
| "What does the vendor docs say about Y?" | `researcher` |
| "How does *this customer* apply Y in their plant?" | `sme-<domain>` (primary-source) |
| "What are the trade-offs of approach Z in domain D?" | `sme-<domain>` (derivative) — if the project has one |
| "How do we structure this *domain-specific* decision?" | `sme-<domain>` first; escalate to customer via `tech-lead` if SME lacks authority |
| No `sme-<domain>` exists for the question's domain? | Escalate to `tech-lead`; `tech-lead` decides whether to stand up an SME or escalate to customer |

## 4. Creating an SME agent

See `CLAUDE.md` § "Creating an SME agent" for the procedure. In
short:

1. `tech-lead` confirms with the customer that the domain warrants
   an SME and which mode fits.
2. `tech-lead` copies `.claude/agents/sme-template.md` to
   `.claude/agents/sme-<domain>.md`.
3. Frontmatter `mode:` set to the agreed mode.
4. `researcher` seeds `docs/sme/<domain>/INVENTORY.md` from
   `docs/sme/INVENTORY-template.md`.
5. `tech-lead` routes future domain questions to the new SME.

## 5. Interaction with `researcher`

Binding rules:

- An SME agent MAY query `researcher` for Tier-1 citations
  supporting its position. `researcher` cites; the SME frames.
- `researcher` MUST NOT stand in for an SME on questions whose
  answer depends on the customer or a named external expert —
  that's escalation to `tech-lead`.
- Source inventories for each SME's external material live in
  `docs/sme/<domain>/INVENTORY.md`. `researcher` curates them;
  the SME contributes content. IP policy applies identically to
  both.

## 6. When the ruling applies

- New projects scaffolded from template v0.11.0+ — contract applies
  from Step 2 scoping forward.
- Existing projects scaffolded from earlier versions — contract
  applies after `scripts/upgrade.sh` lands the new
  `CLAUDE.md` + `sme-template.md`. Projects with SMEs created
  before the ruling should be audited for mode: if the SME has a
  non-public source, mark `primary-source`; otherwise
  `derivative`. Missing frontmatter is not a crisis, just a
  yellow flag at the next milestone-close review.

## 7. Revision log

| Date | Change | Ratified by |
|---|---|---|
| 2026-04-19 | Fix-C hybrid ruling — two-mode SME contract adopted | Customer (see `CUSTOMER_NOTES.md`) |
| 2026-04-23 | Consolidated memo written (this file); replaces prior scattered references in CHANGELOG + CUSTOMER_NOTES | tech-lead + researcher (closes issue #6) |

## 8. Cross-references

- `CLAUDE.md` § "SME scope: what is and is not an SME (binding)"
- `.claude/agents/sme-template.md` § "Mode (pick one at creation;
  binding)"
- `.claude/agents/researcher.md` § "Source discipline" and § "SME
  inventory steward"
- `CUSTOMER_NOTES.md` — 2026-04-19 ruling entry
- Upstream issue: occamsshavingkit/sw-dev-team-template#6
