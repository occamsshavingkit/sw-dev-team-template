---
name: customer-note-entry-template
description: Canonical shape for a single CUSTOMER_NOTES.md entry. The content-aware guard enforces this structure.
template_class: customer-note-entry
---


# Customer Note Entry Template

<!-- TOC -->

- [Purpose](#purpose)
- [Entry shape (canonical)](#entry-shape-canonical)
- [Field reference](#field-reference)
- [Rules](#rules)
- [Filled example](#filled-example)

<!-- /TOC -->

## Purpose

This template defines the canonical structure for one entry in
`CUSTOMER_NOTES.md`. The content-aware guard (`customer-notes-guard.py`)
enforces this shape. Use it whenever `librarian` appends a new
customer-truth record. Entries that deviate from this shape — missing
fields, unquoted answers, oversized prose, or off-scope commentary —
will be flagged by the guard.

`CUSTOMER_NOTES.md` is the authoritative record of verbatim customer answers.
`librarian` is the steward: only `librarian` appends entries. `tech-lead`
routes verbatim answers to `librarian`; `librarian` writes the record.

---

## Entry shape (canonical)

```markdown
## YYYY-MM-DD — <issue/ref>: <short title> (turn: <intake-log ref>)

**Question (from tech-lead, Q-NNNN):**
> <verbatim question>

**Customer answer (verbatim):**
> <verbatim answer>

**Recorded by:** <role>
```

This shape is exact. Do not reorder fields, rename headings, or add
free-form paragraphs between fields. Additional context belongs in the
`notes:` field of the corresponding intake-log entry, not here.

---

## Field reference

| Field | Format | Notes |
|---|---|---|
| Heading date | `YYYY-MM-DD` | Date the answer was received, UTC |
| `<issue/ref>` | Issue number, ADR ID, or `Q-NNNN` | The artifact that prompted the question |
| `<short title>` | ≤ 8 words | Identifies the decision at a glance |
| `(turn: <intake-log ref>)` | `turn: N` | Links to the intake-log entry for this Q&A round |
| `Q-NNNN` | Question register ID | From `docs/OPEN_QUESTIONS.md` |
| Verbatim question | Blockquote (`>`) | Exact wording sent to the customer — no paraphrase |
| Verbatim answer | Blockquote (`>`) | Exact customer reply — no paraphrase |
| `Recorded by` | Role name | Always `researcher` for new entries |

---

## Rules

1. **Verbatim only.** Both the question and the answer are quoted exactly as
   spoken/written. Never paraphrase in these fields. Paraphrase belongs in
   the intake-log `decision:` or `notes:` field.
2. **Blockquote syntax required.** The `>` prefix is structural, not stylistic.
   The guard checks for it. A missing blockquote is a schema violation.
3. **`librarian` is the steward.** No other agent writes to `CUSTOMER_NOTES.md`.
   If another agent needs to record a customer answer, it routes to `librarian`
   with the verbatim text.
4. **Scope and size.** Each entry covers one question-answer pair. Do not combine
   multiple Q&As into one entry. The guard flags entries that are oversized
   (excessive prose outside the canonical fields) or off-scope (content that
   belongs in a different artifact such as an ADR or a task).
5. **Append-only.** Never edit a prior entry. If a customer revises an earlier
   answer, add a new entry that references the superseded one by heading anchor.
6. **Cross-reference the intake log.** Every entry cites the intake-log `turn:`
   it corresponds to. The intake-log entry in turn cites this entry's heading
   anchor (per intake-log Hard Rule #5).

---

## Filled example

```markdown
## 2026-06-03 — Q-0031: customer-note entry shape (turn: 47)

**Question (from tech-lead, Q-0031):**
> Should the CUSTOMER_NOTES.md entry template enforce a specific structured
> shape, and should a content-aware guard validate entries against it?

**Customer answer (verbatim):**
> Yes — use a structured template and add a content-aware guard. The guard
> should flag oversized, off-scope, or unstructured entries.

**Recorded by:** researcher
```
