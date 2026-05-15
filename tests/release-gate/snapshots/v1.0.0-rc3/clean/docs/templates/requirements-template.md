# Requirements — <project name>

<!-- TOC -->

- [1. Introduction](#1-introduction)
- [2. Stakeholders and their concerns](#2-stakeholders-and-their-concerns)
- [3. System context](#3-system-context)
- [4. Functional requirements](#4-functional-requirements)
  - [FR-0001 — <one-line title>](#fr-0001-one-line-title)
- [5. Non-functional requirements (quality attributes)](#5-non-functional-requirements-quality-attributes)
  - [NFR-0001 — <characteristic>: <one-line title>](#nfr-0001-characteristic-one-line-title)
- [6. Constraints](#6-constraints)
- [7. Traceability matrix](#7-traceability-matrix)
- [8. Change log](#8-change-log)

<!-- /TOC -->

Shaped after ISO/IEC/IEEE 29148:2018. Terms are binding per
`docs/glossary/ENGINEERING.md` and `docs/glossary/PROJECT.md`. Each
requirement is uniquely identified, testable, traceable, and owns at
least one acceptance criterion.

Stewarded by `tech-lead` (intake) and `researcher` (numbering,
traceability). Technical decisions that flow *from* these requirements
live in architecture docs and ADRs, not here.

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
| FR-0001 | CUSTOMER_NOTES 2026-MM-DD | FW-ADR-0003, §X of arch | module/path.ext | T-0001 | verified |

Empty cells flag gaps. No row is "complete" until all cells are filled.

---

## 8. Change log

Append-only. Each change: date, requirement ID(s), change type (added /
withdrawn / superseded / reworded-without-scope-change), author, source
(`CUSTOMER_NOTES.md` entry or equivalent).
