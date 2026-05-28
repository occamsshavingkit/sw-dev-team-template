# Implementation Plan: Issues-Based Multi-Machine Coordination Interface

**Branch**: `014-issues-coordination-interface` | **Date**: 2026-05-27 | **Spec**: `specs/014-issues-coordination-interface/spec.md`
**Input**: Feature specification from `specs/014-issues-coordination-interface/spec.md`

## Summary

Build the v1.1.0 "Half B" coordination layer per FW-ADR-0020: an opt-in, additive GitHub-Issues-native convention (labels + milestones + an advisory issue "checkout"/claim with deterministic tie-break + structured comments) that lets multiple operators run the agent set from different machines without colliding, while the in-repo registers stay the binding records and only `tech-lead` talks to the customer. Deliverables are mostly documentation + conventions: a label taxonomy + `gh` setup transcript, a multi-machine operating-model doc, a register-sync authority table, two agent-routed issue templates, model-routing-playbook integration, an optional `github_issue` handoff-schema field, a scaffold gitignore for the per-machine active pointer, governance (FW-ADR-0020 Proposed→Accepted, ROADMAP exit-criteria amendment), and a single-operator + simulated-concurrency claim/collision smoke (live two-machine test deferred per Q-0018).

## Technical Context

**Language/Version**: Markdown (docs/operating model/setup guide); GitHub issue-form YAML (`.github/ISSUE_TEMPLATE/*.yml`); Bash (scaffold edit, label-setup transcript, the simulated-concurrency smoke); JSON Schema (the optional `github_issue` field on `handoff.schema.json`).  
**Primary Dependencies**: GitHub CLI (`gh`) and GitHub Issues/labels/milestones for the documented convention (operator-side, not required by the framework itself); the existing handoff-contract spine (feature 012) and `scripts/scaffold.sh`.  
**Storage**: Repo files for the convention/docs/templates/schema; runtime coordination state (claims, statuses) lives in GitHub Issues/labels — external, advisory, not a binding repo record.  
**Testing**: A shell-based single-operator + simulated-concurrency smoke for the claim/collision/yield/release flows (no live second machine, per Q-0018); schema validation for the new `github_issue` field; a check that a "gate-passed" comment cannot satisfy an evidence gate.  
**Target Platform**: GitHub-hosted repositories whose operators use `gh`; opt-in — single-operator/offline downstream projects need none of it.  
**Project Type**: Framework/template repository — conventions, docs, issue templates, a schema field, and shell tooling.  
**Performance Goals**: N/A (operator-paced coordination); the claim flow is a few sequential `gh` calls with a bounded (~seconds) race window.  
**Constraints**: The claim is ADVISORY/optimistic (GitHub has no atomic lock) with a deterministic tie-break; opt-in/additive; in-repo registers remain authoritative; only `tech-lead` interfaces with the customer; no parallel authority or second customer-interface path; comments never satisfy evidence gates.  
**Scale/Scope**: A documentation + convention surface plus two templates, one optional schema field, one scaffold tweak, and one smoke — modest, mostly non-code.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Role routing (Principle I)**: PASS. Prose/docs/operating-model/setup-guide/templates → `tech-writer`; schema field + scaffold edit + smoke → `software-engineer`; smoke verification → `qa-engineer`; ADR acceptance + ROADMAP amendment → `architect`; pre-commit review → `code-reviewer`. `tech-lead` orchestrates only.
- **Token/context economy (Principle II)**: PASS. Deliverables are opt-in docs/templates; no recurring runtime context added to the agent set. Single-operator projects load none of it.
- **Source authority (Principle III)**: PASS. Canonical: `ROADMAP.md`, `docs/adr/fw-adr-0020-*.md`, `.github/ISSUE_TEMPLATE/*`, the operating-model/setup docs, `schemas/handoff.schema.json`, `scripts/scaffold.sh`. Generated/planning: this plan + research/data-model/contracts/quickstart. GitHub issues/labels are runtime coordination state, never binding records.
- **Customer intake (Principle IV)**: PASS. Adoption ruled by customer (Q-0016); the three sub-rulings (Q-0017/0018/0019) resolved in clarify and recorded. No open customer-owned question blocks planning.
- **Quality gates (Principle V)**: PASS. The claim/collision smoke must pass at the agreed single-operator threshold; the new schema field must validate; `code-reviewer` sign-off before commit.
- **Framework/project boundary (Principle VI)**: PASS. All edits are framework-managed paths in `sw-dev-team-template` (customer-directed v1.1.0 Half-B). No product/framework mixing.
- **Adapter discipline (Principle VII)**: PASS. GitHub Issues are an ADDITIVE coordination surface adapting the existing role model; they do not create parallel authority, a second customer interface, or a binding store that supersedes the in-repo registers.

## Project Structure

### Documentation (this feature)

```text
specs/014-issues-coordination-interface/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── claim-protocol.md          # the advisory claim/checkout state machine + tie-break
│   └── label-taxonomy.md          # status/role/priority/meta labels + milestone convention + comment types
└── tasks.md                       # /speckit-tasks output (not created here)
```

### Source Code (repository root)

```text
sw-dev-team-template/
├── .github/ISSUE_TEMPLATE/
│   ├── agent-task.yml              # NEW — agent-routed task intake (role, acceptance, prior-art, release-note impact)
│   └── agent-review-request.yml    # NEW — review-request routing (review owner, gate references)
├── docs/
│   ├── coordination/               # NEW — operating model, register-authority table, setup guide
│   │   ├── multi-operator-model.md
│   │   ├── register-authority.md
│   │   └── setup-guide.md          # gh label/milestone/template bootstrap transcript
│   ├── model-routing-guidelines.md # integrate the multi-operator playbook hooks
│   └── adr/fw-adr-0020-issues-based-coordination-model.md  # Proposed → Accepted
├── schemas/handoff.schema.json     # add optional `github_issue` field
├── scripts/scaffold.sh             # gitignore .devteam/active-handoff.json downstream
├── tests/coordination/             # NEW — simulated-concurrency claim/collision smoke
│   └── test-claim-protocol.sh
└── ROADMAP.md                      # amend v1.1.0 Half-B exit criteria (Projects → Issues)
```

**Structure Decision**: Group the coordination docs under `docs/coordination/`, the two templates under the existing `.github/ISSUE_TEMPLATE/`, the smoke under a new `tests/coordination/`, and make the minimal schema (`github_issue`) + scaffold (gitignore) + governance (ADR/ROADMAP) edits. Exact final paths/filenames are confirmed at task time.

## Complexity Tracking

No constitution violations require justification.

## Phase 0: Research

Research decisions are captured in `research.md`: the claim/checkout tie-break mechanics and stale-claim recovery (grounded in FW-ADR-0020), the GitHub issue-form template format, the `gh`-based label/milestone bootstrap approach, the optional `github_issue` schema-field shape, and how to validate the claim protocol deterministically with simulated concurrency on a single machine.

## Phase 1: Design & Contracts

Design outputs: `data-model.md` (coordination-issue / claim-record / label-taxonomy / structured-comment / register-authority entities + the optional `github_issue` field), `contracts/claim-protocol.md` (the advisory claim state machine, collision tie-break, yield/release, stale-claim recovery — the testable core), `contracts/label-taxonomy.md` (the label/milestone/comment-type vocabulary), and `quickstart.md` (bootstrap a repo, claim/collide/yield/release walkthrough, opt-out check). The Spec Kit plan pointer in `CLAUDE.md` is updated to this plan.

## Post-Design Constitution Check

- **Role routing**: PASS. Design preserves canonical ownership; docs→tech-writer, code→software-engineer, tests→qa-engineer, governance→architect, review→code-reviewer.
- **Token/context economy**: PASS. Opt-in artifacts; no recurring runtime context.
- **Source authority**: PASS. Canonical inputs cited; GitHub issues remain non-binding coordination state.
- **Customer intake**: PASS. All rulings recorded; nothing open.
- **Quality gates**: PASS. Contracts + quickstart define the smoke surface; one primary verification per task at `/speckit-tasks`.
- **Framework/project boundary**: PASS. All edits in framework-managed paths.
- **Adapter discipline**: PASS. Additive coordination surface; no parallel authority; registers + sole-customer-interface preserved.
