# librarian — manual (rationale, examples, history)

**Canonical contract**: [.claude/agents/librarian.md](../../../.claude/agents/librarian.md)
**Generated runtime contract**: [docs/runtime/agents/librarian.md](../../runtime/agents/librarian.md)
**Classification**: canonical (manual; rationale companion)

This manual carries rationale, formats, and example content that supports
the librarian canonical contract but is not part of the compact runtime
contract. The canonical contract names each rule; this manual carries
elaboration, entry formats, archival mechanics, and SME-inventory
procedures.

The custodial duties in this manual were previously held by `researcher`
(prior to #291). The split was ratified by customer ruling Q-0031 /
issue #291: `researcher` retains investigation (sourcing, prior-art scans,
pronoun verification); `librarian` holds all record custodianship
(customer-truth, open-questions, glossary, SME inventories, archival).

## CUSTOMER_NOTES.md format

The canonical entry shape is defined and enforced by
`docs/templates/customer-note-entry-template.md`. Use that template
as the reference when appending any entry. The shape reproduced here
must stay in sync with that template; if they diverge, the template
is authoritative.

```
## YYYY-MM-DD — <issue/ref>: <short title> (turn: <intake-log ref>)

**Question (from tech-lead, Q-NNNN):**
> <verbatim question>

**Customer answer (verbatim):**
> <verbatim answer>

**Recorded by:** librarian
```

Both the question and the answer are blockquoted (`>`) and verbatim —
no paraphrase. `librarian` is the sole agent that appends entries.
Additional context (implications, routing decisions) belongs in the
corresponding intake-log entry's `notes:` or `decision:` fields, not
in the `CUSTOMER_NOTES.md` entry itself. Entries that are oversized,
off-scope, or structurally non-conformant are flagged by
`scripts/hooks/customer-notes-guard.py`.

**Intake-log cross-reference.** Every entry cites the intake-log `turn:`
it corresponds to. If no intake-log entry exists for the answer being
recorded, flag to `tech-lead` before writing the entry — `tech-lead`
appends the intake-log row first.

**Process-drift flag.** If a `CUSTOMER_NOTES.md` entry was written
inline by `tech-lead` (or any non-`librarian` agent), flag it as
process drift to `tech-lead` and preserve the original text rather than
silently rewriting history.

## Archival mechanic

Binding docs accumulate closed rows and grow past their useful density.
`librarian` owns rolling closed content out.

**Append-only archive files.** Each binding register that can have
closed rows gets a peer file:

| Live file | Archive file |
|---|---|
| `OPEN_QUESTIONS.md` | `OPEN_QUESTIONS-ARCHIVE.md` |
| `docs/pm/RISKS.md` | `docs/pm/RISKS-ARCHIVE.md` |
| `docs/pm/LESSONS.md` | `docs/pm/LESSONS-ARCHIVE.md` |
| `docs/tasks/*.md` | `docs/tasks/ARCHIVE/` |

When a row's status is terminal (answered / closed / resolved / shipped)
and has been stable for at least one milestone close, move it to the
archive. The archive is append-only: never edit or reorder archived rows.

**Soft size budgets (guidance, not gates).**

| Register | Soft line cap | Warning threshold |
|---|---:|---|
| `CUSTOMER_NOTES.md` | 500 lines | 400 lines (80%) |
| `OPEN_QUESTIONS.md` | 200 open rows | 160 rows |
| Each `docs/glossary/*.md` | 300 lines | 240 lines |
| Each `docs/sme/<domain>/INVENTORY.md` | 200 rows | 160 rows |

When a doc reaches 80% of its cap, surface a warning to `tech-lead`
proposing an archival pass. Caps are guidance; customer / architect can
override with an ADR.

**Archival is not deletion.** Archived content stays in git history and
in the archive file. It is removed from the live context only.

**Archival mechanic script.** Implemented in `scripts/archive-registers.sh`
(FR-004). Cutoff auto-derived from `docs/pm/SCHEDULE.md`'s most-recent
`passed` row. `CUSTOMER_NOTES.md` requires `--include-customer-notes`
to opt in (customer-truth safety).

## SME inventory stewardship

Every `docs/sme/<domain>/` directory has an `INVENTORY.md` based on
`docs/sme/INVENTORY-template.md`. `librarian` keeps them current.

**URL re-verification.** Re-verify all inventory URLs every 6 months.
A URL that 404s becomes a `blocked:` row until a replacement is found.

**Large-PDF extraction procedure.** When a local-only PDF under
`docs/sme/<domain>/local/` is over 20 pages or 1 MB:

1. Run `pdftotext -layout <file>.pdf <file>.txt`.
2. Record in the inventory row: extraction path, tool used (`pdftotext
   -layout`), and date extracted.
3. If the PDF is scanned and extraction fails (output is empty or
   garbled), mark the row `blocked: OCR needed` and notify `tech-lead`.
   Do not let SME agents discover the unreadable-PDF gap during a later
   dispatch.

**File-creation handoff.** When any agent creates a new file under
`docs/sme/<domain>/` or adds external material to `local/`, the creating
agent must either (a) update `INVENTORY.md` in the same turn, or (b)
`SendMessage` to `librarian` with the new path. An `INVENTORY.md` that
does not list every item in its domain directory is a process failure —
surface it to `tech-lead` as a routing gap, not a silent fix.

## Glossary amendment procedure

1. Agent identifies an ambiguous or missing term.
2. Agent proposes amendment to `librarian` via `tech-lead`.
3. `librarian` drafts the amendment in the correct file:
   - Generic software-engineering terms → `docs/glossary/ENGINEERING.md`
   - Project-specific / customer-domain terms → `docs/glossary/PROJECT.md`
4. `librarian` routes draft to `architect` + `tech-lead` for concurrence
   (ENGINEERING.md). For PROJECT.md, additionally pull in the relevant
   `sme-<domain>` if the term is domain-specific.
5. Only after concurrence does `librarian` commit the amendment.

Never branch-redefine a term in a specific document. The glossary
files are binding; amendments propagate to all agents that load them.
