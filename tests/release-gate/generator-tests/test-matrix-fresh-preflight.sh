#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# tests/release-gate/generator-tests/test-matrix-fresh-preflight.sh —
# unit test for the upgrade-matrix-fresh pre-flight snapshot check
# (issue #288, gate-tags.sh gate_subgate_upgrade-matrix-fresh).
#
# Asserts:
#   (a) When the current-VERSION clean/ snapshot is ABSENT from disk,
#       the sub-gate exits non-zero immediately with a message that names
#       the missing path and the fix command.
#   (b) When the current-VERSION clean/ snapshot is PRESENT on disk,
#       the pre-flight does NOT emit the fast-fail message (the sub-gate
#       may still fail for drift reasons, but not the pre-flight branch).
#
# Strategy: manipulate the GATE_CANDIDATE_TREE's VERSION file to point at
# a synthetic version whose snapshot never exists (absent case), then
# point it at a version whose snapshot does exist (present case).
# Invokes the sub-gate directly by sourcing the library, so this test
# does NOT require a clean worktree (unlike fixtures 06/07/08 in
# test-gate-fail-each.sh which must commit + reset --hard).
#
# VERSION-mutation hygiene: the restore trap removes VERSION when it was
# originally absent, and byte-for-byte restores it when it was present.
# This keeps the working tree clean regardless of how the test exits.
#
# Owned by release-engineer (procedure gap, issue #288).

set -eu

repo_root="$(cd "$(dirname "$0")/../../.." && pwd)"
gate="$repo_root/scripts/pre-release-gate.sh"

pass=0
fail=0

PREFLIGHT_MSG="pre-flight FAIL"
FIX_CMD="bash scripts/generate-fixture-snapshots.sh"

# ---------------------------------------------------------------------------
# Hermetic VERSION save/restore
# ---------------------------------------------------------------------------
version_file="$repo_root/VERSION"
version_was_present=0
real_version=""
if [ -f "$version_file" ]; then
    version_was_present=1
    real_version="$(cat "$version_file")"
fi

restore_version() {
    if [ "$version_was_present" -eq 1 ]; then
        # printf '%s\n' matches the original: command substitution strips the
        # trailing newline from cat's output, so we add it back on restore.
        printf '%s\n' "$real_version" > "$version_file"
    else
        # File did not exist before — remove it so the tree is clean.
        rm -f "$version_file"
    fi
}
trap restore_version EXIT

# ---------------------------------------------------------------------------
# Case (a): absent snapshot — pre-flight must fire
# ---------------------------------------------------------------------------
fake_version="v0.0.0-matrix-fresh-preflight-test-$$"
printf '%s\n' "$fake_version" > "$version_file"

absent_out=$("$gate" --only upgrade-matrix-fresh 2>&1) || absent_rc=$?
absent_rc=${absent_rc:-0}

restore_version

if [ "$absent_rc" -eq 0 ]; then
    echo "  FAIL: [preflight-absent] gate exited 0 — pre-flight should have returned non-zero"
    fail=$((fail + 1))
else
    missing_path="tests/release-gate/snapshots/$fake_version/clean/"
    ok=1
    if ! printf '%s' "$absent_out" | grep -qF "$missing_path"; then
        echo "  FAIL: [preflight-absent] output does not name missing path '$missing_path'"
        printf '%s\n' "$absent_out" | grep -i 'missing\|snapshot\|Missing' | head -5 | sed 's/^/         /' >&2
        ok=0
    fi
    if ! printf '%s' "$absent_out" | grep -qF "$FIX_CMD"; then
        echo "  FAIL: [preflight-absent] output does not name fix command '$FIX_CMD'"
        printf '%s\n' "$absent_out" | grep -i 'generate\|fix\|run' | head -5 | sed 's/^/         /' >&2
        ok=0
    fi
    if [ "$ok" -eq 1 ]; then
        echo "  PASS: [preflight-absent] pre-flight fires on absent snapshot (rc=$absent_rc); message names path and fix"
        pass=$((pass + 1))
    else
        fail=$((fail + 1))
    fi
fi

# ---------------------------------------------------------------------------
# Case (b): present snapshot — pre-flight must NOT fire
# ---------------------------------------------------------------------------
# Find a version whose clean/ snapshot exists on disk.
snapshots_root="$repo_root/tests/release-gate/snapshots"
present_version=""
for d in "$snapshots_root"/*/clean; do
    [ -d "$d" ] || continue
    # Extract the version component (parent dir name).
    v="$(basename "$(dirname "$d")")"
    present_version="$v"
    break
done

if [ -z "$present_version" ]; then
    echo "  SKIP: [preflight-present] no clean/ snapshot exists on disk — run generate-fixture-snapshots.sh first"
else
    printf '%s\n' "$present_version" > "$version_file"
    present_out=$("$gate" --only upgrade-matrix-fresh 2>&1) || true
    restore_version

    if printf '%s' "$present_out" | grep -qF "$PREFLIGHT_MSG"; then
        echo "  FAIL: [preflight-present] pre-flight message fired even though clean/ snapshot exists for $present_version"
        printf '%s\n' "$present_out" | grep "$PREFLIGHT_MSG" | head -3 | sed 's/^/         /' >&2
        fail=$((fail + 1))
    else
        echo "  PASS: [preflight-present] pre-flight silent when clean/ snapshot present (VERSION=$present_version)"
        pass=$((pass + 1))
    fi
fi

echo
echo "------------------------------------------------------------"
echo "test-matrix-fresh-preflight: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
