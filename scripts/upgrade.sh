#!/usr/bin/env bash
#
# scripts/upgrade.sh — upgrade this scaffolded project to the latest
# template version. Respects user-added agents and SMEs; flags
# customized standard agents for human review rather than overwriting
# them.
#
# Strategy, per template-shipped file:
#   (1) Not present in project        → add from upstream.
#   (2) Unchanged since scaffold      → overwrite with new upstream.
#   (3) Customized since scaffold,
#       and upstream unchanged        → leave alone (customization wins).
#   (4) Customized since scaffold,
#       AND upstream also changed     → flag for human review (CONFLICT).
#
# Files the project has added that the template does not ship
# (most commonly sme-<domain>.md agents, docs/pm/*.md artifacts, any
# other project-created file) are untouched.
#
# Usage:
#   scripts/upgrade.sh [--dry-run]
#
# Runs the full upgrade if no flag; with --dry-run, prints the plan
# and changes nothing.

set -euo pipefail

upstream="https://github.com/occamsshavingkit/sw-dev-team-template"
if [[ -n "${GH_TOKEN:-}" ]]; then
  upstream_auth="https://${GH_TOKEN}@github.com/occamsshavingkit/sw-dev-team-template"
else
  upstream_auth="$upstream"
fi
project_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
tv="$project_root/TEMPLATE_VERSION"

dry_run=0
[[ "${1:-}" == "--dry-run" ]] && dry_run=1

if [[ ! -f "$tv" ]]; then
  echo "ERROR: no TEMPLATE_VERSION at project root. Not a scaffolded project?" >&2
  exit 1
fi

local_version="$(head -1 "$tv" | tr -d '[:space:]')"
local_sha="$(sed -n '2p' "$tv" | tr -d '[:space:]')"

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

echo "Cloning upstream..." >&2
git clone -q "$upstream_auth" "$workdir/new" 2>/dev/null || {
  echo "ERROR: clone of $upstream failed. Check network / auth." >&2
  exit 1
}

new_version="$(cat "$workdir/new/VERSION" | tr -d '[:space:]')"
new_sha="$(git -C "$workdir/new" rev-parse HEAD)"

if [[ "$local_version" == "$new_version" ]]; then
  echo "Template already at $local_version — nothing to do." >&2
  exit 0
fi

# Clone the baseline (the version this project was scaffolded from) so we
# can detect which files the project has customized since scaffold.
baseline_available=0
if [[ -n "$local_sha" && "$local_sha" != "unknown" ]]; then
  git clone -q "$upstream_auth" "$workdir/old" 2>/dev/null || true
  if [[ -d "$workdir/old" ]]; then
    if git -C "$workdir/old" checkout -q "$local_sha" 2>/dev/null; then
      baseline_available=1
    else
      echo "WARN: baseline SHA $local_sha not reachable; conservative mode — all differences flagged as customized." >&2
      rm -rf "$workdir/old"
    fi
  fi
fi

# --- Per-version migrations (pre-sync) --------------------------------------
# Run migrations/<version>.sh for every upstream tag strictly greater than the
# project's current TEMPLATE_VERSION and less-than-or-equal-to the new one,
# in ascending order. Migrations handle file moves / renames / reshapes that
# the plain file-sync cannot. Most are no-ops.
all_tags=$(git -C "$workdir/new" tag -l 'v*' 2>/dev/null | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V || true)
migrations_to_run=()
past_local=0
for tag in $all_tags; do
  if [[ $past_local -eq 0 ]]; then
    [[ "$tag" == "$local_version" ]] && past_local=1
    continue
  fi
  migrations_to_run+=("$tag")
  [[ "$tag" == "$new_version" ]] && break
done

# Edge case: local_version doesn't appear in the tag list (e.g., pre-release
# or hand-stamped). In that case, past_local stays 0 and migrations_to_run is
# empty. Fall back: run every migration ≤ new_version, letting idempotency
# guards handle re-runs.
if [[ $past_local -eq 0 && ${#migrations_to_run[@]} -eq 0 ]]; then
  echo "NOTE: local_version $local_version does not match any upstream tag — running all migrations ≤ $new_version with idempotency guards." >&2
  for tag in $all_tags; do
    migrations_to_run+=("$tag")
    [[ "$tag" == "$new_version" ]] && break
  done
fi

if [[ ${#migrations_to_run[@]} -gt 0 ]]; then
  echo >&2
  echo "Running migrations between $local_version and $new_version:" >&2
  for v in "${migrations_to_run[@]}"; do
    mig="$workdir/new/migrations/$v.sh"
    if [[ -f "$mig" ]]; then
      echo "  [$v]" >&2
      if [[ $dry_run -eq 1 ]]; then
        echo "    (dry-run: would run $mig)" >&2
      else
        (
          cd "$project_root"
          export PROJECT_ROOT="$project_root"
          export OLD_VERSION="$local_version"
          export NEW_VERSION="$new_version"
          export TARGET_VERSION="$v"
          export WORKDIR_NEW="$workdir/new"
          [[ $baseline_available -eq 1 ]] && export WORKDIR_OLD="$workdir/old"
          bash "$mig"
        ) 2>&1 | sed 's/^/    /' >&2
      fi
    fi
  done
  echo >&2
fi

# Files the template ships (exclude template-only paths; keep in sync with scaffold.sh).
ship_files=$(cd "$workdir/new" && git ls-files \
  | grep -vE '^(VERSION|CHANGELOG\.md|CONTRIBUTING\.md)$' \
  | grep -vE '^(\.github/|dryrun-project/|migrations/)')

added=(); upgraded=(); kept=(); conflicts=()

for f in $ship_files; do
  new_path="$workdir/new/$f"
  proj_path="$project_root/$f"

  if [[ ! -f "$proj_path" ]]; then
    added+=("$f")
    if [[ $dry_run -eq 0 ]]; then
      mkdir -p "$(dirname "$proj_path")"
      cp "$new_path" "$proj_path"
    fi
    continue
  fi

  # Project already has this file. Compare.
  if [[ $baseline_available -eq 1 ]]; then
    old_path="$workdir/old/$f"
    if [[ -f "$old_path" ]] && cmp -s "$old_path" "$proj_path"; then
      # Unchanged since scaffold — safe to overwrite.
      if ! cmp -s "$new_path" "$proj_path"; then
        upgraded+=("$f")
        [[ $dry_run -eq 0 ]] && cp "$new_path" "$proj_path"
      fi
      continue
    fi
  else
    # No baseline — conservative: any divergence from upstream is treated as customization.
    :
  fi

  # Project diverges from baseline (or baseline unavailable).
  if cmp -s "$new_path" "$proj_path"; then
    : # Project already matches new upstream — coincidence, no action.
  else
    conflicts+=("$f")
    kept+=("$f")
  fi
done

# Stamp the new TEMPLATE_VERSION (only if not dry-run AND there are no conflicts,
# OR if the user accepts leaving conflicts in place — we do the latter by default).
if [[ $dry_run -eq 0 ]]; then
  cat > "$tv" <<EOF
$new_version
$new_sha
$(date -u +%Y-%m-%d)
EOF
fi

# --- Report ------------------------------------------------------------------
prefix=""
[[ $dry_run -eq 1 ]] && prefix="[dry-run] "

echo
echo "${prefix}Template upgrade: $local_version → $new_version ($new_sha)"
echo

if [[ ${#added[@]} -gt 0 ]]; then
  echo "${prefix}Added from upstream (${#added[@]}):"
  for f in "${added[@]}"; do echo "  + $f"; done
  echo
fi

if [[ ${#upgraded[@]} -gt 0 ]]; then
  echo "${prefix}Upgraded in place — unchanged since scaffold (${#upgraded[@]}):"
  for f in "${upgraded[@]}"; do echo "  ~ $f"; done
  echo
fi

if [[ ${#conflicts[@]} -gt 0 ]]; then
  echo "${prefix}⚠  Customized standard files — LEFT ALONE — review and merge manually (${#conflicts[@]}):"
  for f in "${conflicts[@]}"; do
    echo "  ! $f"
    echo "      diff <(git -C $workdir/new show HEAD:\"$f\") \"$project_root/$f\""
  done
  echo
  echo "  For each conflict, diff the upstream version against your customized"
  echo "  version and decide: keep yours, take upstream, or merge."
  echo
fi

# User-added files (not in template's ship_files) are implicitly preserved —
# they were never touched.
user_added_agents=$(find "$project_root/.claude/agents" -maxdepth 1 -name 'sme-*.md' \
                    ! -name 'sme-template.md' 2>/dev/null \
                    | sed "s|^$project_root/||" || true)
if [[ -n "$user_added_agents" ]]; then
  echo "${prefix}User-added SME agents preserved:"
  echo "$user_added_agents" | sed 's/^/  · /'
  echo
fi

if [[ $dry_run -eq 0 ]]; then
  echo "Done. TEMPLATE_VERSION now $new_version / $new_sha."
  [[ ${#conflicts[@]} -gt 0 ]] && echo "Resolve the ${#conflicts[@]} conflict(s) above, then commit."
else
  echo "(No changes written — this was a dry run.)"
fi
