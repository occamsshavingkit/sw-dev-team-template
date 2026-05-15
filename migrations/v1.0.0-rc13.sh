#!/usr/bin/env bash
#
# migrations/v1.0.0-rc13.sh — pre-bootstrap for rc-to-rc structural-rewrite
# cliffs in the v1.x lineage (per FW-ADR-0013).
#
# Failure class this migration closes (dogfood-2026-05-15, blocker #1):
#   A downstream stamped at v1.0.0-rc2 upgrading to v1.0.0-rc12 crashes mid-run
#   with `./scripts/upgrade.sh: line 205: syntax error near unexpected token
#   ';;'`. The rc2-era upgrade.sh is ~270 lines, has no `case` statement, and
#   no SWDT_BOOTSTRAPPED self-bootstrap branch (added in v0.15.0 /
#   FW-ADR-0010). When the rc2 driver's sync loop overwrites scripts/upgrade.sh
#   on disk with the rc12 candidate (which has both `case` and `;;` tokens
#   around line 205), bash continues parsing from its current byte offset and
#   explodes on the structurally-incompatible token.
#
#   v0.14.0.sh closed the equivalent v0.x → v1.x cliff with the same trick.
#   But v0.14.0.sh only fires when OLD_VERSION < v0.14.0; on rc2 → rc12 the
#   project is already past v0.14.0, so no pre-bootstrap fires at all. This
#   migration covers the rc-to-rc gap below v1.0.0-rc13.
#
# What this migration does:
#   Atomic-replaces scripts/upgrade.sh + scripts/lib/*.sh from $WORKDIR_NEW
#   into $PROJECT_ROOT BEFORE the OLD driver's sync loop runs. The migration
#   runner (scripts/upgrade.sh lines ~864-942 in the candidate) sources this
#   file before any sync, so the OLD driver's later `cp` over upgrade.sh sees
#   cmp-equal between $new_path and $proj_path and skips the cp.
#
#   The atomic mv-rename leaves the parent bash's open fd on the original
#   (now-unlinked) inode, so the running v1.x-rcN script reads its original
#   content to EOF without seeing the replacement.
#
# FW-ADR-0010 inheritance (binding):
#   3-SHA decision matrix, refuse-on-uncertain posture,
#   SWDT_PREBOOTSTRAP_FORCE=1 self-service override,
#   SWDT_PREBOOTSTRAP_FORCE_REASON audit annotation,
#   .template-prebootstrap-blocked.json schema v1 block artefact,
#   docs/pm/pre-release-gate-overrides.md audit-log row
#     (Gate=pre-bootstrap, Commit SHA slot = "(migration v1.0.0-rc13)"),
#   retrofit-playbook routing on baseline-unreachable rows.
#
#   Behavioural divergence from FW-ADR-0010 requires a new ADR.
#
# Intentional de-duplication boundary (FW-ADR-0013):
#   The pre-bootstrap logic below is a near-verbatim copy of
#   migrations/v0.14.0.sh lines 42-277. A shared helper at
#   scripts/lib/prebootstrap.sh is NOT extracted because at the moment any
#   pre-bootstrap migration runs, the file in question is exactly what is
#   being installed — neither migration can rely on a shared file being
#   present at the moment it must run. The duplication is cheaper than the
#   abstraction. Do not refactor without superseding FW-ADR-0013.
#
# Idempotency:
#   Re-running on a project whose bootstrap-critical files already match the
#   candidate produces zero writes and exit 0 (the 3-SHA matrix's
#   `project == upstream` branch). Verified by QA.
#
# Cross-migration interaction:
#   On a v0.13.x → rc13 path, v0.14.0.sh runs first and pre-bootstraps. By
#   the time this migration runs, bootstrap-critical files in the project
#   already match $WORKDIR_NEW; the 3-SHA matrix returns `noop` for every
#   path and the migration exits 0 with no writes.

set -euo pipefail

: "${PROJECT_ROOT:?PROJECT_ROOT is required}"
: "${WORKDIR_NEW:?WORKDIR_NEW is required}"

prebootstrap_sha() {
    if [ -f "$1" ]; then
        sha256sum "$1" | awk '{print $1}'
    else
        printf ''
    fi
}

# Build the bootstrap-critical path list: scripts/upgrade.sh + every
# scripts/lib/*.sh the candidate ships.
prebootstrap_paths=""
if [ -f "$WORKDIR_NEW/scripts/upgrade.sh" ]; then
    prebootstrap_paths="scripts/upgrade.sh"
fi
if [ -d "$WORKDIR_NEW/scripts/lib" ]; then
    for lib in "$WORKDIR_NEW/scripts/lib"/*.sh; do
        [ -f "$lib" ] || continue
        prebootstrap_paths="$prebootstrap_paths
scripts/lib/$(basename "$lib")"
    done
fi

baseline_dir=""
if [ -n "${WORKDIR_OLD:-}" ] && [ -d "${WORKDIR_OLD:-}" ]; then
    baseline_dir="$WORKDIR_OLD"
fi

# Build two parallel newline-delimited lists: blocked (refused) paths
# (action:reason:path:project_sha:baseline_sha:upstream_sha) and proceed
# paths (path).
blocked_list=""
proceed_list=""
any_block=0
saw_local_edit=0
saw_baseline_unreachable=0

# Iterate the newline-delimited path list via `while IFS= read -r` (the
# per-command IFS prefix is local to read and does NOT modify the global
# IFS — Semgrep ifs-tampering rule ignores it). Process substitution
# (`< <(...)`) keeps the loop in the parent shell so variable mutations
# propagate. Same idiom is used throughout scripts/* in this repo.
while IFS= read -r rel; do
    [ -z "$rel" ] && continue
    proj_file="$PROJECT_ROOT/$rel"
    new_file="$WORKDIR_NEW/$rel"
    proj_sha=$(prebootstrap_sha "$proj_file")
    new_sha=$(prebootstrap_sha "$new_file")
    base_sha=""
    if [ -n "$baseline_dir" ]; then
        base_sha=$(prebootstrap_sha "$baseline_dir/$rel")
    fi

    # Missing locally: treat as add-from-upstream (proceed).
    if [ -z "$proj_sha" ]; then
        proceed_list="$proceed_list
$rel"
        continue
    fi

    if [ -n "$base_sha" ]; then
        if [ "$proj_sha" = "$base_sha" ]; then
            if [ "$proj_sha" = "$new_sha" ]; then
                : # noop
            else
                proceed_list="$proceed_list
$rel"
            fi
        else
            if [ "$proj_sha" = "$new_sha" ]; then
                : # noop — operator already at upstream
            else
                blocked_list="$blocked_list
refuse:local-edit:$rel:$proj_sha:$base_sha:$new_sha"
                any_block=1
                saw_local_edit=1
            fi
        fi
    else
        if [ "$proj_sha" = "$new_sha" ]; then
            : # noop
        else
            blocked_list="$blocked_list
retrofit:baseline-unreachable:$rel:$proj_sha::$new_sha"
            any_block=1
            saw_baseline_unreachable=1
        fi
    fi
done < <(printf '%s\n' "$prebootstrap_paths")

prebootstrap_block_artefact="$PROJECT_ROOT/.template-prebootstrap-blocked.json"

if [ "$any_block" -eq 1 ]; then
    if [ "$saw_local_edit" -eq 1 ] && [ "$saw_baseline_unreachable" -eq 1 ]; then
        reason_summary="mixed"
    elif [ "$saw_local_edit" -eq 1 ]; then
        reason_summary="local-edit"
    else
        reason_summary="baseline-unreachable"
    fi

    if [ "${SWDT_PREBOOTSTRAP_FORCE:-}" = "1" ]; then
        override_log="$PROJECT_ROOT/docs/pm/pre-release-gate-overrides.md"
        if [ ! -w "$override_log" ]; then
            printf 'ERROR: SWDT_PREBOOTSTRAP_FORCE=1 set, but %s is unwritable.\n' "$override_log" >&2
            printf '       Refusing to bypass without an audit row. Fix permissions and re-run.\n' >&2
            exit 2
        fi
        date_iso=$(date -u +%Y-%m-%d)
        operator=$(git config user.email 2>/dev/null || echo "${USER:-unknown}@$(hostname 2>/dev/null || echo unknown)")
        force_reason="${SWDT_PREBOOTSTRAP_FORCE_REASON:-unspecified}"
        while IFS= read -r entry; do
            [ -z "$entry" ] && continue
            # entry: action:reason:path:project_sha:baseline_sha:upstream_sha
            action=$(printf '%s' "$entry" | cut -d: -f1)
            reason=$(printf '%s' "$entry" | cut -d: -f2)
            path=$(printf '%s' "$entry" | cut -d: -f3)
            row="| $date_iso | pre-bootstrap | (migration v1.0.0-rc13) | | $operator | ${reason}:${path} ($force_reason) | |"
            printf '%s\n' "$row" >> "$override_log"
            printf 'WARN: SWDT_PREBOOTSTRAP_FORCE=1 — overriding pre-bootstrap block on %s (reason=%s, action=%s)\n' "$path" "$reason" "$action" >&2
            # Promote to proceed.
            proceed_list="$proceed_list
$path"
        done < <(printf '%s\n' "$blocked_list")
        printf 'WARN: pre-bootstrap audit row(s) appended to %s\n' "$override_log" >&2
        rm -f "$prebootstrap_block_artefact"
    else
        # Write block artefact atomically.
        tmp_artefact=$(mktemp "$prebootstrap_block_artefact.tmp.XXXXXX")
        {
            printf '{\n'
            printf '  "version": 1,\n'
            printf '  "generated": "%s",\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
            printf '  "reason_summary": "%s",\n' "$reason_summary"
            printf '  "blocked": [\n'
            # Sort entries by path for determinism.
            sorted_entries=$(printf '%s' "$blocked_list" | awk -F: 'NF { print $3 "|" $0 }' | LC_ALL=C sort | sed 's/^[^|]*|//')
            first=1
            while IFS= read -r entry; do
                [ -z "$entry" ] && continue
                action=$(printf '%s' "$entry" | cut -d: -f1)
                reason=$(printf '%s' "$entry" | cut -d: -f2)
                path=$(printf '%s' "$entry" | cut -d: -f3)
                proj_sha=$(printf '%s' "$entry" | cut -d: -f4)
                base_sha=$(printf '%s' "$entry" | cut -d: -f5)
                new_sha=$(printf '%s' "$entry" | cut -d: -f6)
                reason_field="local-edit"
                [ "$action" = "retrofit" ] && reason_field="baseline-unreachable"
                if [ "$first" -eq 0 ]; then printf ',\n'; fi
                printf '    {\n'
                printf '      "path": "%s",\n' "$path"
                printf '      "project_sha": "%s",\n' "$proj_sha"
                printf '      "baseline_sha": "%s",\n' "$base_sha"
                printf '      "upstream_sha": "%s",\n' "$new_sha"
                printf '      "reason": "%s"\n' "$reason_field"
                printf '    }'
                first=0
            done < <(printf '%s\n' "$sorted_entries")
            printf '\n  ]\n}\n'
        } > "$tmp_artefact"
        mv "$tmp_artefact" "$prebootstrap_block_artefact"

        printf '\nERROR: pre-bootstrap refused — bootstrap-critical files carry local edits or an unreachable baseline.\n' >&2
        while IFS= read -r entry; do
            [ -z "$entry" ] && continue
            action=$(printf '%s' "$entry" | cut -d: -f1)
            reason=$(printf '%s' "$entry" | cut -d: -f2)
            path=$(printf '%s' "$entry" | cut -d: -f3)
            printf '  %s: reason=%s\n' "$path" "$reason" >&2
        done < <(printf '%s\n' "$blocked_list")
        printf '\nBlock artefact: %s\n' "$prebootstrap_block_artefact" >&2
        printf 'Recovery:\n' >&2
        printf '  - Review the listed paths; declare deliberate local edits in .template-customizations.\n' >&2
        printf '  - For baseline-unreachable rows, follow the retrofit playbook:\n' >&2
        printf '      docs/templates/retrofit-playbook-template.md\n' >&2
        printf '  - To bypass (atomic-replace every blocked path, audit-logged):\n' >&2
        printf '      SWDT_PREBOOTSTRAP_FORCE=1 scripts/upgrade.sh ...\n' >&2
        printf '    (Optionally set SWDT_PREBOOTSTRAP_FORCE_REASON=<note> for the audit row.)\n' >&2
        exit 2
    fi
fi

# Execute the proceed list (atomic install).
while IFS= read -r rel; do
    [ -z "$rel" ] && continue
    new_file="$WORKDIR_NEW/$rel"
    proj_file="$PROJECT_ROOT/$rel"
    [ -f "$new_file" ] || continue
    case "$rel" in
        scripts/lib/*)
            mkdir -p "$PROJECT_ROOT/scripts/lib"
            ;;
    esac
    if [ -x "$new_file" ]; then
        install -m 0755 "$new_file" "$proj_file"
    else
        install -m 0644 "$new_file" "$proj_file"
    fi
    if [ "$rel" = "scripts/upgrade.sh" ]; then
        echo "  pre-bootstrapped scripts/upgrade.sh to candidate (rc-to-rc structural-rewrite safe)"
    fi
done < <(printf '%s\n' "$proceed_list")

# Clear any stale block artefact from a prior refused run.
rm -f "$prebootstrap_block_artefact"

exit 0
