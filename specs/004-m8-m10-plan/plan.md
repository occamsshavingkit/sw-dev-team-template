# Implementation Plan: M8-M10 Plan

**Branch**: `004-m8-m10-plan` | **Date**: 2026-05-13 | **Spec**: `specs/004-m8-m10-plan/spec.md`
**Input**: Feature specification from `specs/004-m8-m10-plan/spec.md`

**Note**: This plan is filled for the `/speckit.plan` workflow. It covers planning and documentation artifacts only; no application code is introduced.

## Summary

Plan the M8 downstream rollout and retrofit repair work for `QuackDCS`, `QuackPLC`, `QuackS7`, and `QuackSim`, then plan M9 release-readiness gates for a stable template release candidate. The plan treats `sw_dev_template_implementation_plan-2.md` as the canonical source for M8 and M9, records M10 as absent from that source, and bounds M10 handling to follow-up gap management until the source plan is amended.

## Milestone Planning Scope

### M8 Downstream Rollout and Retrofit Repair

| Repository | Scaffold mode | Known rollout observations | Planned outcome |
|---|---|---|---|
| `QuackDCS` | Retrofitted | Large `OPEN_QUESTIONS.md`; missing `docs/intake-log.md` observed | Repair or document exception; ensure intake log, live-register disposition, framework-file coverage, boundary compliance, lint disposition, and PM change-log evidence |
| `QuackPLC` | Retrofitted | Roadmap/status staleness; missing `docs/intake-log.md` observed | Repair or document exception; ensure roadmap repair or quarantine, intake log, lint disposition, boundary compliance, and PM change-log evidence |
| `QuackS7` | Retrofitted | Has intake log; customer corrected PM-routing behavior | Verify existing compliance, preserve corrected PM routing, and document any remaining gate exceptions or waivers |
| `QuackSim` | From-template | Has intake log; atomic-question violations and growing live registers | Repair or document historical exceptions; reduce or waive live surfaces, resolve question-lint disposition, and record PM change-log evidence |

M8 acceptance is planned as pass only when all four repositories are repaired or explicitly exceptioned, rollout lessons are captured upstream, and scaffold smoke coverage reflects downstream repair lessons.

### M9 v1.0 Readiness and Release Gate

M9 starts after token, authority, question, routing, compiler, and rollout work are complete or exceptioned. Release readiness requires conformance review by `code-reviewer`, scaffold/upgrade/retrofit verification by `qa-engineer`, release mechanics by `release-engineer`, PM risk/schedule/change/lessons review by `project-manager`, zero-context usability review by `onboarding-auditor`, and process-debt review by `process-auditor`.

G9 acceptance requires fresh scaffold smoke tests, reference retrofit evidence, agent-contract lint, question lint, generated-artifact freshness, no unresolved high-priority authority drift, current model-routing guidance with runtime-verifiable exact model IDs, release notes that classify canonical/generated/ephemeral artifacts, the named specialist approvals, no open release-blocking PM risk, and customer approval when required by release policy.

### M10 Gap Handling

No M10 milestone is planned because the authoritative source plan does not define one. Any future M10 scope requires a source-plan update or separate documented follow-up before objectives, deliverables, tasks, or gates are added.

## Technical Context

**Language/Version**: Markdown planning artifacts; no runtime language version applies.  
**Primary Dependencies**: Spec Kit planning templates, `.specify/memory/constitution.md`, canonical role contracts in `.claude/agents/`, `CLAUDE.md`, `AGENTS.md`, and `sw_dev_template_implementation_plan-2.md`.  
**Storage**: Repository files under `specs/004-m8-m10-plan/`; downstream rollout evidence and release evidence will remain in their owning downstream or framework documentation surfaces.  
**Testing**: Document review against `spec.md`, constitution checks, source-plan coverage review for M8/G8 and M9/G9, placeholder/clarification scan, and later specialist review gates named in M9.  
**Target Platform**: Template-maintenance repository and downstream planning context for `QuackDCS`, `QuackPLC`, `QuackS7`, and `QuackSim`.  
**Project Type**: Documentation, planning, and template-maintenance workflow; not an application, library, service, or mobile project.  
**Performance Goals**: Keep live planning artifacts short enough for routine agent loading; preserve downstream live context soft caps or require waivers during M8.  
**Constraints**: Do not invent M10 scope; preserve product/framework boundaries; route customer-truth capture through `researcher`; require specialist-owned review evidence before release acceptance; distinguish fixed findings from documented exceptions or historical waivers.  
**Scale/Scope**: One feature-spec artifact set covering two defined milestones, two acceptance gates, four downstream reference repositories, and one bounded M10 gap.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Role routing**: PASS. Planning artifacts are owned by `project-manager`; implementation, docs, QA, code review, release mechanics, onboarding audit, process audit, and customer-truth capture remain with their canonical roles. M9 explicitly requires `code-reviewer`, `qa-engineer`, `release-engineer`, `project-manager`, `onboarding-auditor`, and `process-auditor` review. Customer approval, if required by release policy, must be relayed by `tech-lead` and captured by `researcher`.
- **Token/context economy**: PASS. The live plan cites canonical sources instead of duplicating all milestone history. M8 requires archiving oversized live registers, splitting PM live/evidence surfaces where needed, and keeping rollout lessons upstream rather than expanding recurring runtime context.
- **Source authority**: PASS. `sw_dev_template_implementation_plan-2.md` is canonical for M8 and M9 milestone scope; `.specify/memory/constitution.md`, `CLAUDE.md`, `AGENTS.md`, and `.claude/agents/*.md` are canonical governance and role inputs; `specs/004-m8-m10-plan/spec.md` is canonical for this feature's requirements; this `plan.md` and `research.md` are planning outputs derived from those inputs.
- **Customer intake**: PASS. No new customer-owned answer is required to plan M8/M9. M9 customer approval remains conditional on the governing release policy and must be represented as a queued atomic question only if that policy requires direct customer confirmation and no recorded answer exists.
- **Quality gates**: PASS. Plan verification requires source-plan coverage, no unresolved clarification markers, no template placeholders, constitution alignment, and later M9 approvals from code review, QA, release engineering, PM risk review, and customer approval when policy requires it.
- **Framework/project boundary**: PASS. This feature is explicitly template-maintenance planning work. M8 downstream work must keep product changes and framework upgrade or repair changes classified and split unless an exception is documented.
- **Adapter discipline**: PASS. Cross-harness and generated-output work is only referenced through existing canonical role authority. OpenCode, Codex, Claude, Gemini, OpenAI, memory, and compiler surfaces must remain adapters or generated artifacts unless explicitly promoted by canonical policy.

### Post-Design Re-Check

PASS after `research.md`, `data-model.md`, and `quickstart.md`: role routing remains canonical, context cost stays bounded to planning artifacts, source authority is explicit, no new customer-owned answer is introduced, quality gates are reviewable, framework/project boundaries are preserved, and no adapter creates parallel authority.

## Project Structure

### Documentation (this feature)

```text
specs/004-m8-m10-plan/
├── spec.md               # Feature requirements and acceptance criteria
├── plan.md               # This implementation plan
├── research.md           # Phase 0 planning decisions
├── data-model.md         # Phase 1 entity model
├── quickstart.md         # Phase 1 validation guide
├── contracts/            # Phase 1 contracts only if a public interface is defined later
└── tasks.md              # Phase 2 task list from /speckit.tasks
```

### Relevant Repository Root Paths

```text
sw_dev_template_implementation_plan-2.md  # Canonical M8/M9 source plan
.specify/memory/constitution.md           # Spec Kit governance
CLAUDE.md                                 # Shared runtime contract
AGENTS.md                                 # Codex/OpenCode adapter into shared contract
.claude/agents/                           # Canonical specialist role contracts
docs/framework-project-boundary.md        # Framework/product boundary policy
docs/MEMORY_POLICY.md                     # Context and memory policy inputs
docs/TEMPLATE_UPGRADE.md                  # Scaffold/upgrade and template-maintenance guidance
docs/IP_POLICY.md                         # Source and licensing constraints
docs/sme/CONTRACT.md                      # SME routing contract if domain input is needed
docs/pm/                                  # PM registers for risk, schedule, changes, and lessons
scripts/                                  # Existing framework scripts used by later verification tasks
```

**Structure Decision**: Use the Spec Kit documentation artifact layout under `specs/004-m8-m10-plan/`. No `src/`, backend, frontend, mobile, or application test tree is introduced because this feature plans documentation, rollout gates, and release-readiness evidence rather than code.

## Complexity Tracking

No unjustified constitution violations are present. Complexity tracking is not required because all evaluated gates pass without exceptions.
