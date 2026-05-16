# Open Questions register

Tracks every open question on the project. Steward: `researcher`.
`tech-lead` opens items; the named answerer closes them.

Columns:

- **ID** — `Q-NNNN`, monotonic.
- **Opened** — ISO date.
- **Question** — single sentence, sharp enough to answer.
- **Blocked on** — what cannot proceed until this is answered.
- **Answerer** — `customer` / `tech-lead` / `architect` / `researcher` / `sme-<domain>` / agent name.
- **Status** — `open` / `answered` / `deferred` / `withdrawn`.
- **Resolution** — verbatim answer (if from customer, mirror into `CUSTOMER_NOTES.md`) + date.

Canonical question-batching rule (binding, identical wording in
`CLAUDE.md`, `docs/FIRST_ACTIONS.md`, `.claude/agents/tech-lead.md`, and
`docs/templates/intake-log-template.md`):

> Batch questions internally in docs/OPEN_QUESTIONS.md.
> Do not batch customer-facing questions.
> Ask one queued customer question per turn, only when all agents and tools are idle, with the question as the final line.

Enforcement: Customer Question Gate in `.claude/agents/tech-lead.md`
(FR-011); lint by `scripts/lint-questions.sh` (FR-012).

| ID | Opened | Question | Blocked on | Answerer | Status | Resolution |
|---|---|---|---|---|---|---|
| Q-0001 | … | … | … | … | … | archived 2026-05-13 -> [archive](./OPEN_QUESTIONS-ARCHIVE.md#row-Q-0001) |
| Q-0002 | … | … | … | … | … | archived 2026-05-13 -> [archive](./OPEN_QUESTIONS-ARCHIVE.md#row-Q-0002) |
| Q-0003 | … | … | … | … | … | archived 2026-05-13 -> [archive](./OPEN_QUESTIONS-ARCHIVE.md#row-Q-0003) |
| Q-0004 | … | … | … | … | … | archived 2026-05-13 -> [archive](./OPEN_QUESTIONS-ARCHIVE.md#row-Q-0004) |
| Q-0005 | … | … | … | … | … | archived 2026-05-13 -> [archive](./OPEN_QUESTIONS-ARCHIVE.md#row-Q-0005) |
| Q-0006 | … | … | … | … | … | archived 2026-05-13 -> [archive](./OPEN_QUESTIONS-ARCHIVE.md#row-Q-0006) |
| Q-0007 | … | … | … | … | … | archived 2026-05-13 -> [archive](./OPEN_QUESTIONS-ARCHIVE.md#row-Q-0007) |
| Q-0008 | … | … | … | … | … | archived 2026-05-13 -> [archive](./OPEN_QUESTIONS-ARCHIVE.md#row-Q-0008) |
| Q-0009 | … | … | … | … | … | archived 2026-05-13 -> [archive](./OPEN_QUESTIONS-ARCHIVE.md#row-Q-0009) |
| Q-0010 | … | … | … | … | … | archived 2026-05-13 -> [archive](./OPEN_QUESTIONS-ARCHIVE.md#row-Q-0010) |
| Q-0011 | … | … | … | … | … | archived 2026-05-13 -> [archive](./OPEN_QUESTIONS-ARCHIVE.md#row-Q-0011) |
| Q-0012 | … | … | … | … | … | archived 2026-05-13 -> [archive](./OPEN_QUESTIONS-ARCHIVE.md#row-Q-0012) |
| Q-0013 | 2026-05-16 | Researcher runtime contract `SC-002` margin is 17.2% vs the 20% floor (issue #151). Apply the "where-safe exception" precedent and keep current text, or trim to reach the 20% floor? | T030 disposition of #151 (researcher fix-and-close vs PM wontfix-and-close) | customer | answered | 2026-05-16: **Trim** — moved pronoun-verification block to `docs/agents/manual/researcher-manual.md` § "Pronoun verification". Runtime 1655 → 1494; SC-002 cleared with 25.1% margin. Closed via PR #248 (#151). |
| Q-0014 | 2026-05-16 | `tests/prompt-regression/` artifacts (`results-*.md` + `token-ledger.md`) — track in git, gitignore, or split (track schema, gitignore per-run results)? Issue #189. | T032 disposition of #189 (qa-engineer fix-and-close) | customer | answered | 2026-05-16: **Gitignore both** — both declared ephemeral session output. qa-engineer dispatched for fix-and-close of #189. |
