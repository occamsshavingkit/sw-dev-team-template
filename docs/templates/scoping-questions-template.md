# Scoping Questions (Step 2 queue)

The seed queue `tech-lead` uses to open Step 2 of `CLAUDE.md` FIRST
ACTIONS. Copy one row per decision axis into `docs/OPEN_QUESTIONS.md`
at the start of a new project, add follow-ups as separate one-axis rows,
and ask them **one per idle turn** with all agents idle (see
`CLAUDE.md` "Question-asking protocol").

## Minimum queue

0. **(Step-1 follow-up) Extra installation requests.** Beyond the
   catalog above, are there any specialized skills, plugins, MCP
   servers, agent packs, or tools you already know you want installed
   for this project?
1. **(Step-1 follow-up) Watch-items / issue triggers.** Is there
   anything specific you want the team to watch for or file an issue
   about, such as a known domain risk, style convention, or safety-
   critical behaviour?
2. **Project summary.** What are we building?
3. **Target user.** Who is it for?
4. **Technical stack.** What stack, platform, or existing repository
   should the team assume?
5. **First milestone done criteria.** What counts as done for the
   first milestone?
6. **Deliverable kind.** What shape is the deliverable: code, data,
   artefact, process, or hybrid?
7. **Named deliverables.** What specific deliverables should exist,
   and where should each live if you already know?
8. **Customer-domain terms.** Which customer-domain terms in the
   deliverable description need definitions before design starts?
9. **SME domains.** Which domain SME areas does this project need?
10. **Customer SME role.** Which SME domains, if any, do you
    personally cover?
11. **External SME availability.** For SME domains you do not cover,
    do you have an external SME available?
12. **SME substitute criteria.** If the team must recruit or
    substitute for an SME domain, what acceptance criteria should that
    substitute meet?
13. **Step 3 — agent naming category.** What naming category, custom
    name list, or canonical-name decision should the team use for
    agent names?

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
