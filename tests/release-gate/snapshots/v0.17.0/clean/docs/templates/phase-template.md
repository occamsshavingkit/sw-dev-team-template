# Phase / Iteration — <identifier>

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
| Requirements doc v1 | `tech-lead`/`researcher` | `docs/requirements.md` | customer review |
| Arch doc + ADRs | `architect` | `docs/architecture.md`, `docs/adr/` | `code-reviewer` audit |
| Implementation slice | `software-engineer` | <repo path> | `qa-engineer` tests + `code-reviewer` |
| Test plan + results | `qa-engineer` | `docs/tests/` | `code-reviewer` |
| Release artifact | `release-engineer` | registry / tag | `sre` smoke-test |

---

## V-model pairing (if applicable)

For phases on the construction arm, state the verification phase that
will check this phase's deliverable.

| This phase produces | Verified against by |
|---|---|
| Requirements | Acceptance test phase |
| Architecture | System integration phase |
| Detailed design | Integration test phase |
| Implementation | Unit + integration test |

Omit this section if not using a V-model life cycle.

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
