#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# tests/hooks/test-canonical-sha-guard.sh — regression test for the
# canonical_sha staleness guard in .git-hooks/pre-commit (issue #250).
#
# Cases:
#   A. Mirror with correct canonical_sha (matches index) → guard passes.
#   B. Mirror with stale canonical_sha (differs from index) → guard blocks.
#   C. SKIP_CANONICAL_SHA_CHECK=1 → guard skipped even with stale SHA.
#   D. compile-runtime-agents.sh uses git ls-files --stage (index), not HEAD.
#
# All cases run in a throwaway git repo to avoid touching the live checkout.

set -u

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
hook="$repo_root/.git-hooks/pre-commit"
compile="$repo_root/scripts/compile-runtime-agents.sh"

pass=0
fail=0

check() {
    local label="$1"; shift
    if "$@" >/dev/null 2>&1; then
        echo "  PASS: $label"
        pass=$((pass + 1))
    else
        echo "  FAIL: $label" >&2
        fail=$((fail + 1))
    fi
}

tmp="$(mktemp -d -t canonical-sha-guard-XXXXXX)"
trap 'rm -rf "$tmp"' EXIT

# ---------------------------------------------------------------------------
# Build a minimal throwaway git repo for hook testing.
# ---------------------------------------------------------------------------
git -C "$tmp" init -q
git -C "$tmp" config user.email "test@test.invalid"
git -C "$tmp" config user.name "test"

mkdir -p "$tmp/.claude/agents" "$tmp/docs/runtime/agents"

# Write a minimal canonical agent.
cat > "$tmp/.claude/agents/synthetic-role.md" << 'EOF'
---
name: synthetic-role
description: Synthetic role for canonical_sha guard test.
---

## Job

Synthetic role.

## Escalation

Route to tech-lead.

## Hard rules

1. Do not contact the customer.

## Output format

Return diffs.
EOF

git -C "$tmp" add .claude/agents/synthetic-role.md
git -C "$tmp" -c commit.gpgsign=false commit -q -m "add canonical"

# Get the committed blob SHA — this is the "correct" SHA.
correct_sha="$(git -C "$tmp" rev-parse HEAD:.claude/agents/synthetic-role.md)"

# ---------------------------------------------------------------------------
# Helper: build a mirror file claiming a specific SHA.
# ---------------------------------------------------------------------------
make_mirror() {
    local sha="$1"
    cat > "$tmp/docs/runtime/agents/synthetic-role.md" << EOF
---
canonical_sha: ${sha}
generator: compile-runtime-agents.sh
---

## synthetic-role

Synthetic runtime contract.
EOF
}

# ---------------------------------------------------------------------------
# Case A: correct SHA — guard must pass (exit 0).
# ---------------------------------------------------------------------------
echo "-- Case A: correct canonical_sha → guard passes --"

make_mirror "$correct_sha"
git -C "$tmp" add docs/runtime/agents/synthetic-role.md

# Run only the canonical_sha guard section of the hook by setting the
# SKIP_HOOK_NEGATIVE_CORPUS=1 bypass (skips the corpus driver, leaves the
# SHA guard active).
SKIP_HOOK_NEGATIVE_CORPUS=1 SKIP_CANONICAL_SHA_CHECK=0 \
    GIT_DIR="$tmp/.git" GIT_WORK_TREE="$tmp" \
    bash "$hook" >/dev/null 2>&1
hook_rc=$?

check "A: correct SHA → hook exits 0" bash -c "[ '$hook_rc' -eq 0 ]"

git -C "$tmp" -c commit.gpgsign=false commit -q -m "add correct mirror" >/dev/null 2>&1

# ---------------------------------------------------------------------------
# Case B: stale SHA — guard must block (exit 1) and name the mirror file.
# ---------------------------------------------------------------------------
echo ""
echo "-- Case B: stale canonical_sha → guard blocks --"

stale_sha="0000000000000000000000000000000000000001"
make_mirror "$stale_sha"
git -C "$tmp" add docs/runtime/agents/synthetic-role.md

stale_out=$(SKIP_HOOK_NEGATIVE_CORPUS=1 SKIP_CANONICAL_SHA_CHECK=0 \
    GIT_DIR="$tmp/.git" GIT_WORK_TREE="$tmp" \
    bash "$hook" 2>&1) || stale_rc=$?
stale_rc=${stale_rc:-0}

check "B: stale SHA → hook exits non-zero" bash -c "[ '$stale_rc' -ne 0 ]"
check "B: stale SHA → message names the mirror file" \
    bash -c "printf '%s' '$stale_out' | grep -q 'synthetic-role.md'"
check "B: stale SHA → message shows claimed SHA" \
    bash -c "printf '%s' '$stale_out' | grep -q '$stale_sha'"
check "B: stale SHA → message includes fix instruction" \
    bash -c "printf '%s' '$stale_out' | grep -q 'compile-runtime-agents.sh'"

# Reset staged state.
git -C "$tmp" restore --staged docs/runtime/agents/synthetic-role.md >/dev/null 2>&1 || true

# ---------------------------------------------------------------------------
# Case C: SKIP_CANONICAL_SHA_CHECK=1 → guard skipped despite stale SHA.
# ---------------------------------------------------------------------------
echo ""
echo "-- Case C: SKIP_CANONICAL_SHA_CHECK=1 → guard bypassed --"

make_mirror "$stale_sha"
git -C "$tmp" add docs/runtime/agents/synthetic-role.md

SKIP_HOOK_NEGATIVE_CORPUS=1 SKIP_CANONICAL_SHA_CHECK=1 \
    GIT_DIR="$tmp/.git" GIT_WORK_TREE="$tmp" \
    bash "$hook" >/dev/null 2>&1
skip_rc=$?

check "C: SKIP_CANONICAL_SHA_CHECK=1 → hook exits 0 (bypass active)" \
    bash -c "[ '$skip_rc' -eq 0 ]"

git -C "$tmp" restore --staged docs/runtime/agents/synthetic-role.md >/dev/null 2>&1 || true

# ---------------------------------------------------------------------------
# Case D: compile-runtime-agents.sh uses git ls-files --stage (index SHA).
# Verify the fix is present in the source.
# ---------------------------------------------------------------------------
echo ""
echo "-- Case D: compile-runtime-agents.sh uses index SHA (not HEAD) --"

check "D: compile script uses git ls-files --stage for canonical_sha" \
    grep -q "ls-files --stage" "$compile"
check "D: compile script comment references issue #250" \
    grep -q "250" "$compile"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "PASS: $pass"
echo "FAIL: $fail"
[ "$fail" -eq 0 ]
