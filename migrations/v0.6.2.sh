#!/usr/bin/env bash
#
# migrations/v0.6.2.sh — upgrade TO v0.6.2.
#
# Between v0.5.0 and v0.6.1 the upgrade script leaked two template-only
# files into downstream project trees:
#
#   - LICENSE              (added in v0.5.1; scaffold excluded, upgrade did not)
#   - scripts/smoke-test.sh (added in v0.6.0; scaffold excluded, upgrade did not)
#
# v0.6.1 fixed the ship-file exclusion list so new upgrades no longer
# leak them. This migration cleans up any downstream project that took
# one of those buggy upgrades.

set -euo pipefail

: "${PROJECT_ROOT:?}"

leaked_license="$PROJECT_ROOT/LICENSE"
leaked_smoke="$PROJECT_ROOT/scripts/smoke-test.sh"

# Only remove if the downstream has NOT recorded LICENSE as a permanent
# customization (some projects may legitimately want a copy of the upstream
# MIT text, though they are meant to pick their own license — respect the
# preserve-list if set).
is_preserved() {
  local p="$1"
  [[ -f "$PROJECT_ROOT/.template-customizations" ]] || return 1
  grep -E "^[[:space:]]*$(printf '%s' "$p" | sed 's|[.*^$|/\\]|\\&|g')[[:space:]]*$" "$PROJECT_ROOT/.template-customizations" > /dev/null
}

if [[ -f "$leaked_license" ]]; then
  if is_preserved "LICENSE"; then
    echo "  kept: LICENSE (listed in .template-customizations)"
  else
    rm "$leaked_license"
    echo "  removed leaked: LICENSE  (template-only — each project picks its own)"
  fi
fi

if [[ -f "$leaked_smoke" ]]; then
  if is_preserved "scripts/smoke-test.sh"; then
    echo "  kept: scripts/smoke-test.sh (listed in .template-customizations)"
  else
    rm "$leaked_smoke"
    echo "  removed leaked: scripts/smoke-test.sh  (template-maintenance tool)"
  fi
fi
