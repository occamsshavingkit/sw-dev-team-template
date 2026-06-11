#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# tests/upgrade/test-trivial-structural-delta.sh — FW-ADR-0028 Item 1 coverage
# for _is_trivial_structural_delta() and its call site in scripts/upgrade.sh.
#
# Cases (integration):
#   (a) +1 blank line; upstream lacks it         → auto-merge structural
#   (b) +3 blank lines within cap (<=10)         → auto-merge structural
#   (c) +1 # comment line; upstream lacks it     → auto-merge structural
#   (d) +11 blank lines (above cap)              → falls through → conflict
#   (e) +1 blank + 1 substantive line            → falls through → conflict
#                                                   (regression guard)
#   (f) deletion + blank add                     → falls through (deletions)
#   (g) +1 blank; dry-run mode                   → "[dry-run] would auto-merge
#                                                   (trivial structural delta): <path>"
#                                                   printed; file NOT written
#   (h) +1 SPDX line upstream has                → SPDX classifier fires first;
#                                                   auto-merge SPDX (not structural)
#   (i) +1 SPDX line upstream lacks + blank      → SPDX falls through; structural
#                                                   fires on blank-only remainder
#                                                   when remainder is purely blank
#
# Static checks:
#   static-1  _is_trivial_structural_delta function defined in upgrade.sh
#   static-2  dry-run call site does NOT gate on "dry_run -eq 0"
#             (grep absence check for the old guard pattern)
#
# Integration approach: SWDT_PRESTAGED_WORKDIR + SWDT_BOOTSTRAPPED=1 ephemeral
# mktemp fixture (same pattern as test-spdx-trivial-delta.sh).

set -u

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
upgrade="$repo_root/scripts/upgrade.sh"

tmp="$(mktemp -d -t structural-delta-XXXXXX)"
keep=0
[[ "${1:-}" == "--keep" ]] && keep=1
trap 'if [[ $keep -eq 0 ]]; then rm -rf "$tmp"; else echo "(kept $tmp for inspection)" >&2; fi' EXIT

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

# ---------------------------------------------------------------------------
# sha256 helper
# ---------------------------------------------------------------------------
file_sha256() {
  sha256sum "$1" 2>/dev/null | awk '{print $1}' \
  || shasum -a 256 "$1" 2>/dev/null | awk '{print $1}'
}

# ---------------------------------------------------------------------------
# Fixture factory (identical signature to test-spdx-trivial-delta.sh helpers)
# ---------------------------------------------------------------------------

make_upstream_repo() {
  local dir="$1" tag="$2" file_path="$3" file_content="$4"
  rm -rf "$dir"
  mkdir -p "$dir/$(dirname "$file_path")"
  (
    cd "$dir"
    git init -b main -q
    git config user.email structural-test-upstream@example.invalid
    git config user.name "Structural Test Upstream"
    printf '%s\n' "$tag" > VERSION
    printf '%s' "$file_content" > "$file_path"
    git add VERSION "$file_path"
    git commit -q -m "release $tag"
    git tag "$tag"
  )
}

make_baseline_repo() {
  local dst="$1" upstream="$2" ref="$3"
  rm -rf "$dst"
  git clone -q "$upstream" "$dst" 2>/dev/null
  git -C "$dst" checkout -q "$ref" 2>/dev/null
}

make_project() {
  local dir="$1" old_sha="$2" new_version="$3" file_path="$4" proj_content="$5"
  local baseline_file="${6:-}"
  local old_version="v1.0.0-rc9"
  rm -rf "$dir"
  mkdir -p "$dir/$(dirname "$file_path")"
  (
    cd "$dir"
    git init -b main -q
    git config user.email structural-test-project@example.invalid
    git config user.name "Structural Test Project"
    printf '%s\n%s\n%s\n' "$old_version" "$old_sha" "2026-01-01" > TEMPLATE_VERSION
    printf '%s' "$proj_content" > "$file_path"
    git add TEMPLATE_VERSION "$file_path"
    git commit -q -m "fixture init"
  )
  local sha
  if [[ -n "$baseline_file" && -f "$baseline_file" ]]; then
    sha="$(file_sha256 "$baseline_file")"
  else
    sha="$(file_sha256 "$dir/$file_path")"
  fi
  {
    echo "# TEMPLATE_MANIFEST.lock — auto-generated"
    echo "$sha  $file_path"
  } > "$dir/TEMPLATE_MANIFEST.lock"
}

make_prestaged_workdir() {
  local wdir="$1" new_repo="$2" old_repo="$3"
  rm -rf "$wdir"
  mkdir -p "$wdir"
  cp -a "$new_repo" "$wdir/new"
  cp -a "$old_repo" "$wdir/old"
}

run_upgrade() {
  local proj_dir="$1" workdir="$2" log="$3"
  local extra_args="${4:-}"
  local rc=0
  (
    cd "$proj_dir"
    SWDT_BOOTSTRAPPED=1 \
    SWDT_PRESTAGED_WORKDIR="$workdir" \
      bash "$upgrade" $extra_args 2>&1
  ) > "$log" 2>&1 || rc=$?
  echo "$rc"
}

# ---------------------------------------------------------------------------
# Shared constants
# ---------------------------------------------------------------------------
UPSTREAM_NEW_TAG="v1.0.0-rc14"
TEST_FILE="scripts/test-structural-fixture.sh"

# Baseline: no blank lines or comment additions (pure functional content).
BASELINE_CONTENT='#!/usr/bin/env bash
# A test script used as structural upgrade fixture.
echo "hello"
'

# Upstream: has a functional change the project does not (ensures project != upstream).
UPSTREAM_CONTENT_BASE='#!/usr/bin/env bash
# A test script used as structural upgrade fixture.
# upstream added this line in the new release
echo "hello"
'

# ---------------------------------------------------------------------------
# Static checks
# ---------------------------------------------------------------------------
echo "-- structural-delta static checks --"

check "static-1: _is_trivial_structural_delta defined in upgrade.sh" \
  grep -q "_is_trivial_structural_delta()" "$upgrade"

# The old guard was: && $dry_run -eq 0 ]] on the same line as the spdx call.
# After the fix, neither classifier call site should be gated that way.
# We check absence of the combined pattern in the call-site region.
check "static-2: trivial-spdx call site no longer has dry_run -eq 0 guard" \
  bash -c "! grep -A3 '_is_trivial_spdx_delta' '$upgrade' | grep -q 'dry_run -eq 0'"

# ---------------------------------------------------------------------------
# Case (a): +1 blank line; upstream does NOT contain it → auto-merge structural
# ---------------------------------------------------------------------------
echo ""
echo "-- structural case (a): +1 blank line, upstream lacks it → auto-merge --"

PROJ_CONTENT_A='#!/usr/bin/env bash
# A test script used as structural upgrade fixture.

echo "hello"
'

upstream_a="$tmp/a-upstream"
baseline_a="$tmp/a-baseline"
workdir_a="$tmp/a-workdir"
proj_a="$tmp/a-project"

make_upstream_repo "$upstream_a" "$UPSTREAM_NEW_TAG" "$TEST_FILE" "$UPSTREAM_CONTENT_BASE"
baseline_sha_a="$(git -C "$upstream_a" rev-parse HEAD)"
make_baseline_repo "$baseline_a" "$upstream_a" "$baseline_sha_a"
printf '%s' "$BASELINE_CONTENT" > "$baseline_a/$TEST_FILE"

make_project "$proj_a" "$baseline_sha_a" "$UPSTREAM_NEW_TAG" "$TEST_FILE" "$PROJ_CONTENT_A" "$baseline_a/$TEST_FILE"
make_prestaged_workdir "$workdir_a" "$upstream_a" "$baseline_a"

log_a="$tmp/case-a.log"
rc_a="$(run_upgrade "$proj_a" "$workdir_a" "$log_a")"

check "(a): auto-merge exits 0" \
  bash -c "[ '$rc_a' = '0' ]"
check "(a): log contains 'auto-merged (trivial structural delta):'" \
  bash -c "grep -q 'auto-merged (trivial structural delta):' '$log_a'"
check "(a): log mentions test file path" \
  bash -c "grep -q '$TEST_FILE' '$log_a'"
check "(a): file not listed under Conflicts" \
  bash -c "! grep -q 'Conflicts:' '$log_a' || ! grep -A5 'Conflicts:' '$log_a' | grep -q '$TEST_FILE'"

# ---------------------------------------------------------------------------
# Case (b): +3 blank lines within cap → auto-merge structural
# ---------------------------------------------------------------------------
echo ""
echo "-- structural case (b): +3 blank lines (within cap) → auto-merge --"

PROJ_CONTENT_B='#!/usr/bin/env bash
# A test script used as structural upgrade fixture.



echo "hello"
'

upstream_b="$tmp/b-upstream"
baseline_b="$tmp/b-baseline"
workdir_b="$tmp/b-workdir"
proj_b="$tmp/b-project"

make_upstream_repo "$upstream_b" "$UPSTREAM_NEW_TAG" "$TEST_FILE" "$UPSTREAM_CONTENT_BASE"
baseline_sha_b="$(git -C "$upstream_b" rev-parse HEAD)"
make_baseline_repo "$baseline_b" "$upstream_b" "$baseline_sha_b"
printf '%s' "$BASELINE_CONTENT" > "$baseline_b/$TEST_FILE"

make_project "$proj_b" "$baseline_sha_b" "$UPSTREAM_NEW_TAG" "$TEST_FILE" "$PROJ_CONTENT_B" "$baseline_b/$TEST_FILE"
make_prestaged_workdir "$workdir_b" "$upstream_b" "$baseline_b"

log_b="$tmp/case-b.log"
rc_b="$(run_upgrade "$proj_b" "$workdir_b" "$log_b")"

check "(b): auto-merge exits 0" \
  bash -c "[ '$rc_b' = '0' ]"
check "(b): log contains 'auto-merged (trivial structural delta):'" \
  bash -c "grep -q 'auto-merged (trivial structural delta):' '$log_b'"

# ---------------------------------------------------------------------------
# Case (c): +1 # comment line; upstream does NOT contain it → auto-merge structural
# ---------------------------------------------------------------------------
echo ""
echo "-- structural case (c): +1 # comment line, upstream lacks it → auto-merge --"

PROJ_CONTENT_C='#!/usr/bin/env bash
# A test script used as structural upgrade fixture.
# local section divider comment added by project
echo "hello"
'

upstream_c="$tmp/c-upstream"
baseline_c="$tmp/c-baseline"
workdir_c="$tmp/c-workdir"
proj_c="$tmp/c-project"

make_upstream_repo "$upstream_c" "$UPSTREAM_NEW_TAG" "$TEST_FILE" "$UPSTREAM_CONTENT_BASE"
baseline_sha_c="$(git -C "$upstream_c" rev-parse HEAD)"
make_baseline_repo "$baseline_c" "$upstream_c" "$baseline_sha_c"
printf '%s' "$BASELINE_CONTENT" > "$baseline_c/$TEST_FILE"

make_project "$proj_c" "$baseline_sha_c" "$UPSTREAM_NEW_TAG" "$TEST_FILE" "$PROJ_CONTENT_C" "$baseline_c/$TEST_FILE"
make_prestaged_workdir "$workdir_c" "$upstream_c" "$baseline_c"

log_c="$tmp/case-c.log"
rc_c="$(run_upgrade "$proj_c" "$workdir_c" "$log_c")"

check "(c): auto-merge exits 0" \
  bash -c "[ '$rc_c' = '0' ]"
check "(c): log contains 'auto-merged (trivial structural delta):'" \
  bash -c "grep -q 'auto-merged (trivial structural delta):' '$log_c'"

# ---------------------------------------------------------------------------
# Case (d): +11 blank lines (above cap of 10) → falls through → conflict
# ---------------------------------------------------------------------------
echo ""
echo "-- structural case (d): +11 blank lines (>10 cap) → falls through → conflict --"

# 11 blank lines between the comment and echo (above cap of 10).
# Built with printf to avoid editor/heredoc blank-line collapsing.
PROJ_CONTENT_D="$(printf '%s\n' \
  '#!/usr/bin/env bash' \
  '# A test script used as structural upgrade fixture.' \
  '' '' '' '' '' '' '' '' '' '' '' \
  'echo "hello"')"
PROJ_CONTENT_D="${PROJ_CONTENT_D}"$'\n'

upstream_d="$tmp/d-upstream"
baseline_d="$tmp/d-baseline"
workdir_d="$tmp/d-workdir"
proj_d="$tmp/d-project"

make_upstream_repo "$upstream_d" "$UPSTREAM_NEW_TAG" "$TEST_FILE" "$UPSTREAM_CONTENT_BASE"
baseline_sha_d="$(git -C "$upstream_d" rev-parse HEAD)"
make_baseline_repo "$baseline_d" "$upstream_d" "$baseline_sha_d"
printf '%s' "$BASELINE_CONTENT" > "$baseline_d/$TEST_FILE"

make_project "$proj_d" "$baseline_sha_d" "$UPSTREAM_NEW_TAG" "$TEST_FILE" "$PROJ_CONTENT_D" "$baseline_d/$TEST_FILE"
make_prestaged_workdir "$workdir_d" "$upstream_d" "$baseline_d"

log_d="$tmp/case-d.log"
rc_d="$(run_upgrade "$proj_d" "$workdir_d" "$log_d")"

check "(d): 11-blank-line delta classified as conflict" \
  bash -c "grep -q 'Conflicts' '$log_d'"
check "(d): no structural auto-merged log line" \
  bash -c "! grep -q 'auto-merged (trivial structural delta):' '$log_d'"

# ---------------------------------------------------------------------------
# Case (e): +1 blank + 1 substantive line → falls through → conflict
#           REGRESSION GUARD: substantive addition must not auto-merge.
# ---------------------------------------------------------------------------
echo ""
echo "-- structural case (e): +1 blank +1 substantive line → conflict (regression guard) --"

PROJ_CONTENT_E='#!/usr/bin/env bash
# A test script used as structural upgrade fixture.

custom_function() { echo "I am substantive"; }
echo "hello"
'

upstream_e="$tmp/e-upstream"
baseline_e="$tmp/e-baseline"
workdir_e="$tmp/e-workdir"
proj_e="$tmp/e-project"

make_upstream_repo "$upstream_e" "$UPSTREAM_NEW_TAG" "$TEST_FILE" "$UPSTREAM_CONTENT_BASE"
baseline_sha_e="$(git -C "$upstream_e" rev-parse HEAD)"
make_baseline_repo "$baseline_e" "$upstream_e" "$baseline_sha_e"
printf '%s' "$BASELINE_CONTENT" > "$baseline_e/$TEST_FILE"

make_project "$proj_e" "$baseline_sha_e" "$UPSTREAM_NEW_TAG" "$TEST_FILE" "$PROJ_CONTENT_E" "$baseline_e/$TEST_FILE"
make_prestaged_workdir "$workdir_e" "$upstream_e" "$baseline_e"

log_e="$tmp/case-e.log"
rc_e="$(run_upgrade "$proj_e" "$workdir_e" "$log_e")"

check "(e) regression guard: blank+substantive line classified as conflict" \
  bash -c "grep -q 'Conflicts' '$log_e'"
check "(e) regression guard: no structural auto-merged log line" \
  bash -c "! grep -q 'auto-merged (trivial structural delta):' '$log_e'"
check "(e) regression guard: no SPDX auto-merged log line" \
  bash -c "! grep -q 'auto-merged (trivial SPDX delta):' '$log_e'"

# ---------------------------------------------------------------------------
# Case (f): deletion + blank add → falls through (deletions present, rule 2)
# ---------------------------------------------------------------------------
echo ""
echo "-- structural case (f): deletion + blank add → falls through (deletions) --"

BASELINE_CONTENT_F='#!/usr/bin/env bash
# A test script used as structural upgrade fixture.
# This line will be deleted.
echo "hello"
'
# Project: removes the "will be deleted" line, adds a blank line instead.
PROJ_CONTENT_F='#!/usr/bin/env bash
# A test script used as structural upgrade fixture.

echo "hello"
'

upstream_f="$tmp/f-upstream"
baseline_f="$tmp/f-baseline"
workdir_f="$tmp/f-workdir"
proj_f="$tmp/f-project"

make_upstream_repo "$upstream_f" "$UPSTREAM_NEW_TAG" "$TEST_FILE" "$UPSTREAM_CONTENT_BASE"
baseline_sha_f="$(git -C "$upstream_f" rev-parse HEAD)"
make_baseline_repo "$baseline_f" "$upstream_f" "$baseline_sha_f"
printf '%s' "$BASELINE_CONTENT_F" > "$baseline_f/$TEST_FILE"

make_project "$proj_f" "$baseline_sha_f" "$UPSTREAM_NEW_TAG" "$TEST_FILE" "$PROJ_CONTENT_F" "$baseline_f/$TEST_FILE"
make_prestaged_workdir "$workdir_f" "$upstream_f" "$baseline_f"

log_f="$tmp/case-f.log"
rc_f="$(run_upgrade "$proj_f" "$workdir_f" "$log_f")"

check "(f): deletion+blank-add classified as conflict" \
  bash -c "grep -q 'Conflicts' '$log_f'"
check "(f): no structural auto-merged log line" \
  bash -c "! grep -q 'auto-merged (trivial structural delta):' '$log_f'"

# ---------------------------------------------------------------------------
# Case (g): +1 blank; dry-run mode
#           → "[dry-run] would auto-merge (trivial structural delta): <path>" printed
#           → file NOT written (project file still has the blank line)
# ---------------------------------------------------------------------------
echo ""
echo "-- structural case (g): +1 blank, dry-run → would-auto-merge log, no write --"

PROJ_CONTENT_G='#!/usr/bin/env bash
# A test script used as structural upgrade fixture.

echo "hello"
'

upstream_g="$tmp/g-upstream"
baseline_g="$tmp/g-baseline"
workdir_g="$tmp/g-workdir"
proj_g="$tmp/g-project"

make_upstream_repo "$upstream_g" "$UPSTREAM_NEW_TAG" "$TEST_FILE" "$UPSTREAM_CONTENT_BASE"
baseline_sha_g="$(git -C "$upstream_g" rev-parse HEAD)"
make_baseline_repo "$baseline_g" "$upstream_g" "$baseline_sha_g"
printf '%s' "$BASELINE_CONTENT" > "$baseline_g/$TEST_FILE"

make_project "$proj_g" "$baseline_sha_g" "$UPSTREAM_NEW_TAG" "$TEST_FILE" "$PROJ_CONTENT_G" "$baseline_g/$TEST_FILE"
make_prestaged_workdir "$workdir_g" "$upstream_g" "$baseline_g"

log_g="$tmp/case-g.log"
rc_g="$(run_upgrade "$proj_g" "$workdir_g" "$log_g" "--dry-run")"

check "(g): dry-run exits 0" \
  bash -c "[ '$rc_g' = '0' ]"
check "(g): log contains '[dry-run] would auto-merge (trivial structural delta):'" \
  bash -c "grep -q '\[dry-run\] would auto-merge (trivial structural delta):' '$log_g'"
check "(g): project file still contains the blank line (not written)" \
  bash -c "grep -c '^$' '$proj_g/$TEST_FILE' | grep -q '[1-9]'"
# Verify the project file has NOT been overwritten with upstream content
# (upstream has "upstream added this line" which baseline/project do not).
check "(g): project file does NOT contain upstream-only content (no write)" \
  bash -c "! grep -q 'upstream added this line' '$proj_g/$TEST_FILE'"

# ---------------------------------------------------------------------------
# Case (h): +1 SPDX line upstream HAS → SPDX classifier fires first (not structural)
# ---------------------------------------------------------------------------
echo ""
echo "-- structural case (h): +1 SPDX line upstream has → SPDX fires (not structural) --"

UPSTREAM_CONTENT_H='# SPDX-License-Identifier: MIT
#!/usr/bin/env bash
# A test script used as structural upgrade fixture.
# upstream added this line in the new release
echo "hello"
'
PROJ_CONTENT_H='# SPDX-License-Identifier: MIT
#!/usr/bin/env bash
# A test script used as structural upgrade fixture.
echo "hello"
'

upstream_h="$tmp/h-upstream"
baseline_h="$tmp/h-baseline"
workdir_h="$tmp/h-workdir"
proj_h="$tmp/h-project"

make_upstream_repo "$upstream_h" "$UPSTREAM_NEW_TAG" "$TEST_FILE" "$UPSTREAM_CONTENT_H"
baseline_sha_h="$(git -C "$upstream_h" rev-parse HEAD)"
make_baseline_repo "$baseline_h" "$upstream_h" "$baseline_sha_h"
printf '%s' "$BASELINE_CONTENT" > "$baseline_h/$TEST_FILE"

make_project "$proj_h" "$baseline_sha_h" "$UPSTREAM_NEW_TAG" "$TEST_FILE" "$PROJ_CONTENT_H" "$baseline_h/$TEST_FILE"
make_prestaged_workdir "$workdir_h" "$upstream_h" "$baseline_h"

log_h="$tmp/case-h.log"
rc_h="$(run_upgrade "$proj_h" "$workdir_h" "$log_h")"

check "(h): SPDX auto-merge exits 0" \
  bash -c "[ '$rc_h' = '0' ]"
check "(h): SPDX classifier fires (log contains 'auto-merged (trivial SPDX delta):')" \
  bash -c "grep -q 'auto-merged (trivial SPDX delta):' '$log_h'"
check "(h): structural classifier does NOT fire" \
  bash -c "! grep -q 'auto-merged (trivial structural delta):' '$log_h'"

# ---------------------------------------------------------------------------
# Case (i): +1 SPDX line upstream LACKS + 1 blank line
#           → SPDX falls through (upstream-containment fails for SPDX line)
#           → structural fires only if ALL added lines are blank/comment
#           Here: SPDX line fails structural rule 3 (SPDX line is a comment
#           and DOES match the # pattern), so structural fires → auto-merge.
#           This confirms the structural classifier catches comment-adds that
#           the SPDX classifier rejected solely on upstream-containment.
# ---------------------------------------------------------------------------
echo ""
echo "-- structural case (i): +1 SPDX line upstream lacks + blank → structural fires --"

# Upstream does NOT have the SPDX line.
UPSTREAM_CONTENT_I='#!/usr/bin/env bash
# A test script used as structural upgrade fixture.
# upstream added this line in the new release
echo "hello"
'
# Project adds an SPDX line (upstream lacks it) AND a blank line.
# SPDX classifier: rejects (upstream-containment fails for SPDX line).
# Structural classifier: SPDX line is "^# ..." which matches ^[[:space:]]*(#)
#   → both added lines pass rule 3 → structural fires.
PROJ_CONTENT_I='# SPDX-License-Identifier: MIT
#!/usr/bin/env bash
# A test script used as structural upgrade fixture.

echo "hello"
'

upstream_i="$tmp/i-upstream"
baseline_i="$tmp/i-baseline"
workdir_i="$tmp/i-workdir"
proj_i="$tmp/i-project"

make_upstream_repo "$upstream_i" "$UPSTREAM_NEW_TAG" "$TEST_FILE" "$UPSTREAM_CONTENT_I"
baseline_sha_i="$(git -C "$upstream_i" rev-parse HEAD)"
make_baseline_repo "$baseline_i" "$upstream_i" "$baseline_sha_i"
printf '%s' "$BASELINE_CONTENT" > "$baseline_i/$TEST_FILE"

make_project "$proj_i" "$baseline_sha_i" "$UPSTREAM_NEW_TAG" "$TEST_FILE" "$PROJ_CONTENT_I" "$baseline_i/$TEST_FILE"
make_prestaged_workdir "$workdir_i" "$upstream_i" "$baseline_i"

log_i="$tmp/case-i.log"
rc_i="$(run_upgrade "$proj_i" "$workdir_i" "$log_i")"

check "(i): structural auto-merge exits 0" \
  bash -c "[ '$rc_i' = '0' ]"
check "(i): structural classifier fires" \
  bash -c "grep -q 'auto-merged (trivial structural delta):' '$log_i'"
check "(i): SPDX classifier does NOT fire" \
  bash -c "! grep -q 'auto-merged (trivial SPDX delta):' '$log_i'"

# ---------------------------------------------------------------------------
# Case (j): project adds a DUPLICATE of an existing substantive baseline line
#           (plus optionally a blank) — safety-boundary explicit regression guard.
#
#           The duplicated line is "echo \"hello\"" — plainly substantive
#           (not blank, not matching the comment-token set).  comm -23 will
#           surface it as an "added" line because sort+comm deduplicates: the
#           sorted project has two copies of the line and the sorted baseline
#           has one, so one copy appears as an addition.  Rule 3 must catch
#           that the added line is not blank/whitespace-only and does not match
#           the bounded comment-token pattern → return 1 → conflict.
#           Also adds a blank line to confirm that the presence of a legitimate
#           blank does not rescue a batch that contains a substantive addition.
# ---------------------------------------------------------------------------
echo ""
echo "-- structural case (j): duplicate substantive line + blank → conflict (S-2 safety guard) --"

# Project: duplicate the "echo hello" line and add a blank.
# Baseline has: shebang, comment, echo "hello" (3 lines + trailing newline).
# Project adds:  the same "echo \"hello\"" line again + a blank line.
# comm will report "echo \"hello\"" as an added line (extra copy).
# Rule 3 rejects "echo \"hello\"" (not blank, not a comment token).
PROJ_CONTENT_J='#!/usr/bin/env bash
# A test script used as structural upgrade fixture.
echo "hello"

echo "hello"
'

upstream_j="$tmp/j-upstream"
baseline_j="$tmp/j-baseline"
workdir_j="$tmp/j-workdir"
proj_j="$tmp/j-project"

make_upstream_repo "$upstream_j" "$UPSTREAM_NEW_TAG" "$TEST_FILE" "$UPSTREAM_CONTENT_BASE"
baseline_sha_j="$(git -C "$upstream_j" rev-parse HEAD)"
make_baseline_repo "$baseline_j" "$upstream_j" "$baseline_sha_j"
printf '%s' "$BASELINE_CONTENT" > "$baseline_j/$TEST_FILE"

make_project "$proj_j" "$baseline_sha_j" "$UPSTREAM_NEW_TAG" "$TEST_FILE" "$PROJ_CONTENT_J" "$baseline_j/$TEST_FILE"
make_prestaged_workdir "$workdir_j" "$upstream_j" "$baseline_j"

log_j="$tmp/case-j.log"
rc_j="$(run_upgrade "$proj_j" "$workdir_j" "$log_j")"

check "(j) S-2 safety guard: duplicate substantive line classified as conflict" \
  bash -c "grep -q 'Conflicts' '$log_j'"
check "(j) S-2 safety guard: no structural auto-merged log line" \
  bash -c "! grep -q 'auto-merged (trivial structural delta):' '$log_j'"
check "(j) S-2 safety guard: no SPDX auto-merged log line" \
  bash -c "! grep -q 'auto-merged (trivial SPDX delta):' '$log_j'"

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
