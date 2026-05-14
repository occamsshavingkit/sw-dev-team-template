# Feature Specification: Pre-release upgrade-regression gate

**Feature Branch**: `007-pre-release-upgrade`
**Created**: 2026-05-14
**Status**: Draft
**Input**: User description: "we need a new release test before committing that catches upgrade errors. Each new release canddidate keeps failing on things that look like we should have caught to me."

## Clarifications

### Session 2026-05-14

- Q: When a sub-gate fails, does the gate stop or keep going? → A: Fail-all — run every sub-gate to completion, report every failure, exit non-zero if any failed.
- Q: Which prior tags does the gate exercise as upgrade sources? → A: Every published tag ever (full historical coverage; no scope cap by track or recency).
- Q: How strict is the pre-push hook? → A: Strict when pushing an annotated `v*` tag (blocks until gate passes); advisory (WARN-only) on all other pushes.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - One-command pre-tag readiness check (Priority: P1)

Before tagging a new release candidate, the maintainer runs a single command and gets a single-line PASS or FAIL with a specific per-sub-gate diagnostic on failure. PASS means the candidate is upgrade-safe from every prior on-track release tag; FAIL names which gate caught the regression and where to look.

**Why this priority**: Today the maintainer relies on a wrapped local smoke-test invocation whose exit code can be silently masked by the wrapping (the rc10 cycle hit exactly this: smoke-test reported "162 passed, 1 failed" with the wrapper showing `EXIT=0`, so the regression was only caught when PR CI ran the unwrapped smoke-test). The single-command gate replaces the ad-hoc wrapper and removes the only place where an exit-1 can disappear before commit.

**Independent Test**: Run `scripts/pre-release-gate.sh` (or equivalent single entry point) on a known-good template tree → PASS, exit 0; deliberately break one assertion (e.g., touch a tracked file to invalidate the manifest) → FAIL, exit non-zero, with the offending sub-gate named in the output.

**Acceptance Scenarios**:

1. **Given** the template tree is at a clean candidate state, **When** the maintainer runs the pre-release gate, **Then** every sub-gate runs to completion, the summary line reads `PASS` and the process exits 0.
2. **Given** any single sub-gate is failing (smoke-test, lint-agent-contracts, check-spdx, advisory-pointer scan, migration standalone run), **When** the maintainer runs the pre-release gate, **Then** the process exits non-zero, the summary names the failing sub-gate, and the offending diagnostic is shown without requiring a second invocation with a different flag.
3. **Given** a sub-gate exits non-zero, **When** the gate's summary is captured by any reasonable wrapper (pipe, tee, redirect, command substitution), **Then** the gate's exit code is propagated unchanged to the caller; no wrapper can silently turn an exit-1 into a 0.

---

### User Story 2 - Upgrade-path coverage from every prior on-track tag (Priority: P2)

The gate exercises `scaffold → upgrade to current candidate → verify` for every prior on-track release tag, not only the rc3-era fixture that the current smoke-test hardcodes. Each prior tag that downstream projects might still be stamped at contributes one round-trip assertion.

**Why this priority**: The rc8→rc9 upgrade exercise surfaced 10 issues across 7 downstream projects despite the rc3→rc9 fixture passing in CI. Coverage was the limiting factor: rc3 is no longer a representative source, and intermediate rc tags carried customisations the rc3 fixture doesn't reproduce. Iterating over the full prior-tag set turns "we tested one upgrade path" into "we tested every upgrade path a real downstream might hit."

**Independent Test**: List the prior on-track tags currently exercised by the gate; confirm coverage matches the policy (e.g., "every `v1.0.0-rc*` tag on `main` ancestry"); deliberately break one historical migration step; confirm the gate's per-tag round-trip detects the break on the specific tag and names it in the failure summary.

**Acceptance Scenarios**:

1. **Given** N prior on-track tags exist in the repository, **When** the gate runs, **Then** N scaffold+upgrade+verify round-trips execute; the summary reports `N rounds passed`, or names the specific tag whose round-trip failed.
2. **Given** a tag was force-moved (e.g., a VERSION-bump correction post-publish), **When** the gate encounters that tag, **Then** the round-trip uses the tag's current commit and either passes or fails on that commit's content; the gate does not skip force-moved tags silently.

---

### User Story 3 - Stale-pointer and silent-placeholder catches (Priority: P3)

The gate fails when the candidate tree contains internal references that won't resolve post-tag (advisory strings, documentation, migration scripts) and when any migration silently falls back to a placeholder body during the gate's standalone migration runs.

**Why this priority**: The rc10 cycle shipped with `scripts/upgrade.sh` printing an advisory pointing at `migrations/v1.0.0-rc10.sh` even though no such migration exists in the candidate (filed as upstream issue #158). Similarly, running `migrations/v1.0.0-rc9.sh` standalone with mis-set `WORKDIR_NEW` silently produced TODO-placeholder bodies (filed as #159). Both are caught only by the operator noticing the symptom after-the-fact; a pre-tag gate would have failed loud.

**Independent Test**: Add a deliberate `# Backfill per migrations/v1.0.0-rc99.sh` string to `scripts/upgrade.sh`; run the gate; confirm it fails and names the dangling path. Re-run a migration with a deliberately-empty `WORKDIR_NEW`; confirm the gate flags the placeholder-bodied output instead of accepting it.

**Acceptance Scenarios**:

1. **Given** an advisory string in `scripts/upgrade.sh` references a path that does not exist in the candidate tree, **When** the gate runs, **Then** the gate fails and names both the advisory string and the missing path.
2. **Given** any `migrations/*.sh` invocation produced a TODO-placeholder body during the gate's per-migration run, **When** the gate evaluates that run, **Then** it fails with a diagnostic naming the migration and the affected file(s).

---

### Edge Cases

- **Tag deprecation policy**: if a prior rc has been retracted (force-deleted on the remote), the gate should treat it as out-of-scope rather than fail because the tag no longer fetches.
- **Tag force-move during gate run**: if the maintainer force-moves a tag between candidate prep and gate invocation, the gate should detect the SHA drift and re-bootstrap its fixture rather than caching a stale tree.
- **Brand-new rc with no prior tags**: if no prior tags are reachable at all, the gate's upgrade-path sub-gate reports `0 rounds (no prior tags)` and does not fail. With even one prior tag (including pre-1.0 `0.y.z` or a prior MAJOR), the gate attempts the round-trip and reports failure if the upgrade path is unsupported.
- **Cross-MAJOR upgrade attempt**: the gate's per-tag round-trip will attempt e.g. `v0.10.0 → v1.0.0-rcN`. If `scripts/upgrade.sh` rejects or breaks on that path, the gate fails loud — surfacing the cross-MAJOR gap as a release-blocking finding rather than a silent skip.
- **Migration introduced in the candidate itself**: a `migrations/v1.0.0-rcN.sh` shipping for the first time in the candidate must be exercised against fixtures from rc-(N−1), not against itself.
- **Long-running gate**: if the per-tag round-trip becomes too slow at large N, the gate must remain fast enough to be habitual; otherwise maintainers will skip it.
- **Wrapper masking**: a maintainer who runs the gate inside `tail`, `head`, `tee`, or a command substitution must still get the exit code propagated; gate exit semantics must survive realistic shell composition.
- **Gate runs against a dirty worktree**: the gate should refuse to declare PASS on a dirty worktree (uncommitted changes mean the tagged commit will not match what was tested).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide a single command (the "pre-release gate") that runs every release-blocking sub-gate sequentially to completion (fail-all semantics — a failing sub-gate MUST NOT short-circuit later sub-gates) and exits 0 if and only if every sub-gate exits 0. (Aggregate exit-code propagation against external wrappers is FR-002's responsibility; this requirement owns the run-all-to-completion semantics.)
- **FR-002**: System MUST propagate any sub-gate's non-zero exit code as the gate's overall exit code; the gate MUST NOT consume, swallow, or remap a non-zero sub-gate exit through pipes, command substitution, or `tail`/`head`/`tee` chaining. When multiple sub-gates fail, the overall exit code is non-zero and the per-sub-gate detail block lists every failing sub-gate (not only the first). (FR-001 guarantees every sub-gate has actually been executed before this aggregation runs.)
- **FR-003**: System MUST exercise `scaffold → upgrade --target <candidate> → upgrade --verify` for every published release tag reachable in the local clone, with no scope cap by track, recency, or MAJOR version. A round-trip MUST be attempted from every tag, including pre-1.0 `0.y.z` stable tags and rc tags from any prior MAJOR. A failed round-trip on a cross-MAJOR or otherwise-unsupported upgrade path MUST surface as a sub-gate failure (not a silent skip), so cross-version upgrade gaps become release-blocking findings rather than latent surprises.
- **FR-004**: System MUST run `scripts/lint-agent-contracts.sh --canonical-only` against the candidate tree and fail if any error is reported.
- **FR-005**: System MUST run `scripts/check-spdx.sh --summary` against the candidate tree and fail if any file is reported as missing an SPDX header.
- **FR-006**: System MUST scan every advisory or operator-facing message in `scripts/upgrade.sh`, `scripts/scaffold.sh`, and every `migrations/*.sh` for path references (`migrations/<...>`, `.claude/agents/<...>`, `scripts/<...>`, `docs/<...>`) and fail if any referenced path does not exist in the candidate tree.
- **FR-007**: System MUST exercise every `migrations/*.sh` script standalone against a freshly-scaffolded fixture with `WORKDIR_NEW` set to the candidate tree, and fail if any migration emits a `TODO`-placeholder body or writes a `decisions_log` entry whose source attribution is `placeholder` rather than `from upstream`.
- **FR-008**: System MUST refuse to report PASS on a worktree with uncommitted changes; the maintainer must commit, stash, or stage every change before the gate can succeed.
- **FR-009**: System MUST emit a single PASS or FAIL summary line at the end of every run, and on FAIL MUST also emit a per-sub-gate detail block naming which sub-gate caught the regression and the most-relevant diagnostic.
- **FR-010**: System MUST be documented in the rc-tag release checklist as a precondition for tagging; the checklist MUST cite the gate by its canonical script name and exit-code contract.
- **FR-011**: System MUST be invocable both manually by the maintainer and from a git pre-push hook supplied in the template. The hook MUST be **strict when the push includes an annotated `v*` tag** — it MUST block the push (non-zero pre-push exit) until the gate runs to PASS for the candidate at HEAD. For all other pushes (feature branches, `main` without a tag, branch deletions), the hook MUST be **advisory**: it emits a stderr warning when the gate is skipped or has not run successfully against HEAD, but does NOT block the push. An explicit override (e.g., `SKIP_PRE_RELEASE_GATE=1` env var) MAY bypass the strict block, but its use MUST be logged to a tamper-evident location so retroactive auditing can show that a `v*` tag pushed without a green gate did so by deliberate override.
- **FR-012**: System MUST complete a full run in under five minutes of wall-clock time on a typical Linux maintainer workstation with the prior-tag set already fetched into the local clone, including the N per-tag round-trips and the per-migration standalone runs.
- **FR-013**: System MUST include a `readme-current` sub-gate that fails when `README.md` neither mentions the current `VERSION` literally NOR was modified since the most recent `v*` tag reachable from `HEAD`. Rationale: the README must reflect the release being tagged; customer-authorised 2026-05-14 after the rc8–rc10 cycle shipped stale README content.

### Constitution Alignment *(mandatory)*

- **CA-001**: Source authority MUST be classified for affected artifacts: the gate script and its test fixtures are canonical (framework-managed); per-run logs are ephemeral; any per-rc audit record (e.g., "pre-release gate green at SHA X on date Y") is canonical and lives under `docs/pm/`.
- **CA-002**: Customer-owned requirements MUST cite a recorded customer answer, a documented assumption, or one queued atomic question. The driving customer statement here is "we need a new release test before committing that catches upgrade errors" (2026-05-14, this session's `/speckit-specify` invocation); assumptions below cover defaulted scope.
- **CA-003**: Framework-managed file edits MUST be marked as framework work and require explicit authorization unless this feature is a template-maintenance task. This feature IS a template-maintenance task and edits framework-managed files under `scripts/`, `migrations/`, `docs/`, `.github/`, and the rc-tag release checklist; downstream consumers receive the gate via the next rc upgrade.
- **CA-004**: Cross-AI or generated-output changes MUST preserve existing role authority and identify canonical inputs. The gate is owned by `release-engineer` (SWEBOK V4 ch. 6 Operations Delivery); per-tag round-trip semantics are co-owned with `qa-engineer`; advisory-pointer scanning is co-owned with `code-reviewer`. Canonical inputs are the candidate tree, the published prior-tag set, and the `.template-customizations` of any synthetic fixture used.

### Key Entities

- **Pre-release gate**: the single entry-point script that orchestrates all sub-gates; emits one PASS/FAIL summary plus per-sub-gate detail on failure.
- **Sub-gate**: an individual release-blocking check (upgrade-path round-trip, lint-agent-contracts, check-spdx, advisory-pointer scan, migration standalone run, worktree-clean check, etc.); each sub-gate has its own exit contract and its own diagnostic format.
- **Source tag**: any published release tag the gate exercises as an upgrade source; defined as every tag reachable in the local clone, with no scope cap by track, recency, or MAJOR (cross-MAJOR included).
- **Round-trip**: one scaffold-from-source-tag → upgrade-to-candidate → verify-clean cycle; one round-trip per source tag. A failed round-trip is a sub-gate failure, including cross-MAJOR paths that may surface upgrade-script gaps.
- **Advisory pointer**: any operator-facing string in candidate scripts that names a file path; the gate must verify every such path resolves in the candidate tree.
- **Migration standalone run**: one invocation of a `migrations/*.sh` script with `WORKDIR_NEW` set to the candidate tree, used by the gate to detect silent-placeholder fallbacks.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Across the three rc cycles following the gate's first ship, the count of regressions caught only by post-tag operator reports drops to zero, where "regression" means "an issue file-able as a framework-gap that the gate's sub-gate scope covers."
- **SC-002**: The maintainer completes a full pre-release-gate run on a typical Linux workstation with the prior-tag set already fetched into the local clone in under five minutes of wall-clock time, end-to-end, with no manual setup beyond a clean worktree.
- **SC-003**: 100% of the four representative regressions from the rc8→rc10 window (smoke-test exit-code mask, dangling `migrations/v1.0.0-rcN.sh` advisory pointer, SPDX-header-missing on a new script, lint-agent-contracts failure on a `sme-template`-derived file) are caught by the gate when reproduced against the gate's test fixtures.
- **SC-004**: After the gate ships, zero `migrations/*.sh` standalone runs in any rc cycle produce a `placeholder` `decisions_log` entry; every migration backfills from an upstream-attributed source or fails loud.
- **SC-005**: After the gate ships, the rc-tag release checklist references the gate as a numbered precondition; auditing the most recent three rc tags shows the gate was run on each (recorded in `docs/pm/`).

## Assumptions

- The gate runs against a local checkout of the template repository; remote-only fetches are not required during a normal run, though the gate may fetch tags if the local clone is shallow.
- "Prior tags" means every published tag reachable in the local clone, with no scope cap by track, recency, or MAJOR. Cross-MAJOR upgrades are explicitly in scope: if `scripts/upgrade.sh` fails on `v0.10.0 → v1.0.0-rcN`, the gate exposes that gap rather than skipping it. Deprecated or retracted tags (force-deleted from the remote) are out of scope only because they no longer fetch.
- "Under five minutes" assumes the maintainer's machine has the prior-tag set already fetched and is not contending with parallel CI on the same checkout; CI mirroring of the gate is out of scope for this spec.
- Strict severity is the default: any sub-gate exit-non-zero blocks the gate; there is no advisory-only severity tier. If a sub-gate is known-flaky, it must be hardened or removed, not demoted.
- The gate is the maintainer's release-engineer-side check; downstream-project upgrade flows already have their own per-project verification via `scripts/upgrade.sh --verify` and are not in scope here.
- The pre-push git hook is shipped as a template artefact with **scoped strict semantics**: block when the push includes an annotated `v*` tag (release moment); advisory (WARN-only) on all other pushes. Operators can bypass the strict block with an explicit override; the override is logged so audit shows when a tag pushed without a green gate.
- The gate emits human-readable output by default; structured (JSON) output is desirable for CI integration but is a follow-up, not in scope for the first ship.
- Existing local "CI gates" wrappers that mask exit codes (the source of the rc10 smoke-test surprise) are out-of-tree and not framework-managed; this spec does not enforce their removal, only that the gate itself cannot be wrapped into silence.

## Dependencies

- `scripts/smoke-test.sh` (existing) provides the per-tag round-trip primitive that the upgrade-path sub-gate orchestrates over the full prior-tag set.
- `scripts/lint-agent-contracts.sh` (existing) provides the canonical-only contract check the gate reuses.
- `scripts/check-spdx.sh` (existing, shipped in rc10) provides the SPDX header gate the gate reuses.
- `migrations/*.sh` (existing) are exercised standalone by the migration sub-gate; per-migration `WORKDIR_NEW` setup logic must be available either inside the gate or as a shared helper.
- The rc-tag release checklist (existing, `docs/v1.0.0-final-checklist.md` and similar) is updated to reference the gate as a precondition.
