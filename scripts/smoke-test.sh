#!/usr/bin/env bash
#
# scripts/smoke-test.sh — run a minimal end-to-end sanity check on the
# scaffold + version-check flow.
#
# What it does:
#   1. Scaffolds a throwaway project in a fresh temp dir.
#   2. Asserts the expected layout is present (CLAUDE.md,
#      TEMPLATE_VERSION, empty registers, .template-customizations,
#      etc.) and the expected template-only files are NOT present
#      (VERSION, CHANGELOG.md, LICENSE, CONTRIBUTING.md, .github/,
#      dryrun-project/, migrations/).
#   3. Runs version-check.sh in the scaffolded project and asserts it
#      reports "up to date" (since it was just scaffolded at current
#      VERSION).
#   4. Cleans up unless --keep is passed.
#
# Exit 0 on all checks green; exit 1 on any failure.
#
# Run from the template repo root.

set -euo pipefail

keep=0
[[ "${1:-}" == "--keep" ]] && keep=1

if [[ ! -f VERSION || ! -x scripts/scaffold.sh ]]; then
  echo "ERROR: run this from the template repo root." >&2
  exit 1
fi

repo_root="$(pwd)"
tmp="$(mktemp -d -t sw-dev-smoke-XXXXXX)"
trap 'if [[ $keep -eq 0 ]]; then rm -rf "$tmp"; else echo "(kept $tmp for inspection)" >&2; fi' EXIT

target="$tmp/acme"
fail=0
pass=0

check() {
  # check "<label>" <bool-expr...>
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "  PASS: $label"
    pass=$((pass + 1))
  else
    echo "  FAIL: $label" >&2
    fail=$((fail + 1))
  fi
}

echo "-- scaffold --"
./scripts/scaffold.sh "$target" "Acme Smoke Test" >/dev/null

echo "-- expected-present --"
check "target directory exists"           test -d "$target"
check "CLAUDE.md present"                 test -f "$target/CLAUDE.md"
check "README.md present (project stub)"  test -f "$target/README.md"
check "TEMPLATE_VERSION stamped"          test -f "$target/TEMPLATE_VERSION"
check ".template-customizations seeded"   test -f "$target/.template-customizations"
check "OPEN_QUESTIONS.md present"         test -f "$target/docs/OPEN_QUESTIONS.md"
check "AGENT_NAMES.md present"            test -f "$target/docs/AGENT_NAMES.md"
check "CUSTOMER_NOTES.md present"         test -f "$target/CUSTOMER_NOTES.md"
check "docs/glossary/ENGINEERING.md"      test -f "$target/docs/glossary/ENGINEERING.md"
check "docs/glossary/PROJECT.md"          test -f "$target/docs/glossary/PROJECT.md"
check "docs/templates/ present"           test -d "$target/docs/templates"
check "docs/templates/pm/ present"        test -d "$target/docs/templates/pm"
check ".claude/agents/tech-lead.md"       test -f "$target/.claude/agents/tech-lead.md"
check ".claude/agents/project-manager.md" test -f "$target/.claude/agents/project-manager.md"
check "scaffold.sh carried"               test -f "$target/scripts/scaffold.sh"
check "upgrade.sh carried"                test -f "$target/scripts/upgrade.sh"
check "version-check.sh carried"          test -f "$target/scripts/version-check.sh"
check "git initialized"                   test -d "$target/.git"

echo "-- expected-ABSENT (template-only) --"
check "VERSION not carried"           test ! -f "$target/VERSION"
check "CHANGELOG.md not carried"      test ! -f "$target/CHANGELOG.md"
check "LICENSE not carried"           test ! -f "$target/LICENSE"
check "CONTRIBUTING.md not carried"   test ! -f "$target/CONTRIBUTING.md"
check ".github not carried"           test ! -d "$target/.github"
check "dryrun-project not carried"    test ! -d "$target/dryrun-project"
check "examples/ not carried"         test ! -d "$target/examples"
check "migrations not carried"        test ! -d "$target/migrations"
check "scripts/smoke-test.sh not carried (template tool)"  test ! -f "$target/scripts/smoke-test.sh"

echo "-- content-shape --"
check "OPEN_QUESTIONS.md is empty register (no Q-0001 row)"  bash -c "! grep -q 'Q-0001' '$target/docs/OPEN_QUESTIONS.md'"
check "AGENT_NAMES.md has empty mapping table"               bash -c "grep -q '| \`tech-lead\` *|' '$target/docs/AGENT_NAMES.md'"
check "TEMPLATE_VERSION first line is a SemVer"              bash -c "head -1 '$target/TEMPLATE_VERSION' | grep -qE '^v[0-9]+\\.[0-9]+\\.[0-9]+$'"

# Template version stamp should match our current VERSION
expected_version="$(cat VERSION | tr -d '[:space:]')"
actual_version="$(head -1 "$target/TEMPLATE_VERSION" | tr -d '[:space:]')"
check "TEMPLATE_VERSION matches current VERSION ($expected_version)" \
  bash -c "[ '$actual_version' = '$expected_version' ]"

echo "-- manifest (ADR-0002, v0.14.0+) --"
check "TEMPLATE_MANIFEST.lock exists after scaffold"      test -f "$target/TEMPLATE_MANIFEST.lock"
check "manifest header carries the ADR-0002 marker"       bash -c "head -1 '$target/TEMPLATE_MANIFEST.lock' | grep -q 'ADR-0002'"
check "manifest is non-empty (>= 10 entries)"             bash -c "[ \"\$(grep -cv '^#' '$target/TEMPLATE_MANIFEST.lock')\" -ge 10 ]"
check "TEMPLATE_MANIFEST.lock excluded from manifest"     bash -c "! grep -q ' TEMPLATE_MANIFEST\\.lock\$' '$target/TEMPLATE_MANIFEST.lock'"
check "TEMPLATE_VERSION excluded from manifest"           bash -c "! grep -q ' TEMPLATE_VERSION\$' '$target/TEMPLATE_MANIFEST.lock'"

# v0.14.1 regression: manifest must NOT include project-added files.
# Add a project-owned file (mimics sme-*, docs/pm/*, an operator
# secret, etc.) and a nested directory, regenerate the manifest by
# rerunning the upgrade flow's writeup path, then assert.
mkdir -p "$target/docs/pm" "$target/.claude/agents"
echo "project secret" > "$target/wg0.conf"
echo "project sme" > "$target/.claude/agents/sme-fake.md"
echo "project pm" > "$target/docs/pm/CHARTER.md"
# Re-run scaffold-style manifest_write with the lib helpers.
bash -c "
  source '$repo_root/scripts/lib/manifest.sh'
  manifest_write '$repo_root' '$target' '$target/TEMPLATE_MANIFEST.lock'
"
check "manifest excludes project-added wg0.conf"          bash -c "! grep -q ' wg0\\.conf\$' '$target/TEMPLATE_MANIFEST.lock'"
check "manifest excludes user-added sme-*.md"             bash -c "! grep -q ' sme-fake\\.md\$' '$target/TEMPLATE_MANIFEST.lock'"
check "manifest excludes docs/pm/* artefacts"             bash -c "! grep -q ' docs/pm/CHARTER\\.md\$' '$target/TEMPLATE_MANIFEST.lock'"
# Cleanup the synthetic project-added paths so subsequent tests run
# against the clean scaffold.
find "$target/wg0.conf" "$target/.claude/agents/sme-fake.md" "$target/docs/pm/CHARTER.md" -delete 2>/dev/null
find "$target/docs/pm" -depth -delete 2>/dev/null
# Regenerate manifest from clean state for the rest of the suite.
bash -c "
  source '$repo_root/scripts/lib/manifest.sh'
  manifest_write '$repo_root' '$target' '$target/TEMPLATE_MANIFEST.lock'
"

# Helper: run a command capturing its exit code without tripping set -e.
# The expected nonzero exits (drift=1, missing=2, corrupt=3, bogus=2)
# would otherwise abort the smoke test under -e.
run_capture() {
  local _logfile="$1"; shift
  local _rc=0
  "$@" > "$_logfile" 2>&1 || _rc=$?
  echo "$_rc"
}

# upgrade.sh --verify on a freshly scaffolded project should be clean (exit 0).
verify_rc=$(run_capture "$tmp/verify-clean.log" \
            bash -c "cd '$target' && bash '$repo_root/scripts/upgrade.sh' --verify")
check "upgrade.sh --verify on fresh scaffold exits 0"     bash -c "[ $verify_rc -eq 0 ]"
check "verify reports OK"                                 bash -c "grep -q '^OK:' '$tmp/verify-clean.log'"

# Perturb a file; verify should detect drift (exit 1).
echo "  // smoke-test perturbation" >> "$target/CLAUDE.md"
drift_rc=$(run_capture "$tmp/verify-drift.log" \
           bash -c "cd '$target' && bash '$repo_root/scripts/upgrade.sh' --verify")
check "verify detects drift after perturbation (exit 1)"  bash -c "[ $drift_rc -eq 1 ]"
check "drift report names the perturbed file"             bash -c "grep -q '^drift:.*CLAUDE\\.md' '$tmp/verify-drift.log'"

# Restore (truncate the trailing line we added).
head -n -1 "$target/CLAUDE.md" > "$tmp/claude.tmp" && mv "$tmp/claude.tmp" "$target/CLAUDE.md"
restore_rc=$(run_capture "$tmp/verify-restore.log" \
             bash -c "cd '$target' && bash '$repo_root/scripts/upgrade.sh' --verify")
check "verify clean again after restore (exit 0)"         bash -c "[ $restore_rc -eq 0 ]"

# Missing manifest should yield exit 2.
mv "$target/TEMPLATE_MANIFEST.lock" "$tmp/manifest-stash"
missing_rc=$(run_capture "$tmp/verify-missing.log" \
             bash -c "cd '$target' && bash '$repo_root/scripts/upgrade.sh' --verify")
check "verify with no manifest exits 2"                   bash -c "[ $missing_rc -eq 2 ]"
mv "$tmp/manifest-stash" "$target/TEMPLATE_MANIFEST.lock"

# Corrupt manifest (mangled SHA on the first non-comment line) → exit 3.
cp "$target/TEMPLATE_MANIFEST.lock" "$tmp/manifest-pristine"
sed -i '/^[a-f0-9]\{64\}  /{s/^.\{20\}/SHORT/;:done;n;b done}' "$target/TEMPLATE_MANIFEST.lock"
corrupt_rc=$(run_capture "$tmp/verify-corrupt.log" \
             bash -c "cd '$target' && bash '$repo_root/scripts/upgrade.sh' --verify")
check "verify with corrupt manifest exits 3"              bash -c "[ $corrupt_rc -eq 3 ]"
cp "$tmp/manifest-pristine" "$target/TEMPLATE_MANIFEST.lock"

# upgrade.sh --help should print usage and exit 0 (issue #58).
help_rc=$(run_capture "$tmp/upgrade-help.log" \
          bash "$repo_root/scripts/upgrade.sh" --help)
check "upgrade.sh --help exits 0"                         bash -c "[ $help_rc -eq 0 ]"
check "upgrade.sh --help prints Usage"                    bash -c "grep -q '^Usage:' '$tmp/upgrade-help.log'"

# upgrade.sh with unknown flag should exit 2 with error + usage.
bogus_rc=$(run_capture "$tmp/upgrade-bogus.log" \
           bash "$repo_root/scripts/upgrade.sh" --no-such-flag)
check "upgrade.sh with unknown flag exits 2"              bash -c "[ $bogus_rc -eq 2 ]"
check "upgrade.sh unknown-flag prints ERROR"              bash -c "grep -q '^ERROR: unknown flag' '$tmp/upgrade-bogus.log'"

echo "-- version-check (scaffolded project should be up-to-date) --"
# Run version-check in the scaffolded project. It requires network — if unavailable,
# skip the assertion rather than fail.
probe_url="https://github.com/occamsshavingkit/sw-dev-team-template"
[[ -n "${GH_TOKEN:-}" ]] && probe_url="https://${GH_TOKEN}@github.com/occamsshavingkit/sw-dev-team-template"
if timeout 5 git ls-remote --tags --refs "$probe_url" >/dev/null 2>&1; then
  vc_output="$(
    cd "$target"
    GH_TOKEN="${GH_TOKEN:-}" ./scripts/version-check.sh 2>&1 || true
  )"
  if echo "$vc_output" | grep -q "up to date"; then
    echo "  PASS: version-check reports up to date"
    pass=$((pass + 1))
  else
    echo "  FAIL: version-check did not report up to date"
    echo "        got: $vc_output"
    fail=$((fail + 1))
  fi
else
  echo "  SKIP: version-check (upstream unreachable)"
fi

echo "-- upgrade (simulate older stamp, run upgrade to HEAD) --"
# Simulate an older project by stamping TEMPLATE_VERSION back to v0.1.0, then
# run upgrade.sh. Verifies:
#   - upgrade completes cleanly
#   - template-only files (LICENSE, smoke-test.sh, CHANGELOG.md, VERSION,
#     CONTRIBUTING.md, migrations/, .github/) are NOT present after upgrade
#   - TEMPLATE_VERSION is stamped to current VERSION
#   - migrations ran (we can detect the v0.1.0 glossary migration fired by
#     presence of docs/glossary/ENGINEERING.md — already there from scaffold
#     so we don't add an extra check)
if timeout 5 git ls-remote --tags --refs "$probe_url" >/dev/null 2>&1; then
  printf 'v0.1.0\nunknown\n2026-01-01\n' > "$target/TEMPLATE_VERSION"
  (
    cd "$target"
    GH_TOKEN="${GH_TOKEN:-}" ./scripts/upgrade.sh
  ) > "$tmp/upgrade.log" 2>&1 || {
    echo "  FAIL: upgrade.sh exited non-zero (see $tmp/upgrade.log)"
    fail=$((fail + 1))
  }

  # Assert template-only files absent after upgrade
  check "no LICENSE after upgrade"                test ! -f "$target/LICENSE"
  check "no smoke-test.sh after upgrade"          test ! -f "$target/scripts/smoke-test.sh"
  check "no CHANGELOG.md after upgrade"           test ! -f "$target/CHANGELOG.md"
  check "no VERSION after upgrade"                test ! -f "$target/VERSION"
  check "no CONTRIBUTING.md after upgrade"        test ! -f "$target/CONTRIBUTING.md"
  check "no migrations/ after upgrade"            test ! -d "$target/migrations"
  check "no examples/ after upgrade"              test ! -d "$target/examples"
  check "no .github/ after upgrade"               test ! -d "$target/.github"

  # TEMPLATE_VERSION stamped to current
  post_version="$(head -1 "$target/TEMPLATE_VERSION" | tr -d '[:space:]')"
  check "TEMPLATE_VERSION matches current VERSION after upgrade ($expected_version)" \
    bash -c "[ '$post_version' = '$expected_version' ]"

  # ADR-0002 / v0.14.2: TEMPLATE_MANIFEST.lock should exist + verify clean
  # immediately after a single upgrade run, no manual regen needed.
  # This exercises migrations/v0.14.0.sh's predicted-post-sync logic.
  check "TEMPLATE_MANIFEST.lock present after upgrade"      test -f "$target/TEMPLATE_MANIFEST.lock"
  post_verify_rc=$(run_capture "$tmp/post-upgrade-verify.log" \
                   bash -c "cd '$target' && bash '$repo_root/scripts/upgrade.sh' --verify")
  check "upgrade.sh --verify clean after one upgrade run"   bash -c "[ $post_verify_rc -eq 0 ]"

  # v0.14.3 / issue #63: atomic_install via tmp+mv must not leave
  # stale .tmp.* files after upgrade.
  check "no stale .tmp.* files after upgrade"               bash -c "[ \"\$(find '$target' -name '*.tmp.*' 2>/dev/null | wc -l)\" -eq 0 ]"

# v0.14.4 / issue #65: scaffold pre-populates canonical stub-fills.
check "stub-fill: CUSTOMER_NOTES.md in .template-customizations" \
  bash -c "grep -qE '^CUSTOMER_NOTES\\.md\$' '$target/.template-customizations'"
check "stub-fill: docs/OPEN_QUESTIONS.md in .template-customizations" \
  bash -c "grep -qE '^docs/OPEN_QUESTIONS\\.md\$' '$target/.template-customizations'"
check "stub-fill: docs/AGENT_NAMES.md in .template-customizations" \
  bash -c "grep -qE '^docs/AGENT_NAMES\\.md\$' '$target/.template-customizations'"
check "stub-fill: docs/glossary/PROJECT.md in .template-customizations" \
  bash -c "grep -qE '^docs/glossary/PROJECT\\.md\$' '$target/.template-customizations'"
check "stub-fill: .gitignore in .template-customizations" \
  bash -c "grep -qE '^\\.gitignore\$' '$target/.template-customizations'"
check "stub-fill: README.md in .template-customizations" \
  bash -c "grep -qE '^README\\.md\$' '$target/.template-customizations'"
else
  echo "  SKIP: upgrade (upstream unreachable)"
fi

echo
echo "------------------------------------------------------------"
echo "smoke-test: $pass passed, $fail failed"
if [[ $fail -gt 0 ]]; then
  exit 1
fi
