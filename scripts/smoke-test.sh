#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
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
check "CUSTOMER_NOTES guard hook carried" test -f "$target/scripts/hooks/customer-notes-guard.py"
check "git initialized"                   test -d "$target/.git"
check "software-engineer advertises role-local supplement" \
  bash -c "grep -q 'software-engineer-local\\.md' '$target/.claude/agents/software-engineer.md'"

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
check "AGENTS.md present"                                  test -f "$target/AGENTS.md"
check "AGENTS.md binds Codex tech-lead"                    bash -c "grep -q 'main Codex session plays \`tech-lead\` directly' '$target/AGENTS.md'"
check "OPEN_QUESTIONS.md is empty register (no Q-0001 row)"  bash -c "! grep -q 'Q-0001' '$target/docs/OPEN_QUESTIONS.md'"
check "AGENT_NAMES.md has empty mapping table"               bash -c "grep -q '| \`tech-lead\` *|' '$target/docs/AGENT_NAMES.md'"
check "TEMPLATE_VERSION first line is a SemVer"              bash -c "head -1 '$target/TEMPLATE_VERSION' | grep -qE '^v[0-9]+\\.[0-9]+\\.[0-9]+(-[0-9A-Za-z.-]+)?(\\+[0-9A-Za-z.-]+)?$'"

# Template version stamp should match our current VERSION
expected_version="$(cat VERSION | tr -d '[:space:]')"
actual_version="$(head -1 "$target/TEMPLATE_VERSION" | tr -d '[:space:]')"
check "TEMPLATE_VERSION matches current VERSION ($expected_version)" \
  bash -c "[ '$actual_version' = '$expected_version' ]"

echo "-- manifest (FW-ADR-0002, v0.14.0+) --"
check "TEMPLATE_MANIFEST.lock exists after scaffold"      test -f "$target/TEMPLATE_MANIFEST.lock"
check "manifest header carries the FW-ADR-0002 marker"       bash -c "head -1 '$target/TEMPLATE_MANIFEST.lock' | grep -q 'FW-ADR-0002'"
check "manifest is non-empty (>= 10 entries)"             bash -c "[ \"\$(grep -cv '^#' '$target/TEMPLATE_MANIFEST.lock')\" -ge 10 ]"
check "TEMPLATE_MANIFEST.lock excluded from manifest"     bash -c "! grep -q ' TEMPLATE_MANIFEST\\.lock\$' '$target/TEMPLATE_MANIFEST.lock'"
check "TEMPLATE_VERSION excluded from manifest"           bash -c "! grep -q ' TEMPLATE_VERSION\$' '$target/TEMPLATE_MANIFEST.lock'"
check "AGENTS.md included in manifest"                    bash -c "grep -q ' AGENTS\\.md\$' '$target/TEMPLATE_MANIFEST.lock'"
manifest_ship_list="$tmp/manifest-ship-files.txt"
bash -c "
  source '$repo_root/scripts/lib/manifest.sh'
  manifest_ship_files '$repo_root' > '$manifest_ship_list'
"
check "manifest ship-files excludes ROADMAP.md"           bash -c "! grep -q '^ROADMAP\\.md\$' '$manifest_ship_list'"
check "manifest ship-files includes AGENTS.md"            bash -c "grep -q '^AGENTS\\.md\$' '$manifest_ship_list'"
check "manifest ship-files excludes docs/audits/"         bash -c "! grep -q '^docs/audits/' '$manifest_ship_list'"
check "manifest ship-files excludes docs/v2/"             bash -c "! grep -q '^docs/v2/' '$manifest_ship_list'"
check "manifest ship-files excludes docs/proposals/"      bash -c "! grep -q '^docs/proposals/' '$manifest_ship_list'"
check "manifest ship-files excludes role-local agents"    bash -c "! grep -q '^\\.claude/agents/.*-local\\.md\$' '$manifest_ship_list'"

# v0.14.1 regression: manifest must NOT include project-added files.
# Add a project-owned file (mimics sme-*, docs/pm/*, an operator
# secret, etc.) and a nested directory, regenerate the manifest by
# rerunning the upgrade flow's writeup path, then assert.
mkdir -p "$target/docs/pm" "$target/.claude/agents"
echo "project secret" > "$target/wg0.conf"
echo "project sme" > "$target/.claude/agents/sme-fake.md"
echo "project rust routing" > "$target/.claude/agents/software-engineer-local.md"
echo "project pm" > "$target/docs/pm/CHARTER.md"
# Re-run scaffold-style manifest_write with the lib helpers.
bash -c "
  source '$repo_root/scripts/lib/manifest.sh'
  manifest_write '$repo_root' '$target' '$target/TEMPLATE_MANIFEST.lock'
"
check "manifest excludes project-added wg0.conf"          bash -c "! grep -q ' wg0\\.conf\$' '$target/TEMPLATE_MANIFEST.lock'"
check "manifest excludes user-added sme-*.md"             bash -c "! grep -q ' sme-fake\\.md\$' '$target/TEMPLATE_MANIFEST.lock'"
check "manifest excludes role-local agent supplements"    bash -c "! grep -q ' software-engineer-local\\.md\$' '$target/TEMPLATE_MANIFEST.lock'"
check "manifest excludes docs/pm/* artefacts"             bash -c "! grep -q ' docs/pm/CHARTER\\.md\$' '$target/TEMPLATE_MANIFEST.lock'"
# Cleanup the synthetic project-added paths so subsequent tests run
# against the clean scaffold.
find "$target/wg0.conf" "$target/.claude/agents/sme-fake.md" "$target/.claude/agents/software-engineer-local.md" "$target/docs/pm/CHARTER.md" -delete 2>/dev/null
find "$target/docs/pm" -depth -delete 2>/dev/null
# Regenerate manifest from clean state for the rest of the suite.
bash -c "
  source '$repo_root/scripts/lib/manifest.sh'
  manifest_write '$repo_root' '$target' '$target/TEMPLATE_MANIFEST.lock'
"

echo "-- first-actions detection --"
check "first-actions helper reports missing Step 0 on fresh scaffold" \
  bash -c "source '$target/scripts/lib/first-actions.sh' && ! first_actions_step0_recorded '$target'"
check "first-actions warning names Step 0 when missing" \
  bash -c "source '$target/scripts/lib/first-actions.sh' && first_actions_step0_warning '$target' session | grep -q 'Step 0 issue-feedback opt-in'"
vc_first_actions="$(
  cd "$target"
  ./scripts/version-check.sh 2>&1 || true
)"
if echo "$vc_first_actions" | grep -q 'FIRST ACTIONS pending'; then
  echo "  PASS: version-check surfaces FIRST ACTIONS on fresh scaffold"
  pass=$((pass + 1))
else
  echo "  FAIL: version-check did not surface FIRST ACTIONS on fresh scaffold"
  fail=$((fail + 1))
fi
cat >> "$target/CUSTOMER_NOTES.md" <<'EOF'

## 2026-01-01 — Issue feedback opt-in

**Question (from tech-lead):**
> Do you want this project to file framework-gap issues upstream?

**Customer answer (verbatim):**
> Yes.

**Recorded by:** researcher
EOF
check "first-actions helper detects recorded Step 0" \
  bash -c "source '$target/scripts/lib/first-actions.sh' && first_actions_step0_recorded '$target'"
check "first-actions warning stays quiet after Step 0" \
  bash -c "source '$target/scripts/lib/first-actions.sh' && [ -z \"\$(first_actions_step0_warning '$target' session)\" ]"

echo "-- hook guards --"
guard_customer_output="$(
  printf '%s\n' '{"tool_name":"Write","tool_input":{"file_path":"CUSTOMER_NOTES.md","content":"x"}}' \
    | python3 "$target/scripts/hooks/customer-notes-guard.py"
)"
check "CUSTOMER_NOTES guard asks on notes write" \
  bash -c "echo '$guard_customer_output' | grep -q 'permissionDecision.*ask'"
guard_other_output="$(
  printf '%s\n' '{"tool_name":"Write","tool_input":{"file_path":"README.md","content":"x"}}' \
    | python3 "$target/scripts/hooks/customer-notes-guard.py"
)"
check "CUSTOMER_NOTES guard stays quiet on other files" \
  bash -c "[ -z '$guard_other_output' ]"
guard_bash_output="$(
  printf '%s\n' '{"tool_name":"Bash","tool_input":{"command":"printf x >> CUSTOMER_NOTES.md"}}' \
    | python3 "$target/scripts/hooks/customer-notes-guard.py"
)"
check "CUSTOMER_NOTES guard asks on Bash notes command" \
  bash -c "echo '$guard_bash_output' | grep -q 'permissionDecision.*ask'"

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

echo "-- upgrade bootstrap args and FIRST ACTIONS warning --"
bootstrap_upstream="$tmp/bootstrap-upstream"
mkdir -p "$bootstrap_upstream"
tar --exclude='./.git' -cf - . | (cd "$bootstrap_upstream" && tar -xf -)
(
  cd "$bootstrap_upstream"
  git init -q
  git config user.email smoke@example.invalid
  git config user.name "Smoke Test"
  git add .
  git commit -q -m "bootstrap upstream"
  git tag "$expected_version"
)
bootstrap_target="$tmp/bootstrap-target"
./scripts/scaffold.sh "$bootstrap_target" "Bootstrap Args Smoke" >/dev/null
printf 'v0.1.0\nunknown\n2026-01-01\n' > "$bootstrap_target/TEMPLATE_VERSION"
printf '\n# force bootstrap drift\n' >> "$bootstrap_target/scripts/lib/first-actions.sh"
bootstrap_rc=$(run_capture "$tmp/bootstrap-dry-run.log" \
               bash -c "cd '$bootstrap_target' && SWDT_UPSTREAM_URL='$bootstrap_upstream' ./scripts/upgrade.sh --dry-run --target '$expected_version'")
bootstrap_post_version="$(head -1 "$bootstrap_target/TEMPLATE_VERSION" | tr -d '[:space:]')"
check "bootstrap dry-run with --target exits 0" \
  bash -c "[ $bootstrap_rc -eq 0 ]"
check "bootstrap re-exec preserves --dry-run" \
  bash -c "grep -q '^\\[dry-run\\] Template upgrade:' '$tmp/bootstrap-dry-run.log'"
check "bootstrap re-exec preserves --target" \
  bash -c "grep -q 'Pinning upgrade to --target $expected_version' '$tmp/bootstrap-dry-run.log'"
check "bootstrap dry-run leaves TEMPLATE_VERSION unchanged" \
  bash -c "[ '$bootstrap_post_version' = 'v0.1.0' ]"
check "upgrade surfaces FIRST ACTIONS warning when Step 0 missing" \
  bash -c "grep -q 'ACTION REQUIRED: FIRST ACTIONS Step 0 is not recorded' '$tmp/bootstrap-dry-run.log'"

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
if [[ -d "$bootstrap_upstream/.git" ]]; then
  printf 'v0.1.0\nunknown\n2026-01-01\n' > "$target/TEMPLATE_VERSION"
  (
    cd "$target"
    SWDT_UPSTREAM_URL="$bootstrap_upstream" ./scripts/upgrade.sh
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
  check "AGENTS.md present after upgrade"         test -f "$target/AGENTS.md"
  check "no migrations/ after upgrade"            test ! -d "$target/migrations"
  check "no examples/ after upgrade"              test ! -d "$target/examples"
  check "no .github/ after upgrade"               test ! -d "$target/.github"

  # TEMPLATE_VERSION stamped to current
  post_version="$(head -1 "$target/TEMPLATE_VERSION" | tr -d '[:space:]')"
  check "TEMPLATE_VERSION matches current VERSION after upgrade ($expected_version)" \
    bash -c "[ '$post_version' = '$expected_version' ]"

  # FW-ADR-0002 / v0.14.2: TEMPLATE_MANIFEST.lock should exist + verify clean
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
# v0.15.0 / issue #66: INDEX split — both INDEX.md (dispatcher) and
# INDEX-PROJECT.md are project-owned post-scaffold.
check "stub-fill: docs/INDEX.md in .template-customizations" \
  bash -c "grep -qE '^docs/INDEX\\.md\$' '$target/.template-customizations'"
check "stub-fill: docs/INDEX-PROJECT.md in .template-customizations" \
  bash -c "grep -qE '^docs/INDEX-PROJECT\\.md\$' '$target/.template-customizations'"
check "INDEX-FRAMEWORK.md present after scaffold (template-shipped)" \
  test -f "$target/docs/INDEX-FRAMEWORK.md"
check "INDEX-PROJECT.md present after scaffold (project-fillable stub)" \
  test -f "$target/docs/INDEX-PROJECT.md"
check "INDEX.md present after scaffold (dispatcher)" \
  test -f "$target/docs/INDEX.md"
# v0.15.0 / issue #67: framework ADRs use fw-adr-NNNN-* filename prefix.
check "fw-adr-0001 present in scaffolded project" \
  test -f "$target/docs/adr/fw-adr-0001-context-memory-strategy.md"
check "no unprefixed 0001-context-memory-strategy.md (collision-prone old name)" \
  bash -c "[ ! -f '$target/docs/adr/0001-context-memory-strategy.md' ]"
else
  echo "  SKIP: upgrade (local upstream fixture unavailable)"
fi

echo
echo "------------------------------------------------------------"
echo "smoke-test: $pass passed, $fail failed"
if [[ $fail -gt 0 ]]; then
  exit 1
fi
