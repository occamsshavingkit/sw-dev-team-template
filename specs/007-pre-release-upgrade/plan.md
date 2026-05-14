# Implementation Plan: Pre-release upgrade-regression gate

**Branch**: `007-pre-release-upgrade` | **Date**: 2026-05-14 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/007-pre-release-upgrade/spec.md`

## Summary

A single command (`scripts/pre-release-gate.sh`) that orchestrates every release-blocking sub-gate over the full set of published prior tags, fails-all on regression, propagates exit codes through any wrapper, and ships paired with a scoped-strict pre-push git hook that blocks pushes containing annotated `v*` tags until the gate is green. Replaces the ad-hoc `local-ci-gates` wrapper whose exit-code mask let rc10 smoke-test failures slip past local verification.

## Technical Context

**Language/Version**: POSIX `sh` for portable sub-gate code; Bash 4+ for the orchestrator where array semantics are required (matches existing `scripts/upgrade.sh` shebang convention).
**Primary Dependencies**: `git` (for tag enumeration + fixture archives), GNU coreutils, `find`, `awk`, `sed`, `mktemp`, plus the existing helper scripts the gate orchestrates (`scripts/smoke-test.sh`, `scripts/lint-agent-contracts.sh`, `scripts/check-spdx.sh`).
**Storage**: tempfiles (`mktemp -d`) for per-tag round-trip fixtures (cleaned up on exit); a single append-only audit log at `docs/pm/pre-release-gate-overrides.md` for `SKIP_PRE_RELEASE_GATE=1` events at the pre-push gate AND `SWDT_PREBOOTSTRAP_FORCE=1` events at the FW-ADR-0010 pre-bootstrap step (shared schema, FW-ADR-0010 v2).
**Testing**: shell-based fixture harness under `tests/release-gate/` paralleling the existing `tests/workflows/` and `tests/prompt-regression/` layout; each sub-gate has a positive (PASS) fixture and at least one negative (deliberate-break) fixture.
**Target Platform**: developer Linux workstations (POSIX) + GitHub Actions `ubuntu-latest` runners. macOS is best-effort; sub-gates that depend on GNU `find` flags are guarded.
**Project Type**: CLI tool / shell script collection (template-maintenance tooling, framework-scoped).
**Performance Goals**: full gate run < 5 min wall-clock on a typical Linux maintainer workstation with the prior-tag set already fetched into the local clone (SC-002 / FR-012); per-tag round-trip < 30s; the per-migration standalone sub-gate < 60s total across all migrations.
**Constraints**: gate exit-code propagation MUST survive `tail`/`head`/`tee`/pipe/`$()` composition (FR-002); fail-all semantics across all sub-gates (FR-001); no scope cap on prior-tag set (FR-003); strict-on-`v*`-tag pre-push hook (FR-011).
**Scale/Scope**: ~15-20 published tags today (v0.10.0 through v1.0.0-rc10 plus pre-rc intermediates); plan supports growth to 50+ tags by parallelising per-tag round-trips if the serial budget breaks the 5-min target.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Role routing**: `release-engineer` owns the gate script, the pre-push hook template, and the rc-tag release-checklist update (SWEBOK V4 ch. 6 Operations Delivery). `qa-engineer` co-owns the per-tag round-trip fixtures and the negative-fixture deliberate-break library. `code-reviewer` co-owns the advisory-pointer scan rules and reviews every gate-script change. `tech-writer` updates the release-checklist prose and any user-facing docs. `tech-lead` orchestrates dispatch and customer interface. Customer-truth (the three Clarifications-session answers) was captured by the main session during `/speckit-clarify` and is owned by `researcher` for inclusion in CUSTOMER_NOTES if promoted.
- **Token/context economy**: the gate is a script + fixture set, not a recurring-runtime instruction surface. The pre-push hook is a one-line dispatcher to the gate script. Per-run logs are ephemeral and excluded from canonical surfaces. The override-audit log under `docs/pm/` is append-only and grows slowly (one row per `SKIP_PRE_RELEASE_GATE=1` event). No new agent contracts or recurring prompts introduced; net token cost ≈ 0.
- **Source authority**: gate script + sub-gate libraries + fixtures = **canonical** (framework-managed). Per-run output and tempfile fixtures = **ephemeral**. Override-audit log = **canonical** (release-engineer-owned, lives at `docs/pm/pre-release-gate-overrides.md`); schema authority for that log is FW-ADR-0010 (v2, 2026-05-14), which also owns the `SWDT_PREBOOTSTRAP_FORCE=1` pre-bootstrap producer side written by `scripts/upgrade.sh` and `migrations/v0.14.0.sh`. Generated artifacts named by the gate (e.g., JSONL future-output if added) cite their canonical inputs.
- **Customer intake**: three customer answers captured in spec.md `## Clarifications` (Session 2026-05-14): fail-all severity, every-published-tag scope, strict-on-`v*`-tag hook severity. No new customer-facing questions queued; all in-scope decisions resolved by these three plus the spec's assumptions.
- **Quality gates**: this feature **is** a new pre-commit quality gate. Itself requires `code-reviewer` review before commit; `qa-engineer` reviews the negative-fixture coverage; `release-engineer` self-reviews the rc-tag-checklist integration; `tech-writer` reviews user-facing docs. Smoke-test regression: the gate's introduction MUST NOT itself break the existing `scripts/smoke-test.sh`.
- **Framework/project boundary**: this work is **framework** scope and edits only files under `./sw-dev-team-template/`. The meta-project (rooted at `/home/quackdcs/SWEProj`) is unaffected except as a downstream consumer that will receive the gate via the next rc upgrade. Customer authorisation: implied by the customer's `/speckit-specify` invocation requesting "a new release test before committing"; this is the planned response.
- **Adapter discipline**: the gate is a single canonical script with a thin git-hook adapter. No new agent role, no parallel orchestrator, no competing release-blocking authority. The `release-engineer` role contract (`.claude/agents/release-engineer.md`) gains the gate in its `## Output` / `## Hard rules` section but does not become a new authority surface.

**Verdict**: Constitution Check PASSES; no violations, no Complexity Tracking entries required.

## Project Structure

### Documentation (this feature)

```text
specs/007-pre-release-upgrade/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
│   ├── pre-release-gate.cli.md      # The gate's flags, exit-code contract
│   ├── sub-gate.contract.md         # What every sub-gate must implement
│   └── pre-push-hook.contract.md    # The git-hook scoped-strict semantics
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (template repository: ./sw-dev-team-template)

```text
sw-dev-team-template/
├── scripts/
│   ├── pre-release-gate.sh          # NEW — the orchestrator (P1 entrypoint)
│   ├── lib/
│   │   ├── gate-runner.sh           # NEW — sub-gate registry + fail-all dispatcher
│   │   ├── gate-tags.sh             # NEW — prior-tag enumeration (FR-003)
│   │   ├── gate-advisory-scan.sh    # NEW — path-reference scanner (FR-006)
│   │   └── gate-migrations.sh       # NEW — per-migration standalone runner + placeholder detection (FR-007)
│   ├── smoke-test.sh                # EXISTING — invoked by upgrade-path sub-gate
│   ├── lint-agent-contracts.sh      # EXISTING — invoked by contract sub-gate
│   └── check-spdx.sh                # EXISTING — invoked by SPDX sub-gate
├── tests/
│   └── release-gate/                # NEW
│       ├── fixtures/                # positive + negative fixtures per sub-gate
│       │   ├── 01-clean-tree/
│       │   ├── 02-broken-smoke/
│       │   ├── 03-dangling-advisory/
│       │   ├── 04-spdx-missing/
│       │   ├── 05-lint-fail/
│       │   ├── 06-migration-placeholder/
│       │   └── 07-dirty-worktree/
│       ├── test-gate-pass.sh         # positive end-to-end
│       ├── test-gate-fail-each.sh    # each negative fixture → fail-all proof
│       └── test-gate-wrapper.sh      # FR-002 exit-code propagation through wrappers
├── .git-hooks/                       # NEW — opt-in template-shipped hooks
│   └── pre-push                       # invokes pre-release-gate.sh with scoped-strict semantics
├── docs/
│   ├── pm/
│   │   └── pre-release-gate-overrides.md   # NEW — append-only override audit log
│   └── v1.0.0-final-checklist.md     # EDIT — add gate as numbered precondition
└── .claude/agents/
    └── release-engineer.md           # EDIT — add gate to ## Output / ## Hard rules
```

**Structure Decision**: framework-scoped tooling under `sw-dev-team-template/scripts/` with the orchestrator as a single canonical entrypoint and four thin library helpers under `scripts/lib/` (`gate-runner.sh`, `gate-tags.sh`, `gate-advisory-scan.sh`, `gate-migrations.sh`). Sub-gate logic stays in the existing `smoke-test.sh` / `lint-agent-contracts.sh` / `check-spdx.sh` to keep change scope bounded; the new code is composition + advisory-scan + tag enumeration + override audit. Test fixtures live under `tests/release-gate/` paralleling the existing `tests/workflows/` and `tests/prompt-regression/` patterns. The git-hook adapter is opt-in (operators copy `.git-hooks/pre-push` into `.git/hooks/` or set `core.hooksPath`).

## Complexity Tracking

> No Constitution Check violations; Complexity Tracking table not required.
