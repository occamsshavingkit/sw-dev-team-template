#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# tests/upgrade/test-spdx-trivial-delta.sh — issue #262 SPDX trivial-delta
# auto-merge coverage for scripts/upgrade.sh.
#
# Tests the _is_trivial_spdx_delta() function and its call site in the
# per-file sync loop.
#
# Cases:
#   (a) Local = baseline + 1 SPDX line; upstream contains that line.
#       → auto-merge takes upstream; log line emitted.
#   (b) Local = baseline + 2 SPDX lines + 1 Copyright line; upstream
#       contains all three. → auto-merge.
#   (c) Local = baseline + 1 SPDX line + 1 non-SPDX comment edit.
#       → falls through (rule 4 violation — line count wrong).
#   (d) Local = baseline + 6 SPDX lines (above the <=5 cap).
#       → falls through (rule 2 violation).
#   (e) Local = baseline - 1 deleted line + 1 SPDX add.
#       → falls through (rule 3 violation — deletions present).
#   (f) Local trivial SPDX, but upstream does NOT contain those lines.
#       → falls through (upstream containment check fails).
#   (g) Local = baseline exactly (no modification). → existing fast-path,
#       untouched (file upgraded normally, no conflict).
#   (h) Local has substantial changes (canonical conflict case).
#       → falls through, classified as conflict (regression guard).
#   (i) Log line content exactly matches "auto-merged (trivial SPDX delta): <path>".
#
# Static checks (code-presence):
#   (static-1) _is_trivial_spdx_delta function is defined in upgrade.sh.
#   (static-2) Call site references _is_trivial_spdx_delta.
#   (static-3) Log line literal "auto-merged (trivial SPDX delta):" present.
#   (static-4) Issue #262 cited in upgrade.sh.
#
# Integration approach: build a minimal self-contained fixture using
# SWDT_PRESTAGED_WORKDIR + SWDT_BOOTSTRAPPED=1 to skip the self-bootstrap
# re-exec and point directly at pre-staged workdir/new + workdir/old.
# Each case constructs:
#   workdir/new  — upstream git repo at "new_tag"
#   workdir/old  — baseline git repo at "old_tag" (baseline SHA)
#   project      — downstream git repo with TEMPLATE_VERSION + TEMPLATE_MANIFEST.lock

set -u

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
upgrade="$repo_root/scripts/upgrade.sh"
manifest_lib="$repo_root/scripts/lib/manifest.sh"

tmp="$(mktemp -d -t spdx-trivial-delta-XXXXXX)"
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

run_capture() {
  local log="$1"; shift
  local rc=0
  "$@" > "$log" 2>&1 || rc=$?
  echo "$rc"
}

# ---------------------------------------------------------------------------
# Static checks
# ---------------------------------------------------------------------------
echo "-- #262 static checks --"

check "#262 static-1: _is_trivial_spdx_delta function defined in upgrade.sh" \
  grep -q "_is_trivial_spdx_delta()" "$upgrade"

check "#262 static-2: call site references _is_trivial_spdx_delta" \
  grep -q "_is_trivial_spdx_delta" "$upgrade"

check "#262 static-3: log line literal present in upgrade.sh" \
  grep -q 'auto-merged (trivial SPDX delta):' "$upgrade"

check "#262 static-4: Issue #262 cited in upgrade.sh" \
  grep -q "Issue #262" "$upgrade"

# ---------------------------------------------------------------------------
# Fixture factory helpers
# ---------------------------------------------------------------------------

# sha256 of a file (portable: works with sha256sum or shasum -a 256)
file_sha256() {
  sha256sum "$1" 2>/dev/null | awk '{print $1}' \
  || shasum -a 256 "$1" 2>/dev/null | awk '{print $1}'
}

# Make a minimal upstream git repo containing a single test file at $file_path
# with content $file_content, tagged with $tag_name.
# Sets global: upstream_sha (commit SHA of the tag)
make_upstream_repo() {
  local dir="$1" tag="$2" file_path="$3" file_content="$4"
  rm -rf "$dir"
  mkdir -p "$dir/$(dirname "$file_path")"
  (
    cd "$dir"
    git init -b main -q
    git config user.email spdx-test-upstream@example.invalid
    git config user.name "SPDX Test Upstream"
    printf '%s\n' "$tag" > VERSION
    printf '%s' "$file_content" > "$file_path"
    git add VERSION "$file_path"
    git commit -q -m "release $tag"
    git tag "$tag"
  )
}

# Make a minimal baseline git repo (workdir/old) from an existing upstream
# repo by cloning it. Checks out $baseline_sha.
# Usage: make_baseline_repo <dst_dir> <upstream_dir> <sha_or_tag>
make_baseline_repo() {
  local dst="$1" upstream="$2" ref="$3"
  rm -rf "$dst"
  git clone -q "$upstream" "$dst" 2>/dev/null
  git -C "$dst" checkout -q "$ref" 2>/dev/null
}

# Make a downstream project fixture.
# $1 dir          — project directory to create
# $2 old_sha      — baseline commit sha (for TEMPLATE_VERSION line 2)
# $3 new_version  — upstream new tag (what we're upgrading to)
# $4 file_path    — test file path (relative to project root)
# $5 proj_content — content to write into the project's copy of the file
# $6 baseline_file — path to the baseline copy of the file (for manifest SHA)
#
# Writes TEMPLATE_VERSION and TEMPLATE_MANIFEST.lock.
# The manifest must record the BASELINE SHA (what was installed at scaffold),
# not the project's modified SHA — otherwise upgrade.sh treats any deviation
# as an already-accepted local merge and bypasses the conflict classifier.
make_project() {
  local dir="$1" old_sha="$2" new_version="$3" file_path="$4" proj_content="$5"
  local baseline_file="${6:-}"
  local old_version="v1.0.0-rc9"  # fixture "previous" version
  rm -rf "$dir"
  mkdir -p "$dir/$(dirname "$file_path")"
  (
    cd "$dir"
    git init -b main -q
    git config user.email spdx-test-project@example.invalid
    git config user.name "SPDX Test Project"
    printf '%s\n%s\n%s\n' "$old_version" "$old_sha" "2026-01-01" > TEMPLATE_VERSION
    printf '%s' "$proj_content" > "$file_path"
    git add TEMPLATE_VERSION "$file_path"
    git commit -q -m "fixture init"
  )
  # Write TEMPLATE_MANIFEST.lock with the BASELINE file SHA, not the project SHA.
  # The manifest records what was last synced from upstream, so the classifier
  # can tell whether the project file matches what was installed (accepted merge)
  # or has drifted further (potential conflict).
  local sha
  if [[ -n "$baseline_file" && -f "$baseline_file" ]]; then
    sha="$(file_sha256 "$baseline_file")"
  else
    # Fallback: use the project file's SHA (may cause accepted_via_manifest path).
    sha="$(file_sha256 "$dir/$file_path")"
  fi
  {
    echo "# TEMPLATE_MANIFEST.lock — auto-generated"
    echo "$sha  $file_path"
  } > "$dir/TEMPLATE_MANIFEST.lock"
}

# Build a prestaged workdir from pre-built upstream and baseline repos.
# $1 workdir base  $2 upstream dir  $3 baseline dir
make_prestaged_workdir() {
  local wdir="$1" new_repo="$2" old_repo="$3"
  rm -rf "$wdir"
  mkdir -p "$wdir"
  # upgrade.sh checks for SWDT_PRESTAGED_WORKDIR/new being a directory
  cp -a "$new_repo" "$wdir/new"
  cp -a "$old_repo" "$wdir/old"
}

# Run upgrade.sh for a case, return exit code, output in $log.
run_upgrade() {
  local proj_dir="$1" workdir="$2" log="$3"
  local rc=0
  (
    cd "$proj_dir"
    SWDT_BOOTSTRAPPED=1 \
    SWDT_PRESTAGED_WORKDIR="$workdir" \
      bash "$upgrade" 2>&1
  ) > "$log" 2>&1 || rc=$?
  echo "$rc"
}

# ---------------------------------------------------------------------------
# Test file setup.
#
# The auto-merge path requires:
#   baseline: old content (no SPDX header)
#   project:  old content + SPDX header added locally
#   upstream: new content = SPDX header + old content + upstream functional changes
#
# This models the real-world scenario: the user added SPDX headers between
# rc-versions, and upstream independently made changes AND added the same
# SPDX headers. The heuristic detects that the only diff between project and
# baseline is the SPDX header(s), which upstream already has, and auto-merges.
# ---------------------------------------------------------------------------
BASELINE_CONTENT='#!/usr/bin/env bash
# A test script used as upgrade fixture.
echo "hello"
'

# Upstream has SPDX header AND a functional change (new comment).
# This ensures project != upstream (so files_match returns false) while
# still satisfying the trivial-SPDX heuristic.
UPSTREAM_CONTENT_WITH_SPDX_AND_CHANGE='# SPDX-License-Identifier: MIT
#!/usr/bin/env bash
# A test script used as upgrade fixture.
# upstream added this line in the new release
echo "hello"
'

UPSTREAM_NEW_TAG="v1.0.0-rc14"
TEST_FILE="scripts/test-fixture.sh"

# ---------------------------------------------------------------------------
# Case (a): local = baseline + 1 SPDX line; upstream contains that line
#           AND has additional content. → auto-merge; log line emitted.
# ---------------------------------------------------------------------------
echo ""
echo "-- #262 case (a): +1 SPDX line, upstream contains it + more → auto-merge --"

# Project added the SPDX header but not the upstream's new functional line.
PROJ_CONTENT_A='# SPDX-License-Identifier: MIT
#!/usr/bin/env bash
# A test script used as upgrade fixture.
echo "hello"
'

upstream_a="$tmp/a-upstream"
baseline_a="$tmp/a-baseline"
workdir_a="$tmp/a-workdir"
proj_a="$tmp/a-project"

make_upstream_repo "$upstream_a" "$UPSTREAM_NEW_TAG" "$TEST_FILE" "$UPSTREAM_CONTENT_WITH_SPDX_AND_CHANGE"
baseline_sha_a="$(git -C "$upstream_a" rev-parse HEAD)"
make_baseline_repo "$baseline_a" "$upstream_a" "$baseline_sha_a"
# Baseline content: the pre-SPDX version (no SPDX, no upstream change).
printf '%s' "$BASELINE_CONTENT" > "$baseline_a/$TEST_FILE"

make_project "$proj_a" "$baseline_sha_a" "$UPSTREAM_NEW_TAG" "$TEST_FILE" "$PROJ_CONTENT_A" "$baseline_a/$TEST_FILE"
make_prestaged_workdir "$workdir_a" "$upstream_a" "$baseline_a"

log_a="$tmp/case-a.log"
rc_a="$(run_upgrade "$proj_a" "$workdir_a" "$log_a")"

check "(a): auto-merge exits 0" \
  bash -c "[ '$rc_a' = '0' ]"
check "(a): log contains 'auto-merged (trivial SPDX delta):'" \
  bash -c "grep -q 'auto-merged (trivial SPDX delta):' '$log_a'"
check "(a): log mentions the test file path" \
  bash -c "grep -q '$TEST_FILE' '$log_a'"
check "(a): file not listed under Conflicts" \
  bash -c "! grep -q 'Conflicts:' '$log_a' || ! grep -A5 'Conflicts:' '$log_a' | grep -q '$TEST_FILE'"

# ---------------------------------------------------------------------------
# Case (b): local = baseline + 2 SPDX lines + 1 Copyright line;
#           upstream contains all three. → auto-merge.
# ---------------------------------------------------------------------------
echo ""
echo "-- #262 case (b): +2 SPDX + 1 Copyright; upstream has all → auto-merge --"

UPSTREAM_CONTENT_B='# SPDX-License-Identifier: MIT
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 contributors
#!/usr/bin/env bash
# A test script used as upgrade fixture.
# upstream added this line in the new release
echo "hello"
'
PROJ_CONTENT_B='# SPDX-License-Identifier: MIT
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 contributors
#!/usr/bin/env bash
# A test script used as upgrade fixture.
echo "hello"
'

upstream_b="$tmp/b-upstream"
baseline_b="$tmp/b-baseline"
workdir_b="$tmp/b-workdir"
proj_b="$tmp/b-project"

make_upstream_repo "$upstream_b" "$UPSTREAM_NEW_TAG" "$TEST_FILE" "$UPSTREAM_CONTENT_B"
baseline_sha_b="$(git -C "$upstream_b" rev-parse HEAD)"
make_baseline_repo "$baseline_b" "$upstream_b" "$baseline_sha_b"
printf '%s' "$BASELINE_CONTENT" > "$baseline_b/$TEST_FILE"

make_project "$proj_b" "$baseline_sha_b" "$UPSTREAM_NEW_TAG" "$TEST_FILE" "$PROJ_CONTENT_B" "$baseline_b/$TEST_FILE"
make_prestaged_workdir "$workdir_b" "$upstream_b" "$baseline_b"

log_b="$tmp/case-b.log"
rc_b="$(run_upgrade "$proj_b" "$workdir_b" "$log_b")"

check "(b): auto-merge exits 0" \
  bash -c "[ '$rc_b' = '0' ]"
check "(b): log contains auto-merged log line" \
  bash -c "grep -q 'auto-merged (trivial SPDX delta):' '$log_b'"

# ---------------------------------------------------------------------------
# Case (c): local = baseline + 1 SPDX line + 1 non-SPDX addition.
#           → falls through (rule 1 violation: non-SPDX line added).
# ---------------------------------------------------------------------------
echo ""
echo "-- #262 case (c): +1 SPDX + non-SPDX addition → falls through (rule 1) --"

# Project has an extra comment line that is NOT SPDX/Copyright.
PROJ_CONTENT_C='# SPDX-License-Identifier: MIT
#!/usr/bin/env bash
# A test script used as upgrade fixture.
# extra non-SPDX comment added by project
echo "hello"
'

upstream_c="$tmp/c-upstream"
baseline_c="$tmp/c-baseline"
workdir_c="$tmp/c-workdir"
proj_c="$tmp/c-project"

make_upstream_repo "$upstream_c" "$UPSTREAM_NEW_TAG" "$TEST_FILE" "$UPSTREAM_CONTENT_WITH_SPDX_AND_CHANGE"
baseline_sha_c="$(git -C "$upstream_c" rev-parse HEAD)"
make_baseline_repo "$baseline_c" "$upstream_c" "$baseline_sha_c"
printf '%s' "$BASELINE_CONTENT" > "$baseline_c/$TEST_FILE"

make_project "$proj_c" "$baseline_sha_c" "$UPSTREAM_NEW_TAG" "$TEST_FILE" "$PROJ_CONTENT_C" "$baseline_c/$TEST_FILE"
make_prestaged_workdir "$workdir_c" "$upstream_c" "$baseline_c"

log_c="$tmp/case-c.log"
rc_c="$(run_upgrade "$proj_c" "$workdir_c" "$log_c")"

check "(c): non-SPDX addition classified as conflict (conflict message in log)" \
  bash -c "grep -q 'Conflicts' '$log_c'"
check "(c): no auto-merged log line emitted" \
  bash -c "! grep -q 'auto-merged (trivial SPDX delta):' '$log_c'"

# ---------------------------------------------------------------------------
# Case (d): local = baseline + 6 SPDX lines (above <=5 cap).
#           → falls through (rule 2 violation).
# ---------------------------------------------------------------------------
echo ""
echo "-- #262 case (d): +6 SPDX lines (>5 cap) → falls through (rule 2) --"

PROJ_CONTENT_D='# SPDX-License-Identifier: MIT
# SPDX-License-Identifier: MIT-0
# SPDX-License-Identifier: Apache-2.0
# SPDX-License-Identifier: BSD-2-Clause
# SPDX-License-Identifier: BSD-3-Clause
# SPDX-License-Identifier: GPL-2.0-only
#!/usr/bin/env bash
# A test script used as upgrade fixture.
echo "hello"
'

UPSTREAM_CONTENT_D='# SPDX-License-Identifier: MIT
# SPDX-License-Identifier: MIT-0
# SPDX-License-Identifier: Apache-2.0
# SPDX-License-Identifier: BSD-2-Clause
# SPDX-License-Identifier: BSD-3-Clause
# SPDX-License-Identifier: GPL-2.0-only
#!/usr/bin/env bash
# A test script used as upgrade fixture.
# upstream added this line in the new release
echo "hello"
'

upstream_d="$tmp/d-upstream"
baseline_d="$tmp/d-baseline"
workdir_d="$tmp/d-workdir"
proj_d="$tmp/d-project"

make_upstream_repo "$upstream_d" "$UPSTREAM_NEW_TAG" "$TEST_FILE" "$UPSTREAM_CONTENT_D"
baseline_sha_d="$(git -C "$upstream_d" rev-parse HEAD)"
make_baseline_repo "$baseline_d" "$upstream_d" "$baseline_sha_d"
printf '%s' "$BASELINE_CONTENT" > "$baseline_d/$TEST_FILE"

make_project "$proj_d" "$baseline_sha_d" "$UPSTREAM_NEW_TAG" "$TEST_FILE" "$PROJ_CONTENT_D" "$baseline_d/$TEST_FILE"
make_prestaged_workdir "$workdir_d" "$upstream_d" "$baseline_d"

log_d="$tmp/case-d.log"
rc_d="$(run_upgrade "$proj_d" "$workdir_d" "$log_d")"

check "(d): 6-SPDX-line addition classified as conflict (conflict message in log)" \
  bash -c "grep -q 'Conflicts' '$log_d'"
check "(d): no auto-merged log line emitted" \
  bash -c "! grep -q 'auto-merged (trivial SPDX delta):' '$log_d'"

# ---------------------------------------------------------------------------
# Case (e): local = baseline - 1 deleted line + 1 SPDX add.
#           → falls through (rule 3: deletions present).
# ---------------------------------------------------------------------------
echo ""
echo "-- #262 case (e): deletion + SPDX add → falls through (rule 3) --"

# Baseline has 4 lines; project removes one line and adds a SPDX header.
BASELINE_CONTENT_E='#!/usr/bin/env bash
# A test script used as upgrade fixture.
# This line will be deleted.
echo "hello"
'
PROJ_CONTENT_E='# SPDX-License-Identifier: MIT
#!/usr/bin/env bash
# A test script used as upgrade fixture.
echo "hello"
'
# Upstream has SPDX header AND an additional change, ensuring project != upstream.
UPSTREAM_CONTENT_E='# SPDX-License-Identifier: MIT
#!/usr/bin/env bash
# A test script used as upgrade fixture.
# upstream added this line in the new release
echo "hello"
'

upstream_e="$tmp/e-upstream"
baseline_e="$tmp/e-baseline"
workdir_e="$tmp/e-workdir"
proj_e="$tmp/e-project"

make_upstream_repo "$upstream_e" "$UPSTREAM_NEW_TAG" "$TEST_FILE" "$UPSTREAM_CONTENT_E"
baseline_sha_e="$(git -C "$upstream_e" rev-parse HEAD)"
make_baseline_repo "$baseline_e" "$upstream_e" "$baseline_sha_e"
printf '%s' "$BASELINE_CONTENT_E" > "$baseline_e/$TEST_FILE"

make_project "$proj_e" "$baseline_sha_e" "$UPSTREAM_NEW_TAG" "$TEST_FILE" "$PROJ_CONTENT_E" "$baseline_e/$TEST_FILE"
make_prestaged_workdir "$workdir_e" "$upstream_e" "$baseline_e"

log_e="$tmp/case-e.log"
rc_e="$(run_upgrade "$proj_e" "$workdir_e" "$log_e")"

check "(e): deletion+SPDX add classified as conflict (conflict message in log)" \
  bash -c "grep -q 'Conflicts' '$log_e'"
check "(e): no auto-merged log line emitted" \
  bash -c "! grep -q 'auto-merged (trivial SPDX delta):' '$log_e'"

# ---------------------------------------------------------------------------
# Case (f): local trivial SPDX delta, but upstream does NOT contain those lines.
#           → falls through (upstream containment check fails).
# ---------------------------------------------------------------------------
echo ""
echo "-- #262 case (f): trivial SPDX, upstream lacks those lines → falls through --"

PROJ_CONTENT_F='# SPDX-License-Identifier: MIT
#!/usr/bin/env bash
# A test script used as upgrade fixture.
echo "hello"
'
# Upstream does NOT have the SPDX line.
UPSTREAM_CONTENT_F='#!/usr/bin/env bash
# A test script used as upgrade fixture.
echo "hello"
# upstream added a different change here
'

upstream_f="$tmp/f-upstream"
baseline_f="$tmp/f-baseline"
workdir_f="$tmp/f-workdir"
proj_f="$tmp/f-project"

make_upstream_repo "$upstream_f" "$UPSTREAM_NEW_TAG" "$TEST_FILE" "$UPSTREAM_CONTENT_F"
baseline_sha_f="$(git -C "$upstream_f" rev-parse HEAD)"
make_baseline_repo "$baseline_f" "$upstream_f" "$baseline_sha_f"
printf '%s' "$BASELINE_CONTENT" > "$baseline_f/$TEST_FILE"

make_project "$proj_f" "$baseline_sha_f" "$UPSTREAM_NEW_TAG" "$TEST_FILE" "$PROJ_CONTENT_F" "$baseline_f/$TEST_FILE"
make_prestaged_workdir "$workdir_f" "$upstream_f" "$baseline_f"

log_f="$tmp/case-f.log"
rc_f="$(run_upgrade "$proj_f" "$workdir_f" "$log_f")"

check "(f): upstream-lacks-SPDX classified as conflict (conflict message in log)" \
  bash -c "grep -q 'Conflicts' '$log_f'"
check "(f): no auto-merged log line emitted" \
  bash -c "! grep -q 'auto-merged (trivial SPDX delta):' '$log_f'"

# ---------------------------------------------------------------------------
# Case (g): local = baseline exactly (no modification).
#           → existing fast-path: file upgraded silently, no conflict.
#           This is the normal unchanged-since-scaffold upgrade path.
# ---------------------------------------------------------------------------
echo ""
echo "-- #262 case (g): no modification → existing fast-path, no conflict --"

# Upstream has the SPDX header; baseline and project have the same content
# (neither has the header yet — project matches baseline).
UPSTREAM_CONTENT_G='# SPDX-License-Identifier: MIT
#!/usr/bin/env bash
# A test script used as upgrade fixture.
echo "hello"
'

upstream_g="$tmp/g-upstream"
baseline_g="$tmp/g-baseline"
workdir_g="$tmp/g-workdir"
proj_g="$tmp/g-project"

make_upstream_repo "$upstream_g" "$UPSTREAM_NEW_TAG" "$TEST_FILE" "$UPSTREAM_CONTENT_G"
baseline_sha_g="$(git -C "$upstream_g" rev-parse HEAD)"
make_baseline_repo "$baseline_g" "$upstream_g" "$baseline_sha_g"
# Baseline and project both have the pre-header content.
printf '%s' "$BASELINE_CONTENT" > "$baseline_g/$TEST_FILE"

make_project "$proj_g" "$baseline_sha_g" "$UPSTREAM_NEW_TAG" "$TEST_FILE" "$BASELINE_CONTENT" "$baseline_g/$TEST_FILE"
make_prestaged_workdir "$workdir_g" "$upstream_g" "$baseline_g"

log_g="$tmp/case-g.log"
rc_g="$(run_upgrade "$proj_g" "$workdir_g" "$log_g")"

check "(g): unchanged-since-scaffold exits 0" \
  bash -c "[ '$rc_g' = '0' ]"
check "(g): no conflict reported" \
  bash -c "! grep -q 'Conflicts:' '$log_g'"
check "(g): no auto-merged log line (fast-path, not the SPDX path)" \
  bash -c "! grep -q 'auto-merged (trivial SPDX delta):' '$log_g'"

# ---------------------------------------------------------------------------
# Case (h): local has substantial changes (current canonical conflict case).
#           → falls through to conflicts[], regression guard for existing behaviour.
# ---------------------------------------------------------------------------
echo ""
echo "-- #262 case (h): substantial local changes → conflict (regression guard) --"

PROJ_CONTENT_H='#!/usr/bin/env bash
# A test script SUBSTANTIALLY MODIFIED by the project.
# Added 3 lines of custom logic.
custom_function() { echo "custom"; }
echo "hello from modified script"
'
UPSTREAM_CONTENT_H='#!/usr/bin/env bash
# A test script used as upgrade fixture.
# Upstream made its own changes here.
echo "hello from upstream v2"
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

check "(h): substantial change classified as conflict (conflict message in log)" \
  bash -c "grep -q 'Conflicts' '$log_h'"
check "(h): no auto-merged log line emitted" \
  bash -c "! grep -q 'auto-merged (trivial SPDX delta):' '$log_h'"

# ---------------------------------------------------------------------------
# Case (i): Verify log line content exactly matches the spec.
#           Reuse case (a) log output.
# ---------------------------------------------------------------------------
echo ""
echo "-- #262 case (i): log line format exact match --"

check "(i): log line is 'auto-merged (trivial SPDX delta): scripts/test-fixture.sh'" \
  bash -c "grep -qF 'auto-merged (trivial SPDX delta): scripts/test-fixture.sh' '$log_a'"

# ---------------------------------------------------------------------------
# Case (j): Issue #269 — auto-merged file appears in its own
#           "Auto-merged (trivial SPDX delta)" summary bucket, not under
#           "unchanged since scaffold". Reuse case (a) log output.
# ---------------------------------------------------------------------------
echo ""
echo "-- #269 case (j): summary report label for auto-merged file --"

check "(j): summary contains 'Auto-merged (trivial SPDX delta)' bucket header" \
  bash -c "grep -qF 'Auto-merged (trivial SPDX delta)' '$log_a'"
check "(j): auto-merged file listed as bare filename under new bucket" \
  bash -c "grep -qE '^  ~ scripts/test-fixture\.sh$' '$log_a'"
check "(j): auto-merged file NOT listed under 'unchanged since scaffold' bucket" \
  bash -c "! grep -qF 'Upgraded in place — unchanged since scaffold' '$log_a' || ! grep -A100 'Upgraded in place — unchanged since scaffold' '$log_a' | grep -qF 'scripts/test-fixture.sh'"

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
