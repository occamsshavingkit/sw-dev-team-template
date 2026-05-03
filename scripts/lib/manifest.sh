#!/usr/bin/env bash
#
# scripts/lib/manifest.sh — shared TEMPLATE_MANIFEST.lock helpers.
#
# Per FW-ADR-0002 (upgrade content verification, hash-based, manifest-
# primary). Sourced by scripts/upgrade.sh (write at upgrade-end +
# verify at --verify) and scripts/scaffold.sh (write at scaffold-end
# + immediate self-verify).
#
# Exports:
#   manifest_ship_files <repo>           - list shipped files, sorted
#   manifest_file_sha   <abs-path>       - sha256 hex of one file
#   manifest_write      <repo> <out>     - write manifest from repo
#   manifest_verify     <repo> <manifest-path>
#                                        - verify; rc 0/1/2/3
#
# Files in .template-customizations are omitted from the manifest by
# design — the project has explicitly declared them permanently
# customised and the framework gives up the right to know what's in
# them.

# List **template-shipped** files from <paths-repo> using `git ls-files`,
# with the same exclusion regex the upgrade ship_files block uses.
# Optionally applies a project-side .template-customizations preserve-
# list when <project-repo> is provided.
#
# <paths-repo> MUST be a git repository — typically the upstream clone
# (`WORKDIR_NEW` / `WORKDIR_OLD`) or the template source repo. A
# downstream project tree is NOT a valid <paths-repo> because it may
# contain project-added files (sme-*, docs/pm/*, nested clones,
# operator notes) that are not template-shipped.
#
# v0.14.1 (#-fix): the v0.14.0 implementation enumerated paths from
# the project tree, which produced bloated manifests on projects with
# non-template content (and a useless `find`-fallback when the project
# was not git-initialised). The path source must be the upstream's
# git tree.
manifest_ship_files() {
  local paths_repo="$1"
  local project_repo="${2:-}"
  if [[ ! -d "$paths_repo/.git" ]]; then
    echo "ERROR: manifest_ship_files: '$paths_repo' is not a git repository." >&2
    echo "  Use a clone of the upstream template (or the template repo itself)." >&2
    echo "  Project trees are not a valid path source — they may contain" >&2
    echo "  non-template content that should not appear in the manifest." >&2
    return 1
  fi
  local -A preserve=()
  if [[ -n "$project_repo" && -f "$project_repo/.template-customizations" ]]; then
    while IFS= read -r line; do
      line="${line%%#*}"
      line="$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
      [[ -z "$line" ]] && continue
      preserve["$line"]=1
    done < "$project_repo/.template-customizations"
  fi
  (cd "$paths_repo" && git ls-files 2>/dev/null) \
    | grep -vE '^(VERSION|CHANGELOG\.md|CONTRIBUTING\.md|LICENSE|ROADMAP\.md|AGENTS\.md|TEMPLATE_VERSION|TEMPLATE_MANIFEST\.lock)$' \
    | grep -vE '^(\.github/|dryrun-project/|examples/|migrations/)' \
    | grep -vE '^\.claude/agents/[^/]+-local\.md$' \
    | grep -vE '^docs/(audits|v2|proposals)/' \
    | grep -vE '^docs/v1\.0-rc3-checklist\.md$' \
    | grep -vE '^docs/pm/process-audit-.*\.md$' \
    | grep -vE '^scripts/smoke-test\.sh$' \
    | while IFS= read -r f; do
        [[ -z "$f" ]] && continue
        [[ -n "${preserve[$f]:-}" ]] && continue
        echo "$f"
      done | sort
}

# SHA256 of a file (hex hash only, no filename).
manifest_file_sha() {
  sha256sum "$1" | awk '{print $1}'
}

# Write the manifest. Paths come from <paths-repo> (which MUST be a
# git-controlled tree — the upstream clone or the template source);
# SHA256 hashes are computed from the corresponding paths in
# <project-repo>. Files listed in <project-repo>'s
# .template-customizations are omitted. Files that exist in the
# upstream ship_files but are missing from the project are also
# omitted from the manifest (verify reports those separately by
# walking ship_files at verify time, not by the manifest content
# alone — see manifest_verify).
#
# v0.14.1 signature change: previously `manifest_write <repo> <out>`
# enumerated and hashed from the same <repo>; now path enumeration
# and SHA computation are decoupled.
manifest_write() {
  local paths_repo="$1"
  local project_repo="$2"
  local out="$3"
  {
    echo "# TEMPLATE_MANIFEST.lock — per FW-ADR-0002"
    echo "# Generated $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "# Format: <sha256>  <project-relative path>"
    echo "# Paths from upstream ship_files; SHAs from project tree."
    echo "# Files in .template-customizations are omitted by design."
    echo "#"
    while IFS= read -r f; do
      [[ -z "$f" ]] && continue
      if [[ -f "$project_repo/$f" ]]; then
        printf '%s  %s\n' "$(manifest_file_sha "$project_repo/$f")" "$f"
      fi
    done < <(manifest_ship_files "$paths_repo" "$project_repo")
  } > "$out"
}

# Verify <project-repo> against <manifest-path>. Walks every entry
# in the manifest and checks that the corresponding file in the
# project has the expected SHA256. The manifest is the canonical
# list of template-shipped paths; project-added files (sme-*,
# docs/pm/*, operator notes, nested clones, etc.) are out of scope
# and **not** reported as "extra" — they are project-owned by
# definition under the v0.14.1 design.
#
# Returns:
#   0  verified clean (every manifest entry matches)
#   1  drift detected (one or more files differ or are missing)
#   2  manifest missing or unreadable; verify could not run
#   3  manifest corrupt (malformed line, wrong SHA length)
manifest_verify() {
  local repo="$1"
  local manifest="$2"

  if [[ ! -f "$manifest" ]]; then
    echo "ERROR: manifest not found at $manifest" >&2
    echo "  Run 'scripts/upgrade.sh' to (re)generate it. Pre-v0.14.0" >&2
    echo "  projects without a manifest can also run scripts/upgrade.sh" >&2
    echo "  — the v0.14.0 migration synthesises an initial manifest." >&2
    return 2
  fi

  local -A expected=()
  while IFS= read -r line; do
    [[ -z "$line" || "${line:0:1}" == "#" ]] && continue
    local sha rest
    sha="${line%%  *}"
    rest="${line#*  }"
    if [[ ${#sha} -ne 64 || -z "$rest" ]]; then
      echo "ERROR: corrupt manifest line: $line" >&2
      return 3
    fi
    expected["$rest"]="$sha"
  done < "$manifest"

  local drift=0 ok=0
  local path
  for path in "${!expected[@]}"; do
    if [[ ! -f "$repo/$path" ]]; then
      printf 'missing:  %s  (in manifest but not in project)\n' "$path"
      drift=1
      continue
    fi
    local actual
    actual="$(manifest_file_sha "$repo/$path")"
    if [[ "$actual" != "${expected[$path]}" ]]; then
      printf 'drift:    %s\n  expected %s\n  actual   %s\n' "$path" "${expected[$path]}" "$actual"
      drift=1
    else
      ok=$((ok+1))
    fi
  done

  if [[ $drift -eq 0 ]]; then
    echo "OK: $ok files verified clean against manifest."
    return 0
  fi
  echo
  echo "Drift detected. Run 'scripts/upgrade.sh' to resync, or audit manually." >&2
  return 1
}
