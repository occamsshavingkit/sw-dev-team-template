#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# tests/release-gate/test-gate-wrapper.sh — FR-002 / R-5 exit-code
# propagation test.
#
# Invokes the pre-release gate inside 5 wrapper compositions against a
# deliberately-failing scenario (worktree-clean fails because we drop a stray
# untracked file). For each composition, asserts the gate's non-zero exit
# survives unmasked.
#
# The contract tested: the gate itself never consumes its own non-zero exit.
# Downstream wrappers that hide that exit are out-of-tree user error, but the
# gate makes no choice that could swallow a sub-gate's exit-1 before the
# orchestrator returns.

set -u

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
gate="$repo_root/scripts/pre-release-gate.sh"
sentinel="$repo_root/.gate-wrapper-sentinel-$$"
pass=0
fail=0

cleanup() { rm -f "$sentinel"; }
trap cleanup EXIT

# Setup: create the stray untracked file so worktree-clean fails.
: > "$sentinel"

# 1) Direct invocation.
"$gate" >/dev/null 2>&1; rc=$?
if [ "$rc" -ne 0 ]; then
    echo "  PASS: direct invocation propagates non-zero ($rc)"
    pass=$((pass + 1))
else
    echo "  FAIL: direct invocation returned 0 despite worktree-clean failure"
    fail=$((fail + 1))
fi

# 2) Piped to tail. Must use ${PIPESTATUS[0]} (bash) or pipefail to capture.
set -o pipefail
"$gate" 2>&1 | tail -5 >/dev/null; rc=$?
set +o pipefail
if [ "$rc" -ne 0 ]; then
    echo "  PASS: pipe-to-tail with pipefail propagates non-zero ($rc)"
    pass=$((pass + 1))
else
    echo "  FAIL: pipe-to-tail returned 0 with pipefail set"
    fail=$((fail + 1))
fi

# 3) Piped to tee. Same composition.
set -o pipefail
"$gate" 2>&1 | tee /dev/null >/dev/null; rc=$?
set +o pipefail
if [ "$rc" -ne 0 ]; then
    echo "  PASS: pipe-to-tee with pipefail propagates non-zero ($rc)"
    pass=$((pass + 1))
else
    echo "  FAIL: pipe-to-tee returned 0 with pipefail set"
    fail=$((fail + 1))
fi

# 4) Command substitution captures stderr; $? is the gate's exit directly.
out=$("$gate" 2>&1); rc=$?
if [ "$rc" -ne 0 ]; then
    echo "  PASS: command substitution propagates non-zero ($rc)"
    pass=$((pass + 1))
else
    echo "  FAIL: command substitution returned 0"
    fail=$((fail + 1))
fi
unset out

# 5) Redirected to file.
"$gate" >/tmp/gate-wrapper-$$.log 2>&1; rc=$?
rm -f "/tmp/gate-wrapper-$$.log"
if [ "$rc" -ne 0 ]; then
    echo "  PASS: redirect-to-file propagates non-zero ($rc)"
    pass=$((pass + 1))
else
    echo "  FAIL: redirect-to-file returned 0"
    fail=$((fail + 1))
fi

echo
echo "------------------------------------------------------------"
echo "test-gate-wrapper: $pass passed, $fail failed"
if [ "$fail" -gt 0 ]; then
    exit 1
fi
