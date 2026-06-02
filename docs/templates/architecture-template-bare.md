---
name: architecture-template-bare
description: Bare ISO/IEC/IEEE 42010:2022 plus arc42 plus C4 architecture template; structure only.
template_class: architecture
---


# Architecture — <project name>

<!-- TOC -->

- [SDD viewpoint mapping](#sdd-viewpoint-mapping)
- [1. Introduction and goals](#1-introduction-and-goals)
  - [1.1 Stakeholder concerns](#11-stakeholder-concerns)
  - [1.2 Selected viewpoints](#12-selected-viewpoints)
  - [1.3 Design views and rationale chain](#13-design-views-and-rationale-chain)
- [2. Constraints](#2-constraints)
- [3. Context (C4 level 1)](#3-context-c4-level-1)
- [4. Solution strategy](#4-solution-strategy)
- [5. Container view (C4 level 2)](#5-container-view-c4-level-2)
- [6. Component view (C4 level 3)](#6-component-view-c4-level-3)
- [7. Runtime view](#7-runtime-view)
- [8. Deployment view](#8-deployment-view)
- [9. State dynamics view](#9-state-dynamics-view)
- [10. Concurrency view](#10-concurrency-view)
- [11. Information view](#11-information-view)
- [12. Resource view](#12-resource-view)
- [13. Cross-cutting concepts](#13-cross-cutting-concepts)
- [14. Architecture decisions (index)](#14-architecture-decisions-index)
- [15. Quality requirements (trade-off scenarios)](#15-quality-requirements-trade-off-scenarios)
- [16. Risks and technical debt](#16-risks-and-technical-debt)
- [17. Glossary delta](#17-glossary-delta)

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
| § 5.5 Dependency | § 6 / § 13 |
| § 5.6 Information | § 11 |
| § 5.7 Patterns use | § 4 |
| § 5.8 Interface | § 5 / § 6 |
| § 5.9 Structure | § 6 |
| § 5.10 Interaction (concurrency overlay) | § 10 |
| § 5.11 State dynamics | § 9 |
| § 5.12 Algorithm | ADRs |
| § 5.13 Resource | § 12 |

---

## 1. Introduction and goals

- **Purpose:**
- **Quality goals (top 3):**

### 1.1 Stakeholder concerns

| Stakeholder | Role / interest | Concern |
|---|---|---|

### 1.2 Selected viewpoints

**Viewpoints instantiated:**

| Viewpoint | Section | Addresses concern(s) of |
|---|---|---|

**Viewpoints omitted:**

| Viewpoint | Rationale |
|---|---|

### 1.3 Design views and rationale chain

| Stakeholder concern | Viewpoint(s) | ADR(s) | Quality attribute | Status |
|---|---|---|---|---|

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

> **Scope:** infrastructure topology. For resource budgets, see § 12.

| Environment | Components deployed | Resource notes |
|---|---|---|

## 9. State dynamics view

<!-- IEEE 1016-2009 §5.11 -->

Per significant component, state-transition table or diagram.

| Component | From state | Event / condition | To state | Side-effect |
|---|---|---|---|---|

## 10. Concurrency view

<!-- IEEE 1016-2009 §5.10 Interaction — concurrency overlay -->

- **Concurrency model:**

| Shared resource | Concurrent accessors | Strategy | Failure mode |
|---|---|---|---|

## 11. Information view

<!-- IEEE 1016-2009 §5.6 -->

| Entity | Persistence | Owner (single writer) | Format | Retention |
|---|---|---|---|---|

- **Migration / evolution strategy:**

## 12. Resource view

<!-- IEEE 1016-2009 §5.13 -->

| Service | CPU (nom/peak) | Memory (nom/peak) | Storage | Scaling model | First bottleneck |
|---|---|---|---|---|---|

- **DR standby footprint:**

## 13. Cross-cutting concepts

- **Domain model / ubiquitous language:**
- **Error handling:**
- **Observability:**
- **Configuration and secrets:**
- **Authentication / authorization / audit:**
- **Data management (backup, restore, retention):** entity detail in § 11.
- **i18n / a11y (if applicable):**
- **Safety / compliance (if applicable):**

## 14. Architecture decisions (index)

| ADR | Title | Status |
|---|---|---|

## 15. Quality requirements (trade-off scenarios)

| Scenario | Quality attribute | Response measure |
|---|---|---|

## 16. Risks and technical debt

| Risk / debt | Impact | Mitigation / planned remediation |
|---|---|---|

## 17. Glossary delta

Project-specific terms not in `docs/glossary/PROJECT.md`.
