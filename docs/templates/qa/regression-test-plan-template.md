---
name: regression-test-plan-template
description: ISTQB Regression-testing plus IEEE 829 template; runs every CI invocation and before every release.
template_class: regression-test-plan
---


# Regression Test Plan — <project name>

Shape per ISTQB "Regression testing" + IEEE 829. Owned by
`qa-engineer`. Runs on every CI pipeline invocation plus before
every release.

## 1. Regression suite scope

Three tiers:

| Tier | Scope | Cadence | Budget |
|---|---|---|---|
| Fast smoke | Critical happy paths | every PR | ≤ 5 min |
| Full regression | All known-fixed defects + acceptance flows | every merge to main | ≤ 60 min |
| Nightly / long-run | Soak tests, full acceptance, perf baselines | daily / weekly | ≤ 8 h |

## 2. Regression-case inclusion rules

A defect's fix is merged with a regression test that would have
caught it. The test joins the Fast-smoke tier by default; promote
to Full only if runtime forces the move.

## 3. Selection strategy

- Always run Fast smoke.
- Run Full regression on merges to main and before every release
  tag.
- Run Nightly / long-run on a session-anchored cadence
  (`CLAUDE.md` § Time-based cadences).

## 4. Flaky-test policy

A flake is an incident, not a nuisance. Quarantine a flaky test
within 24 h of detection (exclude from the gating suite, file a
row in `docs/pm/RISKS.md`), and fix or delete within 7 days. A
test "that passes most of the time" is a defect in the test.

## 5. Exit criteria

Every tier green before promotion to the next gate.

## 6. Metrics

- Escape rate to production (defects not caught by regression).
- Flake rate by test file.
- Mean time to quarantine.
- Full-regression runtime trend (avoid gradual bloat).

## 7. References

- ISTQB Foundation Level Syllabus.
- `docs/templates/qa/test-strategy-template.md`.
- Google Testing on the Toilet: "Flakey Tests" discussions (Tier-2).
