# Literature review — sw-dev resources surfaced via Luked91's GitHub

Reviewer: tech-lead (with researcher assistance)
Date: 2026-04-25
Scope: Resources reachable from `https://github.com/Luked91` (own repos +
starred repos) that are directly relevant to the **sw-dev team
template** itself. The PLC / industrial-control set is reviewed
separately (out of scope here).

Sources held on `quackplc@plc-test:~/ref/sw-dev/` (full clones):

- `jam01/SRS-Template` — Markdown SRS template, CC0
- `jam01/SDD-Template` — Markdown SDD template, CC0
- `Luked91/IEEE` — 18 IEEE standards PDFs (mirror; **third-party
  copyright**, reference only — see IP caveat below)
- `Orthant/IEEE` — second IEEE standards mirror (cross-check)
- `Luked91/software-development-books` — 44+ commercial books
  (**third-party copyright**)
- `iamindian/References_Books` — additional book mirror
- `DovAmir/awesome-design-patterns` — curated list (CC-BY type)

This review focuses on the two highest-value items: **jam01/SRS-Template
(MSRS)** and **jam01/SDD-Template (MSDD)**. They are CC0-public-domain
and aligned with the same IEEE/ISO standards we already cite, so they
are directly mineable for our `docs/templates/`.

---

## 1. Comparison — Requirements templates

### 1.1 Side-by-side at a glance

| Dimension | Our `requirements-template.md` | jam01 `srs-template.md` (MSRS) |
|---|---|---|
| Standards cited | ISO/IEC/IEEE 29148:2018; ISO/IEC 25010 (NFR taxonomy) | IEEE 830; ISO/IEC/IEEE 29148:2011/2017; van Lamsweerde NFR taxonomy |
| Length | 137 lines | 422 lines (guided), 186 lines (bare) |
| ID scheme | Flat: `FR-NNNN`, `NFR-NNNN`, `C-NNNN`, `AC-NNNN.M` | Per-area: `REQ-[AREA]-[NNN]-[VER]`, AREA ∈ {FUNC, INT, PERF, SEC, REL, AVAIL, OBS, COMP, INST, BUILD, DIST, MAINT, REUSE, PORT, COST, DEAD, POC, CM, ML} |
| NFR taxonomy | ISO/IEC 25010 (8 quality characteristics) | van Lamsweerde + IEEE 830 (Performance, Security, Reliability, Availability, Observability — flatter) |
| Verification field | Implicit (rationale + AC cover it) | **Explicit** field per requirement: Test \| Analysis \| Inspection \| Demonstration \| Other |
| Stakeholder section | Yes — top-level, integrated | No — folded into "User Characteristics" |
| Constraints | Separate section (`C-NNNN`), distinct from requirements | Subsection 2.3 "Product Constraints" + cross-referenced from 3.* |
| Compliance | Folded into NFR + Constraints | **Dedicated subsection 3.4 Compliance** |
| Apportioning / release allocation | Absent | **Subsection 2.6** — explicit allocation table |
| AI/ML requirements | Absent | **Dedicated 3.6** with 6 sub-areas (model spec, data mgmt, guardrails, ethics, HITL, lifecycle) |
| Build / Delivery / Distribution / POC / Change Mgmt | Folded into NFR / cross-cutting | Explicit subsections under 3.5 Design and Implementation |
| Traceability matrix | Top-level Section 7 | Section 4 Verification matrix |
| Change log | Top-level Section 8 (append-only) | Inline Revision History table |
| Author guidance | Sparse — assumes practitioner | **Heavy** — `💬` what / `➥` how / `💡` tips per section |
| Variants shipped | Single monolithic template | **Three**: guided (`srs-template.md`), bare (`srs-template-bare.md`), per-requirement (`req-template.md`, `req-template-bare.md`) for MADR-style breakouts |
| MoSCoW priority | Yes (`Must / Should / Could / Won't`) | Implicit (no first-class field) |
| Steward roles | Named (`tech-lead` intake, `researcher` numbering) | Generic (no role taxonomy) |

### 1.2 Where ours is stronger

- **Stakeholder concerns are first-class** — Section 2 of ours pulls
  stakeholders forward as the lens for the rest of the doc. MSRS folds
  this into "User Characteristics" and loses the architectural-stakeholder
  framing.
- **ISO/IEC 25010 NFR taxonomy** — ours organises NFRs against the
  current ISO standard (8 characteristics: functional suitability,
  performance efficiency, compatibility, interaction capability,
  reliability, security, maintainability, flexibility, plus safety
  where applicable). MSRS flattens this and is missing modern entries
  (compatibility, flexibility, interaction capability).
- **Constraints as a separate, ID'd section** — we treat `C-NNNN` as
  distinct non-negotiable inputs, not requirements. MSRS keeps them
  inside Section 2.
- **MoSCoW prioritisation** — explicit Priority field per requirement.
- **Steward roles named** — `tech-lead` intake, `researcher` numbering /
  traceability — works with our agent roster.
- **Append-only change log section** — discipline baked into the template
  rather than left to the document author's habit.
- **Project-glossary integration** — explicitly defers generic terms to
  `docs/glossary/ENGINEERING.md` and project terms to `PROJECT.md`. MSRS
  redefines API/SRS/UI inline, which invites drift.

### 1.3 Where MSRS is stronger (gaps in ours)

1. **AI/ML requirements section.** ⭐⭐ Six sub-areas: Model Spec, Data
   Management, Guardrails, Ethics, Human-in-the-Loop, Model Lifecycle &
   Operations. Given this very project uses AI agents, and downstream
   projects will increasingly include ML components, this is a real gap.
2. **Verification Method enumeration.** ⭐ Test / Analysis / Inspection /
   Demonstration / Other. This is straight from IEEE practice and
   pairs naturally with our traceability matrix. We currently leave it
   to the AC field, which is less inspectable.
3. **Apportioning of requirements.** ⭐ Allocation across components,
   subsystems, and releases is a 29148 concept we currently omit. For
   multi-release programs, this is load-bearing.
4. **Per-area ID prefixes.** ⭐ `REQ-FUNC-001`, `REQ-PERF-001`,
   `REQ-SEC-001` are far more grep-friendly than flat `FR-NNNN`. Useful
   when filtering requirements by category in CI / verification reports.
5. **Compliance as a dedicated subsection.** ⭐ Currently we fold this
   into NFR or Constraints, but in regulated domains (food/beverage
   GMP, GDPR, ISO 22000, FSMA, 21 CFR Part 11) it deserves a dedicated
   home with its own audit-evidence trail.
6. **Three-variant shipping** — guided, bare, per-requirement breakout.
   The per-requirement breakout pairs with MADR-style ADRs and lets a
   project evolve from monolithic SRS → directory of requirement files
   without retemplating.
7. **Heavy inline author guidance.** Particularly useful for new
   project-managers and for **AI-agent interpretation**: the explicit
   "what this section is for / how to fill it / tips" makes it much
   easier for `tech-lead` or `researcher` to fill the template
   correctly without prior context.
8. **Build / Delivery / Distribution / POC / Change Management as
   explicit subsections.** Modern lifecycle stages our template
   collapses into "cross-cutting concepts" or NFR.

### 1.4 Recommendations — requirements template

Concrete, ranked by ROI:

1. **Add an AI/ML subsection** to `requirements-template.md`, mirroring
   MSRS § 3.6. (Highest ROI; fills a glaring gap.)
2. **Add an explicit Verification Method field** to the per-requirement
   schema (Test | Analysis | Inspection | Demonstration | Other) and
   surface it in the traceability matrix.
3. **Add an Apportioning / Allocation subsection** under System Context,
   capturing per-component and per-release allocation with a
   cross-reference table.
4. **Adopt per-area ID prefixes** alongside the existing `FR-NNNN` (or
   migrate). At minimum keep an "AREA" tag on each requirement so
   verification reports can filter.
5. **Promote Compliance to a top-level subsection** of NFRs (next to
   Security, Reliability, etc.), with an audit-evidence column in the
   traceability matrix.
6. **Add a `requirements-template-bare.md` and a per-requirement
   breakout template** to support the three workflow modes (monolithic,
   long-lived in VCS, MADR-style breakout).
7. **Add inline `💬 / ➥ / 💡` author guidance** — particularly
   valuable for AI-agent-driven authoring in the multi-agent workflow.

These are CC0-clean to copy verbatim or adapt; attribution to
`jam01/SRS-Template` in the file header is courteous but not required.

---

## 2. Comparison — Architecture / Design templates

### 2.1 Side-by-side at a glance

| Dimension | Our `architecture-template.md` | jam01 `sdd-template.md` (MSDD) |
|---|---|---|
| Standards cited | ISO/IEC/IEEE 42010:2022; arc42; C4 model | IEEE 1016-2009; ISO/IEC/IEEE 42010:2011 |
| Length | 158 lines | 271 lines (guided), 117 lines (bare) |
| Top-level structure | C4-shaped: Context → Container → Component → Runtime → Deployment + Cross-cutting | Viewpoint-shaped: 15 explicit viewpoints + Design Views (instances) + Decisions |
| Diagram model | C4 (Context / Container / Component / Code) baked in | Per-viewpoint typical languages enumerated (UML, C4, ER, BPMN, ADL, Petri nets, sequence diagrams, etc.) |
| Quality-attribute scenarios | SEI form (Source / Stimulus / Environment / Artifact / Response / Response measure) | Not directly — referenced only as concerns under viewpoints |
| Solution Strategy section (arc42) | Yes — high-level shaping decisions | No equivalent |
| Risks & technical debt | Top-level table | Absent |
| ADR index | Top-level table; references `docs/adr/` | Inline Decisions section with embedded MADR-style template |
| Glossary delta | Top-level | Embedded in Section 1.3 |
| Variants shipped | Single template | **Two**: guided + bare, plus a `view-template.md` per-view breakout |

### 2.2 The 15 IEEE 1016 viewpoints (MSDD)

| # | Viewpoint | Addresses | Typical languages |
|---|---|---|---|
| 1 | Context | System boundaries, environment actors, offered services | UML use case, C4 Context |
| 2 | Composition | Major design elements, modularity, integration | UML component, hierarchical decomposition, deployment |
| 3 | Logical | Static structure: types, interfaces, relationships | UML class, UML object |
| 4 | Physical | Hardware config, physical topology, constraints | Block diagram, network topology, rack layout, cloud infra |
| 5 | Structure | Internal composition: parts, ports, connectors | UML composite structure, class, package; C4 Container |
| 6 | Dependency | Integration needs, coupling, change-impact | UML package, dependency graph, UML component |
| 7 | Information | Persistent data, schemas, integrity | ER, UML class, logical data model |
| 8 | Interface | Externally visible interfaces, contracts | API specs, IDLs, signatures, UML component |
| 9 | Interaction | Runtime collaboration: messages, ordering, errors | UML sequence, collaboration, BPMN |
| 10 | Algorithm | Internal processing logic, complexity, determinism | Pseudocode, flowchart, decision table, math formulation |
| 11 | State Dynamics | Modes/states, transitions, events, guards | UML state machine, state-transition table, automata, **Petri net** |
| 12 | Concurrency | Parallelism, synchronization, ordering | UML activity, sequence + state, actor model |
| 13 | Patterns | Reusable patterns, architectural styles | UML composite structure, package/class, ADL |
| 14 | Deployment | Software-to-node mapping, topology, scaling | UML deployment, IaC topology, network, CI/CD pipeline |
| 15 | Resources | Memory / bandwidth / threads / handles, contention | UML class, UML real-time profile, OCL, resource alloc tables |

### 2.3 Where ours is stronger

- **C4 levelling baked in** — Context / Container / Component is the
  most-adopted modern architecture-diagram model. MSDD lists C4 as one
  notation among many but doesn't structure the doc around it.
- **arc42 Solution Strategy** — captures the half-dozen big shaping
  decisions in one place, separate from individual ADRs.
- **SEI Quality-Attribute Scenarios** — Source/Stimulus/Environment/
  Artifact/Response/Response measure is the gold standard for
  trade-off analysis; MSDD does not include this form.
- **Risks and technical debt table** — ours has a first-class section.
- **ADR index as a table** — chronological, status-tagged. MSDD embeds
  decisions inline, which makes for a longer doc but less of an index.

### 2.4 Where MSDD is stronger (gaps in ours)

1. **Explicit viewpoint enumeration.** ⭐⭐ Our template effectively
   recognises ~6 viewpoints (Context, Container, Component, Runtime,
   Deployment, Cross-cutting). MSDD spells out 15. For
   **safety-critical or control-systems** projects (which is the
   customer's domain), the omitted viewpoints matter:
   - **State Dynamics** — modes/states/transitions, with Petri-net /
     state-machine notations; essential for PLC and discrete-control
     reasoning.
   - **Concurrency** — parallelism, synchronisation, race conditions;
     essential anywhere multiple controllers, threads, or actors
     interact.
   - **Resources** — memory, bandwidth, threads; central to embedded
     and real-time work.
   - **Algorithm** — formal description of critical processing logic;
     useful for control-loop tuning and analytical verification.
   - **Information** — persistent data model; we currently bury this
     under "Cross-cutting > Data management".
2. **Per-viewpoint typical languages.** ⭐ Each viewpoint comes with
   "use UML state machine, or Petri net, or state-transition table"
   guidance. This makes diagram choice less of a free-for-all.
3. **A `view-template.md` for individual views.** ⭐ Lets large designs
   live as `docs/design/views/<NNN>-<title>.md` and keeps the SDD itself
   as an index — same MADR-style modularity benefit as the SRS variant.
4. **Inline `💬 / ➥ / 💡` author guidance.** Same advantage as the
   SRS template — lowers the floor for both human and AI authors.
5. **Cleaner Stakeholder Concerns → Viewpoints chain.** § 2.1 surfaces
   stakeholder concerns; § 2.2 selects viewpoints to address them; § 3
   instantiates views. This is exactly the 42010 reasoning chain. Ours
   gestures at it but doesn't make it explicit.

### 2.5 Recommendations — architecture template

Two viable adoption paths:

**Path A — Augment the existing C4-shaped template.**

1. Add an explicit "Selected Viewpoints" subsection that lists which of
   the IEEE 1016 viewpoints this project's SDD will instantiate, with
   stakeholder-concern justification per viewpoint.
2. Add **State Dynamics**, **Concurrency**, and **Resources** as
   first-class sections (currently buried in Cross-cutting), at minimum
   for safety-critical / control-systems projects.
3. Lift **Information** out of Cross-cutting to a peer of the C4 views.
4. Add per-section "typical languages" guidance.
5. Add inline `💬 / ➥ / 💡` author guidance for AI-agent legibility.
6. Add a `view-template.md` for breakout views under `docs/design/`.

**Path B — Ship a second viewpoint-based template alongside the C4
one.** `architecture-template-viewpoints.md` would be the right pick
for control-systems and safety-critical projects; the existing
C4-shaped one stays the default for web/cloud/SaaS work. `tech-lead`
picks per project at scoping time.

Path A is less disruptive and probably the right starting move.
Path B can come later if a project demands it.

### 2.6 Decision template

MSDD § 4 ships a per-decision template (ID, Title, Context, Options,
Outcome, More Information). We already use ADRs at `docs/adr/`. The
MSDD form is MADR-compatible, so no change is needed — but we could
make this explicit in `docs/templates/` by adding a tiny ADR-template
file that mirrors MADR + this form, so projects don't reinvent the
ADR shape.

---

## 3. Other resources surfaced

### 3.1 Standards reference shelf — `Luked91/IEEE` and `Orthant/IEEE`

Eighteen IEEE standards as PDFs. Highly relevant to this template:

| File | Maps to in our project |
|---|---|
| 1028-2008.pdf | `code-reviewer.md` IEEE 1028 audit role |
| 1016-2009.pdf, 1016.1-1993.pdf | architecture template (jam01 cites 1016) |
| 1012-2016.pdf | V&V — supports `qa-engineer.md` |
| 1044-2009.pdf, 1044.1-1995.pdf | defect classification — `qa-engineer.md` |
| 730-2014.pdf, 730.1-1995.pdf | SQA processes — `code-reviewer.md` periodic audits |
| 828-2012.pdf | configuration management — `release-engineer.md` |
| 829-2008.pdf | test documentation — `qa-engineer.md` |
| 29148-2011.pdf | requirements (ours cites 29148:2018; this is the prior edition) |
| 16326-2009.pdf, 24765-2010.pdf | 12207-derived life-cycle / vocabulary — `docs/glossary/` |
| 982.2-1988.pdf | software reliability measures — SRE |
| 1008-1987.pdf | unit testing — `software-engineer.md` |
| 1042-1987.pdf, 729-1983.pdf, 928.1-2005.pdf | older SCM, vocab, SRPS — historical reference |

**IP caveat (binding).** IEEE standards are copyrighted by IEEE
regardless of any wrapper repo's MIT LICENSE — the MIT only covers the
mirror author's own contributions. We **must not** commit, redistribute,
or quote at length. Use is limited to:

- Reading on the customer's own host (`plc-test`) where the customer
  asserts they hold local rights.
- Cross-checking our paraphrases against the authoritative text.
- Citing by clause in research notes.

If we want these in our `docs/library/`, the customer must:
1. Confirm local right-of-access (employer license, personal IEEE
   member subscription, or other authorized channel).
2. Have `researcher` add LIB-NNNN entries to `docs/library/INVENTORY.md`
   for each, with the same scrutiny applied to LIB-0001/LIB-0002.
3. Place the PDFs in `docs/library/local/` (already gitignored).

### 3.2 Books — `Luked91/software-development-books`, `iamindian/References_Books`

Combined ~50 commercial titles spanning Clean Code, Refactoring, Clean
Architecture, Fundamentals of Software Architecture, DDIA, Building
Secure & Reliable Systems, SWE@Google, Pro Git, DDD, System Design
Interview, Beyond Vibe Coding, etc.

**IP caveat.** Same as IEEE — commercial books are copyrighted; the
mirror's wrapper LICENSE does not change that. Treat as personal
reference shelf only. None can be committed.

Of practical interest to the agent roster:

- **Software Engineering at Google** — `code-reviewer.md`, process
  paraphrases.
- **Clean Architecture, Fundamentals of Software Architecture** —
  `architect.md` reading list.
- **Building Secure and Reliable Systems** — `sre.md` baseline.
- **Designing Data-Intensive Applications** — `architect.md` data view.
- **Pro Git** — `release-engineer.md`.
- **Beyond Vibe Coding (Addy Osmani)** — directly relevant to this
  multi-agent framework.

We do not need these committed; researcher can cite by row ID only if
the customer adds them to `docs/library/INVENTORY.md` per the same IP
process used for PMBOK/SWEBOK.

### 3.3 Other repos — passing relevance

- `DovAmir/awesome-design-patterns` — curated design-patterns list;
  research pointer for `architect.md` only, no install.

---

## 4. Concrete next-step proposals

Ranked. None of the actions below are taken without customer assent —
they are framed as upstream issues against `sw-dev-team-template` so
they are reviewable.

| # | Action | Target | Issue title proposal |
|---|---|---|---|
| 1 | Add AI/ML requirements subsection to `requirements-template.md` | template | feat(templates): add AI/ML requirements subsection (per IEEE/jam01 MSRS § 3.6) |
| 2 | Add Verification Method field to per-requirement schema | template | feat(templates): explicit Verification Method (Test/Analysis/Inspection/Demonstration) on each requirement |
| 3 | Add Apportioning / Allocation subsection | template | feat(templates): add release/component allocation matrix to requirements template |
| 4 | Adopt per-area ID prefixes (`REQ-FUNC-NNN`, etc.) | template | refactor(templates): per-area requirement ID prefixes for grep-ability |
| 5 | Promote Compliance to top-level NFR subsection | template | feat(templates): dedicated Compliance subsection with audit-evidence column |
| 6 | Ship `requirements-template-bare.md` + per-requirement breakout | template | feat(templates): bare + per-requirement breakout variants |
| 7 | Add inline `💬 / ➥ / 💡` author guidance | templates (both) | feat(templates): inline author + AI-agent guidance |
| 8 | Add State Dynamics / Concurrency / Resources / Information as first-class architecture viewpoints | template | feat(templates): expand architecture template with IEEE 1016 viewpoints |
| 9 | Add `view-template.md` for breakout architecture views | template | feat(templates): per-view breakout for large architectures |
| 10 | Document explicit viewpoint-selection step (stakeholder concerns → viewpoints → views) | template | feat(templates): make 42010 reasoning chain explicit |
| 11 | (optional) Ship a second viewpoint-based architecture template variant | template | proposal: viewpoint-based architecture template variant for safety-critical / control-systems projects |

Items 1–3 and 8 are the highest-leverage and would land cleanly inside
v0.14.0 of the template.

---

## 5. IP / attribution note

`jam01/SRS-Template` and `jam01/SDD-Template` are released under
**CC0 1.0 Universal** (public domain dedication). We may copy, adapt,
and redistribute their content without restriction. Best practice is
to credit the source in a small "Influences" block at the head of the
adapted template, even though CC0 does not require it.

The IEEE PDFs and commercial books listed above are **not** affected by
the wrapper repos' licenses; they are independently copyrighted and
must be treated under our standard IP policy (CLAUDE.md § "IP policy").

---

## 6. What the other repos can shape in our agents and procedures

This section answers a follow-on question: beyond the jam01 templates,
do the IEEE PDFs, the book mirrors, and `awesome-design-patterns` carry
material that should reshape any of our **agent definitions** or
**procedures**? Verdicts below.

### 6.1 IEEE standards (Luked91/IEEE + Orthant/IEEE)

Both mirrors hold the same 18-PDF set. The standards listed below
have direct procedural overlap with one of our agent files; the
recommendation column proposes how the agent could change once the
customer confirms read-rights and `researcher` adds the PDF to
`docs/library/INVENTORY.md`. **Until that happens, no edit lands** —
IEEE content is copyrighted (Hard rule #5).

| Standard | Topic | Most relevant agent | What it could shape |
|---|---|---|---|
| IEEE 1044-2009 (+ 1044.1) | Defect classification | `qa-engineer.md` | Adopt the 1044 attribute taxonomy (severity, priority, type, source-detection-activity, …) so defect records are structured the same way across projects. Today our defect handling is implicit. |
| IEEE 730-2014 (+ 730.1) | Software Quality Assurance plans / processes | `code-reviewer.md` (audits) and `project-manager.md` | Defines the SQA-plan structure and audit cadence. Could replace ad-hoc audit prompts with an explicit SQA-plan section in `docs/pm/` and a cadence rule in `code-reviewer.md`. |
| IEEE 1012-2016 | Software V&V | `qa-engineer.md` + `code-reviewer.md` | Provides the canonical V&V activity list per life-cycle phase. Pair with our `phase-template.md` to fill the V&V column per phase. |
| IEEE 829-2008 | Software test documentation | `qa-engineer.md` | Test-plan / test-design-spec / test-case-spec / test-procedure / test-log / test-incident-report / test-summary-report shapes. We currently leave test docs to the agent's discretion. |
| IEEE 1008-1987 | Unit testing | `software-engineer.md` | Unit-test process steps and pass/fail criteria. Could codify a binding "every commit ships unit tests for the changed surface" rule with the standard's vocabulary. |
| IEEE 828-2012 | Configuration management | `release-engineer.md` | CM plan structure, baselines, change control. Could replace ad-hoc release-engineer tasks with an explicit CMP. |
| IEEE 1016-2009 (+ 1016.1) | Software Design Description | `architect.md` | Already cited indirectly via jam01/SDD-Template. Direct reading lets `architect` paraphrase the viewpoint definitions accurately. |
| IEEE 29148-2011 | Requirements engineering | `tech-lead` (intake), `researcher` (numbering) | Prior edition of what our requirements-template already cites (29148:2018). Useful for cross-reference, not a replacement. |
| IEEE 16326-2009 + 24765-2010 | Project management of software / vocabulary | `project-manager.md` + `docs/glossary/` | 24765 is the Software & Systems Engineering Vocabulary — paraphrased entries here would harden `docs/glossary/ENGINEERING.md`. 16326 covers PM-of-software life-cycle processes that complement PMBOK. |
| IEEE 982.2-1988 | Software reliability measures | `sre.md` | Older but canonical reliability-metric definitions; pair with modern SRE practice. |
| IEEE 1042-1987 | (Older) software CM guidance | `release-engineer.md` | Historical, superseded by 828; reference only. |
| IEEE 729-1983 | (Older) software engineering vocabulary | `docs/glossary/` | Historical, superseded by 24765. Reference only. |
| IEEE 928.1-2005 | Software-product reliability prediction | `sre.md` | Reference / supplemental. |

**Recommended next step.** Pick the highest-leverage three and mine
them on plc-test (where the customer asserts local rights):

1. **IEEE 1044-2009** → fold a defect-classification subsection into
   `qa-engineer.md`.
2. **IEEE 730-2014** → add an SQA-plan section to `docs/pm/` and a
   periodic-audit cadence rule in `code-reviewer.md`.
3. **IEEE 1012-2016** → add a V&V activity column to
   `phase-template.md` and reference it from `qa-engineer.md`.

For each: `researcher` adds a `LIB-NNNN` row to
`docs/library/INVENTORY.md` with the same scrutiny used for
LIB-0001 / LIB-0002, then paraphrases (no quoting) into the target
agent file with citations by clause.

### 6.2 Book mirrors (`software-development-books`, `References_Books`)

Combined ~50 commercial titles. None can be committed (third-party
copyright). They can however *inform* agent prompts via paraphrase,
provided the customer adds the title to `docs/library/INVENTORY.md`.

The titles most relevant to specific agents:

| Title | Most relevant agent | What it could shape |
|---|---|---|
| Software Engineering at Google (Winters et al.) | `code-reviewer.md`, `project-manager.md` | Code-review norms, post-commit testing, large-scale changes. Probably the highest single-source ROI for `code-reviewer.md`. |
| Clean Code, The Pragmatic Programmer | `software-engineer.md` | Already canonical; reading list reference, not direct procedure change. |
| Refactoring (Fowler) | `software-engineer.md` | Refactor catalog as a reference shelf. |
| Working Effectively With Legacy Code (Feathers) | `software-engineer.md`, `qa-engineer.md` | Test-seam techniques; pairs well with the retrofit playbook. |
| Designing Data-Intensive Applications (Kleppmann) | `architect.md` | Data-platform reasoning; reference. |
| Building Secure and Reliable Systems | `sre.md`, `code-reviewer.md` | Reliability-and-security baseline. |
| Building Microservices (Newman) | `architect.md` | Microservice patterns — reference. |
| Patterns of Enterprise Application Architecture (Fowler) | `architect.md` | Patterns reference. |
| Head First Design Patterns | `architect.md`, `software-engineer.md` | Patterns introduction — onboarding. |
| Clean Architecture (Martin) | `architect.md` | Layering principles — reference. |
| Soft Skills (Sonmez) | `tech-lead.md` indirectly | Communication norms; reference. |
| Discrete Mathematical Structures, Intro to Algorithms (CLRS) | `software-engineer.md` | Background reference. |
| Hands-On Machine Learning (Géron), Mastering ML Algorithms, Bayesian Reasoning and ML | future ML-related SME | Build out an `sme-ml` if and when an ML-track project starts. |
| Cracking the Coding Interview, Grokking System Design | n/a | Not procedural — interview-prep books. |

**Recommended next step.** Don't try to mine these systematically. Two
narrowly-scoped reads pay off:

1. *Software Engineering at Google* → distill 1–2 pages of paraphrased
   process notes into `code-reviewer.md` + `project-manager.md`. This
   is the single highest-ROI book on the shelf.
2. *Working Effectively With Legacy Code* → cross-check the retrofit
   playbook (`docs/templates/retrofit-playbook-template.md`) against
   Feathers's seam techniques; surface any missing patterns as
   `retrofit-playbook` issues.

Anything beyond those should wait for a specific agent to hit a
specific gap and pull a specific chapter on demand — not a bulk
read.

### 6.3 `awesome-design-patterns` (DovAmir)

A curated link list, not a procedural source. It belongs in
`researcher`'s reference shelf as a starting point when an
`architect` request hits "what design patterns apply here". No agent
edit needed; a single line in `researcher.md` pointing at the list
suffices.

### 6.4 What did NOT survive the screen

- **No methodology / process repos** were found in the Luked91 set
  that improve on what we already have (PMBOK, ISO 12207, IEEE 1028,
  ISTQB, SFIA).
- **No agent / Claude Code skill packs** of relevance.
- **No AI-agent-orchestration material** beyond what was already
  catalogued and rejected via ADR-0001 (claude-mem in, ruflo-class
  out).

---

## 7. Reference inventory (for `researcher`)

Full clones held at `quackplc@plc-test:~/ref/sw-dev/`:

```
~/ref/sw-dev/SRS-Template/             — jam01, CC0
~/ref/sw-dev/SDD-Template/             — jam01, CC0
~/ref/sw-dev/IEEE/                     — Luked91 mirror, IEEE © (reference only)
~/ref/sw-dev/Orthant-IEEE/             — Orthant mirror, IEEE © (reference only)
~/ref/sw-dev/software-development-books/ — Luked91 mirror, multiple © (reference only)
~/ref/sw-dev/References_Books/         — iamindian mirror, multiple © (reference only)
~/ref/sw-dev/awesome-design-patterns/  — DovAmir, curated list
```

PLC / industrial-control set held at `quackplc@plc-test:~/ref/plc/` and
reviewed in a separate document.
