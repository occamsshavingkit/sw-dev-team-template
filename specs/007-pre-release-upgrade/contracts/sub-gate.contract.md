---
name: sub-gate-contract
description: Sub-gate contract; every release-blocking check the orchestrator runs must implement this interface.
status: resolved
created_date: 2026-05-14
---


# Contract: Sub-gate

**Owner**: `release-engineer` (registry); per-sub-gate logic co-owned by `qa-engineer` / `code-reviewer` / `software-engineer` as appropriate.
**Status**: design
**Spec**: [../spec.md](../spec.md) — FR-001..FR-007, FR-009, FR-013.

## Purpose

Every release-blocking check the orchestrator runs is a sub-gate. This contract defines what every sub-gate MUST implement and what guarantees it MUST provide so the orchestrator can fail-all over them safely.

## Shape

A sub-gate is a single shell function registered in `scripts/lib/gate-runner.sh` with this signature:

```sh
# Required globals (read-only):
#   GATE_CANDIDATE_TREE  — absolute path to the candidate worktree root
#   GATE_TEMP_ROOT       — absolute path to the orchestrator's per-run tempdir
#   GATE_FIXTURES_DIR    — absolute path to tests/release-gate/fixtures (read-only)
#
# Required outputs:
#   stdout: nothing
#   stderr: human-readable diagnostic on FAIL; empty (or silent) on PASS
#
# Exit codes:
#   0 — PASS
#   non-zero — FAIL; the value is preserved and reported by the orchestrator
#
# Side effects:
#   none on the candidate tree (read-only against $GATE_CANDIDATE_TREE)
#   tempfiles MUST live under $GATE_TEMP_ROOT/<subgate_name>/ and are cleaned up by the orchestrator
gate_subgate_<name>() {
  : # implementation
}
```

## Registration

Each sub-gate registers itself with `gate_register <name> <category> <description>` at the top of `scripts/lib/gate-runner.sh` (so `--help` enumerates them). Order of registration determines order within a category; categories run in fixed order: `precondition` first, `regression` second.

## Required guarantees

1. **Idempotent**: re-running the sub-gate against an unchanged candidate produces the same exit code and the same diagnostic.
2. **No worktree mutation**: any file the sub-gate writes lives under `$GATE_TEMP_ROOT/<subgate_name>/`.
3. **No global state leak**: the sub-gate restores any shell options it changes (`set -e`, `set -u`, `set -o pipefail`).
4. **Exit propagation**: the sub-gate function MUST return the underlying check's exit code; wrapping `... || true` is forbidden.
5. **Stderr-only diagnostics**: stdout is reserved for future structured output; v1 sub-gates emit nothing on stdout.
6. **Bounded runtime**: each sub-gate documents its expected upper-bound runtime in `gate_register`; the orchestrator does NOT enforce per-sub-gate timeouts in v1 but uses the documented bound to size SC-002 audits.

## Required interface to the orchestrator

The orchestrator's dispatch loop (`scripts/lib/gate-runner.sh::gate_run_all`) calls each registered sub-gate function, captures `$?`, records the duration, and appends to the per-run summary. The sub-gate MUST NOT call back into the orchestrator (no recursion, no cross-sub-gate dispatch).

## v1 sub-gate roster (concrete instances)

| Name | Category | Implements | Fixture style | Underlying check | Expected runtime |
|---|---|---|---|---|---|
| `worktree-clean` | precondition | FR-008 | A | `git status --porcelain` empty | < 1s |
| `upgrade-paths` | regression | FR-003 | A | per-source-tag round-trip via `smoke-test`-style fixture | ~100s (15-20 tags) |
| `lint-contracts` | regression | FR-004 | A | `scripts/lint-agent-contracts.sh --canonical-only` | < 5s |
| `check-spdx` | regression | FR-005 | A | `scripts/check-spdx.sh --summary` | < 2s |
| `readme-current` | regression | FR-013 | A | README mentions current VERSION or was touched since last `v*` tag | < 1s |
| `advisory-pointers` | regression | FR-006 | A | path-reference scan against candidate tree (R-8) | < 5s |
| `migrations-standalone` | regression | FR-007 | A | per-migration scaffold+standalone-run+placeholder-scan (R-7) | < 60s |

## Negative-fixture contract

Every sub-gate MUST have at least one negative fixture proving the
sub-gate fails on a deliberate break, exercised by
`tests/release-gate/test-gate-fail-each.sh`. Two fixture styles are
permitted; the sub-gate's author picks the style and documents the
choice in the runner's per-fixture comment block.

**Style A — in-test perturbation (default).** The runner mutates the
live candidate tree at test time (create a stray file, strip a `##
Hard rules` section, append a synthetic v* tag, drop a stub
migration), runs the orchestrator, asserts the named sub-gate
surfaces in the failing list, and reverts the mutation via a
registered revert action and `trap ... EXIT`. Required guarantees:

1. **PID-scoped markers.** Every artifact the perturbation introduces
   carries `$$` (or an equivalent collision-free token) so concurrent
   runs do not clobber each other.
2. **Revert verification.** History-mutating perturbations (commits,
   tags, branch moves) MUST verify post-revert state matches
   pre-test state (e.g., `git rev-parse HEAD` equality) and fail the
   test if not.
3. **Worktree-dirty precondition.** Perturbations that mutate git
   history MUST hard-fail (not skip) if the worktree is already
   dirty, with a diagnostic naming the perturbation and instructing
   the contributor to stash or commit before re-running. Rationale:
   dirty-tree is a contributor environment problem, not a coverage
   problem; silently skipping coverage was qa-engineer's T050
   finding for prior versions of fixtures 05 and 07.
4. **Sanitiser hook.** The runner MUST scan for and remove stale
   perturbation artifacts from prior crashed runs at startup
   (`trap` does not fire on SIGKILL / OOM). The sweep covers four
   namespaces:
   - Files matching `.fixture-*-*` under the repo root (excluding
     `.git/`) — stray-file perturbations.
   - Files matching `.claude/agents/fixture-*-no-hard-rules-*.md`
     — synthetic-canonical-agent perturbations.
   - Files matching `migrations/v9.9.9-fixture-*.sh` — stub-migration
     perturbations.
   - Git tags matching `v0.0.0-fixture-*` and `v9.9.9-fixture-*` —
     history-mutating perturbation tags.

   Each removed artifact MUST be reported with a single-line
   `WARN: sanitiser removing stale fixture <kind> '<name>' (prior
   crashed run?)` so contributors learn their previous run crashed.
   The runner proceeds regardless of how many artifacts were
   removed.

**Style B — static fixture directory.** A pre-materialised tree at
`tests/release-gate/fixtures/0N-<sub-gate-name-broken>/` representing
a complete candidate the sub-gate must reject. Use Style B only when
the break is non-local (multi-file, structural, or hard to express as
a one-shot mutation). Static fixtures MUST carry a
`tests/release-gate/fixtures/0N-.../README.md` recording: which
sub-gate, what the break is, and the canonical-tree commit the
fixture was last reconciled against. Static fixtures are reconciled
against the canonical tree at every MINOR boundary.

Style A is the v1 default for all seven sub-gates. Style B is reserved
for future sub-gates whose breaks Style A cannot express.

## Adding a new sub-gate

1. Implement `gate_subgate_<name>()` in `scripts/lib/gate-runner.sh` or a dedicated `scripts/lib/gate-<name>.sh` (source it from `gate-runner.sh`).
2. Call `gate_register <name> <category> "<description>"` at the top of the file.
3. Add a positive + negative fixture under `tests/release-gate/fixtures/`.
4. Add a row to the roster table in this contract.
5. Run `scripts/pre-release-gate.sh` against the candidate to confirm the new sub-gate is invoked.

## Removing or renaming a sub-gate

Rename or removal is a breaking change to the orchestrator's diagnostic format and triggers a MAJOR bump of the gate's `version` field (cf. data-model.md state-transitions note). The `release-engineer` MUST update:
- the sub-gate function
- this contract's roster table
- the `--help` output (automatic via `gate_register`)
- `docs/v1.0.0-final-checklist.md` references
- any consuming git hook adapter under `.git-hooks/`
