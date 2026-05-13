#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# scripts/setup-github-labels.sh — idempotently create the FR-025
# taxonomy labels on a GitHub repository via `gh label create`.
#
# This is a setup script the customer runs against their own GitHub
# remote after a fresh clone or after a template upgrade introduces
# new labels. It is intentionally NOT invoked automatically by any
# pipeline; label creation is a shared-state action that the
# customer authorizes by running this script.
#
# Usage:
#   REPO=<owner>/<repo> scripts/setup-github-labels.sh [--dry-run]
#   scripts/setup-github-labels.sh --help
#
# Environment:
#   REPO   — required. GitHub repo slug, e.g. "occamsshavingkit/sw-dev-team-template".
#
# Flags:
#   --dry-run   List the labels that would be created without calling
#               `gh label create`. Does not contact GitHub.
#   --help, -h  Print this usage and exit 0.
#
# Exit codes:
#   0  success (all labels handled, or --help / --dry-run completed)
#   2  precondition failed (gh missing, REPO unset, bad flag)

set -eu

usage() {
  cat <<'USAGE'
setup-github-labels.sh — create the FR-025 taxonomy labels on a GitHub repo.

Usage:
  REPO=<owner>/<repo> scripts/setup-github-labels.sh [--dry-run]

Environment:
  REPO        Required. GitHub repo slug (e.g. "occamsshavingkit/sw-dev-team-template").

Flags:
  --dry-run   List the labels that would be created; do not call `gh label create`.
  --help, -h  Print this usage and exit.

Exit codes:
  0  success
  2  precondition failed (gh missing, REPO unset, bad flag)
USAGE
}

DRY_RUN=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --help|-h) usage; exit 0 ;;
    *)
      echo "setup-github-labels: unknown argument: $arg" >&2
      usage >&2
      exit 2
      ;;
  esac
done

# Precondition 1: gh must be installed.
if ! gh --version >/dev/null 2>&1; then
  echo "setup-github-labels: \`gh\` (GitHub CLI) is not installed. Install: https://cli.github.com/" >&2
  exit 2
fi

# Precondition 2: REPO must be set.
if [ -z "${REPO:-}" ]; then
  echo "setup-github-labels: REPO env var is required (e.g. REPO=owner/repo)." >&2
  usage >&2
  exit 2
fi

# FR-025 taxonomy label set. Format: name|color|description
# Color values are 6-hex-digit, no leading '#', per gh label create.
LABELS="\
template-gap|d73a4a|Missing framework capability surfaced by downstream use
template-friction|fbca04|Existing capability that is harder than necessary to use
authority-drift|5319e7|Source-of-truth confusion or stale manual mirrors (Constitution III)
docs-drift|0e8a16|Documentation diverged from code reality
agent-contract|1d76db|Issue in a canonical agent role file
atomic-question|ee0701|Customer-question protocol violation (FR-010 / FR-011)
model-routing|fbca04|Routing-table change or model fallback edge case
token-economy|0e8a16|Context-cost regression or runtime contract bloat
process-breakdown|d4c5f9|Workflow stage skipped or gate failed
traceability-gap|0052cc|Missing requirement / spec / test trace
generalization-risk|fef2c0|Project-specific code in framework-managed file
ai-behavior|bfd4f2|Agent behavioral regression or drift (prompt-regression catch)
m8-waiver|cccccc|Downstream-repo M8 waiver issue (per FR-029)"

# In non-dry-run mode, list existing labels once so each iteration is cheap.
EXISTING_LIST=""
if [ "$DRY_RUN" -eq 0 ]; then
  EXISTING_LIST=$(gh label list --repo "$REPO" --limit 200 2>/dev/null || true)
fi

# Counters live in temp files because the `while read` loop below runs
# in a subshell (pipeline RHS); plain shell-variable increments would
# not survive the loop exit under POSIX sh.
COUNT_DIR=$(mktemp -d)
trap 'rm -rf "$COUNT_DIR"' EXIT INT TERM HUP
echo 0 > "$COUNT_DIR/created"
echo 0 > "$COUNT_DIR/existing"
echo 0 > "$COUNT_DIR/would_create"

bump() {
  # bump <counter-name> — increment the named counter file by 1.
  _f="$COUNT_DIR/$1"
  _n=$(cat "$_f")
  echo $((_n + 1)) > "$_f"
}

# Iterate newline-separated label table; the IFS='|' prefix on `read`
# is local to that command, so no global IFS mutation occurs.
printf '%s\n' "$LABELS" | while IFS='|' read -r name color desc; do
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "would-create: $name (color=$color)"
    bump would_create
    continue
  fi

  # Idempotent: skip if a label with this exact name (column 1) already exists.
  if echo "$EXISTING_LIST" | awk -v n="$name" '$1 == n { found=1 } END { exit !found }'; then
    echo "exists: $name"
    bump existing
  else
    if gh label create --repo "$REPO" "$name" --description "$desc" --color "$color" >/dev/null 2>&1; then
      echo "created: $name"
      bump created
    else
      echo "failed: $name (gh label create returned non-zero)" >&2
    fi
  fi
done

CREATED=$(cat "$COUNT_DIR/created")
EXISTING=$(cat "$COUNT_DIR/existing")
WOULD_CREATE=$(cat "$COUNT_DIR/would_create")

if [ "$DRY_RUN" -eq 1 ]; then
  echo "setup-github-labels: dry-run — $WOULD_CREATE label(s) would be processed (no GitHub calls made)"
else
  echo "setup-github-labels: $CREATED new, $EXISTING already present"
fi
