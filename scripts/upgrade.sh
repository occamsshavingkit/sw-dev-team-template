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
Usage: scripts/upgrade.sh [--dry-run | --verify | --resolve | --target <ref> |
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
  --target <ref>    Pin the upgrade to a specific upstream ref. Accepts:
                      * a tag (e.g. v0.14.4)                — stamps the tag
                      * a branch (e.g. main, feat/foo)      — stamps
                          "untagged-<short-sha>"
                      * a short or full commit SHA          — same
                    Resolution priority: tags first (back-compat), then
                    branches (refs/heads then refs/remotes/origin), then
                    commit SHAs. For untagged targets, ALL migrations
                    strictly greater than the project's current
                    TEMPLATE_VERSION are run (semver progression
                    unavailable; conservative full-walk). Without this
                    flag, upgrade.sh targets the latest stable upstream
                    tag for stable projects, or the latest upstream tag
                    for projects already on a pre-release track.
                    (Issues #60/#68; untagged refs added 2026-05-15.)
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
        echo "ERROR: --target requires a ref argument (tag, branch, or commit SHA — e.g. --target v0.14.4, --target main, --target b7aa9d3)" >&2
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
  # Issue #152: collect "path<TAB>new_sha" lines for every conflict entry
  # cleared by hand-merge so we can refresh TEMPLATE_MANIFEST.lock rows
  # after the JSON rewrite. Without this, --verify fails on the very
  # next run because the manifest still carries pre-resolution SHAs.
  resolved_paths_log="$conflicts_path.resolved.$$"
  : > "$resolved_paths_log"
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
        # Issue #152: stash the new SHA so the manifest gets refreshed
        # below. Tab-separated to keep parsing trivial.
        printf '%s\t%s\n' "$e_path" "$proj_now" >> "$resolved_paths_log"
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

  # Issue #152: refresh TEMPLATE_MANIFEST.lock rows for every conflict
  # cleared above. Rewrite each row in-place with the post-merge SHA so
  # the very next `--verify` run sees a clean manifest. Lock format
  # (per scripts/lib/manifest.sh): `<sha256>  <path>` with exactly two
  # spaces. Comment lines start with `#` and are passed through.
  manifest_for_resolve="$project_root/TEMPLATE_MANIFEST.lock"
  refreshed_manifest_rows=0
  if [[ -s "$resolved_paths_log" && -f "$manifest_for_resolve" ]]; then
    manifest_tmp="$manifest_for_resolve.tmp.$$"
    awk -F '\t' '
      NR == FNR { new_sha[$1] = $2; next }
      /^[[:space:]]*#/ || /^[[:space:]]*$/ { print; next }
      {
        sep = index($0, "  ")
        if (sep > 0) {
          path = substr($0, sep + 2)
          if (path in new_sha && new_sha[path] != "") {
            printf "%s  %s\n", new_sha[path], path
            refreshed[path] = 1
            next
          }
        }
        print
      }
      END {
        n = 0
        for (p in refreshed) n++
        # Print count to stderr for caller capture.
        print n > "/dev/stderr"
      }
    ' "$resolved_paths_log" "$manifest_for_resolve" > "$manifest_tmp" 2> "$manifest_tmp.count"
    refreshed_manifest_rows=$(tr -d '[:space:]' < "$manifest_tmp.count" 2>/dev/null || echo 0)
    mv "$manifest_tmp" "$manifest_for_resolve"
    rm -f "$manifest_tmp.count"
  fi
  rm -f "$resolved_paths_log"

  if [[ $kept_unresolved -eq 0 ]]; then
    rm -f "$conflicts_path"
    echo "Resolved $removed entr$([[ $removed -eq 1 ]] && echo 'y' || echo 'ies'); .template-conflicts.json removed."
  else
    echo "Cleared $removed entr$([[ $removed -eq 1 ]] && echo 'y' || echo 'ies'); $kept_unresolved still unresolved."
  fi
  if [[ "$refreshed_manifest_rows" -gt 0 ]] 2>/dev/null; then
    echo "Refreshed $refreshed_manifest_rows manifest row(s) in TEMPLATE_MANIFEST.lock (issue #152)."
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
# Check out the intended upstream ref before any other steps run.
# Bootstrap, baseline-clone, and sync all see the selected target state.
# VERSION inside the clone is the selected target's VERSION at that ref
# — for tag targets new_version is derived from it; for untagged targets
# (branch / SHA) we use a synthetic "untagged-<short-sha>" label instead
# so the TEMPLATE_VERSION stamp is unambiguously distinct from semver.
#
# target_kind tracks how --target resolved: "tag" / "untagged" / "" (none).
# Resolution priority for --target: tags first (back-compat), then
# branches (refs/heads, then refs/remotes/origin/<ref>), then commit SHAs.
target_kind=""
target_resolved_sha=""
if [[ -n "$target_version" ]]; then
  if git -C "$workdir/new" rev-parse --verify --quiet "refs/tags/$target_version" >/dev/null; then
    target_kind="tag"
    target_resolved_sha="$(git -C "$workdir/new" rev-parse --verify --quiet "refs/tags/$target_version^{commit}")"
    echo "Pinning upgrade to --target $target_version (tag)" >&2
    git -C "$workdir/new" checkout -q "$target_version"
  elif git -C "$workdir/new" rev-parse --verify --quiet "refs/heads/$target_version" >/dev/null; then
    target_kind="untagged"
    target_resolved_sha="$(git -C "$workdir/new" rev-parse --verify --quiet "refs/heads/$target_version^{commit}")"
    echo "Pinning upgrade to --target $target_version (branch → ${target_resolved_sha:0:7})" >&2
    git -C "$workdir/new" checkout -q "$target_version"
  elif git -C "$workdir/new" rev-parse --verify --quiet "refs/remotes/origin/$target_version" >/dev/null; then
    target_kind="untagged"
    target_resolved_sha="$(git -C "$workdir/new" rev-parse --verify --quiet "refs/remotes/origin/$target_version^{commit}")"
    echo "Pinning upgrade to --target $target_version (remote branch → ${target_resolved_sha:0:7})" >&2
    git -C "$workdir/new" checkout -q "refs/remotes/origin/$target_version"
  elif git -C "$workdir/new" rev-parse --verify --quiet "${target_version}^{commit}" >/dev/null; then
    # Bare SHA (short or full). Reject anything that *looks like* a tag
    # syntactically (starts with v + digit) but did not match the tag
    # branch above — that case is a typo, not a SHA.
    if [[ "$target_version" =~ ^v[0-9] ]]; then
      echo "ERROR: --target $target_version is not a known tag, branch, or commit in $upstream." >&2
      echo "  Recent tags (last 10):" >&2
      git -C "$workdir/new" tag -l 'v*' | semver_sort_tags | tail -10 | sed 's/^/    /' >&2
      exit 2
    fi
    target_kind="untagged"
    target_resolved_sha="$(git -C "$workdir/new" rev-parse --verify --quiet "${target_version}^{commit}")"
    echo "Pinning upgrade to --target $target_version (commit → ${target_resolved_sha:0:7})" >&2
    git -C "$workdir/new" checkout -q "$target_resolved_sha"
  else
    echo "ERROR: --target $target_version is not a known tag, branch, or commit in $upstream." >&2
    echo "  Recent tags (last 10):" >&2
    git -C "$workdir/new" tag -l 'v*' | semver_sort_tags | tail -10 | sed 's/^/    /' >&2
    exit 2
  fi
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
#
# FW-ADR-0010 (issue #170): pre-bootstrap now respects local edits to
# bootstrap-critical files. For each bootstrap-critical path, compute the
# 3-SHA tuple (project / baseline / upstream) and apply the matrix in
# FW-ADR-0010 §"3-SHA decision matrix (binding)". Refuse-on-uncertain
# when local edits or an unreachable baseline are detected; require an
# explicit `SWDT_PREBOOTSTRAP_FORCE=1` override that leaves an audit row
# in docs/pm/pre-release-gate-overrides.md.
if [[ "${SWDT_BOOTSTRAPPED:-}" != "1" ]]; then
  upstream_upgrade="$workdir/new/scripts/upgrade.sh"
  upstream_lib_dir="$workdir/new/scripts/lib"
  local_lib_dir="$(dirname "$0")/lib"

  # Hoist the baseline clone so pre-bootstrap can run the 3-SHA matrix.
  # The post-bootstrap path (line ~537) re-uses workdir/old if it exists,
  # so this work is not duplicated. If the baseline SHA is unknown or
  # unreachable, prebootstrap_baseline_available stays 0 and the matrix
  # routes to the baseline-unreachable refuse path (FW-ADR-0010).
  prebootstrap_baseline_available=0
  if [[ -n "$local_sha" && "$local_sha" != "unknown" && ! -d "$workdir/old" ]]; then
    git clone -q "$upstream_auth" "$workdir/old" 2>/dev/null || true
    if [[ -d "$workdir/old" ]]; then
      if git -C "$workdir/old" checkout -q "$local_sha" 2>/dev/null; then
        prebootstrap_baseline_available=1
      else
        rm -rf "$workdir/old"
      fi
    fi
  elif [[ -d "$workdir/old" ]]; then
    prebootstrap_baseline_available=1
  fi

  # Helper: sha256 of a file, empty string if absent.
  prebootstrap_sha() {
    if [[ -f "$1" ]]; then
      sha256sum "$1" | awk '{print $1}'
    else
      printf ''
    fi
  }

  # Collect the bootstrap-critical fileset: scripts/upgrade.sh + every
  # scripts/lib/*.sh the candidate ships. Walk each through the matrix.
  declare -a prebootstrap_paths=()
  declare -a prebootstrap_project_path=()
  declare -a prebootstrap_upstream_path=()
  if [[ -f "$upstream_upgrade" ]]; then
    prebootstrap_paths+=("scripts/upgrade.sh")
    prebootstrap_project_path+=("$0")
    prebootstrap_upstream_path+=("$upstream_upgrade")
  fi
  if [[ -d "$upstream_lib_dir" ]]; then
    while IFS= read -r upstream_lib; do
      lib_name="$(basename "$upstream_lib")"
      prebootstrap_paths+=("scripts/lib/$lib_name")
      prebootstrap_project_path+=("$local_lib_dir/$lib_name")
      prebootstrap_upstream_path+=("$upstream_lib")
    done < <(find "$upstream_lib_dir" -maxdepth 1 -type f -name '*.sh' | sort)
  fi

  # Per-path matrix evaluation.
  #
  # action codes:
  #   proceed   — atomic-replace this path (project == baseline; safe to upgrade)
  #   noop      — project already matches upstream; nothing to do
  #   refuse    — local edit detected; block unless SWDT_PREBOOTSTRAP_FORCE=1
  #   retrofit  — baseline unreachable + project != upstream; refuse + retrofit
  declare -a prebootstrap_actions=()
  declare -a prebootstrap_project_shas=()
  declare -a prebootstrap_baseline_shas=()
  declare -a prebootstrap_upstream_shas=()
  declare -a prebootstrap_reasons=()
  any_proceed=0
  any_block=0
  for i in "${!prebootstrap_paths[@]}"; do
    rel="${prebootstrap_paths[$i]}"
    proj_file="${prebootstrap_project_path[$i]}"
    new_file="${prebootstrap_upstream_path[$i]}"
    proj_sha="$(prebootstrap_sha "$proj_file")"
    new_sha_local="$(prebootstrap_sha "$new_file")"
    base_sha=""
    if [[ $prebootstrap_baseline_available -eq 1 ]]; then
      base_sha="$(prebootstrap_sha "$workdir/old/$rel")"
    fi
    prebootstrap_project_shas+=("$proj_sha")
    prebootstrap_baseline_shas+=("$base_sha")
    prebootstrap_upstream_shas+=("$new_sha_local")

    # File not yet present in project: treat as add-from-upstream — safe to
    # install. (Not part of the matrix proper; the matrix assumes the file
    # exists in both project and upstream. Missing-locally is "no edit to
    # protect"; proceed.)
    if [[ -z "$proj_sha" ]]; then
      prebootstrap_actions+=("proceed")
      prebootstrap_reasons+=("missing-locally")
      any_proceed=1
      continue
    fi

    if [[ -n "$base_sha" ]]; then
      if [[ "$proj_sha" == "$base_sha" ]]; then
        if [[ "$proj_sha" == "$new_sha_local" ]]; then
          prebootstrap_actions+=("noop")
          prebootstrap_reasons+=("project-matches-upstream")
        else
          prebootstrap_actions+=("proceed")
          prebootstrap_reasons+=("unedited-baseline")
          any_proceed=1
        fi
      else
        if [[ "$proj_sha" == "$new_sha_local" ]]; then
          prebootstrap_actions+=("noop")
          prebootstrap_reasons+=("project-already-at-upstream")
        else
          prebootstrap_actions+=("refuse")
          prebootstrap_reasons+=("local-edit")
          any_block=1
        fi
      fi
    else
      # Baseline absent.
      if [[ "$proj_sha" == "$new_sha_local" ]]; then
        prebootstrap_actions+=("noop")
        prebootstrap_reasons+=("project-matches-upstream-no-baseline")
      else
        prebootstrap_actions+=("retrofit")
        prebootstrap_reasons+=("baseline-unreachable")
        any_block=1
      fi
    fi
  done

  prebootstrap_block_artefact="$project_root/.template-prebootstrap-blocked.json"

  if [[ $any_block -eq 1 ]]; then
    # Build the reason summary.
    saw_local_edit=0
    saw_baseline_unreachable=0
    for i in "${!prebootstrap_actions[@]}"; do
      case "${prebootstrap_actions[$i]}" in
        refuse) saw_local_edit=1 ;;
        retrofit) saw_baseline_unreachable=1 ;;
      esac
    done
    if [[ $saw_local_edit -eq 1 && $saw_baseline_unreachable -eq 1 ]]; then
      reason_summary="mixed"
    elif [[ $saw_local_edit -eq 1 ]]; then
      reason_summary="local-edit"
    else
      reason_summary="baseline-unreachable"
    fi

    # Check override BEFORE writing artefact: a forced run skips the artefact.
    if [[ "${SWDT_PREBOOTSTRAP_FORCE:-}" == "1" ]]; then
      override_log="$project_root/docs/pm/pre-release-gate-overrides.md"
      if [[ ! -w "$override_log" ]]; then
        echo "ERROR: SWDT_PREBOOTSTRAP_FORCE=1 set, but $override_log is unwritable." >&2
        echo "       Refusing to bypass without an audit row. Fix permissions and re-run." >&2
        exit 2
      fi
      # Append one row per blocked path so each forced override is itemised.
      date_iso="$(date -u +%Y-%m-%d)"
      operator="$(git config user.email 2>/dev/null || echo "${USER:-unknown}@$(hostname 2>/dev/null || echo unknown)")"
      force_reason="${SWDT_PREBOOTSTRAP_FORCE_REASON:-unspecified}"
      new_sha_short="${new_sha:-}"
      if [[ -n "$new_sha_short" ]]; then
        new_sha_short="${new_sha_short:0:12}"
      else
        new_sha_short="(pre-bootstrap)"
      fi
      for i in "${!prebootstrap_actions[@]}"; do
        case "${prebootstrap_actions[$i]}" in
          refuse|retrofit)
            row="| $date_iso | pre-bootstrap | $new_sha_short | | $operator | ${prebootstrap_reasons[$i]}:${prebootstrap_paths[$i]} ($force_reason) | |"
            printf '%s\n' "$row" >> "$override_log"
            echo "WARN: SWDT_PREBOOTSTRAP_FORCE=1 — overriding pre-bootstrap block on ${prebootstrap_paths[$i]} (reason=${prebootstrap_reasons[$i]})" >&2
            ;;
        esac
      done
      echo "WARN: pre-bootstrap audit row(s) appended to $override_log" >&2
      # Force-proceed: every refused/retrofit path becomes proceed; noop stays noop.
      for i in "${!prebootstrap_actions[@]}"; do
        case "${prebootstrap_actions[$i]}" in
          refuse|retrofit) prebootstrap_actions[$i]="proceed"; any_proceed=1 ;;
        esac
      done
      any_block=0
      # Remove any stale block artefact from a prior run.
      rm -f "$prebootstrap_block_artefact"
    else
      # Write block artefact atomically (mktemp + mv).
      if [[ $dry_run -eq 0 ]]; then
        tmp_artefact="$(mktemp "$prebootstrap_block_artefact.tmp.XXXXXX")"
        {
          printf '{\n'
          printf '  "version": 1,\n'
          printf '  "generated": "%s",\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
          printf '  "reason_summary": "%s",\n' "$reason_summary"
          printf '  "blocked": [\n'
          first=1
          # Emit sorted-by-path for determinism (paths are collected in
          # find-sort order plus scripts/upgrade.sh; resort explicitly).
          # Build a sortable index list of refusing entries.
          declare -a sorted_idx=()
          while IFS= read -r line; do
            sorted_idx+=("${line#*:}")
          done < <(
            for j in "${!prebootstrap_actions[@]}"; do
              case "${prebootstrap_actions[$j]}" in
                refuse|retrofit) printf '%s:%s\n' "${prebootstrap_paths[$j]}" "$j" ;;
              esac
            done | LC_ALL=C sort
          )
          for j in "${sorted_idx[@]}"; do
            reason_field="local-edit"
            [[ "${prebootstrap_actions[$j]}" == "retrofit" ]] && reason_field="baseline-unreachable"
            if [[ $first -eq 0 ]]; then printf ',\n'; fi
            printf '    {\n'
            printf '      "path": "%s",\n' "${prebootstrap_paths[$j]}"
            printf '      "project_sha": "%s",\n' "${prebootstrap_project_shas[$j]}"
            printf '      "baseline_sha": "%s",\n' "${prebootstrap_baseline_shas[$j]}"
            printf '      "upstream_sha": "%s",\n' "${prebootstrap_upstream_shas[$j]}"
            printf '      "reason": "%s"\n' "$reason_field"
            printf '    }'
            first=0
          done
          printf '\n  ]\n}\n'
        } > "$tmp_artefact"
        mv "$tmp_artefact" "$prebootstrap_block_artefact"
      fi

      echo >&2
      echo "ERROR: pre-bootstrap refused — bootstrap-critical files carry local edits or an unreachable baseline." >&2
      for i in "${!prebootstrap_actions[@]}"; do
        case "${prebootstrap_actions[$i]}" in
          refuse)
            echo "  ${prebootstrap_paths[$i]}: reason=local-edit (project SHA differs from baseline)" >&2
            ;;
          retrofit)
            echo "  ${prebootstrap_paths[$i]}: reason=baseline-unreachable (cannot decide without baseline)" >&2
            ;;
        esac
      done
      if [[ $dry_run -eq 1 ]]; then
        echo >&2
        echo "(dry-run: would have written $prebootstrap_block_artefact)" >&2
      else
        echo >&2
        echo "Block artefact: $prebootstrap_block_artefact" >&2
      fi
      echo "Recovery:" >&2
      echo "  - Review the listed paths; declare deliberate local edits in .template-customizations." >&2
      echo "  - For baseline-unreachable rows, follow the retrofit playbook:" >&2
      echo "      docs/templates/retrofit-playbook-template.md" >&2
      echo "  - To bypass (atomic-replace every blocked path, audit-logged):" >&2
      echo "      SWDT_PREBOOTSTRAP_FORCE=1 scripts/upgrade.sh ..." >&2
      echo "    (Optionally set SWDT_PREBOOTSTRAP_FORCE_REASON='<note>' for the audit row.)" >&2
      exit 2
    fi
  fi

  # Determine if any work remains for the bootstrap stage.
  bootstrap=0
  for action in "${prebootstrap_actions[@]}"; do
    if [[ "$action" == "proceed" ]]; then
      bootstrap=1
      break
    fi
  done

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
    # Only paths whose matrix action is "proceed" are written.
    mkdir -p "$local_lib_dir"
    for i in "${!prebootstrap_actions[@]}"; do
      [[ "${prebootstrap_actions[$i]}" == "proceed" ]] || continue
      rel="${prebootstrap_paths[$i]}"
      proj_file="${prebootstrap_project_path[$i]}"
      new_file="${prebootstrap_upstream_path[$i]}"
      # Preserve mode bits per source intent.
      if [[ -x "$new_file" ]]; then
        install_mode=0755
      else
        install_mode=0644
      fi
      install -m "$install_mode" "$new_file" "$proj_file.tmp.$$"
      mv "$proj_file.tmp.$$" "$proj_file"
    done
    # A successful pre-bootstrap clears any stale block artefact (idempotency).
    rm -f "$prebootstrap_block_artefact"
    # Reuse the workdir we just cloned — no need to clone twice. Hand the
    # path to the re-execed self via env; child trap takes ownership of
    # cleanup.
    export SWDT_BOOTSTRAPPED=1
    export SWDT_PRESTAGED_WORKDIR="$workdir"
    trap '' EXIT  # don't double-rm; child owns the workdir now
    exec bash "$0" "${original_args[@]}"
  fi

  # No bootstrap work needed — but still clear any stale block artefact
  # from a prior refused run, since the project state is now clean.
  rm -f "$prebootstrap_block_artefact"
fi

if declare -F first_actions_step0_warning >/dev/null; then
  first_actions_step0_warning "$project_root" "upgrade"
fi

new_sha="$(git -C "$workdir/new" rev-parse HEAD)"
if [[ "$target_kind" == "untagged" ]]; then
  # Synthetic version label for untagged targets (branch / SHA). The
  # "untagged-" prefix makes the TEMPLATE_VERSION first line visually
  # distinct from semver so operators recognise a pre-release /
  # experimental state. version-check.sh prints a WARN line on this
  # state. (2026-05-15.)
  new_version="untagged-${new_sha:0:7}"
else
  new_version="$(tr -d '[:space:]' < "$workdir/new/VERSION")"
fi

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
      # Issue #138: same version, same path-set, manifest clean — but the
      # stamped SHA on the second line of TEMPLATE_VERSION may still
      # differ from the upstream tag's actual commit (e.g., upstream
      # force-updated the tag after the project stamped, or the project
      # was stamped at a pre-correction SHA). Detect and refresh the
      # SHA + date lines silently-but-noisily; the manifest is fine, so
      # nothing else to sync.
      local_sha_short="${local_sha:0:12}"
      new_sha_short="${new_sha:0:12}"
      if [[ -n "$new_sha" && -n "$local_sha" && "$local_sha" != "$new_sha" ]]; then
        echo "WARN: TEMPLATE_VERSION stamp SHA drift detected: local=$local_sha_short upstream=$new_sha_short for version $local_version" >&2
        if [[ $dry_run -eq 0 ]]; then
          cat > "$tv.tmp.$$" <<EOF
$local_version
$new_sha
$(date -u +%Y-%m-%d)
EOF
          mv "$tv.tmp.$$" "$tv"
          echo "       TEMPLATE_VERSION SHA line refreshed to $new_sha_short (issue #138)." >&2
        else
          echo "       (dry-run: would refresh TEMPLATE_VERSION SHA line to $new_sha_short) (issue #138)" >&2
        fi
        exit 0
      fi
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
#
# Untagged targets (branch / SHA): semver progression breaks because
# new_version is a synthetic "untagged-<sha>" label. Run every migration
# strictly greater than local_version (conservative full-walk). Migrations
# are required to be idempotent per their contract, so re-running ones
# that already applied is safe.
all_tags=$(git -C "$workdir/new" tag -l 'v*' 2>/dev/null | semver_sort_tags || true)
migrations_to_run=()
if [[ "$target_kind" == "untagged" ]]; then
  past_local=0
  for tag in $all_tags; do
    if [[ $past_local -eq 0 ]]; then
      [[ "$tag" == "$local_version" ]] && past_local=1
      continue
    fi
    migrations_to_run+=("$tag")
  done
  # If local_version isn't a known tag (hand-stamped / itself untagged-*),
  # walk every migration up to tip.
  if [[ $past_local -eq 0 && ${#migrations_to_run[@]} -eq 0 ]]; then
    for tag in $all_tags; do
      migrations_to_run+=("$tag")
    done
  fi
  echo "NOTE: Running all migrations from $local_version to $new_version (semver progression unavailable; conservative full-walk)." >&2
else
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
#
# Per FW-ADR-0014, the preserve-list is no longer authoritative on its own.
# At sync time each entry is classified by should_preserve() against
# (a) project-vs-baseline divergence and (b) the destination manifest's
# fresh-write declaration. Inert entries silently drop; genuine
# manifest-vs-customisation conflicts refuse with exit 2 unless
# SWDT_PRESERVATION_FORCE=1. The on-disk file is untouched here — the
# opt-in pruning migration (migrations/v1.0.0-rc14.sh) is the only writer.
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

# --- FW-ADR-0014: preservation decision helper -------------------------------
#
# Classify a preserve-list entry against project divergence and the
# destination manifest's fresh-write declaration. Returns one of:
#
#   preserve          — divergence AND path not declared fresh-write
#   drop-inert        — no divergence (inert entry; sync proceeds)
#   refuse-conflict   — divergence AND path declared fresh-write
#                       (manifest contradiction; caller must refuse
#                       unless SWDT_PRESERVATION_FORCE=1)
#
# Reads (caller-supplied via positional args):
#   $1  project-relative path
#   $2  workdir/new (upstream new clone)
#   $3  workdir/old (upstream baseline clone, or empty when unreachable)
#   $4  project_root
#   $5  baseline_available (0/1)
#
# When baseline is unreachable (baseline_available=0) we cannot prove
# the project is at the same content as the baseline — every diverged-
# from-upstream path is treated as divergence (conservative, matches
# the existing "no baseline" comment in the sync classifier below).
should_preserve() {
  local path="$1"
  local wnew="$2"
  local wold="$3"
  local proot="$4"
  local b_avail="$5"

  local proj_file="$proot/$path"
  if [[ ! -f "$proj_file" ]]; then
    # Project doesn't have the file at all — nothing to preserve. The
    # sync loop will fall through to its add path (or skip if upstream
    # also lacks it). Treat as drop-inert.
    echo "drop-inert"
    return 0
  fi

  # Divergence check: project vs baseline.
  local diverged=0
  if [[ "$b_avail" == "1" && -n "$wold" && -f "$wold/$path" ]]; then
    if ! cmp -s "$wold/$path" "$proj_file"; then
      diverged=1
    fi
  else
    # Baseline unreachable for this path. Conservative: compare project
    # against new upstream. If they match, there's nothing custom to
    # preserve (drop-inert). If they differ, we cannot prove which
    # change introduced the diff, so treat as diverged.
    if [[ -f "$wnew/$path" ]] && cmp -s "$wnew/$path" "$proj_file"; then
      diverged=0
    else
      diverged=1
    fi
  fi

  if [[ $diverged -eq 0 ]]; then
    echo "drop-inert"
    return 0
  fi

  # Divergence is real. Now check the destination manifest's fresh-write
  # declaration. Pass the project root so the helper consults the
  # project's `.template-customizations`: preserved paths are excluded
  # from the destination manifest by design and therefore cannot be
  # "declared fresh-write" for this project (PR #197 / dogfood-2026-05-15
  # fix for scaffold-canonical stub-fills).
  if manifest_declares_fresh_write "$path" "$wnew" "$wold" "$proot"; then
    echo "refuse-conflict"
  else
    echo "preserve"
  fi
  return 0
}

# --- FW-ADR-0014: preservation refusal block-artefact writer -----------------
#
# Mirrors the FW-ADR-0010 pre-bootstrap block-artefact writer. Emits
# .template-preservation-blocked.json at project root. Reads three
# parallel arrays populated by the sync loop's classification pass:
#
#   preservation_refused_paths[]
#   preservation_refused_project_shas[]
#   preservation_refused_baseline_shas[]
#   preservation_refused_manifest_shas[]
#
# Format: schema parallel to .template-prebootstrap-blocked.json
# (version 1, generated, reason_summary, blocked[] sorted by path).
write_preservation_block_artefact() {
  local out="$1"
  local tmp
  tmp="$(mktemp "$out.tmp.XXXXXX")"
  {
    printf '{\n'
    printf '  "version": 1,\n'
    printf '  "generated": "%s",\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf '  "reason_summary": "manifest-fresh-write-vs-customisation",\n'
    printf '  "blocked": [\n'
    # Build a sortable list (path -> index) so output is deterministic.
    local sorted_idx=()
    while IFS= read -r idx_line; do
      sorted_idx+=("${idx_line#*:}")
    done < <(
      for j in "${!preservation_refused_paths[@]}"; do
        printf '%s:%s\n' "${preservation_refused_paths[$j]}" "$j"
      done | LC_ALL=C sort
    )
    local first=1
    for j in "${sorted_idx[@]}"; do
      [[ $first -eq 0 ]] && printf ',\n'
      first=0
      printf '    {\n'
      printf '      "path": "%s",\n' "${preservation_refused_paths[$j]}"
      printf '      "project_sha": "%s",\n' "${preservation_refused_project_shas[$j]}"
      printf '      "baseline_sha": "%s",\n' "${preservation_refused_baseline_shas[$j]}"
      printf '      "manifest_declared_sha": "%s",\n' "${preservation_refused_manifest_shas[$j]}"
      printf '      "reason": "manifest-fresh-write-vs-customisation"\n'
      printf '    }'
    done
    printf '\n  ]\n}\n'
  } > "$tmp"
  mv "$tmp" "$out"
}

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
# FW-ADR-0014: per-path classification of preserve-list entries.
#   dropped_inert[]     — entries with no divergence (silently dropped).
#   preservation_refused_paths[] (+ parallel SHA arrays) — entries that
#     hit the manifest-fresh-write-vs-customisation conflict and need
#     a block-artefact row.
dropped_inert=()
preservation_refused_paths=()
preservation_refused_project_shas=()
preservation_refused_baseline_shas=()
preservation_refused_manifest_shas=()
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

  # Honor .template-customizations, gated by FW-ADR-0014's
  # divergence-AND-manifest-respecting rule (see should_preserve()).
  if [[ -n "${preserve_list[$f]:-}" ]]; then
    case "$(should_preserve "$f" "$workdir/new" "$workdir/old" "$project_root" "$baseline_available")" in
      preserve)
        preserved+=("$f")
        continue
        ;;
      drop-inert)
        # Inert entry — silently drop from the in-memory preserve set
        # and fall through to the normal sync classifier so the path
        # gets the upstream content. The on-disk file is not rewritten
        # here; the opt-in pruning migration is the only writer.
        dropped_inert+=("$f")
        ;;
      refuse-conflict)
        # Manifest-fresh-write-vs-customisation collision. Record per-
        # path detail; the post-loop refusal handler emits the block
        # artefact (or, with SWDT_PRESERVATION_FORCE=1, appends an
        # audit row and falls through to the normal classifier).
        proj_sha_p=""
        baseline_sha_p=""
        manifest_sha_p=""
        if [[ -f "$project_root/$f" ]]; then
          proj_sha_p="$(manifest_file_sha "$project_root/$f")"
        fi
        if [[ $baseline_available -eq 1 && -f "$workdir/old/$f" ]]; then
          baseline_sha_p="$(manifest_file_sha "$workdir/old/$f")"
        fi
        if [[ -f "$workdir/new/$f" ]]; then
          manifest_sha_p="$(manifest_file_sha "$workdir/new/$f")"
        fi
        preservation_refused_paths+=("$f")
        preservation_refused_project_shas+=("$proj_sha_p")
        preservation_refused_baseline_shas+=("$baseline_sha_p")
        preservation_refused_manifest_shas+=("$manifest_sha_p")
        # Default action when not forced: preserve (do not overwrite
        # the customisation). The post-loop handler will refuse the
        # whole upgrade if any refusals remain unforced.
        preserved+=("$f")
        continue
        ;;
    esac
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

# --- FW-ADR-0014: preservation-vs-manifest refusal handler ------------------
#
# If any entry hit the refuse-conflict row, either:
#   (a) honour SWDT_PRESERVATION_FORCE=1 — append one audit row per
#       refused path to docs/pm/pre-release-gate-overrides.md with
#       Gate=preservation, then atomically install the upstream
#       content over the divergent project file. Removes any stale
#       block artefact.
#   (b) write .template-preservation-blocked.json and exit 2 (the
#       refuse-on-uncertain posture; matches FW-ADR-0010).
#
# dry-run: print the planned refusal / override; change nothing.
preservation_block_artefact="$project_root/.template-preservation-blocked.json"
if [[ ${#preservation_refused_paths[@]} -gt 0 ]]; then
  if [[ "${SWDT_PRESERVATION_FORCE:-}" == "1" ]]; then
    override_log_p="$project_root/docs/pm/pre-release-gate-overrides.md"
    if [[ ! -w "$override_log_p" ]]; then
      echo "ERROR: SWDT_PRESERVATION_FORCE=1 set, but $override_log_p is unwritable." >&2
      echo "       Refusing to bypass without an audit row. Fix permissions and re-run." >&2
      exit 2
    fi
    date_iso_p="$(date -u +%Y-%m-%d)"
    operator_p="$(git config user.email 2>/dev/null || echo "${USER:-unknown}@$(hostname 2>/dev/null || echo unknown)")"
    force_reason_p="${SWDT_PRESERVATION_FORCE_REASON:-unspecified}"
    new_sha_short_p="${new_sha:-}"
    if [[ -n "$new_sha_short_p" ]]; then
      new_sha_short_p="${new_sha_short_p:0:12}"
    else
      new_sha_short_p="(preservation)"
    fi
    if [[ $dry_run -eq 0 ]]; then
      for j in "${!preservation_refused_paths[@]}"; do
        row="| $date_iso_p | preservation | $new_sha_short_p | | $operator_p | manifest-fresh-write-vs-customisation:${preservation_refused_paths[$j]} ($force_reason_p) | |"
        printf '%s\n' "$row" >> "$override_log_p"
        echo "WARN: SWDT_PRESERVATION_FORCE=1 — overriding preservation block on ${preservation_refused_paths[$j]}" >&2
      done
      echo "WARN: preservation audit row(s) appended to $override_log_p" >&2
      # Install upstream content over each refused project file. These
      # paths were classified `preserved` during the sync loop; the
      # force path now reclassifies them as `upgraded` and writes the
      # upstream bytes.
      for f_p in "${preservation_refused_paths[@]}"; do
        # Remove the path from preserved[] (rebuild without it).
        # NB: the `[@]:-` rebuild idiom is unsafe — when the source
        # array is empty, `("${arr[@]:-}")` yields a one-element
        # empty-string array, not an empty array. Guard on length
        # instead. (CR blocker B-1, branch
        # fix/blocker-4-preservation-vs-manifest.)
        new_preserved=()
        if [ "${#preserved[@]}" -gt 0 ]; then
          for q in "${preserved[@]}"; do
            [[ "$q" == "$f_p" ]] && continue
            new_preserved+=("$q")
          done
        fi
        if [ "${#new_preserved[@]}" -gt 0 ]; then
          preserved=("${new_preserved[@]}")
        else
          preserved=()
        fi
        # Stage upstream content via the atomic helper used by the
        # main sync loop.
        if [[ -f "$workdir/new/$f_p" ]]; then
          mkdir -p "$(dirname "$project_root/$f_p")"
          atomic_install "$workdir/new/$f_p" "$project_root/$f_p"
        fi
        upgraded+=("$f_p")
      done
      rm -f "$preservation_block_artefact"
    else
      echo "(dry-run: would override preservation block on ${#preservation_refused_paths[@]} path(s) and append audit rows to $override_log_p)" >&2
    fi
  else
    if [[ $dry_run -eq 0 ]]; then
      write_preservation_block_artefact "$preservation_block_artefact"
    fi
    echo >&2
    echo "ERROR: preservation refused — preserve-list path(s) collide with destination manifest fresh-write declaration." >&2
    for j in "${!preservation_refused_paths[@]}"; do
      echo "  ${preservation_refused_paths[$j]}: project diverges AND release ships new content (manifest-fresh-write-vs-customisation)" >&2
    done
    if [[ $dry_run -eq 0 ]]; then
      echo >&2
      echo "Block artefact: $preservation_block_artefact" >&2
    else
      echo "(dry-run: would have written $preservation_block_artefact)" >&2
    fi
    echo "Recovery:" >&2
    echo "  - Inspect the diff at each blocked path and decide whether the" >&2
    echo "    project customisation should win (remove the upstream change," >&2
    echo "    re-run upgrade) or whether the release content should win" >&2
    echo "    (SWDT_PRESERVATION_FORCE=1 — overwrites the project file)." >&2
    echo "  - To bypass (overwrite every refused path, audit-logged):" >&2
    echo "      SWDT_PRESERVATION_FORCE=1 scripts/upgrade.sh ..." >&2
    echo "    (Optionally set SWDT_PRESERVATION_FORCE_REASON='<note>' for the audit row.)" >&2
    exit 2
  fi
else
  # No refusals — clear any stale block artefact from a prior run.
  rm -f "$preservation_block_artefact"
fi

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
if [[ -f "$intake_template" && ! -f "$intake_target" ]]; then
  if [[ $dry_run -eq 0 ]]; then
    mkdir -p "$project_root/docs"
    # Derive a project name for the substitution: basename of project root.
    proj_name="$(basename "$project_root")"
    sed "s|<project name>|$proj_name|g" "$intake_template" > "$intake_target.tmp.$$"
    mv "$intake_target.tmp.$$" "$intake_target"
  fi
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
      # Avoid the `[@]:-` iteration idiom — under `set -u` on modern
      # bash, `"${arr[@]}"` over an empty array is safe; the `[@]:-`
      # form injects a phantom empty-string iteration. Gate on length
      # instead. (CR blocker B-1.)
      if [ "${#conflicts[@]}" -gt 0 ]; then
        for f in "${conflicts[@]}"; do emit_entry "$f" "conflict"; done
      fi
      if [ "${#local_only_kept[@]}" -gt 0 ]; then
        for f in "${local_only_kept[@]}"; do emit_entry "$f" "local_only_kept"; done
      fi
      if [ "${#accepted_local[@]}" -gt 0 ]; then
        for f in "${accepted_local[@]}"; do emit_entry "$f" "accepted_local"; done
      fi
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
if [ "${#added[@]}" -gt 0 ]; then
  for f in "${added[@]}"; do
    case "$f" in
      .claude/agents/*.md) new_agents+=("$f") ;;
    esac
  done
fi
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
  # FW-ADR-0014 two-phase tail.
  # Phase A — migration chain complete signal (grep-stable literal).
  echo "Migration chain complete (TEMPLATE_VERSION now $new_version)."
  if [[ ${#conflicts[@]} -gt 0 ]]; then
    echo "Resolve the ${#conflicts[@]} conflict(s) above, then commit."
    echo "Unresolved conflicts persisted to .template-conflicts.json;"
    echo "  --verify will track them until resolved (issue #107)."
    echo "  After hand-merging, run scripts/upgrade.sh --resolve to clear."
  elif [[ ${#local_only_kept[@]} -gt 0 || ${#accepted_local[@]} -gt 0 ]]; then
    echo "Manifest verifies clean; remaining listed files are local customizations, not upgrade blockers."
  fi

  # Phase B — verification. Re-invoke the existing --verify formatter
  # (manifest_verify from scripts/lib/manifest.sh) and map its result
  # onto exit codes 0 / 1 / 2 per FW-ADR-0014 Q2.
  #
  # Exit codes:
  #   0  clean      — verify reports OK and no preservation refusal.
  #   1  drift      — verify reports drift (rc 1) or corrupt manifest
  #                   (rc 3) — both indicate the post-upgrade project
  #                   state is not in the shape the manifest claims.
  #   2  refusal    — preservation refusal artefact present at project
  #                   root (handled above via exit 2; never reaches
  #                   this block, but the discriminator is documented
  #                   here for completeness).
  verify_rc=0
  manifest_verify "$project_root" "$project_root/TEMPLATE_MANIFEST.lock" || verify_rc=$?
  if [[ $verify_rc -eq 0 ]]; then
    echo "Verification: clean."
  else
    # manifest_verify already printed its per-path drift report to
    # stdout above; nothing extra needed here. Map rc to exit code.
    if [[ -f "$preservation_block_artefact" ]]; then
      # Unreachable in practice (refusal handler exits before stamping)
      # but keep the mapping documented.
      exit 2
    fi
    if [[ $verify_rc -eq 1 || $verify_rc -eq 3 ]]; then
      exit 1
    fi
    # rc 2 means "manifest missing/unreadable" — surface as drift.
    exit 1
  fi

  # Issue #155: when the upgrade preserves custom canonical agent files
  # (entries in .template-customizations pointing at .claude/agents/*.md),
  # those files were last validated against the OLD schema. The new
  # release may have tightened the contract schema. Run a read-only
  # lint pass and surface failures as ACTION REQUIRED so the operator
  # backfills before the next session — instead of discovering it on
  # the next interactive lint run. Advisory only: the upgrade itself
  # is complete, exit code stays 0.
  lint_script="$project_root/scripts/lint-agent-contracts.sh"
  if [[ -x "$lint_script" ]]; then
    preserved_canonical_agents=()
    if [ "${#preserved[@]}" -gt 0 ]; then
      for pf in "${preserved[@]}"; do
        case "$pf" in
          .claude/agents/*.md)
            # Skip sme-* / *-local / sme-template — those aren't canonical
            # contract surfaces per lint-agent-contracts.sh's surface 1.
            case "$pf" in
              .claude/agents/sme-*.md|.claude/agents/*-local.md) ;;
              *) preserved_canonical_agents+=("$pf") ;;
            esac
            ;;
        esac
      done
    fi
    if [[ ${#preserved_canonical_agents[@]} -gt 0 ]]; then
      lint_log="$(mktemp -t upgrade-lint-XXXXXX.log)"
      lint_rc=0
      ( cd "$project_root" && "$lint_script" --canonical-only ) >"$lint_log" 2>&1 || lint_rc=$?
      if [[ $lint_rc -ne 0 ]]; then
        echo
        echo "ACTION REQUIRED: preserved custom agent file(s) fail the new contract schema (issue #155):"
        # Filter the lint log to lines that name a preserved canonical
        # agent path; show those plus their immediately-following
        # context (missing-section / schema-error detail).
        for pf in "${preserved_canonical_agents[@]}"; do
          if grep -F -- "$pf" "$lint_log" >/dev/null 2>&1; then
            echo "  $pf:"
            grep -F -- "$pf" "$lint_log" | sed 's/^/    /'
          fi
        done
        # Surface any errors that didn't match a preserved-agent path
        # in case the schema reports them by a different label.
        echo
        echo "  Full lint output (read-only --canonical-only pass):"
        sed 's/^/    /' "$lint_log"
        echo
        if [ -f "migrations/$new_version.sh" ]; then
          echo "  Backfill the missing sections per the rc-specific migration at"
          echo "    migrations/$new_version.sh"
          echo "  (or the latest migrations/<target>.sh that touches agent contracts)."
        else
          echo "  Backfill the missing sections per the latest migrations/<target>.sh"
          echo "  that touches agent contracts (no rc-specific migration exists for"
          echo "  $new_version)."
        fi
        echo "  The upgrade itself succeeded; this notice is advisory."
      fi
      rm -f "$lint_log"
    fi
  fi
else
  echo "(No changes written — this was a dry run.)"
fi
exit 0
