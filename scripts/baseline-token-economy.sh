#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# scripts/baseline-token-economy.sh — produce the M0 token-economy
# baseline report (FR-002 / data-model E-14) for the
# template-improvement-program (specs/006-template-improvement-program).
#
# Measures the sub-repo's per-agent contract sizes, live-register
# row/word counts, OPEN_QUESTIONS answered-rows-still-live, SCHEDULE
# length, downstream-repo presence + TEMPLATE_VERSION, and broken
# internal Markdown link refs. Output is deterministic: same git state
# + same BASELINE_DOWNSTREAM_ROOTS = byte-identical output.
#
# Usage:
#   BASELINE_DOWNSTREAM_ROOTS=path1:path2:... scripts/baseline-token-economy.sh [--stdout]
#
# Without --stdout, writes to docs/pm/token-economy-baseline.md.
# With --stdout, emits the report to stdout (useful for idempotency
# checks and T004 self-test).
#
# POSIX-sh only: no bashisms (no [[ ]], no arrays, no pipefail, no
# process-substitution). Pinned LANG=C/LC_ALL=C for stable sort.

set -eu

LANG=C
LC_ALL=C
export LANG LC_ALL

usage() {
    cat >&2 <<'EOF'
Usage: BASELINE_DOWNSTREAM_ROOTS=path1:path2:... baseline-token-economy.sh [--stdout]

Required:
  BASELINE_DOWNSTREAM_ROOTS  Colon-separated list of paths to reference
                             downstream repos (e.g.,
                             ../../QuackDCS:../../QuackPLC).

Options:
  --stdout                   Emit the report on stdout instead of
                             writing docs/pm/token-economy-baseline.md.
EOF
}

emit_stdout=0
while [ $# -gt 0 ]; do
    case "$1" in
        --stdout) emit_stdout=1 ;;
        -h|--help) usage; exit 0 ;;
        *) printf 'baseline-token-economy.sh: unknown argument: %s\n' "$1" >&2
           usage
           exit 2 ;;
    esac
    shift
done

if [ -z "${BASELINE_DOWNSTREAM_ROOTS:-}" ]; then
    printf 'baseline-token-economy.sh: BASELINE_DOWNSTREAM_ROOTS is required\n' >&2
    usage
    exit 2
fi

# Resolve sub-repo root (the directory containing this script's parent).
script_dir="$(cd -- "$(dirname -- "$0")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"

cd "$repo_root"

template_sha="$(git rev-parse HEAD 2>/dev/null || echo unknown)"

# captured_at is deterministic on inputs (git state) so that two
# consecutive invocations on the same SHA produce byte-identical
# output. Precedence:
#   1. $SOURCE_DATE_EPOCH (reproducible-build idiom) if set,
#   2. commit time of HEAD (UTC) if the repo is a git checkout,
#   3. current UTC wall-clock time as a final fallback.
if [ -n "${SOURCE_DATE_EPOCH:-}" ]; then
    captured_at="$(date -u -d "@${SOURCE_DATE_EPOCH}" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null \
        || date -u -r "${SOURCE_DATE_EPOCH}" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null \
        || date -u +%Y-%m-%dT%H:%M:%SZ)"
elif commit_epoch="$(git log -1 --format=%ct HEAD 2>/dev/null)" && [ -n "$commit_epoch" ]; then
    captured_at="$(date -u -d "@${commit_epoch}" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null \
        || date -u -r "${commit_epoch}" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null \
        || date -u +%Y-%m-%dT%H:%M:%SZ)"
else
    captured_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
fi

# Working tempdir; cleaned on exit.
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT INT HUP TERM

# ---------------------------------------------------------------------------
# Per-agent contract sizes
# ---------------------------------------------------------------------------
agent_rows="$tmpdir/agent_rows"
: > "$agent_rows"
if [ -d .claude/agents ]; then
    # List, sort, count.
    find .claude/agents -maxdepth 1 -type f -name '*.md' -print | sort > "$tmpdir/agents.list"
    while IFS= read -r f; do
        [ -n "$f" ] || continue
        role="$(basename "$f" .md)"
        lines="$(wc -l < "$f" | tr -d ' ')"
        words="$(wc -w < "$f" | tr -d ' ')"
        printf '| %s | %s | %s |\n' "$role" "$lines" "$words" >> "$agent_rows"
    done < "$tmpdir/agents.list"
fi

# ---------------------------------------------------------------------------
# Live register sizes
# ---------------------------------------------------------------------------
# Markdown-table row counter: lines starting with '|' that are not
# pure separator rows (i.e. not /^\|[ \t\-:|]*\|\s*$/). We further
# exclude header rows by skipping the first non-separator |-row?
# Spec says "row counts use a Markdown-table-aware grep" — include
# every non-separator pipe-led line. Header rows are part of the row
# total; this is the simplest deterministic rule.
count_md_rows() {
    f="$1"
    if [ ! -f "$f" ]; then
        printf '0'
        return
    fi
    awk '
        /^\|/ {
            line = $0
            # strip trailing whitespace
            sub(/[[:space:]]+$/, "", line)
            # separator row: only |, -, :, space inside pipes
            if (line ~ /^\|[[:space:]\-:|]+\|$/) next
            n++
        }
        END { print n + 0 }
    ' "$f"
}

count_words() {
    f="$1"
    if [ ! -f "$f" ]; then
        printf '0'
        return
    fi
    wc -w < "$f" | tr -d ' '
}

register_rows="$tmpdir/register_rows"
: > "$register_rows"
for rel in \
    docs/OPEN_QUESTIONS.md \
    docs/intake-log.md \
    docs/pm/RISKS.md \
    docs/pm/LESSONS.md \
    CUSTOMER_NOTES.md \
    docs/pm/SCHEDULE.md
do
    rows="$(count_md_rows "$rel")"
    words="$(count_words "$rel")"
    printf '| %s | %s | %s |\n' "$rel" "$rows" "$words" >> "$register_rows"
done

# ---------------------------------------------------------------------------
# OPEN_QUESTIONS answered-rows-still-live
# Parse the Status column (6th pipe-delimited field after the leading
# pipe). A row is counted if its status is answered / superseded /
# withdrawn AND it lives in the live file (not the archive).
# ---------------------------------------------------------------------------
answered_live=0
if [ -f docs/OPEN_QUESTIONS.md ]; then
    answered_live="$(awk -F'|' '
        /^\|/ {
            line = $0
            sub(/[[:space:]]+$/, "", line)
            if (line ~ /^\|[[:space:]\-:|]+\|$/) next
            # skip header row (Status column literal "Status")
            status = $7
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", status)
            if (status == "Status") next
            if (status == "answered" || status == "superseded" || status == "withdrawn") n++
        }
        END { print n + 0 }
    ' docs/OPEN_QUESTIONS.md)"
fi

# ---------------------------------------------------------------------------
# SCHEDULE total line count
# ---------------------------------------------------------------------------
schedule_lines=0
if [ -f docs/pm/SCHEDULE.md ]; then
    schedule_lines="$(wc -l < docs/pm/SCHEDULE.md | tr -d ' ')"
fi

# ---------------------------------------------------------------------------
# Downstream repos
# ---------------------------------------------------------------------------
downstream_rows="$tmpdir/downstream_rows"
: > "$downstream_rows"
# Split colon-separated list into lines, preserving order (do not sort).
# The spec only requires deterministic output — list order is fixed by
# the env var, which is part of the inputs.
printf '%s\n' "$BASELINE_DOWNSTREAM_ROOTS" | tr ':' '\n' > "$tmpdir/roots.list"
while IFS= read -r root; do
    [ -n "$root" ] || continue
    label="$(basename "$root")"
    if [ ! -d "$root" ]; then
        intake_state="not_present"
        tv_state="not_present"
    else
        if [ -f "$root/docs/intake-log.md" ]; then
            intake_state="present"
        else
            intake_state="missing"
        fi
        if [ -f "$root/TEMPLATE_VERSION" ]; then
            tv_state="$(head -1 "$root/TEMPLATE_VERSION" | tr -d '\r')"
            # collapse internal whitespace to one space for cell safety
            tv_state="$(printf '%s' "$tv_state" | tr -s '[:space:]' ' ' | sed 's/^ //; s/ $//')"
            [ -n "$tv_state" ] || tv_state="not_present"
        else
            tv_state="not_present"
        fi
    fi
    printf '| %s | %s | %s |\n' "$label" "$intake_state" "$tv_state" >> "$downstream_rows"
done < "$tmpdir/roots.list"

# ---------------------------------------------------------------------------
# Broken internal Markdown link refs
# Scan every .md file in the sub-repo (git-tracked + untracked, but
# excluding .git). For each [text](target), classify target:
#   - http://, https://, mailto:, #anchor only        → external, skip
#   - target containing '://' (other scheme)          → skip
#   - target with leading '#'                          → skip (in-doc anchor)
# Otherwise: split off any '#fragment' / '?query', resolve relative
# to the .md file's directory (absolute targets resolve from repo
# root), and check existence within repo_root. Targets that escape
# repo_root are reported as broken too.
# ---------------------------------------------------------------------------
broken_raw="$tmpdir/broken_raw"
broken_sorted="$tmpdir/broken_sorted"
: > "$broken_raw"

# Find candidate .md files. Use `find` so untracked files are included
# (the report should reflect on-disk state, not just git index).
find . -type d -name .git -prune -o -type f -name '*.md' -print \
    | sed 's|^\./||' \
    | sort > "$tmpdir/md.list"

# AWK extracts (file, target) pairs; the shell loop resolves paths.
awk_extract='
{
    line = $0
    # Walk the line, find every [..](..). Naive but sufficient for our
    # docs: assume no nested brackets within link text/target.
    while (match(line, /\[[^]]*\]\(([^)]+)\)/, m)) {
        # gawk match() with array — but POSIX awk has no third arg.
    }
}
'
# POSIX awk lacks match() third arg, so we use a different strategy:
# read each line; find every "](" anchor, slice forward to next ")".
extract_links() {
    file="$1"
    awk -v F="$file" '
        {
            s = $0
            while ((i = index(s, "](")) > 0) {
                rest = substr(s, i + 2)
                j = index(rest, ")")
                if (j == 0) { s = ""; continue }
                target = substr(rest, 1, j - 1)
                printf "%s\t%s\n", F, target
                s = substr(rest, j + 1)
            }
        }
    ' "$file"
}

while IFS= read -r mdf; do
    [ -n "$mdf" ] || continue
    extract_links "$mdf"
done < "$tmpdir/md.list" > "$tmpdir/links.raw"

# Resolve and check.
while IFS="$(printf '\t')" read -r src target; do
    [ -n "$target" ] || continue
    # Strip surrounding whitespace
    target="$(printf '%s' "$target" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
    [ -n "$target" ] || continue
    # External / scheme links
    case "$target" in
        http://*|https://*|mailto:*|tel:*|ftp://*|ftps://*|file://*) continue ;;
        '#'*) continue ;;
        *://*) continue ;;
    esac
    # Strip ?query and #fragment
    path_part="${target%%#*}"
    path_part="${path_part%%\?*}"
    [ -n "$path_part" ] || continue
    # Resolve relative to source-file directory, or repo root if absolute.
    src_dir="$(dirname "$src")"
    case "$path_part" in
        /*) resolved="$repo_root$path_part" ;;
        *)  resolved="$repo_root/$src_dir/$path_part" ;;
    esac
    # Normalize ./ and ../ without requiring realpath (which may not
    # tolerate missing components on all systems).
    norm="$(
        printf '%s' "$resolved" | awk '
            BEGIN { n = 0 }
            {
                # split on /
                count = split($0, parts, "/")
                for (i = 1; i <= count; i++) {
                    p = parts[i]
                    if (p == "" && i == 1) { stack[++n] = ""; continue }
                    if (p == "" || p == ".") continue
                    if (p == "..") {
                        if (n > 1) n--
                        continue
                    }
                    stack[++n] = p
                }
                out = ""
                for (i = 1; i <= n; i++) {
                    if (i > 1) out = out "/"
                    out = out stack[i]
                }
                print out
            }
        '
    )"
    if [ -e "$norm" ]; then
        continue
    fi
    # Only count breakages that point inside the repo (or absolute /).
    case "$norm" in
        "$repo_root"|"$repo_root"/*) ;;
        *) continue ;;
    esac
    printf '%s\t%s\n' "$src" "$path_part" >> "$broken_raw"
done < "$tmpdir/links.raw"

sort -u "$broken_raw" > "$broken_sorted"
broken_total=$(wc -l < "$broken_sorted" | tr -d ' ')
broken_display="$tmpdir/broken_display"
head -25 "$broken_sorted" > "$broken_display"
broken_extra=0
if [ "$broken_total" -gt 25 ]; then
    broken_extra=$((broken_total - 25))
fi

# ---------------------------------------------------------------------------
# Compose report
# ---------------------------------------------------------------------------
report="$tmpdir/report.md"
{
    printf '# Token-economy baseline (M0)\n\n'
    printf '**Captured at**: %s\n' "$captured_at"
    printf '**Template SHA**: %s\n' "$template_sha"
    printf '**Source plan**: sw_dev_template_implementation_plan-2.md\n\n'

    printf '## Per-agent contract sizes\n\n'
    printf '| Role | Lines | Words (token proxy) |\n'
    printf '|---|---:|---:|\n'
    cat "$agent_rows"
    printf '\n'

    printf '## Live register sizes\n\n'
    printf '| File | Rows | Words |\n'
    printf '|---|---:|---:|\n'
    cat "$register_rows"
    printf '\n'

    printf '## OPEN_QUESTIONS answered-rows-still-live: %s\n\n' "$answered_live"
    printf '## PM schedule length: %s lines\n\n' "$schedule_lines"

    printf '## Downstream repos\n\n'
    printf '| Repo | docs/intake-log.md | TEMPLATE_VERSION |\n'
    printf '|---|---|---|\n'
    cat "$downstream_rows"
    printf '\n'

    printf '## Broken internal references (cap 25)\n\n'
    if [ "$broken_total" -eq 0 ]; then
        printf '_None._\n'
    else
        while IFS="$(printf '\t')" read -r src target; do
            [ -n "$src" ] || continue
            printf -- '- `%s` -> `%s`\n' "$src" "$target"
        done < "$broken_display"
        if [ "$broken_extra" -gt 0 ]; then
            printf '\n*(+ %s more)*\n' "$broken_extra"
        fi
    fi
} > "$report"

if [ "$emit_stdout" -eq 1 ]; then
    cat "$report"
else
    mkdir -p docs/pm
    cp "$report" docs/pm/token-economy-baseline.md
    printf 'Wrote docs/pm/token-economy-baseline.md\n'
fi
