#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# scripts/lint-canonical-sha.sh — canonical_sha staleness guard (#143).
#
# For each canonical agent source at .claude/agents/<role>.md, compute
# its current git blob SHA (git rev-parse HEAD:<path>) and compare it
# against the canonical_sha: frontmatter field in:
#   docs/runtime/agents/<role>.md
#   .opencode/agents/<role>.md
#
# A mismatch means the canonical was edited and committed but the generated
# artefact was not regenerated + committed in the same change set.
#
# Exit codes:
#   0  all canonical_sha fields match current HEAD blob SHAs
#   1  one or more mismatches (diagnostic printed to stderr)
#   2  usage / environment error (no git, no agents dir, etc.)
#
# Usage:
#   scripts/lint-canonical-sha.sh [--summary] [--agents-dir <path>]
#     [--runtime-dir <path>] [--opencode-dir <path>]
#
# Flags:
#   --summary              emit a final PASS/FAIL summary line on stdout
#   --agents-dir <path>    canonical sources (default: .claude/agents)
#   --runtime-dir <path>   compact runtime artefacts (default: docs/runtime/agents)
#   --opencode-dir <path>  opencode adapter artefacts (default: .opencode/agents)
#   --no-opencode          skip .opencode/agents/ check
#   -h | --help            this help
#
# POSIX-sh only: no bashisms; LANG=C/LC_ALL=C.
# Requires: git (for rev-parse HEAD:<path>)

set -eu

LANG=C
LC_ALL=C
export LANG LC_ALL

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

AGENTS_DIR="${REPO_ROOT}/.claude/agents"
RUNTIME_DIR="${REPO_ROOT}/docs/runtime/agents"
OPENCODE_DIR="${REPO_ROOT}/.opencode/agents"
SUMMARY=0
NO_OPENCODE=0

usage() {
    cat >&2 <<'EOF'
Usage: scripts/lint-canonical-sha.sh [--summary] [--agents-dir <path>]
         [--runtime-dir <path>] [--opencode-dir <path>] [--no-opencode]

Checks that every generated agent artefact carries a canonical_sha: that
matches the current git blob SHA of its canonical source file.

Flags:
  --summary              emit a final PASS/FAIL summary line
  --agents-dir DIR       canonical sources (default: .claude/agents)
  --runtime-dir DIR      compact runtime artefacts (default: docs/runtime/agents)
  --opencode-dir DIR     opencode adapter artefacts (default: .opencode/agents)
  --no-opencode          skip .opencode/agents/ check
  -h | --help            this help

Exit codes:
  0  all canonical_sha fields are current
  1  one or more mismatches
  2  usage / environment error
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --summary) SUMMARY=1; shift ;;
        --agents-dir)
            [ $# -ge 2 ] || { usage; exit 2; }
            AGENTS_DIR="$2"; shift 2 ;;
        --runtime-dir)
            [ $# -ge 2 ] || { usage; exit 2; }
            RUNTIME_DIR="$2"; shift 2 ;;
        --opencode-dir)
            [ $# -ge 2 ] || { usage; exit 2; }
            OPENCODE_DIR="$2"; shift 2 ;;
        --no-opencode) NO_OPENCODE=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) printf 'lint-canonical-sha: unknown arg: %s\n' "$1" >&2; usage; exit 2 ;;
    esac
done

# ---- Environment checks ---------------------------------------------------

if ! command -v git >/dev/null 2>&1; then
    printf 'lint-canonical-sha: git not found on PATH\n' >&2
    exit 2
fi

if [ ! -d "${AGENTS_DIR}" ]; then
    printf 'lint-canonical-sha: agents dir not found: %s\n' "${AGENTS_DIR}" >&2
    exit 2
fi

if [ ! -d "${RUNTIME_DIR}" ]; then
    printf 'lint-canonical-sha: runtime dir not found: %s\n' "${RUNTIME_DIR}" >&2
    exit 2
fi

if [ "${NO_OPENCODE}" -eq 0 ] && [ ! -d "${OPENCODE_DIR}" ]; then
    printf 'lint-canonical-sha: opencode dir not found: %s\n' "${OPENCODE_DIR}" >&2
    exit 2
fi

# Resolve the git work-tree root so rev-parse paths are relative to it.
# Use AGENTS_DIR (not REPO_ROOT) so --agents-dir overrides pointing at a
# different repo (e.g. test fixtures) resolve the correct git root.
GIT_ROOT="$(git -C "${AGENTS_DIR}" rev-parse --show-toplevel 2>/dev/null)" || {
    printf 'lint-canonical-sha: could not determine git root under %s\n' "${AGENTS_DIR}" >&2
    exit 2
}

# ---- Helper: extract canonical_sha from a generated artefact frontmatter --
# Prints the 40-hex SHA or empty string on failure.
extract_canonical_sha() {
    artefact="$1"
    # Parse YAML frontmatter: lines between the first and second '---' sentinel.
    awk '
        BEGIN { state = "pre" }
        {
            if (state == "pre") {
                if ($0 == "---") { state = "fm"; next }
                exit
            }
            if (state == "fm") {
                if ($0 == "---") { exit }
                if ($0 ~ /^canonical_sha:[ \t]*[0-9a-f]{40}[ \t]*$/) {
                    val = $0
                    sub(/^canonical_sha:[ \t]*/, "", val)
                    sub(/[ \t]*$/, "", val)
                    print val
                    exit
                }
            }
        }
    ' "${artefact}"
}

# ---- Helper: compute relative path from GIT_ROOT for rev-parse ----------
# git rev-parse HEAD:<path> requires a path relative to the repo root.
# Use shell parameter expansion (not sed) to strip the prefix as a literal
# string — sed would treat special regex chars in GIT_ROOT (e.g. '.') as
# wildcards.
rel_to_git_root() {
    abs="$1"
    printf '%s' "${abs#${GIT_ROOT}/}"
}

# ---- Main check loop ------------------------------------------------------

overall_fail=0

for canonical in "${AGENTS_DIR}"/*.md; do
    [ -f "${canonical}" ] || continue
    base="$(basename "${canonical}" .md)"
    # Skip sme-template and any non-kebab filenames (same filter as compiler).
    case "${base}" in
        sme-template) continue ;;
        *[!a-z0-9-]*|"") continue ;;
    esac

    # Compute the current HEAD blob SHA for this canonical.
    rel_path="$(rel_to_git_root "${canonical}")"
    current_sha="$(git -C "${GIT_ROOT}" rev-parse "HEAD:${rel_path}" 2>/dev/null || true)"
    if [ -z "${current_sha}" ] || \
       ! printf '%s' "${current_sha}" | grep -qE '^[0-9a-f]{40}$'; then
        printf 'lint-canonical-sha: WARN: could not resolve git blob SHA for %s; skipping\n' \
            "${rel_path}" >&2
        continue
    fi

    # Check compact runtime artefact.
    runtime_artefact="${RUNTIME_DIR}/${base}.md"
    if [ ! -f "${runtime_artefact}" ]; then
        printf 'lint-canonical-sha: MISSING_ARTEFACT: %s (no paired runtime contract)\n' \
            "${runtime_artefact}" >&2
        overall_fail=1
    else
        recorded_sha="$(extract_canonical_sha "${runtime_artefact}")"
        if [ -z "${recorded_sha}" ]; then
            printf 'lint-canonical-sha: NO_SHA_FIELD: %s (canonical_sha: field absent or malformed)\n' \
                "${runtime_artefact}" >&2
            overall_fail=1
        elif [ "${recorded_sha}" != "${current_sha}" ]; then
            printf 'lint-canonical-sha: STALE: %s\n  recorded canonical_sha: %s\n  current  HEAD blob SHA: %s\n  Fix: rerun scripts/compile-runtime-agents.sh and commit both files together.\n' \
                "${runtime_artefact}" "${recorded_sha}" "${current_sha}" >&2
            overall_fail=1
        fi
    fi

    # Check opencode adapter artefact.
    if [ "${NO_OPENCODE}" -eq 0 ]; then
        opencode_artefact="${OPENCODE_DIR}/${base}.md"
        if [ ! -f "${opencode_artefact}" ]; then
            printf 'lint-canonical-sha: MISSING_ARTEFACT: %s (no paired opencode adapter)\n' \
                "${opencode_artefact}" >&2
            overall_fail=1
        else
            recorded_sha="$(extract_canonical_sha "${opencode_artefact}")"
            if [ -z "${recorded_sha}" ]; then
                printf 'lint-canonical-sha: NO_SHA_FIELD: %s (canonical_sha: field absent or malformed)\n' \
                    "${opencode_artefact}" >&2
                overall_fail=1
            elif [ "${recorded_sha}" != "${current_sha}" ]; then
                printf 'lint-canonical-sha: STALE: %s\n  recorded canonical_sha: %s\n  current  HEAD blob SHA: %s\n  Fix: rerun scripts/compile-runtime-agents.sh and commit both files together.\n' \
                    "${opencode_artefact}" "${recorded_sha}" "${current_sha}" >&2
                overall_fail=1
            fi
        fi
    fi
done

if [ "${SUMMARY}" -eq 1 ]; then
    if [ "${overall_fail}" -eq 0 ]; then
        printf 'lint-canonical-sha: PASS\n'
    else
        printf 'lint-canonical-sha: FAIL\n'
    fi
fi

exit "${overall_fail}"
