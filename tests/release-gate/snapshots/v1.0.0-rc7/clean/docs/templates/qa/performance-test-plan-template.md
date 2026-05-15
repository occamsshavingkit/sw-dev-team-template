# Performance Test Plan — <project name>

Shape per ISTQB "Performance testing" + SWEBOK V4 ch. 5 "Software
Testing" + ch. 6 "Software Engineering Operations" §2 Planning.
Owned jointly by `sre` (defines the non-functional targets and
runs the tests) and `qa-engineer` (conformance audit).

## 1. Scope and types

| Type | In scope? | Target / threshold |
|---|---|---|
| Load (nominal) | yes / no | p99 latency ≤ N ms at M RPS |
| Stress (beyond nominal) | yes / no | degradation mode ≤ N% error |
| Soak / endurance | yes / no | stable for H hours |
| Spike | yes / no | recover within S seconds |
| Scalability | yes / no | linear to K × baseline |
| Volume (data) | yes / no | works at V rows / GB |
| Capacity | yes / no | sustains C concurrent users |

## 2. Non-functional requirements traced

Each row cites a requirement in `docs/requirements.md`. No
performance target survives without a requirement row somewhere.

## 3. Test environment

Production-mirror per `docs/operations-plan.md`; include reset +
warm-up procedure; include data-size assumptions.

## 4. Test data

Representative distribution; note any anonymisation that may affect
performance (e.g., index-cardinality skew).

## 5. Tooling

Load generator (k6 / Locust / Gatling / custom), observability
stack, profiler integration. Ties to `sre`'s monitoring setup.

## 6. Entry / exit criteria

- **Entry:** system test green; staging stable; non-functional
  requirements ratified by customer via `tech-lead`.
- **Exit:** all targets met OR variance documented with customer
  acceptance recorded in `CUSTOMER_NOTES.md`.

## 7. Reporting

Per-run report with baseline comparison; trend dashboard; SLO-
impact analysis feeding `sre`'s error-budget review.

## 8. Defect flow

Regression beyond a stated threshold → incident posture; trace to
the change set; `architect` consulted for structural fix.

## 9. References

- ISTQB Foundation Level Syllabus ("Performance testing").
- SWEBOK V4 ch. 5 §2.5 Non-functional testing; ch. 6 §2 Operations
  Planning.
- SRE book (Beyer et al.) ch. on capacity planning.
- `docs/operations-plan.md` §5 Capacity management.
