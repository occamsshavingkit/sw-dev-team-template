#!/usr/bin/env bash
#
# migrations/1.1.0.sh — CLAUDE.md section extraction (issue #120).
#
# v1.1.0 reorganizes CLAUDE.md by extracting non-load-bearing sections
# into dedicated docs/ files. The change is reorganization-only —
# extracted content is byte-equivalent to its CLAUDE.md origin.
#
# New files added by upgrade.sh's file-sync step (no migration action
# required for the additions):
#   - docs/FIRST_ACTIONS.md
#   - docs/TEMPLATE_UPGRADE.md
#   - docs/MEMORY_POLICY.md
#   - docs/IP_POLICY.md
#
# Modified-in-place by upgrade.sh:
#   - CLAUDE.md (extracted sections replaced with pointer block)
#   - docs/sme/CONTRACT.md (creation procedure folded in)
#   - docs/framework-project-boundary.md (final-checklist phrasing)
#   - AGENTS.md (reading-order + framework-managed-files list)
#   - docs/INDEX-FRAMEWORK.md (four new docs indexed)
#
# Inbound link redirects in framework-managed files (handled by
# upgrade.sh file-sync; no action here).
#
# Env vars from scripts/upgrade.sh:
#   PROJECT_ROOT   — absolute path to the downstream project root
#   OLD_VERSION    — version the project is coming from
#   NEW_VERSION    — version the project is going to
#   TARGET_VERSION — this migration's attached version
#   WORKDIR_NEW    — clone of upstream at NEW_VERSION
#   WORKDIR_OLD    — clone of upstream at OLD_VERSION (optional)

set -euo pipefail

: "${PROJECT_ROOT:?PROJECT_ROOT is required}"

echo "  (no migration actions required for v1.1.0; reorganization-only — file-sync handles adds and rewrites)"
