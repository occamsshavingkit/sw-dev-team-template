#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# Self-test for the additive .claude/settings.json merge embedded in
# scripts/upgrade.sh (issue #201). Extracts the inline python helper
# from upgrade.sh and exercises it against fixtures that mirror real
# downstream-project shapes:
#
#   - rc8-era project (only SessionStart customer hook present, no
#     PreToolUse) → expect 4 PreToolUse entries + 2 missing SessionStart
#     hooks added; customer entries preserved.
#   - already-current project → expect no changes.
#   - missing-hooks-block (no `hooks` key at all) → expect both
#     PreToolUse and SessionStart sections added from upstream.
#
# Mirrors test-customer-notes-guard.sh / test-tech-lead-authoring-guard.sh
# style: pass/fail accounting with a final summary, exit non-zero on
# any failure.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
UPGRADE_SH="$REPO_ROOT/scripts/upgrade.sh"
UPSTREAM_SETTINGS="$REPO_ROOT/.claude/settings.json"

pass=0
fail=0
failures=()

# Extract the embedded merge helper from upgrade.sh into a tmp file so
# we can drive it standalone. The python heredoc is delimited by
# <<'PYMERGE' ... PYMERGE — sed extracts everything between those lines.
tmp_helper="$(mktemp -t settings-merge-XXXXXX.py)"
trap 'rm -f "$tmp_helper"' EXIT
awk '/^PYMERGE$/{flag=0} flag{print} /<<.PYMERGE.$/{flag=1}' "$UPGRADE_SH" > "$tmp_helper"
if [ ! -s "$tmp_helper" ]; then
    echo "FAIL  could not extract PYMERGE helper from $UPGRADE_SH"
    exit 1
fi

# run_case <name> <fixture-builder-callback> <expect-changed: yes|no> <jq-check-callback>
#
# fixture-builder writes a JSON object to $project_settings; jq-check is
# a bash function that takes $project_settings (post-merge) and returns
# 0 on success, non-zero on failure (printing diagnostics).
run_case() {
    local name=$1
    local builder=$2
    local expect_changed=$3
    local checker=$4

    local dir
    dir="$(mktemp -d)"
    local project_settings="$dir/settings.json"

    # Invoke the builder so it writes the project-side starting state.
    "$builder" "$project_settings"

    local helper_out
    helper_out="$(python3 "$tmp_helper" "$UPSTREAM_SETTINGS" "$project_settings" 2>&1)"
    local helper_rc=$?

    local actual_changed
    if printf '%s\n' "$helper_out" | grep -q '^settings.json: framework hook wiring already current'; then
        actual_changed="no"
    elif printf '%s\n' "$helper_out" | grep -q '^settings.json: merged'; then
        actual_changed="yes"
    else
        actual_changed="unknown"
    fi

    local ok=1
    if [ "$helper_rc" -ne 0 ]; then
        ok=0
    fi
    if [ "$actual_changed" != "$expect_changed" ]; then
        ok=0
    fi
    if [ "$ok" -eq 1 ] && [ -n "$checker" ]; then
        if ! "$checker" "$project_settings"; then
            ok=0
        fi
    fi

    if [ "$ok" -eq 1 ]; then
        pass=$((pass + 1))
        echo "PASS  $name"
    else
        fail=$((fail + 1))
        failures+=("$name (expected_changed=$expect_changed actual_changed=$actual_changed rc=$helper_rc)")
        echo "FAIL  $name (expected_changed=$expect_changed actual_changed=$actual_changed rc=$helper_rc)"
        printf '      helper output:\n%s\n' "$helper_out" | sed 's/^/      /'
    fi

    rm -rf "$dir"
}

# Fixture builders --------------------------------------------------------

# rc8-era downstream: only the SessionStart version-check hook present,
# permissions block populated, no PreToolUse entries at all.
build_rc8_style() {
    cat > "$1" <<'JSON'
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  },
  "permissions": {
    "allow": [
      "Read",
      "Bash(ls *)"
    ],
    "deny": [
      "Bash(rm *)"
    ]
  },
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "[ -x ./scripts/version-check.sh ] && ./scripts/version-check.sh 2>&1 || true",
            "timeout": 10,
            "statusMessage": "Checking template version..."
          }
        ]
      }
    ]
  }
}
JSON
}

# Already-current downstream: full framework hook wiring already present.
build_current_style() {
    cp "$UPSTREAM_SETTINGS" "$1"
}

# Missing-hooks block entirely: a downstream that only configured
# permissions / env, no hooks block at all.
build_no_hooks_block() {
    cat > "$1" <<'JSON'
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  },
  "permissions": {
    "allow": ["Read"]
  }
}
JSON
}

# Mixed: some PreToolUse already wired (Write only) — merge should add
# Edit / MultiEdit / Bash but leave Write intact and not duplicate.
build_partial_pretooluse() {
    cat > "$1" <<'JSON'
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "command",
            "command": "python3 \"${CLAUDE_PROJECT_DIR}/scripts/hooks/customer-notes-guard.py\"",
            "timeout": 5
          },
          {
            "type": "command",
            "command": "python3 \"${CLAUDE_PROJECT_DIR}/scripts/hooks/tech-lead-authoring-guard.py\"",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
JSON
}

# Checkers --------------------------------------------------------------

# Generic: verify the post-merge file contains the 4 framework
# PreToolUse matchers and the framework's SessionStart hooks.
check_full_framework_wiring() {
    local f=$1
    python3 - "$f" <<'PYCHK'
import json, sys
with open(sys.argv[1]) as fh:
    s = json.load(fh)
hooks = s.get("hooks", {})
pretool = hooks.get("PreToolUse", [])
matchers = {e.get("matcher") for e in pretool}
need = {"Write", "Edit", "MultiEdit", "Bash"}
if not need.issubset(matchers):
    sys.stderr.write("missing PreToolUse matchers: %s\n" % (need - matchers))
    sys.exit(1)
# Each matcher entry must reference both guards.
for entry in pretool:
    cmds = [h.get("command", "") for h in entry.get("hooks", [])]
    if not any("tech-lead-authoring-guard.py" in c for c in cmds):
        sys.stderr.write("PreToolUse[%s] missing tech-lead-authoring-guard\n" % entry.get("matcher"))
        sys.exit(1)
    if not any("customer-notes-guard.py" in c for c in cmds):
        sys.stderr.write("PreToolUse[%s] missing customer-notes-guard\n" % entry.get("matcher"))
        sys.exit(1)
sess = hooks.get("SessionStart", [])
all_cmds = []
for e in sess:
    for h in e.get("hooks", []):
        all_cmds.append(h.get("command", ""))
joined = "\n".join(all_cmds)
need_substrings = ("atomic-question-reminder", "role-routing-reminder")
for s_ in need_substrings:
    if s_ not in joined:
        sys.stderr.write("missing SessionStart hook substring: %s\n" % s_)
        sys.exit(1)
PYCHK
}

# rc8-style: also verify the customer's env + permissions block survived
# the merge, and the customer's version-check hook is still present.
check_customer_preserved() {
    local f=$1
    if ! check_full_framework_wiring "$f"; then return 1; fi
    python3 - "$f" <<'PYCHK'
import json, sys
with open(sys.argv[1]) as fh:
    s = json.load(fh)
if s.get("env", {}).get("CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS") != "1":
    sys.stderr.write("customer env not preserved\n")
    sys.exit(1)
allow = s.get("permissions", {}).get("allow") or []
deny = s.get("permissions", {}).get("deny") or []
if "Read" not in allow or "Bash(ls *)" not in allow:
    sys.stderr.write("customer permissions.allow not preserved\n")
    sys.exit(1)
if "Bash(rm *)" not in deny:
    sys.stderr.write("customer permissions.deny not preserved\n")
    sys.exit(1)
PYCHK
}

# partial: Write entry must NOT have duplicate guard commands.
check_no_duplicate_write_hooks() {
    local f=$1
    if ! check_full_framework_wiring "$f"; then return 1; fi
    python3 - "$f" <<'PYCHK'
import json, sys
with open(sys.argv[1]) as fh:
    s = json.load(fh)
pretool = s["hooks"]["PreToolUse"]
write_entries = [e for e in pretool if e.get("matcher") == "Write"]
if len(write_entries) != 1:
    sys.stderr.write("expected 1 Write entry, got %d\n" % len(write_entries))
    sys.exit(1)
cmds = [h.get("command") for h in write_entries[0].get("hooks", [])]
# Each guard must appear exactly once.
for needle in ("tech-lead-authoring-guard.py", "customer-notes-guard.py"):
    count = sum(1 for c in cmds if needle in c)
    if count != 1:
        sys.stderr.write("%s appears %d times under Write (expected 1)\n" % (needle, count))
        sys.exit(1)
PYCHK
}

# Verifies no rewrite — file content unchanged from build_current_style.
check_unchanged_from_upstream() {
    local f=$1
    if ! diff -q "$f" "$UPSTREAM_SETTINGS" >/dev/null 2>&1; then
        # The merge may have re-pretty-printed; compare canonical JSON.
        python3 - "$f" "$UPSTREAM_SETTINGS" <<'PYCHK'
import json, sys
with open(sys.argv[1]) as a, open(sys.argv[2]) as b:
    aj = json.load(a); bj = json.load(b)
if aj != bj:
    sys.stderr.write("post-merge file differs from upstream after no-op merge\n")
    sys.exit(1)
PYCHK
    fi
}

# Test cases -----------------------------------------------------------

run_case "rc8-style downstream: full framework wiring added, customer preserved" \
    build_rc8_style yes check_customer_preserved

run_case "already-current downstream: no-op merge" \
    build_current_style no check_unchanged_from_upstream

run_case "no hooks block at all: PreToolUse + SessionStart added" \
    build_no_hooks_block yes check_full_framework_wiring

run_case "partial PreToolUse (Write only): missing matchers added, Write not duplicated" \
    build_partial_pretooluse yes check_no_duplicate_write_hooks

# Idempotency: re-running merge after a successful merge is a no-op.
idempotency_dir="$(mktemp -d)"
trap 'rm -f "$tmp_helper"; rm -rf "$idempotency_dir"' EXIT
idempotency_file="$idempotency_dir/settings.json"
build_rc8_style "$idempotency_file"
python3 "$tmp_helper" "$UPSTREAM_SETTINGS" "$idempotency_file" >/dev/null 2>&1
first_rc=$?
second_out="$(python3 "$tmp_helper" "$UPSTREAM_SETTINGS" "$idempotency_file" 2>&1)"
second_rc=$?
if [ "$first_rc" -eq 0 ] && [ "$second_rc" -eq 0 ] \
   && printf '%s' "$second_out" | grep -q '^settings.json: framework hook wiring already current'; then
    pass=$((pass + 1))
    echo "PASS  idempotency: second merge is a no-op"
else
    fail=$((fail + 1))
    failures+=("idempotency: second merge should be no-op (first_rc=$first_rc second_rc=$second_rc out=$second_out)")
    echo "FAIL  idempotency: second merge should be no-op"
fi

echo
echo "settings-merge self-test: $pass passed, $fail failed."
if [ "$fail" -gt 0 ]; then
    echo
    echo "Failures:"
    for f in "${failures[@]}"; do
        echo "  - $f"
    done
    exit 1
fi
exit 0
