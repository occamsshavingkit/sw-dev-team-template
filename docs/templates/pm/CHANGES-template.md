# Change Log — <project name>

PMBOK Monitoring / Controlling artifact. Owned by `project-manager`.
Every change to scope, schedule, cost, quality, or a baselined PM
artifact gets a row. Append-only — corrections are new rows referencing
the original.

## Change control thresholds

Changes below the threshold may be absorbed by the owner without a
formal change; changes at or above require a row here and explicit
approval.

| Dimension | Threshold for formal change | Approver |
|---|---|---|
| Scope | any scope addition / removal that crosses a milestone exit criterion | customer (via `tech-lead`) |
| Schedule | slip > <N> days on a milestone | customer (via `tech-lead`) |
| Cost | > <X> % over baseline | customer (via `tech-lead`) |
| Quality | any loosening of acceptance criteria | customer (via `tech-lead`) |
| Safety-critical | any change touching safety-critical path | customer live approval (no cached approval) |

## Change log

| ID | Date | Submitted by | Description | Dimension | Impact (scope / schedule / cost / quality) | Approver | Decision (approved / rejected / deferred) | Decision date | Notes |
|---|---|---|---|---|---|---|---|---|---|
| C-1 | | | | | | | | | |

## Cross-references

Link each approved change to the downstream artifact it modified:
`CHARTER.md` §, `SCHEDULE.md` milestone, `COST.md` baseline,
requirements doc §, architecture ADR, etc.
