---
name: token-ledger-template
description: Append-only token-consumption ledger per task dispatch; populated at task closure per DoD.
template_class: token-ledger
---


# Token Ledger — <project name>

Append-only log of token consumption per task dispatch. Owned by
`project-manager`; populated at task closure per the DoD row in
`docs/templates/task-template.md`.

## Purpose

Feeds the estimation model `project-manager` uses for future task
budgeting. A task closed without a ledger row cannot inform future
estimates. Keeping the verbatim prompt alongside the token count lets
the PM calibrate "this shape of ask costs roughly N tokens" when
scoping the next slice of work.

## Schema

One markdown table, append-only. Columns:

| Date | Task ID | Agent | Tokens | Prompt (verbatim, fenced) | Notes |
|------|---------|-------|--------|---------------------------|-------|

- **Date** — YYYY-MM-DD of the dispatch (not task closure).
- **Task ID** — `T-NNNN` from `docs/tasks/`.
- **Agent** — role name (`architect`, `software-engineer`, …) or
  teammate name if the project renamed per `AGENT_NAMES.md`.
- **Tokens** — total tokens for that dispatch (input + output, as
  reported by the session).
- **Prompt (verbatim, fenced)** — the exact brief given to the agent,
  inside a fenced block. No paraphrase.
- **Notes** — anomalies worth future reference: early termination,
  context-limit pressure, retry, respawn, etc.

## Example row

| Date | Task ID | Agent | Tokens | Prompt (verbatim, fenced) | Notes |
|------|---------|-------|--------|---------------------------|-------|
| 2026-04-23 | T-0042 | software-engineer | 12,430 | <code>Implement the `parse_header` function per `docs/tasks/T-0042.md`. Follow existing style in `src/parser/`. Unit tests required.</code> | First pass; one retry after hook failure. |

## Conventions

- **Append-only.** Do not edit or delete rows. Corrections go in a
  new row referencing the corrected one via `Notes`.
- **Aggregate per task at closure** — if a task dispatched three
  subagents, log three rows with the same `Task ID`.
- **Create on first use.** The template ships no `TOKEN_LEDGER.md` at
  the project root under `docs/pm/`; the first task to close copies
  this template into place.
