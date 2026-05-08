# System Test Plan — <project name>

Shape per ISTQB "System testing" + IEEE 829 Level Test Plan.
Owned by `qa-engineer`. End-to-end behavior of the integrated
system against requirements.

## 1. Scope

System-under-test defined: which components, which environment
configuration (`docs/operations-plan.md` ref).

## 2. Test types

- Functional (behavior vs requirements).
- Non-functional sampled here: reliability-spot-checks (deeper in
  `sre`'s perf plan), usability walkthroughs, compatibility matrix.
- Change-related: confirmation tests for recent fixes;
  regression-set execution.

## 3. Test environment

Production-like staging per `docs/operations-plan.md` §3. Data
refresh policy, access controls, reset procedure between test runs.

## 4. Test scenarios

One scenario row per user-visible flow. Trace to requirements.

| ID | Scenario | Requirement | Type | Owner |
|---|---|---|---|---|

## 5. Entry / exit criteria

- **Entry:** integration tests green; staging provisioned; data
  loaded.
- **Exit:** all P0/P1 scenarios pass; P2+ triaged; no open
  blockers for acceptance.

## 6. Defect flow

P0/P1 blocks acceptance. P2 may ship with a documented workaround
and a follow-up task in `docs/tasks/`.

## 7. Reporting

Daily status during test cycle; summary at milestone close;
dashboard link for live view.

Evidence for each run lives under:
`docs/test-evidence/system/<YYYYMMDDThhmmssZ>-<run-id>/`.
The timestamp is first and is the UTC run start time.

Each evidence directory contains `MANIFEST.md` with:

| Field | Required content |
|---|---|
| Run ID | Stable run identifier used in reports and defects. |
| Start timestamp | UTC timestamp matching the directory prefix. |
| Writer identity | Person or agent that wrote the evidence. |

Runbooks and closeout checks verify `MANIFEST.md`. Do not rely only
on directory-name patterns.

## 8. References

- ISTQB Foundation Level Syllabus.
- `docs/templates/qa/test-strategy-template.md`.
- `docs/operations-plan.md` (environment).
- `docs/requirements.md`.
