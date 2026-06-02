#!/usr/bin/env bash
#
# migrations/v1.0.0-rc14.sh — upgrade TO v1.0.0-rc14.
#
# Two-pass shape:
#
#   Pass 1 modes: dry-run (default) / apply (SWDT_PRESERVATION_PRUNE_APPLY=1).
#   Walks .template-customizations and identifies entries that match the
#   upstream baseline byte-for-byte (no divergence) and are therefore inert.
#   Dry-run (default): prints the inert list; no file is rewritten; operator
#   inspects the list. Apply: operator re-runs with SWDT_PRESERVATION_PRUNE_APPLY=1
#   in the environment; rewrites .template-customizations atomically
#   (mktemp + mv), removing the inert lines, preserving comments,
#   blank lines, and entries that diverge from baseline or whose
#   baseline is unreachable (conservative — keep what we cannot prove
#   inert). This was formerly "Pass 2" in the original FW-ADR-0014
#   pruning migration; renumbered here because the schema backfill
#   below is now Pass 2.
#
#   Pass 2 — schema backfill (runs unconditionally). Walks preserved
#   canonical agent files listed in .template-customizations and
#   auto-backfills the hard_rules and output_format sections required
#   by the rc14 contract schema. Idempotent: no-op when both sections
#   are already present. Issue: upstream #261.
#
# Idempotent overall. Re-running produces no further changes once both
# passes have fully applied.
#
# Env vars from scripts/upgrade.sh:
#   PROJECT_ROOT                       — absolute path to project root
#   WORKDIR_NEW                        — clone of upstream at NEW_VERSION
#   WORKDIR_OLD                        — clone of upstream at baseline
#                                        SHA (set when reachable)
#   SWDT_PRESERVATION_PRUNE_APPLY=1    — opt-in: apply the prune rewrite
#                                        instead of dry-run-printing.

set -u
LANG=C
LC_ALL=C
export LANG LC_ALL

: "${PROJECT_ROOT:?PROJECT_ROOT is required}"

cust="$PROJECT_ROOT/.template-customizations"

# ---------------------------------------------------------------------------
# Issue #219: evict docs/pm/token-ledger.md from the git index on downstreams
# that had it committed before the #160 gitignore landed.  The gitignore
# suppresses new additions but does not untrack an already-tracked file.
# --ignore-unmatch makes this a no-op when the file is not tracked (safe to
# re-run; idempotent because untracking an already-untracked path is a no-op).
# ---------------------------------------------------------------------------
git -C "$PROJECT_ROOT" rm --cached --ignore-unmatch docs/pm/token-ledger.md 2>/dev/null || true

# ---------------------------------------------------------------------------
# Pass 1 — FW-ADR-0014 opt-in preserve-list pruning
# ---------------------------------------------------------------------------
_run_pass1() {
  if [ ! -f "$cust" ]; then
    echo "  v1.0.0-rc14 prune: no .template-customizations file; nothing to do."
    return
  fi

  # Baseline reachable? Without WORKDIR_OLD we cannot prove inertness;
  # conservative posture: skip the rewrite entirely and warn.
  if [ -z "${WORKDIR_OLD:-}" ] || [ ! -d "${WORKDIR_OLD:-}" ]; then
    echo "  v1.0.0-rc14 prune: WORKDIR_OLD unset/unreachable — cannot compute" >&2
    echo "    divergence. Skipping. (Conservative posture: nothing pruned.)" >&2
    return
  fi

  # Identify inert entries.
  local inert_entries=()
  while IFS= read -r raw; do
    local trimmed="${raw%%#*}"
    trimmed="$(printf '%s' "$trimmed" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    [ -z "$trimmed" ] && continue
    local proj="$PROJECT_ROOT/$trimmed"
    local base="$WORKDIR_OLD/$trimmed"
    [ -f "$proj" ] || continue
    [ -f "$base" ] || continue
    if cmp -s "$base" "$proj"; then
      inert_entries+=("$trimmed")
    fi
  done < "$cust"

  if [ ${#inert_entries[@]} -eq 0 ]; then
    echo "  v1.0.0-rc14 prune: no inert preserve-list entries found; nothing to do."
    return
  fi

  # Dry-run by default.
  if [ "${SWDT_PRESERVATION_PRUNE_APPLY:-}" != "1" ]; then
    echo "  v1.0.0-rc14 prune (dry-run): ${#inert_entries[@]} inert entry/entries identified:"
    for e in "${inert_entries[@]}"; do
      echo "    - $e"
    done
    echo "  To rewrite .template-customizations, re-run with:"
    echo "    SWDT_PRESERVATION_PRUNE_APPLY=1 scripts/upgrade.sh ..."
    return
  fi

  # Apply pass. Build the new file: keep comments, blanks, and any line
  # whose trimmed value is not in the inert set. Rewrite atomically.
  local tmp
  tmp="$(mktemp "$cust.tmp.XXXXXX")"
  while IFS= read -r raw; do
    local trimmed="${raw%%#*}"
    trimmed="$(printf '%s' "$trimmed" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    if [ -z "$trimmed" ]; then
      # Comment-only or blank line — keep verbatim.
      printf '%s\n' "$raw" >> "$tmp"
      continue
    fi
    local drop=0
    for inert in "${inert_entries[@]}"; do
      if [ "$inert" = "$trimmed" ]; then
        drop=1
        break
      fi
    done
    if [ "$drop" -eq 0 ]; then
      printf '%s\n' "$raw" >> "$tmp"
    fi
  done < "$cust"
  mv "$tmp" "$cust"

  echo "  v1.0.0-rc14 prune (apply): rewrote .template-customizations, dropping ${#inert_entries[@]} inert entry/entries."
  for e in "${inert_entries[@]}"; do
    echo "    - $e"
  done
}

_run_pass1

# ---------------------------------------------------------------------------
# NOTE (operator warning): Pass 2 runs unconditionally; it is NOT gated by
# SWDT_PRESERVATION_PRUNE_APPLY (which only affects pass 1). Idempotency
# (re-run safety) is the operator's dry-run substitute — running this
# migration twice is safe and the second run is a no-op.
# ---------------------------------------------------------------------------
# Pass 2 — backfill hard_rules / output_format in preserved canonical agents
#
# Candidate set: every file in $PROJECT_ROOT/.claude/agents/*.md whose
# relative path appears in .template-customizations AND is a canonical
# agent file (sme-*.md, sme-template.md, and *-local.md are excluded per
# customer ruling 2026-05-20).
#
# For each candidate that is missing hard_rules and/or output_format:
#   1. Extract the section body from the rc14-shipped canonical at
#      $WORKDIR_NEW/.claude/agents/<base>.
#   2. If extraction fails (canonical missing or WORKDIR_NEW unavailable),
#      fall back to a labelled TODO placeholder that satisfies the schema's
#      structural requirements (numbered rule entry for hard_rules, 20+
#      char body for output_format).
#   3. Insert after the escalation block, matching rc9 placement logic.
#   4. Append an audit row to docs/DECISIONS.md.
#
# Idempotent: no-op if both sections are already present.
#
# Issue: upstream #261.
# ---------------------------------------------------------------------------

_rc14_normalize_heading() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -e 's/([^)]*)//g' \
          -e 's/[^a-z0-9]\{1,\}/ /g' \
          -e 's/^ *//' \
          -e 's/ *$//'
}

_rc14_map_section() {
  local norm="$1"
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

_rc14_file_slugs() {
  local src="$1"
  awk '/^## / { sub(/^## /, ""); sub(/[ \t]+$/, ""); print }' "$src" \
    | while IFS= read -r heading; do
        [ -z "$heading" ] && continue
        local norm
        norm=$(_rc14_normalize_heading "$heading")
        local slug
        slug=$(_rc14_map_section "$norm")
        [ -n "$slug" ] && echo "$slug"
      done
}

_rc14_extract_section_by_slug() {
  local src="$1"
  local want="$2"
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

# Placeholder bodies that satisfy the agent-contract schema:
#   hard_rules: numbered rule entry so the lint parser extracts it
#     (pattern: ^[0-9]+\. ); body text >= 10 chars.
#   output_format: body string >= 20 chars.
_rc14_placeholder_hard_rules() {
  local role_file="$1"
  printf '## Hard rules\n\n'
  printf '1. **TODO**: backfill required — rc14 agent-contract schema requires this section.\n'
  # shellcheck disable=SC2016
  printf '   Restore from the rc14-shipped canonical (e.g., `git show v1.0.0-rc14:%s`).\n' "$role_file"
}

_rc14_placeholder_output_format() {
  local role_file="$1"
  printf '## Output format\n\n'
  printf -- '- **TODO**: backfill required — rc14 agent-contract schema requires this section.\n'
  # shellcheck disable=SC2016
  printf '  Restore from the rc14-shipped canonical (e.g., `git show v1.0.0-rc14:%s`).\n' "$role_file"
}

_rc14_insert_after_escalation() {
  local target="$1"
  local body_file="$2"
  local workfile
  workfile=$(mktemp)

  local anchor_line
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
    local next_section
    next_section=$(awk -v start="$anchor_line" '
      NR > start && /^## / { print NR; exit }
    ' "$target")

    if [ -n "$next_section" ]; then
      local cut_at=$(( next_section - 1 ))
      head -n "$cut_at" "$target" > "$workfile"
      printf '\n' >> "$workfile"
      cat "$body_file" >> "$workfile"
      tail -n +"$next_section" "$target" >> "$workfile"
    else
      cat "$target" > "$workfile"
      tail -c 1 "$target" | od -An -c | grep -q '\\n' || printf '\n' >> "$workfile"
      printf '\n' >> "$workfile"
      cat "$body_file" >> "$workfile"
    fi
  else
    cat "$target" > "$workfile"
    tail -c 1 "$target" | od -An -c | grep -q '\\n' || printf '\n' >> "$workfile"
    printf '\n' >> "$workfile"
    cat "$body_file" >> "$workfile"
  fi

  mv "$workfile" "$target"
}

_rc14_decisions_log="$PROJECT_ROOT/docs/DECISIONS.md"

_rc14_ensure_decisions_log() {
  if [ ! -f "$_rc14_decisions_log" ]; then
    mkdir -p "$(dirname "$_rc14_decisions_log")"
    printf '# Decisions log — append-only\n\n' > "$_rc14_decisions_log"
  fi
}

_rc14_append_decision() {
  local msg="$1"
  _rc14_ensure_decisions_log
  if grep -F -q -- "$msg" "$_rc14_decisions_log" 2>/dev/null; then
    return 0
  fi
  printf '%s\n' "$msg" >> "$_rc14_decisions_log"
}

# Determine the upstream agents directory (rc14-shipped canonicals).
_rc14_upstream_agents=""
if [ -n "${WORKDIR_NEW:-}" ] && [ -d "${WORKDIR_NEW}/.claude/agents" ]; then
  _rc14_upstream_agents="${WORKDIR_NEW}/.claude/agents"
else
  printf 'WARN: WORKDIR_NEW=%s is not a usable upstream clone; pass 2 will fall back to TODO placeholders.\n' "${WORKDIR_NEW:-}" >&2
fi

_rc14_agents_dir="$PROJECT_ROOT/.claude/agents"
_rc14_backfilled=0
_rc14_already_current=0

if [ ! -f "$cust" ] || [ ! -d "$_rc14_agents_dir" ]; then
  echo "  v1.0.0-rc14 backfill: no .template-customizations or no .claude/agents/; pass 2 skipped."
else
  while IFS= read -r raw; do
    trimmed="${raw%%#*}"
    trimmed="$(printf '%s' "$trimmed" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    [ -z "$trimmed" ] && continue

    # Must be a .claude/agents/*.md path.
    case "$trimmed" in
      .claude/agents/*.md) ;;
      *) continue ;;
    esac

    base="$(basename "$trimmed")"

    # Exclude SME files and local supplements (customer ruling 2026-05-20).
    case "$base" in
      sme-template.md) continue ;;
      sme-*.md)        continue ;;
      *-local.md)      continue ;;
    esac

    proj_file="$PROJECT_ROOT/$trimmed"
    [ -f "$proj_file" ] || continue

    present=$(_rc14_file_slugs "$proj_file")

    missing=""
    echo "$present" | grep -q '^hard_rules$'    || missing="$missing hard_rules"
    echo "$present" | grep -q '^output_format$' || missing="$missing output_format"
    missing="$(printf '%s' "$missing" | sed 's/^ *//')"

    if [ -z "$missing" ]; then
      _rc14_already_current=$((_rc14_already_current + 1))
      continue
    fi

    # shellcheck disable=SC2086
    echo "MIGRATION(rc14-pass2): $base missing section(s):$(printf ' %s' $missing)" >&2  # nosemgrep: bash.lang.correctness.unquoted-expansion.unquoted-variable-expansion-in-command

    # When multiple sections are missing, build a single concatenated body
    # (hard_rules + blank line + output_format) and call the insertion helper
    # once. A single insertion preserves canonical order (Escalation →
    # Hard rules → Output format); two separate insertions at the same anchor
    # invert the order because each call re-anchors at escalation. Issue #267.
    combined_body=$(mktemp)

    for slug in $missing; do
      body_file=$(mktemp)
      sourced_from_upstream=0

      if [ -n "$_rc14_upstream_agents" ] && [ -f "$_rc14_upstream_agents/$base" ]; then
        _rc14_extract_section_by_slug "$_rc14_upstream_agents/$base" "$slug" > "$body_file"
        if [ -s "$body_file" ]; then
          sourced_from_upstream=1
        fi
      fi

      if [ "$sourced_from_upstream" -eq 0 ]; then
        case "$slug" in
          hard_rules)    _rc14_placeholder_hard_rules    ".claude/agents/$base" > "$body_file" ;;
          output_format) _rc14_placeholder_output_format ".claude/agents/$base" > "$body_file" ;;
        esac
      fi

      # Ensure body ends with a newline.
      tail -c 1 "$body_file" | od -An -c | grep -q '\\n' || printf '\n' >> "$body_file"

      # Append to combined body; add a blank separator between sections.
      if [ -s "$combined_body" ]; then
        printf '\n' >> "$combined_body"
      fi
      cat "$body_file" >> "$combined_body"
      rm -f "$body_file"

      case "$slug" in
        hard_rules)    section_label="Hard rules" ;;
        output_format) section_label="Output format" ;;
        *)             section_label="$slug" ;;
      esac

      if [ "$sourced_from_upstream" -eq 1 ]; then
        _rc14_append_decision "M14 rc14 migration pass 2: backfilled ${section_label} for .claude/agents/$base from upstream rc14 ship."
      else
        _rc14_append_decision "M14 rc14 migration pass 2: backfilled ${section_label} placeholder for .claude/agents/$base (upstream rc14 ship not reachable; manual fill required)."
      fi
    done

    _rc14_insert_after_escalation "$proj_file" "$combined_body"
    rm -f "$combined_body"

    _rc14_backfilled=$((_rc14_backfilled + 1))
  done < "$cust"

  echo "  v1.0.0-rc14 backfill (pass 2): $_rc14_backfilled files backfilled, $_rc14_already_current files already current."
fi
