#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# tests/numbering/test-reserve-number.sh — harness for claim-first numbering
# reservation helper (specs/015-claim-first-numbering/).
#
# Structure
# ---------
# Phase 1 (S1–S4): sandbox creation and helper-presence sanity assertions.
# Phase 2 (US1): behavioral cases covering all artifact types, collision
#   avoidance, gap-not-reused, no-renumber, offline, dry-run, no-overwrite,
#   and malformed-register. All phases are shipped and passing.
#
# ---------------------------------------------------------------------------
# Sandbox / helper invocation design
# ---------------------------------------------------------------------------
# The helper scripts/reserve-number.sh reads the on-disk artifact layout to
# compute next(family): it scans docs/adr/, specs/, and the register files
# docs/OPEN_QUESTIONS.md + docs/DECISIONS.md. Running it against the live
# repo would mutate live stubs and register rows.
#
# All test cases run against a SANDBOX — a tmpdir seeded with a minimal
# fixture tree:
#
#   <sandbox>/
#     docs/adr/
#       fw-adr-0001-init.md          (status: accepted  — highest ADR in use)
#       fw-adr-0002-reserved.md      (status: reserved  — counts as in-use)
#     specs/
#       001-first-spec/spec.md       (Status: Accepted)
#       003-gap-spec/spec.md         (Status: Accepted — 002 is a withdrawn gap)
#     docs/OPEN_QUESTIONS.md        (contains Q-0001 and Q-0002 rows)
#     docs/DECISIONS.md             (contains ## D-0001 and ## D-0002 headings)
#
# Expected next numbers for each family at seed time:
#   adr           → 0003  (max in-use = 0002)
#   spec          → 004   (max in-use = 003; 002 gap is not reused)
#   open-question → Q-0003
#   decision      → D-0003
#
# Test cases call:
#   reserve_number <artifact-type> [--slug <slug>] [--dry-run]
# which invokes:
#   bash "$REPO_ROOT/scripts/reserve-number.sh" "$@"
# with PROJECT_ROOT set to $sandbox, and captures stdout/stderr/exit code.
# RESERVE_RC, RESERVE_OUT, RESERVE_ERR are set for assertions.
# ---------------------------------------------------------------------------

set -u

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HELPER="$REPO_ROOT/scripts/reserve-number.sh"

pass=0
fail=0
failures=()
SANDBOXES=()

record_pass() {
    pass=$((pass + 1))
    printf 'PASS  %s\n' "$1"
}

record_fail() {
    fail=$((fail + 1))
    failures+=("$1")
    printf 'FAIL  %s\n' "$1"
    if [ -n "${2:-}" ]; then
        printf '      %s\n' "$2"
    fi
}

cleanup() {
    local sandbox
    for sandbox in "${SANDBOXES[@]}"; do
        rm -rf "$sandbox"
    done
}
trap cleanup EXIT

# make_sandbox: create a minimal fixture repo layout for a test case.
# Sets the shell variable `sandbox` in the caller's scope and registers
# it for cleanup.
#
# Seed layout mirrors the design decision above:
#   docs/adr/fw-adr-0001-init.md       status: accepted
#   docs/adr/fw-adr-0002-reserved.md   status: reserved
#   specs/001-first-spec/spec.md        Status: Accepted
#   specs/003-gap-spec/spec.md          Status: Accepted  (002 is a withdrawn gap)
#   docs/OPEN_QUESTIONS.md              Q-0001 + Q-0002 rows
#   docs/DECISIONS.md                   rows 1 + 2
make_sandbox() {
    sandbox=$(mktemp -d)
    SANDBOXES+=("$sandbox")

    # ADR stubs
    mkdir -p "$sandbox/docs/adr"
    printf -- '---\nstatus: accepted\ntitle: Init\n---\n' \
        > "$sandbox/docs/adr/fw-adr-0001-init.md"
    printf -- '---\nstatus: reserved\ntitle: Reserved placeholder\n---\n' \
        > "$sandbox/docs/adr/fw-adr-0002-reserved.md"

    # Spec dirs (002 intentionally absent — withdrawn gap)
    mkdir -p "$sandbox/specs/001-first-spec"
    printf 'Status: Accepted\n# First spec\n' \
        > "$sandbox/specs/001-first-spec/spec.md"
    mkdir -p "$sandbox/specs/003-gap-spec"
    printf 'Status: Accepted\n# Gap spec (002 withdrawn)\n' \
        > "$sandbox/specs/003-gap-spec/spec.md"

    # Register files
    mkdir -p "$sandbox/docs"
    printf '# Open Questions\n\n| ID | Status | Question |\n|---|---|---|\n| Q-0001 | closed | First question |\n| Q-0002 | open   | Second question |\n' \
        > "$sandbox/docs/OPEN_QUESTIONS.md"
    printf '# Decisions\n\n## D-0001 — 2026-01-01 — First decision\n\n**Who decided:** tech-lead\n**Options considered:** A / B\n**Chose:** A\n**Why:** test seed\n**Files touched:** —\n**Customer visibility:** —\n**Supersedes:** —\n**Notes:** —\n\n## D-0002 — 2026-01-02 — Second decision\n\n**Who decided:** tech-lead\n**Options considered:** A / B\n**Chose:** B\n**Why:** test seed\n**Files touched:** —\n**Customer visibility:** —\n**Supersedes:** —\n**Notes:** —\n' \
        > "$sandbox/docs/DECISIONS.md"
}

# reserve_number: invoke the helper against $sandbox.
# Sets RESERVE_RC, RESERVE_OUT, RESERVE_ERR in the caller's scope.
#
# Usage: reserve_number <artifact-type> [--slug <slug>] [--dry-run] [...]
reserve_number() {
    RESERVE_RC=127
    RESERVE_OUT=""
    RESERVE_ERR=""

    if [[ ! -x "$HELPER" ]]; then
        RESERVE_ERR="helper not found: $HELPER"
        return 0  # caller inspects RESERVE_RC; do not abort the harness
    fi

    local _err_file
    _err_file=$(mktemp)
    set +e
    RESERVE_OUT=$(PROJECT_ROOT="$sandbox" bash "$HELPER" "$@" 2>"$_err_file")
    RESERVE_RC=$?
    set -e
    RESERVE_ERR=$(cat "$_err_file")
    rm -f "$_err_file"
}

# ---------------------------------------------------------------------------
# Sanity assertions (Phase 1)
# ---------------------------------------------------------------------------

# S1: sandbox creates the expected ADR stubs.
make_sandbox
if [[ -f "$sandbox/docs/adr/fw-adr-0001-init.md" && \
      -f "$sandbox/docs/adr/fw-adr-0002-reserved.md" ]]; then
    record_pass "sanity: sandbox seeds fw-adr-0001 and fw-adr-0002"
else
    record_fail "sanity: sandbox seeds fw-adr-0001 and fw-adr-0002" \
        "expected both ADR stubs under $sandbox/docs/adr/"
fi

# S2: sandbox creates the expected spec dirs (with withdrawn gap at 002).
_s2_gap_count=$(find "$sandbox/specs" -maxdepth 1 -type d -name '002-*' 2>/dev/null | wc -l)
if [[ -f "$sandbox/specs/001-first-spec/spec.md" && \
      -f "$sandbox/specs/003-gap-spec/spec.md" && \
      "$_s2_gap_count" -eq 0 ]]; then
    record_pass "sanity: sandbox seeds spec 001 + 003 with gap at 002"
else
    record_fail "sanity: sandbox seeds spec 001 + 003 with gap at 002" \
        "expected 001-first-spec and 003-gap-spec dirs, no 002- dir, under $sandbox/specs/"
fi

# S3: sandbox creates register files with expected seed rows.
_oq_count=$(grep -c 'Q-000' "$sandbox/docs/OPEN_QUESTIONS.md" 2>/dev/null || true)
_dec_count=$(grep -cE '^## D-[0-9]{4}' "$sandbox/docs/DECISIONS.md" 2>/dev/null || true)
if [[ "$_oq_count" -ge 2 && "$_dec_count" -ge 2 ]]; then
    record_pass "sanity: sandbox seeds at least 2 Q- rows and 2 DECISIONS headings"
else
    record_fail "sanity: sandbox seeds at least 2 Q- rows and 2 DECISIONS headings" \
        "OPEN_QUESTIONS Q- rows=$_oq_count DECISIONS D- headings=$_dec_count (expected >=2 each)"
fi

# S4: record whether the helper is present (informational; does not block the suite).
if [[ ! -f "$HELPER" ]]; then
    record_pass "sanity: scripts/reserve-number.sh not yet present (US1 cases will report rc=127)"
else
    record_pass "sanity: scripts/reserve-number.sh exists and is exercised by US1 cases"
fi

# ---------------------------------------------------------------------------
# US1 behavioral cases
# ---------------------------------------------------------------------------

# US1: adr — reserving `adr` returns 0003 and creates docs/adr/fw-adr-0003-*.md
#            with status: reserved (seeded max = 0002).
make_sandbox
reserve_number adr --slug test-adr
_us1_adr_rc=$RESERVE_RC
_us1_adr_out=$RESERVE_OUT
if [[ "$_us1_adr_rc" -eq 0 ]] && \
   echo "$_us1_adr_out" | grep -q '0003' && \
   ls "$sandbox/docs/adr/fw-adr-0003-"*.md >/dev/null 2>&1 && \
   grep -q 'status: reserved' "$sandbox/docs/adr/fw-adr-0003-"*.md 2>/dev/null; then
    record_pass "US1: adr"
else
    record_fail "US1: adr" \
        "rc=$_us1_adr_rc out='$_us1_adr_out' err='$RESERVE_ERR'; expected rc=0, stdout containing 0003, docs/adr/fw-adr-0003-*.md with status: reserved"
fi

# US1: spec — reserving `spec` returns 004 (gap at 002 is NOT reused; max=003+1)
#             and creates specs/004-*/spec.md with Status: Reserved.
make_sandbox
reserve_number spec --slug test-spec
_us1_spec_rc=$RESERVE_RC
_us1_spec_out=$RESERVE_OUT
if [[ "$_us1_spec_rc" -eq 0 ]] && \
   echo "$_us1_spec_out" | grep -q '004' && \
   ls -d "$sandbox/specs/004-"* >/dev/null 2>&1 && \
   grep -qi 'status: reserved' "$sandbox/specs/004-"*/spec.md 2>/dev/null; then
    record_pass "US1: spec"
else
    record_fail "US1: spec" \
        "rc=$_us1_spec_rc out='$_us1_spec_out' err='$RESERVE_ERR'; expected rc=0, stdout containing 004, specs/004-*/spec.md with Status: Reserved"
fi

# US1: open-question — reserving `open-question` returns Q-0003 and appends a
#                      reserved Q-0003 row to docs/OPEN_QUESTIONS.md.
make_sandbox
reserve_number open-question
_us1_oq_rc=$RESERVE_RC
_us1_oq_out=$RESERVE_OUT
if [[ "$_us1_oq_rc" -eq 0 ]] && \
   echo "$_us1_oq_out" | grep -q 'Q-0003' && \
   grep -q 'Q-0003' "$sandbox/docs/OPEN_QUESTIONS.md" && \
   grep -qi 'reserved' "$sandbox/docs/OPEN_QUESTIONS.md"; then
    record_pass "US1: open-question"
else
    record_fail "US1: open-question" \
        "rc=$_us1_oq_rc out='$_us1_oq_out' err='$RESERVE_ERR'; expected rc=0, stdout containing Q-0003, Q-0003 reserved row in docs/OPEN_QUESTIONS.md"
fi

# US1: decision — reserving `decision` returns D-0003 and appends a ## D-0003
#                 reserved heading entry to docs/DECISIONS.md.
make_sandbox
reserve_number decision
_us1_dec_rc=$RESERVE_RC
_us1_dec_out=$RESERVE_OUT
if [[ "$_us1_dec_rc" -eq 0 ]] && \
   echo "$_us1_dec_out" | grep -q 'D-0003' && \
   grep -q '^## D-0003' "$sandbox/docs/DECISIONS.md" && \
   grep -qi 'reserved' "$sandbox/docs/DECISIONS.md"; then
    record_pass "US1: decision"
else
    record_fail "US1: decision" \
        "rc=$_us1_dec_rc out='$_us1_dec_out' err='$RESERVE_ERR'; expected rc=0, stdout containing D-0003, ## D-0003 heading with reserved in docs/DECISIONS.md"
fi

# US1: collision — two consecutive `adr` reservations return distinct consecutive
#                  numbers (0003 then 0004); neither stub is overwritten (SC-001/FR-002/I1/I2).
make_sandbox
reserve_number adr --slug first-collision
_us1_coll_rc1=$RESERVE_RC
_us1_coll_out1=$RESERVE_OUT
reserve_number adr --slug second-collision
_us1_coll_rc2=$RESERVE_RC
_us1_coll_out2=$RESERVE_OUT
if [[ "$_us1_coll_rc1" -eq 0 && "$_us1_coll_rc2" -eq 0 ]] && \
   echo "$_us1_coll_out1" | grep -q '0003' && \
   echo "$_us1_coll_out2" | grep -q '0004' && \
   ls "$sandbox/docs/adr/fw-adr-0003-"*.md >/dev/null 2>&1 && \
   ls "$sandbox/docs/adr/fw-adr-0004-"*.md >/dev/null 2>&1; then
    record_pass "US1: collision"
else
    record_fail "US1: collision" \
        "first: rc=$_us1_coll_rc1 out='$_us1_coll_out1'; second: rc=$_us1_coll_rc2 out='$_us1_coll_out2'; expected 0003 then 0004 with both stubs present"
fi

# US1: counts-reserved — seeded fw-adr-0002 (status: reserved, no authored content)
#                        is counted so the first reservation yields 0003 (FR-002/I4).
#                        (Verified by the same assertion as US1: adr above; this case
#                        makes the invariant explicit as a standalone labelled test.)
make_sandbox
reserve_number adr --slug counts-reserved-check
_us1_cr_rc=$RESERVE_RC
_us1_cr_out=$RESERVE_OUT
if [[ "$_us1_cr_rc" -eq 0 ]] && echo "$_us1_cr_out" | grep -q '0003'; then
    record_pass "US1: counts-reserved"
else
    record_fail "US1: counts-reserved" \
        "rc=$_us1_cr_rc out='$_us1_cr_out' err='$RESERVE_ERR'; expected rc=0 and 0003 (reserved fw-adr-0002 must be counted)"
fi

# US1: no-renumber — after an ADR reservation the pre-existing seeded artifacts
#                    (fw-adr-0001, fw-adr-0002, spec 001/003, Q-0001/0002) are
#                    unchanged (FR-006/I3/SC-003).
make_sandbox
_us1_nr_adr1_before=$(cat "$sandbox/docs/adr/fw-adr-0001-init.md")
_us1_nr_adr2_before=$(cat "$sandbox/docs/adr/fw-adr-0002-reserved.md")
_us1_nr_spec1_before=$(cat "$sandbox/specs/001-first-spec/spec.md")
_us1_nr_spec3_before=$(cat "$sandbox/specs/003-gap-spec/spec.md")
_us1_nr_oq_before=$(cat "$sandbox/docs/OPEN_QUESTIONS.md")
_us1_nr_dec_before=$(cat "$sandbox/docs/DECISIONS.md")
reserve_number adr --slug no-renumber-check
_us1_nr_adr1_after=$(cat "$sandbox/docs/adr/fw-adr-0001-init.md")
_us1_nr_adr2_after=$(cat "$sandbox/docs/adr/fw-adr-0002-reserved.md")
_us1_nr_spec1_after=$(cat "$sandbox/specs/001-first-spec/spec.md")
_us1_nr_spec3_after=$(cat "$sandbox/specs/003-gap-spec/spec.md")
_us1_nr_oq_after=$(cat "$sandbox/docs/OPEN_QUESTIONS.md")
_us1_nr_dec_after=$(cat "$sandbox/docs/DECISIONS.md")
if [[ "$_us1_nr_adr1_before" == "$_us1_nr_adr1_after" && \
      "$_us1_nr_adr2_before" == "$_us1_nr_adr2_after" && \
      "$_us1_nr_spec1_before" == "$_us1_nr_spec1_after" && \
      "$_us1_nr_spec3_before" == "$_us1_nr_spec3_after" && \
      "$_us1_nr_oq_before"    == "$_us1_nr_oq_after"    && \
      "$_us1_nr_dec_before"   == "$_us1_nr_dec_after" ]]; then
    record_pass "US1: no-renumber"
else
    record_fail "US1: no-renumber" \
        "one or more seeded artifacts were modified by the ADR reservation (expected zero mutations to pre-existing files)"
fi

# US1: gap-not-reused — spec reservation returns 004 not 002; the withdrawn gap
#                       at 002 is never backfilled (R2/I5).
make_sandbox
reserve_number spec --slug gap-check
_us1_gnr_rc=$RESERVE_RC
_us1_gnr_out=$RESERVE_OUT
_us1_gnr_002=$(ls -d "$sandbox/specs/002-"* 2>/dev/null | wc -l)
if [[ "$_us1_gnr_rc" -eq 0 ]] && \
   echo "$_us1_gnr_out" | grep -q '004' && \
   [[ "$_us1_gnr_002" -eq 0 ]]; then
    record_pass "US1: gap-not-reused"
else
    record_fail "US1: gap-not-reused" \
        "rc=$_us1_gnr_rc out='$_us1_gnr_out' 002-dirs=$_us1_gnr_002; expected rc=0, stdout 004, no specs/002-* dir created"
fi

# US1: offline — helper succeeds in a bare sandbox with no network/GitHub access.
#                Uses sandbox with only local filesystem; no network calls expected (FR-008/I6).
make_sandbox
reserve_number adr --slug offline-check
_us1_off_rc=$RESERVE_RC
if [[ "$_us1_off_rc" -eq 0 ]]; then
    record_pass "US1: offline"
else
    record_fail "US1: offline" \
        "rc=$_us1_off_rc err='$RESERVE_ERR'; expected rc=0 — helper must succeed with no network (FR-008/I6)"
fi

# US1: dry-run — `--dry-run` prints the next number and writes NOTHING;
#                sandbox state is identical before and after (FR-013/I7).
make_sandbox
_us1_dr_snap_before=$(find "$sandbox" -type f | sort | xargs md5sum 2>/dev/null || find "$sandbox" -type f | sort)
reserve_number adr --slug dry-run-check --dry-run
_us1_dr_rc=$RESERVE_RC
_us1_dr_out=$RESERVE_OUT
_us1_dr_snap_after=$(find "$sandbox" -type f | sort | xargs md5sum 2>/dev/null || find "$sandbox" -type f | sort)
if [[ "$_us1_dr_rc" -eq 0 ]] && \
   echo "$_us1_dr_out" | grep -q '0003' && \
   [[ "$_us1_dr_snap_before" == "$_us1_dr_snap_after" ]]; then
    record_pass "US1: dry-run"
else
    record_fail "US1: dry-run" \
        "rc=$_us1_dr_rc out='$_us1_dr_out'; snapshot_changed=$([ "$_us1_dr_snap_before" != "$_us1_dr_snap_after" ] && echo yes || echo no); expected rc=0, stdout 0003, zero filesystem mutations"
fi

# US1: no-overwrite — the no-overwrite guard fires when the computed target path
#                     already exists on disk (I2/FR-006).
#
# Design: the spec scanner counts only directories (find -type d). Pre-creating
# the next target as a plain FILE (not a directory) makes the scanner skip it
# (max remains 003, next = 004), so the guard's `[[ -e "$spec_dir" ]]` catches
# the collision and exits nonzero before writing anything.
make_sandbox
# Seed a plain file at the path the helper would compute (004-overwrite-target)
touch "$sandbox/specs/004-overwrite-target"
_us1_ow_files_before=$(find "$sandbox/specs" -maxdepth 1 | sort | tr '\n' ':')
reserve_number spec --slug overwrite-target
_us1_ow_rc=$RESERVE_RC
_us1_ow_files_after=$(find "$sandbox/specs" -maxdepth 1 | sort | tr '\n' ':')
if [[ "$_us1_ow_rc" -ne 0 ]] && \
   [[ "$_us1_ow_files_before" == "$_us1_ow_files_after" ]]; then
    record_pass "US1: no-overwrite"
else
    record_fail "US1: no-overwrite" \
        "rc=$_us1_ow_rc (expected nonzero); files_changed=$([ "$_us1_ow_files_before" != "$_us1_ow_files_after" ] && echo yes || echo no) (expected no); err='$RESERVE_ERR'"
fi

# US1: malformed-register (open-question) — helper exits nonzero when
#      docs/OPEN_QUESTIONS.md is absent; no junk files created (I2/FR-006).
make_sandbox
rm -f "$sandbox/docs/OPEN_QUESTIONS.md"
_us1_mr_oq_before=$(find "$sandbox/docs" -maxdepth 1 | sort | tr '\n' ':')
reserve_number open-question
_us1_mr_oq_rc=$RESERVE_RC
_us1_mr_oq_after=$(find "$sandbox/docs" -maxdepth 1 | sort | tr '\n' ':')
if [[ "$_us1_mr_oq_rc" -ne 0 ]] && \
   [[ "$_us1_mr_oq_before" == "$_us1_mr_oq_after" ]]; then
    record_pass "US1: malformed-register (open-question)"
else
    record_fail "US1: malformed-register (open-question)" \
        "rc=$_us1_mr_oq_rc (expected nonzero); files_changed=$([ "$_us1_mr_oq_before" != "$_us1_mr_oq_after" ] && echo yes || echo no) (expected no); err='$RESERVE_ERR'"
fi

# US1: malformed-register (decision) — helper exits nonzero when
#      docs/DECISIONS.md is absent; no junk files created (I2/FR-006).
make_sandbox
rm -f "$sandbox/docs/DECISIONS.md"
_us1_mr_dec_before=$(find "$sandbox/docs" -maxdepth 1 | sort | tr '\n' ':')
reserve_number decision
_us1_mr_dec_rc=$RESERVE_RC
_us1_mr_dec_after=$(find "$sandbox/docs" -maxdepth 1 | sort | tr '\n' ':')
if [[ "$_us1_mr_dec_rc" -ne 0 ]] && \
   [[ "$_us1_mr_dec_before" == "$_us1_mr_dec_after" ]]; then
    record_pass "US1: malformed-register (decision)"
else
    record_fail "US1: malformed-register (decision)" \
        "rc=$_us1_mr_dec_rc (expected nonzero); files_changed=$([ "$_us1_mr_dec_before" != "$_us1_mr_dec_after" ] && echo yes || echo no) (expected no); err='$RESERVE_ERR'"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
printf '\nSummary: %s passed, %s failed\n' "$pass" "$fail"
if [ "$fail" -ne 0 ]; then
    printf 'Failures:\n'
    printf ' - %s\n' "${failures[@]}"
    exit 1
fi
exit 0
