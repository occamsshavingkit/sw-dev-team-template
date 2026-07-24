#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# scripts/lib/gate-opencode-hook-parity.sh — opencode-hook-parity sub-gate.
# fw-adr-0031 (OpenCode enforcement hook bridge): release-gate enforcement
# that scripts/opencode/tool-arg-map.json still accounts for every Claude
# tool a PreToolUse hook guards in .claude/settings.json. Catches "Claude
# side grew a new guarded tool and nobody updated the map" as a
# release-blocking finding before tag.
#
# Sub-gate behaviour:
#   - Run scripts/verify-opencode-hook-parity.sh against the candidate tree.
#   - PASS iff every guarded Claude tool has a mapped-or-recorded-unmapped
#     entry in the mapping table.
#   - FAIL on any gap; diagnostic names the offending tool name(s).
#
# Style discipline: mirrors gate-hook-negative-corpus.sh's thin-wrapper
# shape -- the driver script (scripts/verify-opencode-hook-parity.sh) does
# the real work and is independently invokable outside the gate.

gate_subgate_opencode-hook-parity() {
    cd "$GATE_CANDIDATE_TREE" || return 1

    driver="scripts/verify-opencode-hook-parity.sh"
    if [ ! -x "$driver" ]; then
        echo "opencode-hook-parity: $driver missing or not executable in candidate tree"
        return 1
    fi

    "$driver"
}

if command -v gate_register >/dev/null 2>&1; then
    gate_register opencode-hook-parity regression \
        "OpenCode tool/arg-key mapping table covers every PreToolUse-guarded Claude tool (fw-adr-0031)."
fi
