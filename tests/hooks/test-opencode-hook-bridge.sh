#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# tests/hooks/test-opencode-hook-bridge.sh — differential parity suite for
# the OpenCode enforcement hook bridge (fw-adr-0031-opencode-hook-bridge.md).
#
# Verifies the property the ADR exists to guarantee: Claude Code and
# OpenCode reach IDENTICAL verdicts from identical inputs, modulo the two
# named, accepted parity gaps (warn-mode reason dropped; ask degrades to
# deny). Two parts:
#
#   Part A (always runs, no live bridge / node required): table-driven
#   checks against tests/hooks/lib/opencode_map.py's independently-
#   derived reference tables and scripts/opencode/tool-arg-map.json.
#
#   Part B (requires .opencode/plugin/hook-bridge.js + `node`; SKIPS with
#   a clear message, not a failure, if either is absent — this suite is
#   designed to run both before and after the bridge implementation
#   lands): live differential invocation of the real HookBridge plugin
#   via tests/hooks/lib/opencode-bridge-invoke.mjs, cross-checked against
#   directly running the same scripts/hooks/*.py the bridge shells out to.
#
# No live `opencode` process, network, or model access is used anywhere
# in this file — Part B invokes the plugin module directly with a
# PluginInput stub (see opencode-bridge-invoke.mjs's header comment).
#
# B14-B17 (added by the S1 test-gap closure, 2026-07-25) exercise
# hook-bridge.js's SESSION_STATE_CAP=10000 FIFO bounded-eviction fix
# (finding S1, commit 1368fab) against the REAL cap — see the block
# comment immediately above B14 in Part B for why that is fast enough
# to run on every invocation of this suite. B17 originally shipped as a
# `record_finding` (confirmed-but-undisposed regression: handledIdleSessions
# evicting on the same clock as sessionParent/sessionAgent broke
# session.idle dedup once a sessionID aged off the cap). tech-lead's
# disposition was FIX, not accept; the S2 fix (same day) gives
# handledIdleSessions its own independent, much larger cap, and B17 (and
# B16, whose atomicity property changed as a direct result) are now
# ordinary `record_pass`/`record_fail` assertions.
#
# Usage:
#   tests/hooks/test-opencode-hook-bridge.sh

set -u

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PLUGIN="$REPO_ROOT/.opencode/plugin/hook-bridge.js"
INVOKER="$REPO_ROOT/tests/hooks/lib/opencode-bridge-invoke.mjs"
MAPLIB="$REPO_ROOT/tests/hooks/lib/opencode_map.py"
SESSION_FIXTURE="$REPO_ROOT/tests/hooks/fixtures/opencode-session-events.yml"
export CLAUDE_PROJECT_DIR="$REPO_ROOT"

pass=0
fail=0
skip=0
findings=0
failures=()
finding_notes=()

record_pass() {
    pass=$((pass + 1))
    printf 'PASS  %s\n' "$1"
}

record_fail() {
    fail=$((fail + 1))
    failures+=("$1")
    printf 'FAIL  %s\n' "$1"
    if [ -n "${2:-}" ]; then
        printf '      %s\n' "$2"
    fi
}

record_skip() {
    skip=$((skip + 1))
    printf 'SKIP  %s\n' "$1"
    if [ -n "${2:-}" ]; then
        printf '      %s\n' "$2"
    fi
}

# record_finding — for a behavior that is executable-verified but is a
# DISPOSITION QUESTION for tech-lead / security-engineer, not a simple
# pass/fail regression: the code under test already documents the
# behavior in-line as an accepted-but-unverified residual risk (see
# hook-bridge.js's trackSessionAndEvictIfOverCap comment), and this
# check turns that from "the implementer's inline reasoning" into "an
# executable, reproduced fact" (the exact gap the S1 security
# re-assessment flagged). Deliberately NOT `record_fail`: folding an
# open disposition question into the hard-fail/exit-1 count would make
# this suite block on a decision this file cannot make. Deliberately
# NOT `record_skip` either: the behavior WAS exercised, not bypassed.
# Printed loudly in its own summary block below so it cannot be missed.
record_finding() {
    findings=$((findings + 1))
    finding_notes+=("$1")
    printf 'FINDING  %s\n' "$1"
}

# run_node_steps <steps-json> — invokes the real bridge with a fresh Hooks
# instance for exactly this call. Prints one JSON line per step to stdout.
run_node_steps() {
    printf '%s' "$1" | node "$INVOKER" run "$PLUGIN" 2>/dev/null
}

# ===========================================================================
# Part A — table-driven checks. No live bridge / node required.
# ===========================================================================

echo "== Part A: mapping-table checks (no live bridge required) =="

map_diff_out=$(python3 "$MAPLIB" map-diff 2>&1)
map_diff_rc=$?
if [ "$map_diff_rc" -eq 3 ]; then
    record_skip "scripts/opencode/tool-arg-map.json matches qa-engineer's reference table" \
        "tool-arg-map.json not found — pre-implementation run"
elif [ "$map_diff_rc" -eq 0 ]; then
    record_pass "scripts/opencode/tool-arg-map.json matches qa-engineer's independent reference table (tool ids, claude_tool_name, arg_map, and MultiEdit recorded as unmapped)"
else
    record_fail "scripts/opencode/tool-arg-map.json matches reference table" "$map_diff_out"
fi

# NOTE (code-review finding W1): the three checks immediately below
# exercise `task`'s `subagent_type` argument -- the SPAWN-TARGET the
# `task` tool hands to a new subagent. That is a DIFFERENT mechanism from
# `agent_type`, the field this bridge forwards on `session.created` so
# scripts/hooks/tech-lead-authoring-guard.py can identify WHICH ALREADY-
# RUNNING role is making a write/edit/bash call (privilege forwarding).
# The two names are confusingly similar but test different code paths; do
# not treat coverage of one as coverage of the other. See B9-B11 below
# ("privilege forwarding (W1): ...") for the agent_type coverage.
#
# Regression: a naive blanket snake_case<->camelCase transform gets
# task.subagent_type wrong (it is deliberately unchanged casing on the
# OpenCode side, unlike every other key in the map).
naive_result=$(python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/tests/hooks/lib')
import opencode_map as m
print(m.naive_snake_to_camel('subagent_type'))
")
if [ "$naive_result" = "subagentType" ]; then
    record_pass "regression: a naive snake_case->camelCase transform WOULD mis-translate subagent_type to 'subagentType' — demonstrates why fw-adr-0031 mandates an explicit table, not an inferred transform"
else
    record_fail "naive-transform regression sanity check" "expected the naive transform to produce 'subagentType' (proving it's wrong), got '$naive_result'"
fi

subagent_roundtrip=$(python3 -c "
import sys, json
sys.path.insert(0, '$REPO_ROOT/tests/hooks/lib')
import opencode_map as m
print(json.dumps(m.to_opencode_args('Agent', {'description': 'd', 'prompt': 'p', 'subagent_type': 'qa-engineer'})))
")
if [ "$subagent_roundtrip" = '{"description": "d", "prompt": "p", "subagent_type": "qa-engineer"}' ]; then
    record_pass "the correct (explicit-table) mapper leaves subagent_type unchanged"
else
    record_fail "explicit-table mapper leaves subagent_type unchanged" "got: $subagent_roundtrip"
fi

# Arg-key translation spot checks — pure reference-table checks, one per
# guarded tool, covering every VERIFIED runtime fact given at dispatch.
declare -A ARG_CASES=(
    ["write: file_path -> filePath"]='to_opencode_args("Write", {"file_path": "a/b.md", "content": "x"})|{"filePath": "a/b.md", "content": "x"}'
    ["edit: old_string/new_string -> oldString/newString"]='to_opencode_args("Edit", {"file_path": "a/b.md", "old_string": "x", "new_string": "y"})|{"filePath": "a/b.md", "oldString": "x", "newString": "y"}'
    ["bash: command passthrough, cwd -> workdir"]='to_opencode_args("Bash", {"command": "ls", "cwd": "/tmp"})|{"command": "ls", "workdir": "/tmp"}'
    ["bridge direction: filePath -> file_path (write)"]='to_claude_tool_input("write", {"filePath": "a/b.md", "content": "x"})|{"file_path": "a/b.md", "content": "x"}'
    ["bridge direction: oldString/newString -> old_string/new_string (edit)"]='to_claude_tool_input("edit", {"filePath": "a/b.md", "oldString": "x", "newString": "y"})|{"file_path": "a/b.md", "old_string": "x", "new_string": "y"}'
    ["bridge direction: workdir -> cwd (bash)"]='to_claude_tool_input("bash", {"command": "ls", "workdir": "/tmp"})|{"command": "ls", "cwd": "/tmp"}'
)
for case_name in "${!ARG_CASES[@]}"; do
    expr="${ARG_CASES[$case_name]%%|*}"
    expected="${ARG_CASES[$case_name]#*|}"
    got=$(python3 -c "
import sys, json
sys.path.insert(0, '$REPO_ROOT/tests/hooks/lib')
from opencode_map import to_opencode_args, to_claude_tool_input
print(json.dumps($expr))
")
    expected_norm=$(python3 -c "import json; print(json.dumps(json.loads('$expected')))")
    if [ "$got" = "$expected_norm" ]; then
        record_pass "arg-key translation: $case_name"
    else
        record_fail "arg-key translation: $case_name" "expected $expected_norm, got $got"
    fi
done

# MultiEdit has no OpenCode source — must be recorded EXPLICITLY, not
# silently omitted. Checked two ways: (1) the reference module's own
# table, (2) the checked-in map's unmapped_claude_tools block (when the
# file exists — map_diff above already covers this, but assert directly
# here too so this specific deliverable has its own focused failure
# message rather than being buried in a generic map-diff dump).
multiedit_check=$(python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/tests/hooks/lib')
import opencode_map as m
print('None' if m.CLAUDE_TO_OPENCODE_TOOL.get('MultiEdit') is None else m.CLAUDE_TO_OPENCODE_TOOL.get('MultiEdit'))
")
if [ "$multiedit_check" = "None" ]; then
    record_pass "MultiEdit has no OpenCode source — reference table records this explicitly (fw-adr-0031: OpenCode 1.18.4 has no 'patch' tool)"
else
    record_fail "MultiEdit has no OpenCode source" "reference table maps MultiEdit to '$multiedit_check', expected None"
fi

if [ -f "$REPO_ROOT/scripts/opencode/tool-arg-map.json" ]; then
    if python3 -c "
import json, sys
doc = json.load(open('$REPO_ROOT/scripts/opencode/tool-arg-map.json'))
sys.exit(0 if 'MultiEdit' in doc.get('unmapped_claude_tools', {}) else 1)
"; then
        record_pass "scripts/opencode/tool-arg-map.json records MultiEdit under unmapped_claude_tools (not silently absent)"
    else
        record_fail "scripts/opencode/tool-arg-map.json records MultiEdit under unmapped_claude_tools" \
            "MultiEdit is missing from unmapped_claude_tools — silently omitted rather than recorded as a known gap"
    fi
else
    record_skip "scripts/opencode/tool-arg-map.json records MultiEdit under unmapped_claude_tools" \
        "tool-arg-map.json not found — pre-implementation run"
fi

# Verdict oracle — pure re-derivation of fw-adr-0031's binding table.
declare -A VERDICT_CASES=(
    ["none -> proceed"]="none:proceed"
    ["allow -> proceed"]="allow:proceed"
    ["allow_warn -> proceed (reason dropped, accepted gap)"]="allow_warn:proceed"
    ["deny -> throw"]="deny:throw"
    ["ask -> throw (degrades to deny, not allow)"]="ask:throw"
)
for case_name in "${!VERDICT_CASES[@]}"; do
    claude_verdict="${VERDICT_CASES[$case_name]%%:*}"
    expected="${VERDICT_CASES[$case_name]#*:}"
    got=$(python3 "$MAPLIB" bridge-verdict "$claude_verdict")
    if [ "$got" = "$expected" ]; then
        record_pass "verdict oracle: $case_name"
    else
        record_fail "verdict oracle: $case_name" "expected $expected, got $got"
    fi
done

# ===========================================================================
# Part B — live differential checks. Requires .opencode/plugin/hook-bridge.js
# and `node`. Skips (not fails) if either is missing, per this suite's
# test-first / pre-implementation-runnable design.
# ===========================================================================

echo
echo "== Part B: live bridge differential checks =="

bridge_available=1
if [ ! -f "$PLUGIN" ]; then
    bridge_available=0
    record_skip "Part B: all live-bridge checks" ".opencode/plugin/hook-bridge.js not found — pre-implementation run"
elif ! command -v node >/dev/null 2>&1; then
    bridge_available=0
    record_skip "Part B: all live-bridge checks" "node not available in this environment"
fi

if [ "$bridge_available" -eq 1 ]; then
    # mk_pathshim <logfile> — prints a directory to prepend to PATH. The
    # shimmed `python3` logs "<hook-basename>\t<stdin JSON>" per
    # invocation to <logfile>, then execs the REAL python3 against the
    # same stdin so verdict behaviour is unaffected. Used for: (a)
    # invocation-count assertions (ordering, idempotency), (b) exact
    # payload-content assertions (arg-key translation, observed through
    # the actual bytes the bridge sent to the hook, not just its
    # downstream effect on the verdict).
    REAL_PYTHON3="$(command -v python3)"
    mk_pathshim() {
        local logfile="$1"
        local dir
        dir=$(mktemp -d)
        cat > "$dir/python3" <<SHIM
#!/usr/bin/env bash
tmpin=\$(mktemp)
cat > "\$tmpin"
{
    printf '%s\t' "\$(basename "\$1")"
    cat "\$tmpin"
    printf '\n'
} >> "$logfile"
"$REAL_PYTHON3" "\$@" < "\$tmpin"
rc=\$?
rm -f "\$tmpin"
exit \$rc
SHIM
        chmod +x "$dir/python3"
        printf '%s' "$dir"
    }

    # ---- B1: verdict parity — allow ----
    steps='[{"kind":"tool-before","tool":"write","sessionID":"b1","args":{"filePath":"docs/OPEN_QUESTIONS.md","content":"x"}}]'
    result=$(run_node_steps "$steps")
    verdict=$(printf '%s' "$result" | python3 -c "import json,sys; print(json.load(sys.stdin)['verdict'])")
    python_verdict=$(printf '{"tool_input":{"file_path":"docs/OPEN_QUESTIONS.md","content":"x"}}' \
        | env -u SWDT_AGENT_PUSH python3 "$REPO_ROOT/scripts/hooks/tech-lead-authoring-guard.py" \
        | python3 "$MAPLIB" verdict)
    expected=$(python3 "$MAPLIB" bridge-verdict "$python_verdict")
    if [ "$verdict" = "proceed" ] && [ "$expected" = "proceed" ]; then
        record_pass "verdict parity: write to allow-listed path (docs/OPEN_QUESTIONS.md) -> proceed on both paths"
    else
        record_fail "verdict parity: write to allow-listed path" "bridge=$verdict python-oracle-expects=$expected"
    fi

    # ---- B2: verdict parity — deny (tech-lead-authoring-guard, off-allow-list) ----
    steps='[{"kind":"tool-before","tool":"write","sessionID":"b2","args":{"filePath":"scripts/foo.sh","content":"x"}}]'
    result=$(run_node_steps "$steps")
    verdict=$(printf '%s' "$result" | python3 -c "import json,sys; print(json.load(sys.stdin)['verdict'])")
    message=$(printf '%s' "$result" | python3 -c "import json,sys; print(json.load(sys.stdin).get('message') or '')")
    if [ "$verdict" = "throw" ] && printf '%s' "$message" | grep -q "software-engineer"; then
        record_pass "verdict parity: write to off-allow-list path (scripts/foo.sh) -> throw naming software-engineer, matching Claude-side deny"
    else
        record_fail "verdict parity: write to off-allow-list path" "verdict=$verdict message=$message"
    fi

    # ---- B3: verdict parity + hook ordering — ask degrades to deny,
    # customer-notes-guard wins (first in chain), tech-lead-authoring-guard
    # never runs (short-circuit).
    order_log=$(mktemp)
    shim_dir=$(mk_pathshim "$order_log")
    steps='[{"kind":"tool-before","tool":"write","sessionID":"b3","args":{"filePath":"CUSTOMER_NOTES.md","content":"x"}}]'
    result=$(printf '%s' "$steps" | PATH="$shim_dir:$PATH" node "$INVOKER" run "$PLUGIN" 2>/dev/null)
    verdict=$(printf '%s' "$result" | python3 -c "import json,sys; print(json.load(sys.stdin)['verdict'])")
    message=$(printf '%s' "$result" | python3 -c "import json,sys; print(json.load(sys.stdin).get('message') or '')")
    cng_calls=$(grep -c "^customer-notes-guard.py	" "$order_log" 2>/dev/null || true)
    tlag_calls=$(grep -c "^tech-lead-authoring-guard.py	" "$order_log" 2>/dev/null || true)
    rm -rf "$shim_dir" "$order_log"
    if [ "$verdict" = "throw" ] \
        && printf '%s' "$message" | grep -q "^\[customer-notes-guard.py\]" \
        && [ "${cng_calls:-0}" = "1" ] \
        && [ "${tlag_calls:-0}" = "0" ]; then
        record_pass "hook ordering: customer-notes-guard denies CUSTOMER_NOTES.md write, tech-lead-authoring-guard never runs (first-deny-wins short-circuit); ask degrades to deny (throw), not allow"
    else
        record_fail "hook ordering / ask-degrades-to-deny" \
            "verdict=$verdict cng_calls=${cng_calls:-0} tlag_calls=${tlag_calls:-0} message=$message"
    fi

    # ---- B4: fail-closed — hook script absent (scratch project dir with
    # no scripts/hooks/ at all; does not touch the real repo's scripts/).
    scratch_dir=$(mktemp -d)
    steps='[{"kind":"tool-before","tool":"write","sessionID":"b4","args":{"filePath":"docs/OPEN_QUESTIONS.md","content":"x"}}]'
    result=$(OPENCODE_BRIDGE_TEST_DIRECTORY="$scratch_dir" bash -c \
        "printf '%s' '$steps' | node '$INVOKER' run '$PLUGIN' 2>/dev/null")
    rm -rf "$scratch_dir"
    verdict=$(printf '%s' "$result" | python3 -c "import json,sys; print(json.load(sys.stdin)['verdict'])" 2>/dev/null)
    message=$(printf '%s' "$result" | python3 -c "import json,sys; print(json.load(sys.stdin).get('message') or '')" 2>/dev/null)
    if [ "$verdict" = "throw" ] && printf '%s' "$message" | grep -qi "missing or unreadable"; then
        record_pass "fail-closed: guard hook script absent -> throw (not silent allow)"
    else
        record_fail "fail-closed: guard hook script absent" "verdict=$verdict message=$message"
    fi

    # ---- B5: fail-closed — python3 not on PATH (bridge-infrastructure
    # absence, distinct from B4's missing-script case).
    #
    # NOTE: `PATH=X node ...` (a leading-assignment simple command) makes
    # bash resolve `node` itself via the NEW (temporary) PATH, not the
    # caller's — so node_dir must be included in the restricted PATH for
    # `node` to be found at all, while python3 (looked up separately, at
    # runtime, by hook-bridge.js's own child_process.spawn()) is not.
    empty_path_dir=$(mktemp -d)
    node_dir=$(dirname "$(command -v node)")
    steps='[{"kind":"tool-before","tool":"write","sessionID":"b5","args":{"filePath":"docs/OPEN_QUESTIONS.md","content":"x"}}]'
    result=$(printf '%s' "$steps" | PATH="$empty_path_dir:$node_dir" node "$INVOKER" run "$PLUGIN" 2>/dev/null)
    rm -rf "$empty_path_dir"
    verdict=$(printf '%s' "$result" | python3 -c "import json,sys; print(json.load(sys.stdin)['verdict'])" 2>/dev/null)
    message=$(printf '%s' "$result" | python3 -c "import json,sys; print(json.load(sys.stdin).get('message') or '')" 2>/dev/null)
    if [ "$verdict" = "throw" ] && printf '%s' "$message" | grep -qi "ENOENT\|could not run guard hook"; then
        record_pass "fail-closed: python3 not on PATH -> throw (not silent allow)"
    else
        record_fail "fail-closed: python3 not on PATH" "verdict=$verdict message=$message"
    fi

    # ---- B6: fail-open inheritance — well-formed-but-empty args mirrors
    # the Python guards' own "nothing to check" posture (see
    # test-tech-lead-authoring-guard.sh's "fail-open: missing tool_input").
    steps='[{"kind":"tool-before","tool":"write","sessionID":"b6","args":{}}]'
    result=$(run_node_steps "$steps")
    verdict=$(printf '%s' "$result" | python3 -c "import json,sys; print(json.load(sys.stdin)['verdict'])")
    if [ "$verdict" = "proceed" ]; then
        record_pass "fail-open inheritance: empty/no-opinion tool_input -> proceed, matching the Python guards' own fail-open posture (not tightened by the bridge)"
    else
        record_fail "fail-open inheritance: empty tool_input" "verdict=$verdict (expected proceed)"
    fi

    # ---- B7: arg-key translation observed live through the bridge's
    # ACTUAL wire payload (PATH-shim captures the exact stdin the bridge
    # sent to tech-lead-authoring-guard.py).
    payload_log=$(mktemp)
    shim_dir=$(mk_pathshim "$payload_log")
    steps='[{"kind":"tool-before","tool":"edit","sessionID":"b7","args":{"filePath":"scripts/foo.sh","oldString":"a","newString":"b"}}]'
    printf '%s' "$steps" | PATH="$shim_dir:$PATH" node "$INVOKER" run "$PLUGIN" >/dev/null 2>&1
    sent_payload=$(grep "^tech-lead-authoring-guard.py	" "$payload_log" | head -1 | cut -f2-)
    rm -rf "$shim_dir" "$payload_log"
    expected_ti='{"file_path": "scripts/foo.sh", "old_string": "a", "new_string": "b"}'
    got_ti=$(printf '%s' "$sent_payload" | python3 -c "import json,sys; print(json.dumps(json.load(sys.stdin).get('tool_input', {})))" 2>/dev/null)
    if [ "$got_ti" = "$expected_ti" ]; then
        record_pass "live arg-key translation: edit(filePath/oldString/newString) -> tool_input(file_path/old_string/new_string) observed on the actual wire payload"
    else
        record_fail "live arg-key translation: edit tool" "expected $expected_ti, got $got_ti (raw: $sent_payload)"
    fi

    # ---- B8: session-event fixture (deliverable 3) ----
    if [ ! -f "$SESSION_FIXTURE" ]; then
        record_skip "session-event fixture (opencode-session-events.yml)" "fixture not found"
    elif ! python3 -c "import yaml" >/dev/null 2>&1; then
        record_skip "session-event fixture (opencode-session-events.yml)" "python3 yaml module not available"
    else
        entries_tsv=$(python3 - "$SESSION_FIXTURE" <<'PY'
import base64
import json
import sys
import yaml

fixture = sys.argv[1]
US = "\x1f"
doc = yaml.safe_load(open(fixture, "r", encoding="utf-8")) or {}
for e in doc.get("entries", []):
    label = str(e.get("label", "<unlabeled>"))
    steps = json.loads(e["steps"])
    expected = json.loads(e["expected_gate_invocations"])
    steps_enc = base64.b64encode(json.dumps(steps).encode("utf-8")).decode("ascii")
    expected_enc = base64.b64encode(json.dumps(expected).encode("utf-8")).decode("ascii")
    print(f"{label}{US}{steps_enc}{US}{expected_enc}")
PY
)
        while IFS=$'\x1f' read -r entry_label steps_enc expected_enc; do
            [ -z "$entry_label" ] && continue
            entry_steps=$(printf '%s' "$steps_enc" | base64 --decode)
            entry_expected=$(printf '%s' "$expected_enc" | base64 --decode)

            entry_log=$(mktemp)
            entry_shim_dir=$(mk_pathshim "$entry_log")
            printf '%s' "$entry_steps" | PATH="$entry_shim_dir:$PATH" node "$INVOKER" run "$PLUGIN" >/dev/null 2>&1
            rm -rf "$entry_shim_dir"

            mismatch=$(python3 -c "
import json, sys
expected = json.loads('''$entry_expected''')
counts = {}
try:
    with open('$entry_log') as f:
        for line in f:
            name = line.split('\t', 1)[0]
            counts[name] = counts.get(name, 0) + 1
except FileNotFoundError:
    pass
problems = []
for name, want in expected.items():
    got = counts.get(name, 0)
    if got != want:
        problems.append(f'{name}: expected {want}, got {got}')
print('; '.join(problems))
")
            rm -f "$entry_log"
            if [ -z "$mismatch" ]; then
                record_pass "session-event: $entry_label"
            else
                record_fail "session-event: $entry_label" "$mismatch"
            fi
        done <<EOF
$entries_tsv
EOF
    fi

    # ---- B9/B10/B11: privilege forwarding (code-review finding W1) ----
    #
    # .opencode/plugin/hook-bridge.js:284-300 forwards session.created's
    # info.agent as a top-level `agent_type` field on every guarded
    # tool.execute.before payload for that sessionID.
    # scripts/hooks/tech-lead-authoring-guard.py's `_resolve_subagent_role()`
    # (~line 860) reads `event.get("agent_type")` to decide `caller_role`,
    # which is the entire allow/deny decision for a caller that is NOT
    # tech-lead itself -- so this is the highest-risk mechanism in the
    # bridge and had ZERO coverage before this task (see W1). These three
    # scenarios chain a session.created step with a tool.execute.before
    # step on the SAME sessionID (opencode-bridge-invoke.mjs's single
    # Hooks instance preserves sessionAgent state across the chain -- see
    # that file's header comment) and assert on the actual verdict
    # (throw vs proceed) AND, where practical, on the exact `agent_type`
    # value observed on the real wire payload sent to
    # tech-lead-authoring-guard.py -- not just on the downstream verdict,
    # which could still pass by accident if forwarding silently broke.
    #
    # Deliberately named "privilege forwarding (W1): ..." (not
    # "agent_type" or "subagent_type") so these cannot be confused with
    # the unrelated task.subagent_type spawn-target checks above.

    # ---- B9: privilege forwarding — specialist ALLOWED. session.created
    # with info.agent="software-engineer", then a write to a path OFF
    # tech-lead's allow-list (scripts/foo.sh -- the SAME path B2 denies
    # with no prior session.created / no agent_type). Proceeding here,
    # combined with observing agent_type="software-engineer" on the
    # actual payload sent to tech-lead-authoring-guard.py, proves the
    # field is both forwarded AND honoured end-to-end -- not that some
    # unrelated allow rule happened to fire.
    payload_log=$(mktemp)
    shim_dir=$(mk_pathshim "$payload_log")
    steps='[{"kind":"event","event":{"type":"session.created","properties":{"sessionID":"priv-allow","info":{"id":"priv-allow","agent":"software-engineer"}}}},{"kind":"tool-before","tool":"write","sessionID":"priv-allow","args":{"filePath":"scripts/foo.sh","content":"x"}}]'
    result=$(printf '%s' "$steps" | PATH="$shim_dir:$PATH" node "$INVOKER" run "$PLUGIN" 2>/dev/null)
    rm -rf "$shim_dir"
    step2_verdict=$(printf '%s' "$result" | sed -n '2p' | python3 -c "import json,sys; print(json.load(sys.stdin)['verdict'])" 2>/dev/null)
    sent_agent_type=$(grep "^tech-lead-authoring-guard.py	" "$payload_log" | head -1 | cut -f2- \
        | python3 -c "import json,sys; print(json.load(sys.stdin).get('agent_type', '<ABSENT>'))" 2>/dev/null)
    rm -f "$payload_log"
    if [ "$step2_verdict" = "proceed" ] && [ "$sent_agent_type" = "software-engineer" ]; then
        record_pass "privilege forwarding (W1): session.created(info.agent=software-engineer) then write to off-allow-list path -> proceed, with agent_type=software-engineer observed on the actual tech-lead-authoring-guard.py wire payload"
    else
        record_fail "privilege forwarding (W1): specialist allowed" "step2_verdict=$step2_verdict sent_agent_type=$sent_agent_type"
    fi

    # ---- B10: privilege forwarding — tech-lead SELF-CLAIM DENIED.
    # session.created with info.agent="tech-lead", then the SAME write.
    # _validate_role() (tech-lead-authoring-guard.py:734-754) explicitly
    # rejects the literal string "tech-lead" even though it is otherwise
    # a canonical role, closing the self-push escalation path. Assert
    # BOTH that the verdict is throw AND that agent_type="tech-lead" WAS
    # actually forwarded on the wire -- proving the guard is the one
    # rejecting it (a deliberate, defended-in-depth reject), not that the
    # bridge silently failed to forward tech-lead's claim (which would
    # make this pass for the wrong reason and mask a forwarding bug).
    payload_log=$(mktemp)
    shim_dir=$(mk_pathshim "$payload_log")
    steps='[{"kind":"event","event":{"type":"session.created","properties":{"sessionID":"priv-tl-selfclaim","info":{"id":"priv-tl-selfclaim","agent":"tech-lead"}}}},{"kind":"tool-before","tool":"write","sessionID":"priv-tl-selfclaim","args":{"filePath":"scripts/foo.sh","content":"x"}}]'
    result=$(printf '%s' "$steps" | PATH="$shim_dir:$PATH" node "$INVOKER" run "$PLUGIN" 2>/dev/null)
    rm -rf "$shim_dir"
    step2_line=$(printf '%s' "$result" | sed -n '2p')
    step2_verdict=$(printf '%s' "$step2_line" | python3 -c "import json,sys; print(json.load(sys.stdin)['verdict'])" 2>/dev/null)
    step2_message=$(printf '%s' "$step2_line" | python3 -c "import json,sys; print(json.load(sys.stdin).get('message') or '')" 2>/dev/null)
    sent_agent_type=$(grep "^tech-lead-authoring-guard.py	" "$payload_log" | head -1 | cut -f2- \
        | python3 -c "import json,sys; print(json.load(sys.stdin).get('agent_type', '<ABSENT>'))" 2>/dev/null)
    rm -f "$payload_log"
    if [ "$step2_verdict" = "throw" ] && [ "$sent_agent_type" = "tech-lead" ] \
        && printf '%s' "$step2_message" | grep -q "software-engineer"; then
        record_pass "privilege forwarding (W1): session.created(info.agent=tech-lead) then write to off-allow-list path -> throw naming software-engineer, WITH agent_type=tech-lead confirmed forwarded on the wire (guard rejects the self-claim; the bridge did not silently drop it)"
    else
        record_fail "privilege forwarding (W1): tech-lead self-claim denied" "step2_verdict=$step2_verdict sent_agent_type=$sent_agent_type message=$step2_message"
    fi

    # ---- B11: privilege forwarding — UNKNOWN SESSION DENIED (fail-safe).
    # A tool.execute.before write on a sessionID that had NO prior
    # session.created step at all (a fresh Hooks instance per run_node_steps
    # call guarantees no leftover state from B9/B10). Must throw, and the
    # payload actually sent to tech-lead-authoring-guard.py must have NO
    # agent_type key at all (not an empty string -- genuinely absent),
    # confirming the fail-safe: absent agent_type denies rather than grants.
    payload_log=$(mktemp)
    shim_dir=$(mk_pathshim "$payload_log")
    steps='[{"kind":"tool-before","tool":"write","sessionID":"priv-unknown-session","args":{"filePath":"scripts/foo.sh","content":"x"}}]'
    result=$(printf '%s' "$steps" | PATH="$shim_dir:$PATH" node "$INVOKER" run "$PLUGIN" 2>/dev/null)
    rm -rf "$shim_dir"
    verdict=$(printf '%s' "$result" | python3 -c "import json,sys; print(json.load(sys.stdin)['verdict'])" 2>/dev/null)
    sent_agent_type=$(grep "^tech-lead-authoring-guard.py	" "$payload_log" | head -1 | cut -f2- \
        | python3 -c "import json,sys; print(json.load(sys.stdin).get('agent_type', '<ABSENT>'))" 2>/dev/null)
    rm -f "$payload_log"
    if [ "$verdict" = "throw" ] && [ "$sent_agent_type" = "<ABSENT>" ]; then
        record_pass "privilege forwarding (W1): tool.execute.before with no prior session.created for that sessionID -> throw, with agent_type genuinely ABSENT from the wire payload (fail-safe: no identity forwarded means deny, not grant)"
    else
        record_fail "privilege forwarding (W1): unknown session denied" "verdict=$verdict sent_agent_type=$sent_agent_type"
    fi

    # ---- B12: HIGH-severity privilege-escalation fix — session.updated
    # FOLLOWS an agent-identity change on the SAME sessionID.
    #
    # session.created establishes agent="software-engineer"; a LATER
    # session.updated on the same sessionID reports agent="tech-writer"
    # (the runtime-spike-verified path: resuming a session with a
    # different `--agent` changes info.agent via plain session.updated,
    # and session.created never re-fires for it). Both software-engineer
    # and tech-writer are validated non-tech-lead roles, so
    # tech-lead-authoring-guard.py's write bypass fires either way --
    # checking the verdict ALONE would pass even with the pre-fix bug
    # (stale agent_type="software-engineer" forwarded forever). The
    # load-bearing assertion is on the ACTUAL WIRE PAYLOAD sent to the
    # guard: agent_type must be the NEW 'tech-writer', never the stale
    # 'software-engineer'. Also asserts the identity change is logged
    # (console.error) -- security-relevant even when handled correctly.
    payload_log=$(mktemp)
    stderr_log=$(mktemp)
    shim_dir=$(mk_pathshim "$payload_log")
    steps='[{"kind":"event","event":{"type":"session.created","properties":{"sessionID":"esc-follow","info":{"id":"esc-follow","agent":"software-engineer"}}}},{"kind":"event","event":{"type":"session.updated","properties":{"info":{"id":"esc-follow","agent":"tech-writer"}}}},{"kind":"tool-before","tool":"write","sessionID":"esc-follow","args":{"filePath":"scripts/foo.sh","content":"x"}}]'
    result=$(printf '%s' "$steps" | PATH="$shim_dir:$PATH" node "$INVOKER" run "$PLUGIN" 2>"$stderr_log")
    rm -rf "$shim_dir"
    step3_verdict=$(printf '%s' "$result" | sed -n '3p' | python3 -c "import json,sys; print(json.load(sys.stdin)['verdict'])" 2>/dev/null)
    sent_agent_type=$(grep "^tech-lead-authoring-guard.py	" "$payload_log" | head -1 | cut -f2- \
        | python3 -c "import json,sys; print(json.load(sys.stdin).get('agent_type', '<ABSENT>'))" 2>/dev/null)
    logged_change=$(grep -c "agent identity changed" "$stderr_log" 2>/dev/null || true)
    rm -f "$payload_log" "$stderr_log"
    if [ "$step3_verdict" = "proceed" ] && [ "$sent_agent_type" = "tech-writer" ] && [ "${logged_change:-0}" -ge 1 ]; then
        record_pass "HIGH-severity fix: session.updated(agent=tech-writer) after session.created(agent=software-engineer) on the SAME sessionID -> the wire payload sent to tech-lead-authoring-guard.py carries agent_type=tech-writer (the NEW agent, not the stale software-engineer), and the identity change is logged to stderr"
    else
        record_fail "HIGH-severity fix: session.updated follows the agent change" "step3_verdict=$step3_verdict sent_agent_type=$sent_agent_type logged_change=${logged_change:-0}"
    fi

    # ---- B13: top-level-session safety — session.updated populating
    # sessionAgent for a PRIMARY/top-level session (which previously had
    # NO sessionAgent entry at all — see the corrected sessionAgent
    # declaration comment) must NOT thereby grant it a specialist write
    # bypass. session.created carries NO info.agent for a top-level
    # session (runtime-spike-verified); this project's opencode.json
    # pins `default_agent: "tech-lead"`, so the first session.updated for
    # that session reports info.agent="tech-lead", which
    # `_validate_role()` rejects by name. Assert BOTH the verdict
    # (throw — no bypass) AND the actual wire payload (agent_type=
    # "tech-lead"), so this passes because the guard's dedicated
    # tech-lead self-claim rejection is doing the work, not because the
    # bridge silently failed to forward anything.
    payload_log=$(mktemp)
    shim_dir=$(mk_pathshim "$payload_log")
    steps='[{"kind":"event","event":{"type":"session.created","properties":{"sessionID":"toplevel-1","info":{"id":"toplevel-1"}}}},{"kind":"event","event":{"type":"session.updated","properties":{"info":{"id":"toplevel-1","agent":"tech-lead"}}}},{"kind":"tool-before","tool":"write","sessionID":"toplevel-1","args":{"filePath":"scripts/foo.sh","content":"x"}}]'
    result=$(printf '%s' "$steps" | PATH="$shim_dir:$PATH" node "$INVOKER" run "$PLUGIN" 2>/dev/null)
    rm -rf "$shim_dir"
    step3_verdict=$(printf '%s' "$result" | sed -n '3p' | python3 -c "import json,sys; print(json.load(sys.stdin)['verdict'])" 2>/dev/null)
    sent_agent_type=$(grep "^tech-lead-authoring-guard.py	" "$payload_log" | head -1 | cut -f2- \
        | python3 -c "import json,sys; print(json.load(sys.stdin).get('agent_type', '<ABSENT>'))" 2>/dev/null)
    rm -f "$payload_log"
    if [ "$step3_verdict" = "throw" ] && [ "$sent_agent_type" = "tech-lead" ]; then
        record_pass "top-level-session safety: session.created(no info.agent) then session.updated(info.agent=tech-lead, matching opencode.json's default_agent) -> write to off-allow-list path still throws (no specialist bypass granted), with agent_type=tech-lead observed on the actual wire payload"
    else
        record_fail "top-level-session safety: session.updated must not grant a top-level session a specialist bypass" "step3_verdict=$step3_verdict sent_agent_type=$sent_agent_type"
    fi

    # ---- B14-B17: S1 bounded eviction (finding S1, fixed in 1368fab) --
    #
    # hook-bridge.js's SESSION_STATE_CAP=10000 FIFO cap on sessionParent /
    # sessionAgent / handledIdleSessions had ZERO executable coverage
    # before this task: the "verified fail-safe" claim in 1368fab's
    # commit message rested on the implementing engineer's one-off manual
    # run (cap forced to 3 in a scratch copy) and the code's own inline
    # reasoning, not on anything in this suite that would catch a
    # regression. B14-B17 close that gap.
    #
    # SESSION_STATE_CAP is NOT overridable for testing (no env var / CLI
    # flag / constructor option) and hook-bridge.js is out of scope to
    # edit here (qa-engineer flagged the option; see this task's return
    # for the routed recommendation). That turned out not to matter:
    # empirically measured (2026-07-25), replaying 10,001 session.created
    # events for CHILD sessions (info.parentID set) against the REAL cap
    # takes well under a second. session.created's early
    # `if (info.parentID) return;` (see the event handler below
    # trackSessionAndEvictIfOverCap) means a child session's
    # session.created does NOT reach runSessionStartSet's four
    # subprocess spawns -- only a PARENT-less/top-level session.created
    # does. So B14-B17 fill the ledger with cheap child-session
    # session.created events and reserve real subprocess-backed
    # tool-before / session.idle calls for the handful of sessions each
    # scenario actually needs to observe. No source change was needed to
    # exercise the real 10,000 cap at test-suite speed.

    # ---- B14: eviction is FIFO, oldest-first (property: "eviction
    # happens at the cap"), and the evicted session degrades fail-safe
    # (property: "eviction degrades fail-safe") -- same wire-payload-not-
    # just-verdict pattern as B11. 10,001 distinct sessions is exactly
    # ONE over SESSION_STATE_CAP: the FIRST session ever tracked
    # ("s14-oldest") must be the one evicted, while the SECOND
    # ("s14-second") must survive -- proving oldest-first order, not
    # "some session", not newest, not random.
    steps=$(python3 - <<'PY'
import json
steps = []
steps.append({"kind":"event","event":{"type":"session.created","properties":{"sessionID":"s14-oldest","info":{"id":"s14-oldest","parentID":"s14-parent","agent":"software-engineer"}}}})
steps.append({"kind":"event","event":{"type":"session.created","properties":{"sessionID":"s14-second","info":{"id":"s14-second","parentID":"s14-parent","agent":"software-engineer"}}}})
for i in range(9998):
    sid = f"s14-filler-{i}"
    steps.append({"kind":"event","event":{"type":"session.created","properties":{"sessionID":sid,"info":{"id":sid,"parentID":"s14-parent"}}}})
steps.append({"kind":"event","event":{"type":"session.created","properties":{"sessionID":"s14-trigger","info":{"id":"s14-trigger","parentID":"s14-parent"}}}})
steps.append({"kind":"tool-before","tool":"write","sessionID":"s14-oldest","args":{"filePath":"scripts/foo.sh","content":"x"}})
steps.append({"kind":"tool-before","tool":"write","sessionID":"s14-second","args":{"filePath":"scripts/foo.sh","content":"x"}})
print(json.dumps(steps))
PY
)
    payload_log=$(mktemp)
    shim_dir=$(mk_pathshim "$payload_log")
    result=$(printf '%s' "$steps" | PATH="$shim_dir:$PATH" node "$INVOKER" run "$PLUGIN" 2>/dev/null)
    rm -rf "$shim_dir"
    verdict_oldest=$(printf '%s' "$result" | tail -n 2 | head -n1 | python3 -c "import json,sys; print(json.load(sys.stdin)['verdict'])" 2>/dev/null)
    verdict_second=$(printf '%s' "$result" | tail -n 1 | python3 -c "import json,sys; print(json.load(sys.stdin)['verdict'])" 2>/dev/null)
    agent_oldest=$(grep "^tech-lead-authoring-guard.py	" "$payload_log" | sed -n '1p' | cut -f2- \
        | python3 -c "import json,sys; print(json.load(sys.stdin).get('agent_type', '<ABSENT>'))" 2>/dev/null)
    agent_second=$(grep "^tech-lead-authoring-guard.py	" "$payload_log" | sed -n '2p' | cut -f2- \
        | python3 -c "import json,sys; print(json.load(sys.stdin).get('agent_type', '<ABSENT>'))" 2>/dev/null)
    rm -f "$payload_log"
    if [ "$verdict_oldest" = "throw" ] && [ "$agent_oldest" = "<ABSENT>" ] \
        && [ "$verdict_second" = "proceed" ] && [ "$agent_second" = "software-engineer" ]; then
        record_pass "S1 bounded eviction: the 10,001st distinct session pushes the ledger one over SESSION_STATE_CAP -- the FIRST-tracked session (s14-oldest) is evicted and its later guarded write throws with agent_type genuinely ABSENT from the wire payload (fail-safe degrade), while the SECOND-tracked session (s14-second) survives with agent_type=software-engineer intact on the wire -- confirms FIFO oldest-first eviction against the real SESSION_STATE_CAP=10000, not a stand-in"
    else
        record_fail "S1 bounded eviction: FIFO oldest-first + fail-safe degrade" \
            "verdict_oldest=$verdict_oldest agent_oldest=$agent_oldest verdict_second=$verdict_second agent_second=$agent_second"
    fi

    # ---- B15: the cap boundary is exact (property: "live and recent
    # sessions are untouched"), off-by-one check. Exactly
    # SESSION_STATE_CAP (10000) distinct sessions tracked -- NOT one
    # over -- must evict NOTHING. The very first session tracked
    # ("s15-oldest") is the one most exposed by a `<` vs `<=` off-by-one
    # bug; it must still forward its agent_type and proceed, and no
    # eviction log line may appear at all.
    steps=$(python3 - <<'PY'
import json
steps = []
steps.append({"kind":"event","event":{"type":"session.created","properties":{"sessionID":"s15-oldest","info":{"id":"s15-oldest","parentID":"s15-parent","agent":"software-engineer"}}}})
for i in range(9999):
    sid = f"s15-filler-{i}"
    steps.append({"kind":"event","event":{"type":"session.created","properties":{"sessionID":sid,"info":{"id":sid,"parentID":"s15-parent"}}}})
steps.append({"kind":"tool-before","tool":"write","sessionID":"s15-oldest","args":{"filePath":"scripts/foo.sh","content":"x"}})
print(json.dumps(steps))
PY
)
    stderr_log=$(mktemp)
    payload_log=$(mktemp)
    shim_dir=$(mk_pathshim "$payload_log")
    result=$(printf '%s' "$steps" | PATH="$shim_dir:$PATH" node "$INVOKER" run "$PLUGIN" 2>"$stderr_log")
    rm -rf "$shim_dir"
    verdict=$(printf '%s' "$result" | tail -n 1 | python3 -c "import json,sys; print(json.load(sys.stdin)['verdict'])" 2>/dev/null)
    sent_agent_type=$(grep "^tech-lead-authoring-guard.py	" "$payload_log" | head -1 | cut -f2- \
        | python3 -c "import json,sys; print(json.load(sys.stdin).get('agent_type', '<ABSENT>'))" 2>/dev/null)
    evictions=$(grep -c "session-state cap" "$stderr_log" 2>/dev/null || true)
    rm -f "$payload_log" "$stderr_log"
    if [ "$verdict" = "proceed" ] && [ "$sent_agent_type" = "software-engineer" ] && [ "${evictions:-0}" = "0" ]; then
        record_pass "S1 bounded eviction: exactly SESSION_STATE_CAP (10000) distinct sessions tracked -> NO eviction logged (boundary is <= cap, not < cap), and the earliest-tracked session's agent_type is still forwarded on the wire and its write still proceeds -- a live/recent session is never punished just for being oldest while still within the cap"
    else
        record_fail "S1 bounded eviction: exact-cap boundary (no eviction at size == cap)" \
            "verdict=$verdict sent_agent_type=$sent_agent_type evictions_logged=${evictions:-0}"
    fi

    # ---- B16: eviction is ATOMIC across the two IDENTITY ledgers, and
    # handledIdleSessions is DELIBERATELY DECOUPLED from them (property
    # updated by the S2 fix, 2026-07-25 -- see hook-bridge.js's "Fallback"
    # comment above sessionInsertOrder's declaration for the full
    # reasoning; this test's ORIGINAL property, "all three structures
    # evict together", was the S1 shape that caused the B17 regression
    # and no longer holds by design). For ONE evicted CHILD session, in
    # ONE steps run, observe: sessionAgent gone (agent_type absent on a
    # later guarded write) and sessionParent gone (would mis-route a
    # later session.idle if one reached the routing check) TOGETHER --
    # still atomic, both driven by trackSessionAndEvictIfOverCap in the
    # same synchronous call, same as before this fix. But
    # handledIdleSessions is NOT evicted at this same 10,000-session
    # mark (its own cap, HANDLED_IDLE_SESSIONS_CAP, is 100,000) -- so the
    # repeat session.idle for the SAME sessionID is correctly SUPPRESSED
    # as an already-handled duplicate, never reaching the (now
    # sessionParent-less) routing check at all: zero misroute, zero
    # re-fire. If a future change put handledIdleSessions back on
    # sessionInsertOrder's shared clock (re-introducing the S1 bug this
    # fix removes), this test's post-eviction session.idle would start
    # producing a handoff-stop-gate.py call again and main_gate_calls
    # would flip from 0 to 1.
    steps=$(python3 - <<'PY'
import json
steps = []
steps.append({"kind":"event","event":{"type":"session.created","properties":{"sessionID":"s16-victim","info":{"id":"s16-victim","parentID":"s16-parent","agent":"software-engineer"}}}})
steps.append({"kind":"event","event":{"type":"session.idle","properties":{"sessionID":"s16-victim"}}})
for i in range(9999):
    sid = f"s16-filler-{i}"
    steps.append({"kind":"event","event":{"type":"session.created","properties":{"sessionID":sid,"info":{"id":sid,"parentID":"s16-parent2"}}}})
steps.append({"kind":"event","event":{"type":"session.created","properties":{"sessionID":"s16-trigger","info":{"id":"s16-trigger","parentID":"s16-parent2"}}}})
steps.append({"kind":"event","event":{"type":"session.idle","properties":{"sessionID":"s16-victim"}}})
steps.append({"kind":"tool-before","tool":"write","sessionID":"s16-victim","args":{"filePath":"scripts/foo.sh","content":"x"}})
print(json.dumps(steps))
PY
)
    payload_log=$(mktemp)
    shim_dir=$(mk_pathshim "$payload_log")
    result=$(printf '%s' "$steps" | PATH="$shim_dir:$PATH" node "$INVOKER" run "$PLUGIN" 2>/dev/null)
    rm -rf "$shim_dir"
    verdict=$(printf '%s' "$result" | tail -n 1 | python3 -c "import json,sys; print(json.load(sys.stdin)['verdict'])" 2>/dev/null)
    sent_agent_type=$(grep "^tech-lead-authoring-guard.py	" "$payload_log" | head -1 | cut -f2- \
        | python3 -c "import json,sys; print(json.load(sys.stdin).get('agent_type', '<ABSENT>'))" 2>/dev/null)
    subagent_gate_calls=$(grep -c "^handoff-subagent-stop-gate.py	" "$payload_log" 2>/dev/null || true)
    main_gate_calls=$(grep -c "^handoff-stop-gate.py	" "$payload_log" 2>/dev/null || true)
    rm -f "$payload_log"
    if [ "$verdict" = "throw" ] && [ "$sent_agent_type" = "<ABSENT>" ] \
        && [ "${subagent_gate_calls:-0}" = "1" ] && [ "${main_gate_calls:-0}" = "0" ]; then
        record_pass "S2 bounded eviction: sessionParent/sessionAgent evict ATOMICALLY together (agent_type absent on the post-eviction write; a routing lookup would find no parentID) while handledIdleSessions is on its OWN independent, much larger cap and survives -- for the same evicted child session, the pre-eviction session.idle correctly ran handoff-subagent-stop-gate.py once (sessionParent intact then), and the post-eviction session.idle is correctly SUPPRESSED as an already-handled duplicate (handledIdleSessions still has it) instead of re-firing OR mis-routing to handoff-stop-gate.py -- confirms the S1-regression's specific compounding failure (B16's original finding) is closed by the decoupled caps, not just relocated"
    else
        record_fail "S2 bounded eviction: identity maps evict together, handledIdleSessions decoupled and survives" \
            "verdict=$verdict sent_agent_type=$sent_agent_type subagent_gate_calls=${subagent_gate_calls:-0} main_gate_calls=${main_gate_calls:-0}"
    fi

    # ---- B17: idempotency survives eviction (property: "a sessionID
    # that has aged off SESSION_STATE_CAP still dedupes its own
    # session.idle"). Originally recorded as a `record_finding` (open
    # disposition question) because hook-bridge.js's
    # trackSessionAndEvictIfOverCap comment named this exact risk as
    # accepted-but-unverified and this test then CONFIRMED it
    # reproducible: handledIdleSessions was evicted on the SAME FIFO
    # clock as sessionParent/sessionAgent, so once a sessionID aged out
    # of SESSION_STATE_CAP=10000, a LATER session.idle for that SAME
    # sessionID was no longer deduped and handoff-stop-gate.py re-ran.
    # Confirmed (2026-07-25) a REGRESSION introduced BY the S1 fix, not
    # pre-existing: replaying the identical steps against the pre-S1
    # hook-bridge.js (commit 1368fab~1) called the gate exactly once,
    # since nothing was ever evicted there.
    #
    # tech-lead disposition: FIX, not accept as residual risk (trading
    # lifecycle-gate correctness for a session-count-bounded memory
    # concern is the wrong trade). S2 fix (this commit) gives
    # handledIdleSessions its own independent, much larger cap
    # (HANDLED_IDLE_SESSIONS_CAP=100,000) instead of sharing
    # SESSION_STATE_CAP's clock -- see hook-bridge.js's "Fallback"
    # comment above sessionInsertOrder's declaration for the full
    # reasoning and the memory arithmetic. Converted to a normal
    # record_pass/record_fail assertion now that the property holds.
    steps=$(python3 - <<'PY'
import json
steps = []
steps.append({"kind":"event","event":{"type":"session.created","properties":{"sessionID":"s17-main","info":{"id":"s17-main"}}}})
steps.append({"kind":"event","event":{"type":"session.idle","properties":{"sessionID":"s17-main"}}})
for i in range(9999):
    sid = f"s17-filler-{i}"
    steps.append({"kind":"event","event":{"type":"session.created","properties":{"sessionID":sid,"info":{"id":sid,"parentID":"s17-parent"}}}})
steps.append({"kind":"event","event":{"type":"session.created","properties":{"sessionID":"s17-trigger","info":{"id":"s17-trigger","parentID":"s17-parent"}}}})
steps.append({"kind":"event","event":{"type":"session.idle","properties":{"sessionID":"s17-main"}}})
print(json.dumps(steps))
PY
)
    payload_log=$(mktemp)
    shim_dir=$(mk_pathshim "$payload_log")
    printf '%s' "$steps" | PATH="$shim_dir:$PATH" node "$INVOKER" run "$PLUGIN" >/dev/null 2>/dev/null
    rm -rf "$shim_dir"
    stop_gate_calls=$(grep -c "^handoff-stop-gate.py	" "$payload_log" 2>/dev/null || true)
    rm -f "$payload_log"
    if [ "${stop_gate_calls:-0}" = "1" ]; then
        record_pass "S2 idempotency survives eviction: handoff-stop-gate.py still ran at most once across a pre- and post-eviction session.idle pair for the same sessionID -- handledIdleSessions' own independent, larger cap (HANDLED_IDLE_SESSIONS_CAP) means it does NOT forget this sessionID at the same 10,000-session mark sessionParent/sessionAgent evict at"
    else
        record_fail "S2 idempotency survives eviction: handoff-stop-gate.py must run at most once across a pre- and post-eviction session.idle pair for the same sessionID" \
            "handoff-stop-gate.py ran ${stop_gate_calls:-0} time(s) for one sessionID (expected at most 1) -- if this fails, handledIdleSessions is once again evicting in lockstep with sessionParent/sessionAgent (the S1 regression this fix, and B16/B17, exist to prevent)"
    fi
fi

# ===========================================================================
# Summary.
# ===========================================================================

echo
echo "test-opencode-hook-bridge: $pass passed, $fail failed, $skip skipped, $findings finding(s) open."
if [ "$findings" -gt 0 ]; then
    echo
    echo "OPEN FINDINGS (executable-verified, not pass/fail -- needs tech-lead / security-engineer disposition):"
    for f in "${finding_notes[@]}"; do
        echo "  - $f"
    done
fi
if [ "$fail" -gt 0 ]; then
    echo
    echo "Failures:"
    for f in "${failures[@]}"; do
        echo "  - $f"
    done
    exit 1
fi
exit 0
