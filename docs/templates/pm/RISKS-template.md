# Risk Register — <project name>

PMBOK Planning / Monitoring artifact. Owned by `project-manager`. One
row per risk. Risks are only closed, never deleted.

## Scoring scale

- **Probability.** 1 = rare, 2 = unlikely, 3 = possible, 4 = likely,
  5 = almost certain.
- **Impact.** 1 = negligible, 2 = minor, 3 = moderate, 4 = major,
  5 = severe.
- **Score.** probability × impact (1–25). Any risk ≥ 12 is material
  and requires an explicit response plan, not acceptance.

## Register

| ID | Description | Category | Prob | Impact | Score | Owner | Response (avoid / transfer / mitigate / accept) | Trigger | Status | Last reviewed |
|---|---|---|---|---|---|---|---|---|---|---|
| R-1 | | schedule / cost / technical / external / safety / compliance / people / sustainability / AI-use / other | | | | | | | open / in-response / realized / closed | |

## Response plan details (for material risks)

For each risk with score ≥ 12, a sub-section with:

- Detailed response plan.
- Contingency: what we do if the risk is realized.
- Secondary risks introduced by the response.
- Cost of the response (cross-reference `COST.md`).

## Review cadence

`project-manager` reviews the register at least every milestone. High-
score open risks reviewed in the **first session of each calendar
week**. Every review bumps `Last reviewed`.

Cadences in this framework are **session-anchored, run-once** — the
agent only executes when the customer opens a session, so a cadence
expressed as "weekly" means "in the first session on or after the
week boundary." Missed weeks do not accumulate; the next session runs
the review once, not twice. See `CLAUDE.md` § "Time-based cadences."
