#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# tests/lint/test-agent-model-routing.sh — self-test for
# scripts/lint-agent-model-routing.sh (#207 Part B).
#
# Cases:
#   1. Happy path: all 14 contracts at preferred class -> PASS
#   2. Availability-fallback: contract at next-higher tier -> PASS
#      (e.g., model: opus for a sonnet-defaulted role)
#   3. Misconfigured: model: inherit -> FAIL
#   4. Misconfigured: model: haiku for a sonnet-defaulted role
#      (downward fallback) -> FAIL
#   5. Missing agent contract (one of the 14 absent) -> FAIL
#   6. Schema validation failure (malformed extracted JSON) -> FAIL
#
# Each case builds a minimal isolated fixture directory (temp copy of the
# agents dir + a trimmed rubric) so the real repo contracts are never
# modified during testing.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LINT="$REPO_ROOT/scripts/lint-agent-model-routing.sh"

pass=0
fail=0
failures=()

# --------------------------------------------------------------------------
# run_case <name> <expect-exit: 0|1|2> <extra-args...>
#
# Runs the lint with the given extra args; asserts the exit code matches.
# --------------------------------------------------------------------------
run_case() {
    local name=$1
    local expect_exit=$2
    shift 2

    local actual_exit=0
    "$LINT" "$@" >/dev/null 2>&1 || actual_exit=$?

    if [ "$actual_exit" -eq "$expect_exit" ]; then
        pass=$((pass + 1))
        echo "PASS  $name"
    else
        fail=$((fail + 1))
        failures+=("$name (expected exit=$expect_exit actual exit=$actual_exit)")
        echo "FAIL  $name (expected exit=$expect_exit actual=$actual_exit)"
    fi
}

# --------------------------------------------------------------------------
# Fixture helpers
# --------------------------------------------------------------------------

# Build a minimal agents directory in a tempdir.
# $1 = tmpdir base
# Copies the real contracts as-is (preferred values from Part A).
make_agents_dir() {
    local base="$1"
    local adir="$base/agents"
    mkdir -p "$adir"
    cp "$REPO_ROOT/.claude/agents/"*.md "$adir/"
    echo "$adir"
}

# Write a single-agent minimal contract with a given model: value.
write_contract() {
    local dir="$1"
    local agent="$2"
    local model="$3"
    cat > "$dir/${agent}.md" << EOF
---
name: ${agent}
description: Test contract for ${agent}.
tools: Read
model: ${model}
---

Body.
EOF
}

# Build a minimal rubric containing a single-row binding table.
# $1 = tmpdir base
# $2 = agent name
# $3 = default_class (e.g., claude-sonnet)
# $4 = claude_equivalent (e.g., sonnet)
make_rubric() {
    local base="$1"
    local agent="$2"
    local default_class="$3"
    local claude_eq="$4"
    local rubric="$base/rubric.md"
    cat > "$rubric" << EOF
# Model Routing Guidelines

## Binding per-agent default-class table

| Agent | default_class | Claude equivalent | OpenAI equivalent | Gemini equivalent | frontier_only_when |
|---|---|---|---|---|---|
| \`${agent}\` | \`${default_class}\` | \`${claude_eq}\` | \`openai-coding\` | \`gemini-pro\` | test escalation |

## Availability fallback

See policy above.
EOF
    echo "$rubric"
}

# --------------------------------------------------------------------------
# Case 1: Happy path — all 14 real contracts at preferred class -> PASS
# --------------------------------------------------------------------------
run_case "happy-path: all 14 at preferred" 0 \
    --agents-dir "$REPO_ROOT/.claude/agents" \
    --rubric "$REPO_ROOT/docs/model-routing-guidelines.md"

# --------------------------------------------------------------------------
# Case 2: Availability-fallback — model: opus for a sonnet-preferred role
# --------------------------------------------------------------------------
TMPDIR2="$(mktemp -d)"
trap 'rm -rf "$TMPDIR2"' EXIT INT TERM HUP
ADIR2="$(make_agents_dir "$TMPDIR2")"
# Override researcher contract to use opus (next-higher than sonnet).
write_contract "$ADIR2" "researcher" "opus"
RUBRIC2="$(make_rubric "$TMPDIR2" "researcher" "claude-sonnet" "sonnet")"

run_case "availability-fallback: sonnet-role at opus -> PASS" 0 \
    --agents-dir "$ADIR2" \
    --rubric "$RUBRIC2"

# --------------------------------------------------------------------------
# Case 3: model: inherit -> FAIL
# --------------------------------------------------------------------------
TMPDIR3="$(mktemp -d)"
ADIR3="$(make_agents_dir "$TMPDIR3")"
write_contract "$ADIR3" "architect" "inherit"
RUBRIC3="$(make_rubric "$TMPDIR3" "architect" "claude-sonnet" "sonnet")"

run_case "misconfigured: model: inherit -> FAIL" 1 \
    --agents-dir "$ADIR3" \
    --rubric "$RUBRIC3"

# --------------------------------------------------------------------------
# Case 4: model: haiku for a sonnet-preferred role (downward) -> FAIL
# --------------------------------------------------------------------------
TMPDIR4="$(mktemp -d)"
ADIR4="$(make_agents_dir "$TMPDIR4")"
write_contract "$ADIR4" "software-engineer" "haiku"
RUBRIC4="$(make_rubric "$TMPDIR4" "software-engineer" "openai-coding" "sonnet")"

run_case "misconfigured: haiku for sonnet-preferred role -> FAIL" 1 \
    --agents-dir "$ADIR4" \
    --rubric "$RUBRIC4"

# --------------------------------------------------------------------------
# Case 5: Missing agent contract -> FAIL
# --------------------------------------------------------------------------
TMPDIR5="$(mktemp -d)"
ADIR5="$(make_agents_dir "$TMPDIR5")"
# Remove one contract so it's missing.
rm -f "$ADIR5/security-engineer.md"
RUBRIC5="$(make_rubric "$TMPDIR5" "security-engineer" "claude-sonnet" "sonnet")"

run_case "missing-contract: security-engineer absent -> FAIL" 1 \
    --agents-dir "$ADIR5" \
    --rubric "$RUBRIC5"

# --------------------------------------------------------------------------
# Case 6: Schema validation failure.
# We make a rubric whose table row uses a default_class value that is NOT
# in the schema enum (schemas/model-routing.schema.json), causing
# check-jsonschema to reject the extracted JSON.
# --------------------------------------------------------------------------
TMPDIR6="$(mktemp -d)"
ADIR6="$(make_agents_dir "$TMPDIR6")"
RUBRIC6="$TMPDIR6/bad-rubric.md"
cat > "$RUBRIC6" << 'EOF'
# Model Routing Guidelines

## Binding per-agent default-class table

| Agent | default_class | Claude equivalent | OpenAI equivalent | Gemini equivalent | frontier_only_when |
|---|---|---|---|---|---|
| `architect` | `not-a-real-class` | `sonnet` | `openai-coding` | `gemini-pro` | test |

## Availability fallback

see above
EOF

run_case "schema-validation-fail: invalid default_class -> FAIL" 1 \
    --agents-dir "$ADIR6" \
    --rubric "$RUBRIC6"

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
