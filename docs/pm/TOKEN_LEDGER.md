# Token Ledger — sw-dev-team-template

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
- **Agent** — role name (`architect`, `software-engineer`, etc.) or
  teammate name if the project renamed per `AGENT_NAMES.md`.
- **Tokens** — total tokens for that dispatch (input + output, as
  reported by the session).
- **Prompt (verbatim, fenced)** — the exact brief given to the agent,
  inside a fenced block. No paraphrase.
- **Notes** — anomalies worth future reference: early termination,
  context-limit pressure, retry, respawn, etc.

## Ledger

| Date | Task ID | Agent | Tokens | Prompt (verbatim, fenced) | Notes |
|------|---------|-------|--------|---------------------------|-------|

Initial state, 2026-05-03: no measured per-dispatch token rows have
been recorded yet. The rc4 PM governance pass instantiated this file,
but the harness did not expose a reliable total token count suitable for
the `Tokens` column.

## Conventions

- **Append-only.** Do not edit or delete rows. Corrections go in a
  new row referencing the corrected one via `Notes`.
- **Aggregate per task at closure** — if a task dispatched three
  subagents, log three rows with the same `Task ID`.
- **Create on first use.** This file was created during the rc4 PM
  governance pass with an explicit no-measured-token initial state
  rather than an invented estimate.
