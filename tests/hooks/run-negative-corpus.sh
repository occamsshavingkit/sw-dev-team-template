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
#
# Flags:
#   --all                run every fixture under tests/hooks/fixtures/
#   --hook <name>        run only fixtures/<name>.yml
#   --harness <mode>     restrict cat-6 entries to a single harness mode
#                        (claude-bash | inline-bang | codex-shell |
#                         heredoc | command-substitution)
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
    while IFS= read -r f; do
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

    # Emit entries as TSV: label \t category \t harness \t rationale \t payload
    # Skip entries that don't match the optional --harness / --category filters.
    # The payload is base64-encoded to survive the TSV transport without
    # tab/newline collisions; the bash side decodes it before feeding stdin.
    local tsv
    tsv=$(HARNESS_FILTER="$harness" CATEGORY_FILTER="$category" \
        python3 - "$fixture_path" <<'PY'
import base64
import os
import sys
import yaml

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
    # Sanitise tabs from human fields.
    for fld in (label, rationale, harness):
        if "\t" in fld:
            label = label.replace("\t", " ")
            rationale = rationale.replace("\t", " ")
            harness = harness.replace("\t", " ")
    print(f"{label}\t{cat}\t{harness}\t{rationale}\t{enc}")
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
    while IFS=$'\t' read -r label cat harness rationale enc; do
        [ -z "$label" ] && continue
        local payload
        payload=$(printf '%s' "$enc" | base64 --decode 2>/dev/null)
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
        if [ "$rc_hook" -ne 0 ]; then
            fixture_fail=$((fixture_fail + 1))
            failing_lines+="  FAIL  [$fname] $label (cat=$cat harness=$harness) — hook exited $rc_hook"$'\n'
            failing_lines+="        rationale: $rationale"$'\n'
            failing_lines+="        stderr: $stderr"$'\n'
            continue
        fi
        if [ -n "$stdout" ]; then
            fixture_fail=$((fixture_fail + 1))
            failing_lines+="  FAIL  [$fname] $label (cat=$cat harness=$harness)"$'\n'
            failing_lines+="        rationale: $rationale"$'\n'
            failing_lines+="        stdout:    $stdout"$'\n'
        else
            fixture_pass=$((fixture_pass + 1))
        fi
    done <<EOF
$tsv
EOF

    printf '[%s] %d pass, %d fail\n' "$fname" "$fixture_pass" "$fixture_fail" >&2
    total_pass=$((total_pass + fixture_pass))
    total_fail=$((total_fail + fixture_fail))
}

for fx in "${fixtures[@]}"; do
    run_fixture "$fx"
done

printf '\nhook-negative-corpus driver: %d pass, %d fail\n' "$total_pass" "$total_fail" >&2
if [ "$total_fail" -gt 0 ]; then
    printf '\nFalse-positive regressions:\n%s' "$failing_lines" >&2
    exit 1
fi
exit 0
