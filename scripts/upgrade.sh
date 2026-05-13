#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
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
Usage: scripts/upgrade.sh [--dry-run | --verify | --resolve | --target <ver> |
                          --self-test-semver | --help]

  --dry-run         Print the upgrade plan; change nothing.
  --verify          Verify project files match TEMPLATE_MANIFEST.lock,
                    AND that no entries in .template-conflicts.json are
                    still classified "conflict" (issue #107).
                    No network. Exit codes: 0 clean, 1 drift / unresolved
                    conflicts, 2 missing manifest, 3 corrupt manifest.
                    (FW-ADR-0002, v0.14.0+; conflict tracking added
                    after issue #107.)
  --resolve         Re-check entries in .template-conflicts.json and
                    drop those whose project SHA shows a real merge
                    happened (or that took upstream wholesale).
                    local_only_kept and accepted_local entries are
                    pruned automatically. No network. (Issue #107.)
  --self-test-semver
                    Run the SemVer-sort regression guard for issue #108
                    and exit. No project state needed.
  --target <ver>    Pin the upgrade to a specific upstream tag (e.g.
                    v0.14.4). Validates the tag exists, checks it out
                    in the upstream clone, runs migrations between
                    current TEMPLATE_VERSION and the target, stamps
                    target's tag. Without this flag, upgrade.sh
                    targets the latest stable upstream tag for stable
                    projects, or the latest upstream tag for projects
                    already on a pre-release track. (Issues #60/#68.)
  --help, -h        Print this help and exit.

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
sme-<domain>.md agents, .claude/agents/<role>-local.md supplements,
and docs/pm/* artefacts are project-owned; they are never overwritten.

See docs/INDEX.md for related upgrade contracts (scaffold.sh,
version-check.sh, migrations/README.md).
EOF
}

# Older bootstrap scripts may copy only this script plus manifest.sh,
# then re-exec us with SWDT_PRESTAGED_WORKDIR. Recover required libs
# before the first source so the new bootstrap can take over.
script_dir="$(dirname "$0")"
ensure_prestaged_required_libs() {
  local prestaged_lib_dir
  local lib_name
  local upstream_lib
  local local_lib

  if [[ -z "${SWDT_PRESTAGED_WORKDIR:-}" ]]; then
    return 0
  fi
  prestaged_lib_dir="$SWDT_PRESTAGED_WORKDIR/new/scripts/lib"
  if [[ ! -d "$prestaged_lib_dir" ]]; then
    return 0
  fi

  mkdir -p "$script_dir/lib"
  for lib_name in manifest.sh semver.sh; do
    upstream_lib="$prestaged_lib_dir/$lib_name"
    local_lib="$script_dir/lib/$lib_name"
    if [[ ! -f "$local_lib" && -f "$upstream_lib" ]]; then
      cp "$upstream_lib" "$local_lib.tmp.$$"
      mv "$local_lib.tmp.$$" "$local_lib"
    fi
  done
}
ensure_prestaged_required_libs

# Manifest helpers (FW-ADR-0002, v0.14.0).
# shellcheck source=scripts/lib/manifest.sh
source "$script_dir/lib/manifest.sh"

# SemVer tag sort lives in scripts/lib/semver.sh — shared with
# scripts/stepwise-smoke.sh. Single source of truth (issue #108).
# shellcheck source=scripts/lib/semver.sh
source "$script_dir/lib/semver.sh"

# FIRST ACTIONS helpers (issue #73).
first_actions_lib="$script_dir/lib/first-actions.sh"
if [[ -f "$first_actions_lib" ]]; then
  # shellcheck source=scripts/lib/first-actions.sh
  # shellcheck disable=SC1091
  source "$first_actions_lib"
fi

# Upstream URL is overrideable via SWDT_UPSTREAM_URL. Used by
# scripts/stepwise-smoke.sh to point at a local clone with specific
# tags checked out — supports stepwise upgrade testing without
# polluting the live remote. Falls back to the canonical GitHub URL
# for normal upgrades.
upstream="${SWDT_UPSTREAM_URL:-https://github.com/occamsshavingkit/sw-dev-team-template}"
if [[ -n "${GH_TOKEN:-}" && "$upstream" == https://github.com/* ]]; then
  upstream_auth="${upstream/https:\/\//https://${GH_TOKEN}@}"
else
  upstream_auth="$upstream"
fi
project_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
tv="$project_root/TEMPLATE_VERSION"

# Argument parsing (issue #58 — --help / unknown flags should print
# usage, not run an upgrade). --verify per FW-ADR-0002.
# --target per issue #68.
dry_run=0
verify_mode=0
resolve_mode=0
target_version=""
original_args=("$@")
while [[ $# -gt 0 ]]; do
  case "$1" in
    "--dry-run")     dry_run=1; shift ;;
    "--verify")      verify_mode=1; shift ;;
    "--target")
      if [[ $# -lt 2 || -z "${2:-}" || "${2:-}" == --* ]]; then
        echo "ERROR: --target requires a tag argument (e.g. --target v0.14.4)" >&2
        usage >&2
        exit 2
      fi
      target_version="$2"
      shift 2 ;;
    "--self-test-semver")
      # Issue #108 regression guard. Pure function test, no project
      # state needed. Exits before TEMPLATE_VERSION check.
      semver_sort_tags_self_test
      exit $? ;;
    "--resolve")     resolve_mode=1; shift ;;
    "--help"|"-h")   usage; exit 0 ;;
    *)               echo "ERROR: unknown flag: $1" >&2; echo >&2; usage >&2; exit 2 ;;
  esac
done

if [[ ! -f "$tv" ]]; then
  echo "ERROR: no TEMPLATE_VERSION at project root. Not a scaffolded project?" >&2
  exit 1
fi

local_version="$(head -1 "$tv" | tr -d '[:space:]')"
local_sha="$(sed -n '2p' "$tv" | tr -d '[:space:]')"

# Verify mode short-circuits before clone — no network needed.
# (FW-ADR-0002.) Issue #107: also report unresolved conflicts from
# .template-conflicts.json. Manifest integrity drift takes precedence;
# unresolved conflicts surface separately when the manifest is clean.
if [[ $verify_mode -eq 1 ]]; then
  rc=0
  manifest_verify "$project_root" "$project_root/TEMPLATE_MANIFEST.lock" || rc=$?
  conflicts_path="$project_root/.template-conflicts.json"
  if [[ -f "$conflicts_path" ]]; then
    # Count unresolved entries (classified == "conflict"). Cheap grep
    # — the JSON is generated with one entry per line, no nested
    # structure, so a substring match is unambiguous.
    unresolved=$(grep -c '"classified": "conflict"' "$conflicts_path" || true)
    if [[ "$unresolved" -gt 0 ]]; then
      if [[ $rc -eq 0 ]]; then
        echo "Unresolved conflicts: $unresolved; merge them and run scripts/upgrade.sh --resolve to clear." >&2
        rc=1
      else
        echo "Also: $unresolved unresolved conflict(s) tracked in .template-conflicts.json." >&2
      fi
    fi
  fi
  exit "$rc"
fi

# --resolve mode: re-check entries in .template-conflicts.json and
# remove those whose project SHA changed after the conflict was
# recorded and now either matches upstream or differs from BOTH
# baseline and upstream (indicating a real hand-merge). Files in
# local_only_kept / accepted_local are never blockers and are pruned
# automatically.
# Issue #107.
if [[ $resolve_mode -eq 1 ]]; then
  conflicts_path="$project_root/.template-conflicts.json"
  if [[ ! -f "$conflicts_path" ]]; then
    echo "No .template-conflicts.json present — nothing to resolve." >&2
    exit 0
  fi
  # LOCKSTEP: the sed extractors below depend on the fixed printf
  # shape produced by emit_entry() in the writer (one entry per line,
  # quoted-string fields in fixed order). Do not change the shape on
  # one side without updating the other.
  #
  # Schema 1 only. If we add fields to entries in a future schema,
  # --resolve must preserve unrecognized fields on re-emit; the
  # current re-emit fixes the field set to {path, classified,
  # baseline_sha, upstream_sha, project_sha} and would silently drop
  # anything else. Bump the schema number and gate accordingly.
  tmp_out="$conflicts_path.tmp.$$"
  removed=0
  kept_unresolved=0
  {
    printf '{\n'
    printf '  "schema": 1,\n'
    printf '  "generated": "%s",\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    tv_now="$(head -1 "$tv" | tr -d '[:space:]')"
    printf '  "template_version": "%s",\n' "$tv_now"
    printf '  "entries": [\n'
    first=1
    while IFS= read -r entry_line; do
      [[ "$entry_line" =~ ^\ +\{\"path\" ]] || continue
      # Extract fields. Format is fixed by emit_entry above.
      e_path=$(echo "$entry_line" | sed -n 's/.*"path": "\([^"]*\)".*/\1/p')
      e_class=$(echo "$entry_line" | sed -n 's/.*"classified": "\([^"]*\)".*/\1/p')
      e_baseline=$(echo "$entry_line" | sed -n 's/.*"baseline_sha": "\([^"]*\)".*/\1/p')
      e_upstream=$(echo "$entry_line" | sed -n 's/.*"upstream_sha": "\([^"]*\)".*/\1/p')
      e_project=$(echo "$entry_line" | sed -n 's/.*"project_sha": "\([^"]*\)".*/\1/p')
      [[ -z "$e_path" ]] && continue

      # Auto-prune classes that were never blockers.
      if [[ "$e_class" != "conflict" ]]; then
        removed=$((removed + 1))
        continue
      fi

      # Recompute current project SHA.
      proj_now=""
      [[ -f "$project_root/$e_path" ]] && proj_now="$(manifest_file_sha "$project_root/$e_path")"

      # Resolution heuristic per #107: project SHA must first differ
      # from the recorded conflict snapshot. Without that post-conflict
      # action, a pre-existing local customization that already differs
      # from baseline and upstream is still unresolved.
      resolved=0
      if [[ -n "$proj_now" && "$proj_now" != "$e_project" ]]; then
        # Project SHA matches upstream (took upstream side) → drop.
        # Project SHA differs from both baseline and upstream → real
        # hand-merge happened, drop entry. Project SHA matches baseline
        # OR file missing → still unresolved.
        if [[ "$proj_now" == "$e_upstream" ]]; then
          resolved=1
        elif [[ -n "$e_baseline" && "$proj_now" != "$e_baseline" && "$proj_now" != "$e_upstream" ]]; then
          resolved=1
        fi
      fi

      if [[ $resolved -eq 1 ]]; then
        removed=$((removed + 1))
        continue
      fi

      [[ $first -eq 0 ]] && printf ',\n'
      first=0
      # Re-emit the entry verbatim, but with refreshed project_sha.
      printf '    {"path": "%s", "classified": "conflict", "baseline_sha": "%s", "upstream_sha": "%s", "project_sha": "%s"}' \
        "$e_path" "$e_baseline" "$e_upstream" "$proj_now"
      kept_unresolved=$((kept_unresolved + 1))
    done < "$conflicts_path"
    printf '\n  ]\n}\n'
  } > "$tmp_out"
  mv "$tmp_out" "$conflicts_path"
  if [[ $kept_unresolved -eq 0 ]]; then
    rm -f "$conflicts_path"
    echo "Resolved $removed entr$([[ $removed -eq 1 ]] && echo 'y' || echo 'ies'); .template-conflicts.json removed."
  else
    echo "Cleared $removed entr$([[ $removed -eq 1 ]] && echo 'y' || echo 'ies'); $kept_unresolved still unresolved."
  fi
  exit 0
fi

if [[ -n "${SWDT_PRESTAGED_WORKDIR:-}" && -d "$SWDT_PRESTAGED_WORKDIR/new" ]]; then
  # Re-execed instance: workdir was pre-staged by the parent. Adopt it
  # before cloning so dry-run bootstrap stays no-write and no-extra-network.
  workdir="$SWDT_PRESTAGED_WORKDIR"
  trap 'rm -rf "$workdir"' EXIT
else
  workdir="$(mktemp -d)"
  trap 'rm -rf "$workdir"' EXIT
  echo "Cloning upstream..." >&2
  git clone -q "$upstream_auth" "$workdir/new" 2>/dev/null || {
    echo "ERROR: clone of $upstream failed. Check network / auth." >&2
    exit 1
  }
fi

# --- Select upstream target before bootstrap ----------------------------------
# Check out the intended upstream tag before any other steps run.
# Bootstrap, baseline-clone, and sync all see the selected target state.
# VERSION inside the clone is the selected target's VERSION, so
# new_version derived below picks up correctly.
if [[ -n "$target_version" ]]; then
  if ! git -C "$workdir/new" rev-parse --verify --quiet "refs/tags/$target_version" >/dev/null; then
    echo "ERROR: --target $target_version is not a known tag in $upstream." >&2
    echo "  Recent tags (last 10):" >&2
    git -C "$workdir/new" tag -l 'v*' | semver_sort_tags | tail -10 | sed 's/^/    /' >&2
    exit 2
  fi
  echo "Pinning upgrade to --target $target_version" >&2
  git -C "$workdir/new" checkout -q "$target_version"
else
  all_upstream_tags="$(git -C "$workdir/new" tag -l 'v*' 2>/dev/null | semver_sort_tags || true)"
  if [[ "$local_version" == *-* ]]; then
    target_candidates="$all_upstream_tags"
  else
    target_candidates="$(echo "$all_upstream_tags" | grep -vE -- '-[0-9A-Za-z.-]+$' || true)"
  fi

  if [[ -z "$target_candidates" ]]; then
    echo "ERROR: no suitable upstream release tags found in $upstream." >&2
    if [[ "$local_version" != *-* ]]; then
      echo "       Stable projects do not default-upgrade to pre-release tags; use --target to opt in." >&2
    fi
    exit 2
  fi

  selected_target="$(echo "$target_candidates" | tail -1)"
  if [[ "$local_version" == *-* ]]; then
    echo "Default target: latest upstream tag $selected_target (pre-release track)." >&2
  else
    echo "Default target: latest stable upstream tag $selected_target." >&2
  fi
  git -C "$workdir/new" checkout -q "$selected_target"
fi

# --- Self-bootstrap (issue #63 follow-up) ----------------------------------
# Before we run any sync logic, make sure THIS upgrade.sh and its lib are
# the upstream's current versions. Older versions have buggy in-place cp
# that mutates the running script's inode mid-execution. Atomically install
# upstream's upgrade.sh + lib, then re-exec — the new code does the actual
# upgrade with atomic_install + correct manifest semantics.
if [[ "${SWDT_BOOTSTRAPPED:-}" != "1" ]]; then
  upstream_upgrade="$workdir/new/scripts/upgrade.sh"
  upstream_lib_dir="$workdir/new/scripts/lib"
  local_lib_dir="$(dirname "$0")/lib"
  bootstrap=0
  if [[ -f "$upstream_upgrade" ]] && ! cmp -s "$upstream_upgrade" "$0"; then
    bootstrap=1
  fi
  if [[ -d "$upstream_lib_dir" ]]; then
    while IFS= read -r upstream_lib; do
      local_lib="$local_lib_dir/$(basename "$upstream_lib")"
      if [[ ! -f "$local_lib" ]] || ! cmp -s "$upstream_lib" "$local_lib"; then
        bootstrap=1
        break
      fi
    done < <(find "$upstream_lib_dir" -maxdepth 1 -type f -name '*.sh' | sort)
  fi
  if [[ $bootstrap -eq 1 ]]; then
    if [[ $dry_run -eq 1 ]]; then
      echo "Bootstrapping: dry-run re-execing upstream upgrade helpers without writing local files." >&2
      export SWDT_BOOTSTRAPPED=1
      export SWDT_PRESTAGED_WORKDIR="$workdir"
      trap '' EXIT  # child owns the workdir now
      exec bash "$upstream_upgrade" "${original_args[@]}"
    fi
    echo "Bootstrapping: replacing local upgrade helpers with upstream and re-execing." >&2
    # Atomic mv-rename so bash's open fd stays on the original (now-unlinked)
    # inode through the rest of THIS run. The exec below replaces the process.
    if [[ -f "$upstream_upgrade" ]]; then
      cp "$upstream_upgrade" "$0.tmp.$$"
      mv "$0.tmp.$$" "$0"
    fi
    if [[ -d "$upstream_lib_dir" ]]; then
      mkdir -p "$local_lib_dir"
      while IFS= read -r upstream_lib; do
        lib_name="$(basename "$upstream_lib")"
        cp "$upstream_lib" "$local_lib_dir/$lib_name.tmp.$$"
        mv "$local_lib_dir/$lib_name.tmp.$$" "$local_lib_dir/$lib_name"
      done < <(find "$upstream_lib_dir" -maxdepth 1 -type f -name '*.sh' | sort)
    fi
    # Reuse the workdir we just cloned — no need to clone twice. Hand the
    # path to the re-execed self via env; child trap takes ownership of
    # cleanup.
    export SWDT_BOOTSTRAPPED=1
    export SWDT_PRESTAGED_WORKDIR="$workdir"
    trap '' EXIT  # don't double-rm; child owns the workdir now
    exec bash "$0" "${original_args[@]}"
  fi
fi

if declare -F first_actions_step0_warning >/dev/null; then
  first_actions_step0_warning "$project_root" "upgrade"
fi

new_version="$(tr -d '[:space:]' < "$workdir/new/VERSION")"
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
    expected_paths="$workdir/expected-manifest-paths.txt"
    actual_paths="$workdir/actual-manifest-paths.txt"
    manifest_ship_files "$workdir/new" "$project_root" > "$expected_paths"
    awk '
      /^[[:space:]]*#/ || /^[[:space:]]*$/ { next }
      {
        sep = index($0, "  ")
        if (sep > 0) {
          print substr($0, sep + 2)
        }
      }
    ' "$manifest_path" | sort > "$actual_paths"
    if cmp -s "$expected_paths" "$actual_paths"; then
      echo "Template already at $local_version — files match manifest, nothing to do." >&2
      exit 0
    fi
    echo "WARN: stamp says $local_version and manifest hashes verify, but manifest path set differs from upstream." >&2
    if comm -23 "$expected_paths" "$actual_paths" | grep -q .; then
      echo "       Manifest is missing upstream shipped paths; falling through to sync/regenerate. (#129)" >&2
    else
      echo "       Manifest has path-set drift; falling through to sync/regenerate. (#129)" >&2
    fi
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
all_tags=$(git -C "$workdir/new" tag -l 'v*' 2>/dev/null | semver_sort_tags || true)
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
# files that downstream projects should never receive). Anything stripped at
# scaffold time MUST also be stripped here, otherwise an upgrade re-ships
# the maintainer's release-planning artefacts into downstream (regression
# of F-002 from the v1.0-rc3 onboarding audit).
ship_files=$(cd "$workdir/new" && git ls-files \
  | grep -vE '^(VERSION|CHANGELOG\.md|CONTRIBUTING\.md|LICENSE|ROADMAP\.md)$' \
  | grep -vE '^(\.github/|dryrun-project/|examples/|migrations/)' \
  | grep -vE '^\.claude/agents/[^/]+-local\.md$' \
  | grep -vE '^docs/(audits|v2|proposals)/' \
  | grep -vE '^docs/v1\.0-rc3-checklist\.md$|^docs/v1\.0-rc4-stabilization\.md$|^docs/v1\.0\.0-final-checklist\.md$' \
  | grep -vE '^docs/pm/' \
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

# rc4 introduced a shipped AGENTS.md Codex adapter. Some pre-rc4 projects
# may already have a generated claude-mem context stub at AGENTS.md with no
# binding adapter content. Treat that generated stub as absent so upgrade
# installs the adapter instead of preserving a non-functional local file.
memory_only_agents_stub() {
  local path="$1"
  [[ -f "$path" ]] || return 1
  grep -q '<claude-mem-context>' "$path" || return 1
  grep -q '</claude-mem-context>' "$path" || return 1
  ! grep -q "main Codex session plays \`tech-lead\` directly" "$path" || return 1
  ! grep -q '^## Role Binding' "$path" || return 1
}

install_agents_adapter_over_memory_stub() {
  local src="$1"
  local dst="$2"
  local tmp="$dst.tmp.$$"
  awk '
    /^<claude-mem-context>$/ { skip=1; next }
    /^<\/claude-mem-context>$/ { skip=0; next }
    skip == 0 { print }
  ' "$src" > "$tmp"
  printf '\n\n' >> "$tmp"
  sed -n '/^<claude-mem-context>$/,/^<\/claude-mem-context>$/p' "$dst" >> "$tmp"
  mv "$tmp" "$dst"
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

shortstat_between() {
  local from="$1"
  local to="$2"

  if [[ -f "$from" && -f "$to" ]]; then
    git diff --no-index --shortstat "$from" "$to" 2>/dev/null || true
  else
    echo "(baseline unavailable)"
  fi
}

added=(); upgraded=(); kept=(); conflicts=(); local_only_kept=(); accepted_local=(); preserved=()
# Issue #110: pre-existing collisions — files that the project had
# locally BEFORE upstream started shipping them. Identified by:
# baseline-tree did NOT contain the file, project tree DOES, upstream
# DOES, and content differs. Surfaced as an ACTION REQUIRED line so
# the user can either accept-upstream (rm + rerun) or pin local
# (add to .template-customizations).
preexisting_collisions=()

# Pre-load manifest SHAs for issue #109 stretch: a previous upgrade may
# have accepted a merged state that differs from the scaffold-baseline
# old_path. Without consulting the manifest, that file lands in
# conflicts[] every rerun even when the manifest accepted the merge.
# Format per scripts/lib/manifest.sh manifest_write: exactly two spaces
# between SHA and path (`<sha>  <path>`), enforced at write time. The
# length-64 SHA check below skips malformed lines defensively; the
# parser stays inline (rather than calling a manifest_lib helper) to
# avoid pulling the verifier's strict-error semantics into the upgrade
# classification path.
declare -A manifest_sha=()
manifest_path_pre="$project_root/TEMPLATE_MANIFEST.lock"
if [[ -f "$manifest_path_pre" ]]; then
  while IFS= read -r m_line; do
    [[ -z "$m_line" || "${m_line:0:1}" == "#" ]] && continue
    m_sha="${m_line%%  *}"
    m_path="${m_line#*  }"
    [[ ${#m_sha} -eq 64 && -n "$m_path" ]] || continue
    manifest_sha["$m_path"]="$m_sha"
  done < "$manifest_path_pre"
fi

for f in $ship_files; do
  new_path="$workdir/new/$f"
  proj_path="$project_root/$f"

  # Honor .template-customizations: skip preserved paths entirely.
  if [[ -n "${preserve_list[$f]:-}" ]]; then
    preserved+=("$f")
    continue
  fi

  if [[ "$f" == "AGENTS.md" ]] && memory_only_agents_stub "$proj_path"; then
    upgraded+=("$f")
    if [[ $dry_run -eq 0 ]]; then
      install_agents_adapter_over_memory_stub "$new_path" "$proj_path"
    fi
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
    # Issue #109 stretch: if the manifest recorded this file's SHA at a
    # prior accepted-merge state and the project file still matches that
    # SHA (and the manifest SHA differs from upstream-new SHA), this is
    # an accepted local merge — not a fresh conflict.
    #
    # Silent-equality case (manifest_sha == new_sha_f): the manifest's
    # recorded SHA matches the upstream we're upgrading to, but the
    # project file diverges from both. That means the project drifted
    # AFTER the last manifest write (manual edit, partial revert, etc.).
    # We deliberately do NOT short-circuit to accepted_local[] here;
    # bucketing falls through to baseline-derived classification
    # (local_only_kept[] vs conflicts[]) below, which is correct — the
    # manifest isn't telling us anything new.
    accepted_via_manifest=0
    if [[ -n "${manifest_sha[$f]:-}" ]]; then
      proj_sha="$(manifest_file_sha "$proj_path")"
      new_sha_f="$(manifest_file_sha "$new_path")"
      if [[ "$proj_sha" == "${manifest_sha[$f]}" && "${manifest_sha[$f]}" != "$new_sha_f" ]]; then
        accepted_local+=("$f")
        accepted_via_manifest=1
      fi
    fi
    if [[ $accepted_via_manifest -eq 0 ]]; then
      # Issue #112: distinguish "local-only customization (upstream
      # unchanged)" from "true conflict (both sides changed)". Only
      # the latter blocks the upgrade.
      #
      # Baseline-unavailable note: when $baseline_available -eq 0, the
      # local_only_kept[] branch is unreachable by design — we cannot
      # prove upstream is unchanged without the scaffold-baseline tree,
      # so the conservative classifier sends the file to conflicts[].
      # That matches the "no baseline" comment a few lines up.
      if [[ $baseline_available -eq 1 && -f "$workdir/old/$f" ]] \
         && cmp -s "$workdir/old/$f" "$workdir/new/$f"; then
        local_only_kept+=("$f")
      else
        conflicts+=("$f")
        # Issue #110: pre-existing collision — file present in project
        # AND upstream but absent from baseline. Means upstream began
        # shipping a file the project already had. The user must
        # decide: take upstream (rm the local then rerun) or pin local
        # (add to .template-customizations).
        #
        # Gap (intentional): when baseline_available == 0 the same
        # situation is silently lumped into plain conflicts[]. We
        # cannot prove upstream just-introduced the file without the
        # scaffold-baseline tree. Affects very old projects whose
        # scaffold SHA is unreachable. Mitigation: the conflicts[]
        # report still surfaces the file with diff guidance; users
        # whose baseline is unreachable already see the "baseline
        # unavailable" note in the conflicts block. Promoting these
        # to preexisting_collisions[] would require scanning
        # ALL upstream history to find when the file was introduced,
        # which is out of scope for this fix.
        if [[ $baseline_available -eq 1 && ! -f "$workdir/old/$f" ]]; then
          preexisting_collisions+=("$f")
        fi
      fi
      kept+=("$f")
    fi
  fi
done

# --- Retrofit docs/intake-log.md (T041 / FR-013) -----------------------------
# The template ships docs/templates/intake-log-template.md but does not
# git-track docs/intake-log.md (it's project-owned, append-only customer-truth
# content). Older scaffolds pre-dating this fix never materialised the live
# log. On upgrade, if the project is missing docs/intake-log.md, seed it
# from the upstream template now; if it already exists, leave it untouched.
# Also ensure the path is listed in .template-customizations so future
# upgrades skip it (the manifest_write below honours that file from disk).
intake_template="$workdir/new/docs/templates/intake-log-template.md"
intake_target="$project_root/docs/intake-log.md"
intake_retrofitted=0
if [[ -f "$intake_template" && ! -f "$intake_target" ]]; then
  if [[ $dry_run -eq 0 ]]; then
    mkdir -p "$project_root/docs"
    # Derive a project name for the substitution: basename of project root.
    proj_name="$(basename "$project_root")"
    sed "s|<project name>|$proj_name|g" "$intake_template" > "$intake_target.tmp.$$"
    mv "$intake_target.tmp.$$" "$intake_target"
  fi
  intake_retrofitted=1
  added+=("docs/intake-log.md")
fi
# Idempotently ensure .template-customizations lists docs/intake-log.md.
# Safe to run even when the file already existed — older scaffolds may
# have the live log but no preserve-list entry.
if [[ $dry_run -eq 0 && -f "$customizations_file" ]]; then
  if ! grep -qE '^docs/intake-log\.md[[:space:]]*(#.*)?$' "$customizations_file"; then
    printf '# Project-owned intake conversation log (T041 / FR-013).\ndocs/intake-log.md\n' \
      >> "$customizations_file"
  fi
fi

# --- Retrofit project-local ROADMAP.md stub (T045 / FR-015 / M4.2) -----------
# The template's own upstream ROADMAP.md is excluded from ship_files, so
# upgrade never installs it. Older scaffolds (pre-T045) that received the
# template's ROADMAP.md by mistake, or that scaffolded without one, get a
# project-local stub seeded here when no ROADMAP.md is present. Existing
# ROADMAP.md content is never touched — projects that already carry a
# template-scoped ROADMAP.md must decide (delete it, or replace with a
# project-local file) per docs/TEMPLATE_UPGRADE.md. Path is added to
# .template-customizations so future upgrades treat it as project-owned.
roadmap_target="$project_root/ROADMAP.md"
if [[ ! -f "$roadmap_target" ]]; then
  if [[ $dry_run -eq 0 ]]; then
    proj_name_rm="$(basename "$project_root")"
    cat > "$roadmap_target.tmp.$$" <<EOF
# Roadmap — $proj_name_rm

Project roadmap — owned by \`project-manager\`; entries map to
\`docs/pm/SCHEDULE.md\` milestones.

This file is the project's own forward-looking plan. It is **not** the
upstream \`sw-dev-team-template\` roadmap; that one lives in the template
repo and is intentionally not shipped to downstream scaffolds (FR-015 /
M4.2).
EOF
    mv "$roadmap_target.tmp.$$" "$roadmap_target"
  fi
  added+=("ROADMAP.md")
fi
if [[ $dry_run -eq 0 && -f "$customizations_file" ]]; then
  if ! grep -qE '^ROADMAP\.md[[:space:]]*(#.*)?$' "$customizations_file"; then
    printf '# Project-owned roadmap stub (T045 / FR-015).\nROADMAP.md\n' \
      >> "$customizations_file"
  fi
fi

# Stamp the new TEMPLATE_VERSION (only if not dry-run AND there are no conflicts,
# OR if the user accepts leaving conflicts in place — we do the latter by default).
if [[ $dry_run -eq 0 ]]; then
  cat > "$tv" <<EOF
$new_version
$new_sha
$(date -u +%Y-%m-%d)
EOF

  # Issue #107: persist conflict metadata to .template-conflicts.json
  # BEFORE the manifest is rewritten. --verify reads this file and
  # surfaces unresolved conflicts even when the manifest verifies
  # clean (because manifest SHAs reflect the post-upgrade project
  # state, not the desired post-merge state).
  conflicts_path="$project_root/.template-conflicts.json"
  if [[ ${#conflicts[@]} -gt 0 || ${#local_only_kept[@]} -gt 0 || ${#accepted_local[@]} -gt 0 ]]; then
    {
      printf '{\n'
      printf '  "schema": 1,\n'
      printf '  "generated": "%s",\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
      printf '  "template_version": "%s",\n' "$new_version"
      printf '  "entries": [\n'
      first=1
      # LOCKSTEP: this writer's printf shape is the contract that the
      # --resolve sed extractors (above) read against. Format must
      # stay in lockstep — do not introduce a second writer or change
      # the printf shape without updating the sed extractors. One
      # entry per line, no nested structure, fields in fixed order.
      emit_entry() {
        local path="$1" classified="$2"
        local baseline_sha="" upstream_sha="" project_sha=""
        if [[ $baseline_available -eq 1 && -f "$workdir/old/$path" ]]; then
          baseline_sha="$(manifest_file_sha "$workdir/old/$path")"
        fi
        if [[ -f "$workdir/new/$path" ]]; then
          upstream_sha="$(manifest_file_sha "$workdir/new/$path")"
        fi
        if [[ -f "$project_root/$path" ]]; then
          project_sha="$(manifest_file_sha "$project_root/$path")"
        fi
        [[ $first -eq 0 ]] && printf ',\n'
        first=0
        printf '    {"path": "%s", "classified": "%s", "baseline_sha": "%s", "upstream_sha": "%s", "project_sha": "%s"}' \
          "$path" "$classified" "$baseline_sha" "$upstream_sha" "$project_sha"
      }
      for f in "${conflicts[@]:-}"; do [[ -n "$f" ]] && emit_entry "$f" "conflict"; done
      for f in "${local_only_kept[@]:-}"; do [[ -n "$f" ]] && emit_entry "$f" "local_only_kept"; done
      for f in "${accepted_local[@]:-}"; do [[ -n "$f" ]] && emit_entry "$f" "accepted_local"; done
      printf '\n  ]\n}\n'
    } > "$conflicts_path"
  else
    # No tracked entries — remove any stale file from a prior upgrade.
    rm -f "$conflicts_path"
  fi

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
  echo "${prefix}⚠  Conflicts — local AND upstream both changed (review and merge manually) (${#conflicts[@]}):"
  for f in "${conflicts[@]}"; do
    echo "  ! $f"
    if [[ $baseline_available -eq 1 && -f "$workdir/old/$f" ]]; then
      upstream_stat="$(shortstat_between "$workdir/old/$f" "$workdir/new/$f")"
      local_stat="$(shortstat_between "$workdir/old/$f" "$project_root/$f")"
      echo "      upstream delta: ${upstream_stat:-0 files changed}"
      echo "      local delta:    ${local_stat:-0 files changed}"
    else
      echo "      delta heat-map unavailable: baseline SHA not reachable"
    fi
    echo "      diff <(git -C $workdir/new show HEAD:\"$f\") \"$project_root/$f\""
  done
  echo
  echo "  For each conflict, diff the upstream version against your customized"
  echo "  version and decide: keep yours, take upstream, or merge."
  echo
fi

if [[ ${#preexisting_collisions[@]} -gt 0 ]]; then
  echo "${prefix}ACTION REQUIRED: pre-existing collision(s) detected (${#preexisting_collisions[@]}):"
  for f in "${preexisting_collisions[@]}"; do
    echo "  ! $f — local file pre-dates upstream's introduction of this path."
  done
  echo "  Resolution options (per upstream issue #110):"
  echo "    (1) Take upstream: review upstream's version, remove the local file,"
  echo "        and re-run scripts/upgrade.sh to install upstream."
  echo "    (2) Keep local:    add the path to .template-customizations to pin it."
  echo "    (3) Merge:         hand-merge upstream content into the local file,"
  echo "        then re-run scripts/upgrade.sh --resolve to clear the conflict."
  echo
fi

if [[ ${#local_only_kept[@]} -gt 0 ]]; then
  echo "${prefix}Local customizations kept — upstream unchanged (${#local_only_kept[@]}):"
  for f in "${local_only_kept[@]}"; do echo "  = $f"; done
  echo
fi

if [[ ${#accepted_local[@]} -gt 0 ]]; then
  echo "${prefix}Accepted local merges (recorded in manifest) (${#accepted_local[@]}):"
  for f in "${accepted_local[@]}"; do echo "  ✓ $f"; done
  echo
fi

# User-added files (not in template's ship_files) are implicitly preserved —
# they were never touched.
user_added_agents=$(find "$project_root/.claude/agents" -maxdepth 1 \
                    \( -name 'sme-*.md' -o -name '*-local.md' \) \
                    ! -name 'sme-template.md' 2>/dev/null \
                    | sed "s|^$project_root/||" || true)
if [[ -n "$user_added_agents" ]]; then
  echo "${prefix}User-added agent files preserved:"
  while IFS= read -r f; do
    echo "  · $f"
  done <<< "$user_added_agents"
  echo
fi

if [[ ${#preserved[@]} -gt 0 ]]; then
  echo "${prefix}Preserved per .template-customizations (${#preserved[@]}):"
  for f in "${preserved[@]}"; do echo "  = $f"; done
  echo
fi

if [[ $dry_run -eq 0 ]]; then
  echo "Done. TEMPLATE_VERSION now $new_version / $new_sha."
  if [[ ${#conflicts[@]} -gt 0 ]]; then
    echo "Resolve the ${#conflicts[@]} conflict(s) above, then commit."
    echo "Unresolved conflicts persisted to .template-conflicts.json;"
    echo "  --verify will track them until resolved (issue #107)."
    echo "  After hand-merging, run scripts/upgrade.sh --resolve to clear."
  elif [[ ${#local_only_kept[@]} -gt 0 || ${#accepted_local[@]} -gt 0 ]]; then
    echo "Manifest verifies clean; remaining listed files are local customizations, not upgrade blockers."
  fi
else
  echo "(No changes written — this was a dry run.)"
fi
exit 0
