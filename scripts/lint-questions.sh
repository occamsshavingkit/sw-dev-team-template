#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# scripts/lint-questions.sh — question-style linter (FR-012, R-8).
#
# Five patterns:
#   1 Compound seed question (scoping rows ending in '?').
#   2 Multi-numbered customer question (more than one '^N. ' before '?').
#   3 Multiple independent option sets near a '?' (tables / <details> / ## Option).
#   4 Non-empty `agents-running-at-ask: [...]` metadata in OPEN_QUESTIONS-shaped rows.
#   5 Compound OPEN_QUESTIONS row (question column passes pattern 1).
#
# Modes:
#   warning-only (default until HARDGATE_AFTER_SHA is recorded) — exit 0 with WARN summary.
#   hard-gate (after HARDGATE_AFTER_SHA is set to a real commit SHA) — exit 1 on violations.
#
# Usage:
#   scripts/lint-questions.sh [--summary]
#   scripts/lint-questions.sh --files "<path1> <path2> ..."
#   scripts/lint-questions.sh --since <git-sha> [--summary]
#
# POSIX-sh only: no bashisms (no [[ ]], no arrays, no pipefail). LANG=C/LC_ALL=C.

set -eu

LANG=C
LC_ALL=C
export LANG LC_ALL

# Placeholder until the orchestrator records the actual hard-gate SHA at a
# future MINOR-boundary Release. When this constant is set to a real
# 40-char SHA the linter switches to hard-gate exit-code behaviour for
# files/lines committed after that SHA.
HARDGATE_AFTER_SHA="DEFERRED_SET_AT_HARDGATE_PR"

SUMMARY=0
SINCE_SHA=""
FILES_ARG=""

usage() {
    cat >&2 <<'EOF'
Usage: scripts/lint-questions.sh [--summary] [--since <sha> | --files "<paths>"]

Modes:
  default            walks a fixed in-repo default file set
  --files "<paths>"  space-separated explicit file list (fixture self-test)
  --since <sha>      restrict to files touched in commits since <sha>;
                     the literal token HARDGATE_AFTER_SHA expands to the
                     recorded hard-gate SHA constant

Flags:
  --summary          emit a final 'lint-questions: <N> warnings, <M> errors' line
  -h | --help        this help

Exit codes:
  0    no violations, or violations in warning-only mode
  1    violations and hard-gate mode is active
  2    usage error
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --summary) SUMMARY=1; shift ;;
        --since)
            [ $# -ge 2 ] || { usage; exit 2; }
            SINCE_SHA="$2"
            shift 2
            ;;
        --files)
            [ $# -ge 2 ] || { usage; exit 2; }
            FILES_ARG="$2"
            shift 2
            ;;
        -h|--help) usage; exit 0 ;;
        *) printf 'lint-questions: unknown arg: %s\n' "$1" >&2; usage; exit 2 ;;
    esac
done

# Resolve the literal "HARDGATE_AFTER_SHA" sentinel to the recorded constant.
if [ "$SINCE_SHA" = "HARDGATE_AFTER_SHA" ]; then
    SINCE_SHA="$HARDGATE_AFTER_SHA"
fi

# Determine whether hard-gate mode applies. It applies only when:
#   - HARDGATE_AFTER_SHA is a real commit SHA (not the placeholder), AND
#   - --since was passed AND points to that SHA (CI invocation pattern).
HARD_GATE=0
if [ "$HARDGATE_AFTER_SHA" != "DEFERRED_SET_AT_HARDGATE_PR" ] && \
   [ -n "$SINCE_SHA" ] && [ "$SINCE_SHA" = "$HARDGATE_AFTER_SHA" ]; then
    HARD_GATE=1
fi

# Resolve repo root so relative paths in reports stay short.
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# Build the file list.
TMPFILES="$(mktemp)"
# shellcheck disable=SC2064
trap "rm -f \"$TMPFILES\"" EXIT INT TERM HUP

if [ -n "$FILES_ARG" ]; then
    # Explicit list (fixture-corpus self-test).
    for f in $FILES_ARG; do
        [ -f "$f" ] && printf '%s\n' "$f" >> "$TMPFILES"
    done
elif [ -n "$SINCE_SHA" ] && [ "$SINCE_SHA" != "DEFERRED_SET_AT_HARDGATE_PR" ]; then
    # All files changed since the given SHA.
    git -C "$REPO_ROOT" diff --name-only "$SINCE_SHA"...HEAD 2>/dev/null \
        | while IFS= read -r p; do
            [ -n "$p" ] || continue
            full="$REPO_ROOT/$p"
            [ -f "$full" ] && printf '%s\n' "$full"
        done >> "$TMPFILES"
else
    # Default in-repo file set (recently-touched scoping surfaces + the
    # canonical question-batching homes).
    for rel in \
        CLAUDE.md \
        docs/FIRST_ACTIONS.md \
        docs/OPEN_QUESTIONS.md \
        docs/OPEN_QUESTIONS-ARCHIVE.md \
        docs/templates/scoping-questions-template.md \
        docs/templates/intake-log-template.md \
        .claude/agents/tech-lead.md \
        docs/agents/manual/tech-lead-manual.md \
        docs/runtime/agents/tech-lead.md \
        docs/adr/fw-adr-0008-tech-lead-orchestration-boundary.md
    do
        full="$REPO_ROOT/$rel"
        [ -f "$full" ] && printf '%s\n' "$full" >> "$TMPFILES"
    done
fi

# Emit a single violation line. File path is relativized to REPO_ROOT.
emit_to() {
    # emit_to <outfile> <file> <line> <pattern-id> <snippet>
    out="$1"; rel="$2"; lineno="$3"; pid="$4"; snippet="$5"
    case "$rel" in
        "$REPO_ROOT"/*) rel="${rel#$REPO_ROOT/}" ;;
    esac
    snippet=$(printf '%s' "$snippet" | tr -d '\r' | cut -c 1-160)
    printf '%s:%s: %s: "%s"\n' "$rel" "$lineno" "$pid" "$snippet" >> "$out"
}

# ----- Pattern detectors --------------------------------------------------

# Pattern 1: Compound seed question.
#   Heuristic per spec:
#     * a row ending with `?`, and one of:
#       - `, and ` immediately before the `?`
#       - `; ` between two `?`-bearing clauses
#       - more than one `?` in the row
#
# A "row" is a single line OR a table-row column. We approximate by
# operating per line: most violations live on a single physical line
# (numbered seed questions, OPEN_QUESTIONS table rows, bullet rows).
check_pattern1() {
    f="$1"
    awk -v F="$f" '
    BEGIN { count = 0 }
    {
        line = $0
        # Skip code fences and HTML comments crudely.
        if (line ~ /^[[:space:]]*```/) { in_code = !in_code; next }
        if (in_code) next
        if (line !~ /\?/) next

        # Count `?` characters in the line.
        tmp = line; qs = 0
        n = gsub(/\?/, "?", tmp)
        qs = n

        # Trigger A: ends with `?` and contains ", and " before the final `?`.
        triggerA = 0
        if (line ~ /, and [^?]*\?[[:space:]]*$/ || line ~ /, and [^?]*\? *\|/) triggerA = 1

        # Trigger B: `; ` separating two `?`-bearing clauses.
        triggerB = 0
        if (qs >= 2 && line ~ /\?[^?]*; [^?]*\?/) triggerB = 1

        # Trigger C: more than one `?` in the row.
        triggerC = (qs >= 2) ? 1 : 0

        if (triggerA || triggerB || triggerC) {
            tag = "pattern-1-compound-seed"
            printf "P1\t%d\t%s\t%s\n", NR, tag, line
        }
    }
    ' "$f"
}

# Pattern 2: Multi-numbered customer question.
#   A paragraph that contains `^\s*[0-9]+\.\s` more than once before the next `?`.
#   "Paragraph" = run of non-blank lines.
check_pattern2() {
    f="$1"
    awk -v F="$f" '
    BEGIN {
        para_start = 0; numbered_count = 0; saw_question = 0;
        first_num_line = 0; in_code = 0
    }
    function flush(   p_start) {
        # No-op: emission happens when we detect the trigger condition.
    }
    {
        line = $0
        if (line ~ /^[[:space:]]*```/) { in_code = !in_code; next }
        if (in_code) next

        if (line ~ /^[[:space:]]*$/) {
            # paragraph boundary
            para_start = 0
            numbered_count = 0
            saw_question = 0
            first_num_line = 0
            next
        }
        if (para_start == 0) {
            para_start = NR
        }
        if (line ~ /^[[:space:]]*[0-9]+\.[[:space:]]/) {
            numbered_count += 1
            if (first_num_line == 0) first_num_line = NR
        }
        if (line ~ /\?/) {
            if (numbered_count > 1 && !saw_question) {
                printf "P2\t%d\tpattern-2-multi-numbered\t%s\n", first_num_line, line
                saw_question = 1
            }
        }
    }
    ' "$f"
}

# Pattern 3: Multiple independent option sets near a `?`.
#   Approximated by counting clustered table-shaped lines (`^| ... |`),
#   `<details>` blocks, or `## Option` headings within a 25-line window
#   that also contains a `?`.
check_pattern3() {
    f="$1"
    awk -v F="$f" '
    BEGIN {
        WIN = 25; in_code = 0
    }
    {
        lines[NR] = $0
        if ($0 ~ /^[[:space:]]*```/) code_toggle[NR] = 1
    }
    END {
        # Resolve in-code state per line.
        c = 0
        for (i = 1; i <= NR; i++) {
            if (code_toggle[i]) c = 1 - c
            incode[i] = c
        }
        for (i = 1; i <= NR; i++) {
            if (incode[i]) continue
            if (lines[i] !~ /\?/) continue
            # Count option-set blocks in the window [i-WIN, i+WIN].
            lo = i - WIN; if (lo < 1) lo = 1
            hi = i + WIN; if (hi > NR) hi = NR

            details_blocks = 0
            option_headings = 0
            table_blocks = 0
            in_table = 0
            seen_table_row = 0
            for (j = lo; j <= hi; j++) {
                L = lines[j]
                if (incode[j]) continue
                if (L ~ /<details>/) details_blocks += 1
                if (L ~ /^##[#]*[[:space:]]+Option[[:space:]A-Za-z0-9_-]*/) option_headings += 1
                if (L ~ /^\|[^|]*\|/) {
                    if (!in_table) {
                        in_table = 1
                        seen_table_row = 0
                    }
                    seen_table_row += 1
                } else {
                    if (in_table && seen_table_row >= 2) {
                        table_blocks += 1
                    }
                    in_table = 0
                    seen_table_row = 0
                }
            }
            if (in_table && seen_table_row >= 2) table_blocks += 1

            total = details_blocks + option_headings + table_blocks
            if (total >= 2) {
                # Report at the question line, but only once per question line.
                if (!reported[i]) {
                    printf "P3\t%d\tpattern-3-multi-option-sets\t%s\n", i, lines[i]
                    reported[i] = 1
                }
            }
        }
    }
    ' "$f"
}

# Pattern 4: Non-empty `agents-running-at-ask: [<id>, ...]` in OQ-shaped rows.
#   Empty (`[]`) is fine; any identifier inside the brackets is a violation.
check_pattern4() {
    f="$1"
    awk -v F="$f" '
    {
        line = $0
        # Match `agents-running-at-ask:` followed by `[` ... `]` with at
        # least one non-`]`, non-whitespace character inside.
        if (match(line, /agents-running-at-ask:[[:space:]]*\[[^]]*\]/)) {
            seg = substr(line, RSTART, RLENGTH)
            # Strip the prefix and brackets, check for any non-whitespace.
            inner = seg
            sub(/^.*\[/, "", inner)
            sub(/\][[:space:]]*$/, "", inner)
            gsub(/[[:space:]]/, "", inner)
            if (length(inner) > 0) {
                printf "P4\t%d\tpattern-4-agents-running\t%s\n", NR, line
            }
        }
    }
    ' "$f"
}

# Pattern 5: Compound OPEN_QUESTIONS row — the `Question` column passes pattern 1.
#   OQ table shape:
#     | ID | Opened | Question | Blocked on | Answerer | Status | Resolution |
#   The `Question` column is the 3rd `|`-delimited field (after the leading `|`).
check_pattern5() {
    f="$1"
    awk -v F="$f" '
    BEGIN { in_table = 0; in_code = 0 }
    {
        line = $0
        if (line ~ /^[[:space:]]*```/) { in_code = !in_code; next }
        if (in_code) next

        # Detect OQ-style table rows: must start with `|` and have at least
        # 7 fields (matching the register schema).
        if (line ~ /^\|/) {
            # Skip header + separator rows (separator has only - and |).
            if (line ~ /^\|[[:space:]:|-]*\|[[:space:]]*$/) next
            # Field count via gsub on `|`.
            tmp = line
            n = gsub(/\|/, "|", tmp)
            if (n < 7) next

            # Skip header (contains the literal word "Question").
            if (line ~ /\|[[:space:]]*Question[[:space:]]*\|/) next

            # Extract the 3rd field (between the 3rd and 4th `|`).
            s = line
            # Drop the first `|`.
            sub(/^\|/, "", s)
            # Field 1.
            f1_end = index(s, "|"); if (f1_end == 0) next
            s = substr(s, f1_end + 1)
            # Field 2.
            f2_end = index(s, "|"); if (f2_end == 0) next
            s = substr(s, f2_end + 1)
            # Field 3.
            f3_end = index(s, "|"); if (f3_end == 0) next
            qcol = substr(s, 1, f3_end - 1)
            # Trim.
            sub(/^[[:space:]]+/, "", qcol); sub(/[[:space:]]+$/, "", qcol)
            if (qcol == "" || qcol == "..." || qcol == "…") next

            # Apply pattern-1 triggers on the question column.
            qs = gsub(/\?/, "?", qcol)
            triggerA = (qcol ~ /, and [^?]*\?[[:space:]]*$/) ? 1 : 0
            triggerB = (qs >= 2 && qcol ~ /\?[^?]*; [^?]*\?/) ? 1 : 0
            triggerC = (qs >= 2) ? 1 : 0
            if (triggerA || triggerB || triggerC) {
                printf "P5\t%d\tpattern-5-compound-oq-row\t%s\n", NR, line
            }
        }
    }
    ' "$f"
}

# ----- Drive the detectors over every file --------------------------------

REPORTFILE="$(mktemp)"
# shellcheck disable=SC2064
trap "rm -f \"$TMPFILES\" \"$REPORTFILE\"" EXIT INT TERM HUP

while IFS= read -r FILE; do
    [ -n "$FILE" ] || continue
    [ -f "$FILE" ] || continue
    case "$FILE" in
        *.md|*.markdown) : ;;
        *) continue ;;
    esac

    {
        check_pattern1 "$FILE"
        check_pattern2 "$FILE"
        check_pattern3 "$FILE"
        check_pattern4 "$FILE"
        check_pattern5 "$FILE"
    } | while IFS=$(printf '\t') read -r _pid lineno pname snippet; do
        [ -n "$lineno" ] || continue
        emit_to "$REPORTFILE" "$FILE" "$lineno" "$pname" "$snippet"
    done
done < "$TMPFILES"

# Print report to stdout, count rows.
if [ -s "$REPORTFILE" ]; then
    cat "$REPORTFILE"
fi
N_TOTAL=$(wc -l < "$REPORTFILE" | tr -d ' ')

# Summary + exit policy.
if [ "$HARD_GATE" -eq 1 ]; then
    if [ "$SUMMARY" -eq 1 ]; then
        printf 'lint-questions: 0 warnings, %s errors\n' "$N_TOTAL"
    fi
    if [ "$N_TOTAL" -gt 0 ]; then
        printf 'lint-questions: hard-gate FAIL (%s violation(s))\n' "$N_TOTAL" >&2
        exit 1
    fi
    exit 0
else
    if [ "$N_TOTAL" -gt 0 ]; then
        printf 'lint-questions: WARN %s violation(s); hard-gate not yet active (HARDGATE_AFTER_SHA=%s)\n' \
            "$N_TOTAL" "$HARDGATE_AFTER_SHA" >&2
    fi
    if [ "$SUMMARY" -eq 1 ]; then
        printf 'lint-questions: %s warnings, 0 errors\n' "$N_TOTAL"
    fi
    exit 0
fi
