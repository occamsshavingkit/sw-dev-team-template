#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# tests/prompt-regression/run.sh — prompt-regression harness for
# the template-improvement-program (specs/006-template-improvement-program,
# task T011).
#
# Walks tests/prompt-regression/<agent>/<case>.yaml, validates required
# YAML keys with awk/grep (no yq / Python), and emits a deterministic
# Markdown results file at tests/prompt-regression/results-<UTC-date>.md.
#
# In this initial version the --canonical and --compiled modes are
# stubs that record placeholder results; T018 will wire up the actual
# LLM-driven execution against .claude/agents/<agent>.md (canonical) and
# docs/runtime/agents/<agent>.md (compiled). --validate-only is the
# default and exercises the discovery + YAML-shape checks only.
#
# Usage:
#   tests/prompt-regression/run.sh [--validate-only | --canonical | --compiled] [--stdout]
#
# Determinism: same fixture set + same git state → byte-identical
# results file. UTC date is anchored via the same SOURCE_DATE_EPOCH /
# HEAD-commit-time chain used by scripts/baseline-token-economy.sh.
#
# POSIX-sh only: no bashisms (no [[ ]], no arrays, no pipefail, no
# process substitution). Pinned LANG=C/LC_ALL=C.

set -eu

LANG=C
LC_ALL=C
export LANG LC_ALL

usage() {
    cat >&2 <<'EOF'
Usage: tests/prompt-regression/run.sh [--validate-only | --canonical | --compiled] [--stdout]

Modes (mutually exclusive; default --validate-only):
  --validate-only   Parse fixtures, report missing-key errors, do not
                    execute. Default.
  --canonical       Stub: record placeholder result per fixture against
                    .claude/agents/<agent>.md. T018 wires in real LLM
                    execution.
  --compiled        Stub: record placeholder result per fixture against
                    docs/runtime/agents/<agent>.md. Fixtures whose
                    compiled contract is missing are recorded as SKIP.

Options:
  --stdout          Emit the report on stdout instead of writing
                    tests/prompt-regression/results-<UTC-date>.md.
  -h, --help        Show this help and exit.
EOF
}

mode=validate-only
emit_stdout=0
while [ $# -gt 0 ]; do
    case "$1" in
        --validate-only) mode=validate-only ;;
        --canonical)     mode=canonical ;;
        --compiled)      mode=compiled ;;
        --stdout)        emit_stdout=1 ;;
        -h|--help)       usage; exit 0 ;;
        *) printf 'run.sh: unknown argument: %s\n' "$1" >&2
           usage
           exit 2 ;;
    esac
    shift
done

# Resolve sub-repo root (parent of tests/prompt-regression).
script_dir="$(cd -- "$(dirname -- "$0")" && pwd)"
fixtures_dir="$script_dir"
repo_root="$(cd -- "$script_dir/../.." && pwd)"

cd "$repo_root"

template_sha="$(git rev-parse HEAD 2>/dev/null || echo unknown)"

# captured_at is deterministic on inputs (git state). Precedence:
#   1. $SOURCE_DATE_EPOCH (reproducible-build idiom),
#   2. commit time of HEAD (UTC) if the repo is a git checkout,
#   3. current UTC wall-clock time as final fallback.
if [ -n "${SOURCE_DATE_EPOCH:-}" ]; then
    captured_epoch="$SOURCE_DATE_EPOCH"
elif commit_epoch="$(git log -1 --format=%ct HEAD 2>/dev/null)" && [ -n "$commit_epoch" ]; then
    captured_epoch="$commit_epoch"
else
    captured_epoch=""
fi

if [ -n "$captured_epoch" ]; then
    captured_date="$(date -u -d "@${captured_epoch}" +%Y-%m-%d 2>/dev/null \
        || date -u -r "${captured_epoch}" +%Y-%m-%d 2>/dev/null \
        || date -u +%Y-%m-%d)"
else
    captured_date="$(date -u +%Y-%m-%d)"
fi

# Working tempdir; cleaned on exit.
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT INT HUP TERM

# ---------------------------------------------------------------------------
# Discovery: collect every tests/prompt-regression/<agent>/<case>.yaml.
# Deterministic sort under LANG=C / LC_ALL=C.
# ---------------------------------------------------------------------------
fixtures_list="$tmpdir/fixtures.list"
: > "$fixtures_list"
if [ -d "$fixtures_dir" ]; then
    find "$fixtures_dir" -mindepth 2 -maxdepth 2 -type f -name '*.yaml' -print \
        | sort > "$fixtures_list"
fi

total_fixtures="$(wc -l < "$fixtures_list" | tr -d ' ')"

# ---------------------------------------------------------------------------
# YAML shallow validation.
#
# Required keys (shallow, structural — we are not implementing a full
# YAML parser):
#   agent                       → top-level scalar
#   case                        → top-level scalar
#   input.user_message          → key under input:
#   input.context               → key under input:
#   expected_behavior           → top-level list, non-empty
#   assertions                  → top-level list, non-empty
#
# Strategy: stream the fixture through awk that tracks the current
# top-level key, records which required keys were seen, and counts
# list items under expected_behavior / assertions. Output the missing
# keys (one per line, stable order) on stdout; empty stdout = pass.
# ---------------------------------------------------------------------------
validate_fixture() {
    f="$1"
    awk '
        BEGIN {
            has_agent = 0
            has_case  = 0
            has_input = 0
            has_user_message = 0
            has_context = 0
            has_expected_behavior = 0
            has_assertions = 0
            expected_count = 0
            assertions_count = 0
            section = ""
        }
        {
            line = $0
            # strip trailing CR
            sub(/\r$/, "", line)
            # skip blank lines and comments
            if (line ~ /^[[:space:]]*$/) next
            if (line ~ /^[[:space:]]*#/) next

            # Top-level key? (no leading whitespace, ends with ":")
            if (line ~ /^[A-Za-z_][A-Za-z0-9_]*:/) {
                # extract key name (up to first colon)
                key = line
                sub(/:.*$/, "", key)
                if      (key == "agent")             { has_agent = 1; section = "agent" }
                else if (key == "case")              { has_case  = 1; section = "case" }
                else if (key == "input")             { has_input = 1; section = "input" }
                else if (key == "expected_behavior") { has_expected_behavior = 1; section = "expected_behavior" }
                else if (key == "assertions")        { has_assertions = 1; section = "assertions" }
                else                                 { section = "other" }
                next
            }

            # Nested under input: detect user_message / context keys.
            if (section == "input") {
                if (line ~ /^[[:space:]]+user_message:/) { has_user_message = 1; next }
                if (line ~ /^[[:space:]]+context:/)     { has_context = 1; next }
                next
            }

            # List item under expected_behavior / assertions.
            # A list item is an indented line starting with "- ".
            if (section == "expected_behavior") {
                if (line ~ /^[[:space:]]+-[[:space:]]/) expected_count++
                next
            }
            if (section == "assertions") {
                if (line ~ /^[[:space:]]+-[[:space:]]/) assertions_count++
                next
            }
        }
        END {
            if (!has_agent)             print "agent"
            if (!has_case)              print "case"
            if (!has_input)             print "input"
            if (!has_user_message)      print "input.user_message"
            if (!has_context)           print "input.context"
            if (!has_expected_behavior) print "expected_behavior"
            else if (expected_count == 0) print "expected_behavior (empty list)"
            if (!has_assertions)        print "assertions"
            else if (assertions_count == 0) print "assertions (empty list)"
        }
    ' "$f"
}

# ---------------------------------------------------------------------------
# Per-fixture parse loop. Collect validation failures + execution rows.
# ---------------------------------------------------------------------------
validation_failures="$tmpdir/validation_failures"
fixture_rows="$tmpdir/fixture_rows"
: > "$validation_failures"
: > "$fixture_rows"

validation_pass=0
validation_fail=0
exec_skipped=0
exec_stubbed=0

# Extract a top-level scalar's value (e.g., agent: tech-lead).
extract_scalar() {
    f="$1"
    key="$2"
    awk -v K="$key" '
        BEGIN { found = 0 }
        {
            line = $0
            sub(/\r$/, "", line)
            if (line ~ /^[[:space:]]*$/) next
            if (line ~ /^[[:space:]]*#/) next
            # only top-level (column 0) scalars considered
            if (line ~ ("^" K ":")) {
                v = line
                sub("^" K ":[[:space:]]*", "", v)
                # strip trailing whitespace
                sub(/[[:space:]]+$/, "", v)
                print v
                found = 1
                exit
            }
        }
    ' "$f"
}

while IFS= read -r fixture; do
    [ -n "$fixture" ] || continue
    # Relative path for display.
    rel="${fixture#"$repo_root"/}"

    missing="$(validate_fixture "$fixture")"
    if [ -n "$missing" ]; then
        validation_fail=$((validation_fail + 1))
        # One row per missing key, stable order from awk.
        printf '%s\n' "$missing" | while IFS= read -r key; do
            [ -n "$key" ] || continue
            printf -- '- `%s`: missing key `%s`\n' "$rel" "$key" >> "$validation_failures"
        done
        # Skip execution for invalid fixtures.
        agent="$(extract_scalar "$fixture" agent)"
        case_id="$(extract_scalar "$fixture" case)"
        [ -n "$agent" ] || agent="?"
        [ -n "$case_id" ] || case_id="$(basename "$fixture" .yaml)"
        printf '| %s | %s | %s | INVALID |\n' "$agent" "$case_id" "$mode" >> "$fixture_rows"
        exec_skipped=$((exec_skipped + 1))
        continue
    fi

    validation_pass=$((validation_pass + 1))
    agent="$(extract_scalar "$fixture" agent)"
    case_id="$(extract_scalar "$fixture" case)"
    [ -n "$agent" ] || agent="?"
    [ -n "$case_id" ] || case_id="$(basename "$fixture" .yaml)"

    case "$mode" in
        validate-only)
            printf '| %s | %s | %s | PASS |\n' "$agent" "$case_id" "$mode" >> "$fixture_rows"
            ;;
        canonical)
            contract=".claude/agents/${agent}.md"
            printf 'STUB: would execute %s against canonical %s\n' "$rel" "$contract"
            printf '| %s | %s | %s | STUB |\n' "$agent" "$case_id" "$mode" >> "$fixture_rows"
            exec_stubbed=$((exec_stubbed + 1))
            ;;
        compiled)
            contract="docs/runtime/agents/${agent}.md"
            if [ ! -f "$contract" ]; then
                printf 'SKIP: compiled contract not present (%s) for %s\n' "$contract" "$rel"
                printf '| %s | %s | %s | SKIP: compiled contract not present |\n' \
                    "$agent" "$case_id" "$mode" >> "$fixture_rows"
                exec_skipped=$((exec_skipped + 1))
            else
                printf 'STUB: would execute %s against compiled %s\n' "$rel" "$contract"
                printf '| %s | %s | %s | STUB |\n' "$agent" "$case_id" "$mode" >> "$fixture_rows"
                exec_stubbed=$((exec_stubbed + 1))
            fi
            ;;
    esac
done < "$fixtures_list"

# ---------------------------------------------------------------------------
# Compose results file.
# ---------------------------------------------------------------------------
report="$tmpdir/report.md"
{
    printf '# Prompt-regression results — %s — %s\n\n' "$captured_date" "$mode"
    printf '**Mode**: %s\n' "$mode"
    printf '**Template SHA**: %s\n' "$template_sha"
    printf '**Total fixtures**: %s\n' "$total_fixtures"
    printf '**Validation pass**: %s / %s\n' "$validation_pass" "$total_fixtures"
    printf '**Validation fail**: %s\n' "$validation_fail"
    printf '**Execution stub**: %s fixtures\n' "$exec_stubbed"
    printf '**Skipped (compiled mode only)**: %s\n\n' "$exec_skipped"

    printf '## Validation failures\n\n'
    if [ "$validation_fail" -eq 0 ]; then
        printf '_None._\n\n'
    else
        cat "$validation_failures"
        printf '\n'
    fi

    printf '## Fixture run summary\n\n'
    printf '| Agent | Case | Mode | Result |\n'
    printf '|---|---|---|---|\n'
    if [ "$total_fixtures" -eq 0 ]; then
        printf '| _none_ | _none_ | %s | _no fixtures discovered_ |\n' "$mode"
    else
        cat "$fixture_rows"
    fi
} > "$report"

results_path="$fixtures_dir/results-${captured_date}.md"

if [ "$emit_stdout" -eq 1 ]; then
    cat "$report"
else
    cp "$report" "$results_path"
    printf 'Wrote %s\n' "${results_path#"$repo_root"/}"
fi

exit 0
