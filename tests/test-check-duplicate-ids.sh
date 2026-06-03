#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# Self-test for scripts/check-duplicate-ids.sh (issue #294).
#
# Builds minimal fixture trees under a temp directory, points PROJECT_ROOT at
# them, and asserts:
#   - Clean tree  → exit 0
#   - Duplicate ADR IDs → exit 1
#   - Duplicate spec IDs → exit 1
#   - Duplicate open-question IDs → exit 1
#   - Duplicate decision IDs → exit 1
#
# Each fixture is isolated so failures are pinpointed.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/check-duplicate-ids.sh"

pass=0
fail=0
failures=()

# ---------------------------------------------------------------------------
# Helper
# ---------------------------------------------------------------------------
run_case() {
    local name="$1"
    local root="$2"
    local expect_exit="$3"  # 0 or 1

    local actual_exit=0
    PROJECT_ROOT="$root" "$SCRIPT" >/dev/null 2>&1 || actual_exit=$?

    if [[ "$actual_exit" -eq "$expect_exit" ]]; then
        pass=$((pass + 1))
        echo "PASS  $name"
    else
        fail=$((fail + 1))
        failures+=("$name (expected exit=$expect_exit got=$actual_exit)")
        echo "FAIL  $name (expected exit=$expect_exit got=$actual_exit)"
    fi
}

# ---------------------------------------------------------------------------
# Fixture builder helpers
# ---------------------------------------------------------------------------

make_clean_root() {
    local root
    root="$(mktemp -d)"
    # ADR: two distinct numbers
    mkdir -p "$root/docs/adr"
    touch "$root/docs/adr/fw-adr-0001-foo.md"
    touch "$root/docs/adr/fw-adr-0002-bar.md"
    # Spec: two distinct numbers
    mkdir -p "$root/specs/001-alpha" "$root/specs/002-beta"
    # Open questions: two distinct Q-IDs
    mkdir -p "$root/docs"
    printf '| Q-0001 | open | question one | — | — | open | — |\n' \
        > "$root/docs/OPEN_QUESTIONS.md"
    printf '| Q-0002 | open | question two | — | — | open | — |\n' \
        >> "$root/docs/OPEN_QUESTIONS.md"
    # Decisions: two distinct D-IDs
    printf '## D-0001 — 2026-01-01 — first\n\n## D-0002 — 2026-01-02 — second\n' \
        > "$root/docs/DECISIONS.md"
    echo "$root"
}

make_dup_adr_root() {
    local root
    root="$(mktemp -d)"
    mkdir -p "$root/docs/adr"
    touch "$root/docs/adr/fw-adr-0001-foo.md"
    touch "$root/docs/adr/fw-adr-0001-bar.md"   # same number, different slug
    mkdir -p "$root/specs"
    mkdir -p "$root/docs"
    touch "$root/docs/OPEN_QUESTIONS.md"
    touch "$root/docs/DECISIONS.md"
    echo "$root"
}

make_dup_spec_root() {
    local root
    root="$(mktemp -d)"
    mkdir -p "$root/docs/adr"
    mkdir -p "$root/specs/003-one" "$root/specs/003-two"  # same number, different slugs
    mkdir -p "$root/docs"
    touch "$root/docs/OPEN_QUESTIONS.md"
    touch "$root/docs/DECISIONS.md"
    echo "$root"
}

make_dup_oq_root() {
    local root
    root="$(mktemp -d)"
    mkdir -p "$root/docs/adr" "$root/specs" "$root/docs"
    # Q-0005 appears twice
    printf '| Q-0005 | open | first  | — | — | open | — |\n' \
        > "$root/docs/OPEN_QUESTIONS.md"
    printf '| Q-0005 | open | second | — | — | open | — |\n' \
        >> "$root/docs/OPEN_QUESTIONS.md"
    touch "$root/docs/DECISIONS.md"
    echo "$root"
}

make_dup_decision_root() {
    local root
    root="$(mktemp -d)"
    mkdir -p "$root/docs/adr" "$root/specs" "$root/docs"
    touch "$root/docs/OPEN_QUESTIONS.md"
    # D-0003 heading appears twice
    printf '## D-0003 — 2026-01-01 — first\n\n## D-0003 — 2026-01-02 — second\n' \
        > "$root/docs/DECISIONS.md"
    echo "$root"
}

# ---------------------------------------------------------------------------
# Test cases
# ---------------------------------------------------------------------------

clean_root="$(make_clean_root)"
run_case "clean tree exits 0" "$clean_root" 0

dup_adr_root="$(make_dup_adr_root)"
run_case "duplicate ADR number exits 1" "$dup_adr_root" 1

dup_spec_root="$(make_dup_spec_root)"
run_case "duplicate spec number exits 1" "$dup_spec_root" 1

dup_oq_root="$(make_dup_oq_root)"
run_case "duplicate Q-NNNN exits 1" "$dup_oq_root" 1

dup_dec_root="$(make_dup_decision_root)"
run_case "duplicate D-NNNN exits 1" "$dup_dec_root" 1

# ---------------------------------------------------------------------------
# Cleanup
# ---------------------------------------------------------------------------
rm -rf "$clean_root" "$dup_adr_root" "$dup_spec_root" "$dup_oq_root" "$dup_dec_root"

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------
echo
echo "check-duplicate-ids self-test: $pass passed, $fail failed."
if [[ "$fail" -gt 0 ]]; then
    for f in "${failures[@]}"; do
        echo "  - $f"
    done
    exit 1
fi
exit 0
