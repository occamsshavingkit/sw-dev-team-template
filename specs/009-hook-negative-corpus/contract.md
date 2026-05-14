# Contract: Hook detector negative-corpus convention

**Feature Branch**: `009-hook-negative-corpus`
**Created**: 2026-05-14
**Status**: Draft (customer decisions pending — see §Customer decisions)
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
surface produced. Each category carries at least **N = 3 distinct
inputs** (per-hook extension allowed upward; floor binds).

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
6. **Cross-harness invocation shapes.** Claude `Bash` payload,
   inline `!`-bash, Codex shell, command-substitution `$(...)`,
   heredoc stdin. Each harness mode the hook fires under
   contributes one entry.

Mode coverage: each command-string detector MUST have at least one
category-6 entry per harness mode listed in
`.claude/settings.json` and the Codex mirror. Missing-mode coverage
is a `code-reviewer` blocker (#119, #122, #124 root cause).

## Authoring requirement

For each `scripts/hooks/<name>.py`:

1. A peer fixture file `tests/hooks/fixtures/<name>.negative.json`
   lists negative inputs grouped by the six categories. Each entry
   carries `category`, `input` (tool_input payload or command
   string), `rationale` (one line), `regression` (optional issue
   ID).
2. Positive fixtures continue to live in
   `tests/hooks/test-<name>.sh`; the negative corpus is a sibling.
3. Adding a detector without simultaneously adding or extending the
   corpus is a `code-reviewer` review-block.

## Verification

`tests/hooks/test-negative-corpora.sh` iterates every
`tests/hooks/fixtures/*.negative.json`, feeds each entry to the
corresponding hook's stdin, asserts stdout is empty (proceed). A
match fails the driver and names (hook, category, input,
rationale). Registered as a release-gate sub-gate
(`negative-corpora`, Style A per
`specs/007-pre-release-upgrade/contracts/sub-gate.contract.md`),
gating pre-tag.

Lighter pre-commit option: `scripts/lint-hook-corpora.sh` checks
every hook has a peer fixture covering all six categories with
N>=3. Absence or shortfall is a hard lint failure.

## Cross-harness coverage (binding)

A hook's contract spans every harness mode it fires under, not only
Claude `Bash`. Category-6 entries enumerate these per-hook; CI runs
the driver against each. Escape-hatch parsers additionally need
**positive** fixtures (in `test-<name>.sh`, not the negative file)
proving the hatch is honoured in every mode (#176).

## Migration

Existing hooks ship without corpora. Two paths — customer picks:

- **(M-A) Retroactive.** Dispatch `software-engineer` to author
  corpora for `customer-notes-guard.py` and
  `tech-lead-authoring-guard.py` before next tag. Effort: medium.
- **(M-B) On-next-touch.** Grandfather; convention binds on the
  next functional change. Effort: low short-term; risk: untouched
  hooks accumulate the same failure modes (#175 was a touch one
  year after the original write).

## Customer decisions (enumerated, not picked)

1. **N per category.** Spec proposes 3. Alternatives: 2 (lighter),
   5 (heavier), per-category N.
2. **Migration path.** M-A vs. M-B.
3. **Cross-harness scope.** All six categories × every mode (full
   matrix) vs. category 6 × every mode (current spec) vs.
   category 6 × Claude `Bash` only (lightest).
4. **Verification surface.** Release-gate sub-gate (current) vs.
   pre-commit lint vs. both.
5. **Fixture format.** Per-hook author picks (current) vs.
   project-wide single format.

## Effort (adoption, existing hooks)

**Low–medium.** Two hooks × six categories × ~3 entries ≈ 36
fixture entries, plus a driver (~80 lines, mirrors
`test-tech-lead-authoring-guard.sh`) and an optional lint (~40
lines). Skews medium if M-A picked, low if M-B.

## Relationship to other artefacts

- **`specs/007-pre-release-upgrade/contracts/sub-gate.contract.md`
  §Negative-fixture contract.** Sibling: sub-gates perturb the
  candidate tree, hooks perturb `tool_input`. Borrows Style-A
  discipline (PID-scoped markers, revert verification) for driver
  tempfiles; does not extend sub-gate.contract.md.
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
