#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# Self-test for scripts/hooks/customer-notes-guard.py — read-vs-write
# distinction (issues #111, #175 sister, #182). Mirrors the
# tech-lead-authoring-guard.py harness pattern: feed crafted JSON
# tool-input payloads on stdin, assert exit code 0 and inspect stdout
# for `permissionDecision: "ask"` (FIRE) or empty (PROCEED).
#
# The hook ALWAYS exits 0; the gate decision is conveyed in stdout.
# Case payloads are built by a small python helper so we don't have to
# wrangle shell escaping for the inner-quoted bodies the hook is
# designed to discriminate.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HOOK="$REPO_ROOT/scripts/hooks/customer-notes-guard.py"

pass=0
fail=0
failures=()

# Build a tool_input JSON payload from a raw command string. Uses python
# to do JSON encoding so we don't have to escape `"` and `\` in shell.
mkpayload() {
    python3 -c 'import json,sys; print(json.dumps({"tool_input":{"command":sys.argv[1]}}))' "$1"
}

mkpayload_file() {
    python3 -c 'import json,sys; print(json.dumps({"tool_input":{"file_path":sys.argv[1]}}))' "$1"
}

mkpayload_path() {
    python3 -c 'import json,sys; print(json.dumps({"tool_input":{"path":sys.argv[1]}}))' "$1"
}

# run_cmd_case <name> <command-literal> <expect: fire|proceed>
run_cmd_case() {
    local name=$1
    local cmd=$2
    local expect=$3
    _run_payload "$name" "$(mkpayload "$cmd")" "$expect"
}

_run_payload() {
    local name=$1
    local payload=$2
    local expect=$3
    local tmp_out rc stdout actual
    tmp_out=$(mktemp)
    printf '%s' "$payload" | python3 "$HOOK" >"$tmp_out" 2>/dev/null
    rc=$?
    stdout=$(cat "$tmp_out")
    rm -f "$tmp_out"
    if [ -z "$stdout" ]; then
        actual="proceed"
    elif printf '%s' "$stdout" | grep -q '"permissionDecision": "ask"'; then
        actual="fire"
    else
        actual="unknown"
    fi
    if [ "$actual" = "$expect" ] && [ "$rc" -eq 0 ]; then
        pass=$((pass + 1))
        echo "PASS  $name"
    else
        fail=$((fail + 1))
        failures+=("$name (expected=$expect actual=$actual rc=$rc)")
        echo "FAIL  $name (expected=$expect actual=$actual rc=$rc)"
        [ -n "$stdout" ] && echo "      stdout: $stdout"
    fi
}

# ---------------------------------------------------------------------------
# Reads — must proceed (#111 + #182).
# ---------------------------------------------------------------------------

run_cmd_case "read: grep CUSTOMER_NOTES.md (#111)" \
    'grep -n researcher CUSTOMER_NOTES.md' proceed

run_cmd_case "read: wc -l CUSTOMER_NOTES.md (#111)" \
    'wc -l CUSTOMER_NOTES.md' proceed

run_cmd_case "read: cat CUSTOMER_NOTES.md (#111)" \
    'cat CUSTOMER_NOTES.md' proceed

run_cmd_case "read: head -5 CUSTOMER_NOTES.md (#111)" \
    'head -5 CUSTOMER_NOTES.md' proceed

run_cmd_case "read: diff a CUSTOMER_NOTES.md (#111)" \
    'diff -u a CUSTOMER_NOTES.md' proceed

run_cmd_case "read: sed -n print CUSTOMER_NOTES.md (#111)" \
    'sed -n 1,40p CUSTOMER_NOTES.md' proceed

# Interpreter-inline read forms — the #182 false-positive class.
run_cmd_case "read: python3 -c json.load(open(file)) (#182)" \
    'python3 -c "import json; json.load(open(\"CUSTOMER_NOTES.md\"))"' proceed

run_cmd_case "read: python3 -c print mentioning file (#182)" \
    'python3 -c "print(\"reads CUSTOMER_NOTES.md\")"' proceed

run_cmd_case "read: node -e console.log mentioning file (#182)" \
    'node -e "console.log(\"opening CUSTOMER_NOTES.md\")"' proceed

run_cmd_case "read: sh -c cat | head (#182)" \
    "sh -c 'cat CUSTOMER_NOTES.md | head -5'" proceed

run_cmd_case "read: python3 heredoc open(file).read() (#182)" \
    'python3 <<PY
open("CUSTOMER_NOTES.md").read()
PY' proceed

run_cmd_case "read: bash -c with cat (#182)" \
    "bash -c 'cat CUSTOMER_NOTES.md | wc -l'" proceed

# Prose / data — must proceed.
run_cmd_case "prose: cat heredoc body mentioning file" \
    'cat <<EOF
this mentions CUSTOMER_NOTES.md but writes nowhere
EOF' proceed

# Single-quoted literal payload — `$(cat <<EOF ...)` is data fed to the
# guard under test, not a shell expansion.
# shellcheck disable=SC2016
run_cmd_case "prose: git commit -m with heredoc body mentioning file" \
    'git commit -m "$(cat <<EOF
docs: ref CUSTOMER_NOTES.md
EOF
)"' proceed

run_cmd_case "prose: shell comment referencing file" \
    'echo hello  # see CUSTOMER_NOTES.md for the ruling' proceed

run_cmd_case "prose: ls listing with file in result" \
    'ls -la CUSTOMER_NOTES.md docs/' proceed

# Carrier prefixes (no escape-hatch in this hook, but read must still proceed).
run_cmd_case "carrier: SWDT_AGENT_PUSH prefix + grep" \
    'SWDT_AGENT_PUSH=software-engineer grep researcher CUSTOMER_NOTES.md' proceed

# ---------------------------------------------------------------------------
# Writes — must fire.
# ---------------------------------------------------------------------------

run_cmd_case "write: > redirect into file" \
    'echo hi > CUSTOMER_NOTES.md' fire

run_cmd_case "write: >> append into file" \
    'cat new >> CUSTOMER_NOTES.md' fire

run_cmd_case "write: tee file" \
    'echo hi | tee CUSTOMER_NOTES.md' fire

run_cmd_case "write: sed -i on file" \
    'sed -i s/foo/bar/ CUSTOMER_NOTES.md' fire

run_cmd_case "write: perl -i on file" \
    'perl -i -pe s/x/y/ CUSTOMER_NOTES.md' fire

run_cmd_case "write: mv file" \
    'mv CUSTOMER_NOTES.md backup.md' fire

run_cmd_case "write: rm file" \
    'rm CUSTOMER_NOTES.md' fire

run_cmd_case "write: truncate file" \
    'truncate -s 0 CUSTOMER_NOTES.md' fire

run_cmd_case "write: dd of= file" \
    'dd if=/dev/null of=CUSTOMER_NOTES.md' fire

run_cmd_case "write: python3 -c open(file, 'w').write" \
    "python3 -c 'open(\"CUSTOMER_NOTES.md\",\"w\").write(\"x\")'" fire

run_cmd_case "write: python3 heredoc open(file, 'w').write" \
    'python3 <<PY
open("CUSTOMER_NOTES.md","w").write("x")
PY' fire

run_cmd_case "write: bash -c redirect (real shell -c body)" \
    "bash -c 'echo x > CUSTOMER_NOTES.md'" fire

run_cmd_case "write: sh -c redirect (real shell -c body)" \
    "sh -c 'echo x > CUSTOMER_NOTES.md'" fire

run_cmd_case "write: cat <<EOF >> file (post-opener redirect)" \
    'cat <<EOF >> CUSTOMER_NOTES.md
stuff
EOF' fire

run_cmd_case "write: python3 -c mode=w kwarg form" \
    "python3 -c 'open(\"CUSTOMER_NOTES.md\", mode=\"w\").write(\"x\")'" fire

# Direct file_path-mode targets (Write / Edit tools).
_run_payload "write: file_path tool input" \
    "$(mkpayload_file CUSTOMER_NOTES.md)" fire

_run_payload "write: nested docs/customer-notes path" \
    "$(mkpayload_path docs/customer-notes/CUSTOMER_NOTES.md)" fire

# ---------------------------------------------------------------------------
# pathlib write detection (issue #184). Mirror coverage from the sister
# hook so write_text / write_bytes / Path.open("w") on CUSTOMER_NOTES.md
# are caught by this hook too.
# ---------------------------------------------------------------------------

run_cmd_case "write: python3 -c Path.write_text on file (#184)" \
    "python3 -c 'import pathlib; pathlib.Path(\"CUSTOMER_NOTES.md\").write_text(\"x\")'" fire

run_cmd_case "write: python3 -c Path.write_bytes on file (#184)" \
    "python3 -c 'from pathlib import Path; Path(\"CUSTOMER_NOTES.md\").write_bytes(b\"x\")'" fire

run_cmd_case "write: python3 -c Path.open('w') on file (#184)" \
    "python3 -c 'from pathlib import Path; Path(\"CUSTOMER_NOTES.md\").open(\"w\").write(\"x\")'" fire

run_cmd_case "write: python3 -c Path.open(mode='w') on file (#184)" \
    "python3 -c 'from pathlib import Path; Path(\"CUSTOMER_NOTES.md\").open(mode=\"w\").write(\"x\")'" fire

run_cmd_case "write: python3 heredoc Path.write_text (#184)" \
    'python3 <<PY
from pathlib import Path
Path("CUSTOMER_NOTES.md").write_text("x")
PY' fire

# Read forms must still proceed.
run_cmd_case "read: python3 -c Path.read_text on file (#184 negative)" \
    "python3 -c 'from pathlib import Path; Path(\"CUSTOMER_NOTES.md\").read_text()'" proceed

run_cmd_case "read: python3 -c Path.open('r') on file (#184 negative)" \
    "python3 -c 'from pathlib import Path; Path(\"CUSTOMER_NOTES.md\").open(\"r\").read()'" proceed

run_cmd_case "read: python3 -c Path.open(mode='r') on file (#184 negative)" \
    "python3 -c 'from pathlib import Path; Path(\"CUSTOMER_NOTES.md\").open(mode=\"r\").read()'" proceed

# Different filename must not trigger.
run_cmd_case "read: Path.write_text on a different file (#184 negative)" \
    "python3 -c 'from pathlib import Path; Path(\"OTHER.md\").write_text(\"x\")'" proceed

echo
echo "customer-notes-guard self-test: $pass passed, $fail failed."
if [ "$fail" -gt 0 ]; then
    for f in "${failures[@]}"; do
        echo "  - $f"
    done
    exit 1
fi
exit 0
