#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
#
# scripts/audit-agent-tools.sh — pre-flight audit of .claude/agents/*.md
# frontmatter against the body. Flags agents whose `description:` or
# body text implies capabilities their `tools:` grant does not cover.
#
# Motivating case: `architect.md` was shipped with `tools: Read, Grep,
# Glob` but its description and body explicitly require writing ADRs,
# architecture descriptions, and specification drafts — round-tripping
# every write back through tech-lead. See upstream issue #11.
#
# Usage:
#   scripts/audit-agent-tools.sh
#       # scans .claude/agents/*.md in the current project and prints
#       # a report of mismatches to stdout.
#   scripts/audit-agent-tools.sh --strict
#       # exits non-zero if any WARN or FAIL rows are emitted. Useful
#       # in CI / pre-commit.
#
# Heuristic only. Flags are cues, not verdicts; review the agent file
# before acting.
#
# Exit codes:
#   0 — clean (no mismatches, or not in strict mode)
#   1 — strict mode + mismatches found
#   2 — usage error

set -euo pipefail

strict=0
if [[ "${1:-}" == "--strict" ]]; then
  strict=1
elif [[ $# -gt 0 ]]; then
  echo "Usage: $0 [--strict]" >&2
  exit 2
fi

project_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
agents_dir="$project_root/.claude/agents"

if [[ ! -d "$agents_dir" ]]; then
  echo "No .claude/agents/ directory found under $project_root — nothing to audit." >&2
  exit 0
fi

# Keywords that imply a tool requirement. Order matters for first-match
# reporting. Patterns are lowercase; file contents lowercased before match.
declare -A imply
imply[Write]="write the file|write to \`|produce .* artifact|produce .* deliverab|author .* adr|author .* document|write a report|append an entry|append to the journal|maintain .* register|maintain .* inventory|steward .* document|record .* in \`|create .* template|produce the .* template|drafts? .*\.md|stubs out|writes .*\.md"
imply[Edit]="amend the|revise the|update the|update .* file|insert a row|insert a line|update .* register|rewrite|replace the|update section|edit in place|amend in place"
imply[Bash]="run a script|run the script|run the build|run tests|execute the|shell command|bash command|git log|git diff|git status|run \`|shell script|invoke a shell|invoke .* script"
imply[Grep]="grep|search for|scan for|audit files|find references"
imply[Glob]="glob|walk the tree|list files matching"
imply[SendMessage]="sendmessage|send a message to|ping the|hand off to|dispatch to"
imply[WebSearch]="web search|search the web|web-search|look up online"
imply[WebFetch]="webfetch|fetch the url|download .* page|pull the .* docs"

emit_header() {
  printf '%-24s | %-10s | %-12s | %s\n' "agent" "severity" "missing" "reason"
  printf '%-24s | %-10s | %-12s | %s\n' "------------------------" "----------" "------------" "--------------------------------------------------"
}

found_any=0

emit_header

for f in "$agents_dir"/*.md; do
  [[ -f "$f" ]] || continue

  name="$(basename "$f" .md)"
  tools_line=$(awk '/^tools:/ {print; exit}' "$f")
  if [[ -z "$tools_line" ]]; then
    printf '%-24s | %-10s | %-12s | %s\n' "$name" "WARN" "(no tools:)" "frontmatter has no tools: line"
    found_any=1
    continue
  fi

  # Extract granted tools (after "tools:" up to end-of-line).
  granted="${tools_line#tools:}"
  granted="$(echo "$granted" | tr ',' ' ' | tr -d '[]' | xargs)"

  # Body text (lowercased, frontmatter stripped) for keyword match.
  body_lc=$(awk 'BEGIN{in_fm=0} /^---$/{in_fm=1-in_fm; next} !in_fm {print tolower($0)}' "$f")

  for needed in "${!imply[@]}"; do
    # Is this tool granted?
    granted_lc=" $(echo "$granted" | tr '[:upper:]' '[:lower:]') "
    needed_lc="$(echo "$needed" | tr '[:upper:]' '[:lower:]')"
    if [[ "$granted_lc" == *" $needed_lc "* ]]; then
      continue
    fi

    # Not granted — is it implied by the body?
    pattern="${imply[$needed]}"
    if echo "$body_lc" | grep -Eq "$pattern"; then
      reason="body text mentions $(echo "$body_lc" | grep -Eom1 "$pattern" | head -c 60)…"
      printf '%-24s | %-10s | %-12s | %s\n' "$name" "WARN" "$needed" "$reason"
      found_any=1
    fi
  done
done

if (( found_any == 0 )); then
  echo "Clean — no implied-tool mismatches in $agents_dir" >&2
fi

if (( strict == 1 && found_any == 1 )); then
  exit 1
fi
exit 0
