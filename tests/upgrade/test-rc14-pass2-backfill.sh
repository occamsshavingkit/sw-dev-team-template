#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# tests/upgrade/test-rc14-pass2-backfill.sh — coverage for the rc14 migration
# Pass 2: schema backfill of hard_rules / output_format in preserved canonical
# agent files. Issue: upstream #261.
#
# Cases:
#   1. Fixture: preserved agent missing hard_rules only.
#      Expected: hard_rules inserted; output_format untouched; lint clean.
#   2. Fixture: preserved agent missing output_format only.
#      Expected: output_format inserted; hard_rules untouched; lint clean.
#   3. Fixture: preserved agent missing both hard_rules and output_format.
#      Expected: both sections inserted in canonical order (Hard rules before
#      Output format); lint clean. Order assertion added per issue #267.
#   4. Fixture: preserved agent already has both sections (idempotent no-op).
#      Expected: file unchanged; lint clean; no duplicate sections.
#   5. Fixture: WORKDIR_NEW is absent (no upstream clone); placeholder fallback.
#      Expected: placeholder sections inserted; lint clean.
#
# Each post-migration agent file is validated with lint-agent-contracts.sh
# --canonical-only to confirm it satisfies the rc14 contract schema.
#
# The test invokes migrations/v1.0.0-rc14.sh directly (as upgrade.sh would)
# with the required env vars.

set -u

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
migration="$repo_root/migrations/v1.0.0-rc14.sh"
lint_script="$repo_root/scripts/lint-agent-contracts.sh"

tmp="$(mktemp -d -t rc14-pass2-XXXXXX)"
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

run_capture() {
  local log="$1"; shift
  local rc=0
  "$@" > "$log" 2>&1 || rc=$?
  echo "$rc"
}

# ---------------------------------------------------------------------------
# Shared helpers
# ---------------------------------------------------------------------------

# Write a minimal valid agent file with frontmatter + role_overview +
# escalation. Optionally include hard_rules and/or output_format.
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

  local basename
  basename="$(basename "$path" .md)"

  cat > "$path" <<EOF
---
name: ${basename}
description: A synthetic test agent for rc14 migration pass 2 coverage. This is a placeholder role.
---

## Job

This is the role overview body for ${basename}. It provides a high-level
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
description: Upstream canonical agent for rc14 migration pass 2 coverage. This is the shipped version.
---

## Job

Upstream role overview body for $(basename "$base" .md). This is the reference
version shipped with the rc14 template release.

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

# Build a minimal project fixture with a .template-customizations file
# listing one agent path, plus the agent file itself.
# Usage: make_project <dir> <agent_basename> [make_agent args...]
make_project() {
  local dir="$1"
  local agent_base="$2"; shift 2
  mkdir -p "$dir/.claude/agents" "$dir/docs"
  make_agent "$dir/.claude/agents/$agent_base" "$@"
  printf '.claude/agents/%s\n' "$agent_base" > "$dir/.template-customizations"
}

# Run the migration and capture output. Returns the exit code.
run_migration() {
  local proj="$1"
  local upstream="$2"   # path to upstream clone, or "" to omit WORKDIR_NEW
  local log="$3"
  local rc=0
  (
    export PROJECT_ROOT="$proj"
    export WORKDIR_NEW="${upstream}"
    # WORKDIR_OLD is not needed for pass 2; omit it so pass 1 skips cleanly.
    unset WORKDIR_OLD
    bash "$migration"
  ) > "$log" 2>&1 || rc=$?
  echo "$rc"
}

# Run lint-agent-contracts.sh --canonical-only against an agent file.
# Temporarily places the agents dir where the lint script expects it.
lint_agent() {
  local proj_dir="$1"
  # lint-agent-contracts.sh reads from .claude/agents/ relative to
  # the script's REPO_ROOT (it cds to repo root). We need it to run
  # from the project fixture. Invoke it with a wrapper that overrides
  # AGENTS_DIR via a symlink trick: copy the agent dir into a temp
  # tree that mimics the schema path, then run from there.
  local lint_tmp
  lint_tmp="$(mktemp -d)"
  mkdir -p "$lint_tmp/.claude/agents"
  # Copy the project's agent files into the lint tree.
  cp "$proj_dir/.claude/agents/"*.md "$lint_tmp/.claude/agents/" 2>/dev/null || true
  # Copy the schema so lint can find it.
  mkdir -p "$lint_tmp/schemas"
  cp "$repo_root/schemas/agent-contract.schema.json" "$lint_tmp/schemas/"
  # Run lint from the lint_tmp tree.
  local out
  out="$(mktemp)"
  local rc=0
  (
    cd "$lint_tmp"
    # Patch SCRIPT_DIR so the script resolves REPO_ROOT to lint_tmp.
    # We do this by invoking the script with a symlinked scripts/ dir.
    mkdir -p "$lint_tmp/scripts"
    ln -sf "$repo_root/scripts/lint-agent-contracts.sh" "$lint_tmp/scripts/lint-agent-contracts.sh"
    bash "$lint_tmp/scripts/lint-agent-contracts.sh" --canonical-only
  ) > "$out" 2>&1 || rc=$?
  cat "$out" >&2
  rm -rf "$lint_tmp" "$out"
  return "$rc"
}

# Simpler lint approach: use the real lint script but pass just the
# agent file by building a minimal project tree with schemas in place.
lint_one_agent() {
  local agent_file="$1"
  local lint_tmp
  lint_tmp="$(mktemp -d)"
  mkdir -p "$lint_tmp/.claude/agents" "$lint_tmp/schemas" "$lint_tmp/scripts"
  cp "$agent_file" "$lint_tmp/.claude/agents/"
  cp "$repo_root/schemas/agent-contract.schema.json" "$lint_tmp/schemas/"
  ln -sf "$repo_root/scripts/lint-agent-contracts.sh" "$lint_tmp/scripts/lint-agent-contracts.sh"
  local rc=0
  ( cd "$lint_tmp" && bash "$lint_tmp/scripts/lint-agent-contracts.sh" --canonical-only ) \
    >/dev/null 2>&1 || rc=$?
  rm -rf "$lint_tmp"
  return "$rc"
}

# ---------------------------------------------------------------------------
# Case 1: agent missing hard_rules only
# ---------------------------------------------------------------------------
echo "-- Case 1: agent missing hard_rules only --"

proj1="$tmp/proj1"
upstream1="$tmp/upstream1"
make_project "$proj1" "synthetic-agent.md" --with-output-format
make_upstream "$upstream1" "synthetic-agent.md"

rc1=$(run_migration "$proj1" "$upstream1" "$tmp/case1.log")
check "case1: migration exits 0" bash -c "[ '$rc1' = '0' ]"
check "case1: hard_rules section inserted" \
  grep -q "^## Hard rules" "$proj1/.claude/agents/synthetic-agent.md"
check "case1: output_format section still present" \
  grep -q "^## Output format" "$proj1/.claude/agents/synthetic-agent.md"
check "case1: hard_rules section not duplicated" \
  bash -c "[ \"\$(grep -c '^## Hard rules' '$proj1/.claude/agents/synthetic-agent.md')\" = '1' ]"
check "case1: audit row written to docs/DECISIONS.md" \
  grep -q "rc14 migration pass 2" "$proj1/docs/DECISIONS.md"
check "case1: lint passes" lint_one_agent "$proj1/.claude/agents/synthetic-agent.md"

# ---------------------------------------------------------------------------
# Case 2: agent missing output_format only
# ---------------------------------------------------------------------------
echo ""
echo "-- Case 2: agent missing output_format only --"

proj2="$tmp/proj2"
upstream2="$tmp/upstream2"
make_project "$proj2" "synthetic-agent.md" --with-hard-rules
make_upstream "$upstream2" "synthetic-agent.md"

rc2=$(run_migration "$proj2" "$upstream2" "$tmp/case2.log")
check "case2: migration exits 0" bash -c "[ '$rc2' = '0' ]"
check "case2: output_format section inserted" \
  grep -q "^## Output format" "$proj2/.claude/agents/synthetic-agent.md"
check "case2: hard_rules section still present" \
  grep -q "^## Hard rules" "$proj2/.claude/agents/synthetic-agent.md"
check "case2: output_format section not duplicated" \
  bash -c "[ \"\$(grep -c '^## Output format' '$proj2/.claude/agents/synthetic-agent.md')\" = '1' ]"
check "case2: audit row written to docs/DECISIONS.md" \
  grep -q "rc14 migration pass 2" "$proj2/docs/DECISIONS.md"
check "case2: lint passes" lint_one_agent "$proj2/.claude/agents/synthetic-agent.md"

# ---------------------------------------------------------------------------
# Case 3: agent missing both hard_rules and output_format
# ---------------------------------------------------------------------------
echo ""
echo "-- Case 3: agent missing both hard_rules and output_format --"

proj3="$tmp/proj3"
upstream3="$tmp/upstream3"
make_project "$proj3" "synthetic-agent.md"
make_upstream "$upstream3" "synthetic-agent.md"

rc3=$(run_migration "$proj3" "$upstream3" "$tmp/case3.log")
check "case3: migration exits 0" bash -c "[ '$rc3' = '0' ]"
check "case3: hard_rules section inserted" \
  grep -q "^## Hard rules" "$proj3/.claude/agents/synthetic-agent.md"
check "case3: output_format section inserted" \
  grep -q "^## Output format" "$proj3/.claude/agents/synthetic-agent.md"
check "case3: exactly one hard_rules section" \
  bash -c "[ \"\$(grep -c '^## Hard rules' '$proj3/.claude/agents/synthetic-agent.md')\" = '1' ]"
check "case3: exactly one output_format section" \
  bash -c "[ \"\$(grep -c '^## Output format' '$proj3/.claude/agents/synthetic-agent.md')\" = '1' ]"
check "case3: two audit rows written (one per section)" \
  bash -c "[ \"\$(grep -c 'rc14 migration pass 2' '$proj3/docs/DECISIONS.md')\" = '2' ]"
check "case3: canonical order — Hard rules before Output format (issue #267)" \
  bash -c "[ \"\$(awk '/^## Hard rules/{print NR; exit}' '$proj3/.claude/agents/synthetic-agent.md')\" -lt \"\$(awk '/^## Output format/{print NR; exit}' '$proj3/.claude/agents/synthetic-agent.md')\" ]"
check "case3: lint passes" lint_one_agent "$proj3/.claude/agents/synthetic-agent.md"

# ---------------------------------------------------------------------------
# Case 4: agent already has both sections (idempotent no-op)
# ---------------------------------------------------------------------------
echo ""
echo "-- Case 4: agent already has both sections (idempotent no-op) --"

proj4="$tmp/proj4"
upstream4="$tmp/upstream4"
make_project "$proj4" "synthetic-agent.md" --with-hard-rules --with-output-format
make_upstream "$upstream4" "synthetic-agent.md"

# Capture the file content before migration.
before4="$(cat "$proj4/.claude/agents/synthetic-agent.md")"

rc4=$(run_migration "$proj4" "$upstream4" "$tmp/case4.log")
after4="$(cat "$proj4/.claude/agents/synthetic-agent.md")"

check "case4: migration exits 0" bash -c "[ '$rc4' = '0' ]"
check "case4: file content unchanged (idempotent)" bash -c "[ '$before4' = '$after4' ]"
check "case4: exactly one hard_rules section" \
  bash -c "[ \"\$(grep -c '^## Hard rules' '$proj4/.claude/agents/synthetic-agent.md')\" = '1' ]"
check "case4: exactly one output_format section" \
  bash -c "[ \"\$(grep -c '^## Output format' '$proj4/.claude/agents/synthetic-agent.md')\" = '1' ]"
check "case4: lint passes" lint_one_agent "$proj4/.claude/agents/synthetic-agent.md"

# Idempotency: re-run the migration on the same project.
rc4b=$(run_migration "$proj4" "$upstream4" "$tmp/case4b.log")
after4b="$(cat "$proj4/.claude/agents/synthetic-agent.md")"
check "case4: idempotent re-run exits 0" bash -c "[ '$rc4b' = '0' ]"
check "case4: file content unchanged after re-run" bash -c "[ '$after4' = '$after4b' ]"

# ---------------------------------------------------------------------------
# Case 5: WORKDIR_NEW absent — placeholder fallback path
# ---------------------------------------------------------------------------
echo ""
echo "-- Case 5: WORKDIR_NEW absent; placeholder fallback --"

proj5="$tmp/proj5"
make_project "$proj5" "synthetic-agent.md"

# Run with empty WORKDIR_NEW to force placeholder path.
rc5=$(run_migration "$proj5" "" "$tmp/case5.log")
check "case5: migration exits 0" bash -c "[ '$rc5' = '0' ]"
check "case5: hard_rules section inserted (placeholder)" \
  grep -q "^## Hard rules" "$proj5/.claude/agents/synthetic-agent.md"
check "case5: output_format section inserted (placeholder)" \
  grep -q "^## Output format" "$proj5/.claude/agents/synthetic-agent.md"
check "case5: placeholder contains TODO marker" \
  grep -q "TODO" "$proj5/.claude/agents/synthetic-agent.md"
check "case5: placeholder references git show command" \
  grep -q "git show v1.0.0-rc14" "$proj5/.claude/agents/synthetic-agent.md"
check "case5: audit row mentions 'not reachable'" \
  grep -q "not reachable" "$proj5/docs/DECISIONS.md"
check "case5: lint passes" lint_one_agent "$proj5/.claude/agents/synthetic-agent.md"

# ---------------------------------------------------------------------------
# Additional exclusion checks
# ---------------------------------------------------------------------------
echo ""
echo "-- Exclusion checks: sme-*.md and *-local.md are skipped --"

proj6="$tmp/proj6"
upstream6="$tmp/upstream6"
mkdir -p "$proj6/.claude/agents" "$proj6/docs"
make_upstream "$upstream6" "sme-brewing.md"
make_upstream "$upstream6" "tech-lead-local.md"

# Write an SME agent and a local supplement — neither should be canonical-schema-linted.
cat > "$proj6/.claude/agents/sme-brewing.md" <<'EOF'
---
name: sme-brewing
description: Brewing SME — domain knowledge for mashing and fermentation processes.
---

## Mode

Knowledge lookup and domain question answering.

## Scope

Brewing process domain only.
EOF

cat > "$proj6/.claude/agents/tech-lead-local.md" <<'EOF'
---
name: tech-lead-local
description: Local supplement for tech-lead; project-specific routing overrides.
---

## Local supplement rule

Override routing for database questions to sme-db agent.
EOF

printf '.claude/agents/sme-brewing.md\n.claude/agents/tech-lead-local.md\n' \
  > "$proj6/.template-customizations"

rc6=$(run_migration "$proj6" "$upstream6" "$tmp/case6.log")
check "excl: migration exits 0" bash -c "[ '$rc6' = '0' ]"
check "excl: sme-brewing.md not modified (no hard_rules injected)" \
  bash -c "! grep -q '## Hard rules' '$proj6/.claude/agents/sme-brewing.md'"
check "excl: tech-lead-local.md not modified (no hard_rules injected)" \
  bash -c "! grep -q '## Hard rules' '$proj6/.claude/agents/tech-lead-local.md'"
check "excl: no audit rows written for excluded files" \
  bash -c "[ ! -f '$proj6/docs/DECISIONS.md' ] || ! grep -q 'rc14 migration pass 2' '$proj6/docs/DECISIONS.md'"

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
