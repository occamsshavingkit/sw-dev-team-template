# Issue draft — CUSTOMER_NOTES.md: no machine enforcement of entry scope or size

## Template version

```text
v1.1.1
SHA 2984c6890046c48c577b7cd3ba3b4d344622b526
```

## Short title

`CUSTOMER_NOTES.md` entry scope and size are advisory-only;
`customer-notes-guard.py` is content-blind.

## Where

- `scripts/hooks/customer-notes-guard.py` — content-blind approval
  gate; no size or scope inspection.
- `.claude/agents/researcher.md` § "Customer-notes steward" and
  § "Archival + size budgets" — soft-size-budget rule and verbatim
  requirement are prose-only; no machine enforcement.
- `CUSTOMER_NOTES.md` entry template — section vocabulary not enforced.
- `docs/DECISIONS.md` — single append-file with no sharded-record
  convention; decision-memo content drifts into `CUSTOMER_NOTES.md`
  when no better home exists.

## What happened

On a downstream project, `CUSTOMER_NOTES.md` grew to 531 KB, 108
entries, with a median entry length of 68 lines and a maximum of
690 lines. Zero entries were at or under 10 lines; 73 exceeded
50 lines. Operators invented sections the template does not define
(`Context`, `Cross-refs`, `Downstream effects`, `Process notes`)
across the majority of entries. Only 76 of 108 entries contained
a "Customer answer" field — roughly 30% recorded no customer ruling.
One question ID was triplicated across `CUSTOMER_NOTES.md` (44
occurrences), `docs/intake-log.md` (13), and `docs/OPEN_QUESTIONS.md`
(2). `docs/DECISIONS.md` was abandoned at 47 lines; the intended
decision home was empty while `CUSTOMER_NOTES.md` absorbed decision
memos. `docs/OPEN_QUESTIONS.md` reached 232 KB with a single entry at
16 KB, indicating the queue was never drained.

A second downstream project of comparable template lineage showed a
median entry length of 24 lines, near-zero invented sections, and an
active `docs/DECISIONS.md` at 103 lines. This control project isolates
operator behavior as the dominant variable; the template rules were
identical in both cases.

## Why it is a gap

The `researcher.md` contract has carried both the verbatim-recording
requirement and the soft-size-budget rule since early in the rc series.
`customer-notes-guard.py` is wired on every write path but inspects
only whether a write should proceed, not what is written. There is no
lint equivalent to `scripts/lint-questions.sh` for entry scope or size.
The result is that the binding rules are unenforceable by any automated
path; a project's conformance depends entirely on session-level operator
habit. The gap affects `CUSTOMER_NOTES.md` as an escalation artifact: a
531 KB always-read file with 690-line entries imposes a large and growing
context cost on every agent that must consult it.

The v1.1.1 release does not close this gap. The guard script remains
content-blind at that version.

## Suggested fix

In priority order:

1. **Entry-scope lint for `CUSTOMER_NOTES.md`.** Add a script (e.g.,
   `scripts/lint-customer-notes.sh`) that flags: entries exceeding a
   configurable line threshold (suggested default: ~30 lines), entries
   lacking a "Customer answer" block, and entries containing section
   headings not in the canonical template. Wire it the same way as
   `scripts/lint-questions.sh` — advisory in pre-commit, hard-gate
   in CI after a recorded `HARDGATE_AFTER_SHA`.

2. **Sharded decision records.** Introduce `docs/decisions/D-NNNN.md`
   as the canonical home for decision memos, with a generated index.
   Add a routing rule: decision rationale goes to `docs/decisions/`;
   `CUSTOMER_NOTES.md` records only the verbatim customer answer and
   a back-reference. Retire the single-file `docs/DECISIONS.md`
   append pattern or keep it as an auto-generated index only.

3. **`OPEN_QUESTIONS.md` drain rule.** A resolved question must be
   moved to a decision record and deleted from the queue in the same
   turn. The queue should never carry answered rows; answered rows
   that persist are a process violation flagged by the lint.

4. **Relationship to spec 016 (token-economy).** Spec 016 is trimming
   agent CONTRACT files to reduce per-session context. The runtime
   register growth documented here (`CUSTOMER_NOTES.md`,
   `OPEN_QUESTIONS.md`) is a parallel and larger context-budget
   problem that is currently out of scope for 016. It should be folded
   into 016 or filed as a companion issue so the two efforts share a
   measurement baseline.
