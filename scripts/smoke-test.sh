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

echo
echo "------------------------------------------------------------"
echo "smoke-test: $pass passed, $fail failed"
if [[ $fail -gt 0 ]]; then
  exit 1
fi
