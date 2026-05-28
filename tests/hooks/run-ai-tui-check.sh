#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# tests/hooks/run-ai-tui-check.sh — AI TUI interaction check driver.
#
# Feeds session-shape payloads (tests/hooks/fixtures/session-shapes.yml)
# through the PreToolUse hooks installed in a FIXTURE's
# .claude/settings.json configuration, asserting that each payload
# behaves as its `expected:` directive specifies:
#
#   expected: pass  — NO hook fires `ask`/`deny` on the payload
#   expected: deny  — AT LEAST ONE hook fires a `deny` decision
#
# This is the second-tier check beyond the per-hook negative-corpus
# (tests/hooks/run-negative-corpus.sh). The negative-corpus validates
# a SINGLE hook in isolation against a same-named fixture; this
# driver validates the COMPOSED hook set as a real session would
# fire it on a PreToolUse event, against a downstream FIXTURE's
# post-upgrade hooks (not the canonical template's).
#
# Purpose: catch AI-TUI interaction regressions that the script-level
# dogfood (tests/release-gate/dogfood-downstream.sh) misses. See
# feedback-dogfood-needs-tui-check (2026-05-15): the rc11->rc12
# upgrade wired tech-lead-authoring-guard per spec but blocked
# commit-message HEREDOCs and the inline SWDT_AGENT_PUSH escape
# hatch, breaking real session workflow while script-level checks
# showed green.
#
# Hook discovery:
#   The driver parses <fixture>/.claude/settings.json for
#   .hooks.PreToolUse[] entries. Each entry has a `matcher`
#   (e.g. "Bash", "Edit", "Write|MultiEdit") and a list of hook
#   commands. For each session-shape payload, the driver looks up
#   the payload's `tool_name`, finds matchers that apply, and runs
#   each matched hook against the payload.
#
#   Payloads whose tool_name has no matching PreToolUse hook are
#   treated as "no hook fires" → pass-equivalent. An `expected: deny`
#   payload that finds no matchers is therefore a fail.
#
# Usage:
#   tests/hooks/run-ai-tui-check.sh --fixture <path> [--fixture-yaml <path>]
#
# Flags:
#   --fixture <path>       Root of the fixture tree. The driver looks
#                          for <path>/.claude/settings.json. If absent,
#                          the driver exits 4 with a NOTE so the
#                          caller can skip rather than fail.
#   --fixture-yaml <path>  Override the corpus file. Defaults to
#                          tests/hooks/fixtures/session-shapes.yml
#                          relative to the repo root.
#   --help, -h             Print this help and exit.
#
# Exit codes:
#   0  PASS — every payload behaved as expected
#   1  FAIL — at least one payload behaved inappropriately
#   2  Argument or invocation error
#   3  PyYAML missing (install hint emitted)
#   4  NOTE — fixture has no .claude/settings.json or no PreToolUse
#      hooks configured; phase skipped (caller treats as benign)
#
# Requires: python3 with PyYAML.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DEFAULT_YAML="$REPO_ROOT/tests/hooks/fixtures/session-shapes.yml"

usage() {
    sed -n '/^# Usage:/,/^# Requires:/p' "$0" | sed 's/^# \{0,1\}//'
}

fixture=""
fixture_yaml="$DEFAULT_YAML"

while [ "$#" -gt 0 ]; do
    case "$1" in
        --fixture)        fixture="$2"; shift 2 ;;
        --fixture=*)      fixture="${1#--fixture=}"; shift ;;
        --fixture-yaml)   fixture_yaml="$2"; shift 2 ;;
        --fixture-yaml=*) fixture_yaml="${1#--fixture-yaml=}"; shift ;;
        --help|-h)        usage; exit 0 ;;
        *)
            printf 'run-ai-tui-check: unknown flag: %s\n' "$1" >&2
            exit 2
            ;;
    esac
done

if [ -z "$fixture" ]; then
    printf 'run-ai-tui-check: --fixture is required\n' >&2
    exit 2
fi

if [ ! -d "$fixture" ]; then
    printf 'run-ai-tui-check: fixture not a directory: %s\n' "$fixture" >&2
    exit 2
fi

settings_path="$fixture/.claude/settings.json"
if [ ! -f "$settings_path" ]; then
    printf 'run-ai-tui-check: NOTE no settings at %s; AI TUI check skipped\n' "$settings_path" >&2
    exit 4
fi

if [ ! -f "$fixture_yaml" ]; then
    printf 'run-ai-tui-check: corpus YAML not found: %s\n' "$fixture_yaml" >&2
    exit 2
fi

if ! python3 -c "import yaml" >/dev/null 2>&1; then
    printf 'run-ai-tui-check: python3 yaml module not available.\n' >&2
    printf '  install via: pip install --user PyYAML  (or distro python3-yaml)\n' >&2
    exit 3
fi

# ----- Parse PreToolUse hook table out of settings.json
# Emit TSV: matcher \t cmd (one row per (matcher, hook command) pair).
# Matchers are bar-delimited (Claude Code spec) — the cmd row carries
# the raw matcher string; matching against a tool_name is done in
# bash below by splitting on '|' and comparing.
hooktab=$(python3 - "$settings_path" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as f:
    doc = json.load(f)
hooks = doc.get("hooks") or {}
for entry in hooks.get("PreToolUse") or []:
    matcher = str(entry.get("matcher", ""))
    for hk in entry.get("hooks") or []:
        if hk.get("type") != "command":
            continue
        cmd = str(hk.get("command", ""))
        matcher_clean = matcher.replace("\t", " ")
        cmd_clean = cmd.replace("\t", " ").replace("\n", " ")
        print(f"{matcher_clean}\t{cmd_clean}")
PY
)
hp_rc=$?
if [ "$hp_rc" -ne 0 ]; then
    printf 'run-ai-tui-check: failed to parse settings.json (rc=%d)\n' "$hp_rc" >&2
    exit 2
fi

if [ -z "$hooktab" ]; then
    printf 'run-ai-tui-check: NOTE no PreToolUse hooks in %s; AI TUI check skipped\n' "$settings_path" >&2
    exit 4
fi

n_hooks=$(printf '%s\n' "$hooktab" | grep -c .)
printf 'run-ai-tui-check: fixture=%s PreToolUse-hook-rows=%d\n' "$fixture" "$n_hooks" >&2
printf '%s\n' "$hooktab" | while IFS=$'\t' read -r m c; do
    printf '  matcher=%s  cmd=%s\n' "$m" "$c" >&2
done

# ----- Parse corpus into TSV: label \t category \t expected \t rationale \t payload (b64)
tsv=$(python3 - "$fixture_yaml" <<'PY'
import base64
import json
import sys
import yaml

with open(sys.argv[1], "r", encoding="utf-8") as f:
    doc = yaml.safe_load(f) or {}
entries = doc.get("entries") or []
for e in entries:
    label = str(e.get("label", "<unlabeled>"))
    cat = str(e.get("category", "0"))
    expected = str(e.get("expected", "pass"))
    rationale = str(e.get("rationale", ""))
    payload = e.get("payload", "")
    if isinstance(payload, (dict, list)):
        payload = json.dumps(payload)
    payload = str(payload).rstrip("\n")
    enc = base64.b64encode(payload.encode("utf-8")).decode("ascii")
    label = label.replace("\t", " ")
    rationale = rationale.replace("\t", " ")
    print(f"{label}\t{cat}\t{expected}\t{rationale}\t{enc}")
PY
)
rc=$?
if [ "$rc" -ne 0 ] || [ -z "$tsv" ]; then
    printf 'run-ai-tui-check: failed to parse %s (rc=%d, empty=%s)\n' \
        "$fixture_yaml" "$rc" "$( [ -z "$tsv" ] && echo yes || echo no )" >&2
    exit 2
fi

n_entries=$(printf '%s\n' "$tsv" | grep -c .)
printf 'run-ai-tui-check: corpus entries=%d\n' "$n_entries" >&2

# ----- Helper: parse a permissionDecision out of stdout if it is JSON.
# Non-JSON stdout (e.g. SessionStart-style banner text from reminder
# hooks) is treated as benign — not a decision.
parse_decision() {
    printf '%s' "$1" | python3 -c '
import json
import sys

raw = sys.stdin.read().strip()
if not raw:
    print("")
    sys.exit(0)
try:
    d = json.loads(raw)
except Exception:
    # Non-JSON stdout from a hook is informational, not a permission
    # decision. Treat as benign.
    print("")
    sys.exit(0)
if not isinstance(d, dict):
    print("")
    sys.exit(0)
h = d.get("hookSpecificOutput") or {}
print(h.get("permissionDecision", ""))
' 2>/dev/null
}

# ----- Helper: extract tool_name from a payload (JSON).
extract_tool_name() {
    printf '%s' "$1" | python3 -c '
import json
import sys

try:
    d = json.load(sys.stdin)
    print(d.get("tool_name", ""))
except Exception:
    print("")
' 2>/dev/null
}

# ----- Helper: does matcher_str (e.g. "Edit" or "Edit|Write") match tool_name?
matcher_matches() {
    local matcher="$1"
    local tool="$2"
    [ -z "$matcher" ] && return 0    # empty matcher = match all
    [ -z "$tool" ] && return 1
    local IFS='|'
    # shellcheck disable=SC2086
    set -- $matcher
    for m in "$@"; do
        if [ "$m" = "$tool" ]; then
            return 0
        fi
    done
    return 1
}

# ----- Run each payload through the matching hooks.
total_pass=0
total_fail=0
failing_lines=""

while IFS=$'\t' read -r label cat expected rationale enc; do
    [ -z "$label" ] && continue
    payload=$(printf '%s' "$enc" | base64 --decode 2>/dev/null)
    tool_name=$(extract_tool_name "$payload")

    aggregate="pass"
    detail=""
    matched_any="no"

    while IFS=$'\t' read -r matcher cmd; do
        [ -z "$cmd" ] && continue
        if ! matcher_matches "$matcher" "$tool_name"; then
            continue
        fi
        matched_any="yes"

        # Run the hook command with payload on stdin. Honour the
        # fixture as CLAUDE_PROJECT_DIR so allow-list-relative path
        # normalisation works the way a real session would.
        tmp_out=$(mktemp)
        tmp_err=$(mktemp)
        CLAUDE_PROJECT_DIR="$fixture" \
            env -u SWDT_AGENT_PUSH /bin/sh -c "$cmd" \
                <<<"$payload" >"$tmp_out" 2>"$tmp_err"
        hook_rc=$?
        stdout=$(cat "$tmp_out")
        stderr=$(cat "$tmp_err")
        rm -f "$tmp_out" "$tmp_err"

        # Identify the hook by its trailing basename for diagnostics.
        # The cmd shape is e.g. `python3 "${CLAUDE_PROJECT_DIR}/scripts/hooks/foo.py"`;
        # we pull the basename of the last path-like token and strip
        # any trailing quote.
        # shellcheck disable=SC2016  # deliberate: python source is single-quoted
        hook_name=$(printf '%s' "$cmd" | python3 -c '
import re
import sys
raw = sys.stdin.read()
m = re.findall(r"[\w./${}-]+\.(?:py|sh)", raw)
if m:
    base = m[-1].rsplit("/", 1)[-1]
    print(base)
else:
    print("<hook>")
' 2>/dev/null)

        if [ "$hook_rc" -ne 0 ]; then
            aggregate="crash"
            detail="$hook_name exited $hook_rc; stderr=$stderr"
            break
        fi

        decision=$(parse_decision "$stdout")
        case "$decision" in
            deny)
                aggregate="deny"
                detail="$hook_name denied"
                break
                ;;
            ask)
                if [ "$aggregate" = "pass" ]; then
                    aggregate="ask"
                    detail="$hook_name asked"
                fi
                ;;
            "")
                : # no decision; benign
                ;;
            *)
                aggregate="malformed"
                detail="$hook_name emitted unknown decision: $decision"
                break
                ;;
        esac
    done <<HOOKTAB
$hooktab
HOOKTAB

    # Compare to expected directive.
    ok=""
    case "$expected" in
        pass) [ "$aggregate" = "pass" ] && ok="yes" ;;
        deny) [ "$aggregate" = "deny" ] && ok="yes" ;;
        ask)  { [ "$aggregate" = "ask" ] || [ "$aggregate" = "deny" ]; } && ok="yes" ;;
    esac

    if [ "$ok" = "yes" ]; then
        total_pass=$((total_pass + 1))
    else
        total_fail=$((total_fail + 1))
        failing_lines+="  FAIL  $label (cat=$cat tool=$tool_name)"$'\n'
        failing_lines+="        expected: $expected   got: $aggregate   matched-hooks: $matched_any"$'\n'
        failing_lines+="        rationale: $rationale"$'\n'
        if [ -n "$detail" ]; then
            failing_lines+="        detail:    $detail"$'\n'
        fi
    fi
done <<EOF
$tsv
EOF

printf '\nai-tui-check: %d pass, %d fail (fixture=%s)\n' "$total_pass" "$total_fail" "$fixture" >&2
if [ "$total_fail" -gt 0 ]; then
    printf '\nAI TUI regressions:\n%s' "$failing_lines" >&2
    exit 1
fi
exit 0
