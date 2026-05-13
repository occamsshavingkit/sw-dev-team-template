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
