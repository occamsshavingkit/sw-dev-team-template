#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# scripts/lib/gate-hook-bridge-suite.sh — hook-bridge-suite sub-gate.
#
# CR-OPENCODE-HOOK-BRIDGE-0006 (fw-adr-0031 review): registers
# tests/hooks/test-opencode-hook-bridge.sh -- the 40-scenario differential
# parity suite for the OpenCode enforcement hook bridge -- with the
# release gate. Before this sub-gate existed, the suite was invoked
# nowhere automated (not gate-runner.sh, not any `.github/workflows/*`),
# and a genuine, previously-undisposed regression (the `handledIdleSessions`
# S1/S2 eviction bug the suite's own B17 case caught) was surfaced only
# because a human happened to run this one file by hand and read its
# output. tech-lead's ruling: a safety net with no automated invocation
# is not a safety net -- register it.
#
# Disposition of `record_finding()` (tech-lead ruling, carried into this
# sub-gate): the suite deliberately does NOT flip its own exit code for an
# open `record_finding()` -- that separation of concerns is sound (a test
# file should not unilaterally decide a disposition question that belongs
# to tech-lead / security-engineer). But an undisposed finding must not
# ship silently through a green release gate either -- that is
# CR-OPENCODE-HOOK-BRIDGE-0006 recurring in a new place. This wrapper
# therefore parses the suite's own summary line and treats
# `findings > 0` as a GATE failure, without altering the suite file's own
# exit-code contract: the suite still reports its findings loudly on its
# own terms (record_finding()'s design is preserved end to end), and this
# layer is where the release-blocking consequence is attached.
#
# Runtime note: the suite includes B14/B18, which each replay ~10,000
# session.created events against the real SESSION_STATE_CAP=10000 FIFO
# eviction bound. Measured standalone: ~2s wall-clock for the full 40-case
# suite on this machine -- well inside the budget of the other sub-gates
# already registered here (hook-negative-corpus alone runs two full
# 40-entry corpus passes). Not a gate-runtime concern.
#
# Sub-gate behaviour:
#   - Run tests/hooks/test-opencode-hook-bridge.sh against the candidate
#     tree, capturing combined stdout+stderr (the suite writes its PASS/
#     FAIL/FINDING lines and summary to stdout).
#   - FAIL if the suite's own exit code is non-zero (a real regression).
#   - FAIL if the suite's own exit code is 0 but its summary line reports
#     one or more open findings (an undisposed, executable-verified
#     regression that the suite intentionally does not hard-fail on).
#   - FAIL (defensively) if the summary line cannot be parsed at all --
#     a format change in the suite's own output must not silently read
#     as "zero findings."
#   - PASS iff the suite exits 0 AND reports zero open findings.
#
# Style discipline: mirrors gate-opencode-hook-parity.sh's thin-wrapper
# shape -- the driver script (tests/hooks/test-opencode-hook-bridge.sh)
# does the real work and is independently invokable outside the gate.

gate_subgate_hook-bridge-suite() {
    cd "$GATE_CANDIDATE_TREE" || return 1

    driver="tests/hooks/test-opencode-hook-bridge.sh"
    if [ ! -x "$driver" ]; then
        echo "hook-bridge-suite: $driver missing or not executable in candidate tree"
        return 1
    fi

    output="$("$driver" 2>&1)"
    rc=$?
    printf '%s\n' "$output"

    if [ "$rc" -ne 0 ]; then
        echo "hook-bridge-suite: FAIL -- suite exited $rc (see failures above)"
        return 1
    fi

    # Suite's own summary line: "test-opencode-hook-bridge: N passed, N
    # failed, N skipped, N finding(s) open." Parse the finding count
    # rather than re-deriving it -- the suite is the source of truth for
    # its own bookkeeping.
    findings="$(printf '%s\n' "$output" | sed -n 's/.* \([0-9][0-9]*\) finding(s) open\.$/\1/p' | tail -n1)"

    if [ -z "$findings" ]; then
        echo "hook-bridge-suite: FAIL -- could not parse a finding count from the suite's summary line; its output format may have changed. Update this sub-gate's parser rather than assuming zero findings."
        return 1
    fi

    if [ "$findings" -gt 0 ]; then
        echo "hook-bridge-suite: FAIL -- $findings open finding(s) reported by the suite (see the OPEN FINDINGS block above). The suite intentionally does not hard-fail on record_finding(); this gate enforces the release-blocking consequence instead. Disposition (fix, or explicit tech-lead/security-engineer accepted-risk registration) is required before this can ship -- see CR-OPENCODE-HOOK-BRIDGE-0006."
        return 1
    fi

    return 0
}

if command -v gate_register >/dev/null 2>&1; then
    gate_register hook-bridge-suite regression \
        "OpenCode hook-bridge differential parity suite (40 scenarios, fw-adr-0031); fails on any suite failure OR any open record_finding()."
fi
