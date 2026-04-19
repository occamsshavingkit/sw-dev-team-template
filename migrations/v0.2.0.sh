#!/usr/bin/env bash
#
# migrations/v0.2.0.sh — upgrade TO v0.2.0.
#
# v0.2.0 adds scripts/scaffold.sh and a pronoun-verification procedure.
# Both are purely additive; no downstream file moves or reshapes.

set -euo pipefail

: "${PROJECT_ROOT:?}"

echo "  (no migration actions required for this version)"
