<!--
SPDX-License-Identifier: MIT
Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
-->

# docs/pm/ — Project Management artifacts

This directory holds PM artifacts that accumulate over the life of a project:
schedule evidence, risk register, lessons-learned log, fallback log, and
session-specific review reports.

## `fallback-log.jsonl` — create-on-first-write contract

`docs/pm/fallback-log.jsonl` is **not seeded at scaffold time**. The file is
created by `scripts/log-fallback.sh` on the first fallback event. A newly
scaffolded project that has never triggered a model fallback will not have
this file. That is expected behavior, not a missing file.

Consequences for downstream operators:

- **Absence means no events have occurred.** Do not treat a missing
  `fallback-log.jsonl` as a broken installation. If you expect events but
  the file is absent, confirm that `scripts/log-fallback.sh` is being
  invoked and that it completed without error.
- **The file appears lazily.** After the first fallback event the file will
  be present and `grep`/`jq` queries against it will work normally.
- **Do not create the file by hand** unless you have a real event to record.
  An empty file or a file with a malformed record will cause
  `scripts/lint-agent-model-routing.sh` to report a parse error.

### Log format

Each line is a JSON object with six required fields (FR-020):

| Field | Type | Description |
|---|---|---|
| `agent` | string | Role slug (e.g., `software-engineer`) |
| `requested_model` | string | Model ID the routing table selected |
| `actual_model` | string | Model ID the provider actually used |
| `fallback_reason` | string | One of `credit_exhausted`, `provider_unavailable_5xx`, `provider_timeout`, `provider_rate_limit`; append `; downgraded_one_tier` when no same-class peer was available |
| `timestamp` | string | ISO 8601 UTC |
| `task_id` | string | Task identifier from the current dispatch |

### Recording an event

```sh
scripts/log-fallback.sh \
    --agent software-engineer \
    --requested-model claude-sonnet-4-5 \
    --actual-model claude-haiku-3-5 \
    --reason credit_exhausted \
    --task-id T042
```

Pass `--downgraded-one-tier` when the substitute is one class below the
requested class (adds the suffix to `fallback_reason` automatically).

See `scripts/log-fallback.sh --help` for the full flag set including
`--timestamp` (override) and `--log-path` (redirect to a non-default path).

## Other artifacts in this directory

| File | Purpose |
|---|---|
| `LESSONS.md` | Append-only post-milestone observations (OBS-* entries). |
| `RISKS.md` | Risk register. |
| `SCHEDULE-EVIDENCE.md` | Milestone acceptance evidence log. |
| `SCHEDULE-ARCHIVE.md` | Superseded schedule snapshots. |
| `dispatch-log.md` | Per-PR dispatch and close record for multi-PR burndowns. |
| `pre-release-gate-overrides.md` | Bypass audit log for `scripts/pre-release-gate.sh`. |
