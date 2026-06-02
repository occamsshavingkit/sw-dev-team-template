---
name: architecture-template
description: Guided ISO/IEC/IEEE 42010:2022 plus arc42 plus C4 architecture template with views, scenarios, and ADR index. Includes first-class IEEE 1016-2009 viewpoint sections and a 42010 rationale chain.
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

Shaped after ISO/IEC/IEEE 42010:2022 (Architecture description) and the
arc42 template, with diagrams in the C4 model (Context / Container /
Component / Code). Terms are binding per `docs/glossary/ENGINEERING.md`
and `docs/glossary/PROJECT.md`.

Owned by `architect`. Architecturally significant decisions live in
ADRs at `docs/adr/NNNN-<slug>.md` — this document *summarizes* them and
shows how they compose.

<!-- IEEE 1016-2009 §5 defines 11 viewpoints; each section that
     instantiates one is annotated with its §5.x clause in an HTML comment.
     ISO/IEC/IEEE 42010:2022 §6 governs the rationale chain in §1.1–§1.3.
     All content is paraphrased per project IP policy; no verbatim
     standard text appears in this file. -->

**SDD viewpoints (IEEE 1016-2009 / `LIB-0009`).** This template
satisfies IEEE 1016's SDD shape via the section-to-viewpoint mapping
below (see `architect.md` § "Software design descriptions" for the full
catalog and rationale). Viewpoints not instantiated in a given SDD must
be listed with rationale in § 1.2.

## SDD viewpoint mapping

<!-- IEEE 1016-2009 §4.5 — viewpoint selection is concern-driven;
     §5.2–§5.13 — the 11 standard viewpoints and their content. -->

| 1016 § viewpoint | Section in this template |
|---|---|
| § 5.2 Context | § 3 Context (C4 level 1) |
| § 5.3 Composition | § 5 Container view (C4 level 2) |
| § 5.4 Logical | § 6 Component view (C4 level 3) |
| § 5.5 Dependency | § 6 dependency diagram + § 13 Cross-cutting |
| § 5.6 Information | § 11 Information view |
| § 5.7 Patterns use | § 4 Solution strategy |
| § 5.8 Interface | § 5 / § 6 (interface subsections) |
| § 5.9 Structure | § 6 Component view |
| § 5.10 Interaction (concurrency overlay) | § 10 Concurrency view |
| § 5.11 State dynamics | § 9 State dynamics view |
| § 5.12 Algorithm | embedded in ADRs (`docs/adr/`) |
| § 5.13 Resource | § 12 Resource view |

---

## 1. Introduction and goals

One paragraph: what is being built, for whom, why. Link the project
charter in `CUSTOMER_NOTES.md`.

**Top-3 quality attributes** (drives trade-offs). Name them and rank.

### 1.1 Stakeholder concerns

<!-- ISO/IEC/IEEE 42010:2022 §6.2 — an architecture description identifies
     stakeholders and their concerns before viewpoints are selected.
     Paraphrased. -->

List the stakeholders whose concerns this architecture description
addresses and the specific question each needs answered. Every viewpoint
selected in § 1.2 must trace to at least one row here.

| Stakeholder | Role / interest | Concern (what they need the architecture to answer) |
|---|---|---|
| <e.g., SRE> | Operations | <e.g., How does the system recover from an infrastructure failure?> |
| <e.g., Security engineer> | Security | <e.g., Where does sensitive data transit and rest, and what controls protect it?> |
| <e.g., Platform team> | Capacity planning | <e.g., What resources does the system require at 2× current load?> |
| <e.g., Product owner> | Feature delivery | <e.g., What are the key domain-state transitions and are they consistent?> |

Cross-reference the requirements doc; do not duplicate requirements here.

### 1.2 Selected viewpoints

<!-- IEEE 1016-2009 §4.5 — a conformant SDD selects viewpoints based on
     stakeholder concerns and states rationale for any omitted viewpoint.
     Paraphrased. -->

State which viewpoints are instantiated in this SDD and which are
omitted. Omit a viewpoint when no stakeholder has the corresponding
concern, or when another viewpoint already answers it. Never silently
drop a viewpoint — record the rationale.

**Viewpoints instantiated:**

| Viewpoint | Section | Addresses concern(s) of |
|---|---|---|
| Context (§ 5.2) | § 3 | <stakeholder(s)> |
| Composition (§ 5.3) | § 5 | <stakeholder(s)> |
| Logical (§ 5.4) | § 6 | <stakeholder(s)> |
| Dependency (§ 5.5) | § 6 / § 13 | <stakeholder(s)> |
| Information (§ 5.6) | § 11 | <stakeholder(s)> |
| Patterns use (§ 5.7) | § 4 | <stakeholder(s)> |
| Interface (§ 5.8) | § 5 / § 6 | <stakeholder(s)> |
| Structure (§ 5.9) | § 6 | <stakeholder(s)> |
| Interaction / Concurrency (§ 5.10) | § 10 | <stakeholder(s)> |
| State dynamics (§ 5.11) | § 9 | <stakeholder(s)> |
| Resource (§ 5.13) | § 12 | <stakeholder(s)> |

**Viewpoints omitted:**

| Viewpoint | Rationale |
|---|---|
| Algorithm (§ 5.12) | No bespoke algorithms with complexity or correctness risk; standard library and off-shelf components only. Revisit if a custom algorithm is introduced. |
| <other viewpoint> | <rationale> |

Remove placeholder rows for viewpoints that are in fact instantiated.

### 1.3 Design views and rationale chain

<!-- ISO/IEC/IEEE 42010:2022 §6.4 and §6.5 — architecture decisions and
     their rationale must be recorded and traceable to stakeholder concerns.
     Paraphrased. -->

This table is the traceability spine of the SDD. Each row connects a
stakeholder concern (from § 1.1) through the viewpoint(s) that address it
to the ADR(s) that record the binding decision and its three-path
alternatives.

A concern with no governing ADR is an open design gap — mark it
`decision pending` and resolve before implementation starts.

<!-- Author-guidance: minimum one row per top-3 quality attribute named
     above. Cross-link: each ADR# must match a row in § 14; each
     Viewpoint must match a row in the SDD mapping table and in § 1.2. -->

| Stakeholder concern | Viewpoint(s) | ADR(s) | Quality attribute | Status |
|---|---|---|---|---|
| <e.g., Recovery from DB failover> | § 9 State dynamics; § 7 Runtime view | ADR-0005, ADR-0012 | Availability | accepted |
| <e.g., PII transit and rest controls> | § 11 Information; § 13 Cross-cutting (auth) | ADR-0008 | Security | accepted |
| <e.g., Resource commitment at 2× load> | § 12 Resource; § 8 Deployment | ADR-0003 | Scalability | accepted |
| <e.g., Order-state consistency> | § 9 State dynamics; § 10 Concurrency | ADR-0011 | Consistency | decision pending |

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

<!-- IEEE 1016-2009 §5.2 Context viewpoint — system boundary, external actors,
     and data exchanges. -->

**Diagram.** System-context diagram: the system as a single box, with
users, external systems, and data exchanges around it.

**Narrative.** One paragraph per external actor or system, with
protocol / data flow summary.

---

## 4. Solution strategy

<!-- IEEE 1016-2009 §5.7 Patterns use viewpoint — design patterns adopted
     and the rationale behind each choice. -->

Short: the handful of high-level decisions that most shape everything
else. Examples: "monolith-first", "event-sourced core", "server-side
rendered UI", "relational primary + document archive".

Each item links to its governing ADR.

---

## 5. Container view (C4 level 2)

<!-- IEEE 1016-2009 §5.3 Composition viewpoint (deployable units) and
     §5.8 Interface viewpoint (inter-container contracts). -->

**Diagram.** Containers: deployable/runnable units (services, apps,
databases, queues). One diagram per top-level system.

**Per-container table.**

| Container | Responsibility | Technology | Persistence | Dependencies |
|---|---|---|---|---|
| <name> | <what it does> | <lang / framework> | <store> | <other containers> |

---

## 6. Component view (C4 level 3)

<!-- IEEE 1016-2009 §5.4 Logical, §5.5 Dependency, §5.8 Interface, and
     §5.9 Structure viewpoints — internal decomposition of each container. -->

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

<!-- IEEE 1016-2009 §5.10 Interaction viewpoint — runtime collaboration
     sequences and timing. For concurrency-specific concerns, see §10. -->

The important scenarios, shown as sequence or activity diagrams with a
one-paragraph narrative each. Cover at least:
- happy path of the primary use case,
- one error-handling scenario,
- one recovery / restart scenario.

---

## 8. Deployment view

<!-- IEEE 1016-2009 §5.13 Resource viewpoint — infrastructure topology.
     Scope note: this section covers where containers run and
     network / environment configuration. Runtime resource budgets
     (CPU, memory, scaling policy, connection limits) belong in §12. -->

> **Scope:** infrastructure topology — where containers run, network
> boundaries, environment configuration. For runtime resource budgets
> (CPU, memory, scaling policy), see § 12 Resource view.

Where the containers run. Environments (dev / staging / prod),
infrastructure choices, network topology, security boundaries. If
infrastructure is code, link the module paths.

---

## 9. State dynamics view

<!-- IEEE 1016-2009 §5.11 State dynamics viewpoint — lifecycle and state
     transitions of architecturally significant components.
     Promoted from §7 sub-item to first-class section per issue #243 (ARCH-1). -->

<!-- Author-guidance: What goes here — one state-transition diagram or
     table per component whose lifecycle is observable at the architecture
     boundary. Use a UML state diagram, Mermaid stateDiagram-v2, or a
     prose transition table. Model only components whose state affects
     system-level behavior; do not model every internal object.

     Example (prose table style):

     **Component: OrderProcessor**

     | From state | Event / condition | To state | Side-effect |
     |---|---|---|---|
     | Idle | Payment confirmed | Processing | Emits ORDER_ACCEPTED |
     | Processing | Inventory unavailable | Degraded | Emits INVENTORY_HOLD; alerts ops |
     | Degraded | Manual retry | Processing | — |
     | Processing | Order fulfilled | Idle | Emits ORDER_COMPLETE |
     | Any | Shutdown signal | Stopped | Drains in-flight; no new accepts |

     Link to the ADR governing retry policy and the degraded-state timeout.
     Flag any state that can only be exited by restart or human
     intervention — these are high operational risk and must be explicit. -->

This view captures how architecturally significant components move through
distinct operational phases over time. It answers: given an external event
or internal condition, what state transitions are valid and what happens at
each boundary?

**Design elements to capture:**
- Named states for each component whose lifecycle affects system-level
  behavior (not every object — only those observable at the architecture
  boundary).
- Allowed transitions, guard conditions, and the actors or events that
  trigger each.
- Error states and the paths back to nominal operation.
- Any state that can only be exited by restart or human intervention
  (a "sticky" state) — call these out explicitly; they are high risk.
- Cross-component state dependencies: component A can only enter state X
  while component B is in state Y.

---

## 10. Concurrency view

<!-- IEEE 1016-2009 §5.10 Interaction viewpoint — concurrency overlay.
     "Concurrency" names the concern; this section instantiates the
     Interaction viewpoint with concurrent execution as the primary design
     focus. Promoted to first-class section per issue #243 (ARCH-1). -->

<!-- Author-guidance: What goes here — a concurrency map showing concurrent
     actors and the shared resources between them, or a table of
     shared-state elements with their access strategies. Add sequence
     diagrams only where an ordering constraint is non-obvious.

     Example (table style):

     **Concurrency model: single event loop per service; inter-service via
     message queue (at-least-once delivery).**

     | Shared resource | Concurrent accessors | Strategy | Failure mode |
     |---|---|---|---|
     | Order DB (write path) | API service × N replicas | Optimistic locking (version column) | Retry on conflict; 3 retries, then 409 |
     | Inventory cache | API + background reloader | Cache-aside; stale reads tolerated ≤ 30 s | Stale read may allow oversell; compensated by post-hoc check |
     | Payment saga state | Orchestrator only (single writer) | No lock needed | Orchestrator crash → resume from last committed step on restart |

     Link to the ADR governing the message-queue delivery guarantee and
     the saga implementation choice. -->

This view describes how the system handles work that runs simultaneously —
across threads, processes, services, or nodes — and where the risks of
concurrent execution (race conditions, deadlocks, ordering violations,
resource contention) live in the design. It answers: where does shared
state exist, what synchronization strategy governs access to it, and what
is the worst-case outcome when that strategy fails?

**Design elements to capture:**
- Concurrency model: thread-per-request, actor model, event loop, worker
  pool, reactive streams — state the governing model and where it applies.
- Shared mutable state: which components or stores are accessed concurrently
  and what protects them (lock, CAS, MVCC, partition-by-key, immutability).
- Ordering constraints: sequences that must be globally or causally ordered
  and the mechanism enforcing that order.
- Known contention points and their throughput / latency limits.
- Failure modes specific to concurrent execution: what happens when a lock
  holder crashes, when a saga step fails mid-way, or when a worker pool is
  saturated.

---

## 11. Information view

<!-- IEEE 1016-2009 §5.6 Information viewpoint — data structures, schemas,
     persistence, ownership, and data lifecycle.
     Promoted from §9 Cross-cutting data-model bullet to first-class section
     per issue #243 (ARCH-1). -->

<!-- Author-guidance: What goes here — an entity-relationship diagram or
     entity summary table, followed by a persistence strategy table.
     This is not a schema listing — link to schema files; do not reproduce
     them here. Call out PII fields explicitly and link to the data-retention
     ADR and any GDPR / compliance note in §13.

     Example:

     **Core entities:** Customer, Order, OrderLine, Product, Payment,
     ShipmentEvent.

     | Entity | Persistence | Owner (single writer) | Format | Retention |
     |---|---|---|---|---|
     | Customer | PostgreSQL | customer-service | normalized relational | 7 years post-closure |
     | Order | PostgreSQL | order-service | normalized relational | 7 years |
     | ShipmentEvent | Event log (Kafka) | shipping-service | Avro v2 | 90 days hot, 2 years cold |
     | Session token | Redis | auth-service | JWT, HS256 | 24 h TTL |

     Link to the ADR governing serialization format and migration strategy. -->

This view describes the data the system creates, transforms, persists, and
exchanges — its structure, ownership, and how it moves between components
or survives component restarts. It describes what the system knows about,
where that knowledge is stored, and how it flows.

**Design elements to capture:**
- Core domain entities and their relationships (ER diagram or entity summary
  table — not a full schema dump; link to schema files).
- Persistence strategy per entity: relational, document, key-value, event
  log, in-memory-only, or external-system-of-record.
- Ownership and mutation rights: which component is the single writer for
  each entity, and how read-only consumers receive updates.
- Data-at-rest and data-in-transit formats: serialization format, encoding,
  and evolution strategy.
- Data lifecycle: creation, retention period, archival, and deletion.
  PII implications must be called out explicitly.
- Migration and schema evolution strategy: how breaking changes are
  deployed without downtime.

---

## 12. Resource view

<!-- IEEE 1016-2009 §5.13 Resource viewpoint — runtime resource allocation,
     capacity, and limits. Promoted from §8 Deployment view to first-class
     section per issue #243 (ARCH-1). §8 retains infrastructure topology;
     §12 captures resource budgets and scaling constraints. -->

<!-- Author-guidance: What goes here — a resource budget table (nominal and
     peak per service), a scaling model description, and bottleneck callouts.
     Do not duplicate the deployment topology from §8 — link there for
     "where it runs." This section answers "what it needs to run."

     Example:

     | Service | CPU (nom/peak) | Memory (nom/peak) | Storage | Scaling model | First bottleneck |
     |---|---|---|---|---|---|
     | API service | 0.25 / 2 vCPU | 256 MB / 1 GB | stateless | Horizontal (0–20 replicas) | DB connection pool (max 100) |
     | Order DB | 2 / 4 vCPU | 8 GB / 16 GB | 500 GB + 10 GB/month | Vertical; read replicas for reads | Write IOPS at ~50k orders/day |
     | Kafka | 2 / 4 vCPU | 4 GB / 8 GB | 200 GB (90-day retention) | Horizontal (partition scale) | Partition rebalance latency |

     DR standby: active-passive; standby consumes ~50% of prod budget (pre-warmed).
     Link to `docs/dr-plan.md` and to the ADR governing scaling choices. -->

This view describes the runtime resources the system requires — compute,
memory, network, storage, concurrency budget — and the allocation strategy
that keeps the system within its operational envelope. It answers: what
does this system cost to run, what limits bound its capacity, and where
will it break first under load?

**Design elements to capture:**
- Resource budget per container or service: CPU, memory, disk, network
  bandwidth — nominal and peak.
- Concurrency budget: maximum parallel requests, thread-pool sizes,
  connection-pool limits, queue depths.
- Scaling model: which components scale horizontally vs. vertically, and
  the constraint that governs each choice.
- Resource limits and circuit-breaker behavior: what happens when a budget
  is exceeded (throttling, load shedding, graceful degradation).
- External resource dependencies with SLA or quota constraints: third-party
  APIs, managed services, hardware.
- DR / failover resource footprint: the additional capacity the standby
  environment requires.

---

## 13. Cross-cutting concepts

Short sections on concerns that span the architecture:
- Domain model / ubiquitous language (defer to
  `docs/glossary/ENGINEERING.md` + `docs/glossary/PROJECT.md`).
- Error handling and resilience strategy.
- Observability (logs, metrics, traces).
- Configuration and secrets management.
- Authentication, authorization, audit.
- Data management (backup schedule, restore procedure, retention
  enforcement) — entity-level structure, ownership, and lifecycle
  detail live in § 11 Information view.
- Internationalization and accessibility (if applicable).
- Safety and compliance (if applicable).

Each subsection: one paragraph + link to detailed ADR or external doc.

---

## 14. Architecture decisions (index)

A chronological list of ADRs under `docs/adr/`. One row per ADR.
Shape per `docs/templates/adr-template.md` (MADR-based with the
binding Three-Path Rule — Minimalist / Scalable / Creative —
under § "Considered options").

| # | Title | Status | Date |
|---|---|---|---|
| ADR-0001 | <short title> | accepted | YYYY-MM-DD |

Do not paraphrase ADR content here; just index them. Cross-link: each
ADR listed here should appear in at least one row of the § 1.3 rationale
chain.

Filename convention: `docs/adr/NNNN-<kebab-case-slug>.md`. New ADRs
are required whenever any row of `.claude/agents/architect.md`
§ "ADR trigger list" fires.

---

## 15. Quality requirements (trade-off scenarios)

For each top-3 quality attribute, one concrete scenario with:
- **Source** (stimulus origin), **Stimulus**, **Environment**,
  **Artifact**, **Response**, **Response measure**. (SEI
  Quality-Attribute Scenario form.)
- **Trade-off note** — what this scenario costs elsewhere.

---

## 16. Risks and technical debt

| ID | Description | Likelihood | Impact | Mitigation / ADR |
|---|---|---|---|---|
| R-01 | <risk> | L/M/H | L/M/H | <reference> |

---

## 17. Glossary delta

Project-specific architecture terms not already in
`docs/glossary/ENGINEERING.md` or `docs/glossary/PROJECT.md`. If a term
is general, add it to `ENGINEERING.md`; if it's project-specific, add
it to `PROJECT.md` (via `researcher`).
