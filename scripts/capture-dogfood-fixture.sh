#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# scripts/capture-dogfood-fixture.sh — operator-local fixture capture.
#
# Snapshots a real downstream project into a content-only tree the
# dogfood-downstream driver can replay against scripts/upgrade.sh.
# History is intentionally stripped: the snapshot is *content*, not
# a working repository. This mirrors the spec-008 generator pattern
# (tests/release-gate/snapshots/ also ships history-less trees).
#
# Operator-only: this script touches an operator clone URL. Run it
# locally with credentials that can clone the source repo. The URL
# is consumed once for the clone and never written to disk.
#
# Output never carries the source repo's identity — only the
# operator-supplied codename appears in the destination path.
# Operators choosing a codename should follow the redaction rule:
# generic, non-identifying labels (alpha / beta / gamma /
# example-project) over real customer or vendor names.
#
# Usage:
#   scripts/capture-dogfood-fixture.sh \
#       --from-url <url> \
#       --rc <state> \
#       --codename <name> \
#       [--out <path>] \
#       [--ref <name>] \
#       [--verbose] \
#       [--help]
#
# Arguments:
#   --from-url <url>   Clone URL (https, ssh, file://, or a local path).
#                      Consumed once, then discarded. Not persisted.
#   --rc <state>       The rc / version label the source was at when
#                      captured (e.g. rc8, rc11, v1.0.0). Appears in
#                      the destination path.
#   --codename <name>  Operator-chosen label. Appears in the destination
#                      path. Keep generic.
#   --out <path>       Destination directory. Default:
#                      ${HOME}/ref/dogfood/<codename>/<rc>/
#   --ref <name>       Optional clone ref (tag or branch). Useful when
#                      the source URL's default branch is not what you
#                      want captured. Passed as `--branch <ref>` to
#                      git clone (which accepts both tags and branches).
#   --verbose          Print one line per removed-or-skipped scrub path.
#   --help, -h         Print this help and exit.
#
# Exit codes:
#   0  Snapshot captured successfully
#   2  Argument validation error
#   3  Clone or copy failure

set -eu

usage() {
    cat <<'USAGE'
Usage: scripts/capture-dogfood-fixture.sh
         --from-url <url>
         --rc <state>
         --codename <name>
         [--out <path>]
         [--ref <name>]
         [--verbose]
         [--help]

Clones a downstream project, strips .git/ and related git/CI metadata,
and stores the content tree at the destination for later replay by
the dogfood driver.

Required:
  --from-url <url>   Clone URL (consumed once, discarded).
  --rc <state>       rc / version label (e.g. rc8, rc11).
  --codename <name>  Generic, non-identifying label.

Optional:
  --out <path>       Destination dir
                     (default ${HOME}/ref/dogfood/<codename>/<rc>/).
  --ref <name>       Optional tag or branch ref to clone (passes
                     `--branch <ref>` to git clone).
  --verbose          Print one line per scrub path (kept/removed).
  --help, -h         This help.

Operator-only tool. Never commits the URL or any source-repo
identifier. Companion to tests/release-gate/dogfood-downstream.sh.

Scrubbed from the snapshot (always):
  .git/, nested submodule .git pointer files, .gitattributes,
  .gitmodules, .github/, .git-credentials (defensive).

Operator-responsibility: any other identifying metadata that may
have crept into the source tree (e.g. .dockerignore comments
referencing the repo, CI-runner labels, custom dotfile configs
embedding org / repo URLs) is NOT auto-scrubbed. Inspect the
destination before sharing reports outside the operator's machine.
USAGE
}

# ---- arg parsing -----------------------------------------------------

FROM_URL=""
RC=""
CODENAME=""
OUT=""
REF=""
VERBOSE=0

while [ "$#" -gt 0 ]; do
    case "$1" in
        --help|-h)
            usage
            exit 0
            ;;
        --from-url)
            if [ "$#" -lt 2 ] || [ -z "${2:-}" ]; then
                echo "ERROR: --from-url requires a URL argument" >&2
                exit 2
            fi
            FROM_URL="$2"
            shift 2
            ;;
        --rc)
            if [ "$#" -lt 2 ] || [ -z "${2:-}" ]; then
                echo "ERROR: --rc requires a state argument" >&2
                exit 2
            fi
            RC="$2"
            shift 2
            ;;
        --codename)
            if [ "$#" -lt 2 ] || [ -z "${2:-}" ]; then
                echo "ERROR: --codename requires a name argument" >&2
                exit 2
            fi
            CODENAME="$2"
            shift 2
            ;;
        --out)
            if [ "$#" -lt 2 ] || [ -z "${2:-}" ]; then
                echo "ERROR: --out requires a path argument" >&2
                exit 2
            fi
            OUT="$2"
            shift 2
            ;;
        --ref)
            if [ "$#" -lt 2 ] || [ -z "${2:-}" ]; then
                echo "ERROR: --ref requires a name argument" >&2
                exit 2
            fi
            REF="$2"
            shift 2
            ;;
        --verbose)
            VERBOSE=1
            shift
            ;;
        *)
            echo "ERROR: unknown flag: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

if [ -z "$FROM_URL" ]; then
    echo "ERROR: --from-url is required" >&2
    usage >&2
    exit 2
fi
if [ -z "$RC" ]; then
    echo "ERROR: --rc is required" >&2
    usage >&2
    exit 2
fi
if [ -z "$CODENAME" ]; then
    echo "ERROR: --codename is required" >&2
    usage >&2
    exit 2
fi

# Reject obviously identifying codenames? No — that's a judgment
# call. Document the redaction discipline in the README and trust
# the operator. The repo-level protection is .gitignore.

if [ -z "$OUT" ]; then
    OUT="${HOME}/ref/dogfood/${CODENAME}/${RC}"
fi

if [ -e "$OUT" ]; then
    echo "ERROR: destination already exists: $OUT" >&2
    echo "       Remove it first or choose a different --out." >&2
    exit 2
fi

# ---- clone into scratch ----------------------------------------------

SCRATCH="$(mktemp -d -t dogfood-capture.XXXXXX)"
# shellcheck disable=SC2317  # false positive: cleanup() is invoked via trap
cleanup() {
    if [ -n "${SCRATCH:-}" ] && [ -d "$SCRATCH" ]; then
        rm -rf "$SCRATCH"
    fi
}
trap cleanup EXIT INT TERM

CLONE_DIR="$SCRATCH/clone"
# --depth 1 to keep the temporary clone small; we strip .git anyway.
# When --ref is supplied, pass --branch so the clone is allowed to
# resolve a non-default tag or branch under the shallow constraint.
if [ -n "$REF" ]; then
    if ! git clone --depth 1 --branch "$REF" --quiet "$FROM_URL" "$CLONE_DIR" >/dev/null 2>&1; then
        echo "ERROR: git clone failed for the supplied URL + --ref" >&2
        echo "       (URL not echoed to keep it out of logs; check your" >&2
        echo "       credentials / network / ref name and try again.)" >&2
        exit 3
    fi
else
    if ! git clone --depth 1 --quiet "$FROM_URL" "$CLONE_DIR" >/dev/null 2>&1; then
        echo "ERROR: git clone failed for the supplied URL" >&2
        echo "       (URL not echoed to keep it out of logs; check your" >&2
        echo "       credentials / network and try again.)" >&2
        exit 3
    fi
fi

# ---- scrub git + CI metadata ----------------------------------------
#
# Snapshot is content, not history. Strip:
#   - .git/                 — full history dir
#   - nested .git           — submodule pointer files (defensive)
#   - .gitattributes        — may carry org-specific normalisation
#   - .gitmodules           — leaks submodule URLs
#   - .github/              — operator's workflow defs leak org/repo
#   - .git-credentials      — defensive; should never be present
#
# In --verbose mode, print one line per path acted on.
scrub_log() {
    if [ "$VERBOSE" -eq 1 ]; then
        printf 'scrub: %s\n' "$1"
    fi
}

if [ -d "$CLONE_DIR/.git" ]; then
    rm -rf "$CLONE_DIR/.git"
    scrub_log "removed .git/"
else
    scrub_log "skipped .git/ (not present)"
fi

# Submodule .git pointer files (files, not dirs); print only when verbose.
if [ "$VERBOSE" -eq 1 ]; then
    find "$CLONE_DIR" -name ".git" -type f 2>/dev/null | while IFS= read -r p; do
        rel="${p#"$CLONE_DIR"/}"
        scrub_log "removed nested .git pointer: $rel"
    done
fi
find "$CLONE_DIR" -name ".git" -type f -delete 2>/dev/null || true

# Top-level git config files + GitHub workflows + credentials.
for path in .gitattributes .gitmodules .github .git-credentials; do
    full="$CLONE_DIR/$path"
    if [ -e "$full" ]; then
        rm -rf "$full"
        scrub_log "removed $path"
    else
        scrub_log "skipped $path (not present)"
    fi
done

# ---- copy to destination ---------------------------------------------

# Create parent dir.
parent_dir="$(dirname "$OUT")"
mkdir -p "$parent_dir"

# cp -a preserves modes, timestamps, symlinks; trailing /. copies
# contents including dotfiles.
if ! cp -a "$CLONE_DIR" "$OUT"; then
    echo "ERROR: copy to $OUT failed" >&2
    exit 3
fi

# ---- report ----------------------------------------------------------

SIZE="$(du -sh "$OUT" 2>/dev/null | awk '{print $1}')"
FILE_COUNT="$(find "$OUT" -type f 2>/dev/null | wc -l | tr -d ' ')"

printf 'Snapshot captured.\n'
printf '  destination:  %s\n' "$OUT"
printf '  codename:     %s\n' "$CODENAME"
printf '  rc state:     %s\n' "$RC"
printf '  size:         %s\n' "$SIZE"
printf '  file count:   %s\n' "$FILE_COUNT"
printf '\n'
printf 'Replay with:\n'
printf '  tests/release-gate/dogfood-downstream.sh \\\n'
printf '      --fixture %s \\\n' "$OUT"
printf '      --upstream <ref> \\\n'
printf '      --codename %s\n' "$CODENAME"
