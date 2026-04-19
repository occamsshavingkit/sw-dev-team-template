#!/usr/bin/env bash
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

upstream="https://github.com/occamsshavingkit/sw-dev-team-template"
# Allow token-auth for private upstream without persisting credentials.
if [[ -n "${GH_TOKEN:-}" ]]; then
  upstream_auth="https://${GH_TOKEN}@github.com/occamsshavingkit/sw-dev-team-template"
else
  upstream_auth="$upstream"
fi
project_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
tv="$project_root/TEMPLATE_VERSION"

if [[ ! -f "$tv" ]]; then
  # Not a scaffolded project (or run from the template repo itself). Stay quiet.
  exit 0
fi

local_version="$(head -1 "$tv" 2>/dev/null | tr -d '[:space:]')"

# Short timeout — don't stall the session on flaky network.
latest_tag="$(timeout 5 git ls-remote --tags --refs "$upstream_auth" 2>/dev/null \
               | awk '{print $2}' | sed 's|refs/tags/||' \
               | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' \
               | sort -V | tail -1)"

if [[ -z "$latest_tag" ]]; then
  # Network failed or upstream returned nothing. Don't nag.
  exit 0
fi

if [[ "$local_version" == "$latest_tag" ]]; then
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
