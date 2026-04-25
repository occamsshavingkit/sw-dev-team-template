# Architecture — <project name>

<!-- TOC -->

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

Shaped after ISO/IEC/IEEE 42010:2022 (Architecture description) and the
arc42 template, with diagrams in the C4 model (Context / Container /
Component / Code). Terms are binding per `docs/glossary/ENGINEERING.md`
and `docs/glossary/PROJECT.md`.

Owned by `architect`. Architecturally significant decisions live in
ADRs at `docs/adr/NNNN-<slug>.md` — this document *summarizes* them and
shows how they compose.

---

## 1. Introduction and goals

One paragraph: what is being built, for whom, why. Link the project
charter in `CUSTOMER_NOTES.md`.

**Top-3 quality attributes** (drives trade-offs). Name them and rank.

**Top-3 stakeholders and concerns.** Cross-reference the requirements
doc; do not duplicate.

---

## 2. Constraints

Non-negotiable inputs that bound the solution space.

| Category | Constraint | Source |
|---|---|---|
| Technical | <e.g., must run on runtime X ≥ vY> | <reference> |
| Business | <e.g., ship by date Z> | `CUSTOMER_NOTES.md` date |
| Regulatory | <e.g., GDPR applicability> | <reference> |
| Organizational | <e.g., only these tools approved> | <reference> |

Distinct from requirements: constraints are inherited, not chosen.

---

## 3. Context (C4 level 1)

**Diagram.** System-context diagram: the system as a single box, with
users, external systems, and data exchanges around it.

**Narrative.** One paragraph per external actor or system, with
protocol / data flow summary.

---

## 4. Solution strategy

Short: the handful of high-level decisions that most shape everything
else. Examples: "monolith-first", "event-sourced core", "server-side
rendered UI", "relational primary + document archive".

Each item links to its governing ADR.

---

## 5. Container view (C4 level 2)

**Diagram.** Containers: deployable/runnable units (services, apps,
databases, queues). One diagram per top-level system.

**Per-container table.**

| Container | Responsibility | Technology | Persistence | Dependencies |
|---|---|---|---|---|
| <name> | <what it does> | <lang / framework> | <store> | <other containers> |

---

## 6. Component view (C4 level 3)

Per container, decompose into components. One diagram per
non-trivial container.

**Per-component:**
- **Responsibility** — one sentence.
- **Interfaces** — what it exposes, to whom, with what contract.
- **Key design decisions** — link the ADRs.
- **Traces to requirements** — `FR-NNNN`, `NFR-NNNN` IDs from the
  requirements doc.

---

## 7. Runtime view

The important scenarios, shown as sequence or activity diagrams with a
one-paragraph narrative each. Cover at least:
- happy path of the primary use case,
- one error-handling scenario,
- one recovery / restart scenario.

---

## 8. Deployment view

Where the containers run. Environments (dev / staging / prod),
infrastructure choices, network topology, security boundaries. If
infrastructure is code, link the module paths.

---

## 9. Cross-cutting concepts

Short sections on concerns that span the architecture:
- Domain model / ubiquitous language (defer to
  `docs/glossary/ENGINEERING.md` + `docs/glossary/PROJECT.md`).
- Error handling and resilience strategy.
- Observability (logs, metrics, traces).
- Configuration and secrets management.
- Authentication, authorization, audit.
- Data management (migration, retention, backup).
- Internationalization and accessibility (if applicable).
- Safety and compliance (if applicable).

Each subsection: one paragraph + link to detailed ADR or external doc.

---

## 10. Architecture decisions (index)

A chronological list of ADRs under `docs/adr/`. One row per ADR.
Shape per `docs/templates/adr-template.md` (MADR-based with the
binding Three-Path Rule — Minimalist / Scalable / Creative —
under § "Considered options").

| # | Title | Status | Date |
|---|---|---|---|
| FW-ADR-0001 | <short title> | accepted | YYYY-MM-DD |

Do not paraphrase ADR content here; just index them.

Filename convention: `docs/adr/NNNN-<kebab-case-slug>.md`. New ADRs
are required whenever any row of `.claude/agents/architect.md`
§ "ADR trigger list" fires.

---

## 11. Quality requirements (trade-off scenarios)

For each top-3 quality attribute, one concrete scenario with:
- **Source** (stimulus origin), **Stimulus**, **Environment**,
  **Artifact**, **Response**, **Response measure**. (SEI
  Quality-Attribute Scenario form.)
- **Trade-off note** — what this scenario costs elsewhere.

---

## 12. Risks and technical debt

| ID | Description | Likelihood | Impact | Mitigation / ADR |
|---|---|---|---|---|
| R-01 | <risk> | L/M/H | L/M/H | <reference> |

---

## 13. Glossary delta

Project-specific architecture terms not already in
`docs/glossary/ENGINEERING.md` or `docs/glossary/PROJECT.md`. If a term
is general, add it to `ENGINEERING.md`; if it's project-specific, add
it to `PROJECT.md` (via `researcher`).
