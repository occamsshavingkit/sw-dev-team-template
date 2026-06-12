#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# tests/upgrade/test-gen-register-index-yaml.sh — regression tests for
# gen-register-index.sh YAML intake-log indexing (issue #337).
#
# Cases:
#   T1. A YAML-format intake log (timestamp: fields, --- delimiters) reports
#       the correct non-zero entry count and a non-empty date range.
#   T2. A table-format register still indexes correctly after the YAML fix
#       (no regression in the existing heuristic).
#   T3. A file containing BOTH a YAML preamble and a markdown table is
#       treated as YAML (timestamp: fields present) — count reflects
#       the YAML records, not the table rows.
#   T4. An empty file (no entries) reports count=0 and no date range
#       for both shapes.
#   T5. A YAML log with a single entry reports count=1 and earliest==latest.
#
# All fixtures are throwaway temp files; the live registers are never
# touched.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GEN_INDEX="$REPO_ROOT/scripts/gen-register-index.sh"

tmp="$(mktemp -d -t yaml-index-XXXXXX)"
keep=0
[[ "${1:-}" == "--keep" ]] && keep=1
trap 'if [[ $keep -eq 0 ]]; then rm -rf "$tmp"; else echo "(kept $tmp)" >&2; fi' EXIT

fail=0
pass=0

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

check_output() {
    local label="$1"
    local pattern="$2"
    shift 2
    local out
    out=$("$@" 2>&1) || true
    if printf '%s' "$out" | grep -qF "$pattern"; then
        echo "  PASS: $label"
        pass=$((pass + 1))
    else
        echo "  FAIL: $label (pattern='$pattern' not found)" >&2
        printf "        output: %s\n" "$out" >&2
        fail=$((fail + 1))
    fi
}

check_not_output() {
    local label="$1"
    local pattern="$2"
    shift 2
    local out
    out=$("$@" 2>&1) || true
    if ! printf '%s' "$out" | grep -qF "$pattern"; then
        echo "  PASS: $label"
        pass=$((pass + 1))
    else
        echo "  FAIL: $label (pattern='$pattern' unexpectedly found)" >&2
        printf "        output: %s\n" "$out" >&2
        fail=$((fail + 1))
    fi
}

# ---------------------------------------------------------------------------
# T1: YAML intake-log — correct entry count and date range
# ---------------------------------------------------------------------------
echo "-- T1: YAML intake-log reports correct non-zero entry count + date range --"

proj1="$tmp/proj1"
mkdir -p "$proj1/docs"
cat > "$proj1/docs/intake-log.md" <<'EOF'
# Intake Log — test-project

---
turn: 1
timestamp: 2026-01-15T14:30Z
asked-by: tech-lead
framing: |
  What is the primary use case for this project?
agents-running-at-ask: []
customer-answer: |
  Automate the CI pipeline.
decision: CI automation is the primary use case.
cross-refs: []
---
turn: 2
timestamp: 2026-03-20T09:00Z
asked-by: tech-lead
framing: |
  Should we target Python 3.11 or 3.12?
agents-running-at-ask: []
customer-answer: |
  Python 3.12.
decision: Target Python 3.12.
cross-refs: []
---
turn: 3
timestamp: 2026-04-05T16:45Z
asked-by: tech-lead
framing: |
  Do you require SBOM generation?
agents-running-at-ask: []
customer-answer: |
  Yes, SPDX format.
decision: SPDX SBOM required.
cross-refs: []
EOF

bash "$GEN_INDEX" "docs/intake-log.md" --root "$proj1"

check "T1: INDEX.md created" test -f "$proj1/docs/intake-log-INDEX.md"

# Verify count is 3 (not 0).
_count1=$(awk '/^\*\*Total entries/{print $NF}' "$proj1/docs/intake-log-INDEX.md" | tr -d '**' || echo "?")
if [[ "$_count1" == "3" ]]; then
    echo "  PASS: T1: entry count is 3"
    pass=$((pass + 1))
else
    echo "  FAIL: T1: expected entry count 3, got '$_count1'" >&2
    fail=$((fail + 1))
fi

# Verify date range present (should contain 2026-01-15).
check "T1: date range contains earliest date 2026-01-15" \
    grep -q "2026-01-15" "$proj1/docs/intake-log-INDEX.md"
check "T1: date range contains latest date 2026-04-05" \
    grep -q "2026-04-05" "$proj1/docs/intake-log-INDEX.md"

# Count must not be 0.
check_not_output "T1: dry-run does not report 0 entries" \
    "| 0 |" \
    bash "$GEN_INDEX" "docs/intake-log.md" --root "$proj1" --dry-run

# ---------------------------------------------------------------------------
# T2: Table-format register still indexes correctly (no regression)
# ---------------------------------------------------------------------------
echo ""
echo "-- T2: table-format register still indexes correctly --"

proj2="$tmp/proj2"
mkdir -p "$proj2/docs"
cat > "$proj2/docs/OPEN_QUESTIONS.md" <<'EOF'
# Open Questions register

| ID | Opened | Question | Blocked on | Answerer | Status | Resolution |
|---|---|---|---|---|---|---|
| Q-0001 | 2026-01-10 | First question | — | tech-lead | answered | Done. 2026-02-01 |
| Q-0002 | 2026-02-15 | Second question | — | customer | answered | Done. 2026-03-01 |
| Q-0003 | 2026-04-01 | Third question | — | customer | open | — |
EOF

bash "$GEN_INDEX" "docs/OPEN_QUESTIONS.md" --root "$proj2"

check "T2: INDEX.md created for table register" \
    test -f "$proj2/docs/OPEN_QUESTIONS-INDEX.md"

_count2=$(awk '/^\*\*Total entries/{print $NF}' "$proj2/docs/OPEN_QUESTIONS-INDEX.md" | tr -d '**' || echo "?")
if [[ "$_count2" == "3" ]]; then
    echo "  PASS: T2: table register entry count is 3"
    pass=$((pass + 1))
else
    echo "  FAIL: T2: expected entry count 3 for table register, got '$_count2'" >&2
    fail=$((fail + 1))
fi

check "T2: date range contains 2026-01-10" \
    grep -q "2026-01-10" "$proj2/docs/OPEN_QUESTIONS-INDEX.md"

# ---------------------------------------------------------------------------
# T3: File with YAML timestamp fields is treated as YAML (not table)
# ---------------------------------------------------------------------------
echo ""
echo "-- T3: file with timestamp: fields treated as YAML intake log --"

proj3="$tmp/proj3"
mkdir -p "$proj3/docs"
# File has a markdown table header but also YAML-style records with timestamp:.
# The YAML shape should win (timestamp: detection).
cat > "$proj3/docs/intake-log.md" <<'EOF'
# Intake Log — hybrid test

| turn | timestamp | question |
|---|---|---|

---
turn: 1
timestamp: 2026-05-01T10:00Z
asked-by: tech-lead
framing: |
  Question 1?
agents-running-at-ask: []
customer-answer: |
  Answer 1.
decision: Decision 1.
cross-refs: []
---
turn: 2
timestamp: 2026-06-01T12:00Z
asked-by: tech-lead
framing: |
  Question 2?
agents-running-at-ask: []
customer-answer: |
  Answer 2.
decision: Decision 2.
cross-refs: []
EOF

bash "$GEN_INDEX" "docs/intake-log.md" --root "$proj3"

_count3=$(awk '/^\*\*Total entries/{print $NF}' "$proj3/docs/intake-log-INDEX.md" | tr -d '**' || echo "?")
if [[ "$_count3" == "2" ]]; then
    echo "  PASS: T3: YAML-detected file reports count 2 (YAML records, not table rows)"
    pass=$((pass + 1))
else
    echo "  FAIL: T3: expected count 2 for YAML-detected hybrid file, got '$_count3'" >&2
    fail=$((fail + 1))
fi

# ---------------------------------------------------------------------------
# T4: Empty file reports count=0 for both shapes
# ---------------------------------------------------------------------------
echo ""
echo "-- T4: empty file reports count=0 for both shapes --"

proj4="$tmp/proj4"
mkdir -p "$proj4/docs"
printf '# Empty intake log\n' > "$proj4/docs/intake-log.md"

bash "$GEN_INDEX" "docs/intake-log.md" --root "$proj4"

_count4=$(awk '/^\*\*Total entries/{print $NF}' "$proj4/docs/intake-log-INDEX.md" | tr -d '**' || echo "?")
if [[ "$_count4" == "0" ]]; then
    echo "  PASS: T4: empty YAML log reports count 0"
    pass=$((pass + 1))
else
    echo "  FAIL: T4: expected count 0 for empty log, got '$_count4'" >&2
    fail=$((fail + 1))
fi

proj4b="$tmp/proj4b"
mkdir -p "$proj4b/docs"
printf '# Empty table register\n' > "$proj4b/docs/OPEN_QUESTIONS.md"

bash "$GEN_INDEX" "docs/OPEN_QUESTIONS.md" --root "$proj4b"

_count4b=$(awk '/^\*\*Total entries/{print $NF}' "$proj4b/docs/OPEN_QUESTIONS-INDEX.md" | tr -d '**' || echo "?")
if [[ "$_count4b" == "0" ]]; then
    echo "  PASS: T4: empty table register reports count 0"
    pass=$((pass + 1))
else
    echo "  FAIL: T4: expected count 0 for empty table register, got '$_count4b'" >&2
    fail=$((fail + 1))
fi

# ---------------------------------------------------------------------------
# T5: YAML log with a single entry — count=1, earliest==latest
# ---------------------------------------------------------------------------
echo ""
echo "-- T5: single-entry YAML log — count=1, earliest==latest --"

proj5="$tmp/proj5"
mkdir -p "$proj5/docs"
cat > "$proj5/docs/intake-log.md" <<'EOF'
# Intake Log — single entry

---
turn: 1
timestamp: 2026-03-07T08:00Z
asked-by: tech-lead
framing: |
  Only question.
agents-running-at-ask: []
customer-answer: |
  Only answer.
decision: Single decision.
cross-refs: []
EOF

bash "$GEN_INDEX" "docs/intake-log.md" --root "$proj5"

_count5=$(awk '/^\*\*Total entries/{print $NF}' "$proj5/docs/intake-log-INDEX.md" | tr -d '**' || echo "?")
if [[ "$_count5" == "1" ]]; then
    echo "  PASS: T5: single-entry YAML log reports count 1"
    pass=$((pass + 1))
else
    echo "  FAIL: T5: expected count 1, got '$_count5'" >&2
    fail=$((fail + 1))
fi

# Date range should show a single date (earliest == latest).
check "T5: date 2026-03-07 appears in INDEX" \
    grep -q "2026-03-07" "$proj5/docs/intake-log-INDEX.md"

# ---------------------------------------------------------------------------
# T6: Run gen-register-index against the repo's own intake-log.md if present
# ---------------------------------------------------------------------------
echo ""
echo "-- T6: run against live repo intake-log.md if present --"

_live_intake="$REPO_ROOT/docs/intake-log.md"
if [[ -f "$_live_intake" ]]; then
    _live_out="$(bash "$GEN_INDEX" "docs/intake-log.md" --root "$REPO_ROOT" --dry-run 2>&1)" || true
    # Should not error.
    if printf '%s' "$_live_out" | grep -qiE '(error|command not found)'; then
        echo "  FAIL: T6: gen-register-index errored on live intake-log.md" >&2
        printf '        output: %s\n' "$_live_out" >&2
        fail=$((fail + 1))
    else
        # Extract total count from dry-run output.
        _live_count=$(printf '%s' "$_live_out" | awk '/^\*\*Total entries/{print $NF}' | tr -d '**' || echo "?")
        if [[ "$_live_count" == "0" && -s "$_live_intake" ]]; then
            echo "  FAIL: T6: live intake-log.md is non-empty but index reports 0 entries" >&2
            fail=$((fail + 1))
        else
            echo "  PASS: T6: live intake-log.md indexed without error (count=$_live_count)"
            pass=$((pass + 1))
        fi
    fi
else
    echo "  SKIP: T6 — $REPO_ROOT/docs/intake-log.md not present"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "PASS: $pass"
echo "FAIL: $fail"
if [[ "$fail" -gt 0 ]]; then
    exit 1
fi
exit 0
