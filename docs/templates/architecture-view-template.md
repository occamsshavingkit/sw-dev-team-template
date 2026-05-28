---
name: architecture-view-template
description: Guided per-view file template; one file per significant IEEE 1016-2009 view per FW-ADR-0004.
template_class: architecture-view
---


# View — <viewpoint> — <name>

One file per significant view per FW-ADR-0004. Each view is an instance
of one IEEE 1016-2009 (`LIB-0009`) viewpoint, addressing specific
stakeholder concerns. Lives at
`docs/views/<viewpoint>-<name>.md`.

Owned by `architect`.

A view is *not* a complete architecture. It is one lens onto the
architecture, addressing one concern set. Composing all the views
plus the cross-cutting sections in `docs/architecture.md` is the
SDD.

---

## Identification

- **Viewpoint:** Context | Composition | Logical | Dependency |
  Information | Patterns use | Interface | Structure | Interaction
  | State dynamics | Algorithm | Resource (per IEEE 1016 § 5)
- **Name:** <human-readable name, e.g., "checkout-runtime",
  "user-data-information">
- **Stakeholders:** who reads this view, what concern it addresses
- **Status:** Draft | Reviewed | Approved | Superseded
- **Date:** YYYY-MM-DD
- **Related ADRs:** ADR-NNNN (decisions that shaped this view)

## Concern

One paragraph. What question does this view answer? Whose question
is it?

## Notation

What design language is used (UML, C4, ER, BPMN, prose…). If a
notation is non-standard, link to the legend.

## View content

The view itself. Diagram (or its source), supporting prose, key
relationships. Keep tight — the view answers its concern, not "all
about the system".

## Rationale (cross-reference)

Design decisions that shaped this view live in ADRs, not here. List
them:

- ADR-NNNN — <title> — <one-line relevance>

## Open questions

Issues this view does not resolve, with owners.

## Change log

| Date | Change | Who |
|---|---|---|
