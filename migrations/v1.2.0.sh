#!/usr/bin/env bash
#
# migrations/v1.2.0.sh — handoff activity-array sidecar migration
#   (fw-adr-0023 D2 Option S, schema v1.1.0)
#
# Walks every docs/handoffs/*.json file in the project:
#   1. If the file carries a NON-EMPTY top-level "activity" array, exports
#      the entries to a sidecar docs/handoffs/<task_id>.activity.jsonl
#      (one JSON object per line), then removes the "activity" key from
#      the JSON file. Data moves; nothing is discarded.
#   2. If the file carries an EMPTY "activity" array (or no "activity" key
#      at all), the file is left completely untouched — no rewrite, no SHA
#      change. The deprecated-but-schema-valid empty array is inert (the
#      hook now writes to the sidecar) and cosmetic removal is not worth
#      the SHA churn it causes on downstream upgrade paths.
#
# The migration is idempotent: re-running it on a file with no activity key
# (or an empty array left in place) is a no-op.
#
# Requires python3 (already required by the hook layer).
#
# Env vars from scripts/upgrade.sh:
#   PROJECT_ROOT   — absolute path to the downstream project root
#   OLD_VERSION    — version the project is coming from
#   NEW_VERSION    — version the project is going to
#   TARGET_VERSION — this migration's attached version (v1.2.0)
#   WORKDIR_NEW    — clone of upstream at NEW_VERSION
#   WORKDIR_OLD    — clone of upstream at OLD_VERSION (optional)

set -euo pipefail

: "${PROJECT_ROOT:?PROJECT_ROOT is required}"

HANDOFFS_DIR="$PROJECT_ROOT/docs/handoffs"

if [[ ! -d "$HANDOFFS_DIR" ]]; then
  echo "  v1.2.0 activity-sidecar migration: docs/handoffs/ not found — skipping"
  exit 0
fi

migrated=0
already_done=0

while IFS= read -r -d '' json_file; do
  rc=0
  python3 - "$json_file" <<'PYEOF' || rc=$?
import json, os, sys
from pathlib import Path

json_file = Path(sys.argv[1])

with json_file.open(encoding="utf-8") as f:
    doc = json.load(f)

activity = doc.get("activity")

if activity is None:
    # Already migrated or never had the key — true no-op.
    print(f"  skip (no activity key): {json_file.name}", flush=True)
    sys.exit(2)

if not (isinstance(activity, list) and activity):
    # Empty array: leave the file completely untouched (no SHA change).
    # Cosmetic removal of "activity": [] is not worth the upgrade-path
    # conflict it causes on v1.1.0→v1.3.0 downstream upgrades.
    print(f"  skip (empty activity array, file unchanged): {json_file.name}", flush=True)
    sys.exit(2)

# Non-empty array: export entries to sidecar then strip the key.
doc.pop("activity")
task_id = doc.get("task_id") or json_file.stem
sidecar = json_file.parent / f"{task_id}.activity.jsonl"

with sidecar.open("a", encoding="utf-8") as sf:
    for entry in activity:
        sf.write(json.dumps(entry, ensure_ascii=False) + "\n")
print(f"  migrated {len(activity)} entries -> {sidecar.name}", flush=True)
sys.exit(0)

PYEOF
  # rc=0: non-empty activity exported to sidecar; file must be rewritten (key stripped).
  # rc=2: no-op (absent key OR empty array) — file is left byte-identical; no rewrite.
  if [[ $rc -eq 0 ]]; then
    rc2=0
    python3 - "$json_file" <<'PYEOF' || rc2=$?
import json, os, sys
from pathlib import Path

json_file = Path(sys.argv[1])
with json_file.open(encoding="utf-8") as f:
    doc = json.load(f)
doc.pop("activity", None)

tmp = json_file.with_suffix(".json.migration-tmp")
with tmp.open("w", encoding="utf-8") as f:
    json.dump(doc, f, indent=2, ensure_ascii=False)
    f.write("\n")
os.replace(tmp, json_file)
PYEOF
    if [[ $rc2 -ne 0 ]]; then
      echo "  ERROR: failed to write stripped JSON for $json_file" >&2
      exit 1
    fi
    migrated=$((migrated + 1))
  else
    # rc=2: no-op (absent or empty activity array).
    already_done=$((already_done + 1))
  fi
done < <(find "$HANDOFFS_DIR" -maxdepth 1 -name '*.json' -not -name '*.migration-tmp' -print0 | sort -z)

echo "  v1.2.0 activity-sidecar migration: migrated=$migrated already-done-or-empty=$already_done"
