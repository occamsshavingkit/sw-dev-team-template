# Requirements — <project name>

Shaped after ISO/IEC/IEEE 29148:2018 (current edition); see
**§ "Information items (ISO/IEC/IEEE 29148)"** below for the binding
information-item shapes drawn from 29148:2011 (`LIB-0010` in
`docs/library/INVENTORY.md`) — content unchanged in 2018, so the
2011 paraphrase remains current. Terms are binding per
`docs/glossary/ENGINEERING.md` and `docs/glossary/PROJECT.md`. Each
requirement is uniquely identified, testable, traceable, and owns at
least one acceptance criterion.

Stewarded by `tech-lead` (intake) and `researcher` (numbering,
traceability). Technical decisions that flow *from* these requirements
live in architecture docs and ADRs, not here.

---

## Information items (ISO/IEC/IEEE 29148)

29148 defines **three information-item shapes** at successive
abstraction levels. A project picks one or more depending on its
contractual / domain context; pick the shallowest that satisfies
stakeholder needs.

### Stakeholder Requirements Specification — StRS (29148 § 9.3)

Captures user / customer / acquirer needs in their own language,
**before** translation to system terms. Required content (per § 9.3):
business purpose, business scope, business overview, stakeholders,
stakeholder needs, stakeholder requirements, operational concept (use
cases), system overview, life-cycle concepts, project constraints.

In this project the StRS material is largely captured in
`CUSTOMER_NOTES.md` + the project charter (`docs/pm/CHARTER.md`); a
formal StRS is written only when contractually required.

### System Requirements Specification — SyRS (29148 § 9.4)

Translates stakeholder needs into system requirements (the system as
a whole — software + hardware + people). Required content: system
purpose, system scope, system overview, system context, functional
requirements, usability requirements, performance requirements, system
interface, system operations, system modes/states, physical
characteristics, environmental conditions, system security,
information management, policies and regulations, computer resource
requirements, system quality characteristics, design constraints.

The SyRS is the bridge between StRS and SRS in cyber-physical /
multi-component projects (e.g., a process-control system spanning a
PLC, a SCADA host, and operator workstations).

### Software Requirements Specification — SRS (29148 § 9.5)

Software-component-specific requirements. Required content: software
purpose, software scope, software overview, software context, software
functional requirements, software usability requirements, software
performance requirements, software interface, software operations,
software modes/states, software physical characteristics, software
environmental conditions, software security, software information
management, software policies and regulations, software computer
resource requirements, software quality characteristics, software
design constraints.

This template (the file you are reading) instantiates the SRS shape.
For a multi-component system, write one SRS per software component
plus one SyRS for the integrated system.

### Requirements characteristics (29148 § 5.2)

Every requirement, regardless of which information item it lives in,
must satisfy:

- **Necessary** — removing it changes the system's value.
- **Implementation-free** — states *what*, not *how*.
- **Unambiguous** — one and only one interpretation.
- **Consistent** — does not contradict another requirement.
- **Complete** — measurable conditions, no "TBD".
- **Singular** — one requirement, one statement.
- **Feasible** — physically and technically achievable within
  constraints.
- **Traceable** — links to source (stakeholder need, regulation,
  prior requirement) and to verification.
- **Verifiable** — has at least one objective method of confirmation.

A requirement that fails any of these is a defect of the requirement
itself — fix or remove it.

### Requirements engineering activities (29148 § 6)

The standard separates **definition processes** (§ 6.2 stakeholder
requirements definition; § 6.3 requirements analysis) from
**management** (§ 6.5 — change control, traceability maintenance,
metrics). In this project:

- Definition: `tech-lead` runs intake; `researcher` writes the
  artifact and stewards numbering.
- Analysis: `architect` participates for feasibility / constraint
  pushback before requirements freeze.
- Management: `project-manager` owns change-control workflow per
  `docs/pm/CHANGES.md`; `researcher` owns the traceability matrix
  (§ 7 below in this template).

### Tailoring (29148 § 2.5)

29148 explicitly permits tailored conformance — keep the information-
item shape but omit or merge sections that don't apply, recording the
tailoring decision. A short StRS with five sections of "n/a — see
CHARTER.md" is more useful than a thick "complete" document. Tailor
visibly; never silently drop required sections.

---

## 1. Introduction

**Purpose.** One paragraph: what this document specifies.

**Scope.** What is in, what is out. Cite the project charter in
`CUSTOMER_NOTES.md`.

**Definitions.** Project-specific terms. If a term is generic and
appears in `docs/glossary/ENGINEERING.md`, don't redefine it here; if
it's project-specific, add it to `docs/glossary/PROJECT.md` and cite
from here.

**References.** External documents this requires or implies. For any
copyrighted external material, cite per `docs/glossary/ENGINEERING.md`
§ IP.

---

## 2. Stakeholders and their concerns

| Stakeholder | Role | Primary concerns |
|---|---|---|
| <customer name> | Customer | <top 3 concerns> |
| <user persona> | End user | <top 3 concerns> |
| <other> | <role> | <concerns> |

---

## 3. System context

One paragraph narrative. Include a context diagram (C4 level 1) if
`architect` has produced one — link, don't duplicate.

**Assumptions.** List, each tagged with impact if wrong.
**Constraints.** Non-negotiable externally-imposed limits.
**Dependencies.** Required from outside this project.

---

## 4. Functional requirements

ID format: `FR-NNNN`. Never reused, even after deletion (mark as
`SUPERSEDED BY FR-MMMM` or `WITHDRAWN`).

### FR-0001 — <one-line title>

**Statement.** The system shall <verb-phrase> <object> <condition>.

**Rationale.** Why this requirement exists. Cite `CUSTOMER_NOTES.md`
entry or standard if applicable.

**Acceptance criteria.**
- AC-0001.1: <observable, checkable condition>
- AC-0001.2: <…>

**Priority.** Must | Should | Could | Won't (MoSCoW).

**Source.** `CUSTOMER_NOTES.md` YYYY-MM-DD entry / standard §X.Y /
regulatory reference.

**Traces to.** <design artifact / component / test cases, to be filled
by `architect` + `qa-engineer`>.

---

## 5. Non-functional requirements (quality attributes)

Organize by ISO/IEC 25010 quality characteristic. Use the same
ID-and-AC format as FRs, but prefix `NFR-NNNN`.

Mandatory categories to consider (omit with explicit rationale):
- Functional suitability
- Performance efficiency (response time, throughput, resource use)
- Compatibility
- Interaction capability (usability, accessibility)
- Reliability (availability, fault tolerance, recoverability)
- Security (confidentiality, integrity, authenticity, accountability)
- Maintainability
- Flexibility (portability, adaptability, scalability)
- Safety (where applicable)

### NFR-0001 — <characteristic>: <one-line title>

**Statement.** Under <conditions>, the system shall <measurable
threshold with units>.

**Measurement method.** How `sre` or `qa-engineer` will verify.

**Acceptance criteria.** <observable, checkable>.

**Priority.** Must | Should | Could | Won't.

**Source.** <reference>.

---

## 6. Constraints

Separate from requirements: these are non-negotiable. ID format: `C-NNNN`.

| ID | Constraint | Source |
|---|---|---|
| C-0001 | <description> | <regulatory / business / technical reference> |

---

## 7. Traceability matrix

Maintained by `researcher`. A row per requirement.

| Req ID | Source | Design | Implementation | Test | Status |
|---|---|---|---|---|---|
| FR-0001 | CUSTOMER_NOTES 2026-MM-DD | ADR-0003, §X of arch | module/path.ext | T-0001 | verified |

Empty cells flag gaps. No row is "complete" until all cells are filled.

---

## 8. Change log

Append-only. Each change: date, requirement ID(s), change type (added /
withdrawn / superseded / reworded-without-scope-change), author, source
(`CUSTOMER_NOTES.md` entry or equivalent).
