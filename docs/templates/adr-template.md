# ADR-NNNN — <short title>

<!-- TOC -->

- [Section discipline (per FW-ADR-0006)](#section-discipline-per-fw-adr-0006)
- [Status &nbsp; <sub>**REQUIRED**</sub>](#status--required)
- [Context and problem statement &nbsp; <sub>**REQUIRED**</sub>](#context-and-problem-statement--required)
- [Decision drivers &nbsp; <sub>**RECOMMENDED**</sub>](#decision-drivers--recommended)
- [Considered options (Three-Path Rule, binding) &nbsp; <sub>**REQUIRED**</sub>](#considered-options-three-path-rule-binding--required)
  - [Option M — Minimalist](#option-m--minimalist)
  - [Option S — Scalable](#option-s--scalable)
  - [Option C — Creative (experimental)](#option-c--creative-experimental)
- [Decision outcome &nbsp; <sub>**REQUIRED**</sub>](#decision-outcome--required)
- [Consequences &nbsp; <sub>**RECOMMENDED**</sub>](#consequences--recommended)
  - [Positive](#positive)
  - [Negative / trade-offs accepted](#negative--trade-offs-accepted)
  - [Follow-up ADRs &nbsp; <sub>*OPTIONAL*</sub>](#follow-up-adrs--optional)
- [Verification &nbsp; <sub>**RECOMMENDED**</sub>](#verification--recommended)
- [Links &nbsp; <sub>*OPTIONAL*</sub>](#links--optional)

<!-- /TOC -->

Shape per MADR 3.0 (Markdown Architecture Decision Records;
`https://adr.github.io/madr/`), adapted to this template's
Three-Path Rule (upstream issue #33). Owned by `architect`;
co-owned with `security-engineer` on Hard-Rule-#7 paths and with
`sre` on operations-critical paths.

One file per decision. Indexed from `docs/architecture.md` § 10.

**Namespace split (per FW-ADR-0007 / issue #67):**

- **Framework ADRs** (decisions affecting the template itself —
  shipped to every downstream project): `FW-ADR-NNNN` ID, filename
  `docs/adr/fw-adr-NNNN-<kebab-case-slug>.md`. Maintained in the
  upstream template repo.
- **Project ADRs** (decisions for one specific downstream project):
  `ADR-NNNN` ID, filename `docs/adr/NNNN-<kebab-case-slug>.md`.
  Maintained per-project; never touched by upgrades.

The two namespaces share the directory but never collide. When this
template (`docs/templates/adr-template.md`) is used to author a new
ADR, choose the namespace based on whether the decision is
template-wide (FW-ADR) or project-local (ADR). Sequential NNNN within
each namespace.

## Section discipline (per FW-ADR-0006)

Sections below are tagged **REQUIRED**, **RECOMMENDED**, or
**OPTIONAL**.

- **Required** sections must be present in every ADR.
  Missing-required is a `code-reviewer` audit-mode finding.
- **Recommended** sections are present by default; may be omitted
  by replacing their body with a single-line rationale (e.g.,
  *"omitted: this ADR has no measurable verification signal"*).
  Silent omission of a Recommended section is a finding.
- **Optional** sections are present when they add value; absent
  otherwise. No rationale needed.

A minimal ADR (Required only, all Recommended omitted-with-rationale)
fits in ~40 lines. A full ADR runs ~200+. Choose the shape that
matches the decision's substance, not the template's habit.

---

## Status &nbsp; <sub>**REQUIRED**</sub>

- **Proposed** | **Accepted** | **Rejected** | **Deprecated** | **Superseded by ADR-NNNN**
- **Date:** YYYY-MM-DD (accept date, not propose date)
- **Deciders:** `architect` + <other agents involved> + customer
  (for ADRs that alter requirement-facing behaviour, customer
  approval is required per CLAUDE.md Hard Rules)
- **Consulted:** <SMEs, external experts, documents>

## Context and problem statement &nbsp; <sub>**REQUIRED**</sub>

Two paragraphs max. What situation forces a decision? What is
being optimised for? What constraints are in play (requirement,
schedule, cost, team composition, regulatory)?

Cite:
- The task or feature triggering this ADR (task ID, issue number,
  customer request)
- The specific `architect.md` § "ADR trigger list" row that
  required this ADR (new dep / public-API / cross-cutting / data
  model / auth / etc.)
- The prior-art artifact if one exists
  (`docs/prior-art/<task-id>.md`)

## Decision drivers &nbsp; <sub>**RECOMMENDED**</sub>

What makes this decision non-trivial. Each driver is a one-line
constraint or priority. *Omit-with-rationale acceptable for trivial
decisions (e.g., naming convention, tooling pin).*

- <driver 1>
- <driver 2>

## Considered options (Three-Path Rule, binding) &nbsp; <sub>**REQUIRED**</sub>

**Three named alternatives are required**, not one recommendation
disguised as alternatives. Forces divergent thinking and documents
the road not taken, for future auditors. Per upstream issue #33
and `docs/proposals/workflow-redesign-v0.12.md` §4.2. The
Three-Path Rule is **binding** and stays Required even on minimal
ADRs — never omit-with-rationale.

### Option M — Minimalist

The simplest thing that could solve the problem. Prioritises:
low implementation cost, minimum new surface area, no new
dependencies where avoidable, ship-today viability. Typically
accepts tighter operating envelope, less headroom for growth,
manual operations where automation would cost design time.

- **Sketch:** <one paragraph>
- **Pros:** <bullets>
- **Cons:** <bullets>
- **When M wins:** tight schedule; unclear long-term requirement
  stability; throwaway / spike scope; minimum-viable proof of
  concept.

### Option S — Scalable

The production-grade solution that handles reasonable growth
without re-architecture. Prioritises: correctness under load,
operability, observability, clear extension points. Typically
accepts higher up-front cost in exchange for headroom.

- **Sketch:** <one paragraph>
- **Pros:** <bullets>
- **Cons:** <bullets>
- **When S wins:** known growth trajectory; production-facing;
  operationally critical; cost of re-architecture > cost of
  building for scale up-front.

### Option C — Creative (experimental)

The option that breaks the usual pattern — a novel architecture,
a non-obvious library, a radical simplification nobody else has
written up, a research-grade technique. Prioritises: long-term
leverage, team learning, unusual fit to an unusual constraint.
Typically accepts higher risk from unfamiliarity.

- **Sketch:** <one paragraph>
- **Pros:** <bullets>
- **Cons:** <bullets>
- **When C wins:** the problem is an outlier that M and S don't
  naturally fit; team has bandwidth for technique learning; a
  spike or experimental scope has de-risked the unfamiliarity;
  the project already sits somewhere unusual.

Ordering note: Minimalist → Scalable → Creative. The first two
are the safe pair; Creative is the provocation. Do not omit
Creative as "obviously not"; its purpose is to make the team
name the constraint that rejects it.

## Decision outcome &nbsp; <sub>**REQUIRED**</sub>

**Chosen option:** M | S | C
**Reason:** one-paragraph justification keyed to the decision
drivers above. Why this option wins against the other two.

## Consequences &nbsp; <sub>**RECOMMENDED**</sub>

### Positive
- <what this enables>

### Negative / trade-offs accepted
- <what this costs>

### Follow-up ADRs &nbsp; <sub>*OPTIONAL*</sub>
- <ADR-NNN — title — reason this decision triggers a downstream one>

## Verification &nbsp; <sub>**RECOMMENDED**</sub>

How we'll know the decision was right / wrong:

- **Success signal:** <observable thing that indicates the chosen
  option is working>
- **Failure signal:** <observable thing that would require a
  superseding ADR>
- **Review cadence:** <when this ADR is re-examined; session-
  anchored per `CLAUDE.md` § "Time-based cadences">

*Omit-with-rationale acceptable when the decision has no measurable
post-hoc signal (e.g., a naming convention).*

## Links &nbsp; <sub>*OPTIONAL*</sub>

- Task: `docs/tasks/<T-NNNN>.md`
- Prior-art: `docs/prior-art/<T-NNNN>.md` (if applicable)
- Proposal: `docs/proposals/<T-NNNN>.md` (if applicable)
- Related ADRs: ADR-NNNN, ADR-NNNN
- External references: <citations>
