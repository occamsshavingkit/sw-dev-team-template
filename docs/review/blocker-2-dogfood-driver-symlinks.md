# Code review — blocker #2 (dogfood driver symlink crash)

- **Date:** 2026-05-15
- **Branch:** `fix/blocker-2-dogfood-driver-symlinks`
- **Commit under review:** `c5bd106` — `fix(release-gate): preserve absolute-target symlinks in dogfood driver`
- **Reviewer:** `code-reviewer`
- **Mode:** Per-CL technical review under IEEE 1028 § 5 (escalated from walk-through because the dogfood driver is part of upgrade-flow tooling, and the customer's 2026-05-15 ruling — "the big blocker to going to v1.0.0 in my view is that the upgrade is always buggy" — raises the bar on upgrade-adjacent changes).
- **Author / dispatchee:** `software-engineer`
- **Net judgment: APPROVED.**

## Scope reviewed

1. `tests/release-gate/dogfood-downstream.sh` — region lines 204–243 in commit `c5bd106` (net `+35 −13`).
2. Routing-trailer compliance on `c5bd106`.
3. Hard Rule #8 / framework-boundary check on the commit.
4. Behavioural confirmation against the four dogfood-examples stub fixtures and against a fixture mixing both symlink shapes.

## Evidence collected

- **`bash -n`:** PASS.
- **`shellcheck` (default profile, v0.9.0):** clean, rc=0.
- **`scripts/lint-routing.sh --files c5bd106 --summary`:** `lint-routing: 0 warnings, 0 errors`.
- **`git diff main...c5bd106 --stat`:** `tests/release-gate/dogfood-downstream.sh | 48 +++++++++++++++++++++++--------- 1 file changed, 35 insertions(+), 13 deletions(-)` — single file changed; no other framework or product paths touched.
- **`git log --format=fuller c5bd106`:** body carries `Routed-Through: software-engineer`.
- **Smoke test #1 — stub fixture (`tests/release-gate/dogfood-examples/alpha/rc8`):** driver exited 0; report `/tmp/cr-smoke-alpha-rc8.txt` shows `upgrade exit: 0`, `verify exit: 0`, `conflict count: 0`, `ai-tui status: skipped-no-hooks`, `PASS`.
- **Smoke test #2 — mixed fixture (`/tmp/cr-mixed-fixture`):** contains BOTH a stub-style relative `scripts/upgrade.sh` symlink (`-> ../_shared/upgrade.sh`) AND an absolute-target rootfs symlink (`image/overlay/rootfs/etc/runlevels/default/sshd -> /etc/init.d/sshd`) within the same tree. Driver exited 0; report `/tmp/cr-mixed.txt` shows `upgrade exit: 0`, `verify exit: 0`, `conflict count: 0`, `PASS`. Confirms the new code path handles a fixture that exercises both symlink shapes simultaneously (priority 2).
- **Stub-fixture symlink shape survey:** all four shipped stubs (`alpha/rc8`, `beta/rc10`, `gamma/rc11`, `delta/rc11`) carry `scripts/upgrade.sh -> ../../../_shared/upgrade.sh` (relative). `readlink -f` against the original `$FIXTURE` path resolves correctly to `tests/release-gate/dogfood-examples/_shared/upgrade.sh` for each — confirms priority 1 (SE's deliberate choice to resolve against the original).
- **Dangling-stub behaviour:** verified out of band that if `$FIXTURE/scripts/upgrade.sh` points to a nonexistent target, `readlink -f` still returns a string, but `[ -f "$STUB_TARGET" ]` is false, so the block leaves the (broken) symlink in place. The driver then trips when upgrade.sh tries to execute — an acceptable downstream failure path, not a regression caused by the fix.
- **End-to-end symlink-dereferencing surface in the driver:** scanned for `cp `, `readlink`, `-L`, `find`, `rsync`. Only two `cp` invocations are content-bearing: the bulk `cp -a` at line 220 and the narrow targeted `cp -a "$STUB_TARGET" ...` at line 241. The only other `cp` (line 264) is the git-init log preservation, which copies a regular file under the driver's own scratch dir — no symlink exposure. The later `git add -A` on the scratch tree stores symlinks-as-symlinks (git mode 120000), which is the correct preservation behaviour. Priority 3: no other dereferencing paths in the driver.

## Review priorities — findings

### 1. Correctness of `readlink -f` against `$FIXTURE`

PASS. The `STUB_TARGET="$(readlink -f "$FIXTURE/scripts/upgrade.sh" 2>/dev/null || true)"` call deliberately uses the ORIGINAL `$FIXTURE` path, not `$SCRATCH_TREE`. For the dogfood-examples stub case the symlink target is relative (`../../../_shared/upgrade.sh`), so resolving against `$FIXTURE` lands at the real shared file, while resolving against `$SCRATCH_TREE` (`$SCRATCH/tree/scripts/...`) would walk out of the scratch root into a nonexistent path. SE's choice is correct and necessary; the comment block at lines 231–233 captures the reasoning. Confirmed empirically: all four shipped stubs resolve cleanly via the chosen path.

### 2. Mixed-fixture edge case (stub-style symlink AND absolute-target rootfs symlinks in the same tree)

PASS. The constructed `/tmp/cr-mixed-fixture` exercises both shapes simultaneously and the driver completes cleanly with a `PASS` report. Bulk `cp -a` preserves the absolute-target rootfs symlink verbatim (no dereference attempt → no crash), and the targeted post-copy block replaces the relative `scripts/upgrade.sh` symlink with the resolved file. The two code paths are independent and do not interact.

### 3. Other symlink-touching code paths in the driver

PASS. No other `cp -L`, `find -L`, or implicit-dereference paths in the file. `git init` / `git add -A` on the scratch tree records symlinks as symlinks; this is the desired behaviour because the upgrade phase later runs in that working tree, and overlay-rootfs symlinks should remain symlinks throughout. No regression surface.

### 4. No regression on the four dogfood-examples stub fixtures

PASS (smoke test #1 + symlink-shape survey). The relative `../../../_shared/upgrade.sh` target is identical across all four stubs, and the `readlink -f`-against-`$FIXTURE` resolution is shape-agnostic to the stub's directory depth as long as the relative path resolves. The behaviour is equivalent across the four.

### 5. Hard Rule #8 file-boundary check

PASS. `git diff main...c5bd106 --stat` shows exactly one file changed: `tests/release-gate/dogfood-downstream.sh`. No edits to `VERSION`, `CHANGELOG.md`, `TEMPLATE_VERSION`, `scripts/upgrade.sh`, ADRs, release notes, or any other framework-managed surface. The fix is scoped to the dogfood driver only, as the task brief requires.

### 6. `Routed-Through` trailer compliance

PASS. `Routed-Through: software-engineer` present on `c5bd106`; `scripts/lint-routing.sh --files c5bd106 --summary` reports `0 warnings, 0 errors`.

### 7. Hard Rule #3 / general correctness, safety, style

PASS. Code is straightforward shell; `set -eu` already in force at line 74; the `2>/dev/null || true` guard on `readlink -f` is appropriate (prevents an unbound-target failure mode from killing the driver under `-e`); the `[ -n "$STUB_TARGET" ] && [ -f "$STUB_TARGET" ]` double-guard is correct; the `rm -f` before `cp -a` of the resolved target is necessary because `cp -a SRC DST` where DST is an existing symlink would write through the symlink rather than replace it. Style matches the surrounding file: comment block precedes the logic, `if [ -L ...` shape parallels the existing fixture-validation guards earlier in the file. No findings.

## Non-blocking observations

These are recorded for visibility but do NOT block approval.

- **O-1 (cosmetic, stale docstring).** The script header at line 64 still says "The fixture is rsync-copied to a mktemp scratch dir". The driver has used `cp` (not `rsync`) for at least the duration of this branch's parent commits; this fix doesn't change that, but it does invalidate the wording slightly because the copy strategy now has two phases (bulk `cp -a` + targeted dereference). Suggest updating to "The fixture is copied to a mktemp scratch dir (symlinks preserved; stub `scripts/upgrade.sh` symlinks are resolved into real files)" in a future docs-only pass. Not in scope for this fix.
- **O-2 (defensive depth, optional).** The targeted dereference matches exactly one path (`scripts/upgrade.sh`). If a future stub-fixture pattern ever symlinks another required-by-driver file (e.g., a hooks sidecar) into `_shared/`, the same crash will recur for that file. A more general approach — walk the scratch tree, detect any symlink whose `readlink -f` against `$FIXTURE` resolves to a real file outside `$FIXTURE` AND inside the framework repo, and dereference only those — would be future-proof. Premature today; current fixture set has only the one stub-symlinked path. File as a follow-up issue if the stub vocabulary grows.
- **O-3 (test asset).** No automated test fixture exists in the repo for "absolute-target rootfs symlink in fixture preflight". The reviewer's mixed fixture (`/tmp/cr-mixed-fixture`) lives outside the repo and won't catch regressions. Consider asking `qa-engineer` to add a small captured-style fixture under `tests/release-gate/dogfood-examples/` (or a sibling regression-fixtures dir) that contains an absolute-target symlink, so CI catches a future re-introduction of `cp -aL`. Out of scope for this blocker fix.

## Conformance statement

The change at `c5bd106` conforms to:
- Hard Rule #3 (review present before merge — this document).
- Hard Rule #8 (specialist authorship — `Routed-Through: software-engineer` trailer verified).
- The change's stated objective (preserve absolute-target symlinks during bulk copy; preserve existing stub-fixture behaviour).
- The project style for shell scripts under `tests/release-gate/` (POSIX `sh`, `set -eu`, comment-led logic blocks, defensive `2>/dev/null || true` on readlink-class calls).

Customer's 2026-05-15 quality-bar ruling is honoured: the driver itself no longer hides upgrade-flow defects behind a preflight crash, so subsequent dogfood passes can actually exercise the upgrade contract on the alpha/mid and alpha/latest fixtures that this fix unblocks.

## Recommendation

APPROVE for merge. No blocking findings. The three non-blocking observations (O-1, O-2, O-3) are file-as-follow-up-issue candidates, not amendments to this commit.
