# Phase 0 Research: Pre-release upgrade-regression gate

**Feature**: `007-pre-release-upgrade`
**Plan**: [plan.md](plan.md)
**Spec**: [spec.md](spec.md)
**Date**: 2026-05-14

## Open questions surfaced at end of `/speckit-clarify`

Plan-level only; none block Phase 1.

1. Exact location of the override-audit log (tamper-evident store).
2. Whether the gate supports `--only <sub-gate>` for iteration speed.
3. Whether structured (JSON) output is in scope.

Each addressed below with a Decision / Rationale / Alternatives entry.

---

## R-1: Override-audit log location

**Decision**: Append-only Markdown file at `docs/pm/pre-release-gate-overrides.md`, one row per `SKIP_PRE_RELEASE_GATE=1` event, with columns `Date | Commit SHA | Tag pushed | Operator | Reason | Gate sub-gates that would have run`.

**Rationale**:
- `docs/pm/` is the project-manager-canonical area; an audit table fits the existing append-only conventions (cf. `TOKEN_LEDGER.md`, `LESSONS.md`).
- Markdown is grep-able, diff-reviewable, and survives `git log -p` reviews — properties a binary audit log would not have.
- Tamper-evidence comes from git history itself: any modification to an existing row shows up in `git log -p docs/pm/pre-release-gate-overrides.md`. This matches the constitution's Source Authority principle (canonical artifact, human-maintained, change traceable).

**Alternatives considered**:
- JSONL append-only file: grep-able but less reviewable; `git log -p` on JSONL is harder to read. Rejected.
- External audit service / cloud bucket: out of scope for a CLI template; introduces remote dependency + secrets. Rejected.
- `.git/notes` ref: invisible to operators who don't know about notes; not synced by default `git push`. Rejected.
- Per-row append into the existing `docs/pm/CHANGES.md`: mixes release-gate overrides with project-management change entries — categorically different. Rejected.

---

## R-2: `--only <sub-gate>` flag for iteration speed

**Decision**: Ship `--only <sub-gate>` and `--skip <sub-gate>` flags from day one, with the constraint that the **strict pre-push hook ignores both flags** when the push contains a `v*` tag — i.e., release-time gating always runs every sub-gate even if the operator's last manual run was scoped.

**Rationale**:
- Iteration speed during local development matters; running the full 5-minute gate to debug one sub-gate fixture turns into "I'll just skip it." The flags make the right thing easy.
- The strict-hook scope guarantees that flags can't bypass release gating: the hook's contract is "full gate green at HEAD" regardless of what was last invoked.
- Symmetric `--only` / `--skip` lets the operator either focus on one sub-gate or exclude one known-flaky one for iteration, without inventing a different mental model later.

**Alternatives considered**:
- Manual sub-gate invocation (run `scripts/check-spdx.sh` directly, etc.): possible today but loses the gate's exit-code propagation guarantee and the fail-all aggregation. Rejected as default; `--only` is the right ergonomic.
- No flags, ship a `--quick` profile instead: hides the per-sub-gate names behind a profile; harder to reason about. Rejected.
- Configuration file with default sub-gate set: introduces a new persistent surface; YOLO; rejected for v1.

---

## R-3: Structured (JSON) output

**Decision**: **Defer**. Ship human-readable output only in v1. The spec already lists this as a deferred follow-up; planning agrees. Reconsider once a CI consumer (planner, dashboard, status-line integration) appears.

**Rationale**:
- No identified consumer needs JSON today. Premature structure-design risks getting the schema wrong.
- The single PASS/FAIL summary line + per-sub-gate stderr block is grep-able enough for manual / CI use.
- Adding `--format=json` later is non-breaking; lifting it from a deferred follow-up is cheap.

**Alternatives considered**:
- Ship JSON-by-default with a `--human` flag flipping back: inverts the current UX for no current consumer. Rejected.
- Ship both formats from day one: doubles the surface and the test matrix for negligible payoff. Rejected.

---

## R-4: Per-tag round-trip parallelisation

**Decision**: Ship **serial** per-tag round-trips in v1. Reconsider parallel execution only if/when the local five-minute budget (SC-002) breaks.

**Rationale**:
- 15-20 published tags × ~5s per round-trip = 75-100s; comfortable inside the 5-min budget with smoke-test runtime measured at ~30s in CI.
- Serial output is debuggable; parallel shell with `wait` adds fixture-isolation requirements (each round-trip uses its own tempdir already, so this is solvable, but cost grows).
- Parallelisation has a clear later trigger (the 5-min budget), and the orchestrator design (FR-001 fail-all) doesn't preclude moving to it.

**Alternatives considered**:
- GNU parallel from day one: extra dependency for marginal gain. Rejected.
- Per-tag CI matrix: would move work off the maintainer's workstation but breaks the "before committing" framing. Out of scope.
- Cache round-trip results by (source-tag-SHA, candidate-SHA) pair: real speedup over iterations but requires a cache invalidation contract. Deferred until needed.

---

## R-5: Wrapper-masking test contract (FR-002)

**Decision**: The gate's exit-code propagation is verified by a dedicated test (`tests/release-gate/test-gate-wrapper.sh`) that invokes the gate inside each of these compositions, against a known-failing fixture, and asserts non-zero exit:
1. Direct invocation: `./scripts/pre-release-gate.sh; echo $?`
2. Piped to `tail`: `./scripts/pre-release-gate.sh | tail -5; echo "outer=$?"` — outer MUST capture gate's exit via `${PIPESTATUS[0]}` in bash or `set -o pipefail` in sh.
3. Piped to `tee`: same pattern.
4. Command substitution: `out=$(./scripts/pre-release-gate.sh)` — `$?` is the gate's exit.
5. Redirected to a file: `./scripts/pre-release-gate.sh > /tmp/out.log; echo $?`.

The contract tested is: **the gate itself always exits with the right code; downstream wrappers that hide that exit are out-of-tree user error, but the gate makes no choice that consumes its own non-zero exit.**

**Rationale**:
- The rc10 surprise was: the gate (smoke-test.sh) DID exit 1; the local-CI-gates wrapper's `command | tail -5; echo "EXIT=$?"` captured `tail`'s exit (0), not smoke's.
- The fix isn't to make the gate compensate for wrappers that mask its exit — that's impossible. The fix is to (a) make the gate's exit unambiguous and (b) document the failure mode so future wrappers don't repeat it.
- The test fixture proves (a) directly; the documentation in `docs/release-engineer-manual.md` (or equivalent) handles (b).

**Alternatives considered**:
- Make the gate also write a sentinel file (`.gate-failed`) that wrappers must check: introduces a side-channel that can itself be ignored; reduces the "exit code is the contract" simplicity. Rejected.
- Refuse to run if stdout is not a TTY (to detect piping): breaks legitimate CI use. Rejected.

---

## R-6: macOS / non-GNU compatibility

**Decision**: Best-effort macOS support; gate runs on Linux are authoritative. GNU-specific flags (e.g., `find ... -printf`) are avoided in favour of POSIX equivalents wherever they exist. Where they don't, the gate emits a graceful skip with a documented reason. CI runs only `ubuntu-latest`.

**Rationale**:
- The maintainer's primary workstation is Linux; CI is Linux; the test fixtures target Linux semantics.
- macOS coverage is nice-to-have but not blocking. A maintainer on macOS can run the gate via Docker if needed.
- "Graceful skip" is preferred to "silent partial run" — any skip is logged so the audit shows it.

**Alternatives considered**:
- Hard-block on Linux (refuse to run on macOS): customer-hostile for any maintainer who occasionally works from a Mac. Rejected.
- Ship a portable shim layer (homebrew install instructions for `coreutils`): scope creep; deferred until requested.

---

## R-7: Migration placeholder detection (FR-007)

**Decision**: The gate detects silent-placeholder fallbacks in two ways:
1. **Post-run file scan**: after each `migrations/*.sh` standalone run, grep the affected files for the literal string `**TODO**: the rc9 agent-contract schema requires this section.` (and any future migration's analogous placeholder marker — to be enumerated by the gate's `lib/gate-migrations.sh`).
2. **Decisions-log attribution scan**: parse `docs/DECISIONS.md` (the migration's append target) for entries written during the run, and fail if any has the `placeholder` source attribution.

Both checks must pass for the migration sub-gate to PASS. Either failure names the migration and the affected files.

**Rationale**:
- The dual check catches both the "placeholder body landed in file" and the "decisions-log says placeholder" cases, which can drift independently if a future migration only logs and doesn't change file contents.
- Scanning literal strings is brittle but enumeratable; the gate's `lib/gate-migrations.sh` keeps the list explicit so adding a new migration's marker is a one-line edit.
- Filing as an upstream issue (#159) noted the silent fallback; the gate is the fix.

**Alternatives considered**:
- Make migrations themselves exit non-zero on placeholder fallback: better upstream fix but changes contract for downstream operators running migrations standalone. Filed as #159 follow-up; not duplicated here.
- AST-walk Markdown to detect TODO blocks: heavier dependency for minimal gain over literal-string scan. Rejected for v1.

---

## R-8: Advisory-pointer scanner scope (FR-006)

**Decision**: The scanner reads `scripts/upgrade.sh`, `scripts/scaffold.sh`, and every `migrations/*.sh`, extracts every string matching the regex `(?:migrations|scripts|docs|\.claude/agents|\.github)/[A-Za-z0-9._/-]+\.(?:sh|md|yml|yaml|json|py)`, deduplicates, and tests each path with `[ -e "$candidate_tree/$path" ]`. Any missing path fails the sub-gate with the source line + the missing path.

**Rationale**:
- The rc10 dangling pointer (`migrations/v1.0.0-rc10.sh`) would have been caught by this regex against the candidate tree.
- Limiting to top-level project directories (`migrations/`, `scripts/`, `docs/`, `.claude/agents/`, `.github/`) avoids false positives from generic references like `path/to/file`.
- Including `.py`, `.sh`, `.md`, `.yml`, `.yaml`, `.json` covers the file types templates reference operationally.

**Alternatives considered**:
- Scan all `*.md` and `*.sh` files: broader coverage but produces noise (e.g., paths inside code-block examples). Rejected.
- Parse heredocs / printf strings semantically: heavyweight and language-specific. Rejected.
- Require an explicit `# advisory-pointer:` annotation marker on every operator-facing path string: discipline burden + retroactive markup of existing code. Rejected.

---

## R-9: Force-moved tag handling (FR-003 edge case)

**Decision**: For each tag in scope, the gate resolves the tag's current commit via `git rev-parse <tag>^{commit}` at run start and pins fixtures to that SHA. If the tag is force-moved mid-run (between resolve and use), the gate treats the new SHA as authoritative on the next invocation and does not cache stale fixtures across runs.

**Rationale**:
- The rc9 VERSION-bump-correction force-move scenario (already in repo memory) showed force-moves happen.
- Pinning to the current SHA at run start gives a stable per-run snapshot; mid-run drift is rare enough that re-running the gate is acceptable.

**Alternatives considered**:
- Reject force-moved tags as poison: breaks the rc9-VERSION-correction pattern that's already in use. Rejected.
- Cache fixtures by tag-SHA across runs: speedup for repeated runs but cache-invalidation complexity. Deferred per R-4.

---

## R-10: Pre-push hook detection of annotated `v*` tag

**Decision**: The hook inspects `stdin` per the git pre-push protocol (`<local_ref> <local_sha> <remote_ref> <remote_sha>` lines) and triggers strict mode if any line's `remote_ref` matches `refs/tags/v[0-9]*` AND the local-tag object is annotated (test via `[ "$(git cat-file -t <sha>)" = "tag" ]`).

**Rationale**:
- The pre-push protocol is well-defined and stable; no need to invent a new detection mechanism.
- "Annotated v* tag" matches the existing release policy (`docs/versioning.md`: rc and stable tags are annotated).
- Lightweight tags MUST NOT be used for releases per the policy, so excluding them is safe.

**Alternatives considered**:
- Trigger strict on ANY tag push: catches non-release tags (e.g., personal markers). Rejected as overreach.
- Trigger strict only on `v[0-9]+\.[0-9]+\.[0-9]+(-rc[0-9]+)?$` (exact SemVer): more restrictive, possibly miss future cohorts (e.g., `v2-beta1` if pattern drift). Decided to keep broader `v[0-9]*` glob and rely on annotation check.

---

## R-11: Override audit-log enforcement

**Decision**: When `SKIP_PRE_RELEASE_GATE=1` is set on a strict-mode push, the hook MUST:
1. Append an audit row to `docs/pm/pre-release-gate-overrides.md` BEFORE the push completes (via a one-line `printf >> ...`);
2. Print the appended row to stderr so the operator sees what was logged;
3. Refuse to bypass if the audit log is unwritable (read-only filesystem, missing path) — fall back to blocking the push.

**Rationale**:
- Logging-before-bypass guarantees the audit trail can't be skipped; logging-after-bypass loses the trail when the operator force-quits.
- Refusing to bypass on unwritable log preserves the "no silent override" invariant; the operator's recovery is to fix the log path, not to ignore it.

**Alternatives considered**:
- Log to git-notes: not synced on push, not visible without `git config notes.displayRef`. Rejected.
- Log to a remote service: out-of-scope dependency. Rejected.
- Make override require interactive confirmation (`y/N` prompt): hostile to scripted release flows; the env-var-with-audit pattern is the right level of friction. Rejected.

---

## Summary

| ID | Topic | Status |
|---|---|---|
| R-1  | Override-audit log location | RESOLVED — `docs/pm/pre-release-gate-overrides.md`, append-only Markdown table. |
| R-2  | `--only` / `--skip` flag | RESOLVED — ship both; strict hook ignores them when pushing `v*` tag. |
| R-3  | Structured (JSON) output | DEFERRED — explicit Assumption in spec; revisit when CI consumer appears. |
| R-4  | Per-tag round-trip parallelisation | RESOLVED — serial in v1; trigger for parallel is 5-min budget break. |
| R-5  | Wrapper-masking test contract | RESOLVED — dedicated test invokes the gate inside 5 wrapper compositions. |
| R-6  | macOS compatibility | RESOLVED — best-effort; Linux authoritative; CI on ubuntu-latest only. |
| R-7  | Migration placeholder detection | RESOLVED — dual check: file-scan + decisions-log-attribution scan. |
| R-8  | Advisory-pointer scanner scope | RESOLVED — top-level dirs + 6 file types; regex enumerated. |
| R-9  | Force-moved tag handling | RESOLVED — resolve to commit at run-start; no cross-run cache. |
| R-10 | Hook detection of annotated `v*` | RESOLVED — pre-push stdin parse + annotated-object check. |
| R-11 | Override audit-log enforcement | RESOLVED — log-before-bypass; refuse on unwritable log. |

All `NEEDS CLARIFICATION` items from Technical Context resolved. Ready for Phase 1.
