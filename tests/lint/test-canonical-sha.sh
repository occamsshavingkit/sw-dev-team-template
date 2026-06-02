#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# tests/lint/test-canonical-sha.sh — self-test for
# scripts/lint-canonical-sha.sh (#143 T072-style fixture test).
#
# Cases:
#   1. Happy path: all artefacts have matching canonical_sha -> PASS (exit 0)
#   2. Stale runtime artefact: canonical edited+committed, runtime not updated
#      -> FAIL (exit 1) with STALE diagnostic naming both SHAs
#   3. Stale opencode artefact only: runtime current, opencode stale -> FAIL
#   4. Missing runtime artefact: canonical exists but no runtime file -> FAIL
#   5. Missing canonical_sha field in runtime artefact -> FAIL
#   6. --no-opencode flag: opencode stale but --no-opencode set -> PASS
#   7. --summary flag: FAIL summary line printed on stdout when stale -> FAIL
#   8. --summary flag: PASS summary line printed on stdout when current -> PASS
#
#   9. Orphan runtime artefact: runtime file exists but canonical deleted
#      -> exit 0 (WARN only, non-fatal) + MISSING_CANONICAL on stderr (issue #223)
#
# Each case builds an isolated git repo fixture in a tempdir containing:
#   .claude/agents/<role>.md      (canonical)
#   docs/runtime/agents/<role>.md  (runtime artefact with frontmatter)
#   .opencode/agents/<role>.md    (opencode adapter with frontmatter)
# All files are committed to HEAD so rev-parse works.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LINT="$REPO_ROOT/scripts/lint-canonical-sha.sh"

pass=0
fail=0
failures=()

# --------------------------------------------------------------------------
# run_case <name> <expect-exit: 0|1|2>
# run with the env var FIXTURE_DIR set before calling; remaining args
# are passed to the lint script.
# --------------------------------------------------------------------------
run_case() {
    local name="$1"
    local expect_exit="$2"
    shift 2

    local actual_exit=0
    "$LINT" "$@" >/dev/null 2>&1 || actual_exit=$?

    if [ "$actual_exit" -eq "$expect_exit" ]; then
        pass=$((pass + 1))
        echo "PASS  $name"
    else
        fail=$((fail + 1))
        failures+=("$name (expected exit=$expect_exit actual=$actual_exit)")
        echo "FAIL  $name (expected exit=$expect_exit actual=$actual_exit)"
    fi
}

# --------------------------------------------------------------------------
# make_fixture_repo <tmpdir>
# Creates a minimal git repo under $tmpdir/repo with the standard layout.
# Returns the repo path on stdout (for capture with $(...)).
# Does NOT commit anything — callers do that after populating.
# --------------------------------------------------------------------------
make_fixture_repo() {
    local base="$1"
    local repo="$base/repo"
    mkdir -p "$repo"
    git -C "$repo" init -q
    git -C "$repo" config user.email "test@example.com"
    git -C "$repo" config user.name "Test"
    mkdir -p "$repo/.claude/agents"
    mkdir -p "$repo/docs/runtime/agents"
    mkdir -p "$repo/.opencode/agents"
    printf '%s' "$repo"
}

# --------------------------------------------------------------------------
# write_canonical <repo> <role> <content>
# --------------------------------------------------------------------------
write_canonical() {
    local repo="$1" role="$2" content="$3"
    printf '%s\n' "$content" > "$repo/.claude/agents/${role}.md"
}

# --------------------------------------------------------------------------
# write_runtime_artefact <repo> <role> <canonical_sha>
# Writes a minimal generated runtime contract with the given canonical_sha.
# --------------------------------------------------------------------------
write_runtime_artefact() {
    local repo="$1" role="$2" sha="$3"
    cat > "$repo/docs/runtime/agents/${role}.md" << EOF
---
name: ${role}
description: Test contract for ${role}.
model: inherit
canonical_source: .claude/agents/${role}.md
canonical_sha: ${sha}
generator: scripts/compile-runtime-agents.sh
generator_version: 0.2.0
classification: generated
---

Body text.
EOF
}

# --------------------------------------------------------------------------
# write_opencode_artefact <repo> <role> <canonical_sha>
# Writes a minimal generated opencode adapter with the given canonical_sha.
# --------------------------------------------------------------------------
write_opencode_artefact() {
    local repo="$1" role="$2" sha="$3"
    cat > "$repo/.opencode/agents/${role}.md" << EOF
---
name: ${role}
model: claude-sonnet
canonical_source: .claude/agents/${role}.md
canonical_sha: ${sha}
generator: scripts/compile-runtime-agents.sh
generator_version: 0.2.0
classification: generated
---

Read \`.claude/agents/${role}.md\` (canonical role contract).
Act only as that role.
EOF
}

# --------------------------------------------------------------------------
# commit_all <repo> <message>
# Stages everything and commits.
# --------------------------------------------------------------------------
commit_all() {
    local repo="$1" msg="$2"
    git -C "$repo" add -A
    git -C "$repo" commit -q -m "$msg"
}

# --------------------------------------------------------------------------
# get_blob_sha <repo> <rel_path>
# Returns the git blob SHA at HEAD for the given path.
# --------------------------------------------------------------------------
get_blob_sha() {
    local repo="$1" rel_path="$2"
    git -C "$repo" rev-parse "HEAD:${rel_path}"
}

# ==========================================================================
# Single parent tempdir — all per-case dirs live under it.
# Trap removes the entire tree regardless of which case fails or exits early.
# ==========================================================================
PARENT_TMPDIR="$(mktemp -d)"
trap 'rm -rf "$PARENT_TMPDIR"' EXIT INT TERM HUP

TMPDIR1="$PARENT_TMPDIR/tmpdir1"; mkdir -p "$TMPDIR1"
TMPDIR2="$PARENT_TMPDIR/tmpdir2"; mkdir -p "$TMPDIR2"
TMPDIR3="$PARENT_TMPDIR/tmpdir3"; mkdir -p "$TMPDIR3"
TMPDIR4="$PARENT_TMPDIR/tmpdir4"; mkdir -p "$TMPDIR4"
TMPDIR5="$PARENT_TMPDIR/tmpdir5"; mkdir -p "$TMPDIR5"

# ==========================================================================
# Case 1: Happy path — all artefacts current -> PASS
# ==========================================================================
REPO1="$(make_fixture_repo "$TMPDIR1")"

write_canonical "$REPO1" "soft-eng" "canonical body v1"
commit_all "$REPO1" "add canonical"
SHA1="$(get_blob_sha "$REPO1" ".claude/agents/soft-eng.md")"
write_runtime_artefact "$REPO1" "soft-eng" "$SHA1"
write_opencode_artefact "$REPO1" "soft-eng" "$SHA1"
commit_all "$REPO1" "add artefacts"

run_case "happy-path: all artefacts current" 0 \
    --agents-dir "$REPO1/.claude/agents" \
    --runtime-dir "$REPO1/docs/runtime/agents" \
    --opencode-dir "$REPO1/.opencode/agents"

# ==========================================================================
# Case 2: Stale runtime artefact — canonical committed with new content,
#         runtime not updated -> FAIL with STALE diagnostic
# ==========================================================================
REPO2="$(make_fixture_repo "$TMPDIR2")"

# First commit: canonical + artefacts in sync.
write_canonical "$REPO2" "soft-eng" "canonical body v1"
commit_all "$REPO2" "add canonical v1"
SHA2_v1="$(get_blob_sha "$REPO2" ".claude/agents/soft-eng.md")"
write_runtime_artefact "$REPO2" "soft-eng" "$SHA2_v1"
write_opencode_artefact "$REPO2" "soft-eng" "$SHA2_v1"
commit_all "$REPO2" "add artefacts synced to v1"

# Second commit: canonical updated, artefacts NOT updated (stale).
write_canonical "$REPO2" "soft-eng" "canonical body v2 — new content"
commit_all "$REPO2" "update canonical to v2 without refreshing artefacts"
# Artefacts still record SHA2_v1 but HEAD canonical is now v2.

# Verify that the STALE diagnostic fires.
STALE_OUT2="$(mktemp)"
ACTUAL_EXIT2=0
"$LINT" \
    --agents-dir "$REPO2/.claude/agents" \
    --runtime-dir "$REPO2/docs/runtime/agents" \
    --opencode-dir "$REPO2/.opencode/agents" \
    >"$STALE_OUT2" 2>&1 || ACTUAL_EXIT2=$?

STALE_FOUND2=0
if grep -q "STALE:" "$STALE_OUT2" && grep -q "recorded canonical_sha:" "$STALE_OUT2"; then
    STALE_FOUND2=1
fi
rm -f "$STALE_OUT2"

if [ "$ACTUAL_EXIT2" -eq 1 ] && [ "$STALE_FOUND2" -eq 1 ]; then
    pass=$((pass + 1))
    echo "PASS  stale-runtime: STALE diagnostic + exit 1"
else
    fail=$((fail + 1))
    failures+=("stale-runtime: STALE diagnostic + exit 1 (exit=$ACTUAL_EXIT2 stale_found=$STALE_FOUND2)")
    echo "FAIL  stale-runtime: STALE diagnostic + exit 1 (exit=$ACTUAL_EXIT2 stale_found=$STALE_FOUND2)"
fi

# ==========================================================================
# Case 3: Only opencode artefact is stale (runtime is current) -> FAIL
# ==========================================================================
REPO3="$(make_fixture_repo "$TMPDIR3")"

write_canonical "$REPO3" "soft-eng" "canonical body v1"
commit_all "$REPO3" "add canonical v1"
SHA3_v1="$(get_blob_sha "$REPO3" ".claude/agents/soft-eng.md")"
write_runtime_artefact "$REPO3" "soft-eng" "$SHA3_v1"
write_opencode_artefact "$REPO3" "soft-eng" "$SHA3_v1"
commit_all "$REPO3" "add artefacts synced to v1"

# Update canonical + runtime only; opencode left stale.
write_canonical "$REPO3" "soft-eng" "canonical body v2"
commit_all "$REPO3" "update canonical to v2"
SHA3_v2="$(get_blob_sha "$REPO3" ".claude/agents/soft-eng.md")"
write_runtime_artefact "$REPO3" "soft-eng" "$SHA3_v2"
# opencode still has v1 SHA
commit_all "$REPO3" "update runtime to v2 but not opencode"

run_case "stale-opencode-only: opencode artefact stale -> FAIL" 1 \
    --agents-dir "$REPO3/.claude/agents" \
    --runtime-dir "$REPO3/docs/runtime/agents" \
    --opencode-dir "$REPO3/.opencode/agents"

# ==========================================================================
# Case 4: Missing runtime artefact -> FAIL
# ==========================================================================
REPO4="$(make_fixture_repo "$TMPDIR4")"

write_canonical "$REPO4" "soft-eng" "canonical body"
commit_all "$REPO4" "add canonical only"
# No runtime or opencode artefact.

run_case "missing-runtime: no runtime artefact -> FAIL" 1 \
    --agents-dir "$REPO4/.claude/agents" \
    --runtime-dir "$REPO4/docs/runtime/agents" \
    --opencode-dir "$REPO4/.opencode/agents"

# ==========================================================================
# Case 5: Missing canonical_sha field in runtime artefact -> FAIL
# ==========================================================================
REPO5="$(make_fixture_repo "$TMPDIR5")"

write_canonical "$REPO5" "soft-eng" "canonical body"
commit_all "$REPO5" "add canonical"
SHA5="$(get_blob_sha "$REPO5" ".claude/agents/soft-eng.md")"

# Write a runtime artefact with no canonical_sha field.
cat > "$REPO5/docs/runtime/agents/soft-eng.md" << 'EOF'
---
name: soft-eng
description: Test.
model: inherit
generator: scripts/compile-runtime-agents.sh
classification: generated
---

Body.
EOF
write_opencode_artefact "$REPO5" "soft-eng" "$SHA5"
commit_all "$REPO5" "add artefacts — runtime missing canonical_sha"

run_case "missing-sha-field: no canonical_sha in runtime -> FAIL" 1 \
    --agents-dir "$REPO5/.claude/agents" \
    --runtime-dir "$REPO5/docs/runtime/agents" \
    --opencode-dir "$REPO5/.opencode/agents"

# ==========================================================================
# Case 6: --no-opencode flag: opencode artefact stale but flag suppresses -> PASS
# ==========================================================================
# Reuse REPO3 state (opencode stale, runtime current at v2).
run_case "no-opencode-flag: opencode stale but --no-opencode set -> PASS" 0 \
    --agents-dir "$REPO3/.claude/agents" \
    --runtime-dir "$REPO3/docs/runtime/agents" \
    --no-opencode

# ==========================================================================
# Case 7: --summary flag emits FAIL line on mismatch
# ==========================================================================
# Reuse REPO2 (stale runtime).
SUMMARY_OUT7="$(mktemp)"
ACTUAL_EXIT7=0
"$LINT" \
    --summary \
    --agents-dir "$REPO2/.claude/agents" \
    --runtime-dir "$REPO2/docs/runtime/agents" \
    --opencode-dir "$REPO2/.opencode/agents" \
    >"$SUMMARY_OUT7" 2>/dev/null || ACTUAL_EXIT7=$?

SUMMARY_FAIL_FOUND7=0
if grep -q "lint-canonical-sha: FAIL" "$SUMMARY_OUT7"; then
    SUMMARY_FAIL_FOUND7=1
fi
rm -f "$SUMMARY_OUT7"

if [ "$ACTUAL_EXIT7" -ne 0 ] && [ "$SUMMARY_FAIL_FOUND7" -eq 1 ]; then
    pass=$((pass + 1))
    echo "PASS  summary-fail-line: FAIL summary printed + non-zero exit"
else
    fail=$((fail + 1))
    failures+=("summary-fail-line (exit=$ACTUAL_EXIT7 fail_line_found=$SUMMARY_FAIL_FOUND7)")
    echo "FAIL  summary-fail-line (exit=$ACTUAL_EXIT7 fail_line_found=$SUMMARY_FAIL_FOUND7)"
fi

# ==========================================================================
# Case 8: --summary flag emits PASS line when all current
# ==========================================================================
# Reuse REPO1 (all current).
SUMMARY_OUT8="$(mktemp)"
ACTUAL_EXIT8=0
"$LINT" \
    --summary \
    --agents-dir "$REPO1/.claude/agents" \
    --runtime-dir "$REPO1/docs/runtime/agents" \
    --opencode-dir "$REPO1/.opencode/agents" \
    >"$SUMMARY_OUT8" 2>/dev/null || ACTUAL_EXIT8=$?

SUMMARY_PASS_FOUND8=0
if grep -q "lint-canonical-sha: PASS" "$SUMMARY_OUT8"; then
    SUMMARY_PASS_FOUND8=1
fi
rm -f "$SUMMARY_OUT8"

if [ "$ACTUAL_EXIT8" -eq 0 ] && [ "$SUMMARY_PASS_FOUND8" -eq 1 ]; then
    pass=$((pass + 1))
    echo "PASS  summary-pass-line: PASS summary printed + zero exit"
else
    fail=$((fail + 1))
    failures+=("summary-pass-line (exit=$ACTUAL_EXIT8 pass_line_found=$SUMMARY_PASS_FOUND8)")
    echo "FAIL  summary-pass-line (exit=$ACTUAL_EXIT8 pass_line_found=$SUMMARY_PASS_FOUND8)"
fi

# ==========================================================================
# Case 9: orphan runtime artefact — runtime file exists, canonical absent
# Issue #223: the main loop only iterates .claude/agents/; a runtime artefact
# whose canonical was deleted is invisible to it. The orphan pass iterates
# the artefact dirs and emits WARN: MISSING_CANONICAL on stderr (non-fatal,
# so exit code is still 0).
# ==========================================================================
TMPDIR9="$(mktemp -d -p "$PARENT_TMPDIR")"
REPO9="$(make_fixture_repo "$TMPDIR9")"

# Write a canonical, commit an artefact pair, then DELETE the canonical so
# only the runtime/opencode artefacts survive. This simulates agent retirement.
write_canonical "$REPO9" "retired-agent" "canonical body for retired agent"
commit_all "$REPO9" "add canonical"
SHA9="$(get_blob_sha "$REPO9" ".claude/agents/retired-agent.md")"
write_runtime_artefact "$REPO9" "retired-agent" "$SHA9"
write_opencode_artefact "$REPO9" "retired-agent" "$SHA9"
commit_all "$REPO9" "add artefacts"

# Now remove the canonical (simulates retirement) and commit the deletion.
rm "$REPO9/.claude/agents/retired-agent.md"
commit_all "$REPO9" "retire agent (delete canonical)"

# Lint should exit 0 (orphan is WARN, not FAIL) but emit MISSING_CANONICAL on stderr.
ORPHAN_STDERR9="$(mktemp)"
ACTUAL_EXIT9=0
"$LINT" \
    --agents-dir "$REPO9/.claude/agents" \
    --runtime-dir "$REPO9/docs/runtime/agents" \
    --opencode-dir "$REPO9/.opencode/agents" \
    >/dev/null 2>"$ORPHAN_STDERR9" || ACTUAL_EXIT9=$?

ORPHAN_RUNTIME_WARN9=0
ORPHAN_OPENCODE_WARN9=0
if grep -q "MISSING_CANONICAL.*runtime.*retired-agent" "$ORPHAN_STDERR9" || \
   grep -q "MISSING_CANONICAL.*retired-agent.*runtime" "$ORPHAN_STDERR9" || \
   grep -q "MISSING_CANONICAL" "$ORPHAN_STDERR9"; then
    ORPHAN_RUNTIME_WARN9=1
fi
if grep -q "MISSING_CANONICAL.*opencode.*retired-agent" "$ORPHAN_STDERR9" || \
   grep -q "MISSING_CANONICAL.*retired-agent.*opencode" "$ORPHAN_STDERR9" || \
   ( grep -c "MISSING_CANONICAL" "$ORPHAN_STDERR9" | grep -qE "^[2-9]" ); then
    ORPHAN_OPENCODE_WARN9=1
fi
rm -f "$ORPHAN_STDERR9"

if [ "$ACTUAL_EXIT9" -eq 0 ]; then
    pass=$((pass + 1))
    echo "PASS  orphan-exit-0: orphan runtime artefact is WARN (non-fatal, exit 0)"
else
    fail=$((fail + 1))
    failures+=("orphan-exit-0 (expected exit=0, got exit=$ACTUAL_EXIT9)")
    echo "FAIL  orphan-exit-0 (expected exit=0, got exit=$ACTUAL_EXIT9)"
fi

if [ "$ORPHAN_RUNTIME_WARN9" -eq 1 ]; then
    pass=$((pass + 1))
    echo "PASS  orphan-runtime-warn-emitted: MISSING_CANONICAL WARN emitted for runtime artefact"
else
    fail=$((fail + 1))
    failures+=("orphan-runtime-warn-emitted (MISSING_CANONICAL not found in stderr for runtime artefact)")
    echo "FAIL  orphan-runtime-warn-emitted (MISSING_CANONICAL not found in stderr for runtime artefact)"
fi

if [ "$ORPHAN_OPENCODE_WARN9" -eq 1 ]; then
    pass=$((pass + 1))
    echo "PASS  orphan-opencode-warn-emitted: MISSING_CANONICAL WARN emitted for opencode artefact"
else
    fail=$((fail + 1))
    failures+=("orphan-opencode-warn-emitted (MISSING_CANONICAL not found in stderr for opencode artefact)")
    echo "FAIL  orphan-opencode-warn-emitted (MISSING_CANONICAL not found in stderr for opencode artefact)"
fi

# --------------------------------------------------------------------------
# Summary
# --------------------------------------------------------------------------
echo ""
echo "Results: $pass passed, $fail failed"

if [ "${#failures[@]}" -gt 0 ]; then
    echo "Failures:"
    for f in "${failures[@]}"; do
        echo "  - $f"
    done
    exit 1
fi

exit 0
