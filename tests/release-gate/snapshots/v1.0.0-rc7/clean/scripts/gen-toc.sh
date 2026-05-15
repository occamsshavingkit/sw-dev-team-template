#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# scripts/gen-toc.sh — generate/refresh a Table of Contents block in a
# Markdown file. Idempotent: only mutates content between the markers
#
#     <!-- TOC -->
#     ...auto-generated...
#     <!-- /TOC -->
#
# Skips headings inside fenced code blocks. Emits ## through ######;
# excludes H1 (the doc title links to itself).
#
# A TOC at the top of long binding docs is a context-economy lever:
# agents read the TOC region first, then `Read offset/limit` only the
# section they need, instead of pulling the whole file.

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/gen-toc.sh [options] FILE...
    --insert       insert markers if missing (after first H1, else at top)
    --check        exit 1 if any file's TOC is stale or markers are missing
                   (CI mode — never mutates files)
    --min-lines N  skip files shorter than N lines (default 0 — process all)
    -h, --help     show this help
EOF
}

generate_toc_body() {
  # Emit the TOC list (without surrounding marker lines) for stdin.
  awk '
    BEGIN { in_code = 0 }
    /^```/  { in_code = !in_code; next }
    in_code { next }
    /^#+[[:space:]]/ {
      hashes = $0
      sub(/[[:space:]].*/, "", hashes)
      depth = length(hashes)
      if (depth < 2 || depth > 6) next
      title = $0
      sub(/^#+[[:space:]]+/, "", title)
      sub(/[[:space:]]+$/, "", title)
      # GitHub-flavoured slug: lowercase, strip punct (keep alnum, space, _, -),
      # then spaces → "-".
      slug = tolower(title)
      gsub(/[^a-z0-9 _-]/, "", slug)
      gsub(/ +/, "-", slug)
      indent = ""
      for (i = 2; i < depth; i++) indent = indent "  "
      printf "%s- [%s](#%s)\n", indent, title, slug
    }
  '
}

splice_toc() {
  # Splice a generated TOC into FILE between the existing markers.
  # Stdout: the new file content. No mutation.
  local file="$1"
  local body
  body="$(generate_toc_body < "$file")"
  awk -v body="$body" '
    /<!-- TOC -->/ {
      print
      print ""
      print body
      print ""
      in_block = 1
      next
    }
    /<!-- \/TOC -->/ {
      in_block = 0
      print
      next
    }
    !in_block { print }
  ' "$file"
}

insert_markers() {
  # Insert empty TOC markers after the YAML frontmatter (if any), else
  # after the first H1, else at the top of the file. Stdout: file with
  # markers inserted. No splice yet — caller should re-run splice_toc
  # afterwards.
  local file="$1"
  awk '
    BEGIN { inserted = 0; in_fm = 0; fm_done = 0 }
    NR == 1 && /^---[[:space:]]*$/ {
      in_fm = 1
      print
      next
    }
    in_fm && /^---[[:space:]]*$/ {
      in_fm = 0
      fm_done = 1
      print
      print ""
      print "<!-- TOC -->"
      print "<!-- /TOC -->"
      inserted = 1
      next
    }
    in_fm { print; next }
    NR == 1 && !/^# / && !fm_done {
      print "<!-- TOC -->"
      print "<!-- /TOC -->"
      print ""
      inserted = 1
    }
    /^# / && !inserted {
      print
      print ""
      print "<!-- TOC -->"
      print "<!-- /TOC -->"
      inserted = 1
      next
    }
    { print }
  ' "$file"
}

has_markers() {
  grep -q '<!-- TOC -->' "$1" && grep -q '<!-- /TOC -->' "$1"
}

mode_insert=0
mode_check=0
min_lines=0
files=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --insert)    mode_insert=1; shift ;;
    --check)     mode_check=1; shift ;;
    --min-lines) min_lines="$2"; shift 2 ;;
    -h|--help)   usage; exit 0 ;;
    --)          shift; files+=("$@"); break ;;
    -*)          echo "ERROR: unknown flag: $1" >&2; usage >&2; exit 2 ;;
    *)           files+=("$1"); shift ;;
  esac
done

if [[ ${#files[@]} -eq 0 ]]; then
  echo "ERROR: no files given" >&2
  usage >&2
  exit 2
fi

stale=0
for f in "${files[@]}"; do
  if [[ ! -f "$f" ]]; then
    echo "ERROR: not a file: $f" >&2
    exit 1
  fi
  lines="$(wc -l < "$f")"
  if [[ $lines -lt $min_lines ]]; then
    continue
  fi

  if ! has_markers "$f"; then
    if [[ $mode_check -eq 1 ]]; then
      echo "STALE: $f — TOC markers missing"
      stale=1
      continue
    fi
    if [[ $mode_insert -eq 1 ]]; then
      tmp="$(mktemp)"
      insert_markers "$f" > "$tmp"
      mv "$tmp" "$f"
    else
      echo "SKIP: $f — no TOC markers (use --insert to add)" >&2
      continue
    fi
  fi

  new="$(splice_toc "$f")"
  if [[ $mode_check -eq 1 ]]; then
    if ! diff -q <(printf '%s\n' "$new") "$f" >/dev/null 2>&1; then
      echo "STALE: $f — TOC out of date"
      stale=1
    fi
  else
    printf '%s\n' "$new" > "$f.tmp.$$"
    mv "$f.tmp.$$" "$f"
  fi
done

if [[ $mode_check -eq 1 && $stale -ne 0 ]]; then
  exit 1
fi
exit 0
