# Data Model: Open-Issue Backlog Triage and Burndown

The data model is read-only metadata over GitHub Issues at `occamsshavingkit/sw-dev-team-template`. No persistence layer is introduced; no schema migrations; no database. All entity state lives in (a) GitHub's issue/PR API and (b) `docs/pm/dispatch-log.md` as working state during the burndown.

## Entities

### Issue

A single GitHub issue at `occamsshavingkit/sw-dev-team-template`.

**Identity**: `number` (GitHub-assigned monotonic integer; unique within the repo; immutable).

**Attributes**:

| Field            | Source                                       | Notes                                                                            |
|------------------|----------------------------------------------|----------------------------------------------------------------------------------|
| `number`         | GitHub                                       | identity; cited verbatim in PR titles, close-comments, dispatch-log entries      |
| `title`          | GitHub                                       | display only                                                                     |
| `body`           | GitHub                                       | binding spec for the fix (when applicable)                                       |
| `labels`         | GitHub                                       | informational; `v2-deferred` is set on `defer-to-v2` close                       |
| `created_at`     | GitHub                                       | used for baseline-lock semantics (≤ 2026-05-16T23:59Z = baseline)                |
| `state`          | GitHub                                       | one of `open` / `closed`                                                         |
| `bucket`         | triage.md                                    | enum; see Bucket entity                                                          |
| `disposition`    | triage.md                                    | enum; see Disposition entity                                                     |
| `owning_role`    | triage.md                                    | canonical role from OWNERSHIP_RULES                                              |
| `blocking_set`   | triage.md (implicit; explicit in PR clusters) | set of issue numbers whose closure is prerequisite                              |
| `status`         | dispatch-log.md                              | runtime status: `pending-triage`, `dispatched`, `in-review`, `ready-to-close`, `closed` |

**Lifecycle**:

```
pending-triage → dispatched → in-review → ready-to-close → closed
        \                                                      ▲
         └─→ (skip; v2-defer or wontfix path) ─────────────────┘
```

**Invariants**:
- `status = closed` ⟺ GitHub `state = closed` (the local state mirrors GitHub after each disposition lands).
- `bucket` and `disposition` are pinned at first dispatch; they do not change during the lifecycle (a re-disposition reopens the issue, which counts as a new dispatch).
- An issue with `disposition = consolidate-with-other-issue` MUST cite the surviving issue's number on close.

### Bucket

A coarse categorization used for processing order and PR grouping.

**Identity**: enum (string).

**Values** (priority-ordered per FR-003):

1. `release-gate-upgrade-flow`
2. `hook-behavior`
3. `framework-gap`
4. `framework-friction`
5. `docs-drift`
6. `v2-proposal`
7. `other`

**Notes**:
- Buckets 1–2 are P1 (release-gate blockers).
- Buckets 3–4 are P2.
- Buckets 5–7 are P3.
- New issues filed during burndown inherit a bucket on FR-010 disposition; they do NOT grow the SC-001 baseline.

### Disposition

The terminal-state classifier per issue.

**Identity**: enum (string).

**Values**:

| Value                          | Closes with        | Required artifact                                                       |
|--------------------------------|--------------------|-------------------------------------------------------------------------|
| `fix-and-close`                | merged PR          | PR link cited in close-comment (FR-004)                                 |
| `wontfix-and-close`            | rationale comment  | reason cite (superseding change / scope / obsolete) (FR-005)            |
| `defer-to-v2`                  | `v2-deferred` label + comment | anchor link to `ROADMAP.md#v2-deferred` (FR-006)            |
| `consolidate-with-other-issue` | cross-link comment | surviving issue's number; closed as duplicate (FR-007)                  |
| `close-as-duplicate`           | cross-link comment | original issue's number. Used when the canonical issue is **already closed** and the baseline issue is a re-report of the same problem. (Compare `consolidate-with-other-issue`, used when the surviving issue is **open**.) |

### Dispatch

A single assignment of an issue to an owning specialist with brief, branch, and review status.

**Identity**: composite — `(issue_number, dispatch_seq)` where `dispatch_seq` increments per re-dispatch (a re-dispatch happens if code-review rejects).

**Attributes**:

| Field                | Source                | Notes                                                                |
|----------------------|-----------------------|----------------------------------------------------------------------|
| `issue_number`       | triage.md             | foreign key to Issue                                                 |
| `dispatch_seq`       | dispatch-log.md       | 1-indexed                                                            |
| `owning_role`        | triage.md             | the specialist invoked                                               |
| `brief`              | dispatch-log.md       | one-line summary of the dispatch directive                           |
| `branch`             | dispatch-log.md       | the fix branch (e.g., `fix/issue-201-hook-wiring`)                   |
| `pr_link`            | dispatch-log.md       | populated once the PR is opened                                      |
| `review_status`      | dispatch-log.md       | enum: `pending`, `approved`, `approved-with-changes`, `rejected`     |
| `merge_status`       | dispatch-log.md       | enum: `pending`, `merged`, `aborted`                                 |
| `started_at`         | dispatch-log.md       | ISO 8601 timestamp                                                   |
| `ended_at`           | dispatch-log.md       | ISO 8601 timestamp; nullable until merge or abort                    |

**Invariants**:
- One issue may have N dispatches; only one is `merge_status = merged`.
- Re-dispatch after `review_status = rejected` increments `dispatch_seq`.
- `merge_status = merged` ⟹ Issue.status transitions to `closed`.

## Out-of-scope entities

- ChangelogEntry, ReleaseNote, RcTag — handled by existing template release-engineer machinery, not by this feature.
- TestRun, FailureRecord — covered by existing test harness output; not modelled here.
- AgentContract, RuntimeAgentCandidate — generated artifacts not touched by this plan.
