# Acceptance Test Plan — <project name>

Shape per ISTQB "Acceptance testing" (User Acceptance / Operational
Acceptance / Contract / Regulation / Alpha / Beta). Owned by
`qa-engineer` with the customer as the acceptance authority per
CLAUDE.md Hard Rule #2 and #4.

## 1. Acceptance types in scope

| Type | Applies? | Criterion owner |
|---|---|---|
| User acceptance (UAT) | yes / no | customer |
| Operational acceptance | yes / no | sre |
| Contract / regulatory | yes / no | sme-<domain> + customer |
| Alpha / beta | yes / no | customer |

## 2. Acceptance criteria

Per charter §2 "Measurable objectives and success criteria." Each
row is a verifiable statement with a named verifier.

| ID | Criterion | Verifier | Ref |
|---|---|---|---|
| A-1 | | customer | CHARTER §2 O-1 |

## 3. Entry / exit criteria

- **Entry:** system test complete; all P0/P1 defects closed;
  staging mirror of production available.
- **Exit:** every acceptance criterion passed with a dated
  customer sign-off in `CUSTOMER_NOTES.md`.

## 4. Sign-off procedure

1. `qa-engineer` demonstrates each criterion against the system.
2. Customer reviews per-criterion and signs off one-by-one (not
   bundled) in a single session.
3. `tech-lead` routes the verbatim sign-off to `researcher`;
   `researcher` appends it to `CUSTOMER_NOTES.md` with a new entry
   heading "<date> — Acceptance sign-off: <milestone>".
4. `project-manager` updates `docs/pm/CHARTER.md` §5 milestone
   status and `docs/pm/SCHEDULE.md` variance.

## 5. Rejection / re-test

If a criterion is rejected: one-line rejection reason captured
verbatim; `software-engineer` addresses; `qa-engineer` re-runs;
new sign-off round. Do not silently re-run a rejected criterion
with no fix.

## 6. References

- ISTQB Foundation Level Syllabus.
- CLAUDE.md Hard Rules #2 and #4.
- `docs/pm/CHARTER.md` §2 (success criteria).
