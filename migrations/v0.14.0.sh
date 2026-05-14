#!/usr/bin/env bash
#
# migrations/v0.14.0.sh — upgrade TO v0.14.0 (or any v0.14.x).
#
# v0.14.0 introduces TEMPLATE_MANIFEST.lock (per FW-ADR-0002): a per-file
# SHA256 manifest at project root, used by `scripts/upgrade.sh
# --verify` for offline drift / tamper detection.
#
# This migration synthesises the manifest by **predicting the post-sync
# state** using the same 3-way compare upgrade.sh's sync loop performs.
# That way a single upgrade run produces a correct manifest regardless
# of the version of upgrade.sh the project starts with — including
# v0.13.x projects whose upgrade.sh has no post-sync manifest_write
# step.
#
# Prediction per file:
#   - file in WORKDIR_NEW but not in PROJECT_ROOT       → sync will
#     add it; predicted SHA = WORKDIR_NEW SHA.
#   - file in both, baseline available, project SHA ==
#     WORKDIR_OLD SHA (unchanged since scaffold)        → sync will
#     overwrite; predicted SHA = WORKDIR_NEW SHA.
#   - file in both, baseline available, project SHA !=
#     WORKDIR_OLD SHA (customisation since scaffold)    → sync will
#     leave alone (conflict / kept); predicted SHA =
#     project's current SHA.
#   - file in both, no baseline                          → conservative:
#     treat as customisation; predicted SHA = project's current SHA.
#
# After the actual sync, real on-disk SHAs match these predictions, so
# `scripts/upgrade.sh --verify` exits 0 even on projects whose
# upgrade.sh predates v0.14.0's post-sync manifest_write step.
# v0.14.x+ upgrade.sh's post-sync manifest_write rewrites the manifest
# with the real post-sync SHAs — same result, double-checked.
#
# Idempotency: if the manifest already exists, leave it alone.

set -euo pipefail

: "${PROJECT_ROOT:?PROJECT_ROOT is required}"
: "${WORKDIR_NEW:?WORKDIR_NEW is required}"

# Pre-bootstrap: atomic-replace project's scripts/upgrade.sh + scripts/lib/*
# with the candidate's versions BEFORE the calling v0.x upgrade.sh's sync
# loop runs. Pre-v0.15.0 upgrade.sh lacks self-bootstrap, so its sync loop
# would otherwise `cp` over scripts/upgrade.sh while bash is reading it —
# corrupting the running script and producing arbitrary crashes mid-loop
# (observed as `line N: y: command not found`-style errors picked up from
# the byte offset of a comment in the candidate). Atomic mv-rename leaves
# the parent bash's open fd on the original (now-unlinked) inode, so the
# running v0.x script reads its original content to EOF without seeing the
# replacement; the sync loop then sees cmp-equal between $new_path and
# $proj_path and skips the cp altogether.
#
# FW-ADR-0010 (issue #170): apply the 3-SHA decision matrix here too.
# Refuse-on-uncertain when project carries local edits or the baseline is
# unreachable. SWDT_PREBOOTSTRAP_FORCE=1 is the operator's self-service
# override (audit-logged to docs/pm/pre-release-gate-overrides.md).
#
# Idempotent: re-running on the same project state produces the same
# block artefact (timestamp aside) or proceeds with no work.

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

# shellcheck disable=SC2034
oldIFS="$IFS"
IFS='
'
for rel in $prebootstrap_paths; do
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
done
IFS="$oldIFS"

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
        IFS='
'
        for entry in $blocked_list; do
            [ -z "$entry" ] && continue
            # entry: action:reason:path:project_sha:baseline_sha:upstream_sha
            action=$(printf '%s' "$entry" | cut -d: -f1)
            reason=$(printf '%s' "$entry" | cut -d: -f2)
            path=$(printf '%s' "$entry" | cut -d: -f3)
            row="| $date_iso | pre-bootstrap | (migration v0.14.0) | | $operator | ${reason}:${path} ($force_reason) | |"
            printf '%s\n' "$row" >> "$override_log"
            printf 'WARN: SWDT_PREBOOTSTRAP_FORCE=1 — overriding pre-bootstrap block on %s (reason=%s, action=%s)\n' "$path" "$reason" "$action" >&2
            # Promote to proceed.
            proceed_list="$proceed_list
$path"
        done
        IFS="$oldIFS"
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
            IFS='
'
            for entry in $sorted_entries; do
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
            done
            IFS="$oldIFS"
            printf '\n  ]\n}\n'
        } > "$tmp_artefact"
        mv "$tmp_artefact" "$prebootstrap_block_artefact"

        printf '\nERROR: pre-bootstrap refused — bootstrap-critical files carry local edits or an unreachable baseline.\n' >&2
        IFS='
'
        for entry in $blocked_list; do
            [ -z "$entry" ] && continue
            action=$(printf '%s' "$entry" | cut -d: -f1)
            reason=$(printf '%s' "$entry" | cut -d: -f2)
            path=$(printf '%s' "$entry" | cut -d: -f3)
            printf '  %s: reason=%s\n' "$path" "$reason" >&2
        done
        IFS="$oldIFS"
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
IFS='
'
for rel in $proceed_list; do
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
        echo "  pre-bootstrapped scripts/upgrade.sh to candidate (cross-MAJOR safe)"
    fi
done
IFS="$oldIFS"

# Clear any stale block artefact from a prior refused run.
rm -f "$prebootstrap_block_artefact"

manifest="$PROJECT_ROOT/TEMPLATE_MANIFEST.lock"

if [[ -f "$manifest" ]]; then
  echo "  TEMPLATE_MANIFEST.lock exists — leaving it (will be rewritten post-sync)"
  exit 0
fi

# v0.14.0 ships scripts/lib/manifest.sh; pre-v0.14.0 projects don't
# have it locally yet, so we source from the upgrade-time clone of
# upstream.
# shellcheck source=scripts/lib/manifest.sh
# shellcheck disable=SC1091
source "$WORKDIR_NEW/scripts/lib/manifest.sh"

# Collect baseline SHAs if WORKDIR_OLD is available.
declare -A baseline_sha=()
baseline_label="(unavailable)"
if [[ -n "${WORKDIR_OLD:-}" && -d "$WORKDIR_OLD" ]]; then
  baseline_label="WORKDIR_OLD ($OLD_VERSION)"
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    baseline_sha["$f"]="$(manifest_file_sha "$WORKDIR_OLD/$f")"
  done < <(manifest_ship_files "$WORKDIR_OLD")
fi

added=0
upgraded=0
kept=0
total=0

{
  echo "# TEMPLATE_MANIFEST.lock — per FW-ADR-0002"
  echo "# Generated $(date -u +%Y-%m-%dT%H:%M:%SZ) by migrations/v0.14.0.sh"
  echo "# Format: <sha256>  <project-relative path>"
  echo "# Predicted post-sync state (3-way compare against baseline=$baseline_label)."
  echo "# Files in .template-customizations are omitted by design."
  echo "#"
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    total=$((total+1))
    new_sha="$(manifest_file_sha "$WORKDIR_NEW/$f")"
    if [[ ! -f "$PROJECT_ROOT/$f" ]]; then
      # Sync will add this file from upstream.
      printf '%s  %s\n' "$new_sha" "$f"
      added=$((added+1))
    elif [[ -n "${baseline_sha[$f]:-}" ]]; then
      proj_sha="$(manifest_file_sha "$PROJECT_ROOT/$f")"
      if [[ "$proj_sha" == "${baseline_sha[$f]}" ]]; then
        # Unchanged since scaffold — sync will overwrite.
        printf '%s  %s\n' "$new_sha" "$f"
        upgraded=$((upgraded+1))
      else
        # Customised — sync will leave the project file alone.
        printf '%s  %s\n' "$proj_sha" "$f"
        kept=$((kept+1))
      fi
    else
      # No baseline — conservative: treat as customisation.
      proj_sha="$(manifest_file_sha "$PROJECT_ROOT/$f")"
      printf '%s  %s\n' "$proj_sha" "$f"
      kept=$((kept+1))
    fi
  done < <(manifest_ship_files "$WORKDIR_NEW" "$PROJECT_ROOT")
} > "$manifest"

echo "  synthesised TEMPLATE_MANIFEST.lock — predicted post-sync state ($total entries)"
echo "    +$added (will be added) ~$upgraded (will be upgraded) !$kept (customisations kept)"
echo "    baseline: $baseline_label"
