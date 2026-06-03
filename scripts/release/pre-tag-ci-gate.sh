#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# scripts/release/pre-tag-ci-gate.sh — assert CI is green on the release
# commit before tagging (issue #285).
#
# Background: v1.1.0 shipped with template-contract-smoke RED because
# core.hooksPath was unset (#282). This script provides an automated CI-
# green assertion step so a failing workflow is caught before the tag is
# cut, not after.
#
# Usage:
#   scripts/release/pre-tag-ci-gate.sh [<commit-sha>]
#
# Arguments:
#   <commit-sha>   Commit to check (default: HEAD).
#
# Required environment:
#   GH_TOKEN (or GITHUB_TOKEN) — a GitHub token with read access to check runs.
#   GITHUB_REPOSITORY           — owner/repo (e.g. occamsshavingkit/sw-dev-team-template).
#                                 Falls back to `gh repo view --json nameWithOwner`.
#
# Exit codes:
#   0  All required workflows are SUCCESS on the candidate commit.
#   1  One or more required workflows are not SUCCESS (or have not run).
#   2  Usage or environment error.
#
# Required workflows (per release-engineer-manual.md pre-tag checklist):
#   template-contract-smoke
#   agent-contract-check
#   agent-model-routing-lint
#   question-lint
#
# Wire-in: called as step 3.5 in the canonical tag sequence
# (docs/agents/manual/release-engineer-manual.md § "rc tag procedure"),
# after the pre-release gate PASS and before cutting the annotated tag.

set -eu

REQUIRED_WORKFLOWS=(
    "template-contract-smoke"
    "agent-contract-check"
    "agent-model-routing-lint"
    "question-lint"
)

# ---------------------------------------------------------------------------
# Argument / environment parsing
# ---------------------------------------------------------------------------
if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    sed -n '3,30p' "$0" | sed 's/^# \{0,1\}//'
    exit 0
fi

commit_sha="${1:-HEAD}"

# Resolve HEAD to a real SHA so the gh API call is unambiguous.
if [ "$commit_sha" = "HEAD" ]; then
    commit_sha="$(git rev-parse HEAD 2>/dev/null)" || {
        echo "pre-tag-ci-gate: cannot resolve HEAD — are you in a git repo?" >&2
        exit 2
    }
fi

# Resolve repo from environment or gh CLI.
repo="${GITHUB_REPOSITORY:-}"
if [ -z "$repo" ]; then
    repo="$(gh repo view --json nameWithOwner --jq '.nameWithOwner' 2>/dev/null)" || {
        echo "pre-tag-ci-gate: GITHUB_REPOSITORY unset and 'gh repo view' failed." >&2
        echo "  Set GITHUB_REPOSITORY=owner/repo or authenticate gh CLI." >&2
        exit 2
    }
fi

echo "pre-tag-ci-gate: checking CI for commit ${commit_sha} on ${repo}"
echo "  Required workflows: ${REQUIRED_WORKFLOWS[*]}"
echo ""

# ---------------------------------------------------------------------------
# Fetch check-run conclusions for the commit.
# gh run list returns workflow runs; we filter by commit SHA.
# ---------------------------------------------------------------------------
run_json="$(gh run list \
    --repo "$repo" \
    --commit "$commit_sha" \
    --json "name,conclusion,status,headSha" \
    --limit 50 \
    2>&1)" || {
    echo "pre-tag-ci-gate: 'gh run list' failed." >&2
    echo "  Output: $run_json" >&2
    echo "  Ensure GH_TOKEN / GITHUB_TOKEN is set and has repo read access." >&2
    exit 2
}

if [ -z "$run_json" ] || [ "$run_json" = "[]" ]; then
    echo "pre-tag-ci-gate: FAIL — no workflow runs found for commit ${commit_sha}." >&2
    echo "  Workflows may not have run yet, or the commit SHA is not pushed." >&2
    echo "  Push the commit and wait for CI to trigger before tagging." >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# For each required workflow, check the conclusion.
# ---------------------------------------------------------------------------
overall_pass=1
fail_reasons=()

for workflow in "${REQUIRED_WORKFLOWS[@]}"; do
    # Extract the conclusion for this workflow name (latest run for this commit).
    conclusion="$(printf '%s' "$run_json" \
        | python3 -c "
import json, sys
runs = json.load(sys.stdin)
name = sys.argv[1]
matches = [r for r in runs if r.get('name','') == name]
if not matches:
    print('NOT_FOUND')
else:
    # Most recent first (gh returns newest first already).
    print(matches[0].get('conclusion') or matches[0].get('status') or 'UNKNOWN')
" "$workflow" 2>/dev/null)" || conclusion="PARSE_ERROR"

    case "$conclusion" in
        success)
            printf '  %-40s  GREEN\n' "$workflow"
            ;;
        NOT_FOUND)
            printf '  %-40s  NOT FOUND (workflow has not run on this commit)\n' "$workflow"
            fail_reasons+=("$workflow: not found — has it been triggered on ${commit_sha}?")
            overall_pass=0
            ;;
        failure|cancelled|timed_out|action_required|startup_failure)
            printf '  %-40s  RED (%s)\n' "$workflow" "$conclusion"
            fail_reasons+=("$workflow: $conclusion")
            overall_pass=0
            ;;
        in_progress|queued|waiting|pending|requested)
            printf '  %-40s  PENDING (%s — not yet complete)\n' "$workflow" "$conclusion"
            fail_reasons+=("$workflow: still $conclusion — wait for completion before tagging")
            overall_pass=0
            ;;
        *)
            printf '  %-40s  UNKNOWN (%s)\n' "$workflow" "$conclusion"
            fail_reasons+=("$workflow: unknown conclusion '$conclusion'")
            overall_pass=0
            ;;
    esac
done

echo ""

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
if [ "$overall_pass" -eq 1 ]; then
    echo "pre-tag-ci-gate: PASS — all required workflows green on ${commit_sha}."
    exit 0
else
    echo "pre-tag-ci-gate: FAIL — one or more required workflows are not SUCCESS." >&2
    for reason in "${fail_reasons[@]}"; do
        echo "  - $reason" >&2
    done
    echo "" >&2
    echo "  Do NOT cut the release tag until all required workflows are SUCCESS." >&2
    echo "  Re-run this script after CI completes: scripts/release/pre-tag-ci-gate.sh ${commit_sha}" >&2
    exit 1
fi
