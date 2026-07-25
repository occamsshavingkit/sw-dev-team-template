#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# scripts/lib/gate-hook-negative-corpus.sh — hook-negative-corpus sub-gate.
# Spec 009 §Verification (b): release-gate enforcement of the negative-corpus
# convention. Catches drift accumulated across multi-commit branches before
# tag.
#
# Sub-gate behaviour:
#   - Run tests/hooks/run-negative-corpus.sh --all against the candidate
#     tree (Claude Code path), THEN tests/hooks/run-negative-corpus.sh
#     --all --harness opencode (OpenCode round-trip mode, fw-adr-0031:
#     every entry is round-tripped through the bridge's arg-key mapping
#     table before being fed to the same hook). Both modes run
#     unconditionally -- a failure in the first does not skip the second,
#     so a regression introduced only on the OpenCode side is never
#     masked by (or allowed to mask) a Claude-side failure.
#   - PASS iff BOTH invocations pass.
#   - FAIL on any false-positive regression in EITHER mode; diagnostic
#     names which mode failed and carries that mode's own offending-hook /
#     fixture-entry-label / category / rationale detail, so a reader does
#     not have to guess which invocation produced which failure block.
#
# Style discipline: borrows Style-A from
# specs/007-pre-release-upgrade/contracts/sub-gate.contract.md per spec 009
# §Relationship to other artefacts. No tree perturbation here (fixtures are
# data, not commands); the driver is read-only against the candidate tree.

gate_subgate_hook-negative-corpus() {
    cd "$GATE_CANDIDATE_TREE" || return 1

    driver="tests/hooks/run-negative-corpus.sh"
    if [ ! -x "$driver" ]; then
        echo "hook-negative-corpus: $driver missing or not executable in candidate tree"
        return 1
    fi
    if [ ! -d "tests/hooks/fixtures" ]; then
        echo "hook-negative-corpus: tests/hooks/fixtures/ missing in candidate tree"
        return 1
    fi

    failures=0

    # Mode 1: Claude Code path. Driver writes its progress + failure block
    # to stderr; capture both so the orchestrator's per-sub-gate diagnostic
    # file carries them.
    echo "hook-negative-corpus: === mode: claude (--all) ==="
    if ! "$driver" --all; then
        echo "hook-negative-corpus: FAILED in claude mode (--all)"
        failures=$((failures + 1))
    fi

    # Mode 2: OpenCode round-trip mode (fw-adr-0031). Independent of mode
    # 1's outcome -- both invocations always run, so neither can mask the
    # other's failure.
    echo "hook-negative-corpus: === mode: opencode (--all --harness opencode) ==="
    if ! "$driver" --all --harness opencode; then
        echo "hook-negative-corpus: FAILED in opencode mode (--all --harness opencode)"
        failures=$((failures + 1))
    fi

    if [ "$failures" -gt 0 ]; then
        echo "hook-negative-corpus: $failures of 2 mode(s) failed"
        return 1
    fi
    return 0
}

if command -v gate_register >/dev/null 2>&1; then
    gate_register hook-negative-corpus regression \
        "Hook detector negative-corpus regression (spec 009)."
fi
