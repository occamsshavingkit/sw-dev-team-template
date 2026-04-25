# Architecture — <project name>

<!-- TOC -->

- [SDD viewpoint mapping](#sdd-viewpoint-mapping)
- [1. Introduction and goals](#1-introduction-and-goals)
- [2. Constraints](#2-constraints)
- [3. Context (C4 level 1)](#3-context-c4-level-1)
- [4. Solution strategy](#4-solution-strategy)
- [5. Container view (C4 level 2)](#5-container-view-c4-level-2)
- [6. Component view (C4 level 3)](#6-component-view-c4-level-3)
- [7. Runtime view](#7-runtime-view)
- [8. Deployment view](#8-deployment-view)
- [9. Cross-cutting concepts](#9-cross-cutting-concepts)
- [10. Architecture decisions (index)](#10-architecture-decisions-index)
- [11. Quality requirements (trade-off scenarios)](#11-quality-requirements-trade-off-scenarios)
- [12. Risks and technical debt](#12-risks-and-technical-debt)
- [13. Glossary delta](#13-glossary-delta)

<!-- /TOC -->

Bare variant per FW-ADR-0003. For fluent authors and agents. The
guided variant at `architecture-template.md` carries the prose; this
file carries the structure only. Synchronisation rule: heading sets
must match between this file and the guided variant. Smoke check
verifies.

Shape: ISO/IEC/IEEE 42010:2022 + arc42 + C4. SDD viewpoints per
IEEE 1016-2009 (`LIB-0009`).

Owned by `architect`.

---

## SDD viewpoint mapping

| 1016 § viewpoint | Section in this template |
|---|---|
| § 5.2 Context | § 3 |
| § 5.3 Composition | § 5 |
| § 5.4 Logical | § 6 |
| § 5.5 Dependency | § 6 / § 9 |
| § 5.6 Information | § 9 |
| § 5.7 Patterns use | § 4 |
| § 5.8 Interface | § 5 / § 6 |
| § 5.9 Structure | § 6 |
| § 5.10 Interaction | § 7 |
| § 5.11 State dynamics | § 7 |
| § 5.12 Algorithm | ADRs |
| § 5.13 Resource | § 8 |

---

## 1. Introduction and goals

- **Purpose:**
- **Quality goals (top 3):**
- **Stakeholders + concerns:**

## 2. Constraints

- **Technical:**
- **Organisational:**
- **Conventions:**

## 3. Context (C4 level 1)

| External actor / system | Interaction |
|---|---|

## 4. Solution strategy

- **Top-level decomposition rationale:**
- **Patterns adopted:**
- **Key technology choices:**

## 5. Container view (C4 level 2)

| Container | Responsibility | Tech |
|---|---|---|

## 6. Component view (C4 level 3)

Per significant container, list components and their dependencies.
For non-trivial views, link to per-view file under `docs/views/`.

## 7. Runtime view

Per significant scenario, sequence of interactions. Link to
`docs/views/runtime-<name>.md` for details.

## 8. Deployment view

| Environment | Components deployed | Resource notes |
|---|---|---|

## 9. Cross-cutting concepts

- **Data model:**
- **Error handling:**
- **Security:**
- **Logging / observability:**
- **i18n / a11y (if applicable):**

## 10. Architecture decisions (index)

| ADR | Title | Status |
|---|---|---|

## 11. Quality requirements (trade-off scenarios)

| Scenario | Quality attribute | Response measure |
|---|---|---|

## 12. Risks and technical debt

| Risk / debt | Impact | Mitigation / planned remediation |
|---|---|---|

## 13. Glossary delta

Project-specific terms not in `docs/glossary/PROJECT.md`.
