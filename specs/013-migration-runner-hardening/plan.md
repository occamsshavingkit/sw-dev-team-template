# Implementation Plan: Migration Runner Hardening

**Branch**: `013-migration-runner-hardening` | **Date**: 2026-05-27 | **Spec**: `specs/013-migration-runner-hardening/spec.md`
**Input**: Feature specification from `specs/013-migration-runner-hardening/spec.md`

## Summary

Harden the migration runner inside `sw-dev-team-template/scripts/upgrade.sh` so a migration that exits non-zero is caught deterministically (non-zero exit = failure; true exit status captured without pipeline/`set -e` masking) and reported with actionable chain context — a human-readable stderr summary plus a structured `.template-migration-failed.json` artifact naming the failing migration, its chain position, the already-applied migrations, and the not-run migrations. Recovery is forward-only (applied migrations stay; operator fixes and re-runs). Behavior is locked by a new test in `tests/upgrade/` with a deliberately-failing fixture migration, and must not regress the chain walked by `scripts/stepwise-smoke.sh`. Grounded in FW-ADR-0017 §4.

## Technical Context

**Language/Version**: Bash (the `scripts/upgrade.sh` runner) targeting the project's existing shell baseline; Python 3 standard library for emitting the JSON failure artifact (same approach the script already uses for `.template-*-blocked.json`).  
**Primary Dependencies**: Existing `sw-dev-team-template/scripts/upgrade.sh` migration-running section, `migrations/*.sh`, and `scripts/stepwise-smoke.sh`; no new third-party dependencies.  
**Storage**: Repository files — the failure artifact `.template-migration-failed.json` is written at the project root, schema-parallel to the existing `.template-prebootstrap-blocked.json` / `.template-preservation-blocked.json` block artifacts.  
**Testing**: Shell test under `sw-dev-team-template/tests/upgrade/` exercising a failing fixture migration (asserting stderr summary, artifact contents, non-zero exit) and a success/no-op case; plus `scripts/stepwise-smoke.sh` as the non-regression surface.  
**Target Platform**: Linux/macOS developer worktrees running the template upgrade.  
**Project Type**: Framework/template repository — deterministic shell tooling.  
**Performance Goals**: Runner remains local and deterministic; no network, no transcript-scale parsing; negligible overhead vs current behavior.  
**Constraints**: Forward-only recovery (no rollback / no down-migrations); stop at first failing migration; no stale `.tmp.*` files; observable stopping point; behavior must match FW-ADR-0017 §4.  
**Scale/Scope**: The migration-running block of one script plus its test and a docs/ADR touch-up; small, contained surface.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Role routing (Principle I)**: PASS. Implementation → `software-engineer`; failing-fixture test + assertions → `qa-engineer`; upgrade/reproducibility validation (stepwise smoke) → `release-engineer`; ADR/governance wording → `architect`; any operator-doc prose → `tech-writer`; pre-commit review → `code-reviewer`. `tech-lead` orchestrates only.
- **Token/context economy (Principle II)**: PASS. Runtime cost is one additional JSON artifact emitted only on failure; planning context stays in `specs/013-migration-runner-hardening/`. No recurring runtime context added.
- **Source authority (Principle III)**: PASS. Canonical: `scripts/upgrade.sh`, `migrations/`, `docs/adr/fw-adr-0017-*.md`. Generated/planning: this plan, `research.md`, `data-model.md`, `contracts/*`, `quickstart.md`. Test fixtures are test assets. The `.template-migration-failed.json` artifact is generated runtime output (ephemeral, project-local), parallel to existing block artifacts.
- **Customer intake (Principle IV)**: PASS. The three open decisions were resolved in the spec's Clarifications (session 2026-05-27); no customer-owned question is open and none blocks planning.
- **Quality gates (Principle V)**: PASS. Implementation requires the new automated test green, no stepwise-smoke regression, and `code-reviewer` sign-off before commit.
- **Framework/project boundary (Principle VI)**: PASS. Explicitly template-maintenance work in `sw-dev-team-template` (customer-directed); all edits are framework-managed paths authorized by this feature; no product/framework mixing.
- **Adapter discipline (Principle VII)**: PASS. The runner stays a deterministic shell mechanism; no new authority surface, no parallel role model, no cross-harness coupling introduced.

## Project Structure

### Documentation (this feature)

```text
specs/013-migration-runner-hardening/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── migration-failure-report.md
└── tasks.md            # /speckit-tasks output (not created here)
```

### Source Code (repository root)

```text
sw-dev-team-template/
├── scripts/
│   ├── upgrade.sh              # migration-running block: capture true exit status,
│   │                          # stop-at-first-failure, emit stderr summary + artifact
│   └── stepwise-smoke.sh       # non-regression surface (unchanged behavior expected)
├── migrations/                 # real migrations (unchanged by this feature)
├── tests/
│   └── upgrade/
│       ├── test-migration-runner.sh        # new: failing-fixture + success/no-op cases
│       └── fixtures/                       # new: a deliberately-failing fixture migration
└── docs/
    └── adr/
        └── fw-adr-0017-file-keyed-migration-discovery.md   # §4 alignment touch-up if needed
```

**Structure Decision**: Use the existing `sw-dev-team-template` script/test/docs layout. The change is localized to the migration-running block of `scripts/upgrade.sh`, a new `tests/upgrade/` test with a failing fixture migration, and (if the §4 wording needs it) an FW-ADR-0017 touch-up. The failure artifact follows the established `.template-*-blocked.json` project-root convention.

## Complexity Tracking

No constitution violations require justification.

## Phase 0: Research

Research decisions are captured in `research.md`. The key unknowns — how to capture each migration's true exit status without the current pipeline masking it, the exact shape of the `.template-migration-failed.json` artifact (parallel to existing block artifacts), how FW-ADR-0017 §4 constrains the summary content, and the failing-fixture test approach — are resolved there with no further customer clarification needed.

## Phase 1: Design & Contracts

Design outputs are in `data-model.md` (Migration chain / Migration outcome / Failure report entities and the artifact field set), `contracts/migration-failure-report.md` (the stderr summary format and the JSON artifact schema), and `quickstart.md` (inject a failing fixture migration, observe summary + artifact + non-zero exit, then fix and re-run to confirm forward resume). The Spec Kit plan pointer in `CLAUDE.md` (between the SPECKIT markers) is updated to this plan.

## Post-Design Constitution Check

- **Role routing**: PASS. Design preserves canonical ownership and names review/QA/release/ADR owners.
- **Token/context economy**: PASS. Feature-local planning artifacts; runtime adds only an on-failure artifact.
- **Source authority**: PASS. Canonical inputs cited; generated artifacts do not supersede `scripts/upgrade.sh`, `migrations/`, or FW-ADR-0017.
- **Customer intake**: PASS. Clarified decisions recorded in the spec; nothing open.
- **Quality gates**: PASS. Contracts and quickstart define the verification surface; one primary verification per task to be preserved at `/speckit-tasks`.
- **Framework/project boundary**: PASS. All edits remain in `sw-dev-team-template` framework-maintenance paths plus the root planning artifacts.
- **Adapter discipline**: PASS. No parallel authority; deterministic shell mechanism only.
