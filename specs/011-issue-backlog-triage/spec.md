# Feature Specification: Open-Issue Backlog Triage and Burndown

**Feature Branch**: `011-issue-backlog-triage`
**Created**: 2026-05-16
**Status**: Complete (2026-05-16 — 35/35 baseline closed, v1.0.0-rc14 tagged b421a60 at commit 1090ae1)
**Input**: User description: "Address all 35 outstanding GitHub issues in occamsshavingkit/sw-dev-team-template and close them after fixing or determining they are not relevant. Triage all open issues into buckets (release-gate blockers, upgrade-flow cluster, hook-behavior cluster, framework-gaps, framework-friction, docs-drift, v2-proposals, others). For each bucket, define entry/exit criteria, dependency ordering, and disposition options (fix-and-close, wontfix-and-close, defer-to-v2, consolidate-with-other-issue). The #203 branch-guard fix is already in flight on branch fix/issue-203-upgrade-branch-guard via dispatched software-engineer; treat it as in-progress, not pending-triage. Each remaining issue gets a disposition decision and, where the disposition is fix, a brief specification of the fix shape so software-engineer / code-reviewer / qa-engineer can be dispatched with full context. Closure criterion for the meta-effort: every issue currently open as of 2026-05-16 reaches a terminal state (closed-as-fixed, closed-as-wontfix, closed-as-duplicate, closed-as-v2-deferred, or merged-into-other-open-issue)."


## Clarifications

### Session 2026-05-16

- Q: How should rc tags be bumped during the 14-18 PR burndown — per-PR, per-bucket, per-session, or held until v1.0.0 final? → A: One rc tag bump at plan completion. All burndown PRs merge against the in-progress rc13 working tree; rc14 is cut once when the burndown plan reaches terminal state. v1.0.0 final follows later as a separate decision.
- Q: Where should `defer-to-v2` close-comment links point — new ROADMAP-V2.md, GitHub milestone, both, label-only, or appended section in existing ROADMAP.md? → A: Append `## V2 deferred` section to the existing `sw-dev-team-template/ROADMAP.md`. Anchor link `ROADMAP.md#v2-deferred` becomes the canonical surface.
- Q: How should umbrella issue #59 (v0.10.0 v1.0.0-RC backlog enumeration) be dispositioned given many children may already be resolved across rc11–rc13? → A: Audit children against current rc13 state; close #59 with a summary close-comment listing per-child status (citing merged PRs for done items); file NEW issues only for still-relevant items. New issues do NOT count toward the 35 baseline (per A-003) and ride FR-010's new-findings disposition path.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Release-gate readiness (Priority: P1)

The framework cannot credibly tag v1.0.0 final until the upgrade-flow and hook-behavior issue clusters close. Memory records "Upgrade-flow reliability is the v1.0.0 blocker," and the QuackDCS downstream incident (rc8 → rc13 on a non-default branch, multi-hour cleanup) is concrete evidence the cluster is actively bleeding session-hours. This story burns down every release-gate-blocking issue so a v1.0.0 release-prep audit has a clean open-issue list.

**Why this priority**: a single P1 issue left open in either cluster can re-trigger the QuackDCS class of incident on the next downstream upgrade. The cluster cost a real customer one full session to recover from; future cost compounds across downstreams.

**Independent Test**: run the template repo's full test suite (smoke-test, hook-test, upgrade-test), then perform an end-to-end rc8 → latest upgrade against a fixture downstream and confirm no divergence, all hooks active, version-check accurate, post-upgrade smoke-test green. Any single fix in this cluster ships on its own and removes one regression vector.

**Acceptance Scenarios**:

1. **Given** the release-gate upgrade-flow cluster (issues #154, #161, #163, #169, #171, #190, #191, #199, #200, #203) and the hook-behavior cluster (issues #184, #188, #201, #202, plus any new hook-behavior findings filed during this effort up to meta-close), **When** each baseline issue is dispositioned (fix-and-close, wontfix-and-close, or consolidate-with-other-issue) AND every new hook-behavior finding filed during the effort has been bucketed and dispositioned per FR-010, **Then** zero items in those buckets remain open on `occamsshavingkit/sw-dev-team-template`.
2. **Given** a fixture downstream at v1.0.0-rc8, **When** `scripts/upgrade.sh` is invoked on the default branch with no flags, **Then** it completes without TEMPLATE_VERSION/manifest divergence, settings.json receives the new PreToolUse + SessionStart hook wires, version-check reports the correct latest, and the post-upgrade smoke-test passes.
3. **Given** the same fixture, **When** `scripts/upgrade.sh` is invoked on a non-default branch with no override, **Then** it refuses with exit 2 and the documented branch-guard message (issue #203 acceptance criterion).

---

### User Story 2 - Framework-gap and friction closeout (Priority: P2)

Every rc9-era framework-gap and framework-friction issue gets an explicit disposition: either close-as-fixed (with merged PR) or close-with-rationale. The volume (≈15 issues, several over six release-candidates old) creates a noisy open-issue list that obscures real new regressions.

**Why this priority**: these don't block v1.0.0 individually but the noise compounds. Closing them clarifies signal for ongoing triage and removes the "we have N+15 open issues, all important" stale-context tax on every release audit.

**Independent Test**: `gh issue list --state open --label template-gap,template-friction,framework-friction,framework-gap` shows zero items, OR every remaining item carries a `v2-deferred` or `wontfix` label plus a close-comment rationale.

**Acceptance Scenarios**:

1. **Given** issues #143, #144, #145, #146, #147, #148, #149, #151, #160, #165, #185, #189, #190, #191, #194, #195, **When** each is dispositioned, **Then** each closes with a final comment naming the disposition and (for fix-and-close) the merged PR.
2. **Given** an issue whose original report has been superseded by a later rc-cycle change (rc9-era issue moot under rc13 code), **When** the disposition is `wontfix`, **Then** the close comment cites the superseding commit, ADR, or issue.

---

### User Story 3 - V2 deferral, docs-drift, and `other`-bucket cleanup (Priority: P3)

V2-proposal issues (#3, #27, #59) close with an explicit deferral comment and `v2-deferred` label, linking to a v2 tracking surface. Docs-drift issues (#150, #192, #193) close with cheap doc patches that don't require code review beyond a single docs-writer pass. The `other` bucket (#136, project-manager-cadence) closes alongside as P3 cleanup so the meta-effort drains the entire baseline rather than leaving an `other`-bucket residual.

**Why this priority**: v2-proposals belong on a roadmap, not the open-issue list. Docs-drift items are typically minutes-of-work and clear up quickly. Both clusters can close without a long review cycle.

**Independent Test**: after this slice, the only items remaining in the issue tracker should be net-new findings filed during this burndown effort. The 2026-05-16 baseline of 35 is at zero.

**Acceptance Scenarios**:

1. **Given** a v2-proposal issue, **When** the disposition lands, **Then** the issue closes with a `v2-deferred` label and a comment linking to the v2 roadmap surface.
2. **Given** a docs-drift issue, **When** the docs patch lands and the PR merges, **Then** the issue closes and the merged PR is cross-referenced in the close comment.

---

### User Story 4 - New-finding intake during burndown (Priority: P2)

Every new bug or gap surfaced during burndown (e.g., the two hook false-positive behaviors already observed in this session — outside-project-tree denials and `/dev/null` redirect denials) is filed, bucketed, and dispositioned before the meta-effort closes. Without this rule, burndown becomes Whack-a-Mole and the post-effort open-issue list grows even as the baseline closes.

**Why this priority**: P2 (not P1) because new findings typically ride with the cluster they belong to and inherit that cluster's priority. The rule itself is P2 — it prevents recursion explosion without forcing every new finding to be a P1.

**Independent Test**: at meta-close, `gh issue list --state open --search "created:>=2026-05-16"` either returns zero, or each remaining item is explicitly recorded in a next-cycle backlog with a named owner and target window.

**Acceptance Scenarios**:

1. **Given** the two hook false-positive findings surfaced in this session (outside-CLAUDE_PROJECT_DIR denial; `/dev/*` redirect denial), **When** filed and bucketed into the hook-behavior cluster, **Then** each is dispositioned alongside #201/#202 in the P1 burndown.

---

### Edge Cases

- **Issue with no clear owner under OWNERSHIP_RULES fallback**: route to architect for a structural read first, then re-route to the implementer specialist.
- **Issue that requires a fresh customer ruling**: queue via the Customer Question Gate in `docs/OPEN_QUESTIONS.md`; do not block other dispositions on the customer's response.
- **Issue rendered obsolete during burndown** (example: #163 v0.16.0 conflict on upgrade.sh becomes moot if #203 rewrites the surface): close as `obsolete-by-PR#NNN` with a cross-link to the superseding PR.
- **In-flight #203 fails code-review**: re-dispatch; do not unblock dependent upgrade-flow issues until #203 ships.
- **Multi-issue PR**: a single PR may close several related issues (e.g., the hook-behavior cluster could ride one PR with three fixes). The PR body lists every closed issue.
- **Issue is a duplicate of one already closed**: close as `duplicate-of-#NNN` with a cross-link and no further work.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST publish a triage table at `specs/011-issue-backlog-triage/triage.md` listing every open issue at session-start (number, title, bucket, disposition, owning role, blocking-set, current status).
- **FR-002**: System MUST disposition each of the 35 baseline issues (open at 2026-05-16) into one of: `fix-and-close`, `wontfix-and-close`, `defer-to-v2`, `consolidate-with-other-issue` (when the surviving issue is also open in the baseline or filed during the effort), `close-as-duplicate` (when the canonical issue is already closed and the baseline issue is a re-report).
- **FR-003**: System MUST process buckets in priority order: (1) `release-gate-upgrade-flow` (P1), (2) `hook-behavior` (P1), (3) `framework-gap` (P2), (4) `framework-friction` (P2), (5) `docs-drift` (P3), (6) `v2-proposal` (P3), (7) `other` (P3, cleanup last). Buckets 1–2 are the release-gate cluster and close before any bucket 3+ work begins.
- **FR-004**: Each `fix-and-close` disposition MUST result in a merged PR cross-referenced in the issue's close comment.
- **FR-005**: Each `wontfix-and-close` disposition MUST include a close comment naming the rationale (superseding change, out-of-scope rationale, or irrelevance under a newer rc cycle).
- **FR-006**: Each `defer-to-v2` disposition MUST link to the anchor `ROADMAP.md#v2-deferred` in the template repo's existing `ROADMAP.md` (appended section) and apply a `v2-deferred` label. The `## V2 deferred` section is created on first use of this disposition and lists every deferred issue with its title and a one-line rationale.
- **FR-007**: Each `consolidate-with-other-issue` disposition MUST add a cross-link comment on the surviving issue and close the consolidated one as duplicate.
- **FR-008**: Dispatcher MUST route fix work to the owning specialist per the existing FW-ADR-0012 OWNERSHIP_RULES table.
- **FR-009**: Dispatch progress MUST be recorded in `sw-dev-team-template/docs/pm/dispatch-log.md` per the existing convention. This is the authoritative location. A meta-project mirror at `docs/pm/dispatch-log.md` is permitted but advisory; the template-subrepo file is canonical.
- **FR-010**: New issues filed during burndown (including children spawned from auditing umbrella issue #59) MUST be bucketed and dispositioned before meta-close. SC-001's baseline locks at the 35 issues open at 2026-05-16 session-start; new issues are tracked separately and do not retroactively grow the baseline.
- **FR-011**: A final meta-summary commit MUST update the template repo's CHANGELOG and the meta-project's release-prep document with the closure count and any explicit deferrals.

- **FR-012**: System MUST advance the template's rc tag exactly once during this effort — `v1.0.0-rc14` cut when the burndown plan reaches terminal state (all 35 baseline issues closed). All intermediate PRs merge against the in-progress rc13 working tree; no per-bucket or per-PR rc bumps. The v1.0.0 final tag is a downstream decision not bound by this spec.
### Constitution Alignment *(mandatory)*

- **CA-001**: The triage table is generated from a point-in-time snapshot of `gh issue list` taken 2026-05-16; the spec is canonical; PRs are canonical work products; issue close comments are operational records.
- **CA-002**: Customer authorization for this effort recorded in this conversation (2026-05-16). Triage dispositions that require fresh customer rulings (e.g., scope of a `wontfix`) are queued via the atomic-question gate.
- **CA-003**: This is explicitly authorized template-maintenance work. Edits under `sw-dev-team-template/**` are framework work and proceed under the standing customer authorization for this effort; meta-project edits stay scoped to `specs/011-*` and `docs/pm/dispatch-log.md`.
- **CA-004**: Role authority is preserved: project-manager owns the triage table and dispatch log; software-engineer / qa-engineer / tech-writer / architect own fixes per OWNERSHIP_RULES; code-reviewer reviews each PR; tech-lead orchestrates and lands PRs.

### Key Entities *(include if feature involves data)*

- **Issue**: a GitHub issue at `occamsshavingkit/sw-dev-team-template`. Attributes: number, title, labels, bucket, disposition, owning role, blocking-set (other issues whose closure is a prerequisite), status (`pending-triage`, `dispatched`, `in-review`, `ready-to-close`, `closed`).
- **Bucket**: one of `release-gate-upgrade-flow`, `hook-behavior`, `framework-gap`, `framework-friction`, `docs-drift`, `v2-proposal`, `other`.
- **Disposition**: one of `fix-and-close`, `wontfix-and-close`, `defer-to-v2`, `consolidate-with-other-issue`, `close-as-duplicate`.
- **Dispatch**: an assignment of an issue to an owning specialist with brief, branch, PR link, review status, merge status.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of the 35 issues open at 2026-05-16 reach a terminal state (closed for any of the five allowed reasons).
- **SC-002**: Every release-gate cluster issue (release-gate-upgrade-flow + hook-behavior) closes before any v2-proposal closes — priority ordering is observable in the close-date timeline.
- **SC-003**: Every `fix-and-close` issue has a merged PR cross-referenced in its close comment; every `wontfix-and-close` and `defer-to-v2` issue has a rationale comment of at least one sentence.
- **SC-004**: Zero regressions in any test suite that was passing at session-start, measured by running the full template test suite plus the fixture-downstream upgrade-test after each merged PR.
- **SC-005**: 100% of issues filed during the burndown effort are themselves dispositioned by meta-close — closed or rolled into a documented next-cycle backlog with a named owner.
- **SC-006**: A single final meta-summary commit records the counts (fixed, wontfix, v2-deferred, consolidated, duplicate) and lands one-line CHANGELOG entries on both the template repo and the meta-project release-prep doc. The rc-tag history at meta-close shows exactly one new tag — `v1.0.0-rc14` — cut at burndown completion per FR-012.
- **SC-007**: The fixture downstream upgrade-test passes the combined post-fix state of #203 + #201 + #199 + #200 + #154/#161 — i.e., a downstream at v1.0.0-rc8 upgrades to v1.0.0-rc14 (the tag cut at burndown completion per FR-012) cleanly with no divergence, no missing hook wires, no version-check confusion. v1.0.0-final is out of scope for this spec.

## Assumptions

- **A-001**: Multiple sessions over an unspecified calendar window. No hard deadline; the v1.0.0 release-gate is the natural close.
- **A-002**: Consolidation counts as a terminal state for SC-001 — merging issue A into open issue B closes A as duplicate without violating the SC.
- **A-003**: New issues filed during the effort are tracked, but the SC-001 baseline locks at the 35 numbered today.
- **A-004**: V2-proposals close without code review (label + comment is sufficient); fix-and-close issues require code-reviewer per Hard Rule #3.
- **A-005**: The dispatch-log + memory layer are the working state. No external tracker is introduced.
- **A-006**: `gh` CLI is authenticated and the user's GitHub credentials are present (verified in this session).
- **A-007**: The in-flight #203 fix is the reference template for fix-and-close shape: branch → software-engineer → code-reviewer → PR → merge → close. Other fix issues follow the same flow.
- **A-008**: The two hook false-positive findings already observed in this session (outside-CLAUDE_PROJECT_DIR denial, `/dev/*` redirect denial) will be filed as part of this effort and ride the hook-behavior cluster.
- **A-009**: Umbrella issue #59 will be audited child-by-child against the current rc13 state. The umbrella closes with a single summary comment; per-child status (already-done vs still-relevant) is recorded in that comment. Children that remain relevant become new issues outside the 35-baseline.
- **A-010**: A third new finding surfaced 2026-05-16 — issue #207 (`agent contracts ship with model: inherit — binding default-class table is unenforced`). Bucket: framework-gap. Rides PR-G (new cluster) with #147 (model-routing-guidelines table merge) since #147's table is the canonical source #207's Part-A and Part-B work need to read.
