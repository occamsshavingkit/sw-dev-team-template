#!/usr/bin/env bash
#
# migrations/v1.3.0.sh — register sharding initial setup (fw-adr-0025 Option S)
#
# For each of the 5 live registers:
#   (a) If the active file exceeds ~150 KB, split entries by date into
#       <register>-YYYY-QN.md quarter shards, leaving the most-recent
#       quarter in the active file.
#   (b) Write (or regenerate) the <register>-INDEX.md.
#
# Milestone archival (pruning terminal rows below a cutoff date) is NOT
# performed here — that requires an explicit --milestone-close date and
# is handled by scripts/archive-registers.sh --milestone-close DATE.
#
# Idempotent: safe to re-run. Data-preserving: no entry is discarded.
# The active file's canonical path is unchanged.
#
# This migration does NOT run milestone archival automatically (that
# requires a --milestone-close date from the operator). Instead it
# checks file sizes and reports whether sharding would help. The actual
# sharding is only performed if a register exceeds the SHARD_THRESHOLD_BYTES.
#
# Env vars from scripts/upgrade.sh:
#   PROJECT_ROOT   — absolute path to project root
#   WORKDIR_NEW    — (optional) upstream clone
#   WORKDIR_OLD    — (optional) previous upstream baseline

set -euo pipefail

: "${PROJECT_ROOT:?PROJECT_ROOT is required}"

SHARD_THRESHOLD_BYTES=153600   # 150 KB
# Look for gen-register-index.sh next to this migration script (same repo),
# then fall back to PROJECT_ROOT/scripts/.
_mig_dir="$(cd "$(dirname "$0")" && pwd)"
_repo_scripts="$(cd "$_mig_dir/../scripts" 2>/dev/null && pwd || echo "$PROJECT_ROOT/scripts")"
GEN_INDEX=""
for _c in "$_repo_scripts/gen-register-index.sh" "$PROJECT_ROOT/scripts/gen-register-index.sh"; do
    if [[ -x "$_c" ]]; then GEN_INDEX="$_c"; break; fi
done
# Quarter helper: derive YYYY-QN for a YYYY-MM-DD date.
date_to_quarter() {
    local d="$1"
    local y m q
    y="${d%%-*}"
    m="${d#*-}"; m="${m%%-*}"
    case "$m" in
        01|02|03) q=1 ;;
        04|05|06) q=2 ;;
        07|08|09) q=3 ;;
        *)         q=4 ;;
    esac
    printf '%s-Q%d' "$y" "$q"
}

# Current quarter label.
TODAY="$(date -u +%Y-%m-%d)"
CURRENT_Q="$(date_to_quarter "$TODAY")"

shard_register_oq() {
    local reg_abs="$1"
    local dir stem
    dir="$(dirname "$reg_abs")"
    stem="$(basename "$reg_abs" .md)"

    # Parse OPEN_QUESTIONS-style table: extract rows, group by quarter.
    python3 - "$reg_abs" "$dir" "$stem" "$CURRENT_Q" <<'PYEOF'
import sys, re, os, json
from pathlib import Path
from collections import defaultdict

reg_path = Path(sys.argv[1])
outdir   = Path(sys.argv[2])
stem     = sys.argv[3]
cur_q    = sys.argv[4]

def date_to_quarter(d):
    y, m = d[:4], int(d[5:7])
    q = (m - 1) // 3 + 1
    return f"{y}-Q{q}"

def latest_date(s):
    dates = re.findall(r'\d{4}-\d{2}-\d{2}', s)
    return max(dates) if dates else None

lines = reg_path.read_text(encoding='utf-8').splitlines(keepends=True)

# Find the header and separator rows.
header_idx = sep_idx = None
for i, l in enumerate(lines):
    if re.match(r'^\|[ \t]*-', l) and i > 0 and lines[i-1].startswith('|'):
        header_idx = i - 1
        sep_idx = i
        break

if header_idx is None:
    print(f"  v1.3.0 shard: {stem}.md has no parseable table; skipping", flush=True)
    sys.exit(0)

# Separate preamble, header+sep, data rows, postamble.
preamble = lines[:header_idx]
header_row = lines[header_idx]
sep_row    = lines[sep_idx]

data_rows = []
postamble_start = len(lines)
for i in range(sep_idx + 1, len(lines)):
    l = lines[i]
    if l.startswith('|'):
        data_rows.append(l)
    elif l.strip() == '':
        # Blank line within the table region: skip it (don't end the table).
        # Some editors insert blank lines between table rows; stopping here
        # would send all subsequent rows to the postamble (unsharded).
        continue
    else:
        # Non-blank, non-row content ends the table.
        postamble_start = i
        break
postamble = lines[postamble_start:]

# Group rows by quarter, using Date-family columns.
# Find the date column index from the header.
hcells = [c.strip() for c in header_row.strip('|\n').split('|')]
date_col = None
for idx, h in enumerate(hcells):
    lh = h.lower()
    if lh in ('answered date','last reviewed','resolution','opened','date'):
        date_col = idx
        break

# Bucket rows.
current_rows = []
shard_rows = defaultdict(list)  # quarter_label -> [row]
unmapped = []

for row in data_rows:
    rcells = [c.strip() for c in row.strip('|\n').split('|')]
    d = None
    if date_col is not None and date_col < len(rcells):
        d = latest_date(rcells[date_col])
    if d is None:
        # No date found — keep in current quarter (conservative).
        current_rows.append(row)
        continue
    q = date_to_quarter(d)
    if q >= cur_q:
        current_rows.append(row)
    else:
        shard_rows[q].append(row)

if not shard_rows:
    print(f"  v1.3.0 shard: {stem}.md — all entries in current quarter; no split needed", flush=True)
    sys.exit(0)

# Write shards (append-only — don't duplicate rows already in shard).
for q, rows in sorted(shard_rows.items()):
    shard_path = outdir / f"{stem}-{q}.md"
    existing = shard_path.read_text(encoding='utf-8') if shard_path.exists() else ''
    with shard_path.open('a', encoding='utf-8') as f:
        if not existing:
            f.write(f"# {stem} — {q} quarter shard\n\n")
            f.write(f"Quarter shard created by `migrations/v1.3.0.sh`.\n\n")
            # Write the header so the file is parseable.
            f.write(header_row)
            f.write(sep_row)
        for row in rows:
            if row not in existing:
                f.write(row)
    print(f"  v1.3.0 shard: wrote {len(rows)} row(s) to {stem}-{q}.md", flush=True)

# Rewrite active file with preamble + header + current rows.
tmp_path = reg_path.with_suffix('.tmp_shard')
with tmp_path.open('w', encoding='utf-8') as f:
    f.writelines(preamble)
    f.write(header_row)
    f.write(sep_row)
    f.writelines(current_rows)
    f.writelines(postamble)
tmp_path.replace(reg_path)
print(f"  v1.3.0 shard: {stem}.md updated ({len(current_rows)} current rows)", flush=True)
PYEOF
}

shard_register_cn() {
    local reg_abs="$1"
    local dir stem
    dir="$(dirname "$reg_abs")"
    stem="$(basename "$reg_abs" .md)"

    python3 - "$reg_abs" "$dir" "$stem" "$CURRENT_Q" <<'PYEOF'
import sys, re
from pathlib import Path
from collections import defaultdict

reg_path = Path(sys.argv[1])
outdir   = Path(sys.argv[2])
stem     = sys.argv[3]
cur_q    = sys.argv[4]

def date_to_quarter(d):
    y, m = d[:4], int(d[5:7])
    q = (m - 1) // 3 + 1
    return f"{y}-Q{q}"

text = reg_path.read_text(encoding='utf-8')
lines = text.splitlines(keepends=True)

# Split into sections at ## YYYY-MM-DD headings.
sections = []
preamble = []
in_section = False
cur_section = []
cur_date = None

for line in lines:
    m = re.match(r'^## (\d{4}-\d{2}-\d{2})', line)
    if m:
        if in_section:
            sections.append((cur_date, cur_section))
        cur_date = m.group(1)
        cur_section = [line]
        in_section = True
    elif not in_section:
        preamble.append(line)
    else:
        cur_section.append(line)

if in_section:
    sections.append((cur_date, cur_section))

current_sections = []
shard_sections = defaultdict(list)

for d, sec in sections:
    q = date_to_quarter(d)
    if q >= cur_q:
        current_sections.append((d, sec))
    else:
        shard_sections[q].append((d, sec))

if not shard_sections:
    print(f"  v1.3.0 shard: {stem}.md — all entries in current quarter; no split needed", flush=True)
    sys.exit(0)

for q, secs in sorted(shard_sections.items()):
    shard_path = outdir / f"{stem}-{q}.md"
    existing = shard_path.read_text(encoding='utf-8') if shard_path.exists() else ''
    with shard_path.open('a', encoding='utf-8') as f:
        if not existing:
            f.write(f"# {stem} — {q} quarter shard\n\n")
            f.write(f"Quarter shard created by `migrations/v1.3.0.sh`.\n\n")
        for _, sec in secs:
            sec_text = ''.join(sec)
            if sec_text not in existing:
                f.write(sec_text)
    print(f"  v1.3.0 shard: wrote {len(secs)} section(s) to {stem}-{q}.md", flush=True)

tmp_path = reg_path.with_suffix('.tmp_shard')
with tmp_path.open('w', encoding='utf-8') as f:
    f.writelines(preamble)
    for _, sec in current_sections:
        f.writelines(sec)
tmp_path.replace(reg_path)
print(f"  v1.3.0 shard: {stem}.md updated ({len(current_sections)} current sections)", flush=True)
PYEOF
}

# ---------------------------------------------------------------------------
# Process each register
# ---------------------------------------------------------------------------

REGISTERS=(
    "docs/OPEN_QUESTIONS.md:table"
    "docs/intake-log.md:table"
    "docs/pm/RISKS.md:table"
    "docs/pm/LESSONS.md:table"
    "CUSTOMER_NOTES.md:cn"
)

any_sharded=0

for entry in "${REGISTERS[@]}"; do
    reg_rel="${entry%%:*}"
    reg_type="${entry##*:}"
    reg_abs="$PROJECT_ROOT/$reg_rel"

    if [[ ! -f "$reg_abs" ]]; then
        echo "  v1.3.0: $reg_rel not found — skipping"
        continue
    fi

    sz=$(wc -c < "$reg_abs" || echo 0)
    echo "  v1.3.0: $reg_rel size=${sz} bytes (threshold=${SHARD_THRESHOLD_BYTES})"

    if [[ "$sz" -gt "$SHARD_THRESHOLD_BYTES" ]]; then
        echo "  v1.3.0: sharding $reg_rel ..."
        if [[ "$reg_type" == "cn" ]]; then
            shard_register_cn "$reg_abs"
        else
            shard_register_oq "$reg_abs"
        fi
        any_sharded=1
    else
        echo "  v1.3.0: $reg_rel below threshold — no sharding needed"
    fi

    # Always (re)generate INDEX.
    if [[ -n "$GEN_INDEX" ]] && [[ -x "$GEN_INDEX" ]]; then
        bash "$GEN_INDEX" "$reg_rel" --root "$PROJECT_ROOT" || true
    fi
done

if [[ "$any_sharded" -eq 0 ]]; then
    echo "  v1.3.0: no registers exceeded the ${SHARD_THRESHOLD_BYTES}-byte threshold in this repo; sharding skipped."
    echo "  (This is expected for fresh scaffolds. The tooling is ready for when registers grow.)"
fi

echo "  v1.3.0: register-sharding migration complete."
