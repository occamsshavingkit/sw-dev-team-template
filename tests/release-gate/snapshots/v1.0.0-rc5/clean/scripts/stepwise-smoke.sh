#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
#
# scripts/stepwise-smoke.sh — stepwise upgrade smoke for release tracks.
#
# Scaffolds a synthetic project, hand-stamps it to a starting tag
# (default depends on track), then walks every published tag selected
# by that track running `scripts/upgrade.sh` against a
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
#   scripts/stepwise-smoke.sh                    # stable: v0.14.4 → latest stable
#   scripts/stepwise-smoke.sh --track rc         # rc: v1.0.0-rc3 → latest rc/final
#   scripts/stepwise-smoke.sh --start v0.12.0    # stable, start later
#   scripts/stepwise-smoke.sh --track rc --start v1.0.0-rc3
#   scripts/stepwise-smoke.sh --keep             # keep tmp dirs
#
# Cost: clones the repo once locally, then per-tag checkouts (no
# network beyond the initial clone). Acceptable for periodic CI.

set -euo pipefail

# Stable-track default start: v0.14.4 — the first version with the bootstrap
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
start_tag=""
track="stable"
keep=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --start)
      if [[ $# -lt 2 || -z "${2:-}" || "${2:-}" == --* ]]; then
        echo "ERROR: --start requires a tag argument" >&2
        exit 2
      fi
      start_tag="$2"; shift 2 ;;
    --track)
      if [[ $# -lt 2 || -z "${2:-}" || "${2:-}" == --* ]]; then
        echo "ERROR: --track requires stable or rc" >&2
        exit 2
      fi
      track="$2"; shift 2 ;;
    --keep) keep=1; shift ;;
    --help|-h)
      sed -n '2,/^$/p' "$0" | sed 's/^# \?//'
      exit 0 ;;
    *) echo "ERROR: unknown flag: $1" >&2; exit 2 ;;
  esac
done

case "$track" in
  stable|rc) ;;
  *) echo "ERROR: --track must be stable or rc" >&2; exit 2 ;;
esac

semver_sort_tags() {
  awk '
    function prerelease_key(pre, ids, n, i, id, key) {
      if (pre == "") {
        return "1"
      }
      n = split(pre, ids, ".")
      key = "0"
      for (i = 1; i <= n; i++) {
        id = ids[i]
        if (id ~ /^[0-9]+$/) {
          key = key ".1.0." sprintf("%010d", length(id)) "." id
        } else {
          key = key ".1.1." id
        }
      }
      return key ".0"
    }
    /^v[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$/ {
      tag = $0
      rest = substr(tag, 2)
      prerelease = ""
      dash = index(rest, "-")
      if (dash > 0) {
        prerelease = substr(rest, dash + 1)
        rest = substr(rest, 1, dash - 1)
      }
      split(rest, parts, ".")
      printf "%010d.%010d.%010d.%s\t%s\n", parts[1], parts[2], parts[3], prerelease_key(prerelease), tag
    }
  ' | LC_ALL=C sort -t "$(printf '\t')" -k1,1 | cut -f2-
}

if [[ -z "$start_tag" ]]; then
  case "$track" in
    stable) start_tag="v0.14.4" ;;
    rc)     start_tag="v1.0.0-rc3" ;;
  esac
fi

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

echo "stepwise-smoke: $track track, starting at $start_tag" | tee "$log"
echo "  workdir: $tmp" | tee -a "$log"

# Clone upstream once locally. Each hop checks out a different tag
# and runs upgrade.sh against this clone via SWDT_UPSTREAM_URL.
git clone -q "$repo_root" "$clone"

# Tag list, sorted by SemVer, starting at $start_tag. Stable track filters
# out pre-release tags: stable projects don't upgrade to pre-releases by
# default. rc track includes pre-releases so hops such as rc3 -> rc4 are
# exercised.
case "$track" in
  stable)
    all_tags="$(git -C "$clone" tag -l 'v*' | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | semver_sort_tags)"
    ;;
  rc)
    all_tags="$(git -C "$clone" tag -l 'v*' | semver_sort_tags)"
    ;;
esac

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

# Redirect the GitHub upstream URL to our local $clone via git's insteadOf
# rewrite, exported through GIT_CONFIG_COUNT/KEY/VALUE so every git invocation
# in the upgrade subprocess tree picks it up — including bootstrap re-execs
# that use the historical (pre-v0.16.0) upgrade.sh, which hardcodes the
# GitHub URL with no SWDT_UPSTREAM_URL override. With this redirect in
# place, each hop runs its OWN historical upgrade.sh naturally — bootstrap,
# re-exec, and all — and clones still hit the pinned local repo. This
# replaces the earlier workaround of pre-installing HEAD's upgrade.sh and
# suppressing bootstrap (which avoided the bug but didn't exercise the real
# upgrade flow).
export GIT_CONFIG_COUNT=1
export GIT_CONFIG_KEY_0="url.file://$clone.insteadOf"
export GIT_CONFIG_VALUE_0="https://github.com/occamsshavingkit/sw-dev-team-template"

# Per-hop upstream pinning. upgrade.sh in older versions has no
# --target flag; it reads VERSION from upstream's default-branch
# HEAD and walks tags up to "latest". `git clone $clone` copies
# `main` (not the detached HEAD), so `git checkout $tag` in $clone
# alone is invisible to upgrade.sh. We pin each hop two ways:
#
# 1. Reset $clone/main to $tag's commit (so upstream's VERSION is
#    $tag's VERSION).
# 2. Delete tags strictly newer than $tag (so the "latest tag"
#    walker stops at $tag).
#
# Both are restored after the hop so the next iteration can move
# forward. If anything aborts mid-hop, the EXIT trap restores.
declare -a masked_tags=()
declare -a masked_shas=()
saved_main_sha=""

pin_clone_to_tag() {
  local boundary="$1"
  saved_main_sha="$(git -C "$clone" rev-parse refs/heads/main)"
  git -C "$clone" checkout -q main
  git -C "$clone" reset -q --hard "$boundary"
  local newer
  case "$track" in
    stable)
      newer="$(git -C "$clone" tag -l 'v*' | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | semver_sort_tags \
               | sed -n "/^${boundary}\$/,\$p" | tail -n +2)"
      ;;
    rc)
      newer="$(git -C "$clone" tag -l 'v*' | semver_sort_tags \
               | sed -n "/^${boundary}\$/,\$p" | tail -n +2)"
      ;;
  esac
  masked_tags=()
  masked_shas=()
  for nt in $newer; do
    masked_tags+=("$nt")
    masked_shas+=("$(git -C "$clone" rev-parse "refs/tags/$nt")")
    git -C "$clone" tag -d "$nt" >/dev/null
  done
}
unpin_clone() {
  local i
  for i in "${!masked_tags[@]}"; do
    git -C "$clone" tag "${masked_tags[$i]}" "${masked_shas[$i]}" >/dev/null 2>&1 || true
  done
  masked_tags=()
  masked_shas=()
  if [[ -n "$saved_main_sha" ]]; then
    git -C "$clone" checkout -q main 2>/dev/null || true
    git -C "$clone" reset -q --hard "$saved_main_sha" 2>/dev/null || true
    saved_main_sha=""
  fi
}

passed=0
failed_at=""
trap 'unpin_clone 2>/dev/null || true; if [[ $keep -eq 0 ]]; then rm -rf "$tmp"; else echo "(kept $tmp for inspection)" >&2; fi' EXIT

for tag in "${hop_tags[@]}"; do
  echo "  hop $tag" | tee -a "$log"
  pin_clone_to_tag "$tag"
  hop_log="$tmp/hop-$tag.log"
  rc=0
  # Each hop runs the project's CURRENT upgrade.sh (whatever historical
  # version is in $target/scripts/). The exported GIT_CONFIG_* redirect
  # above transparently sends GitHub clones to $clone. Tag-masking pins
  # $clone so the historical upgrade.sh's "latest tag" picker stops at $tag.
  ( cd "$target" && bash ./scripts/upgrade.sh ) > "$hop_log" 2>&1 || rc=$?
  unpin_clone
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
  ( cd "$target" && bash ./scripts/upgrade.sh --verify ) > "$tmp/hop-$tag-verify.log" 2>&1 || vrc=$?
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
