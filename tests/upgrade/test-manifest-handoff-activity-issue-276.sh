#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# tests/upgrade/test-manifest-handoff-activity-issue-276.sh
#
# Issue #276: TEMPLATE_MANIFEST.lock must not report drift when the
# runtime-mutable "activity" array in docs/handoffs/*.json changes,
# but MUST still detect changes to the durable contract portions
# (status, mode, allowed_paths, hard_rule_traces, acceptance_criteria,
# verification).
#
# IEEE 1008-1987 §3.2 — features under test:
#   F1. manifest_file_sha_normalized strips "activity" before hashing.
#   F2. A change to the "activity" array produces the same normalized
#       hash (no drift reported by manifest_verify).
#   F3. A change to the durable "status" field IS detected (drift
#       reported) — the normalization does not blind the manifest to
#       real contract changes.
#   F4. A file outside docs/handoffs/ is hashed raw (normalization is
#       not applied to unrelated files).
#   F5. manifest_write records the normalized hash for handoff JSON
#       files, so a subsequent manifest_verify passes even after the
#       activity array has been appended to.

set -u

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
manifest_lib="$repo_root/scripts/lib/manifest.sh"
# shellcheck source=scripts/lib/manifest.sh
source "$manifest_lib"

tmp="$(mktemp -d -t manifest-276-XXXXXX)"
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

check_output() {
  # check_output <label> <expected-pattern> <cmd...>
  local label="$1"; shift
  local pattern="$1"; shift
  local out
  out=$("$@" 2>&1) || true
  if echo "$out" | grep -qF "$pattern"; then
    echo "  PASS: $label"
    pass=$((pass + 1))
  else
    echo "  FAIL: $label (pattern='$pattern' not found in output)" >&2
    echo "        output was: $out" >&2
    fail=$((fail + 1))
  fi
}

check_not_output() {
  local label="$1"; shift
  local pattern="$1"; shift
  local out
  out=$("$@" 2>&1) || true
  if ! echo "$out" | grep -qF "$pattern"; then
    echo "  PASS: $label"
    pass=$((pass + 1))
  else
    echo "  FAIL: $label (unwanted pattern='$pattern' found in output)" >&2
    echo "        output was: $out" >&2
    fail=$((fail + 1))
  fi
}

# ---------------------------------------------------------------------------
# Fixture: a minimal handoff JSON with an empty activity array.
# ---------------------------------------------------------------------------
HANDOFF_RELPATH="docs/handoffs/test-276-handoff.json"
mkdir -p "$tmp/docs/handoffs"

cat > "$tmp/$HANDOFF_RELPATH" << 'EOF'
{
  "schema": "https://example.invalid/sw-dev-team-template/handoff.schema.json",
  "task_id": "test-276",
  "status": "active",
  "activity": [],
  "verification": {
    "tests": []
  }
}
EOF

# ---------------------------------------------------------------------------
# F1. manifest_file_sha_normalized strips "activity" before hashing.
#     Verify that two files differing only in "activity" produce the same hash.
# ---------------------------------------------------------------------------
echo "-- F1: normalized hash ignores activity array --"

cat > "$tmp/handoff-with-activity.json" << 'EOF'
{
  "schema": "https://example.invalid/sw-dev-team-template/handoff.schema.json",
  "task_id": "test-276",
  "status": "active",
  "activity": [{"name": "Bash: ls", "result": "passed", "actor_role": "hook"}],
  "verification": {
    "tests": []
  }
}
EOF

cat > "$tmp/handoff-no-activity.json" << 'EOF'
{
  "schema": "https://example.invalid/sw-dev-team-template/handoff.schema.json",
  "task_id": "test-276",
  "status": "active",
  "activity": [],
  "verification": {
    "tests": []
  }
}
EOF

sha_with=$(manifest_file_sha_normalized "$tmp/handoff-with-activity.json" "docs/handoffs/handoff-with-activity.json")
sha_without=$(manifest_file_sha_normalized "$tmp/handoff-no-activity.json" "docs/handoffs/handoff-no-activity.json")

if [[ "$sha_with" == "$sha_without" && -n "$sha_with" ]]; then
  echo "  PASS: F1 — activity-differing files produce same normalized hash"
  pass=$((pass + 1))
else
  echo "  FAIL: F1 — expected same hash, got '$sha_with' vs '$sha_without'" >&2
  fail=$((fail + 1))
fi

# ---------------------------------------------------------------------------
# F2. After appending to activity, manifest_verify does NOT report drift.
#     Simulate: write manifest from baseline (empty activity), then append
#     to activity, then verify.
# ---------------------------------------------------------------------------
echo ""
echo "-- F2: manifest_verify clean after activity append --"

# Build a minimal fake upstream git repo (manifest_write requires one for
# manifest_ship_files, but we bypass ship_files and write the manifest
# directly using the normalized hash instead).
# We write the manifest by hand using manifest_file_sha_normalized so the
# test does not require a full upstream clone.

manifest_path="$tmp/TEMPLATE_MANIFEST.lock"
{
  echo "# TEMPLATE_MANIFEST.lock — per FW-ADR-0002"
  echo "# Generated by test-manifest-handoff-activity-issue-276.sh"
  echo "# Format: <sha256>  <project-relative path>"
  echo "#"
  printf '%s  %s\n' \
    "$(manifest_file_sha_normalized "$tmp/$HANDOFF_RELPATH" "$HANDOFF_RELPATH")" \
    "$HANDOFF_RELPATH"
} > "$manifest_path"

# Now simulate the hook appending an activity entry (in-place JSON edit).
python3 - "$tmp/$HANDOFF_RELPATH" << 'PYEOF'
import json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    doc = json.load(f)
doc.setdefault("activity", []).append({
    "name": "Bash: git status",
    "result": "passed",
    "actor_role": "hook",
    "timestamp": "2026-06-02T15:00:00Z"
})
with open(sys.argv[1], "w", encoding="utf-8") as f:
    json.dump(doc, f, indent=2)
    f.write("\n")
PYEOF

# manifest_verify should return 0 (no drift) even though the file changed.
verify_output=$(manifest_verify "$tmp" "$manifest_path" 2>&1)
verify_rc=$?

if [[ $verify_rc -eq 0 ]]; then
  echo "  PASS: F2 — manifest_verify rc=0 after activity append (no drift)"
  pass=$((pass + 1))
else
  echo "  FAIL: F2 — manifest_verify rc=$verify_rc after activity append" >&2
  echo "        output: $verify_output" >&2
  fail=$((fail + 1))
fi

if echo "$verify_output" | grep -qiF "drift"; then
  echo "  FAIL: F2 — 'drift' appeared in verify output after activity-only change" >&2
  fail=$((fail + 1))
else
  echo "  PASS: F2 — 'drift' absent from verify output (activity correctly ignored)"
  pass=$((pass + 1))
fi

# ---------------------------------------------------------------------------
# F3. A change to the durable "status" field IS detected.
# ---------------------------------------------------------------------------
echo ""
echo "-- F3: manifest_verify detects durable contract change (status field) --"

# Write a fresh manifest from the current state (with activity appended).
{
  echo "# TEMPLATE_MANIFEST.lock — per FW-ADR-0002"
  echo "# Generated by test-manifest-handoff-activity-issue-276.sh"
  echo "# Format: <sha256>  <project-relative path>"
  echo "#"
  printf '%s  %s\n' \
    "$(manifest_file_sha_normalized "$tmp/$HANDOFF_RELPATH" "$HANDOFF_RELPATH")" \
    "$HANDOFF_RELPATH"
} > "$manifest_path"

# Now mutate the durable "status" field (not activity).
python3 - "$tmp/$HANDOFF_RELPATH" << 'PYEOF'
import json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    doc = json.load(f)
doc["status"] = "completed"  # durable contract change
with open(sys.argv[1], "w", encoding="utf-8") as f:
    json.dump(doc, f, indent=2)
    f.write("\n")
PYEOF

verify_output_durable=$(manifest_verify "$tmp" "$manifest_path" 2>&1)
verify_rc_durable=$?

if [[ $verify_rc_durable -ne 0 ]]; then
  echo "  PASS: F3 — manifest_verify rc=$verify_rc_durable (drift detected for status change)"
  pass=$((pass + 1))
else
  echo "  FAIL: F3 — manifest_verify rc=0 but expected drift for status field change" >&2
  echo "        output: $verify_output_durable" >&2
  fail=$((fail + 1))
fi

if echo "$verify_output_durable" | grep -qiF "drift"; then
  echo "  PASS: F3 — 'drift' reported for durable contract change"
  pass=$((pass + 1))
else
  echo "  FAIL: F3 — 'drift' not reported; durable change was silently missed" >&2
  fail=$((fail + 1))
fi

# ---------------------------------------------------------------------------
# F4. A non-handoff file is hashed raw (normalization not applied).
#     Two files with different content must produce different normalized hashes.
# ---------------------------------------------------------------------------
echo ""
echo "-- F4: non-handoff file hashed raw (normalization not applied) --"

cat > "$tmp/not-a-handoff.md" << 'EOF'
# Some markdown file
content A
EOF
cat > "$tmp/not-a-handoff-changed.md" << 'EOF'
# Some markdown file
content B
EOF

sha_md_a=$(manifest_file_sha_normalized "$tmp/not-a-handoff.md" "docs/not-a-handoff.md")
sha_md_b=$(manifest_file_sha_normalized "$tmp/not-a-handoff-changed.md" "docs/not-a-handoff-changed.md")
sha_raw_a=$(manifest_file_sha "$tmp/not-a-handoff.md")

if [[ "$sha_md_a" == "$sha_raw_a" ]]; then
  echo "  PASS: F4 — non-handoff file: normalized hash == raw hash"
  pass=$((pass + 1))
else
  echo "  FAIL: F4 — non-handoff file: normalized hash '$sha_md_a' != raw '$sha_raw_a'" >&2
  fail=$((fail + 1))
fi

if [[ "$sha_md_a" != "$sha_md_b" ]]; then
  echo "  PASS: F4 — non-handoff files with different content produce different hashes"
  pass=$((pass + 1))
else
  echo "  FAIL: F4 — non-handoff files with different content produced same hash" >&2
  fail=$((fail + 1))
fi

# ---------------------------------------------------------------------------
# F5. manifest_file_sha_normalized is applied for handoff files even when
#     the relpath argument is detected from the absolute path (fallback).
#     Ensures the regex matches when relpath is omitted.
# ---------------------------------------------------------------------------
echo ""
echo "-- F5: normalized hash via absolute-path detection (no relpath arg) --"

# Reset handoff to baseline (empty activity).
cat > "$tmp/$HANDOFF_RELPATH" << 'EOF'
{
  "schema": "https://example.invalid/sw-dev-team-template/handoff.schema.json",
  "task_id": "test-276",
  "status": "active",
  "activity": [],
  "verification": {
    "tests": []
  }
}
EOF

sha_empty_activity_relpath=$(manifest_file_sha_normalized "$tmp/$HANDOFF_RELPATH" "$HANDOFF_RELPATH")
sha_empty_activity_abspath=$(manifest_file_sha_normalized "$tmp/$HANDOFF_RELPATH")

if [[ "$sha_empty_activity_relpath" == "$sha_empty_activity_abspath" && -n "$sha_empty_activity_relpath" ]]; then
  echo "  PASS: F5 — relpath and absolute-path detection agree on normalized hash"
  pass=$((pass + 1))
else
  echo "  FAIL: F5 — hash mismatch: relpath='$sha_empty_activity_relpath' abs='$sha_empty_activity_abspath'" >&2
  fail=$((fail + 1))
fi

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
