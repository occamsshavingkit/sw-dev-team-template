---
name: phase-template
description: ISO/IEC/IEEE 12207:2017 life-cycle phase template with entry/exit criteria, V-model pairing, and gate review.
template_class: phase
---


# Phase / Iteration — <identifier>

<!-- TOC -->

- [Identification](#identification)
- [Entry criteria](#entry-criteria)
- [Objectives](#objectives)
- [Deliverables](#deliverables)
- [V-model pairing (if applicable)](#v-model-pairing-if-applicable)
- [Activities](#activities)
- [Exit criteria](#exit-criteria)
- [Gate review](#gate-review)
- [Retrospective](#retrospective)

<!-- /TOC -->

Shaped after ISO/IEC/IEEE 12207:2017 life-cycle process structure. One
phase (or iteration, if the project is iterative) per file. Terms are
binding per `docs/glossary/ENGINEERING.md` (and `docs/glossary/PROJECT.md`
for project-specific terms) — note that *phase* and *iteration* are
distinct.

Owned by `tech-lead` with `architect` concurrence on technical gates.

---

## Identification

- **Phase / iteration ID:** <e.g., P-01 Requirements; or Sprint-07>
- **Type:** Phase | Iteration | Spike
- **Owner:** tech-lead
- **Planned dates:** start YYYY-MM-DD → end YYYY-MM-DD
- **Actual dates:** (filled on close)

---

## Entry criteria

Conditions that must be true before work begins. Gate-reviewed by
`tech-lead`; blocking. Example categories:

- Preceding phase closed and deliverables accepted.
- Required customer sign-offs recorded in `CUSTOMER_NOTES.md`.
- Required inputs available (requirements, designs, environments).
- Team capacity confirmed.

List each as a checkbox with the evidence source.

- [ ] <condition> — evidence: <path / entry / commit>

---

## Objectives

One paragraph. What this phase/iteration must accomplish, stated as
outcomes not activities.

Linked work items (stories, tasks, WBS leaves):
- <ID> — <title>
- <ID> — <title>

---

## Deliverables

The artifacts this phase produces. Each deliverable has an owner, a
destination, and a verification activity.

| Deliverable | Owner (agent) | Destination | Verified by |
|---|---|---|---|
| Requirements doc v1 | `researcher` + `architect` | `docs/requirements.md` | customer review via `tech-lead` |
| Arch doc + ADRs | `architect` | `docs/architecture.md`, `docs/adr/` | `code-reviewer` audit |
| Implementation slice | `software-engineer` | <repo path> | `qa-engineer` tests + `code-reviewer` |
| Test plan + results | `qa-engineer` | `docs/tests/` | `code-reviewer` |
| Release artifact | `release-engineer` | registry / tag | `sre` smoke-test |

---

## V&V activity table (IEEE 1012-2016 Part B paraphrase)

State the verification and validation activities paired to this phase.
Per IEEE 1012-2016 § 9, both verification (conformance to specification) and
validation (fitness for intended use) activities are assigned at each phase;
the required depth scales with the software integrity level assigned to the
component (IL-1 minimal through IL-4 full — record the integrity level in the
project charter or architecture document).

Fill in the rows applicable to this phase; delete inapplicable rows.

| Activity | Type | Description | Owner | Entry condition | Exit criterion |
|---|---|---|---|---|---|
| Requirements inspection | Verification | Check requirements for correctness, unambiguity, completeness, and testability; trace to stakeholder needs | `qa-engineer` + `architect` | Requirements draft available | All items dispositioned; traceability matrix updated |
| Requirements validation | Validation | Confirm requirements reflect actual intended use; involve customer via `tech-lead` | `qa-engineer` | Customer available | Customer sign-off recorded in `CUSTOMER_NOTES.md` |
| Design inspection | Verification | Check design for conformance to requirements; trace design elements to requirements | `code-reviewer` | Design draft available | No open Major findings; ADR updated |
| Design validation | Validation | Evaluate design against operational constraints; prototype or model critical paths | `qa-engineer` | Design stable | Prototype results reviewed; risks logged |
| Code inspection | Verification | Review implementation for conformance to design and coding standards | `code-reviewer` | Implementation complete for the unit | No open hard-block findings |
| Unit test | Verification | Exercise individual units against their specification | `software-engineer` | Code inspection passed | Coverage targets met; no failing tests |
| Integration test | Verification | Verify that combined components interact correctly across interfaces | `qa-engineer` | Units integrated in the test environment | All interface contracts satisfied |
| System test | Verification + Validation | Verify system behaviour against requirements; validate against real or representative operational conditions | `qa-engineer` | Integration test passed | All requirements covered; no open Severity-1 defects |
| Acceptance test | Validation | Confirm the system meets stakeholder needs in the target environment | `qa-engineer` + customer (via `tech-lead`) | System test passed | Customer sign-off recorded in `CUSTOMER_NOTES.md` |
| Installation verification | Verification | Confirm installed system matches tested configuration | `release-engineer` | System deployed | Configuration matches release artefact |
| Installation validation | Validation | Validate installed system in target operational environment | `sre` + `qa-engineer` | Installation verification passed | Smoke tests pass; operations team accepts |

**Integrity-level tailoring note:** for IL-1 components, a subset of the
above (e.g., code inspection + unit test + integration test) is sufficient.
For IL-3 or IL-4, the full table applies and independent V&V should be
considered — record the rationale in the project charter and route through
`tech-lead` for customer sign-off.

Omit this section if not using a V-model or V&V life cycle.

---

## Activities

Bulleted breakdown per agent. Not a task list (those live in
`docs/tasks/`); a summary of which agent is doing what kind of work.

- `architect`: <summary>
- `software-engineer`: <summary>
- `qa-engineer`: <summary>
- `sre`: <summary>
- `tech-writer`: <summary>
- `release-engineer`: <summary>
- `researcher`: <summary>
- `sme-<domain>` (if any): <summary>

---

## Exit criteria

Conditions that must be true before the phase closes. Gate-reviewed by
`tech-lead`; blocking.

- [ ] All deliverables produced and accepted by their verifiers.
- [ ] All in-scope requirements traced end-to-end in the requirements doc.
- [ ] `code-reviewer` has issued approval or a superseded-ADR list.
- [ ] Customer sign-off recorded in `CUSTOMER_NOTES.md` on required items.
- [ ] Known-defect list and risk register updated.
- [ ] Phase retrospective captured below.

---

## Gate review

- **Date of review:** YYYY-MM-DD
- **Participants:** tech-lead, architect, customer (or customer-proxy
  per `CUSTOMER_NOTES.md`)
- **Decision:** Accept | Conditional accept | Reject
- **Conditions (if conditional):** list
- **Evidence of customer decision:** `CUSTOMER_NOTES.md` entry date

---

## Retrospective

Append-only. Not a blame log.

- **What went well:** …
- **What didn't:** …
- **Changes for next phase:** …
- **Glossary / taxonomy updates proposed:** (route to `researcher`)
