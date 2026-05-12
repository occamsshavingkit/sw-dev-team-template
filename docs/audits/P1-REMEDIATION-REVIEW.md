# P1 Remediation Review — IEEE 1028 audit of SWEBOK V4 / PMBOK 8 pass-2 P1 edits

**Date:** 2026-04-23
**Reviewer:** code-reviewer (audit mode)
**Scope:** P1 remediation edits landed 2026-04-23 between 19:54 and
20:19 UTC against `docs/audits/P1-REMEDIATION-PLAN.md` and the two
pass-2 audit reports. Pre-existing uncommitted hunks in the same
files are out of scope (identified by content keywords and mtime).

---

## §0 Summary

**Verdict: APPROVE WITH CONDITIONS.**

All eight P1 items are landed in the tree; the edits are internally
consistent with each other; customer sign-off for the one new binding
(Hard Rule #7) and the one new binding interpretation ("NO AI
TRAINING" scope) is traceable to `CUSTOMER_NOTES.md` (2026-04-23) or
to the plan's "no decision needed" classification. No hard-block
conditions fire. Two cross-reference accuracy issues and one
citation-verification issue should be resolved before commit; none
are release-blockers but all three are cheap to fix.

### Conditions to clear before commit

1. **Verify SWEBOK V4 ch. 13 §4.6 exists** — security-template.md §8
   and security-engineer.md §§cite "§4.6 assurance case" multiple
   times. The pass-2 audit's ch. 13 structural summary (lines
   93-105 of the SWEBOK audit) names six sub-topics under "Security
   Engineering for Software Systems" (Requirements, Design,
   Patterns, Construction, Testing, Vulnerability Management) —
   "assurance case" is not among them. Either `researcher`
   re-verifies §4.6 against `docs/library/local/swebok-v4.pdf`
   ch. 13 TOC and confirms, or the citation is corrected to the
   actual section that covers assurance cases (may be under §3
   Processes / Common Criteria, or a later section).
2. **Align taxonomy sub-letter numbering** — new taxonomy section
   `2.4c Security engineer` inserts at line 301 of
   `SW_DEV_ROLE_TAXONOMY.md` after §2.4 (the combined
   architect/tech-lead section). §2.4a and §2.4b are referenced
   across the roster (`CLAUDE.md` roster table, `architect.md`,
   `tech-lead.md`) but **do not exist as headers in the
   taxonomy.** This is pre-existing drift — the security edit did
   not create it — but the P1 work makes it more visible by
   placing a §2.4c peer. Either rename to §2.4a/§2.4b/§2.4c and
   split the existing §2.4 into a header plus two sub-sections
   (Architect, Tech Lead), or renumber the new security section
   to §2.4a and accept the roster-table references as aspirational.
   Recommendation: split §2.4, since `architect.md` and
   `tech-lead.md` already claim §2.4a / §2.4b.
3. **Fix typo in new §2.4c** — taxonomy line ~312 reads
   "Industry-common role names: *Application Security Engineer*
   ("AppSec Engineer"), *Product Security Engineer*, *DevSecOps
   Engineer*, *Security Architect*." The "Security Architect"
   label is ambiguous given `architect.md` already owns "security
   architecture decisions" structurally (post-edit). Non-blocking;
   a one-line clarification that *Security Architect* is the
   SWEBOK-named adjacent role, not to be confused with this
   template's `architect` agent, would close the loop.

### Top-3 issues

1. Unverified SWEBOK ch. 13 §4.6 citation (§0 condition #1).
2. Taxonomy sub-letter numbering mismatch (§0 condition #2).
3. Minor: `CHANGELOG.md` v0.11.0 entry cross-references "downstream
   project audit" — wording is fine but the file paths listed in the
   CHANGELOG are **project-scope** paths (e.g., the audit lives at
   `/home/quackdcs/SWEProj/docs/audits/`) while the remediation is
   **template-scope**. The plan itself flags this (plan §0 says "all
   eight P1 items are template-level"). A one-line clarifier in the
   CHANGELOG that the audit was driven from a downstream project but
   the fixes land upstream would prevent confusion for a future
   reader of the template history.

---

## §1 Per-file findings

### §1.1 New files (7)

#### `/home/quackdcs/SWEProj/sw-dev-team-template/.claude/agents/security-engineer.md`

- **Approve.** SWEBOK V4 ch. 13 anchor clearly stated; interfaces
  table covers every agent handoff named in the plan; escalation
  format matches template convention; canonical-role self-reference
  `§2.4c` matches CLAUDE.md roster but see §0 condition #2 for the
  taxonomy-numbering mismatch.
- **Warning (line 33).** Cites "SWEBOK V4 ch. 13 §4.6" for security
  assurance case. See §0 condition #1 — needs verification.
- **Warning (line 29).** "SWEBOK V4 ch. 13 §4.5 / §4.6" for SBOM —
  audit's §4 topic list has Vulnerability Management as §4's last
  item; SBOM is named in the recommended-fix text (pass-2 audit
  line 119) but not tied to a specific §4.x by the audit. Same
  verification follow-up as condition #1.
- **Suggestion (line 4).** `tools:` includes `SendMessage` which is
  correct for a named teammate per CLAUDE.md § "Agent-teams
  panel"; consistent with `qa-engineer`, `architect`, etc.

#### `/home/quackdcs/SWEProj/sw-dev-team-template/docs/templates/security-template.md`

- **Approve** structurally. §§1-9 map cleanly to plan outline.
- **Warning.** §8 "Assurance case and sign-off" is cited as SWEBOK
  V4 ch. 13 §4.6 (via security-engineer.md's anchor); verify the
  section number.
- **Suggestion.** §5 references "SWEBOK V4 ch. 13 §6.3" for
  ML-security — the pass-2 audit confirms §6.3 Security for Machine
  Learning exists (SWEBOK audit line 309), so this cite is good.

#### `/home/quackdcs/SWEProj/sw-dev-team-template/docs/templates/operations-plan-template.md`

- **Approve.** CONOPS, supplier mgmt, IaC/PaC, capacity, DR pointer,
  DevSecOps touchpoints — all 9 sections trace to SWEBOK V4 ch. 6 §2
  per audit line 162-165. ISO 20000-1 / 12207:2017 / 32675:2022
  references match audit line 157-159.
- **Suggestion.** §6 "Backup / DR / failover" labels the pointer
  file as `docs/dr-plan.md` — consistent with the template naming;
  good.

#### `/home/quackdcs/SWEProj/sw-dev-team-template/docs/templates/dr-plan-template.md`

- **Approve.** Sections match plan outline; ISO 27001:2022 §A.5.29-30
  and ISO 22301:2019 cited are correct and audit-independent.
- **Suggestion.** §5 restore-rehearsal cadence text "Cadence
  session-anchored, run-once (see CLAUDE.md § 'Time-based
  cadences')" is crisp and compatible with the new Time-based
  cadences section.

#### `/home/quackdcs/SWEProj/sw-dev-team-template/docs/templates/pm/TEAM-CHARTER-template.md`

- **Approve.** §1-7 shape matches plan outline and PMBOK 8 §2.6
  (audit line 160 confirms team charter is an explicit output of
  Plan Resource Management at line 8574 of the .txt). Customer
  ratification path via `CUSTOMER_NOTES.md` is named (line 4).
- **Suggestion.** §3.1 decision-table row "Architectural /
  structural trade-offs → `architect` (All agents; customer
  consulted if quality-attribute changes)" is slightly out of sync
  with `architect.md`'s new operations-trade-off clause (architect
  arbitrates operations trade-offs that cross cost/schedule
  thresholds). Not wrong, just not reflected in the table. Low
  priority.

#### `/home/quackdcs/SWEProj/sw-dev-team-template/docs/templates/pm/RESOURCES-template.md`

- **Approve.** Five-process framing (Plan / Estimate / Acquire /
  Lead / Monitor) matches PMBOK 8 audit line 160 verbatim.
  Human / physical / virtual split matches plan outline. Pointer
  to `TEAM-CHARTER.md §1` for roster metadata (line 17) is the
  intended ordering per the plan dependency graph.

#### `/home/quackdcs/SWEProj/sw-dev-team-template/docs/templates/pm/AI-USE-POLICY-template.md`

- **Approve.** Three adoption strategies (Automation / Assistance /
  Augmentation) per PMBOK 8 §X3.1 confirmed by audit line 169.
  Eight ethical factors match the enumerated list in audit line 169
  (the audit's prose says "six ethical factors" then enumerates 8;
  the template uses the enumerated list, which is the correct
  one).
- **Approve.** §2.7 Copyright cross-references CLAUDE.md IP policy
  and `CUSTOMER_NOTES.md` 2026-04-23 ruling — traceability is
  tight.

### §1.2 Modified files (14)

#### `CLAUDE.md`

- **Approve.** New Hard Rule #7 is well-formed, cites SWEBOK V4
  ch. 13 §4.6 (see §0 condition #1). Traces to plan §1 and to
  pass-2 audit §2.1 recommendation line 129-132. No customer
  sign-off was required per the plan (Q1 default path, "new
  standing agent"); the plan notes Q1 has a recommended default
  and the edits follow it.
- **Approve.** IP-policy scope clarification on "NO AI TRAINING"
  is directly traceable to the verbatim customer ruling in
  `/home/quackdcs/SWEProj/CUSTOMER_NOTES.md` 2026-04-23 —
  binding-rule provenance is clean.
- **Approve.** "Operations KA ownership" routing section lands
  where the plan §2 proposed.
- **Approve.** Agent roster table gains `security-engineer.md`
  row; citation `§2.4c` matches the new taxonomy section but
  see §0 condition #2.
- **Approve.** Step-2 DoD gains Team Charter + AI Use Policy
  rows — matches plan §§4, 6 explicitly.

#### `SW_DEV_ROLE_TAXONOMY.md`

- **Approve** content of new §2.4c Security Engineer — the
  SWEBOK V4 ch. 13 anchor, SFIA v9 SCTY/VUAS/SFEN observation,
  and scope-boundary-vs-domain-compliance paragraph all match
  pass-2 audit recommendations and the plan.
- **Warning — §0 condition #2.** Numbering discontinuity
  (§2.4 → §2.4c; no §2.4a / §2.4b headers in the file).
- **Approve** §2.3 SRE addition (new paragraph with V4 ch. 6
  mapping) and §2.8 release-engineer addition (V4 ch. 6 §3 +
  ch. 8 anchor). Both are directly traceable to the plan §2.

#### `CHANGELOG.md`

- **Approve.** v0.11.0 entry is additive and accurate. See §0
  top-3 #3 for a minor clarifier suggestion.

#### `docs/glossary/ENGINEERING.md`

- **Approve.** ISO/IEC 27001:2022 binding entry (new) matches plan
  §1 ("Bind ISO/IEC 27001:2022 as ISMS reference"). Restricted-
  source clause entry cross-references CLAUDE.md IP policy and
  researcher agent — traceability tight.

#### `.claude/agents/project-manager.md`

- **Approve.** Three new artifact rows (AI Use Policy, Team
  Charter, Resources), three template mappings, and expanded
  Responsibilities lines for sustainability (PMBOK 8 Principle #5
  §3.7), AI-use policy (Appendix X3), team charter (§2.6 Plan
  Resource Management), and resource management (§2.6 five
  processes). All match plan §§3, 4, 5, 6.

#### `.claude/agents/architect.md`

- **Approve.** Security-engineer handoff insert at line 17 is
  concise and matches plan §1. Operations trade-off arbitration
  section (new) matches plan §2.

#### `.claude/agents/code-reviewer.md`

- **Approve.** Security-engineer joint-review handoff added;
  "either can block" wording matches `security-engineer.md`
  interfaces paragraph — consistent.

#### `.claude/agents/release-engineer.md`

- **Approve.** SWEBOK V4 ch. 6 §3 anchor added; IaC/PaC and
  Operations Delivery artefacts are now explicitly named.
  Handoffs to security-engineer for SBOM and auth-touching
  releases match `security-engineer.md` interfaces.

#### `.claude/agents/researcher.md`

- **Approve.** New "Cite hygiene for restricted sources" section
  captures the narrow-interpretation customer ruling verbatim
  (with date stamp), lists four handling rules, and provides the
  source-handling matrix the plan §8 requested. Traceable to
  `CUSTOMER_NOTES.md` 2026-04-23.
- **Note.** This file also contains two other non-P1 hunks landed
  today (the "No silent source substitution" and "Archival + size
  budgets" sections). Those are out of scope for this review; they
  appear harmless and do not conflict with the P1 edits.

#### `.claude/agents/sre.md`

- **Approve.** V4 ch. 6 anchor and new "Operations Planning +
  Control" section match plan §2. CONOPS, capacity plan, DR/failover
  plan, supplier mgmt, operations control — all present.

#### `.claude/agents/tech-lead.md`

- **Approve.** Routing-table row for `security-engineer` (line 50)
  lands where plan §1 specified.
- **Note.** Additional non-P1 hunks (parallelism, R-1/R-2/R-3
  rewrite, scoping-transcript dump) are out of scope for this
  review; no conflict with P1 content.

#### `docs/templates/pm/CHARTER-template.md`

- **Approve.** §1 rename to "Purpose, justification, and value
  proposition" with benefits/value proposition paragraph matches
  plan §3 (Focus on Value + Finance domain cross-reference). §11
  Sustainability considerations table matches plan §3 explicitly
  (environmental / social / economic with KPI column).

#### `docs/templates/pm/RISKS-template.md`

- **Approve.** Category enum gains `sustainability` and `AI-use`
  entries — matches plan §3.
- **Note.** The cadence-wording change (session-anchored, run-once)
  appears in the same diff but is a pre-existing v0.10.1 edit
  per the CHANGELOG; it is not a P1 edit. Does not conflict.

#### `docs/templates/pm/LESSONS-template.md`

- **Approve.** Category enum gains `sustainability` and `AI-use` —
  matches plan §3.

### §1.3 Project-scope files (2)

#### `/home/quackdcs/SWEProj/docs/library/INVENTORY.md`

- **Approve.** LIB-0001 row edited to:
  - Publication year 2025 (audit-pass-2 correction).
  - Copyright column flags "NO AI TRAINING" clause explicitly.
  - ISBNs corrected to hyphenated form.
  LIB-0002 row updated with V4.0a (not V4.0), release date
  September 2025, copyright span 2014-2025 IEEE, explicit note
  that ch. 13 copyright page has **no** AI-training prohibition
  (contrast with LIB-0001). Change log at bottom records all
  three edits with dates. Consistent with pass-2 audit §0 method
  note and plan §7.

#### `/home/quackdcs/SWEProj/CUSTOMER_NOTES.md`

- **Approve.** New 2026-04-23 "NO AI TRAINING clause scope"
  ruling is recorded verbatim with customer's "good point. go with
  (a) and I think your work is ok." wording, and then followed by
  a paraphrase of the narrow-interpretation scope. Ratified-by:
  tech-lead (self-recorded for in-turn ruling) — consistent with
  the escalation protocol.
- **Approve.** Implications bullet list traces every downstream
  artefact touched by the ruling (`CLAUDE.md`, `researcher.md`,
  `AI-USE-POLICY-template.md`) — no dangling references.

---

## §2 Traceability matrix — P1 item → landed edits

| Plan § | P1 item | Landed file(s) | Status |
|---|---|---|---|
| §1 | Software Security ownership + artefacts | `.claude/agents/security-engineer.md` (new); `docs/templates/security-template.md` (new); `CLAUDE.md` roster row + Hard Rule #7 + Operations KA section; `SW_DEV_ROLE_TAXONOMY.md` §2.4c; `docs/glossary/ENGINEERING.md` ISO 27001 binding; `architect.md`, `code-reviewer.md`, `release-engineer.md`, `tech-lead.md` handoffs | **Complete** (condition #1 on §4.6 citation, condition #2 on taxonomy numbering) |
| §2 | Software Engineering Operations ownership + artefacts | `.claude/agents/sre.md` V4 ch. 6 anchor + Planning/Control block; `.claude/agents/release-engineer.md` V4 ch. 6 §3 anchor + IaC/PaC + Operations Delivery artefacts; `CLAUDE.md` Operations KA routing section; `docs/templates/operations-plan-template.md` (new); `docs/templates/dr-plan-template.md` (new); `SW_DEV_ROLE_TAXONOMY.md` §2.3 + §2.8 V4 citations; `architect.md` operations-trade-off clause | **Complete** |
| §3 | Sustainability integration (PMBOK Principle #5) | `docs/templates/pm/CHARTER-template.md` §1 rename + §11 Sustainability; `docs/templates/pm/RISKS-template.md` enum; `docs/templates/pm/LESSONS-template.md` enum; `.claude/agents/project-manager.md` Responsibilities | **Complete** |
| §4 | Team Charter template | `docs/templates/pm/TEAM-CHARTER-template.md` (new); `.claude/agents/project-manager.md` artifact row + mapping + Responsibilities; `CLAUDE.md` Step-2 DoD row | **Complete** |
| §5 | Resources template + Resources performance domain coverage | `docs/templates/pm/RESOURCES-template.md` (new); `.claude/agents/project-manager.md` artifact row + mapping + expanded Responsibilities (five-process framing) | **Complete** |
| §6 | AI Use Policy template (Appendix X3) | `docs/templates/pm/AI-USE-POLICY-template.md` (new); `.claude/agents/project-manager.md` artifact row + mapping + Responsibilities; `CLAUDE.md` Step-2 DoD row | **Complete** |
| §7 | "NO AI TRAINING" clause citation in IP policy | `CLAUDE.md` IP-policy bullet (restricted-source clauses) with customer-ruling scope paragraph; `docs/glossary/ENGINEERING.md` restricted-source-clause entry; `docs/library/INVENTORY.md` LIB-0001 Copyright column | **Complete** |
| §8 | Researcher cite-hygiene for PMI materials | `.claude/agents/researcher.md` new "Cite hygiene for restricted sources" section with source-handling matrix | **Complete** |

No P1 item is skipped or partially implemented.

---

## §3 Drift flags — edits beyond plan scope

The plan itself limits P1 work to the eight items enumerated.
Additional content landed in the same diffs that is **not** part of
P1 but also does not conflict:

1. **`researcher.md` "No silent source substitution" and "Archival +
   size budgets" sections** — not in the P1 plan; pre-existing
   v0.10.1 queued work per the CHANGELOG. Out of scope for this
   review.
2. **`tech-lead.md` R-1/R-2/R-3 rewrite, scoping-transcript dump,
   parallelism-default** — not in the P1 plan; v0.10.1 queued work.
   The one P1-scoped hunk (security-engineer routing-table row)
   is clean and small.
3. **`docs/templates/pm/RISKS-template.md` cadence-wording change
   to session-anchored / run-once** — v0.10.1 Issue #31 work; not
   P1. Lands in the same file as the P1 enum edit.
4. **`SW_DEV_ROLE_TAXONOMY.md`** — only the new §2.4c section and
   the V4-ch.-6 paragraphs under §2.3 / §2.8 are P1. Other hunks
   (if any) are not in the P1 review scope.

None of the drift items conflict with the P1 edits. The plan did
not explicitly authorize these additional hunks, but they are
pre-existing queued work with their own CHANGELOG entries, not
silent scope creep.

---

## §4 Hard-block check

- **Safety-critical production-code changes.** None — all edits
  are documentation / agent-definition. No hard block.
- **ADR-conflicting changes with no superseding ADR.** None.
- **New binding rules requiring customer sign-off.**
  - **Hard Rule #7** (security-engineer sign-off for
    auth/authz/secrets/PII/network-exposed releases). Plan §1
    Q1 specified a customer decision ("new agent vs SME vs
    split"); the plan listed the default as "new standing
    agent" and the editorial work proceeded on that default.
    Customer did not sign off explicitly on Hard Rule #7 as
    such — but the customer's ruling "do the items in your
    recommended sequence" (2026-04-23) authorized the plan's
    recommended defaults, and Hard Rule #7 is in plan §1's
    "Proposed changes" table. **Traceable. Does not hard-block.**
    That said — Hard Rule #7 is a binding that constrains
    every future release touching auth/secrets/PII, so it would
    be prudent for `tech-lead` to confirm the wording with the
    customer once before committing, framed as "this is what
    lands as Hard Rule #7; anything to change?" rather than as
    an open-ended approval.
  - **"NO AI TRAINING" narrow-interpretation scope.** Customer
    sign-off is verbatim in `CUSTOMER_NOTES.md` 2026-04-23.
    Clean.
- **Conflict with existing Hard Rules #1-#6.** Checked: none.
  Hard Rule #7 strengthens (does not contradict) #2 and #4.

---

## §5 Recommendations before commit

1. **Dispatch `researcher`** to verify the existence and naming
   of SWEBOK V4 ch. 13 §4.6 against `docs/library/local/swebok-v4.pdf`
   ch. 13 TOC. If §4.6 is **Assurance Case** → keep as-is. If §4.6
   is something else or does not exist → fix the three cites in
   `.claude/agents/security-engineer.md`, `CLAUDE.md` (Hard Rule
   #7), and `docs/templates/security-template.md` to the correct
   section. **Estimated: 10 min.**
2. **Decide taxonomy sub-letter layout.** Either:
   - (a) Split `SW_DEV_ROLE_TAXONOMY.md` §2.4 into §2.4a Architect
     + §2.4b Tech Lead headers (matching the existing
     `CLAUDE.md` roster and agent self-references). Renumber the
     new security section at §2.4c. **Estimated: 15 min.**
   - (b) Renumber the new security section to §2.4a and accept
     that the `CLAUDE.md` roster `§2.4a` / `§2.4b` citations are
     aspirational. **Not recommended** — easier to propagate drift.
   - Recommendation: (a).
3. **`CHANGELOG.md` v0.11.0 entry** — one-line clarifier that the
   audit reports were produced in a downstream project but the
   fixes land in the template. Low priority.
4. **Confirm Hard Rule #7 wording** with the customer (`tech-lead`
   asks one question, agents idle). Not a hard block — the plan's
   default path is authorized — but the rule is a material
   binding. The customer can ratify in one turn.
5. **`tech-writer`** (if active for this release) may want to
   update the `README.md` roster mention and any onboarding doc
   that lists standing agents, to include `security-engineer`.
   Not in the P1 plan; worth mentioning as a related follow-up.

---

## Appendix — files reviewed

New (7):
- `/home/quackdcs/SWEProj/sw-dev-team-template/.claude/agents/security-engineer.md`
- `/home/quackdcs/SWEProj/sw-dev-team-template/docs/templates/security-template.md`
- `/home/quackdcs/SWEProj/sw-dev-team-template/docs/templates/operations-plan-template.md`
- `/home/quackdcs/SWEProj/sw-dev-team-template/docs/templates/dr-plan-template.md`
- `/home/quackdcs/SWEProj/sw-dev-team-template/docs/templates/pm/TEAM-CHARTER-template.md`
- `/home/quackdcs/SWEProj/sw-dev-team-template/docs/templates/pm/RESOURCES-template.md`
- `/home/quackdcs/SWEProj/sw-dev-team-template/docs/templates/pm/AI-USE-POLICY-template.md`

Modified (template-scope, 14) — P1 hunks only:
- `/home/quackdcs/SWEProj/sw-dev-team-template/CLAUDE.md`
- `/home/quackdcs/SWEProj/sw-dev-team-template/SW_DEV_ROLE_TAXONOMY.md`
- `/home/quackdcs/SWEProj/sw-dev-team-template/CHANGELOG.md`
- `/home/quackdcs/SWEProj/sw-dev-team-template/docs/glossary/ENGINEERING.md`
- `/home/quackdcs/SWEProj/sw-dev-team-template/.claude/agents/project-manager.md`
- `/home/quackdcs/SWEProj/sw-dev-team-template/.claude/agents/architect.md`
- `/home/quackdcs/SWEProj/sw-dev-team-template/.claude/agents/code-reviewer.md`
- `/home/quackdcs/SWEProj/sw-dev-team-template/.claude/agents/release-engineer.md`
- `/home/quackdcs/SWEProj/sw-dev-team-template/.claude/agents/researcher.md`
- `/home/quackdcs/SWEProj/sw-dev-team-template/.claude/agents/sre.md`
- `/home/quackdcs/SWEProj/sw-dev-team-template/.claude/agents/tech-lead.md`
- `/home/quackdcs/SWEProj/sw-dev-team-template/docs/templates/pm/CHARTER-template.md`
- `/home/quackdcs/SWEProj/sw-dev-team-template/docs/templates/pm/RISKS-template.md`
- `/home/quackdcs/SWEProj/sw-dev-team-template/docs/templates/pm/LESSONS-template.md`

Project-scope (2):
- `/home/quackdcs/SWEProj/docs/library/INVENTORY.md`
- `/home/quackdcs/SWEProj/CUSTOMER_NOTES.md`


---

## Re-review 2026-04-23

**Reviewer:** code-reviewer (audit mode, second pass)
**Scope:** verification of the three findings raised in pass 1 (§0
conditions #1 and #2, plus the Hard Rule #7 wording-confirmation
recommendation from §5 item 4). All other pass-1 findings are out
of scope for this pass.

### Finding 1 — SWEBOK V4 ch. 13 §4.x citations

**Status: RESOLVED.**

Verified in `sw-dev-team-template/.claude/agents/security-engineer.md`
(lines 19-54) and `sw-dev-team-template/docs/templates/security-template.md`
(§§2-6, 8):

- §4.1 Security Requirements — cited correctly (sec-eng.md line 20;
  sec-tmpl.md §2 heading).
- §4.2 Security Design + §4.3 Security Patterns — cited correctly
  as a pair (sec-eng.md line 25; sec-tmpl.md §3 heading).
- §4.4 Construction for Security — cited correctly (sec-eng.md
  line 32; sec-tmpl.md §4 heading).
- §4.5 Security Testing — cited correctly (sec-eng.md line 36;
  sec-tmpl.md §5 heading).
- §4.6 Vulnerability Management — cited correctly (sec-eng.md
  line 39; sec-tmpl.md §6 heading). SBOM stewardship is attached
  to this §4.6 bullet, which matches SWEBOK V4's ch. 13 structure
  where SBOM handling sits under vulnerability management.
- §6.3 Security for Machine Learning-Based Application — cited
  correctly (sec-eng.md line 51; sec-tmpl.md §5 reference).
- Security assurance case re-grounded in ISO/IEC 15026-2:2022
  "Systems and software assurance — Part 2: Assurance case" — real
  standard, correctly titled, cited in sec-eng.md line 45-46,
  sec-tmpl.md §8 line 65-67, and CLAUDE.md Hard Rule #7.
- sec-eng.md line 47-48 explicitly flags that assurance case is
  "not a named SWEBOK V4 ch. 13 sub-section but implied by the
  combination of §§4.1–4.6 outputs" — honest framing, prevents
  future reviewers from hunting for a §4.7.

No spurious §4.x citations detected in the sweep. SDL / DevSecOps
coordination at sec-eng.md line 28 cites §3 Software Security
Engineering and Processes, which is the correct umbrella section.

### Finding 2 — Taxonomy §2.4a / §2.4b sub-headers

**Status: RESOLVED.**

Verified in `sw-dev-team-template/SW_DEV_ROLE_TAXONOMY.md`:

- Line 248: `#### 2.4a Software architect` — inserted before the
  architect sub-responsibilities block. Sensible split point.
- Line 259: `#### 2.4b Tech lead (technical lead within a delivery
  team)` — inserted before the tech-lead sub-responsibilities
  block. Sensible split point. Includes a cross-reference to
  `CLAUDE.md` § "Escalation protocol" noting the orchestration +
  sole-human-interface layer on top of the industry-generic role.
- Line 307: pre-existing `### 2.4c Security engineer` is now
  structurally coherent — sits as peer to the two new §2.4a /
  §2.4b sub-headers rather than as an orphan sub-letter.

Cross-reference resolution spot-checked:

- `CLAUDE.md` roster table (lines 386-398) references §2.4a, §2.4b,
  §2.4c — all resolve.
- `.claude/agents/architect.md` line 8 — §2.4a resolves.
- `.claude/agents/tech-lead.md` line 8 — §2.4b resolves.
- `.claude/agents/security-engineer.md` line 8 — §2.4c resolves.

**Note (non-blocking):** other sub-letter references in the roster
(§2.5a tech-writer, §2.6a SME, §2.7 code-reviewer with internal
§2.7a / §2.7b, §2.9a project-manager) do **not** have matching
`####` sub-headers in the taxonomy. These sub-letters are
introduced instead by the §4 role-boundary table (taxonomy lines
783-792) which uses them as row identifiers. This is a pre-existing
design pattern, consistent across the table, and is not drift
introduced by the P1 work. If the template later decides to
promote all sub-letters to `####` headers for consistency with
§2.3 / §2.4, that is a separate cleanup item — out of scope for
this remediation.

### Finding 3 — Hard Rule #7 customer ratification

**Status: RESOLVED.**

Verified in `/home/quackdcs/SWEProj/CUSTOMER_NOTES.md` (lines 250-277):

- Entry titled "2026-04-23 — Hard Rule #7 (security-engineer release
  sign-off) confirmed" — dated, specific, indexable.
- Context paragraph (lines 252-260) traces the ratification back to
  the pass-1 audit finding and notes that `tech-lead` brought the
  exact wording plus a plain-language explanation to the customer.
- Customer response captured verbatim (line 262-263): "ok. I think
  the rule is good as is. if this is ever widely adopted and people
  hate it, we can remove it."
- Ruling paragraph (lines 265-268) records ratified-as-authored
  disposition and flags adoption friction as future-release
  revision grounds (not a ship-blocker).
- Implications list (lines 270-275) separates concerns cleanly:
  Hard Rule #7 cleared for v0.11.0; automated secret-scanning is
  *not* part of Hard Rule #7 and is logged as a v0.12.0+ follow-up.
- Recorded-by footer (line 277) attributes to tech-lead
  (self-recorded) — consistent with other in-turn rulings in this
  file.

Traceability is substantive: the entry explains why the question
was asked, what the customer was shown, what the customer said
verbatim, what the ruling means, and what it does not cover. Future
reviewers can reconstruct the decision without re-asking the
customer.

### Overall verdict

**CLEAR TO COMMIT.**

All three pass-1 findings are fully resolved. No new issues
introduced by the fix hunks. No regressions detected in the
surrounding text. No hard-block conditions fire.

The pass-1 report's other `APPROVE WITH CONDITIONS` items (§0
condition #3 on "Security Architect" label clarifier, §5
recommendation #3 CHANGELOG clarifier, §5 recommendation #5
README roster mention) remain as low-priority cleanup that may
ship in v0.11.0 or slide to v0.11.1 / v0.12.0 at the release
engineer's discretion. They are not blockers.

**Recommendation:** proceed with the v0.11.0 commit.
