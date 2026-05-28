# Research: Migration Runner Hardening

## R1 — Capture each migration's true exit status without masking

- **Decision**: Invoke each migration so its own exit status is captured directly, decoupled from any downstream pipeline stage. Either capture the migration's output first (to a variable/temp) then evaluate its return code, or run it under an explicit `rc` capture (e.g. temporarily relax `set -e` around the single call, record `$?`, restore) before forwarding its output to stderr. The runner must NOT let the exit status of a trailing `sed`/`tee` (or `set -e` on the pipeline) stand in for the migration's status.
- **Rationale**: The current runner pipes the migration through `sed` (`bash "$mig" 2>&1 | sed … >&2`); under `set -euo pipefail` the migration's real status is obscured and `set -e` aborts before any chain-context report. Capturing `rc` directly is deterministic and satisfies FR-001.
- **Alternatives considered**: Rely on `PIPESTATUS[0]` after the existing pipe — works today but is fragile to future pipe-stage changes and still aborts under `set -e` before reporting; rejected in favor of explicit capture + controlled handling.

## R2 — Failure artifact shape and location

- **Decision**: Write `.template-migration-failed.json` at the project root, schema-parallel to the existing `.template-prebootstrap-blocked.json` and `.template-preservation-blocked.json` artifacts, emitted via the same Python-stdlib `json.dump` approach already used in `upgrade.sh`.
- **Rationale**: Reuses an established, recognized block-artifact convention so operators and CI already know where to look and how to parse it; no new dependency.
- **Alternatives considered**: A bespoke text file or stderr-only (rejected per spec clarification — automation needs structured output); a new directory (rejected — inconsistent with existing root-level block artifacts).

## R3 — FW-ADR-0017 §4 alignment

- **Decision**: Treat FW-ADR-0017 §4 as authoritative for the required failure-report content (failing migration filename, position in the ordered chain, migrations already applied, migrations not run). The stderr summary and the JSON artifact both carry this set. Touch up the ADR only if its wording needs to explicitly cite the structured artifact.
- **Rationale**: Keeps the runner's behavior governed by the existing ADR rather than introducing a divergent contract.
- **Alternatives considered**: Defining a fresh contract independent of the ADR — rejected (drift risk, Principle III).

## R4 — Stop-at-first-failure vs run-all

- **Decision**: Stop at the first failing migration; report it and the remaining (not-run) migrations. Do not continue the chain past a failure.
- **Rationale**: Matches FR-005/FR-006 and forward-only recovery — continuing past a failure risks compounding partial state.
- **Alternatives considered**: Run all and aggregate failures — rejected; later migrations may depend on the failed one, and forward-only recovery wants a clean stopping point.

## R5 — Forward-only recovery

- **Decision**: No rollback and no down-migrations. Migrations applied before the failure remain applied; recovery is "fix the failing migration and re-run," which resumes forward from the reported stopping point. The runner leaves no stale `.tmp.*` files and an observable stopping point.
- **Rationale**: Spec clarification; migrations are forward-only/idempotent with no reverse scripts, and the existing upgrade model is resume-forward.
- **Alternatives considered**: Rollback (requires down-migrations that don't exist) and whole-tree snapshot/restore (heavy, out of scope) — both rejected.

## R6 — Test approach (failing fixture migration)

- **Decision**: Add `tests/upgrade/test-migration-runner.sh` with a deliberately-failing fixture migration, driving the runner so the failure path executes, and asserting (a) non-zero exit, (b) stderr summary content, (c) the `.template-migration-failed.json` artifact contents (failing filename, position, applied, not-run), plus a success/no-op case asserting no false failure and no artifact. Keep `scripts/stepwise-smoke.sh` as the non-regression surface.
- **Open implementation detail (for tasks)**: whether the migration-running logic can be exercised in isolation or must be driven through a scaffolded synthetic upgrade (as `stepwise-smoke.sh` does). The implementer should prefer the most direct deterministic harness that exercises the real runner code path; if isolation requires a small refactor to make the runner callable, that is in scope.
- **Rationale**: Locks the observable contract (SC-004) without depending on network or published tags; stepwise-smoke guards the real chain (FR-009/SC-003).
- **Alternatives considered**: Only extending stepwise-smoke — rejected as the sole coverage (slow, and harder to inject a controlled failure); used as regression guard instead.
