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
