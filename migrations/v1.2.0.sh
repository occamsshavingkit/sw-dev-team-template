#!/usr/bin/env bash
#
# migrations/v1.2.0.sh — handoff activity-array sidecar migration
#   (fw-adr-0023 D2 Option S, schema v1.1.0)
#
# Walks every docs/handoffs/*.json file in the project:
#   1. If the file carries a non-empty top-level "activity" array, exports
#      the entries to a sidecar docs/handoffs/<task_id>.activity.jsonl
#      (one JSON object per line), then removes the "activity" key from
#      the JSON file. Data moves; nothing is discarded.
#   2. If the file carries an empty "activity" array (or no "activity"
#      key at all), the "activity" key is removed (or left absent) and
#      the sidecar is not created.
#
# The migration is idempotent: re-running it on an already-migrated file
# (no "activity" key) is a no-op.
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
skipped=0
already_done=0

while IFS= read -r -d '' json_file; do
  rc=0
  python3 - "$json_file" <<'PYEOF' || rc=$?
import json, os, sys
from pathlib import Path

json_file = Path(sys.argv[1])

with json_file.open(encoding="utf-8") as f:
    doc = json.load(f)

if "activity" not in doc:
    # Already migrated or never had the key.
    print(f"  skip (no activity key): {json_file.name}", flush=True)
    sys.exit(2)

activity = doc.pop("activity")

# Export non-empty arrays to sidecar.
task_id = doc.get("task_id") or json_file.stem
sidecar = json_file.parent / f"{task_id}.activity.jsonl"

if isinstance(activity, list) and activity:
    with sidecar.open("a", encoding="utf-8") as sf:
        for entry in activity:
            sf.write(json.dumps(entry, ensure_ascii=False) + "\n")
    print(f"  migrated {len(activity)} entries -> {sidecar.name}", flush=True)
    sys.exit(0)
else:
    print(f"  removed empty activity array: {json_file.name}", flush=True)
    sys.exit(3)

PYEOF
  # rc=0: entries exported to sidecar; rc=3: empty array stripped; rc=2: already done.
  # Write the stripped JSON back for rc=0 or rc=3 (activity key present and removed).
  if [[ $rc -eq 0 || $rc -eq 3 ]]; then
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
    if [[ $rc -eq 0 ]]; then
      migrated=$((migrated + 1))
    else
      skipped=$((skipped + 1))
    fi
  else
    already_done=$((already_done + 1))
  fi
done < <(find "$HANDOFFS_DIR" -maxdepth 1 -name '*.json' -not -name '*.migration-tmp' -print0 | sort -z)

echo "  v1.2.0 activity-sidecar migration: migrated=$migrated empty-stripped=$skipped already-done=$already_done"
