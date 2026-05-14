#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# scripts/lint-routing.sh — Hard Rule #8 routing-trailer linter.
#
# Enforces the `Routed-Through:` commit-message trailer on every
# non-merge commit past HARDGATE_AFTER_SHA. Mirrors the shape of
# scripts/lint-questions.sh (R-8 sibling): warning-only until the
# hard-gate SHA is recorded at a future MINOR-boundary Release, then
# CI-blocking on violations in the post-cutoff range.
#
# Trailer format (per architect-hr8 design + customer rulings 6/7/8
# 2026-05-14):
#
#   Routed-Through: <role>[:<qualifier>]
#
# Allowed roles:
#   software-engineer architect tech-writer researcher qa-engineer sre
#   release-engineer security-engineer code-reviewer project-manager
#   sme-<domain> onboarding-auditor process-auditor tool-bridge
#
# - `sme-<domain>` is a glob matching `^sme-[a-z][a-z0-9_-]*$`.
# - `tool-bridge` REQUIRES a `:qualifier` from the closed set
#   { agent-push, orchestration, ci-fixup, merge, revert, rebase,
#     cherry-pick }.
# - Non-tool-bridge roles MAY carry a `:qualifier` (informational,
#   not validated).
#
# Pattern IDs:
#   R1 — missing Routed-Through: trailer in commit body
#   R2 — malformed trailer (unknown role; bad / missing tool-bridge
#        qualifier; syntax error)
#   R3 — trailer / file-class mismatch (see file-class table below)
#   R4 — tool-bridge trailer on a disallowed file class
#   R5 — CUSTOMER_NOTES.md touched with a non-researcher trailer
#
# File-class table for R3 / R4:
#
#   *.py, *.sh, src/**, scripts/**             software-engineer | sre |
#                                              release-engineer
#   docs/adr/**                                architect | tech-writer
#   CHANGELOG.md, README.md,                   tech-writer
#   docs/**/*.md (non-ADR)
#   CUSTOMER_NOTES.md                          researcher (sole)
#   tests/**, *test*                           qa-engineer |
#                                              software-engineer
#   .github/workflows/**, release/**           release-engineer
#   docs/security/**                           security-engineer
#   docs/OPEN_QUESTIONS.md,                    tool-bridge OR any role
#   docs/intake-log.md,
#   docs/pm/dispatch-log.md
#   anything else                              any role
#
# Tool-bridge is additionally allowed on the explicit orchestration
# artefacts above and on zero-net-content cases (merge / revert /
# rebase / cherry-pick qualifiers). Tool-bridge on a code / ADR /
# CHANGELOG / CUSTOMER_NOTES path → R4.
#
# Modes:
#   warning-only (default until HARDGATE_AFTER_SHA is recorded) —
#                exit 0 with WARN summary.
#   hard-gate    (after HARDGATE_AFTER_SHA is set to a real commit
#                SHA AND --since references it) — exit 1 on violations.
#
# Usage:
#   scripts/lint-routing.sh [--summary]
#   scripts/lint-routing.sh --since <git-sha> [--summary]
#   scripts/lint-routing.sh --files "<sha1> <sha2> ..."   (explicit list)
#
# POSIX-sh only: no bashisms (no [[ ]], no arrays, no pipefail).
# LANG=C / LC_ALL=C.

set -eu

LANG=C
LC_ALL=C
export LANG LC_ALL

# Placeholder until the orchestrator records the actual hard-gate SHA
# at a future MINOR-boundary Release. When this constant is set to a
# real 40-char SHA the linter switches to hard-gate exit-code behaviour
# for commits made after that SHA. Mirrors lint-questions.sh.
HARDGATE_AFTER_SHA="DEFERRED_SET_AT_HARDGATE_PR"

SUMMARY=0
SINCE_SHA=""
FILES_ARG=""

# Self-test mode is requested via env var (mirrors the
# `semver_sort_tags_self_test` pattern in scripts/lib/semver.sh).
# When LINT_ROUTING_SELF_TEST=1, the script runs the synthetic-cases
# regression suite against a throwaway temp repo and exits 0 (PASS)
# or 1 (FAIL).
if [ "${LINT_ROUTING_SELF_TEST:-0}" = "1" ]; then
    SELF_TEST_MODE=1
else
    SELF_TEST_MODE=0
fi

usage() {
    cat >&2 <<'EOF'
Usage: scripts/lint-routing.sh [--summary] [--since <sha> | --files "<shas>"]

Modes:
  default            scan the last 50 commits on HEAD
  --files "<shas>"   space-separated explicit commit SHA list (self-test)
  --since <sha>      restrict to commits since <sha>;
                     the literal token HARDGATE_AFTER_SHA expands to the
                     recorded hard-gate SHA constant

Flags:
  --summary          emit a final 'lint-routing: <N> warnings, <M> errors' line
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
        *) printf 'lint-routing: unknown arg: %s\n' "$1" >&2; usage; exit 2 ;;
    esac
done

# Resolve the literal "HARDGATE_AFTER_SHA" sentinel to the recorded
# constant. CI passes the literal so the workflow file does not need
# touching when the constant flips.
if [ "$SINCE_SHA" = "HARDGATE_AFTER_SHA" ]; then
    SINCE_SHA="$HARDGATE_AFTER_SHA"
fi

# Hard-gate mode applies only when:
#   - HARDGATE_AFTER_SHA is a real commit SHA (not the placeholder), AND
#   - --since was passed AND resolves to that SHA (CI invocation pattern).
HARD_GATE=0
if [ "$HARDGATE_AFTER_SHA" != "DEFERRED_SET_AT_HARDGATE_PR" ] && \
   [ -n "$SINCE_SHA" ] && [ "$SINCE_SHA" = "$HARDGATE_AFTER_SHA" ]; then
    HARD_GATE=1
fi

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# ----- Allowed-role list / closed qualifier set ---------------------------

# Fixed-role list. `sme-<domain>` and qualifier-bearing forms checked
# separately. Space-delimited so we can grep it cheaply.
FIXED_ROLES="software-engineer architect tech-writer researcher qa-engineer sre release-engineer security-engineer code-reviewer project-manager onboarding-auditor process-auditor tool-bridge"

# Closed set of tool-bridge qualifiers per customer ruling 7
# (2026-05-14): adds rebase / cherry-pick to the earlier list.
TOOLBRIDGE_QUALS="agent-push orchestration ci-fixup merge revert rebase cherry-pick"

# ----- Role classification helpers ----------------------------------------

# Validate a "role[:qualifier]" token. Echoes the canonical role on
# stdout when valid; echoes nothing and returns non-zero when invalid.
# Sets the global var ROLE_BASE to the role and ROLE_QUAL to the
# qualifier (or empty) for the caller.
ROLE_BASE=""
ROLE_QUAL=""
validate_role_token() {
    tok="$1"
    ROLE_BASE=""
    ROLE_QUAL=""

    # Split on first colon.
    case "$tok" in
        *:*)
            ROLE_BASE="${tok%%:*}"
            ROLE_QUAL="${tok#*:}"
            ;;
        *)
            ROLE_BASE="$tok"
            ROLE_QUAL=""
            ;;
    esac

    # Empty pieces are malformed.
    [ -n "$ROLE_BASE" ] || return 1
    case "$tok" in
        *:) return 1 ;;
    esac

    # sme-<domain> glob.
    case "$ROLE_BASE" in
        sme-*)
            # Must match ^sme-[a-z][a-z0-9_-]*$
            rest="${ROLE_BASE#sme-}"
            [ -n "$rest" ] || return 1
            # First char must be lowercase a-z.
            first=$(printf '%s' "$rest" | cut -c1)
            case "$first" in
                [a-z]) : ;;
                *) return 1 ;;
            esac
            # Remaining chars must be [a-z0-9_-].
            tail_chars=$(printf '%s' "$rest" | cut -c2-)
            if [ -n "$tail_chars" ]; then
                case "$tail_chars" in
                    *[!a-z0-9_-]*) return 1 ;;
                esac
            fi
            return 0
            ;;
    esac

    # Fixed-role membership.
    found=0
    for r in $FIXED_ROLES; do
        if [ "$ROLE_BASE" = "$r" ]; then
            found=1
            break
        fi
    done
    [ "$found" -eq 1 ] || return 1

    # tool-bridge requires a qualifier from the closed set.
    if [ "$ROLE_BASE" = "tool-bridge" ]; then
        [ -n "$ROLE_QUAL" ] || return 1
        qfound=0
        for q in $TOOLBRIDGE_QUALS; do
            if [ "$ROLE_QUAL" = "$q" ]; then
                qfound=1
                break
            fi
        done
        [ "$qfound" -eq 1 ] || return 1
    fi
    return 0
}

# ----- File-class classification ------------------------------------------

# Classify a path into one of:
#   code            *.py *.sh src/** scripts/**
#   adr             docs/adr/**
#   docs            docs/**/*.md (non-ADR), CHANGELOG.md, README.md
#   customer_notes  CUSTOMER_NOTES.md
#   tests           tests/** or anything containing "test"
#   ci              .github/workflows/** release/**
#   security        docs/security/**
#   orchestration   docs/OPEN_QUESTIONS.md, docs/intake-log.md,
#                   docs/pm/dispatch-log.md
#   other           everything else
#
# Order matters: more specific classes win. We check customer_notes,
# orchestration, security, ci, adr, tests, code, docs in that order.
classify_path() {
    p="$1"
    # Strip leading ./ if present.
    p="${p#./}"

    case "$p" in
        CUSTOMER_NOTES.md) printf 'customer_notes\n'; return 0 ;;
        docs/OPEN_QUESTIONS.md|docs/intake-log.md|docs/pm/dispatch-log.md)
            printf 'orchestration\n'; return 0 ;;
        docs/security/*) printf 'security\n'; return 0 ;;
        .github/workflows/*|release/*) printf 'ci\n'; return 0 ;;
        docs/adr/*) printf 'adr\n'; return 0 ;;
    esac

    # tests/** OR filename / path containing "test"
    case "$p" in
        tests/*) printf 'tests\n'; return 0 ;;
        *test*) printf 'tests\n'; return 0 ;;
    esac

    # Code paths.
    case "$p" in
        *.py|*.sh) printf 'code\n'; return 0 ;;
        src/*|scripts/*) printf 'code\n'; return 0 ;;
    esac

    # Docs (non-ADR markdown + top-level docs).
    case "$p" in
        CHANGELOG.md|README.md) printf 'docs\n'; return 0 ;;
        docs/*.md|docs/*/*.md|docs/*/*/*.md|docs/*/*/*/*.md)
            printf 'docs\n'; return 0 ;;
    esac

    printf 'other\n'
}

# Is the role allowed on the given file class?
# Returns 0 (yes) or non-zero (no). Also encodes the tool-bridge
# allowlist: tool-bridge is OK on `orchestration` and on zero-net-content
# qualifiers (merge / revert / rebase / cherry-pick).
role_allowed_for_class() {
    role="$1"; qual="$2"; klass="$3"

    case "$role" in
        tool-bridge)
            # Zero-net-content qualifiers are always OK regardless of class.
            case "$qual" in
                merge|revert|rebase|cherry-pick) return 0 ;;
            esac
            # Otherwise tool-bridge only on orchestration class.
            case "$klass" in
                orchestration|other) return 0 ;;
                *) return 1 ;;
            esac
            ;;
    esac

    case "$klass" in
        code)
            case "$role" in
                software-engineer|sre|release-engineer) return 0 ;;
                *) return 1 ;;
            esac
            ;;
        adr)
            case "$role" in
                architect|tech-writer) return 0 ;;
                *) return 1 ;;
            esac
            ;;
        docs)
            case "$role" in
                tech-writer) return 0 ;;
                *) return 1 ;;
            esac
            ;;
        customer_notes)
            # R5: researcher only.
            [ "$role" = "researcher" ] && return 0
            return 1
            ;;
        tests)
            case "$role" in
                qa-engineer|software-engineer) return 0 ;;
                *) return 1 ;;
            esac
            ;;
        ci)
            [ "$role" = "release-engineer" ] && return 0
            return 1
            ;;
        security)
            [ "$role" = "security-engineer" ] && return 0
            return 1
            ;;
        orchestration|other)
            return 0
            ;;
    esac
    return 1
}

# ----- Per-commit lint ----------------------------------------------------

# emit a violation row.
REPORTFILE=""
emit() {
    sha="$1"; pid="$2"; detail="$3"
    short=$(printf '%s' "$sha" | cut -c 1-12)
    printf '%s: %s: %s\n' "$short" "$pid" "$detail" >> "$REPORTFILE"
}

# Extract the Routed-Through: trailer value (last occurrence wins) from
# a commit message body. Echoes the value on stdout, or empty if absent.
extract_trailer() {
    sha="$1"
    git -C "$REPO_ROOT" log -1 --format=%B "$sha" 2>/dev/null \
        | awk '
            BEGIN { val = "" }
            /^[Rr]outed-[Tt]hrough:[[:space:]]*/ {
                v = $0
                sub(/^[Rr]outed-[Tt]hrough:[[:space:]]*/, "", v)
                # Trim trailing whitespace / CR.
                sub(/[[:space:]]+$/, "", v)
                val = v
            }
            END { print val }
        '
}

# Return 1 if commit is a merge commit (>= 2 parents), 0 otherwise.
is_merge_commit() {
    sha="$1"
    n=$(git -C "$REPO_ROOT" rev-list --parents -n 1 "$sha" 2>/dev/null | awk '{print NF - 1}')
    [ "${n:-0}" -ge 2 ] && return 0
    return 1
}

# Lint one commit SHA.
lint_commit() {
    sha="$1"

    # Skip merge commits — Hard Rule #8 trailer requirement is per
    # non-merge commit.
    if is_merge_commit "$sha"; then
        return 0
    fi

    trailer=$(extract_trailer "$sha")
    if [ -z "$trailer" ]; then
        emit "$sha" "R1" "missing Routed-Through: trailer"
        return 0
    fi

    # Validate token.
    if ! validate_role_token "$trailer"; then
        emit "$sha" "R2" "malformed trailer: \"$trailer\""
        return 0
    fi
    role="$ROLE_BASE"
    qual="$ROLE_QUAL"

    # Gather changed files for this commit.
    files=$(git -C "$REPO_ROOT" show --no-renames --name-only --pretty=format: "$sha" 2>/dev/null \
            | awk 'NF > 0')
    [ -n "$files" ] || return 0

    # Per-file class checks.
    saw_customer_notes=0
    bad_classes=""
    toolbridge_bad=""
    printf '%s\n' "$files" | while IFS= read -r f; do
        [ -n "$f" ] || continue
        klass=$(classify_path "$f")
        # R5 takes priority over R3 for CUSTOMER_NOTES.md.
        if [ "$klass" = "customer_notes" ] && [ "$role" != "researcher" ]; then
            emit "$sha" "R5" "non-researcher trailer ($role) touches $f"
            continue
        fi
        if ! role_allowed_for_class "$role" "$qual" "$klass"; then
            # R4 for tool-bridge on a non-allowlisted class;
            # R3 for everyone else.
            if [ "$role" = "tool-bridge" ]; then
                emit "$sha" "R4" "tool-bridge:$qual on $klass file $f"
            else
                emit "$sha" "R3" "$role not allowed on $klass file $f"
            fi
        fi
    done
}

# ----- Self-test ----------------------------------------------------------
#
# Regression guard for the synthetic cases enumerated in the design
# brief. Builds a throwaway git repo with handcrafted commits, runs the
# in-script linter logic against each, and asserts on expected pattern
# emissions.

_self_test() {
    rc=0
    tmproot=$(mktemp -d 2>/dev/null) || {
        printf 'lint-routing self-test: cannot mktemp -d\n' >&2
        return 1
    }
    # shellcheck disable=SC2064
    trap "rm -rf \"$tmproot\"" EXIT INT TERM HUP

    (
        cd "$tmproot" || exit 1
        git init -q .
        git config user.email "selftest@example.invalid"
        git config user.name "lint-routing self-test"
        git config commit.gpgsign false 2>/dev/null || :
        # Seed commit so we always have a HEAD.
        printf 'seed\n' > .seed
        git add .seed
        git commit -q -m "seed

Routed-Through: software-engineer
"
    ) || { rm -rf "$tmproot"; return 1; }

    # Helper: make_case <case-id> <file-path> <content> <trailer-or-NONE>
    # Creates the file at the given relative path inside the tmp repo
    # and commits it with the given trailer (or no trailer when NONE).
    # Echoes the resulting commit SHA on stdout.
    make_case() {
        cid="$1"; fpath="$2"; content="$3"; trailer="$4"
        (
            cd "$tmproot" || exit 1
            mkdir -p "$(dirname -- "$fpath")" 2>/dev/null || :
            printf '%s\n' "$content" > "$fpath"
            git add -- "$fpath"
            if [ "$trailer" = "NONE" ]; then
                git commit -q -m "case $cid

body
"
            else
                git commit -q -m "case $cid

body

$trailer
"
            fi
            git rev-parse HEAD
        )
    }

    # Override REPO_ROOT for the duration of the self-test so the
    # extractor / classifier helpers operate on the temp repo.
    SAVED_REPO_ROOT="$REPO_ROOT"
    REPO_ROOT="$tmproot"

    # Each case captures: case-id, expected pattern ('PASS' = no
    # violations from this commit).
    REPORTFILE_SAVED="${REPORTFILE:-}"
    REPORTFILE=$(mktemp)

    sha_A=$(make_case A "scripts/foo.sh" "echo A" "Routed-Through: software-engineer")
    sha_B=$(make_case B "scripts/foo.sh" "echo B" "Routed-Through: architect")
    sha_C=$(make_case C "scripts/foo.sh" "echo C" "NONE")
    sha_D=$(make_case D "docs/OPEN_QUESTIONS.md" "x" "Routed-Through: tool-bridge:agent-push")
    sha_E=$(make_case E "scripts/foo.sh" "echo E" "Routed-Through: tool-bridge:agent-push")
    sha_F=$(make_case F "docs/OPEN_QUESTIONS.md" "y" "Routed-Through: tool-bridge:rebase")
    sha_G=$(make_case G "CUSTOMER_NOTES.md" "note" "Routed-Through: researcher")
    sha_H=$(make_case H "CUSTOMER_NOTES.md" "note2" "Routed-Through: software-engineer")

    # Run lint_commit per case into independent report files so we can
    # assert on each commit's findings individually.
    check_case() {
        cid="$1"; sha="$2"; expected_pid="$3"
        : > "$REPORTFILE"
        lint_commit "$sha"
        actual=$(cat "$REPORTFILE")
        if [ "$expected_pid" = "PASS" ]; then
            if [ -z "$actual" ]; then
                printf 'OK case %s (%s) → PASS\n' "$cid" "$(printf '%s' "$sha" | cut -c 1-8)"
            else
                printf 'FAIL case %s (%s) → expected PASS, got:\n%s\n' "$cid" "$sha" "$actual"
                rc=1
            fi
        else
            if printf '%s' "$actual" | grep -q ": $expected_pid:"; then
                printf 'OK case %s (%s) → %s\n' "$cid" "$(printf '%s' "$sha" | cut -c 1-8)" "$expected_pid"
            else
                printf 'FAIL case %s (%s) → expected %s, got:\n%s\n' "$cid" "$sha" "$expected_pid" "$actual"
                rc=1
            fi
        fi
    }

    check_case A "$sha_A" "PASS"   # software-engineer on scripts/foo.sh
    check_case B "$sha_B" "R3"     # architect on scripts/foo.sh
    check_case C "$sha_C" "R1"     # no trailer
    check_case D "$sha_D" "PASS"   # tool-bridge:agent-push on OPEN_QUESTIONS.md
    check_case E "$sha_E" "R4"     # tool-bridge:agent-push on scripts/foo.sh
    check_case F "$sha_F" "PASS"   # tool-bridge:rebase (zero-net-content)
    check_case G "$sha_G" "PASS"   # researcher on CUSTOMER_NOTES.md
    check_case H "$sha_H" "R5"     # software-engineer on CUSTOMER_NOTES.md

    # Restore.
    REPO_ROOT="$SAVED_REPO_ROOT"
    if [ -n "$REPORTFILE_SAVED" ]; then
        REPORTFILE="$REPORTFILE_SAVED"
    fi

    if [ "$rc" -eq 0 ]; then
        printf 'lint-routing self-test: PASS\n'
    else
        printf 'lint-routing self-test: FAIL\n' >&2
    fi
    return "$rc"
}

if [ "$SELF_TEST_MODE" -eq 1 ]; then
    _self_test
    exit $?
fi

# ----- Build commit list --------------------------------------------------

COMMITSFILE="$(mktemp)"
REPORTFILE="$(mktemp)"
# shellcheck disable=SC2064
trap "rm -f \"$COMMITSFILE\" \"$REPORTFILE\"" EXIT INT TERM HUP

if [ -n "$FILES_ARG" ]; then
    # Explicit SHA list.
    for s in $FILES_ARG; do
        printf '%s\n' "$s" >> "$COMMITSFILE"
    done
elif [ -n "$SINCE_SHA" ] && [ "$SINCE_SHA" != "DEFERRED_SET_AT_HARDGATE_PR" ]; then
    # All non-merge commits since SHA. We deliberately do NOT use
    # --no-merges here because we still want to *visit* merge commits
    # and skip them inside lint_commit (so the merge-skip logic stays
    # in one place).
    if git -C "$REPO_ROOT" cat-file -e "$SINCE_SHA^{commit}" 2>/dev/null; then
        git -C "$REPO_ROOT" rev-list "$SINCE_SHA"..HEAD > "$COMMITSFILE" 2>/dev/null || :
    else
        # SHA not in repo (e.g. placeholder) — degrade to "no commits"
        # so warning-only mode stays quiet rather than 2-exiting.
        : > "$COMMITSFILE"
    fi
else
    # Default: last 50 commits on HEAD.
    git -C "$REPO_ROOT" rev-list --max-count=50 HEAD > "$COMMITSFILE" 2>/dev/null || :
fi

while IFS= read -r SHA; do
    [ -n "$SHA" ] || continue
    lint_commit "$SHA"
done < "$COMMITSFILE"

# ----- Report + exit ------------------------------------------------------

if [ -s "$REPORTFILE" ]; then
    cat "$REPORTFILE"
fi
N_TOTAL=$(wc -l < "$REPORTFILE" | tr -d ' ')

if [ "$HARD_GATE" -eq 1 ]; then
    if [ "$SUMMARY" -eq 1 ]; then
        printf 'lint-routing: 0 warnings, %s errors\n' "$N_TOTAL"
    fi
    if [ "$N_TOTAL" -gt 0 ]; then
        printf 'lint-routing: hard-gate FAIL (%s violation(s))\n' "$N_TOTAL" >&2
        exit 1
    fi
    exit 0
else
    if [ "$N_TOTAL" -gt 0 ]; then
        printf 'lint-routing: WARN %s violation(s); hard-gate not yet active (HARDGATE_AFTER_SHA=%s)\n' \
            "$N_TOTAL" "$HARDGATE_AFTER_SHA" >&2
    fi
    if [ "$SUMMARY" -eq 1 ]; then
        printf 'lint-routing: %s warnings, 0 errors\n' "$N_TOTAL"
    fi
    exit 0
fi
