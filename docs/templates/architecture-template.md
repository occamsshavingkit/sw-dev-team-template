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

<!-- Author-guidance: Keep this table current whenever a viewpoint is
     added, removed, or re-homed to a different section. When a
     viewpoint is omitted in a specific SDD, record the rationale in
     § 1.2 — do not simply delete its row here. The Algorithm viewpoint
     (§ 5.12) routes to ADRs rather than a body section; update the
     ADR reference if a bespoke algorithm is introduced. -->

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

<!-- Author-guidance: Write the narrative paragraph before filling in
     the top-3 quality attributes — the narrative anchors the
     architecture's purpose and the attributes should flow from it.
     Rank the three attributes in priority order; that ranking governs
     trade-off decisions throughout the document. Cross-reference: the
     project charter lives in CUSTOMER_NOTES.md; each quality attribute
     named here must appear in at least one scenario in § 15. -->

One paragraph: what is being built, for whom, why. Link the project
charter in `CUSTOMER_NOTES.md`.

**Top-3 quality attributes** (drives trade-offs). Name them and rank.

### 1.1 Stakeholder concerns

<!-- ISO/IEC/IEEE 42010:2022 §6.2 — an architecture description identifies
     stakeholders and their concerns before viewpoints are selected.
     Paraphrased. -->

<!-- Author-guidance: Add one row per distinct stakeholder concern, not
     per person — a single person may hold multiple concerns and should
     appear in multiple rows if needed. The Concern column is the key
     column: phrase it as a statement of what that stakeholder needs
     the architecture to make clear (e.g., "The path the system takes
     to recover from a database failure"). Every viewpoint in § 1.2 must
     trace to at least one row here; concerns with no governing viewpoint
     are unaddressed gaps to resolve before architecture review. -->

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

<!-- Author-guidance: Fill the Instantiated table by confirming each
     viewpoint maps to a real section with content, not a placeholder.
     Remove placeholder rows for viewpoints that are genuinely present.
     The Omitted table must have a rationale for every standard viewpoint
     not instantiated — "not applicable" is acceptable only when no
     stakeholder concern maps to it. Cross-reference: each row in the
     Instantiated table should appear in the SDD viewpoint mapping
     table above, and each addresses-concern-of cell should trace to a
     row in § 1.1. -->

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

<!-- Author-guidance: List only constraints the architecture must
     accept as fixed — inputs the team did not choose and cannot
     negotiate. Platform mandates, regulatory absolutes, and
     hard delivery dates belong here. Design preferences and defaults
     belong in § 4 Solution strategy as ADR-governed decisions.
     Cross-reference: every constraint here should also appear in the
     requirements doc §7 Constraints with matching wording. -->

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

<!-- Author-guidance: The diagram shows the system as a single opaque
     box — internal structure belongs in §§ 5–6, not here. Each
     external actor or system in the diagram gets one narrative
     paragraph covering the protocol used, the data exchanged, and
     the direction of flow. Cross-reference: the requirements doc §3
     System context links to this diagram; keep the external-actor list
     consistent between the two documents. -->

**Diagram.** System-context diagram: the system as a single box, with
users, external systems, and data exchanges around it.

**Narrative.** One paragraph per external actor or system, with
protocol / data flow summary.

---

## 4. Solution strategy

<!-- IEEE 1016-2009 §5.7 Patterns use viewpoint — design patterns adopted
     and the rationale behind each choice. -->

<!-- Author-guidance: Name only the three to five decisions that most
     constrain everything else — the ones a new team member must know
     before reading any other section. Each item is one sentence naming
     the pattern or approach, followed by a link to its ADR. Avoid
     restating detailed rationale here; the ADR carries it.
     Cross-reference: each ADR linked here must appear in § 14 and in
     at least one row of the § 1.3 rationale chain. -->

Short: the handful of high-level decisions that most shape everything
else. Examples: "monolith-first", "event-sourced core", "server-side
rendered UI", "relational primary + document archive".

Each item links to its governing ADR.

---

## 5. Container view (C4 level 2)

<!-- IEEE 1016-2009 §5.3 Composition viewpoint (deployable units) and
     §5.8 Interface viewpoint (inter-container contracts). -->

<!-- Author-guidance: A "container" in C4 terms is any separately
     deployable or runnable unit — a service, a web app, a database, a
     message queue, a scheduled job. One row per container in the table.
     The Dependencies column names other containers (not external systems
     — those belong in § 3) by their table row name. Interfaces between
     containers belong in the Interface subsection; link to the contract
     (OpenAPI spec, proto file, event schema) rather than reproducing it.
     Cross-reference: each container here should appear in the §3.1
     allocation table in the requirements doc once `architect` has
     completed that column. -->

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

<!-- Author-guidance: Decompose only containers that carry non-trivial
     internal structure — a container whose implementation is a single
     module does not need a component diagram. The Traces to requirements
     field is mandatory; leave it blank only before architecture review,
     and flag it as a gap in the § 1.3 rationale chain if still empty
     at review. Key design decisions must link ADRs — prose rationale
     without an ADR citation is not sufficient. Cross-reference: component
     names used here are the canonical names for the §3.1 allocation
     table in the requirements doc. -->

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

<!-- Author-guidance: Show the three mandatory scenarios as sequence or
     activity diagrams — use Mermaid sequenceDiagram or a linked image.
     Each diagram is followed by one prose paragraph naming the
     components involved, the timing constraints (if any), and the
     failure mode the error-handling scenario guards against. Avoid
     duplicating concurrency-specific detail here; cross-reference § 10
     for shared-state and ordering concerns. Keep diagrams at the
     container boundary — component-internal sequences belong in the
     component's ADR. -->

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

<!-- Author-guidance: Draw or describe one topology diagram per
     environment (dev / staging / prod) if they differ in meaningful
     ways. Label network boundaries and security zones explicitly.
     If infrastructure is managed as code, link the IaC module paths
     rather than duplicating their content. Cross-reference: resource
     budgets (CPU, memory, scaling policy, connection-pool limits) belong
     in § 12 — do not repeat them here. The DR standby topology, if any,
     belongs in § 12 as well. -->

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

<!-- Author-guidance: Write one subsection per concern listed below.
     Each subsection is one paragraph naming the strategy adopted,
     followed by a link to the governing ADR or external document.
     Omit a subsection only when the concern is genuinely not present
     in this system — record a one-sentence rationale for each omission.
     Do not reproduce entity-level data structure or ownership detail
     here; that belongs in § 11. Cross-reference: the authentication and
     authorization subsection must align with the security controls
     documented by `security-engineer` in the security assurance artefact.

     Example (Observability subsection):
     Structured JSON logs emitted at INFO and above; Prometheus metrics
     scraped by the platform agent; distributed traces via OpenTelemetry
     SDK with a 10 % sampling rate in production. See ADR-0014. -->

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

<!-- Author-guidance: Add one row per ADR file in docs/adr/ in
     chronological order. Do not summarise or paraphrase ADR content
     here — the title and status are sufficient. Mark superseded ADRs
     with status "superseded by ADR-NNNN" rather than deleting the row.
     Cross-reference: every ADR listed here must appear in at least one
     row of the § 1.3 rationale chain; an ADR without a rationale-chain
     entry is an untraced decision. New ADRs are required whenever any
     trigger condition in `.claude/agents/architect.md` § "ADR trigger
     list" fires. -->

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

<!-- Author-guidance: Write one scenario per quality attribute named in
     § 1. Use the six-part SEI form — Source, Stimulus, Environment,
     Artifact, Response, Response measure — with measurable values in
     the Response measure field ("≤ 200 ms at p99 under 500 concurrent
     users" rather than "fast"). The Trade-off note is mandatory: state
     which other quality attribute is degraded and by how much. Cross-
     reference: each scenario here maps to at least one NFR in the
     requirements doc; link the NFR ID. -->

For each top-3 quality attribute, one concrete scenario with:
- **Source** (stimulus origin), **Stimulus**, **Environment**,
  **Artifact**, **Response**, **Response measure**. (SEI
  Quality-Attribute Scenario form.)
- **Trade-off note** — what this scenario costs elsewhere.

---

## 16. Risks and technical debt

<!-- Author-guidance: List risks that could cause the architecture to
     fail to meet its quality attributes, not general project risks
     (those belong in the project-manager's risk register). Technical
     debt rows describe known shortcuts taken with a plan to address
     them; use "debt" as a prefix in the Description to distinguish
     from open risks. The Mitigation / ADR column must not be blank —
     if no mitigation exists yet, record "open" and flag it at
     architecture review. Cross-reference: high-impact risks should
     appear in the § 1.3 rationale chain as a concern driving an ADR. -->

| ID | Description | Likelihood | Impact | Mitigation / ADR |
|---|---|---|---|---|
| R-01 | <risk> | L/M/H | L/M/H | <reference> |

---

## 17. Glossary delta

<!-- Author-guidance: Record only terms introduced or given a specific
     meaning in this architecture document that do not yet appear in
     the binding glossaries. Define each term in one sentence. Once the
     term is stable and reused across documents, promote it to
     `docs/glossary/ENGINEERING.md` (generic) or
     `docs/glossary/PROJECT.md` (project-specific) via `researcher` and
     remove it from this delta. This section should shrink, not grow,
     as the project matures. -->

Project-specific architecture terms not already in
`docs/glossary/ENGINEERING.md` or `docs/glossary/PROJECT.md`. If a term
is general, add it to `ENGINEERING.md`; if it's project-specific, add
it to `PROJECT.md` (via `researcher`).
