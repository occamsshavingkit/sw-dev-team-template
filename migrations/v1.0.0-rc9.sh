#!/bin/sh
#
# migrations/v1.0.0-rc9.sh — upgrade TO v1.0.0-rc9.
#
# rc9 introduced schemas/agent-contract.schema.json with new required
# sections: `role_overview`, `hard_rules`, `escalation`, and
# `output_format`. Downstream projects that customised canonical
# agents under rc6/rc7/rc8 may lack `## Hard rules` or `## Output
# format` sections; the upgrade auto-merges those customisations as
# "accepted local merges" without surfacing the schema regression,
# and the first lint-agent-contracts.sh run after upgrade then fails.
#
# This migration walks .claude/agents/*.md (excluding sme-template.md,
# per-project SMEs sme-*.md, and -local.md supplements), checks for
# the required sections using the same slug-mapping table as
# scripts/compile-runtime-agents.sh (case-insensitive, synonyms
# accepted), and backfills missing sections from the rc9-shipped
# version of the same canonical role when possible. The backfill is
# inserted after `## Escalation` (or `## Hand-offs` / `## Escalation
# format`) when present, otherwise appended at end of file.
#
# Idempotent: if a section already exists (under any accepted
# synonym), no action is taken for that section. Re-running the
# migration produces no further changes.
#
# Issue: upstream #141.
#
# Env vars from scripts/upgrade.sh:
#   PROJECT_ROOT   — absolute path to the downstream project root
#   WORKDIR_NEW    — clone of upstream at NEW_VERSION (rc9 ship)
#   TARGET_VERSION — this migration's attached version (v1.0.0-rc9)

# Note on shell options: we use `set -u` (fail on unset variables) but
# deliberately do NOT use `set -e`. The body of this migration contains
# pipelines whose last component is a probe (`grep -q ... || ...`) where
# a non-zero pipe exit is part of normal control flow. Under `set -e`
# those pipelines (and command-substitution patterns like
# `var=$(fn_with_while_loop)`) can short-circuit the script silently.
# Idempotency + explicit return-value handling cover the safety that
# errexit would have given us.
set -u
LANG=C
LC_ALL=C
export LANG LC_ALL

: "${PROJECT_ROOT:?PROJECT_ROOT is required}"

agents_dir="$PROJECT_ROOT/.claude/agents"
decisions_log="$PROJECT_ROOT/docs/DECISIONS.md"

# Upstream rc9 ship for sourcing reference section bodies. May be unset
# when this script is run standalone (e.g., during the self-test); in
# that case we fall back to a placeholder body that points at the
# git-show recovery command.
upstream_agents=""
if [ -n "${WORKDIR_NEW:-}" ] && [ -d "${WORKDIR_NEW}/.claude/agents" ]; then
    upstream_agents="${WORKDIR_NEW}/.claude/agents"
fi

if [ ! -d "$agents_dir" ]; then
    echo "  v1.0.0-rc9 migration: no .claude/agents/ directory; nothing to do."
    exit 0
fi

# ---- section-heading normalisation + slug mapping --------------------
# Verbatim derivation of map_section() in
# scripts/compile-runtime-agents.sh. Same accepted-synonyms table.
normalize_heading() {
    printf '%s' "$1" \
        | tr '[:upper:]' '[:lower:]' \
        | sed -e 's/([^)]*)//g' \
              -e 's/[^a-z0-9]\{1,\}/ /g' \
              -e 's/^ *//' \
              -e 's/ *$//'
}

map_section() {
    norm="$1"
    case "${norm}" in
        "role overview"|"job"|"two modes"|"overview")
            echo "role_overview" ;;
        "hard rules"|"hard block conditions"|"enforcement"|"constraints")
            echo "hard_rules" ;;
        "escalation"|"escalation protocol"|"escalation format"|"hand offs"|"handoffs")
            echo "escalation" ;;
        "output"|"output format"|"customer facing output discipline")
            echo "output_format" ;;
        *)
            echo "" ;;
    esac
}

# ---- helpers ---------------------------------------------------------

# List the canonical-slug set already present in a given file.
# Emits one slug per line. Sections that map to a slug not in our
# tracked set are dropped.
file_slugs() {
    src="$1"
    awk '/^## / { sub(/^## /, ""); sub(/[ \t]+$/, ""); print }' "$src" \
        | while IFS= read -r heading; do
            [ -z "$heading" ] && continue
            norm=$(normalize_heading "$heading")
            slug=$(map_section "$norm")
            [ -n "$slug" ] && echo "$slug"
        done
}

# Extract the body of the FIRST section whose canonical-mapped slug
# matches the requested target slug. Used to lift `## Hard rules` /
# `## Output` content out of the rc9-shipped upstream file.
extract_section_by_slug() {
    src="$1"
    want="$2"
    awk -v want="$want" '
        function norm(s) {
            s = tolower(s)
            gsub(/\([^)]*\)/, "", s)
            gsub(/[^a-z0-9]+/, " ", s)
            sub(/^ +/, "", s); sub(/ +$/, "", s)
            return s
        }
        function map_slug(n) {
            if (n == "role overview" || n == "job" || n == "two modes" || n == "overview") return "role_overview"
            if (n == "hard rules" || n == "hard block conditions" || n == "enforcement" || n == "constraints") return "hard_rules"
            if (n == "escalation" || n == "escalation protocol" || n == "escalation format" || n == "hand offs" || n == "handoffs") return "escalation"
            if (n == "output" || n == "output format" || n == "customer facing output discipline") return "output_format"
            return ""
        }
        /^## / {
            heading = $0
            sub(/^## /, "", heading)
            sub(/[ \t]+$/, "", heading)
            slug = map_slug(norm(heading))
            if (capturing) { exit }
            if (slug == want) {
                capturing = 1
                print $0
                next
            }
            next
        }
        capturing { print }
    ' "$src"
}

# Placeholder body — used when WORKDIR_NEW is unavailable or the
# upstream file lacks the requested section.
placeholder_body() {
    section="$1"   # "Hard rules" | "Output format"
    role_file="$2" # e.g. .claude/agents/sre.md
    printf '## %s\n\n' "$section"
    printf -- '- **TODO**: the rc9 agent-contract schema requires this section.\n'
    printf -- '  Backfill with the canonical content from the rc9-shipped\n'
    # shellcheck disable=SC2016
    # `%s` here is a printf format-string conversion (substitutes
    # $role_file), not a shell variable. Single-quoting is required so
    # the backticks render literally in the output.
    printf -- '  version of this role (e.g., `git show v1.0.0-rc9:%s`).\n' "$role_file"
}

# Insert the supplied body block AFTER the last existing
# `## Escalation` / `## Hand-offs ...` / `## Escalation format`
# section (whichever appears last by file order). If no such anchor
# exists, append at end of file. Returns 0 on success.
insert_after_escalation() {
    target="$1"
    body_file="$2"
    workfile=$(mktemp)

    # Find the line number of the LAST `## ` heading whose normalised
    # text maps to the `escalation` slug. If none, anchor = EOF.
    anchor_line=$(awk '
        /^## / {
            h = $0
            sub(/^## /, "", h); sub(/[ \t]+$/, "", h)
            n = tolower(h)
            gsub(/\([^)]*\)/, "", n)
            gsub(/[^a-z0-9]+/, " ", n)
            sub(/^ +/, "", n); sub(/ +$/, "", n)
            if (n == "escalation" || n == "escalation protocol" ||
                n == "escalation format" || n == "hand offs" || n == "handoffs") {
                last = NR
            }
        }
        END { if (last) print last }
    ' "$target")

    if [ -n "$anchor_line" ]; then
        # Find the end of that anchored section: next `## ` heading
        # after $anchor_line, or EOF.
        next_section=$(awk -v start="$anchor_line" '
            NR > start && /^## / { print NR; exit }
        ' "$target")

        if [ -n "$next_section" ]; then
            cut_at=$((next_section - 1))
            # Print 1..cut_at, then injected body (with leading blank
            # line separator), then cut_at+1..EOF.
            head -n "$cut_at" "$target" > "$workfile"
            printf '\n' >> "$workfile"
            cat "$body_file" >> "$workfile"
            tail -n +"$next_section" "$target" >> "$workfile"
        else
            # Anchor exists, runs to EOF. Append after.
            cat "$target" > "$workfile"
            # Ensure a trailing newline + separator before the new section.
            tail -c 1 "$target" | od -An -c | grep -q '\\n' || printf '\n' >> "$workfile"
            printf '\n' >> "$workfile"
            cat "$body_file" >> "$workfile"
        fi
    else
        # No escalation anchor; append at end of file with separator.
        cat "$target" > "$workfile"
        tail -c 1 "$target" | od -An -c | grep -q '\\n' || printf '\n' >> "$workfile"
        printf '\n' >> "$workfile"
        cat "$body_file" >> "$workfile"
    fi

    mv "$workfile" "$target"
}

ensure_decisions_log() {
    if [ ! -f "$decisions_log" ]; then
        mkdir -p "$(dirname "$decisions_log")"
        printf '# Decisions log — append-only\n\n' > "$decisions_log"
    fi
}

append_decision() {
    msg="$1"
    ensure_decisions_log
    # Idempotency: don't double-write the same line.
    if grep -F -q -- "$msg" "$decisions_log" 2>/dev/null; then
        return 0
    fi
    printf '%s\n' "$msg" >> "$decisions_log"
}

# ---- walk + backfill -------------------------------------------------
#
# Only operate on canonical agents the project has CUSTOMISED (i.e.,
# paths listed in `.template-customizations`). Files not in that list
# are overwritten by the ship sync that runs immediately after this
# migration in scripts/upgrade.sh, so the rc9-canonical Hard rules and
# Output format sections will arrive automatically — modifying them
# here would create a spurious local-delta that the 3-way merge then
# flags as a conflict (regression observed in rc3->rc9 smoke; see
# issue #141 follow-up in PR #157).

customizations_file="$PROJECT_ROOT/.template-customizations"
preserved_agents=""
if [ -f "$customizations_file" ]; then
    preserved_agents=$(grep -E '^\.claude/agents/[^/]+\.md$' "$customizations_file" 2>/dev/null || true)
fi
if [ -z "$preserved_agents" ]; then
    echo "migrations/v1.0.0-rc9.sh: 0 files backfilled, 0 files already current (no customised canonical agents)."
    exit 0
fi

backfilled=0
already_current=0

# shellcheck disable=SC2034  # iterated by relative path, not glob
for rel in $preserved_agents; do
    f="$PROJECT_ROOT/$rel"
    [ -f "$f" ] || continue

    base=$(basename "$f")
    # Skip per-project SMEs and -local supplements.
    case "$base" in
        sme-template.md) continue ;;
        sme-*.md)        continue ;;
        *-local.md)      continue ;;
    esac

    # Determine which required sections (of the two added by rc9 that
    # downstream customisation tends to drop) are missing. role_overview
    # + escalation are not in this migration's scope — they were
    # already required in pre-rc9 versions and are unlikely to be
    # missing from a customised file; auto-injecting them blindly
    # would risk overwriting legitimate body content. This migration
    # is bounded to the rc9-new requirements: hard_rules + output_format.
    present=$(file_slugs "$f")

    missing=""
    echo "$present" | grep -q '^hard_rules$' || missing="$missing hard_rules"
    echo "$present" | grep -q '^output_format$' || missing="$missing output_format"
    # Trim leading space.
    missing=$(printf '%s' "$missing" | sed 's/^ *//')

    if [ -z "$missing" ]; then
        already_current=$((already_current + 1))
        continue
    fi

    # Stderr advisory per the issue contract.
    # shellcheck disable=SC2086
    # nosemgrep: bash.lang.correctness.unquoted-expansion.unquoted-variable-expansion-in-command
    # $missing is a deliberately whitespace-separated list of section
    # slugs (built above via "$missing $slug"); word-splitting is the
    # intended behaviour so `printf ' %s'` emits one space-prefixed
    # token per slug.
    echo "MIGRATION: $base missing section(s):$(printf ' %s' $missing)" >&2

    for slug in $missing; do
        case "$slug" in
            hard_rules)    section_label="Hard rules" ;;
            output_format) section_label="Output format" ;;
            *)             continue ;;
        esac

        body_file=$(mktemp)
        sourced_from_upstream=0
        if [ -n "$upstream_agents" ] && [ -f "$upstream_agents/$base" ]; then
            extract_section_by_slug "$upstream_agents/$base" "$slug" > "$body_file"
            if [ -s "$body_file" ]; then
                sourced_from_upstream=1
            fi
        fi

        if [ "$sourced_from_upstream" -eq 0 ]; then
            placeholder_body "$section_label" ".claude/agents/$base" > "$body_file"
        fi

        # Ensure the body ends with a single newline.
        tail -c 1 "$body_file" | od -An -c | grep -q '\\n' || printf '\n' >> "$body_file"

        insert_after_escalation "$f" "$body_file"
        rm -f "$body_file"

        if [ "$sourced_from_upstream" -eq 1 ]; then
            append_decision "M9 rc9 migration: backfilled ${section_label} for .claude/agents/$base from upstream rc9 ship."
        else
            append_decision "M9 rc9 migration: backfilled ${section_label} placeholder for .claude/agents/$base (upstream rc9 ship not reachable during migration; manual fill required)."
        fi
    done

    backfilled=$((backfilled + 1))
done

echo "migrations/v1.0.0-rc9.sh: $backfilled files backfilled, $already_current files already current."
