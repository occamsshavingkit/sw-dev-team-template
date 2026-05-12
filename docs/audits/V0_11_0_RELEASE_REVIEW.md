# v0.11.0 Release Review — IEEE 1028 audit of the full v0.11.0 delta

**Date:** 2026-04-23
**Reviewer:** code-reviewer (audit mode, per §2.7b)
**Scope:** the entire uncommitted working-tree delta on `main`
(HEAD = `v0.10.0` tag, `7fa2d8d`) against v0.11.0 intent as
written in the repo's own `CHANGELOG.md` lines 19–200. Prior P1
findings already cleared in
`/home/quackdcs/SWEProj/docs/audits/P1-REMEDIATION-REVIEW.md` are
not re-audited in substance; only verified as still-resolved.

---

## §0 Summary

**Verdict: APPROVE WITH CONDITIONS. Clear to tag once §6 conditions
land, or tag as-is and ship the conditions as v0.11.1.**

The v0.11.0 bundle is large (27 files changed, ~1,100 lines added),
but every substantive change traces to the CHANGELOG section, and
every new file has a corresponding CHANGELOG entry. The three P1-
remediation findings verified in
`P1-REMEDIATION-REVIEW.md` remain resolved through all subsequent
edits. Scripts are well-shaped, shebang-correct, and executable.
Templates conform to the shape of their peers. No hard-rule
conflicts. No safety-critical code touched (documentation and
agent-definition only).

Three defects should block a clean tag — one is a documentation
inconsistency that future reviewers will stumble on, two are
cross-reference gaps where new artifacts are not wired into the
roster. None are release-blockers in the strict sense (no Hard
Rule triggered, no safety path affected), but they are cheap to
fix and avoid an immediate v0.11.1 patch.

### Top-3 issues

1. **Taxonomy §2.4c SWEBOK §4.x numbering disagrees with
   security-engineer.md and security-template.md.** §2.4c lines
   332–336 cite §4.3 construction, §4.4 testing, §4.5 vuln mgmt,
   §4.6 assurance case — but the verified numbering (confirmed in
   P1 pass-2 review) is §4.4 construction, §4.5 testing, §4.6
   vuln mgmt, and **no §4.x for assurance case** (grounded in
   ISO/IEC 15026-2:2022 instead). The taxonomy was written before
   P1 re-verification corrected the security-engineer file and
   was not updated to match. Documentation drift within the same
   release bundle.
2. **`qa-engineer.md` does not mention any of the 8 new QA
   templates it is named as owner of, nor the `onboarding-auditor`
   it is named as dispatcher of, nor the `intake-conformance`
   audit it is named as owner of.** Downstream files reference
   qa-engineer; qa-engineer does not reference back. A reader
   starting from qa-engineer cannot discover the new responsibilities.
3. **The 5 new `docs/style-guides/*.md` files are orphaned.**
   No agent, `CLAUDE.md` section, `README.md` section, or
   `CONTRIBUTING.md` row references them. `software-engineer`,
   `architect`, and `code-reviewer` are the natural consumers;
   none mention the directory. This is a soft issue (the files
   can still be found by grep), but against the template's own
   cross-reference discipline it is a drift.

### Conditions to clear before a clean tag (pick any or ship as v0.11.1)

- **C-1 (top-3 #1).** Update `SW_DEV_ROLE_TAXONOMY.md` §2.4c
  bullets on lines 332–336 to match the verified SWEBOK V4 ch. 13
  numbering used in `security-engineer.md` and
  `security-template.md`. One-line edit per bullet.
- **C-2 (top-3 #2).** Add a short "QA templates owned" section to
  `qa-engineer.md` listing the 8 new QA templates; add a line
  to "Hand-offs" noting milestone-close dispatch of
  `onboarding-auditor`; add a line to Job noting intake-conformance
  audit ownership.
- **C-3 (top-3 #3).** Add a "Style guides" section to `CLAUDE.md`
  between § "Standard document templates" and § "IP policy",
  listing the 5 seed files and noting that project teams extend
  rather than replace. Alternatively, add cross-refs from
  `software-engineer.md` / `architect.md` / `code-reviewer.md`.

---

## §1 CHANGELOG ↔ artifact traceability

Every bullet under `v0.11.0 — Added` and `v0.11.0 — Changed`
(CHANGELOG lines 26–198) has a landed artifact in the working
tree. Matrix:

| CHANGELOG row | Landed artifact | Status |
|---|---|---|
| TOKEN_LEDGER template + DoD pointer (#17, #26) | `docs/templates/pm/TOKEN_LEDGER-template.md`; `docs/templates/task-template.md` DoD +10 lines | Complete |
| P1 remediation (8 items, SWEBOK V4 + PMBOK 8) | See P1 review matrix §2 | Complete; re-verified |
| #5 part C repair-in-place | `scripts/repair-in-place.sh`; `README.md` Quickstart lines 87–112 | Complete |
| #25 zero-context onboarding auditor | `.claude/agents/onboarding-auditor.md`; `CLAUDE.md` roster line 397; `tech-lead.md` routing line 67 | Complete |
| V2 §2 QA outlines (7 plans) | `docs/templates/qa/test-strategy / unit / integration / system / acceptance / regression / performance -template.md` | Complete (file-level) |
| V2 §3 Style-guide seeds (5) | `docs/style-guides/python.md / typescript.md / rust.md / go.md / bash.md` | Complete (file-level) |
| Premature-close fix #11 (audit-agent-tools) | `scripts/audit-agent-tools.sh` | Complete |
| Premature-close fix #13 (heartbeat convention) | `docs/agent-health-contract.md` § "Heartbeat convention (binding for long-running agents)" lines 84–112; `tech-lead.md` liveness-expectation bullet (already present post-v0.10.1) | Complete |
| Premature-close fix #16 (intake log) | `docs/templates/intake-log-template.md`; `scripts/intake-show.sh`; `docs/templates/qa/intake-conformance-template.md`; `researcher.md` cross-ref section | Complete |
| Changed: SME two-mode contract (#6) | `CLAUDE.md` § "SME scope" rewrite; `sme-template.md` Mode section; `CUSTOMER_NOTES.md` verbatim ruling | Complete |
| Changed: task-template DoD token row | `docs/templates/task-template.md` DoD +10 lines pointing at TOKEN_LEDGER-template.md | Complete |
| Advisor §5.4 QA adversarial stance | `.claude/agents/qa-engineer.md` § "Adversarial stance (binding)" | Complete (also listed in v0.10.1; bundled forward) |
| Advisor §5.5 researcher archival + size budgets | `.claude/agents/researcher.md` §7 "Archival + size budgets (binding)" lines 117–140 | Complete (also listed in v0.10.1; bundled forward) |

Traceability is clean — no CHANGELOG row is missing an artifact.

---

## §2 Per-file findings (non-clean files only)

### §2.1 `SW_DEV_ROLE_TAXONOMY.md`

- **Warning — condition C-1.** §2.4c bullets 332–336 cite
  `§4.3` Construction, `§4.4` Testing, `§4.5` Vuln Mgmt,
  `§4.6` Assurance case. The P1 re-review (§"Finding 1 —
  SWEBOK V4 ch. 13 §4.x citations") verified the correct
  numbering as `§4.4` Construction, `§4.5` Testing, `§4.6`
  Vuln Mgmt, and **no §4.x** for assurance case (ISO/IEC
  15026-2:2022 instead). Internal disagreement within the
  same release bundle.
- **Approve** §2.4a / §2.4b split — resolved per P1 review.
  Sub-headers exist and cross-refs resolve.

### §2.2 `.claude/agents/qa-engineer.md`

- **Warning — condition C-2.** The file is silent on:
  - The 8 new QA templates under `docs/templates/qa/`, of
    which `qa-engineer` is named as the owner in every
    template's frontmatter.
  - The `onboarding-auditor` agent, which
    `onboarding-auditor.md` line 16 says is spawned by
    `qa-engineer` at milestone close.
  - The intake-conformance audit, which
    `intake-conformance-template.md` line 1 names
    `qa-engineer` as owner of.
- **Suggestion.** Add one section "QA artefacts owned" pointing
  at `docs/templates/qa/*` and one "Hand-offs" row
  "milestone-close → dispatch `onboarding-auditor`".

### §2.3 `docs/style-guides/*.md` (5 files)

- **Approve** shape. Each file follows the same section
  skeleton: Baseline standards → Required toolchain →
  Style points → Anti-patterns → References. Good citation
  hygiene (Tier-1 vs Tier-2 labels where Tier-2 applies).
- **Warning — condition C-3.** Orphaned relative to the roster.
  No agent or binding doc references `docs/style-guides/`.
  The natural cross-refs are `software-engineer.md`
  (implementation), `code-reviewer.md` (enforcement),
  `architect.md` (ADR trigger when project changes language).
  None mention the directory.

### §2.4 `docs/templates/qa/` (8 files)

- **Approve.** Consistent shape per ISTQB Foundation + IEEE 829;
  every template cites `test-strategy-template.md` as the
  master plan and `docs/requirements.md` for traceability.
  Ownership rows correctly name `qa-engineer` (primary),
  `software-engineer` (unit), `sre` (performance),
  `security-engineer` (security via security-template.md).
- **Suggestion.** `test-strategy-template.md` §3 table row
  "Security | `security-template.md` §5 | ..." — the
  security-template's §5 is "Security testing" per the
  P1 review; good cite.
- **Approve.** `intake-conformance-template.md` C1–C10 +
  S1–S4 checklist rows each cite the relevant binding doc
  with section. Forensically useful.

### §2.5 `scripts/audit-agent-tools.sh`

- **Approve.** Shebang `#!/usr/bin/env bash`, `set -euo
  pipefail`, executable bit set. `--strict` flag behaves per
  header comment. Usage / exit-codes block matches
  `docs/style-guides/bash.md` required header shape.
- **Note.** The script uses `declare -A` (associative array,
  Bash 4+). Not a portability issue on Linux/macOS-with-brew-
  bash, but macOS system Bash is 3.2. If the template is ever
  run on a stock macOS shell, this will fail. Not a v0.11.0
  blocker; worth a line in the style guide or a fallback.
- **Observation.** When run against the current working tree,
  the script would likely flag `architect`, `sre`, `security-
  engineer`, `code-reviewer`, and possibly `onboarding-auditor`
  for implied-Write-without-grant (they produce artefacts but
  lack `Write`). This is exactly its job; the first real run
  will produce a to-do list, not a clean exit. Not a defect.

### §2.6 `scripts/intake-show.sh`

- **Approve.** Shebang, flags, exit codes all clean.
- **Observation.** `--since` date comparison uses string
  compare (`ts < since`) on ISO-8601 strings; works because
  ISO-8601 is lexicographically sortable. Not a bug; worth a
  comment in the script for a future maintainer.

### §2.7 `scripts/repair-in-place.sh`

- **Approve** shape, shebang, set-flags, exit codes, dry-run
  support, destructive-confirmation gating.
- **Approve** consistency with `scripts/scaffold.sh`. The
  `to_remove` list (lines 75–85) matches `scaffold.sh` tar
  excludes (lines 61–70) item-for-item, minus `./.git` (which
  makes no sense for in-place repair).
- **Suggestion — cosmetic.** The empty-stub content for
  `CUSTOMER_NOTES.md` (lines 166–183) is simpler than
  `scaffold.sh`'s equivalent (lines 100–133). Both work, but
  a future repair-in-place user will end up with thinner
  scaffolding than a fresh scaffold user. Not a defect; worth
  aligning in a follow-up.

### §2.8 `.claude/agents/onboarding-auditor.md`

- **Approve.** Role definition is coherent; constraints are
  explicit (binding-negative list of what it may not read);
  output shape is specified.
- **Approve.** Tool grant `Read, Grep, Glob, Bash` with no
  `SendMessage` is consistent with "isolated by design"
  constraint (line 39).
- **Note.** The CHANGELOG entry (line 99) says "Reads only
  public docs + source + scripts + tests." The file itself
  (lines 29–35) lists permitted inputs more broadly, including
  `docs/templates/*` and CI config. No contradiction; the
  file is the authoritative spec.

### §2.9 `docs/templates/intake-log-template.md`

- **Approve.** Shape, Hard Rules, Rendering pointer, example
  entries — all clean. YAML-block format is reasonable and
  machine-grepable.
- **Approve.** Cross-ref discipline — `researcher.md` §2
  "Intake-log cross-reference (binding)" mirrors the rule
  that every `CUSTOMER_NOTES.md` entry cites an intake-log
  `turn:`.

### §2.10 `docs/agent-health-contract.md` (new "Heartbeat convention" section)

- **Approve.** Binding scope is clearly stated; the 7 agents
  named (lines 89–92) are exactly the 7 long-running
  specialists in the roster. Three accepted heartbeat forms
  (file write / TaskUpdate / SendMessage) cover all extant
  tool grants.
- **Approve.** Heartbeat is a floor not a ceiling (line 111);
  no conflict with existing signal 11 "Silent hang" default
  windows (3 / 10 / 20 / 30 min).

### §2.11 `CLAUDE.md`

- **Approve.** Hard Rule #7 is in place (per P1 review §"Finding
  3"); customer ratification in `CUSTOMER_NOTES.md` is traceable.
- **Approve.** Operations KA ownership section (post-Routing
  defaults) correctly maps ch. 6 §2/§4 → sre, §3 →
  release-engineer, DevSecOps three-way. No conflict with
  existing routing rules.
- **Warning — condition C-3.** No `Style guides` section. The
  5 new style-guide seeds are not listed in `## Standard
  document templates` either.

### §2.12 `CHANGELOG.md`

- **Approve.** Traceability is clean, every row has an artifact.
- **Note.** The bundle folds v0.10.1 PATCH-queued items into
  the v0.11.0 MINOR release (the v0.10.1 section remains as
  `unreleased`). This is a reasonable release choice — MINOR
  subsumes PATCH — but the v0.10.1 section could be either
  marked as "superseded by v0.11.0" or collapsed into it.
  Not a defect; a tag-time decision.

### §2.13 `README.md`

- **Approve.** Quickstart §"I already unzipped into my working
  directory" (lines 87–112) is clear, names both repair and
  scaffold paths, warns against the unzipped-as-project state.
- **Observation.** The roster in README does not list
  `security-engineer` or `onboarding-auditor`. If the README
  has a "What's in the team" section, both new agents should
  be listed. (Did not verify; if this section does not exist
  in the README it's not a regression.)

---

## §3 Drift — artifacts without CHANGELOG rows

None detected that affect v0.11.0 scope. Modifications not
explicitly in v0.11.0 entries trace to the v0.10.1 section
(still-unreleased PATCH bundle being folded in):

- `docs/ISSUE_FILING.md`, `docs/versioning.md`,
  `scripts/scaffold.sh`, `scripts/version-check.sh`,
  `STAKEHOLDERS-template.md`, `scoping-questions-template.md`,
  `OPEN_QUESTIONS.md` template stub, `brewday-log-annotator`
  example — all in v0.10.1 section.

CHANGELOG rows without artifacts:

- `#15 customer → product owner rename` (v0.11.0 "roll-up"
  line 199) — listed under "Advisor recommendations landed"
  but this is a **breaking** rename that would require the
  `migrations/0.11.0.sh` referenced on CHANGELOG line 22.
  No migration script exists in `migrations/`. Either the
  rename did not land (CHANGELOG overstates) or it landed
  without a migration. Grep the tree for "customer" → spot-
  checked `CLAUDE.md` lines 8–25 still say "customer" not
  "product owner." **The rename has NOT landed.** This is
  CHANGELOG overstatement — `#15` should move to `### Pending`
  or be removed from the v0.11.0 entry.

---

## §4 Cross-reference errors

1. **(C-1)** Taxonomy §2.4c §4.x numbering vs
   security-engineer.md / security-template.md — mismatch. See
   §0 top-3 #1.
2. **(C-2)** `qa-engineer.md` does not list the QA templates
   it owns, the `onboarding-auditor` it dispatches, or the
   intake-conformance audit it owns. See §0 top-3 #2.
3. **(C-3)** `docs/style-guides/*.md` not referenced from any
   agent, CLAUDE.md section, or README. See §0 top-3 #3.
4. **CHANGELOG `#15` customer rename claim** — listed as
   landed; not landed in-tree. See §3.
5. **Minor.** `performance-test-plan-template.md` §9 cites
   "SRE book (Beyer et al.) ch. on capacity planning." The
   SRE book is Tier-2 per researcher taxonomy; naming the
   specific chapter ("Capacity Planning," ch. 11) would
   tighten the citation. Non-blocking.

---

## §5 Hard-rule conflicts

None.

- Hard Rule #7 (security-engineer sign-off) — verified landed
  and customer-ratified per P1 review §"Finding 3."
- Heartbeat convention — does not conflict with Hard Rule #1
  (only `tech-lead` interfaces with customer); heartbeats flow
  to `tech-lead` not to customer.
- Restricted-source clause (CLAUDE.md IP policy addition) —
  strengthens Hard Rule #5 (prefer paraphrase); does not
  contradict it.
- Intake-log `agents-running-at-ask: []` invariant — operationalises
  CLAUDE.md Step 2 "all agents and tool calls idle" rule; does
  not contradict.
- SME two-mode contract (Fix-C hybrid) — strengthens the SME
  scope rule without breaking any existing SME invocation.

---

## §6 Recommendations for the tag commit message

```
v0.11.0 — SWEBOK V4 / PMBOK 8 + V2 roadmap MINOR bundle

- New agent: security-engineer (SWEBOK V4 ch. 13 owner). Hard
  Rule #7 gates auth / secrets / PII / network-exposed releases
  on security-engineer sign-off (customer-ratified 2026-04-23).
- New agent: onboarding-auditor (zero-context doc audit;
  upstream #25 first half).
- 8 new QA templates (test-strategy + 6 level plans +
  intake-conformance) under docs/templates/qa/.
- 5 style-guide seeds under docs/style-guides/ (Python,
  TypeScript, Rust, Go, Bash).
- New operations artefacts: operations-plan-template.md,
  dr-plan-template.md (SWEBOK V4 ch. 6 split: sre owns
  planning/control, release-engineer owns delivery).
- 3 new PMBOK 8 artefacts: TEAM-CHARTER-template.md,
  RESOURCES-template.md, AI-USE-POLICY-template.md. Step-2
  DoD now gates on both Team Charter and AI Use Policy.
- New: scripts/repair-in-place.sh (closes #5 part C),
  scripts/audit-agent-tools.sh (closes #11 secondary ask),
  scripts/intake-show.sh (for #16).
- New: docs/templates/intake-log-template.md + researcher
  intake-log cross-ref binding (closes #16).
- Heartbeat convention (binding for long-running agents)
  under docs/agent-health-contract.md (closes #13).
- SME contract two-mode hybrid (primary-source / derivative)
  per customer ruling (closes #6).
- Restricted-source IP policy clause + narrow "NO AI TRAINING"
  interpretation recorded per customer ruling 2026-04-23.
- Taxonomy §2.4a / §2.4b sub-headers split to match long-
  standing roster references; new §2.4c Security Engineer.
- v0.10.1 PATCH-queue items folded in (intake opt-in Step 0,
  session-anchored cadences, adversarial QA stance, archival
  + size budgets, SemVer 2.0.0 normative ref, + others).

Folded-in v0.10.1 items per CHANGELOG lines 203–294. Full
traceability matrix: docs/audits/V0_11_0_RELEASE_REVIEW.md §1.

Known minor issues (non-blocking; tag-or-v0.11.1 discretion):
- Taxonomy §2.4c SWEBOK §4.x bullet numbering is out of sync
  with security-engineer.md (off-by-one on §4.3/§4.4 etc.).
- qa-engineer.md does not yet list the new QA templates /
  onboarding-auditor / intake-conformance audit it owns.
- docs/style-guides/*.md not yet cross-referenced from any
  agent.
- CHANGELOG line 199 claims #15 customer → product owner
  rename landed; the rename has not landed in-tree and no
  migrations/0.11.0.sh exists. Move to "Pending" before tag.
```

If the tag commit message should stay short, at minimum the
CHANGELOG #15 claim should be corrected before the tag (it's
a factual misrepresentation of what lands).

---

## Appendix A — verified P1 findings still resolved

Confirmed against the current working-tree state:

- `security-engineer.md` §4.x citations — still matching the
  P1 pass-2 verification (§4.4 Construction, §4.5 Testing,
  §4.6 Vuln Mgmt; assurance case grounded in ISO/IEC
  15026-2:2022). Resolved.
- `security-template.md` §§ — still matching. Resolved.
- `SW_DEV_ROLE_TAXONOMY.md` §2.4a / §2.4b sub-headers at
  lines 248 / 259 — present and correctly placed. §2.4c at
  line 307 resolves as peer. Resolved.
- `CUSTOMER_NOTES.md` Hard Rule #7 ratification entry
  2026-04-23 — present. Resolved.

No regressions introduced by subsequent edits.

## Appendix B — files reviewed at full-review depth

New (beyond P1):
- `scripts/audit-agent-tools.sh`
- `scripts/intake-show.sh`
- `scripts/repair-in-place.sh`
- `docs/templates/intake-log-template.md`
- `docs/templates/qa/test-strategy-template.md`
- `docs/templates/qa/unit-test-plan-template.md`
- `docs/templates/qa/integration-test-plan-template.md`
- `docs/templates/qa/system-test-plan-template.md`
- `docs/templates/qa/acceptance-test-plan-template.md`
- `docs/templates/qa/regression-test-plan-template.md`
- `docs/templates/qa/performance-test-plan-template.md`
- `docs/templates/qa/intake-conformance-template.md`
- `docs/style-guides/python.md`, `typescript.md`, `rust.md`,
  `go.md`, `bash.md`
- `docs/templates/pm/TOKEN_LEDGER-template.md`
- `.claude/agents/onboarding-auditor.md`
- `docs/agent-health-contract.md` (heartbeat section)

Modified hunks reviewed (v0.11.0 labelled):
- `CLAUDE.md` (Operations KA section, Hard Rule #7,
  Step-2 DoD, IP policy addition, roster)
- `README.md` (repair-in-place section)
- `CHANGELOG.md` (v0.11.0 section)
- `SW_DEV_ROLE_TAXONOMY.md` (§2.4a / §2.4b / §2.4c)
- `.claude/agents/qa-engineer.md` (adversarial stance)
- `.claude/agents/tech-lead.md` (onboarding-auditor routing)
- `.claude/agents/researcher.md` (intake-log cross-ref,
  archival + size budgets, restricted-source hygiene)
- `docs/templates/task-template.md` (DoD token row)

Reviewed but no v0.11.0-scope changes:
- `CONTRIBUTING.md` (no v0.11.0 hunks detected)
