# ADR-NNNN — <short title>

Shape per MADR 3.0 (Markdown Architecture Decision Records;
`https://adr.github.io/madr/`), adapted to this template's
Three-Path Rule (upstream issue #33). Owned by `architect`;
co-owned with `security-engineer` on Hard-Rule-#7 paths and with
`sre` on operations-critical paths.

One file per decision. Indexed from `docs/architecture.md` § 10.
Filename convention: `docs/adr/NNNN-<kebab-case-slug>.md` with
sequential NNNN.

---

## Status

- **Proposed** | **Accepted** | **Rejected** | **Deprecated** | **Superseded by ADR-NNNN**
- **Date:** YYYY-MM-DD (accept date, not propose date)
- **Deciders:** `architect` + <other agents involved> + customer
  (for ADRs that alter requirement-facing behaviour, customer
  approval is required per CLAUDE.md Hard Rules)
- **Consulted:** <SMEs, external experts, documents>

## Context and problem statement

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

## Decision drivers

What makes this decision non-trivial. Each driver is a one-line
constraint or priority.

- <driver 1>
- <driver 2>

## Considered options (Three-Path Rule, binding)

**Three named alternatives are required**, not one recommendation
disguised as alternatives. Forces divergent thinking and documents
the road not taken, for future auditors. Per upstream issue #33
and `docs/proposals/workflow-redesign-v0.12.md` §4.2.

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

## Decision outcome

**Chosen option:** M | S | C
**Reason:** one-paragraph justification keyed to the decision
drivers above. Why this option wins against the other two.

## Consequences

### Positive
- <what this enables>

### Negative / trade-offs accepted
- <what this costs>

### Follow-up ADRs
- <ADR-NNN — title — reason this decision triggers a downstream one>

## Verification

How we'll know the decision was right / wrong:

- **Success signal:** <observable thing that indicates the chosen
  option is working>
- **Failure signal:** <observable thing that would require a
  superseding ADR>
- **Review cadence:** <when this ADR is re-examined; session-
  anchored per `CLAUDE.md` § "Time-based cadences">

## Links

- Task: `docs/tasks/<T-NNNN>.md`
- Prior-art: `docs/prior-art/<T-NNNN>.md` (if applicable)
- Proposal: `docs/proposals/<T-NNNN>.md` (if applicable)
- Related ADRs: ADR-NNNN, ADR-NNNN
- External references: <citations>
