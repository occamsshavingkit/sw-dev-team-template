# researcher — manual (rationale, examples, history)

**Canonical contract**: [.claude/agents/researcher.md](../../../.claude/agents/researcher.md)
**Generated runtime contract**: [docs/runtime/agents/researcher.md](../../runtime/agents/researcher.md)
**Classification**: canonical (manual; rationale companion)

This manual carries rationale, formats, and example content that supports
the researcher canonical contract but is not part of the compact runtime
contract. The canonical contract names each rule; this manual carries
elaboration, source-handling detail, and the verbatim `CUSTOMER_NOTES.md`
entry format.

## Cite hygiene for restricted sources (binding)

Some external materials carry use restrictions that go beyond default
copyright — most commonly an explicit "NO AI TRAINING" clause on the
publication's copyright page. PMI's PMBOK Guide 8 (library row
`LIB-0001`) is the current motivating example; future Tier-1 sources
from PMI or other publishers may carry similar clauses.

Handling rules for restricted sources:

1. **Paraphrase only.** Verbatim quotation is capped at 15 words per
   fragment and only where the exact wording is load-bearing. Never
   commit long excerpts; cite by row ID plus specific anchor (line
   range in the extracted `.txt` and/or PDF page).
2. **No training / fine-tuning feed.** Restricted-source text must
   not be passed to an AI training pipeline, fine-tuning run, or
   persistent retrieval-augmented generation corpus (vector stores,
   embedding caches that outlive a single session). **Permitted:**
   transient in-context reading — i.e., passing the text to the
   model you are currently working with, for immediate paraphrase
   or summarization, after which the text does not persist. This
   is the narrow interpretation of "AI training" ratified by the
   customer 2026-04-23 (see `docs/IP_POLICY.md`). **Not
   permitted:** storing the raw text outside
   `docs/library/local/` (or equivalent gitignored local path);
   chunking + embedding the text into a persistent vector store;
   training-loop use.
3. **Cite by inventory row ID.** Every use in a committed file
   cites the library or SME row ID (e.g., `LIB-0001 p. 48, .txt
   line 3000–3040`). Future agents must be able to re-verify.
4. **Restriction recorded in inventory.** Each restricted source
   has its specific restriction captured in the inventory row's
   IP-restrictions / copyright column, so the handling rule
   travels with the source.

### Source-handling matrix

| Source type | Quotation policy | Embedding / RAG | Committed-file citation |
|---|---|---|---|
| Restricted-source material (e.g., `LIB-0001` with "NO AI TRAINING") | Paraphrase; ≤15-word verbatim fragments only | **Prohibited** — no training, no persistent embedding | Required: row ID + page + .txt line range |
| Tier-1 standards with default copyright (SWEBOK, IEEE, ISO, ISTQB, SFIA, official vendor docs) | Paraphrase preferred; ≤15-word verbatim fragments OK | Allowed in-session only; no persistent public corpora | Required: row ID or URL + section anchor |
| Tier-2 (SRE book, Wikipedia, well-sourced blogs) | Paraphrase preferred; short quotes OK with attribution | Allowed with attribution | Required: URL + date retrieved |
| Tier-3 (vendor blogs, forum posts) | Use sparingly; attribute | Allowed with attribution | Required: URL + date retrieved |
| Project-created work | Full quotation OK | Unrestricted within project license | Internal cross-reference |

When in doubt, treat as restricted-source and escalate via `tech-lead`
for clarification.

## CUSTOMER_NOTES.md format

```
## YYYY-MM-DD — <short topic> (turn: <docs/intake-log.md turn id, or "pre-intake">)

**Question (from <agent>, relayed by tech-lead):**
> <verbatim question>

**Customer answer (verbatim):**
> <verbatim response>

**Context / implications:**
- <only what the customer stated, or direct process context>
```

## Pronoun verification

Canonical contract Job #6 (the binding rule "verify pronouns against an
authoritative source and record the citation") points here for the
source hierarchy, citation format, fallback handling, and re-verification
cadence. The detail moved from canonical to manual on 2026-05-16 (issue
#151, SC-002 trim) — the binding *rule* still lives in the contract; only
the procedural elaboration moved here.

### Source hierarchy (use the highest available)

- **Living persons** — (a) the person's own public self-identification
  (official-site bio, verified profile, first-person interview);
  (b) their label / publisher / agency / employer bio; (c) a reference
  encyclopedia entry **when that entry itself cites (a) or (b)** —
  record the URL plus the date you checked it.
- **Historical figures** — a reference biography. Accept the era's
  conventional pronouns as the default unless a modern reference
  explicitly reconsiders them; in that case, cite the reference and
  note the reconsideration.
- **Fictional characters** — the canon source (creator's published work
  or the official franchise's current canonical site).

### Citation format

One line in the `Source` column of `docs/AGENT_NAMES.md`:

> "<title of source>, <URL or reference>, as of <YYYY-MM-DD>"

### Fallback handling

If pronouns cannot be verified to the bar above, the canonical contract
requires flagging to `tech-lead`. From there, `tech-lead` either asks
the customer to pick a different member of the category or records the
use of "they / them" as a documented fallback in `CUSTOMER_NOTES.md`.
Do not silently guess or default to "they / them" without that record.

### Re-verification cadence

Re-verify pronouns before a new version of the project's
`docs/AGENT_NAMES.md` ships if > 12 months since the last check.

## Archival sizing policy

**Authoritative source:** `docs/pm/token-economy-baseline.md`
§ "Per-agent contract sizes" and § "M1.1 post-reduction sizes".

The researcher canonical contract is subject to a size constraint:
the runtime contract (generated by `scripts/compile-runtime-agents.sh`)
must be at least 20% smaller than the M0 baseline word count
(SC-002: "≥20% reduction where safe"). Researcher's current figures:

| Version | Canonical (words) | Runtime (words) | SC-002 margin |
|---|---|---|---|
| M0 baseline | 1996 | — | — |
| Post-M1.1 (issue #151) | 1604 | 1494 | 25.1% — PASS |

**Key constraint for future edits.** The post-M1.1 margin is 5.1
points above the 20% floor. Adding content to the canonical contract
without a corresponding extraction to this manual or another prose
companion will erode SC-002 margin. Before committing any net-additive
change to `.claude/agents/researcher.md`, measure the generated runtime
word count and compare against the SC-002 ceiling:

```sh
# Compile the researcher runtime to a temp dir, then count words.
outdir=$(mktemp -d)
scripts/compile-runtime-agents.sh --out-dir "$outdir" researcher 2>/dev/null
wc -w "$outdir/researcher.md"
# SC-002 ceiling: 1996 × 0.80 = 1596.8 → must be ≤ 1596 words.
```

If `wc -w` reports more than **1596 words**, the change breaches the
SC-002 floor (M0 = 1996, 20% reduction required: `1996 × 0.80 = 1596.8`,
ceiling = 1596). Extract the new prose into this manual instead and add
a pointer from the canonical.

Note: `scripts/compile-runtime-agents.sh --check` only validates inputs
and reports `ok: researcher -> <path>`; it does **not** count words or
enforce the floor. `--verify` checks byte-identity against committed
files, also without word-count enforcement. Use the `wc -w` recipe above
to actually catch a regression.

**This section** exists because spec 016 (token-economy design pass)
referenced "the archival sizing policy in `docs/agents/manual/researcher-manual.md`"
as the source of per-file size caps. The actual cap derivation lives in
`docs/pm/token-economy-baseline.md`; this section is the named stub
that makes that reference resolvable (issue #277).
