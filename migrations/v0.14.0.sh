#!/usr/bin/env bash
#
# migrations/v0.14.0.sh — upgrade TO v0.14.0.
#
# v0.14.0 introduces TEMPLATE_MANIFEST.lock (per ADR-0002): a per-file
# SHA256 manifest at project root, used by `scripts/upgrade.sh
# --verify` for offline drift / tamper detection. Pre-v0.14.0
# projects have no manifest; this migration synthesises an initial
# one so subsequent verify operations have a reference.
#
# Synthesis strategy (per ADR-0002):
#
#   1. If WORKDIR_OLD exists (clean baseline available — the project's
#      stamp resolved to a reachable upstream commit), synthesise the
#      manifest from WORKDIR_OLD's file SHAs. This captures "what the
#      files SHOULD look like at the project's stamped version" —
#      verify after migration then exposes any drift between the
#      project tree and that baseline. The subsequent sync resolves
#      drift per the existing per-file rules (customisation → kept;
#      same-as-baseline → upgraded; both-changed → conflict).
#
#   2. If WORKDIR_OLD is unavailable (stamp doesn't match any upstream
#      tag, or the SHA is gone — see the upstream issue #61 bug case),
#      fall back to synthesising the manifest from the project's
#      *current* on-disk SHAs. The sync still compares against
#      upstream and resolves; the manifest itself gets rewritten
#      post-sync regardless.
#
# Idempotency: if the manifest already exists, leave it alone. The
# normal upgrade flow rewrites it at end.

set -euo pipefail

: "${PROJECT_ROOT:?PROJECT_ROOT is required}"
: "${WORKDIR_NEW:?WORKDIR_NEW is required}"

manifest="$PROJECT_ROOT/TEMPLATE_MANIFEST.lock"

if [[ -f "$manifest" ]]; then
  echo "  TEMPLATE_MANIFEST.lock exists — leaving it (will be rewritten post-sync)"
  exit 0
fi

# v0.14.0 ships scripts/lib/manifest.sh; pre-v0.14.0 projects don't
# have it locally yet (the sync step copies it in), so we source from
# the upgrade-time clone of the upstream.
# shellcheck source=../scripts/lib/manifest.sh
source "$WORKDIR_NEW/scripts/lib/manifest.sh"

# Pick the synthesis source.
if [[ -n "${WORKDIR_OLD:-}" && -d "$WORKDIR_OLD" ]]; then
  src="$WORKDIR_OLD"
  src_label="WORKDIR_OLD (baseline at $OLD_VERSION)"
else
  src="$PROJECT_ROOT"
  src_label="project tree (current on-disk SHAs — baseline unavailable)"
fi

manifest_write "$src" "$manifest"

count="$(grep -cv '^#' "$manifest" 2>/dev/null || echo 0)"

echo "  synthesised TEMPLATE_MANIFEST.lock from $src_label ($count entries)"
echo "    (rewritten post-sync with v0.14.0+ on-disk SHAs)"
