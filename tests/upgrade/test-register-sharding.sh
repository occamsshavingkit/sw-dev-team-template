#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# tests/upgrade/test-register-sharding.sh — tests for fw-adr-0025 Option S
# (date-quarter register sharding).
#
# Cases:
#   T1. gen-register-index.sh emits a valid INDEX.md for a register with
#       active file + one shard + one archive.
#   T2. archive-registers.sh --quarter-roll moves old entries to a shard,
#       leaves current-quarter entries in the active file, regenerates INDEX.
#   T3. reserve-number.sh does NOT reuse a Q-ID that lives in a shard.
#   T4. check-duplicate-ids.sh flags a Q-ID that appears in both the active
#       file and a shard (cross-shard duplicate).
#   T5. migrations/v1.3.0.sh splits a fixture >150KB by date; no entries
#       lost; idempotent (second run is a no-op).
#
# All fixtures are throwaway; the live registers are never touched.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GEN_INDEX="$REPO_ROOT/scripts/gen-register-index.sh"
ARCHIVE_SH="$REPO_ROOT/scripts/archive-registers.sh"
RESERVE="$REPO_ROOT/scripts/reserve-number.sh"
DUP_CHECK="$REPO_ROOT/scripts/check-duplicate-ids.sh"
MIGRATION="$REPO_ROOT/migrations/v1.3.0.sh"

tmp="$(mktemp -d -t reg-shard-XXXXXX)"
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
    local label="$1"; shift
    local pattern="$1"; shift
    local out
    out=$("$@" 2>&1) || true
    if printf '%s' "$out" | grep -qF "$pattern"; then
        echo "  PASS: $label"
        pass=$((pass + 1))
    else
        echo "  FAIL: $label (pattern='$pattern' not found)" >&2
        echo "        output: $out" >&2
        fail=$((fail + 1))
    fi
}

# ---------------------------------------------------------------------------
# Build minimal register fixtures
# ---------------------------------------------------------------------------

# A minimal OPEN_QUESTIONS.md table with entries from two different quarters.
make_oq() {
    local path="$1"
    mkdir -p "$(dirname "$path")"
    cat > "$path" <<'EOF'
# Open Questions register

| ID | Opened | Question | Blocked on | Answerer | Status | Resolution |
|---|---|---|---|---|---|---|
| Q-0001 | 2025-10-15 | Old question 1 | — | tech-lead | answered | Done. 2025-11-01 |
| Q-0002 | 2025-12-01 | Old question 2 | — | customer | answered | Done. 2026-01-10 |
| Q-0003 | 2026-04-01 | Current question | — | customer | open | — |
EOF
}

# An OPEN_QUESTIONS quarter shard (2025-Q4).
make_oq_shard() {
    local path="$1"
    mkdir -p "$(dirname "$path")"
    cat > "$path" <<'EOF'
# OPEN_QUESTIONS — 2025-Q4 quarter shard

| ID | Opened | Question | Blocked on | Answerer | Status | Resolution |
|---|---|---|---|---|---|---|
| Q-0010 | 2025-10-01 | Archived Q10 | — | customer | answered | Done. 2025-11-15 |
EOF
}

# A minimal OPEN_QUESTIONS-ARCHIVE.md (legacy milestone archive).
make_oq_archive() {
    local path="$1"
    mkdir -p "$(dirname "$path")"
    cat > "$path" <<'EOF'
# OPEN_QUESTIONS archive

| Q-0020 | 2025-08-01 | Very old question | — | researcher | answered | Done. 2025-09-01 |
<!-- archived 2026-01-01 by archive-registers.sh -->
EOF
}

# ---------------------------------------------------------------------------
# T1: gen-register-index.sh produces a valid INDEX.md
# ---------------------------------------------------------------------------
echo "-- T1: gen-register-index.sh produces INDEX.md --"

proj1="$tmp/proj1"
mkdir -p "$proj1/docs"
make_oq         "$proj1/docs/OPEN_QUESTIONS.md"
make_oq_shard   "$proj1/docs/OPEN_QUESTIONS-2025-Q4.md"
make_oq_archive "$proj1/docs/OPEN_QUESTIONS-ARCHIVE.md"

bash "$GEN_INDEX" "docs/OPEN_QUESTIONS.md" --root "$proj1"
check "T1: INDEX.md created" test -f "$proj1/docs/OPEN_QUESTIONS-INDEX.md"
check "T1: INDEX contains Shard column header" \
    grep -q "| Shard |" "$proj1/docs/OPEN_QUESTIONS-INDEX.md"
check "T1: INDEX lists active file" \
    grep -q "OPEN_QUESTIONS.md" "$proj1/docs/OPEN_QUESTIONS-INDEX.md"
check "T1: INDEX lists quarter shard 2025-Q4" \
    grep -q "2025-Q4" "$proj1/docs/OPEN_QUESTIONS-INDEX.md"
check "T1: INDEX lists legacy archive" \
    grep -q "ARCHIVE" "$proj1/docs/OPEN_QUESTIONS-INDEX.md"
# Idempotency: second run overwrites cleanly.
bash "$GEN_INDEX" "docs/OPEN_QUESTIONS.md" --root "$proj1"
check "T1: INDEX still present after re-run (idempotent)" \
    test -f "$proj1/docs/OPEN_QUESTIONS-INDEX.md"

# ---------------------------------------------------------------------------
# T2: archive-registers.sh --quarter-roll moves old entries to shard
# ---------------------------------------------------------------------------
echo ""
echo "-- T2: --quarter-roll moves old entries to shard --"

proj2="$tmp/proj2"
mkdir -p "$proj2/docs"
make_oq "$proj2/docs/OPEN_QUESTIONS.md"
# Also need SCHEDULE.md so --milestone-close is derived, or we bypass it
# entirely since --quarter-roll runs independently of milestone-close.

# Count rows before.
rows_before=$(grep -c '^| Q-' "$proj2/docs/OPEN_QUESTIONS.md" || echo 0)

# Run quarter-roll for 2025-Q4 (entries with Opened < 2026-01-01 go to shard).
bash "$ARCHIVE_SH" --quarter-roll 2025-Q4 \
    --milestone-close 2025-09-01 \
    --root "$proj2" >/dev/null 2>&1 || true

check "T2: shard file created" test -f "$proj2/docs/OPEN_QUESTIONS-2025-Q4.md"
check "T2: Q-0001 moved to shard (2025-10-15 < 2026-01-01)" \
    grep -q "Q-0001" "$proj2/docs/OPEN_QUESTIONS-2025-Q4.md"
check "T2: Q-0002 moved to shard (2025-12-01 < 2026-01-01)" \
    grep -q "Q-0002" "$proj2/docs/OPEN_QUESTIONS-2025-Q4.md"
check "T2: Q-0003 remains in active file (2026-04-01 >= 2026-01-01)" \
    grep -q "Q-0003" "$proj2/docs/OPEN_QUESTIONS.md"
check "T2: Q-0001 not in active file after roll" \
    bash -c "! grep -q 'Q-0001' '$proj2/docs/OPEN_QUESTIONS.md'"
check "T2: INDEX regenerated by quarter-roll" \
    test -f "$proj2/docs/OPEN_QUESTIONS-INDEX.md"

# T2 idempotency: re-run quarter-roll — no duplication in shard.
shard_rows_before=$(grep -c '^| Q-' "$proj2/docs/OPEN_QUESTIONS-2025-Q4.md" || echo 0)
bash "$ARCHIVE_SH" --quarter-roll 2025-Q4 \
    --milestone-close 2025-09-01 \
    --root "$proj2" >/dev/null 2>&1 || true
shard_rows_after=$(grep -c '^| Q-' "$proj2/docs/OPEN_QUESTIONS-2025-Q4.md" || echo 0)
check "T2: idempotent — no duplicate rows in shard after re-roll" \
    bash -c "[ '$shard_rows_before' = '$shard_rows_after' ]"

# ---------------------------------------------------------------------------
# T3: reserve-number.sh does NOT reuse a Q-ID from a shard
# ---------------------------------------------------------------------------
echo ""
echo "-- T3: reserve-number.sh skips IDs in shards --"

proj3="$tmp/proj3"
mkdir -p "$proj3/docs"
# Active file has Q-0001 and Q-0002.
cat > "$proj3/docs/OPEN_QUESTIONS.md" <<'EOF'
# Open Questions register

| ID | Opened | Question | Blocked on | Answerer | Status | Resolution |
|---|---|---|---|---|---|---|
| Q-0001 | 2026-01-01 | Current Q1 | — | customer | open | — |
| Q-0002 | 2026-02-01 | Current Q2 | — | customer | open | — |
EOF

# Shard has Q-0003 (highest so far across all files).
make_oq_shard "$proj3/docs/OPEN_QUESTIONS-2025-Q4.md"
# Override shard to have Q-0003.
cat > "$proj3/docs/OPEN_QUESTIONS-2025-Q4.md" <<'EOF'
# OPEN_QUESTIONS — 2025-Q4 quarter shard

| ID | Opened | Question | Blocked on | Answerer | Status | Resolution |
|---|---|---|---|---|---|---|
| Q-0003 | 2025-10-01 | Archived Q3 | — | customer | answered | Done. 2025-11-01 |
EOF

out=$(PROJECT_ROOT="$proj3" bash "$RESERVE" open-question --dry-run 2>&1)
check "T3: next ID is Q-0004 (not Q-0003 which is in shard)" \
    bash -c "printf '%s' '$out' | grep -q 'Q-0004'"

# ---------------------------------------------------------------------------
# T4: check-duplicate-ids.sh flags cross-shard duplicate
# ---------------------------------------------------------------------------
echo ""
echo "-- T4: check-duplicate-ids.sh detects cross-shard duplicate --"

proj4="$tmp/proj4"
mkdir -p "$proj4/docs"
# Active file has Q-0001.
cat > "$proj4/docs/OPEN_QUESTIONS.md" <<'EOF'
# Open Questions

| ID | Opened | Question | Blocked on | Answerer | Status | Resolution |
|---|---|---|---|---|---|---|
| Q-0001 | 2026-01-01 | Current question | — | customer | open | — |
EOF

# Shard ALSO has Q-0001 (intentional cross-shard duplicate for test).
cat > "$proj4/docs/OPEN_QUESTIONS-2025-Q4.md" <<'EOF'
# OPEN_QUESTIONS — 2025-Q4 quarter shard

| ID | Opened | Question | Blocked on | Answerer | Status | Resolution |
|---|---|---|---|---|---|---|
| Q-0001 | 2025-10-01 | Same ID as active | — | customer | answered | Done. 2025-11-01 |
EOF

# Stub out other families so check-duplicate-ids.sh has no other complaints.
mkdir -p "$proj4/docs/adr" "$proj4/specs"
printf '' > "$proj4/docs/DECISIONS.md"

rc4=0
PROJECT_ROOT="$proj4" bash "$DUP_CHECK" >/dev/null 2>&1 || rc4=$?
check "T4: exits nonzero on cross-shard duplicate Q-0001" \
    bash -c "[ '$rc4' -ne 0 ]"

# Clean tree (no cross-shard dup) should exit 0.
cat > "$proj4/docs/OPEN_QUESTIONS-2025-Q4.md" <<'EOF'
# OPEN_QUESTIONS — 2025-Q4 quarter shard

| ID | Opened | Question | Blocked on | Answerer | Status | Resolution |
|---|---|---|---|---|---|---|
| Q-0002 | 2025-10-01 | Different ID | — | customer | answered | Done. 2025-11-01 |
EOF

rc4b=0
PROJECT_ROOT="$proj4" bash "$DUP_CHECK" >/dev/null 2>&1 || rc4b=$?
check "T4: exits 0 when no cross-shard duplicate" \
    bash -c "[ '$rc4b' -eq 0 ]"

# ---------------------------------------------------------------------------
# T5: migrations/v1.3.0.sh splits a large register; no entries lost; idempotent
# ---------------------------------------------------------------------------
echo ""
echo "-- T5: migration v1.3.0 splits large register --"

proj5="$tmp/proj5"
mkdir -p "$proj5/docs" "$proj5/docs/pm"

# Generate a synthetic OPEN_QUESTIONS.md > 150KB with entries from 3 quarters.
# Use long text in each row so the file reaches the threshold.
python3 - "$proj5/docs/OPEN_QUESTIONS.md" <<'PYEOF'
import sys
path = sys.argv[1]
padding = "x" * 400  # long resolution column to bulk up file size
rows = []
rows.append("# Open Questions register\n\n")
rows.append("| ID | Opened | Question | Blocked on | Answerer | Status | Resolution |\n")
rows.append("|---|---|---|---|---|---|---|\n")
# ~300 rows from 2025-Q1 (old) — each row ~500+ bytes
for i in range(1, 301):
    rows.append(f"| Q-{i:04d} | 2025-02-{(i%28)+1:02d} | Old question {i} — detailed context about this question | blocking:T{i:03d} | customer | answered | Done. 2025-03-01. {padding} |\n")
# ~50 rows from current quarter (keep in active)
for i in range(301, 351):
    rows.append(f"| Q-{i:04d} | 2026-04-{(i%28)+1:02d} | Current question {i} | — | customer | open | — |\n")
with open(path, 'w') as f:
    f.writelines(rows)
PYEOF

sz=$(wc -c < "$proj5/docs/OPEN_QUESTIONS.md")
check "T5: fixture > 150KB" bash -c "[ '$sz' -gt '153600' ]"

# Count total rows before migration.
rows_before=$(grep -c '^| Q-' "$proj5/docs/OPEN_QUESTIONS.md")

# Add minimal stubs for other registers so migration doesn't error.
for reg in docs/intake-log.md docs/pm/RISKS.md docs/pm/LESSONS.md CUSTOMER_NOTES.md; do
    printf '# %s\n\n' "$(basename "$reg" .md)" > "$proj5/$reg"
done

PROJECT_ROOT="$proj5" bash "$MIGRATION" 2>&1 | head -20

# Count total rows across active + shards after migration.
rows_after=0
for f in "$proj5/docs/OPEN_QUESTIONS.md" "$proj5/docs/OPEN_QUESTIONS-"*.md; do
    [[ -f "$f" ]] || continue
    [[ "$f" == *-INDEX.md ]] && continue
    c=$(grep -c '^| Q-' "$f" 2>/dev/null || echo 0)
    rows_after=$((rows_after + c))
done

check "T5: no entries lost after sharding" \
    bash -c "[ '$rows_before' -eq '$rows_after' ]"
check "T5: INDEX generated" \
    test -f "$proj5/docs/OPEN_QUESTIONS-INDEX.md"
# At least one shard created.
check "T5: at least one quarter shard created" \
    bash -c "ls '$proj5/docs/OPEN_QUESTIONS-'[0-9][0-9][0-9][0-9]-Q[1-4].md 2>/dev/null | grep -q ."
# Current quarter entries remain in active file.
check "T5: current-quarter entries remain in active file" \
    grep -q "Q-0301" "$proj5/docs/OPEN_QUESTIONS.md"

# Idempotency: re-run should not duplicate rows.
PROJECT_ROOT="$proj5" bash "$MIGRATION" >/dev/null 2>&1
rows_after2=0
for f in "$proj5/docs/OPEN_QUESTIONS.md" "$proj5/docs/OPEN_QUESTIONS-"*.md; do
    [[ -f "$f" ]] || continue
    [[ "$f" == *-INDEX.md ]] && continue
    c=$(grep -c '^| Q-' "$f" 2>/dev/null || echo 0)
    rows_after2=$((rows_after2 + c))
done
check "T5: idempotent — same total rows after second run" \
    bash -c "[ '$rows_after' -eq '$rows_after2' ]"

# ---------------------------------------------------------------------------
# T6: blank lines between table rows do not strand rows in active file (m-2)
# ---------------------------------------------------------------------------
echo ""
echo "-- T6: blank lines between table rows still shard correctly (m-2) --"

proj6="$tmp/proj6"
mkdir -p "$proj6/docs"

# Table with blank lines between some data rows — the old code would break on
# the first blank and send all subsequent rows to the postamble (active file).
# All three old-quarter rows use dates in 2025-Q1 (Jan–Mar).
# The blank lines between them are the m-2 exercise.
# cutoff for 2025-Q1 roll = 2025-04-01 (first day of Q2).
cat > "$proj6/docs/OPEN_QUESTIONS.md" <<'EOF'
# Open Questions register

| ID | Opened | Question | Blocked on | Answerer | Status | Resolution |
|---|---|---|---|---|---|---|
| Q-0001 | 2025-01-15 | Old Q1 row1 | — | customer | answered | Done. 2025-02-01 |

| Q-0002 | 2025-02-10 | Old Q1 row2 | — | customer | answered | Done. 2025-03-01 |

| Q-0003 | 2025-03-20 | Old Q1 row3 | — | customer | answered | Done. 2025-03-25 |
| Q-0004 | 2026-04-01 | Current Q | — | customer | open | — |
EOF

# Add stubs for other registers.
for reg in docs/intake-log.md docs/pm/RISKS.md docs/pm/LESSONS.md CUSTOMER_NOTES.md; do
    mkdir -p "$proj6/$(dirname "$reg")"
    printf '# %s\n\n' "$(basename "$reg" .md)" > "$proj6/$reg"
done

bash "$ARCHIVE_SH" --quarter-roll 2025-Q1 \
    --milestone-close 2025-01-01 \
    --root "$proj6" >/dev/null 2>&1 || true

# All three rows are in 2025-Q1 (cutoff 2025-04-01); all should be in the shard.
check "T6: Q-0001 sharded (not stranded by blank line)" \
    bash -c "[ -f '$proj6/docs/OPEN_QUESTIONS-2025-Q1.md' ] && grep -q 'Q-0001' '$proj6/docs/OPEN_QUESTIONS-2025-Q1.md'"
check "T6: Q-0002 sharded (not stranded by blank line)" \
    bash -c "[ -f '$proj6/docs/OPEN_QUESTIONS-2025-Q1.md' ] && grep -q 'Q-0002' '$proj6/docs/OPEN_QUESTIONS-2025-Q1.md'"
check "T6: Q-0003 sharded (not stranded by blank line)" \
    bash -c "[ -f '$proj6/docs/OPEN_QUESTIONS-2025-Q1.md' ] && grep -q 'Q-0003' '$proj6/docs/OPEN_QUESTIONS-2025-Q1.md'"
check "T6: Q-0004 stays in active file (current quarter)" \
    grep -q "Q-0004" "$proj6/docs/OPEN_QUESTIONS.md"
check "T6: old rows not stranded in active file" \
    bash -c "! grep -q 'Q-0001' '$proj6/docs/OPEN_QUESTIONS.md'"

# Also test migration Python path with blank-line table.
proj6b="$tmp/proj6b"
mkdir -p "$proj6b/docs"
# Same blank-line fixture, but padded past 150KB for the migration path.
python3 - "$proj6b/docs/OPEN_QUESTIONS.md" <<'PYEOF'
import sys
from pathlib import Path
padding = "x" * 800   # longer to ensure > 150KB even with blank lines included
p = Path(sys.argv[1])
rows = ["# Open Questions\n\n",
        "| ID | Opened | Question | Blocked on | Answerer | Status | Resolution |\n",
        "|---|---|---|---|---|---|---|\n"]
# Old quarter rows with blank lines between them — all in 2025-Q1
for i in range(1, 201):
    rows.append(f"| Q-{i:04d} | 2025-02-{(i%28)+1:02d} | Old {i} | — | customer | answered | Done. 2025-03-01. {padding} |\n")
    rows.append("\n")  # blank line after every row (m-2 exercise)
# Current quarter
for i in range(201, 211):
    rows.append(f"| Q-{i:04d} | 2026-04-01 | Current {i} | — | customer | open | — |\n")
p.write_text("".join(rows), encoding='utf-8')
PYEOF

for reg in docs/intake-log.md docs/pm/RISKS.md docs/pm/LESSONS.md CUSTOMER_NOTES.md; do
    mkdir -p "$proj6b/$(dirname "$reg")"
    printf '# %s\n\n' "$(basename "$reg" .md)" > "$proj6b/$reg"
done

total_before_6b=$(grep -c '^| Q-' "$proj6b/docs/OPEN_QUESTIONS.md" || echo 0)
PROJECT_ROOT="$proj6b" bash "$MIGRATION" >/dev/null 2>&1

total_after_6b=0
for f in "$proj6b/docs/OPEN_QUESTIONS.md" "$proj6b/docs/OPEN_QUESTIONS-"[0-9]*.md; do
    [[ -f "$f" ]] || continue
    [[ "$f" == *-INDEX.md ]] && continue
    c=$(grep -c '^| Q-' "$f" 2>/dev/null || echo 0)
    total_after_6b=$((total_after_6b + c))
done

check "T6 migration: no entries lost with blank-line table" \
    bash -c "[ '$total_before_6b' -eq '$total_after_6b' ]"
check "T6 migration: old-quarter rows sharded (not stranded)" \
    bash -c "ls '$proj6b/docs/OPEN_QUESTIONS-'[0-9][0-9][0-9][0-9]-Q[1-4].md 2>/dev/null | grep -q ."

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
