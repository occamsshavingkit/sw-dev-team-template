#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# tests/upgrade/test-conflicts-parser-sanity-issue-222.sh — regression for
# issue #222: malformed/truncated .template-conflicts.json that contains raw
# "classified": "conflict" markers but is unparseable by the line-level loop
# must hard-fail (exit 1) with a clear repair-steps message.
#
# Background:
#   The writer in upgrade.sh formerly used `} > "$conflicts_path"` — a
#   truncate-then-write that can leave a partial file on disk if the process
#   is killed mid-write.  The parser uses a line-level grep/sed loop with no
#   JSON-validity check.  A truncated file can produce zero prior_conflict_sha
#   keys even when raw conflict markers are present, causing the #200
#   rerun-safety guard to silently fail open.
#
#   Fix (issue #222, two parts):
#     A. Writer: atomic tmp+rename (`conflicts_path.tmp.$$` → rename).
#     B. Parser: after the loop, if file is non-empty AND contains raw
#        "classified": "conflict" markers AND extracted zero keys →
#        exit 1 with repair-steps message.
#
# Cases:
#   #222-static-A  — upgrade.sh contains the ERROR exit-1 guard.
#   #222-static-B  — upgrade.sh uses atomic tmp+rename for the writer.
#   #222-static-C  — atomic mv of conflicts_path.tmp.$$ present.
#   #222-static-D  — guard checks prior_conflict_sha count == 0.
#   #222-unit-A    — well-formed file with a conflict entry → guard does
#                    NOT fire (exit 0, no ERROR message).
#   #222-unit-B    — truncated file: raw "classified": "conflict" present but
#                    "path" is on a separate line so sed yields nothing →
#                    guard fires (exit 1, ERROR message emitted).
#   #222-unit-C    — empty file → guard does NOT fire (exit 0).
#   #222-unit-D    — non-empty file with only accepted_local entries and zero
#                    conflict markers → guard does NOT fire (false-positive
#                    protection per the 3-condition gate requirement).
#
# Why inline unit tests instead of end-to-end invocation of upgrade.sh:
#   upgrade.sh requires a live upstream clone (network) to proceed past the
#   pre-bootstrap block to the parser at ~line 1592.  The parser logic is
#   self-contained and short enough to replicate directly; this keeps the
#   test offline and fast while still exercising the exact condition branches
#   added by the fix.  The static checks confirm the guard code is actually
#   present in upgrade.sh.

set -u

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
upgrade="$repo_root/scripts/upgrade.sh"

tmp="$(mktemp -d -t upgrade-issue-222-XXXXXX)"
keep=0
[[ "${1:-}" == "--keep" ]] && keep=1
trap 'if [[ $keep -eq 0 ]]; then rm -rf "$tmp"; else echo "(kept $tmp for inspection)" >&2; fi' EXIT

fail=0
pass=0

check() {
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "  PASS: $label"
    pass=$((pass + 1))
  else
    echo "  FAIL: $label" >&2
    fail=$((fail + 1))
  fi
}

# ---------------------------------------------------------------------------
# Static checks (issue #222 implementation presence)
# ---------------------------------------------------------------------------
echo "-- #222 static checks --"

check "#222-static-A: ERROR exit-1 guard for issue #222 present in upgrade.sh" \
  grep -q "ERROR: issue #222" "$upgrade"

check "#222-static-B: writer uses atomic tmp file (conflicts_path.tmp.\$\$)" \
  grep -q 'conflicts_path\.tmp\.\$\$' "$upgrade"

check "#222-static-C: atomic mv of conflicts_path.tmp.\$\$ into conflicts_path" \
  grep -qP 'mv "\$conflicts_path\.tmp\.\$\$" "\$conflicts_path"' "$upgrade"

check "#222-static-D: guard checks prior_conflict_sha count == 0" \
  grep -q 'prior_conflict_sha\[@\]\}' "$upgrade"

# ---------------------------------------------------------------------------
# Inline unit tests: replicate the exact guard logic from upgrade.sh so we
# can exercise the condition branches without network access.
#
# The guard (as implemented in upgrade.sh after the fix):
#
#   if [[ ${#prior_conflict_sha[@]} -eq 0 ]] \
#       && [[ -s "$path" ]] \
#       && grep -q '"classified": "conflict"' "$path"; then
#     echo "ERROR: issue #222: ..." >&2
#     ...
#     exit 1
#   fi
#
# run_guard returns the exit code and writes combined stdout+stderr to a log.
# ---------------------------------------------------------------------------

run_guard() {
  local conflicts_file="$1"
  local log="$2"
  local rc=0
  bash -c '
    set -u
    conflicts_file="$1"
    declare -A prior_conflict_sha=()
    if [[ -f "$conflicts_file" ]]; then
      while IFS= read -r _c_line; do
        [[ "$_c_line" == *'"'"'"classified": "conflict"'"'"'* ]] || continue
        _c_path="$(printf "%s" "$_c_line" | sed -n '"'"'s/.*"path": "\([^"]*\)".*/\1/p'"'"')"
        _c_proj="$(printf "%s" "$_c_line" | sed -n '"'"'s/.*"project_sha": "\([^"]*\)".*/\1/p'"'"')"
        [[ -n "$_c_path" ]] || continue
        prior_conflict_sha["$_c_path"]="$_c_proj"
      done < "$conflicts_file"
      if [[ ${#prior_conflict_sha[@]} -eq 0 ]] \
          && [[ -s "$conflicts_file" ]] \
          && grep -q '"'"'"classified": "conflict"'"'"' "$conflicts_file"; then
        echo "ERROR: issue #222: $conflicts_file is non-empty and contains conflict markers but the line-parser extracted zero prior_conflict_sha keys — the file is likely malformed or truncated mid-write." >&2
        echo "       The #200 rerun-safety guard cannot fire for the affected entries." >&2
        echo "       Repair steps:" >&2
        echo "         1. Inspect $conflicts_file for truncation or corruption." >&2
        echo "         2. If the tracked conflicts are gone (hand-merged or abandoned), delete the file and re-run." >&2
        echo "         3. If the file is repairable, restore valid JSON and re-run." >&2
        echo "         4. Run scripts/upgrade.sh --resolve after any hand-merges to clear resolved entries." >&2
        exit 1
      fi
    fi
  ' _ "$conflicts_file" > "$log" 2>&1 || rc=$?
  echo "$rc"
}

# ---------------------------------------------------------------------------
# Case #222-unit-A: well-formed file with a conflict entry → guard must NOT
# fire (exit 0, no ERROR).
# ---------------------------------------------------------------------------
echo ""
echo "-- #222-unit-A: well-formed conflict entry → no hard-fail --"

cat > "$tmp/well-formed.json" << 'EOF'
{
  "schema": 1,
  "generated": "2026-01-01T00:00:00Z",
  "template_version": "v1.0.0-rc13",
  "entries": [
    {"path": "CLAUDE.md", "classified": "conflict", "baseline_sha": "aaaa", "upstream_sha": "bbbb", "project_sha": "cccc"}
  ]
}
EOF

rc_a="$(run_guard "$tmp/well-formed.json" "$tmp/case-a.log")"
check "#222-unit-A: exit 0 for well-formed file" \
  bash -c '[ '"$rc_a"' -eq 0 ]'
check "#222-unit-A: no ERROR message for well-formed file" \
  bash -c '! grep -q "ERROR: issue #222" '"$tmp/case-a.log"

# ---------------------------------------------------------------------------
# Case #222-unit-B: truncated file — "classified": "conflict" present in raw
# text but "path" is on a separate line, so sed yields "" for _c_path and the
# key is never stored.  Guard must fire: exit 1 + ERROR message.
# ---------------------------------------------------------------------------
echo ""
echo "-- #222-unit-B: truncated file with raw conflict marker, no extractable path → hard-fail --"

cat > "$tmp/truncated.json" << 'EOF'
{
  "schema": 1,
  "generated": "2026-01-01T00:00:00Z",
  "template_version": "v1.0.0-rc13",
  "entries": [
    {"path":
      "CLAUDE.md",
      "classified": "conflict",
      "baseline_sha": "aaaa"
EOF
# File ends here — truncated mid-entry.

rc_b="$(run_guard "$tmp/truncated.json" "$tmp/case-b.log")"
check "#222-unit-B: exit 1 for truncated file with conflict marker" \
  bash -c '[ '"$rc_b"' -eq 1 ]'
check "#222-unit-B: ERROR message emitted naming the file" \
  bash -c 'grep -q "ERROR: issue #222" '"$tmp/case-b.log"
check "#222-unit-B: ERROR message mentions #200 rerun-safety guard" \
  bash -c 'grep -q "#200" '"$tmp/case-b.log"
check "#222-unit-B: repair steps included in output" \
  bash -c 'grep -q "Repair steps" '"$tmp/case-b.log"

# ---------------------------------------------------------------------------
# Case #222-unit-C: empty file → guard must NOT fire (exit 0).
# ---------------------------------------------------------------------------
echo ""
echo "-- #222-unit-C: empty .template-conflicts.json → no hard-fail --"

: > "$tmp/empty.json"
rc_c="$(run_guard "$tmp/empty.json" "$tmp/case-c.log")"
check "#222-unit-C: exit 0 for empty file" \
  bash -c '[ '"$rc_c"' -eq 0 ]'
check "#222-unit-C: no ERROR message for empty file" \
  bash -c '! grep -q "ERROR: issue #222" '"$tmp/case-c.log"

# ---------------------------------------------------------------------------
# Case #222-unit-D: non-empty file with only accepted_local entries, zero
# conflict markers → guard must NOT fire (false-positive protection).
# ---------------------------------------------------------------------------
echo ""
echo "-- #222-unit-D: accepted_local-only file → no hard-fail (false-positive guard) --"

cat > "$tmp/accepted-local.json" << 'EOF'
{
  "schema": 1,
  "generated": "2026-01-01T00:00:00Z",
  "template_version": "v1.0.0-rc13",
  "entries": [
    {"path": "CLAUDE.md", "classified": "accepted_local", "baseline_sha": "aaaa", "upstream_sha": "bbbb", "project_sha": "cccc"},
    {"path": "docs/foo.md", "classified": "local_only_kept", "baseline_sha": "", "upstream_sha": "", "project_sha": "dddd"}
  ]
}
EOF

rc_d="$(run_guard "$tmp/accepted-local.json" "$tmp/case-d.log")"
check "#222-unit-D: exit 0 for accepted_local-only file" \
  bash -c '[ '"$rc_d"' -eq 0 ]'
check "#222-unit-D: no ERROR message for accepted_local-only file" \
  bash -c '! grep -q "ERROR: issue #222" '"$tmp/case-d.log"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "PASS: $pass"
echo "FAIL: $fail"
if [[ $fail -gt 0 ]]; then
  exit 1
fi
exit 0
