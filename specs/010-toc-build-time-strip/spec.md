# Feature Specification: TOC source-vs-model divergence (build-time strip)

**Feature Branch**: `010-toc-build-time-strip`
**Created**: 2026-05-15
**Status**: Draft
**Input**: Customer ruling on token-economization Q6 (2026-05-14) —
"TOC blocks should be stripped model-side but preserved for human
readers in the canonical repo."

## Problem

~30 files carry `<!-- TOC -->...<!-- /TOC -->` blocks (≈150 lines of
overhead). Humans want them for navigation in GitHub / editors; the
model gets no value from them (it sees the headings directly). This
is a **source-vs-model divergence** pattern not previously present in
the framework. The repo on disk is canonical for both audiences and
must stay readable; the divergence is delivered through a strip step,
not by removing TOCs from source.

## Binding decisions

### D-1 — Strip site: post-commit hook writing a gitignored mirror tree

The strip runs as a **post-commit hook** on the author's workstation
(and the same script runs as a CI sub-gate, see D-6). For each
tracked file matching the in-scope predicate (D-3), the hook
regenerates a **sibling stripped copy** at the same path with a
`.model.md` suffix in a parallel mirror tree under `.model-view/`.
The mirror tree is **gitignored** (`.model-view/` added to
`.gitignore`); it is regenerated locally per clone and per edit. The
canonical file (`*.md`) is untouched and remains the single source
of truth committed to the repo. Per customer ruling Q-1 (2026-05-15),
committing the mirror was rejected to avoid diff-noise and dual-
source-of-truth drift; the cost is one-shot local regeneration after
clone (see D-8).

**Rejected alternatives**: Committed mirror (Option S — rejected
Q-1 2026-05-15: diff-noise on every TOC edit, two sources of truth);
Read-tool interception (Option C — requires forking the Claude Code
harness; non-portable across Codex); runtime regeneration (drift risk
+ no auditability); strip-in-source (loses human-readable TOC,
defeats the upstream Q6 ruling).

### D-2 — Delimiter: existing `<!-- TOC --> ... <!-- /TOC -->` fences

The convention is already in use across 30 files (grep-verified
2026-05-15). No new marker. The strip removes the fenced block
**inclusive of both fence comments**, plus the single blank line
immediately following `<!-- /TOC -->` if present (cosmetic — the
stripped file should read naturally). The fence regex is fixed and
documented in `contracts/strip-mechanism.md`.

### D-3 — Scope: tracked Markdown files only; opt-out via path predicate

In scope: every tracked `*.md` file under the repo root that contains
at least one `<!-- TOC -->` fence pair. This intentionally includes
`.claude/agents/*.md`, `docs/adr/*.md`, `docs/templates/*.md`,
`CLAUDE.md`, `README.md`, `ROADMAP.md`,
`SW_DEV_ROLE_TAXONOMY.md`, and `docs/glossary/*.md`. **Out of
scope** (path-blacklist in the strip script): `examples/**` (downstream
illustrations may diverge intentionally), `specs/**` (spec-kit
artefacts have no recurring-context cost — they are read once per
feature), and `tests/**/fixtures/**` (fixtures must reflect canonical
shape verbatim). Files without a TOC fence are no-ops.

### D-4 — Ownership: `release-engineer` owns the script + hook + CI

`release-engineer` owns `scripts/strip-toc.sh`, the post-commit and
post-checkout hook templates under `.git-hooks/`, the `.gitignore`
entry for `.model-view/`, and the CI sub-gate that verifies sources
parse. `software-engineer` writes the script (routine shell, no
architectural decision left after this spec). `code-reviewer`
reviews. No new agent role.

### D-5 — Mirror layout: `.model-view/<original-path>.model.md` (gitignored)

The mirror tree at `.model-view/` mirrors the source layout exactly.
Example: `.claude/agents/tech-lead.md` →
`.model-view/.claude/agents/tech-lead.model.md`. Mirrors are
**gitignored** (entry `.model-view/` in `.gitignore`); they are
local-only regenerated artefacts, never committed. Model-side
consumers `Read` the mirror path; the strip script populates it on
clone (D-8) and per-edit (D-1 post-commit hook). No `.gitattributes
linguist-generated` hint is needed since the tree is not tracked. A
top-level `.model-view/README.md` is itself emitted by
`scripts/strip-toc.sh --all` (one paragraph) explaining the
convention for anyone landing there directly.

### D-6 — Test surface: source-parse sub-gate in pre-release-gate

A new `mirror-current` sub-gate (under the FR-001 fail-all framework
of spec 007) runs `scripts/strip-toc.sh --all --dry-run`, which
walks the in-scope `*.md` source set and verifies every TOC fence
pair parses without writing any mirror file. Failure modes that
trip the gate: unpaired fence (FATAL exit 2 per
`contracts/strip-mechanism.md`), unreadable file, or any in-scope
file the script would refuse to process. This shape was chosen over
"regenerate-and-diff-against-on-disk" because the on-disk mirror is
gitignored and may not exist in CI; under gitignore-mirror semantics
there is no committed artefact to diff against, so the meaningful
invariant is "sources are well-formed and the script will succeed
when an operator regenerates locally." Per-operator staleness (an
on-disk mirror that lags the source after a `git pull`) is caught
by the post-commit / post-checkout hook (D-1, D-8), not by CI.

### D-7 — Consumption: opt-in via consumer policy, not enforced here

This spec ships the **mirror**. It does NOT modify any agent contract
to tell agents "Read the .model-view path instead of the source." That
is a follow-up token-economization decision (the customer may want
specific agents to switch consumption sites independently). Until a
consumer is changed, the mirror is dead weight — that is acceptable
for v1 because the strip is cheap and the mirror is small. Promotion
to mandatory consumption is a future spec.

### D-8 — Post-checkout hook: opt-in, graceful degradation when absent

A `.git-hooks/post-checkout` template (parallel to the spec-007
`pre-push` shipping pattern) invokes `scripts/strip-toc.sh --all`
after `git clone` and after `git checkout <branch>`. The hook is
**opt-in**: operators install it themselves (one-line `cp` or
`git config core.hooksPath .git-hooks`), documented in the
`.model-view/README.md` emitted by the script and in the
project-level onboarding doc. Required installation was rejected
because git provides no portable mechanism to enforce hook
installation on clone, and a "missing-hook" hard-fail would block
fresh clones from reading source.

**Graceful-degradation behaviour when the hook is absent**: the
mirror tree simply does not exist; model-side consumers routed to
the mirror (none in v1 — see D-7) MUST tolerate a missing mirror
by falling back to the canonical source. Until a consumer is
routed, hook absence is invisible. Operators who edit a TOC without
the post-commit hook installed produce a stale local mirror; this is
invisible to the repo (gitignored) and is fixed by re-running
`scripts/strip-toc.sh --all`. CI does not see operator-local
staleness because CI regenerates from scratch (D-6).

## Success Criteria

- **SC-001**: `scripts/strip-toc.sh --all --dry-run` walks every
  in-scope `*.md` file with zero fatal errors; pre-release gate's
  `mirror-current` sub-gate exits 0. Operator-local mirror
  freshness is out of CI scope (gitignored, regenerated on demand).
- **SC-002**: Stripped mirrors contain zero `<!-- TOC -->` fences and
  zero lines between matched fence pairs; verified by post-strip grep
  in the script's self-test.
- **SC-003**: Total token reduction across the in-scope mirror set
  vs the canonical set is ≥ 100 lines (auditor cited ~150; allow some
  margin for files added between audit and ship).
- **SC-004**: Post-commit hook runtime on a typical edit (single
  file) is < 200ms; full-tree regenerate (post-checkout / `--all`)
  is < 2s on a typical Linux workstation.

## Assumptions

- TOC fences are well-formed (paired `<!-- TOC -->` and `<!-- /TOC -->`).
  Malformed fences are a lint problem (separate concern); the script
  fails loud on an unpaired fence rather than silently consuming the
  rest of the file.
- The mirror tree's existence does NOT alter any current consumer
  behaviour. Consumers continue to Read the canonical `*.md` until a
  follow-up spec routes them to the mirror.
- Diff-noise on the mirror is structurally impossible because the
  tree is gitignored (no diffs are ever staged). Hand-edits to a
  local mirror are overwritten on next regenerate; the source `*.md`
  remains the only edit surface.

## Dependencies

- `scripts/pre-release-gate.sh` (from spec 007) — gains the new
  `mirror-current` sub-gate per D-6.
- `.git-hooks/post-commit` and `.git-hooks/post-checkout` (template-
  shipped opt-in, parallels the `.git-hooks/pre-push` shipped for
  spec 007). Operators install via `git config core.hooksPath
  .git-hooks` or by copying into `.git/hooks/`.
- `.gitignore` entry `.model-view/` (the mirror tree is local-only).
- Existing `<!-- TOC -->` convention — already in use, no migration
  needed.

## Out of scope

- Re-routing agent contracts to consume the mirror (separate
  follow-up token-economization spec).
- Stripping other content classes (e.g., HTML comments generally,
  decorative section dividers); this spec is **TOC-only**.
- Generating the TOCs themselves; existing TOC generation (whatever
  tool authors use) is unchanged.
- Source-side TOC linting (paired-fence enforcement is a separate
  hygiene concern; this spec only requires the strip script fail-loud
  on a malformed fence it encounters).

## Resolved decisions

- **Q-1 (resolved 2026-05-15)**: Commit policy for `.model-view/`.
  Ruling: **gitignored mirror**, regenerated locally per clone / per
  edit. Rejected: committed mirror (diff-noise, dual source of truth).
  Cost accepted: operators run `scripts/strip-toc.sh --all` after
  clone (one-shot; automatable via opt-in post-checkout hook, D-8).
  Drives D-1, D-5, D-6, D-8.
