# Token Ledger — <project name>

Compact append-only log of token consumption per task dispatch. Owned
by `project-manager`; populated at task closure per the DoD row in
`docs/templates/task-template.md`.

## Purpose

Feeds the estimation model `project-manager` uses for future task
budgeting without storing full prompts in the live ledger. A task closed
without a ledger row cannot inform future estimates.

## Schema

One markdown table, append-only. Columns:

| Date | Task ID | Agent | Prompt hash | Prompt class | Token budget | Token actual | Notes |
|---|---|---|---|---|---:|---:|---|

- **Date** — YYYY-MM-DD of the dispatch or closure.
- **Task ID** — task identifier from the active task plan.
- **Agent** — canonical role name or teammate name from `docs/AGENT_NAMES.md`.
- **Prompt hash** — stable hash of the dispatched prompt or `unavailable`.
- **Prompt class** — compact class such as `implementation`, `review`,
  `research`, `qa`, `pm`, or `orchestration`.
- **Token budget** — estimated budget for the dispatch.
- **Token actual** — measured total tokens, when available.
- **Notes** — anomalies, retries, archive pointer, or measurement limits.

Full prompt text is not stored here. Archive full prompts only when audit
or regression review needs exact text, following
`docs/pm/token-ledger/prompts/README.md`.

## Example row

| Date | Task ID | Agent | Prompt hash | Prompt class | Token budget | Token actual | Notes |
|---|---|---|---|---|---:|---:|---|
| 2026-04-23 | T-0042 | software-engineer | sha256:abc123... | implementation | 30000 | 12430 | First pass; one retry after hook failure. |

## Conventions

- **Append-only.** Do not edit or delete rows. Corrections go in a
  new row referencing the corrected one via `Notes`.
- **Aggregate per task at closure.** If a task dispatched three agents,
  log three rows with the same `Task ID`.
- **Create on first use.** The template ships no `TOKEN_LEDGER.md` at
  the project root under `docs/pm/`; the first task to close copies
  this template into place.
