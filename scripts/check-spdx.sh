#!/usr/bin/env sh
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# check-spdx.sh — pre-release gate (issue #142 suggested-fix #2).
#
# Walks scripts/**/*.sh and tests/**/*.sh and verifies that each file's
# first 5 lines contain `SPDX-License-Identifier:`. Files missing the
# header are reported to stderr; exit non-zero if any are missing.
#
# Usage:
#   scripts/check-spdx.sh            # report missing, exit non-zero on failure
#   scripts/check-spdx.sh --summary  # also emit a final compliance count
#
# Designed for CI: invoked early in
# .github/workflows/template-contract-smoke.yml to block PRs that
# regress the SPDX-header invariant.

set -eu

SUMMARY=0
for arg in "$@"; do
    case "$arg" in
        --summary) SUMMARY=1 ;;
        *)
            printf 'check-spdx.sh: unknown argument: %s\n' "$arg" >&2
            printf 'usage: check-spdx.sh [--summary]\n' >&2
            exit 2
            ;;
    esac
done

# Anchor on the repo root regardless of invocation cwd.
SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd)
cd -- "$REPO_ROOT"

missing=0
total=0
missing_list=""

# Collect candidates: any .sh under scripts/ or tests/.
# Use find with -print to handle nested directories; null-delimit to be
# safe with whitespace even though we control the filenames.
candidates=$(find scripts tests -type f -name '*.sh' 2>/dev/null | LC_ALL=C sort)

if [ -z "$candidates" ]; then
    printf 'check-spdx.sh: no .sh files found under scripts/ or tests/\n' >&2
    exit 1
fi

# Iterate without globally tampering with IFS (avoids
# Semgrep `bash.lang.security.ifs-tampering`). Heredoc keeps the loop
# in the current shell so $total / $missing / $missing_list persist.
while IFS= read -r file; do
    [ -z "$file" ] && continue
    total=$((total + 1))
    if head -n 5 -- "$file" | grep -q 'SPDX-License-Identifier:'; then
        :
    else
        missing=$((missing + 1))
        missing_list="${missing_list}${file}
"
        printf 'missing SPDX header: %s\n' "$file" >&2
    fi
done <<EOF
$candidates
EOF

if [ "$SUMMARY" -eq 1 ]; then
    compliant=$((total - missing))
    printf 'check-spdx: %d/%d files compliant (missing=%d)\n' \
        "$compliant" "$total" "$missing"
fi

if [ "$missing" -gt 0 ]; then
    exit 1
fi
exit 0
