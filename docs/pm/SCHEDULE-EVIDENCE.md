# Schedule Evidence - Template Improvement Program M0/M1

PMBOK support/evidence artifact. Owned by `project-manager`.

Purpose: hold closure evidence, raw references, and G0/G1 acceptance
support that should not expand the live schedule surface.

Related files:

- Live schedule: [`docs/pm/SCHEDULE.md`](./SCHEDULE.md)
- Closed-row archive: [`docs/pm/SCHEDULE-ARCHIVE.md`](./SCHEDULE-ARCHIVE.md)
- Token baseline: [`docs/pm/token-economy-baseline.md`](./token-economy-baseline.md)

## Usage

- Keep current milestone, activity, gate, and PR-slice planning in `docs/pm/SCHEDULE.md`.
- Record validation output, closure evidence, raw command references, and acceptance support here.
- Move closed historical schedule rows or reconciliations to `docs/pm/SCHEDULE-ARCHIVE.md`, not this file.

## G0/G1 Acceptance Support

| Gate | Evidence item | Status | Reference |
|---|---|---|---|
| G0 baseline | Baseline acceptance evidence captured before M1 acceptance. | accepted | `docs/pm/token-economy-baseline.md` -> `G0 Baseline Acceptance Evidence` |
| G1 token quick wins | PM schedule split evidence created. | in progress | This file, `docs/pm/SCHEDULE.md`, `docs/pm/SCHEDULE-ARCHIVE.md`, and `docs/pm/token-economy-baseline.md` |

## Architect Runtime Separation Signoff

Date: 2026-05-12

Reviewer: `architect`

Status: Signoff accepted for T063 final M0/M1 review.

Evidence:

- Canonical/generated/manual separation is preserved: `docs/agents/common-runtime.md`, `docs/runtime/agents/README.md`, and `docs/agents/manual/README.md` all state that runtime candidates and manuals are not canonical policy and remain subordinate to `CLAUDE.md`, `AGENTS.md`, `.claude/agents/*.md`, and matching local supplements.
- Runtime candidates are generated role candidates only: each `docs/runtime/agents/*.md` role file names canonical inputs, points to `docs/agents/common-runtime.md`, and keeps role scope under the matching canonical role rather than redefining authority.
- Role authority and escalation boundaries are preserved: common runtime rules keep `tech-lead` as sole customer interface, require local supplement checks, preserve hard rules, route domain gaps through approved sources, and route escalations through `tech-lead`.
- Review evidence records non-blocking compaction gaps for `tech-lead` intake-register naming and `code-reviewer` traceability wording; neither gap changes source authority or role authority because canonical inputs remain controlling.

Blockers: None.

## Final M0/M1 Verification And Signoffs

Date: 2026-05-12

Status: Accepted for final M0/M1 review.

T062 gate verification:

| Check | Status | Evidence |
|---|---|---|
| G0 pass/fail evidence exists before later work | pass | `docs/pm/token-economy-baseline.md` records G0 gate status as accepted and includes pass rows for baseline counts, word proxies, live-register metrics, terminal-row counts, archive candidates, downstream read-only observations, and largest recurring surfaces. |
| G1 pass/fail evidence exists before M2-M9 starts | pass | `docs/pm/token-economy-baseline.md` records G1 status as pass with documented non-blocking compaction gaps and pass rows for runtime candidates, prompt-regression evidence, code-review preservation evidence, archival script/archive surfaces, compact token ledger, and PM schedule split. |
| M2-M9 implementation prohibition recorded | pass | `docs/pm/token-economy-baseline.md` explicitly prohibits M2 token operating model, M3/M4 authority/question-flow repairs, M5 cross-AI routing, M6 compiler/schema/generation pipeline, M7 self-improvement automation, M8 downstream rollout/retrofit, and M9 release-readiness implementation from the M0/M1 task list. |

T063 role signoffs:

| Role | Status | Evidence |
|---|---|---|
| `project-manager` | signed off | G0/G1 schedule evidence, token baseline acceptance, PM schedule split metrics, and this final verification section are recorded in `docs/pm/SCHEDULE-EVIDENCE.md` and `docs/pm/token-economy-baseline.md`. |
| `software-engineer` | signed off | `scripts/archive-registers.sh` implements the archival behavior; T058 records `sh -n scripts/archive-registers.sh` passed; `docs/pm/token-economy-baseline.md` accepts the archival script and archive surfaces. |
| `tech-writer` | signed off | `docs/agents/manual/runtime-manual-guidance.md` preserves manual status, non-authority relationship, review checklist, paraphrase discipline, and canonical-source alignment; `docs/runtime/agents/review-evidence.md` marks `tech-writer` pass. |
| `architect` | signed off | Architect runtime separation signoff is recorded above with no blockers. |
| `qa-engineer` | signed off | `docs/runtime/agents/prompt-regression-evidence.md` records required scenario coverage and overall pass with documented non-blocking compaction gaps; `docs/runtime/agents/review-evidence.md` marks `qa-engineer` pass. |
| `code-reviewer` | signed off | `docs/runtime/agents/review-evidence.md` records overall pass with documented non-blocking compaction gaps and no blocking preservation defects; `docs/runtime/agents/prompt-regression-evidence.md` records the code-reviewer scenario pass with gap. |
| `release-engineer` | signed off | T061 records release-engineer scope signoff: final reviewable diff is M0/M1 framework-maintenance only, with no downstream product files detected. |

Blockers: None.

## Raw References

| Date | Reference | Evidence |
|---|---|---|
| 2026-05-12 | T041-T044 PM schedule split | Live schedule kept to current M0/M1 plan content; no closed schedule rows or historical reconciliations were present to move. |
| 2026-05-12 | T058 shell syntax check | `sh -n scripts/archive-registers.sh` passed with no output. |
| 2026-05-12 | T059 whitespace check | `git diff --check` passed with no output. |
| 2026-05-12 | T061 final diff scope check | `git status --short --untracked-files=all`, `git diff --name-status`, `git diff --cached --name-status`, and `git diff --stat` showed M0/M1 framework-maintenance, generated-runtime, SpecKit integration, PM/register, template-doc, and planning artifacts only; no downstream product source, tests, deployment config, product docs, or downstream repository files were present. |
| 2026-05-12 | T062 G0/G1 final gate check | `docs/pm/token-economy-baseline.md` contains accepted G0 evidence, accepted G1 evidence with documented non-blocking gaps, and explicit M2-M9 implementation prohibition before later-milestone starts. |
| 2026-05-12 | T063 final M0/M1 role signoffs | Final signoff evidence recorded for `project-manager`, `software-engineer`, `tech-writer`, `architect`, `qa-engineer`, `code-reviewer`, and `release-engineer`; no blockers remain. |

## Closure Evidence

| Date | Task | Evidence |
|---|---|---|
| 2026-05-12 | T041 | Created this schedule evidence file for closure evidence, raw references, and G0/G1 support. |
| 2026-05-12 | T042 | Created `docs/pm/SCHEDULE-ARCHIVE.md`; no old closed schedule rows were present in `docs/pm/SCHEDULE.md` at split time. |
| 2026-05-12 | T043 | Updated `docs/pm/SCHEDULE.md` with live/evidence/archive cross-links and kept only current M0/M1 plan sections. |
| 2026-05-12 | T044 | Post-change line counts recorded in `docs/pm/token-economy-baseline.md`. |
| 2026-05-12 | T056 | Planning-scope quickstart checks passed for `plan.md`, `research.md`, `data-model.md`, `quickstart.md`, and absence of `contracts/`. |
| 2026-05-12 | T057 | Literal unresolved-marker quickstart grep matched only the quickstart command example; equivalent scan excluding `quickstart.md` and direct `tasks.md` scan found no unresolved planning markers. |
| 2026-05-12 | T058 | `sh -n scripts/archive-registers.sh` passed with no output. |
| 2026-05-12 | T059 | `git diff --check` passed with no output. |
| 2026-05-12 | T060 | Authority and traceability grep checks found `canonical`/`generated`/`ephemeral` coverage and archive discoverability across the requested live, PM, runtime, agent, customer-notes, open-question, and planning surfaces. |
| 2026-05-12 | T061 | Release-engineer scope signoff: final reviewable diff split is framework-maintenance only for M0/M1; no downstream product files were detected, so the framework/product boundary check passes. |
| 2026-05-12 | T062 | G0 and G1 pass/fail evidence exists in `docs/pm/token-economy-baseline.md`; M2-M9 implementation is explicitly prohibited from the M0/M1 task list. |
| 2026-05-12 | T063 | Final M0/M1 role signoffs recorded for all required roles with no blockers. |
