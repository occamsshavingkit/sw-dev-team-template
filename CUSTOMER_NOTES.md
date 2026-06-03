# CUSTOMER_NOTES.md

Append-only log of customer-originated facts: domain truths, requirements,
acceptance criteria, and rulings relayed by `tech-lead`. Maintained by
`researcher`.

**Rules:**
- Append only. Never rewrite or delete past entries.
- Record customer answers verbatim. Paraphrase only in the surrounding
  framing, not in the quoted text.
- One entry per topic. If a later answer supersedes an earlier one, add a
  new entry and cross-reference the superseded one.
- If an entry is ambiguous on re-read, do not reinterpret — `tech-lead`
  must take the clarification back to the customer.
- Archive pointer: historical snapshots live in `docs/customer-notes-archive.md`.
  Use `scripts/archive-registers.sh` for append-only archival before replacing
  historical live content with a compact tombstone; do not alter customer-note
  entries during archival.

**Entry template:**

```
## YYYY-MM-DD — <short topic>

**Question (from <agent>, relayed by tech-lead):**
> <verbatim question>

**Customer answer (verbatim):**
> <verbatim response>

**Supersedes:** <date + topic of prior entry, if any>
**Recorded by:** researcher
```

---

<!-- Entries begin below this line. First entry will typically be the
     Step-2 project charter + SME plan from the CLAUDE.md first-action flow. -->

## 2026-04-19 — project scope: improve the sw-dev-team template

**Question (from tech-lead):**
> What are we doing and in which directory?

**Customer answer (verbatim):**
> "Your first project is to review the code you are currently running, and
> make sure it is actually complete. I have put a copy in sw-dev-team-template
> for you to improve."

**Recorded by:** researcher

## 2026-04-19 — customer's SME status on this project

**Customer answer (verbatim):**
> "I am not an SME here. SMEs would know about project engineering and
> software engineering/architecture standards."

**Recorded by:** researcher

## 2026-04-19 — naming category for this team

**Question (from tech-lead, Step 3):**
> Pick a naming category for the team.

**Customer answer (verbatim):**
> "muppets has been fun."

**Recorded by:** researcher. Mapping applied in
`/home/quackdcs/SWEProj/docs/AGENT_NAMES.md`.

## 2026-04-19 — gender-representation rule tightening

**Customer answer (verbatim):**
> "the M/F/non-binary split shouldn't overrepresent a gender in the
> category either. we don't need to flag if a category is biased toward
> one gender: the user picked it. (Famous CEOs has women, but doesn't
> need to over represent them.)"

**Recorded by:** researcher. Codified in
`sw-dev-team-template/docs/AGENT_NAMES.md` § "Gender-representation rule".

## 2026-04-19 — personality-match rule

**Customer answer (verbatim):**
> "add to the project that if named agents have a well known personality
> that matches a role, they should get that role. not necessary to
> change anything for us now, though."

**Recorded by:** researcher. Codified in
`sw-dev-team-template/docs/AGENT_NAMES.md` § "Personality-match rule".

## 2026-04-19 — scoping Definition of Done

**Question (Q-0007):**
> Define explicit DoD for the scoping conversation itself.

**Customer answer (verbatim):**
> "iii"  — i.e., a checklist: project summary / SMEs identified /
> escalation paths named / first milestone defined / Step-3 naming done.

**Recorded by:** researcher. Codified in
`sw-dev-team-template/CLAUDE.md` § Step 2 DoD.

## 2026-04-19 — v1 milestone for this project

**Question (Q-0011):**
> What is the v1 milestone?

**Customer answer (verbatim):**
> "c"  — (a) all OPEN_QUESTIONS closed + (b) `docs/templates/pm/`
> artifact templates seeded + (c) dry-run on a throwaway new project to
> prove the scoping flow end-to-end.

**Recorded by:** researcher.

## 2026-05-13 — sweproj-meta-project-working-tree (turn: docs/intake-log.md turn 2)

Customer said: "HOLY SHIT THIS NEEDS TO BE IN THE INFO FOR THIS DIRECTORY: this is the meta-project to improve sw-dev-team-template. All work happens in ./sw-dev-team-template

this was already known and somehow got lost."
Context: Tech-lead misidentified `/home/quackdcs/SWEProj` as the work target instead of the meta-project; the actual work target is `./sw-dev-team-template`.
Asked by: tech-lead

## 2026-04-19 — issue feedback opt-in (Step 4)

**Question (from tech-lead, Step 4):**
> Does this project participate in upstream issue feedback?

**Customer answer (verbatim):**
> "yes"

**Recorded by:** researcher. Upstream:
`https://github.com/occamsshavingkit/sw-dev-team-template`. Template
version this project runs against: `v0.1.0` (stamped in
`/home/quackdcs/SWEProj/TEMPLATE_VERSION`).

## 2026-04-19 — additional customer directives this session

- "check out also the trail of bits skills, add them to the list you
  ask about." → Step 1 menu updated; ToB cloned to
  `~/.claude/trailofbits-skills`.
- "look into the config in ../QuackS7 - the agent names show up on the
  bottom. why does that happen and make it part of this project and
  the template." → `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` pinned in
  both project and template `.claude/settings.json`; `tech-lead`
  spawns named teammates.
- "start a private github repo for this project. When I am working on
  other projects and gaps in this paradigm arise, they should be sent
  to our github repo as issues. We will review the issues
  periodically." → repo created private; `docs/ISSUE_FILING.md`
  documents the convention.
- "this will require some version code on the project so we know if
  it is a current issue." → `VERSION` + `CHANGELOG.md` + template
  version-stamp convention added.
- "explicitly ask the user if they want to give this issues feedback
  at the start of the project in an atomic question." → Step 4 added
  to `CLAUDE.md` FIRST ACTIONS.

**Recorded by:** researcher.

## 2026-04-21 — standards library seeded; read-restriction directive

**Customer directive (paraphrased from placement + verbal instruction):**
> PMBOK 8th Edition and SWEBOK V4.0 have been placed in
> `docs/library/local/` (as `pmbok.pdf` and `swebok-v4.pdf`). Both are
> copyrighted third-party standards. Do **not** open either PDF until
> Thursday **2026-04-23**, when the token allotment refreshes.

**Context:** Researcher was asked to register the two files in a new
`docs/library/INVENTORY.md` populated exclusively from public metadata
(PMI bookstore, IEEE Computer Society SWEBOK page) without reading
the PDFs. Inventory rows are `LIB-0001` (PMBOK 8) and `LIB-0002`
(SWEBOK V4.0) in `/home/quackdcs/SWEProj/docs/library/INVENTORY.md`.

**Implications:**
- No agent may open `docs/library/local/pmbok.pdf` or
  `docs/library/local/swebok-v4.pdf` before 2026-04-23. This blocks
  Read, pdftotext, pdfplumber, strings, and any other extraction.
- Public-metadata discrepancy flagged on LIB-0001: customer year
  "2025" matches the Kindle release (2025-11-13); paperback is dated
  2026-01-13. Not resolved — verification requires opening the PDF.
- Paraphrase policy (CLAUDE.md § IP policy) applies once reading is
  unblocked: cite by row ID, no verbatim commits, no redistribution.

**Recorded by:** researcher.

## 2026-04-19 — SME contract (Fix-C hybrid): primary-source vs derivative modes

**Question (from architect, relayed by tech-lead):**
> Issue #6 surfaces that the current SME scope (customer-specific or
> externally-held non-public knowledge only) blocks a common mental
> model of "domain specialist that uses any source." Three candidate
> fixes: A — tighten current model + document feeding workflow;
> B — broaden SME to "domain specialist over curated sources" (a
> MAJOR, binding-rule reversal); C — hybrid, project chooses per
> domain. Which?

**Customer answer (verbatim):**
> "3 - if SMEs have sources that aren't public (humans, proprietary
> documentation) then they use that and web research. if they don't
> have any of that, then they take the researcher's findings and
> provide opinions on them. this way the researcher doesn't get a
> clogged context."

**Ruling (canonical).** Fix-C with sharper formulation. Two operating
modes, decided at SME creation time:

- **Primary-source SME.** Has a human or proprietary-documentation
  knowledge source. Cites that source first; may consult public web
  research on top. Acts as the authoritative voice for the domain.
- **Derivative SME.** No primary source. Consumes `researcher`'s
  paraphrases and public citations, applies domain-specialist framing
  and opinions on top. Exists primarily for context segmentation so
  `researcher` does not hold every vendor ecosystem in one context.

Both modes cite sources. The "opinion" in derivative mode is
explicitly flagged as judgment / framing, not as new fact.

**Implications:**
- `CLAUDE.md` § "SME scope" rewritten to describe both modes and the
  creation-time choice. Lands in v0.11.0.
- `sme-template.md` frontmatter gains a `mode: primary-source |
  derivative` field; body gains a "Source(s)" section matching the
  chosen mode.
- Gate 5 ("no open contract-breaking themes") is cleared by this
  ruling. #6 closed.

**Recorded by:** researcher (via tech-lead).

## 2026-04-23 — "NO AI TRAINING" clause scope (LIB-0001 PMBOK 8)

**Context.** PMBOK 8 copyright page (LIB-0001 p. iv) carries an
explicit "NO AI TRAINING" clause. Customer asked whether the audit
pass-2 work (researcher reading the `.txt` extraction, paraphrasing
into committed audit documents) violates the clause, since AI models
were the readers.

**Customer said:** "good point. go with (a) and I think your work is
ok." — selecting option (a), the narrow interpretation.

**Narrow interpretation (ratified):**
- Prohibited: updating model weights via training, fine-tuning, or
  RLHF on the material; persistent embedding / vector-store
  ingestion that retains the source text across sessions.
- Permitted: transient in-context reading — passing the text to the
  model currently working, for immediate paraphrase or
  summarization, after which the text does not persist.

**Implications:**
- Audit pass-2 work (SWEBOK + PMBOK gap analyses) retained as valid.
- `CLAUDE.md` § IP policy gains a scope clarification under the
  "Restricted-source clauses beyond default copyright" bullet.
- `researcher.md` § Cite hygiene restates the scope.
- `AI-USE-POLICY-template.md` §2.7 Copyright cross-references the
  interpretation and allows per-project override to a stricter rule.
- Revisit the interpretation if PMI (or another restricted-source
  publisher) issues guidance narrowing or broadening the clause.

**Recorded by:** tech-lead (self-recorded; no researcher dispatch for
in-turn ruling).

## 2026-04-23 — Hard Rule #7 (security-engineer release sign-off) confirmed

**Context.** `code-reviewer` audit of the P1 remediation edits flagged
that Hard Rule #7 (new binding on every future release touching
authentication, authorization, secrets, PII, or network-exposed
endpoints) had been implicitly authorized via the customer's "do the
items in your recommended sequence" (2026-04-23) but not explicitly
confirmed on its exact wording. `tech-lead` brought the exact wording
back to the customer plus a plain-language explanation of what the
rule does and does not do (release gating via agent sign-off; not
a write-time code restriction; not automated secret scanning).

**Customer said:** "ok. I think the rule is good as is. if this is
ever widely adopted and people hate it, we can remove it."

**Ruling.** Hard Rule #7 wording in `sw-dev-team-template/CLAUDE.md`
ratified as authored. Adoption friction, if surfaced by downstream
projects, is grounds for revision in a future template release —
not an immediate concern.

**Implications.**
- Hard Rule #7 cleared to ship in v0.11.0.
- Automated secret-scanning (pre-commit hooks, gitleaks / truffleHog
  in CI) is a separate concern and is not part of Hard Rule #7.
  Logged as a possible v0.12.0+ follow-up: `release-engineer`
  pipeline spec + pre-commit hook template for secret detection.

**Recorded by:** tech-lead (self-recorded).

## 2026-04-23 — Retrofit flow (upstream issue #3) approach pinned

**Context.** Tech-lead asked whether the v0.11.0 bundle should
ship a retrofit script for migrating an existing project onto the
team template, since `scripts/scaffold.sh` /
`scripts/repair-in-place.sh` / `scripts/upgrade.sh` cover the
fresh-project / unzipped-in-place / upgrade cases but not the
adopt-on-an-existing-codebase case.

**Customer said:** "do not pause. your memory is correct. The user
scaffolds an empty directory then asks to migrate the project from
its original directory. The agents have to figure out what is there
and how they migrate it."

**Ruling / flow definition.** The retrofit is not a script; it is
an agent workflow invoked after a normal scaffold:

1. User runs `scripts/scaffold.sh <new-empty-target>` to produce a
   clean scaffolded project.
2. Inside the new scaffolded project, user asks `tech-lead` to
   migrate their existing codebase from a named source path.
3. `tech-lead` dispatches the appropriate agents —
   `onboarding-auditor` (to produce a friction/inventory report
   against the source), `architect` (structural decisions on what
   to move where), `researcher` (source-material inventory and IP
   triage), `project-manager` (charter + risk capture from the
   source), `code-reviewer` (final conformance pass).
4. The agents decide what to pull, where it lands, which registers
   to populate, and which template conventions to apply. No
   blanket copy; driven by the source inventory.

**Implications:**
- Upstream issue #3 stays v2-scoped on the script side because a
  script is not the right artifact. v2 work will document the
  agent-workflow shape, perhaps as a new `docs/retrofit-playbook.md`
  and an addition to the `tech-lead.md` routing table ("migrate
  from existing project → dispatch onboarding-auditor first").
- `onboarding-auditor` (landing this cycle) is directly reusable
  for step 3 of the retrofit flow — zero-context audit of the
  source project is exactly what the retrofit needs.
- v0.11.0 does not need to address this. Tag proceeds.

**Recorded by:** tech-lead (self-recorded).

## 2026-05-12 — spec-kit-tech-lead-governance (turn: docs/intake-log.md turn 1)

**Context.** Customer provided guidance during M2 implementation on the
correct Spec Kit integration model for scaffolded `sw-dev-team-template`
projects.

**Customer guidance (concise preservation):**
- In a scaffolded `sw-dev-team-template` project, the main session is
  already `tech-lead`.
- `tech-lead` invokes Spec Kit as a subordinate workflow tool for draft
  specification, clarification, planning, task-generation, analysis, and
  optional task-to-issue conversion outputs.
- Spec Kit output is candidate material, not automatically
  customer-facing output or final authority.
- `tech-lead` must govern Spec Kit output: adjudicate, route, atomize
  customer-owned questions, record answers through the existing intake /
  `researcher` / `CUSTOMER_NOTES.md` flow, and enforce sw-dev role gates.
- Raw Spec Kit implementation output must not bypass `architect`,
  `software-engineer`, `qa-engineer`, `code-reviewer`, `project-manager`,
  or `release-engineer`.
- Slash commands, skills, and wrapper commands are all acceptable
  harness-specific invocation surfaces if output returns to `tech-lead`
  for routing and gate enforcement.
- Core rule: Spec Kit may generate; `tech-lead` must govern.

**Recorded by:** researcher.

## 2026-05-14 — #170 escape hatch policy (turn: pending — flagged to tech-lead)

**Context.** Post-PR-#162 triage: architect proposed hybrid design for
pre-bootstrap edited-file protection (#170). Open decision: knowing-override
mechanism for operators who intentionally want to overwrite a customised
file.

**Question (from architect, relayed by tech-lead):**
> knowing-override path: `SWDT_PREBOOTSTRAP_FORCE=1` env var, or operator must `rm`-then-re-run?

**Customer answer (verbatim):**
> A

**Ruling.** `SWDT_PREBOOTSTRAP_FORCE=1` env var is the escape hatch (option A).

**Implications:**
- Pre-bootstrap edited-file check honours `SWDT_PREBOOTSTRAP_FORCE=1` as
  the explicit operator override; no `rm`-then-re-run required.
- ADR-NNNN (in flight by architect on `feat/rc12-followup-triage`)
  documents the design.

**Cross-refs:** → ADR-NNNN (architect in flight); issue #170.

**Recorded by:** researcher (via tech-lead).

## 2026-05-14 — #170 baseline-unreachable behaviour (turn: pending — flagged to tech-lead)

**Context.** Post-PR-#162 triage: open decision on the pre-bootstrap
edited-file protection (#170) for the case where the baseline SHA is
unreachable (e.g., shallow clone, missing ref, force-pushed history).

**Question (from architect, relayed by tech-lead):**
> when baseline SHA is unreachable, refuse-all-edited-files or fall back to silent-overwrite-with-warning?

**Customer answer (verbatim):**
> refuse the upgrade and make the user run it as a retrofit.

**Ruling.** When the baseline SHA is unreachable, the upgrade is refused;
the operator must re-run the flow as a retrofit. No silent-overwrite
fallback.

**Implications:**
- Upgrade path hard-fails on unreachable baseline rather than degrading
  to a warning-only mode.
- Retrofit flow (the agent-workflow form documented 2026-04-23) is the
  prescribed fallback when baseline comparison cannot be performed.
- ADR-NNNN (in flight by architect on `feat/rc12-followup-triage`)
  documents the design.

**Cross-refs:** → ADR-NNNN (architect in flight); issue #170; retrofit
flow ruling 2026-04-23.

**Recorded by:** researcher (via tech-lead).

## 2026-05-14 — #172 migration scope (turn: pending — flagged to tech-lead)

**Context.** Post-PR-#162 triage: open decision on the scope of the
schema-backfill migration (#172, `migrations/v1.0.0-rc9.sh`).

**Question (from architect, relayed by tech-lead):**
> widen to all canonical agents only, or also include `*-local.md` supplements?

**Customer answer (verbatim):**
> b

**Ruling.** Include `*-local.md` supplements in the migration scope
(option b).

**Boundary note.** This crosses the framework/project boundary per
`docs/framework-project-boundary.md` (canonical framework files vs
project-owned `*-local.md` supplements). The customer's ruling
explicitly accepts the boundary cross for this specific migration
(schema-backfill); not a general precedent.

**Implications:**
- `migrations/v1.0.0-rc9.sh` operates on both canonical agent files and
  project-owned `*-local.md` supplements when backfilling schema.
- Boundary-cross is one-off and ruling-specific; future migrations must
  re-decide scope explicitly.

**Cross-refs:** → issue #172; `migrations/v1.0.0-rc9.sh`;
`docs/framework-project-boundary.md`.

**Recorded by:** researcher (via tech-lead).

## 2026-05-14 — #170/#163 sequencing (turn: pending — flagged to tech-lead)

**Context.** Post-PR-#162 triage: open decision on the relative ordering
of #170 (pre-bootstrap edited-file protection, ADR-gated) and #163
(customisation-marker hotfix).

**Question (from architect, relayed by tech-lead):**
> #170-first-then-#163, or #163-as-hotfix-now?

**Customer answer (verbatim):**
> A

**Ruling.** #170 ships first as ADR-gated work; #163's customisation-marker
follows (option A). No #163 hotfix ahead of #170.

**Implications:**
- #170 ADR drafting (architect, in flight on `feat/rc12-followup-triage`)
  is on the critical path; #163 work queues behind it.
- Customisation-marker design in #163 can be informed by the #170 ADR
  rather than retrofitted around an in-flight hotfix.

**Cross-refs:** → issue #170; issue #163.

**Recorded by:** researcher (via tech-lead).

## 2026-05-14 — FW-ADR-0010 override-audit surface (turn: pending — flagged to tech-lead)

**Context.** Post-PR-#162 triage: FW-ADR-0010 (commit `876208f` on
`feat/rc12-followup-triage`) introduces `SWDT_PREBOOTSTRAP_FORCE=1` as
the operator escape hatch for pre-bootstrap's refuse-on-edit behaviour
(ruling 2026-05-14 — #170 escape hatch policy). Open decision on where
the override-audit row lands when an operator exercises the hatch.

**Question (from architect, relayed by tech-lead):**
> Where does the override-audit row land when an operator uses `SWDT_PREBOOTSTRAP_FORCE=1` to bypass pre-bootstrap's refuse-on-edit?
> A) Overload `docs/pm/pre-release-gate-overrides.md` (add a `Gate` column distinguishing `pre-release` from `pre-bootstrap`; existing rows leave the new column empty)
> B) Sibling file `docs/pm/pre-bootstrap-overrides.md` (separate clean-header append-only log)

**Customer answer (verbatim):**
> A

**Ruling.** Single audit history on the existing append-only file with a
new `Gate` column (option A). No sibling file.

**Implications:**
- Schema bump on `docs/pm/pre-release-gate-overrides.md`: new `Gate`
  column with values `pre-release` or `pre-bootstrap`. Existing rows
  leave the new column empty.
- FW-ADR-0010 to be updated to encode "audit row goes to the shared
  file with the new `Gate` column."
- Software-engineer implementing #170 must add the column to the file
  header AND emit the column value (`pre-bootstrap`) when appending
  rows on `SWDT_PREBOOTSTRAP_FORCE=1` overrides.
- Existing pre-release-gate hook (`.git-hooks/pre-push`) also writes
  to this file; its append code must be updated to fill the column
  with `pre-release`.

**Cross-refs:** → FW-ADR-0010 (commit `876208f` on
`feat/rc12-followup-triage`); issue #170;
`docs/pm/pre-release-gate-overrides.md`; `.git-hooks/pre-push`; prior
2026-05-14 rulings (#170 escape hatch policy, #170 baseline-unreachable
behaviour, #172 migration scope, #170/#163 sequencing).

**Recorded by:** researcher (via tech-lead).

## 2026-05-14 — Hard Rule #8 enforcement: Routed-Through trailer scope (turn: pending — flagged to tech-lead)

**Context.** Hard Rule #8 enforcement design (architect `architect-hr8`,
design completed 2026-05-14) proposes a `Routed-Through:` commit-message
trailer plus a lint script (`scripts/lint-routing.sh`) to enforce that
non-orchestration commits past `HARDGATE_AFTER_SHA` carry a specialist
trailer. Customer directive 2026-05-14 framing the design: "it isn't
about doing things fast. we are trying to do them right. we need
stronger enforcement." Open decision on the scope of the trailer
requirement: every commit, or only commits whose changed files match
the architect's classification table.

**Question (from architect, relayed by tech-lead):**
> The Hard Rule #8 enforcement design proposes a `Routed-Through:`
> commit-message trailer plus a lint script. Should the trailer be
> required on every commit past `HARDGATE_AFTER_SHA`, or only on
> commits whose changed files match the architect's classification
> table (code/ADRs/CHANGELOG/CUSTOMER_NOTES/tests/workflows/security
> docs)?
> A) Required on every commit past the cutoff.
> B) Required only on commits whose changed files match the
>    classification table.

**Customer answer (verbatim):**
> A

**Ruling.** `Routed-Through:` trailer required on every commit past
`HARDGATE_AFTER_SHA` (option A). Includes one-line typo fixes,
intake-log appends, and all routine orchestration commits — no
classification-based exemption.

**Implications:**
- No file-pattern carve-out; lint applies uniformly to every commit
  past the cutoff.
- Tool-bridge / orchestration commits still satisfy the trailer
  requirement via the qualifier set (see companion ruling 7).
- Lint script (`scripts/lint-routing.sh`, forthcoming) enforces
  presence of `Routed-Through:` on every commit past the cutoff
  without inspecting changed-file paths to gate the requirement.

**Cross-refs:** → FW-ADR-NNNN (architect `architect-hr8` drafting in
parallel); `scripts/lint-routing.sh` (forthcoming); Hard Rule #8 in
`sw-dev-team-template/CLAUDE.md`; customer directive 2026-05-14
("stronger enforcement").

**Recorded by:** researcher (via tech-lead).

## 2026-05-14 — Hard Rule #8 enforcement: tool-bridge qualifier enumeration (turn: pending — flagged to tech-lead)

**Context.** Hard Rule #8 enforcement design (architect `architect-hr8`,
design completed 2026-05-14) defines a tool-bridge qualifier set for
`Routed-Through:` trailers covering commits that `tech-lead` performs
as a tool bridge rather than as authored work. Initial qualifier set:
`agent-push`, `orchestration`, `ci-fixup`, `merge`, `revert`. Open
decision on whether git history operations `rebase` and `cherry-pick`
join the set.

**Question (from architect, relayed by tech-lead):**
> Should the tool-bridge qualifier set (`agent-push`, `orchestration`,
> `ci-fixup`, `merge`, `revert`) also include git history operations
> `rebase` and `cherry-pick`?
> A) Yes — add `rebase` and `cherry-pick` to the qualifier set.
> B) No — keep the set as proposed; rebase/cherry-pick commits need
>    a specialist trailer.

**Customer answer (verbatim):**
> A

**Ruling.** Add `rebase` and `cherry-pick` to the tool-bridge qualifier
set (option A). Tech-lead can use the tool-bridge qualifier for
PR-cleanup operations (rebases, cherry-picks) without those commits
needing a specialist trailer.

**Implications:**
- Final tool-bridge qualifier set: `agent-push`, `orchestration`,
  `ci-fixup`, `merge`, `revert`, `rebase`, `cherry-pick`.
- `tech-lead` PR-cleanup workflows (interactive rebases, cherry-picks
  during conflict resolution or branch curation) ship under the
  tool-bridge qualifier without specialist routing.
- Qualifier list lives in `scripts/lint-routing.sh` as the
  allowed-values check; expanding the set later requires a fresh
  customer ruling or an ADR amendment.

**Cross-refs:** → FW-ADR-NNNN (architect `architect-hr8` drafting in
parallel); `scripts/lint-routing.sh` allowed-values check; companion
ruling 2026-05-14 (Routed-Through trailer scope).

**Recorded by:** researcher (via tech-lead).

## 2026-05-14 — Hard Rule #8 enforcement: R5 CUSTOMER_NOTES.md cutoff (turn: pending — flagged to tech-lead)

**Context.** Hard Rule #8 enforcement design (architect `architect-hr8`,
design completed 2026-05-14) defines pattern R5 in the lint's pattern
table: commits touching `CUSTOMER_NOTES.md` with a non-`researcher`
trailer fail the lint, because `CUSTOMER_NOTES.md` is sole-owned by
`researcher`. The general lint cutoff (`HARDGATE_AFTER_SHA`)
grandfathers pre-cutoff history. Open decision on whether R5 is
hard-gated from day one (ignoring the grandfather) or follows the
general cutoff.

**Question (from architect, relayed by tech-lead):**
> `CUSTOMER_NOTES.md` is sole-owned by `researcher`. Pattern R5
> catches commits touching it with non-`researcher` trailer. Should R5
> be hard-gated from day one (ignoring HARDGATE_AFTER_SHA grandfather),
> or follow the general cutoff?
> A) Hard-gate R5 from day one (ignore the grandfather).
> B) R5 follows the general cutoff — symmetric with all other file
>    classes.

**Customer answer (verbatim):**
> B

**Ruling.** R5 follows the general `HARDGATE_AFTER_SHA` cutoff (option
B). `CUSTOMER_NOTES.md` is treated symmetric with all other file
classes — no special early-gate. Pre-cutoff commits touching
`CUSTOMER_NOTES.md` without a `researcher` trailer are grandfathered.

**Implications:**
- R5 enforcement starts at `HARDGATE_AFTER_SHA` like every other
  pattern; no asymmetric early-gate.
- Pre-cutoff history with `CUSTOMER_NOTES.md` touches under
  non-`researcher` trailers (or no trailer at all) remains valid
  history and does not need backfill.
- Symmetry preserved across the pattern table: one cutoff governs
  all file classes.

**Cross-refs:** → FW-ADR-NNNN (architect `architect-hr8` drafting in
parallel); `scripts/lint-routing.sh` §"Pattern IDs" (R5 row);
companion 2026-05-14 rulings (Routed-Through trailer scope, tool-bridge
qualifier enumeration).

**Recorded by:** researcher (via tech-lead).

## 2026-06-02 — fw-adr-0021 semver + gate-default rulings (turn: pre-intake)

**Question (from architect, relayed by tech-lead):**
> (1) Should the fw-adr-0021 handoff-schema change ship as a minor
> semver bump or wait for a v1.2 handoff-contract milestone?
> (2) Should the new dispatch gate default to warn (enforce opt-in)
> or enforce from day one?

**Customer answer (verbatim):**
> rulings look good.

Accepting architect-recommended options: minor semver bump; warn
default with enforce opt-in.

**Pointer:** `docs/adr/fw-adr-0021-harness-agnostic-leaf-task-dispatch.md`
**Recorded by:** researcher

## 2026-06-02 — fw-adr-0022 description-source + lint-placement rulings (turn: pre-intake)

**Question (from architect, relayed by tech-lead):**
> (1) Where do Gemini per-agent `description` values live — dedicated YAML
> vs a new `gemini_description` frontmatter field in `.claude/agents/<role>.md`?
> (2) Lint placement — extend existing agent-contract lint vs a separate
> gemini lint script?

**Customer answer (verbatim):**
> "1: how did we do it for codex? make it all match."

Resolution (paraphrase): reuse the canonical `.claude/agents/<role>.md`
`description:` field, generated into `.gemini/agents/` by
`compile-runtime-agents.sh` (both proposed options rejected); lint via
the existing canonical_sha path that already covers `.opencode/agents/`
(no separate gemini lint script).

**Pointer:** `docs/adr/fw-adr-0022-gemini-harness-adapter.md`
**Recorded by:** researcher

## 2026-06-03 — fw-adr-0024 / #212: parallel-agent working-tree race — Hybrid adopted (turn: no intake-log entry; see flag to tech-lead)

**Question (from architect, relayed by tech-lead, Q-0019):**
> fw-adr-0024 / #212: which parallel-agent isolation strategy to adopt for readers vs writers sharing the canonical checkout?

**Customer answer (verbatim):**
> Hybrid adopted: readers (code-reviewer/researcher) run in throwaway git worktrees; writers serialized on the canonical checkout via a writer-lane token. Implement the 11 enumerated contract/helper changes. fw-adr-0024 → Accepted.

**Recorded by:** researcher

## 2026-06-03 — fw-adr-0023 / #276: handoff activity-array growth — Sidecar adopted (turn: no intake-log entry; see flag to tech-lead)

**Question (from architect, relayed by tech-lead, Q-0020):**
> fw-adr-0023 / #276: how to address unbounded growth of the handoff activity array?

**Customer answer (verbatim):**
> Sidecar adopted: move `activity` to a gitignored `docs/handoffs/<task>.activity.jsonl`; MINOR schema bump + one-time migration; removes the hash-exclusion normalizer. fw-adr-0023 → Accepted.

**Recorded by:** researcher

## 2026-06-03 — #301 (P13): add ui-ux-designer role (turn: no intake-log entry; see flag to tech-lead)

**Question (from tech-lead, Q-0021):**
> #301 (P13): should a ui-ux-designer role be added as the 14th canonical role?

**Customer answer (verbatim):**
> Add ui-ux-designer role (14th canonical role; owns UX design + WCAG/accessibility; likely wraps accesslint).

**Recorded by:** researcher

## 2026-06-03 — #290: add mcp-liaison role (turn: no intake-log entry; see flag to tech-lead)

**Question (from tech-lead, Q-0022):**
> #290: should an mcp-liaison role be added to own delegated external-model MCP sessions?

**Customer answer (verbatim):**
> Add mcp-liaison role (owns delegated external-model MCP sessions; brief construction + divergence reconciliation).

**Recorded by:** researcher

## 2026-06-03 — #291: split researcher into researcher + librarian (turn: no intake-log entry; see flag to tech-lead)

**Question (from tech-lead, Q-0023):**
> #291: should researcher be split into two roles — investigation vs record custodian?

**Customer answer (verbatim):**
> Split researcher into researcher (investigation) + librarian (record custodian: CUSTOMER_NOTES, OPEN_QUESTIONS, glossary, SME inventory, archival).

**Recorded by:** researcher

## 2026-06-03 — #302 (P14): project-tailoring/integrity-level artifact — declined (turn: no intake-log entry; see flag to tech-lead)

**Question (from tech-lead, Q-0024):**
> #302 (P14): should a project-tailoring/integrity-level artifact be added to support non-uniform ceremony across projects?

**Customer answer (verbatim):**
> Keep uniform ceremony — decline project-tailoring/integrity-level artifact; close #302 won't-fix.

**Recorded by:** researcher

## 2026-06-03 — #303 (P15): clarification-session mode (turn: no intake-log entry; see flag to tech-lead)

**Question (from tech-lead, Q-0025):**
> #303 (P15): should a clarification-session mode be documented that relaxes HR-11 cadence within an opted-in session?

**Customer answer (verbatim):**
> Document a clarification-session mode: inside an opted-in session, tech-lead asks sequential one-axis questions back-to-back (relaxing HR-11 cadence) while each stays atomic (one decision axis); shape rule stays binding.

**Recorded by:** researcher

## 2026-06-03 — #287: specialist poll-loop bounding (turn: no intake-log entry; see flag to tech-lead)

**Question (from tech-lead, Q-0026):**
> #287: how should specialists handle unbounded polling or long-running background tasks?

**Customer answer (verbatim):**
> Bounded + harness mechanism: specialists must not poll-loop unbounded; cap and escalate to tech-lead, with a background-task auto-re-invoke pattern (ties to #265).

**Recorded by:** researcher

## 2026-06-03 — #293: delegated-specialist mode across all supported providers (turn: no intake-log entry; see flag to tech-lead)

**Question (from tech-lead, Q-0027):**
> #293: should delegated-specialist mode be added to all supported harness providers, or only AGENTS.md?

**Customer answer (verbatim):**
> Add delegated-specialist mode across ALL supported providers (AGENTS.md/Codex, GEMINI.md/Gemini, opencode, etc.), not just AGENTS.md.

**Recorded by:** researcher

## 2026-06-03 — #300 (P12): Gemini full-team harness (turn: no intake-log entry; see flag to tech-lead)

**Question (from tech-lead, Q-0028):**
> #300 (P12): should the Gemini full-team harness be built now as a standalone, or deferred until delegated-specialist parity is resolved?

**Customer answer (verbatim):**
> Build the Gemini full-team harness now, standalone (GEMINI.md + .gemini/agents roster); retrofit delegated-specialist parity (#293) afterward. (fw-adr-0022 already accepted.)

**Recorded by:** researcher

## 2026-06-03 — #294 (P1): ID auto-allocation + CI backstop (turn: no intake-log entry; see flag to tech-lead)

**Question (from tech-lead, Q-0029):**
> #294 (P1): for preventing duplicate ADR/spec/Q IDs, should the solution be a script mechanism, a CI gate, or both?

**Customer answer (verbatim):**
> Both: auto-allocate next-free IDs via reserve-number.sh (mechanism) AND a CI backstop that fails on duplicate ADR/spec/Q IDs.

**Recorded by:** researcher

## 2026-06-03 — #297 (P9): dispatch-template mechanism (turn: no intake-log entry; see flag to tech-lead)

**Question (from tech-lead, Q-0030):**
> #297 (P9): should one-task-per-dispatch be enforced via a dispatch-template mechanism, a CI gate, or both?

**Customer answer (verbatim):**
> Dispatch-template mechanism only: structure dispatch so one-task-per-dispatch is the default shape (no CI gate — dispatch is ephemeral).

**Recorded by:** researcher

## 2026-06-03 — #292: structured CUSTOMER_NOTES + content-aware guard (turn: no intake-log entry; see flag to tech-lead)

**Question (from tech-lead, Q-0031):**
> #292: for improving CUSTOMER_NOTES integrity, should the solution be a structured entry template, a content-aware guard script, or both?

**Customer answer (verbatim):**
> Both: structured CUSTOMER_NOTES entry template (mechanism) AND make customer-notes-guard.py content-aware (flag oversized/off-scope/unstructured entries).

**Recorded by:** researcher

## 2026-06-03 — #299 (P11): authoring checklist for rule enforcement (turn: no intake-log entry; see flag to tech-lead)

**Question (from tech-lead, Q-0032):**
> #299 (P11): should a rule-authoring enforcement checklist be binding or non-binding guidance?

**Customer answer (verbatim):**
> Authoring checklist (non-binding): a guidance checklist reminding rule-authors to consider enforcement — NOT a new binding rule (respects the Q-0018 anti-proliferation concern).

**Recorded by:** researcher
