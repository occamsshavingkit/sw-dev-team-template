#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
#
# scripts/intake-show.sh — render docs/intake-log.md as a readable
# transcript for customer review and qa-engineer conformance audit.
#
# Usage:
#   scripts/intake-show.sh [--from N] [--to M] [--since YYYY-MM-DD]
#                          [--violations-only]
#
# Options:
#   --from N             first turn to include (default: 1)
#   --to M               last turn to include (default: last)
#   --since YYYY-MM-DD   only entries with timestamp ≥ DATE
#   --violations-only    only entries where agents-running-at-ask != []
#
# Reads docs/intake-log.md by default. Override via INTAKE_LOG env var.
#
# Exits 0 on success; 2 on usage error; 1 if --violations-only and any
# violations were found (for CI/pre-commit integration).

set -euo pipefail

log_file="${INTAKE_LOG:-docs/intake-log.md}"
from=1
to=999999
since=""
violations_only=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --from)  from="$2"; shift 2 ;;
    --to)    to="$2";   shift 2 ;;
    --since) since="$2"; shift 2 ;;
    --violations-only) violations_only=1; shift ;;
    -h|--help)
      sed -n 's/^# \{0,1\}//;3,17p' "$0"
      exit 0
      ;;
    *) echo "Usage: $0 [--from N] [--to M] [--since YYYY-MM-DD] [--violations-only]" >&2
       exit 2 ;;
  esac
done

if [[ ! -f "$log_file" ]]; then
  echo "No intake log at $log_file (override with INTAKE_LOG=...)" >&2
  exit 2
fi

awk -v from="$from" -v to="$to" -v since="$since" -v vonly="$violations_only" '
  BEGIN { in_block=0; buf=""; turn=""; ts=""; arr=""; violation_found=0 }
  /^---$/ {
    if (in_block == 1) {
      include = 1
      if (turn+0 < from+0) include = 0
      if (turn+0 > to+0)   include = 0
      if (since != "" && ts != "" && ts < since) include = 0
      if (vonly == 1 && arr == "[]") include = 0
      if (arr != "[]" && arr != "") violation_found = 1
      if (include == 1) {
        printf "%s\n", buf
        print "---"
      }
      in_block = 0; buf = ""; turn = ""; ts = ""; arr = ""
    } else {
      in_block = 1
      buf = "---"
    }
    next
  }
  in_block == 1 {
    buf = buf "\n" $0
    if ($1 == "turn:")                     { turn = $2 }
    if ($1 == "timestamp:")                { ts = $2 }
    if ($1 == "agents-running-at-ask:")    { arr = $2 }
  }
  END {
    if (vonly == 1 && violation_found == 1) exit 1
  }
' "$log_file"
