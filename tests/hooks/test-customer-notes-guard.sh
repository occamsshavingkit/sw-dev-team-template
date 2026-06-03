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

# ---------------------------------------------------------------------------
# Content-awareness cases (issue #292, ruling Q-0031).
#
# All write payloads below fire the gate (permissionDecision: ask).
# The additional assertion is whether the stdout contains a specific
# finding keyword (OVERSIZED / UNSTRUCTURED / OFF-SCOPE) or is clean
# (well-formed entry → fire with no finding keywords).
#
# Helper: _run_payload_with_finding <name> <json-payload> <expect-finding-substr|"">
#   "" means: gate fires AND no finding keywords present (well-formed entry).
#   non-empty: gate fires AND finding substr is present in stdout.
# ---------------------------------------------------------------------------

_run_payload_with_finding() {
    local name=$1
    local payload=$2
    local expect_finding=$3   # substring to grep for, or "" for no findings
    local tmp_out rc stdout gate_ok finding_ok
    tmp_out=$(mktemp)
    printf '%s' "$payload" | python3 "$HOOK" >"$tmp_out" 2>/dev/null
    rc=$?
    stdout=$(cat "$tmp_out")
    rm -f "$tmp_out"

    # Gate must fire
    if printf '%s' "$stdout" | grep -q '"permissionDecision": "ask"'; then
        gate_ok=1
    else
        gate_ok=0
    fi

    # Finding assertion
    if [ -z "$expect_finding" ]; then
        # No findings expected — none of the advisory keywords should appear
        if printf '%s' "$stdout" | grep -qE 'OVERSIZED|UNSTRUCTURED|OFF-SCOPE'; then
            finding_ok=0
        else
            finding_ok=1
        fi
    else
        if printf '%s' "$stdout" | grep -q "$expect_finding"; then
            finding_ok=1
        else
            finding_ok=0
        fi
    fi

    if [ "$gate_ok" -eq 1 ] && [ "$finding_ok" -eq 1 ] && [ "$rc" -eq 0 ]; then
        pass=$((pass + 1))
        echo "PASS  $name"
    else
        fail=$((fail + 1))
        failures+=("$name (gate_ok=$gate_ok finding_ok=$finding_ok rc=$rc expect_finding='$expect_finding')")
        echo "FAIL  $name (gate_ok=$gate_ok finding_ok=$finding_ok rc=$rc)"
        [ -n "$stdout" ] && echo "      stdout: $stdout"
    fi
}

# Build Write-tool payloads (file_path + content) safely for multi-line content.
# We write the content to a temp file and read it in Python to avoid shell
# newline mangling through command substitution + sys.argv.
mkpayload_write_file() {
    local target_path="$1"
    local content_file="$2"   # path to a file containing the content string
    python3 - "$target_path" "$content_file" <<'PYEOF'
import json, sys
target = sys.argv[1]
with open(sys.argv[2]) as f:
    content = f.read()
print(json.dumps({"tool_input": {"file_path": target, "content": content}}))
PYEOF
}

# Helper: write content to a temp file, build payload, run case, clean up.
_run_write_content_case() {
    local name="$1"
    local content="$2"
    local expect_finding="$3"
    local tmp_content
    tmp_content="$(mktemp)"
    printf '%s' "$content" > "$tmp_content"
    local payload
    payload="$(mkpayload_write_file CUSTOMER_NOTES.md "$tmp_content")"
    rm -f "$tmp_content"
    _run_payload_with_finding "$name" "$payload" "$expect_finding"
}

# A canonical well-formed entry (all required sections + verbatim quote).
_run_write_content_case \
    "content: well-formed entry fires gate with no findings (#292)" \
    "## 2026-06-03 — Q-0031: test entry (turn: T-0042)

**Question (from tech-lead, Q-0031):**
> Is this the canonical shape?

**Customer answer (verbatim):**
> Yes, this is the canonical shape.

**Recorded by:** researcher" \
    ""

# Oversized entry (more than ENTRY_MAX_LINES=60 lines).
# Write the payload directly to a temp file using Python so trailing newlines
# are preserved (shell $() command substitution strips them, making the line
# count wrong if we build the padding in the shell).
_oversized_tmp="$(mktemp)"
python3 - "$_oversized_tmp" <<'PYEOF'
import sys
body = (
    "## 2026-06-03 — Q-0099: oversized (turn: T-0001)\n\n"
    "**Question (from tech-lead, Q-0099):**\n"
    "> Is this too long?\n\n"
    "**Customer answer (verbatim):**\n"
    "> Yes.\n\n"
    "**Recorded by:** researcher\n"
)
# 55 extra lines pushes past the ENTRY_MAX_LINES=60 threshold
body += "\n" * 55
with open(sys.argv[1], "w") as f:
    f.write(body)
PYEOF
_run_payload_with_finding \
    "content: oversized entry fires OVERSIZED finding (#292)" \
    "$(mkpayload_write_file CUSTOMER_NOTES.md "$_oversized_tmp")" \
    "OVERSIZED"
rm -f "$_oversized_tmp"

# Unstructured entry: missing required sections.
_run_write_content_case \
    "content: unstructured entry fires UNSTRUCTURED finding (#292)" \
    "Some informal note about a customer preference.
No headers, no quote blocks, no recorded-by field." \
    "UNSTRUCTURED"

# Off-scope entry: has the header structure but no verbatim quote lines at all.
_run_write_content_case \
    "content: entry without verbatim quotes fires OFF-SCOPE finding (#292)" \
    "## 2026-06-03 — Q-0050: missing quotes (turn: T-0010)

**Question (from tech-lead, Q-0050):**
The question text goes here without a block-quote.

**Customer answer (verbatim):**
The answer text goes here without a block-quote either.

**Recorded by:** researcher" \
    "OFF-SCOPE"

# m-2: answer block lacks a blockquote even though question block has one.
# Only one "> " line total — below the threshold of 2 — so OFF-SCOPE fires.
_run_write_content_case \
    "content: question has quote but answer does not fires OFF-SCOPE (m-2)" \
    "## 2026-06-03 — Q-0051: partial quotes (turn: T-0011)

**Question (from tech-lead, Q-0051):**
> What is the ruling?

**Customer answer (verbatim):**
The answer text written as plain prose, not a block-quote.

**Recorded by:** researcher" \
    "OFF-SCOPE"

# M-1: multi-entry (full-file) Write payload must NOT fire OVERSIZED.
# Simulate a full-file rewrite by prepending an existing entry before the new
# one; two ## YYYY-MM-DD headings → multi-entry path → OVERSIZED suppressed.
_multi_entry_tmp="$(mktemp)"
python3 - "$_multi_entry_tmp" <<'PYEOF'
import sys
# Build a payload with two entry headings and enough lines to exceed
# ENTRY_MAX_LINES=60 if checked naively, but is a legitimate full-file write.
existing = (
    "## 2026-01-01 — Q-0001: prior entry (turn: T-0001)\n\n"
    "**Question (from tech-lead, Q-0001):**\n"
    "> Prior question text.\n\n"
    "**Customer answer (verbatim):**\n"
    "> Prior answer text.\n\n"
    "**Recorded by:** researcher\n"
)
new_entry = (
    "## 2026-06-03 — Q-0099: new entry (turn: T-0099)\n\n"
    "**Question (from tech-lead, Q-0099):**\n"
    "> New question text.\n\n"
    "**Customer answer (verbatim):**\n"
    "> New answer text.\n\n"
    "**Recorded by:** researcher\n"
)
# Pad to well over 60 lines total to confirm the naive check would fire
content = existing + "\n" * 55 + new_entry
with open(sys.argv[1], "w") as f:
    f.write(content)
PYEOF
_run_payload_with_finding \
    "content: multi-entry full-file Write does NOT fire OVERSIZED (M-1)" \
    "$(mkpayload_write_file CUSTOMER_NOTES.md "$_multi_entry_tmp")" \
    ""
rm -f "$_multi_entry_tmp"

# Bash redirect with uninspectable content (no heredoc body) — gate fires,
# no crash, finding analysis degrades gracefully.
run_cmd_case \
    "content: uninspectable bash redirect fires gate without crash (#292)" \
    'echo stub >> CUSTOMER_NOTES.md' \
    fire

echo
echo "customer-notes-guard self-test: $pass passed, $fail failed."
if [ "$fail" -gt 0 ]; then
    for f in "${failures[@]}"; do
        echo "  - $f"
    done
    exit 1
fi
exit 0
