# v0.12.0 Release Review — IEEE 1028 audit of the v0.12.0 bundle

**Date:** 2026-04-23
**Reviewer:** code-reviewer (audit mode, per §2.7b)
**Scope:** the entire uncommitted working-tree delta against HEAD
(`v0.11.0`, `ee9729d`) interpreted as the v0.12.0 bundle, audited
against the repo's own `CHANGELOG.md` v0.12.0 section and the
workflow-redesign memo at `docs/proposals/workflow-redesign-v0.12.md`.

---

## §0 Summary

**Verdict: APPROVE. Clear to tag v0.12.0.**

Seven files modified, six new files (one directory `docs/proposals/`
added). Every substantive working-tree change traces to a CHANGELOG
v0.12.0 entry, and every CHANGELOG entry has a landed artifact.
Scripts have correct shebangs, `set -euo pipefail`, and executable
bits. New templates (`prior-art-template.md`,
`proposal-template.md`) follow the section-skeleton conventions of
their peers under `docs/templates/`. The new `process-auditor.md`
agent mirrors the `onboarding-auditor.md` frontmatter shape.

The workflow-redesign bundle conforms to the customer's 2026-04-23
"bundle Phases 1+2 in v0.12.0, defer Phase 3 to v0.13.0" ruling.
All six Phase-1+2 items land; no Phase-3 artifact leaks into the
tree (`docs/templates/architecture-template.md` is untouched, no
Minimalist/Scalable/Creative expansion). `CHANGELOG.md` v0.13.0
section correctly lists `#33 Three-Path Rule` under `Pending` with
an explicit "Deferred from v0.12.0" note.

No Hard Rule conflicts. No new Hard Rules introduced (Hard Rule #7
unchanged; new workflow rules are task-level binding rules within
agent files, not additions to the CLAUDE.md `## Hard rules` list).
No safety-critical code touched.

### Top-3 issues

None rise to block-level. The three observations below are
cosmetic / documentation-polish and may ship in v0.12.1 or be
ignored.

1. **Trigger annotation in `tech-lead.md` §Job item 2 treats the
   architect stage as "Phase-3 feature, currently optional"** but
   `CHANGELOG.md` bills Phase 3 as `Deferred` rather than
   `optional-until-v0.13.0`. The tech-lead annotation is the more
   operationally useful framing (it tells tech-lead what to do
   *today*); the CHANGELOG framing is cleaner from a release-notes
   standpoint. No action required, but a future reader will
   reconcile the two.
2. **`docs/templates/proposal-template.md` §8.2 references
   `docs/intake-log.md`** as a citation target for tech-lead
   ratification. That file is per-project (scaffolded from
   `docs/templates/intake-log-template.md`), not template-level. A
   template pointing to a per-project path is conventional in this
   repo (e.g., `docs/requirements.md` referenced from other
   templates) but the reader has to know the convention. Not a
   defect.
3. **`docs/sme/CONTRACT.md` §7 revision log row dated 2026-04-23**
   cites `tech-lead + researcher` as ratifier. `CHANGELOG.md`
   v0.12.0 entry for #6 describes this as "consolidated reference
   ... replaces prior scattered references" — i.e., this is a
   memo, not a new ruling. Correct. No action.

---

## §1 CHANGELOG ↔ artifact traceability

Every bullet under v0.12.0 `Added` (including the "Added
(continued)" block) matches a landed artifact:

| CHANGELOG row | Landed artifact | Status |
|---|---|---|
| #36 new-agent registration warning | `scripts/upgrade.sh` lines 230–246 (new block detecting `.claude/agents/*.md` in `added[]`, prints `ACTION REQUIRED`); `CLAUDE.md` lines 89–95 (restart-requirement paragraph) | Complete |
| #6 SME contract decision memo | `docs/sme/CONTRACT.md` (new, 157 lines) | Complete |
| #5 option 2 — repair-script pointer in unzipped-state warning | `scripts/version-check.sh` lines 45–55 (two-option recovery block naming `repair-in-place.sh`) | Complete |
| #25 Cultural-disruptor / process-auditor agent | `.claude/agents/process-auditor.md` (new, 200 lines); routing in `tech-lead.md` line 95; roster in `CLAUDE.md` line 406 | Complete |
| #32/#33/#34/#35 design memo | `docs/proposals/workflow-redesign-v0.12.md` (new, 538 lines) | Complete |
| Agent tool-grant fix (pre-flight) | `.claude/agents/onboarding-auditor.md` frontmatter `tools:` now includes `Write`; `process-auditor.md` frontmatter includes `Write` | Complete |
| Claude Code harness anomaly (architect spawns not inheriting declared tools) | Provenance entry only; no code artifact expected | Complete (documentation) |
| Workflow redesign Phase 1+2 — prior-art template | `docs/templates/prior-art-template.md` (new) | Complete |
| Workflow redesign Phase 1+2 — proposal template with §Duel annex | `docs/templates/proposal-template.md` (new, §8 is Duel) | Complete |
| `researcher.md` §5 durable-artifact rule + re-verification cadence | `.claude/agents/researcher.md` §Job item 5 (rewritten; now lines ~77–98) | Complete |
| `software-engineer.md` pre-code workflow section | `.claude/agents/software-engineer.md` new section "Pre-code workflow (binding, workflow-pipeline stage 3+4)" (~30 lines after Escalation-format block) | Complete |
| `qa-engineer.md` Solution Duel section | `.claude/agents/qa-engineer.md` new section "Solution Duel (binding, workflow-pipeline stage 4)" (+43 lines after Adversarial stance) | Complete |
| `security-engineer.md` duel participation on Rule-#7 paths | `.claude/agents/security-engineer.md` new section "Solution Duel participation (Hard-Rule-#7 paths)" (+12 lines) | Complete |
| `tech-lead.md` Trigger annotation + routing rows | `.claude/agents/tech-lead.md` §Job item 2 (+27 lines); routing table +3 rows (prior-art, proposal, duel) + 1 row for process-auditor | Complete |
| `task-template.md` DoR rows + `Trigger:` field | `docs/templates/task-template.md` Identification block +2 lines (`Trigger:` field); DoR +20 lines (two new checkbox rows) | Complete |

**Traceability is clean — no CHANGELOG row is missing an artifact,
and (see §3) no substantive working-tree change is missing a
CHANGELOG row.**

---

## §2 Per-file findings (non-clean files only)

### §2.1 `docs/proposals/workflow-redesign-v0.12.md`

- **Approve.** Memo shape is coherent: §0 executive summary, §1
  pipeline composition, §2 mechanical trigger, §3 integration
  with existing gates, §4 artifact catalogue, §5 routing
  changes, §6 agent-file changes, §7 escape hatches, §8 worked
  examples, §9 risks, §10 recommendation + phasing.
- **Approve.** §10 final paragraph explicitly authorizes the
  bundled-1+2 option that the customer chose: *"If the customer
  prefers a single-release bundle, **Phases 1+2 in v0.12.0** is
  defensible."* The v0.12.0 implementation matches this path.
- **Approve.** §Note on architect tool-grant gap cleanly flags
  the harness issue as upstream Claude Code, not template defect,
  and explains the manual-persistence workaround.
- **Observation.** Memo is 538 lines — longer than most
  `docs/proposals/` artifacts will be once the pipeline runs
  regularly. Fine for an architect-authored memo that defines
  the pipeline; a one-liner at top would orient readers who
  arrive from the CHANGELOG entry.

### §2.2 `.claude/agents/process-auditor.md`

- **Approve.** Frontmatter (`name`, `description`, `tools`,
  `model`) matches the shape of `onboarding-auditor.md`. Tool
  grant `Read, Grep, Glob, Bash, Write, SendMessage` is
  consistent with a writer of `docs/pm/PROCESS_AUDIT-*.md` that
  needs to check the repo and escalate.
- **Approve.** §Mode + §Scope-boundaries binding list is explicit
  and symmetric with `onboarding-auditor.md` (what it audits vs
  what it does not). Rule "You do not audit the IP policy or
  hard rules" is good — it prevents the auditor from becoming
  an end-run around the amendment paths for those.
- **Approve.** Cadence rule (§Cadence) is session-anchored
  ("every 2nd or 3rd milestone close"), consistent with
  `CLAUDE.md` § "Time-based cadences".
- **Observation.** §Mode names `docs/DECISIONS.md` as an
  input. No template for DECISIONS.md exists under
  `docs/templates/`; it is defined inline in `tech-lead.md`
  lines 227–233. This is pre-existing (v0.11.0) and not a
  v0.12.0 regression, but worth tracking as a future
  template-ification candidate.

### §2.3 `docs/templates/prior-art-template.md`

- **Approve.** Section skeleton (Task reference, Search scope,
  Canonical solution, Candidates, Pitfalls, Recommendation,
  Metadata) matches the memo §4.1 spec. Tier-1/2/3 source
  labels align with `researcher.md` §Job item 1.
- **Approve.** §7 Metadata block carries `Last verified:` and
  library versions, enabling the re-verification cadence in
  `researcher.md` §Job item 5.
- **Approve.** Retention clause at bottom of §7 matches the
  memo §4.1 durable-artifact policy.

### §2.4 `docs/templates/proposal-template.md`

- **Approve.** §Duel (§8) is an annex inside the proposal, not
  a separate file, matching the memo §4.4 "single-artifact"
  rule. §8.1 Findings + §8.2 Rebuttals split mirrors the
  memo's qa-engineer / software-engineer joint-stewardship
  model.
- **Approve.** §8.3 Status block (`Round: 1 (default) /
  escalated after round 1`) operationalises the `qa-engineer.md`
  round-limit rule.
- **Approve.** §8 explicitly names `security-engineer` as a
  joint duelist on Hard-Rule-#7 paths, matching the memo §9.5
  and `security-engineer.md`'s new section.
- **Note (issue §0 #2).** §8.2 references `docs/intake-log.md`
  as a citation target; that's a per-project path, not a
  template path. Convention-consistent with other template
  references to `docs/requirements.md` etc., but worth noting.

### §2.5 `docs/sme/CONTRACT.md`

- **Approve.** Consolidates the Fix-C hybrid ruling (customer
  2026-04-19) that previously lived only in `CHANGELOG.md` v0.11.0
  + `CUSTOMER_NOTES.md`. §1 Why-this-exists, §2 Two modes, §2.3
  Not-an-SME, §3 Rule-of-thumb table, §4 Creation procedure, §5
  Interaction with researcher, §6 When-the-ruling-applies, §7
  Revision log, §8 Cross-references.
- **Approve.** §8 Cross-references correctly point at
  `CLAUDE.md`, `sme-template.md`, `researcher.md`,
  `CUSTOMER_NOTES.md`, and upstream issue #6. Each exists.
- **Approve.** Precedence clause in the intro
  ("ruling > this document > agent files > examples") is
  unambiguous and prevents this file from competing with the
  underlying ruling.

### §2.6 `.claude/agents/researcher.md` (§Job item 5)

- **Approve.** Rewrite of §Job item 5 is additive to the
  pre-existing prior-art-scan bullet: the durable-artifact
  requirement is scoped to "triggered tasks" per memo §2;
  untriggered tasks retain the old ambient behaviour.
- **Approve.** Re-verification cadence (major-version bump +
  milestone close for artifacts older than 30 days) matches
  memo §9.4 and is explicitly cross-referenced to §6 pronoun
  re-verification as the same cadence pattern.

### §2.7 `.claude/agents/software-engineer.md`

- **Approve.** New "Pre-code workflow" section lands cleanly
  between the Escalation-format block and the Constraints
  block. Four numbered rules: (1) proposal before code, (2)
  respond to duel, (3) below-threshold behaviour, (4) escape
  hatches are tech-lead calls not engineer calls.
- **Approve.** Constraints block gains the new bullet "Do not
  start code on a triggered task until the proposal's Duel
  section is closed" — this is the code-start gate
  operationalised as a constraint.
- **Approve.** No conflict with existing "Do not silently
  expand scope" or "Diffs with short rationale. No essays"
  rules — proposals are pre-code artifacts, not essays in
  diffs.

### §2.8 `.claude/agents/qa-engineer.md`

- **Approve.** New "Solution Duel" section lands after the
  existing "Adversarial stance (binding)" section. Composes
  cleanly: duel is the same adversarial posture applied
  earlier on a different artifact.
- **Approve.** §Round-limit block precisely matches memo §6
  round-limit rule: one round, then tech-lead escalation, then
  Hard-Rule-#4 customer escalation if tech-lead can't resolve.
- **Approve.** §Hard-Rule-#7 paths block precisely matches
  memo §9.5 (security-engineer as joint duelist, not
  substitute).
- **Approve.** §Below-threshold block matches memo §2 trigger
  semantics (no duel when trigger=none; diff-time adversarial
  stance still fires).

### §2.9 `.claude/agents/security-engineer.md`

- **Approve.** New "Solution Duel participation" section is
  scoped to Hard-Rule-#7 paths (trigger clause 5 only), per
  memo §9.5. Explicitly distinguishes design-time duel
  participation from release-time Hard-Rule-#7 sign-off —
  the latter is unchanged.
- **Approve.** No conflict with the existing
  `security-engineer` responsibilities or with Hard Rule #7.

### §2.10 `.claude/agents/tech-lead.md`

- **Approve.** §Job item 2 gains the Trigger-annotation
  sub-block (+27 lines). Clauses (1)–(6) quoted verbatim from
  memo §2. Pipeline dispatch order (researcher → architect →
  engineer → qa → engineer-revise → code) matches memo §1.
- **Approve.** Escape-hatch summary (§7 of the memo) is
  one-paragraph and points at the memo for detail, rather than
  duplicating it. Good — single source of truth.
- **Approve.** Routing table gains four new rows:
  process-auditor, prior-art (→ researcher), proposal
  (→ software-engineer), Solution Duel (→ qa-engineer
  + security-engineer). All four match the memo §5 routing-
  changes list.
- **Note (issue §0 #1).** Item (b) in the pipeline dispatch
  list says "`architect` → ADR with three alternatives when
  ADR trigger also fires [stage 2, **Phase-3 feature, currently
  optional**]". This is operationally correct — Phase 3 is
  deferred, so architect's three-alternative expansion is
  optional in v0.12.0. The CHANGELOG phrasing ("Deferred from
  v0.12.0") is cleaner from a release-notes standpoint. Both
  are correct; the reader reconciles.

### §2.11 `docs/templates/task-template.md`

- **Approve.** Identification block gains `Trigger:` field
  with annotation source note ("annotated by `tech-lead` at
  dispatch — see DoR").
- **Approve.** DoR gains two new checkbox rows. Row 1
  (trigger annotated) is the mechanical gate; row 2 (pipeline
  artifacts present if trigger fires) lists exactly four
  artifact requirements (prior-art, ADR-with-three-alts,
  proposal, duel) with the Phase-3 ADR-expansion flagged as
  "optional until v0.13.0". Matches memo §3.
- **Approve.** DoR addition does not conflict with the
  existing rows (acceptance-criteria, test-coverage, safety-
  critical sign-off, estimate).

### §2.12 `.claude/agents/onboarding-auditor.md`

- **Approve.** One-line frontmatter change: `tools:` gains
  `Write`. Matches CHANGELOG "Agent tool-grant fix" entry.
  The agent writes `docs/pm/FRICTION_REPORT-<date>.md` (per
  `onboarding-auditor.md` §Output) and previously lacked the
  grant to do so; the gap was a v0.11.0 ship defect caught by
  `scripts/audit-agent-tools.sh` pre-flight.

### §2.13 `scripts/upgrade.sh`

- **Approve** shape. Shebang `#!/usr/bin/env bash`, executable,
  `set -euo pipefail` header per `docs/style-guides/bash.md`.
- **Approve.** New block (lines 230–246 in the hunk) iterates
  `added[]` (already-computed earlier in the script), filters
  for `.claude/agents/*.md`, prints the `ACTION REQUIRED`
  warning if any match. Idempotent with respect to the rest
  of the summary output.
- **Approve.** Comment block explains why `sme-*.md` doesn't
  need filtering (user-owned, never shipped, never in
  `added`). Good forward documentation.

### §2.14 `scripts/version-check.sh`

- **Approve.** Warning-message rewrite (lines 45–55 of the
  hunk) replaces the "if an in-place repair script ships
  later…" placeholder with two concrete recovery options
  naming `scripts/repair-in-place.sh --dry-run` and
  `scripts/scaffold.sh`. Clear, action-oriented.
- **Approve.** No behaviour change in the detection logic;
  only the user-facing message changed.

### §2.15 `CLAUDE.md`

- **Approve.** Two changes only:
  1. New paragraph after the `scripts/upgrade.sh [--dry-run]`
     line (lines 89–95 of the updated file): restart
     requirement when new agents are added. Correctly cites
     upstream issue #36.
  2. Roster table gains `process-auditor.md` row; existing
     `onboarding-auditor.md` row clarifies "first half" so
     the two peer halves of #25 are distinguishable.
- **Approve.** No change to the Hard Rules list — v0.12.0
  does not introduce a new Hard Rule. The workflow-pipeline
  rules are agent-level binding, not CLAUDE.md Hard Rules.

### §2.16 `CHANGELOG.md`

- **Approve.** v0.12.0 section is well-shaped. `Added` block
  covers the small items (#36, #6, #5-option-2); `Added
  (continued)` block covers the workflow-redesign bundle.
  `Pending` is correctly `(none — all v0.12.0 scope items
  landed or deferred)`.
- **Approve.** v0.13.0 `Pending` section correctly lists
  `#33 Three-Path Rule` with an explicit "Deferred from
  v0.12.0 per architect's phased-rollout recommendation"
  note. Traceability to the memo §10 is preserved.
- **Note.** The harness-anomaly entry (architect tool-grant
  gap) is correctly marked as provenance, not a template
  change. Customer-action line ("the customer should report
  at github.com/anthropics/claude-code/issues if they want
  it fixed upstream") is useful for the next session.

---

## §3 Drift — artifacts without CHANGELOG rows; CHANGELOG rows without artifacts

**Artifacts without CHANGELOG rows:** none detected. Every new
file and every modified file corresponds to a CHANGELOG v0.12.0
bullet.

**CHANGELOG rows without artifacts:** none. Every bullet in the
v0.12.0 `Added` + `Added (continued)` blocks has a matching
landed file (see §1 matrix).

**v0.11.0 follow-through still holding.** Prior review
(`V0_11_0_RELEASE_REVIEW.md`) flagged the `#15 customer →
product owner rename` as falsely listed in v0.11.0. In the
v0.12.0 CHANGELOG section and in `v0.13.0 Pending`, that
item is correctly absent (neither claimed as landed nor
newly-deferred — it's owned by the v0.11.0 Pending block's
"#15 customer → product owner rename (breaking; needs
migrations/0.12.0.sh; MAJOR-track ...)"). Consistent.

**Prior-review C-1/C-2/C-3 status** (v0.11.0 conditions):

- **C-1 (Taxonomy §2.4c §4.x numbering).** Not re-audited in
  this pass — out of v0.12.0 scope. If still open, it should
  land in v0.12.1 or be recorded in v0.13.0 Pending.
- **C-2 (qa-engineer does not list its new artefacts).**
  Addressed. `qa-engineer.md` now lists the 8 QA templates
  in its §"Per-project QA artefacts owned" table and names
  the intake-conformance audit as milestone-close work.
- **C-3 (style-guides orphan).** Addressed.
  `software-engineer.md` line 20 now points at
  `docs/style-guides/` per language; `code-reviewer.md` line
  66 instructs reviewers to cite the style guide in
  findings.

---

## §4 Cross-reference errors

None that block the tag.

1. `docs/proposals/workflow-redesign-v0.12.md` is referenced
   from `prior-art-template.md`, `proposal-template.md`,
   `researcher.md`, `software-engineer.md`, `qa-engineer.md`,
   `security-engineer.md`, `tech-lead.md`, `task-template.md`,
   `CHANGELOG.md` — each reference hits an existing §
   (§1 / §2 / §6 / §7 / §9.5 / §10). All resolve.
2. `docs/sme/CONTRACT.md` §8 cross-references all resolve.
3. `process-auditor.md` §Mode names five per-project files
   (`CUSTOMER_NOTES.md`, `LESSONS.md`, `CHANGES.md`,
   `OPEN_QUESTIONS.md`, `DECISIONS.md`, `intake-log.md`).
   Four of the five have a template under `docs/templates/`
   or `docs/templates/pm/`; `DECISIONS.md` has no template
   (it is defined inline in `tech-lead.md` lines 227–233).
   Pre-existing and out of v0.12.0 scope.
4. Memo §Note names `scripts/audit-agent-tools.sh` — the
   script exists (v0.11.0). Memo's claim that the script
   "checks declared tools, not dispatched tools" is factually
   correct (verified by inspection of the script's logic).

---

## §5 Hard-rule conflicts

None.

- **Hard Rule #1 (only `tech-lead` interfaces with customer).**
  Workflow-pipeline dispatches by `tech-lead` preserve this —
  researcher, architect, engineer, qa-engineer all escalate to
  `tech-lead` on disputes (per memo §6 round-limit, per
  `qa-engineer.md`, per `software-engineer.md`). No agent
  addresses customer directly on duel findings.
- **Hard Rule #2 (no production code on safety-critical
  without customer sign-off).** Unchanged. Memo §9.5 explicitly
  confirms proposal is *upstream of* #2, not a substitute.
- **Hard Rule #3 (no commit without code-reviewer review).**
  Unchanged. Pipeline ends with code → existing review flow.
- **Hard Rule #4 (live customer approval on safety-critical /
  irreversible / customer-flagged-critical).** Unchanged.
  Escape hatch #2 in memo §7 (emergency security patch) is
  the same shape as the existing Hard-Rule-#4 live-approval
  path.
- **Hard Rule #5 (prefer paraphrase).** Unchanged; prior-art
  artifact explicitly cites-not-quotes.
- **Hard Rule #6 (agent escalation hygiene).** Unchanged;
  pipeline's round-limit / tech-lead escalation preserves the
  "check CUSTOMER_NOTES and peer agents first" rule.
- **Hard Rule #7 (security-engineer sign-off on auth / secrets /
  PII / network-exposed).** Unchanged. `security-engineer.md`
  new section explicitly distinguishes design-time duel
  participation from release-time sign-off.

No new Hard Rule introduced. (Task-level binding rules in agent
files — e.g., "code without a matching proposal under trigger is
a DoR violation" — are agent-scope and enforceable via task DoR,
not CLAUDE.md-level Hard Rules.)

---

## §6 Workflow-redesign bundle conformance check

**Customer ruling:** 2026-04-23 — bundle Phase 1 + Phase 2 in
v0.12.0; defer Phase 3 (#33 Three-Path) to v0.13.0.

### Phase 1 — Researcher-First (#34) + Options Before Actions (#32) — MUST be present

| Item | Artifact | Status |
|---|---|---|
| Prior-art durable-artifact rule on triggered tasks | `researcher.md` §Job item 5 | Present |
| Prior-art template | `docs/templates/prior-art-template.md` | Present |
| Re-verification cadence (major-bump + 30-day milestone-close) | `researcher.md` §Job item 5 end | Present |
| Proposal before code on triggered tasks | `software-engineer.md` §"Pre-code workflow" #1 | Present |
| Proposal template | `docs/templates/proposal-template.md` | Present |
| `Trigger:` field in task Identification | `task-template.md` Identification block | Present |
| DoR row: trigger annotated | `task-template.md` DoR | Present |
| DoR row: pipeline artifacts present | `task-template.md` DoR | Present |
| Tech-lead Trigger-annotation rule | `tech-lead.md` §Job item 2 sub-block | Present |
| Escape hatches summary in tech-lead | `tech-lead.md` §Job item 2 end | Present |
| Routing rows for prior-art + proposal | `tech-lead.md` routing table | Present |

**Phase 1: fully landed.**

### Phase 2 — Solution Duel (#35) — MUST be present

| Item | Artifact | Status |
|---|---|---|
| Duel section as annex in proposal template | `proposal-template.md` §8 | Present |
| Duel Findings + Rebuttals subsections | `proposal-template.md` §8.1, §8.2 | Present |
| Round-limit rule (one round, then tech-lead) | `qa-engineer.md` §"Round limit" | Present |
| qa-engineer Duel section | `qa-engineer.md` §"Solution Duel" | Present |
| software-engineer "Respond to Duel" rule | `software-engineer.md` §"Pre-code workflow" #2 | Present |
| security-engineer Duel participation on Rule-#7 paths | `security-engineer.md` §"Solution Duel participation" | Present |
| Routing row for Solution Duel | `tech-lead.md` routing table | Present |
| DoR row: duel status=closed | `task-template.md` DoR (last sub-bullet) | Present |

**Phase 2: fully landed.**

### Phase 3 — Three-Path Rule (#33) — MUST be absent (deferred)

| Item | Artifact | Status |
|---|---|---|
| Three-alternative (Minimalist/Scalable/Creative) expansion in architecture template | `docs/templates/architecture-template.md` | **Absent (correctly)** |
| architect.md new rule requiring three named alternatives | `.claude/agents/architect.md` | **Absent (correctly)** |
| CHANGELOG v0.13.0 Pending entry for #33 | `CHANGELOG.md` v0.13.0 Pending | Present (correctly deferred) |

**Phase 3: properly excluded. No drift.**

**Note:** `task-template.md` DoR row for stage-2 ADR
expansion is present but marked "Phase 3 item, optional
until v0.13.0" — i.e., the task-template is forward-
compatible with Phase 3 without requiring it. This is the
right call: avoids a task-template breaking change in
v0.13.0.

Similarly, `tech-lead.md` §Job item 2 pipeline dispatch
item (b) names `architect` at stage 2 but marks Phase-3
content "currently optional". Same forward-compat logic.

**Bundle conformance: APPROVE.** Phases 1+2 land fully;
Phase 3 is properly excluded; the forward-compat hooks for
Phase 3 do not constitute Phase-3 content landing early.

---

## §7 Recommendations for the tag commit message

```
v0.12.0 — workflow-redesign Phase 1+2 + process-auditor + small fixes

- Workflow redesign (customer-bundled Phase 1+2 per 2026-04-23
  ruling; Phase 3 / #33 Three-Path deferred to v0.13.0):
  prior-art → proposal → duel pipeline, gated by a mechanical
  six-clause trigger annotated by `tech-lead` at dispatch. See
  docs/proposals/workflow-redesign-v0.12.md for the full memo.
    - New: docs/templates/prior-art-template.md (#34)
    - New: docs/templates/proposal-template.md with §Duel annex
      (#32 + #35)
    - researcher.md, software-engineer.md, qa-engineer.md,
      security-engineer.md, tech-lead.md each gain binding
      rules scoped to triggered tasks.
    - task-template.md gains Trigger: field + two DoR rows.
- New agent: process-auditor (cultural-disruptor / "The American"
  pattern; one-shot, every 2–3 milestone closes). Counterpart to
  v0.11.0 onboarding-auditor; closes second half of #25.
- SME contract consolidated memo at docs/sme/CONTRACT.md
  (closes #6). Replaces prior scattered references in CHANGELOG
  + CUSTOMER_NOTES.md with one durable document; ruling itself
  (Fix-C hybrid, 2026-04-19) unchanged.
- scripts/upgrade.sh: ACTION REQUIRED banner when new agents land
  under .claude/agents/, naming Claude Code restart as the
  registration path. CLAUDE.md § "Template version check +
  upgrade" documents the same. (Closes part of #36.)
- scripts/version-check.sh: unzipped-in-place warning now names
  scripts/repair-in-place.sh (v0.11.0) as option (a). (Closes
  #5 option 2.)
- Agent tool-grant fix (pre-flight): onboarding-auditor and
  process-auditor now declare Write in tools; both produce
  durable report files under docs/pm/.

Provenance (non-release content):
- Harness anomaly: architect spawns in this harness receive only
  Read, not the declared Write/Edit/SendMessage set. Documented
  in the workflow-redesign memo §Note and in CHANGELOG entry.
  Upstream Claude Code issue, not a template defect; customer
  (repo owner) may file at github.com/anthropics/claude-code.

Traceability matrix: docs/audits/V0_12_0_RELEASE_REVIEW.md §1.
Phase 3 deferral: CHANGELOG.md v0.13.0 Pending.
```

If a shorter tag body is preferred, the two-line summary is:

```
v0.12.0 — workflow-redesign Phase 1+2 (#32/#34/#35), process-auditor
agent (#25 second half), SME contract consolidation (#6), upgrade-
warning for new agents (#36 part), version-check repair pointer (#5
option 2). Phase 3 (#33 Three-Path) deferred to v0.13.0.
```

---

## Appendix A — files reviewed

Modified (working-tree against `ee9729d` / v0.11.0):
- `.claude/agents/onboarding-auditor.md` (1-line: `tools:` += `Write`)
- `.claude/agents/qa-engineer.md` (+43 lines: Solution Duel section)
- `.claude/agents/researcher.md` (§Job 5 rewrite: +durable-artifact + cadence)
- `.claude/agents/security-engineer.md` (+12 lines: Duel participation)
- `.claude/agents/software-engineer.md` (+26 lines: Pre-code workflow + Constraints bullet)
- `.claude/agents/tech-lead.md` (+27 lines §Job 2 + 4 routing rows)
- `CHANGELOG.md` (v0.12.0 section populated; v0.13.0 Pending)
- `CLAUDE.md` (+8 lines: restart paragraph; +1 row: process-auditor in roster; clarified onboarding-auditor "first half")
- `docs/templates/task-template.md` (+22 lines: Trigger field + 2 DoR rows)
- `scripts/upgrade.sh` (+20 lines: new-agent detection)
- `scripts/version-check.sh` (+5 lines: two-option recovery message)

New:
- `.claude/agents/process-auditor.md` (200 lines)
- `docs/proposals/workflow-redesign-v0.12.md` (538 lines)
- `docs/sme/CONTRACT.md` (157 lines)
- `docs/templates/prior-art-template.md` (77 lines)
- `docs/templates/proposal-template.md` (123 lines)

Verified-clean (no v0.12.0-scope changes):
- `.claude/agents/architect.md` — Phase 3 content correctly absent
- `docs/templates/architecture-template.md` — Phase 3 content correctly absent
- `migrations/` — no v0.12.0 migration required (purely additive)
- `VERSION` — still `v0.11.0`; tag commit will bump to `v0.12.0`

---

## Appendix B — harness-anomaly note

Context for this review session: the architect spawn's lost
`Write` tool (noted in workflow-redesign memo §Note and
CHANGELOG) was checked against this reviewer's own tool grant.
`code-reviewer` spawns in this harness received `Read`, `Bash`,
and the read-family tools as declared; no tool-grant gap on
this role. Review completed with `Read` + `Bash` + `Grep`, no
writes to files under review (per audit-mode rule).

