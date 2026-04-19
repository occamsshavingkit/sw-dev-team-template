# Handover brief — `<teammate-name>` (`<canonical-role>`)

**Generated:** YYYY-MM-DD HH:MM
**Author:** `<agent-writing-the-brief>` (e.g., `tech-lead`, or
`project-manager` when handing over tech-lead itself).
**Reason for respawn:** signal numbers from
`docs/agent-health-contract.md` § 2 (e.g., "signals #3, #7, #10
over the past week").

All claims below cite a source. A claim without a citation does
not belong in a handover brief.

## 1. Who you are

You are **`<teammate-name>`**, role `<canonical-role>` per
`.claude/agents/<role>.md`. You persist across turns via the
agent-teams experimental feature.

## 2. The project

- **Charter:** `docs/pm/CHARTER.md` §1 (cite).
- **Current milestone:** `<M-N, name>`, exit criterion `<cite
  CHARTER.md §5 or SCHEDULE.md>`.
- **TEMPLATE_VERSION:** see `TEMPLATE_VERSION` file at project
  root (cite first line).

## 3. State of your work (as of last known-good turn)

One paragraph per active workstream. Every claim cites a file +
line. Examples:

- "Writing the `BrewDay` PDF export module. Current state:
  `src/export/pdf.py:1-130` implements chronological event
  rendering; pagination not yet implemented. Last change committed
  at `<SHA>`." — cite `git log -1 --format='%H %s'`.
- "Reviewing requirements §4.2 (acceptance test 3)." — cite
  `docs/requirements.md` §4.2.

## 4. Open questions assigned to you

One row per `Q-NNNN` from `docs/OPEN_QUESTIONS.md` where
`Answerer = <teammate-name>` or `<canonical-role>`:

| Q-ID | Question | Blocked on | Status |
|---|---|---|---|

Each `Q-ID` cross-references the row in `OPEN_QUESTIONS.md`;
the brief summarizes, the register is the source.

## 5. Current blocker (if any)

One sentence. If there is no blocker, say so plainly.

## 6. Decisions NOT to revisit

Prior decisions the customer (or architect, or project-manager)
has already made. Cite `CUSTOMER_NOTES.md` entries or ADR
numbers. The respawned teammate MUST treat these as settled.

| Decision | Source |
|---|---|
| e.g., "Stack is Python FastAPI + HTMX + SQLite" | `CUSTOMER_NOTES.md` § 2026-04-19 Q-0001 |

## 7. Hand-off in flight

If another agent is waiting on you right now, name them, cite
where they asked (chat log turn if findable, or the
`OPEN_QUESTIONS.md` row), and state what you owe them.

## 8. Next concrete action

One sentence. What the respawned teammate should do first. Not
a strategy — an action.

---

**Respawn note.** When the new instance starts, it reads this
brief, confirms it can find every cited file + line, and if any
citation is stale it escalates back to the brief's author
before doing any other work.

Never trust a handover brief whose citations do not resolve.
