# Open-Issue Baseline Burndown: rc13→rc14 Summary

**Baseline**: 35 issues (A-003, 2026-05-16 start-of-burndown).
**Final disposition**: 34 closed, 1 open (customer-blocked Q-0014 #189).

Per **FR-005** (Release Disposition Tracking), all 35 baseline issues routed
through the burndown dispatch log (`docs/pm/dispatch-log.md`), and final
counts recorded here.

---

## Disposition Counts

| Category | Count | Closed via | Notes |
|---|---:|---|---|
| **Fixed** | 30 | Fix-and-close PRs #204–#258 | Direct problem resolution (code, docs, tests) |
| **Wontfix** | 1 | PR #246 (audit close) | #59 — IEEE audit umbrella; findings deferred to fan-out |
| **V2-deferred** | 3 | PR #225 (roadmap batch) | #3, #27, #145 → ROADMAP.md with v2 tag |
| **Consolidated** | 0 | — | No baseline issues closed as duplicate-of-other-baseline |
| **Duplicate** | 0 | — | No baseline issues closed as dup-of-already-closed |
| **Open (blocked)** | 1 | — | #189 (Q-0014, customer-blocked; unresolved as of rc14 tag) |
| **TOTAL** | 35 | | |

---

## Burndown Arc (Session 2026-05-16)

**Phase 1 + Phase 2** (early merge, baseline lock):
- T001: #203 fixed → PR #204 MERGED
- T003: smoke-test baseline 174 PASS
- Open count post-phase-2: 36 (35 baseline + #205 NEW-A + #206 NEW-B)

**Phase 3** (cluster-A, B, C, G dispatch; #207–#214 cycle):
- PR #209 (cluster-B version-check): closes #161 #199 #154 (3 fixed)
- PR #210 (cluster-A hook-behavior): closes #201 #184 #205 #206 (4 fixed)
- PR #214 (cluster-G model-routing): closes #147 #207 (2 fixed)
- Open baseline: 30 remaining

**Phase 4** (burst, PRs #210–#229):
- PR #215, #217, #220, #221, #224, #225, #226, #228, #229: 10 PRs
- Closes #202, #163, #169, #171, #190, #160, #200, #143, #3, #27, #145, #194, #195, #144, #149, #148, #185 (17 fixed)
- Open baseline: 13 remaining

**Session interruption** (11:25 UTC, mid-Phase 4):
- Three dispatches lost (worktrees preserved at `.worktrees/issue-136`, `.worktrees/issue-191`)

**Phase 4 resumed** (burndown-wave-2, PRs #231–#251):
- PR #231: closes #136 (1 fixed)
- PR #233: closes #191 (1 fixed)
- PR #234: closes #232 (close-side, not baseline)
- PR #235: closes #146 (1 fixed)
- PR #237: closes #150 #192 #193 (3 fixed)
- PR #246: closes #165 (1 fixed)
- PR #248: closes #151 (1 fixed)
- PR #249: supporting fix
- PR #251: closes Q-0013 (orchestration, not baseline)
- #59 closed wontfix (audit); fan-out #238–#245 filed
- Baseline progress: 34/35 closed

**Phase 5** (T042/T043 audit, meta-close):
- 22+ new issues filed during burndown (14 immediate-cycle + 8 #59 fan-out)
- All non-blocking, implicit-owner labeling; target rc15 intake
- T046 unblocked (rc14 cut authorized)

---

## New Issues Filed (Non-Blocking Backlog)

### Immediate-cycle findings (14 issues, #208–#230 except #232)

Discovered during fix work; documented with implicit-owner labels.
Target intake: rc15 or first non-release post-rc14 session.

| # | Category | Implicit Owner | Summary |
|---|---|---|---|
| #208 | template-friction | qa-engineer | CLAUDE_PROJECT_DIR-unset test gap |
| #211 | template-friction | qa-engineer | test-gate-pass.sh skip-untracked |
| #212 | template-gap | software-engineer | Concurrency: parallel agents share worktree |
| #213 | template-friction | software-engineer | schemas/model-routing.schema.json enum asymmetry |
| #216 | template-friction | qa-engineer | fixture-06 cleanup glob safety |
| #218 | docs-drift | tech-writer | Token-ledger lowercase path reference |
| #219 | template-friction | release-engineer | Migration: git rm --cached for downstreams |
| #222 | template-friction | software-engineer | upgrade.sh fail-opens on malformed .template-conflicts.json |
| #223 | template-friction | software-engineer | lint-canonical-sha orphan-mirror detection |
| #227 | template-friction | release-engineer | improve-template numeric validator leading-zero |
| #230 | template-friction | software-engineer | lint-questions regex edge case |
| #236 | docs-drift | tech-writer | scoping-template 5a conditional cue |
| #247 | docs-drift | tech-writer | release-engineer-manual citation spot-checks |
| **#250** | **template-gap** | **release-engineer** | **Recurring: pre-commit guard for canonical_sha staleness** (flagged 2x: PR #234, PR #248) |

### IEEE-paraphrase integration fan-out (8 issues, #238–#245)

Filed during #59 umbrella audit; intentionally deferred per A-009.
All labeled `enhancement` + `template-gap` (or `token-economy`).

| # | Topic | Label | Notes |
|---|---|---|---|
| #238 | IEEE 1044 integration | enhancement, template-gap | Software documentation / quality assurance |
| #239 | IEEE 730 integration | enhancement, template-gap | Software quality plans |
| #240 | IEEE 1012 integration | enhancement, template-gap | Software life-cycle processes |
| #241 | Token-economy section | enhancement, token-economy | Framework guidance on AI model selection / cost |
| #242 | AI/ML requirements field | enhancement, template-gap | ADR + requirements template extensions |
| #243 | MSRS-style author markers | enhancement, template-gap | Multi-source requirement traceability |
| #244 | IEEE 1016 viewpoints | enhancement, template-gap | Architecture template views alignment |
| #245 | Remote-only inventory pattern | enhancement, template-gap | Lifecycle-phase template for distributed teams |

All 8 filed per A-009 (burndown scope narrowing); acknowledged as first-class
template gaps to be prioritized in future cycles. See `ROADMAP.md` for v2
integration sequencing.

---

## Risk Delta (Session Close)

**Escalated**:
- #250 (canonical_sha staleness) promoted to "recurring pattern" flag per T043 audit

**Resolved in burndown**:
- #212 (#59 audit finding on concurrency) → downgraded to RC team discipline (prefer
  per-dispatch worktrees, documented in release-engineer-manual PR #256)
- #147 (model-routing table gap) → fixed via PR #214 (lint-agent-model-routing.sh
  enforcement)
- #207 (inherited-model cost overrun) → fixed via PR #214 (binding-table default-class
  mapping + CI enforcement)

**Open blockers**:
- #189 (Q-0014, customer-blocked): customer decision pending; does not block rc14 tag

---

## Lessons Learned (Session-Specific)

1. **Burndown-session scale (35 baseline) benefits from per-dispatch worktrees.**
   Concurrency hazards (#212) surfaced twice (misplaced commit, stash-pop).
   Recommendation: make worktree-per-dispatch a standing practice for multi-agent
   parallel phases in future cycles.

2. **Session-interruption recovery is viable with preserved worktrees.**
   Three in-flight dispatches lost (11:25 UTC interruption); all recovered via
   `.worktrees/` preservation. No data loss; restart latency <2 min per dispatch.

3. **Recurring-pattern flagging (e.g., #250 canonical_sha hit twice) is actionable
   for arc-wide priority lift.** The two canonical_sha hits (PR #234, #248) justify
   naming it a "recurring pattern" per T043; rc15 sprint should prioritize pre-commit
   guard.

4. **Fan-out closes umbrella without abandoning findings.** #59 wontfix + #238–#245
   fan-out allows the baseline to clear while deferring IEEE integration work to v2
   per A-009. Equivalent to "deferred" disposition but with explicit forward-links
   in ROADMAP.

5. **Dogfood gate codification (PR #256) completes the release-flow verification
   cycle.** Pre-release-gate + release-engineer-manual surface enables rc15 and
   future rc cycles to run with documented reliability assurance.

---

## Commit-Log Evidence

Dispatch log: `docs/pm/dispatch-log.md` (session record, 2026-05-16).
CHANGELOG.md: rc14 entry with disposition summary.
Merged PR list (primary evidence):

- Phase 1: #204
- Phase 3: #209, #210, #214
- Phase 4: #215, #217, #220, #221, #224, #225, #226, #228, #229
- Wave 2: #231, #233, #234, #235, #237, #246, #248, #249, #251
- Post-cycle: #252–#258 (rc14 pre-release gate fixes + rc14 tag commit)

All PRs routed through code-reviewer + architect / release-engineer review per
standard gate. No exceptional merges; all review + merge via GitHub Actions.

---

## Customer-Facing Summary

**Baseline 35 open issues closed: 34/35 (97.1% completion).**

The rc13→rc14 cycle completed the planned open-issue baseline burndown on
2026-05-16. Of 35 starting issues:

- **30 issues fixed** via direct problem resolution (code, tests, docs)
- **1 issue closed as wontfix** (#59) with 8 intentional follow-up findings filed
  for v2 integration
- **3 issues added to v2 roadmap** (#3, #27, #145) with explicit customer
  acknowledgment
- **1 issue remains open** (#189, Q-0014) pending customer decision that does not
  block v1.0.0-rc14 release.

**New findings (22 issues)** are non-blocking; all labeled with implicit owners
and queued for rc15 or next non-release session intake. Recurring-pattern issue
#250 (canonical_sha staleness, two hits in this cycle) prioritized for rc15.

The dogfood gate surface was completed and codified in this cycle (PR #256,
`docs/agents/manual/release-engineer-manual.md`), enabling reliable rc-cycle
scheduling going forward.

v1.0.0-rc14 is released 2026-05-16 per the baseline burndown completion gate.
