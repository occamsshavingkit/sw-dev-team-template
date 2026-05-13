# docs/pm/token-ledger/prompts/

Verbatim-prompt archive supporting `docs/pm/token-ledger.md` rows per
FR-005. Each file holds one dispatched prompt; the live ledger row
references the file via its `Prompt hash` cell.

## When to write here

Optional. Archive a prompt only when it is non-trivial:

- the dispatch brief is **> 500 words**, OR
- the task is **calibration-disputable** (the row will likely be cited
  in future budget arguments, post-mortems, or R-2 band review).

Trivial prompts may live as a hash-only reference in the live ledger.

## File naming

`<task-id>-<agent>.md` — e.g. `T012-software-engineer.md`. Re-dispatches
to the same agent for the same task suffix with `.1`, `.2`, …:
`T012-software-engineer.1.md`, `T012-software-engineer.2.md`.

## File contents

The verbatim prompt as dispatched, inside a fenced code block (`` ```text ``).
Optional YAML frontmatter:

```yaml
---
task_id: T012
agent: software-engineer
dispatched_at: 2026-05-13
prompt_class: dispatch
prompt_hash: a1b2c3d4e5f6
---
```

The `prompt_hash` (first 12 hex chars of sha256) MUST match the live
ledger row's `Prompt hash` cell.

## Invariants

- **Append-only.** Once committed, a prompt file does not change.
  Re-dispatches create new files; corrections do not edit history.
- **Classification: ephemeral** (data-model.md E-5 companion). Not
  loaded into any agent's runtime context.

## Lifecycle

Prompt files survive milestone closes; they are **not** archived by
`scripts/archive-registers.sh`. Cleanup is manual at MAJOR-boundary
releases (e.g. v1.0.0 → v2.0.0) when the team consciously prunes
calibration history that no longer applies.
