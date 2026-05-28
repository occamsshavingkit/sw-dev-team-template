#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# tests/release-gate/mutations/with-accepted-local.mutation.sh —
# `with-accepted-local` variant (spec 008 FR-002,
# contracts/variant-catalog.md § with-accepted-local).
#
# Mutation:
#   - Write a deterministic .template-conflicts.json carrying one
#     `accepted_local` and one `local_only_kept` entry. This is the
#     "directly-write" path per the variant-catalog contract; faster
#     than replay and deterministic by construction.
#
# Catches: rc11/rc12 issue family — accepted-local pruning, --resolve
# regressions, accumulated-state handling.
#
# Contract:
#   - Reads $PWD as a scaffolded fixture tree.
#   - Reads $SWDT_MUTATION_SOURCE_RC for the source tag.
#   - Deterministic: same source-rc + variant => same output bytes.
#     The `generated` timestamp is pinned to a fixed marker (not
#     wall-clock) to keep snapshots byte-stable.
#   - Idempotent: re-running on an already-mutated tree overwrites
#     to the same canonical bytes.
#   - POSIX sh; no external network.

set -eu

: "${SWDT_MUTATION_SOURCE_RC:?with-accepted-local.mutation.sh requires SWDT_MUTATION_SOURCE_RC}"

# Synthetic SHAs — 40-hex strings derived from the source-rc name +
# variant + path. The mutation does not run a real prior upgrade; the
# entry exists to exercise the candidate's --resolve / pruning machinery
# (which keys on the `classified` field, not on SHA validity).
#
# We use a fixed-format synthetic SHA so re-running produces byte
# identical output, while still being deterministic per-variant.
synth_sha() {
    # $1: scope label. Produces a stable 40-hex string from the inputs.
    printf '%s:%s:%s' "$SWDT_MUTATION_SOURCE_RC" "with-accepted-local" "$1" \
        | sha1sum 2>/dev/null \
        | awk '{print $1}'
}

accepted_path=".claude/agents/researcher.md"
kept_path=".claude/agents/architect.md"

baseline_a=$(synth_sha "accepted-baseline")
upstream_a=$(synth_sha "accepted-upstream")
project_a=$(synth_sha "accepted-project")
baseline_k=$(synth_sha "kept-baseline")
upstream_k=$(synth_sha "kept-upstream")
project_k=$(synth_sha "kept-project")

# Fixed `generated` marker keeps the file byte-stable across runs.
generated="2026-05-15T00:00:00Z"

cat > .template-conflicts.json <<EOF
{
  "schema": 1,
  "generated": "$generated",
  "template_version": "$SWDT_MUTATION_SOURCE_RC",
  "entries": [
    {"path": "$accepted_path", "classified": "accepted_local", "baseline_sha": "$baseline_a", "upstream_sha": "$upstream_a", "project_sha": "$project_a"},
    {"path": "$kept_path", "classified": "local_only_kept", "baseline_sha": "$baseline_k", "upstream_sha": "$upstream_k", "project_sha": "$project_k"}
  ]
}
EOF

exit 0
