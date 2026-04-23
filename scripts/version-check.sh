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

Fix: re-scaffold into a new directory --
    scripts/scaffold.sh <new-target-dir> <project-name>
then cd into the new directory and start your session there.

If an in-place repair script ships later, it will be documented in
README.md. Until then, re-scaffolding is the supported path.
====================================================================
EOF
fi

if [[ ! -f "$tv" ]]; then
  # Not a scaffolded project (or run from the template repo itself). Stay quiet.
  exit 0
fi

local_version="$(head -1 "$tv" 2>/dev/null | tr -d '[:space:]')"

# Short timeout — don't stall the session on flaky network.
latest_tag="$(timeout 5 git ls-remote --tags --refs "$upstream_auth" 2>/dev/null \
               | awk '{print $2}' | sed 's|refs/tags/||' \
               | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+(-[A-Za-z0-9.]+)?$' \
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
