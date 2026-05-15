# Code review — blocker #1 (rc-to-rc pre-bootstrap, FW-ADR-0013)

- **Date:** 2026-05-15
- **Branch:** `fix/blocker-1-rc-to-rc-prebootstrap`
- **Commit under review:** `c7599b5` — `fix(migrations): add v1.0.0-rc13 pre-bootstrap for rc-to-rc cliffs (FW-ADR-0013)`
- **Reviewer:** `code-reviewer`
- **Mode:** Per-CL technical review under IEEE 1028 § 5 (escalated from walk-through because the change touches the upgrade-contract — Hard-Rule-#4-adjacent path with elevated customer scrutiny: "the upgrade is always buggy").
- **Author / dispatchee:** `software-engineer`
- **Net judgment: APPROVED-WITH-CHANGES (non-blocking; ADR + release-prereq notes).**

## Scope reviewed

1. `migrations/v1.0.0-rc13.sh` — new file, 285 lines, executable, in commit `c7599b5`.
2. `docs/adr/fw-adr-0013-rc-to-rc-pre-bootstrap.md` — currently untracked (in working-tree / stash; 616 lines, `status: proposed`). Reviewed for design soundness; status flip recommendation in §"ADR status" below.
3. Routing-trailer compliance on `c7599b5`.
4. Hard Rule #8 file-boundary check on the commit.

## Evidence collected

- **Structural diff** vs `migrations/v0.14.0.sh` (the stated source-of-truth, lines 42–277): single contiguous block diff shows the intended changes only.
  - Header rewritten to cite FW-ADR-0013, dogfood-2026-05-15 evidence, and the rc-to-rc cliff.
  - Pre-bootstrap block byte-identical to v0.14.0.sh's lines 62–277 modulo two strings: audit-row `(migration v0.14.0)` → `(migration v1.0.0-rc13)`; success echo `cross-MAJOR safe` → `rc-to-rc structural-rewrite safe`.
  - Manifest-synthesis tail (v0.14.0.sh lines 279–346) correctly omitted per ADR § "Migration file" item 2.
  - Trailing `exit 0` added (v0.14.0.sh doesn't need one because the manifest block runs to EOF). Correct.
- **`bash -n` syntax check:** PASS.
- **`shellcheck -s bash`:** clean.
- **Smoke tests (reviewer-side, scratch dir `/tmp/rc13-smoke`):**
  1. project == upstream, no baseline → exit 0, no writes, no artefact. PASS.
  2. local-edit on `scripts/upgrade.sh`, no FORCE → exit 2, schema-v1 block artefact written, project file untouched. PASS.
  3. local-edit + `SWDT_PREBOOTSTRAP_FORCE=1 SWDT_PREBOOTSTRAP_FORCE_REASON=test-r3` → exit 0, audit row appended with marker `(migration v1.0.0-rc13)` in `Commit SHA` slot, project file atomic-replaced to upstream content, block artefact cleared. PASS.
  4. baseline-unreachable (no WORKDIR_OLD, files differ) → exit 2, block artefact with `"reason": "baseline-unreachable"`. PASS.
- **`scripts/lint-routing.sh --files c7599b5 --summary`:** `lint-routing: 0 warnings, 0 errors`.
- **`git diff main...c7599b5 --stat`:** `migrations/v1.0.0-rc13.sh | 285 +++++++` — single file, no edits to `scripts/upgrade.sh`, `VERSION`, `CHANGELOG.md`, `TEMPLATE_VERSION`, or any other framework-managed surface.
- **`git log --format=fuller c7599b5`:** body carries `Routed-Through: software-engineer` trailer.
- **Audit-log column count:** force-path row emits 7 pipe-delimited columns (`Date | Gate | Commit SHA | Tag pushed | Operator | Reason | Sub-gates`), matching `docs/pm/pre-release-gate-overrides.md` schema-v2 header.
- **rc2 driver compatibility:** confirmed `git show v1.0.0-rc2:scripts/upgrade.sh | sed -n '78,138p'` carries a pre-sync migration runner block that sources `$workdir/new/migrations/<v>.sh` and exports the same envs (`PROJECT_ROOT`, `WORKDIR_NEW`, `WORKDIR_OLD`). The architectural premise of the fix (pre-sync hook reachable from the OLD driver) holds for the rc2 baseline.

## Review priorities — findings

### 1. Correctness vs the ADR

Match is faithful. Trigger predicate (tag iteration past `v1.0.0-rc13`), atomic-rename semantics (`install -m` after `cp`-cmp-skip from the OLD driver), exit codes (`0` / `2` only, `0` for noop and proceed, `2` for refuse), env-var threading (`SWDT_PREBOOTSTRAP_FORCE`, `SWDT_PREBOOTSTRAP_FORCE_REASON`), audit-row shape (with `(migration v1.0.0-rc13)` marker), and refusal artefact (`.template-prebootstrap-blocked.json` schema v1) all match the ADR's "Interface decisions (binding)" and "Migration file" sections.

### 2. Correctness vs `migrations/v0.14.0.sh` prior art

All inter-file diffs are intentional and ADR-justified. No silent drift. The `IFS` save/restore pattern (`oldIFS="$IFS"` … `IFS="$oldIFS"`), the `mktemp` + `mv` atomic block-artefact write, and the sort-on-path for deterministic JSON output are preserved verbatim. The migration is therefore reviewable as "v0.14.0 minus manifest-tail, with marker strings swapped" — the exact review surface the ADR promised.

### 3. FW-ADR-0010 interface conformance

Verified end-to-end via smoke tests:
- Audit-row columns match schema v2.
- Force-with-unwritable-log refuses (exit 2) per FW-ADR-0010 invariant — preserved at lines 170–174 of the migration.
- Block-artefact JSON schema v1 produced verbatim (`version`, `generated`, `reason_summary`, `blocked[].path/project_sha/baseline_sha/upstream_sha/reason`).
- `reason_summary` resolution (`local-edit` / `baseline-unreachable` / `mixed`) preserves v0.14.0.sh semantics.

### 4. Routing trailer compliance

PASS. `Routed-Through: software-engineer` present; lint-routing reports 0/0.

### 5. Hard Rule #8 boundary

PASS. Single-file commit (`migrations/v1.0.0-rc13.sh`). No edit to `scripts/upgrade.sh`, `VERSION`, `CHANGELOG.md`, or any framework-managed file outside the ADR-blessed scope.

### 6. Hard Rule #3 / overall safety

PASS. Idempotency exercised under both noop and post-force-replace scenarios. Atomic-replace pattern uses `install` (single-step inode swap on the target path under POSIX semantics, with mode preservation), matching the v0.14.0 prior art.

## Blocking findings

**None.** Migration is safe to merge as-is.

## Non-blocking findings (file as separate PRs or roadmap items)

### NB-1 — Release-prerequisite: the migration only activates once a `v1.0.0-rc13` tag exists in the candidate

The migration runner (`scripts/upgrade.sh` lines 875–916, both in the rc12 candidate and in the rc2 prior art) iterates `git -C "$workdir/new" tag -l 'v*' | semver_sort_tags`. Files in `migrations/` are only dispatched when their name matches an iterated tag. So `migrations/v1.0.0-rc13.sh` is dormant code until upstream cuts a `v1.0.0-rc13` tag. SE's smoke tests evidently used a scratch fixture with a synthetic tag; in production this means a downstream upgrading to a SHA / branch on a candidate that does not yet carry the rc13 tag will NOT receive the pre-bootstrap.

- **Why non-blocking:** the ADR § "Trigger predicate" explicitly describes this contract; the file's purpose is to be picked up when its tag is cut, and the release-engineer cuts that tag as part of the rc13 release. This is "as designed."
- **Action:** `release-engineer` to confirm the rc13 tag cut is the immediate next gate in the v1.0.0 stabilisation sequence (per `docs/pm/dogfood-2026-05-15-results.md`). Until the tag exists, no rc-baseline downstream is protected; meta-pointer must not advance past rc12 until rc13 is tagged AND a real-fixture dogfood run on the rc2→rc13 path passes.
- **Suggested wording for the rc13 release notes:** "This release introduces `migrations/v1.0.0-rc13.sh`, the per-cliff pre-bootstrap migration that closes blocker-1 from dogfood-2026-05-15. The migration activates on any upgrade path that crosses `v1.0.0-rc13`."

### NB-2 — `docs/pm/pre-release-gate-overrides.md` Gate-row description should cite the rc13 migration site

The audit-log header text at `docs/pm/pre-release-gate-overrides.md` lines 15–20 names only `scripts/upgrade.sh` self-bootstrap and `migrations/v0.14.0.sh` as `Gate: pre-bootstrap` sites. Once rc13 ships, that text becomes stale.

- **Why non-blocking:** the audit log's column schema is unchanged; the documentation note is editorial.
- **Action:** small `tech-writer` follow-up — append `migrations/v1.0.0-rc13.sh` to the list at lines 15–20 of `docs/pm/pre-release-gate-overrides.md`. Single-line patch, can ride the rc13 release commit.

### NB-3 — Consider naming the de-dup boundary in `migrations/v0.14.0.sh` too

The new migration's header (lines 43–50) explicitly documents the intentional non-extraction of `scripts/lib/prebootstrap.sh` and forbids refactor without superseding FW-ADR-0013. `migrations/v0.14.0.sh` has no such marker, so a future reader looking at v0.14.0 first might attempt the de-dup without seeing the rc13-side warning.

- **Why non-blocking:** the ADR encodes the rule; lazy code-readers are a separate problem and a comment in v0.14.0.sh is editorial.
- **Action:** optional one-line comment addition to `migrations/v0.14.0.sh` near line 42 pointing to FW-ADR-0013's de-dup-boundary clause. Could be folded into the same rc13 commit, but on a separate framework-touched file it's cleaner as a follow-up PR.

### NB-4 — Future hardening: explicit floor check

The ADR § "Negative / trade-offs accepted" notes "the supported floor (v1.0.0-rc1) is implicit, not enforced in code." Today this is fine — projects below the floor naturally route through `baseline-unreachable`. A future hardening pass could add an explicit `OLD_VERSION` floor refusal for clearer diagnostics, but no current bug exists.

- **Action:** file as a roadmap item, not a PR.

## ADR review (FW-ADR-0013)

The ADR is well-structured: MADR 3.0 shape, full Three-Path Rule with Options M/S/C plus rejected variants, explicit binding sections (trigger predicate, interface decisions, FW-ADR-0010 inheritance), and a verification section that names a concrete success signal. The decision rationale (M + out-of-range refusal hybrid) is defensible:

- Option S's signature-marker idea correctly identified as introducing a load-bearing comment pattern → reject.
- Option C's shim-based redesign correctly identified as not fixing the rc2-baseline-today problem (the shim has to arrive via the same migration mechanism Option M uses) → reject.
- Hybrid out-of-range refusal correctly defers to FW-ADR-0010's existing `baseline-unreachable` path → no new operator-facing concept.

The ADR's "Implementation notes for software-engineer" section was faithfully followed by the commit. No drift.

### ADR status

**Recommendation: flip `status: proposed` → `status: accepted` on merge.**

The ADR file is currently in working-tree / stash and not part of the reviewed commit `c7599b5`. Treating the status flip as the merge-time action is correct per project convention: the ADR is accepted by virtue of the implementation passing review and being merged. SE (or whoever stages the ADR for commit) should:

1. Restore the ADR from stash (`git checkout stash@{0} -- docs/adr/fw-adr-0013-rc-to-rc-pre-bootstrap.md`) or otherwise stage the file.
2. Edit line 4: `status: proposed` → `status: accepted`.
3. Add an "Accepted: 2026-05-15" line under § "Status" alongside "Proposed: 2026-05-15".
4. Commit (separately or as a fixup on the same branch) with routing trailer `Routed-Through: architect` (ADRs are architect-owned writes; tech-lead's `agent-push` qualifier is the alternative if architect is not in the loop).

I am NOT modifying the ADR file directly from this review session because (a) it lives in working-tree / stash on a different branch than the one I'm in, and (b) ADR authorship/edits belong to `architect`, not `code-reviewer`. The status flip is mechanical and acknowledgement-grade, not a re-decision, so it does not need a fresh architect dispatch — but the file edit itself should be done by whoever stages the ADR for commit (tech-lead or SE acting under tech-lead's direction, with an appropriate routing trailer).

## Customer-strategic-frame note

The customer's "the big blocker to going to v1.0.0 in my view is that the upgrade is always buggy" framing was kept in view through this review. Findings posture:

- The change is **a strict improvement** to the upgrade flow: it closes a known regression class (mid-run bash syntax error from in-place script overwrite during sync) and inherits a customer-already-accepted refusal posture (FW-ADR-0010) for local-edit protection.
- The change introduces **no new operator-facing surface** (no new flags, env vars, exit codes, artefact schemas). Operators already trained on FW-ADR-0010's pre-bootstrap on the v0.x→v1.x cliff get the same UX here.
- The de-duplication catch-22 between this migration and `v0.14.0.sh` is **structurally documented** (ADR § "Implementation notes" + migration header lines 43–50). A future reviewer will not be tempted to "clean up" the duplication and re-open the bug class.
- The single **non-mechanical risk** is NB-1 (the tag-cut precondition). That is a release-engineering gate, not a code defect, and is naturally handled by the next rc13 tag cut.

I do not see a fresh upgrade-class regression risk in this commit. The remaining quality concern for the v1.0.0 release is whether the rc13-tagged candidate, once cut, passes a full dogfood pass on the rc2 → rc13 path against the alpha/scaffold fixture; that is QA's gate, not this review's.

## Approval

Approved. SE may proceed with:

1. (Optional) staging the FW-ADR-0013 file with `status: accepted` per § "ADR status" above.
2. Coordinating with `release-engineer` to cut the `v1.0.0-rc13` tag (NB-1 release-prereq).
3. Coordinating with `qa-engineer` for a full rc2 → rc13 dogfood verification once the tag is cut.

Non-blocking items NB-1 through NB-4 can be filed as follow-ups; none of them gate the merge of `c7599b5`.
