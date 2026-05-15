#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# scripts/log-fallback.sh — record a model-fallback event to
# docs/pm/fallback-log.jsonl as a single JSON-line entry.
#
# Backs FR-020 (six required fields) and research.md R-10 (the
# "; downgraded_one_tier" suffix when no same-class peer was
# available). See specs/006-template-improvement-program for context.
#
# POSIX-sh, set -eu. Uses jq when available for safe JSON emission;
# falls back to printf escaping otherwise.

set -eu

usage() {
  cat <<'EOF' >&2
Usage: log-fallback.sh --agent <slug> --requested-model <id> \
    --actual-model <id> --reason <reason> --task-id <id> \
    [--downgraded-one-tier] [--timestamp <ISO 8601>] \
    [--log-path <path>]

Reasons (one of):
  credit_exhausted
  provider_unavailable_5xx
  provider_timeout
  provider_rate_limit

Appends one JSON object per line to docs/pm/fallback-log.jsonl
(relative to git toplevel) unless --log-path overrides.
EOF
}

AGENT=""
REQUESTED_MODEL=""
ACTUAL_MODEL=""
REASON=""
TASK_ID=""
TIMESTAMP=""
LOG_PATH=""
DOWNGRADED=0

while [ $# -gt 0 ]; do
  case "$1" in
    --agent)
      [ $# -ge 2 ] || { usage; exit 2; }
      AGENT="$2"
      shift 2
      ;;
    --requested-model)
      [ $# -ge 2 ] || { usage; exit 2; }
      REQUESTED_MODEL="$2"
      shift 2
      ;;
    --actual-model)
      [ $# -ge 2 ] || { usage; exit 2; }
      ACTUAL_MODEL="$2"
      shift 2
      ;;
    --reason)
      [ $# -ge 2 ] || { usage; exit 2; }
      REASON="$2"
      shift 2
      ;;
    --task-id)
      [ $# -ge 2 ] || { usage; exit 2; }
      TASK_ID="$2"
      shift 2
      ;;
    --timestamp)
      [ $# -ge 2 ] || { usage; exit 2; }
      TIMESTAMP="$2"
      shift 2
      ;;
    --log-path)
      [ $# -ge 2 ] || { usage; exit 2; }
      LOG_PATH="$2"
      shift 2
      ;;
    --downgraded-one-tier)
      DOWNGRADED=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'log-fallback.sh: unknown argument: %s\n' "$1" >&2
      usage
      exit 2
      ;;
  esac
done

if [ -z "$AGENT" ] || [ -z "$REQUESTED_MODEL" ] || [ -z "$ACTUAL_MODEL" ] \
    || [ -z "$REASON" ] || [ -z "$TASK_ID" ]; then
  printf 'log-fallback.sh: missing required argument\n' >&2
  usage
  exit 2
fi

case "$REASON" in
  credit_exhausted|provider_unavailable_5xx|provider_timeout|provider_rate_limit)
    ;;
  *)
    printf 'log-fallback.sh: invalid --reason: %s\n' "$REASON" >&2
    usage
    exit 2
    ;;
esac

if [ "$DOWNGRADED" -eq 1 ]; then
  REASON="${REASON}; downgraded_one_tier"
fi

if [ -z "$TIMESTAMP" ]; then
  TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
fi

if [ -z "$LOG_PATH" ]; then
  TOPLEVEL="$(git rev-parse --show-toplevel 2>/dev/null || true)"
  if [ -z "$TOPLEVEL" ]; then
    TOPLEVEL="$(pwd)"
  fi
  LOG_PATH="${TOPLEVEL}/docs/pm/fallback-log.jsonl"
fi

LOG_DIR="$(dirname "$LOG_PATH")"
mkdir -p "$LOG_DIR"

# Build JSON line. Prefer jq for safety; fall back to printf escaping.
if command -v jq >/dev/null 2>&1; then
  LINE="$(jq -c -n \
    --arg agent "$AGENT" \
    --arg requested_model "$REQUESTED_MODEL" \
    --arg actual_model "$ACTUAL_MODEL" \
    --arg fallback_reason "$REASON" \
    --arg timestamp "$TIMESTAMP" \
    --arg task_id "$TASK_ID" \
    '{agent: $agent, requested_model: $requested_model, actual_model: $actual_model, fallback_reason: $fallback_reason, timestamp: $timestamp, task_id: $task_id}')"
else
  # Minimal JSON-string escaping: backslash, double-quote, control chars.
  json_escape() {
    # shellcheck disable=SC2039
    printf '%s' "$1" | awk '
      BEGIN { RS="\0" }
      {
        gsub(/\\/, "\\\\")
        gsub(/"/, "\\\"")
        gsub(/\b/, "\\b")
        gsub(/\f/, "\\f")
        gsub(/\n/, "\\n")
        gsub(/\r/, "\\r")
        gsub(/\t/, "\\t")
        printf "%s", $0
      }
    '
  }
  E_AGENT="$(json_escape "$AGENT")"
  E_REQ="$(json_escape "$REQUESTED_MODEL")"
  E_ACT="$(json_escape "$ACTUAL_MODEL")"
  E_REASON="$(json_escape "$REASON")"
  E_TS="$(json_escape "$TIMESTAMP")"
  E_TASK="$(json_escape "$TASK_ID")"
  LINE="{\"agent\":\"${E_AGENT}\",\"requested_model\":\"${E_REQ}\",\"actual_model\":\"${E_ACT}\",\"fallback_reason\":\"${E_REASON}\",\"timestamp\":\"${E_TS}\",\"task_id\":\"${E_TASK}\"}"
fi

# Ensure file ends with newline before appending (create if missing).
if [ ! -e "$LOG_PATH" ]; then
  : > "$LOG_PATH"
else
  if [ -s "$LOG_PATH" ]; then
    LAST_BYTE="$(tail -c 1 "$LOG_PATH" 2>/dev/null || true)"
    if [ "$LAST_BYTE" != "" ] && [ "$(printf '%s' "$LAST_BYTE" | wc -c | tr -d ' ')" -gt 0 ]; then
      printf '\n' >> "$LOG_PATH"
    fi
  fi
fi

printf '%s\n' "$LINE" >> "$LOG_PATH"
printf '%s\n' "$LINE"
