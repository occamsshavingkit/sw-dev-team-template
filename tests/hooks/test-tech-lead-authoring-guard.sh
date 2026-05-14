#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# Self-test for scripts/hooks/tech-lead-authoring-guard.py (FW-ADR-0012).
# Mirrors the customer-notes-guard.py harness pattern: feed crafted JSON
# tool-input payloads on stdin, assert exit code 0 (the hook always exits
# 0 — the harness reads permissionDecision from stdout) and inspect
# stdout for the expected decision shape.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HOOK="$REPO_ROOT/scripts/hooks/tech-lead-authoring-guard.py"
export CLAUDE_PROJECT_DIR="$REPO_ROOT"

pass=0
fail=0
failures=()

# run_case <name> <env-line> <stdin-json> <expect-decision: proceed|deny> [<expect-stderr-substr>]
#
# <env-line> is a single whitespace-delimited string of KEY=VALUE pairs (or
# empty). It is split on whitespace into a bash array so each KEY=VALUE
# token reaches `env` as a separate argv element. The previous unquoted
# `$env_line` expansion (Codacy PR #173 HIGH-RISK shell-injection) is gone:
# unquoted expansion is susceptible to glob expansion and IFS surprises.
run_case() {
    local name=$1
    local env_line=$2
    local stdin=$3
    local expect=$4
    local stderr_substr=${5:-}

    local stdout stderr rc
    local tmp_out tmp_err
    tmp_out=$(mktemp)
    tmp_err=$(mktemp)

    if [ -n "$env_line" ]; then
        # Word-split env_line into an array with explicit IFS scope, then
        # pass the array elements as separate args to `env`. Quoting the
        # array expansion prevents glob/IFS surprises while still letting
        # multiple KEY=VAL tokens through as distinct argv elements.
        local -a env_args=()
        local _old_ifs=$IFS
        IFS=' 	'
        # shellcheck disable=SC2206  # intentional word-split of env_line
        env_args=( $env_line )
        IFS=$_old_ifs
        printf '%s' "$stdin" | env "${env_args[@]}" python3 "$HOOK" >"$tmp_out" 2>"$tmp_err"
    else
        # Explicitly clear the escape hatch so it can't leak in from the
        # caller's environment.
        printf '%s' "$stdin" | env -u SWDT_AGENT_PUSH python3 "$HOOK" >"$tmp_out" 2>"$tmp_err"
    fi
    rc=$?
    stdout=$(cat "$tmp_out")
    stderr=$(cat "$tmp_err")
    rm -f "$tmp_out" "$tmp_err"

    local actual
    if [ -z "$stdout" ]; then
        actual="proceed"
    elif printf '%s' "$stdout" | grep -q '"permissionDecision": "deny"'; then
        actual="deny"
    elif printf '%s' "$stdout" | grep -q '"permissionDecision": "ask"'; then
        actual="ask"
    else
        actual="unknown"
    fi

    local ok=1
    if [ "$actual" != "$expect" ]; then
        ok=0
    fi
    if [ "$rc" -ne 0 ]; then
        ok=0
    fi
    if [ -n "$stderr_substr" ] && ! printf '%s' "$stderr" | grep -q "$stderr_substr"; then
        ok=0
    fi

    if [ "$ok" -eq 1 ]; then
        pass=$((pass + 1))
        echo "PASS  $name"
    else
        fail=$((fail + 1))
        failures+=("$name (expected=$expect actual=$actual rc=$rc stderr=$stderr stdout=$stdout)")
        echo "FAIL  $name"
        echo "      expected=$expect actual=$actual rc=$rc"
        [ -n "$stderr" ] && echo "      stderr: $stderr"
        [ -n "$stdout" ] && echo "      stdout: $stdout"
    fi
}

# ---------------------------------------------------------------------------
# Allow-list paths — proceed.
# ---------------------------------------------------------------------------

run_case "allow: docs/OPEN_QUESTIONS.md" "" \
    '{"tool_input":{"file_path":"docs/OPEN_QUESTIONS.md","content":"x"}}' \
    proceed

run_case "allow: docs/intake-log.md" "" \
    '{"tool_input":{"file_path":"docs/intake-log.md","content":"x"}}' \
    proceed

run_case "allow: docs/DECISIONS.md" "" \
    '{"tool_input":{"file_path":"docs/DECISIONS.md","content":"x"}}' \
    proceed

run_case "allow: docs/pm/dispatch-log.md" "" \
    '{"tool_input":{"file_path":"docs/pm/dispatch-log.md","content":"x"}}' \
    proceed

run_case "allow: TEMPLATE_VERSION" "" \
    '{"tool_input":{"file_path":"TEMPLATE_VERSION","content":"x"}}' \
    proceed

run_case "allow: docs/AGENT_NAMES.md" "" \
    '{"tool_input":{"file_path":"docs/AGENT_NAMES.md","content":"x"}}' \
    proceed

run_case "allow: docs/pm/intake-foo.md (glob)" "" \
    '{"tool_input":{"file_path":"docs/pm/intake-foo.md","content":"x"}}' \
    proceed

run_case "allow: docs/pm/intake-foo.local.md (glob)" "" \
    '{"tool_input":{"file_path":"docs/pm/intake-foo.local.md","content":"x"}}' \
    proceed

run_case "allow: docs/tech-lead/anything.md" "" \
    '{"tool_input":{"file_path":"docs/tech-lead/anything.md","content":"x"}}' \
    proceed

run_case "allow: docs/tech-lead/nested/deep.md" "" \
    '{"tool_input":{"file_path":"docs/tech-lead/nested/deep.md","content":"x"}}' \
    proceed

run_case "allow: docs/tasks/T-0042.md" "" \
    '{"tool_input":{"file_path":"docs/tasks/T-0042.md","content":"x"}}' \
    proceed

# ---------------------------------------------------------------------------
# Off-list paths — deny with specialist hint.
# ---------------------------------------------------------------------------

run_case "deny: scripts/foo.sh → software-engineer" "" \
    '{"tool_input":{"file_path":"scripts/foo.sh","content":"#!/bin/sh"}}' \
    deny

# Inspect the deny payload for the routing hint explicitly.
hint_out=$(printf '%s' '{"tool_input":{"file_path":"scripts/foo.sh","content":"x"}}' \
    | env -u SWDT_AGENT_PUSH python3 "$HOOK")
if printf '%s' "$hint_out" | grep -q "software-engineer"; then
    pass=$((pass + 1))
    echo "PASS  deny payload names software-engineer for scripts/foo.sh"
else
    fail=$((fail + 1))
    failures+=("deny payload missing software-engineer hint")
    echo "FAIL  deny payload missing software-engineer hint: $hint_out"
fi

run_case "deny: docs/adr/fw-adr-XXXX.md → architect" "" \
    '{"tool_input":{"file_path":"docs/adr/fw-adr-XXXX.md","content":"x"}}' \
    deny

hint_out=$(printf '%s' '{"tool_input":{"file_path":"docs/adr/fw-adr-XXXX.md","content":"x"}}' \
    | env -u SWDT_AGENT_PUSH python3 "$HOOK")
if printf '%s' "$hint_out" | grep -q "architect"; then
    pass=$((pass + 1))
    echo "PASS  deny payload names architect for docs/adr/..."
else
    fail=$((fail + 1))
    failures+=("deny payload missing architect hint")
    echo "FAIL  deny payload missing architect hint: $hint_out"
fi

run_case "deny: src/foo.py → software-engineer" "" \
    '{"tool_input":{"file_path":"src/foo.py","content":"print(1)"}}' \
    deny

run_case "deny: CHANGELOG.md → tech-writer" "" \
    '{"tool_input":{"file_path":"CHANGELOG.md","content":"x"}}' \
    deny

run_case "deny: tests/foo.sh → qa-engineer" "" \
    '{"tool_input":{"file_path":"tests/foo.sh","content":"x"}}' \
    deny

run_case "deny: .github/workflows/ci.yml → release-engineer" "" \
    '{"tool_input":{"file_path":".github/workflows/ci.yml","content":"x"}}' \
    deny

run_case "deny: docs/security/threat-model.md → security-engineer" "" \
    '{"tool_input":{"file_path":"docs/security/threat-model.md","content":"x"}}' \
    deny

# ---------------------------------------------------------------------------
# Escape hatch — SWDT_AGENT_PUSH widens, proceed + audit log line.
# ---------------------------------------------------------------------------

run_case "escape: scripts/foo.sh with SWDT_AGENT_PUSH=software-engineer" \
    "SWDT_AGENT_PUSH=software-engineer" \
    '{"tool_input":{"file_path":"scripts/foo.sh","content":"x"}}' \
    proceed \
    "SWDT_AGENT_PUSH=software-engineer"

run_case "escape: docs/adr/foo.md with SWDT_AGENT_PUSH=architect" \
    "SWDT_AGENT_PUSH=architect" \
    '{"tool_input":{"file_path":"docs/adr/foo.md","content":"x"}}' \
    proceed \
    "SWDT_AGENT_PUSH=architect"

run_case "escape: unrecognised role falls back to deny" \
    "SWDT_AGENT_PUSH=not-a-role" \
    '{"tool_input":{"file_path":"scripts/foo.sh","content":"x"}}' \
    deny

run_case "escape: sme-brewing role accepted" \
    "SWDT_AGENT_PUSH=sme-brewing" \
    '{"tool_input":{"file_path":"src/foo.py","content":"x"}}' \
    proceed \
    "SWDT_AGENT_PUSH=sme-brewing"

# ---------------------------------------------------------------------------
# Bash write-pattern detection.
# ---------------------------------------------------------------------------

run_case "deny: bash heredoc to src/foo.py" "" \
    '{"tool_input":{"command":"python3 <<EOF\nopen(\"src/foo.py\",\"w\").write(\"x\")\nEOF"}}' \
    deny

run_case "deny: bash redirect to src/foo.py" "" \
    '{"tool_input":{"command":"echo bad > src/foo.py"}}' \
    deny

run_case "deny: bash append to scripts/foo.sh" "" \
    '{"tool_input":{"command":"echo more >> scripts/foo.sh"}}' \
    deny

run_case "deny: tee to src/foo.py" "" \
    '{"tool_input":{"command":"echo bad | tee src/foo.py"}}' \
    deny

run_case "deny: sed -i on src/foo.py" "" \
    '{"tool_input":{"command":"sed -i s/x/y/ src/foo.py"}}' \
    deny

run_case "deny: rm on src/foo.py" "" \
    '{"tool_input":{"command":"rm src/foo.py"}}' \
    deny

run_case "proceed: bash redirect to docs/OPEN_QUESTIONS.md" "" \
    '{"tool_input":{"command":"echo q >> docs/OPEN_QUESTIONS.md"}}' \
    proceed

run_case "proceed: bash redirect to docs/tech-lead/notes.md" "" \
    '{"tool_input":{"command":"echo note >> docs/tech-lead/notes.md"}}' \
    proceed

run_case "proceed: read-only bash (grep) does not trigger" "" \
    '{"tool_input":{"command":"grep -r foo src/"}}' \
    proceed

run_case "escape: bash heredoc with SWDT_AGENT_PUSH=software-engineer" \
    "SWDT_AGENT_PUSH=software-engineer" \
    '{"tool_input":{"command":"cat > src/foo.py <<EOF\nx=1\nEOF"}}' \
    proceed \
    "SWDT_AGENT_PUSH=software-engineer"

# ---------------------------------------------------------------------------
# CUSTOMER_NOTES.md handling — defer to customer-notes-guard.
# ---------------------------------------------------------------------------

run_case "defer: CUSTOMER_NOTES.md path (no escape hatch)" "" \
    '{"tool_input":{"file_path":"CUSTOMER_NOTES.md","content":"x"}}' \
    proceed

run_case "defer: CUSTOMER_NOTES.md with SWDT_AGENT_PUSH=architect" \
    "SWDT_AGENT_PUSH=architect" \
    '{"tool_input":{"file_path":"CUSTOMER_NOTES.md","content":"x"}}' \
    proceed

run_case "defer: CUSTOMER_NOTES.md bash write" "" \
    '{"tool_input":{"command":"echo x >> CUSTOMER_NOTES.md"}}' \
    proceed

# ---------------------------------------------------------------------------
# Malformed payloads — fail open.
# ---------------------------------------------------------------------------

run_case "fail-open: malformed JSON" "" "not json" proceed
run_case "fail-open: empty stdin" "" "" proceed
run_case "fail-open: non-dict event" "" '[]' proceed
run_case "fail-open: missing tool_input" "" '{}' proceed

# ---------------------------------------------------------------------------
# Regression: Codacy PR #173 HIGH-RISK bypass cases.
# ---------------------------------------------------------------------------

# Bug 1 — MultiEdit / multi-target tool_input.
#
# Per the Claude Code tool spec, MultiEdit is single-file (one top-level
# `file_path` plus an `edits` array of {old_string, new_string} pairs
# applied to that one file). Codacy assumed multi-file, so we cover both
# readings: the spec-correct case (MultiEdit on an allow-listed file
# proceeds) AND the defense-in-depth case (off-list `file_path` inside any
# nested array entry must deny, in case a future tool revision actually
# carries per-entry paths).
run_case "allow: MultiEdit single-file on docs/OPEN_QUESTIONS.md (spec shape)" "" \
    '{"tool_input":{"file_path":"docs/OPEN_QUESTIONS.md","edits":[{"old_string":"a","new_string":"b"},{"old_string":"c","new_string":"d"}]}}' \
    proceed

run_case "deny: MultiEdit-style multi-file (top allow-listed, nested entry off-list)" "" \
    '{"tool_input":{"file_path":"docs/OPEN_QUESTIONS.md","edits":[{"file_path":"scripts/evil.sh","old_string":"x","new_string":"y"}]}}' \
    deny

run_case "deny: changes array with off-list entry" "" \
    '{"tool_input":{"changes":[{"file_path":"docs/OPEN_QUESTIONS.md"},{"file_path":"scripts/evil.sh"}]}}' \
    deny

run_case "deny: files array with off-list entry" "" \
    '{"tool_input":{"files":[{"path":"scripts/evil.sh","content":"x"}]}}' \
    deny

# Bug 2 — tee multi-target loop must NOT break after first allow-listed
# file. Operator could otherwise prefix an allow-listed target to smuggle
# off-list writes.
run_case "deny: tee allow-listed THEN off-list (first allow-listed bypass)" "" \
    '{"tool_input":{"command":"echo x | tee docs/OPEN_QUESTIONS.md scripts/evil.sh"}}' \
    deny

run_case "deny: tee off-list THEN allow-listed" "" \
    '{"tool_input":{"command":"echo x | tee scripts/evil.sh docs/OPEN_QUESTIONS.md"}}' \
    deny

run_case "proceed: tee with two allow-listed targets" "" \
    '{"tool_input":{"command":"echo x | tee docs/OPEN_QUESTIONS.md docs/intake-log.md"}}' \
    proceed

run_case "deny: tee -a allow-listed THEN off-list" "" \
    '{"tool_input":{"command":"echo x | tee -a docs/OPEN_QUESTIONS.md scripts/evil.sh"}}' \
    deny

# ---------------------------------------------------------------------------
# Path-to-role mapping coverage — every branch of _owning_specialist.
#
# After the table-driven refactor (Codacy MEDIUM-RISK on PR #173) we
# assert the deny payload names the exact role for one path per rule,
# plus the fallback. Six rules + fallback = 7 cases.
# ---------------------------------------------------------------------------

# expect_role <name> <path> <expected-role-string>
expect_role() {
    local name=$1
    local path=$2
    local role=$3
    local payload
    payload=$(printf '{"tool_input":{"file_path":"%s","content":"x"}}' "$path" \
        | env -u SWDT_AGENT_PUSH python3 "$HOOK")
    if printf '%s' "$payload" | grep -q "Dispatch '$role'"; then
        pass=$((pass + 1))
        echo "PASS  $name (-> $role)"
    else
        fail=$((fail + 1))
        failures+=("$name expected role=$role payload=$payload")
        echo "FAIL  $name expected role=$role"
        echo "      payload: $payload"
    fi
}

expect_role "owning: docs/adr/foo.md"          "docs/adr/foo.md"          "architect"
expect_role "owning: tests/foo.sh"             "tests/foo.sh"             "qa-engineer"
expect_role "owning: .github/workflows/ci.yml" ".github/workflows/ci.yml" "release-engineer"
expect_role "owning: docs/security/x.md"       "docs/security/x.md"       "security-engineer"
expect_role "owning: scripts/foo.sh"           "scripts/foo.sh"           "software-engineer"
expect_role "owning: src/foo.py"               "src/foo.py"               "software-engineer"
expect_role "owning: CHANGELOG.md"             "CHANGELOG.md"             "tech-writer"
expect_role "owning: docs/random.md"           "docs/random.md"           "tech-writer"
expect_role "owning: fallback README-top"      "weird-top-level-file.bin" "the appropriate specialist"

# ---------------------------------------------------------------------------
# Regression: upstream issues #175 / #176 — false-positive over-block and
# inline SWDT_AGENT_PUSH carve-out.
# ---------------------------------------------------------------------------

# #175 bug 1: heredoc body containing arbitrary path-looking tokens (e.g.
# a path mentioned in a commit-message body) is data, not a write target.
# The heredoc detector previously fired on ANY interpreter+heredoc pattern
# and extracted every quoted path token from the entire command.
run_case "issue#175: heredoc body with quoted path token (no write)" "" \
    '{"tool_input":{"command":"bash -c \"echo hi\" <<EOF\nthis mentions '"'"'src/file.py'"'"' which is fine\nEOF"}}' \
    proceed

run_case "issue#175: git commit -m with heredoc-quoted path token" "" \
    '{"tool_input":{"command":"git commit -m \"$(cat <<'"'"'EOF'"'"'\nfix(scripts/foo.sh): tidy\nEOF\n)\""}}' \
    proceed

# #175 bug 2: read-only open() inside `-c` argument is not a write.
run_case "issue#175: python3 -c read-only open allows" "" \
    '{"tool_input":{"command":"python3 -c \"import json; json.load(open('"'"'foo.json'"'"'))\""}}' \
    proceed

run_case "issue#175: node -e read-only fs call allows" "" \
    '{"tool_input":{"command":"node -e \"require('"'"'fs'"'"').readFileSync('"'"'src/foo.js'"'"')\""}}' \
    proceed

# Preserve the real protection: write-mode open() inside `-c` still denies.
run_case "issue#175: python3 -c open(...,'w') still denies" "" \
    '{"tool_input":{"command":"python3 -c \"open('"'"'src/foo.py'"'"','"'"'w'"'"').write('"'"'x'"'"')\""}}' \
    deny

run_case "issue#175: python3 -c open(...,'a') still denies" "" \
    '{"tool_input":{"command":"python3 -c \"open('"'"'src/foo.py'"'"','"'"'a'"'"').write('"'"'x'"'"')\""}}' \
    deny

# Heredoc fed to an interpreter that performs a real write still denies.
run_case "issue#175: python <<EOF write open still denies" "" \
    '{"tool_input":{"command":"python3 <<EOF\nopen('"'"'src/foo.py'"'"','"'"'w'"'"').write('"'"'x'"'"')\nEOF"}}' \
    deny

# Heredoc fed to an interpreter that only reads is now permitted.
run_case "issue#175: python <<EOF read-only allows" "" \
    '{"tool_input":{"command":"python3 <<EOF\nopen('"'"'src/foo.py'"'"').read()\nEOF"}}' \
    proceed

# #176: inline SWDT_AGENT_PUSH=role on the same Bash command honors the
# escape hatch (behavioural fix; matches natural reading of the deny
# diagnostic).
run_case "issue#176: inline SWDT_AGENT_PUSH=role allows write" "" \
    '{"tool_input":{"command":"SWDT_AGENT_PUSH=release-engineer echo x > src/foo.py"}}' \
    proceed \
    "SWDT_AGENT_PUSH=release-engineer"

run_case "issue#176: inline export SWDT_AGENT_PUSH=role allows write" "" \
    '{"tool_input":{"command":"export SWDT_AGENT_PUSH=software-engineer; echo x > src/foo.py"}}' \
    proceed \
    "SWDT_AGENT_PUSH=software-engineer"

run_case "issue#176: inline SWDT_AGENT_PUSH=sme-brewing allowed" "" \
    '{"tool_input":{"command":"SWDT_AGENT_PUSH=sme-brewing echo x > src/foo.py"}}' \
    proceed \
    "SWDT_AGENT_PUSH=sme-brewing"

run_case "issue#176: inline SWDT_AGENT_PUSH=not-a-role still denies" "" \
    '{"tool_input":{"command":"SWDT_AGENT_PUSH=not-a-role echo x > src/foo.py"}}' \
    deny

# Real-write protection regression: `cat > FILE <<EOF ... EOF` still denies
# because the top-level redirect extractor catches the `> FILE`.
run_case "regression: cat > off-list <<EOF still denies" "" \
    '{"tool_input":{"command":"cat > src/foo.py <<EOF\nx=1\nEOF"}}' \
    deny

# ---------------------------------------------------------------------------
# Code-reviewer tightening #2: tech-lead self-push must NOT escape-hatch.
# The guard exists to restrain tech-lead; a self-push defeats it. Both the
# env-form and the inline-form must deny.
# ---------------------------------------------------------------------------

run_case "tightening#2: env-form SWDT_AGENT_PUSH=tech-lead denies" \
    "SWDT_AGENT_PUSH=tech-lead" \
    '{"tool_input":{"file_path":"scripts/foo.py","content":"x"}}' \
    deny

run_case "tightening#2: env-form SWDT_AGENT_PUSH=tech-lead denies bash write" \
    "SWDT_AGENT_PUSH=tech-lead" \
    '{"tool_input":{"command":"echo x > scripts/foo.py"}}' \
    deny

run_case "tightening#2: inline SWDT_AGENT_PUSH=tech-lead denies" "" \
    '{"tool_input":{"command":"SWDT_AGENT_PUSH=tech-lead echo x > scripts/foo.py"}}' \
    deny

run_case "tightening#2: inline export SWDT_AGENT_PUSH=tech-lead denies" "" \
    '{"tool_input":{"command":"export SWDT_AGENT_PUSH=tech-lead; echo x > scripts/foo.py"}}' \
    deny

# ---------------------------------------------------------------------------
# Code-reviewer tightening #4: kwarg mode= form must be caught.
# Positional ``open('path', 'w')`` was already covered; the kwarg spelling
# ``open('path', mode='w')`` previously slipped through as read-only.
# Also verifies positional binary modes (``'wb'``) still deny.
# ---------------------------------------------------------------------------

run_case "tightening#4: python3 -c open(p, mode='w') denies" "" \
    '{"tool_input":{"command":"python3 -c \"open('"'"'src/foo.py'"'"', mode='"'"'w'"'"').write('"'"'x'"'"')\""}}' \
    deny

run_case "tightening#4: python3 -c open(p, mode='a') denies" "" \
    '{"tool_input":{"command":"python3 -c \"open('"'"'src/foo.py'"'"', mode='"'"'a'"'"').write('"'"'x'"'"')\""}}' \
    deny

run_case "tightening#4: python3 -c open(p, mode='r') allows (read-only kwarg)" "" \
    '{"tool_input":{"command":"python3 -c \"open('"'"'src/foo.py'"'"', mode='"'"'r'"'"').read()\""}}' \
    proceed

run_case "tightening#4: python <<EOF open(p, mode='w') denies (heredoc body)" "" \
    '{"tool_input":{"command":"python3 <<EOF\nopen('"'"'src/foo.py'"'"', mode='"'"'w'"'"').write('"'"'x'"'"')\nEOF"}}' \
    deny

run_case "tightening#4: python <<EOF open(p, mode='r') allows (read-only heredoc)" "" \
    '{"tool_input":{"command":"python3 <<EOF\nopen('"'"'src/foo.py'"'"', mode='"'"'r'"'"').read()\nEOF"}}' \
    proceed

# Binary write modes (positional) must also deny — confirms 'wb' / 'ab' /
# 'xb' / 'wb+' all still trip the existing positional regex (the mode
# capture allows non-write chars alongside the write-mode char).
run_case "tightening#4: python3 -c open(p, 'wb') denies (positional binary)" "" \
    '{"tool_input":{"command":"python3 -c \"open('"'"'src/foo.py'"'"', '"'"'wb'"'"').write(b'"'"'x'"'"')\""}}' \
    deny

run_case "tightening#4: python3 -c open(p, 'ab') denies (positional binary append)" "" \
    '{"tool_input":{"command":"python3 -c \"open('"'"'src/foo.py'"'"', '"'"'ab'"'"').write(b'"'"'x'"'"')\""}}' \
    deny

run_case "tightening#4: python3 -c open(p, mode='wb') denies (kwarg binary)" "" \
    '{"tool_input":{"command":"python3 -c \"open('"'"'src/foo.py'"'"', mode='"'"'wb'"'"').write(b'"'"'x'"'"')\""}}' \
    deny

# kwarg ordering with extra kwargs between path and mode= must still trip.
run_case "tightening#4: open(p, buffering=0, mode='w') denies" "" \
    '{"tool_input":{"command":"python3 -c \"open('"'"'src/foo.py'"'"', buffering=0, mode='"'"'w'"'"').write('"'"'x'"'"')\""}}' \
    deny

# ---------------------------------------------------------------------------
# Summary.
# ---------------------------------------------------------------------------

echo
echo "tech-lead-authoring-guard self-test: $pass passed, $fail failed."
if [ "$fail" -gt 0 ]; then
    echo
    echo "Failures:"
    for f in "${failures[@]}"; do
        echo "  - $f"
    done
    exit 1
fi
exit 0
