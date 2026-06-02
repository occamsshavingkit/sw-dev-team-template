## Template version

v1.1.1
SHA 2984c6890046c48c577b7cd3ba3b4d344622b526

## Where

- `.claude/agents/` — no `ui-ux-designer.md` present
- `SW_DEV_ROLE_TAXONOMY.md` — no UX-design entry
- `CLAUDE.md` § "Agent roster" — table has 13 roles, none covering
  visual/interaction design or accessibility
- `docs/sme/CONTRACT.md` — per-project SME mechanism does not
  substitute for a first-class roster role

## What happened

A project with user-facing UI components requiring accessibility
review (WCAG) and interaction-design decisions had no roster agent
owning those responsibilities. `software-engineer` implemented the
UI; `architect` made frontend architecture calls; `tech-writer`
documented the result. Interaction design and accessibility were
handled ad hoc — no owning role, no systematic WCAG audit, no
design-level UX review gate. The per-project SME mechanism was not
sufficient because the gap is structural: no first-class role means
no routing path, no Solution Duel participant for UX failure modes,
and no WCAG sign-off.

Provenance: surfaced in a Gemini external review of the team design
(2026-06-02), triaged against framework reality by `tech-lead`.

## Why it is a gap

SFIA v9 includes "User experience design" as a distinct skill
(HCEV). ISO 9241 (usability) and WCAG 2.x (accessibility) each
require a designated owner for systematic coverage. The roster's
standards basis (SWEBOK, ISO 12207, SFIA v9) does not exclude UX
design roles; the gap is omission, not standard conflict. For any
user-facing project the absence produces a routing void: no agent
owns the decision, so it defaults silently to `software-engineer`
(an implementation role) or goes unaddressed.

## Suggested fix

Add `.claude/agents/ui-ux-designer.md` mapped to the taxonomy
(SFIA v9 HCEV or equivalent). Define explicit boundaries:
- `ui-ux-designer` owns: interaction design, UX research synthesis,
  WCAG audit, accessibility sign-off, design-system decisions.
- `software-engineer` owns: implementation of the design.
- `architect` owns: frontend architecture decisions that constrain
  design options.
- `tech-writer` owns: user-facing documentation.

Determine at authorship time whether this is a fixed roster slot or
a per-project SME-class agent (and document the decision in
`SW_DEV_ROLE_TAXONOMY.md`).
