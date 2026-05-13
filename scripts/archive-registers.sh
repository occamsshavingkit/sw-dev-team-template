#!/bin/sh
# archive-registers.sh — bound live registers per the live-bound rule.
#
# Live-bound rule: a row is "live" iff its Status is `open`/`in-progress`
# (non-terminal) OR its row-date is on/after the most-recent milestone
# close date. Terminal rows older than the cutoff move to a paired
# append-only archive; the live file keeps a tombstone-plus-archive-
# pointer for traceability.
#
# Source: T021 / FR-004 + SC-003 + spec clarification 1.
# Standards: ISO/IEC/IEEE 12207 record-retention spirit; PMBOK
# closing-process archiving. The script itself is POSIX-sh, `set -eu`
# (no pipefail), no bashisms, LC_ALL=C-pinned.
#
# Usage:
#   archive-registers.sh [--dry-run] [--include-customer-notes] \
#                        [--milestone-close YYYY-MM-DD] [--root PATH]
#
# Exit codes:
#   0  — success (changes applied or dry-run output written)
#   2  — usage error (bad flag, missing cutoff, future cutoff)
#   3  — internal: required register layout could not be parsed
#
# Idempotence: a second run with no new eligible rows leaves both
# live and archive files byte-identical.

set -eu
LANG=C
LC_ALL=C
export LANG LC_ALL

# shellcheck disable=SC2100  # false positive: hyphen in filename literal, not arithmetic
PROG=archive-registers.sh

usage() {
    cat <<'EOF'
Usage: archive-registers.sh [options]

Options:
  --dry-run                   Print eligible rows; do not modify files.
  --include-customer-notes    Archive eligible CUSTOMER_NOTES.md rows
                              (only `superseded` or `withdrawn`). Default
                              is to list-only in dry-run, skip in apply.
  --milestone-close DATE      Cutoff date (YYYY-MM-DD). If omitted, the
                              most recent passed milestone from
                              docs/pm/SCHEDULE.md is used (Baseline date
                              column; Forecast date if Baseline is TBD).
  --root PATH                 Repository root (default: script's parent).
  -h, --help                  This help.

Live registers (paired archive):
  docs/OPEN_QUESTIONS.md    -> docs/OPEN_QUESTIONS-ARCHIVE.md
  docs/intake-log.md        -> docs/intake-log-ARCHIVE.md
  docs/pm/RISKS.md          -> docs/pm/RISKS-ARCHIVE.md
  docs/pm/LESSONS.md        -> docs/pm/LESSONS-ARCHIVE.md
  CUSTOMER_NOTES.md         -> docs/customer-notes-archive.md
EOF
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

DRY_RUN=0
INCLUDE_CN=0
CUTOFF=""
ROOT=""

while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run) DRY_RUN=1 ;;
        --include-customer-notes) INCLUDE_CN=1 ;;
        --milestone-close)
            shift
            [ $# -gt 0 ] || { usage >&2; exit 2; }
            CUTOFF="$1"
            ;;
        --milestone-close=*)
            CUTOFF="${1#--milestone-close=}"
            ;;
        --root)
            shift
            [ $# -gt 0 ] || { usage >&2; exit 2; }
            ROOT="$1"
            ;;
        --root=*)
            ROOT="${1#--root=}"
            ;;
        -h|--help) usage; exit 0 ;;
        *) echo "$PROG: unknown argument: $1" >&2; usage >&2; exit 2 ;;
    esac
    shift
done

# ---------------------------------------------------------------------------
# Resolve repo root
# ---------------------------------------------------------------------------

if [ -z "$ROOT" ]; then
    # Resolve script's parent directory portably.
    # shellcheck disable=SC1007  # deliberate: empty CDPATH assignment scopes to the cd call
    script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
    # shellcheck disable=SC1007  # deliberate: empty CDPATH assignment scopes to the cd call
    ROOT=$(CDPATH= cd -- "$script_dir/.." && pwd)
fi

[ -d "$ROOT" ] || { echo "$PROG: root not a directory: $ROOT" >&2; exit 2; }

# ---------------------------------------------------------------------------
# Date helpers (POSIX — no GNU-date assumption)
# ---------------------------------------------------------------------------

# Validate YYYY-MM-DD shape. 0 on valid, non-zero otherwise.
date_valid() {
    case "$1" in
        ????-??-??)
            y=${1%%-*}; rest=${1#*-}; m=${rest%%-*}; d=${rest#*-}
            case "$y$m$d" in *[!0-9]*) return 1 ;; esac
            [ "$m" -ge 1 ] && [ "$m" -le 12 ] || return 1
            [ "$d" -ge 1 ] && [ "$d" -le 31 ] || return 1
            return 0
            ;;
    esac
    return 1
}

# Compare two YYYY-MM-DD strings. Echoes -1/0/1 for a<b/a=b/a>b.
# Lexical compare works because the format is fixed-width.
date_cmp() {
    # shellcheck disable=SC3012  # POSIX \< is undefined; we target bash/dash where it works for fixed-width date strings
    if [ "$1" = "$2" ]; then echo 0
    elif [ "$1" \< "$2" ]; then echo -1
    else echo 1
    fi
}

today() { date '+%Y-%m-%d'; }

TODAY=$(today)

# ---------------------------------------------------------------------------
# Derive cutoff from SCHEDULE.md when not passed explicitly.
# Rule: scan the milestone table for rows whose Status column equals
# `passed`; take the most recent Baseline date (or Forecast date if
# Baseline is TBD). Most-recent means lexically max of valid dates.
# ---------------------------------------------------------------------------

derive_cutoff_from_schedule() {
    sched="$ROOT/docs/pm/SCHEDULE.md"
    [ -f "$sched" ] || return 1
    awk '
        BEGIN { in_table = 0; have_header = 0;
                col_baseline = 0; col_forecast = 0; col_status = 0;
                best = "" }
        # A table separator like |---|---|...| follows the header row.
        /^\|[ \t-]*-+/ { if (have_header) in_table = 1; next }
        /^\|/ {
            # Parse cells: strip leading/trailing | and split on |.
            line = $0
            sub(/^\|[ \t]*/, "", line)
            sub(/[ \t]*\|[ \t]*$/, "", line)
            n = split(line, cells, /[ \t]*\|[ \t]*/)
            if (!have_header) {
                for (i = 1; i <= n; i++) {
                    h = tolower(cells[i])
                    gsub(/^[ \t]+|[ \t]+$/, "", h)
                    if (h == "baseline date") col_baseline = i
                    else if (h == "forecast date") col_forecast = i
                    else if (h == "status") col_status = i
                }
                if (col_status && (col_baseline || col_forecast)) {
                    have_header = 1
                }
                next
            }
            if (!in_table) next
            status = cells[col_status]
            gsub(/^[ \t]+|[ \t]+$/, "", status)
            if (status != "passed") next
            d = ""
            if (col_baseline) {
                d = cells[col_baseline]
                gsub(/^[ \t]+|[ \t]+$/, "", d)
            }
            if ((d == "" || d == "TBD" || d == "tbd") && col_forecast) {
                d = cells[col_forecast]
                gsub(/^[ \t]+|[ \t]+$/, "", d)
            }
            if (d !~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/) next
            if (best == "" || d > best) best = d
        }
        # Blank line ends the first table we are reading; further tables
        # in the file (Activities, Variance, Gates) get their own header
        # detection, which is fine — we just want the highest passed date.
        /^[ \t]*$/ { in_table = 0; have_header = 0;
                     col_baseline = 0; col_forecast = 0; col_status = 0 }
        END { if (best != "") print best }
    ' "$sched"
}

if [ -z "$CUTOFF" ]; then
    CUTOFF=$(derive_cutoff_from_schedule)
    if [ -z "$CUTOFF" ]; then
        echo "$PROG: no --milestone-close passed and no passed milestone with a date found in docs/pm/SCHEDULE.md" >&2
        usage >&2
        exit 2
    fi
fi

date_valid "$CUTOFF" || {
    echo "$PROG: invalid --milestone-close: $CUTOFF (expected YYYY-MM-DD)" >&2
    exit 2
}

# Reject future cutoff dates.
if [ "$(date_cmp "$CUTOFF" "$TODAY")" = "1" ]; then
    echo "$PROG: cutoff $CUTOFF is in the future (today=$TODAY)" >&2
    usage >&2
    exit 2
fi

# ---------------------------------------------------------------------------
# Status classification
# ---------------------------------------------------------------------------

# Terminal statuses are eligible for archive when row-date < cutoff.
# Non-terminal statuses always stay live regardless of date.
# CUSTOMER_NOTES special case: only superseded/withdrawn are eligible.
# shellcheck disable=SC2317  # false positive: case-branch returns are reachable via call site
is_terminal_status() {
    case "$1" in
        answered|deferred|withdrawn|superseded|closed|done|resolved|accepted|rejected|mitigated) return 0 ;;
        *) return 1 ;;
    esac
}

# shellcheck disable=SC2317  # false positive: case-branch returns are reachable via call site
is_customer_notes_eligible_status() {
    case "$1" in
        superseded|withdrawn) return 0 ;;
        *) return 1 ;;
    esac
}

# ---------------------------------------------------------------------------
# Dry-run report buffer (collected to a temp file so output is ordered).
# ---------------------------------------------------------------------------

TMPDIR_RUN=$(mktemp -d 2>/dev/null || mktemp -d -t "$PROG.XXXXXX")
trap 'rm -rf "$TMPDIR_RUN"' EXIT INT HUP TERM
REPORT="$TMPDIR_RUN/report.txt"
: > "$REPORT"

note() { printf '%s\n' "$*" >> "$REPORT"; }

# ---------------------------------------------------------------------------
# Per-file processing.
#
# Approach: read the file once with awk. Find the first markdown table
# whose header includes a `Status` (or `status`) column AND at least one
# of `Answered date`, `Last reviewed`, `Opened`, `Resolution`, `Date set`
# (the candidate date column, in that priority).
#
# For each data row inside that table:
#   - Extract Status and the chosen date cell.
#   - For the date cell: take the latest YYYY-MM-DD substring found in
#     the cell (handles prose like "Customer, 2026-04-19").
#   - Decide eligibility per the rules.
# Emit two streams: rows-to-archive and the rewritten live-file content.
#
# Files without a parseable table (LESSONS.md journal, CUSTOMER_NOTES.md)
# are handled by separate logic below.
# ---------------------------------------------------------------------------

# process_table_register LIVE_PATH ARCHIVE_PATH LABEL EXTRA_TERMINAL_FILTER
# EXTRA_TERMINAL_FILTER: "" = use is_terminal_status; "cn" = only
# superseded/withdrawn (customer-notes-style; not used for table form).
process_table_register() {
    live="$1"; archive_rel="$2"; label="$3"
    archive="$ROOT/$archive_rel"

    if [ ! -f "$ROOT/$live" ]; then
        note "[$label] not-present: $live (skipped)"
        return 0
    fi

    # Run an awk pass that:
    #  - Detects table header & relevant column positions.
    #  - For each data row, classifies eligibility and either:
    #      * prints the row to FD3 (archive stream) plus a timestamp comment,
    #      * substitutes a tombstone line into FD4 (rewritten-live stream),
    #      * or copies the row unchanged to FD4.
    #  - Outside the chosen table, all lines pass through unchanged to FD4.
    #
    # Communication with the shell about counts: awk writes a final
    # summary line to stdout in the form: COUNT=<n> WARNINGS=<n> ID_LIST=...
    archived_tmp="$TMPDIR_RUN/${label}.archived.md"
    newlive_tmp="$TMPDIR_RUN/${label}.newlive.md"
    summary_tmp="$TMPDIR_RUN/${label}.summary.txt"
    : > "$archived_tmp"; : > "$newlive_tmp"; : > "$summary_tmp"

    awk -v cutoff="$CUTOFF" -v today="$TODAY" -v label="$label" \
        -v archive_rel="$archive_rel" \
        -v archived_file="$archived_tmp" \
        -v newlive_file="$newlive_tmp" \
        -v summary_file="$summary_tmp" '
        function lc(s) { return tolower(s) }
        function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
        # Extract the latest YYYY-MM-DD substring from a string.
        function latest_date(s,    best, t, r, m) {
            best = ""
            t = s
            while (match(t, /[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/)) {
                m = substr(t, RSTART, RLENGTH)
                if (best == "" || m > best) best = m
                t = substr(t, RSTART + RLENGTH)
            }
            return best
        }
        function is_terminal(s,    x) {
            x = lc(trim(s))
            if (x == "answered" || x == "deferred" || x == "withdrawn" \
                || x == "superseded" || x == "closed" || x == "done" \
                || x == "resolved" || x == "accepted" || x == "rejected" \
                || x == "mitigated") return 1
            return 0
        }
        # Parse a markdown table row into cells[1..n].
        function parse_row(line,    s, n) {
            s = line
            sub(/^\|[ \t]*/, "", s)
            sub(/[ \t]*\|[ \t]*$/, "", s)
            n = split(s, cells, /[ \t]*\|[ \t]*/)
            return n
        }
        function emit_archive(row, id, archived_date,    line) {
            print row >> archived_file
            printf "<!-- archived %s by archive-registers.sh -->\n", archived_date >> archived_file
            archived_ids[++archived_n] = id
        }
        function emit_tombstone(id, archived_date, ncols,    s, i) {
            # Build a row with ncols cells: first is ID, last is the
            # tombstone link, middle cells are placeholder "…".
            s = "| " id " |"
            for (i = 2; i < ncols; i++) s = s " … |"
            s = s " archived " archived_date " -> [archive](./" basename(archive_rel) "#row-" id ") |"
            print s >> newlive_file
        }
        function basename(p,    n, parts) {
            n = split(p, parts, "/")
            return parts[n]
        }
        BEGIN {
            in_target_table = 0
            seen_target = 0
            have_header = 0
            col_status = 0; col_date = 0; col_id = 0
            ncols = 0
            archived_n = 0
            warnings = 0
        }
        {
            line = $0
            # Detect table header (a |---|---| separator line). When we
            # see one, the previous line buffered as candidate header.
            if (line ~ /^\|[ \t]*-+/ && !seen_target) {
                # cand_header was set by previous |...| row.
                if (cand_header_set) {
                    nh = parse_row(cand_header)
                    cs = 0; cd = 0; cid = 0
                    for (i = 1; i <= nh; i++) {
                        h = lc(trim(cells[i]))
                        if (h == "status") cs = i
                        else if (h == "answered date") { if (!cd) cd = i }
                        else if (h == "last reviewed") { if (!cd) cd = i }
                        else if (h == "resolution") { if (!cd) cd = i }
                        else if (h == "opened") { if (!cd) cd = i }
                        else if (h == "date") { if (!cd) cd = i }
                        # ID column candidates (first wins):
                        if (cid == 0) {
                            if (h == "id" || h == "turn") cid = i
                        }
                    }
                    if (cs && cd && cid) {
                        # Lock in this table.
                        col_status = cs; col_date = cd; col_id = cid
                        ncols = nh
                        print cand_header >> newlive_file
                        print line >> newlive_file
                        in_target_table = 1
                        seen_target = 1
                        next
                    } else {
                        # Not the table we want; write header + sep through.
                        print cand_header >> newlive_file
                        print line >> newlive_file
                        cand_header_set = 0
                        next
                    }
                }
            }
            # If we are inside the target table:
            if (in_target_table) {
                # Empty line or non-pipe line ends the table.
                if (line !~ /^\|/) {
                    in_target_table = 0
                    print line >> newlive_file
                    next
                }
                # Parse the row.
                n = parse_row(line)
                if (n < ncols) {
                    # Malformed; pass through with warning.
                    warnings++
                    printf "%s: malformed row (cols=%d expected=%d): %s\n", label, n, ncols, substr(line, 1, 80) | "cat 1>&2"
                    print line >> newlive_file
                    next
                }
                id = trim(cells[col_id])
                status = trim(cells[col_status])
                datecell = cells[col_date]
                rdate = latest_date(datecell)
                if (is_terminal(status)) {
                    if (rdate == "") {
                        warnings++
                        printf "%s: row %s terminal but no parseable date in column; skipping archive\n", label, id | "cat 1>&2"
                        print line >> newlive_file
                        next
                    }
                    # Eligible iff rdate < cutoff. (rows at or after the
                    # cutoff stay live by the live-bound rule.)
                    if (rdate < cutoff) {
                        emit_archive(line, id, today)
                        emit_tombstone(id, today, ncols)
                        next
                    } else {
                        print line >> newlive_file
                        next
                    }
                } else {
                    # Non-terminal: always live.
                    print line >> newlive_file
                    next
                }
            }
            # Buffer candidate-header rows (any |...| line that is NOT a
            # separator) for the next iteration; until we lock onto a
            # target table.
            if (!seen_target && line ~ /^\|/ && line !~ /^\|[ \t]*-+/) {
                cand_header = line
                cand_header_set = 1
                # Do NOT print yet — we will print on the separator pass
                # (whether or not it locks in as target).
                next
            }
            # Default: pass-through.
            print line >> newlive_file
        }
        END {
            # If we buffered a candidate header but never hit a separator,
            # flush it.
            if (cand_header_set && !seen_target) print cand_header >> newlive_file
            printf "ARCHIVED=%d WARNINGS=%d\n", archived_n, warnings > summary_file
            for (i = 1; i <= archived_n; i++) printf "%s\n", archived_ids[i] >> summary_file
        }
    ' "$ROOT/$live"

    # Read summary line.
    if [ ! -s "$summary_tmp" ]; then
        note "[$label] internal: summary missing"
        return 3
    fi
    first=$(sed -n '1p' "$summary_tmp")
    archived_n=$(printf '%s\n' "$first" | sed -n 's/^ARCHIVED=\([0-9]*\).*/\1/p')
    warnings_n=$(printf '%s\n' "$first" | sed -n 's/.*WARNINGS=\([0-9]*\).*/\1/p')
    [ -n "$archived_n" ] || archived_n=0
    [ -n "$warnings_n" ] || warnings_n=0

    if [ "$archived_n" -eq 0 ]; then
        note "[$label] no eligible rows (cutoff=$CUTOFF)"
    else
        note "[$label] $archived_n eligible row(s) (cutoff=$CUTOFF):"
        # Print IDs.
        sed -n '2,$p' "$summary_tmp" | while IFS= read -r idline; do
            [ -n "$idline" ] && note "    - $idline"
        done
    fi
    if [ "$warnings_n" -gt 0 ]; then
        note "[$label] $warnings_n warning(s) emitted (see stderr)"
    fi

    if [ "$DRY_RUN" -eq 0 ] && [ "$archived_n" -gt 0 ]; then
        # Write archive file (create with header if needed).
        if [ ! -s "$archive" ]; then
            archive_dir=$(dirname -- "$archive")
            mkdir -p "$archive_dir"
            live_base=$(basename -- "$live")
            {
                printf '# %s archive\n\n' "$live_base"
                # shellcheck disable=SC2016  # literal backticks for Markdown output
                printf 'Append-only archive paired with `%s`.\n' "$live"
                # shellcheck disable=SC2016  # literal backticks for Markdown output
                printf 'Rules in `scripts/archive-registers.sh`.\n\n'
            } > "$archive"
        fi
        cat "$archived_tmp" >> "$archive"
        # Replace the live file atomically.
        cp "$newlive_tmp" "$ROOT/$live.tmp"
        mv "$ROOT/$live.tmp" "$ROOT/$live"
    fi

    return 0
}

# ---------------------------------------------------------------------------
# CUSTOMER_NOTES handler (non-table, ## YYYY-MM-DD sections).
# Eligibility: status==superseded or withdrawn AND section-date < cutoff
# AND --include-customer-notes is set. Otherwise list-only (dry-run) or
# skip (apply).
# A section is from `## YYYY-MM-DD ...` up to (but not including) the
# next `## ` header.
# Status is detected from a `**Supersedes:**` line OR an explicit
# `**Status:** superseded|withdrawn` line.
# ---------------------------------------------------------------------------

process_customer_notes() {
    live="$1"; archive_rel="$2"; label="$3"
    archive="$ROOT/$archive_rel"

    if [ ! -f "$ROOT/$live" ]; then
        note "[$label] not-present: $live (skipped)"
        return 0
    fi

    archived_tmp="$TMPDIR_RUN/${label}.archived.md"
    newlive_tmp="$TMPDIR_RUN/${label}.newlive.md"
    summary_tmp="$TMPDIR_RUN/${label}.summary.txt"
    : > "$archived_tmp"; : > "$newlive_tmp"; : > "$summary_tmp"

    awk -v cutoff="$CUTOFF" -v today="$TODAY" -v label="$label" \
        -v include_cn="$INCLUDE_CN" -v dry_run="$DRY_RUN" \
        -v archived_file="$archived_tmp" \
        -v newlive_file="$newlive_tmp" \
        -v summary_file="$summary_tmp" '
        function flush_section(eligible, section_id, sect_lines_idx,    i) {
            if (eligible == "yes" && include_cn == "1" && dry_run == "0") {
                for (i = 1; i <= sect_lines_idx; i++) print sect_lines[i] >> archived_file
                printf "<!-- archived %s by archive-registers.sh -->\n", today >> archived_file
                # Tombstone in live: header line + a tombstone bullet.
                # Live keeps the section header so cross-refs continue working.
                print sect_lines[1] >> newlive_file
                printf "\n> Section archived %s -> see `%s`.\n\n", today, "docs/customer-notes-archive.md" >> newlive_file
                archived_ids[++archived_n] = section_id
            } else {
                # Either not eligible, or list-only in dry-run, or
                # include flag off. Always keep section intact in live.
                for (i = 1; i <= sect_lines_idx; i++) print sect_lines[i] >> newlive_file
                if (eligible == "yes") {
                    list_only_ids[++list_only_n] = section_id
                }
            }
        }
        BEGIN {
            in_section = 0
            archived_n = 0
            list_only_n = 0
            sect_n = 0
            sect_id = ""
            sect_date = ""
            sect_status_terminal = "no"
        }
        {
            line = $0
            if (line ~ /^## [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/) {
                if (in_section) {
                    # Flush previous.
                    eligible = "no"
                    if (sect_status_terminal == "yes" && sect_date != "" && sect_date < cutoff) eligible = "yes"
                    flush_section(eligible, sect_id, sect_n)
                }
                in_section = 1
                sect_n = 0
                sect_lines[++sect_n] = line
                # Extract date.
                if (match(line, /[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/)) {
                    sect_date = substr(line, RSTART, RLENGTH)
                } else { sect_date = "" }
                sect_id = sect_date  # use date as the stable section ID
                sect_status_terminal = "no"
                next
            }
            if (!in_section) {
                # Preamble: pass through.
                print line >> newlive_file
                next
            }
            sect_lines[++sect_n] = line
            # Status indicators inside section.
            if (line ~ /\*\*[Ss]tatus:\*\*[ \t]*(superseded|withdrawn)/) sect_status_terminal = "yes"
            else if (line ~ /\*\*[Ss]upersedes:\*\*[ \t]*[^[:space:]]/) sect_status_terminal = "yes"
            # Note: a Supersedes pointer means THIS entry replaces an
            # older one; the OLD one was superseded. We do not auto-flag
            # the new one. So actually do not set on Supersedes. Reverse:
            # remove that branch.
        }
        END {
            if (in_section) {
                eligible = "no"
                if (sect_status_terminal == "yes" && sect_date != "" && sect_date < cutoff) eligible = "yes"
                flush_section(eligible, sect_id, sect_n)
            }
            printf "ARCHIVED=%d LIST_ONLY=%d\n", archived_n, list_only_n > summary_file
            for (i = 1; i <= archived_n; i++) printf "A:%s\n", archived_ids[i] >> summary_file
            for (i = 1; i <= list_only_n; i++) printf "L:%s\n", list_only_ids[i] >> summary_file
        }
    ' "$ROOT/$live"

    if [ ! -s "$summary_tmp" ]; then
        note "[$label] internal: summary missing"
        return 3
    fi
    first=$(sed -n '1p' "$summary_tmp")
    archived_n=$(printf '%s\n' "$first" | sed -n 's/^ARCHIVED=\([0-9]*\).*/\1/p')
    list_only_n=$(printf '%s\n' "$first" | sed -n 's/.*LIST_ONLY=\([0-9]*\).*/\1/p')
    [ -n "$archived_n" ] || archived_n=0
    [ -n "$list_only_n" ] || list_only_n=0

    if [ "$INCLUDE_CN" -eq 0 ]; then
        if [ "$list_only_n" -eq 0 ]; then
            note "[$label] no eligible rows (cutoff=$CUTOFF; --include-customer-notes not set)"
        else
            note "[$label] $list_only_n eligible row(s) (cutoff=$CUTOFF; --include-customer-notes NOT set, list-only):"
            sed -n '2,$p' "$summary_tmp" | while IFS= read -r idline; do
                case "$idline" in
                    L:*) note "    - ${idline#L:}" ;;
                esac
            done
        fi
        return 0
    fi

    # INCLUDE_CN set.
    if [ "$archived_n" -eq 0 ]; then
        note "[$label] no eligible rows (cutoff=$CUTOFF)"
    else
        note "[$label] $archived_n eligible row(s) (cutoff=$CUTOFF):"
        sed -n '2,$p' "$summary_tmp" | while IFS= read -r idline; do
            case "$idline" in
                A:*) note "    - ${idline#A:}" ;;
            esac
        done
    fi

    if [ "$DRY_RUN" -eq 0 ] && [ "$archived_n" -gt 0 ]; then
        if [ ! -s "$archive" ]; then
            archive_dir=$(dirname -- "$archive")
            mkdir -p "$archive_dir"
            live_base=$(basename -- "$live")
            {
                printf '# %s archive\n\n' "$live_base"
                # shellcheck disable=SC2016  # literal backticks for Markdown output
                printf 'Append-only archive paired with `%s`.\n' "$live"
                # shellcheck disable=SC2016  # literal backticks for Markdown output
                printf 'Rules in `scripts/archive-registers.sh`.\n\n'
            } > "$archive"
        fi
        cat "$archived_tmp" >> "$archive"
        cp "$newlive_tmp" "$ROOT/$live.tmp"
        mv "$ROOT/$live.tmp" "$ROOT/$live"
    fi
    return 0
}

# ---------------------------------------------------------------------------
# LESSONS.md handler.
# Format is a journal with `### YYYY-MM-DD — <title>` sections, not a
# table. Treat journal entries as terminal once their date is < cutoff
# and a `**Category.**` line is present (the synthesis marker). We list
# eligibility but DO NOT auto-archive lessons by default — lessons are
# long-tail learning; archiving them silently risks losing institutional
# memory. Lessons are reported in dry-run; in apply mode we only archive
# entries explicitly tagged with `**Status:** archive-ready` (none today).
# This keeps the script conservative for LESSONS while still surfacing
# size signal.
# ---------------------------------------------------------------------------

process_lessons() {
    live="$1"; archive_rel="$2"; label="$3"

    if [ ! -f "$ROOT/$live" ]; then
        note "[$label] not-present: $live (skipped)"
        return 0
    fi

    summary_tmp="$TMPDIR_RUN/${label}.summary.txt"
    : > "$summary_tmp"

    awk -v cutoff="$CUTOFF" '
        BEGIN { count = 0; old = 0 }
        /^### [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/ {
            count++
            if (match($0, /[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/)) {
                d = substr($0, RSTART, RLENGTH)
                if (d < cutoff) { old++; print d }
            }
        }
        END { printf "TOTAL=%d OLD=%d\n", count, old > "/dev/stderr" }
    ' "$ROOT/$live" > "$summary_tmp" 2>>"$TMPDIR_RUN/${label}.counts.txt"

    counts=$(cat "$TMPDIR_RUN/${label}.counts.txt" 2>/dev/null || true)
    total=$(printf '%s\n' "$counts" | sed -n 's/.*TOTAL=\([0-9]*\).*/\1/p')
    old=$(printf '%s\n' "$counts" | sed -n 's/.*OLD=\([0-9]*\).*/\1/p')
    [ -n "$total" ] || total=0
    [ -n "$old" ] || old=0

    if [ "$old" -eq 0 ]; then
        note "[$label] no eligible journal entries (cutoff=$CUTOFF; total=$total entries)"
    else
        note "[$label] $old of $total journal entries are pre-cutoff (cutoff=$CUTOFF):"
        note "        (LESSONS is a journal — list-only; no auto-archive)"
        # Show first up to 5 dates as evidence.
        i=0
        while IFS= read -r d; do
            [ -z "$d" ] && continue
            i=$((i + 1))
            [ "$i" -le 5 ] || break
            note "    - $d"
        done < "$summary_tmp"
        if [ "$old" -gt 5 ]; then
            note "    - (and $((old - 5)) more)"
        fi
    fi
    return 0
}

# ---------------------------------------------------------------------------
# Driver
# ---------------------------------------------------------------------------

note "archive-registers.sh"
note "  cutoff (milestone-close): $CUTOFF"
note "  today: $TODAY"
note "  root: $ROOT"
note "  mode: $(if [ "$DRY_RUN" -eq 1 ]; then echo dry-run; else echo apply; fi)"
note "  include-customer-notes: $(if [ "$INCLUDE_CN" -eq 1 ]; then echo yes; else echo no; fi)"
note ""

process_table_register "docs/OPEN_QUESTIONS.md" \
    "docs/OPEN_QUESTIONS-ARCHIVE.md" "OPEN_QUESTIONS"

process_table_register "docs/intake-log.md" \
    "docs/intake-log-ARCHIVE.md" "INTAKE_LOG"

process_table_register "docs/pm/RISKS.md" \
    "docs/pm/RISKS-ARCHIVE.md" "RISKS"

process_lessons "docs/pm/LESSONS.md" \
    "docs/pm/LESSONS-ARCHIVE.md" "LESSONS"

process_customer_notes "CUSTOMER_NOTES.md" \
    "docs/customer-notes-archive.md" "CUSTOMER_NOTES"

# Print collected report (always to stdout).
cat "$REPORT"

exit 0
