---
description: "Atomic tasks for Open-Issue Backlog Triage and Burndown"
---

# Tasks: Open-Issue Backlog Triage and Burndown

**Input**: Design documents from `/specs/011-issue-backlog-triage/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/dispatch-cycle.md, quickstart.md, triage.md

**Verification**: Every task below names exactly one primary verification command/test. Code review remains a required gate for fix-and-close work, but it is not listed as a second primary verification command.

**Organization**: Tasks are grouped by user story and bucket priority so each story can be implemented and tested independently. Completed state is preserved from the prior `tasks.md` and `sw-dev-team-template/docs/pm/dispatch-log.md` context.

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel because it touches a different issue, file set, or terminal disposition.
- **[Story]**: `US1`, `US2`, `US3`, or `US4`; setup, foundational, and polish tasks have no story label.
- Every task includes an exact file path and one `Primary verification:` command.
- Working tree paths are rooted at `/home/quackdcs/SWEProj/` unless a `gh` command targets GitHub state.

## Path Conventions

- Template repository: `sw-dev-team-template/`
- Canonical dispatch log: `sw-dev-team-template/docs/pm/dispatch-log.md`
- Feature planning artifacts: `specs/011-issue-backlog-triage/`

---

## Phase 1: Setup

**Purpose**: Confirm the post-#203 baseline and preserve the dispatch record needed for atomic issue burndown.

- [X] T001 Confirm issue #203 reached terminal state after PR #204 in `sw-dev-team-template/scripts/upgrade.sh`; Primary verification: `gh -R occamsshavingkit/sw-dev-team-template issue view 203 --json state,closedAt`
- [X] T002 Confirm the canonical dispatch log exists at `sw-dev-team-template/docs/pm/dispatch-log.md`; Primary verification: `test -f sw-dev-team-template/docs/pm/dispatch-log.md`
- [X] T003 Capture the post-#204 smoke baseline for `sw-dev-team-template/`; Primary verification: `sw-dev-team-template/scripts/smoke-test.sh`

---

## Phase 2: Foundational

**Purpose**: File and record new findings required before release-gate dispatches can cite concrete issue numbers.

**Critical**: US1 hook-behavior work depends on T004 and T005 because PR-A needed real issue numbers for the two new false-positive findings.

- [X] T004 File and record issue #205 for absolute paths outside `CLAUDE_PROJECT_DIR` in `sw-dev-team-template/docs/pm/dispatch-log.md`; Primary verification: `gh -R occamsshavingkit/sw-dev-team-template issue view 205 --json number,state,title,labels`
- [X] T005 File and record issue #206 for `/dev/*` redirect false positives in `sw-dev-team-template/docs/pm/dispatch-log.md`; Primary verification: `gh -R occamsshavingkit/sw-dev-team-template issue view 206 --json number,state,title,labels`
- [X] T006 File and record issue #207 for model-routing enforcement in `sw-dev-team-template/docs/pm/dispatch-log.md`; Primary verification: `gh -R occamsshavingkit/sw-dev-team-template issue view 207 --json number,state,title,labels`

**Checkpoint**: Foundational issues #205, #206, and #207 are concrete GitHub records and can be routed through US1/US2 tasks.

---

## Phase 3: User Story 1 - Release-gate readiness (Priority: P1) MVP

**Goal**: Close every release-gate-upgrade-flow and hook-behavior issue so v1.0.0 final is no longer blocked by the QuackDCS-class upgrade incident.

**Independent Test**: `sw-dev-team-template/scripts/pre-release-gate.sh` passes after all US1 tasks and no release-gate baseline issue remains open.

### Upgrade-flow and Version-check Fixes

- [X] T007 [P] [US1] Fix #154 by suppressing missing GitHub Release links for rc tags in `sw-dev-team-template/scripts/version-check.sh`; Primary verification: `sw-dev-team-template/tests/upgrade/test-version-check.sh`
- [X] T008 [P] [US1] Fix #161 by correcting rc semver ordering in `sw-dev-team-template/scripts/version-check.sh`; Primary verification: `sw-dev-team-template/tests/upgrade/test-version-check.sh`
- [X] T009 [P] [US1] Fix #199 by reading `TEMPLATE_VERSION` from `HEAD` in `sw-dev-team-template/scripts/version-check.sh`; Primary verification: `sw-dev-team-template/tests/upgrade/test-version-check.sh`
- [X] T010 [P] [US1] Fix #163 by preserving v0.x upgrade conflict detection in `sw-dev-team-template/scripts/upgrade.sh`; Primary verification: `sw-dev-team-template/tests/upgrade/test-cluster-c-fixes.sh`
- [X] T011 [P] [US1] Fix #169 by removing the stale rc11 migration advisory reference in `sw-dev-team-template/scripts/upgrade.sh`; Primary verification: `sw-dev-team-template/tests/upgrade/test-cluster-c-fixes.sh`
- [X] T012 [P] [US1] Fix #171 by making `--resolve` honor `.template-customizations` in `sw-dev-team-template/scripts/upgrade.sh`; Primary verification: `sw-dev-team-template/tests/upgrade/test-cluster-c-fixes.sh`
- [X] T013 [P] [US1] Fix #190 by citing the migration idempotency contract at the untagged-target full-walk site in `sw-dev-team-template/scripts/upgrade.sh`; Primary verification: `sw-dev-team-template/tests/upgrade/test-cluster-c-fixes.sh`
- [X] T014 [P] [US1] Fix #191 by adding downgrade-from-untagged-to-tag coverage in `sw-dev-team-template/tests/upgrade/test-downgrade-from-untagged-to-tag.sh`; Primary verification: `sw-dev-team-template/tests/upgrade/test-downgrade-from-untagged-to-tag.sh`
- [X] T015 [P] [US1] Fix #200 by preventing plain reruns from silently reclassifying conflicts in `sw-dev-team-template/scripts/upgrade.sh`; Primary verification: `sw-dev-team-template/tests/upgrade/test-rerun-safety.sh`
- [X] T016 [P] [US1] Fix #203 by rejecting unsafe non-default-branch upgrades in `sw-dev-team-template/scripts/upgrade.sh`; Primary verification: `sw-dev-team-template/tests/upgrade/test-branch-guard.sh`

### Hook-behavior Fixes

- [X] T017 [P] [US1] Fix #184 by covering `pathlib.Path.write_text()` and `Path(...).open('w')` in `sw-dev-team-template/scripts/hooks/customer-notes-guard.py`; Primary verification: `sw-dev-team-template/tests/hooks/test-customer-notes-guard.sh`
- [X] T018 [P] [US1] Fix #201 by additively merging PreToolUse hook wiring during upgrade in `sw-dev-team-template/scripts/upgrade.sh`; Primary verification: `sw-dev-team-template/tests/hooks/test-settings-merge.sh`
- [X] T019 [P] [US1] Fix #202 by recording the canonical-scope disposition in `sw-dev-team-template/ROADMAP.md`; Primary verification: `gh -R occamsshavingkit/sw-dev-team-template issue view 202 --json state,labels,comments`
- [X] T020 [P] [US1] Fix #205 by scoping tech-lead authoring guard checks to project paths in `sw-dev-team-template/scripts/hooks/tech-lead-authoring-guard.py`; Primary verification: `sw-dev-team-template/tests/hooks/test-tech-lead-authoring-guard.sh`
- [X] T021 [P] [US1] Fix #206 by allowing `/dev/*` redirect targets in `sw-dev-team-template/scripts/hooks/tech-lead-authoring-guard.py`; Primary verification: `sw-dev-team-template/tests/hooks/test-tech-lead-authoring-guard.sh`
- [X] T022 [P] [US1] Fix #188 by correcting fixture-06 PID-scope stub migration filename and tag in `sw-dev-team-template/tests/release-gate/dogfood-examples/`; Primary verification: `sw-dev-team-template/scripts/pre-release-gate.sh`

### US1 Checkpoint

- [X] T023 [US1] Verify all P1 baseline issues are closed and recorded in `sw-dev-team-template/docs/pm/dispatch-log.md`; Primary verification: `gh -R occamsshavingkit/sw-dev-team-template issue list --state open --search '154 OR 161 OR 163 OR 169 OR 171 OR 184 OR 188 OR 190 OR 191 OR 199 OR 200 OR 201 OR 202 OR 203'`

**Checkpoint**: User Story 1 is complete and independently testable by the release-gate command.

---

## Phase 4: User Story 2 - Framework-gap and friction closeout (Priority: P2)

**Goal**: Close rc9-era framework-gap and framework-friction noise with either a merged fix or an explicit rationale.

**Independent Test**: `gh -R occamsshavingkit/sw-dev-team-template issue list --state open --label template-gap,template-friction,framework-friction,framework-gap` returns no remaining baseline items.

### Framework-gap Fixes and Dispositions

- [X] T024 [P] [US2] Fix #143 by adding canonical_sha staleness CI coverage in `sw-dev-team-template/.github/workflows/canonical-sha-staleness.yml`; Primary verification: `sw-dev-team-template/tests/lint/test-canonical-sha.sh`
- [X] T025 [P] [US2] Fix #144 by tightening protected-file matching in `sw-dev-team-template/.github/workflows/improve-template.yml`; Primary verification: `gh -R occamsshavingkit/sw-dev-team-template issue view 144 --json state,closedAt,comments`
- [X] T026 [P] [US2] Defer #145 to v2 with a roadmap link in `sw-dev-team-template/ROADMAP.md`; Primary verification: `gh -R occamsshavingkit/sw-dev-team-template issue view 145 --json state,labels,comments`
- [X] T027 [P] [US2] Fix #146 by making scoping seed questions atomic in `sw-dev-team-template/docs/templates/scoping-questions-template.md`; Primary verification: `sw-dev-team-template/scripts/lint-questions.sh sw-dev-team-template/docs/templates/scoping-questions-template.md`
- [X] T028 [P] [US2] Fix #160 by preventing lowercase token-ledger clutter in `sw-dev-team-template/docs/pm/`; Primary verification: `gh -R occamsshavingkit/sw-dev-team-template issue view 160 --json state,closedAt,comments`
- [X] T029 [P] [US2] Fix #165 by authoring the release-engineer manual in `sw-dev-team-template/docs/agents/manual/release-engineer-manual.md`; Primary verification: `gh -R occamsshavingkit/sw-dev-team-template issue view 165 --json state,closedAt,comments`
- [X] T030 [P] [US2] Fix #207 Part A by replacing inherited model frontmatter in `sw-dev-team-template/.claude/agents/*.md`; Primary verification: `sw-dev-team-template/scripts/lint-agent-model-routing.sh`
- [X] T031 [P] [US2] Fix #207 Part B by adding the model-routing lint gate in `sw-dev-team-template/scripts/lint-agent-model-routing.sh`; Primary verification: `sw-dev-team-template/tests/lint/test-agent-model-routing.sh`
- [X] T032 [P] [US2] Fix #207 Part C by making `sw-dev-team-template/docs/model-routing-guidelines.md` the single model-routing table source; Primary verification: `sw-dev-team-template/scripts/lint-agent-model-routing.sh`

### Framework-friction Fixes and Dispositions

- [X] T033 [P] [US2] Fix #147 by merging overlapping model-routing tables in `sw-dev-team-template/docs/model-routing-guidelines.md`; Primary verification: `sw-dev-team-template/scripts/lint-agent-model-routing.sh`
- [X] T034 [P] [US2] Fix #148 by suppressing Customer Question Gate enumeration false positives in `sw-dev-team-template/scripts/lint-questions.sh`; Primary verification: `sw-dev-team-template/tests/lint/test-lint-questions.sh`
- [X] T035 [P] [US2] Fix #149 by validating numeric `issue_number` input in `sw-dev-team-template/.github/workflows/improve-template.yml`; Primary verification: `gh -R occamsshavingkit/sw-dev-team-template issue view 149 --json state,closedAt,comments`
- [X] T036 [P] [US2] Fix #151 by applying the customer-selected trim ruling in `sw-dev-team-template/docs/runtime/agents/researcher.md`; Primary verification: `gh -R occamsshavingkit/sw-dev-team-template issue view 151 --json state,closedAt,comments`
- [X] T037 [P] [US2] Fix #185 by suppressing nested template sub-bullets in `sw-dev-team-template/scripts/lint-questions.sh`; Primary verification: `sw-dev-team-template/tests/lint/test-lint-questions.sh`
- [X] T038 [P] [US2] Fix #189 by applying the customer-selected prompt-regression tracking disposition in `sw-dev-team-template/tests/prompt-regression/`; Primary verification: `gh -R occamsshavingkit/sw-dev-team-template issue view 189 --json state,closedAt,comments`
- [X] T039 [P] [US2] Fix #194 by adding dogfood stub-vs-driver flag coupling coverage in `sw-dev-team-template/tests/release-gate/`; Primary verification: `sw-dev-team-template/scripts/pre-release-gate.sh`
- [X] T040 [P] [US2] Fix #195 by failing on unparseable `.template-conflicts.json` in `sw-dev-team-template/tests/release-gate/`; Primary verification: `sw-dev-team-template/scripts/pre-release-gate.sh`

### US2 Checkpoint

- [X] T041 [US2] Verify all P2 baseline issues are closed and recorded in `sw-dev-team-template/docs/pm/dispatch-log.md`; Primary verification: `gh -R occamsshavingkit/sw-dev-team-template issue list --state open --search '143 OR 144 OR 145 OR 146 OR 147 OR 148 OR 149 OR 151 OR 160 OR 165 OR 185 OR 189 OR 194 OR 195 OR 207'`

**Checkpoint**: User Story 2 is complete and independently testable by the framework-gap/friction issue query.

---

## Phase 5: User Story 3 - V2 deferral, docs-drift, and other cleanup (Priority: P3)

**Goal**: Close V2 proposals, docs-drift items, and the `other` bucket so the 35-issue baseline reaches zero.

**Independent Test**: `gh -R occamsshavingkit/sw-dev-team-template issue list --state open --search 'created:<=2026-05-16'` returns zero baseline items.

### V2 Deferrals

- [X] T042 [P] [US3] Create the V2 deferral surface in `sw-dev-team-template/ROADMAP.md`; Primary verification: `grep -n '## V2 deferred' sw-dev-team-template/ROADMAP.md`
- [X] T043 [P] [US3] Defer #3 to v2 with a roadmap anchor in `sw-dev-team-template/ROADMAP.md`; Primary verification: `gh -R occamsshavingkit/sw-dev-team-template issue view 3 --json state,labels,comments`
- [X] T044 [P] [US3] Defer #27 to v2 with a roadmap anchor in `sw-dev-team-template/ROADMAP.md`; Primary verification: `gh -R occamsshavingkit/sw-dev-team-template issue view 27 --json state,labels,comments`
- [X] T045 [P] [US3] Audit and close umbrella #59 with child status fan-out recorded in `sw-dev-team-template/docs/pm/dispatch-log.md`; Primary verification: `gh -R occamsshavingkit/sw-dev-team-template issue view 59 --json state,comments`

### Docs-drift Fixes

- [X] T046 [P] [US3] Fix #150 by documenting fallback-log create-on-first-write behavior in `sw-dev-team-template/docs/`; Primary verification: `gh -R occamsshavingkit/sw-dev-team-template issue view 150 --json state,closedAt,comments`
- [X] T047 [P] [US3] Fix #192 by listing commonly overlooked scrub paths in `sw-dev-team-template/tests/release-gate/dogfood-examples/README.md`; Primary verification: `gh -R occamsshavingkit/sw-dev-team-template issue view 192 --json state,closedAt,comments`
- [X] T048 [P] [US3] Fix #193 by documenting `cp -aL` symlink dereference tradeoffs in `sw-dev-team-template/tests/release-gate/dogfood-examples/README.md`; Primary verification: `gh -R occamsshavingkit/sw-dev-team-template issue view 193 --json state,closedAt,comments`

### Other Bucket

- [X] T049 [P] [US3] Fix #136 by adding proactive project-manager cadence in `sw-dev-team-template/.claude/agents/project-manager.md`; Primary verification: `gh -R occamsshavingkit/sw-dev-team-template issue view 136 --json state,closedAt,comments`

### US3 Checkpoint

- [X] T050 [US3] Verify the 35-issue baseline is closed in `specs/011-issue-backlog-triage/spec.md`; Primary verification: `gh -R occamsshavingkit/sw-dev-team-template issue list --state open --search 'created:<=2026-05-16'`

**Checkpoint**: User Story 3 is complete and the original baseline is at zero open issues.

---

## Phase 6: User Story 4 - New-finding intake during burndown (Priority: P2, cross-cutting)

**Goal**: File, bucket, and disposition every new issue discovered during the burndown without expanding the 35-issue baseline.

**Independent Test**: `gh -R occamsshavingkit/sw-dev-team-template issue list --state open --search 'created:>=2026-05-16'` returns either zero or items recorded in the next-cycle backlog with labels and owners.

- [X] T051 [P] [US4] File and bucket issue #208 in `sw-dev-team-template/docs/pm/dispatch-log.md`; Primary verification: `gh -R occamsshavingkit/sw-dev-team-template issue view 208 --json number,state,labels`
- [X] T052 [P] [US4] File and bucket issue #211 in `sw-dev-team-template/docs/pm/dispatch-log.md`; Primary verification: `gh -R occamsshavingkit/sw-dev-team-template issue view 211 --json number,state,labels`
- [X] T053 [P] [US4] File and bucket issue #212 in `sw-dev-team-template/docs/pm/dispatch-log.md`; Primary verification: `gh -R occamsshavingkit/sw-dev-team-template issue view 212 --json number,state,labels`
- [X] T054 [P] [US4] File and bucket issue #213 in `sw-dev-team-template/docs/pm/dispatch-log.md`; Primary verification: `gh -R occamsshavingkit/sw-dev-team-template issue view 213 --json number,state,labels`
- [X] T055 [P] [US4] File and bucket issue #216 in `sw-dev-team-template/docs/pm/dispatch-log.md`; Primary verification: `gh -R occamsshavingkit/sw-dev-team-template issue view 216 --json number,state,labels`
- [X] T056 [P] [US4] File and bucket issue #218 in `sw-dev-team-template/docs/pm/dispatch-log.md`; Primary verification: `gh -R occamsshavingkit/sw-dev-team-template issue view 218 --json number,state,labels`
- [X] T057 [P] [US4] File and bucket issue #219 in `sw-dev-team-template/docs/pm/dispatch-log.md`; Primary verification: `gh -R occamsshavingkit/sw-dev-team-template issue view 219 --json number,state,labels`
- [X] T058 [P] [US4] File and bucket issue #222 in `sw-dev-team-template/docs/pm/dispatch-log.md`; Primary verification: `gh -R occamsshavingkit/sw-dev-team-template issue view 222 --json number,state,labels`
- [X] T059 [P] [US4] File and bucket issue #223 in `sw-dev-team-template/docs/pm/dispatch-log.md`; Primary verification: `gh -R occamsshavingkit/sw-dev-team-template issue view 223 --json number,state,labels`
- [X] T060 [P] [US4] File and bucket issue #227 in `sw-dev-team-template/docs/pm/dispatch-log.md`; Primary verification: `gh -R occamsshavingkit/sw-dev-team-template issue view 227 --json number,state,labels`
- [X] T061 [P] [US4] File and bucket issue #230 in `sw-dev-team-template/docs/pm/dispatch-log.md`; Primary verification: `gh -R occamsshavingkit/sw-dev-team-template issue view 230 --json number,state,labels`
- [X] T062 [P] [US4] File and bucket issue #236 in `sw-dev-team-template/docs/pm/dispatch-log.md`; Primary verification: `gh -R occamsshavingkit/sw-dev-team-template issue view 236 --json number,state,labels`
- [X] T063 [P] [US4] File and bucket issue #247 in `sw-dev-team-template/docs/pm/dispatch-log.md`; Primary verification: `gh -R occamsshavingkit/sw-dev-team-template issue view 247 --json number,state,labels`
- [X] T064 [P] [US4] File and bucket issue #250 in `sw-dev-team-template/docs/pm/dispatch-log.md`; Primary verification: `gh -R occamsshavingkit/sw-dev-team-template issue view 250 --json number,state,labels`
- [X] T065 [P] [US4] Record #59 fan-out issues #238-#245 in `sw-dev-team-template/docs/pm/dispatch-log.md`; Primary verification: `gh -R occamsshavingkit/sw-dev-team-template issue list --state all --search '238 OR 239 OR 240 OR 241 OR 242 OR 243 OR 244 OR 245'`
- [X] T066 [US4] Complete the pre-meta-close new-finding audit in `sw-dev-team-template/docs/pm/dispatch-log.md`; Primary verification: `gh -R occamsshavingkit/sw-dev-team-template issue list --state open --search 'created:>=2026-05-16'`

**Checkpoint**: User Story 4 is complete because every post-baseline finding is either closed or explicitly recorded for the next cycle with labels and implicit owner.

---

## Final Phase: Polish & Cross-Cutting Concerns

**Purpose**: Cut rc14, validate the combined state, and close the meta-effort.

- [X] T067 Run the final template smoke suite for `sw-dev-team-template/`; Primary verification: `sw-dev-team-template/scripts/smoke-test.sh`
- [X] T068 Run the release-gate validation for `sw-dev-team-template/`; Primary verification: `sw-dev-team-template/scripts/pre-release-gate.sh`
- [X] T069 Cut and verify annotated tag `v1.0.0-rc14` for `sw-dev-team-template/`; Primary verification: `git -C sw-dev-team-template rev-parse v1.0.0-rc14^{tag}`
- [X] T070 Record the rc14 closure count and explicit deferrals in `sw-dev-team-template/CHANGELOG.md`; Primary verification: `grep -n '35/35 baseline closed' sw-dev-team-template/CHANGELOG.md`
- [X] T071 Record the required meta-project release-prep update in `docs/pm/CHANGES.md`; Primary verification: `grep -n 'C-15.*35/35 closed.*#189 closed via PR #252' docs/pm/CHANGES.md`
- [X] T072 Run the rc8-to-rc14 fixture-downstream upgrade-test for `sw-dev-team-template/tests/release-gate/dogfood-examples/alpha/rc8`; Primary verification: `sw-dev-team-template/tests/release-gate/dogfood-downstream.sh --fixture sw-dev-team-template/tests/release-gate/dogfood-examples/alpha/rc8 --upstream v1.0.0-rc14 --codename alpha-rc8-to-rc14`
- [X] T073 Write the burndown meta-summary in `sw-dev-team-template/docs/pm/burndown-rc13-rc14-summary.md`; Primary verification: `gh -R occamsshavingkit/sw-dev-team-template pr view 259 --json state,mergedAt`
- [X] T074 Record final issue-count delta and close the meta-effort in `sw-dev-team-template/docs/pm/dispatch-log.md`; Primary verification: `grep -n 'baseline 35 → 0 open' sw-dev-team-template/docs/pm/dispatch-log.md`

### Optional Post-Close Review (Excluded From Completion Counts)

- [ ] T075 [P] Optional final sanity review of cumulative rc13-to-rc14 changes in `sw-dev-team-template/docs/pm/dispatch-log.md`; Primary verification: `git -C sw-dev-team-template diff --stat v1.0.0-rc13..v1.0.0-rc14`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 Setup**: No dependencies; establishes the post-#203 baseline.
- **Phase 2 Foundational**: Depends on Phase 1; T004 and T005 block US1 hook-behavior dispatches.
- **Phase 3 US1**: Depends on Phase 2; MVP and release-gate blocker closure.
- **Phase 4 US2**: Depends on US1 closure per FR-003 priority order.
- **Phase 5 US3**: Depends on US1 and US2 closure; completes the 35-issue baseline.
- **Phase 6 US4**: Cross-cutting; runs at session boundaries and before meta-close.
- **Final Phase**: Depends on US1, US2, US3, and the T066 new-finding audit; optional post-close T075 is excluded from completion counts.

### User Story Dependencies

- **US1 (P1)**: Starts after Phase 2; no dependency on US2 or US3.
- **US2 (P2)**: Starts after US1 to preserve release-gate-first priority.
- **US4 (P2)**: Runs alongside all stories; final audit must pass before rc14 cut.
- **US3 (P3)**: Starts after P1/P2 buckets; closes baseline residue.

### Within Each User Story

- Close-only disposition tasks use one `gh issue view ...` primary verification command.
- Fix-and-close tasks use one focused script/test command where available.
- Review and PR merge gates are lifecycle requirements from `contracts/dispatch-cycle.md`, not extra primary verification commands.

---

## Parallel Execution Examples

### US1 Version-check Fan-out

```text
T007 [US1] #154 -> sw-dev-team-template/tests/upgrade/test-version-check.sh
T008 [US1] #161 -> sw-dev-team-template/tests/upgrade/test-version-check.sh
T009 [US1] #199 -> sw-dev-team-template/tests/upgrade/test-version-check.sh
```

These tasks share one focused test command but each names one issue behavior and can be reviewed as separate commits in the same PR when appropriate.

### US1 Hook-behavior Fan-out

```text
T017 [US1] #184 -> sw-dev-team-template/tests/hooks/test-customer-notes-guard.sh
T018 [US1] #201 -> sw-dev-team-template/tests/hooks/test-settings-merge.sh
T020 [US1] #205 -> sw-dev-team-template/tests/hooks/test-tech-lead-authoring-guard.sh
T021 [US1] #206 -> sw-dev-team-template/tests/hooks/test-tech-lead-authoring-guard.sh
```

The tasks are atomic by behavior even when landed through one cluster PR.

### US2 Independent Closeout Fan-out

```text
T024 [US2] #143 -> sw-dev-team-template/tests/lint/test-canonical-sha.sh
T027 [US2] #146 -> sw-dev-team-template/scripts/lint-questions.sh sw-dev-team-template/docs/templates/scoping-questions-template.md
T031 [US2] #207 Part B -> sw-dev-team-template/tests/lint/test-agent-model-routing.sh
T039 [US2] #194 -> sw-dev-team-template/scripts/pre-release-gate.sh
```

Different owners can execute these after US1 without file-level conflict.

### US4 New-finding Intake Fan-out

```text
T051-T064 [US4] each verify one new issue with gh issue view
T065 [US4] verifies the #59 fan-out issue set
T066 [US4] verifies the meta-close open-new-issue query
```

New-finding issue records can be checked independently before the aggregate audit.

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 and Phase 2.
2. Complete Phase 3 US1 tasks T007-T023.
3. Validate with `sw-dev-team-template/scripts/pre-release-gate.sh`.
4. Stop if the only goal is release-gate readiness.

### Incremental Delivery

1. Deliver US1 to remove v1.0.0 release-gate blockers.
2. Deliver US2 to clear framework-gap and friction noise.
3. Deliver US3 to close the original 35-issue baseline.
4. Keep US4 running at each session boundary and before final tag.
5. Execute Final Phase only after the T066 new-finding audit passes.

### Parallel Team Strategy

1. Assign US1 version-check, upgrade-flow, and hook-behavior slices to separate specialists with disjoint branch/worktree scopes.
2. Assign US2 framework-gap, lint, docs, and dogfood fixes to separate specialists after US1 closes.
3. Assign US4 issue-record checks in parallel because each task reads one GitHub issue record.

---

## Task Count Summary

| Phase | Tasks | Story labels | Completed | Incomplete |
|---|---:|---|---:|---:|
| Phase 1 Setup | 3 | - | 3 | 0 |
| Phase 2 Foundational | 3 | - | 3 | 0 |
| Phase 3 US1 Release-gate | 17 | [US1] | 17 | 0 |
| Phase 4 US2 Framework gap + friction | 18 | [US2] | 18 | 0 |
| Phase 5 US3 V2 + docs-drift + other | 9 | [US3] | 9 | 0 |
| Phase 6 US4 New-finding intake | 16 | [US4] | 16 | 0 |
| Final Phase Polish | 8 | - | 8 | 0 |
| Optional Post-Close Review | 1 | - | 0 | 1 excluded |
| **Completion Scope Total** | **74** | - | **74** | **0** |

## Format Validation

- All 75 task/checklist rows use markdown checklist syntax, sequential IDs `T001` through `T075`, optional `[P]`, and `[USN]` labels only inside user-story phases.
- Every task description includes at least one concrete file path or GitHub issue path and exactly one `Primary verification:` command.
- Completed state is intentionally preserved with `[X]`; T075 remains unchecked because the prior context marked the final sanity review as optional, user-initiated, and excluded from completion counts.
- No task bundles multiple independent primary verification commands; broad cluster work from the prior task list has been split by issue, behavior, disposition, or lifecycle transition.

## Suggested MVP

**MVP scope**: Phase 1 + Phase 2 + Phase 3 (`T001`-`T023`). This closes the release-gate-upgrade-flow and hook-behavior buckets before lower-priority work, satisfying the risk-first priority in FR-003.
