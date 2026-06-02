#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# tests/upgrade/test-rc9-pass2-backfill.sh — regression coverage for the
# v1.0.0-rc9 migration: section backfill of hard_rules / output_format in
# customised canonical agent files. Issue: upstream #271.
#
# Cases:
#   1. Fixture: agent missing both hard_rules and output_format.
#      Expected: both sections inserted in canonical order (Hard rules before
#      Output format). Order assertion per issue #267 fix in rc9 migration.
#   2. Fixture: agent already has both sections (idempotent no-op).
#      Expected: file content unchanged on first run AND on re-run.
#
# The rc9 migration operates on every .claude/agents/*.md EXCEPT sme-*.md and
# sme-template.md (it does NOT gate on .template-customizations unlike rc14).
# When WORKDIR_OLD is available and the project file byte-matches the baseline,
# the migration skips it (clean canonical fast-path); when not, it falls through
# to the slug check. We omit WORKDIR_OLD here to exercise the slug-check path.
#
# Each post-migration agent file is validated with lint-agent-contracts.sh
# --canonical-only to confirm it satisfies the rc9 contract schema.

set -u

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
migration="$repo_root/migrations/v1.0.0-rc9.sh"
lint_script="$repo_root/scripts/lint-agent-contracts.sh"

tmp="$(mktemp -d -t rc9-pass2-XXXXXX)"
keep=0
[[ "${1:-}" == "--keep" ]] && keep=1
trap 'if [[ $keep -eq 0 ]]; then rm -rf "$tmp"; else echo "(kept $tmp for inspection)" >&2; fi' EXIT

fail=0
pass=0

check() {
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "  PASS: $label"
    pass=$(( pass + 1 ))
  else
    echo "  FAIL: $label" >&2
    fail=$(( fail + 1 ))
  fi
}

# ---------------------------------------------------------------------------
# Shared helpers
# ---------------------------------------------------------------------------

# Write a minimal valid agent file with frontmatter + role_overview + escalation.
# Optionally include hard_rules and/or output_format.
# Usage: make_agent <path> [--with-hard-rules] [--with-output-format]
make_agent() {
  local path="$1"; shift
  local with_hard_rules=0
  local with_output_format=0
  for arg in "$@"; do
    case "$arg" in
      --with-hard-rules)    with_hard_rules=1 ;;
      --with-output-format) with_output_format=1 ;;
    esac
  done

  local base
  base="$(basename "$path" .md)"

  cat > "$path" <<EOF
---
name: ${base}
description: A synthetic test agent for rc9 migration coverage. This is a placeholder role.
---

## Job

This is the role overview body for ${base}. It provides a high-level
description of the responsibilities assigned to this agent role in the
software development team.

## Escalation format

Route all unresolved questions to tech-lead. Do not contact the customer
directly. Escalation path: agent → tech-lead → customer (if required).
Tech-lead is the sole customer-facing interface.
EOF

  if [ "$with_hard_rules" -eq 1 ]; then
    cat >> "$path" <<EOF

## Hard rules

1. Do not contact the customer directly; all customer communication flows through tech-lead.
2. Do not commit production code without code-reviewer approval.
EOF
  fi

  if [ "$with_output_format" -eq 1 ]; then
    cat >> "$path" <<EOF

## Output format

Return diffs with short rationale. No essays. Include file paths when
referencing code. Skip introductory filler; lead with the conclusion.
EOF
  fi
}

# Build a minimal upstream clone directory with a canonical agent file
# that has both hard_rules and output_format (for upstream-extract path).
make_upstream() {
  local dir="$1"
  local base="$2"
  mkdir -p "$dir/.claude/agents"
  cat > "$dir/.claude/agents/$base" <<EOF
---
name: $(basename "$base" .md)
description: Upstream canonical agent for rc9 migration coverage. This is the shipped version.
---

## Job

Upstream role overview for $(basename "$base" .md). Reference version shipped with rc9.

## Escalation format

Route all unresolved questions to tech-lead. Do not contact the customer
directly. Escalation path: agent → tech-lead → customer (if required).

## Hard rules

1. Do not contact the customer directly; all customer communication flows through tech-lead.
2. Do not commit production code without code-reviewer approval.
3. Do not silently expand scope; surface discovered issues to tech-lead.

## Output format

Return diffs with short rationale. No essays. Include absolute file paths
when referencing code. Lead with the conclusion; skip introductory filler.
EOF
}

# Build a minimal project fixture containing one agent file.
# The rc9 migration does NOT gate on .template-customizations; it walks
# .claude/agents/*.md directly (excluding sme-*.md and sme-template.md).
make_project() {
  local dir="$1"
  local agent_base="$2"; shift 2
  mkdir -p "$dir/.claude/agents" "$dir/docs"
  make_agent "$dir/.claude/agents/$agent_base" "$@"
}

# Run the rc9 migration and capture output. Returns the exit code.
run_migration() {
  local proj="$1"
  local upstream="$2"   # path to upstream clone, or "" to omit WORKDIR_NEW
  local log="$3"
  local rc=0
  (
    export PROJECT_ROOT="$proj"
    export WORKDIR_NEW="${upstream}"
    # Omit WORKDIR_OLD so the clean-canonical fast-path (cmp -s check) is
    # bypassed and every file falls through to the slug check. This matches
    # the real-world scenario where baseline is unavailable.
    unset WORKDIR_OLD
    sh "$migration"
  ) > "$log" 2>&1 || rc=$?
  echo "$rc"
}

# Validate a single agent file against the agent-contract schema.
lint_one_agent() {
  local agent_file="$1"
  local lint_tmp
  lint_tmp="$(mktemp -d)"
  mkdir -p "$lint_tmp/.claude/agents" "$lint_tmp/schemas" "$lint_tmp/scripts"
  cp "$agent_file" "$lint_tmp/.claude/agents/"
  cp "$repo_root/schemas/agent-contract.schema.json" "$lint_tmp/schemas/"
  ln -sf "$repo_root/scripts/lint-agent-contracts.sh" \
         "$lint_tmp/scripts/lint-agent-contracts.sh"
  local rc=0
  ( cd "$lint_tmp" && bash "$lint_tmp/scripts/lint-agent-contracts.sh" --canonical-only ) \
    >/dev/null 2>&1 || rc=$?
  rm -rf "$lint_tmp"
  return "$rc"
}

# ---------------------------------------------------------------------------
# Case 1 (case-3 equivalent from rc14 test): agent missing BOTH hard_rules
# and output_format. Both must be inserted in canonical order: Hard rules
# before Output format. Issue #267.
# ---------------------------------------------------------------------------
echo "-- Case 1: agent missing both hard_rules and output_format --"

proj1="$tmp/proj1"
upstream1="$tmp/upstream1"
make_project "$proj1" "synthetic-agent.md"
make_upstream "$upstream1" "synthetic-agent.md"

log1="$tmp/case1.log"
rc1=$(run_migration "$proj1" "$upstream1" "$log1")

check "case1: migration exits 0" bash -c "[ '$rc1' = '0' ]"
check "case1: hard_rules section inserted" \
  grep -q "^## Hard rules" "$proj1/.claude/agents/synthetic-agent.md"
check "case1: output_format section inserted" \
  grep -q "^## Output format" "$proj1/.claude/agents/synthetic-agent.md"
check "case1: exactly one hard_rules section" \
  bash -c "[ \"\$(grep -c '^## Hard rules' '$proj1/.claude/agents/synthetic-agent.md')\" = '1' ]"
check "case1: exactly one output_format section" \
  bash -c "[ \"\$(grep -c '^## Output format' '$proj1/.claude/agents/synthetic-agent.md')\" = '1' ]"
check "case1: canonical order — Hard rules before Output format (issue #267)" \
  bash -c "[ \"\$(awk '/^## Hard rules/{print NR; exit}' '$proj1/.claude/agents/synthetic-agent.md')\" -lt \"\$(awk '/^## Output format/{print NR; exit}' '$proj1/.claude/agents/synthetic-agent.md')\" ]"
check "case1: audit rows written to docs/DECISIONS.md" \
  grep -q "M9 rc9 migration" "$proj1/docs/DECISIONS.md"
check "case1: Hard rules audit row present" \
  grep -q "Hard rules" "$proj1/docs/DECISIONS.md"
check "case1: Output format audit row present" \
  grep -q "Output format" "$proj1/docs/DECISIONS.md"
check "case1: lint passes" lint_one_agent "$proj1/.claude/agents/synthetic-agent.md"

# ---------------------------------------------------------------------------
# Case 2: agent already has both sections — idempotent no-op.
# File content must be unchanged on first run AND on re-run.
# ---------------------------------------------------------------------------
echo ""
echo "-- Case 2: agent already has both sections (idempotent no-op) --"

proj2="$tmp/proj2"
upstream2="$tmp/upstream2"
make_project "$proj2" "synthetic-agent.md" --with-hard-rules --with-output-format
make_upstream "$upstream2" "synthetic-agent.md"

before2="$(cat "$proj2/.claude/agents/synthetic-agent.md")"

log2="$tmp/case2.log"
rc2=$(run_migration "$proj2" "$upstream2" "$log2")
after2="$(cat "$proj2/.claude/agents/synthetic-agent.md")"

check "case2: migration exits 0" bash -c "[ '$rc2' = '0' ]"
check "case2: file content unchanged (idempotent first run)" \
  bash -c "[ '$before2' = '$after2' ]"
check "case2: exactly one hard_rules section (no duplication)" \
  bash -c "[ \"\$(grep -c '^## Hard rules' '$proj2/.claude/agents/synthetic-agent.md')\" = '1' ]"
check "case2: exactly one output_format section (no duplication)" \
  bash -c "[ \"\$(grep -c '^## Output format' '$proj2/.claude/agents/synthetic-agent.md')\" = '1' ]"
check "case2: lint passes" lint_one_agent "$proj2/.claude/agents/synthetic-agent.md"

# Idempotency: re-run the migration on the same project.
log2b="$tmp/case2b.log"
rc2b=$(run_migration "$proj2" "$upstream2" "$log2b")
after2b="$(cat "$proj2/.claude/agents/synthetic-agent.md")"

check "case2: idempotent re-run exits 0" bash -c "[ '$rc2b' = '0' ]"
check "case2: file content unchanged after re-run" \
  bash -c "[ '$after2' = '$after2b' ]"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "PASS: $pass"
echo "FAIL: $fail"
if [[ $fail -gt 0 ]]; then
  exit 1
fi
exit 0
