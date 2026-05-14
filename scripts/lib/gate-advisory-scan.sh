#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# scripts/lib/gate-advisory-scan.sh — advisory-pointer scanner sub-gate
# (FR-006, US3). Per R-8: scan every operator-facing message in
# scripts/upgrade.sh, scripts/scaffold.sh, and every migrations/*.sh
# for path references and fail if any referenced path does not exist in
# the candidate tree.

# gate_advisory_scan_file <file>
#   Emit one "<line>:<path>" record per path reference found in <file>.
#   Path-reference regex (R-8):
#     (migrations|scripts|docs|\.claude/agents|\.github)/[A-Za-z0-9._/-]+\.(sh|md|yml|yaml|json|py)
gate_advisory_scan_file() {
    file="$1"
    [ -f "$file" ] || return 0
    # Use grep -nE to print "<line>:<match>" with line number.
    # The egrep alternative regex matches the canonical top-level dirs
    # plus a typical file extension set per R-8.
    grep -nE '(migrations|scripts|docs|\.claude/agents|\.github)/[A-Za-z0-9._/-]+\.(sh|md|yml|yaml|json|py)' "$file" 2>/dev/null \
        | while IFS=: read -r line_no rest; do
            # Pull every matching path on the line.
            printf '%s\n' "$rest" | grep -oE '(migrations|scripts|docs|\.claude/agents|\.github)/[A-Za-z0-9._/-]+\.(sh|md|yml|yaml|json|py)' \
                | while IFS= read -r path; do
                    printf '%s\t%s\t%s\n' "$file" "$line_no" "$path"
                done
        done
}

# gate_subgate_advisory-pointers (regression). FR-006.
gate_subgate_advisory-pointers() {
    cd "$GATE_CANDIDATE_TREE" || return 1

    targets="scripts/upgrade.sh scripts/scaffold.sh"
    for m in migrations/*.sh; do
        [ -f "$m" ] && targets="$targets $m"
    done

    matches_file="$GATE_TEMP_ROOT/advisory-pointers.matches"
    : > "$matches_file"

    for f in $targets; do
        [ -f "$f" ] || continue
        gate_advisory_scan_file "$f" >> "$matches_file"
    done

    # Dedupe on (source_file, source_line, path_reference) per data-model E-5.
    sort -u "$matches_file" -o "$matches_file"

    # Allowlist: paths legitimately referenced but not present in the tree
    # (runtime-created downstream targets, doc-comment placeholders).
    allowlist="$GATE_CANDIDATE_TREE/tests/release-gate/advisory-allowlist.txt"

    failed=0
    while IFS=$(printf '\t') read -r source_file source_line path_ref; do
        [ -z "$path_ref" ] && continue
        if [ ! -e "$GATE_CANDIDATE_TREE/$path_ref" ]; then
            # Skip if path is in the allowlist (matches an exact line).
            if [ -f "$allowlist" ] && grep -Fxq "$path_ref" "$allowlist"; then
                continue
            fi
            echo "$source_file:$source_line — references missing path '$path_ref'"
            failed=$((failed + 1))
        fi
    done < "$matches_file"

    if [ "$failed" -gt 0 ]; then
        echo
        echo "$failed dangling advisory pointer(s) detected"
        return 1
    fi
    return 0
}

if command -v gate_register >/dev/null 2>&1; then
    gate_register advisory-pointers regression "Scan operator-facing path references; fail on dangling paths (FR-006)."
fi
