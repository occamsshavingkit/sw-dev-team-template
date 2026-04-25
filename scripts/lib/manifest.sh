#!/usr/bin/env bash
#
# scripts/lib/manifest.sh — shared TEMPLATE_MANIFEST.lock helpers.
#
# Per ADR-0002 (upgrade content verification, hash-based, manifest-
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

# List shipped files in <repo>, project-relative, sorted, with the
# .template-customizations preserve-list applied. Same exclusion
# shape as the upgrade ship_files block; centralised here so verify
# uses identical filtering.
manifest_ship_files() {
  local repo="$1"
  local custfile="$repo/.template-customizations"
  local -A preserve=()
  if [[ -f "$custfile" ]]; then
    while IFS= read -r line; do
      line="${line%%#*}"
      line="$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
      [[ -z "$line" ]] && continue
      preserve["$line"]=1
    done < "$custfile"
  fi
  local raw
  if [[ -d "$repo/.git" ]]; then
    raw="$(cd "$repo" && git ls-files 2>/dev/null)"
  else
    raw="$(cd "$repo" && find . -type f -not -path "./.git/*" -printf '%P\n' 2>/dev/null)"
  fi
  echo "$raw" \
    | grep -vE '^(VERSION|CHANGELOG\.md|CONTRIBUTING\.md|LICENSE|TEMPLATE_VERSION|TEMPLATE_MANIFEST\.lock)$' \
    | grep -vE '^(\.github/|dryrun-project/|examples/|migrations/)' \
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

# Write the manifest from <repo> to <out-path>. Deterministic:
# files sorted by path, single space-pair separator, header comment
# block giving generation time and provenance.
manifest_write() {
  local repo="$1"
  local out="$2"
  {
    echo "# TEMPLATE_MANIFEST.lock — per ADR-0002"
    echo "# Generated $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "# Format: <sha256>  <project-relative path>"
    echo "# Files in .template-customizations are omitted by design."
    echo "#"
    while IFS= read -r f; do
      [[ -z "$f" ]] && continue
      printf '%s  %s\n' "$(manifest_file_sha "$repo/$f")" "$f"
    done < <(manifest_ship_files "$repo")
  } > "$out"
}

# Verify <manifest-path> against <repo>. Prints a human-readable
# drift report. Returns:
#   0  verified clean (every file matches manifest entry)
#   1  drift detected (one or more files differ / extra / missing)
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

  local -A seen=()
  local drift=0 ok=0

  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    seen["$f"]=1
    if [[ -z "${expected[$f]:-}" ]]; then
      printf 'extra:    %s  (in project but not in manifest)\n' "$f"
      drift=1
    else
      local actual
      actual="$(manifest_file_sha "$repo/$f")"
      if [[ "$actual" != "${expected[$f]}" ]]; then
        printf 'drift:    %s\n  expected %s\n  actual   %s\n' "$f" "${expected[$f]}" "$actual"
        drift=1
      else
        ok=$((ok+1))
      fi
    fi
  done < <(manifest_ship_files "$repo")

  local path
  for path in "${!expected[@]}"; do
    if [[ -z "${seen[$path]:-}" ]]; then
      printf 'missing:  %s  (in manifest but not in project)\n' "$path"
      drift=1
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
