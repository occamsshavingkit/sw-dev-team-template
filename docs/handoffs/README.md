# docs/handoffs/

Durable handoff contracts for bounded specialist sessions. One JSON file
per task (`<task_id>.json`), shaped per `schemas/handoff.schema.json` and
the contract spec in `docs/v1.1-handoff-contracts.md`.

## File types in this directory

| Pattern | Tracked | Purpose |
|---|---|---|
| `<task_id>.json` | Yes (git-tracked) | Durable contract — `status`, `mode`, `allowed_paths`, `hard_rule_traces`, `acceptance_criteria`, `verification`. Static after creation. |
| `<task_id>.activity.jsonl` | No (gitignored) | Runtime telemetry — one JSON object per line, appended by `handoff-record-activity.py` on every PreToolUse/PostToolUse boundary. Ephemeral to the local session. |

## Separation of concerns

The JSON contract file is static after the handoff is created. It holds the
durable fields that the gate hooks, `upgrade.sh --verify`, and the bounded-
Codex authorization path all depend on. Do not append telemetry to it.

The `*.activity.jsonl` sidecar holds runtime telemetry for the same task. It
is gitignored and local-only — it does not appear in `git status`, is not
covered by `TEMPLATE_MANIFEST.lock`, and is not replicated to other machines.
It exists for local debugging and observability only. If you need to share
session telemetry, export the sidecar separately; do not commit it.

This split was introduced by FW-ADR-0023 (D2 Option S: activity sidecar).
Prior to that release, the `"activity"` array lived inside the handoff JSON
and was excluded from manifest hashing via `manifest_file_sha_normalized`
in `scripts/lib/manifest.sh`.

## Active handoff pointer

`.devteam/active-handoff.json` (project root, if present) names the
`task_id` of the currently active handoff. Hooks read this pointer to
locate the relevant `docs/handoffs/<task_id>.json` without scanning the
directory.
