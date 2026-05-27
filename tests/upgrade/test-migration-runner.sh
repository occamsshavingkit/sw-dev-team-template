#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# tests/upgrade/test-migration-runner.sh — harness for migration-runner
# hardening (specs/013-migration-runner-hardening/).
#
# Structure
# ---------
# Phase 1 (this file as shipped): sanity assertions only — fixtures exist and
# have the expected exit behavior.  Exits 0 today.
#
# Phase 2 (T004): US1 failure-path cases (labelled "US1: ...") are added here
# by qa-engineer.  They will FAIL until T005–T008 land in upgrade.sh.
#
# Phase 3 (T009/T010): US2 success/no-op and detection-contract cases (labelled
# "US2: ...") are added here.  They depend on T003 (runner refactor).
#
# ----------------------------------------------------------------------------
# R6 runner-driving approach — DOCUMENTED DESIGN DECISION
# ----------------------------------------------------------------------------
# The migration-running block in scripts/upgrade.sh (lines 1066-1090 as of
# this writing) is NOT callable in isolation.  It depends on a full upgrade.sh
# execution context: a git-cloned workdir with migrations/ present
# ($workdir/new/migrations/$v.sh), $project_root, $local_version,
# $new_version, $dry_run, $baseline_available, and the SWDT_BOOTSTRAPPED guard
# that triggers self-bootstrap re-exec.  Sourcing upgrade.sh or trying to
# inject only the migration loop without the rest of the execution state is not
# feasible without significant surgery.
#
# scripts/stepwise-smoke.sh drives upgrade.sh against a real git repo with
# tags, which is the correct approach for non-regression (T011).  For
# deterministic unit-level runner testing (T004/T009/T010), the right approach
# is a synthetic local git repo that:
#   (a) has a TEMPLATE_VERSION file matching a synthetic "from" version,
#   (b) has a "upstream" clone with the fixture migrations placed under
#       migrations/<version>.sh at the right version names, and
#   (c) sets SWDT_UPSTREAM_URL to that local clone so upgrade.sh treats it
#       as upstream (identical to how stepwise-smoke.sh works).
#
# The helper stub `run_migrations_against` below captures this shape.  It is
# a STUB — it is not yet wired to a real synthetic repo because T003 must
# first refactor the runner to expose its exit status deterministically (the
# current pipe to sed masks it).  Without T003, even a perfectly-constructed
# synthetic upgrade cannot reliably assert the failure path.
#
# DEPENDENCY ON T003 (BLOCKING):
#   Before run_migrations_against can be used in real assertions:
#     1. T003 must refactor the migration-running block in upgrade.sh so each
#        migration's exit status is captured directly (not masked by the
#        `bash "$mig" 2>&1 | sed ... >&2` pipe and set -e).
#     2. Once T003 lands, the helper below can construct a synthetic upstream
#        repo, place fixture migrations under migrations/<label>.sh, and drive
#        upgrade.sh --allow-non-default-branch against it, asserting on the
#        runner's controlled exit code and artifact output.
#
# This skeleton's sanity assertions (fixture existence + exit-code contracts)
# are independent of T003 and pass today.
# ----------------------------------------------------------------------------

set -u

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FIXTURES_DIR="$REPO_ROOT/tests/upgrade/fixtures"
FAIL_FIXTURE="$FIXTURES_DIR/fail-migration.sh"
SUCCESS_FIXTURE="$FIXTURES_DIR/success-migration.sh"
NONZERO_LAST_FIXTURE="$FIXTURES_DIR/nonzero-last-statement-migration.sh"

pass=0
fail=0
failures=()
SANDBOXES=()

record_pass() {
    pass=$((pass + 1))
    printf 'PASS  %s\n' "$1"
}

record_fail() {
    fail=$((fail + 1))
    failures+=("$1")
    printf 'FAIL  %s\n' "$1"
    if [ -n "${2:-}" ]; then
        printf '      %s\n' "$2"
    fi
}

cleanup() {
    local sandbox
    for sandbox in "${SANDBOXES[@]}"; do
        rm -rf "$sandbox"
    done
}
trap cleanup EXIT

# make_sandbox: create a minimal project root for a test case.
# Sets the shell variable `sandbox` in the caller's scope.
make_sandbox() {
    sandbox=$(mktemp -d)
    SANDBOXES+=("$sandbox")
}

# ---------------------------------------------------------------------------
# run_migrations_against <chain_dir>
#
# Drives a synthetic upgrade against a controlled migration chain.
#
# <chain_dir> is a directory whose *.sh files (sorted by basename) form
# the ordered migration chain to inject as migrations/v9999.0.0.sh,
# v9999.0.1.sh, etc. in the synthetic upstream clone.
#
# Approach (mirrors scripts/stepwise-smoke.sh):
#   1. Clone the template repo locally (REPO_ROOT).
#   2. Check out the designated start tag in the clone.
#   3. Scaffold a synthetic project from the clone at that tag (satisfies
#      FW-ADR-0010 bootstrap guard: project SHA == baseline SHA == start tag).
#   4. Stamp TEMPLATE_VERSION to the start tag.
#   5. Place each fixture *.sh from <chain_dir> into migrations/v9999.0.N.sh
#      in the clone, commit them, and tag each as v9999.0.N (synthetic tags
#      strictly greater than all real tags — upgrade.sh picks the highest tag
#      as "latest" and the migration loop runs from the start tag to v9999.0.N).
#   6. Redirect the GitHub URL to the local clone via GIT_CONFIG_COUNT/KEY/VALUE
#      (same redirect used by stepwise-smoke.sh for bootstrap re-exec compat).
#   7. Run upgrade.sh --allow-non-default-branch from the synthetic project.
#
# On return, the caller can inspect:
#   $runner_rc         — exit code of upgrade.sh
#   $runner_stdout     — captured stdout of upgrade.sh (separate from stderr)
#   $runner_stderr     — captured stderr of upgrade.sh (separate from stdout)
#   $runner_project    — path to the synthetic project root (for artifact checks)
# ---------------------------------------------------------------------------
run_migrations_against() {
    local chain_dir="${1:-}"
    runner_rc=127
    runner_stdout=""
    runner_stderr=""
    runner_project=""

    if [[ -z "$chain_dir" || ! -d "$chain_dir" ]]; then
        printf '  [run_migrations_against] ERROR: chain_dir must be an existing directory\n' >&2
        return 1
    fi

    local tmp
    tmp=$(mktemp -d)
    SANDBOXES+=("$tmp")

    local clone="$tmp/clone"
    local project="$tmp/project"
    runner_project="$project"

    # Step 1: clone the template repo locally.
    git clone -q "$REPO_ROOT" "$clone" 2>/dev/null || {
        printf '  [run_migrations_against] ERROR: git clone failed\n' >&2
        return 1
    }

    # Determine a start tag: use the latest pre-release tag (matching
    # "v<major>.<minor>.<patch>-<prerelease>") as the synthetic project's
    # starting point.  A pre-release start version makes upgrade.sh consider
    # ALL upstream tags as upgrade candidates (the "pre-release track" branch),
    # ensuring the synthetic v9999.0.N-<fixture> tags (which have a "-" component
    # and would be excluded from stable-project upgrades) are treated as valid
    # targets.  Using the latest available pre-release also guarantees no real
    # migrations exist between the start tag and the synthetic ones — the next
    # "real" version after the latest pre-release is the stable release, and no
    # migration script covers that gap.
    local start_tag
    start_tag="$(git -C "$clone" tag -l 'v*' \
        | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+-' \
        | bash -c 'source '"$REPO_ROOT"'/scripts/lib/semver.sh && cat | semver_sort_tags' \
        2>/dev/null | tail -1 || true)"
    # Fallback: if no pre-release tag exists, use the latest stable tag.
    if [[ -z "$start_tag" ]]; then
        start_tag="$(git -C "$clone" tag -l 'v*' | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' \
            | sort -t. -k1,1V -k2,2n -k3,3n 2>/dev/null | tail -1 || true)"
    fi
    if [[ -z "$start_tag" ]]; then
        printf '  [run_migrations_against] ERROR: no v* tags in clone\n' >&2
        return 1
    fi

    # Step 2: check out the start tag in the clone.
    git -C "$clone" checkout -q "$start_tag"

    # Step 3: scaffold synthetic project from the clone at start_tag.
    ( cd "$clone" && ./scripts/scaffold.sh "$project" "Migration-Runner-Test" ) >/dev/null 2>&1 || {
        printf '  [run_migrations_against] ERROR: scaffold.sh failed\n' >&2
        return 1
    }

    # Step 4: stamp TEMPLATE_VERSION to the start tag (same as stepwise-smoke).
    local start_sha
    start_sha="$(git -C "$clone" rev-parse "$start_tag")"
    printf '%s\n%s\n%s\n' "$start_tag" "$start_sha" "$(date -u +%Y-%m-%d)" \
        > "$project/TEMPLATE_VERSION"

    # Restore clone to its branch head (so git operations work cleanly).
    local clone_branch
    clone_branch="$(git -C "$clone" branch --format='%(refname:short)' | grep -v 'HEAD' | head -1 || true)"
    if [[ -n "$clone_branch" ]]; then
        git -C "$clone" checkout -q "$clone_branch" 2>/dev/null || true
    fi

    # Step 4b: inject the working-tree upgrade.sh and lib into the synthetic project.
    # The scaffolded project contains the start-tag version of upgrade.sh, which may
    # predate flags and code paths added on the current branch (e.g.
    # --allow-non-default-branch, the failure-path summary).  Replacing these files
    # ensures the runner under test is the current implementation, not the tagged one.
    # SWDT_BOOTSTRAPPED=1 (set in step 7) then skips the bootstrap self-check so the
    # injected files are used directly without a SHA-mismatch refusal.
    cp "$REPO_ROOT/scripts/upgrade.sh" "$project/scripts/upgrade.sh"
    if [[ -d "$REPO_ROOT/scripts/lib" ]]; then
        cp -rp "$REPO_ROOT/scripts/lib/." "$project/scripts/lib/"
    fi

    # Step 5: inject fixture migrations into the clone under synthetic v9999.0.N tags.
    # Tag names embed the source fixture's basename (minus .sh) as a prerelease
    # identifier so that migration filenames in the runner output contain recognisable
    # substrings that test assertions can grep for (e.g. "01-fail", "00-success").
    # The semver regex accepts prerelease identifiers matching [0-9A-Za-z.-]+, so
    # "v9999.0.1-01-fail" is a valid tag and "migrations/v9999.0.1-01-fail.sh" is
    # the corresponding migration file the runner will discover.
    local idx=0
    local fixture_file
    while IFS= read -r fixture_file; do
        [[ -f "$fixture_file" ]] || continue
        local fixture_base
        fixture_base="$(basename "$fixture_file" .sh)"
        local tag="v9999.0.$idx-$fixture_base"
        local dest="$clone/migrations/${tag}.sh"
        cp "$fixture_file" "$dest"
        git -C "$clone" add "migrations/${tag}.sh"
        git -C "$clone" -c user.email="test@test" -c user.name="Test" \
            commit -q -m "fixture migration $tag" 2>/dev/null
        git -C "$clone" tag "$tag"
        idx=$(( idx + 1 ))
    done < <(find "$chain_dir" -maxdepth 1 -name '*.sh' | sort)

    if [[ $idx -eq 0 ]]; then
        printf '  [run_migrations_against] WARNING: no *.sh files found in chain_dir\n' >&2
    fi

    # Step 6: redirect GitHub URL to local clone (same technique as stepwise-smoke.sh).
    # This covers bootstrap re-exec because GIT_CONFIG_* is inherited by child processes.
    export GIT_CONFIG_COUNT=1
    export GIT_CONFIG_KEY_0="url.file://$clone.insteadOf"
    export GIT_CONFIG_VALUE_0="https://github.com/occamsshavingkit/sw-dev-team-template"

    # Step 7: run upgrade.sh from the synthetic project; capture stdout and stderr
    # SEPARATELY so that assertions on the stderr summary contract (FR-002) can
    # prove the summary appears specifically on stderr, not on stdout.
    # SWDT_BOOTSTRAPPED=1 bypasses the bootstrap self-check so the working-tree
    # upgrade.sh injected in step 4b is used directly without a SHA-mismatch refusal.
    local _err_file
    _err_file=$(mktemp)
    set +e
    runner_stdout=$(
        cd "$project"
        SWDT_BOOTSTRAPPED=1 bash ./scripts/upgrade.sh --allow-non-default-branch 2>"$_err_file"
    )
    runner_rc=$?
    set -e
    runner_stderr=$(cat "$_err_file")
    rm -f "$_err_file"

    # Clean up the GIT_CONFIG redirect so it does not bleed into subsequent calls.
    unset GIT_CONFIG_COUNT GIT_CONFIG_KEY_0 GIT_CONFIG_VALUE_0

    return 0
}

# ---------------------------------------------------------------------------
# Sanity assertions (Phase 1 — pass today, independent of T003)
# ---------------------------------------------------------------------------

# S1: fail-migration.sh fixture exists and is executable.
if [ -x "$FAIL_FIXTURE" ]; then
    record_pass "sanity: fail-migration.sh exists and is executable"
else
    record_fail "sanity: fail-migration.sh exists and is executable" \
        "expected executable at $FAIL_FIXTURE"
fi

# S2: success-migration.sh fixture exists and is executable.
if [ -x "$SUCCESS_FIXTURE" ]; then
    record_pass "sanity: success-migration.sh exists and is executable"
else
    record_fail "sanity: success-migration.sh exists and is executable" \
        "expected executable at $SUCCESS_FIXTURE"
fi

# S3: fail-migration.sh exits non-zero when run with a valid PROJECT_ROOT.
# This verifies the fixture's own contract: it must always produce exit 1.
make_sandbox
_fail_rc=0
PROJECT_ROOT="$sandbox" bash "$FAIL_FIXTURE" >/dev/null 2>&1 || _fail_rc=$?
if [ "$_fail_rc" -ne 0 ]; then
    record_pass "sanity: fail-migration.sh exits non-zero (fixture contract)"
else
    record_fail "sanity: fail-migration.sh exits non-zero (fixture contract)" \
        "expected non-zero exit from fail-migration.sh; got rc=$_fail_rc"
fi

# S4: success-migration.sh exits 0 when run with a valid PROJECT_ROOT.
# This verifies the fixture's own contract: it must always produce exit 0.
make_sandbox
_succ_rc=99
PROJECT_ROOT="$sandbox" bash "$SUCCESS_FIXTURE" >/dev/null 2>&1
_succ_rc=$?
if [ "$_succ_rc" -eq 0 ]; then
    record_pass "sanity: success-migration.sh exits 0 (fixture contract)"
else
    record_fail "sanity: success-migration.sh exits 0 (fixture contract)" \
        "expected exit 0 from success-migration.sh; got rc=$_succ_rc"
fi

# S5: success-migration.sh is idempotent — second run also exits 0.
# (The fixture must guard via its sentinel file per FW-ADR-0017 §5.)
make_sandbox
PROJECT_ROOT="$sandbox" bash "$SUCCESS_FIXTURE" >/dev/null 2>&1
PROJECT_ROOT="$sandbox" bash "$SUCCESS_FIXTURE" >/dev/null 2>&1
_idem_rc=$?
if [ "$_idem_rc" -eq 0 ]; then
    record_pass "sanity: success-migration.sh is idempotent (second run exits 0)"
else
    record_fail "sanity: success-migration.sh is idempotent (second run exits 0)" \
        "expected exit 0 on idempotent re-run; got rc=$_idem_rc"
fi

# S6: harness wiring — both fixtures are under tests/upgrade/fixtures/.
# This catches a mis-placed fixture that would silently make T004 cases
# unable to locate the files they pass to run_migrations_against.
_fix_count=$(find "$FIXTURES_DIR" -maxdepth 1 -name '*.sh' | wc -l)
if [ "$_fix_count" -ge 2 ]; then
    record_pass "sanity: at least 2 fixture .sh files present under tests/upgrade/fixtures/"
else
    record_fail "sanity: at least 2 fixture .sh files present under tests/upgrade/fixtures/" \
        "found $_fix_count .sh file(s) in $FIXTURES_DIR; expected >= 2"
fi

# ---------------------------------------------------------------------------
# T003 foundational assertion: runner captures true exit status
#
# A chain containing only the failing fixture migration must cause the runner
# to exit non-zero.  This proves FR-001: the migration's exit status is
# captured and not swallowed by the pipeline/set -e.
# ---------------------------------------------------------------------------

# Build a chain dir containing only the failing fixture.
make_sandbox
_fail_chain="$sandbox/chain"
mkdir -p "$_fail_chain"
cp "$FAIL_FIXTURE" "$_fail_chain/fail-migration.sh"

run_migrations_against "$_fail_chain"
if [[ "$runner_rc" -ne 0 ]]; then
    record_pass "T003: failing fixture migration causes runner to exit non-zero"
else
    record_fail "T003: failing fixture migration causes runner to exit non-zero" \
        "expected non-zero exit from upgrade.sh; got rc=$runner_rc"
fi

# ---------------------------------------------------------------------------
# US1 failure-path cases (T004 — RED until T005–T008 implement the behavior)
#
# All six assertions below are expected to FAIL until upgrade.sh emits the
# failure report (stderr summary + artifact).  The T003 foundational case
# above already confirms the non-zero exit; the US1 cases demand the full
# contract per contracts/migration-failure-report.md §A and §B.
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Build a mid-chain: success, fail, success  (3 migrations, fail at pos 2)
# ---------------------------------------------------------------------------
make_sandbox
_mid_chain="$sandbox/mid_chain"
mkdir -p "$_mid_chain"
# Position 0: 00-success.sh  (applied before failure)
cp "$SUCCESS_FIXTURE" "$_mid_chain/00-success.sh"
# Position 1: 01-fail.sh     (the failing migration — pos 2 of 3)
cp "$FAIL_FIXTURE"    "$_mid_chain/01-fail.sh"
# Position 2: 02-success.sh  (not run — after failure)
cp "$SUCCESS_FIXTURE" "$_mid_chain/02-success.sh"

run_migrations_against "$_mid_chain"
_us1_rc="$runner_rc"
_us1_stderr="$runner_stderr"
_us1_project="$runner_project"

# US1: non-zero exit
if [[ "$_us1_rc" -ne 0 ]]; then
    record_pass "US1: non-zero exit"
else
    record_fail "US1: non-zero exit" \
        "expected non-zero exit from runner with failing mid-chain; got rc=$_us1_rc"
fi

# US1: stderr summary
# FR-002 requires the failure summary be written to STANDARD ERROR.
# §A requires fields: failing migration filename, position "N of M", applied list, not-run list.
# Each field is checked against runner_stderr (true stderr only — not stdout).
# A bug that redirects the summary to stdout would not satisfy this assertion.
_us1_stderr_ok=1
if ! printf '%s' "$_us1_stderr" | grep -q "01-fail"; then
    _us1_stderr_ok=0
fi
if ! printf '%s' "$_us1_stderr" | grep -qE '2 of 3|2of3'; then
    _us1_stderr_ok=0
fi
if ! printf '%s' "$_us1_stderr" | grep -q "00-success"; then
    _us1_stderr_ok=0
fi
if ! printf '%s' "$_us1_stderr" | grep -q "02-success"; then
    _us1_stderr_ok=0
fi
if [[ "$_us1_stderr_ok" -eq 1 ]]; then
    record_pass "US1: stderr summary (fields on stderr, not stdout)"
else
    record_fail "US1: stderr summary (fields on stderr, not stdout)" \
        "STDERR missing one or more required fields (failing filename, 'N of M', applied list, not-run list) — summary must be on stderr per FR-002; stderr=$(printf '%s' "$_us1_stderr" | head -20)"
fi

# US1: artifact
# §B: .template-migration-failed.json at project root; must contain
#   failing_migration, position{index,total}, applied[], not_run[], exit_status.
# Invariant: applied + [failing] + not_run reconstructs the ordered chain.
_artifact="$_us1_project/.template-migration-failed.json"
_artifact_ok=1
if [[ ! -f "$_artifact" ]]; then
    _artifact_ok=0
    record_fail "US1: artifact" \
        "expected $_artifact to exist; file not found"
else
    # Check required top-level fields exist in the JSON.
    for _field in failing_migration position applied not_run exit_status; do
        if ! grep -q "\"$_field\"" "$_artifact"; then
            _artifact_ok=0
        fi
    done
    # Check failing migration filename appears.
    if ! grep -q "01-fail" "$_artifact"; then
        _artifact_ok=0
    fi
    # Check chain-reconstruction invariant (index arithmetic):
    # position.index == 2, position.total == 3, len(applied)==1, len(not_run)==1.
    # We parse index/total directly; use python3 for JSON if available.
    if command -v python3 >/dev/null 2>&1; then
        _inv=$(python3 - "$_artifact" <<'PYEOF'
import sys, json
try:
    data = json.load(open(sys.argv[1]))
    idx   = data["position"]["index"]
    total = data["position"]["total"]
    applied  = data["applied"]
    not_run  = data["not_run"]
    failing  = data["failing_migration"]
    assert len(applied) == idx - 1, f"applied len {len(applied)} != index-1 {idx-1}"
    assert len(not_run) == total - idx, f"not_run len {len(not_run)} != total-index {total-idx}"
    assert data["exit_status"] != 0, "exit_status must be non-zero"
    print("OK")
except Exception as e:
    print(f"FAIL: {e}")
PYEOF
        )
        if [[ "$_inv" != "OK" ]]; then
            _artifact_ok=0
        fi
    fi
    if [[ "$_artifact_ok" -eq 1 ]]; then
        record_pass "US1: artifact"
    else
        record_fail "US1: artifact" \
            "artifact exists but failed field/invariant checks; see $_artifact"
    fi
fi

# US1: no stale tmp
# No .tmp.* or *.tmp.* files should remain anywhere under the synthetic project
# root after a failed run (FR-007).  Search the entire tree (no depth cap) to
# catch stale temporaries left in any subdirectory.
_stale_count=$(find "$_us1_project" \( -name '.tmp.*' -o -name '*.tmp.*' \) 2>/dev/null | wc -l)
if [[ "$_stale_count" -eq 0 ]]; then
    record_pass "US1: no stale tmp"
else
    record_fail "US1: no stale tmp" \
        "found $_stale_count stale .tmp.* / *.tmp.* file(s) under $_us1_project after failed run"
fi

# US1: forward-only / applied stay (FR-011)
# After a failed run in the mid-chain (00-success → 01-fail → 02-success),
# the already-applied success migration must NOT have been rolled back:
#   (a) its sentinel file must still exist in the synthetic project root,
#   (b) the artifact's "applied" list must contain an entry referencing 00-success.
# This proves the runner does not revert applied migrations on failure.
_sentinel="$_us1_project/.fixture-success-migration-applied"
_fwd_ok=1
_fwd_reason=""

# (a) sentinel file persists
if [[ ! -f "$_sentinel" ]]; then
    _fwd_ok=0
    _fwd_reason="sentinel file $_sentinel missing after failed run — success migration effect was lost"
fi

# (b) artifact applied list contains 00-success entry
if [[ -f "$_artifact" ]]; then
    if ! grep -q "00-success" "$_artifact"; then
        _fwd_ok=0
        _fwd_reason="${_fwd_reason:+$_fwd_reason; }artifact applied list does not reference 00-success migration"
    fi
    # Additionally verify via python3 that applied is non-empty and contains exactly one entry.
    if command -v python3 >/dev/null 2>&1; then
        _fwd_inv=$(python3 - "$_artifact" <<'PYEOF'
import sys, json
try:
    data = json.load(open(sys.argv[1]))
    applied = data.get("applied", [])
    assert len(applied) >= 1, f"applied list is empty — success migration not recorded; applied={applied}"
    # The success migration should appear in the applied list (by substring match on basename).
    matches = [e for e in applied if "00-success" in e or "success" in e.lower()]
    assert len(matches) >= 1, f"no success-migration entry found in applied list; applied={applied}"
    print("OK")
except Exception as e:
    print(f"FAIL: {e}")
PYEOF
        )
        if [[ "$_fwd_inv" != "OK" ]]; then
            _fwd_ok=0
            _fwd_reason="${_fwd_reason:+$_fwd_reason; }artifact invariant: $_fwd_inv"
        fi
    fi
else
    # If the artifact does not exist at all, the no-artifact failure was already
    # caught by "US1: artifact" above.  Here we skip the artifact sub-check and
    # rely solely on the sentinel-file evidence.
    _fwd_reason="${_fwd_reason:+$_fwd_reason; }artifact absent — skipping applied-list check (already reported)"
    # Only fail this assertion on the sentinel check; if sentinel is present that
    # is sufficient positive evidence of no rollback even without the artifact.
    if [[ -f "$_sentinel" ]]; then
        _fwd_ok=1
        _fwd_reason=""
    fi
fi

if [[ "$_fwd_ok" -eq 1 ]]; then
    record_pass "US1: forward-only / applied stay"
else
    record_fail "US1: forward-only / applied stay" \
        "$_fwd_reason"
fi

# ---------------------------------------------------------------------------
# Edge case: first-position failure
# Chain: fail, success, success  (fail at pos 1 of 3)
# Expect: position "1 of 3", applied list empty, not_run has both success migrations.
# ---------------------------------------------------------------------------
make_sandbox
_first_chain="$sandbox/first_chain"
mkdir -p "$_first_chain"
cp "$FAIL_FIXTURE"    "$_first_chain/00-fail.sh"
cp "$SUCCESS_FIXTURE" "$_first_chain/01-success.sh"
cp "$SUCCESS_FIXTURE" "$_first_chain/02-success.sh"

run_migrations_against "$_first_chain"
_first_rc="$runner_rc"
_first_stderr="$runner_stderr"
_first_project="$runner_project"

_first_ok=1
# Must exit non-zero.
if [[ "$_first_rc" -eq 0 ]]; then
    _first_ok=0
fi
# Position "1 of 3" must appear on stderr (FR-002: summary on STANDARD ERROR).
if ! printf '%s' "$_first_stderr" | grep -qE '1 of 3|1of3'; then
    _first_ok=0
fi
# Applied list must be empty (no prior migrations).
# Check artifact if it exists; otherwise look for "applied" with empty-ish value in stderr.
_first_artifact="$_first_project/.template-migration-failed.json"
if [[ -f "$_first_artifact" ]] && command -v python3 >/dev/null 2>&1; then
    _first_inv=$(python3 - "$_first_artifact" <<'PYEOF'
import sys, json
try:
    data = json.load(open(sys.argv[1]))
    idx   = data["position"]["index"]
    total = data["position"]["total"]
    applied = data["applied"]
    assert idx == 1, f"index should be 1, got {idx}"
    assert total == 3, f"total should be 3, got {total}"
    assert len(applied) == 0, f"applied should be empty at first position, got {applied}"
    print("OK")
except Exception as e:
    print(f"FAIL: {e}")
PYEOF
    )
    if [[ "$_first_inv" != "OK" ]]; then
        _first_ok=0
    fi
fi
if [[ "$_first_ok" -eq 1 ]]; then
    record_pass "US1: first-position failure"
else
    record_fail "US1: first-position failure" \
        "first-position failure did not produce expected position '1 of 3' with empty applied list; rc=$_first_rc stderr=$(printf '%s' "$_first_stderr" | head -10)"
fi

# ---------------------------------------------------------------------------
# Edge case: last-position failure
# Chain: success, success, fail  (fail at pos 3 of 3)
# Expect: position "3 of 3", not_run list empty, applied has both success migrations.
# ---------------------------------------------------------------------------
make_sandbox
_last_chain="$sandbox/last_chain"
mkdir -p "$_last_chain"
cp "$SUCCESS_FIXTURE" "$_last_chain/00-success.sh"
cp "$SUCCESS_FIXTURE" "$_last_chain/01-success.sh"
cp "$FAIL_FIXTURE"    "$_last_chain/02-fail.sh"

run_migrations_against "$_last_chain"
_last_rc="$runner_rc"
_last_stderr="$runner_stderr"
_last_project="$runner_project"

_last_ok=1
if [[ "$_last_rc" -eq 0 ]]; then
    _last_ok=0
fi
# Position "3 of 3" must appear on stderr (FR-002: summary on STANDARD ERROR).
if ! printf '%s' "$_last_stderr" | grep -qE '3 of 3|3of3'; then
    _last_ok=0
fi
_last_artifact="$_last_project/.template-migration-failed.json"
if [[ -f "$_last_artifact" ]] && command -v python3 >/dev/null 2>&1; then
    _last_inv=$(python3 - "$_last_artifact" <<'PYEOF'
import sys, json
try:
    data = json.load(open(sys.argv[1]))
    idx     = data["position"]["index"]
    total   = data["position"]["total"]
    not_run = data["not_run"]
    assert idx == 3, f"index should be 3, got {idx}"
    assert total == 3, f"total should be 3, got {total}"
    assert len(not_run) == 0, f"not_run should be empty at last position, got {not_run}"
    print("OK")
except Exception as e:
    print(f"FAIL: {e}")
PYEOF
    )
    if [[ "$_last_inv" != "OK" ]]; then
        _last_ok=0
    fi
fi
if [[ "$_last_ok" -eq 1 ]]; then
    record_pass "US1: last-position failure"
else
    record_fail "US1: last-position failure" \
        "last-position failure did not produce expected position '3 of 3' with empty not_run list; rc=$_last_rc stderr=$(printf '%s' "$_last_stderr" | head -10)"
fi

# ---------------------------------------------------------------------------
# US2 success/no-op cases (T009 — FR-008)
#
# Contract §C: "A successful migration produces no failure report and no
# artifact; an all-success run leaves no .template-migration-failed.json."
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# US2: all-success no false failure
# Chain: success, success  (2 migrations, both exit 0)
# Expect: runner exits 0; every migration recorded applied; NO
#         .template-migration-failed.json written anywhere under the project.
# ---------------------------------------------------------------------------
make_sandbox
_all_success_chain="$sandbox/all_success_chain"
mkdir -p "$_all_success_chain"
cp "$SUCCESS_FIXTURE" "$_all_success_chain/00-success.sh"
cp "$SUCCESS_FIXTURE" "$_all_success_chain/01-success.sh"

run_migrations_against "$_all_success_chain"
_us2_rc="$runner_rc"
_us2_stderr="$runner_stderr"
_us2_project="$runner_project"

# (a) Runner must exit 0.
if [[ "$_us2_rc" -eq 0 ]]; then
    record_pass "US2: all-success no false failure — runner exits 0"
else
    record_fail "US2: all-success no false failure — runner exits 0" \
        "expected exit 0 from runner with all-success chain; got rc=$_us2_rc stderr=$(printf '%s' "$_us2_stderr" | head -10)"
fi

# (b) No .template-migration-failed.json must be written.
_us2_artifact="$_us2_project/.template-migration-failed.json"
if [[ ! -f "$_us2_artifact" ]]; then
    record_pass "US2: all-success no false failure — no failure artifact written"
else
    record_fail "US2: all-success no false failure — no failure artifact written" \
        "spurious failure artifact found at $_us2_artifact after all-success run"
fi

# ---------------------------------------------------------------------------
# US2: empty chain no-op
# Empty chain: no *.sh files in chain_dir → no synthetic tags injected →
# upgrade.sh sees local_version == new_version and exits 0 (no-op path,
# "Template already at <tag>" or SHA-refresh path).  No migration block runs,
# so no .template-migration-failed.json is written.
#
# Empty-chain representation: run_migrations_against is given a chain_dir
# that contains no *.sh files.  With idx==0 no synthetic tags are added to
# the clone; the upstream's latest tag equals the project's stamped version;
# upgrade.sh takes the already-at-latest exit-0 path.  This is the closest
# achievable representation of "nothing selected" without modifying the runner.
# ---------------------------------------------------------------------------
make_sandbox
_empty_chain="$sandbox/empty_chain"
mkdir -p "$_empty_chain"
# Deliberately leave _empty_chain empty — no .sh files.

run_migrations_against "$_empty_chain"
_us2_empty_rc="$runner_rc"
_us2_empty_stderr="$runner_stderr"
_us2_empty_project="$runner_project"

# (a) Runner must exit 0.
if [[ "$_us2_empty_rc" -eq 0 ]]; then
    record_pass "US2: empty chain no-op — runner exits 0"
else
    record_fail "US2: empty chain no-op — runner exits 0" \
        "expected exit 0 for empty chain (no-op); got rc=$_us2_empty_rc stderr=$(printf '%s' "$_us2_empty_stderr" | head -10)"
fi

# (b) No .template-migration-failed.json must be written.
_us2_empty_artifact="$_us2_empty_project/.template-migration-failed.json"
if [[ ! -f "$_us2_empty_artifact" ]]; then
    record_pass "US2: empty chain no-op — no failure artifact written"
else
    record_fail "US2: empty chain no-op — no failure artifact written" \
        "spurious failure artifact found at $_us2_empty_artifact after empty-chain run"
fi

# ---------------------------------------------------------------------------
# T010 detection-contract cases (US2)
#
# FR-001 from both directions:
#   (a) explicit-exit-0 ⇒ APPLIED  (runner does not false-fail a benign migration
#       whose last action is a conditional guarded with || true + explicit exit 0)
#   (b) true-non-zero   ⇒ FAILED   (runner keys on actual exit status, not on
#       whether the preceding work was benign)
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# US2: explicit-exit-0 applied
# Chain: success-migration.sh only (1 migration)
# The fixture's last real action is `printf … > "$sentinel" || true` — a
# guarded conditional that may internally return non-zero — followed by an
# explicit `exit 0`.  This proves a benign conditional does NOT cause a false
# failure when the migration exits 0 explicitly.
# Expect: runner exits 0; NO .template-migration-failed.json written.
# ---------------------------------------------------------------------------
make_sandbox
_explicit_exit0_chain="$sandbox/explicit_exit0_chain"
mkdir -p "$_explicit_exit0_chain"
cp "$SUCCESS_FIXTURE" "$_explicit_exit0_chain/00-explicit-exit0.sh"

run_migrations_against "$_explicit_exit0_chain"
_ee0_rc="$runner_rc"
_ee0_stderr="$runner_stderr"
_ee0_project="$runner_project"

# (a) Runner must exit 0.
if [[ "$_ee0_rc" -eq 0 ]]; then
    record_pass "US2: explicit-exit-0 applied — runner exits 0"
else
    record_fail "US2: explicit-exit-0 applied — runner exits 0" \
        "expected exit 0 (benign conditional + explicit exit 0); got rc=$_ee0_rc stderr=$(printf '%s' "$_ee0_stderr" | head -10)"
fi

# (b) No failure artifact must be written.
_ee0_artifact="$_ee0_project/.template-migration-failed.json"
if [[ ! -f "$_ee0_artifact" ]]; then
    record_pass "US2: explicit-exit-0 applied — no failure artifact written"
else
    record_fail "US2: explicit-exit-0 applied — no failure artifact written" \
        "spurious failure artifact found at $_ee0_artifact; explicit-exit-0 migration must not be classified FAILED"
fi

# ---------------------------------------------------------------------------
# US2: bare-nonzero-last-statement failed
# Chain: nonzero-last-statement-migration.sh only (1 migration)
# The fixture does benign work then ends on `[[ -f /nonexistent ]]` — a bare
# falsy conditional with no `|| true` and no `exit 0` — so the script exits
# non-zero.  This proves the runner classifies on TRUE exit status, not on
# whether the work was benign.
# Expect: runner exits non-zero; .template-migration-failed.json written.
# ---------------------------------------------------------------------------

# Sanity: the fixture itself must exist and be executable.
if [[ ! -x "$NONZERO_LAST_FIXTURE" ]]; then
    record_fail "US2: bare-nonzero-last-statement failed — fixture exists and is executable" \
        "expected executable at $NONZERO_LAST_FIXTURE"
else
    record_pass "US2: bare-nonzero-last-statement failed — fixture exists and is executable"

    make_sandbox
    _nzls_chain="$sandbox/nonzero_last_chain"
    mkdir -p "$_nzls_chain"
    cp "$NONZERO_LAST_FIXTURE" "$_nzls_chain/00-nonzero-last-statement.sh"

    run_migrations_against "$_nzls_chain"
    _nzls_rc="$runner_rc"
    _nzls_stderr="$runner_stderr"
    _nzls_project="$runner_project"

    # (a) Runner must exit non-zero.
    if [[ "$_nzls_rc" -ne 0 ]]; then
        record_pass "US2: bare-nonzero-last-statement failed — runner exits non-zero"
    else
        record_fail "US2: bare-nonzero-last-statement failed — runner exits non-zero" \
            "expected non-zero exit (bare falsy last statement exits non-zero); got rc=0; runner silently ignored true exit status"
    fi

    # (b) Failure artifact must be written.
    _nzls_artifact="$_nzls_project/.template-migration-failed.json"
    if [[ -f "$_nzls_artifact" ]]; then
        record_pass "US2: bare-nonzero-last-statement failed — failure artifact written"
    else
        record_fail "US2: bare-nonzero-last-statement failed — failure artifact written" \
            "expected failure artifact at $_nzls_artifact; runner did not classify true-non-zero migration as FAILED"
    fi
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
printf '\nSummary: %s passed, %s failed\n' "$pass" "$fail"
if [ "$fail" -ne 0 ]; then
    printf 'Failures:\n'
    printf ' - %s\n' "${failures[@]}"
    exit 1
fi
exit 0
