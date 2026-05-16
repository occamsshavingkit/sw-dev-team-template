#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# scripts/lint-agent-model-routing.sh — binding default-class gate for
# agent contracts (#207 Part B).
#
# Steps:
#   1. Parse the binding default-class table from
#      docs/model-routing-guidelines.md into JSON (one object per agent row).
#   2. Validate the extracted JSON against schemas/model-routing.schema.json
#      using check-jsonschema.
#   3. For each .claude/agents/<role>.md in the template, read the
#      frontmatter model: value and verify it is the preferred Claude
#      equivalent OR the next-higher Claude tier (availability-fallback):
#        haiku-preferred roles  → haiku | sonnet
#        sonnet-preferred roles → sonnet | opus
#        opus-preferred roles   → opus
#      model: inherit always fails.
#   4. Check that every agent listed in the table has a contract file.
#   5. If a project-local override supplement exists (carrying the
#      project_local_override_marker per schemas/model-routing.schema.json)
#      log it as "override-respected" rather than failing.
#
# Exit codes:
#   0  all checks pass
#   1  one or more checks fail (diagnostic printed to stderr)
#   2  usage / environment error
#
# Usage:
#   scripts/lint-agent-model-routing.sh [--summary]
#   scripts/lint-agent-model-routing.sh --agents-dir <path>
#   scripts/lint-agent-model-routing.sh --rubric <path>
#
# POSIX-sh only: no bashisms; LANG=C/LC_ALL=C.
# Requires: python3, check-jsonschema (pipx install check-jsonschema).

set -eu

LANG=C
LC_ALL=C
export LANG LC_ALL

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

AGENTS_DIR="${REPO_ROOT}/.claude/agents"
RUBRIC="${REPO_ROOT}/docs/model-routing-guidelines.md"
SCHEMA="${REPO_ROOT}/schemas/model-routing.schema.json"

SUMMARY=0

usage() {
    cat >&2 <<'EOF'
Usage: scripts/lint-agent-model-routing.sh [--summary]
       scripts/lint-agent-model-routing.sh --agents-dir <path>
       scripts/lint-agent-model-routing.sh --rubric <path>

Checks that every .claude/agents/<role>.md contract has a model: field
equal to the Claude equivalent (or next-higher availability-fallback tier)
per the binding default-class table in docs/model-routing-guidelines.md.

Flags:
  --summary          emit a final summary count line
  --agents-dir DIR   override agents directory (default: .claude/agents)
  --rubric FILE      override rubric source (default: docs/model-routing-guidelines.md)
  -h | --help        this help

Exit codes:
  0  all agent contracts pass
  1  one or more failures
  2  usage / environment error
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --summary) SUMMARY=1; shift ;;
        --agents-dir)
            [ $# -ge 2 ] || { usage; exit 2; }
            AGENTS_DIR="$2"; shift 2 ;;
        --rubric)
            [ $# -ge 2 ] || { usage; exit 2; }
            RUBRIC="$2"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) printf 'lint-agent-model-routing: unknown arg: %s\n' "$1" >&2; usage; exit 2 ;;
    esac
done

# ---- Environment checks ---------------------------------------------------

if [ ! -f "$RUBRIC" ]; then
    printf 'lint-agent-model-routing: rubric not found: %s\n' "$RUBRIC" >&2
    exit 2
fi

if [ ! -f "$SCHEMA" ]; then
    printf 'lint-agent-model-routing: schema not found: %s\n' "$SCHEMA" >&2
    exit 2
fi

if [ ! -d "$AGENTS_DIR" ]; then
    printf 'lint-agent-model-routing: agents dir not found: %s\n' "$AGENTS_DIR" >&2
    exit 2
fi

# check-jsonschema may be on PATH or in the pipx bin dir.
if ! command -v check-jsonschema >/dev/null 2>&1; then
    printf 'lint-agent-model-routing: check-jsonschema not found; install via: pipx install check-jsonschema\n' >&2
    exit 2
fi

# ---- Step 1: Parse rubric table into JSON via python3 --------------------
#
# The table starts after "## Binding per-agent default-class table" and has
# the header:
#   | Agent | default_class | Claude equivalent | OpenAI equivalent | Gemini equivalent | frontier_only_when |
# Each data row is parsed into a JSON object per agent.

EXTRACTED_JSON="$(mktemp)"
trap 'rm -f "$EXTRACTED_JSON"' EXIT INT TERM HUP

python3 << PYEOF > "$EXTRACTED_JSON"
import sys, json, re

rubric_path = """$RUBRIC"""
with open(rubric_path, encoding="utf-8") as f:
    lines = f.readlines()

in_section = False
header_seen = False
agents = []

for line in lines:
    stripped = line.rstrip("\n")
    if re.match(r'^## Binding per-agent default-class table', stripped):
        in_section = True
        continue
    if in_section and re.match(r'^## ', stripped):
        break
    if not in_section:
        continue
    if not stripped.startswith('|'):
        continue
    if re.match(r'^\|[-:| ]+\|$', stripped):
        continue
    cols = [c.strip() for c in stripped.strip('|').split('|')]
    if not header_seen:
        header_seen = True
        continue
    if len(cols) < 6:
        continue
    agent_raw, default_class, claude_eq, openai_eq, gemini_eq, frontier = cols[:6]
    agent = agent_raw.strip('\`').strip()
    if not agent:
        continue
    agents.append({
        "agent": agent,
        "default_class": default_class.strip('\`').strip(),
        "claude_equivalent": claude_eq.strip('\`').strip(),
        "openai_equivalent": openai_eq.strip('\`').strip(),
        "gemini_equivalent": gemini_eq.strip('\`').strip(),
        "frontier_only_when": frontier.strip(),
    })

if not agents:
    print("lint-agent-model-routing: no agents parsed from rubric table", file=sys.stderr)
    sys.exit(1)

output = {
    "version": "0.0.0",
    "binding": True,
    "agents": [
        {
            "agent": a["agent"],
            "default_class": a["default_class"],
            "claude_equivalent": a["claude_equivalent"],
            "openai_equivalent": a["openai_equivalent"],
            "gemini_equivalent": a["gemini_equivalent"],
            "frontier_only_when": a["frontier_only_when"],
        }
        for a in agents
    ],
    "fallback": {
        "triggers": [
            "credit_exhausted",
            "provider_unavailable_5xx",
            "provider_timeout",
            "provider_rate_limit"
        ],
        "substitution_policy": "closest-peer-then-one-tier-down",
        "log_path": "docs/pm/fallback-log.jsonl"
    }
}
print(json.dumps(output, indent=2))
PYEOF

if [ ! -s "$EXTRACTED_JSON" ]; then
    printf 'lint-agent-model-routing: rubric parse produced no output\n' >&2
    exit 1
fi

# ---- Step 2: Validate extracted JSON against schema ----------------------

if ! check-jsonschema --schemafile "$SCHEMA" "$EXTRACTED_JSON" >/dev/null 2>&1; then
    printf 'lint-agent-model-routing: schema validation FAIL\n' >&2
    check-jsonschema --schemafile "$SCHEMA" "$EXTRACTED_JSON" >&2 || true
    exit 1
fi

# ---- Steps 3+4: Check each agent contract against the parsed table -------
#
# Availability-fallback chains (Claude Code, upward only):
#   haiku-preferred  -> haiku, sonnet
#   sonnet-preferred -> sonnet, opus
#   opus-preferred   -> opus

python3 << PYEOF
import sys, json, os, re

with open("""$EXTRACTED_JSON""", encoding="utf-8") as f:
    data = json.load(f)

agents_dir = """$AGENTS_DIR"""
agents = data["agents"]

FALLBACK_ALLOWED = {
    "haiku":  {"haiku", "sonnet"},
    "sonnet": {"sonnet", "opus"},
    "opus":   {"opus"},
}

def parse_model_frontmatter(filepath):
    try:
        with open(filepath, encoding="utf-8") as f:
            lines = f.readlines()
    except OSError:
        return None
    if not lines or not lines[0].startswith("---"):
        return None
    for line in lines[1:]:
        if line.startswith("---"):
            break
        m = re.match(r'^model:\s*(\S+)', line)
        if m:
            return m.group(1).strip()
    return None

failures = []

local_supplement = os.path.join(
    os.path.dirname(agents_dir),
    "docs", "model-routing-guidelines.local.md"
)
if os.path.exists(local_supplement):
    print(f"  override-respected: project-local supplement found at {local_supplement}")

for row in agents:
    agent_name = row["agent"]
    preferred = row["claude_equivalent"]
    contract_file = os.path.join(agents_dir, f"{agent_name}.md")

    if not os.path.exists(contract_file):
        failures.append(
            f"  MISSING_CONTRACT: {agent_name} — expected {contract_file}"
        )
        continue

    model_val = parse_model_frontmatter(contract_file)
    if model_val is None:
        failures.append(
            f"  NO_MODEL_FIELD: {agent_name} ({contract_file}) — no model: frontmatter"
        )
        continue

    allowed = FALLBACK_ALLOWED.get(preferred, {preferred})
    if model_val not in allowed:
        failures.append(
            f"  BAD_MODEL: {agent_name} — expected one of {sorted(allowed)}, found '{model_val}' (preferred: '{preferred}')"
        )

if failures:
    for msg in failures:
        print(msg, file=sys.stderr)
    sys.exit(1)

sys.exit(0)
PYEOF

EXIT_CODE=$?

if [ "$SUMMARY" -eq 1 ]; then
    if [ "$EXIT_CODE" -eq 0 ]; then
        printf 'lint-agent-model-routing: PASS\n'
    else
        printf 'lint-agent-model-routing: FAIL\n'
    fi
fi

exit "$EXIT_CODE"
