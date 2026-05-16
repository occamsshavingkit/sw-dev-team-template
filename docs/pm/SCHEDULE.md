# Schedule — sw-dev-team-template improvement program (M0–M9)

PMBOK Planning / Monitoring artifact. Owned by `project-manager`.
Baseline snapshot plus live forecast. Variances recorded, not
overwritten.

Source plan: `sw_dev_template_implementation_plan-2.md` (meta-project
root). Spec directory: `specs/006-template-improvement-program/`.
Working branches in this sub-repo: `feat/m0-baseline` (M0),
`feat/m1-token-quick-wins` (M1, Phase 3 US1).

## Freshness expectation

This file is updated whenever a PR merges that affects milestone status,
scope, or forecasts. Update cadence: **after every merged PR** via
`project-manager` delta-pass dispatch from `tech-lead`. Target
freshness: schedule and roadmap reflect the repository HEAD state within
one session turn, never stale by more than one session turn.

Live forecast dates in this table track actual slip; do not edit baseline
dates once a milestone is baselined. Use `CHANGES.md` to record variance
and `SCHEDULE-EVIDENCE.md` to archive closed milestones and their evidence.

## Milestone list

| ID | Milestone | Baseline date | Forecast date | Status | Exit criterion |
|---|---|---|---|---|---|
| M0 | Establish current-state measurements before changing behavior. | 2026-05-13 | 2026-05-13 | passed | G0 signed 2026-05-13 (`code-reviewer` + `project-manager`); evidence in [SCHEDULE-EVIDENCE.md §M0](./SCHEDULE-EVIDENCE.md#m0--mobilize-and-baseline). |
| M1 | Reduce recurring context cost before adding new cross-AI features. | 2026-05-13 | 2026-05-13 | passed | G1 signed 2026-05-13 (`code-reviewer` re-audit + `project-manager`); evidence in [SCHEDULE-EVIDENCE.md §M1](./SCHEDULE-EVIDENCE.md#m1--token-quick-wins). PRs PR-2a + PR-2 + PR-3 + PR-4 merged. |
| M2 | Token operating model. | 2026-05-13 | 2026-05-13 | passed | G2 signed 2026-05-13 (`code-reviewer` audit + `project-manager`); evidence in [SCHEDULE-EVIDENCE.md §M2](./SCHEDULE-EVIDENCE.md#m2--token-operating-model). PRs PR-3 (token-budget fields + delta-pass) merged. |
| M3 | Atomic-question + intake repair. | 2026-05-13 | 2026-05-13 | passed | G3 signed 2026-05-13 (`code-reviewer` audit + `project-manager`); evidence in [SCHEDULE-EVIDENCE.md §M3](./SCHEDULE-EVIDENCE.md#m3--atomic-question--intake-repair). PRs PR-5 + PR-6 + PR-7 merged. |
| M4 | Documentation authority + drift control. | 2026-05-13 | 2026-05-13 | passed | G4 signed 2026-05-13 (`code-reviewer` audit + `project-manager`); evidence in [SCHEDULE-EVIDENCE.md §M4](./SCHEDULE-EVIDENCE.md#m4--documentation-authority--drift-control). PRs PR-8 + PR-9 merged. |
| M5 | Cross-AI / OpenCode / Gemini routing as adapter. | 2026-05-13 | 2026-05-13 | passed | G5 signed 2026-05-13 (`code-reviewer` audit + `project-manager`); evidence in [SCHEDULE-EVIDENCE.md §M5](./SCHEDULE-EVIDENCE.md#m5--cross-ai--opencode--gemini-routing-as-adapter). PRs PR-10 + PR-11 merged. |
| M6 | Markdown compiler / runtime contract pipeline. | 2026-05-13 | 2026-05-13 | passed | G6 signed 2026-05-13 (`code-reviewer` + `qa-engineer` audit + `project-manager`); evidence in [SCHEDULE-EVIDENCE.md §M6](./SCHEDULE-EVIDENCE.md#m6--markdown-compiler--runtime-contract-pipeline). PRs PR-12 + PR-13 merged. |
| M7 | Self-improvement loop. | 2026-05-13 | 2026-05-13 | passed | G7 signed 2026-05-13 (`code-reviewer` + `release-engineer` + `security-engineer` audit + `project-manager`); evidence in [SCHEDULE-EVIDENCE.md §M7](./SCHEDULE-EVIDENCE.md#m7--self-improvement-loop). PRs PR-14 + PR-15 merged. Security sign-off: PASS-WITH-RESIDUAL-RISK (5 risks R-5..R-9 in docs/pm/RISKS.md). |

## Activities

Activities roll up to milestones. Keep at the size one specialist can
own end-to-end.

| ID | Activity | Owner (teammate) | Predecessors | Duration | Start | Finish | Status |
|---|---|---|---|---|---|---|---|
| A-M0-1 | M0 baseline scaffold + PM artifact opens (this turn — T005/T006/T007/T008) | `project-manager` | — | 1 turn | 2026-05-13 | 2026-05-13 | in-progress |
| A-M1-1 | M1.1 compact runtime contracts (PR-2a) | `architect` + `software-engineer` | M0 gate G0 | TBD | 2026-05-13 | 2026-05-13 | passed |
| A-M1-2 | M1.2 archive-registers.sh (PR-2) | `software-engineer` | M0 gate G0 | TBD | 2026-05-13 | 2026-05-13 | passed |
| A-M1-3 | Token ledger automation (PR-3) | `software-engineer` | A-M0-1 | TBD | 2026-05-13 | 2026-05-13 | passed |
| A-M1-4 | PM live-surface split (PR-4) | `project-manager` | A-M1-2 | TBD | 2026-05-13 | 2026-05-13 | passed |

## Critical path

List the activities on the critical path (longest dependency chain).
Any slip here moves the milestone.

- A-M0-1 → A-M1-1 → A-M1-3 → A-M1-4 (M1.1 compact contracts must land
  before token ledger can measure post-compact deltas; PM split
  consumes the archive script from A-M1-2 in parallel).

## Baseline snapshot

Record the baseline date and the milestone dates at baseline. Do not
edit once baselined — re-baseline with a change log row.

| Baseline | Date set | Milestones at baseline |
|---|---|---|
| B-0 | 2026-05-13 | M0: 2026-05-13; M1: TBD (set at G0 gate close). |

## Variance log

| Date | Milestone | Baseline | Forecast | Variance | Cause | Response |
|---|---|---|---|---|---|---|

## Gates

| Gate | Milestone | Signers | Status |
|---|---|---|---|
| G0 | M0 | `code-reviewer` (audit) + `project-manager` | signed 2026-05-13 |
| G1 | M1 | `code-reviewer` (re-audit) + `project-manager` | signed 2026-05-13 |
| G2 | M2 | `code-reviewer` (audit) + `project-manager` | signed 2026-05-13 |
| G3 | M3 | `code-reviewer` (audit) + `project-manager` | signed 2026-05-13 |
| G4 | M4 | `code-reviewer` (audit) + `project-manager` | signed 2026-05-13 |
| G5 | M5 | `code-reviewer` (audit) + `project-manager` | signed 2026-05-13 |
| G6 | M6 | code-reviewer + qa-engineer (audit) + project-manager | signed 2026-05-13 |
| G7 | M7 | code-reviewer + release-engineer + security-engineer (audit) + project-manager | signed 2026-05-13 |
