# Dispatch Log

Authoritative location per FR-009 / `specs/011-issue-backlog-triage/spec.md`. Records every issue-burndown dispatch from session-start (2026-05-16) through meta-close. One row per dispatch; re-dispatches increment `seq`.

## Columns

`issue` `seq` `role` `branch` `started` `pr` `review_status` `merge_status` `ended`

---

## 2026-05-16 session

| Issue | Seq | Role               | Branch                                | Started (UTC) | PR  | Review | Merge | Ended (UTC) |
|-------|----:|--------------------|---------------------------------------|---------------|----:|--------|-------|-------------|
| #203  | 1   | software-engineer  | `fix/issue-203-upgrade-branch-guard`  | 2026-05-16 ~06:00 | 204 | APPROVED | MERGED | 2026-05-16 07:48 |

## Smoke-test baseline (2026-05-16, post-#204)

(filled in by T003)



## 2026-05-16 — Phase 1 + Phase 2 + T013 complete

| Task | Outcome |
|------|---------|
| T001 | PR #204 MERGED 07:48:06Z; #203 CLOSED 07:48:07Z; open count 35→34 |
| T002 | dispatch-log.md scaffolded (this file) |
| T003 | smoke-test baseline 174 PASS / 0 FAIL (elapsed 145s) |
| T004 | NEW-A filed as #205 (outside-CLAUDE_PROJECT_DIR denial) |
| T005 | NEW-B filed as #206 (`/dev/null` redirect denial; meta-ironic guard trip on the issue body itself) |
| T013 | #163 (v0.x conflict-detection) re-evaluated — independent of #203; still relevant; folds into PR-C scope |

Open issue count post-Phase-2: 36 (34 baseline + 2 new findings = #205 + #206). Baseline locked at 35 per A-003; #205 + #206 ride the hook-behavior cluster per A-008 / FR-010.

## Phase 3 dispatch start

PR-A: hook-behavior cluster (#201 + #184 + #205 + #206). software-engineer dispatched 2026-05-16.
PR-B: version-check cluster (#161 + #199 + #154). software-engineer dispatched 2026-05-16.


## 2026-05-16 — NEW-C / #207 filed mid-Phase-3

Customer-triggered review during Phase 3 fan-out: "is software-engineer using the most appropriate AI model?" Audit found all 14 agent contracts × 2 trees ship with `model: inherit`. PR #204 SE (91k tokens) and CR (49k tokens) both burned 2-3× expected cost on inherited Opus. Filed as **#207** (framework-gap). Folds with #147 into **PR-G** (3-part: Part C = table merge, Part A = contract updates, Part B = CI lint).

In-flight PR-A + PR-B continue on inherited Opus (work already in progress; not killing). All future Agent dispatches in this session pass explicit `model: sonnet` (or `haiku` for project-manager) per the binding-table mapping. Cross-provider note: opencode reaches Gemini + OpenAI; the binding default-class table stays multi-provider authoritative (not collapsed to Claude only).

Open count now: 37 (35 baseline + #205 + #206 + #207).

## 2026-05-16 — PR-B complete

| Issue | Seq | Role               | Branch                                | Started (UTC) | PR  | Review | Merge | Ended (UTC) |
|-------|----:|--------------------|---------------------------------------|---------------|----:|--------|-------|-------------|
| #161  | 1   | software-engineer  | `fix/cluster-B-version-check`         | 2026-05-16 08:30 | — | pending | pending | 2026-05-16 08:41 |
| #199  | 1   | software-engineer  | `fix/cluster-B-version-check`         | 2026-05-16 08:30 | — | pending | pending | 2026-05-16 08:41 |
| #154  | 1   | software-engineer  | `fix/cluster-B-version-check`         | 2026-05-16 08:30 | — | pending | pending | 2026-05-16 08:41 |

Branch @ `14f6aff5`. 24 new tests + 174 smoke regression all green. Awaiting code-reviewer dispatch.


## 2026-05-16 — PR-B MERGED + PR-A CR + PR-G Part C

| Event | Result |
|-------|--------|
| PR #209 (cluster-B / version-check) | MERGED → closes #161 #199 #154 |
| CR-PR-A verdict | APPROVED-WITH-CHANGES: 1 blocking (dead-code `_is_harness_path` second call), 3 non-blocking |
| SE-PR-A respin | dispatched on sonnet to apply blocking + ADR-language non-blocking |
| PR-G Part C (model-routing table merge) | committed via tool-bridge on `fix/cluster-G-model-routing` @ `db82d54` (#147 resolution) |
| NEW-D | filed as #208 (CLAUDE_PROJECT_DIR-unset test gap) |
| Concurrency hazard | hit twice (misplaced commit, stash-pop conflict). Worktrees recommended for future parallel dispatches. |

Open count: 35 (baseline 35 – #203 – #161 – #199 – #154 + #205 + #206 + #207 + #208 = 35). Baseline progress: 4/35 closed (#203 #161 #199 #154).

## 2026-05-16 — PR-G MERGED (model-routing rubric + enforcement)

PR #214 (cluster-G, 5 commits) merged. Closes #147 (table merge) + #207 (model: inherit gap; rubric now enforced via `scripts/lint-agent-model-routing.sh` + new GitHub Actions step).

| Issue | Disposition |
|-------|------|
| #147 | fix-and-close via PR #214 Part C |
| #207 | fix-and-close via PR #214 Parts A+B (lint enforcement) + B-respin (CR blocking fix) |

New issues filed mid-PR-G:
- #208 — CLAUDE_PROJECT_DIR-unset test gap (framework-friction)
- #211 — test-gate-pass.sh skip-untracked flag (framework-friction)
- #212 — concurrency hazard / worktree-per-dispatch (framework-gap)
- #213 — schema asymmetry on equivalent enums (framework-friction)

Baseline progress: 7/35 closed (#154 #161 #184 #199 #201 #203 #147). Open: 32.

## 2026-05-16 — Phase 3 next wave dispatched

| Branch | Role | Model | Worktree | Scope |
|--------|------|-------|----------|-------|
| `fix/cluster-C-upgrade-sh-followups` | software-engineer | sonnet | `.worktrees/pr-c` | #169 #190 #171 #163 — upgrade.sh post-PR-A follow-ups |
| `fix/issue-188-fixture-06-pid-scope` | qa-engineer | sonnet | `.worktrees/issue-188` | #188 — PID-scope stub migration filename + tag |
| (read-only) | architect | sonnet | n/a | #202 — canonical-scope guard inversion; architect produces a brief disposition note |

## 2026-05-16 — Phase 3 close + Phase 4 burst (PRs #210–#229)

| PR  | Closes        | Branch                                      | Role               | Merged (UTC) |
|----:|---------------|---------------------------------------------|--------------------|--------------|
| #210| #201 #184 #205 #206 | fix/cluster-A-hook-behavior            | software-engineer  | 2026-05-16 09:26 |
| #214| #147 #207     | fix/cluster-G-model-routing                 | release-engineer   | 2026-05-16 09:58 |
| #215| #202 + V2 sec | docs/issue-202-roadmap-v2-deferred          | tech-writer        | 2026-05-16 10:04 |
| #217| #163 #169 #171 #190 | fix/cluster-C-upgrade-sh-followups    | software-engineer  | 2026-05-16 10:18 |
| #220| #160          | fix/issue-160-token-ledger-clutter          | software-engineer  | 2026-05-16 10:32 |
| #221| #200          | fix/issue-200-rerun-safety                  | software-engineer  | 2026-05-16 10:35 |
| #224| #143          | fix/issue-143-canonical-sha-ci-guard        | release-engineer   | 2026-05-16 10:49 |
| #225| #3 #27 #145   | docs/roadmap-v2-deferred-batch              | tech-writer        | 2026-05-16 10:51 |
| #226| #194 #195     | fix/cluster-D-dogfood-safety                | qa-engineer        | 2026-05-16 10:58 |
| #228| #144 #149     | fix/cluster-improve-template-144-149        | release-engineer   | 2026-05-16 11:11 |
| #229| #148 #185     | fix/cluster-F-lint-questions                | software-engineer  | 2026-05-16 11:18 |

New issues filed mid-burst: #216, #218, #219, #222, #223, #227, #230.

Baseline progress: 26/35 closed. Open baseline issues remaining: #59, #136, #146, #150, #151, #165, #189, #191, #192, #193.

Session interruption 2026-05-16 ~11:25 UTC — three in-flight dispatches lost. Worktrees preserved at `.worktrees/issue-136` (PM #136, dirty) and `.worktrees/issue-191` (QA #191, clean). Third dispatch identity pending customer recall.


## 2026-05-16 — Burndown wave 2 (post-recovery)

| PR  | Closes        | Branch                                | Merged (UTC) |
|----:|---------------|---------------------------------------|--------------|
| #231| #136          | docs/issue-136-pm-cadence             | 12:06 |
| #233| #191          | test/issue-191-downgrade-regression   | 11:59 |
| #234| #232          | fix/issue-232-compound-seeds-auditors | 12:10 |
| #235| #146          | fix/issue-146-scoping-template-seeds  | 12:20 |
| #237| #150 #192 #193| docs/cluster-E-drift                  | 12:24 |
| #246| #165          | fix/issue-165-release-engineer-manual | 12:50 |
| #248| #151          | fix/issue-151-researcher-sc-002       | 13:00 |
| #249| (#248 fix)    | fix/issue-151-runtime-sha-recover     | 13:05 |
| #251| (orchestration)| docs/open-questions-q0013-answer     | 13:09 |

Also: #59 closed wontfix via audit (8 fan-out issues #238-#245 filed). #195 closed manually (PR #226 multi-Closes syntax bug).

**Baseline (35 original): 34 closed / 1 open.** Remaining: #189 (Q-0014, customer-blocked).

## 2026-05-16 - T042 / T043 new-finding intake + pre-meta-close audit

22 new issues filed since 2026-05-16. None are operationally blocking the rc14 release - each has an implicit owner from its label set, and the backlog is the GitHub issue tracker itself. Target window for next cycle: rc15 or the first non-release session post-rc14.

### Immediate-cycle finds (14 - caught during burndown work)

| # | Labels | Implicit owner | Notes |
|---|---|---|---|
| #208 | template-friction | qa-engineer | CLAUDE_PROJECT_DIR-unset test gap |
| #211 | template-friction | qa-engineer | test-gate-pass.sh skip-untracked |
| #212 | template-gap, ai-behavior | software-engineer | concurrency: parallel agents share worktree |
| #213 | template-friction | software-engineer | schemas/model-routing.schema.json enum asymmetry |
| #216 | template-friction | qa-engineer | fixture-06 cleanup glob safety |
| #218 | docs-drift | tech-writer | token-ledger lowercase path reference |
| #219 | upgrade, template-friction | release-engineer | migration: git rm --cached for downstreams |
| #222 | bug, upgrade, template-friction | software-engineer | upgrade.sh fail-opens on malformed .template-conflicts.json |
| #223 | template-friction | software-engineer | lint-canonical-sha orphan-mirror detection |
| #227 | template-friction | release-engineer | improve-template numeric validator leading-zero |
| #230 | template-friction | software-engineer | lint-questions regex edge case |
| #236 | template-friction, docs-drift | tech-writer | scoping-template 5a conditional cue |
| #247 | docs-drift | tech-writer | release-engineer-manual citation spot-checks |
| #250 | upgrade, template-gap | release-engineer | **recurring** - pre-commit guard for canonical_sha staleness (hit PR #234 + PR #248) |

### #59 fan-out (8 - deferred from umbrella close)

Issues #238-#245 - IEEE 1044/730/1012 integration, token-economy section, AI/ML requirements, requirements field additions, MSRS-style author markers, IEEE 1016 viewpoints, remote-only inventory pattern, agent prose audit. All `enhancement` + `template-gap` (or `token-economy`). Intentionally deferred from the #59 umbrella audit per A-009.

### T043 audit conclusion

**T043 PASSES**: every post-2026-05-16 issue is in the GitHub backlog with explicit labels indicating bucket and implicit owner. The 14 immediate finds are non-blocking quality follow-ups; the 8 fan-outs are intentionally deferred per A-009. **#250 is flagged as a recurring-pattern issue** - the canonical_sha staleness pitfall has hit twice (PR #234, PR #248); priority for rc15.

**T046 (rc14 cut) is unblocked from T043's side.** Remaining gate: customer authorization per HR-4 and Q-0014 disposition for #189 (the last open baseline issue).


## 2026-05-16 — Meta-close (T046 / T047 / T049)

**T046 rc14 cut** (release-engineer 2026-05-16 ~20:50 UTC):
- VERSION bumped to `v1.0.0-rc14` on `main` (squashed via PR #253 alongside other rc14 prep).
- Pre-release-gate 10/10 PASS (after PR #253 advisory-allowlist + PR #255 v0.16.0 + PR #258 branch-guard fallback).
- Dogfood gate PASS on quackdcs/rc13-gh fixture against main: upgrade exit 0, --verify clean, ai-tui 21/21.
- Annotated tag `v1.0.0-rc14` cut at commit `1090ae1`, tag SHA `b421a60`, pushed to origin.
- Post-tag smoke dogfood PASS — TEMPLATE_VERSION resolves to v1.0.0-rc14 at `1090ae1`, tag identity confirmed.
- No GitHub Release object (rc tags only per `project_releases_at_minor_only`).

**T047 meta-summary** (project-manager 2026-05-16 ~21:00 UTC, PR #259 merged):
- `CHANGELOG.md` rc14 entry: 35/35 baseline closed (31 fixed, 1 wontfix, 3 v2-deferred).
- `docs/pm/burndown-rc13-rc14-summary.md` (new, 198 lines): full disposition table + burndown arc + new-finding fan-out.

**T049 close meta-effort** (this entry):
- Per-bucket disposition (final):
  - **Fixed (31)**: every release-gate/upgrade-flow/hook-behavior/framework-gap/framework-friction/docs-drift baseline that wasn't wontfix or v2-deferred.
  - **Wontfix (1)**: #59 (umbrella audit → fanned out as #238–#245 per A-009).
  - **V2-deferred (3)**: #3, #27, #145 (via PR #225 batch).
  - **Consolidated (0)** / **Duplicate (0)**.
  - **Customer-blocked open (0)** — #189 closed via PR #252 (Q-0014 ruling).
- **Issue-count delta**: baseline 35 → 0 open. **100% completion.**
- **New-finding fan-out**: 22 issues filed during burndown (14 immediate-cycle + 8 #59-audit fan-out + #250 recurring-pattern + #254 v0.16.0 real-fix + #257 branch-guard root-cause). All have implicit owners via labels; target window rc15.
- **Spec status**: `specs/011-issue-backlog-triage/spec.md` → Complete.

Meta-effort closed 2026-05-16.
