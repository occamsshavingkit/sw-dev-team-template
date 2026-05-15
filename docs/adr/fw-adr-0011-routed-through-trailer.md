---
name: fw-adr-0011-routed-through-trailer
description: Routed-Through commit-trailer plus lint/hook/tool-bridge carve-out enforces Hard Rule 8; primary-enforcement framing superseded by FW-ADR-0012.
status: superseded-in-part
superseded-in-part-by: fw-adr-0012
date: 2026-05-14
---


# FW-ADR-0011 — `Routed-Through:` commit-trailer enforcement for Hard Rule #8

<!-- TOC -->

- [Status](#status)
- [Context and problem statement](#context-and-problem-statement)
- [Decision drivers](#decision-drivers)
- [Considered options (Three-Path Rule, binding)](#considered-options-three-path-rule-binding)
  - [Option M — Minimalist: prose tightening on Hard Rule #8](#option-m--minimalist-prose-tightening-on-hard-rule-8)
  - [Option S — Scalable: `Routed-Through:` trailer with lint + hook + tool-bridge carve-out](#option-s--scalable-routed-through-trailer-with-lint--hook--tool-bridge-carve-out)
  - [Option C — Creative: pre-commit hook that reconstructs ownership from git blame](#option-c--creative-pre-commit-hook-that-reconstructs-ownership-from-git-blame)
- [Decision outcome](#decision-outcome)
  - [Trailer grammar (binding)](#trailer-grammar-binding)
  - [Allowed roles (binding)](#allowed-roles-binding)
  - [Tool-bridge carve-out (binding)](#tool-bridge-carve-out-binding)
  - [Pattern IDs (binding)](#pattern-ids-binding)
  - [Lint implementation surface](#lint-implementation-surface)
  - [CI workflow](#ci-workflow)
  - [SessionStart hook](#sessionstart-hook)
  - [Downstream override surface](#downstream-override-surface)
  - [Grandfathering](#grandfathering)
- [Consequences](#consequences)
  - [Positive](#positive)
  - [Negative / trade-offs accepted](#negative--trade-offs-accepted)
  - [Follow-up ADRs](#follow-up-adrs)
- [Relationship to other rules and ADRs](#relationship-to-other-rules-and-adrs)
- [Verification](#verification)
- [ADR-internal follow-ups](#adr-internal-follow-ups)
- [Links](#links)

<!-- /TOC -->

Shape per MADR 3.0 + this template's Three-Path Rule
(`docs/templates/adr-template.md`).

---

## Status

- **Proposed** (Accepted upon merge)
- **Date:** 2026-05-14
- **Superseded-in-part:** Primary-enforcement framing
  (CI-blocking lint as the gate for Hard Rule #8) is superseded by
  FW-ADR-0012 (PreToolUse tool-layer hook). The `Routed-Through:`
  trailer convention and `scripts/lint-routing.sh` live on as
  defense-in-depth audit tooling (FW-ADR-0012 prong 2). The
  `.github/workflows/role-routing-lint.yml` CI workflow is retired
  by FW-ADR-0012.
- **Deciders:** `architect` + `tech-lead` + customer (this ADR
  introduces a public commit-message contract, a new lint script
  on the framework CLI surface, a new CI workflow, and a new
  SessionStart hook — customer approval required per CLAUDE.md
  Hard Rules)
- **Consulted:** `software-engineer` (lint implementation), `tech-writer`
  (SessionStart hook authoring + Hard Rule #8 verbatim citation),
  `researcher` (CUSTOMER_NOTES.md rulings 6/7/8 record), `code-reviewer`
  (PR #162 review surfacing the largest single-turn direct-write
  incident on record), `release-engineer` (CI workflow shape).

## Context and problem statement

Hard Rule #8 in `CLAUDE.md` binds `tech-lead` to orchestration only —
production artifacts, requirements, ADRs, release notes, code,
scripts, and customer-truth records route to the owning specialist.
The rule is documentary; it has no mechanical enforcement. PR #162's
code review flagged the largest single-turn direct-write incident on
record (multiple production artifacts authored in the main session
without specialist routing), and the customer surfaced the concern
again on 2026-05-14 with an explicit request for "stronger
enforcement." Hard Rule #11 (atomic customer questions) was promoted
the same day from distributed-prose status to a numbered Hard Rule
because the prior shape was insufficient; #11's enforcement is
three-pronged — `scripts/lint-questions.sh` hard-gate, SessionStart
reminder hook, and the numbered rule itself. Hard Rule #8 currently
has only the third prong.

The ADR-trigger rows that fire: cross-cutting pattern change (commit-
message contract is a project-wide convention), new lint script on
the framework CLI surface (`scripts/lint-routing.sh`), new CI
workflow (`.github/workflows/role-routing-lint.yml`), new
SessionStart hook (`scripts/hooks/role-routing-reminder.sh`), and
choice that locks downstream projects into a public commit-message
contract they inherit from the template. Customer rulings 6, 7, and
8 from 2026-05-14 (recorded in `CUSTOMER_NOTES.md` by `researcher`)
pin the trailer scope, the tool-bridge qualifier set, and the
CUSTOMER_NOTES.md cutoff posture, respectively.

## Decision drivers

- **Symmetry with Hard Rule #11's enforcement shape.** The customer
  has accepted that #11 needs lint + hook + numbered-rule
  reinforcement; #8 is structurally analogous (a discipline that
  recurs without mechanical signal) and should receive the same
  shape. No new Hard Rule is added; this ADR enforces the existing
  #8.
- **Per-commit signal beats per-file signal.** A trailer on every
  commit is a single, parseable, append-only record of who authored
  what. File-class-conditional rules (which would tag only "is this
  an ADR / production code / customer-truth path?") were considered
  and rejected by customer ruling 6: every commit past
  `HARDGATE_AFTER_SHA` carries the trailer regardless of file class.
- **Tool-bridge work is real and not a violation.** `tech-lead` does
  legitimately commit on behalf of specialists (sandbox limits,
  merge / revert / rebase / cherry-pick operations, orchestration
  artifacts that no specialist owns). The carve-out must be
  enumerated and closed so it cannot drift into a general escape
  hatch.
- **Discipline burden must be bounded.** Every commit carrying a
  trailer costs typing seconds. The grammar must be one line,
  machine-parseable, and learnable in one sitting. No second-order
  conventions (multi-line trailers, JSON-in-trailer, conditional
  fields).
- **Downstream extensibility.** Downstream projects may add
  project-local roles (e.g., `sme-brewing`, `sme-plc`) that the
  framework cannot enumerate at scaffold time. The override surface
  must be present from day one so downstream adoption does not stall.
- **Grandfathering.** All commits at or before `HARDGATE_AFTER_SHA`
  are exempt. Mirrors the `scripts/lint-questions.sh` cutoff
  precedent — no retroactive lint on history that predates the rule.

## Considered options (Three-Path Rule, binding)

### Option M — Minimalist: prose tightening on Hard Rule #8

Leave the enforcement model unchanged; reword Hard Rule #8 to be more
explicit about specialist routing, and add a paragraph to
`tech-lead.md`'s pre-close audit that lists "direct writes I made
this turn" by file class.

- **Sketch:** No new script, no new hook, no new CI workflow. The
  rule remains documentary; the prose simply names more failure
  modes.
- **Pros:**
  - Zero new surface on the framework CLI or CI.
  - Zero discipline burden per commit.
  - Cheapest implementation.
- **Cons:**
  - PR #162 happened *under* the existing prose. Tightening the
    prose does not change the mechanical signal: there is none.
  - The customer's 2026-05-14 ask was for "stronger enforcement,"
    not "louder prose." Hard Rule #11's parallel promotion path
    establishes the customer's stated preference for mechanical
    reinforcement when prose recurs.
  - No machine-parseable record of who-routed-what; auditors must
    reconstruct routing from PR review notes and chat history,
    which are not append-only.
- **When M wins:** if direct-write incidents were rare and isolated.
  PR #162 plus the customer's 2026-05-14 surface establishes they
  are recurrent.

### Option S — Scalable: `Routed-Through:` trailer with lint + hook + tool-bridge carve-out

A commit-message trailer of the form
`Routed-Through: <role>[:<qualifier>]` is required on every commit
past `HARDGATE_AFTER_SHA`. Allowed roles are the canonical taxonomy
roster. A closed tool-bridge qualifier set covers the legitimate
cases where `tech-lead` commits on behalf of the team. Five lint
patterns (R1–R5) catch missing trailer, malformed trailer, role /
file-class mismatch, tool-bridge on disallowed file class, and the
specific CUSTOMER_NOTES.md case. Three-pronged enforcement: lint
script + CI workflow + SessionStart hook, mirroring Hard Rule #11's
shape exactly.

- **Sketch:** `scripts/lint-routing.sh` (POSIX sh, mirroring
  `scripts/lint-questions.sh`); `.github/workflows/role-routing-lint.yml`
  (mirroring `.github/workflows/question-lint.yml`);
  `scripts/hooks/role-routing-reminder.sh` (mirroring
  `scripts/hooks/atomic-question-reminder.sh`). All three are
  additive surface; no existing file changes shape.
- **Pros:**
  - Per-commit, append-only, machine-parseable signal.
  - Symmetric with Hard Rule #11's three-pronged enforcement —
    one shape for both rules reduces cognitive load.
  - Tool-bridge carve-out is closed (enumerated qualifier set per
    customer ruling 7), so the legitimate cases are documented
    and the disallowed ones lint.
  - Downstream-extensible via a per-project allowlist file.
  - Grandfathering precedent already shipped with lint-questions.
- **Cons:**
  - Every commit past the cutoff carries the trailer. Discipline
    burden, bounded but real.
  - Trailer becomes a public contract surface; downstream projects
    inherit it and pay the same burden.
  - The tool-bridge qualifier set is closed; expanding it later
    requires another ADR. That is the intended cost (prevents
    drift) but it is a cost.
  - New lint script + CI workflow + hook on the framework surface.
    Three additive files to maintain.
- **When S wins:** the recurrence pattern (PR #162 + customer's
  2026-05-14 follow-up) plus the existing Hard Rule #11 precedent
  for three-pronged enforcement. This is the framework's actual
  use case.

### Option C — Creative: pre-commit hook that reconstructs ownership from git blame

Drop the trailer entirely. A pre-commit hook (or CI job) reads each
staged file, runs `git blame` against the previous HEAD, and infers
the routing role from the previous owner of each modified line.
Flag commits where the inferred role for any line is inconsistent
with the committer's expected persona (main-session = tech-lead).

- **Sketch:** No commit-message contract; the routing record is
  reconstructed mechanically from the repo's existing history. The
  framework ships a `scripts/lint-routing-from-blame.sh` that
  computes per-line inferred ownership and flags mismatches.
- **Pros:**
  - Zero discipline burden on the commit author (the inference
    runs on existing data).
  - No new commit-message surface to maintain.
  - Catches "tech-lead edited a line that historically belonged to
    a specialist" automatically.
- **Cons:**
  - `git blame` does not know roles; it knows committer identities.
    Mapping committer to role requires a separate registry that
    will drift. In a multi-agent harness where every commit comes
    from the same operator account, the mapping is structurally
    impossible without a trailer or some equivalent annotation.
  - New files have no blame history; the hook would flag every
    new-file commit as "unknown ownership."
  - Refactors that move large blocks across files would
    consistently misattribute.
  - The inference is non-trivially expensive on large diffs and
    grows with repo size.
  - Loses the auditable per-commit binary "did the routing
    discipline apply" signal the customer's 2026-05-14 ask
    implied.
- **When C wins:** if the framework operated in a context where
  every commit carried a distinct committer identity per role
  (e.g., one OS user per agent, signed commits per persona). It
  does not; the harness puts the operator account on every commit.
  C loses on the operator-identity-collision failure mode alone.

## Decision outcome

**Chosen option: S (`Routed-Through:` trailer with lint + hook +
tool-bridge carve-out).**

**Reason:** Option M is insufficient on the same evidence Hard Rule
#11's promotion ran on — prose-only enforcement recurred into a
violation. Option C founders on the harness's structural reality
that every commit carries the same operator identity, so blame
cannot recover role information that was never recorded. Option S
matches the three-pronged enforcement shape the customer has
already accepted for Hard Rule #11, gives Hard Rule #8 a per-commit
mechanical signal, scopes the carve-out for tool-bridge work to a
closed qualifier set per customer ruling 7, applies the trailer
universally past the cutoff per customer ruling 6, and treats
CUSTOMER_NOTES.md violations symmetrically with every other file
class per customer ruling 8. The cost — one trailer line per
commit, one new lint script, one new CI workflow, one new
SessionStart hook — is bounded and tracks the existing pattern.

### Trailer grammar (binding)

- Exactly one `Routed-Through:` trailer per commit. Multiple
  trailers in one commit are a malformed-trailer violation (R2).
- Format: `Routed-Through: <role>` OR
  `Routed-Through: <role>:<qualifier>` (no whitespace around the
  colon between role and qualifier; one space after the leading
  colon-prefix).
- `<role>` is exactly one token from the allowed-roles list
  below (or from the downstream allowlist).
- `<qualifier>` is exactly one token from the tool-bridge
  qualifier set; present only when `<role>` is `tech-lead`.
- The trailer is placed in the commit-message trailer block (one
  blank line above, no blank line within the trailer block),
  per the conventional `git interpret-trailers` shape. Multi-
  line trailers, JSON-in-trailer, comma-separated role lists, and
  free-text qualifiers are all malformed-trailer violations (R2).

### Allowed roles (binding)

The trailer's `<role>` token must be one of the canonical roster
entries (mirroring `CLAUDE.md` § Agent roster) plus the dynamic
SME shape:

- `tech-lead`
- `project-manager`
- `architect`
- `software-engineer`
- `researcher`
- `qa-engineer`
- `sre`
- `tech-writer`
- `code-reviewer`
- `release-engineer`
- `security-engineer`
- `onboarding-auditor`
- `process-auditor`
- `sme-<domain>` (matches `^sme-[a-z][a-z0-9-]*$`; the per-project
  SME naming convention)

A `<role>` token that is not on this list and not on the
downstream allowlist file is a malformed-trailer violation (R2).

`tech-lead` as the routed role is the carve-out case; it is only
valid when accompanied by a tool-bridge qualifier (see below).
A bare `Routed-Through: tech-lead` (no qualifier) on a commit
touching anything other than the orchestration-artifact whitelist
is a tool-bridge-on-disallowed-file-class violation (R4).

### Tool-bridge carve-out (binding)

Per customer ruling 7, the closed qualifier set is exactly:

- `agent-push` — `tech-lead` pushes a specialist's
  in-conversation work to disk because the specialist's harness
  cannot perform the write (sandbox limit, sub-agent
  filesystem boundary).
- `orchestration` — `tech-lead` writes an orchestration artifact
  it owns under Hard Rule #8's narrow exception (entries in
  `docs/OPEN_QUESTIONS.md`, intake-log rows,
  `docs/pm/dispatch-log.md` rows if present, `docs/DECISIONS.md`
  entries, Turn-Ledger entries).
- `ci-fixup` — `tech-lead` commits a minimal CI-driven fix
  (e.g., re-running a generator, regenerating a manifest) where
  the change is purely mechanical and reviewable as a no-op
  semantic change.
- `merge` — merge commit with no net content change.
- `revert` — revert commit with no net content change.
- `rebase` — rebase-produced commit preserving prior authorship;
  no net content change relative to the rebased commit.
- `cherry-pick` — cherry-pick commit preserving prior authorship;
  no net content change relative to the picked commit.

A qualifier not in this set is a malformed-trailer violation (R2).
Expanding the set requires a follow-up ADR; the closed-set
discipline is a feature of this ADR, not an oversight.

Allowed file classes for tool-bridge commits:

- `orchestration` qualifier — writes limited to orchestration
  artifacts: `docs/OPEN_QUESTIONS.md`, `docs/intake-log.md`,
  `docs/pm/dispatch-log.md` (when present), `docs/DECISIONS.md`,
  and Turn-Ledger entries. Writes outside that
  whitelist are R4.
- `agent-push` qualifier — writes limited to the artifact the
  routed specialist would have written. The specialist's
  identity is recorded in a second trailer line
  (`On-Behalf-Of: <role>`) on `agent-push` commits;
  `On-Behalf-Of` is required when and only when the qualifier is
  `agent-push`. Missing or extraneous `On-Behalf-Of` on an
  `agent-push` is R2.
- `ci-fixup` qualifier — writes limited to generated artifacts,
  manifests, and CI configuration. Hand-written code, prose
  deliverables, ADRs, CHANGELOG entries, and customer-truth
  records under this qualifier are R4.
- `merge` / `revert` / `rebase` / `cherry-pick` qualifiers —
  zero-net-content cases. Any non-trivial content delta on these
  commits is R4 (the qualifier is being misapplied to smuggle a
  hand-written change past the routing check).

A `tech-lead:<qualifier>` trailer on a code path, ADR path,
CHANGELOG path, or customer-truth path is R4 unless the
qualifier's whitelist explicitly covers that path.

### Pattern IDs (binding)

Per customer ruling 8, R5 follows the general
`HARDGATE_AFTER_SHA` cutoff — no special early hard-gate for
CUSTOMER_NOTES.md. All five patterns are symmetric in hard-gate
posture and grandfathering.

- **R1 — missing trailer.** Commit past `HARDGATE_AFTER_SHA` has
  no `Routed-Through:` trailer.
- **R2 — malformed trailer.** Trailer present but does not parse:
  multiple trailers, unknown role token, unknown qualifier
  token, whitespace / casing violations, multi-line trailer
  shape, qualifier on a non-`tech-lead` role, `On-Behalf-Of`
  missing on `agent-push` or present on other qualifiers, free-
  text in trailer value.
- **R3 — trailer / file-class mismatch.** Trailer parses, role is
  on the allowed list, but the role does not own the file
  classes touched by the commit. Example: `Routed-Through: tech-writer`
  on a commit that modifies `src/lib/foo.py` (production code,
  owned by `software-engineer`). The file-class → role mapping
  is documented in `scripts/lint-routing.sh`'s embedded table;
  see [Lint implementation surface](#lint-implementation-surface).
- **R4 — tool-bridge on disallowed file class.** Trailer is
  `tech-lead:<qualifier>` and the commit touches a file class
  not on the qualifier's whitelist (per the table above).
- **R5 — `CUSTOMER_NOTES.md` with non-`researcher` trailer.**
  Commit modifies `CUSTOMER_NOTES.md` (or, by Hard Rule #8 and
  FW-ADR-0008, any customer-truth record) and the trailer is
  not `Routed-Through: researcher`. Tool-bridge qualifiers do
  not exempt CUSTOMER_NOTES.md; `tech-lead:agent-push` on
  CUSTOMER_NOTES.md requires `On-Behalf-Of: researcher`, and
  the lint reports R5 when that pair is absent. R5 follows the
  general `HARDGATE_AFTER_SHA` cutoff per customer ruling 8.

### Lint implementation surface

- **Script.** `scripts/lint-routing.sh`, mirroring
  `scripts/lint-questions.sh`'s shape: POSIX sh, `set -eu`,
  `LANG=C`/`LC_ALL=C`, no bashisms, no arrays, no `pipefail`.
- **Flags.** `--summary`, `--since <sha>`, `--files "<paths>"`
  (with `--files` reading commit-message bodies from a fixture
  corpus for the self-test).
- **Hard-gate placeholder.** `HARDGATE_AFTER_SHA` constant set
  to the literal string `DEFERRED_SET_AT_HARDGATE_PR` at
  ADR-accept time. At a future MINOR release the orchestrator
  records the actual cutoff SHA, mirroring the
  `lint-questions.sh` precedent (the placeholder rolls to a
  real SHA in the PR that ships the hard-gate switch). Until
  then the script runs warning-only (exit 0 with WARN
  summary).
- **Default file set.** Walks recent commits' trailers via
  `git log --format=%B` rather than a fixed file list (this
  lint runs against commit messages, not source files). The
  default in-repo mode reads the last 50 commits' trailers and
  reports per-commit findings.
- **File-class → role table.** Embedded in the script as a
  static lookup. Initial mapping (subject to evolution via
  future ADRs or downstream allowlist):

  | File class (glob) | Owning role |
  |---|---|
  | `src/**`, `lib/**`, `scripts/**` (non-hook) | `software-engineer` |
  | `docs/adr/**` | `architect` |
  | `docs/templates/**` | `architect` (+ `tech-writer` on prose-only edits) |
  | `docs/requirements*.md` | `architect` |
  | `docs/architecture*.md` | `architect` |
  | `docs/pm/**` | `project-manager` |
  | `CUSTOMER_NOTES.md`, `docs/customer-notes/**` | `researcher` |
  | `docs/prior-art/**`, `docs/library/**` | `researcher` |
  | `tests/**`, `qa/**` | `qa-engineer` |
  | `.github/workflows/**`, `migrations/**`, `Dockerfile*` | `release-engineer` |
  | `docs/security/**`, security policy / advisory files | `security-engineer` |
  | `docs/CHANGELOG.md`, `CHANGELOG.md`, `docs/release-notes/**` | `release-engineer` |
  | `.claude/agents/**`, `docs/agents/**` | `tech-writer` (+ `architect` for role-contract changes) |
  | `docs/OPEN_QUESTIONS.md`, `docs/intake-log.md`, `docs/pm/dispatch-log.md` | `tech-lead:orchestration` |

  Multi-owner cells (e.g., `docs/templates/**`) accept either
  role on the trailer; lint reports R3 only when no acceptable
  role matches.

- **Self-test fixture corpus.** Under
  `tests/fixtures/lint-routing/` — pairs of `(commit-message,
  expected-pattern-id)` for each of R1–R5 plus a no-violation
  control set. Mirrors the `lint-questions` fixture pattern.

### CI workflow

- **File.** `.github/workflows/role-routing-lint.yml`.
- **Shape.** Mirrors `.github/workflows/question-lint.yml`:
  `pull_request` + `push` to `main` + `workflow_dispatch`,
  `permissions: contents: read`, single step that runs
  `./scripts/lint-routing.sh --since HARDGATE_AFTER_SHA --summary`.
- **Hard-gating.** The workflow blocks the PR on whatever exit
  code the script returns. Warning-only until the
  `HARDGATE_AFTER_SHA` constant rolls from
  `DEFERRED_SET_AT_HARDGATE_PR` to a real SHA at a future
  MINOR-release boundary. Post-cutoff the workflow becomes
  CI-blocking.

### SessionStart hook

- **File.** `scripts/hooks/role-routing-reminder.sh`.
- **Shape.** Mirrors `scripts/hooks/atomic-question-reminder.sh`:
  prints a banner at SessionStart citing Hard Rule #8 verbatim
  (per `CLAUDE.md` § Hard rules item 8) and naming the
  `Routed-Through:` trailer convention as the mechanical
  signal. Cites the lint hard-gate posture and the
  HARDGATE_AFTER_SHA cutoff.
- **Wiring.** Added to `.claude/settings.json`'s `SessionStart`
  hooks array alongside `version-check.sh` and
  `atomic-question-reminder.sh`. Timeout 5 seconds. Existence-
  guarded `[ -x ... ] && ... || true` so a missing hook does not
  fail the session.

### Downstream override surface

Downstream projects extend the role list via
`.routing-allowlist` at the project root. Schema:

- One role token per line, comments via `#`-prefix, blank
  lines ignored.
- Tokens follow the same regex as the canonical roster
  (`^[a-z][a-z0-9-]*$`); the `sme-` prefix discipline is not
  enforced at this layer — downstream may name a project-local
  role anything that matches the regex.
- `scripts/lint-routing.sh` reads `.routing-allowlist` if
  present and merges it into the allowed-roles set before
  applying R2.
- The file is project-local state; framework upgrades do not
  touch it. The presence of `.routing-allowlist` is documented
  in `docs/framework-project-boundary.md` (follow-up
  `tech-writer` work; not in this ADR's mandate).

`.routing-allowlist` does not extend the tool-bridge qualifier
set; that set is framework-bound and changes only via a follow-
up ADR. Downstream projects that need a new qualifier file an
upstream issue per `docs/ISSUE_FILING.md`.

### Grandfathering

All commits at or before `HARDGATE_AFTER_SHA` are exempt from
R1–R5. Identical model to Hard Rule #11's
`scripts/lint-questions.sh` cutoff. Until the constant rolls
from `DEFERRED_SET_AT_HARDGATE_PR` to a real SHA, the lint runs
warning-only and no commits are blocked. Post-cutoff: commits
*at or before* the SHA remain warning-only; commits *after* the
SHA are hard-gated.

## Consequences

### Positive

- Hard Rule #8 acquires the same three-pronged enforcement shape
  Hard Rule #11 was promoted into on 2026-05-14. Symmetry across
  the two rules reduces the cost of explaining either.
- Per-commit, append-only, machine-parseable record of who-
  routed-what. PR #162's class of incident becomes mechanically
  detectable at commit time rather than at PR-review time.
- Tool-bridge work is explicitly named and bounded. The
  legitimate cases (sandbox-limited specialist work, orchestration
  artifacts, merge / revert / rebase / cherry-pick mechanics)
  have a documented annotation; the illegitimate cases (hand-
  written code under a tool-bridge qualifier) lint.
- CUSTOMER_NOTES.md gets a named pattern (R5) and is treated
  symmetrically with every other file class per customer ruling
  8 — no special early hard-gate complicating the cutoff story.
- Downstream extensibility via `.routing-allowlist` is present
  from day one; per-project SME roles can land without an
  upstream change.
- Grandfathering precedent is reused unchanged from
  `lint-questions.sh`; no new cutoff vocabulary.

### Negative / trade-offs accepted

- Every commit past the cutoff carries the trailer. Bounded
  discipline burden, but real — the framework now charges one
  trailer line per commit.
- The trailer is a public contract surface. Every downstream
  project inherits it; the shape cannot change without breaking
  downstream lint runs. Future schema bumps are framework-
  ADR events, not patch-release events.
- The tool-bridge qualifier set is closed (per customer ruling
  7). Expanding it requires another ADR. This is the intended
  cost — it prevents drift — but it is a cost.
- The lint script, CI workflow, and SessionStart hook are three
  additive files on the framework surface. Maintenance burden
  scales with the framework's own velocity.
- The file-class → role table embedded in the lint script is a
  judgement call; mismatches between the table and emergent
  ownership will lint as R3 false-positives until the table
  evolves. Customer ruling 7 leaves the table at architect's
  discretion to amend; downstream override is via
  `.routing-allowlist` on roles only, not on the file-class
  table.
- Operators committing tool-bridge work must remember the
  qualifier set. The SessionStart hook surfaces the set at
  session start; CI catches misses post-hoc; there is no
  pre-commit hook in this ADR's scope.

### Follow-up ADRs

- None required for this ADR's scope. A future ADR may revisit
  the tool-bridge qualifier set if recurrent legitimate cases
  fall outside the closed seven. A future ADR may also extend
  the file-class → role table if a new artifact class emerges
  (e.g., infrastructure-as-code under `release-engineer` vs.
  `sre`).

## Relationship to other rules and ADRs

- **Hard Rule #8 (`CLAUDE.md`).** This ADR does not add a new
  Hard Rule; it adds enforcement for the existing #8. The
  customer's stated preference against Hard Rule proliferation
  (recorded 2026-05-14 in the same session as rulings 6, 7, 8)
  is honored.
- **Hard Rule #11 (`CLAUDE.md`).** Same enforcement shape — lint
  hard-gate + SessionStart hook + numbered Hard Rule. Documented
  here for symmetry. Maintainers of one prong should consider
  the parallel prong on the other rule when making changes
  (e.g., a change to `lint-questions.sh`'s `HARDGATE_AFTER_SHA`
  workflow likely wants the same change applied to
  `lint-routing.sh`).
- **FW-ADR-0008 (tech-lead orchestration boundary).** This ADR
  is the mechanical-enforcement layer for FW-ADR-0008's prose
  boundary. FW-ADR-0008 names the rule; this ADR makes it
  machine-checkable. The `On-Behalf-Of` second trailer on
  `agent-push` commits is the auditable record FW-ADR-0008's
  "customer truth has one steward" commitment needs at the
  commit level.
- **FW-ADR-0002 (upgrade content verification).** The
  `.routing-allowlist` file is project-local state, not
  framework-managed; upgrades do not touch it. Same
  customisation-wins posture FW-ADR-0002 commits to.

## Verification

- **Success signal:** Post-cutoff CI runs show R1–R5 hits drop
  to zero on `main` over a 4-week observation window;
  PR-review notes stop citing direct-write incidents in their
  blocking-findings category; the `agent-push` /
  `On-Behalf-Of` pair appears on the expected set of commits
  (tool-bridge work the operator has historically performed
  for specialists).
- **Failure signal:** Operators routinely use a tool-bridge
  qualifier to land hand-written code (R4 hits cluster on the
  same operator-commit pattern); the file-class → role table
  produces R3 false-positives at a rate that swamps real R3
  signal; downstream projects file upstream issues asking for
  qualifier additions at a rate of more than one per MINOR
  release.
- **Review cadence:** at the next MINOR release after the
  hard-gate cutoff ships, then session-anchored every two
  MINOR releases thereafter per the time-based-cadences rule
  in `CLAUDE.md`. Reconsider if any failure signal fires, or
  if `.routing-allowlist` adoption patterns suggest the
  framework-managed role list is too narrow.

## ADR-internal follow-ups

Recorded here per the customer's instruction not to escalate
further on this turn. None of these block the ADR's acceptance;
they are work the implementing specialists pick up after merge.

- The file-class → role table embedded in
  `scripts/lint-routing.sh` is an initial mapping. The first
  4 weeks of CI runs will surface false-positive patterns;
  `software-engineer` adjusts the table in a follow-up patch,
  not via ADR.
- `docs/framework-project-boundary.md` needs a paragraph on
  `.routing-allowlist` semantics. `tech-writer` follow-up.
- `docs/TEMPLATE_UPGRADE.md` should call out the
  `.routing-allowlist` file in its "do not commit upstream"
  guidance. `tech-writer` follow-up.
- `docs/CHANGELOG.md` entry for the trailer convention's
  introduction. `release-engineer` follow-up at MINOR-boundary
  release.
- Consider whether `agent-push` commits should also carry a
  task-ID trailer (`Task: T-NNNN`) for cross-referencing into
  `docs/tasks/`. Out of scope for this ADR; named here so a
  future ADR can pick it up if the routing record's audit
  value warrants the extra discipline.
- Consider whether the `On-Behalf-Of` trailer should accept a
  comma-separated multi-specialist value for commits that bridge
  more than one specialist's work in the same `agent-push`. Out
  of scope for this ADR; current shape is single-specialist per
  `agent-push` and operators split multi-specialist work across
  multiple commits.
- `software-engineer` follow-ups surfaced by `code-reviewer-hr8`
  (2026-05-14) post-merge:
  - `.routing-allowlist` downstream-override surface promised in
    §"Downstream override surface" but not yet implemented in
    `scripts/lint-routing.sh`'s role-validation path (FW-ADR-0011
    §"Downstream override surface").
  - File-class → role table drift between ADR §"Lint implementation
    surface" (14 rows) and `scripts/lint-routing.sh`'s 8-class
    `classify_path` (rows for `docs/templates/**`, `docs/pm/**`,
    `docs/library/**`, `docs/prior-art/**`, `CHANGELOG.md`,
    `.claude/agents/**`, `docs/agents/**`, `migrations/**`,
    `Dockerfile*` not yet implemented).
  - Multi-`Routed-Through:` detection (ADR §"Trailer grammar"
    line 248 says R2 fires on multiple trailers; current
    `extract_trailer` takes the last occurrence silently).
  - Shellcheck-class cleanup in `scripts/lint-routing.sh`
    (dead-code locals at lines 432-434; redundant docs glob
    patterns at line 293).

## Links

- Upstream issues:
  - PR #162 (the largest single-turn direct-write incident on
    record; the trigger for this ADR's "stronger enforcement"
    customer ask)
- Related ADRs:
  - FW-ADR-0008 — Tech-lead orchestration boundary (prose layer;
    this ADR is the mechanical-enforcement layer)
  - FW-ADR-0002 — Upgrade content verification (project-local
    state precedent for `.routing-allowlist`)
- Related artefacts:
  - `CLAUDE.md` § Hard rules item 8 (the rule this ADR enforces)
  - `CLAUDE.md` § Hard rules item 11 (the symmetry precedent)
  - `scripts/lint-questions.sh` (the shape `scripts/lint-routing.sh`
    mirrors)
  - `.github/workflows/question-lint.yml` (the shape
    `.github/workflows/role-routing-lint.yml` mirrors)
  - `scripts/hooks/atomic-question-reminder.sh` (the shape
    `scripts/hooks/role-routing-reminder.sh` mirrors)
  - `.claude/settings.json` § SessionStart hooks array (the
    wiring surface)
  - `CUSTOMER_NOTES.md` rulings 6, 7, 8 of 2026-05-14 (the
    customer-truth inputs encoded in this ADR)
- External references: MADR 3.0 (`https://adr.github.io/madr/`);
  `git interpret-trailers(1)` (trailer-block grammar reference).
