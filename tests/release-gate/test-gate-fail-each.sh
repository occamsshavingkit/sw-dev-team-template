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
# Pick a canonical agent that DOES have a ## Hard rules section; strip it;
# run gate; restore. sre.md is a stable canonical role with ## Hard rules
# present at rc10.
victim="$repo_root/.claude/agents/sre.md"
backup="$victim.bak-$$"
if [ -f "$victim" ] && grep -q '^## Hard rules' "$victim"; then
    cp "$victim" "$backup"
    register_revert "mv '$backup' '$victim'"
    # Delete every line from the "## Hard rules" heading through to (but not
    # including) the next "## " heading.
    awk '
        BEGIN { skip = 0 }
        /^## Hard rules/ { skip = 1; next }
        skip && /^## / { skip = 0 }
        !skip { print }
    ' "$backup" > "$victim"
    assert_subgate_fails "05-lint-fail" "lint-contracts"
    mv "$backup" "$victim"
    revert_actions=()
else
    echo "  SKIP: 05-lint-fail — $victim missing or lacks ## Hard rules"
fi

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
    revert_actions=()
else
    echo "  SKIP: 07-upgrade-paths-fail — worktree is dirty; cannot synthesize a transient v* tag safely"
fi

# ----- Fixture 06: migration writes placeholder body → migrations-standalone --
# Create a one-shot stub migration that writes the placeholder marker into
# a canonical agent file. The gate's per-migration scan will find it.
stub_mig="$repo_root/migrations/v0.0.1-fixture-06.sh"
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
register_revert "rm -f '$stub_mig'"
assert_subgate_fails "06-migration-placeholder" "migrations-standalone"
rm -f "$stub_mig"
revert_actions=()

echo
echo "------------------------------------------------------------"
echo "test-gate-fail-each: $pass passed, $fail failed"
if [ "$fail" -gt 0 ]; then
    exit 1
fi
