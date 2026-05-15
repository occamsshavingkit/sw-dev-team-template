---
name: scoping-questions-template
description: Seed queue for Step 2 scoping intake; one question per turn with all agents idle.
template_class: scoping-questions
---


# Scoping Questions (Step 2 queue)

The seed queue `tech-lead` uses to open Step 2 of `CLAUDE.md` FIRST
ACTIONS. Copy each question as a row into `docs/OPEN_QUESTIONS.md`
at the start of a new project, add follow-ups as they arise, and
ask them **one per turn** with all agents idle (see
`CLAUDE.md` "Question-asking protocol").

## Minimum queue

0. **(Step-1 follow-up) Specialized skills / watch-items.** Beyond
   the Step-1 skill-pack catalog, are there any specialized skills,
   plugins, MCP servers, agent packs, or tools you want installed
   for this project, or anything specific the team should watch for
   (a known risk in your domain, a style convention, a safety-
   critical behaviour)? Names get verified by `researcher` and
   installed / tracked.
1. **Project summary.** What are we building, for whom, on what stack,
   and what counts as "done" for the first milestone?
2. **Deliverable shape.** What shape is the deliverable: code
   (library / CLI / service / agent), data (dataset / model / corpus),
   artefact (document, skill, playbook, prompt, runbook), process
   (procedure humans or AI follow), or hybrid? Define every customer-
   domain term used in the answer so `tech-lead` can add it to
   `docs/glossary/PROJECT.md` before design work starts.
3. **Domain SMEs.** Does this project need domain SMEs? Candidate
   domains: industry-specific process knowledge, regulatory /
   compliance, legal, accessibility, security, hardware, a specific
   vendor platform or framework, legacy-system archaeology, a specific
   customer site's conventions, localization / i18n, accounting /
   finance rules, anything else.
4. **Customer as SME.** Are you (the customer) one of the SMEs? If
   yes, which domains?
5. **External SMEs.** For SME domains you are NOT expert in — do you
   have external SMEs to consult, or does the team need to recruit /
   substitute? If substitute, say what acceptance criteria the
   substitute must meet.
6. **Step 3 — agent naming category.** Pick a naming category (e.g.,
   Muppets, famous singers, historical scientists), a custom name
   list, or keep canonical role names. `tech-lead` proposes
   specific names; `researcher` verifies pronouns. See
   `docs/AGENT_NAMES.md`.
7. **Step 0 — issue-feedback opt-in** (atomic yes/no). Does this
   project participate in upstream issue feedback when the team hits
   a gap in the framework? See `docs/ISSUE_FILING.md`.

## Follow-ups to consider (ask only when genuinely thin)

- Safety-critical or regulated scope? If yes, cite the standard(s).
- Expected cadence (one-off, sprint, continuous)?
- Target deployment environment(s) and any environment constraints
  that shape architecture (air-gapped, on-prem vendor PLC, browser
  only, mobile only, etc.)?
- Known hard constraints (licensing, toolchain version pinning,
  hardware limits, offline requirement, translation requirements)?
- Stakeholders beyond the customer who must sign off (legal, product,
  security, customer-side ops)?
- First-milestone budget in time or cost (for `project-manager`
  baselining)?

## Done criteria

See `CLAUDE.md` Step 2 "Definition of Done" checklist. Scoping is
complete only when every box is checked.
