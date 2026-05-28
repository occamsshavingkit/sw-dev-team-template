#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# Shared stub upgrade.sh for dogfood-driver smoke-test fixtures.
#
# Symlinked from each fixture's scripts/upgrade.sh path:
#   dogfood-examples/<codename>/<rc>/scripts/upgrade.sh
#     -> ../../../_shared/upgrade.sh
#
# Honours --target <ref>, --verify, --help; exits 0.
#
# --dry-run is deliberately NOT accepted — the driver never invokes
# it and the real scripts/upgrade.sh covers --dry-run via its own
# smoke-test suite. Keeping unused flags out of the stub avoids
# misleading "looks supported here too" signals to readers.
#
# These fixtures exist to exercise the driver's control flow, not
# the real upgrade.sh logic. Real downstream fixtures captured via
# scripts/capture-dogfood-fixture.sh ship the actual upgrade.sh
# from the scaffolded project; the driver works on both.

set -eu

mode="upgrade"
target=""

while [ "$#" -gt 0 ]; do
    case "$1" in
        --help|-h)
            cat <<'USAGE'
stub upgrade.sh — dogfood-examples fixture
  --target <ref>   accept (no-op)
  --verify         accept (no-op)
  --help, -h       this help
USAGE
            exit 0
            ;;
        --target)
            if [ "$#" -lt 2 ]; then
                echo "stub: --target requires arg" >&2
                exit 2
            fi
            target="$2"
            shift 2
            ;;
        --verify)
            mode="verify"
            shift
            ;;
        *)
            echo "stub: unknown flag $1" >&2
            exit 2
            ;;
    esac
done

case "$mode" in
    verify)
        echo "stub upgrade.sh --verify: ok"
        ;;
    *)
        echo "stub upgrade.sh: target=${target:-<unset>}, no-op"
        ;;
esac
exit 0
