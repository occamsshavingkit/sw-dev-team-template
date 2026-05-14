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

semver_sort_tags() {
  awk '
    function prerelease_key(pre, ids, n, i, id, key) {
      if (pre == "") {
        return "1"
      }
      n = split(pre, ids, ".")
      key = "0"
      for (i = 1; i <= n; i++) {
        id = ids[i]
        if (id ~ /^[0-9]+$/) {
          key = key ".1.0." sprintf("%010d", length(id)) "." id
        } else {
          key = key ".1.1." id
        }
      }
      return key ".0"
    }
    /^v[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$/ {
      tag = $0
      rest = substr(tag, 2)
      prerelease = ""
      dash = index(rest, "-")
      if (dash > 0) {
        prerelease = substr(rest, dash + 1)
        rest = substr(rest, 1, dash - 1)
      }
      split(rest, parts, ".")
      printf "%010d.%010d.%010d.%s\t%s\n", parts[1], parts[2], parts[3], prerelease_key(prerelease), tag
    }
  ' | LC_ALL=C sort -t "$(printf '\t')" -k1,1 | cut -f2-
}

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

settings_contains_literal_path() {
  local settings_file="$1/.claude/settings.json"
  local expected_path="$2"
  local legacy_path="$3"

  ! grep -Fq "$legacy_path" "$settings_file" && grep -Fq "$expected_path" "$settings_file"
}

check_semver_sorter() {
  local label="$1"
  local script="$2"
  local sorter="$tmp/$label-semver-sorter.sh"
  local expected="$tmp/$label-semver-expected.txt"
  local actual="$tmp/$label-semver-actual.txt"
  local script_dir
  script_dir="$(dirname "$script")"

  {
    if sed -n '/^semver_sort_tags()/,/^}/p' "$script" | grep -q '^semver_sort_tags()'; then
      sed -n '/^semver_sort_tags()/,/^}/p' "$script"
    elif [[ -f "$script_dir/lib/semver.sh" ]]; then
      printf 'source %q\n' "$script_dir/lib/semver.sh"
    else
      printf 'echo "semver_sort_tags unavailable for %s" >&2\n' "$script"
      printf 'exit 127\n'
    fi
    cat <<'EOF'
printf '%s\n' \
  v1.0.0-rc.10 \
  v1.0.0-alpha.1 \
  v1.0.0-beta.11 \
  v1.0.0 \
  v1.0.0-alpha \
  v1.0.0-beta \
  v1.0.0-rc.1 \
  v1.0.0-alpha.beta \
  v1.0.0-beta.2 \
  | semver_sort_tags
EOF
  } > "$sorter"

  printf '%s\n' \
    v1.0.0-alpha \
    v1.0.0-alpha.1 \
    v1.0.0-alpha.beta \
    v1.0.0-beta \
    v1.0.0-beta.2 \
    v1.0.0-beta.11 \
    v1.0.0-rc.1 \
    v1.0.0-rc.10 \
    v1.0.0 > "$expected"

  bash "$sorter" > "$actual"
  if cmp -s "$expected" "$actual"; then
    echo "  PASS: $label SemVer dotted prerelease ordering"
    pass=$((pass + 1))
  else
    echo "  FAIL: $label SemVer dotted prerelease ordering" >&2
    echo "        expected:" >&2
    sed 's/^/          /' "$expected" >&2
    echo "        got:" >&2
    sed 's/^/          /' "$actual" >&2
    fail=$((fail + 1))
  fi
}

echo "-- semver sorting --"
printf '%s\n' \
  v1.0.0-rc.10 \
  v1.0.0-alpha.1 \
  v1.0.0-beta.11 \
  v1.0.0 \
  v1.0.0-alpha \
  v1.0.0-beta \
  v1.0.0-rc.1 \
  v1.0.0-alpha.beta \
  v1.0.0-beta.2 \
  | semver_sort_tags > "$tmp/smoke-semver-actual.txt"
printf '%s\n' \
  v1.0.0-alpha \
  v1.0.0-alpha.1 \
  v1.0.0-alpha.beta \
  v1.0.0-beta \
  v1.0.0-beta.2 \
  v1.0.0-beta.11 \
  v1.0.0-rc.1 \
  v1.0.0-rc.10 \
  v1.0.0 > "$tmp/smoke-semver-expected.txt"
check "smoke-test SemVer dotted prerelease ordering" \
  cmp -s "$tmp/smoke-semver-expected.txt" "$tmp/smoke-semver-actual.txt"
check_semver_sorter "upgrade" "$repo_root/scripts/upgrade.sh"
check_semver_sorter "version-check" "$repo_root/scripts/version-check.sh"
check_semver_sorter "stepwise-smoke" "$repo_root/scripts/stepwise-smoke.sh"

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
# T041 / T042 / FR-013: scaffold seeds docs/intake-log.md from the template.
check "docs/intake-log.md present (T041/FR-013)" \
  test -f "$target/docs/intake-log.md"
check "docs/intake-log.md is non-empty" \
  bash -c "[ -s '$target/docs/intake-log.md' ]"
check "docs/intake-log.md carries canonical question-batching rule" \
  bash -c "grep -q 'Batch questions internally in docs/OPEN_QUESTIONS.md' '$target/docs/intake-log.md'"
check "docs/intake-log.md substitutes project name in title" \
  bash -c "head -1 '$target/docs/intake-log.md' | grep -q 'Acme Smoke Test'"
check "docs/intake-log.md listed in .template-customizations" \
  bash -c "grep -qE '^docs/intake-log\\.md\$' '$target/.template-customizations'"
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
check "docs/pm runtime artifacts not carried"  test ! -d "$target/docs/pm"
check "rc4 stabilization plan not carried"     test ! -f "$target/docs/v1.0-rc4-stabilization.md"
check "final checklist not carried"            test ! -f "$target/docs/v1.0.0-final-checklist.md"
check "scripts/smoke-test.sh not carried (template tool)"  test ! -f "$target/scripts/smoke-test.sh"

echo "-- content-shape --"
check "AGENTS.md present"                                  test -f "$target/AGENTS.md"
check "AGENTS.md binds Codex tech-lead"                    bash -c "grep -q 'main Codex session plays \`tech-lead\` directly' '$target/AGENTS.md'"
check "OPEN_QUESTIONS.md is empty register (no Q-0001 row)"  bash -c "! grep -q 'Q-0001' '$target/docs/OPEN_QUESTIONS.md'"
check "AGENT_NAMES.md has empty mapping table"               bash -c "grep -q '| \`tech-lead\` *|' '$target/docs/AGENT_NAMES.md'"
check "TEMPLATE_VERSION first line is a SemVer"              bash -c "head -1 '$target/TEMPLATE_VERSION' | grep -qE '^v[0-9]+\\.[0-9]+\\.[0-9]+(-[0-9A-Za-z.-]+)?(\\+[0-9A-Za-z.-]+)?$'"
check "CUSTOMER_NOTES template includes intake turn field"   bash -c "grep -q 'turn: <docs/intake-log.md turn id' '$target/CUSTOMER_NOTES.md'"

# Template version stamp should match our current VERSION
expected_version="$(tr -d '[:space:]' < VERSION)"
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
check "manifest ship-files excludes docs/pm/"             bash -c "! grep -q '^docs/pm/' '$manifest_ship_list'"
check "manifest ship-files excludes rc4 stabilization"    bash -c "! grep -q '^docs/v1\\.0-rc4-stabilization\\.md$' '$manifest_ship_list'"
check "manifest ship-files excludes final checklist"      bash -c "! grep -q '^docs/v1\\.0\\.0-final-checklist\\.md$' '$manifest_ship_list'"
check "manifest ship-files excludes role-local agents"    bash -c "! grep -q '^\\.claude/agents/.*-local\\.md\$' '$manifest_ship_list'"
manifest_worktree="$tmp/manifest-linked-worktree"
(
  # shellcheck disable=SC2317
  cleanup_manifest_worktree() {
    git -C "$repo_root" worktree remove --force "$manifest_worktree" >/dev/null 2>&1 || true
  }

  trap cleanup_manifest_worktree EXIT
  git -C "$repo_root" worktree add --detach "$manifest_worktree" HEAD >/dev/null
  bash -c "
    source '$repo_root/scripts/lib/manifest.sh'
    manifest_ship_files '$manifest_worktree' > '$tmp/manifest-worktree-ship-files.txt'
  "
)
check "manifest ship-files accepts linked worktree path"  test -s "$tmp/manifest-worktree-ship-files.txt"
check "linked worktree ship-files includes AGENTS.md"     bash -c "grep -q '^AGENTS\\.md\$' '$tmp/manifest-worktree-ship-files.txt'"

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
check "first-actions warning routes notes through researcher" \
  bash -c "source '$target/scripts/lib/first-actions.sh' && first_actions_step0_warning '$target' session | grep -q 'Route the answer to researcher'"
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
check "settings guard covers Claude MultiEdit" \
  bash -c "grep -q '\"matcher\": \"MultiEdit\"' '$target/.claude/settings.json'"
customer_notes_guard_path="\${CLAUDE_PROJECT_DIR}/scripts/hooks/customer-notes-guard.py"
version_check_path="\${CLAUDE_PROJECT_DIR}/scripts/version-check.sh"
check "settings guard commands use CLAUDE_PROJECT_DIR" \
  settings_contains_literal_path "$target" "$customer_notes_guard_path" "python3 ./scripts/hooks/customer-notes-guard.py"
check "settings SessionStart version-check uses CLAUDE_PROJECT_DIR" \
  settings_contains_literal_path "$target" "$version_check_path" "./scripts/version-check.sh"
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
guard_bash_stdin_output="$(
  printf '%s\n' '{"tool_name":"Bash","tool_input":{"command":"python3 - <<'\''PY'\''\nfrom pathlib import Path\nPath('\''CUSTOMER_NOTES.md'\'').write_text('\''x'\'')\nPY"}}' \
    | python3 "$target/scripts/hooks/customer-notes-guard.py"
)"
check "CUSTOMER_NOTES guard asks on interpreter stdin notes command" \
  bash -c "echo '$guard_bash_stdin_output' | grep -q 'permissionDecision.*ask'"
guard_bash_read_output="$(
  printf '%s\n' '{"tool_name":"Bash","tool_input":{"command":"cat CUSTOMER_NOTES.md"}}' \
    | python3 "$target/scripts/hooks/customer-notes-guard.py"
)"
check "CUSTOMER_NOTES guard stays quiet on Bash notes read" \
  bash -c "[ -z '$guard_bash_read_output' ]"

# Issue #156 — structurally-unexpected JSON must fail-open, not raise
# AttributeError. The hook's isinstance() guards cover (a) top-level
# payload not being a dict and (b) tool_input not being a dict.
guard_toplevel_list_rc=0
guard_toplevel_list_output="$(
  printf '%s' '[]' \
    | python3 "$target/scripts/hooks/customer-notes-guard.py" 2>&1
)" || guard_toplevel_list_rc=$?
check "CUSTOMER_NOTES guard fail-opens on top-level JSON list (#156)" \
  bash -c "[ '$guard_toplevel_list_rc' -eq 0 ] && [ -z '$guard_toplevel_list_output' ]"

guard_toplevel_string_rc=0
guard_toplevel_string_output="$(
  printf '%s' '"hello"' \
    | python3 "$target/scripts/hooks/customer-notes-guard.py" 2>&1
)" || guard_toplevel_string_rc=$?
check "CUSTOMER_NOTES guard fail-opens on top-level JSON string (#156)" \
  bash -c "[ '$guard_toplevel_string_rc' -eq 0 ] && [ -z '$guard_toplevel_string_output' ]"

guard_tool_input_string_rc=0
guard_tool_input_string_output="$(
  printf '%s' '{"tool_input":"CUSTOMER_NOTES.md"}' \
    | python3 "$target/scripts/hooks/customer-notes-guard.py" 2>&1
)" || guard_tool_input_string_rc=$?
check "CUSTOMER_NOTES guard fail-opens on string tool_input (#156)" \
  bash -c "[ '$guard_tool_input_string_rc' -eq 0 ] && [ -z '$guard_tool_input_string_output' ]"

guard_tool_input_list_rc=0
guard_tool_input_list_output="$(
  printf '%s' '{"tool_input":["CUSTOMER_NOTES.md"]}' \
    | python3 "$target/scripts/hooks/customer-notes-guard.py" 2>&1
)" || guard_tool_input_list_rc=$?
check "CUSTOMER_NOTES guard fail-opens on list tool_input (#156)" \
  bash -c "[ '$guard_tool_input_list_rc' -eq 0 ] && [ -z '$guard_tool_input_list_output' ]"

guard_toplevel_number_rc=0
guard_toplevel_number_output="$(
  printf '%s' '42' \
    | python3 "$target/scripts/hooks/customer-notes-guard.py" 2>&1
)" || guard_toplevel_number_rc=$?
check "CUSTOMER_NOTES guard fail-opens on top-level JSON number (#156)" \
  bash -c "[ '$guard_toplevel_number_rc' -eq 0 ] && [ -z '$guard_toplevel_number_output' ]"

# Helper: run a command capturing its exit code without tripping set -e.
# The expected nonzero exits (drift=1, missing=2, corrupt=3, bogus=2)
# would otherwise abort the smoke test under -e.
run_capture() {
  local _logfile="$1"; shift
  local _rc=0
  "$@" > "$_logfile" 2>&1 || _rc=$?
  echo "$_rc"
}

manifest_sha_for_path() {
  local manifest="$1"
  local path="$2"
  awk -v path="$path" '
    $1 ~ /^#/ { next }
    $2 == path { print $1; exit }
  ' "$manifest"
}

current_claude_sha="$(sha256sum "$target/CLAUDE.md" | awk '{print $1}')"
cat > "$target/.template-conflicts.json" <<EOF
{
  "schema": 1,
  "generated": "2026-01-01T00:00:00Z",
  "template_version": "$expected_version",
  "entries": [
    {"path": "CLAUDE.md", "classified": "conflict", "baseline_sha": "0000000000000000000000000000000000000000000000000000000000000000", "upstream_sha": "1111111111111111111111111111111111111111111111111111111111111111", "project_sha": "$current_claude_sha"}
  ]
}
EOF
resolve_unchanged_rc=$(run_capture "$tmp/resolve-unchanged.log" \
                       bash -c "cd '$target' && bash '$repo_root/scripts/upgrade.sh' --resolve")
check "upgrade.sh --resolve keeps untouched conflict entry" \
  bash -c "[ $resolve_unchanged_rc -eq 0 ] && grep -q '1 still unresolved' '$tmp/resolve-unchanged.log' && test -f '$target/.template-conflicts.json'"
rm -f "$target/.template-conflicts.json"

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

echo "-- version-check (scaffolded project produces recognised output) --"
# Run version-check in the scaffolded project. It requires network — if unavailable,
# skip the assertion rather than fail.
#
# The strict "up to date" assertion only holds when the LOCAL repo state matches
# the published remote (i.e., commits have landed on main; the PR branch HEAD is
# at remote main's HEAD). On PR branches whose HEAD is past remote main,
# version-check correctly reports "Template upgrade available" because the
# scaffolded project's stamp differs from the remote's latest released tag.
# Both outcomes are valid "version-check is working" signals; only a crash or
# unrecognised output is a real failure.
probe_url="https://github.com/occamsshavingkit/sw-dev-team-template"
[[ -n "${GH_TOKEN:-}" ]] && probe_url="https://${GH_TOKEN}@github.com/occamsshavingkit/sw-dev-team-template"
if timeout 5 git ls-remote --tags --refs "$probe_url" >/dev/null 2>&1; then
  vc_output="$(
    cd "$target"
    GH_TOKEN="${GH_TOKEN:-}" ./scripts/version-check.sh 2>&1 || true
  )"
  if echo "$vc_output" | grep -qE "up to date|Template upgrade available"; then
    echo "  PASS: version-check produced recognised output"
    pass=$((pass + 1))
  else
    echo "  FAIL: version-check produced unrecognised output (crash or unexpected pattern)"
    echo "        got: $vc_output"
    fail=$((fail + 1))
  fi
else
  echo "  SKIP: version-check (upstream unreachable)"
fi

echo "-- upgrade bootstrap args and FIRST ACTIONS warning --"
bootstrap_upstream="$tmp/bootstrap-upstream"
stable_fixture_version="v0.17.0"
final_fixture_version="v1.0.0"
mkdir -p "$bootstrap_upstream"
tar --exclude='./.git' -cf - . | (cd "$bootstrap_upstream" && tar -xf -)
(
  cd "$bootstrap_upstream"
  git init -q
  git config user.email smoke@example.invalid
  git config user.name "Smoke Test"
  printf '%s\n' "$stable_fixture_version" > VERSION
  git add .
  git commit -q -m "stable fixture"
  git tag "$stable_fixture_version"
  printf '%s\n' "$expected_version" > VERSION
  git add VERSION
  git commit -q -m "rc fixture"
  git tag "$expected_version"
  printf '%s\n' "$final_fixture_version" > VERSION
  mkdir -p migrations
  cat > migrations/v1.0.0.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
mkdir -p docs/glossary
printf 'final migration ran\n' > docs/glossary/FINAL-MIGRATION-SMOKE.md
EOF
  chmod +x migrations/v1.0.0.sh
  git add VERSION migrations/v1.0.0.sh
  git commit -q -m "final fixture"
  git tag "$final_fixture_version"
)

vc_rc_final_output="$(
  cd "$target"
  SWDT_UPSTREAM_URL="$bootstrap_upstream" ./scripts/version-check.sh 2>&1 || true
)"
if echo "$vc_rc_final_output" | grep -q "Template upgrade available: $expected_version .* $final_fixture_version"; then
  echo "  PASS: version-check orders final above rc for same base version"
  pass=$((pass + 1))
else
  echo "  FAIL: version-check did not pick final over rc for same base version"
  echo "        got: $vc_rc_final_output"
  fail=$((fail + 1))
fi

bootstrap_target="$tmp/bootstrap-target"
./scripts/scaffold.sh "$bootstrap_target" "Bootstrap Args Smoke" >/dev/null
printf 'v0.1.0\nunknown\n2026-01-01\n' > "$bootstrap_target/TEMPLATE_VERSION"
# FW-ADR-0010: pre-bootstrap 3-SHA matrix routes baseline-unreachable +
# project-edited bootstrap-critical files to "refuse" (exit 2). To exercise
# the dry-run re-exec path under the new contract, drop a bootstrap-critical
# helper so the matrix routes "missing-locally → proceed" for that one path
# (the rest of the lib stays project==upstream, which routes "noop"). The
# missing-helper case is the legitimate add-from-upstream signal that
# bootstrap is meant to handle. Predecessor fixture (`force bootstrap drift`)
# routed to baseline-unreachable refuse under the new ADR and was removed.
rm -f "$bootstrap_target/scripts/lib/first-actions.sh"
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
# FW-ADR-0010: dry-run must not install the missing helper into the project.
# (Pre-ADR-0010 fixture asserted "drift in place"; under the new contract
# the dry-run signal is the inverse — the missing-locally path stays
# missing locally on a dry-run.)
check "bootstrap dry-run leaves missing helper missing" \
  bash -c "[ ! -f '$bootstrap_target/scripts/lib/first-actions.sh' ]"
check "upgrade surfaces FIRST ACTIONS warning when Step 0 missing" \
  bash -c "grep -q 'ACTION REQUIRED: FIRST ACTIONS Step 0 is not recorded' '$tmp/bootstrap-dry-run.log'"

echo "-- upgrade manifest post-copy hashes --"
issue105_upstream="$tmp/issue105-upstream"
issue105_target="$tmp/issue105-target"
mkdir -p "$issue105_upstream"
(
  cd "$issue105_upstream"
  git -C "$repo_root" archive v1.0.0-rc3 | tar -xf -
  git init -q
  git config user.email smoke@example.invalid
  git config user.name "Smoke Test"
  git add .
  git commit -q -m "rc3 fixture"
  git tag v1.0.0-rc3
)
# Exercise the current candidate tree even before the maintainer creates
# the real prerelease tag in repo_root.
find "$issue105_upstream" -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +
tar --exclude='./.git' -cf - . | (cd "$issue105_upstream" && tar -xf -)
(
  cd "$issue105_upstream"
  git add -A
  git commit -q -m "candidate fixture"
  git tag "$expected_version"
  git checkout -q v1.0.0-rc3
  ./scripts/scaffold.sh "$issue105_target" "Issue 105 Smoke" >/dev/null
)
issue105_upgrade_rc=$(run_capture "$tmp/issue105-upgrade.log" \
                      bash -c "cd '$issue105_target' && SWDT_UPSTREAM_URL='$issue105_upstream' ./scripts/upgrade.sh --target '$expected_version'")
issue105_verify_rc=$(run_capture "$tmp/issue105-verify.log" \
                     bash -c "cd '$issue105_target' && ./scripts/upgrade.sh --verify")
issue105_manifest_sha="$(manifest_sha_for_path "$issue105_target/TEMPLATE_MANIFEST.lock" AGENTS.md)"
issue105_actual_sha="$(sha256sum "$issue105_target/AGENTS.md" | awk '{print $1}')"
check "rc3 -> $expected_version upgrade exits 0" \
  bash -c "[ $issue105_upgrade_rc -eq 0 ]"
check "rc3 -> $expected_version verify passes immediately after upgrade" \
  bash -c "[ $issue105_verify_rc -eq 0 ]"
check "manifest records final post-copy AGENTS.md hash" \
  bash -c "[ '$issue105_manifest_sha' = '$issue105_actual_sha' ]"
check "real bootstrap copies semver lib before re-exec" \
  test -f "$issue105_target/scripts/lib/semver.sh"

issue129_target="$tmp/issue129-target"
./scripts/scaffold.sh "$issue129_target" "Issue 129 Smoke" >/dev/null
printf '%s\nunknown\n2026-01-01\n' "$expected_version" > "$issue129_target/TEMPLATE_VERSION"
grep -v 'scripts/lib/semver\.sh$' "$issue129_target/TEMPLATE_MANIFEST.lock" > "$issue129_target/TEMPLATE_MANIFEST.lock.tmp"
mv "$issue129_target/TEMPLATE_MANIFEST.lock.tmp" "$issue129_target/TEMPLATE_MANIFEST.lock"
issue129_upgrade_rc=$(run_capture "$tmp/issue129-upgrade.log" \
                      bash -c "cd '$issue129_target' && SWDT_UPSTREAM_URL='$issue105_upstream' ./scripts/upgrade.sh --target '$expected_version'")
check "same-version upgrade falls through on manifest path omissions" \
  bash -c "[ $issue129_upgrade_rc -eq 0 ] && grep -q 'missing upstream shipped paths' '$tmp/issue129-upgrade.log'"
check "same-version upgrade regenerates omitted manifest path" \
  bash -c "grep -q ' scripts/lib/semver\\.sh$' '$issue129_target/TEMPLATE_MANIFEST.lock'"

echo "-- upgrade (simulate older stamp, run stable default upgrade) --"
# Simulate an older project by stamping TEMPLATE_VERSION back to v0.1.0, then
# run upgrade.sh. Verifies:
#   - upgrade completes cleanly
#   - template-only files (LICENSE, smoke-test.sh, CHANGELOG.md, VERSION,
#     CONTRIBUTING.md, migrations/, .github/) are NOT present after upgrade
#   - stable-track default chooses the final tag, not the rc tag
#   - migrations ran (we can detect the v0.1.0 glossary migration fired by
#     presence of docs/glossary/ENGINEERING.md — already there from scaffold
#     so we don't add an extra check)
if [[ -d "$bootstrap_upstream/.git" ]]; then
  printf 'v0.1.0\nunknown\n2026-01-01\n' > "$target/TEMPLATE_VERSION"
  cat > "$target/AGENTS.md" <<'EOF'
<claude-mem-context>
# Memory Context

# [acme] recent context, 2026-01-01 12:00am UTC

Generated-only downstream memory.
</claude-mem-context>
EOF
  stable_upgrade_rc=0
  (
    cd "$target"
    SWDT_UPSTREAM_URL="$bootstrap_upstream" ./scripts/upgrade.sh
  ) > "$tmp/upgrade-stable.log" 2>&1 || stable_upgrade_rc=$?
  check "stable-track default upgrade exits 0" \
    bash -c "[ $stable_upgrade_rc -eq 0 ]"
  check "stable-track default chooses latest stable final tag" \
    bash -c "grep -q 'Default target: latest stable upstream tag $final_fixture_version' '$tmp/upgrade-stable.log'"

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
  check "no docs/pm runtime artifacts after upgrade"  test ! -d "$target/docs/pm"
  check "no rc4 stabilization plan after upgrade"     test ! -f "$target/docs/v1.0-rc4-stabilization.md"
  check "no final checklist after upgrade"            test ! -f "$target/docs/v1.0.0-final-checklist.md"
  check "memory-only AGENTS.md stub replaced by adapter" \
    bash -c "grep -q 'main Codex session plays \`tech-lead\` directly' '$target/AGENTS.md'"
  check "memory-only AGENTS.md memory context preserved" \
    bash -c "grep -q 'Generated-only downstream memory' '$target/AGENTS.md'"

  # Stable default should stamp the latest final tag, not the rc tag.
  post_version="$(head -1 "$target/TEMPLATE_VERSION" | tr -d '[:space:]')"
  check "stable default stamps latest final tag ($final_fixture_version)" \
    bash -c "[ '$post_version' = '$final_fixture_version' ]"
  check "stable default does not silently promote to rc ($expected_version)" \
    bash -c "[ '$post_version' != '$expected_version' ]"

  # FW-ADR-0002 / v0.14.2: TEMPLATE_MANIFEST.lock should exist + verify clean
  # immediately after a single upgrade run, no manual regen needed.
  # This exercises migrations/v0.14.0.sh's predicted-post-sync logic.
  check "TEMPLATE_MANIFEST.lock present after upgrade"      test -f "$target/TEMPLATE_MANIFEST.lock"
  post_verify_rc=$(run_capture "$tmp/post-upgrade-verify.log" \
                   bash -c "cd '$target' && bash '$repo_root/scripts/upgrade.sh' --verify")
  check "upgrade.sh --verify clean after one upgrade run"   bash -c "[ $post_verify_rc -eq 0 ]"

  echo "-- upgrade --target rc opt-in --"
  target_rc_opt_in="$tmp/target-rc-opt-in"
  ./scripts/scaffold.sh "$target_rc_opt_in" "RC Opt-In Smoke" >/dev/null
  printf '%s\nunknown\n2026-01-01\n' "$stable_fixture_version" > "$target_rc_opt_in/TEMPLATE_VERSION"
  rc_upgrade_rc=0
  (
    cd "$target_rc_opt_in"
    SWDT_UPSTREAM_URL="$bootstrap_upstream" ./scripts/upgrade.sh --target "$expected_version"
  ) > "$tmp/upgrade-rc-target.log" 2>&1 || rc_upgrade_rc=$?
  check "explicit --target rc upgrade exits 0" \
    bash -c "[ $rc_upgrade_rc -eq 0 ]"
  check "explicit --target rc log pins rc tag" \
    bash -c "grep -q 'Pinning upgrade to --target $expected_version' '$tmp/upgrade-rc-target.log'"
  rc_post_version="$(head -1 "$target_rc_opt_in/TEMPLATE_VERSION" | tr -d '[:space:]')"
  check "explicit --target rc stamps current rc ($expected_version)" \
    bash -c "[ '$rc_post_version' = '$expected_version' ]"

  echo "-- upgrade rc-track default to final --"
  target_rc_track="$tmp/target-rc-track"
  ./scripts/scaffold.sh "$target_rc_track" "RC Track Smoke" >/dev/null
  rc_track_upgrade_rc=0
  (
    cd "$target_rc_track"
    SWDT_UPSTREAM_URL="$bootstrap_upstream" ./scripts/upgrade.sh
  ) > "$tmp/upgrade-rc-track.log" 2>&1 || rc_track_upgrade_rc=$?
  check "rc-track default upgrade exits 0" \
    bash -c "[ $rc_track_upgrade_rc -eq 0 ]"
  check "rc-track default chooses final over rc" \
    bash -c "grep -q 'Default target: latest upstream tag $final_fixture_version (pre-release track).' '$tmp/upgrade-rc-track.log'"
  rc_track_post_version="$(head -1 "$target_rc_track/TEMPLATE_VERSION" | tr -d '[:space:]')"
  check "rc-track default stamps final tag ($final_fixture_version)" \
    bash -c "[ '$rc_track_post_version' = '$final_fixture_version' ]"
  check "rc-track final migration ran" \
    test -f "$target_rc_track/docs/glossary/FINAL-MIGRATION-SMOKE.md"

  # v0.14.3 / issue #63: atomic_install via tmp+mv must not leave
  # stale .tmp.* files after upgrade.
  check "no stale .tmp.* files after upgrade"               bash -c "[ \"\$(find '$target' -name '*.tmp.*' 2>/dev/null | wc -l)\" -eq 0 ]"

  echo "-- upgrade intake-log retrofit (T041 / T042 / FR-013) --"
  # Scaffold a project, simulate an older scaffold by removing
  # docs/intake-log.md and its .template-customizations entry, then
  # run upgrade. Expect the upgrade to retrofit both.
  intake_retrofit_target="$tmp/intake-retrofit-target"
  ./scripts/scaffold.sh "$intake_retrofit_target" "Intake Retrofit Smoke" >/dev/null
  rm -f "$intake_retrofit_target/docs/intake-log.md"
  grep -v '^docs/intake-log\.md$' \
    "$intake_retrofit_target/.template-customizations" \
    > "$intake_retrofit_target/.template-customizations.tmp" \
    && mv "$intake_retrofit_target/.template-customizations.tmp" \
          "$intake_retrofit_target/.template-customizations"
  # Hand-stamp to v0.1.0 so the upgrade runs the full sync path.
  printf 'v0.1.0\nunknown\n2026-01-01\n' > "$intake_retrofit_target/TEMPLATE_VERSION"
  retrofit_rc=0
  (
    cd "$intake_retrofit_target"
    SWDT_UPSTREAM_URL="$bootstrap_upstream" ./scripts/upgrade.sh
  ) > "$tmp/upgrade-intake-retrofit.log" 2>&1 || retrofit_rc=$?
  check "upgrade with missing intake-log exits 0" \
    bash -c "[ $retrofit_rc -eq 0 ]"
  check "upgrade retrofits docs/intake-log.md when missing" \
    test -f "$intake_retrofit_target/docs/intake-log.md"
  check "retrofitted intake-log carries canonical batching rule" \
    bash -c "grep -q 'Batch questions internally in docs/OPEN_QUESTIONS.md' '$intake_retrofit_target/docs/intake-log.md'"
  check "upgrade appends docs/intake-log.md to .template-customizations" \
    bash -c "grep -qE '^docs/intake-log\\.md\$' '$intake_retrofit_target/.template-customizations'"

  # Second run: intake-log already present, .template-customizations
  # already lists it. Upgrade should NOT re-append the path (idempotent).
  cust_lines_before=$(grep -cE '^docs/intake-log\.md$' \
    "$intake_retrofit_target/.template-customizations")
  intake_sha_before=$(sha256sum "$intake_retrofit_target/docs/intake-log.md" | awk '{print $1}')
  retrofit_rc2=0
  (
    cd "$intake_retrofit_target"
    SWDT_UPSTREAM_URL="$bootstrap_upstream" ./scripts/upgrade.sh
  ) > "$tmp/upgrade-intake-retrofit-2.log" 2>&1 || retrofit_rc2=$?
  cust_lines_after=$(grep -cE '^docs/intake-log\.md$' \
    "$intake_retrofit_target/.template-customizations")
  intake_sha_after=$(sha256sum "$intake_retrofit_target/docs/intake-log.md" | awk '{print $1}')
  check "second upgrade run exits 0 (intake retrofit idempotent)" \
    bash -c "[ $retrofit_rc2 -eq 0 ]"
  check "second upgrade does not duplicate intake-log preserve entry" \
    bash -c "[ '$cust_lines_before' -eq '$cust_lines_after' ]"
  check "second upgrade does not overwrite existing intake-log content" \
    bash -c "[ '$intake_sha_before' = '$intake_sha_after' ]"

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
# T041 / FR-013: docs/intake-log.md is project-owned post-scaffold.
check "stub-fill: docs/intake-log.md in .template-customizations" \
  bash -c "grep -qE '^docs/intake-log\\.md\$' '$target/.template-customizations'"
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
