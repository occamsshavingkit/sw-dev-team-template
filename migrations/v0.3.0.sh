#!/usr/bin/env bash
#
# migrations/v0.3.0.sh — upgrade TO v0.3.0.
#
# v0.3.0 adds session-start version check and scripts/upgrade.sh.
# Purely additive — no downstream file moves or reshapes.

set -euo pipefail

: "${PROJECT_ROOT:?}"

echo "  (no migration actions required for this version)"
