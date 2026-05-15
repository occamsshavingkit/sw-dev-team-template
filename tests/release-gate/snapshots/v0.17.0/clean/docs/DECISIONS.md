# Decisions log — append-only

This file is the black-box recorder for decisions `tech-lead` (or
any other agent) made on behalf of the customer without live
customer input. Purpose: the terminal Turn Ledger (see
`.claude/agents/tech-lead.md` § "Customer-facing output discipline",
R-2) can scroll away, but this file survives.

**Rules:**

- Append only. Never edit or delete past rows.
- One row per decision. Newest at the bottom.
- If a later decision overrides an earlier one, add a new row and
  write `Supersedes: <earlier ID>` in the `Notes` column.

**Row template:**

```
## D-NNNN — <date> — <one-line decision>

**Who decided:** <agent name or role>
**Options considered:** <A / B / C — short>
**Chose:** <X>
**Why:** <one line>
**Files touched:** <paths, optional>
**Customer visibility:** <shown in turn ledger on YYYY-MM-DD / not yet surfaced>
**Supersedes:** <D-NNNN or —>
**Notes:** <anything else>
```

---

<!-- Append decisions below this line. First entry is D-0001. -->
