---
name: test-strategy-template
description: ISTQB Foundation plus IEEE 829:2008 Master Test Plan template; one per project.
template_class: test-strategy
---


# Test Strategy — <project name>

Master-level test plan. Shape per ISTQB Foundation Level "Test
Planning" and IEEE 829:2008 "Master Test Plan" adapted to this
template's roster. One per project. Owned by `qa-engineer`; inputs
from `architect`, `sre`, `security-engineer`, `project-manager`.

## 1. Test objectives

Named testing objectives traced to project requirements and to the
charter's success criteria (`docs/pm/CHARTER.md` §2).

## 2. Scope

- **In scope:** components, integrations, environments, user
  scenarios covered by the strategy.
- **Out of scope:** explicit; name who owns each excluded surface
  (customer-domain testing by SME, upstream service, separate
  compliance audit, etc.).

## 3. Test levels

One sub-section per level; each cites the level-specific plan
template filled in at `docs/qa/<level>-test-plan.md`.

| Level | Plan template | Owner | Gate position |
|---|---|---|---|
| Unit | `unit-test-plan-template.md` | software-engineer + qa-engineer | pre-commit |
| Integration | `integration-test-plan-template.md` | qa-engineer | pre-merge |
| System | `system-test-plan-template.md` | qa-engineer | pre-release |
| Acceptance | `acceptance-test-plan-template.md` | qa-engineer + customer | release gate |
| Regression | `regression-test-plan-template.md` | qa-engineer | every pipeline |
| Performance | `performance-test-plan-template.md` | sre + qa-engineer | milestone close |
| Security | `security-template.md` §5 | security-engineer + qa-engineer | pre-release |

## 4. Test types

Which ISTQB test types apply to this project: functional,
non-functional (performance / reliability / usability / portability /
maintainability / security), structural, change-related.

## 5. Entry and exit criteria

At the strategy level — what must be true to begin testing each
level, what must be true to declare it done. Level-specific
criteria live in the level plans.

## 6. Test environments

What environments exist (dev / test / staging / prod-mirror), who
provisions them (`sre` + `release-engineer` per
`docs/operations-plan.md`), access control.

## 7. Test data

Source, classification, anonymisation policy. Customer PII /
production data handling per `docs/pm/AI-USE-POLICY.md` §2.2
(Privacy) and the security assurance artefact.

## 8. Tools and automation

SAST / DAST / CI integration / reporting dashboards.

## 9. Defect management

Severity / priority rubric; routing to `software-engineer` for fix,
back to `qa-engineer` for re-test; entry in `docs/pm/RISKS.md` for
any defect that threatens schedule or scope.

## 10. Metrics

Coverage, pass rate, defect density, escape rate to production,
re-open rate. Reported at every milestone close to
`project-manager` for inclusion in `docs/pm/LESSONS.md`.

## 11. Schedule

Anchors into `docs/pm/SCHEDULE.md`. Test cycles are named milestones
on the project schedule, not an afterthought appended at the end.

## 12. Risks and contingencies

Test-specific risks (environment unavailability, data-refresh
delays, team capacity); flow into `docs/pm/RISKS.md`.

## 13. Per-run evidence directories

For evidence written on a system-under-test, appliance, or test bench,
use one timestamp position:

    <axis>-<YYYYMMDDTHHMMSSZ>-evidence/

Each per-run directory contains `MANIFEST.md` or `MANIFEST.json` with:
run ID, UTC start timestamp, writer identity, system-under-test or test
bench identifier, and the generated evidence files.

Runbooks and closeout checks query the manifest contents. They do not
decide whether evidence exists by matching a directory-name pattern.

## 14. References

- ISTQB Foundation Level Syllabus (current edition).
- IEEE 829:2008 / ISO/IEC/IEEE 29119 series (software testing).
- SWEBOK V4 ch. 5 "Software Testing" (library row LIB-0002).
- Project-specific: requirements, charter, operations plan,
  security assurance artefact.
