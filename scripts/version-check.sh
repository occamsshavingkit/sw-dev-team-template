#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
#
# scripts/version-check.sh — at session start, compare this project's
# TEMPLATE_VERSION against the upstream template's latest tag and tell
# the user whether an upgrade is available.
#
# Exits 0 even on inability to check (no network, no upstream). The
# output goes to stdout so a SessionStart hook can pipe it back to the
# session transcript.
#
# Intended to be wired as a SessionStart hook in .claude/settings.json.

set -u

# SemVer tag sort lives in scripts/lib/semver.sh — single source of
# truth shared with scripts/upgrade.sh and scripts/stepwise-smoke.sh
# (issue #108). version-check.sh historically carried an inline copy
# that drifted: it kept the pre-#108 alphanumeric-only prerelease key
# generator and therefore mis-sorted legacy `rcN` tags (rc10 < rc8 <
# rc9 < rc11 lexically), masking upgrade banners for projects pinned
# at v1.0.0-rcN once rc10+ shipped (issues #168, #161). Source the
# canonical lib instead.
#
# version-check.sh is invoked from the SessionStart hook so the lookup
# must stay offline-tolerant. If the lib is missing (older scaffold,
# corrupted tree) stay silent and exit 0 — matching the existing
# graceful-failure paths below.
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
semver_lib="$script_dir/lib/semver.sh"
if [[ ! -f "$semver_lib" ]]; then
  exit 0
fi
# shellcheck source=scripts/lib/semver.sh
# shellcheck disable=SC1091
source "$semver_lib"

upstream="${SWDT_UPSTREAM_URL:-https://github.com/occamsshavingkit/sw-dev-team-template}"
# Allow token-auth for private upstream without persisting credentials.
if [[ -n "${GH_TOKEN:-}" && "$upstream" == https://github.com/* ]]; then
  upstream_auth="${upstream/https:\/\//https://${GH_TOKEN}@}"
else
  upstream_auth="$upstream"
fi
project_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
tv="$project_root/TEMPLATE_VERSION"

first_actions_lib="$project_root/scripts/lib/first-actions.sh"
if [[ -f "$first_actions_lib" ]]; then
  # shellcheck source=scripts/lib/first-actions.sh
  # shellcheck disable=SC1091
  source "$first_actions_lib"
fi

# Unzipped-in-place detector (issue #5 part B).
#
# Symptoms of an unzipped-but-unscaffolded directory:
#   * VERSION present (ships with the template release zip)
#   * TEMPLATE_VERSION absent (scaffold.sh stamps this)
#   * .git absent (scaffold.sh runs `git init`)
#
# The template repo itself has VERSION + .git, so it is exempt.
# A scaffolded project has TEMPLATE_VERSION, so it is exempt.
if [[ -f "$project_root/VERSION" && ! -f "$tv" && ! -d "$project_root/.git" ]]; then
  cat >&2 <<'EOF'
====================================================================
WARNING: this directory looks like an unzipped template, not a
scaffolded project.

Symptoms: VERSION is present, TEMPLATE_VERSION is missing, and there
is no .git directory. Running a Claude session here will appear to
work but will skip template invariants (no version stamp, no reset
registers, no stripped template-only files).

Two supported recoveries (v0.11.0+):
  (a) Repair in place -- strips template-only files, resets project
      registers, stamps TEMPLATE_VERSION, git-inits, seeds
      .template-customizations. You keep this directory.
          scripts/repair-in-place.sh --dry-run   # preview first
          scripts/repair-in-place.sh             # apply
  (b) Re-scaffold into a fresh directory, move your work back in.
          scripts/scaffold.sh <new-target-dir> <project-name>
          cd <new-target-dir>

Pick (a) if you want to keep this path; (b) if you want a new one.
====================================================================
EOF
fi

if [[ ! -f "$tv" ]]; then
  # Not a scaffolded project (or run from the template repo itself). Stay quiet.
  exit 0
fi

if declare -F first_actions_step0_warning >/dev/null; then
  first_actions_step0_warning "$project_root" "session"
fi

local_version="$(head -1 "$tv" 2>/dev/null | tr -d '[:space:]')"

# Untagged-state surfaceing (2026-05-15).
#
# When upgrade.sh --target was given a non-tag ref (branch / SHA), the
# TEMPLATE_VERSION first line is stamped "untagged-<short-sha>" instead
# of a semver tag. Surface this prominently so operators know they are
# not on a stable release cut. Skip the tag-comparison block entirely
# afterward — semver comparison against a synthetic label is undefined.
if [[ "$local_version" == untagged-* ]]; then
  cat <<EOF
====================================================================
WARN: Meta-project is on an untagged template state ($local_version);
      not a stable release. Re-run scripts/upgrade.sh --target <tag>
      once a stable tag is available to return to a known release cut.
====================================================================
EOF
  exit 0
fi

# Short timeout — don't stall the session on flaky network.
all_tags="$(timeout 5 git ls-remote --tags --refs "$upstream_auth" 2>/dev/null \
             | awk '{print $2}' | sed 's|refs/tags/||' \
             | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$' \
             | semver_sort_tags)"

if [[ -z "$all_tags" ]]; then
  # Network failed or upstream returned nothing. Don't nag.
  exit 0
fi

# Pre-release gating (issue #60).
#
# Pre-release tags (e.g., v1.0.0-rc2) sort higher than the most-recent
# stable on lower majors but may be withdrawn or experimental. A
# project on a stable release should not be nudged toward a higher-
# major pre-release just because the tag exists. Filter:
#
#   - Local is stable (no -suffix) → consider only stable tags.
#   - Local is pre-release         → consider all tags (stay on the
#                                    pre-release track until the user
#                                    bumps to stable).
#
# This avoids the false-positive where a withdrawn pre-release
# (e.g., v1.0.0-rc2) keeps surfacing on every session start of a
# stable v0.x.y project.
is_local_prerelease=0
[[ "$local_version" == *-* ]] && is_local_prerelease=1

if [[ $is_local_prerelease -eq 0 ]]; then
  candidates="$(echo "$all_tags" | grep -vE -- '-[0-9A-Za-z.-]+$' || true)"
else
  candidates="$all_tags"
fi

if [[ -z "$candidates" ]]; then
  # Only pre-release tags exist upstream and the project is on a
  # stable. Don't suggest a downgrade or a cross-track jump; stay quiet.
  exit 0
fi

latest_tag="$(echo "$candidates" | tail -1)"

if [[ -z "$latest_tag" ]]; then
  exit 0
fi

newest_seen="$(printf '%s\n%s\n' "$local_version" "$latest_tag" | semver_sort_tags | tail -1)"
if [[ "$local_version" == "$latest_tag" || "$newest_seen" == "$local_version" ]]; then
  echo "Template up to date: $local_version."
else
  release_url="$upstream/releases/tag/$latest_tag"
  changelog_url="$upstream/blob/main/CHANGELOG.md"
  cat <<EOF
====================================================================
Template upgrade available: $local_version → $latest_tag

  Release notes:  $release_url
  Full changelog: $changelog_url

To apply:   scripts/upgrade.sh           (add --dry-run to preview)

User-added agents (sme-<domain>.md), filled PM artifacts (docs/pm/*),
and anything listed in .template-customizations are preserved.
Customized standard files are flagged — you decide per-file.
====================================================================
EOF
fi

exit 0
