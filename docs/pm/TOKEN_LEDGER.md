# Token Ledger — sw-dev-team-template

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

## Ledger

| Date | Task ID | Agent | Prompt hash | Prompt class | Token budget | Token actual | Notes |
|---|---|---|---|---|---:|---:|---|

Initial state, 2026-05-03: no measured per-dispatch token rows were
recorded. The rc4 PM governance pass instantiated this file, but the
harness did not expose a reliable total token count. Refactored
2026-05-12 to compact hash/class schema; no full prompts were retained
in the live ledger.

## Conventions

- **Append-only.** Do not edit or delete rows. Corrections go in a
  new row referencing the corrected one via `Notes`.
- **Aggregate per task at closure.** If a task dispatched three agents,
  log three rows with the same `Task ID`.
- **Create on first use.** This file was created during the rc4 PM
  governance pass with an explicit no-measured-token initial state
  rather than an invented estimate.
