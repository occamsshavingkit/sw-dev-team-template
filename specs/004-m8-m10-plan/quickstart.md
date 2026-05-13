# Quickstart: Review the M8-M10 Planning Feature

Use this quickstart to review the planning artifacts before creating tasks with `/speckit.tasks`.

## Artifact Review Order

1. Read `spec.md` first.
   Confirm that M8, M9, and the bounded M10 gap match the requested planning scope and that requirements are expressed as observable planning outcomes.

2. Read `research.md` next, if present.
   Confirm that source authority, rollout assumptions, release-readiness assumptions, and unresolved questions are recorded without adding implementation-only detail.

3. Read `data-model.md` next, if present.
   Confirm that the entities from the spec are represented clearly: Reference Repository, Repair Outcome, Rollout Gate, Release Readiness Audit, Release Candidate Gate, and M10 Gap.

4. Read `plan.md` last.
   Confirm that the plan is filled from the spec and supporting artifacts, has no template placeholders, and preserves framework-maintenance scope.

If `research.md`, `data-model.md`, or a completed `plan.md` is missing, do not treat the feature as ready for `/speckit.tasks`.

## M8 Rollout Planning Verification

Confirm the M8 plan covers all four reference repositories:

| Repository | Required review evidence |
|---|---|
| `QuackDCS` | Retrofitted classification; large `OPEN_QUESTIONS.md`; missing `docs/intake-log.md` observation |
| `QuackPLC` | Retrofitted classification; roadmap/status staleness; missing `docs/intake-log.md` observation |
| `QuackS7` | Retrofitted classification; intake log present; corrected PM-routing behavior |
| `QuackSim` | From-template classification; intake log present; atomic-question violations and growing live registers |

For each repository, verify that the repair outcome includes:

- Required framework file check.
- `docs/intake-log.md` presence or repair.
- Live-register archival or accepted exception.
- Root `ROADMAP.md` repair or quarantine when it contains upstream-template roadmap material.
- PM live/evidence surface sizing and repair if oversized.
- Atomic-question lint disposition.
- PM change-log evidence for the template repair or upgrade.

For Gate G8, verify that all repositories are repaired or explicitly exceptioned, rollout lessons are captured upstream, and scaffold smoke coverage reflects downstream repair lessons.

## M9 Release Readiness Verification

Confirm the M9 plan includes these audit perspectives:

- Code review for agent, ADR, and template conformance.
- QA for scaffold, upgrade, and retrofit validation.
- Release engineering for packaging, versioning, and release notes.
- Project management for risk, schedule, change, and lessons status.
- Onboarding audit for zero-context usability.
- Process audit for process-debt retirement candidates.

Confirm the release criteria include:

- Fresh scaffold smoke tests.
- Retrofit repair evidence on reference repositories or fixtures.
- Passing agent-contract lint.
- Passing question lint on templates.
- Fresh generated artifacts.
- No unresolved high-priority authority-drift issues.
- Current model-routing guidance with exact model IDs marked runtime-verifiable.
- Release notes that distinguish canonical, generated, and ephemeral artifacts.

For Gate G9, verify that code review, QA, release mechanics, project-management risk review, and policy-required customer approval are represented as acceptance requirements.

## M10 Source-Plan Gap Verification

Confirm that M10 is handled only as a source-plan gap:

- `spec.md` states that the authoritative source plan defines M8 and M9 only.
- No M10 objective, milestone, acceptance gate, repository work, or release deliverable is invented.
- Any future M10 work requires a source-plan update or documented follow-up before tasks are generated.

If any artifact adds M10 scope beyond the documented gap, return to planning before `/speckit.tasks`.

## Ready For Tasks

Proceed to `/speckit.tasks` only when the artifact set is complete, M8 and M9 checks are reviewable as pass/fail/exception outcomes, and M10 remains bounded to the documented source-plan gap.
