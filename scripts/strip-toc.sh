#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# scripts/strip-toc.sh — build-time TOC strip producing a gitignored mirror
# tree at .model-view/<path>.model.md.
#
# Spec:      specs/010-toc-build-time-strip/spec.md  (D-1..D-8)
# Contract:  specs/010-toc-build-time-strip/contracts/strip-mechanism.md
#
# POSIX shell. Removes `<!-- TOC --> ... <!-- /TOC -->` fenced blocks
# (line-anchored, non-greedy, inclusive of fences + one trailing blank)
# from in-scope tracked Markdown files, writing stripped copies to
# .model-view/<path>.model.md.
#
# Flags:
#   <path>       optional single-file fast path
#   --all        force whole-tree walk
#   --dry-run    parse + validate only; write nothing
#   --check      regenerate to tempdir + diff on-disk mirror (v1 stub: exit 0)
#   --quiet      suppress per-file progress
#
# Exit codes:
#   0  success
#   1  --check found drift / other non-fatal error
#   2  FATAL: unpaired fence, unreadable file, write failure
#
# In-scope predicate (D-3 / contract § In-scope predicate):
#   - git-tracked, *.md
#   - NOT under examples/, specs/, tests/, .model-view/
#   - contains at least one `<!-- TOC -->` fence

set -u

PROG="strip-toc"
MODE_ALL=0
MODE_DRY=0
MODE_CHECK=0
QUIET=0
SINGLE=""

usage() {
    cat <<EOF
Usage: scripts/strip-toc.sh [<path>] [--all] [--dry-run] [--check] [--quiet]

Build a gitignored mirror tree at .model-view/ with <!-- TOC --> blocks
stripped from each in-scope Markdown file.

  <path>       process a single tracked *.md file (post-commit fast path)
  --all        walk every in-scope tracked *.md file
  --dry-run    validate fences only; write no mirror output
  --check      diff regenerated mirror vs on-disk (exit 1 on drift)
  --quiet      suppress per-file progress (errors still go to stderr)
  -h, --help   show this help

Spec: specs/010-toc-build-time-strip/spec.md (D-1..D-8).
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --all)     MODE_ALL=1; shift ;;
        --dry-run) MODE_DRY=1; shift ;;
        --check)   MODE_CHECK=1; shift ;;
        --quiet)   QUIET=1; shift ;;
        -h|--help) usage; exit 0 ;;
        --) shift; break ;;
        -*) echo "$PROG: unknown flag: $1" >&2; usage >&2; exit 2 ;;
        *)
            if [ -n "$SINGLE" ]; then
                echo "$PROG: only one path argument allowed" >&2; exit 2
            fi
            SINGLE="$1"; shift
            ;;
    esac
done

# Resolve repo root via git, fall back to script dir's parent.
repo_root="$(git rev-parse --show-toplevel 2>/dev/null)"
if [ -z "$repo_root" ]; then
    repo_root="$(cd "$(dirname "$0")/.." && pwd)"
fi
cd "$repo_root" || { echo "$PROG: cannot cd to repo root $repo_root" >&2; exit 2; }

# In-scope predicate: blacklist prefixes for path (after git-ls / *.md).
in_scope_path() {
    p="$1"
    case "$p" in
        examples/*|specs/*|tests/*|.model-view/*) return 1 ;;
        *.md) return 0 ;;
        *) return 1 ;;
    esac
}

# Whether the file contains a TOC fence at all (cheap pre-check). Matches
# EITHER `<!-- TOC -->` or `<!-- /TOC -->` so that stray-close files
# (contract case 5) still enter the parse path and FATAL — not silently
# skip. The full unpaired-fence detection lives in strip_to_stdout's awk.
has_toc_fence() {
    grep -Eq '^[[:space:]]*<!-- /?TOC -->[[:space:]]*$' "$1" 2>/dev/null
}

# Strip TOC blocks from $1 to stdout.
# Honours fenced code blocks (``` lines toggle code-block state; TOC fences
# inside a code block are NOT matched). Emits FATAL diagnostic + exit 2 on
# unpaired fence.
#
# Output prefixes a single generation-banner line per contract § Output.
strip_to_stdout() {
    src="$1"
    awk -v src="$src" '
        BEGIN {
            in_code = 0
            in_toc = 0
            open_line = 0
            pending_blank = 0
            printf "<!-- generated from %s — do not edit by hand -->\n", src
        }
        # Track fenced code blocks (``` at column 1, optional language tag).
        /^```/ { in_code = !in_code }
        {
            line = $0
            # Inside a code block, never enter/exit TOC mode; pass through.
            if (in_code) {
                if (pending_blank) { print ""; pending_blank = 0 }
                print line
                next
            }

            # If we are inside a TOC block, look for the close fence.
            if (in_toc) {
                if (line ~ /^[[:space:]]*<!-- \/TOC -->[[:space:]]*$/) {
                    in_toc = 0
                    pending_blank = 1
                }
                next
            }

            # Not inside TOC: detect open fence.
            if (line ~ /^[[:space:]]*<!-- TOC -->[[:space:]]*$/) {
                in_toc = 1
                open_line = NR
                # Flush a pending blank that was waiting on this line (rare).
                pending_blank = 0
                next
            }

            # Detect stray close fence (no opener).
            if (line ~ /^[[:space:]]*<!-- \/TOC -->[[:space:]]*$/) {
                printf "FATAL: %s:%d: unpaired close fence <!-- /TOC --> with no matching <!-- TOC -->\n", src, NR > "/dev/stderr"
                exit 2
            }

            # Pending trailing blank from a just-closed TOC: swallow exactly
            # one blank line if the next line is blank; otherwise emit the
            # current line as-is and unset pending.
            if (pending_blank) {
                if (line == "") {
                    pending_blank = 0
                    next
                }
                pending_blank = 0
            }
            print line
        }
        END {
            if (in_toc) {
                printf "FATAL: %s:%d: unpaired open fence <!-- TOC --> with no matching <!-- /TOC -->\n", src, open_line > "/dev/stderr"
                exit 2
            }
        }
    ' "$src"
}

# Process a single in-scope file. Honours MODE_DRY / MODE_CHECK.
# Returns: 0 ok; 1 check-drift; 2 fatal.
process_one() {
    src="$1"
    [ -r "$src" ] || { echo "$PROG: FATAL: cannot read $src" >&2; return 2; }

    # Cheap pre-check: skip files with no TOC fence (no-op per D-3).
    if ! has_toc_fence "$src"; then
        return 0
    fi

    mirror_dir=".model-view/$(dirname "$src")"
    # Strip extension `.md`, append `.model.md`.
    base=$(basename "$src")
    stem="${base%.md}"
    mirror_path="$mirror_dir/${stem}.model.md"

    # Parse-only modes do not need a tempfile or mirror_dir; route awk
    # output to /dev/null and rely solely on the exit status.
    if [ "$MODE_DRY" -eq 1 ] || [ "$MODE_CHECK" -eq 1 ]; then
        awk_rc=0
        strip_to_stdout "$src" > /dev/null 2>/tmp/strip-toc-err.$$ || awk_rc=$?
        [ -s "/tmp/strip-toc-err.$$" ] && cat "/tmp/strip-toc-err.$$" >&2
        rm -f "/tmp/strip-toc-err.$$"
        if [ "$awk_rc" -ne 0 ]; then
            return 2
        fi
        if [ "$MODE_DRY" -eq 1 ]; then
            [ "$QUIET" -eq 0 ] && printf '%s: dry-run ok: %s\n' "$PROG" "$src" >&2
            return 0
        fi
        # MODE_CHECK: v1 stub. Drift detection vs the on-disk mirror is
        # NOT yet implemented; only fence-pair parse validation runs.
        # Warn loudly on stderr so the operator does not mistake a clean
        # parse for a clean mirror. Per spec contract § Exit codes,
        # exit 0 reflects the parse result.
        printf '%s: --check is not yet implemented; ran source-parse validation only. To regenerate the mirror, use --all.\n' "$PROG" >&2
        return 0
    fi

    # Write mode: place the tempfile INSIDE mirror_dir so that the final
    # `mv` is a same-filesystem rename (atomic per rename(2)). Putting
    # the tempfile under $TMPDIR (typically tmpfs on Linux) would make
    # `mv` a cross-fs copy+unlink — NOT atomic — violating contract
    # § Output.
    mkdir -p "$mirror_dir" || {
        echo "$PROG: FATAL: cannot mkdir $mirror_dir" >&2; return 2; }
    tmp=$(mktemp "${mirror_path}.XXXXXX") || {
        echo "$PROG: FATAL: cannot create tempfile in $mirror_dir" >&2; return 2; }

    awk_rc=0
    strip_to_stdout "$src" > "$tmp" 2>/tmp/strip-toc-err.$$ || awk_rc=$?
    # Forward awk stderr (FATAL diagnostics).
    [ -s "/tmp/strip-toc-err.$$" ] && cat "/tmp/strip-toc-err.$$" >&2
    rm -f "/tmp/strip-toc-err.$$"

    if [ "$awk_rc" -ne 0 ]; then
        rm -f "$tmp"
        return 2
    fi

    mv "$tmp" "$mirror_path" || { rm -f "$tmp"; echo "$PROG: FATAL: cannot write $mirror_path" >&2; return 2; }
    [ "$QUIET" -eq 0 ] && printf '%s: wrote %s\n' "$PROG" "$mirror_path" >&2
    return 0
}

# Emit the top-level .model-view/README.md (D-5).
emit_mirror_readme() {
    [ "$MODE_DRY" -eq 1 ] && return 0
    [ "$MODE_CHECK" -eq 1 ] && return 0
    mkdir -p .model-view
    cat > .model-view/README.md <<'EOF'
# .model-view/ — gitignored mirror tree

This directory is **regenerated** by `scripts/strip-toc.sh`. It is
gitignored; do not edit files here by hand — your edits are overwritten
on the next strip run.

Each `*.model.md` is a stripped copy of the canonical `*.md` at the
same relative path, with `<!-- TOC --> ... <!-- /TOC -->` fenced blocks
removed. Humans read the canonical source; the mirror is for model-side
consumers that want the same prose without TOC overhead.

Regenerate: `scripts/strip-toc.sh --all`

Opt-in automation: `git config core.hooksPath .git-hooks` (installs
the shipped `post-checkout` and `pre-push` templates).

Spec: `specs/010-toc-build-time-strip/spec.md` (D-1..D-8).
EOF
}

# Build the in-scope file list. Single-file fast path uses $SINGLE iff scoped.
overall_rc=0

if [ -n "$SINGLE" ] && [ "$MODE_ALL" -eq 0 ]; then
    # Normalize relative path.
    rel="$SINGLE"
    case "$rel" in /*) rel="${rel#"$repo_root"/}" ;; esac
    if ! git ls-files --error-unmatch -- "$rel" >/dev/null 2>&1; then
        echo "$PROG: FATAL: $rel is not tracked by git" >&2
        exit 2
    fi
    if in_scope_path "$rel"; then
        process_one "$rel" || overall_rc=$?
    else
        [ "$QUIET" -eq 0 ] && printf '%s: %s out of scope (skipped)\n' "$PROG" "$rel" >&2
    fi
    emit_mirror_readme
    exit "$overall_rc"
fi

# Whole-tree walk. Enumerate tracked *.md, filter by predicate.
files=$(git ls-files -- '*.md' 2>/dev/null) || {
    echo "$PROG: FATAL: git ls-files failed" >&2; exit 2; }

# Process each file. Any FATAL bumps overall_rc to 2 and we keep going so a
# CI dry-run reports every offender; write-mode stops the file's own write
# but continues the walk (the per-file mirror is the only thing left
# inconsistent, and the temp was already cleaned).
echo "$files" | while IFS= read -r f; do
    [ -z "$f" ] && continue
    in_scope_path "$f" || continue
    rc=0
    process_one "$f" || rc=$?
    if [ "$rc" -gt "$overall_rc" ]; then overall_rc=$rc; fi
    # Subshell can't propagate overall_rc to parent; use exit-on-fatal mode.
    if [ "$rc" -eq 2 ]; then
        # Continue the walk so CI lists every malformed file; record via stub
        # file in tempdir.
        printf 'F\n' >> "${STRIP_FATAL_MARK:-/tmp/strip-toc-fatal.$$}"
    fi
done

# Read back fatal marker (subshell limitation).
fatal_mark="${STRIP_FATAL_MARK:-/tmp/strip-toc-fatal.$$}"
if [ -s "$fatal_mark" ]; then
    overall_rc=2
fi
rm -f "$fatal_mark"

emit_mirror_readme

exit "$overall_rc"
