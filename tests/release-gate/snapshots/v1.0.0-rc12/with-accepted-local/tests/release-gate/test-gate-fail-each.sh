#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# tests/release-gate/test-gate-fail-each.sh — one row per sub-gate, each
# row drops a deliberate break and asserts the orchestrator surfaces that
# sub-gate in the failing list.
#
# Each "fixture" is a small in-test perturbation of the live tree (creating
# a stray file, mutating one canonical agent, etc.), reverted on exit so
# the worktree returns to its pre-test state. This avoids the maintenance
# cost of static fixtures while still proving each sub-gate triggers
# correctly.

set -u

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
gate="$repo_root/scripts/pre-release-gate.sh"
pass=0
fail=0

# stash dirtying files so we can roll back atomically.
revert_actions=()
register_revert() { revert_actions+=("$1"); }
do_revert() {
    for action in "${revert_actions[@]}"; do
        eval "$action"
    done
    revert_actions=()
}
trap do_revert EXIT

# Sanitiser hook (sub-gate contract § Negative-fixture contract, guarantee
# 4): `trap do_revert EXIT` does not fire on SIGKILL / OOM, so stale
# fixture artifacts from prior crashed runs can accumulate. Scan once at
# startup and clear them; print a one-line WARN per artifact so a crashed
# prior run is visible (not silently swept under the rug).
#
# Scope per architect's amended contract + customer rulings 2026-05-14:
#   - files: `.fixture-*-*` (fixtures 01, 04) anywhere outside .git/
#   - files: `fixture-*-no-hard-rules-*.md` (fixture 05 synthetic agent)
#   - files: `migrations/v9.9.9-fixture-*.sh` (fixture 06 stub migration)
#   - tags:  `v0.0.0-fixture-*` (fixtures 07, 08) + `v9.9.9-fixture-*`
#            (fixture 06 rehabilitation)
sanitize_stale_fixture_artifacts() {
    local found=0
    local f
    # File-level stale artifacts. Use NUL-separated find output so paths
    # with spaces survive (defensive — none today, but the pattern is
    # repo-wide).
    while IFS= read -r -d '' f; do
        echo "  WARN: sanitiser removing stale fixture file '$f' (prior crashed run?)"
        rm -f "$f"
        found=$((found + 1))
    done < <(find "$repo_root" \
        \( -name '.fixture-*-*' \
        -o -name 'fixture-*-no-hard-rules-*.md' \
        -o -path "$repo_root/migrations/v9.9.9-fixture-*.sh" \) \
        -not -path "$repo_root/.git/*" \
        -print0 2>/dev/null)
    # Tag-level stale artifacts.
    local t
    while IFS= read -r t; do
        [ -z "$t" ] && continue
        echo "  WARN: sanitiser removing stale fixture tag '$t' (prior crashed run?)"
        git -C "$repo_root" tag -d "$t" >/dev/null 2>&1 || true
        found=$((found + 1))
    done < <(git -C "$repo_root" tag --list 'v0.0.0-fixture-*' 'v9.9.9-fixture-*' 2>/dev/null)
    if [ "$found" -eq 0 ]; then
        : # clean — no stale artifacts to report.
    fi
}
sanitize_stale_fixture_artifacts

# Helper: assert post-revert HEAD matches pre-test HEAD (sub-gate contract
# § Negative-fixture contract, guarantee 2). History-mutating fixtures
# (06, 07, 08) commit + tag + reset --hard on revert; if `reset --hard`
# silently failed (e.g., racing with a concurrent process, or the
# captured SHA is stale), the worktree could be left at the wrong
# commit. Hard-fail loudly here so the contributor sees the corrupt
# state instead of green coverage on a poisoned tree.
assert_revert_clean() {
    label="$1"
    expected_head="$2"
    actual_head=$(git -C "$repo_root" rev-parse HEAD 2>/dev/null || echo '<rev-parse-failed>')
    if [ "$actual_head" != "$expected_head" ]; then
        echo "  FAIL: [$label] post-revert HEAD mismatch — expected '$expected_head', got '$actual_head'"
        echo "       worktree is in an unexpected state; investigate before further test runs"
        fail=$((fail + 1))
        return 1
    fi
    return 0
}

# Helper: run gate and assert (a) non-zero exit AND (b) named sub-gate appears
# in the failing list.
assert_subgate_fails() {
    label="$1"
    target_subgate="$2"
    rc=0
    out=$("$gate" 2>&1) || rc=$?
    if [ "$rc" -eq 0 ]; then
        echo "  FAIL: [$label] gate exited 0 (expected non-zero)"
        fail=$((fail + 1))
        return
    fi
    if printf '%s' "$out" | grep -qE "failing sub-gates:.*${target_subgate}"; then
        echo "  PASS: [$label] sub-gate '$target_subgate' surfaces in failing list (rc=$rc)"
        pass=$((pass + 1))
    else
        echo "  FAIL: [$label] '$target_subgate' not in failing list"
        echo "       output: $(printf '%s' "$out" | grep 'failing sub-gates' || echo '<no failing line>')"
        fail=$((fail + 1))
    fi
}

# ----- Fixture 01: dirty worktree → worktree-clean -----------------------
sentinel="$repo_root/.claude/agents/.fixture-01-stray-$$"
: > "$sentinel"
register_revert "rm -f '$sentinel'"
assert_subgate_fails "01-dirty-worktree" "worktree-clean"
rm -f "$sentinel"
revert_actions=()

# ----- Fixture 04: missing SPDX header → check-spdx ---------------------
target_script="$repo_root/scripts/.fixture-04-no-spdx-$$.sh"
{
    echo "#!/bin/sh"
    echo "# (deliberately missing SPDX-License-Identifier; fixture 04)"
    echo ": # no-op"
} > "$target_script"
chmod +x "$target_script"
register_revert "rm -f '$target_script'"
assert_subgate_fails "04-spdx-missing" "check-spdx"
rm -f "$target_script"
revert_actions=()

# ----- Fixture 05: canonical agent missing Hard rules → lint-contracts --
# Coverage hardening (qa-engineer T050 finding, 2026-05-14): the previous
# implementation pointed at .claude/agents/sre.md and SKIPped silently if
# the file was missing or lacked '## Hard rules'. That made coverage
# disappear if a future rename / refactor moved Hard rules out of sre.md,
# with the runner reporting green. Remediation per qa-engineer option (c):
# drop a synthetic canonical-shaped agent contract under .claude/agents/
# so the fixture does not depend on any production agent file's section
# structure. The linter's --canonical-only scan walks every .md under
# AGENTS_DIR whose basename matches ^[a-z0-9][a-z0-9-]*$ (lint-agent-
# contracts.sh:474-481), so the synthetic file participates. Removing its
# Hard rules section then deterministically trips the schema's
# required-section check on the synthetic, regardless of any rename of
# sre.md or other canonical roles.
synth="$repo_root/.claude/agents/fixture-05-no-hard-rules-$$.md"
cat > "$synth" <<'SYNTH'
---
name: fixture-05-no-hard-rules
description: Synthetic agent contract fixture for test-gate-fail-each.sh fixture 05; deliberately omits the Hard rules section so the canonical-contract schema rejects it.
---

## Job

Synthetic fixture. Not a real agent.

## Escalation

Synthetic fixture. Not a real agent.

## Output

Synthetic fixture. Not a real agent.
SYNTH
register_revert "rm -f '$synth'"
assert_subgate_fails "05-lint-fail" "lint-contracts"
rm -f "$synth"
revert_actions=()

# ----- Fixture 03: dangling advisory pointer → advisory-pointers --------
# Append a string to scripts/upgrade.sh that references a non-existent path
# the advisory scanner will catch. Don't pick a path on the allowlist.
victim_script="$repo_root/scripts/upgrade.sh"
backup_script="$victim_script.bak-$$"
cp "$victim_script" "$backup_script"
register_revert "mv '$backup_script' '$victim_script'"
printf '\necho "# fixture-03: see migrations/v9.9.9-fixture-fake.sh for context"\n' >> "$victim_script"
assert_subgate_fails "03-dangling-advisory" "advisory-pointers"
mv "$backup_script" "$victim_script"
revert_actions=()

# ----- Fixture 07: synthetic broken v* tag → upgrade-paths ---------------
# Exercises the upgrade-paths sub-gate's failure surface (issue #166-A). The
# sub-gate enumerates v* tags reachable from HEAD whose scripts/upgrade.sh
# honours SWDT_UPSTREAM_URL, then runs a scaffold+upgrade+verify round-trip
# from each. To produce a deliberate failure that doesn't touch shipped
# history, we:
#
#   1. Create a commit B whose tree intentionally breaks scaffold.sh.
#   2. Create a fixup commit C on top of B that restores scaffold.sh, so the
#      candidate state (HEAD = C) is healthy AND B is reachable from HEAD.
#   3. Tag B as a synthetic v* name (not in the allowlist) — gate enumerates
#      it, runs the round-trip starting from B's broken tree, scaffold fails,
#      round-trip fails, sub-gate reports it as a blocking failing source tag.
#   4. On revert: git reset --hard <orig_head> drops both B and C; tag -d
#      removes the synthetic tag.
#
# The synthetic tag name embeds the PID so concurrent test runs don't collide.
#
# Coverage hardening (qa-engineer T050 finding, 2026-05-14): the previous
# implementation SKIPped silently when the worktree was dirty, so a
# contributor running the test with uncommitted edits would see green
# without exercising upgrade-paths at all. Remediation per qa-engineer
# option (c): an unclean workspace is a contributor environment problem,
# not a coverage problem, so we now hard-fail with an explicit diagnostic
# instead of skipping. The test commits a synthetic broken-tag pair on top
# of HEAD and `git reset --hard`s on revert — that pattern is unsafe on a
# dirty tree.
fixture07_tag="v0.0.0-fixture-07-$$"
fixture07_orig_head=$(git -C "$repo_root" rev-parse HEAD)
if git -C "$repo_root" diff --quiet && git -C "$repo_root" diff --cached --quiet; then
    fixture07_scaffold="$repo_root/scripts/scaffold.sh"
    fixture07_backup="$fixture07_scaffold.bak-$$"
    cp "$fixture07_scaffold" "$fixture07_backup"
    # Commit B: deliberately broken scaffold.sh (early exit 1) → scaffold step
    # of round-trip fails immediately.
    printf '#!/usr/bin/env bash\n# SPDX-License-Identifier: MIT\necho "fixture-07: deliberate scaffold break" >&2\nexit 1\n' > "$fixture07_scaffold"
    git -C "$repo_root" add scripts/scaffold.sh >/dev/null 2>&1
    git -C "$repo_root" -c commit.gpgsign=false commit -q \
        -m "test(fixture-07): broken scaffold.sh (synthetic, do-not-ship)" >/dev/null 2>&1
    git -C "$repo_root" tag "$fixture07_tag" HEAD >/dev/null 2>&1
    # Commit C: restore scaffold.sh so HEAD (the candidate) is healthy.
    mv "$fixture07_backup" "$fixture07_scaffold"
    git -C "$repo_root" add scripts/scaffold.sh >/dev/null 2>&1
    git -C "$repo_root" -c commit.gpgsign=false commit -q \
        -m "test(fixture-07): restore scaffold.sh (synthetic, do-not-ship)" >/dev/null 2>&1
    register_revert "git -C '$repo_root' tag -d '$fixture07_tag' >/dev/null 2>&1; git -C '$repo_root' reset --hard '$fixture07_orig_head' >/dev/null 2>&1"
    assert_subgate_fails "07-upgrade-paths-fail" "upgrade-paths"
    # Check the diagnostic line names the synthetic tag.
    out=$("$gate" 2>&1) || true
    if printf '%s' "$out" | grep -qE "failing source tags:.*${fixture07_tag}"; then
        echo "  PASS: [07-upgrade-paths-fail] '$fixture07_tag' surfaces in failing-source-tags diagnostic"
        pass=$((pass + 1))
    else
        echo "  FAIL: [07-upgrade-paths-fail] '$fixture07_tag' not in failing-source-tags diagnostic"
        echo "       output: $(printf '%s' "$out" | grep 'failing source tags' || echo '<no failing-source-tags line>')"
        fail=$((fail + 1))
    fi
    # Revert via trap action.
    git -C "$repo_root" tag -d "$fixture07_tag" >/dev/null 2>&1 || true
    git -C "$repo_root" reset --hard "$fixture07_orig_head" >/dev/null 2>&1 || true
    assert_revert_clean "07-upgrade-paths-fail" "$fixture07_orig_head"
    revert_actions=()
else
    echo "  FAIL: [07-upgrade-paths-fail] worktree is dirty — fixture 07 needs to commit + reset --hard"
    echo "         and a dirty tree would lose uncommitted work. Clean the worktree and re-run."
    echo "         (Coverage cannot be exercised; see qa-engineer T050 finding 2026-05-14.)"
    fail=$((fail + 1))
fi

# ----- Fixture 08: README missing version + no diff since last tag → readme-current --
# T050 finding (qa-engineer, 2026-05-14): readme-current was registered in
# commit 7292792 after the negative-fixture phase ended, so this script
# never exercised it. FR-009 + sub-gate-contract violation — every
# registered sub-gate must have a negative fixture proving the runner
# surfaces it in the failing list on a deliberate break. Closes T050
# blocker for rc12.
#
# The gate (gate-runner.sh:236-261) passes if README.md either (a)
# literally contains the candidate's VERSION string OR (b) was modified
# since the most recent v* tag reachable from HEAD. To force FAIL we
# need both signals off simultaneously:
#   - (a) off: commit a scrubbed README that omits the VERSION literal.
#   - (b) off: place the "last v* tag reachable from HEAD" AT the
#             scrubbed-README commit so `git diff <last_tag> -- README.md`
#             is empty.
#
# Pattern mirrors fixture-07: requires a clean tree (we commit + tag,
# then reset --hard + tag -d on revert). Same option-(c) remediation
# applies — dirty workspace is a contributor environment problem, not a
# coverage problem.
fixture08_tag="v0.0.0-fixture-08-$$"
fixture08_orig_head=$(git -C "$repo_root" rev-parse HEAD)
if git -C "$repo_root" diff --quiet && git -C "$repo_root" diff --cached --quiet; then
    fixture08_readme="$repo_root/README.md"
    fixture08_backup="$fixture08_readme.bak-$$"
    cp "$fixture08_readme" "$fixture08_backup"
    # Determine current VERSION so we can write a README that deliberately
    # omits it. The scrubbed README is content-free for the rest of the
    # gate (only readme-current cares about it).
    fixture08_version=$(cat "$repo_root/VERSION" 2>/dev/null || echo "unknown")
    cat > "$fixture08_readme" <<'SCRUB'
<!--
SPDX-License-Identifier: MIT
Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
-->

# Fixture 08 — scrubbed README

This file is a transient test fixture. It deliberately omits any
VERSION-shaped string so the readme-current sub-gate (a) signal is off.
Reverted on test exit.
SCRUB
    git -C "$repo_root" add README.md >/dev/null 2>&1
    git -C "$repo_root" -c commit.gpgsign=false commit -q \
        -m "test(fixture-08): scrub README VERSION mention (synthetic, do-not-ship)" >/dev/null 2>&1
    # Tag at the scrubbed-README commit so the "last v* tag reachable
    # from HEAD" IS this commit; git diff <tag> -- README.md is empty,
    # so signal (b) is off too.
    git -C "$repo_root" tag "$fixture08_tag" HEAD >/dev/null 2>&1
    register_revert "git -C '$repo_root' tag -d '$fixture08_tag' >/dev/null 2>&1; git -C '$repo_root' reset --hard '$fixture08_orig_head' >/dev/null 2>&1; mv '$fixture08_backup' '$fixture08_readme' 2>/dev/null || true"
    assert_subgate_fails "08-readme-current" "readme-current"
    # Revert via trap action.
    git -C "$repo_root" tag -d "$fixture08_tag" >/dev/null 2>&1 || true
    git -C "$repo_root" reset --hard "$fixture08_orig_head" >/dev/null 2>&1 || true
    assert_revert_clean "08-readme-current" "$fixture08_orig_head"
    # Backup may have been clobbered by reset --hard restoring the tracked
    # README; remove it if it lingers.
    rm -f "$fixture08_backup"
    revert_actions=()
else
    echo "  FAIL: [08-readme-current] worktree is dirty — fixture 08 needs to commit + reset --hard"
    echo "         and a dirty tree would lose uncommitted work. Clean the worktree and re-run."
    echo "         (Coverage cannot be exercised; see qa-engineer T050 finding 2026-05-14.)"
    fail=$((fail + 1))
fi

# ----- Fixture 06: migration writes placeholder body → migrations-standalone --
# Create a one-shot stub migration that writes the placeholder marker into
# a canonical agent file. The gate's per-migration scan will find it.
#
# Coverage hardening (qa-engineer T050 finding, 2026-05-14): the previous
# stub was named v0.0.1-fixture-06.sh and was relied upon for coverage
# only by accident — gate_migration_prior_tag() returned empty for the
# stub's target version (it does NOT correspond to a real reachable tag),
# so the standalone runner SKIPped the stub silently. The fixture
# historically passed only because v0.14.0's migration was failing for an
# unrelated reason (baseline-unreachable on WORKDIR_OLD, fixed in this
# same commit set). Once that root-cause was fixed, the stub no longer
# triggered any failure.
#
# Real fix: gate_migration_prior_tag() walks the sorted v* tag list and
# returns the tag immediately before the stub's target — but only when
# the target itself is a real tag. So we (a) name the stub
# v9.9.9-fixture-06.sh so it sorts after every real tag, and (b) create
# a transient tag of the same name at HEAD before invoking the gate.
# The gate then sees v1.0.0-rcN as the prior, scaffolds from it, runs
# the stub, observes the placeholder marker, and surfaces
# migrations-standalone in the failing list. Revert removes both the
# stub file and the transient tag.
fixture06_orig_head=$(git -C "$repo_root" rev-parse HEAD)
if git -C "$repo_root" diff --quiet && git -C "$repo_root" diff --cached --quiet; then
    stub_mig="$repo_root/migrations/v9.9.9-fixture-06-$$.sh"
    fixture06_tag="v9.9.9-fixture-06-$$"
    cat > "$stub_mig" <<'STUB'
#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Fixture 06 — deliberately writes the placeholder marker so the gate's
# migrations-standalone sub-gate flags it.
: "${PROJECT_ROOT:?}"
target="$PROJECT_ROOT/.claude/agents/architect.md"
if [ -f "$target" ]; then
    printf '\n## Fixture stub\n- **TODO**: the rc9 agent-contract schema requires this section.\n' >> "$target"
fi
exit 0
STUB
    chmod +x "$stub_mig"
    git -C "$repo_root" add "migrations/v9.9.9-fixture-06-$$.sh" >/dev/null 2>&1
    git -C "$repo_root" -c commit.gpgsign=false commit -q \
        -m "test(fixture-06): synthetic placeholder migration (do-not-ship)" >/dev/null 2>&1
    git -C "$repo_root" tag "$fixture06_tag" HEAD >/dev/null 2>&1
    register_revert "git -C '$repo_root' tag -d '$fixture06_tag' >/dev/null 2>&1; git -C '$repo_root' reset --hard '$fixture06_orig_head' >/dev/null 2>&1; rm -f '$stub_mig'"
    assert_subgate_fails "06-migration-placeholder" "migrations-standalone"
    git -C "$repo_root" tag -d "$fixture06_tag" >/dev/null 2>&1 || true
    git -C "$repo_root" reset --hard "$fixture06_orig_head" >/dev/null 2>&1 || true
    rm -f "$stub_mig"
    assert_revert_clean "06-migration-placeholder" "$fixture06_orig_head"
    revert_actions=()
else
    echo "  FAIL: [06-migration-placeholder] worktree is dirty — fixture 06 needs to commit + reset --hard"
    echo "         and a dirty tree would lose uncommitted work. Clean the worktree and re-run."
    echo "         (Coverage cannot be exercised; see qa-engineer T050 finding 2026-05-14.)"
    fail=$((fail + 1))
fi

echo
echo "------------------------------------------------------------"
echo "test-gate-fail-each: $pass passed, $fail failed"
if [ "$fail" -gt 0 ]; then
    exit 1
fi
