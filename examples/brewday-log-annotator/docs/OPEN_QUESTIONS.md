# Open Questions register

Tracks every open question on the project. Steward: `researcher`.
`tech-lead` opens items; the named answerer closes them.

Columns:

- **ID** — `Q-NNNN`, monotonic.
- **Opened** — ISO date.
- **Question** — single sentence, sharp enough to answer.
- **Blocked on** — what cannot proceed until this is answered.
- **Answerer** — `customer` / `tech-lead` / `architect` / `researcher` / `sme-<domain>` / agent name.
- **Status** — `open` / `answered` / `deferred` / `withdrawn`.
- **Resolution** — verbatim answer (if from customer, mirror into `CUSTOMER_NOTES.md`) + date.

Ask the customer **one question per turn**, only when all agents are idle
(so the question does not scroll off screen). See
`.claude/agents/tech-lead.md` Job #1 and `CLAUDE.md` Step 2.

| ID | Opened | Question | Blocked on | Answerer | Status | Resolution |
|---|---|---|---|---|---|---|
| Q-0001 | 2026-04-19 | Project summary — what are we building, for whom, on what stack, and what counts as "done" for Milestone 1? | Project charter | customer | answered | A small web app that a solo craft brewer uses on a tablet in the brewhouse to annotate brew-day events (grain-in, strike, mash-in, sparge, boil start, hop additions, whirlpool, knockout, pitch, crash, transfer) with timestamps, SG readings, and freeform notes, and exports the completed brew-day to PDF for the brewing logbook. Stack: Python FastAPI + HTMX + SQLite (single-user, local-LAN). Milestone 1: the brewer can start a brew-day, add ≥15 preset events with notes, export to PDF. Customer (Alex Keller), 2026-04-19. |
| Q-0002 | 2026-04-19 | Does this project need domain SMEs? | SME plan | customer | answered | Yes — (a) craft-brewing process, (b) food-safety / beverage-licensing (state level), (c) Python web-dev standards + accessibility. Customer, 2026-04-19. |
| Q-0003 | 2026-04-19 | Are you (the customer) one of the SMEs? If so, which domains? | SME plan | customer | answered | Yes — craft-brewing process. Not expert on food-safety regulatory or web-dev accessibility. Customer, 2026-04-19. |
| Q-0004 | 2026-04-19 | For SME domains you are NOT expert in, do you have external SMEs to consult, or must the team recruit / substitute? | SME plan | customer | answered | Food-safety / licensing: deferred — not on Milestone 1 path (PDF is advisory only, not submitted to regulators yet). Web-dev accessibility + Python standards: use `researcher` against Tier-1 sources (WCAG 2.2, PEP style, FastAPI docs); no external human SME needed. Customer, 2026-04-19. |
| Q-0005 | 2026-04-19 | Step 3 — pick a naming category (or custom list, or canonical). | Agent-teams panel | customer | answered | Classical composers. Customer, 2026-04-19. Mapping in `docs/AGENT_NAMES.md`; reflects the category's historical gender skew (no artificial over-representation); personality-matched where possible. |
| Q-0006 | 2026-04-19 | Any hard non-functional constraints for Milestone 1 — uptime, concurrent users, offline operation, tablet-specific input, printing? | Architecture shape | customer | answered | Single user, local-LAN, runs on brewhouse mini-PC; tablet is just a Chromium browser on the LAN. Must work with wet hands (big tap targets, no hover-only affordances). Offline is fine — the mini-PC is the source of truth. Printing via "export PDF, open in browser, print". Customer, 2026-04-19. |
