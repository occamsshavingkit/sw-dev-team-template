#!/usr/bin/env bash
#
# scripts/stepwise-smoke.sh — stepwise upgrade smoke for the
# v1.0.0-rc3 re-entry checklist (criterion C-7).
#
# Scaffolds a synthetic project, hand-stamps it to a starting tag
# (default v0.10.0), then walks every published tag from there to
# the current upstream HEAD running `scripts/upgrade.sh` against a
# **local clone with that tag checked out** at each hop. Verifies:
#   - upgrade.sh exits 0 at every hop
#   - upgrade.sh --verify exits 0 after each hop
#   - no stale .tmp.* files
#   - TEMPLATE_VERSION matches the just-applied tag
#
# Output: per-hop OK / FAIL line; on failure stops at the offending
# hop and prints which tag broke + log path. Final SUMMARY at end.
#
# Run from the template repo root.
#
# Usage:
#   scripts/stepwise-smoke.sh                  # v0.10.0 → HEAD
#   scripts/stepwise-smoke.sh --start v0.12.0  # start later
#   scripts/stepwise-smoke.sh --keep           # keep tmp dirs
#
# Cost: clones the repo once locally, then per-tag checkouts (no
# network beyond the initial clone). Acceptable for periodic CI.

set -euo pipefail

# Default start: v0.14.4 — the first version with the bootstrap
# fix (issue #63 / v0.14.3 atomic_install + v0.14.4 self-bootstrap).
# Pre-v0.14.4 hops cannot be made cleanly stepwise because the
# in-place cp pattern in v0.13.0–v0.14.2 mutates the running
# upgrade.sh's inode mid-execution. Projects on those versions
# need the one-time curl recovery documented in v0.14.3's
# CHANGELOG to land v0.14.4's upgrade.sh; from there they are
# stepwise-clean.
#
# Override with --start <tag> to test pre-v0.14.4 hops (expected
# to fail at the first cp-mutating hop; documents the historical
# regression boundary, not a live bug).
start_tag="v0.14.4"
keep=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --start) start_tag="$2"; shift 2 ;;
    --keep)  keep=1; shift ;;
    --help|-h)
      sed -n '2,/^$/p' "$0" | sed 's/^# \?//'
      exit 0 ;;
    *) echo "ERROR: unknown flag: $1" >&2; exit 2 ;;
  esac
done

if [[ ! -f VERSION || ! -x scripts/scaffold.sh ]]; then
  echo "ERROR: run this from the template repo root." >&2
  exit 1
fi

repo_root="$(pwd)"
tmp="$(mktemp -d -t sw-dev-stepwise-XXXXXX)"
trap 'if [[ $keep -eq 0 ]]; then rm -rf "$tmp"; else echo "(kept $tmp for inspection)" >&2; fi' EXIT

target="$tmp/acme"
clone="$tmp/clone"
log="$tmp/stepwise.log"

echo "stepwise-smoke: $start_tag → HEAD" | tee "$log"
echo "  workdir: $tmp" | tee -a "$log"

# Clone upstream once locally. Each hop checks out a different tag
# and runs upgrade.sh against this clone via SWDT_UPSTREAM_URL.
git clone -q "$repo_root" "$clone"

# Tag list, sorted by SemVer, starting at $start_tag. Pre-release
# tags (anything with a `-suffix`) are filtered out: stable-track
# projects don't upgrade to pre-releases per the v0.14.3 #60 fix
# in version-check.sh, and upgrade.sh's tag picker mirrors that.
all_tags="$(git -C "$clone" tag -l 'v*' | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V)"

declare -a hop_tags=()
seen_start=0
for t in $all_tags; do
  if [[ $seen_start -eq 0 ]]; then
    [[ "$t" == "$start_tag" ]] && seen_start=1
    continue  # skip the start tag itself; we begin AT it
  fi
  hop_tags+=("$t")
done

if [[ ${#hop_tags[@]} -eq 0 ]]; then
  echo "FAIL: no tags after $start_tag found in clone" | tee -a "$log"
  exit 1
fi

echo "  hops: ${#hop_tags[@]} (${hop_tags[0]} → ${hop_tags[${#hop_tags[@]}-1]})" | tee -a "$log"

# Scaffold a fresh project from the clone at $start_tag.
git -C "$clone" checkout -q "$start_tag"
"$clone/scripts/scaffold.sh" "$target" "Stepwise Smoke" >/dev/null

# Hand-stamp TEMPLATE_VERSION to the start tag with a placeholder SHA.
start_sha="$(git -C "$clone" rev-parse "$start_tag")"
printf '%s\n%s\n%s\n' "$start_tag" "$start_sha" "$(date -u +%Y-%m-%d)" > "$target/TEMPLATE_VERSION"

passed=0
failed_at=""
for tag in "${hop_tags[@]}"; do
  echo "  hop $tag" | tee -a "$log"
  git -C "$clone" checkout -q "$tag"
  hop_log="$tmp/hop-$tag.log"
  rc=0
  ( cd "$target" && SWDT_UPSTREAM_URL="$clone" bash ./scripts/upgrade.sh ) > "$hop_log" 2>&1 || rc=$?
  if [[ $rc -ne 0 ]]; then
    echo "    FAIL: upgrade.sh exited $rc — see $hop_log" | tee -a "$log"
    failed_at="$tag"
    break
  fi
  # Verify TEMPLATE_VERSION stamped to this tag.
  stamped="$(head -1 "$target/TEMPLATE_VERSION" | tr -d '[:space:]')"
  if [[ "$stamped" != "$tag" ]]; then
    echo "    FAIL: TEMPLATE_VERSION expected $tag, got $stamped" | tee -a "$log"
    failed_at="$tag"
    break
  fi
  # Verify --verify exits 0 (manifest matches state).
  vrc=0
  ( cd "$target" && SWDT_UPSTREAM_URL="$clone" bash ./scripts/upgrade.sh --verify ) > "$tmp/hop-$tag-verify.log" 2>&1 || vrc=$?
  if [[ $vrc -ne 0 ]]; then
    echo "    FAIL: --verify exited $vrc after hop to $tag" | tee -a "$log"
    failed_at="$tag"
    break
  fi
  # No stale .tmp.* files.
  stale=$(find "$target" -name '*.tmp.*' 2>/dev/null | wc -l)
  if [[ $stale -ne 0 ]]; then
    echo "    FAIL: $stale stale .tmp.* file(s) after hop to $tag" | tee -a "$log"
    failed_at="$tag"
    break
  fi
  passed=$((passed + 1))
done

echo "------------------------------------------------------------" | tee -a "$log"
if [[ -z "$failed_at" ]]; then
  echo "SUMMARY: stepwise-smoke OK — $passed/$passed hops passed (${hop_tags[0]} → ${hop_tags[${#hop_tags[@]}-1]})" | tee -a "$log"
  exit 0
else
  echo "SUMMARY: stepwise-smoke FAILED at $failed_at — $passed hop(s) passed before failure" | tee -a "$log"
  echo "  full log: $log" | tee -a "$log"
  echo "  hop log:  $tmp/hop-$failed_at.log" | tee -a "$log"
  exit 1
fi
