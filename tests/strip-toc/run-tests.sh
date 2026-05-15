#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# tests/strip-toc/run-tests.sh — fixture-driven test harness for
# scripts/strip-toc.sh.
#
# Spec:     specs/010-toc-build-time-strip/spec.md
# Contract: specs/010-toc-build-time-strip/contracts/strip-mechanism.md
#           § Test surface (the cases below mirror that list, minus the
#           --check drift cases reserved for v2).
#
# Strategy: run strip-toc.sh against each fixture as a one-off file path
# (the script's awk pipeline is path-content-driven and does not require
# the fixture to be git-tracked — we drive `strip_to_stdout` indirectly
# by invoking the script with the fixture path and asserting the produced
# mirror against an expected file).
#
# The fixtures live under tests/strip-toc/fixtures/ but are NOT git-tracked
# in-scope (D-3: tests/** is blacklisted), so we sidestep the git-ls check
# by running the awk pipeline directly via a helper shim.
#
# Pass/fail summary printed at end; exit code = number of failing cases.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
STRIP="$REPO_ROOT/scripts/strip-toc.sh"
FIXDIR="$REPO_ROOT/tests/strip-toc/fixtures"

pass=0
fail=0
failures=()

# strip_fixture <fixture-basename> → emits stripped output to stdout.
#
# We invoke strip-toc.sh in a sandbox: copy fixture into a tempdir that
# looks like a tiny git repo, then run strip-toc.sh on it with --all so
# the in-scope predicate accepts it. (The fixture path lives under
# `docs/` inside the sandbox — never under tests/ — so the blacklist
# passes.)
strip_fixture() {
    local fixname="$1"
    local sandbox
    sandbox=$(mktemp -d "${TMPDIR:-/tmp}/strip-toc-test.XXXXXX")
    (
        cd "$sandbox" || exit 2
        git init -q .
        git config user.email "test@example.com"
        git config user.name "test"
        mkdir -p docs
        cp "$FIXDIR/$fixname" "docs/$fixname"
        git add "docs/$fixname"
        git commit -q -m "fixture"
        "$STRIP" --all --quiet 2>/tmp/strip-toc-test.stderr.$$
        rc=$?
        if [ -f ".model-view/docs/${fixname%.md}.model.md" ]; then
            cat ".model-view/docs/${fixname%.md}.model.md"
        fi
        exit "$rc"
    )
}

# Run a positive case: assert exit 0 + mirror equals expected file.
case_positive() {
    local name="$1" fixname="$2" expname="$3"
    local actual exp_subst exp
    actual=$(strip_fixture "$fixname")
    local rc=$?
    exp_subst=$(sed "s|FIXTURE_PATH|docs/$fixname|g" "$FIXDIR/$expname")
    if [ "$rc" -ne 0 ]; then
        fail=$((fail + 1))
        failures+=("$name: expected exit 0, got $rc")
        return
    fi
    if [ "$actual" != "$exp_subst" ]; then
        fail=$((fail + 1))
        failures+=("$name: mirror content does not match expected")
        diff <(printf '%s' "$actual") <(printf '%s' "$exp_subst") | head -20 >&2
        return
    fi
    pass=$((pass + 1))
    printf '  PASS  %s\n' "$name"
}

# Run a fatal case: assert exit 2 + no mirror written.
case_fatal() {
    local name="$1" fixname="$2"
    local sandbox
    sandbox=$(mktemp -d "${TMPDIR:-/tmp}/strip-toc-test.XXXXXX")
    (
        cd "$sandbox" || exit 99
        git init -q .
        git config user.email "test@example.com"
        git config user.name "test"
        mkdir -p docs
        cp "$FIXDIR/$fixname" "docs/$fixname"
        git add "docs/$fixname"
        git commit -q -m "fixture"
        "$STRIP" --all --quiet 2>/dev/null
        rc=$?
        # Check no mirror was written.
        if [ -f ".model-view/docs/${fixname%.md}.model.md" ]; then
            exit 50  # mirror leak signal
        fi
        exit "$rc"
    )
    local rc=$?
    if [ "$rc" -eq 50 ]; then
        fail=$((fail + 1))
        failures+=("$name: mirror was written despite FATAL")
        return
    fi
    if [ "$rc" -ne 2 ]; then
        fail=$((fail + 1))
        failures+=("$name: expected exit 2, got $rc")
        return
    fi
    pass=$((pass + 1))
    printf '  PASS  %s (exit 2)\n' "$name"
}

# Skipped: file is in-scope but has no live TOC fence (e.g. all fences
# live inside fenced code blocks per N3) — script exits 0 + writes no
# per-file mirror. The top-level .model-view/README.md may still be
# emitted, so we only assert the per-file mirror is absent.
case_skipped() {
    local name="$1" fixname="$2"
    local sandbox
    sandbox=$(mktemp -d "${TMPDIR:-/tmp}/strip-toc-test.XXXXXX")
    (
        cd "$sandbox" || exit 2
        git init -q .
        git config user.email "test@example.com"
        git config user.name "test"
        mkdir -p docs
        cp "$FIXDIR/$fixname" "docs/$fixname"
        git add "docs/$fixname"
        git commit -q -m "fixture"
        "$STRIP" --all --quiet 2>/dev/null
        rc=$?
        if [ "$rc" -ne 0 ]; then exit "$rc"; fi
        if [ -f ".model-view/docs/${fixname%.md}.model.md" ]; then exit 50; fi
        exit 0
    )
    local rc=$?
    if [ "$rc" -eq 50 ]; then
        fail=$((fail + 1))
        failures+=("$name: per-file mirror was written despite no live fence")
        return
    fi
    if [ "$rc" -ne 0 ]; then
        fail=$((fail + 1))
        failures+=("$name: expected exit 0, got $rc")
        return
    fi
    pass=$((pass + 1))
    printf '  PASS  %s\n' "$name"
}

# Idempotence: run twice, assert second mirror == first mirror byte-identical.
case_idempotent() {
    local name="$1" fixname="$2"
    local sandbox
    sandbox=$(mktemp -d "${TMPDIR:-/tmp}/strip-toc-test.XXXXXX")
    (
        cd "$sandbox" || exit 2
        git init -q .
        git config user.email "test@example.com"
        git config user.name "test"
        mkdir -p docs
        cp "$FIXDIR/$fixname" "docs/$fixname"
        git add "docs/$fixname"
        git commit -q -m "fixture"
        "$STRIP" --all --quiet 2>/dev/null || exit 1
        cp ".model-view/docs/${fixname%.md}.model.md" /tmp/strip-idem-1.$$
        "$STRIP" --all --quiet 2>/dev/null || exit 1
        cp ".model-view/docs/${fixname%.md}.model.md" /tmp/strip-idem-2.$$
        if cmp -s /tmp/strip-idem-1.$$ /tmp/strip-idem-2.$$; then
            rm -f /tmp/strip-idem-1.$$ /tmp/strip-idem-2.$$
            exit 0
        fi
        rm -f /tmp/strip-idem-1.$$ /tmp/strip-idem-2.$$
        exit 1
    )
    local rc=$?
    if [ "$rc" -ne 0 ]; then
        fail=$((fail + 1))
        failures+=("$name: second run produced different mirror")
        return
    fi
    pass=$((pass + 1))
    printf '  PASS  %s\n' "$name"
}

# Out-of-scope: file under tests/ in the sandbox should be skipped even
# with a TOC fence.
case_out_of_scope() {
    local name="$1"
    local sandbox
    sandbox=$(mktemp -d "${TMPDIR:-/tmp}/strip-toc-test.XXXXXX")
    (
        cd "$sandbox" || exit 2
        git init -q .
        git config user.email "test@example.com"
        git config user.name "test"
        mkdir -p tests
        cp "$FIXDIR/single-pair.md" "tests/single-pair.md"
        git add "tests/single-pair.md"
        git commit -q -m "fixture"
        "$STRIP" --all --quiet 2>/dev/null || exit 1
        if [ -f ".model-view/tests/single-pair.model.md" ]; then
            exit 50
        fi
        exit 0
    )
    local rc=$?
    if [ "$rc" -ne 0 ]; then
        fail=$((fail + 1))
        failures+=("$name: out-of-scope file produced a mirror (rc=$rc)")
        return
    fi
    pass=$((pass + 1))
    printf '  PASS  %s\n' "$name"
}

# Dry-run: clean source tree exits 0, writes no mirror.
case_dry_run_clean() {
    local name="$1"
    local sandbox
    sandbox=$(mktemp -d "${TMPDIR:-/tmp}/strip-toc-test.XXXXXX")
    (
        cd "$sandbox" || exit 2
        git init -q .
        git config user.email "test@example.com"
        git config user.name "test"
        mkdir -p docs
        cp "$FIXDIR/single-pair.md" "docs/single-pair.md"
        git add "docs/single-pair.md"
        git commit -q -m "fixture"
        "$STRIP" --all --dry-run --quiet 2>/dev/null
        rc=$?
        if [ "$rc" -ne 0 ]; then exit "$rc"; fi
        if [ -f ".model-view/docs/single-pair.model.md" ]; then exit 50; fi
        exit 0
    )
    local rc=$?
    if [ "$rc" -ne 0 ]; then
        fail=$((fail + 1))
        failures+=("$name: dry-run clean did not exit 0 / wrote mirror (rc=$rc)")
        return
    fi
    pass=$((pass + 1))
    printf '  PASS  %s\n' "$name"
}

# Dry-run FATAL: unpaired-open fixture exits 2, writes nothing.
case_dry_run_fatal() {
    local name="$1"
    local sandbox
    sandbox=$(mktemp -d "${TMPDIR:-/tmp}/strip-toc-test.XXXXXX")
    (
        cd "$sandbox" || exit 2
        git init -q .
        git config user.email "test@example.com"
        git config user.name "test"
        mkdir -p docs
        cp "$FIXDIR/unpaired-open.md" "docs/unpaired-open.md"
        git add "docs/unpaired-open.md"
        git commit -q -m "fixture"
        "$STRIP" --all --dry-run --quiet 2>/dev/null
        rc=$?
        if [ -f ".model-view/docs/unpaired-open.model.md" ]; then exit 50; fi
        exit "$rc"
    )
    local rc=$?
    if [ "$rc" -ne 2 ]; then
        fail=$((fail + 1))
        failures+=("$name: dry-run on unpaired fence expected exit 2, got $rc")
        return
    fi
    pass=$((pass + 1))
    printf '  PASS  %s (exit 2)\n' "$name"
}

# --check on a tree whose mirror matches: exit 0, no diagnostic.
case_check_clean() {
    local name="$1"
    local sandbox
    sandbox=$(mktemp -d "${TMPDIR:-/tmp}/strip-toc-test.XXXXXX")
    (
        cd "$sandbox" || exit 2
        git init -q .
        git config user.email "test@example.com"
        git config user.name "test"
        mkdir -p docs
        cp "$FIXDIR/single-pair.md" "docs/single-pair.md"
        git add "docs/single-pair.md"
        git commit -q -m "fixture"
        "$STRIP" --all --quiet 2>/dev/null || exit 90
        "$STRIP" --all --check --quiet 2>/dev/null
        exit $?
    )
    local rc=$?
    if [ "$rc" -ne 0 ]; then
        fail=$((fail + 1))
        failures+=("$name: --check on clean tree expected exit 0, got $rc")
        return
    fi
    pass=$((pass + 1))
    printf '  PASS  %s\n' "$name"
}

# --check on a tree whose on-disk mirror has been mutated: exit 1 + diff.
case_check_drift() {
    local name="$1"
    local sandbox
    sandbox=$(mktemp -d "${TMPDIR:-/tmp}/strip-toc-test.XXXXXX")
    (
        cd "$sandbox" || exit 2
        git init -q .
        git config user.email "test@example.com"
        git config user.name "test"
        mkdir -p docs
        cp "$FIXDIR/single-pair.md" "docs/single-pair.md"
        git add "docs/single-pair.md"
        git commit -q -m "fixture"
        "$STRIP" --all --quiet 2>/dev/null || exit 90
        # Mutate the mirror.
        printf '\n(hand-edit: not regenerated)\n' >> ".model-view/docs/single-pair.model.md"
        "$STRIP" --all --check --quiet 2>/dev/null
        exit $?
    )
    local rc=$?
    if [ "$rc" -ne 1 ]; then
        fail=$((fail + 1))
        failures+=("$name: --check on drift expected exit 1, got $rc")
        return
    fi
    pass=$((pass + 1))
    printf '  PASS  %s (exit 1)\n' "$name"
}

# --check with the on-disk mirror missing: exit 1.
case_check_missing_mirror() {
    local name="$1"
    local sandbox
    sandbox=$(mktemp -d "${TMPDIR:-/tmp}/strip-toc-test.XXXXXX")
    (
        cd "$sandbox" || exit 2
        git init -q .
        git config user.email "test@example.com"
        git config user.name "test"
        mkdir -p docs
        cp "$FIXDIR/single-pair.md" "docs/single-pair.md"
        git add "docs/single-pair.md"
        git commit -q -m "fixture"
        # Do NOT pre-generate the mirror; --check must report drift.
        "$STRIP" --all --check --quiet 2>/dev/null
        exit $?
    )
    local rc=$?
    if [ "$rc" -ne 1 ]; then
        fail=$((fail + 1))
        failures+=("$name: --check with missing mirror expected exit 1, got $rc")
        return
    fi
    pass=$((pass + 1))
    printf '  PASS  %s (exit 1)\n' "$name"
}

printf 'strip-toc fixture harness — %s\n' "$STRIP"
printf '  fixtures: %s\n\n' "$FIXDIR"

case_positive "1. single TOC pair → strip clean"   single-pair.md   single-pair.expected.md
case_positive "2. multi TOC pairs → all stripped"  multi-pair.md    multi-pair.expected.md
case_skipped "3. TOC inside fenced code block → no mirror (N-1, N3)" \
                                                    in-code-block.md
case_fatal    "4. unpaired open fence → FATAL exit 2" unpaired-open.md
case_idempotent "5. idempotence: re-run produces byte-identical mirror" single-pair.md
case_out_of_scope "6. tests/* path skipped despite TOC fence"
case_dry_run_clean "7. --dry-run on clean source → exit 0, no mirror"
case_dry_run_fatal "8. --dry-run on unpaired fence → exit 2, no mirror"
case_fatal    "9. unpaired close fence → FATAL exit 2" unpaired-close.md
case_positive "10. adjacent TOC pairs separated by one blank line (N1)" \
                                                    adjacent-pairs.md adjacent-pairs.expected.md
case_skipped "11. commented-out fence inside code block → no mirror (N2)" \
                                                    commented-fence.md
case_check_clean "12. --check on regenerated tree → exit 0"
case_check_drift "13. --check on hand-edited mirror → exit 1"
case_check_missing_mirror "14. --check with missing mirror → exit 1"

printf '\n----- summary -----\n'
printf '  passed: %d\n' "$pass"
printf '  failed: %d\n' "$fail"
if [ "$fail" -gt 0 ]; then
    printf '\nfailures:\n'
    for f in "${failures[@]}"; do printf '  - %s\n' "$f"; done
fi
exit "$fail"
