#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# tests/release-gate/mutations/clean.mutation.sh — `clean` variant
# (spec 008 FR-002, contracts/variant-catalog.md).
#
# Reads cwd as a freshly-scaffolded source tree. The `clean` variant
# applies no mutations: the tree stays exactly as scaffold.sh produced
# it. Provided as a script (rather than absence) so the generator
# treats every variant uniformly.
#
# Contract:
#   - Reads $PWD as a scaffolded fixture tree.
#   - Reads $SWDT_MUTATION_SOURCE_RC for the source tag (informational).
#   - Deterministic: same source-rc + variant => same output bytes.
#   - POSIX sh; no external network.

set -eu

: "${SWDT_MUTATION_SOURCE_RC:?clean.mutation.sh requires SWDT_MUTATION_SOURCE_RC}"

# No-op variant. The scaffolded tree is the fixture.
exit 0
