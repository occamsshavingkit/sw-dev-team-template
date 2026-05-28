#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# tests/upgrade/test-cluster-c-fixes.sh — cluster-C coverage for four
# upgrade.sh follow-up issues.
#
# Cases:
#   #169 — post-upgrade advisory does not reference a non-existent migration;
#           when a schema-touching migration exists in the clone, its name
#           appears in the advisory fallback text.
#   #190 — untagged-target full-walk comment cites migrations/README.md and
#           docs/TEMPLATE_UPGRADE.md (static code check).
#   #171 — --resolve on a path pinned in .template-customizations drops it
#           from .template-conflicts.json (does NOT keep it as conflict).
#   #163 — v0.14.0 migration writes pre-bootstrapped paths to
#           .template-customizations; tested via the migration script
#           directly against a minimal fixture.

set -u

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
upgrade="$repo_root/scripts/upgrade.sh"
migration_v0_14="$repo_root/migrations/v0.14.0.sh"

tmp="$(mktemp -d -t cluster-c-XXXXXX)"
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

run_capture() {
  local log="$1"; shift
  local rc=0
  "$@" > "$log" 2>&1 || rc=$?
  echo "$rc"
}

# ---------------------------------------------------------------------------
# #190 — static code check: untagged-target comment cites the contract
# ---------------------------------------------------------------------------
echo "-- #190: untagged-target full-walk cites idempotency contract --"
check "#190: upgrade.sh cites migrations/README.md at full-walk site" \
  grep -q "migrations/README.md" "$upgrade"
check "#190: upgrade.sh cites docs/TEMPLATE_UPGRADE.md at full-walk site" \
  grep -q "docs/TEMPLATE_UPGRADE.md" "$upgrade"
check "#190: upgrade.sh cites Issue #190 at full-walk site" \
  grep -q "Issue #190" "$upgrade"

# ---------------------------------------------------------------------------
# #169 — advisory does not reference a version-specific migration when it
#        doesn't exist; when a schema-touching migration exists, it's named.
#        We test the advisory code path using a fixture that triggers
#        lint-agent-contracts.sh to fail (or we verify the dynamic-discovery
#        logic is present in the source).
# ---------------------------------------------------------------------------
echo ""
echo "-- #169: advisory migration-pointer logic --"
# Static check: the new fallback branch names $schema_migration rather than
# always emitting the literal "migrations/<target>.sh" string.
check "#169: advisory code references schema_migration variable" \
  grep -q 'schema_migration' "$upgrade"
check "#169: advisory scans for agent-schema markers (lint-agent-contracts)" \
  grep -q 'lint-agent-contracts' "$upgrade"
check "#169: advisory no longer unconditionally references non-existent migration" \
  bash -c "! grep -q 'migrations/v1.0.0-rc11.sh' '$upgrade'"

# ---------------------------------------------------------------------------
# #171 — --resolve drops conflict entries whose path is pinned in
#         .template-customizations.
# ---------------------------------------------------------------------------
echo ""
echo "-- #171: --resolve respects .template-customizations --"

make_resolve_fixture() {
  local dir="$1"
  rm -rf "$dir"
  mkdir -p "$dir"
  (
    cd "$dir"
    git init -b main -q
    git config user.email cluster-c-test@example.invalid
    git config user.name "Cluster-C Test"
    # Minimal TEMPLATE_VERSION so --resolve doesn't fail early.
    printf 'v0.14.0\ndeadbeef\n2026-01-01\n' > TEMPLATE_VERSION
    git add TEMPLATE_VERSION
    git commit -q -m "fixture init"
  )
}

fix171="$tmp/resolve-pinned"
make_resolve_fixture "$fix171"

# Write a fake .template-conflicts.json with one "conflict" entry.
target_path="scripts/upgrade.sh"
cat > "$fix171/.template-conflicts.json" << 'EOF'
{
  "schema": 1,
  "generated": "2026-01-01T00:00:00Z",
  "template_version": "v0.14.0",
  "entries": [
    {"path": "scripts/upgrade.sh", "classified": "conflict", "baseline_sha": "aaaa", "upstream_sha": "bbbb", "project_sha": "cccc"}
  ]
}
EOF

# Without a .template-customizations entry the conflict stays.
rc_no_pin=$(run_capture "$tmp/resolve-no-pin.log" \
            bash -c "cd '$fix171' && bash '$upgrade' --resolve")
check "#171: without pin, conflict entry is kept (1 still unresolved)" \
  bash -c "grep -q '1 still unresolved' '$tmp/resolve-no-pin.log'"
check "#171: without pin, .template-conflicts.json still exists" \
  bash -c "test -f '$fix171/.template-conflicts.json'"

# Restore conflicts.json (--resolve rewrites it).
cat > "$fix171/.template-conflicts.json" << 'EOF'
{
  "schema": 1,
  "generated": "2026-01-01T00:00:00Z",
  "template_version": "v0.14.0",
  "entries": [
    {"path": "scripts/upgrade.sh", "classified": "conflict", "baseline_sha": "aaaa", "upstream_sha": "bbbb", "project_sha": "cccc"}
  ]
}
EOF

# Now add the path to .template-customizations.
echo "scripts/upgrade.sh  # pinned locally" > "$fix171/.template-customizations"

rc_pinned=$(run_capture "$tmp/resolve-pinned.log" \
            bash -c "cd '$fix171' && bash '$upgrade' --resolve")
check "#171: with pin, --resolve exits 0" \
  bash -c "[ '$rc_pinned' = '0' ]"
check "#171: with pin, pinned conflict entry is removed (not kept unresolved)" \
  bash -c "! grep -q '1 still unresolved' '$tmp/resolve-pinned.log'"
check "#171: with pin, .template-conflicts.json is removed (all conflicts cleared)" \
  bash -c "! test -f '$fix171/.template-conflicts.json'"

# ---------------------------------------------------------------------------
# #163 — v0.14.0 migration writes pre-bootstrapped paths to
#         .template-customizations.
# ---------------------------------------------------------------------------
echo ""
echo "-- #163: v0.14.0 migration marks pre-bootstrapped paths --"

fix163="$tmp/migration-v0-14-marker"
rm -rf "$fix163"
mkdir -p "$fix163/scripts/lib" "$fix163/docs/pm"

(
  cd "$fix163"
  git init -b main -q
  git config user.email cluster-c-test@example.invalid
  git config user.name "Cluster-C Test"
  printf 'v0.16.0\ndeadbeef\n2026-01-01\n' > TEMPLATE_VERSION
  # Seed a scripts/upgrade.sh that differs from "upstream" (simulates v0.16.0 version).
  mkdir -p scripts
  echo "# v0.16.0 upgrade.sh" > scripts/upgrade.sh
  chmod +x scripts/upgrade.sh
  touch docs/pm/pre-release-gate-overrides.md
  git add .
  git commit -q -m "fixture init"
)

# Build a minimal WORKDIR_NEW with a different scripts/upgrade.sh (candidate).
workdir_new="$tmp/workdir-new"
mkdir -p "$workdir_new/scripts/lib"
echo "# candidate upgrade.sh" > "$workdir_new/scripts/upgrade.sh"
chmod +x "$workdir_new/scripts/upgrade.sh"
echo "# candidate lib" > "$workdir_new/scripts/lib/manifest.sh"

# Build WORKDIR_OLD (v0.16.0 baseline).
workdir_old="$tmp/workdir-old"
mkdir -p "$workdir_old/scripts"
echo "# v0.16.0 upgrade.sh" > "$workdir_old/scripts/upgrade.sh"

# Run the migration. It should install the candidate upgrade.sh and mark it.
rc_mig=$(run_capture "$tmp/migration-v0-14.log" \
         bash -c "
           export PROJECT_ROOT='$fix163'
           export WORKDIR_NEW='$workdir_new'
           export WORKDIR_OLD='$workdir_old'
           export OLD_VERSION='v0.16.0'
           export NEW_VERSION='v1.0.0-rc14'
           export TARGET_VERSION='v0.14.0'
           bash '$migration_v0_14'
         ")
check "#163: migration exits 0" \
  bash -c "[ '$rc_mig' = '0' ]"
check "#163: migration creates/updates .template-customizations" \
  bash -c "test -f '$fix163/.template-customizations'"
check "#163: scripts/upgrade.sh is listed in .template-customizations" \
  bash -c "grep -qE '^scripts/upgrade\.sh' '$fix163/.template-customizations'"
check "#163: .template-customizations entry mentions issue #163" \
  bash -c "grep -q 'issue #163' '$fix163/.template-customizations'"

# Idempotency: run migration again — no duplicate entries.
rc_mig2=$(run_capture "$tmp/migration-v0-14-idem.log" \
          bash -c "
            export PROJECT_ROOT='$fix163'
            export WORKDIR_NEW='$workdir_new'
            export WORKDIR_OLD='$workdir_old'
            export OLD_VERSION='v0.16.0'
            export NEW_VERSION='v1.0.0-rc14'
            export TARGET_VERSION='v0.14.0'
            bash '$migration_v0_14'
          ")
count=$(grep -cE '^scripts/upgrade\.sh' "$fix163/.template-customizations" 2>/dev/null || echo 0)
check "#163: idempotent — scripts/upgrade.sh appears exactly once in .template-customizations" \
  bash -c "[ '$count' = '1' ]"

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
