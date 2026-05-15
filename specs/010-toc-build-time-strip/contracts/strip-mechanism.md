---
name: toc-strip-mechanism-contract
description: Behavioural contract for scripts/strip-toc.sh; idempotent removal of TOC blocks from compiled model-side artifacts.
status: active
created_date: 2026-05-15
---


# Contract: TOC strip mechanism

**Owner**: `release-engineer` (script + hook + CI sub-gate).
**Implementer**: `software-engineer`.
**Status**: design
**Spec**: [../spec.md](../spec.md) — D-1..D-8.

## Purpose

Define the behavioural contract `scripts/strip-toc.sh` MUST satisfy
so that the canonical `*.md` files and their (gitignored,
locally-regenerated) `.model-view/*.model.md` mirrors stay in
lockstep on each operator's workstation, with model-readable mirrors
free of TOC overhead.

## Inputs

- `$1` (optional): a single file path under the repo root. If
  supplied, the script processes only that file (post-commit fast
  path). If absent, the script walks every tracked `*.md` file under
  the repo root and processes the in-scope subset.
- `--all` (optional flag): force whole-tree walk regardless of `$1`.
  Used by post-checkout hook and by manual "regenerate everything"
  invocations after clone.
- `--dry-run` (optional flag): parse and validate every in-scope
  source file (fence-pair well-formedness) but write no mirror
  output. Exit 0 on success; exit 2 on any FATAL parse error. Used
  by the `mirror-current` pre-release sub-gate, which runs in CI
  where the gitignored mirror tree does not exist.
- `--check` (optional flag): regenerate the mirror in-memory and
  diff against the on-disk mirror at `.model-view/`; exit 1 if any
  drift detected, 0 if clean. Local-operator convenience for
  detecting stale local mirrors after `git pull`; NOT used by CI
  (which uses `--dry-run`, see D-6).
- `--quiet` (optional flag): suppress per-file progress output;
  errors still go to stderr.

## In-scope predicate

A file is in-scope iff ALL of:

1. Tracked by git (`git ls-files` returns it).
2. Path matches `*.md`.
3. Path does NOT match any of the blacklist prefixes:
   `examples/`, `specs/`, `tests/`, `.model-view/`.
4. File body contains at least one `<!-- TOC -->` fence.

Files outside this predicate are skipped silently; the script does
NOT delete stale mirrors for files that fell out of scope. Stale
on-disk mirrors are local-only artefacts (gitignored); operators
clear them with `rm -rf .model-view/ && scripts/strip-toc.sh --all`
when scope changes.

## Strip rule

The script removes, for each matched fence pair, the byte range from
the line containing `<!-- TOC -->` through the line containing
`<!-- /TOC -->` inclusive, plus one trailing blank line if present.
Both fence comments MUST appear on lines by themselves (modulo
leading whitespace, which is permitted but preserved nowhere — the
whole line is removed). Inline `<!-- TOC -->` mid-paragraph is NOT
matched and is left untouched (it is not the convention).

Fence-pair matching is **non-greedy and line-anchored**:

- Regex (POSIX ERE): `^[[:space:]]*<!-- TOC -->[[:space:]]*$`
  opens; `^[[:space:]]*<!-- /TOC -->[[:space:]]*$` closes.
- Multiple fence pairs in one file are all stripped.
- An unpaired open fence (no matching close before EOF) is a FATAL
  error: the script exits non-zero with a diagnostic naming the file
  and the offending line number; no mirror is written.

## Output

For each in-scope file at `<path>`, the script writes the stripped
content to `.model-view/<path:.md→.model.md>`, creating intermediate
directories as needed. Existing mirror content is overwritten
atomically (write-temp + rename). The mirror's first line is a
single comment: `<!-- generated from <path> — do not edit by hand -->`.

## Exit codes

- 0 — all in-scope files processed (or `--check` / `--dry-run`
  confirmed clean).
- 1 — `--check` found drift between source and on-disk mirror;
  stderr lists divergent paths. (Not emitted by `--dry-run`, which
  does not inspect the on-disk mirror.)
- 2 — fatal error (unpaired fence, unreadable file, write failure);
  stderr names the cause and exits immediately (no partial mirror
  left in an inconsistent state — atomic rename + cleanup).

## Idempotence

Running the script twice in succession against an unchanged tree
MUST produce zero diff on the second run. The script's self-test
fixture asserts this.

## Performance bounds

- Single-file fast path (post-commit hook): < 200ms wall clock.
- Whole-tree regenerate (`--all`, post-checkout / post-clone):
  < 2s wall clock on the current ~30-file surface; < 10s at 200
  in-scope files (growth headroom).
- `--dry-run` whole-tree parse (CI sub-gate): < 2s on the current
  surface (no I/O for writes).

## Test surface (owned by `qa-engineer`)

A fixture set under `tests/strip-toc/fixtures/` covers:

1. File with a single well-formed TOC fence pair → mirror stripped.
2. File with multiple fence pairs → all stripped.
3. File with no TOC fence → no mirror written (script no-op).
4. File with unpaired open fence → FATAL exit 2.
5. File with unpaired close fence (no opener) → FATAL exit 2.
6. File outside scope (under `examples/`, `specs/`, etc.) → ignored
   even if it contains a TOC fence.
7. `--check` against a clean tree with on-disk mirror present →
   exit 0.
8. `--check` against a tree where one on-disk mirror was hand-edited
   → exit 1 with the divergent path listed.
9. `--check` against a tree where `.model-view/` does not exist
   (fresh clone, no hook run yet) → exit 1 with all in-scope paths
   listed as "missing mirror"; operator fix is `--all`.
10. `--dry-run` against a clean source tree → exit 0; writes nothing.
11. `--dry-run` against a source with an unpaired fence → exit 2;
    writes nothing.
12. Idempotence: run twice, second run produces no file mutations.
