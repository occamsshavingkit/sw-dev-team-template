# Contract: Hook detector negative-corpus convention

**Feature Branch**: `009-hook-negative-corpus`
**Created**: 2026-05-14
**Status**: Draft (customer rulings 2026-05-15 substituted; see §Resolved decisions)
**Owner**: `qa-engineer` (convention); per-hook detector logic owned by
  `software-engineer`; review-gate enforcement by `code-reviewer`.
**Input**: Customer ruling 2026-05-14, Class B (hook regex correctness)
  of `process-auditor`'s rc7..rc12 surface — 8/66 issues. Hooks ship
  positive-case tests for the WRITE path; false-positive corpora are
  not part of the spec.

## Headline

Every classifying hook detector ships, alongside positive fixtures, a
**negative corpus** of inputs the detector MUST NOT match. A new
detector merged without a negative corpus covering the six categories
below is a `code-reviewer` blocker.

## Scope: what is a "detector"

Any function inside `scripts/hooks/*.{py,sh}` that, given a
`tool_input` field (or substring), returns a deny / ask / allow
signal or contributes a target path. Concretely: regex / substring
path-extraction, interpreter-inline and heredoc body scanners,
mutation-command detectors, write-mode classifiers, escape-hatch
parsers. Out of scope: JSON-structure validation, tool-name
routing.

## Negative-corpus categories (binding)

Every detector's corpus MUST cover all six categories the rc7..rc12
surface produced. **N = 3 per category.** Per-hook author may extend
upward (e.g., for prose categories where variety is wide); minimum
floor is 3. Total floor per new detector: 18 entries (6 categories ×
3).

1. **Read-only ops mentioning the protected target.** `grep
   CUSTOMER_NOTES.md`, `wc -l docs/DECISIONS.md`, `diff a b
   CUSTOMER_NOTES.md`. (#111, #175.)
2. **Prose / docs / comments carrying path-shaped tokens.** A
   docstring `"writes to CUSTOMER_NOTES.md"`, a comment `# see
   scripts/foo.py`, a markdown link.
3. **Quoted strings in print / log statements.** `print("opening
   foo.txt")`, `logger.info("loaded CUSTOMER_NOTES.md")` — data, not
   write.
4. **Heredoc bodies that do not write.** `cat <<EOF` bodies
   mentioning the target as data; delimiter tokens (`EOF`, `PY`)
   are not paths. (#175.)
5. **Inline-bash / escape-hatch carriers.** `SWDT_AGENT_PUSH=role
   bash -c '...'`, `! SWDT_AGENT_PUSH=role command`, `export
   SWDT_AGENT_PUSH=role; command`. (#176.)
6. **Cross-harness invocation shapes.** Category 6 MUST be exercised
   against every harness mode the hook can fire under: Claude Code
   `Bash` tool, inline `!`-bash, Codex shell, heredoc-fed shells,
   command-substitution wrappers. Categories 1–5 stay single-harness
   (Claude `Bash`).

Mode coverage: each command-string detector MUST have at least one
category-6 entry per harness mode listed in
`.claude/settings.json` and the Codex mirror. Missing-mode coverage
is a `code-reviewer` blocker (#119, #122, #124 root cause).

## Authoring requirement

For each `scripts/hooks/<name>.py`:

1. A peer fixture file `tests/hooks/fixtures/<hook-name>.yml` lists
   negative inputs grouped by the six categories. YAML is the
   project-wide fixture format; the driver supports YAML only. Each
   entry carries `category`, `input` (tool_input payload or command
   string), `rationale` (one line), `regression` (optional issue
   ID).
2. Positive fixtures continue to live in
   `tests/hooks/test-<name>.sh`; the negative corpus is a sibling.
3. Adding a detector without simultaneously adding or extending the
   corpus is a `code-reviewer` review-block.

## Verification

**Both surfaces ship.** Defence-in-depth: pre-commit catches the
single-commit miss early; release-gate catches drift accumulated
across a multi-commit branch.

(a) **Pre-commit lint.** `scripts/lint-hook-corpora.sh` checks every
hook has a peer fixture covering all six categories with N>=3.
Absence or shortfall is a hard lint failure. Catches missing /
regressing corpus at commit time (early shift).

(b) **Release-gate sub-gate.** `hook-negative-corpus` sub-gate in
`scripts/pre-release-gate.sh` runs
`tests/hooks/test-negative-corpora.sh`, which iterates every
`tests/hooks/fixtures/*.yml`, feeds each entry to the corresponding
hook's stdin, asserts stdout is empty (proceed). A match fails the
driver and names (hook, category, input, rationale). Style A per
`specs/007-pre-release-upgrade/contracts/sub-gate.contract.md`.
Catches drift across multi-commit branches before tag.

## Cross-harness coverage (binding)

A hook's contract spans every harness mode it fires under, not only
Claude `Bash`. Category-6 entries enumerate these per-hook; CI runs
the driver against each. Escape-hatch parsers additionally need
**positive** fixtures (in `test-<name>.sh`, not the negative file)
proving the hatch is honoured in every mode (#176).

## Migration

**Migration M-A retroactive.** `software-engineer` authors negative
corpora for both existing hooks immediately upon contract landing,
before next tag:

- `scripts/hooks/customer-notes-guard.py`
- `scripts/hooks/tech-lead-authoring-guard.py`

Effort: medium. Two hooks × six categories × 3 entries floor = 36
fixture entries minimum.

## Resolved decisions (appendix)

Customer rulings 2026-05-15:

1. **N per category = 3** (qa-engineer's recommendation). Total
   floor per new detector: 18 entries. Per-hook author may extend
   upward.
2. **Migration M-A retroactive.** `software-engineer` authors
   corpora for both existing hooks
   (`scripts/hooks/customer-notes-guard.py` and
   `scripts/hooks/tech-lead-authoring-guard.py`) immediately upon
   contract landing.
3. **Cross-harness scope.** Category 6 × every harness mode
   (Claude `Bash`, inline `!`-bash, Codex shell, heredoc,
   command-substitution). Categories 1–5 stay single-harness
   (Claude `Bash`).
4. **Verification surface.** BOTH pre-commit lint AND release-gate
   sub-gate (`hook-negative-corpus` in
   `scripts/pre-release-gate.sh`).
5. **Fixture format.** YAML project-wide. Driver supports YAML
   only. Per-hook fixture files at
   `tests/hooks/fixtures/<hook-name>.yml`.

## Effort (adoption, existing hooks)

**Medium.** Two hooks × six categories × 3 entries = 36 fixture
entries minimum (category 6 expands with harness-mode count). Plus
a YAML-aware driver (~80 lines, mirrors
`test-tech-lead-authoring-guard.sh`) and the pre-commit lint (~40
lines). M-A retroactive is bound, so both existing hooks are in
scope immediately.

## Relationship to other artefacts

- **`specs/007-pre-release-upgrade/contracts/sub-gate.contract.md`
  §Negative-fixture contract.** Sibling: sub-gates perturb the
  candidate tree, hooks perturb `tool_input`. Borrows Style-A
  discipline (PID-scoped markers, revert verification) for driver
  tempfiles; does not extend sub-gate.contract.md.
- **`specs/008-upgrade-matrix-fixtures/`.** Companion attack on
  Class A (upgrade machinery) of the rc7..rc12 surface; this
  contract attacks Class B (hook regex correctness). Both register
  release-gate sub-gates with matching Style-A discipline.
- **`specs/010-toc-build-time-strip/`.** No direct overlap; cited
  for awareness that fixture files under `tests/hooks/fixtures/`
  are out of the TOC-strip predicate (no TOC blocks).
- **FW-ADR-0012 §Verification.** Hook test discipline is cited
  there for `tech-lead-authoring-guard.py`; this contract is the
  cross-cutting generalisation. No supersession.
- **Upstream issue #38** (E-7 cross-references): no overlap.

## Links

- `scripts/hooks/customer-notes-guard.py` — migration target.
- `scripts/hooks/tech-lead-authoring-guard.py` — migration target.
- `tests/hooks/test-tech-lead-authoring-guard.sh` — positive-fixture
  pattern; negative driver mirrors its shape.
- `specs/007-pre-release-upgrade/contracts/sub-gate.contract.md`
  §Negative-fixture contract — sibling discipline.
- Issues: #111, #119, #122, #124, #133, #156, #175, #176.
