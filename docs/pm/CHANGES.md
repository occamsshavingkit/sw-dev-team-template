# Change Log — sw-dev-team-template

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
| Schedule | slip greater than 2 days on a release-candidate or final milestone | customer (via `tech-lead`) |
| Cost | material increase in agent / human effort that changes a release commitment | customer (via `tech-lead`) |
| Quality | any loosening of acceptance criteria or release gate | customer (via `tech-lead`) |
| Safety-critical | any change touching safety-critical path | customer live approval (no cached approval) |

## Change log

| ID | Date | Submitted by | Description | Dimension | Impact (scope / schedule / cost / quality) | Approver | Decision (approved / rejected / deferred) | Decision date | Notes |
|---|---|---|---|---|---|---|---|---|---|
| C-1 | 2026-05-03 | `tech-lead` / downstream field feedback | Add mandatory `v1.0.0-rc4` stabilization release candidate for issues #71-#83 instead of promoting `v1.0.0-rc3` directly to final. | Scope / schedule / quality | Adds one release-candidate stabilization step; improves final quality gate coverage. | Customer via `tech-lead` field triage | Approved in plan | 2026-05-03 | Recorded in `ROADMAP.md` and `docs/v1.0-rc4-stabilization.md`. |
| C-2 | 2026-05-03 | `project-manager` | Add objective `v1.0.0` final readiness gates and normalize rc4 state vocabulary as `review-complete / not tagged / not final-ready`. | Quality / release governance | Adds explicit final gates before GA; no code scope change. | `project-manager` within PM artifact scope | Approved | 2026-05-03 | Recorded in `docs/v1.0.0-final-checklist.md`, `ROADMAP.md`, and rc4 plan / review records. |
| C-3 | 2026-05-03 | `architect` / `project-manager` for issue #99 | Add explicit downstream framework / project boundary guidance and require product reviews / commits to split framework churn from product work. | Scope / quality / process | Adds a framework guidance document plus indexed Codex / Claude visibility; no product code impact. | Customer task authorization | Approved | 2026-05-03 | Recorded in `docs/framework-project-boundary.md`, `CLAUDE.md`, `AGENTS.md`, and task / handover templates. |
| C-4 | 2026-05-03 | `release-engineer` / `code-reviewer` for issue #102 | Require downstream release audits to classify release/version artifact ownership before writing and to route framework release gaps upstream. | Scope / quality / process | Tightens product-only release audit gates; no product code impact. | Customer task authorization | Approved | 2026-05-03 | Extends issue #99 boundary model for release/version files. |
| C-5 | 2026-05-03 | `architect` / Codex adapter for issue #103 | Add Codex specialist completion/status recovery guidance for timed-out waits, empty status, and divergent completion channels. | Quality / process | Prevents silent or unreachable specialists from being mistaken for completed work or from collapsing specialist tasks into local `tech-lead` implementation. | Customer task authorization | Approved | 2026-05-03 | Recorded in `AGENTS.md`, `.claude/agents/tech-lead.md`, and `docs/agent-health-contract.md`. |
| C-6 | 2026-05-03 | `release-engineer` | Add mandatory `v1.0.0-rc5` release-boundary candidate for issues #84-#103 instead of promoting rc4 directly to final. | Scope / schedule / quality | Adds one release-candidate validation step; aligns final readiness with post-rc4 downstream evidence. | Customer task authorization | Approved | 2026-05-03 | Recorded in `CHANGELOG.md`, `ROADMAP.md`, `docs/v1.0-rc4-stabilization.md`, `docs/v1.0.0-final-checklist.md`, and `docs/versioning.md`. |
| C-7 | 2026-05-04 | `release-engineer` | Add mandatory `v1.0.0-rc6` release-governance candidate for issues #84, #104, and #105 instead of promoting rc5 directly to final. | Scope / schedule / quality | Adds one focused rc step so dispatch-policy binding, manifest post-copy verification, and the immutable rc3 workaround boundary are captured before GA. | Customer task authorization | Approved | 2026-05-04 | Final remains blocked until rc6 validation and all checklist gates pass. |

## Cross-references

Link each approved change to the downstream artifact it modified:
`CHARTER.md` section, `SCHEDULE.md` milestone, `COST.md` baseline,
requirements doc section, architecture ADR, etc.

- C-1: `ROADMAP.md` § v1.0.0-rc4; `docs/v1.0-rc4-stabilization.md`.
- C-2: `docs/v1.0.0-final-checklist.md`; `docs/audits/v1.0.0-rc4-review.md`.
- C-3: `docs/framework-project-boundary.md`; `docs/ISSUE_FILING.md`;
  `docs/templates/task-template.md`; `docs/templates/handover-template.md`.
- C-4: `docs/framework-project-boundary.md`;
  `.claude/agents/release-engineer.md`; `CLAUDE.md`; `AGENTS.md`;
  `.claude/agents/tech-lead.md`; `docs/ISSUE_FILING.md`;
  `docs/templates/task-template.md`; `docs/templates/handover-template.md`.
- C-5: `AGENTS.md`; `.claude/agents/tech-lead.md`;
  `docs/agent-health-contract.md`.
- C-6: `VERSION`; `CHANGELOG.md`; `ROADMAP.md`;
  `docs/v1.0-rc4-stabilization.md`;
  `docs/v1.0.0-final-checklist.md`; `docs/versioning.md`.
- C-7: `VERSION`; `CHANGELOG.md`; `ROADMAP.md`;
  `AGENTS.md`; `.claude/agents/tech-lead.md`; `scripts/lib/manifest.sh`;
  `scripts/smoke-test.sh`; `docs/v1.0.0-final-checklist.md`;
  `docs/pm/LESSONS.md`; `docs/versioning.md`.
