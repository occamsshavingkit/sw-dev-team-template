#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# tests/release-gate/mutations/with-customizations.mutation.sh —
# `with-customizations` variant (spec 008 FR-002,
# contracts/variant-catalog.md § with-customizations).
#
# Mutation:
#   - Append a single fixed marker line to .claude/agents/researcher.md.
#   - Append the file's relative path to .template-customizations
#     under a fixture-marker comment.
#
# Catches: the rc8->rc9 issue family — upgrade machinery overwriting
# customised files because .template-customizations parsing regressed
# or the upgrade path stopped honouring the manifest.
#
# Contract:
#   - Reads $PWD as a scaffolded fixture tree.
#   - Reads $SWDT_MUTATION_SOURCE_RC for the source tag (informational).
#   - Deterministic: same source-rc + variant => same output bytes.
#   - Idempotent: re-running on an already-mutated tree must be a no-op.
#   - POSIX sh; no external network.

set -eu

: "${SWDT_MUTATION_SOURCE_RC:?with-customizations.mutation.sh requires SWDT_MUTATION_SOURCE_RC}"

target_file=".claude/agents/researcher.md"
marker_line="# fixture-customization-marker (spec-008 with-customizations)"
customizations_marker="# --- fixture mutations (spec-008 with-customizations) ---"

if [ ! -f "$target_file" ]; then
    echo "with-customizations.mutation.sh: $target_file missing in scaffolded tree" >&2
    exit 1
fi

# Idempotent append: only add marker if not already present.
if ! grep -qxF "$marker_line" "$target_file"; then
    printf '\n%s\n' "$marker_line" >> "$target_file"
fi

# Append a fixture-marker block to .template-customizations if not present.
if [ ! -f .template-customizations ]; then
    echo "with-customizations.mutation.sh: .template-customizations missing in scaffolded tree" >&2
    exit 1
fi

if ! grep -qxF "$customizations_marker" .template-customizations; then
    {
        printf '\n%s\n' "$customizations_marker"
        printf '%s\n' "$target_file"
    } >> .template-customizations
fi

exit 0
