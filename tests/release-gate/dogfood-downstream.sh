#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# tests/release-gate/dogfood-downstream.sh — generic dogfood driver.
#
# Exercises scripts/upgrade.sh against a locally-stored snapshot tree
# of a real downstream project, *without* touching the operator's
# original repository. The original is the operator's truth; this
# driver only operates on a scratch clone.
#
# This script is intentionally generic: no project names appear in any
# committed artefact. Operators pass a codename (alpha / beta / gamma /
# whatever convention they like) on the command line; the codename
# never identifies a specific downstream project to anyone who does
# not already have the fixture path.
#
# Companion: scripts/capture-dogfood-fixture.sh produces the snapshot
# tree (operator-local) that this driver consumes.
#
# Usage:
#   tests/release-gate/dogfood-downstream.sh \
#       --fixture <path> \
#       --upstream <ref> \
#       [--codename <name>] \
#       [--out <path>] \
#       [--help]
#
# Arguments:
#   --fixture <path>   Snapshot tree of a scaffolded project (the
#                      operator's local fixture; typically lives under
#                      ~/ref/dogfood/<codename>/<rc>/). Must contain
#                      TEMPLATE_VERSION and scripts/upgrade.sh.
#   --upstream <ref>   Template ref to upgrade to. Accepts anything
#                      upgrade.sh --target accepts: a tag (v1.0.0),
#                      a branch (origin/main, feat/foo), or a
#                      commit SHA. Leverages the untagged-target
#                      feature (PR #186).
#   --codename <name>  Label used only in the output report's filename
#                      and column headings. Operator picks. Defaults
#                      to the basename of --fixture. Generic examples:
#                      alpha, beta, gamma, example-project.
#   --out <path>       Where to write the report. Default:
#                      /tmp/dogfood-<codename>-<timestamp>.txt
#   --help, -h         Print this help and exit.
#
# Exit codes:
#   0  PASS — upgrade ran, --verify clean, no unresolved conflicts,
#      AI TUI check passed (or was legitimately skipped because the
#      fixture has no hooks)
#   1  FAIL — upgrade non-zero exit, verify non-zero, .template-
#      conflicts.json contains an entry classified "conflict", or
#      AI TUI check caught a session-shape regression
#   2  Argument or fixture validation error
#
# Phases (run in order; later phases skip if earlier ones fail):
#   1. upgrade.sh --target <ref>   (script-level upgrade)
#   2. upgrade.sh --verify         (script-level verification)
#   3. AI TUI check                (session-shape payloads through
#                                   the upgraded fixture's hooks;
#                                   driver: tests/hooks/run-ai-tui-check.sh)
#
# Safety:
#   - The fixture is rsync-copied to a mktemp scratch dir; the
#     operator's original tree is never modified.
#   - Scratch dir is removed on exit (success or fail). Operator's
#     fixture is preserved.
#   - No project-identifying string from the fixture is written into
#     any committed file. The report contains only the operator-
#     supplied codename, paths under the scratch dir, and
#     TEMPLATE_VERSION lines (which are framework version stamps,
#     not project identity).

set -eu

usage() {
    cat <<'USAGE'
Usage: tests/release-gate/dogfood-downstream.sh
         --fixture <path>
         --upstream <ref>
         [--codename <name>]
         [--out <path>]
         [--help]

Runs scripts/upgrade.sh against a local fixture snapshot of a
downstream project. Writes a PASS/FAIL report; original fixture
untouched.

Required:
  --fixture <path>   Local snapshot tree (must contain TEMPLATE_VERSION
                     and scripts/upgrade.sh).
  --upstream <ref>   Template ref: tag, branch, or commit SHA.

Optional:
  --codename <name>  Label for the report (default: basename of fixture).
  --out <path>       Report path (default: /tmp/dogfood-<codename>-<ts>.txt).
  --help, -h         This help.

Exit 0 PASS, 1 FAIL, 2 argument / validation error.

Companion: scripts/capture-dogfood-fixture.sh captures fixtures.
See tests/release-gate/dogfood-downstream.README.md.
USAGE
}

# ---- arg parsing -----------------------------------------------------

FIXTURE=""
UPSTREAM_REF=""
CODENAME=""
OUT=""

while [ "$#" -gt 0 ]; do
    case "$1" in
        --help|-h)
            usage
            exit 0
            ;;
        --fixture)
            if [ "$#" -lt 2 ] || [ -z "${2:-}" ]; then
                echo "ERROR: --fixture requires a path argument" >&2
                exit 2
            fi
            FIXTURE="$2"
            shift 2
            ;;
        --upstream)
            if [ "$#" -lt 2 ] || [ -z "${2:-}" ]; then
                echo "ERROR: --upstream requires a ref argument" >&2
                exit 2
            fi
            UPSTREAM_REF="$2"
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
        *)
            echo "ERROR: unknown flag: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

if [ -z "$FIXTURE" ]; then
    echo "ERROR: --fixture is required" >&2
    usage >&2
    exit 2
fi
if [ -z "$UPSTREAM_REF" ]; then
    echo "ERROR: --upstream is required" >&2
    usage >&2
    exit 2
fi
if [ -z "$CODENAME" ]; then
    CODENAME="$(basename "$FIXTURE")"
fi

# ---- fixture validation ----------------------------------------------

if [ ! -d "$FIXTURE" ]; then
    echo "ERROR: fixture path is not a directory: $FIXTURE" >&2
    exit 2
fi
if [ ! -f "$FIXTURE/TEMPLATE_VERSION" ]; then
    echo "ERROR: fixture missing TEMPLATE_VERSION: $FIXTURE" >&2
    exit 2
fi
if [ ! -f "$FIXTURE/scripts/upgrade.sh" ]; then
    echo "ERROR: fixture missing scripts/upgrade.sh: $FIXTURE" >&2
    exit 2
fi

TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
if [ -z "$OUT" ]; then
    OUT="/tmp/dogfood-${CODENAME}-${TIMESTAMP}.txt"
fi

# ---- scratch workspace -----------------------------------------------

SCRATCH="$(mktemp -d -t dogfood-driver.XXXXXX)"
# shellcheck disable=SC2317  # false positive: cleanup() is invoked via trap
cleanup() {
    if [ -n "${SCRATCH:-}" ] && [ -d "$SCRATCH" ]; then
        rm -rf "$SCRATCH"
    fi
}
trap cleanup EXIT INT TERM

SCRATCH_TREE="$SCRATCH/tree"
# Use cp -aL; rsync is not POSIX-mandatory. cp -a preserves modes,
# timestamps; -L dereferences symlinks at copy time, turning them
# into real files in the scratch tree. Dereferencing matters for
# the dogfood-examples fixtures whose stub `scripts/upgrade.sh` is
# a symlink into `dogfood-examples/_shared/` (outside the per-
# fixture root); without -L the copy preserves the symlink but the
# target is no longer reachable inside the scratch tree.
#
# Real captured fixtures are unaffected: a git-clone content tree
# with internal symlinks gets a slightly heavier copy (links
# resolved to files); external symlinks that would have been
# dangling in the original now resolve correctly — strict
# improvement.
#
# Trailing /. copies contents (incl. dotfiles).
mkdir -p "$SCRATCH_TREE"
cp -aL "$FIXTURE/." "$SCRATCH_TREE/"

# upgrade.sh runs `git rev-parse --show-toplevel`; needs a repo.
# Initialise a throwaway one inside the scratch tree.
# Capture stderr to a log file (parallel to $UPGRADE_LOG) so operators
# have something to read when init fails — silent || error gives no
# diagnostic.
GIT_INIT_LOG="$SCRATCH/git-init.log"
if ! (
    cd "$SCRATCH_TREE"
    git init -q
    git config user.email "dogfood@example.invalid"
    git config user.name "dogfood-driver"
    git add -A
    git commit -q -m "fixture snapshot for dogfood driver" --allow-empty
) >"$GIT_INIT_LOG" 2>&1; then
    echo "ERROR: failed to initialise scratch git repo at $SCRATCH_TREE" >&2
    echo "       see log: $GIT_INIT_LOG" >&2
    # Copy the log to a stable path under /tmp so it survives the
    # trap cleanup; the operator wants to actually read it.
    PERSISTED_LOG="/tmp/dogfood-git-init-${TIMESTAMP}.log"
    cp -p "$GIT_INIT_LOG" "$PERSISTED_LOG" 2>/dev/null || true
    if [ -f "$PERSISTED_LOG" ]; then
        echo "       persisted copy: $PERSISTED_LOG" >&2
    fi
    exit 2
fi

# ---- before state ----------------------------------------------------

TEMPLATE_BEFORE_FILE="$SCRATCH_TREE/TEMPLATE_VERSION"
TEMPLATE_BEFORE="$(cat "$TEMPLATE_BEFORE_FILE" 2>/dev/null || echo '<unreadable>')"

# ---- run upgrade -----------------------------------------------------

UPGRADE_LOG="$SCRATCH/upgrade.log"
UPGRADE_RC=0
(
    cd "$SCRATCH_TREE"
    ./scripts/upgrade.sh --target "$UPSTREAM_REF"
) >"$UPGRADE_LOG" 2>&1 || UPGRADE_RC=$?

# ---- run verify ------------------------------------------------------

VERIFY_LOG="$SCRATCH/verify.log"
VERIFY_RC=0
(
    cd "$SCRATCH_TREE"
    ./scripts/upgrade.sh --verify
) >"$VERIFY_LOG" 2>&1 || VERIFY_RC=$?

# ---- after state -----------------------------------------------------

TEMPLATE_AFTER="$(cat "$SCRATCH_TREE/TEMPLATE_VERSION" 2>/dev/null || echo '<unreadable>')"
GIT_STATUS="$(cd "$SCRATCH_TREE" && git status --porcelain 2>/dev/null || echo '<git-status-failed>')"
GIT_DIFFSTAT="$(cd "$SCRATCH_TREE" && git diff --stat HEAD 2>/dev/null || echo '<git-diff-failed>')"

CONFLICTS_PATH="$SCRATCH_TREE/.template-conflicts.json"
CONFLICTS_PRESENT="no"
CONFLICT_COUNT=0
CONFLICT_BODY=""
CONFLICT_PARSE_NOTE=""
if [ -f "$CONFLICTS_PATH" ]; then
    CONFLICTS_PRESENT="yes"
    # Prefer jq for structural parse — handles arbitrary whitespace,
    # key order, and nested structures. Falls back to a tighter regex
    # when jq is unavailable.
    if command -v jq >/dev/null 2>&1; then
        # The file shape is an object whose `.entries` field is an
        # array of entry objects (see scripts/upgrade.sh writer and
        # tests/release-gate/snapshots/v1.0.0-rc12/with-accepted-local/
        # .template-conflicts.json for the canonical shape).
        # Count entries whose `classified` field equals "conflict".
        # The `?` after `.entries[]` tolerates `.entries` being absent
        # (malformed file) by producing an empty stream → count 0
        # instead of a jq runtime error. The defensive numeric guard
        # (tr -cd '0-9' + ${VAR:-0}) coerces any non-numeric result
        # (e.g. "null", empty string, jq error swallowed by the
        # outer redirect) into 0 so the later `[ -gt 0 ]` test never
        # errors under `set -eu`.
        CONFLICT_COUNT="$(jq '[.entries[]? | select(.classified == "conflict")] | length' "$CONFLICTS_PATH" 2>/dev/null | tr -cd '0-9')"
        CONFLICT_COUNT="${CONFLICT_COUNT:-0}"
    else
        # Fallback: allow arbitrary whitespace between key, colon, and
        # value; still order-dependent on the key spelling but more
        # tolerant than the original literal match. Reduced precision.
        CONFLICT_COUNT="$(grep -Ec '"classified"[[:space:]]*:[[:space:]]*"conflict"' "$CONFLICTS_PATH" 2>/dev/null | tr -cd '0-9')"
        CONFLICT_COUNT="${CONFLICT_COUNT:-0}"
        CONFLICT_PARSE_NOTE="WARN: jq not found; conflict count parsed via regex (reduced precision)."
    fi
    CONFLICT_BODY="$(cat "$CONFLICTS_PATH" 2>/dev/null || echo '<read-failed>')"
fi

# ---- AI TUI check phase ----------------------------------------------
#
# After script-level checks pass, exercise the UPGRADED fixture's
# hook set against the session-shape corpus. Script-level PASS proves
# upgrade.sh ran cleanly; AI TUI check proves the resulting hooks
# don't break Claude Code / Codex session workflow (commit-message
# HEREDOCs, inline SWDT_AGENT_PUSH escape hatch, specialist dispatch,
# read-only inspections). See feedback-dogfood-needs-tui-check.
#
# Phase is activated when the upgraded fixture carries a
# .claude/settings.json with PreToolUse hooks. If absent, the driver
# emits a NOTE and treats the phase as skipped (not a regression).
#
# Driver path: tests/hooks/run-ai-tui-check.sh (sibling of this
# script). Resolved relative to this driver's own location so the
# dogfood driver works when invoked from any cwd.

AI_TUI_RC=-1
AI_TUI_LOG="$SCRATCH/ai-tui.log"
AI_TUI_DRIVER="$(cd "$(dirname "$0")/../.." && pwd)/tests/hooks/run-ai-tui-check.sh"
AI_TUI_STATUS="not-run"

# Only run the AI TUI check if script-level upgrade + verify passed.
# Running it on a broken upgrade adds noise without signal.
if [ "$UPGRADE_RC" -eq 0 ] && [ "$VERIFY_RC" -eq 0 ]; then
    if [ -x "$AI_TUI_DRIVER" ]; then
        AI_TUI_RC=0
        "$AI_TUI_DRIVER" --fixture "$SCRATCH_TREE" >"$AI_TUI_LOG" 2>&1 || AI_TUI_RC=$?
        case "$AI_TUI_RC" in
            0) AI_TUI_STATUS="pass" ;;
            1) AI_TUI_STATUS="fail" ;;
            2) AI_TUI_STATUS="invocation-error" ;;
            3) AI_TUI_STATUS="pyyaml-missing" ;;
            4) AI_TUI_STATUS="skipped-no-hooks" ;;
            *) AI_TUI_STATUS="unknown-rc=${AI_TUI_RC}" ;;
        esac
    else
        AI_TUI_STATUS="driver-missing"
        printf 'run-ai-tui-check driver missing: %s\n' "$AI_TUI_DRIVER" >"$AI_TUI_LOG"
    fi
else
    AI_TUI_STATUS="skipped-script-fail"
    printf 'AI TUI check skipped: script-level upgrade/verify did not pass.\n' >"$AI_TUI_LOG"
fi

# ---- pass/fail classification ----------------------------------------

# PASS requires:
#   - upgrade exited 0
#   - verify exited 0
#   - no .template-conflicts.json entries classified "conflict"
#   - AI TUI check passed OR was legitimately skipped (no hooks /
#     driver missing / script-fail upstream)
#
# AI TUI check statuses that BLOCK PASS:
#   - fail               (real regression caught)
#   - invocation-error   (driver invoked wrong; needs investigation)
#   - pyyaml-missing     (env regression; fix the env)
#   - unknown-rc=N       (driver crashed; investigate)
#
# AI TUI check statuses that DO NOT block PASS:
#   - pass               (clean)
#   - skipped-no-hooks   (fixture has no hooks → nothing to check)
#   - skipped-script-fail (upstream block already counted)
#   - driver-missing     (sibling script absent; phase couldn't run)
#   - not-run            (never set; should not happen)
RESULT="PASS"
REASONS=""
if [ "$UPGRADE_RC" -ne 0 ]; then
    RESULT="FAIL"
    REASONS="${REASONS}upgrade exit=${UPGRADE_RC}; "
fi
if [ "$VERIFY_RC" -ne 0 ]; then
    RESULT="FAIL"
    REASONS="${REASONS}verify exit=${VERIFY_RC}; "
fi
if [ "$CONFLICT_COUNT" -gt 0 ]; then
    RESULT="FAIL"
    REASONS="${REASONS}conflicts=${CONFLICT_COUNT}; "
fi
case "$AI_TUI_STATUS" in
    fail|invocation-error|pyyaml-missing|unknown-rc=*)
        RESULT="FAIL"
        REASONS="${REASONS}ai-tui-check=${AI_TUI_STATUS}; "
        ;;
esac

# ---- emit report -----------------------------------------------------

{
    printf '%s\n' "================================================================"
    printf '%s\n' "dogfood-downstream report"
    printf '%s\n' "================================================================"
    printf 'codename:        %s\n' "$CODENAME"
    printf 'upstream target: %s\n' "$UPSTREAM_REF"
    printf 'fixture path:    %s\n' "$FIXTURE"
    printf 'timestamp:       %s\n' "$TIMESTAMP"
    printf '\n'
    printf '%s\n' "---- TEMPLATE_VERSION (before) ----"
    printf '%s\n' "$TEMPLATE_BEFORE"
    printf '\n'
    printf '%s\n' "---- TEMPLATE_VERSION (after) ----"
    printf '%s\n' "$TEMPLATE_AFTER"
    printf '\n'
    printf 'upgrade exit:    %s\n' "$UPGRADE_RC"
    printf 'verify exit:     %s\n' "$VERIFY_RC"
    printf 'conflicts file:  %s\n' "$CONFLICTS_PRESENT"
    printf 'conflict count:  %s\n' "$CONFLICT_COUNT"
    printf 'ai-tui status:   %s\n' "$AI_TUI_STATUS"
    if [ -n "$CONFLICT_PARSE_NOTE" ]; then
        printf '%s\n' "$CONFLICT_PARSE_NOTE"
    fi
    printf '\n'
    printf '%s\n' "---- git status --porcelain ----"
    if [ -n "$GIT_STATUS" ]; then
        printf '%s\n' "$GIT_STATUS"
    else
        printf '%s\n' "(clean)"
    fi
    printf '\n'
    printf '%s\n' "---- git diff --stat HEAD ----"
    if [ -n "$GIT_DIFFSTAT" ]; then
        printf '%s\n' "$GIT_DIFFSTAT"
    else
        printf '%s\n' "(no diff)"
    fi
    printf '\n'
    if [ "$CONFLICTS_PRESENT" = "yes" ]; then
        printf '%s\n' "---- .template-conflicts.json ----"
        printf '%s\n' "$CONFLICT_BODY"
        printf '\n'
    fi
    printf '%s\n' "---- upgrade.sh stdout/stderr ----"
    cat "$UPGRADE_LOG"
    printf '\n'
    printf '%s\n' "---- upgrade.sh --verify stdout/stderr ----"
    cat "$VERIFY_LOG"
    printf '\n'
    printf '%s\n' "---- ai-tui check stdout/stderr ----"
    if [ -f "$AI_TUI_LOG" ]; then
        cat "$AI_TUI_LOG"
    else
        printf '%s\n' "(no log)"
    fi
    printf '\n'
    printf '%s\n' "================================================================"
    if [ "$RESULT" = "PASS" ]; then
        printf '%s\n' "PASS — upgrade clean, verify clean, no unresolved conflicts"
    else
        printf 'FAIL — %s\n' "${REASONS%; }"
    fi
    printf '%s\n' "================================================================"
} >"$OUT"

# Stdout: just the report path so callers can chain.
printf '%s\n' "$OUT"

if [ "$RESULT" = "PASS" ]; then
    exit 0
else
    exit 1
fi
