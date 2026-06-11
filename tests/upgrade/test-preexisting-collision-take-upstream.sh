#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# tests/upgrade/test-preexisting-collision-take-upstream.sh
# FW-ADR-0028 Item 2 — pre-existing-path collision take-upstream default.
#
# Cases (ADR Item 4, second table):
#   (a) Collision, no flags → take-upstream; collision_taken_upstream bucket.
#   (b) Collision + --keep-local <path> → local_only_kept; no auto-take.
#   (c) Collision + path in .template-customizations → preserved; no auto-take.
#   (d) Collision, dry-run → "would take upstream" printed; file NOT written.
#   (e) Regression guard: non-collision substantive conflict still conflicts.
#
# Static checks:
#   static-1: --keep-local flag parsed in upgrade.sh.
#   static-2: collision_taken_upstream array declared in upgrade.sh.
#
# Integration approach: SWDT_PRESTAGED_WORKDIR + SWDT_BOOTSTRAPPED=1
# ephemeral-mktemp pattern (same as test-spdx-trivial-delta.sh).
# Does NOT touch tests/release-gate/ fixtures.
# Does NOT run test-gate-fail-each.sh (issue #306).

set -u

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
upgrade="$repo_root/scripts/upgrade.sh"
manifest_lib="$repo_root/scripts/lib/manifest.sh"

tmp="$(mktemp -d -t preexisting-collision-XXXXXX)"
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
# Static checks
# ---------------------------------------------------------------------------
echo "-- static checks --"

check "static-1: --keep-local flag parsed in upgrade.sh" \
  grep -q "\-\-keep-local" "$upgrade"

check "static-2: collision_taken_upstream array declared in upgrade.sh" \
  grep -q "collision_taken_upstream=()" "$upgrade"

# ---------------------------------------------------------------------------
# sha256 of a file (portable)
# ---------------------------------------------------------------------------
file_sha256() {
  sha256sum "$1" 2>/dev/null | awk '{print $1}' \
  || shasum -a 256 "$1" 2>/dev/null | awk '{print $1}'
}

# ---------------------------------------------------------------------------
# make_upstream_repo <dir> <tag> <file_path> <file_content>
# Creates a minimal upstream git repo with one file, tagged.
# Sets global: (none — callers derive SHA via git -C <dir> rev-parse HEAD)
# ---------------------------------------------------------------------------
make_upstream_repo() {
  local dir="$1" tag="$2" file_path="$3" file_content="$4"
  rm -rf "$dir"
  mkdir -p "$dir/$(dirname "$file_path")"
  (
    cd "$dir"
    git init -b main -q
    git config user.email collision-test-upstream@example.invalid
    git config user.name "Collision Test Upstream"
    printf '%s\n' "$tag" > VERSION
    printf '%s' "$file_content" > "$file_path"
    git add VERSION "$file_path"
    git commit -q -m "release $tag"
    git tag "$tag"
  )
}

# make_baseline_repo <dst> <upstream_dir> <sha_or_tag>
# Creates workdir/old by cloning upstream and checking out the given ref.
make_baseline_repo() {
  local dst="$1" upstream="$2" ref="$3"
  rm -rf "$dst"
  git clone -q "$upstream" "$dst" 2>/dev/null
  git -C "$dst" checkout -q "$ref" 2>/dev/null
}

# make_project <dir> <old_sha> <new_version> <file_path> <proj_content>
#              [<baseline_file>]
# Creates a downstream project fixture with TEMPLATE_VERSION +
# TEMPLATE_MANIFEST.lock.  manifest uses <baseline_file> SHA when provided.
make_project() {
  local dir="$1" old_sha="$2" new_version="$3" file_path="$4" proj_content="$5"
  local baseline_file="${6:-}"
  local old_version="v1.0.0-rc9"
  rm -rf "$dir"
  mkdir -p "$dir/$(dirname "$file_path")"
  (
    cd "$dir"
    git init -b main -q
    git config user.email collision-test-project@example.invalid
    git config user.name "Collision Test Project"
    printf '%s\n%s\n%s\n' "$old_version" "$old_sha" "2026-01-01" > TEMPLATE_VERSION
    printf '%s' "$proj_content" > "$file_path"
    git add TEMPLATE_VERSION "$file_path"
    git commit -q -m "fixture init"
  )
  # Write TEMPLATE_MANIFEST.lock.
  # For collision cases the file is ABSENT from baseline (workdir/old never
  # has it), so the manifest also must NOT contain it — otherwise the
  # upgrade classifier would take the accepted_via_manifest fast-path and
  # skip the collision detection altogether.  We intentionally leave the
  # manifest without an entry for the colliding path.
  local sha
  if [[ -n "$baseline_file" && -f "$baseline_file" ]]; then
    sha="$(file_sha256 "$baseline_file")"
    {
      echo "# TEMPLATE_MANIFEST.lock — auto-generated"
      echo "$sha  $file_path"
    } > "$dir/TEMPLATE_MANIFEST.lock"
  else
    {
      echo "# TEMPLATE_MANIFEST.lock — auto-generated"
    } > "$dir/TEMPLATE_MANIFEST.lock"
  fi
}

# make_prestaged_workdir <wdir> <new_repo> <old_repo>
make_prestaged_workdir() {
  local wdir="$1" new_repo="$2" old_repo="$3"
  rm -rf "$wdir"
  mkdir -p "$wdir"
  cp -a "$new_repo" "$wdir/new"
  cp -a "$old_repo" "$wdir/old"
}

# run_upgrade <proj_dir> <workdir> <log> [extra args...]
# Runs upgrade.sh with SWDT_BOOTSTRAPPED=1 + SWDT_PRESTAGED_WORKDIR.
# Echoes the exit code.
run_upgrade() {
  local proj_dir="$1" workdir="$2" log="$3"
  shift 3
  local rc=0
  (
    cd "$proj_dir"
    SWDT_BOOTSTRAPPED=1 \
    SWDT_PRESTAGED_WORKDIR="$workdir" \
      bash "$upgrade" "$@" 2>&1
  ) > "$log" 2>&1 || rc=$?
  echo "$rc"
}

# ---------------------------------------------------------------------------
# Common fixture data
#
# A pre-existing-path collision requires:
#   workdir/old/<f>  — ABSENT  (upstream did not ship this path at baseline)
#   project_root/<f> — PRESENT (project had it before upstream shipped it)
#   workdir/new/<f>  — PRESENT (upstream newly ships it)
#   content differs  (proj != upstream, else files_match fast-path applies)
# ---------------------------------------------------------------------------

UPSTREAM_NEW_TAG="v1.0.0-rc14"
TEST_FILE="scripts/check-spdx.sh"

# What upstream newly ships for the colliding path.
UPSTREAM_FILE_CONTENT='#!/usr/bin/env bash
# Upstream version of check-spdx.sh (newly introduced by template).
echo "upstream check-spdx"
'

# What the project had locally (pre-dates upstream shipping this file).
PROJECT_FILE_CONTENT='#!/usr/bin/env bash
# Local pre-existing version of check-spdx.sh.
echo "local check-spdx"
'

# A second (non-colliding) file that does exist in baseline — used to
# ensure the TEMPLATE_MANIFEST.lock / TEMPLATE_VERSION round-trip works.
ANCHOR_FILE="scripts/upgrade.sh"
ANCHOR_CONTENT='#!/usr/bin/env bash
echo "anchor"
'

# ---------------------------------------------------------------------------
# Case (a): Collision, no flags → take-upstream; collision_taken_upstream.
# ---------------------------------------------------------------------------
echo ""
echo "-- case (a): collision, no flags → take-upstream --"

upstream_a="$tmp/a-upstream"
baseline_a="$tmp/a-baseline"
workdir_a="$tmp/a-workdir"
proj_a="$tmp/a-project"

# Upstream has both the anchor and the newly-introduced colliding file.
rm -rf "$upstream_a"
mkdir -p "$upstream_a/scripts"
(
  cd "$upstream_a"
  git init -b main -q
  git config user.email collision-test-upstream@example.invalid
  git config user.name "Collision Test Upstream"
  printf '%s\n' "$UPSTREAM_NEW_TAG" > VERSION
  printf '%s' "$ANCHOR_CONTENT" > "$ANCHOR_FILE"
  printf '%s' "$UPSTREAM_FILE_CONTENT" > "$TEST_FILE"
  git add VERSION "$ANCHOR_FILE" "$TEST_FILE"
  git commit -q -m "release $UPSTREAM_NEW_TAG"
  git tag "$UPSTREAM_NEW_TAG"
)

baseline_sha_a="$(git -C "$upstream_a" rev-parse HEAD)"

# Baseline (workdir/old) has the anchor but NOT the colliding file.
make_baseline_repo "$baseline_a" "$upstream_a" "$baseline_sha_a"
rm -f "$baseline_a/$TEST_FILE"

# Project has anchor (matching baseline) + the pre-existing local copy.
rm -rf "$proj_a"
mkdir -p "$proj_a/scripts"
(
  cd "$proj_a"
  git init -b main -q
  git config user.email collision-test-project@example.invalid
  git config user.name "Collision Test Project"
  printf '%s\n%s\n%s\n' "v1.0.0-rc9" "$baseline_sha_a" "2026-01-01" > TEMPLATE_VERSION
  printf '%s' "$ANCHOR_CONTENT" > "$ANCHOR_FILE"
  printf '%s' "$PROJECT_FILE_CONTENT" > "$TEST_FILE"
  git add TEMPLATE_VERSION "$ANCHOR_FILE" "$TEST_FILE"
  git commit -q -m "fixture init"
)
# Manifest has anchor SHA but NOT the colliding file SHA.
anchor_sha_a="$(file_sha256 "$baseline_a/$ANCHOR_FILE")"
{
  echo "# TEMPLATE_MANIFEST.lock — auto-generated"
  echo "$anchor_sha_a  $ANCHOR_FILE"
} > "$proj_a/TEMPLATE_MANIFEST.lock"

make_prestaged_workdir "$workdir_a" "$upstream_a" "$baseline_a"

log_a="$tmp/case-a.log"
rc_a="$(run_upgrade "$proj_a" "$workdir_a" "$log_a")"

check "(a): upgrade exits 0" \
  bash -c "[ '$rc_a' = '0' ]"
check "(a): log contains 'Accepted upstream (pre-existing collision resolved)'" \
  bash -c "grep -q 'Accepted upstream (pre-existing collision resolved)' '$log_a'"
check "(a): file listed under collision_taken_upstream bucket with > sigil" \
  bash -c "grep -qE '^  > $TEST_FILE\$' '$log_a'"
check "(a): project file content matches upstream after take" \
  bash -c "diff -q '$proj_a/$TEST_FILE' '$upstream_a/$TEST_FILE' >/dev/null 2>&1"
check "(a): no Conflicts line" \
  bash -c "! grep -q '^.*Conflicts' '$log_a'"

# ---------------------------------------------------------------------------
# Case (b): Collision + --keep-local <path> → local_only_kept; no overwrite.
# ---------------------------------------------------------------------------
echo ""
echo "-- case (b): collision + --keep-local → local_only_kept --"

upstream_b="$tmp/b-upstream"
baseline_b="$tmp/b-baseline"
workdir_b="$tmp/b-workdir"
proj_b="$tmp/b-project"

rm -rf "$upstream_b"
mkdir -p "$upstream_b/scripts"
(
  cd "$upstream_b"
  git init -b main -q
  git config user.email collision-test-upstream@example.invalid
  git config user.name "Collision Test Upstream"
  printf '%s\n' "$UPSTREAM_NEW_TAG" > VERSION
  printf '%s' "$ANCHOR_CONTENT" > "$ANCHOR_FILE"
  printf '%s' "$UPSTREAM_FILE_CONTENT" > "$TEST_FILE"
  git add VERSION "$ANCHOR_FILE" "$TEST_FILE"
  git commit -q -m "release $UPSTREAM_NEW_TAG"
  git tag "$UPSTREAM_NEW_TAG"
)
baseline_sha_b="$(git -C "$upstream_b" rev-parse HEAD)"
make_baseline_repo "$baseline_b" "$upstream_b" "$baseline_sha_b"
rm -f "$baseline_b/$TEST_FILE"

rm -rf "$proj_b"
mkdir -p "$proj_b/scripts"
(
  cd "$proj_b"
  git init -b main -q
  git config user.email collision-test-project@example.invalid
  git config user.name "Collision Test Project"
  printf '%s\n%s\n%s\n' "v1.0.0-rc9" "$baseline_sha_b" "2026-01-01" > TEMPLATE_VERSION
  printf '%s' "$ANCHOR_CONTENT" > "$ANCHOR_FILE"
  printf '%s' "$PROJECT_FILE_CONTENT" > "$TEST_FILE"
  git add TEMPLATE_VERSION "$ANCHOR_FILE" "$TEST_FILE"
  git commit -q -m "fixture init"
)
anchor_sha_b="$(file_sha256 "$baseline_b/$ANCHOR_FILE")"
{
  echo "# TEMPLATE_MANIFEST.lock — auto-generated"
  echo "$anchor_sha_b  $ANCHOR_FILE"
} > "$proj_b/TEMPLATE_MANIFEST.lock"

make_prestaged_workdir "$workdir_b" "$upstream_b" "$baseline_b"

log_b="$tmp/case-b.log"
rc_b="$(run_upgrade "$proj_b" "$workdir_b" "$log_b" "--keep-local" "$TEST_FILE")"

check "(b): upgrade exits 0 (kept-local is not a blocker)" \
  bash -c "[ '$rc_b' = '0' ]"
check "(b): log contains 'Local customizations kept'" \
  bash -c "grep -q 'Local customizations kept' '$log_b'"
check "(b): project file NOT overwritten with upstream content" \
  bash -c "grep -qF 'local check-spdx' '$proj_b/$TEST_FILE'"
check "(b): upstream content NOT written to project file" \
  bash -c "! grep -qF 'upstream check-spdx' '$proj_b/$TEST_FILE'"
check "(b): no collision_taken_upstream bucket" \
  bash -c "! grep -q 'Accepted upstream (pre-existing collision resolved)' '$log_b'"

# ---------------------------------------------------------------------------
# Case (b2): Collision + --keep-local ./<path> (leading ./) → normalized →
#            still matches; local_only_kept; file NOT overwritten.
#            Guards the path-normalization fix for shell-completion forms.
# ---------------------------------------------------------------------------
echo ""
echo "-- case (b2): --keep-local ./<path> (leading ./) → normalized → kept-local --"

upstream_b2="$tmp/b2-upstream"
baseline_b2="$tmp/b2-baseline"
workdir_b2="$tmp/b2-workdir"
proj_b2="$tmp/b2-project"

rm -rf "$upstream_b2"
mkdir -p "$upstream_b2/scripts"
(
  cd "$upstream_b2" || exit 1
  git init -b main -q
  git config user.email collision-test-upstream@example.invalid
  git config user.name "Collision Test Upstream"
  printf '%s\n' "$UPSTREAM_NEW_TAG" > VERSION
  printf '%s' "$ANCHOR_CONTENT" > "$ANCHOR_FILE"
  printf '%s' "$UPSTREAM_FILE_CONTENT" > "$TEST_FILE"
  git add VERSION "$ANCHOR_FILE" "$TEST_FILE"
  git commit -q -m "release $UPSTREAM_NEW_TAG"
  git tag "$UPSTREAM_NEW_TAG"
)
baseline_sha_b2="$(git -C "$upstream_b2" rev-parse HEAD)"
make_baseline_repo "$baseline_b2" "$upstream_b2" "$baseline_sha_b2"
rm -f "$baseline_b2/$TEST_FILE"

rm -rf "$proj_b2"
mkdir -p "$proj_b2/scripts"
(
  cd "$proj_b2" || exit 1
  git init -b main -q
  git config user.email collision-test-project@example.invalid
  git config user.name "Collision Test Project"
  printf '%s\n%s\n%s\n' "v1.0.0-rc9" "$baseline_sha_b2" "2026-01-01" > TEMPLATE_VERSION
  printf '%s' "$ANCHOR_CONTENT" > "$ANCHOR_FILE"
  printf '%s' "$PROJECT_FILE_CONTENT" > "$TEST_FILE"
  git add TEMPLATE_VERSION "$ANCHOR_FILE" "$TEST_FILE"
  git commit -q -m "fixture init"
)
anchor_sha_b2="$(file_sha256 "$baseline_b2/$ANCHOR_FILE")"
{
  echo "# TEMPLATE_MANIFEST.lock — auto-generated"
  echo "$anchor_sha_b2  $ANCHOR_FILE"
} > "$proj_b2/TEMPLATE_MANIFEST.lock"

make_prestaged_workdir "$workdir_b2" "$upstream_b2" "$baseline_b2"

log_b2="$tmp/case-b2.log"
# Pass the path with a leading ./ — normalization must strip it so the
# lookup against $TEST_FILE (no leading ./) still matches.
rc_b2="$(run_upgrade "$proj_b2" "$workdir_b2" "$log_b2" "--keep-local" "./$TEST_FILE")"

check "(b2): upgrade exits 0" \
  bash -c "[ '$rc_b2' = '0' ]"
check "(b2): log contains 'Local customizations kept' (normalization matched)" \
  bash -c "grep -q 'Local customizations kept' '$log_b2'"
check "(b2): project file NOT overwritten (leading ./ did not defeat the opt-out)" \
  bash -c "grep -qF 'local check-spdx' '$proj_b2/$TEST_FILE'"
check "(b2): upstream content NOT written to project file" \
  bash -c "! grep -qF 'upstream check-spdx' '$proj_b2/$TEST_FILE'"
check "(b2): no collision_taken_upstream bucket" \
  bash -c "! grep -q 'Accepted upstream (pre-existing collision resolved)' '$log_b2'"

# ---------------------------------------------------------------------------
# Case (b3): Collision + --keep-local <different-path> → does NOT match
#            the colliding file → take-upstream fires for the colliding file.
#            Confirms path specificity: opt-out is scoped to the named path.
# ---------------------------------------------------------------------------
echo ""
echo "-- case (b3): --keep-local <other-path> → no match → take-upstream fires --"

upstream_b3="$tmp/b3-upstream"
baseline_b3="$tmp/b3-baseline"
workdir_b3="$tmp/b3-workdir"
proj_b3="$tmp/b3-project"

DIFFERENT_PATH="scripts/other-file.sh"

rm -rf "$upstream_b3"
mkdir -p "$upstream_b3/scripts"
(
  cd "$upstream_b3" || exit 1
  git init -b main -q
  git config user.email collision-test-upstream@example.invalid
  git config user.name "Collision Test Upstream"
  printf '%s\n' "$UPSTREAM_NEW_TAG" > VERSION
  printf '%s' "$ANCHOR_CONTENT" > "$ANCHOR_FILE"
  printf '%s' "$UPSTREAM_FILE_CONTENT" > "$TEST_FILE"
  git add VERSION "$ANCHOR_FILE" "$TEST_FILE"
  git commit -q -m "release $UPSTREAM_NEW_TAG"
  git tag "$UPSTREAM_NEW_TAG"
)
baseline_sha_b3="$(git -C "$upstream_b3" rev-parse HEAD)"
make_baseline_repo "$baseline_b3" "$upstream_b3" "$baseline_sha_b3"
rm -f "$baseline_b3/$TEST_FILE"

rm -rf "$proj_b3"
mkdir -p "$proj_b3/scripts"
(
  cd "$proj_b3" || exit 1
  git init -b main -q
  git config user.email collision-test-project@example.invalid
  git config user.name "Collision Test Project"
  printf '%s\n%s\n%s\n' "v1.0.0-rc9" "$baseline_sha_b3" "2026-01-01" > TEMPLATE_VERSION
  printf '%s' "$ANCHOR_CONTENT" > "$ANCHOR_FILE"
  printf '%s' "$PROJECT_FILE_CONTENT" > "$TEST_FILE"
  git add TEMPLATE_VERSION "$ANCHOR_FILE" "$TEST_FILE"
  git commit -q -m "fixture init"
)
anchor_sha_b3="$(file_sha256 "$baseline_b3/$ANCHOR_FILE")"
{
  echo "# TEMPLATE_MANIFEST.lock — auto-generated"
  echo "$anchor_sha_b3  $ANCHOR_FILE"
} > "$proj_b3/TEMPLATE_MANIFEST.lock"

make_prestaged_workdir "$workdir_b3" "$upstream_b3" "$baseline_b3"

log_b3="$tmp/case-b3.log"
# --keep-local names a DIFFERENT path, not TEST_FILE → opt-out does not apply.
rc_b3="$(run_upgrade "$proj_b3" "$workdir_b3" "$log_b3" "--keep-local" "$DIFFERENT_PATH")"

check "(b3): upgrade exits 0" \
  bash -c "[ '$rc_b3' = '0' ]"
check "(b3): collision_taken_upstream bucket present (opt-out did not cover TEST_FILE)" \
  bash -c "grep -q 'Accepted upstream (pre-existing collision resolved)' '$log_b3'"
check "(b3): project file overwritten with upstream content (take-upstream fired)" \
  bash -c "diff -q '$proj_b3/$TEST_FILE' '$upstream_b3/$TEST_FILE' >/dev/null 2>&1"
check "(b3): no Conflicts line" \
  bash -c "! grep -q '^.*Conflicts' '$log_b3'"

# ---------------------------------------------------------------------------
# Case (c): Collision + path in .template-customizations → preserved;
#           no auto-take.
# ---------------------------------------------------------------------------
echo ""
echo "-- case (c): collision + .template-customizations → preserved --"

upstream_c="$tmp/c-upstream"
baseline_c="$tmp/c-baseline"
workdir_c="$tmp/c-workdir"
proj_c="$tmp/c-project"

rm -rf "$upstream_c"
mkdir -p "$upstream_c/scripts"
(
  cd "$upstream_c"
  git init -b main -q
  git config user.email collision-test-upstream@example.invalid
  git config user.name "Collision Test Upstream"
  printf '%s\n' "$UPSTREAM_NEW_TAG" > VERSION
  printf '%s' "$ANCHOR_CONTENT" > "$ANCHOR_FILE"
  printf '%s' "$UPSTREAM_FILE_CONTENT" > "$TEST_FILE"
  git add VERSION "$ANCHOR_FILE" "$TEST_FILE"
  git commit -q -m "release $UPSTREAM_NEW_TAG"
  git tag "$UPSTREAM_NEW_TAG"
)
baseline_sha_c="$(git -C "$upstream_c" rev-parse HEAD)"
make_baseline_repo "$baseline_c" "$upstream_c" "$baseline_sha_c"
rm -f "$baseline_c/$TEST_FILE"

rm -rf "$proj_c"
mkdir -p "$proj_c/scripts"
(
  cd "$proj_c"
  git init -b main -q
  git config user.email collision-test-project@example.invalid
  git config user.name "Collision Test Project"
  printf '%s\n%s\n%s\n' "v1.0.0-rc9" "$baseline_sha_c" "2026-01-01" > TEMPLATE_VERSION
  printf '%s' "$ANCHOR_CONTENT" > "$ANCHOR_FILE"
  printf '%s' "$PROJECT_FILE_CONTENT" > "$TEST_FILE"
  # Add the colliding path to .template-customizations.
  printf '%s\n' "$TEST_FILE" > .template-customizations
  git add TEMPLATE_VERSION "$ANCHOR_FILE" "$TEST_FILE" .template-customizations
  git commit -q -m "fixture init"
)
anchor_sha_c="$(file_sha256 "$baseline_c/$ANCHOR_FILE")"
{
  echo "# TEMPLATE_MANIFEST.lock — auto-generated"
  echo "$anchor_sha_c  $ANCHOR_FILE"
} > "$proj_c/TEMPLATE_MANIFEST.lock"

make_prestaged_workdir "$workdir_c" "$upstream_c" "$baseline_c"

log_c="$tmp/case-c.log"
rc_c="$(run_upgrade "$proj_c" "$workdir_c" "$log_c")"

check "(c): upgrade exits 0" \
  bash -c "[ '$rc_c' = '0' ]"
check "(c): log contains 'Preserved per .template-customizations'" \
  bash -c "grep -q 'Preserved per .template-customizations' '$log_c'"
check "(c): project file NOT overwritten" \
  bash -c "grep -qF 'local check-spdx' '$proj_c/$TEST_FILE'"
check "(c): no collision_taken_upstream bucket" \
  bash -c "! grep -q 'Accepted upstream (pre-existing collision resolved)' '$log_c'"

# ---------------------------------------------------------------------------
# Case (d): Collision, dry-run → "would take upstream" printed; no write.
# ---------------------------------------------------------------------------
echo ""
echo "-- case (d): collision, dry-run → message printed; file unchanged --"

upstream_d="$tmp/d-upstream"
baseline_d="$tmp/d-baseline"
workdir_d="$tmp/d-workdir"
proj_d="$tmp/d-project"

rm -rf "$upstream_d"
mkdir -p "$upstream_d/scripts"
(
  cd "$upstream_d"
  git init -b main -q
  git config user.email collision-test-upstream@example.invalid
  git config user.name "Collision Test Upstream"
  printf '%s\n' "$UPSTREAM_NEW_TAG" > VERSION
  printf '%s' "$ANCHOR_CONTENT" > "$ANCHOR_FILE"
  printf '%s' "$UPSTREAM_FILE_CONTENT" > "$TEST_FILE"
  git add VERSION "$ANCHOR_FILE" "$TEST_FILE"
  git commit -q -m "release $UPSTREAM_NEW_TAG"
  git tag "$UPSTREAM_NEW_TAG"
)
baseline_sha_d="$(git -C "$upstream_d" rev-parse HEAD)"
make_baseline_repo "$baseline_d" "$upstream_d" "$baseline_sha_d"
rm -f "$baseline_d/$TEST_FILE"

rm -rf "$proj_d"
mkdir -p "$proj_d/scripts"
(
  cd "$proj_d"
  git init -b main -q
  git config user.email collision-test-project@example.invalid
  git config user.name "Collision Test Project"
  printf '%s\n%s\n%s\n' "v1.0.0-rc9" "$baseline_sha_d" "2026-01-01" > TEMPLATE_VERSION
  printf '%s' "$ANCHOR_CONTENT" > "$ANCHOR_FILE"
  printf '%s' "$PROJECT_FILE_CONTENT" > "$TEST_FILE"
  git add TEMPLATE_VERSION "$ANCHOR_FILE" "$TEST_FILE"
  git commit -q -m "fixture init"
)
anchor_sha_d="$(file_sha256 "$baseline_d/$ANCHOR_FILE")"
{
  echo "# TEMPLATE_MANIFEST.lock — auto-generated"
  echo "$anchor_sha_d  $ANCHOR_FILE"
} > "$proj_d/TEMPLATE_MANIFEST.lock"

make_prestaged_workdir "$workdir_d" "$upstream_d" "$baseline_d"

# Capture a checksum of the project file before dry-run to verify no write.
proj_sha_before_d="$(file_sha256 "$proj_d/$TEST_FILE")"

log_d="$tmp/case-d.log"
rc_d="$(run_upgrade "$proj_d" "$workdir_d" "$log_d" "--dry-run")"

check "(d): dry-run exits 0" \
  bash -c "[ '$rc_d' = '0' ]"
check "(d): log contains 'would take upstream (pre-existing collision)'" \
  bash -c "grep -q 'would take upstream (pre-existing collision)' '$log_d'"
check "(d): project file NOT modified by dry-run (SHA unchanged)" \
  bash -c "[ \"\$(sha256sum '$proj_d/$TEST_FILE' 2>/dev/null | awk '{print \$1}' || shasum -a 256 '$proj_d/$TEST_FILE' 2>/dev/null | awk '{print \$1}')\" = '$proj_sha_before_d' ]"
check "(d): upstream content NOT written to project file" \
  bash -c "! grep -qF 'upstream check-spdx' '$proj_d/$TEST_FILE'"

# ---------------------------------------------------------------------------
# Case (e): Regression guard — non-collision substantive conflict still
#           routes to conflicts[] and blocks.
# ---------------------------------------------------------------------------
echo ""
echo "-- case (e): regression guard: substantive conflict → conflicts[] --"

upstream_e="$tmp/e-upstream"
baseline_e="$tmp/e-baseline"
workdir_e="$tmp/e-workdir"
proj_e="$tmp/e-project"

# For a true conflict (not a pre-existing collision):
#   workdir/old/<f>   — PRESENT (baseline has it)
#   project_root/<f>  — PRESENT, DIFFERENT from baseline (local edit)
#   workdir/new/<f>   — PRESENT, DIFFERENT from baseline (upstream edit)
BASELINE_CONTENT_E='#!/usr/bin/env bash
# baseline version
echo "baseline"
'
UPSTREAM_CONTENT_E='#!/usr/bin/env bash
# upstream changed this
echo "upstream v2"
'
PROJECT_CONTENT_E='#!/usr/bin/env bash
# project substantially changed this
echo "local custom version"
'
CONFLICT_FILE="scripts/conflict-test.sh"

rm -rf "$upstream_e"
mkdir -p "$upstream_e/scripts"
(
  cd "$upstream_e"
  git init -b main -q
  git config user.email collision-test-upstream@example.invalid
  git config user.name "Collision Test Upstream"
  printf '%s\n' "$UPSTREAM_NEW_TAG" > VERSION
  printf '%s' "$UPSTREAM_CONTENT_E" > "$CONFLICT_FILE"
  git add VERSION "$CONFLICT_FILE"
  git commit -q -m "release $UPSTREAM_NEW_TAG"
  git tag "$UPSTREAM_NEW_TAG"
)
baseline_sha_e="$(git -C "$upstream_e" rev-parse HEAD)"
make_baseline_repo "$baseline_e" "$upstream_e" "$baseline_sha_e"
# Overwrite with baseline content in workdir/old.
printf '%s' "$BASELINE_CONTENT_E" > "$baseline_e/$CONFLICT_FILE"

rm -rf "$proj_e"
mkdir -p "$proj_e/scripts"
(
  cd "$proj_e"
  git init -b main -q
  git config user.email collision-test-project@example.invalid
  git config user.name "Collision Test Project"
  printf '%s\n%s\n%s\n' "v1.0.0-rc9" "$baseline_sha_e" "2026-01-01" > TEMPLATE_VERSION
  printf '%s' "$PROJECT_CONTENT_E" > "$CONFLICT_FILE"
  git add TEMPLATE_VERSION "$CONFLICT_FILE"
  git commit -q -m "fixture init"
)
baseline_sha_for_manifest_e="$(file_sha256 "$baseline_e/$CONFLICT_FILE")"
{
  echo "# TEMPLATE_MANIFEST.lock — auto-generated"
  echo "$baseline_sha_for_manifest_e  $CONFLICT_FILE"
} > "$proj_e/TEMPLATE_MANIFEST.lock"

make_prestaged_workdir "$workdir_e" "$upstream_e" "$baseline_e"

log_e="$tmp/case-e.log"
rc_e="$(run_upgrade "$proj_e" "$workdir_e" "$log_e")"

check "(e): substantive conflict upgrade exits 0 (conflict recorded but not fatal)" \
  bash -c "[ '$rc_e' = '0' ]"
check "(e): log contains 'Conflicts'" \
  bash -c "grep -q 'Conflicts' '$log_e'"
check "(e): conflict file listed under Conflicts bucket" \
  bash -c "grep -q '$CONFLICT_FILE' '$log_e'"
check "(e): project file NOT overwritten (conflict, not auto-resolved)" \
  bash -c "grep -qF 'local custom version' '$proj_e/$CONFLICT_FILE'"
check "(e): no collision_taken_upstream bucket (not a pre-existing collision)" \
  bash -c "! grep -q 'Accepted upstream (pre-existing collision resolved)' '$log_e'"

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
