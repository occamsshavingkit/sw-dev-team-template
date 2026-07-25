#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# scripts/lib/gate-hook-exec-bits.sh — hook-exec-bits sub-gate.
# Release-gate enforcement against the role-routing-reminder.sh incident:
# a hook script committed at mode 100644 under a `.claude/settings.json`
# `[ -x "<path>" ] && "<path>" ... || true` wiring silently no-ops forever
# (missing/non-executable is indistinguishable from "nothing to run" —
# both exit 0 via the `|| true`). Catches the mode-bit regression before
# tag, on any hook wired through that idiom.
#
# Sub-gate behaviour:
#   - Run scripts/verify-hook-executable-bits.sh against the candidate tree.
#   - PASS iff every `[ -x ... ]`-guarded hook script in .claude/settings.json
#     is present and executable.
#   - FAIL on any missing/non-executable script; diagnostic names the path
#     and the `git update-index --chmod=+x` remedy.
#
# Style discipline: mirrors gate-opencode-hook-parity.sh's thin-wrapper
# shape -- the driver script (scripts/verify-hook-executable-bits.sh) does
# the real work and is independently invokable outside the gate.

gate_subgate_hook-exec-bits() {
    cd "$GATE_CANDIDATE_TREE" || return 1

    driver="scripts/verify-hook-executable-bits.sh"
    if [ ! -x "$driver" ]; then
        echo "hook-exec-bits: $driver missing or not executable in candidate tree"
        return 1
    fi

    "$driver"
}

if command -v gate_register >/dev/null 2>&1; then
    gate_register hook-exec-bits regression \
        "Every [ -x ... ]-guarded hook script in .claude/settings.json is present and executable (role-routing-reminder.sh incident)."
fi
