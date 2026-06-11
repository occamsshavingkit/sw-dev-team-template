---
name: fw-adr-0028-multi-version-upgrade-conflict-classification
description: >
  Broaden trivial-delta auto-merge beyond SPDX-only, add take-upstream default
  for pre-existing-path collisions, enrich --dry-run conflict diagnostics, and
  define the regression-test strategy — without per-version migration chaining.
status: accepted
date: 2026-06-11
---


# FW-ADR-0028 — Multi-version upgrade conflict classification

<!-- TOC -->

- [Status](#status)
- [Context and problem statement](#context-and-problem-statement)
- [Current-state inventory](#current-state-inventory)
  - [Already shipped (confirmed against HEAD)](#already-shipped-confirmed-against-head)
  - [Still open (confirmed against HEAD)](#still-open-confirmed-against-head)
- [Decision drivers](#decision-drivers)
- [Considered options (Three-Path Rule, binding)](#considered-options-three-path-rule-binding)
  - [Option M — Minimalist: document the remaining gaps, no new code](#option-m--minimalist-document-the-remaining-gaps-no-new-code)
  - [Option S — Scalable: broaden classifier + take-upstream default + enriched dry-run](#option-s--scalable-broaden-classifier--take-upstream-default--enriched-dry-run)
  - [Option C — Creative: per-version migration chaining](#option-c--creative-per-version-migration-chaining)
- [Decision outcome](#decision-outcome)
  - [Detailed design for each open item](#detailed-design-for-each-open-item)
    - [Item 1 — Broaden trivial-delta classifier beyond SPDX-only](#item-1--broaden-trivial-delta-classifier-beyond-spdx-only)
    - [Item 2 — Pre-existing-path collision default: take-upstream](#item-2--pre-existing-path-collision-default-take-upstream)
    - [Item 3 — Enriched --dry-run conflict diagnostics](#item-3--enriched---dry-run-conflict-diagnostics)
    - [Item 4 — Verification and regression strategy](#item-4--verification-and-regression-strategy)
  - [PR sequence (2 PRs)](#pr-sequence-2-prs)
- [Consequences](#consequences)
  - [Positive](#positive)
  - [Negative / trade-offs accepted](#negative--trade-offs-accepted)
  - [Follow-up ADRs](#follow-up-adrs)
- [Risk analysis](#risk-analysis)
- [Verification](#verification)
- [Links](#links)

<!-- /TOC -->

Shape per MADR 3.0 + this template's Three-Path Rule
(`docs/templates/adr-template.md`).

---

## Status

- **Accepted: 2026-06-11**
- **Note:** Customer authorized the #262 fix this session ('scope it, fix it', 2026-06-11); the two behavior changes (broadened trivial-delta auto-merge; take-upstream default for pre-existing-path collisions with --keep-local opt-out) implement issue #262's explicitly-requested expected behavior. Implemented across PR-1 (structural classifier + dry-run fix) and PR-2 (take-upstream default + enriched dry-run).
- **Deciders:** `architect` + `tech-lead` + customer (alters the upgrade
  contract's conflict-classification path — a cross-cutting pattern change
  and a public-surface change to `scripts/upgrade.sh` behaviour; customer
  approval required per CLAUDE.md Hard Rules)
- **Consulted:** upstream issue #262 (root report), upstream issue #110
  (pre-existing collisions, already partially handled), upstream issue #337
  (atomic_install mode-preserve, merged), FW-ADR-0010 (pre-bootstrap
  safety — related but distinct scope), FW-ADR-0002 (manifest verification,
  refuse-on-uncertain posture).

---

## Context and problem statement

Upgrading a downstream project across multiple rc or version skips
compresses every release's conflicts into a single `scripts/upgrade.sh`
invocation. When the project's local delta versus the common baseline is
trivial (an SPDX header stamped by legal review, a blank line, a comment)
but upstream has independently evolved the same file across several
releases, the current classifier surfaces those files as manual conflicts
even though the operator has nothing substantive to resolve. The
`check-spdx.sh` example from the issue report is the canonical case: the
project pre-dated upstream shipping the file, yet the only question is
"yours or ours", which has an obvious answer.

The cross-cutting concern is the sync loop's conflict classification in
`scripts/upgrade.sh` (lines 1593–1888). FW-ADR-0010 covers the
pre-bootstrap window that runs *before* this loop; its scope does not
extend here. The ADR trigger rows that fire for this change: cross-cutting
pattern change (conflict-classification logic), public-surface change to
`upgrade.sh` behaviour, and a choice with a failure mode (silent data loss
from over-eager auto-merge) that requires explicit architectural sign-off.

---

## Current-state inventory

### Already shipped (confirmed against HEAD)

- **`_is_trivial_spdx_delta()` function** (`scripts/upgrade.sh` lines
  ~1497–1580, tagged "Issue #262"). Already auto-merges when the
  project-vs-baseline diff consists exclusively of SPDX/Copyright comment
  additions (up to 5 lines, zero deletions, zero other modifications) that
  upstream already contains verbatim. Conservative: any ambiguity falls
  through to the conflict path.
- **Call site** in the sync loop (lines ~1852–1862): invoked before
  classifying a file as a conflict, only when `baseline_available=1`,
  the baseline file exists, and `dry_run=0`. The `dry_run=0` guard is a
  known gap (see Item 3).
- **`auto_merged[]` bucket** in the summary report with its own labeled
  section "Auto-merged (trivial SPDX delta)".
- **`--dry-run` flag**: non-mutating plan print is implemented, but the
  `_is_trivial_spdx_delta` call site is gated on `dry_run -eq 0`, so
  `--dry-run` currently misclassifies would-be auto-merged files as
  conflicts. That is a gap in the dry-run fidelity (open, see Item 3).
- **`preexisting_collisions[]` bucket**: detection and reporting already
  implemented (lines ~1863–1883 for detection, ~2415–2427 for the report).
  The report gives the operator three options (take upstream, keep local,
  merge). No automated default is taken; the operator must act manually.
  The collision is still classified into `conflicts[]` (it is a member of
  both arrays). This is the open gap for Item 2.
- **`tests/upgrade/test-spdx-trivial-delta.sh`**: 9 integration cases (a–i)
  + 3 static checks covering the existing SPDX-only classifier and its
  call site, including a case (j) for the summary bucket label.
- **`upgrade-paths-allowlist.txt`**: fixture for upgrade-path round-trip
  allowlisting (rc3, v0.17.0, v0.16.0 currently allowlisted for the
  self-bootstrap argv-drop defect, unrelated to #262).

### Still open (confirmed against HEAD)

1. The trivial-delta classifier (`_is_trivial_spdx_delta`) only recognizes
   SPDX/Copyright comment additions. Blank-line-only, comment-only, and
   whitespace-only local deltas that upstream already subsumes are not
   auto-merged; they become conflicts.
2. Pre-existing-path collisions (project has the file, baseline does not,
   upstream newly ships it) are detected and reported but not resolved
   automatically. The "obvious" default — take upstream — is not applied
   even when the operator has given no indication of intent to keep their
   version.
3. `--dry-run` does not call `_is_trivial_spdx_delta`, so its conflict
   list is a pessimistic over-count. An operator planning a multi-version
   skip cannot use `--dry-run` to reliably predict which files will need
   manual attention.
4. No test coverage for items 1–3 above. The existing test suite in
   `tests/upgrade/` does not exercise the broadened classifier, the
   take-upstream collision path, or the corrected `--dry-run` behavior.

---

## Decision drivers

- **False-positive conflicts are operator friction, not safety.** A file
  classified as a conflict blocks the upgrade from completing cleanly; the
  operator must hand-inspect and re-run. Every false positive in a
  multi-version skip multiplies this cost.
- **False-negative auto-merges are silent data loss.** If the classifier
  auto-merges a file where the local delta was substantive, the operator's
  change is gone with no record. This is the primary safety concern and
  must bound every classifier extension.
- **Conservative-by-default is the framework posture.** FW-ADR-0010 and
  FW-ADR-0002 both establish "refuse on uncertain; require explicit override
  for ambiguous cases." The classifier must follow the same posture: false
  negatives (don't auto-merge something trivial) are acceptable; false
  positives (auto-merge something substantive) are not.
- **`--dry-run` fidelity matters for multi-version planning.** Operators
  who skip multiple releases need a reliable pre-flight. Pessimistic output
  undermines trust in the tool.
- **`scripts/upgrade.sh` is the highest blast-radius file in the repo.**
  All downstream upgrade paths execute it. Changes here must be minimally
  invasive, well-tested, and independently reviewable.
- **Per-version migration chaining is a separate, large concern.** The
  architecture decision here should not be blocked on a feature that may
  take 3–5 PRs of its own.

---

## Considered options (Three-Path Rule, binding)

### Option M — Minimalist: document the remaining gaps, no new code

Accept the current state. Annotate the three open gaps in `docs/TEMPLATE_UPGRADE.md`
and issue-body comments. Operators running multi-version skips are advised
to manually inspect `--dry-run` output and expect false-positive conflicts
for blank/comment-only deltas and pre-existing-path collisions.

- **Sketch:** No changes to `scripts/upgrade.sh`. Write a prose section in
  `docs/TEMPLATE_UPGRADE.md` listing the known false-positive categories
  and the manual resolution steps.
- **Pros:**
  - Zero risk of introducing a false-positive auto-merge (no new classifier
    code).
  - Minimal implementation cost.
- **Cons:**
  - The original issue #262 report's motivating case (2-line SPDX amendment
    forcing a manual conflict across N releases) is not improved.
  - `--dry-run` remains unreliable for planning.
  - Pre-existing-path collisions still require a manual `rm`-and-rerun
    cycle even when take-upstream is the obvious answer.
  - Customer deferred this work to a focused session (per memory note),
    indicating expectation of actual resolution, not just documentation.
- **When M wins:** if the classifier extension is too risky relative to the
  benefit, or if the team has no bandwidth for the test-fixture work. That
  risk can be mitigated by Item 4's test strategy; M is therefore dominated
  by S on the safety axis.

### Option S — Scalable: broaden classifier + take-upstream default + enriched dry-run

Extend `_is_trivial_spdx_delta` with sibling classifier functions for
blank-line-only and comment-only deltas, add a take-upstream default
(with `--keep-local` opt-out) for pre-existing-path collisions, fix the
`--dry-run` gate so the trivial-delta check runs in dry-run mode too, and
add test cases for all three.

- **Sketch:**
  - Extract a generic `_is_trivial_structural_delta()` function (or extend
    the existing one with additional rule-sets). Call it from the same call
    site as `_is_trivial_spdx_delta` via a cascade.
  - Add a `--keep-local` flag (or env var) to opt out of the
    take-upstream default for pre-existing-path collisions.
  - Remove the `&& $dry_run -eq 0` guard from the trivial-delta call site;
    in dry-run mode, classify correctly but do not write files.
  - Add `tests/upgrade/test-trivial-structural-delta.sh` and
    `tests/upgrade/test-preexisting-collision-take-upstream.sh`.
- **Pros:**
  - Closes all three open items with coherent, testable logic.
  - `--dry-run` becomes a reliable planner.
  - Take-upstream default eliminates the most common manual step for
    pre-existing-path collisions while preserving the opt-out.
  - All new code is in the same function/call-site region; reviewer scope
    is bounded.
- **Cons:**
  - The broadened classifier introduces new auto-merge surface. Each new
    class of "trivial" must be carefully bounded (see Item 1 for exact rules).
  - The `--keep-local` flag / env var adds surface to the public CLI.
  - Take-upstream for collisions changes the UX from "always prompt" to
    "auto-act with opt-out"; operators who relied on the prompt need to
    read release notes.
- **When S wins:** the framework's actual use case — long-lived downstream
  projects with incremental legal/compliance additions (SPDX, blanks,
  comments) that should not block upgrades. Maps cleanly onto the
  conservative-by-default posture if the classifier rules are exact.

### Option C — Creative: per-version migration chaining

Instead of broadening the single-pass classifier, decompose multi-version
upgrades into a sequence of single-version steps: `v1→v2`, `v2→v3`,
`v3→v4`. Each step produces a clean state before the next runs. Conflicts
are isolated to the specific version that introduced them, making them
attributable and minimising the blast radius of any single conflict.

- **Sketch:** `upgrade.sh` detects the N intermediate versions between
  `TEMPLATE_VERSION` and the target, downloads each intermediate tag, and
  applies them in order. Each step writes `TEMPLATE_VERSION` and the
  manifest before the next step reads them. A conflict at step k halts the
  chain; the operator resolves it and resumes from k+1.
- **Pros:**
  - Most correct model: conflicts are pinned to the version that introduced
    them.
  - No need for a trivial-delta classifier at all — single-version diffs
    are small enough that classification is rarely needed.
  - The `--dry-run` accuracy problem evaporates (each step's dry-run is
    accurate for that step's delta).
- **Cons:**
  - Large implementation scope: N intermediate tag downloads, a
    resume-from-step-k protocol, manifest idempotency across partial
    chains, test fixtures for multi-step scenarios. Estimated 3–5 PRs.
  - The pre-release gate (`test-gate-fail-each.sh`) fixture infrastructure
    is already hazardous (resets the work branch); multi-step chaining
    amplifies that risk.
  - Does not eliminate the pre-existing-path collision problem (collisions
    appear at the version that introduced the path; the operator still
    has to choose).
  - Intermediate tags may not be available for all downstream projects
    (skip-many deployments that jumped from an old MINOR to the latest).
  - Customer memory note explicitly deferred multi-version upgrade-
    reliability as a "focused session" with "~2–3 PRs"; Option C exceeds
    that envelope.
- **When C wins:** if attributable per-version conflict isolation is a
  hard requirement rather than a nice-to-have, and the team has a full
  sprint for the chaining infrastructure. Not satisfied here.

---

## Decision outcome

**Chosen option: S (broaden classifier + take-upstream default + enriched dry-run).**

Option M does not close the issue. Option C exceeds the stated scope
envelope (customer memory note: ~2–3 PRs, focused session) and introduces
hazardous fixture complexity before Option S's simpler increments are even
tried. Option S closes all three open items within a 2-PR sequence, stays
within the conservative-by-default posture if the classifier rules below
are followed precisely, and produces independently reviewable and testable
artifacts.

---

### Detailed design for each open item

#### Item 1 — Broaden trivial-delta classifier beyond SPDX-only

**Rationale for broadening.** The current SPDX-only rule is a special case
of a wider class: local additions that carry zero semantic meaning to the
upstream file's behavior and that upstream already subsumes. Blank lines and
non-functional comment lines belong to this class when the following
conditions all hold.

**New function: `_is_trivial_structural_delta()`**

Called from the same call site as `_is_trivial_spdx_delta`, as a fallback
when SPDX-only returns 1. Signature is identical:

```
_is_trivial_structural_delta() {
  local baseline="$1"   # workdir/old/<f>
  local project="$2"    # project_root/<f>
  local upstream="$3"   # workdir/new/<f>
```

**Classification rules (all must hold; any failure returns 1):**

1. All three files exist. No baseline → return 1 (cannot prove trivial).
2. Zero deletions. `comm -23 <(sort baseline) <(sort project)` is empty.
   A deletion means the local edit removed content, which may be
   substantive.
3. Every added line (lines in project not in baseline) matches at least
   one of:
   - Empty or whitespace-only: `^[[:space:]]*$`
   - A comment line (starting with `#`, `//`, `--`, `/*`, `*`, `*/`,
     `<!--`, or `-->` after optional leading whitespace): the comment
     pattern set is bounded to these tokens and does not extend further.
     The match is `^[[:space:]]*(#|//|--|/\*|\*[^/]|\*/|<!--|--)`.
     A line that is `# SPDX-...` or `# Copyright` also matches the SPDX
     rule and would have been caught by `_is_trivial_spdx_delta` first;
     `_is_trivial_structural_delta` is only reached when SPDX-only
     returns 1, so SPDX lines reachable here are lines upstream does NOT
     contain (which the SPDX-only rule blocks on its upstream-containment
     check). The structural classifier does NOT require upstream to
     contain each added comment — that is the key relaxation vs the SPDX
     classifier. See Safety boundary below.
4. Added-line count is `<= 10`. Cap at 10 (versus SPDX's cap of 5)
   because blank/comment blocks in real projects are sometimes larger
   license headers or section dividers. The cap prevents unbounded
   auto-merge of large comment blocks that could contain substantive
   prose.
5. Line-count invariant: `wc -l project == wc -l baseline + add_count`.
   Detects in-place modifications (the comm approach does not).
6. Added-line count is `> 0`. (If zero, the files are identical and
   would have been caught by the earlier `files_match` fast-path.)
7. **Safety boundary (binding):** the structural classifier does NOT
   check whether upstream contains the added lines. This is a deliberate
   relaxation relative to the SPDX classifier. It is safe because:
   - Rules 1–6 ensure the only local change is a pure additive block of
     blank/comment lines.
   - Taking upstream discards those blank/comment additions from the
     project — this is the intended behavior. The operator added cosmetic
     lines that upstream does not have; upstream's version is what ships.
   - A false positive here means discarding a comment that the operator
     added locally. This is the acceptable risk. It is NOT equivalent to
     discarding substantive code because rule 3 enforces that no non-
     comment, non-blank line was added.
   - Rule 3's comment-pattern set is bounded and tested. Any line that
     does not match one of the enumerated tokens fails rule 3 and falls
     through to the conflict path.

**Call-site cascade (binding order):**

```
if _is_trivial_spdx_delta "$baseline" "$project" "$upstream"; then
  echo "auto-merged (trivial SPDX delta): $f"
  auto_merged+=("$f")
  ...
elif _is_trivial_structural_delta "$baseline" "$project" "$upstream"; then
  echo "auto-merged (trivial structural delta): $f"
  auto_merged+=("$f")
  ...
else
  conflicts+=("$f")
fi
```

Both classifiers share the same `auto_merged[]` bucket; the log line
distinguishes which classifier fired.

**Dry-run fix (part of Item 1's call site):** Remove `&& $dry_run -eq 0`
from the outer guard. In dry-run mode, both classifiers run and print
"would auto-merge (trivial SPDX delta): $f" or "would auto-merge (trivial
structural delta): $f" without mutating files. This makes `--dry-run`
output accurate for planning.

The dry-run log prefix convention: `[dry-run] auto-merged ...` matches
the `$prefix` variable already used by the rest of the dry-run report.

#### Item 2 — Pre-existing-path collision default: take-upstream

**Detection (already implemented):** A file is a pre-existing-path
collision when `baseline_available=1`, `workdir/old/<f>` does NOT exist,
`project_root/<f>` exists, and `workdir/new/<f>` exists. This is the
`preexisting_collisions[]` population condition at lines ~1881–1883.

**Current behavior:** The file lands in both `conflicts[]` (blocks the
upgrade) and `preexisting_collisions[]` (gets an ACTION REQUIRED notice
with three options). The operator must manually choose and re-run.

**New default: take-upstream.** When a pre-existing-path collision is
detected and neither `.template-customizations` lists the path (which
would have routed it to `preserved[]` earlier) nor `--keep-local` is
asserted, the upgrade takes the upstream content silently and classifies
the file into a new bucket: `collision_taken_upstream[]`.

**`--keep-local` flag:** New flag on `scripts/upgrade.sh`:

```
--keep-local <path>   Treat the named path as a local customization for
                      this run: do not auto-take upstream on pre-existing-
                      path collisions for this path. May be specified
                      multiple times. Alternatively, add the path to
                      .template-customizations for a permanent declaration.
```

The flag populates an in-memory set `keep_local_paths`. When a collision
is detected and the path is in `keep_local_paths`, the file is routed to
`local_only_kept[]` (not `conflicts[]`).

**Detection gate (binding):** The take-upstream default applies only
when ALL of the following hold:
- `baseline_available=1`
- Path absent from `workdir/old/` (upstream newly introduced the path)
- Path present in both `project_root/` and `workdir/new/`
- Path NOT in `preserve_list` (would have been handled earlier)
- Path NOT in `keep_local_paths`
- Neither trivial classifier returned 0 for this path (if either did,
  the auto-merge path already handled it via `atomic_install`; this
  branch is not reached)

**Report:** A new summary bucket "Accepted upstream (pre-existing collision
resolved)" lists all `collision_taken_upstream[]` entries with a `>` sigil.
The dry-run report prints "would take upstream (pre-existing collision): $f".

**Migration note:** This is a behavior change for operators who relied on
the existing "always prompt" behavior. Release notes must call it out.
Operators who want to retain their version of the colliding file must add
it to `.template-customizations` before running the upgrade (existing
mechanism) or pass `--keep-local <path>` at the command line.

#### Item 3 — Enriched --dry-run conflict diagnostics

Beyond the dry-run call-site fix in Item 1, the `--dry-run` conflict
report gains per-file delta-nature annotations:

For each file that would land in `conflicts[]`, print:
```
  ! <path>
      upstream delta: <shortstat>
      local delta:    <shortstat>
      nature: <one of: blank/comment-only | spdx-comment | substantive | unknown>
```

The `nature` field is computed as:
- `spdx-comment` — `_is_trivial_spdx_delta` would have returned 0 EXCEPT
  that the upstream-containment check failed (i.e., local added SPDX lines
  that upstream does NOT have). This is a soft signal: the SPDX line may
  need to be accepted into upstream.
- `blank/comment-only` — `_is_trivial_structural_delta` would have returned
  0 EXCEPT for one of the safety rules (e.g., upstream does not subsume; or
  the cap was exceeded). Annotate which rule failed.
- `substantive` — neither classifier returned 0; the delta contains non-
  comment, non-blank content.
- `unknown` — baseline unavailable; cannot classify.

This does not change the exit code or the action taken; it is informational
output for the operator's planning pass. The `nature` field is only emitted
in `--dry-run` mode (not in live runs, where auto-merge already fires or
the conflict is real).

**Implementation note:** To produce the `nature` annotation without code
duplication, the two classifier functions must return a reason code on
failure (e.g., via a global or nameref variable) rather than only a boolean
exit code. The preferred approach is a global `_classifier_reject_reason`
variable that each function sets before returning 1:

```bash
_classifier_reject_reason=""

_is_trivial_structural_delta() {
  ...
  [[ -z "$deleted_lines" ]] || { _classifier_reject_reason="deletions-present"; return 1; }
  ...
}
```

This avoids subprocess calls (which reset exit codes) and keeps the logic
in the same function scope.

#### Item 4 — Verification and regression strategy

**Principle:** use the same SWDT_PRESTAGED_WORKDIR + SWDT_BOOTSTRAPPED=1
fixture pattern that `tests/upgrade/test-spdx-trivial-delta.sh` already
uses. This bypasses the hazardous `test-gate-fail-each.sh` (which
git-resets the work branch, issue #306) and does not require the
release-gate fixture snapshot machinery.

**New test files:**

`tests/upgrade/test-trivial-structural-delta.sh` — covers Item 1's
broadened classifier and the dry-run fix:

| Case | Description | Expected |
|------|-------------|----------|
| (a) | +1 blank line; upstream lacks it | auto-merge structural |
| (b) | +3 blank lines within cap | auto-merge structural |
| (c) | +1 `#` comment line | auto-merge structural |
| (d) | +11 blank lines (above cap) | falls through → conflict |
| (e) | +1 blank + 1 substantive line | falls through → conflict |
| (f) | deletion + blank add | falls through (deletion) |
| (g) | +1 blank; dry-run mode | dry-run log says "would auto-merge", no file written |
| (h) | +1 SPDX line upstream has → SPDX classifier fires first | auto-merge SPDX (not structural) |
| (i) | +1 SPDX line upstream lacks → SPDX classifier rejects (upstream-missing-line); structural classifier catches it as a `#` comment line → auto-merge structural | auto-merge structural |
| static-1 | `_is_trivial_structural_delta` function defined | grep check |
| static-2 | dry-run call site does not gate on `dry_run -eq 0` | grep absence check |

`tests/upgrade/test-preexisting-collision-take-upstream.sh` — covers Item 2:

| Case | Description | Expected |
|------|-------------|----------|
| (a) | Collision, no flags | take-upstream; collision_taken_upstream bucket |
| (b) | Collision + `--keep-local <path>` | local_only_kept; no auto-take |
| (c) | Collision + path in `.template-customizations` | preserved; no auto-take |
| (d) | Collision, dry-run | "would take upstream" printed; no file written |
| (e) | Regression guard: non-collision conflict still conflicts | conflicts bucket |
| static-1 | `--keep-local` flag parsed in upgrade.sh | grep check |
| static-2 | `collision_taken_upstream` array declared | grep check |

**Regression guard (binding):** Every new test file must include a case
that asserts the pre-existing conflict path (a file with substantive local
changes) still routes to `conflicts[]`. This is the false-positive guard.

**No fixture-snapshot mutations:** The new test files use ephemeral `mktemp`
workdirs (same as `test-spdx-trivial-delta.sh`) and do not touch
`tests/release-gate/` fixtures. The release-gate upgrade-paths sub-gate
(`upgrade-paths-allowlist.txt`) is not modified by this work; no new
allowlist entries are needed unless the broadened classifier introduces a
round-trip failure for an existing allowlisted path.

---

### PR sequence (2 PRs)

**PR-1 — Trivial structural classifier + dry-run fix** (software-engineer
owned; qa-engineer review of test cases)

Scope:
- Add `_is_trivial_structural_delta()` to `scripts/upgrade.sh` with the
  exact rules from Item 1.
- Update the call site to cascade SPDX-first, structural-second, with
  the `--dry-run` gate removed from both.
- Add `_classifier_reject_reason` global and set it in both functions for
  use by the dry-run annotator.
- Add `tests/upgrade/test-trivial-structural-delta.sh` (all static + all
  integration cases from Item 4 above).
- Update `docs/TEMPLATE_UPGRADE.md` to document the broadened auto-merge
  behavior.
- Does NOT include Item 2 (take-upstream for collisions) or Item 3
  (dry-run nature annotations) — those are PR-2.

Risk: lowest. The structural classifier is additive and conservative. A bug
here produces a false negative (a blank-line delta falls through to
conflict) not a false positive. The test suite's regression-guard cases
bound the false-positive risk.

**PR-2 — Pre-existing collision take-upstream + enriched dry-run** (software-
engineer owned; qa-engineer review of test cases; release-engineer review
of the CLI surface change for `--keep-local`)

Scope:
- Add `--keep-local` flag parsing to `scripts/upgrade.sh`.
- Implement the take-upstream default for pre-existing-path collisions
  with the detection gate from Item 2.
- Add `collision_taken_upstream[]` array and its summary bucket.
- Implement dry-run nature annotations from Item 3 (uses
  `_classifier_reject_reason` added in PR-1).
- Add `tests/upgrade/test-preexisting-collision-take-upstream.sh` (all
  static + all integration cases from Item 4 above).
- Update `docs/TEMPLATE_UPGRADE.md` and release notes to document the
  behavior change for pre-existing-path collisions.

Risk: medium. The take-upstream default is a behavior change. False-positive
risk here is "take upstream when the operator wanted to keep local" — the
operator's local file is overwritten. Mitigations: the `--keep-local` flag,
the `.template-customizations` path (existing mechanism), and the dry-run
output (which shows "would take upstream" before the operator commits to the
live run). The test suite's case (e) regression guard bounds the scope.

---

## Consequences

### Positive

- Multi-version upgrades that differ from the baseline only in blank lines
  or comment blocks no longer require manual resolution.
- `--dry-run` becomes a reliable planning tool: it reports the correct
  classification (would auto-merge vs would conflict) for each file.
- Pre-existing-path collisions resolve in one pass instead of requiring
  `rm`-and-rerun.
- The operator has a documented opt-out (`--keep-local` or
  `.template-customizations`) for both new behaviors.
- All new behavior is independently testable via the SWDT_PRESTAGED_WORKDIR
  fixture pattern without touching hazardous gate fixtures.

### Negative / trade-offs accepted

- The broadened classifier adds new auto-merge surface. The safety boundary
  (enumerated comment-token set, cap of 10 lines, zero-deletions rule,
  line-count invariant) bounds the risk to cosmetic-only content, but the
  risk is non-zero.
- Take-upstream for collisions changes UX from "always prompt" to "auto-act
  with opt-out." Operators who have not read release notes may lose a local
  file they intended to keep. The opt-out mechanisms exist but require
  foreknowledge.
- `--keep-local` is a new CLI flag on `scripts/upgrade.sh`. Future
  releases must keep it. The flag surface is minimal (one repeated-option
  argument) and follows the existing `--resolve`, `--verify`, `--dry-run`
  pattern.
- Per-version migration chaining (Option C) is not addressed. Multi-version
  conflicts remain compressed into a single pass. This is an accepted
  trade-off for the ~2–3 PR scope constraint.

### Follow-up ADRs

- None required for the scope above. If per-version migration chaining is
  revisited, it would be a new ADR (the scope and risk profile are large
  enough to warrant one).

---

## Risk analysis

The single largest risk is a **false-positive auto-merge in the structural
classifier** (Item 1): the classifier accepts a file as "blank/comment-only
delta" when the operator's local comment actually contained substantive
information (a TODO referencing a live ticket, a disable-reason for a
framework feature, an issue workaround note). The upstream file overwrites
the project file; the comment is gone with no conflict marker.

**Why this is the top risk:** SPDX lines are machine-generated and uniform;
they are safe to auto-merge by identity (upstream-containment check). Comment
lines are human-written and may carry operational meaning. The structural
classifier does not require upstream containment, so it will discard any
comment the operator added that upstream did not independently adopt.

**Mitigations:**
1. Rule 3's comment-token set is bounded and enumerated in this ADR. It is
   not a free-form "starts with a non-alphanumeric" rule. Any extension of
   the set requires a new ADR.
2. The 10-line cap limits the blast radius. A 50-line comment block does
   not auto-merge.
3. The zero-deletions rule (rule 2) ensures the classifier never fires when
   the operator's edit reorganized or replaced content.
4. The line-count invariant (rule 5) catches the comm false-equivalence
   case (two different lines that sort-identical).
5. `--dry-run` now shows "would auto-merge (trivial structural delta)"
   before a live run, giving the operator a chance to add `--keep-local`
   or `.template-customizations` for any path they want to protect.
6. The test suite's regression-guard cases (one per test file) assert that
   substantive local changes still route to `conflicts[]`.

**Residual risk:** A comment line that appears trivial but carries operational
meaning will be silently discarded. This risk is accepted as smaller than
the alternative (every blank-line or comment-only delta requiring manual
conflict resolution in a multi-version skip). The operator's best mitigation
is to use `.template-customizations` for any file that should never be
auto-merged.

---

## Verification

- **Success signal (Item 1):** `tests/upgrade/test-trivial-structural-delta.sh`
  passes all cases including case (g) (dry-run) and the regression-guard
  case (h). The SPDX test suite (`test-spdx-trivial-delta.sh`) continues
  to pass unchanged.
- **Success signal (Item 2):** `tests/upgrade/test-preexisting-collision-take-upstream.sh`
  passes all cases including the regression-guard case (e).
- **Success signal (Item 3):** Case (g) of the structural-delta test
  confirms dry-run output contains "would auto-merge" and that the file
  is not modified.
- **Failure signal:** Any upstream issue reporting a local edit that was
  silently discarded by the structural classifier (false positive); or
  `--dry-run` output inconsistent with the live run; or a pre-existing
  collision auto-taken-upstream when the operator expected a prompt.
- **Review cadence:** at the next MINOR release that touches
  `scripts/upgrade.sh`. Reconsider if any failure signal fires, or if the
  comment-token set needs expansion (triggers a new ADR per the
  enumerated-set rule above).

---

## Links

- Upstream issues:
  - `#262 — multi-version upgrade reliability` (this ADR)
  - `#110 — pre-existing-path collisions` (partial prior fix; extended here)
  - `#337 — atomic_install mode-preserve + exec-bit repair` (merged;
    unblocks Item 1's atomic_install call for non-executable files)
  - `#306 — test-gate-fail-each.sh hazard on work branches` (informs
    Item 4's fixture strategy)
- Related ADRs:
  - `FW-ADR-0002 — upgrade content verification` (refuse-on-uncertain
    posture; this ADR follows the same conservative-by-default posture)
  - `FW-ADR-0010 — pre-bootstrap local edit safety` (distinct scope:
    pre-bootstrap window before the sync loop; not extended here)
  - `FW-ADR-0014 — preservation vs manifest` (preservation-refused path
    in the sync loop; adjacent but independent)
- Related artefacts:
  - `scripts/upgrade.sh` (lines ~1497–1888 — classifier and call site)
  - `tests/upgrade/test-spdx-trivial-delta.sh` (existing #262 coverage)
  - `tests/release-gate/upgrade-paths-allowlist.txt`
  - `docs/TEMPLATE_UPGRADE.md` (operator-facing upgrade procedure)
- External references: MADR 3.0 (`https://adr.github.io/madr/`).
