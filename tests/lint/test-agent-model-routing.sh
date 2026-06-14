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
#   7. --summary prints FAIL on failure path -> PASS
#   8. Codex TOML adapter surface uses concrete Codex model slugs -> PASS
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
# Case 7: --summary FAIL line is printed on failure path (regression-pin for
# CR-PR-G blocking finding: under set -eu the FAIL line was dead code).
# Deliberately corrupt one contract to model: inherit, invoke with --summary,
# assert exit non-zero AND that the FAIL line appears in stdout.
# --------------------------------------------------------------------------
TMPDIR7="$(mktemp -d)"
ADIR7="$(make_agents_dir "$TMPDIR7")"
write_contract "$ADIR7" "architect" "inherit"
RUBRIC7="$(make_rubric "$TMPDIR7" "architect" "claude-sonnet" "sonnet")"

SUMMARY_OUT7="$(mktemp)"
ACTUAL_EXIT7=0
"$LINT" --summary --agents-dir "$ADIR7" --rubric "$RUBRIC7" >"$SUMMARY_OUT7" 2>/dev/null || ACTUAL_EXIT7=$?

SUMMARY_FAIL_FOUND=0
if grep -q "lint-agent-model-routing: FAIL" "$SUMMARY_OUT7"; then
    SUMMARY_FAIL_FOUND=1
fi
rm -f "$SUMMARY_OUT7"

if [ "$ACTUAL_EXIT7" -ne 0 ] && [ "$SUMMARY_FAIL_FOUND" -eq 1 ]; then
    pass=$((pass + 1))
    echo "PASS  summary-fail-line: FAIL summary printed + non-zero exit"
else
    fail=$((fail + 1))
    failures+=("summary-fail-line: FAIL summary printed + non-zero exit (exit=$ACTUAL_EXIT7 fail_line_found=$SUMMARY_FAIL_FOUND)")
    echo "FAIL  summary-fail-line: FAIL summary printed + non-zero exit (exit=$ACTUAL_EXIT7 fail_line_found=$SUMMARY_FAIL_FOUND)"
fi

# --------------------------------------------------------------------------
# Case 8: Codex typed-role adapter surface.
# The native Codex multi_agent_v1 typed-role resolver is external to this
# repository, so this pins the repo-side compatibility contract: generated
# Codex-facing role files must not expose Claude aliases such as `sonnet`
# or abstract OpenAI classes such as `openai-coding`.
# --------------------------------------------------------------------------
codex_model_id_for_class() {
    case "$1" in
        openai-mini) echo "gpt-5.4-mini" ;;
        openai-coding) echo "gpt-5.4" ;;
        openai-frontier) echo "gpt-5.5" ;;
        *) echo "" ;;
    esac
}

CODEX_ADAPTER_FAIL=0
for role in architect software-engineer release-engineer code-reviewer project-manager researcher; do
    adapter="$REPO_ROOT/.codex/agents/${role}.toml"
    expected_class="$(
        awk -v role="$role" '
            BEGIN { FS = "|"; in_table = 0 }
            /^##[ \t]+Binding per-agent default-class table/ { in_table = 1; next }
            /^##[ \t]+/ { if (in_table) in_table = 0 }
            in_table == 0 { next }
            /^\|[ \t]*`[a-z0-9-]+`[ \t]*\|/ {
                agent = $2
                gsub(/^[ \t]+|[ \t]+$/, "", agent)
                gsub(/`/, "", agent)
                if (agent == role) {
                    model = $5
                    gsub(/^[ \t]+|[ \t]+$/, "", model)
                    gsub(/`/, "", model)
                    print model
                    exit
                }
            }
        ' "$REPO_ROOT/docs/model-routing-guidelines.md"
    )"
    expected_model="$(codex_model_id_for_class "$expected_class")"

    if [ ! -f "$adapter" ]; then
        CODEX_ADAPTER_FAIL=1
        failures+=("codex-adapter: missing $adapter")
        echo "FAIL  codex-adapter: missing $adapter"
        continue
    fi

    if [ -z "$expected_model" ]; then
        CODEX_ADAPTER_FAIL=1
        failures+=("codex-adapter: $role unsupported OpenAI class=$expected_class")
        echo "FAIL  codex-adapter: $role unsupported OpenAI class=$expected_class"
        continue
    fi

    actual_model="$(awk -F'=' '/^model[ \t]*=/ { v=$2; sub(/^[ \t]*/, "", v); gsub(/^"|"$/, "", v); print v; exit }' "$adapter")"
    if [ "$actual_model" != "$expected_model" ]; then
        CODEX_ADAPTER_FAIL=1
        failures+=("codex-adapter: $role expected model=$expected_model actual=$actual_model")
        echo "FAIL  codex-adapter: $role expected model=$expected_model actual=$actual_model"
        continue
    fi

    if grep -Eq '^model[[:space:]]*=[[:space:]]*"(haiku|sonnet|opus|openai-mini|openai-coding|openai-frontier)"[[:space:]]*$' "$adapter"; then
        CODEX_ADAPTER_FAIL=1
        failures+=("codex-adapter: $role exposes non-concrete model alias")
        echo "FAIL  codex-adapter: $role exposes non-concrete model alias"
        continue
    fi

    if [ -f "$REPO_ROOT/.codex/agents/${role}.md" ]; then
        CODEX_ADAPTER_FAIL=1
        failures+=("codex-adapter: stale Markdown adapter still present for $role")
        echo "FAIL  codex-adapter: stale Markdown adapter still present for $role"
        continue
    fi

    if ! printf '%s\n' "$actual_model" | grep -Eq '^(gpt-[A-Za-z0-9.-]+|codex-auto-review)$'; then
        CODEX_ADAPTER_FAIL=1
        failures+=("codex-adapter: $role model is not an allowed concrete Codex slug: $actual_model")
        echo "FAIL  codex-adapter: $role model is not an allowed concrete Codex slug: $actual_model"
        continue
    fi
done

TMPDIR8="$(mktemp -d)"
trap 'rm -rf "$TMPDIR2" "$TMPDIR8"' EXIT INT TERM HUP
ADAPTER8="$TMPDIR8/frontier-fixture.toml"
cat > "$ADAPTER8" << 'EOF'
name: frontier-fixture
model = "gpt-5.5"
EOF

frontier_model="$(awk -F'=' '/^model[ \t]*=/ { v=$2; sub(/^[ \t]*/, "", v); gsub(/^"|"$/, "", v); print v; exit }' "$ADAPTER8")"
if [ "$frontier_model" != "$(codex_model_id_for_class openai-frontier)" ]; then
    CODEX_ADAPTER_FAIL=1
    failures+=("codex-adapter: frontier fixture expected model=$(codex_model_id_for_class openai-frontier) actual=$frontier_model")
    echo "FAIL  codex-adapter: frontier fixture expected model=$(codex_model_id_for_class openai-frontier) actual=$frontier_model"
elif ! printf '%s\n' "$frontier_model" | grep -Eq '^(gpt-[A-Za-z0-9.-]+|codex-auto-review)$'; then
    CODEX_ADAPTER_FAIL=1
    failures+=("codex-adapter: frontier fixture model is not an allowed concrete Codex slug: $frontier_model")
    echo "FAIL  codex-adapter: frontier fixture model is not an allowed concrete Codex slug: $frontier_model"
fi

if [ "$CODEX_ADAPTER_FAIL" -eq 0 ]; then
    pass=$((pass + 1))
    echo "PASS  codex-adapter: concrete Codex model slug surface present"
else
    fail=$((fail + 1))
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
