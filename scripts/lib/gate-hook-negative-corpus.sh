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
#   - Run tests/hooks/run-negative-corpus.sh --all against the candidate tree.
#   - PASS iff every fixture entry passes through every hook silently.
#   - FAIL on any false-positive regression; diagnostic names the offending
#     hook, fixture entry label, category, and the rationale string.
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

    # Driver writes its progress + failure block to stderr; capture both
    # so the orchestrator's per-sub-gate diagnostic file carries them.
    "$driver" --all
}

if command -v gate_register >/dev/null 2>&1; then
    gate_register hook-negative-corpus regression \
        "Hook detector negative-corpus regression (spec 009)."
fi
