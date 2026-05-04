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
| C-8 | 2026-05-04 | `project-manager` | Record rc6 final-readiness evidence update: #79 and #84-#105 are closed/downgraded, staged-candidate smoke passed 134/134, and code-reviewer approved the final staged diff. | Quality / release governance | No scope or schedule change; updates the baselined final-readiness evidence and keeps downstream sample / customer ratification / GitHub Release work pending. | `project-manager` within PM artifact scope | Approved | 2026-05-04 | Supports `docs/v1.0.0-final-checklist.md` gates G-2, G-3, G-5, and G-10; rc6 commit `dc2df300d77145ef4d2fe5d30033570bc64127a1` / tag `v1.0.0-rc6` is the historical evidence point; current rc7 readiness remains blocked by pending gates, including G-11 parity evidence. |
| C-9 | 2026-05-04 | `project-manager` | Record G-9 rollback / upgrade-note completion after the release notes landed. | Quality / release governance | No scope or schedule change; records prior G-9 release-note evidence and anchors the old checklist state to the published release notes. | `project-manager` within PM artifact scope | Approved | 2026-05-04 | Records the old G-9 release-note evidence in `docs/v1.0.0-final-checklist.md` with `docs/v1.0.0-release-notes.md`; current rc7 readiness remains blocked by pending gates, including G-11 parity evidence. |
| C-10 | 2026-05-04 | `project-manager` | Add final Claude Code / Codex parity evidence gate for `v1.0.0` release governance. | Quality / release governance | Tightens final readiness: one-AI evidence cannot release final while the template claims Claude Code / Codex parity. | Customer task authorization | Approved | 2026-05-04 | Supports `docs/v1.0.0-final-checklist.md` G-11; final evidence must include both Claude Code and Codex validation where harness capabilities overlap, with exception only for unavailable harness capability plus customer-approved residual risk. |
| C-11 | 2026-05-04 | `release-engineer` | Prepare in-tree `v1.0.0-rc7` candidate files for issue #116 concise specialist briefs and the no-full-context-fork rule. | Scope / schedule / quality | Moves rc7 from draft planning to candidate tag-prep without creating a tag or claiming final readiness; Claude Code validation evidence remains pending. | Customer task authorization | Approved | 2026-05-04 | Updates `VERSION`, `CHANGELOG.md`, `README.md`, `ROADMAP.md`, and `docs/v1.0.0-final-checklist.md`; no `v1.0.0-rc7` tag exists yet. |
| C-12 | 2026-05-04 | `release-engineer` | Record rc7 branch evidence, fix `scripts/stepwise-smoke.sh` so release-prep branches can run stepwise validation before merge/tag, tighten Codex dispatch gates for issues #95 and #114, and clear residual closed-issue gaps for #16/#77. | Quality / release governance | Improves rc7 evidence quality and closes adapter/customer-notes contract gaps; does not tag rc7 or change final-ready state. | Customer task authorization | Approved | 2026-05-04 | `scripts/smoke-test.sh` passed 136/136; `scripts/stepwise-smoke.sh --track rc` passed 3/3 published rc hops; `scripts/stepwise-smoke.sh` passed 4/4 stable hops. G-3 is green; G-4 remains pending downstream-clean and cross-harness evidence. Issue #106 is closed as a documented historical limitation because rc4 dry-run helper writes are in immutable historical code; the release notes document the restore/rerun workaround. |

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
- C-8: `docs/v1.0.0-final-checklist.md`; `docs/pm/LESSONS.md`.
- C-9: `docs/v1.0.0-final-checklist.md`; `docs/v1.0.0-release-notes.md`;
  `docs/pm/LESSONS.md`.
- C-10: `docs/v1.0.0-final-checklist.md`.
- C-11: `VERSION`; `CHANGELOG.md`; `README.md`; `ROADMAP.md`;
  `AGENTS.md`; `.claude/agents/tech-lead.md`;
  `docs/v1.0.0-final-checklist.md`.
- C-12: `AGENTS.md`; `.claude/agents/tech-lead.md`;
  `docs/agent-health-contract.md`; `CUSTOMER_NOTES.md`;
  `scripts/scaffold.sh`;
  `scripts/lib/first-actions.sh`; `scripts/smoke-test.sh`;
  `scripts/stepwise-smoke.sh`; `CHANGELOG.md`;
  `docs/v1.0.0-final-checklist.md`; `docs/v1.0.0-release-notes.md`.
