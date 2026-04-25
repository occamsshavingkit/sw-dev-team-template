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

usage() {
  cat <<'EOF'
Usage: scripts/upgrade.sh [--dry-run | --verify | --help]

  --dry-run    Print the upgrade plan; change nothing.
  --verify     Verify project files match TEMPLATE_MANIFEST.lock.
               No network. Exit codes: 0 clean, 1 drift, 2 missing
               manifest, 3 corrupt manifest. (FW-ADR-0002, v0.14.0+)
  --help, -h   Print this help and exit.

With no flag, run the full upgrade. The script:
  - Clones the upstream template into a workdir.
  - Runs per-version migrations between TEMPLATE_VERSION and the
    upstream tag, in order.
  - Per shipped file, classifies as: added / upgraded / kept (project
    customisation wins) / conflict (both customised — flagged for
    human review).
  - Stamps the new TEMPLATE_VERSION and rewrites
    TEMPLATE_MANIFEST.lock on success.

Files listed in .template-customizations are skipped entirely (also
omitted from the manifest).
sme-<domain>.md agents and docs/pm/* artefacts are project-owned;
they are never overwritten.

See docs/INDEX.md for related upgrade contracts (scaffold.sh,
version-check.sh, migrations/README.md).
EOF
}

# Manifest helpers (FW-ADR-0002, v0.14.0).
# shellcheck source=lib/manifest.sh
source "$(dirname "$0")/lib/manifest.sh"

upstream="https://github.com/occamsshavingkit/sw-dev-team-template"
if [[ -n "${GH_TOKEN:-}" ]]; then
  upstream_auth="https://${GH_TOKEN}@github.com/occamsshavingkit/sw-dev-team-template"
else
  upstream_auth="$upstream"
fi
project_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
tv="$project_root/TEMPLATE_VERSION"

# Argument parsing (issue #58 — --help / unknown flags should print
# usage, not run an upgrade). --verify per FW-ADR-0002.
dry_run=0
verify_mode=0
case "${1:-}" in
  "")              ;;
  "--dry-run")     dry_run=1 ;;
  "--verify")      verify_mode=1 ;;
  "--help"|"-h")   usage; exit 0 ;;
  *)               echo "ERROR: unknown flag: $1" >&2; echo >&2; usage >&2; exit 2 ;;
esac

if [[ ! -f "$tv" ]]; then
  echo "ERROR: no TEMPLATE_VERSION at project root. Not a scaffolded project?" >&2
  exit 1
fi

local_version="$(head -1 "$tv" | tr -d '[:space:]')"
local_sha="$(sed -n '2p' "$tv" | tr -d '[:space:]')"

# Verify mode short-circuits before clone — no network needed.
# (FW-ADR-0002.)
if [[ $verify_mode -eq 1 ]]; then
  rc=0
  manifest_verify "$project_root" "$project_root/TEMPLATE_MANIFEST.lock" || rc=$?
  exit "$rc"
fi

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

echo "Cloning upstream..." >&2
git clone -q "$upstream_auth" "$workdir/new" 2>/dev/null || {
  echo "ERROR: clone of $upstream failed. Check network / auth." >&2
  exit 1
}

# --- Self-bootstrap (issue #63 follow-up) ----------------------------------
# Before we run any sync logic, make sure THIS upgrade.sh and its lib are
# the upstream's current versions. Older versions have buggy in-place cp
# that mutates the running script's inode mid-execution. Atomically install
# upstream's upgrade.sh + lib, then re-exec — the new code does the actual
# upgrade with atomic_install + correct manifest semantics.
if [[ "${SWDT_BOOTSTRAPPED:-}" != "1" ]]; then
  upstream_upgrade="$workdir/new/scripts/upgrade.sh"
  upstream_lib="$workdir/new/scripts/lib/manifest.sh"
  local_lib="$(dirname "$0")/lib/manifest.sh"
  bootstrap=0
  if [[ -f "$upstream_upgrade" ]] && ! cmp -s "$upstream_upgrade" "$0"; then
    bootstrap=1
  fi
  if [[ -f "$upstream_lib" ]]; then
    if [[ ! -f "$local_lib" ]] || ! cmp -s "$upstream_lib" "$local_lib"; then
      bootstrap=1
    fi
  fi
  if [[ $bootstrap -eq 1 ]]; then
    echo "Bootstrapping: replacing local scripts/upgrade.sh + scripts/lib/manifest.sh with upstream and re-execing." >&2
    # Atomic mv-rename so bash's open fd stays on the original (now-unlinked)
    # inode through the rest of THIS run. The exec below replaces the process.
    if [[ -f "$upstream_upgrade" ]]; then
      cp "$upstream_upgrade" "$0.tmp.$$"
      mv "$0.tmp.$$" "$0"
    fi
    if [[ -f "$upstream_lib" ]]; then
      mkdir -p "$(dirname "$0")/lib"
      cp "$upstream_lib" "$(dirname "$0")/lib/manifest.sh.tmp.$$"
      mv "$(dirname "$0")/lib/manifest.sh.tmp.$$" "$(dirname "$0")/lib/manifest.sh"
    fi
    # Reuse the workdir we just cloned — no need to clone twice. Hand the
    # path to the re-execed self via env; child trap takes ownership of
    # cleanup.
    export SWDT_BOOTSTRAPPED=1
    export SWDT_PRESTAGED_WORKDIR="$workdir"
    trap '' EXIT  # don't double-rm; child owns the workdir now
    exec bash "$0" "$@"
  fi
fi

# Re-execed instance: workdir was pre-staged by the parent.
if [[ -n "${SWDT_PRESTAGED_WORKDIR:-}" && -d "$SWDT_PRESTAGED_WORKDIR/new" ]]; then
  rm -rf "$workdir"
  workdir="$SWDT_PRESTAGED_WORKDIR"
  trap 'rm -rf "$workdir"' EXIT
fi

new_version="$(cat "$workdir/new/VERSION" | tr -d '[:space:]')"
new_sha="$(git -C "$workdir/new" rev-parse HEAD)"

if [[ "$local_version" == "$new_version" ]]; then
  # Stamp matches upstream. Closes the #61 bug: do not short-circuit
  # on stamp alone — verify the manifest first. If the manifest is
  # present and clean, truly nothing to do. Otherwise drift exists
  # (or the manifest is missing on a pre-v0.14.0 project that needs
  # the migration), so fall through to the sync flow.
  manifest_path="$project_root/TEMPLATE_MANIFEST.lock"
  if [[ -f "$manifest_path" ]] \
     && manifest_verify "$project_root" "$manifest_path" >/dev/null 2>&1; then
    echo "Template already at $local_version — files match manifest, nothing to do." >&2
    exit 0
  fi
  if [[ ! -f "$manifest_path" ]]; then
    echo "WARN: stamp says $local_version but TEMPLATE_MANIFEST.lock is missing." >&2
    echo "       Falling through to sync to (re)establish a manifest. (FW-ADR-0002, #61)" >&2
  else
    echo "WARN: stamp says $local_version but file tree drifts from manifest." >&2
    echo "       Falling through to sync to reconcile. (FW-ADR-0002, #61)" >&2
  fi
  # Fall through to the sync flow below.
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
all_tags=$(git -C "$workdir/new" tag -l 'v*' 2>/dev/null | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+(-[A-Za-z0-9.]+)?$' | sort -V || true)
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

# Files the template ships to downstream projects.
# This exclusion list MUST match scaffold.sh's --exclude list (template-only
# files that downstream projects should never receive).
ship_files=$(cd "$workdir/new" && git ls-files \
  | grep -vE '^(VERSION|CHANGELOG\.md|CONTRIBUTING\.md|LICENSE)$' \
  | grep -vE '^(\.github/|dryrun-project/|examples/|migrations/)' \
  | grep -vE '^scripts/smoke-test\.sh$')

# --- Load customization preserve-list ----------------------------------------
# Projects can declare files they have permanently customized by listing them
# (one path per line, project-root-relative) in .template-customizations.
# Those paths are skipped entirely by upgrade: never overwritten, never
# flagged as conflicts.
declare -A preserve_list=()
customizations_file="$project_root/.template-customizations"
if [[ -f "$customizations_file" ]]; then
  while IFS= read -r line; do
    # Strip comments and blanks.
    line="${line%%#*}"
    line="$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    [[ -z "$line" ]] && continue
    preserve_list["$line"]=1
  done < "$customizations_file"
fi

# Agent-name-aware compare (issue #64).
#
# `.claude/agents/<canonical>.md` files carry a project-specific `name:`
# frontmatter line after Step 3 (muppet rename). Treating that line as a
# customization re-flags every agent as a conflict on every upgrade even
# when the agent body is byte-identical. Strip the name line before the
# 3-way compare; splice the project's name line back into the upstream
# version after install.
#
# Returns 0 if files match modulo `name:`, non-zero otherwise.
agent_cmp() {
  diff <(grep -v '^name:[[:space:]]' "$1") <(grep -v '^name:[[:space:]]' "$2") >/dev/null 2>&1
}

# After installing upstream's version of an agent file, restore the
# project's name: line if there was one.
agent_splice_name() {
  local installed="$1"
  local name_line="$2"
  [[ -z "$name_line" ]] && return 0
  # Replace upstream's `name: <canonical>` with the project's name line.
  sed -i "s|^name:[[:space:]].*\$|$name_line|" "$installed"
}

# Atomic in-place replacement helper (issue #63).
#
# `cp src dst` truncates+rewrites dst in place, mutating the inode.
# Catastrophic when dst is the *running* `scripts/upgrade.sh` (or any
# other script bash is reading from) — bash reads from the open fd,
# the file under that fd flips to new content mid-parse, parse errors
# erupt at random offsets, sync loop aborts before stamping.
#
# Fix: stage to `dst.tmp`, then `mv` (rename-over). On the same
# filesystem, `mv` is atomic and changes the inode — bash's open fd
# continues pointing at the original inode (now unlinked but still
# resident), the running script finishes cleanly. The next invocation
# picks up the new inode.
#
# Always same-filesystem: tmp lives next to dst.
atomic_install() {
  local src="$1"
  local dst="$2"
  cp "$src" "$dst.tmp.$$"
  mv "$dst.tmp.$$" "$dst"
}

added=(); upgraded=(); kept=(); conflicts=(); preserved=()

for f in $ship_files; do
  new_path="$workdir/new/$f"
  proj_path="$project_root/$f"

  # Honor .template-customizations: skip preserved paths entirely.
  if [[ -n "${preserve_list[$f]:-}" ]]; then
    preserved+=("$f")
    continue
  fi

  if [[ ! -f "$proj_path" ]]; then
    added+=("$f")
    if [[ $dry_run -eq 0 ]]; then
      mkdir -p "$(dirname "$proj_path")"
      atomic_install "$new_path" "$proj_path"
    fi
    continue
  fi

  # Determine if this is an agent file with a possible muppet rename.
  # Capture the project's `name:` line so we can splice it back after
  # an in-place upgrade, instead of clobbering it with upstream's
  # canonical name.
  is_agent=0
  agent_name_line=""
  case "$f" in
    .claude/agents/*.md)
      is_agent=1
      agent_name_line="$(grep -m1 '^name:[[:space:]]' "$proj_path" 2>/dev/null || true)"
      ;;
  esac

  # Compare helpers. For agent files, ignore the `name:` line.
  files_match() {
    if [[ $is_agent -eq 1 ]]; then
      agent_cmp "$1" "$2"
    else
      cmp -s "$1" "$2"
    fi
  }

  # Project already has this file. Compare.
  if [[ $baseline_available -eq 1 ]]; then
    old_path="$workdir/old/$f"
    if [[ -f "$old_path" ]] && files_match "$old_path" "$proj_path"; then
      # Unchanged since scaffold (modulo agent name) — safe to overwrite.
      if ! files_match "$new_path" "$proj_path"; then
        upgraded+=("$f")
        if [[ $dry_run -eq 0 ]]; then
          atomic_install "$new_path" "$proj_path"
          [[ $is_agent -eq 1 ]] && agent_splice_name "$proj_path" "$agent_name_line"
        fi
      fi
      continue
    fi
  else
    # No baseline — conservative: any divergence from upstream is treated as customization.
    :
  fi

  # Project diverges from baseline (or baseline unavailable).
  if files_match "$new_path" "$proj_path"; then
    : # Project already matches new upstream (modulo agent name) — coincidence, no action.
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

  # Rewrite the per-file manifest to reflect the post-upgrade state.
  # FW-ADR-0002. Paths come from the upstream clone (authoritative
  # ship_files list at the upgraded version); SHAs come from the
  # project tree (post-sync state). v0.14.1 split — see
  # scripts/lib/manifest.sh.
  manifest_write "$workdir/new" "$project_root" "$project_root/TEMPLATE_MANIFEST.lock"
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

# Detect newly-added standard agents — these require a Claude Code
# session restart before they become dispatchable via subagent_type.
# sme-*.md files are user-owned (not shipped) so they never appear in
# the 'added' list; no filtering needed here beyond the prefix match.
# Upstream issue #36.
new_agents=()
for f in "${added[@]:-}"; do
  case "$f" in
    .claude/agents/*.md) new_agents+=("$f") ;;
  esac
done
if [[ ${#new_agents[@]} -gt 0 ]]; then
  echo "${prefix}ACTION REQUIRED: restart Claude Code to register ${#new_agents[@]} new agent(s)."
  echo "${prefix}  The agent registry is initialized at session start and does not rescan"
  echo "${prefix}  .claude/agents/ mid-session. Dispatches via subagent_type will fail with"
  echo "${prefix}  \"Agent type not found\" until the session is restarted. Upstream issue #36."
  for f in "${new_agents[@]}"; do echo "${prefix}  · $f"; done
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

if [[ ${#preserved[@]} -gt 0 ]]; then
  echo "${prefix}Preserved per .template-customizations (${#preserved[@]}):"
  for f in "${preserved[@]}"; do echo "  = $f"; done
  echo
fi

if [[ $dry_run -eq 0 ]]; then
  echo "Done. TEMPLATE_VERSION now $new_version / $new_sha."
  [[ ${#conflicts[@]} -gt 0 ]] && echo "Resolve the ${#conflicts[@]} conflict(s) above, then commit."
else
  echo "(No changes written — this was a dry run.)"
fi
