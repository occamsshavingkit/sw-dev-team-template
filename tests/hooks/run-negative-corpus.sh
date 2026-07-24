#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# tests/hooks/run-negative-corpus.sh — driver for the hook negative-corpus
# convention (spec 009).
#
# For each YAML fixture under tests/hooks/fixtures/<hook-name>.yml, feeds
# every entry's `payload` to scripts/hooks/<hook-name>.py on stdin and
# asserts the hook does NOT fire a permissionDecision (no `ask`, no `deny`).
# A non-empty stdout from the hook is a false-positive regression and is
# reported with the entry's label / category / rationale.
#
# Usage:
#   tests/hooks/run-negative-corpus.sh --all
#   tests/hooks/run-negative-corpus.sh --hook customer-notes-guard
#   tests/hooks/run-negative-corpus.sh --hook tech-lead-authoring-guard --harness claude-bash
#   tests/hooks/run-negative-corpus.sh --hook customer-notes-guard --category 5
#   tests/hooks/run-negative-corpus.sh --all --harness opencode
#
# Flags:
#   --all                run every fixture under tests/hooks/fixtures/
#   --hook <name>        run only fixtures/<name>.yml
#   --harness <mode>     claude-bash | inline-bang | codex-shell | heredoc |
#                        command-substitution | opencode
#                        For the first five values: restrict cat-6 entries
#                        to that single harness label (unchanged behaviour).
#                        For `opencode`: a distinct MODE, not a cat-6
#                        filter. Every selected entry (any category) is
#                        round-tripped through the OpenCode enforcement
#                        hook bridge's arg-key mapping table
#                        (tests/hooks/lib/opencode_map.py, cross-checked
#                        against scripts/opencode/tool-arg-map.json when
#                        present) — Claude-shaped tool_input ->
#                        (reverse) synthetic OpenCode args -> (forward,
#                        the bridge's own translation direction)
#                        reconstructed Claude-shaped tool_input — and the
#                        RECONSTRUCTED payload is fed to the same
#                        scripts/hooks/<hook>.py. Asserts the negative-
#                        corpus contract still holds post-round-trip: a
#                        bijective, correctly-implemented mapping table
#                        must not turn a silent-proceed entry into a
#                        false positive. Entries with no OpenCode-side
#                        tool counterpart (MultiEdit; fw-adr-0031) are
#                        counted as SKIP, not PASS/FAIL, and reported
#                        separately. Requires no live `opencode` process,
#                        network, or model access — pure data-table
#                        translation, re-using scripts/hooks/*.py directly.
#   --category <n>       restrict to entries with category=<n>
#
# Requires: python3 with PyYAML (yaml.safe_load). PyYAML is a soft
# dependency; if missing, the driver exits 3 with an install hint.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HOOKS_DIR="$REPO_ROOT/scripts/hooks"
FIXTURES_DIR="$REPO_ROOT/tests/hooks/fixtures"

# ----- Flag parsing ---------------------------------------------------------

mode=""
hook=""
harness=""
category=""

while [ "$#" -gt 0 ]; do
    case "$1" in
        --all)        mode="all"; shift ;;
        --hook)       mode="single"; hook="$2"; shift 2 ;;
        --hook=*)     mode="single"; hook="${1#--hook=}"; shift ;;
        --harness)    harness="$2"; shift 2 ;;
        --harness=*)  harness="${1#--harness=}"; shift ;;
        --category)   category="$2"; shift 2 ;;
        --category=*) category="${1#--category=}"; shift ;;
        --help|-h)
            sed -n '/^# Usage:/,/^# Requires:/p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            printf 'run-negative-corpus: unknown flag: %s\n' "$1" >&2
            exit 2
            ;;
    esac
done

if [ -z "$mode" ]; then
    printf 'run-negative-corpus: must pass --all or --hook <name>\n' >&2
    exit 2
fi

# ----- PyYAML availability check -------------------------------------------

if ! python3 -c "import yaml" >/dev/null 2>&1; then
    printf 'run-negative-corpus: python3 yaml module not available.\n' >&2
    printf '  install via: pip install --user PyYAML  (or distro python3-yaml)\n' >&2
    exit 3
fi

# ----- Fixture enumeration --------------------------------------------------

fixtures=()
if [ "$mode" = "all" ]; then
    if [ ! -d "$FIXTURES_DIR" ]; then
        printf 'run-negative-corpus: no fixtures dir at %s\n' "$FIXTURES_DIR" >&2
        exit 1
    fi
    # Skip multi-hook / non-per-hook fixtures whose name does not
    # correspond to a single hook script. session-shapes.yml is consumed
    # by tests/hooks/run-ai-tui-check.sh; opencode-session-events.yml is
    # consumed by tests/hooks/test-opencode-hook-bridge.sh (session
    # lifecycle events, not a per-hook PreToolUse negative corpus) —
    # neither has a corresponding scripts/hooks/<name>.py.
    while IFS= read -r f; do
        case "$(basename "$f")" in
            session-shapes.yml) continue ;;
            opencode-session-events.yml) continue ;;
        esac
        fixtures+=("$f")
    done < <(find "$FIXTURES_DIR" -maxdepth 1 -type f -name '*.yml' | sort)
    if [ "${#fixtures[@]}" -eq 0 ]; then
        printf 'run-negative-corpus: no *.yml fixtures found in %s\n' "$FIXTURES_DIR" >&2
        exit 1
    fi
else
    f="$FIXTURES_DIR/${hook}.yml"
    if [ ! -f "$f" ]; then
        printf 'run-negative-corpus: fixture not found: %s\n' "$f" >&2
        exit 1
    fi
    fixtures+=("$f")
fi

# ----- Per-fixture run ------------------------------------------------------

total_pass=0
total_fail=0
total_skip=0
failing_lines=""

run_fixture() {
    local fixture_path="$1"
    local fname
    fname=$(basename "$fixture_path" .yml)
    local hook_path="$HOOKS_DIR/${fname}.py"
    if [ ! -x "$hook_path" ] && [ ! -f "$hook_path" ]; then
        printf 'run-negative-corpus: no hook at %s for fixture %s\n' "$hook_path" "$fixture_path" >&2
        total_fail=$((total_fail + 1))
        return
    fi

    # `opencode` is a MODE selector, not a cat-6 harness-label filter — see
    # the --harness doc block above. When active, pass an EMPTY
    # HARNESS_FILTER to the python emitter below so no cat-6 entry is
    # dropped by the (irrelevant, in this mode) harness-label check; every
    # selected entry gets round-tripped instead.
    local opencode_mode=0
    local emit_harness_filter="$harness"
    if [ "$harness" = "opencode" ]; then
        opencode_mode=1
        emit_harness_filter=""
    fi

    # Emit entries as US(0x1F)-separated records: label US category US
    # harness US rationale US payload. The payload is base64-encoded to
    # survive the transport without collisions with the field separator.
    #
    # Field separator is ASCII Unit Separator (0x1F, `\x1f`), NOT a tab.
    # Regression note (found while building the --harness opencode
    # extension): bash's `read -r` with `IFS=$'\t'` treats tab as "IFS
    # whitespace" and COLLAPSES a run of it — an empty field between two
    # tabs (e.g. harness="" on every non-category-6 entry) silently
    # vanished, shifting every subsequent field left by one and leaving
    # the last field (the base64 payload) EMPTY. Every hook then received
    # empty/no stdin, hit its own fail-open path, and produced no
    # permissionDecision — which is exactly what the negative-corpus
    # assertion checks for, so the corruption was invisible: entries were
    # silently testing "empty input" instead of their real payload while
    # still reporting PASS. 0x1F is not in bash's IFS-whitespace set, so
    # runs of it do not collapse and empty fields round-trip correctly
    # (verified directly: `printf 'A\x1fB\x1f\x1fD\x1fE\n' | { IFS=$'\x1f'
    # read -r a b c d e; }` yields the expected 5 fields, where the tab
    # form silently produced 4). This fix is orthogonal to the opencode
    # harness mode but was only surfaced by it, because the round-trip
    # step is the first consumer that actually parses tool_input as JSON
    # and therefore visibly chokes on empty input rather than silently
    # satisfying the negative-corpus's "no permissionDecision" check.
    local tsv
    tsv=$(HARNESS_FILTER="$emit_harness_filter" CATEGORY_FILTER="$category" \
        python3 - "$fixture_path" <<'PY'
import base64
import os
import sys
import yaml

US = "\x1f"
fixture = sys.argv[1]
harness_filter = os.environ.get("HARNESS_FILTER", "")
category_filter = os.environ.get("CATEGORY_FILTER", "")
with open(fixture, "r", encoding="utf-8") as f:
    doc = yaml.safe_load(f) or {}
entries = doc.get("entries") or []
for e in entries:
    label = str(e.get("label", "<unlabeled>"))
    cat = str(e.get("category", "0"))
    harness = str(e.get("harness", ""))
    rationale = str(e.get("rationale", ""))
    payload = e.get("payload", "")
    if isinstance(payload, (dict, list)):
        import json
        payload = json.dumps(payload)
    payload = str(payload).rstrip("\n")
    # Filters.
    if category_filter and cat != str(category_filter):
        continue
    if harness_filter and cat == "6" and harness and harness != harness_filter:
        continue
    enc = base64.b64encode(payload.encode("utf-8")).decode("ascii")
    # Sanitise stray separator/newline bytes from human fields (defensive;
    # none of label/rationale/harness should ever legitimately contain
    # 0x1F, but a corpus author could paste one by accident).
    label = label.replace(US, " ").replace("\n", " ")
    rationale = rationale.replace(US, " ").replace("\n", " ")
    harness = harness.replace(US, " ").replace("\n", " ")
    print(f"{label}{US}{cat}{US}{harness}{US}{rationale}{US}{enc}")
PY
)
    local rc=$?
    if [ "$rc" -ne 0 ]; then
        printf 'run-negative-corpus: failed to parse %s (rc=%d)\n' "$fixture_path" "$rc" >&2
        total_fail=$((total_fail + 1))
        return
    fi

    if [ -z "$tsv" ]; then
        printf '[%s] no entries matched filters; skipping\n' "$fname" >&2
        return
    fi

    printf '\n[%s] %d entries\n' "$fname" "$(printf '%s\n' "$tsv" | grep -c .)" >&2

    local fixture_pass=0
    local fixture_fail=0
    local fixture_skip=0
    local opencode_map_lib="$REPO_ROOT/tests/hooks/lib/opencode_map.py"
    # Regression note: the per-entry field MUST NOT be named `harness` here.
    # `harness` (assigned by `read` without `local`, inside a function) is
    # the SAME variable as the top-level --harness CLI flag global (set at
    # flag-parsing time, never `local`-declared) -- a same-name `read`
    # target silently clobbers it once the loop processes its first entry.
    # In --all mode this corrupted every fixture after the first: by the
    # time run_fixture() re-read `$harness` at its own top (for
    # emit_harness_filter / opencode_mode) on fixture #2+, it was reading
    # fixture #1's LAST entry's per-entry harness label, not the user's
    # requested --harness value. Found while verifying --all --harness
    # opencode behaved identically across multiple fixtures.
    while IFS=$'\x1f' read -r label cat entry_harness rationale enc; do
        [ -z "$label" ] && continue
        local payload
        payload=$(printf '%s' "$enc" | base64 --decode 2>/dev/null)

        if [ "$opencode_mode" -eq 1 ]; then
            local claude_tool_input roundtrip_json roundtrip_rc roundtrip_err
            claude_tool_input=$(printf '%s' "$payload" | python3 -c \
                'import json, sys; d = json.load(sys.stdin); print(json.dumps(d.get("tool_input", {})))' \
                2>/dev/null)
            if [ -z "$claude_tool_input" ]; then
                fixture_skip=$((fixture_skip + 1))
                continue
            fi
            local tmp_rt_err
            tmp_rt_err=$(mktemp)
            roundtrip_json=$(python3 "$opencode_map_lib" roundtrip "$claude_tool_input" 2>"$tmp_rt_err")
            roundtrip_rc=$?
            roundtrip_err=$(cat "$tmp_rt_err")
            rm -f "$tmp_rt_err"
            if [ "$roundtrip_rc" -eq 3 ]; then
                # No OpenCode-side tool counterpart for this entry's shape
                # (MultiEdit, or a shape the inference cannot classify).
                # Documented skip, not a pass/fail — see fw-adr-0031's
                # MultiEdit gap.
                fixture_skip=$((fixture_skip + 1))
                continue
            fi
            if [ "$roundtrip_rc" -ne 0 ]; then
                fixture_fail=$((fixture_fail + 1))
                failing_lines+="  FAIL  [$fname/opencode] $label (cat=$cat) — round-trip translation errored (rc=$roundtrip_rc)"$'\n'
                failing_lines+="        rationale: $rationale"$'\n'
                failing_lines+="        stderr: $roundtrip_err"$'\n'
                continue
            fi
            payload=$(printf '{"tool_input": %s}' "$roundtrip_json")
        fi

        local stdout stderr rc_hook
        local tmp_out tmp_err
        tmp_out=$(mktemp)
        tmp_err=$(mktemp)
        # The hook reads tool_input from stdin as a JSON object.
        # The test environment intentionally clears SWDT_AGENT_PUSH so the
        # corpus entries that exercise inline SWDT_AGENT_PUSH actually flex
        # the inline-form parser rather than the env-form.
        CLAUDE_PROJECT_DIR="$REPO_ROOT" \
            env -u SWDT_AGENT_PUSH python3 "$hook_path" \
                <<<"$payload" >"$tmp_out" 2>"$tmp_err"
        rc_hook=$?
        stdout=$(cat "$tmp_out")
        stderr=$(cat "$tmp_err")
        rm -f "$tmp_out" "$tmp_err"

        # An empty stdout is "proceed" — the negative-corpus contract.
        # ANY permissionDecision in stdout is a false-positive regression.
        local tag="$fname"
        [ "$opencode_mode" -eq 1 ] && tag="$fname/opencode-roundtrip"
        if [ "$rc_hook" -ne 0 ]; then
            fixture_fail=$((fixture_fail + 1))
            failing_lines+="  FAIL  [$tag] $label (cat=$cat harness=$entry_harness) — hook exited $rc_hook"$'\n'
            failing_lines+="        rationale: $rationale"$'\n'
            failing_lines+="        stderr: $stderr"$'\n'
            continue
        fi
        if [ -n "$stdout" ]; then
            fixture_fail=$((fixture_fail + 1))
            failing_lines+="  FAIL  [$tag] $label (cat=$cat harness=$entry_harness)"$'\n'
            failing_lines+="        rationale: $rationale"$'\n'
            failing_lines+="        stdout:    $stdout"$'\n'
            [ "$opencode_mode" -eq 1 ] && failing_lines+="        (post-round-trip payload: $payload)"$'\n'
        else
            fixture_pass=$((fixture_pass + 1))
        fi
    done <<EOF
$tsv
EOF

    if [ "$opencode_mode" -eq 1 ]; then
        printf '[%s] %d pass, %d fail, %d skip (opencode round-trip mode)\n' \
            "$fname" "$fixture_pass" "$fixture_fail" "$fixture_skip" >&2
    else
        printf '[%s] %d pass, %d fail\n' "$fname" "$fixture_pass" "$fixture_fail" >&2
    fi
    total_skip=$((total_skip + fixture_skip))
    total_pass=$((total_pass + fixture_pass))
    total_fail=$((total_fail + fixture_fail))
}

for fx in "${fixtures[@]}"; do
    run_fixture "$fx"
done

if [ "$total_skip" -gt 0 ]; then
    printf '\nhook-negative-corpus driver: %d pass, %d fail, %d skip\n' \
        "$total_pass" "$total_fail" "$total_skip" >&2
else
    printf '\nhook-negative-corpus driver: %d pass, %d fail\n' "$total_pass" "$total_fail" >&2
fi
if [ "$total_fail" -gt 0 ]; then
    printf '\nFalse-positive regressions:\n%s' "$failing_lines" >&2
    exit 1
fi
exit 0
