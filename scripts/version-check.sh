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
  # shellcheck source=lib/first-actions.sh
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
