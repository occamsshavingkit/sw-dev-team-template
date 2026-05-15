# OPEN_QUESTIONS.md archive

Append-only archive paired with `docs/OPEN_QUESTIONS.md`.
Rules in `scripts/archive-registers.sh`.

| Q-0001 | 2026-04-19 | For PMBOK role placement, do we add a dedicated `project-manager.md` agent, harden `tech-lead.md` to own PMBOK, or both? | Template roster shape | customer | answered | **(a)** New dedicated `project-manager.md`; `tech-lead` stays technical. Customer, 2026-04-19. |
<!-- archived 2026-05-13 by archive-registers.sh -->
| Q-0002 | 2026-04-19 | Glossary split — target layout: `docs/glossary/ENGINEERING.md` + `docs/glossary/PROJECT.md`, with existing `docs/GLOSSARY.md` deleted and all references updated. Confirm? | Glossary directory work | customer | answered | Confirmed by customer directive 2026-04-19 (*"we need a glossary directory … with a name like ENGINEERING and a project glossary for project jargon"*). Executed 2026-04-19: `docs/GLOSSARY.md` → `docs/glossary/ENGINEERING.md`, new `docs/glossary/PROJECT.md` stub, all 11 references updated. |
<!-- archived 2026-05-13 by archive-registers.sh -->
| Q-0003 | 2026-04-19 | Which PMBOK artifacts should the new `project-manager.md` agent own as first-class deliverables? | Scope of `project-manager.md` | customer | answered | Superseded by Q-0010 and resolved by milestone scope (c) — full PMBOK seven adopted as template default. |
<!-- archived 2026-05-13 by archive-registers.sh -->
| Q-0004 | 2026-04-19 | `sme-template.md` exists but `CLAUDE.md` never mentions it. Add a §SME creation section to `CLAUDE.md` that points at the template? | CLAUDE.md completeness | tech-lead | answered | Executed 2026-04-19: `sme-template.md` added to roster table; new "Creating an SME agent" section added to `CLAUDE.md`. |
<!-- archived 2026-05-13 by archive-registers.sh -->
| Q-0005 | 2026-04-19 | Move CLAUDE.md Step-2 scoping-question text into `docs/templates/scoping-questions-template.md` so it is maintainable separately? | Template structure | tech-lead | answered | Executed 2026-04-19: created `docs/templates/scoping-questions-template.md`; `CLAUDE.md` Step 2 now references it. |
<!-- archived 2026-05-13 by archive-registers.sh -->
| Q-0006 | 2026-04-19 | Add a `docs/INDEX.md` table-of-contents for all docs? | Doc discoverability | tech-lead | answered | Executed 2026-04-19: `docs/INDEX.md` created covering repo root, `docs/`, `docs/glossary/`, `docs/pm/`, `docs/sme/`, `docs/templates/`, and `.claude/agents/`. |
<!-- archived 2026-05-13 by archive-registers.sh -->
| Q-0007 | 2026-04-19 | Define explicit "definition of done" for the scoping conversation itself. | Scoping gate | customer | answered | Option (iii) — checklist — customer, 2026-04-19. Codified in `CLAUDE.md` Step 2 "Definition of Done" checklist (project summary, SME classification, first milestone, escalation paths, Step-3 naming, project charter, open-questions register). |
<!-- archived 2026-05-13 by archive-registers.sh -->
| Q-0008 | 2026-04-19 | Install Trail of Bits skills into this session via `/plugin marketplace add ~/.claude/trailofbits-skills` + `/plugin install trailofbits-skills@trailofbits-skills`? Customer must type these. | ToB availability this session | customer | answered | Yes — customer, 2026-04-19 (*"install trail of bits into this session too"*). Repo cloned to `~/.claude/trailofbits-skills`; customer types the two `/plugin` slash commands themselves. |
<!-- archived 2026-05-13 by archive-registers.sh -->
| Q-0009 | 2026-04-19 | Pick a naming category (or custom list) for the team. | Agent-team panel readability | customer | answered | **Muppets** — customer, 2026-04-19 (*"muppets has been fun"*). Natural-balance rule applied (no artificial over-representation of minority gender). Mapping filed in the live project's `docs/AGENT_NAMES.md` and exemplified in the template's `docs/AGENT_NAMES.md`. |
<!-- archived 2026-05-13 by archive-registers.sh -->
| Q-0010 | 2026-04-19 | Which PMBOK artifacts should `project-manager` own immediately vs. defer? | PM agent scope | customer | answered | Milestone scope (c), 2026-04-19: seed all seven PMBOK artifact templates in `docs/templates/pm/`. Done 2026-04-19: CHARTER / STAKEHOLDERS / SCHEDULE / COST / RISKS / CHANGES / LESSONS templates in place; `project-manager.md` now points at them. |
<!-- archived 2026-05-13 by archive-registers.sh -->
| Q-0011 | 2026-04-19 | What is the v1 milestone for this template-improvement project? | Milestone definition | customer | answered | Option (c), 2026-04-19: (a) all OPEN_QUESTIONS closed + (b) `docs/templates/pm/` artifact templates seeded + (c) dry-run on a throwaway new project to prove scoping flow end-to-end. |
<!-- archived 2026-05-13 by archive-registers.sh -->
| Q-0012 | 2026-04-19 | Does this project participate in upstream issue feedback (Step 0)? | Gap-reporting convention | customer | answered | **Yes** — customer, 2026-04-19. Stamped `TEMPLATE_VERSION v0.1.0 / 0700927` at project root. Initial gaps filed as issues #1 (scaffold script) and #2 (pronoun verification) against `occamsshavingkit/sw-dev-team-template`. |
<!-- archived 2026-05-13 by archive-registers.sh -->
