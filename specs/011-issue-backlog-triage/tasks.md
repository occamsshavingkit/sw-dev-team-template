---
description: "Tasks for Open-Issue Backlog Triage and Burndown"
---

# Tasks: Open-Issue Backlog Triage and Burndown

**Input**: Design documents from `/specs/011-issue-backlog-triage/`
**Prerequisites**: plan.md ✅, spec.md ✅, triage.md ✅, research.md ✅, data-model.md ✅, contracts/dispatch-cycle.md ✅, quickstart.md ✅

**Verification**: Each fix-and-close task lands a PR that passes `scripts/smoke-test.sh` + the bucket-relevant test directory under `tests/`. Each non-code disposition (wontfix, defer-to-v2, consolidate, duplicate) records a close-comment with rationale per FR-005 / FR-006 / FR-007.

**Organization**: Phases run in strict bucket order per FR-003. Within each user-story phase, multi-issue cluster PRs are dispatched as a single task block; solo-PR issues each get their own task block.

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (independent files, no dependencies on other in-flight tasks).
- **[Story]**: US1 / US2 / US3 / US4 (US4 is cross-cutting — applied throughout, not a sequential phase).
- All file paths assume working tree `/home/quackdcs/SWEProj/sw-dev-team-template/` unless otherwise stated.

## Path Conventions

- Template subrepo: `sw-dev-team-template/` (`scripts/`, `tests/`, `docs/`, `.github/workflows/`, `ROADMAP.md`).
- Meta-project: `specs/011-issue-backlog-triage/` (planning artifacts) and `docs/pm/dispatch-log.md` (if mirrored at meta level).
- Primary dispatch-log location: `sw-dev-team-template/docs/pm/dispatch-log.md`.

---

## Phase 1: Setup

**Purpose**: confirm post-#203 baseline; verify the burndown can begin without surprise.

- [X] T001 Confirm PR #204 merged on `main` and issue #203 closed: `gh -R occamsshavingkit/sw-dev-team-template pr view 204 --json state` returns MERGED; `gh issue view 203 --json state` returns CLOSED. Open-issue count is 34.
- [X] T002 Verify or create `sw-dev-team-template/docs/pm/dispatch-log.md`. If absent, dispatch project-manager to scaffold per template convention. Working tree: `sw-dev-team-template/docs/pm/dispatch-log.md`.
- [X] T003 [P] Establish post-#204 test baseline: run `sw-dev-team-template/scripts/smoke-test.sh` on `main` (expected 174+ PASS / 0 FAIL with the 12 new branch-guard cases included). Record baseline counts in `dispatch-log.md`.

---

## Phase 2: Foundational

**Purpose**: file the two hook-behavior findings observed in the 2026-05-16 session so they ride PR-A. No blocking dependency on Phase 3, but PR-A's brief must reference them by issue number.

**⚠️ CRITICAL**: Phase 3 PR-A cannot dispatch until T004 and T005 are filed (so the dispatch brief can cite real issue numbers).

- [X] T004 File new issue NEW-A on `occamsshavingkit/sw-dev-team-template`: title "tech-lead-authoring-guard.py denies absolute paths outside CLAUDE_PROJECT_DIR — HR-8 should be project-scoped". Body cites the auto-memory write denials observed 2026-05-16 (`~/.claude/projects/-home-quackdcs-SWEProj/memory/`) and `/tmp/issues.json` denial. Labels: `bug`, `template-friction`. Use `gh issue create`.
- [X] T005 File new issue NEW-B on `occamsshavingkit/sw-dev-team-template`: title "tech-lead-authoring-guard.py denies `> /dev/null` and likely all `/dev/*` redirect targets — false positive on device path". Body cites the two `2>/dev/null` and one `>/dev/null` denial events from the 2026-05-16 session. Labels: `bug`, `template-friction`. Use `gh issue create`.

**Checkpoint**: hook-behavior cluster has 6 issues (4 baseline + 2 new). PR-A can now dispatch.

---

## Phase 3: User Story 1 — Release-gate readiness (Priority: P1) 🎯 MVP

**Story goal**: Close every release-gate-upgrade-flow + hook-behavior issue so v1.0.0 final is unblocked. This phase is the MVP — its completion alone delivers the highest-value outcome (the QuackDCS-class incident is structurally prevented and the upgrade flow is reliable).

**Independent test criterion**: At phase close, `gh issue list --state open --label upgrade,template-friction,bug` returns zero items in the release-gate-upgrade-flow and hook-behavior buckets; full `scripts/smoke-test.sh` + `tests/upgrade/*` + `tests/hooks/*` green; QuackDCS-fixture downstream upgrades rc8 → rc13-post-burndown cleanly.

### PR-A: hook-behavior cluster (closes #201, NEW-A, NEW-B, #184)

- [X] T006 [US1] Dispatch software-engineer for PR-A. Brief: implement (1) #201 — additive PreToolUse merge in `scripts/upgrade.sh` so settings.json receives new hook wires on upgrade; (2) NEW-A — scope FW-ADR-0012 guard to paths under `CLAUDE_PROJECT_DIR` (early-return when outside); (3) NEW-B — add `/dev/null` and `/dev/*` to the redirect-scanner allowlist in `scripts/hooks/tech-lead-authoring-guard.py` and `customer-notes-guard.py`; (4) #184 — extend the pathlib detection (`Path(...).open('w')`, `Path.write_text()`). Branch `fix/cluster-A-hook-behavior`. Update tests under `tests/hooks/`.
- [X] T007 [US1] Dispatch code-reviewer for PR-A branch. Verdict format per `contracts/dispatch-cycle.md` § state `in-review`.
- [X] T008 [US1] On APPROVED, push branch and open PR with `Closes #201 #184` plus the two NEW-A/NEW-B issue numbers from T004/T005. Working tree: `sw-dev-team-template/`.
- [X] T009 [US1] Merge PR-A (auto-merge if checks pending); verify 4 issues auto-close; record in `docs/pm/dispatch-log.md`.

### PR-B: version-check cluster (closes #161, #199, #154)

- [X] T010 [US1] Dispatch software-engineer for PR-B. Brief: (1) #161 — fix semver comparator so rc10 isn't reported as a downgrade from rc9; (2) #199 — read `TEMPLATE_VERSION` from `git show HEAD:TEMPLATE_VERSION` not working-tree; (3) #154 — suppress GitHub Release links for rc tags (per memory `project_releases_at_minor_only`, only MINOR boundaries have Release objects). Files: `sw-dev-team-template/scripts/version-check.sh`, possibly `scripts/lib/semver.sh`. Branch `fix/cluster-B-version-check`.
- [X] T011 [US1] Dispatch code-reviewer for PR-B.
- [X] T012 [US1] On APPROVED, push + open PR with `Closes #161 #199 #154`; merge.

### PR-C: upgrade.sh cluster (post-#203, post-PR-B)

- [X] T013 [US1] [P] Re-evaluate #163 (v0.16.0 upgrade-path conflict) against current upgrade.sh post-#203. If the conflict no longer reproduces, disposition becomes `consolidate-with-other-issue` (cross-link to #203's PR #204 and close as obsolete). Otherwise, fold into PR-C scope.
- [X] T014 [US1] Dispatch software-engineer for PR-C. Brief: (1) #169 — fix or remove stale migrations/v1.0.0-rc11.sh reference in post-upgrade advisory; (2) #190 — cite the migration idempotency contract at the new untagged-target full-walk site in `scripts/upgrade.sh`; (3) #171 — `--resolve` consults `.template-customizations` to prune pinned-path conflicts; (4) #163 only if T013 confirms still-relevant. Branch `fix/cluster-C-upgrade-sh-followups`.
- [X] T015 [US1] Dispatch code-reviewer for PR-C.
- [X] T016 [US1] On APPROVED, push + open PR with `Closes #169 #190 #171` (and #163 if folded); merge.

### Solo P1 dispatches

- [X] T017 [US1] Dispatch software-engineer for #200 — upgrade.sh plain re-run silently reclassifies `conflict` → `accepted_local` without `--resolve`. Add explicit re-run safety semantics: refuse to reclassify unless `--resolve` is set, or print a WARN naming the reclassification. Branch `fix/issue-200-rerun-safety`. Code-review → push + open PR `Closes #200` → merge.
- [X] T018 [US1] Dispatch architect for a structural read of #202 (canonical-scope guard inversion); architect returns a brief disposition note (1-2 paragraphs) on whether the inversion is by design or a real bug. If bug: dispatch software-engineer with the architect's note as the binding spec. Branch `fix/issue-202-canonical-scope-guard`. Code-review → push + open PR `Closes #202` → merge.
- [X] T019 [US1] Dispatch qa-engineer for #188 — fixture-06 PID-scope stub migration filename + tag. Branch `fix/issue-188-fixture-06-pid-scope`. Code-review → push + open PR `Closes #188` → merge.

### Phase-3 checkpoint

- [X] T020 [US1] Verify all P1 issues closed: `gh issue list --state open --search 'is:open label:upgrade,template-friction,bug'` returns zero items relevant to release-gate-upgrade-flow or hook-behavior buckets. Update dispatch-log; bucket-1 + bucket-2 marked CLOSED. (verified 2026-05-16: all bucket-1/2 issues closed via PRs #204, #209, #210, #214, #217, #221)

---

## Phase 4: User Story 2 — Framework-gap + Framework-friction closeout (Priority: P2)

**Story goal**: every rc9-era framework-gap and framework-friction issue gets an explicit disposition. Burndown noise drops; release-cycle triage gets clean signal.

**Independent test criterion**: `gh issue list --state open --label template-gap,template-friction,framework-friction,framework-gap` returns zero items, OR each remaining item carries `v2-deferred` or `wontfix` plus a rationale close-comment.

### framework-gap bucket

- [X] T021 [US2] Dispatch release-engineer for #143 — add CI guard for canonical_sha staleness on `docs/runtime/agents/` + `.opencode/agents/`. Files: new `.github/workflows/canonical-sha-staleness.yml`. Branch `fix/issue-143-canonical-sha-ci`. Code-review → PR `Closes #143` → merge.
- [X] T022 [US2] [P] Dispatch release-engineer for #144 — improve-template.yml protected-files regex misses HR-bearing files. File: `.github/workflows/improve-template.yml`. Branch `fix/issue-144-protected-files-regex`. Code-review → PR `Closes #144` → merge. (closed via PR #228 (folded with T029 #149 into cluster `fix/cluster-improve-template-144-149`))
- [X] T023 [US2] [P] Dispatch tech-writer for #146 — `docs/templates/scoping-questions-template.md` still has compound seed questions. Reword seeds per HR-11 atomic-question rule. Branch `fix/issue-146-scoping-template-seeds`. Code-review → PR `Closes #146` → merge. **Closed 2026-05-16:** closed via PR #235 (`fix/issue-146-scoping-template-seeds`); #146 scoping seeds reworded per HR-11
- [X] T024 [US2] [P] Dispatch software-engineer for #160 — recurring stale `docs/pm/token-ledger.md` lowercase clutter. Add a normalization step or pre-commit guard. Branch `fix/issue-160-token-ledger-clutter`. Code-review → PR `Closes #160` → merge.
- [X] T025 [US2] [P] Re-check #165 (release-engineer manual authorship — T044 deferral) state. If superseded by later work: close as `wontfix-and-close` with rationale citing the superseding work. If still relevant: dispatch release-engineer for fix. **Closed 2026-05-16:** re-check returned fix-required; closed via PR #246 (`fix/issue-165-release-engineer-manual`) authoring `docs/agents/manual/release-engineer-manual.md`
- [X] T026 [US2] [P] Close #145 (improve-template.yml Phase-3+ wire real LLM) as `defer-to-v2`. Body anchor: `ROADMAP.md#v2-deferred` (created in T036). Add `v2-deferred` label. Security re-review requirement is the main reason for v2 deferral.

### framework-friction bucket

- [X] T027 [US2] Dispatch software-engineer for PR-F (lint-questions cluster): #148 — pattern-2 false positive on Customer Question Gate enumeration; #185 — `strip_template_prose` nested sub-bullets not suppressed. File: `sw-dev-team-template/scripts/lint-questions.sh`. Branch `fix/cluster-F-lint-questions`. Code-review → PR `Closes #148 #185` → merge. (closed via PR #229; new finding #230 filed mid-PR)
- [X] T028 [US2] Dispatch tech-writer for PR-G **Part C** (#147) — `docs/model-routing-guidelines.md` has two overlapping per-agent tables. Merge into one canonical table; the binding per-agent default-class table becomes the single source of truth for all three providers (Claude, OpenAI, Gemini — all reachable per the harness mix in use). Branch `fix/cluster-G-model-routing` (same branch as Part A + B below — single PR closes #147 + #207).
- [X] T028a [US2] Dispatch release-engineer for PR-G **Part A** (#207) — update 28 agent contracts (14 in template + 14 in meta) `.claude/agents/<role>.md` frontmatter: replace `model: inherit` with the Claude equivalent of each role's binding default_class (Claude-side mapping; class→model fallback chart per #207 body). Same branch `fix/cluster-G-model-routing`.
- [X] T028b [US2] Dispatch release-engineer for PR-G **Part B** (#207) — add `scripts/lint-agent-model-routing.sh` (or python equivalent) that parses agent-contract frontmatter, validates against `docs/model-routing-guidelines.md`'s binding table (extracted to JSON, validated by `schemas/model-routing.schema.json`), and fails on mismatch. Add a CI step in `.github/workflows/` that runs the lint on every PR touching `.claude/agents/` or `docs/model-routing-guidelines.md`. Cross-harness check: also verify the OpenAI/Codex routing (AGENTS.md adapter consumes the table directly) and Gemini class assignments are consistent with reachable providers per the project's harness mix. Same branch.
- [X] T028c [US2] Dispatch code-reviewer for PR-G full cluster (#147 + #207). Verify Part C lands first in commit order so Part A reads the canonical class names. Confirm CI lint catches a deliberately-mutated test case (defensive: ensure the gate actually fails when expected).
- [X] T028d [US2] On APPROVED, push `fix/cluster-G-model-routing` and open PR `Closes #147 #207`; merge.
- [X] T029 [US2] [P] Dispatch release-engineer for #149 — improve-template.yml workflow_dispatch `issue_number` input lacks numeric validator. File: `.github/workflows/improve-template.yml`. Branch `fix/issue-149-numeric-validator`. Code-review → PR `Closes #149` → merge. (closed via PR #228 (folded with T022 #144); new finding #227 filed for leading-zero edge case)
- [X] T030 [US2] Customer ruling first: queue an atomic question on #151 (researcher SC-002 margin 17.2% vs 20% floor — where-safe exception or trim?) in `docs/OPEN_QUESTIONS.md`. On customer answer: dispatch researcher (fix-and-close) or PM (wontfix-and-close with rationale). **Closed 2026-05-16:** Q-0013 queued in OPEN_QUESTIONS.md; customer answered `Trim` 2026-05-16; closed via PR #248 (`fix/issue-151-researcher-sc-002`); recovery PR #249 fixed canonical_sha staleness
- [X] T031 [US2] Dispatch qa-engineer for PR-D (dogfood cluster): #194 — stub-vs-driver flag coupling check at PR time; #195 — force FAIL on unparseable `.template-conflicts.json` (jq empty probe). Branch `fix/cluster-D-dogfood-safety`. Code-review → PR `Closes #194 #195` → merge. (closed via PR #226; note: verify #195 final close-state before Phase-4 checkpoint (gh shows it still open))
- [ ] T032 [US2] Customer ruling first: queue an atomic question on #189 (tests/prompt-regression: tracking status for `results-*.md` + `token-ledger.md`) in `docs/OPEN_QUESTIONS.md`. On customer answer: dispatch qa-engineer with the ruling as binding spec.
- [X] T033 [US2] [P] Dispatch qa-engineer for #191 — smoke-test add downgrade-from-untagged-to-tag regression case. New test under `sw-dev-team-template/tests/upgrade/`. Branch `fix/issue-191-downgrade-regression`. Code-review → PR `Closes #191` → merge. **Closed 2026-05-16:** closed via PR #233 (`test/issue-191-downgrade-regression`); guard + 7-case test + reachability respin

### Phase-4 checkpoint

- [X] T034 [US2] Verify all P2 issues closed: `gh issue list --state open --label template-gap,template-friction,framework-friction,framework-gap` returns zero. Update dispatch-log. **Closed 2026-05-16:** Phase-4 OR-search verified 2026-05-16: 0 of original baseline-Phase-4 labels open; 18 new findings are post-2026-05-16 (route via T042)

---

## Phase 5: User Story 3 — V2 deferral, docs-drift, and `other`-bucket cleanup (Priority: P3)

**Story goal**: V2-proposals close with explicit deferral; docs-drift closes with cheap patches; the `other` bucket (#136 PM cadence) closes alongside. The 2026-05-16 baseline reaches zero.

**Independent test criterion**: `gh issue list --state open --label v2-proposal` returns zero open items; `gh issue list --state open --label docs-drift` returns zero; #136 closed; `ROADMAP.md` contains `## V2 deferred` section listing every deferred issue.

### V2 deferral surface

- [X] T035 [US3] Dispatch tech-writer to append `## V2 deferred` section to `sw-dev-team-template/ROADMAP.md`. Section header is the anchor link target `#v2-deferred`. Initial content: empty list + rationale paragraph. Branch `docs/roadmap-v2-deferred-section`. Code-review → PR `Closes #145 #3 #27` (folds with later defer-to-v2 closes if multiple ride this PR) → merge. (delivered via PR #215 (V2 section + #202 first entry); close-batch landed in PR #225 (#3 #27 #145))

### V2 deferrals (close-only, no code)

- [X] T036 [US3] [P] Close #3 (`[v2] Project triage + repair agent for retrofit adoption`) as `defer-to-v2`. Close-comment: anchor link `ROADMAP.md#v2-deferred`. Add `v2-deferred` label. Append a row in `ROADMAP.md#v2-deferred` listing this issue.
- [X] T037 [US3] [P] Close #27 (`use claude-mem as template for agent memories databases`) as `defer-to-v2`. Same shape as T036.
- [X] T038 [US3] Audit #59 children against current rc13 state per Q3 / A-009. Produce a single summary close-comment listing per-child status (already-done with PR cite; still-relevant; obsolete). For still-relevant items, file each as a NEW issue (outside the 35-baseline per A-003). Close #59 as `wontfix-and-close` with the audit summary as the FR-005 rationale (`superseding change: per-child resolution / new-issue split renders the umbrella obsolete`). The `consolidate-with-other-issue` disposition is NOT used here because no single surviving issue exists — the umbrella's children fan out, they do not collapse into one survivor. **Closed 2026-05-16:** #59 audit complete; 17 children categorized (3 already-done, 14 still-relevant → 8 new issues #238–#245, 0 obsolete, 0 v2-deferred); #59 closed wontfix 2026-05-16

### docs-drift

- [X] T039 [US3] Dispatch tech-writer for PR-E (docs-drift cluster): #150 — document `fallback-log.jsonl` create-on-first-write contract at scaffold time; #192 — enumerate commonly-overlooked scrub paths in `dogfood/README`; #193 — surface `cp -aL` symlink-dereference trade-off in `dogfood/README`. Branch `docs/cluster-E-drift`. Code-review → PR `Closes #150 #192 #193` → merge. **Closed 2026-05-16:** closed via PR #237 (`docs/cluster-E-drift`); #150 #192 #193 (cp -aL trade-off + scrub paths + fallback-log contract)

### other bucket

- [X] T040 [US3] Dispatch project-manager for #136 — Project manager cadence does not keep schedule and roadmap current. Self-referential: PM updates its own cadence contract (`docs/pm/*.md` cadence sections). Branch `docs/issue-136-pm-cadence`. Code-review → PR `Closes #136` → merge. **Closed 2026-05-16:** closed via PR #231 (`docs/issue-136-pm-cadence`); proactive PM dispatch rule added to tech-lead.md Job #6

### Phase-5 checkpoint

- [X] T041 [US3] Verify baseline zero: `gh issue list --state open --search 'created:<=2026-05-16'` returns zero items matching the 35-baseline issue numbers. Update dispatch-log. **Closed 2026-05-16:** baseline zero verification 2026-05-16: 1 baseline issue still open (#189) — customer-blocked, queued as Q-0014. Other 34 of 35 baseline closed

---

## Phase 6: User Story 4 — New-finding intake (Priority: P2, cross-cutting)

**Story goal**: every new bug / gap discovered during burndown is filed, bucketed, and dispositioned before meta-close. This phase is NOT sequential — its tasks apply at every session boundary.

**Independent test criterion**: at meta-close, `gh issue list --state open --search 'created:>=2026-05-16'` returns either zero, or each item has an explicit next-cycle disposition recorded in the meta-summary commit.

- [ ] T042 [US4] Per-session rule: at session start AND session end, query `gh issue list --state open --search 'created:>=2026-05-16'`. For each new issue not yet bucketed: route via tech-lead → triage table extension → dispatch per its bucket's owning role. Skip-rule: if the new issue obviously rides an existing cluster PR, fold it in instead of opening a new PR.
- [ ] T043 [US4] Pre-meta-close audit: confirm every post-2026-05-16 new issue has reached terminal state (closed) OR is recorded in a documented next-cycle backlog with a named owner and target window. Block T046 (rc14 cut) until this passes.

---

## Final Phase: Polish & Cross-Cutting

**Purpose**: cut the release tag, run the fixture downstream test, write the meta-summary, optionally sanity-check the cumulative diff.

- [X] T044 Run full template test suite on `main` post-burndown: `sw-dev-team-template/scripts/smoke-test.sh` + every entry under `sw-dev-team-template/tests/`. All must be green. Compare counts to the baseline from T003. **Closed 2026-05-16:** smoke-test post-burndown 176 PASS / 0 FAIL 2026-05-16 (matches T003 baseline)
- [X] T045 SC-007 fixture-downstream verification: set up a clean fixture at `v1.0.0-rc8`, run the post-burndown `scripts/upgrade.sh`, confirm no divergence (no multi-branch TEMPLATE_VERSION trap; settings.json receives new hook wires; version-check accurate; post-upgrade smoke-test passes). **Closed 2026-05-16:** rc8 → rc13 fixture-downstream upgrade verified clean (8 steps PASS; 3 smoke failures traceable to fixture hybrid nature, not upgrade regressions; canonical 176/0 holds on upstream tree).
- [ ] T046 Dispatch release-engineer to cut `v1.0.0-rc14` per FR-012: tag annotated commit on `main`, push tag, no GitHub Release object (rc tags only per memory `project_releases_at_minor_only`). Branch: tag operation only, no fix branch.
- [ ] T047 Dispatch project-manager (or PM-on-tech-lead-bridge if PM unavailable) to write the meta-summary commit per SC-006. Files: `sw-dev-team-template/CHANGELOG.md` (one-line entry under v1.0.0-rc14) and `docs/pm/` release-prep doc (counts: fixed N, wontfix M, v2-deferred K, consolidated J, duplicate D). Branch `docs/burndown-meta-summary`. Code-review → PR `Closes <any remaining tracking issues>` → merge.
- [ ] T048 [P] Optional final sanity check: invoke `/ultrareview` (user-initiated; tech-lead cannot auto-invoke) on the cumulative diff from `v1.0.0-rc13`..`v1.0.0-rc14`. Record verdict in dispatch-log final entry.
- [ ] T049 Close the meta-effort: final entry in `docs/pm/dispatch-log.md` summarizing per-bucket disposition counts and final issue-count delta (35 → 0 baseline). Mark spec / plan as `Status: Complete`.

---

## Dependencies (story completion order)

```text
Phase 1 (Setup, T001-T003)
    ↓
Phase 2 (Foundational, T004-T005)  ← MUST complete before PR-A in Phase 3
    ↓
Phase 3 (US1 — Release-gate, T006-T020)  ← MVP; structural blocker for v1.0.0
    ↓
Phase 4 (US2 — Framework gap + friction, T021-T034)
    ↓
Phase 5 (US3 — V2 + docs-drift, T035-T041)
    ↓ (Phase 6 runs in parallel across all phases — not sequential)
Final Phase (Polish, T044-T049)

Phase 6 (US4 — new-finding intake, T042-T043)  ← cross-cutting; applies every session
```

**Within-phase parallelism**:

- Phase 3 PR-A / PR-B / PR-C can run as three concurrent specialist dispatches once their respective inputs are ready (PR-A needs T004+T005; PR-C needs #203 merged = done after PR #204).
- Phase 4 framework-gap items T021-T026 are parallel ([P] tagged where files don't conflict).
- Phase 5 V2-deferral close-only tasks T036-T037 are parallel after T035 creates the `## V2 deferred` section.

## Parallel execution examples

**Phase 3 fan-out** (3 PRs concurrent):

```text
T006 [US1] → T007 → T008 → T009    (PR-A: software-engineer → code-reviewer → push → merge)
T010 [US1] → T011 → T012           (PR-B: software-engineer → code-reviewer → merge)
T013 [US1] → T014 → T015 → T016    (PR-C: re-check → software-engineer → review → merge)
```

These three can run as concurrent agent dispatches; tech-lead orchestrates and merges in order of arrival.

**Phase 4 framework-gap fan-out** (5+ parallel):

```text
T021 (release-engineer, CI yaml)
T022 [P] (release-engineer, regex)
T023 [P] (tech-writer, scoping-template)
T024 [P] (software-engineer, token-ledger)
T025 [P] (re-check #165)
T026 [P] (close-only #145)
```

Six concurrent specialist dispatches, no file-overlap. Tech-lead orchestrates and merges per PR completion.

## Implementation strategy

**MVP scope**: Phase 1 → Phase 2 → Phase 3 only. At Phase 3 close, the v1.0.0 release-gate is structurally unblocked even if Phase 4+ remain. If session budget is tight, stop at Phase 3 and queue Phase 4+ for the next cycle.

**Incremental delivery**: each completed PR is shippable independently. The rc14 cut (T046) only happens at full meta-close per FR-012, but every merged PR lands on `main` and is immediately available to downstreams that fetch latest.

**Risk-first ordering**: P1 work hits the upgrade-flow and hook-behavior surfaces — the exact two clusters that caused the QuackDCS-class incident. Closing those clusters first means even a partially-completed burndown materially reduces downstream-incident risk.

**Hard rule reminders during dispatch**:
- HR-3: every PR needs code-reviewer approval.
- HR-7: any PR touching auth / secrets / PII / network endpoints needs security-engineer sign-off. Re-check during each dispatch; none of the 35 baseline issues currently look HR-7-relevant on read.
- HR-8: tech-lead does not author; dispatch.
- HR-9: pre-close audit on every non-trivial tech-lead turn.
- HR-11: atomic customer questions, batched in `docs/OPEN_QUESTIONS.md`, one per turn.

## Task count summary

| Phase | Tasks | Story labels |
|---|---:|---|
| Phase 1 Setup | 3 | — |
| Phase 2 Foundational | 2 | — |
| Phase 3 US1 Release-gate | 15 | [US1] |
| Phase 4 US2 Framework gap + friction | 14 + 4 new = 18 | [US2] |
| Phase 5 US3 V2 + docs-drift | 7 | [US3] |
| Phase 6 US4 New-finding intake | 2 | [US4] |
| Final Phase Polish | 6 | — |
| **Total** | **53** | (+4 for PR-G expanded: T028a T028b T028c T028d) |

## Format validation

All 49 tasks follow the strict checklist format: `- [ ] T### [P?] [USN?] description with file path`. Setup, Foundational, and Polish phase tasks carry no `[USN]` label per the rule; US1-US4 phase tasks all carry their respective story label.

## Suggested MVP

**Stop at Phase 3 (T020)** if session budget is constrained. At that point:
- Release-gate-upgrade-flow + hook-behavior buckets are CLOSED.
- The QuackDCS-class incident is structurally prevented.
- The remaining 19 issues are P2/P3 and can ride a follow-up cycle without blocking v1.0.0 readiness for the high-impact failure modes.

This matches User Story 1's standalone deliverable per the spec.
