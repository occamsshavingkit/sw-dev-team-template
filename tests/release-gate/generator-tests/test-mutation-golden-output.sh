#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# tests/release-gate/generator-tests/test-mutation-golden-output.sh —
# meta-test for tests/release-gate/mutations/*.mutation.sh
# (spec 008 FR-003, variant-catalog.md § Meta-tests).
#
# Asserts each mutation script:
#   (a) is idempotent — applying twice equals applying once;
#   (b) produces a known-shape output against a freshly-scaffolded tree.
#
# This protects against regressions in the mutation contract that the
# generator-idempotence test would miss (e.g., a mutation that grows a
# file on every run while the second-run diff-check still matches
# because both runs grow by the same amount per-cycle is not
# byte-stable across cycles).
#
# Strategy: build a minimal synthetic "scaffold-like" tree in a tempdir,
# apply each mutation twice, assert (a) the second run is a no-op and
# (b) the post-mutation tree carries the expected markers.

set -eu

repo_root="$(cd "$(dirname "$0")/../../.." && pwd)"
mutations_dir="$repo_root/tests/release-gate/mutations"

rc=0
fail() {
    echo "  FAIL: $*" >&2
    rc=1
}

# Build a synthetic scaffolded tree (minimum surface the mutations
# touch: .claude/agents/researcher.md, .claude/agents/architect.md,
# .template-customizations).
build_synthetic_tree() {
    dir="$1"
    rm -rf "$dir"
    mkdir -p "$dir/.claude/agents"
    printf '# researcher\n' > "$dir/.claude/agents/researcher.md"
    printf '# architect\n' > "$dir/.claude/agents/architect.md"
    cat > "$dir/.template-customizations" <<'EOF'
# .template-customizations — one path per line.

CUSTOMER_NOTES.md
docs/OPEN_QUESTIONS.md
EOF
}

# Test: clean.mutation.sh is a no-op.
test_clean() {
    work=$(mktemp -d)
    build_synthetic_tree "$work"

    before=$(find "$work" -type f | LC_ALL=C sort | xargs sha1sum 2>/dev/null | sha1sum | awk '{print $1}')

    (
        cd "$work" || exit 1
        SWDT_MUTATION_SOURCE_RC=v1.0.0-test \
            "$mutations_dir/clean.mutation.sh"
    ) || { fail "clean mutation exited non-zero"; rm -rf "$work"; return; }

    after=$(find "$work" -type f | LC_ALL=C sort | xargs sha1sum 2>/dev/null | sha1sum | awk '{print $1}')

    if [ "$before" != "$after" ]; then
        fail "clean.mutation.sh modified the tree (expected no-op)"
    fi
    rm -rf "$work"
}

# Test: with-customizations.mutation.sh is idempotent + adds the
# marker line and the .template-customizations entry.
test_with_customizations() {
    work=$(mktemp -d)
    build_synthetic_tree "$work"

    (
        cd "$work" || exit 1
        SWDT_MUTATION_SOURCE_RC=v1.0.0-test \
            "$mutations_dir/with-customizations.mutation.sh"
    ) || { fail "with-customizations first apply failed"; rm -rf "$work"; return; }

    # Check the marker exists in researcher.md
    if ! grep -q '# fixture-customization-marker' "$work/.claude/agents/researcher.md"; then
        fail "with-customizations did not add marker to researcher.md"
    fi
    # Check the path was appended to .template-customizations
    if ! grep -q '^\.claude/agents/researcher\.md$' "$work/.template-customizations"; then
        fail "with-customizations did not append researcher.md to .template-customizations"
    fi

    sha_a=$(find "$work" -type f | LC_ALL=C sort | xargs sha1sum 2>/dev/null | sha1sum | awk '{print $1}')

    # Apply again — must be idempotent.
    (
        cd "$work" || exit 1
        SWDT_MUTATION_SOURCE_RC=v1.0.0-test \
            "$mutations_dir/with-customizations.mutation.sh"
    ) || { fail "with-customizations second apply failed"; rm -rf "$work"; return; }

    sha_b=$(find "$work" -type f | LC_ALL=C sort | xargs sha1sum 2>/dev/null | sha1sum | awk '{print $1}')

    if [ "$sha_a" != "$sha_b" ]; then
        fail "with-customizations not idempotent (tree changed between applies)"
    fi
    rm -rf "$work"
}

# Test: with-accepted-local.mutation.sh writes a deterministic
# .template-conflicts.json that re-running overwrites byte-identically.
test_with_accepted_local() {
    work=$(mktemp -d)
    build_synthetic_tree "$work"

    (
        cd "$work" || exit 1
        SWDT_MUTATION_SOURCE_RC=v1.0.0-test \
            "$mutations_dir/with-accepted-local.mutation.sh"
    ) || { fail "with-accepted-local first apply failed"; rm -rf "$work"; return; }

    if [ ! -f "$work/.template-conflicts.json" ]; then
        fail "with-accepted-local did not create .template-conflicts.json"
        rm -rf "$work"; return
    fi
    if ! grep -q '"classified": "accepted_local"' "$work/.template-conflicts.json"; then
        fail "with-accepted-local: .template-conflicts.json missing accepted_local entry"
    fi
    if ! grep -q '"classified": "local_only_kept"' "$work/.template-conflicts.json"; then
        fail "with-accepted-local: .template-conflicts.json missing local_only_kept entry"
    fi

    sha_a=$(sha1sum "$work/.template-conflicts.json" | awk '{print $1}')

    # Apply again — must produce byte-identical .template-conflicts.json.
    (
        cd "$work" || exit 1
        SWDT_MUTATION_SOURCE_RC=v1.0.0-test \
            "$mutations_dir/with-accepted-local.mutation.sh"
    ) || { fail "with-accepted-local second apply failed"; rm -rf "$work"; return; }

    sha_b=$(sha1sum "$work/.template-conflicts.json" | awk '{print $1}')

    if [ "$sha_a" != "$sha_b" ]; then
        fail "with-accepted-local not idempotent (.template-conflicts.json bytes changed)"
    fi
    rm -rf "$work"
}

test_clean
test_with_customizations
test_with_accepted_local

if [ "$rc" -eq 0 ]; then
    echo "  PASS: all 3 mutation scripts produce expected golden output and are idempotent"
fi

exit "$rc"
