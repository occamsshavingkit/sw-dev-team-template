#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# tests/release-gate/test-gate-fail-each.sh — one row per sub-gate, each
# row drops a deliberate break and asserts the orchestrator surfaces that
# sub-gate in the failing list.
#
# HERMETICITY (issues #306 + #216):
#   Fixtures that need git commit / reset --hard (06, 07, 08) operate
#   exclusively inside a throwaway sandbox clone created at test startup
#   via `git clone --no-hardlinks`.  The canonical checkout (repo_root)
#   is NEVER touched by any git-history-mutating operation.
#
#   Fixtures that only create/delete working-tree files (01, 03, 04, 05)
#   continue to run against repo_root but are cleaned up inline; they
#   carry no git-state risk because they write no commits.
#
#   Fixture 09 (VERSION file swap) already restores hermetically.
#
#   A top-of-file guard asserts the sandbox is in place before any
#   history-mutating operation executes.

set -u

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
# The gate script inside the SANDBOX is used for history-mutating fixtures;
# file-only fixtures still invoke the gate from repo_root directly.
gate="$repo_root/scripts/pre-release-gate.sh"
pass=0
fail=0

# ---------------------------------------------------------------------------
# Sandbox: a throwaway clone for all git-history-mutating fixtures (06/07/08).
# Created once; removed on EXIT/INT/TERM.
# ---------------------------------------------------------------------------
sandbox=""          # set after clone succeeds
sandbox_gate=""     # pre-release-gate.sh inside the sandbox

_cleanup_sandbox() {
    # Remove the sandbox clone.  Also sweep any stale bak/fixture artefacts
    # that escaped the sandbox into repo_root (defensive belt-and-suspenders).
    if [ -n "$sandbox" ] && [ -d "$sandbox" ]; then
        rm -rf "$sandbox"
    fi
    # #216 safety glob: kill any orphan fixture migration files in repo_root
    # (left by prior killed runs before hermeticity was enforced).
    rm -f "$repo_root"/migrations/v9.9.9-fixture-*.sh
    rm -f "$repo_root"/scripts/.fixture-04-no-spdx-*.sh
    rm -f "$repo_root"/scripts/upgrade.sh.bak-*  # #308 nit-a: fixture-03 bak on SIGINT
    rm -f "$repo_root"/.claude/agents/.fixture-01-stray-*
    rm -f "$repo_root"/.claude/agents/fixture-*-no-hard-rules-*.md
}
trap '_cleanup_sandbox' EXIT INT TERM

# Create the sandbox clone.  --no-hardlinks ensures the clone has its own
# independent object store so resets in the sandbox never affect repo_root.
sandbox="$(mktemp -d -t gate-hermeticity-XXXXXX)"
git clone --no-hardlinks --local "$repo_root" "$sandbox" >/dev/null 2>&1
# Copy gitignored snapshot dir into sandbox so upgrade-matrix-fresh sub-gate
# (fixture 09b) finds snapshots when VERSION matches.
if [ -d "$repo_root/tests/release-gate/snapshots" ]; then
    cp -r "$repo_root/tests/release-gate/snapshots" \
          "$sandbox/tests/release-gate/snapshots" 2>/dev/null || true
fi
sandbox_gate="$sandbox/scripts/pre-release-gate.sh"

# Guard: if sandbox creation failed, abort loudly rather than mutating repo_root.
if [ ! -x "$sandbox_gate" ]; then
    echo "FATAL: sandbox clone failed or gate script missing at '$sandbox_gate'" >&2
    echo "       Aborting — no git state was mutated in '$repo_root'." >&2
    exit 2
fi

# ---------------------------------------------------------------------------
# Safety guard: called before every history-mutating git operation.
# Fails fast if the target dir is repo_root rather than the sandbox.
# ---------------------------------------------------------------------------
_assert_in_sandbox() {
    local target_dir="$1"
    local operation="$2"
    local real_target real_sandbox
    real_target="$(cd "$target_dir" && pwd -P)"
    real_sandbox="$(cd "$sandbox" && pwd -P)"
    # #308 nit-b: assert target IS sandbox (not just ≠ repo_root) so a third
    # repo that is neither repo_root nor sandbox cannot slip past the guard.
    if [ "$real_target" != "$real_sandbox" ]; then
        echo "FATAL: safety guard fired — '$operation' attempted outside sandbox." >&2
        echo "       target='$real_target' is not sandbox='$real_sandbox'." >&2
        echo "       All git-history operations must target the sandbox." >&2
        exit 2
    fi
}

# stash dirtying files so we can roll back atomically.
revert_actions=()
register_revert() { revert_actions+=("$1"); }
do_revert() {
    for action in "${revert_actions[@]}"; do
        eval "$action"
    done
    revert_actions=()
}
trap 'do_revert; _cleanup_sandbox' EXIT

# Sanitiser hook: scan once at startup and clear stale fixture artifacts
# from prior crashed runs in repo_root (pre-hermeticity orphans).
# Scope: file-level stale artifacts only (git tags are in the sandbox now).
sanitize_stale_fixture_artifacts() {
    local found=0
    local f
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
    # Stale fixture tags are now in the sandbox (not repo_root); nothing to sweep here.
    if [ "$found" -eq 0 ]; then
        : # clean
    fi
}
sanitize_stale_fixture_artifacts

# Helper: assert post-revert HEAD in the SANDBOX matches expected SHA.
# (Replaces the old repo_root HEAD check — sandbox is the only repo that
# should be mutated by history fixtures.)
assert_sandbox_revert_clean() {
    local label="$1"
    local expected_head="$2"
    local actual_head
    actual_head=$(git -C "$sandbox" rev-parse HEAD 2>/dev/null || echo '<rev-parse-failed>')
    if [ "$actual_head" != "$expected_head" ]; then
        echo "  FAIL: [$label] post-revert sandbox HEAD mismatch — expected '$expected_head', got '$actual_head'"
        echo "       sandbox is in an unexpected state; investigate"
        fail=$((fail + 1))
        return 1
    fi
    return 0
}

# Helper: run gate (against repo_root) and assert (a) non-zero exit AND
# (b) named sub-gate appears in the failing list.
assert_subgate_fails() {
    local label="$1"
    local target_subgate="$2"
    local gate_bin="${3:-$gate}"   # default: real gate; overrideable for sandbox gate
    local rc=0
    local out
    out=$("$gate_bin" 2>&1) || rc=$?
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
# File-only: safe to run in repo_root.
sentinel="$repo_root/.claude/agents/.fixture-01-stray-$$"
: > "$sentinel"
register_revert "rm -f '$sentinel'"
assert_subgate_fails "01-dirty-worktree" "worktree-clean"
rm -f "$sentinel"
revert_actions=()

# ----- Fixture 04: missing SPDX header → check-spdx ---------------------
# File-only: safe to run in repo_root.
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
# File-only: safe to run in repo_root.
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
# File-only: safe to run in repo_root (backup + restore, no git ops).
victim_script="$repo_root/scripts/upgrade.sh"
backup_script="$victim_script.bak-$$"
cp "$victim_script" "$backup_script"
register_revert "mv '$backup_script' '$victim_script'"
printf '\necho "# fixture-03: see migrations/v9.9.9-fixture-fake.sh for context"\n' >> "$victim_script"
assert_subgate_fails "03-dangling-advisory" "advisory-pointers"
mv "$backup_script" "$victim_script"
revert_actions=()

# ===========================================================================
# History-mutating fixtures (07, 08, 06) — ALL git operations target $sandbox.
# The gate is invoked as $sandbox_gate so GATE_CANDIDATE_TREE = $sandbox.
# repo_root is NEVER mutated.
# ===========================================================================

# ----- Fixture 07: synthetic broken v* tag → upgrade-paths ---------------
# Exercises the upgrade-paths sub-gate's failure surface (issue #166-A).
# All commits and tags land in $sandbox; reset --hard restores $sandbox HEAD.
# repo_root is untouched.
fixture07_tag="v0.0.0-fixture-07-$$"
fixture07_orig_head=$(git -C "$sandbox" rev-parse HEAD)
_assert_in_sandbox "$sandbox" "fixture-07 git-commit"
if git -C "$sandbox" diff --quiet && git -C "$sandbox" diff --cached --quiet; then
    fixture07_scaffold="$sandbox/scripts/scaffold.sh"
    fixture07_backup="$sandbox/scripts/scaffold.sh.bak-$$"
    cp "$fixture07_scaffold" "$fixture07_backup"
    # Commit B: deliberately broken scaffold.sh.
    printf '#!/usr/bin/env bash\n# SPDX-License-Identifier: MIT\necho "fixture-07: deliberate scaffold break" >&2\nexit 1\n' \
        > "$fixture07_scaffold"
    git -C "$sandbox" add scripts/scaffold.sh >/dev/null 2>&1
    git -C "$sandbox" -c commit.gpgsign=false commit -q \
        -m "test(fixture-07): broken scaffold.sh (synthetic, do-not-ship)" >/dev/null 2>&1
    git -C "$sandbox" tag "$fixture07_tag" HEAD >/dev/null 2>&1
    # Commit C: restore scaffold.sh so sandbox HEAD is healthy.
    mv "$fixture07_backup" "$fixture07_scaffold"
    git -C "$sandbox" add scripts/scaffold.sh >/dev/null 2>&1
    git -C "$sandbox" -c commit.gpgsign=false commit -q \
        -m "test(fixture-07): restore scaffold.sh (synthetic, do-not-ship)" >/dev/null 2>&1
    register_revert "git -C '$sandbox' tag -d '$fixture07_tag' >/dev/null 2>&1; git -C '$sandbox' reset --hard '$fixture07_orig_head' >/dev/null 2>&1"
    assert_subgate_fails "07-upgrade-paths-fail" "upgrade-paths" "$sandbox_gate"
    # Check the diagnostic line names the synthetic tag.
    # Issue #308: gate-tags.sh emits "failing pairs:" (line ~359), not
    # "failing source tags:" which was never emitted anywhere in scripts/.
    out=$("$sandbox_gate" 2>&1) || true
    if printf '%s' "$out" | grep -qE "failing pairs:.*${fixture07_tag}"; then
        echo "  PASS: [07-upgrade-paths-fail] '$fixture07_tag' surfaces in failing-pairs diagnostic"
        pass=$((pass + 1))
    else
        echo "  FAIL: [07-upgrade-paths-fail] '$fixture07_tag' not in failing-pairs diagnostic"
        echo "       output: $(printf '%s' "$out" | grep 'failing pairs' || echo '<no failing-pairs line>')"
        fail=$((fail + 1))
    fi
    # Revert sandbox.
    git -C "$sandbox" tag -d "$fixture07_tag" >/dev/null 2>&1 || true
    git -C "$sandbox" reset --hard "$fixture07_orig_head" >/dev/null 2>&1 || true
    assert_sandbox_revert_clean "07-upgrade-paths-fail" "$fixture07_orig_head"
    revert_actions=()
else
    echo "  FAIL: [07-upgrade-paths-fail] sandbox is unexpectedly dirty — cannot proceed"
    echo "         (sandbox was cloned clean at test startup; investigate)"
    fail=$((fail + 1))
fi

# ----- Fixture 08: README missing version + no diff since last tag → readme-current --
# All commits and tags land in $sandbox; repo_root is untouched.
fixture08_tag="v0.0.0-fixture-08-$$"
fixture08_orig_head=$(git -C "$sandbox" rev-parse HEAD)
_assert_in_sandbox "$sandbox" "fixture-08 git-commit"
if git -C "$sandbox" diff --quiet && git -C "$sandbox" diff --cached --quiet; then
    fixture08_readme="$sandbox/README.md"
    fixture08_backup="$sandbox/README.md.bak-$$"
    cp "$fixture08_readme" "$fixture08_backup"
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
    git -C "$sandbox" add README.md >/dev/null 2>&1
    git -C "$sandbox" -c commit.gpgsign=false commit -q \
        -m "test(fixture-08): scrub README VERSION mention (synthetic, do-not-ship)" >/dev/null 2>&1
    git -C "$sandbox" tag "$fixture08_tag" HEAD >/dev/null 2>&1
    register_revert "git -C '$sandbox' tag -d '$fixture08_tag' >/dev/null 2>&1; git -C '$sandbox' reset --hard '$fixture08_orig_head' >/dev/null 2>&1; rm -f '$fixture08_backup'"
    assert_subgate_fails "08-readme-current" "readme-current" "$sandbox_gate"
    # Revert sandbox.
    git -C "$sandbox" tag -d "$fixture08_tag" >/dev/null 2>&1 || true
    git -C "$sandbox" reset --hard "$fixture08_orig_head" >/dev/null 2>&1 || true
    assert_sandbox_revert_clean "08-readme-current" "$fixture08_orig_head"
    rm -f "$fixture08_backup"
    revert_actions=()
else
    echo "  FAIL: [08-readme-current] sandbox is unexpectedly dirty — cannot proceed"
    echo "         (sandbox was cloned clean at test startup; investigate)"
    fail=$((fail + 1))
fi

# ----- Fixture 06: migration writes placeholder body → migrations-standalone --
# Stub migration committed in $sandbox; #216 safety glob covers repo_root orphans.
fixture06_orig_head=$(git -C "$sandbox" rev-parse HEAD)
_assert_in_sandbox "$sandbox" "fixture-06 git-commit"
if git -C "$sandbox" diff --quiet && git -C "$sandbox" diff --cached --quiet; then
    stub_mig="$sandbox/migrations/v9.9.9-fixture-06-$$.sh"
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
    git -C "$sandbox" add "migrations/v9.9.9-fixture-06-$$.sh" >/dev/null 2>&1
    git -C "$sandbox" -c commit.gpgsign=false commit -q \
        -m "test(fixture-06): synthetic placeholder migration (do-not-ship)" >/dev/null 2>&1
    git -C "$sandbox" tag "$fixture06_tag" HEAD >/dev/null 2>&1
    register_revert "git -C '$sandbox' tag -d '$fixture06_tag' >/dev/null 2>&1; git -C '$sandbox' reset --hard '$fixture06_orig_head' >/dev/null 2>&1"
    assert_subgate_fails "06-migration-placeholder" "migrations-standalone" "$sandbox_gate"
    git -C "$sandbox" tag -d "$fixture06_tag" >/dev/null 2>&1 || true
    git -C "$sandbox" reset --hard "$fixture06_orig_head" >/dev/null 2>&1 || true
    # #216: safety glob inside sandbox (+ belt-and-suspenders in repo_root via cleanup trap).
    rm -f "$sandbox"/migrations/v9.9.9-fixture-06-*.sh
    assert_sandbox_revert_clean "06-migration-placeholder" "$fixture06_orig_head"
    revert_actions=()
else
    echo "  FAIL: [06-migration-placeholder] sandbox is unexpectedly dirty — cannot proceed"
    echo "         (sandbox was cloned clean at test startup; investigate)"
    fail=$((fail + 1))
fi

# ----- Fixture 09: current-VERSION clean/ snapshot absent → upgrade-matrix-fresh fast-fail --
# Issue #288. VERSION file swap — file-only, no git-history mutation.
# Runs against repo_root (the gate reads VERSION from GATE_CANDIDATE_TREE;
# for --only upgrade-matrix-fresh we use the real gate against repo_root
# because the snapshot dirs are only present there, not in the sandbox).

fixture09_version_file="$repo_root/VERSION"
fixture09_version_was_present=0
if [ -f "$fixture09_version_file" ]; then
    fixture09_version_was_present=1
    fixture09_real_version="$(cat "$fixture09_version_file")"
else
    fixture09_real_version=""
fi

fixture09_restore_version() {
    if [ "$fixture09_version_was_present" -eq 1 ]; then
        printf '%s\n' "$fixture09_real_version" > "$fixture09_version_file"
    else
        rm -f "$fixture09_version_file"
    fi
}

# --- 09-a: snapshot ABSENT — expect fast-fail ---
fixture09_fake_version="v0.0.0-fixture-09-$$"
printf '%s\n' "$fixture09_fake_version" > "$fixture09_version_file"
if [ "$fixture09_version_was_present" -eq 1 ]; then
    register_revert "printf '%s\n' '${fixture09_real_version}' > '${fixture09_version_file}'"
else
    register_revert "rm -f '${fixture09_version_file}'"
fi

fixture09_out=$("$gate" --only upgrade-matrix-fresh 2>&1) || fixture09_rc=$?
fixture09_rc=${fixture09_rc:-0}

fixture09_restore_version
revert_actions=()

if [ "$fixture09_rc" -eq 0 ]; then
    echo "  FAIL: [09a-matrix-fresh-absent] gate exited 0 — expected non-zero (pre-flight should have fired)"
    fail=$((fail + 1))
else
    missing_path="tests/release-gate/snapshots/$fixture09_fake_version/clean/"
    fix_cmd="bash scripts/generate-fixture-snapshots.sh"
    msg_ok=1
    if ! printf '%s' "$fixture09_out" | grep -qF "$missing_path"; then
        echo "  FAIL: [09a-matrix-fresh-absent] fast-fail message does not name missing path '$missing_path'"
        echo "       output: $(printf '%s' "$fixture09_out" | grep 'Missing\|missing\|snapshot' | head -5 || echo '<no match>')"
        msg_ok=0
    fi
    if ! printf '%s' "$fixture09_out" | grep -qF "$fix_cmd"; then
        echo "  FAIL: [09a-matrix-fresh-absent] fast-fail message does not name fix command '$fix_cmd'"
        echo "       output: $(printf '%s' "$fixture09_out" | grep 'generate\|Fix\|run' | head -5 || echo '<no match>')"
        msg_ok=0
    fi
    if [ "$msg_ok" -eq 1 ]; then
        echo "  PASS: [09a-matrix-fresh-absent] pre-flight fires on absent snapshot (rc=$fixture09_rc); message names path and fix"
        pass=$((pass + 1))
    else
        fail=$((fail + 1))
    fi
fi

# --- 09-b: snapshot PRESENT — pre-flight must NOT trigger fast-fail ---
if [ -n "$fixture09_real_version" ]; then
    real_clean="$repo_root/tests/release-gate/snapshots/$fixture09_real_version/clean"
    if [ -d "$real_clean" ]; then
        fixture09b_out=$("$gate" --only upgrade-matrix-fresh 2>&1) || true
        preflight_msg="pre-flight FAIL"
        if printf '%s' "$fixture09b_out" | grep -qF "$preflight_msg"; then
            echo "  FAIL: [09b-matrix-fresh-present] pre-flight message triggered even though clean/ snapshot exists"
            echo "       output: $(printf '%s' "$fixture09b_out" | grep "$preflight_msg" | head -3)"
            fail=$((fail + 1))
        else
            echo "  PASS: [09b-matrix-fresh-present] pre-flight silent when clean/ snapshot present (VERSION=$fixture09_real_version)"
            pass=$((pass + 1))
        fi
    else
        echo "  SKIP: [09b-matrix-fresh-present] real clean/ snapshot not on disk — regen not yet run; cannot verify present-path"
    fi
else
    echo "  SKIP: [09b-matrix-fresh-present] VERSION file absent or empty — skipping present-path check"
fi

echo
echo "------------------------------------------------------------"
echo "test-gate-fail-each: $pass passed, $fail failed"
if [ "$fail" -gt 0 ]; then
    exit 1
fi
