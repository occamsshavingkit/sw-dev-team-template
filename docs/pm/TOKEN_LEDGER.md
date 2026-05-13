# Token Ledger — sw-dev-team-template

<!--
Schema source: FR-005 (specs/006-template-improvement-program/spec.md) and
data-model.md E-5. Token-budget bands come from research.md R-2 (word-count
proxy via `wc -w`; bands tiny/small/medium/large/xl).

Verbatim prompts (when retained) live alongside this file under
`docs/pm/token-ledger/prompts/<task-id>-<agent>.md`; see that directory's
README.md for the archive contract. The live ledger holds only the hash —
never the prompt body. Append-only; corrections are new rows referencing
the corrected `Task ID` in `Notes`.

Schema bumped at M1.3 (this program) from the six-column rc4-era form
(Date | Task ID | Agent | Tokens | Prompt verbatim | Notes) to the
eight-column FR-005 form below.
-->

Append-only log of token consumption per task dispatch. Owned by
`project-manager`; populated at task closure per the DoD row in
`docs/templates/task-template.md`.

## Purpose

Feeds the estimation model `project-manager` uses for future task
budgeting. A task closed without a ledger row cannot inform future
estimates. The hash + optional archive split (FR-005) keeps the live
ledger grep-able while preserving full-prompt reproducibility when
calibration disputes arise.

## Schema (FR-005, eight columns)

| Column | Notes |
|---|---|
| `Date` | ISO 8601 date of the dispatch (not task closure). |
| `Task ID` | Primary key, e.g. `T012`, `T058`. |
| `Agent` | Role slug (`architect`, `software-engineer`, …) or teammate name per `AGENT_NAMES.md`. |
| `Prompt hash` | sha256 of the full dispatched prompt, truncated to first 12 hex chars. Matches archive filename when present. |
| `Prompt class` | Enum: `dispatch`, `regen`, `audit`, `summary`, `interactive`. |
| `Token budget` | Enum from research.md R-2: `tiny` / `small` / `medium` / `large` / `xl`. |
| `Token actual` | Integer; words via `wc -w` proxy at dispatch time. |
| `Notes` | Optional free-form short text (anomalies, retry, respawn, …). |

## Ledger

| Date | Task ID | Agent | Prompt hash | Prompt class | Token budget | Token actual | Notes |
|------|---------|-------|-------------|--------------|--------------|--------------|-------|
| 2026-05-13 | T004 | software-engineer | `a1b2c3d4e5f6` | dispatch | small | 2480 | M0 baseline-script dispatch; example row, placeholder hash. |

## Conventions

- **Append-only.** Do not edit or delete rows. Corrections go in a
  new row referencing the corrected one via `Notes`.
- **One row per dispatch.** If a task dispatched three subagents, log
  three rows with the same `Task ID` and distinct `Agent` / `Prompt
  hash`. Re-dispatches to the same agent get a fresh row and a fresh
  archive file (`<task-id>-<agent>.1.md`, `.2.md`, …).
- **Hash, not body.** Never paste prompt text into a ledger cell. If
  the prompt is non-trivial (>500 words or calibration-disputable),
  archive it under `docs/pm/token-ledger/prompts/<task-id>-<agent>.md`
  per that directory's README.
- **Word-count proxy.** `Token actual` is `wc -w` of the dispatched
  prompt at dispatch time. Bands per R-2 are PM-tunable; reviewed at
  M2 gate close and at G9.
- **TBD allowed for migrated rows.** When migrating a row from the
  prior six-column schema, `Prompt hash`, `Prompt class`, `Token
  budget`, and `Token actual` may carry `TBD` until back-fill.
