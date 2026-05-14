---
description: "Task list for pre-release upgrade-regression gate"
---

# Tasks: Pre-release upgrade-regression gate

**Input**: Design documents from `/specs/007-pre-release-upgrade/`
**Prerequisites**: plan.md (loaded), spec.md (3 user stories P1/P2/P3), research.md (R-1..R-11), data-model.md (E-1..E-8), contracts/ (3 files)

**Verification**: This feature ships its own test suite under `tests/release-gate/`; positive + negative fixtures are required per the spec (FR-009 / Sub-gate contract). Constitution Hard Rule #3 still applies (no commit without `code-reviewer` review).

**Organization**: Tasks grouped by user story so each story delivers an independently demonstrable MVP increment.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)

## Path Conventions

All implementation paths are under `sw-dev-team-template/` (the framework subdir). Spec / plan / contracts paths are under `specs/007-pre-release-upgrade/`. Per the constitution, all changes here are framework-scoped.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: create the on-disk skeleton every later phase writes into.

- [x] T001 Create `sw-dev-team-template/scripts/lib/` directory (already exists; verify) and confirm shellcheck + opengrep targets in CI workflows will pick up new `scripts/lib/gate-*.sh` files
- [x] T002 [P] Create `sw-dev-team-template/tests/release-gate/` directory with empty `fixtures/` subdirectory
- [x] T003 [P] Create `sw-dev-team-template/.git-hooks/` directory (template-shipped opt-in hooks)
- [x] T004 [P] Create `sw-dev-team-template/docs/pm/pre-release-gate-overrides.md` as an append-only Markdown table with the 6-column header from data-model.md E-7 and a one-line preamble explaining the audit-row append-only contract
- [x] T005 [P] Add `# SPDX-License-Identifier: MIT` + copyright lines to every new file template under `scripts/lib/`, `.git-hooks/`, and `tests/release-gate/` so the check-spdx sub-gate stays green when these land

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: the orchestrator library and the sub-gate registry; every user story depends on this.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T006 Implement `sw-dev-team-template/scripts/lib/gate-runner.sh` with: `gate_register <name> <category> <description>` helper, `gate_run_all` dispatcher (fail-all semantics per FR-001), `gate_register` storage in two arrays (preconditions vs regression), deterministic in-category order (registration order), per-sub-gate `duration_ms` capture, per-sub-gate stderr capture into a tempfile, and a final summary printer that emits the header + per-sub-gate result lines + the PASS/FAIL summary
- [x] T007 Implement `sw-dev-team-template/scripts/pre-release-gate.sh` (orchestrator entrypoint): flag parser (`--only` / `--skip` / `--help` with mutual-exclusion check per contract), source `scripts/lib/gate-runner.sh`, register the v1 sub-gates by name, call `gate_run_all`, exit with the orchestrator's computed code; SPDX header; usage block matching the CLI contract
- [x] T008 Add wrapper-masking exit-code-propagation test fixture: `sw-dev-team-template/tests/release-gate/test-gate-wrapper.sh` invokes the orchestrator inside the 5 wrapper compositions from R-5, against a known-failing fixture, and asserts non-zero exit through each composition
- [x] T009 Implement `gate_subgate_worktree-clean` in `scripts/lib/gate-runner.sh` (precondition category): runs `git status --porcelain` against `$GATE_CANDIDATE_TREE`, FAIL if non-empty, diagnostic lists offending paths

**Checkpoint**: Foundation ready — orchestrator runs, fails-all, propagates exit, has worktree-clean precondition. User story work can begin.

---

## Phase 3: User Story 1 - One-command pre-tag readiness check (Priority: P1) 🎯 MVP

**Goal**: A single command runs the orchestrator over the cheap sub-gates (worktree-clean, lint-contracts, check-spdx) and emits the PASS/FAIL summary with correct exit propagation. This is the MVP — even without the upgrade-paths or advisory/migration sub-gates, the gate already replaces the rc10-style local-CI-gates wrapper and removes the exit-mask failure mode.

**Independent Test**: `scripts/pre-release-gate.sh` on a clean candidate → PASS exit 0; on a dirty worktree → FAIL exit non-zero with `worktree-clean` named; with a deliberately-broken SPDX header on a script → FAIL with `check-spdx` named.

### Tests for User Story 1 (FAIL FIRST)

- [~] T010 [P] [US1] Negative fixture `sw-dev-team-template/tests/release-gate/fixtures/01-dirty-worktree/` (an untracked file under `.claude/agents/`) + test `tests/release-gate/test-gate-fail-each.sh` assertion that running the gate against this fixture lists `worktree-clean` in the failing sub-gates
  _Superseded by Style-A perturbation contract amendment, 2026-05-14._
- [~] T011 [P] [US1] Negative fixture `sw-dev-team-template/tests/release-gate/fixtures/04-spdx-missing/` (a `.sh` file without the SPDX header) + assertion that `check-spdx` surfaces in the failing list
  _Superseded by Style-A perturbation contract amendment, 2026-05-14._
- [~] T012 [P] [US1] Negative fixture `sw-dev-team-template/tests/release-gate/fixtures/05-lint-fail/` (a canonical agent missing `## Hard rules`) + assertion that `lint-contracts` surfaces in the failing list
  _Superseded by Style-A perturbation contract amendment, 2026-05-14._
- [~] T013 [P] [US1] Positive fixture `sw-dev-team-template/tests/release-gate/fixtures/00-clean-tree/` representing a known-good candidate; positive end-to-end test `sw-dev-team-template/tests/release-gate/test-gate-pass.sh` that asserts the orchestrator exits 0 and prints `PASS — 6/6 sub-gates green` (or N/N for the current registry size)
  _Superseded by Style-A perturbation contract amendment, 2026-05-14._

### Implementation for User Story 1

- [ ] T014 [US1] Implement `gate_subgate_lint-contracts` in `scripts/lib/gate-runner.sh`: runs `scripts/lint-agent-contracts.sh --canonical-only`, captures stderr, exit code is the underlying script's; SPDX header
- [ ] T015 [US1] Implement `gate_subgate_check-spdx` in `scripts/lib/gate-runner.sh`: runs `scripts/check-spdx.sh --summary`, captures stderr, exit code is the underlying script's
- [ ] T016 [US1] Wire the summary printer to format the per-sub-gate detail blocks per the CLI contract (`[<name>] PASS|FAIL (Ns)` and indented diagnostic lines) — refine the T006 stub to match contract output exactly
- [ ] T017 [US1] Add `--only` / `--skip` flag parsing to `scripts/pre-release-gate.sh` with the mutual-exclusion guard returning exit 2; surface in `--help` output
- [ ] T018 [US1] Add the version header line (`pre-release-gate vX.Y.Z (candidate <sha-short>)`) reading `VERSION` and `git rev-parse --short HEAD`
- [ ] T019 [US1] Implement `.git-hooks/pre-push` with scoped-strict semantics per `contracts/pre-push-hook.contract.md`: parse stdin per git protocol, detect annotated `v*` tag refspecs, invoke the orchestrator in strict mode (ignoring `--only`/`--skip`), handle `SKIP_PRE_RELEASE_GATE=1` bypass with audit-log append + unwritable-log refusal
- [ ] T020 [US1] Implement the override-audit-row append logic invoked by `.git-hooks/pre-push`: compute the 6 columns from data-model E-7, append BEFORE returning 0 in bypass mode, refuse to bypass on unwritable log
- [ ] T021 [US1] Negative-fixture test `sw-dev-team-template/tests/release-gate/test-hook-strict-fail.sh` — feed a `refs/tags/v1.0.0-rcN` refspec, gate-mock returns non-zero, hook exits non-zero with documented stderr
- [ ] T022 [US1] Negative-fixture test `sw-dev-team-template/tests/release-gate/test-hook-bypass.sh` — feed same refspec with `SKIP_PRE_RELEASE_GATE=1`, hook exits 0, one row appended to `docs/pm/pre-release-gate-overrides.md`
- [ ] T023 [US1] Negative-fixture test `sw-dev-team-template/tests/release-gate/test-hook-bypass-unwritable.sh` — chmod 0500 the override log, attempt bypass, hook exits non-zero with the documented error message
- [ ] T024 [US1] Advisory-mode test `sw-dev-team-template/tests/release-gate/test-hook-advisory.sh` — feed a `refs/heads/main` refspec, hook exits 0 with WARN to stderr
- [ ] T025 [US1] Run the full `test-gate-*` suite plus `test-hook-*` suite; confirm all green; verify the orchestrator's wall-clock duration on a clean candidate is under 5 minutes (SC-002) with the current sub-gate set (US2/US3 still to add)

**Checkpoint**: At this point, US1 is fully functional and demonstrable. Maintainer can run `scripts/pre-release-gate.sh` locally and get pass/fail. Pre-push hook blocks `v*` tag pushes correctly. MVP ships here even without US2/US3.

---

## Phase 4: User Story 2 - Upgrade-path coverage from every prior on-track tag (Priority: P2)

**Goal**: The orchestrator's `upgrade-paths` sub-gate exercises one scaffold + upgrade + verify round-trip per published prior tag, fail-all surfacing every failing tag in the diagnostic.

**Independent Test**: Mock a candidate tree where one source-tag's round-trip is deliberately broken (e.g., a stub `migrations/<rc>.sh` that exits 1); run `scripts/pre-release-gate.sh --only upgrade-paths`; assert non-zero exit and that the failing tag is named in the diagnostic.

### Tests for User Story 2 (FAIL FIRST)

- [~] T026 [P] [US2] Negative fixture `sw-dev-team-template/tests/release-gate/fixtures/02-broken-roundtrip/` carrying a candidate tree where one prior-tag's upgrade path exits non-zero; assertion in `test-gate-fail-each.sh` that `upgrade-paths` surfaces with the named tag in the diagnostic
  _Superseded by Style-A perturbation contract amendment, 2026-05-14._
- [~] T027 [P] [US2] Positive fixture `sw-dev-team-template/tests/release-gate/fixtures/02-clean-roundtrips/` representing a small synthetic tag set (2-3 prior tags) where every round-trip passes; positive test asserts `N rounds passed`
  _Superseded by Style-A perturbation contract amendment, 2026-05-14._

### Implementation for User Story 2

- [ ] T028 [US2] Implement `sw-dev-team-template/scripts/lib/gate-tags.sh` with `gate_enumerate_source_tags()` returning every reachable published tag via `git tag --list` filtered by reachability (`git merge-base --is-ancestor`); SPDX header; resolves each tag to current commit SHA via `git rev-parse <tag>^{commit}` (R-9 force-move-safe). Handle the zero-tags edge case explicitly: when the enumeration returns an empty set, the `upgrade-paths` sub-gate MUST emit `0 rounds (no prior tags)` to its diagnostic and exit 0 (clean pass), per the spec's "Brand-new rc with no prior tags" edge case.
- [ ] T029 [US2] Implement `gate_subgate_upgrade-paths` in `scripts/lib/gate-runner.sh` (regression category): iterate over `gate_enumerate_source_tags`, for each tag create a fresh tempdir under `$GATE_TEMP_ROOT/upgrade-paths/<tag>/`, run scaffold from the source tag (re-using `scripts/smoke-test.sh` primitives or inlining the same logic), run `scripts/upgrade.sh --target <candidate>`, run `scripts/upgrade.sh --verify`; record per-tag round-trip status (E-4)
- [ ] T030 [US2] Per-round-trip cleanup: each round-trip's tempdir is unconditionally removed at end of round-trip (success or fail); failed round-trips capture the last 40 lines of upgrade.sh / verify output into the diagnostic
- [ ] T031 [US2] Cross-MAJOR upgrade attempts (per FR-003 — Clarifications Session 2026-05-14 settled the scope as every published tag, with no track/recency cap) are NOT skipped silently — a `v0.10.0 → v1.0.0-rcN` failure surfaces as a sub-gate failure naming the source tag and the failing step (scaffold / upgrade / verify); confirm fixture coverage
- [ ] T032 [US2] Update positive end-to-end test `test-gate-pass.sh` to assert the orchestrator's wall-clock duration stays under 5 minutes (SC-002) on the actual prior-tag set in the live repo (use `time` measurement; soft-warn if budget exceeded, hard-fail at 10 min)
- [ ] T033 [US2] Run `tests/release-gate/test-gate-fail-each.sh` with the T026 fixture; confirm `upgrade-paths` is named and exit non-zero; run with T027 positive fixture and confirm clean pass

**Checkpoint**: US1 + US2 work; the gate now exercises every prior tag's upgrade path. This catches the rc8→rc9 class of issue the spec was driven by.

---

## Phase 5: User Story 3 - Stale-pointer and silent-placeholder catches (Priority: P3)

**Goal**: The orchestrator adds `advisory-pointers` (scans scripts for dangling path references) and `migrations-standalone` (runs each migration standalone with proper `WORKDIR_NEW` and detects placeholder fallbacks) sub-gates.

**Independent Test**: Add a deliberate `# see migrations/v1.0.0-rc99.sh` string to `scripts/upgrade.sh`; run `scripts/pre-release-gate.sh --only advisory-pointers`; assert non-zero exit naming the dangling path. Separately, run a migration with deliberately-empty `WORKDIR_NEW`; assert `migrations-standalone` fails citing the placeholder.

### Tests for User Story 3 (FAIL FIRST)

- [~] T034 [P] [US3] Negative fixture `sw-dev-team-template/tests/release-gate/fixtures/03-dangling-advisory/` (a candidate tree with `migrations/v1.0.0-rc99.sh` reference in `scripts/upgrade.sh` but no such file present); assertion in `test-gate-fail-each.sh` that `advisory-pointers` names both the source line and the missing path
  _Superseded by Style-A perturbation contract amendment, 2026-05-14._
- [~] T035 [P] [US3] Negative fixture `sw-dev-team-template/tests/release-gate/fixtures/06-migration-placeholder/` carrying a stub migration that writes a placeholder body when `WORKDIR_NEW` is unset/empty; assertion that `migrations-standalone` fails with the migration name and the affected files
  _Superseded by Style-A perturbation contract amendment, 2026-05-14._

### Implementation for User Story 3

- [ ] T036 [US3] Implement `sw-dev-team-template/scripts/lib/gate-advisory-scan.sh` with the path-reference regex from R-8, the deduplication on `(source_file, source_line, path_reference)`, and per-match existence check against the candidate tree; SPDX header
- [ ] T037 [US3] Implement `gate_subgate_advisory-pointers` in `scripts/lib/gate-runner.sh`: source `gate-advisory-scan.sh`, scan `scripts/upgrade.sh`, `scripts/scaffold.sh`, every `migrations/*.sh`; emit one diagnostic line per dangling path naming the source file:line and the missing target
- [ ] T038 [US3] Implement `sw-dev-team-template/scripts/lib/gate-migrations.sh` with: `gate_enumerate_migrations()` returning each `migrations/v*.sh`; per-migration helper that (a) scaffolds a fixture from the rc-prior tag of `target_version`, (b) extracts the candidate tree to `WORKDIR_NEW`, (c) runs the migration, (d) scans for the placeholder marker `**TODO**: the rc9 agent-contract schema requires this section.` and any future analogous markers, (e) parses `<fixture>/docs/DECISIONS.md` for `placeholder` source-attribution entries added during the run; SPDX header
- [ ] T039 [US3] Implement `gate_subgate_migrations-standalone` in `scripts/lib/gate-runner.sh`: source `gate-migrations.sh`, iterate over enumerated migrations, fail iff any migration's exit is non-zero OR placeholder marker found OR decisions-log placeholder entry written
- [ ] T040 [US3] Confirm SC-003's four representative regressions all surface: rerun the rc10-window negative cases (a) smoke-test-mask via T008 wrapper test, (b) dangling `migrations/v1.0.0-rcN.sh` via T034, (c) SPDX-missing on new script via T011, (d) lint-fail on sme-template-derived file via T012; assert all 4 surface in `test-gate-fail-each.sh` output
- [ ] T041 [US3] Re-confirm full-gate wall-clock budget against SC-002 with all 6 sub-gates active; if over the 5-min target on the live repo's prior-tag set, document the overage in `research.md` with a follow-up for R-4 parallelisation

**Checkpoint**: All 3 user stories complete; all 6 sub-gates active. Gate catches every rc8→rc10 regression class. SC-001..SC-005 measurable.

---

## Phase 6: Polish & Cross-Cutting Concerns

- [ ] T042 [P] Update `sw-dev-team-template/.claude/agents/release-engineer.md` to add the pre-release gate to `## Output` (operator-facing) and `## Hard rules` (gate is a precondition before tagging an rc); preserve `## Hard rules` ID continuity (HR-N+1 etc.)
- [ ] T043 [P] Update `sw-dev-team-template/docs/v1.0.0-final-checklist.md` to reference `scripts/pre-release-gate.sh` as a numbered precondition before tagging; cite the exit-code contract and the override-audit-log path
- [ ] T044 [P] If `sw-dev-team-template/docs/agents/manual/release-engineer-manual.md` already exists in the candidate tree, update it with the wrapper-masking discussion from R-5 so future maintainers don't recreate the local-CI-gates exit-mask footgun. If it does NOT exist, this task is a no-op — creating the manual is out of scope for this feature; file a separate framework-gap issue tracking the manual's authorship instead of inlining it here.
- [ ] T045 [P] Add a one-line entry to `sw-dev-team-template/CHANGELOG.md` under the next rc heading naming the new gate, the new sub-gate names, and the override-audit-log path
- [ ] T046 [P] Add a row to `sw-dev-team-template/docs/INDEX-FRAMEWORK.md` (or equivalent canonical index) pointing at the gate script + quickstart so operators can find it
- [ ] T047 [P] Add the new test files to `sw-dev-team-template/scripts/smoke-test.sh` runner if a wrapping test entrypoint exists, OR document that the release-gate tests are invoked directly (`tests/release-gate/test-*.sh`) and not from `smoke-test.sh`
- [ ] T047a [P] Add force-move regression test `sw-dev-team-template/tests/release-gate/test-gate-force-moved-tag.sh` covering the US2 edge case from R-9: create a throwaway local tag at commit A, run the gate once to enumerate (record the resolved SHA), force-move the tag to commit B via `git tag -f`, run the gate again, assert the second run's per-tag log shows the new SHA (no stale cache) and the round-trip uses the new commit's tree
- [ ] T048 Run `scripts/pre-release-gate.sh` against the live candidate; capture the green run output and append a confirmation row to `docs/pm/SCHEDULE-EVIDENCE.md` (or the equivalent canonical PM record) noting the gate's first green run at this commit. (SC-005's "three most recent rc tags" audit window rolls forward naturally as future rc cuts each append their own confirmation row; no additional task here today — the row added by T048 is the first of the ratchet.)
- [ ] T049 Obtain `code-reviewer` specialist review on the full diff per Constitution Hard Rule #3 before commit
- [ ] T050 Obtain `qa-engineer` review on the negative-fixture coverage to confirm every sub-gate has at least one fail-path fixture
- [ ] T051 Run `quickstart.md` end-to-end manually (install hook, run gate, attempt bypass, read audit log) and update quickstart with any UX surprises

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: no dependencies; start immediately.
- **Foundational (Phase 2)**: depends on Setup completion; BLOCKS all user stories.
- **US1 (Phase 3)**: depends on Foundational. **MVP — can ship alone.**
- **US2 (Phase 4)**: depends on Foundational. Can run in parallel with US3 if staffed; logically follows US1 but does NOT depend on US1's code (it adds one sub-gate).
- **US3 (Phase 5)**: depends on Foundational. Can run in parallel with US2.
- **Polish (Phase 6)**: depends on all desired user stories complete.

### Within Each User Story

- Tests authored FIRST per the spec's negative-fixture contract (Sub-gate contract).
- Sub-gate implementation second.
- Wiring into the orchestrator's registry third.
- End-to-end run + duration check last.

### Parallel Opportunities

- T002 / T003 / T004 / T005 in Phase 1 are all independent dir/file creations.
- Negative-fixture tasks (T010-T013, T026-T027, T034-T035) within each story are independent files and can run in parallel.
- US2 and US3 implementation can run in parallel after Foundational (different sub-gates, different `scripts/lib/gate-*.sh` files).
- Phase 6 polish tasks T042-T046 touch different files and can run in parallel.

### Critical-Path Notes

- T006 (gate-runner.sh) is the central foundational task — every later sub-gate registers through it. Get this right before parallelising US2/US3.
- T019 (pre-push hook) and T020 (override-audit append) must land together; the hook references the audit-log path from the start.
- T032 / T041 wall-clock checks are the SC-002 enforcement; if either fails the 5-min budget, file R-4 parallelisation as a follow-up rather than blocking the ship.

---

## Parallel Example: User Story 1

```text
# Negative fixtures + positive baseline can all be written in parallel:
T010 [P] [US1] fixtures/01-dirty-worktree/ + test assertion
T011 [P] [US1] fixtures/04-spdx-missing/ + test assertion
T012 [P] [US1] fixtures/05-lint-fail/ + test assertion
T013 [P] [US1] fixtures/00-clean-tree/ + positive end-to-end

# Then sub-gate implementations are file-shared in gate-runner.sh; sequential:
T014 [US1] worktree-clean → lint-contracts
T015 [US1] check-spdx
T016 [US1] summary printer
T017 [US1] flag parsing
T018 [US1] version header
```

---

## Implementation Strategy

### MVP First (US1 only)

1. Phases 1 + 2 (Setup + Foundational) — orchestrator skeleton + worktree-clean + exit propagation.
2. Phase 3 (US1) — adds lint-contracts + check-spdx sub-gates + pre-push hook + override audit log.
3. **STOP and VALIDATE**: maintainer runs `scripts/pre-release-gate.sh` against the live candidate and gets PASS/FAIL with cheap sub-gates. The exit-mask failure mode from rc10 is gone. Ship as v1.0.0-rcN+1 if desired.

### Incremental Delivery

1. Setup + Foundational → orchestrator skeleton.
2. + US1 → cheap gates + hook → MVP demo.
3. + US2 → upgrade-path coverage → next rc bump.
4. + US3 → advisory + migration scans → ship full gate.
5. Polish phase → docs, agent contracts, audit-evidence row.

### Parallel Team Strategy

If staffing allows: one developer on US2 (gate-tags.sh + upgrade-paths sub-gate + per-tag fixture), another on US3 (gate-advisory-scan.sh + gate-migrations.sh + advisory + migrations sub-gates) after Foundational completes. Both touch `scripts/lib/gate-runner.sh` to register their sub-gate; coordinate the register-line edit to avoid a small merge conflict.

---

## Notes

- [P] tasks = different files, no dependencies.
- [Story] labels enforce traceability back to spec.md user stories.
- Tests are authored FIRST per the spec's negative-fixture contract.
- Commit after each task or logical group; obtain `code-reviewer` review before commit per Constitution Hard Rule #3.
- Stop at the US1 checkpoint to validate MVP independently; cut an rc if value justifies before US2/US3.
