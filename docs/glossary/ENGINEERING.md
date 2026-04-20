# Engineering Glossary (binding)

Generic software-engineering vocabulary. Every agent and every human
contributor MUST use these terms in these senses. Disagreement with a
definition is resolved by amending this file (via `researcher` +
`architect` + `tech-lead` consensus) — not by using the term differently
in practice.

When industry itself disagrees (see `SW_DEV_ROLE_TAXONOMY.md` §2 ambiguity
subsections), the glossary picks one definition and notes the alternative.

**Project-specific terms** (customer-domain jargon, vendor shorthand,
internal codenames, etc.) live in `docs/glossary/PROJECT.md`, not here.

---

## Structure and design

**Architecture** — the fundamental concepts or properties of a system in
its environment, embodied in its elements, relationships, and principles
of its design and evolution. ISO/IEC/IEEE 42010:2022.

**Design** — decisions internal to a component that do not rise to
architectural significance. Rule of thumb: *architecture is decisions
that are costly to change; design is decisions inside the boundary.*

**Architecture Decision Record (ADR)** — an append-only document
recording one architecturally significant decision, its context, and its
consequences. Pattern by Michael Nygard (2011).

**Component** — a unit of composition with contractually specified
interfaces and explicit context dependencies. Szyperski, 1998.

**Module** — a unit of code organization (package, namespace, file). A
module may implement part or all of a component.

**Service** — a component exposed over a network with an explicit API
contract and lifecycle independent of its callers.

**View / Viewpoint** — per ISO/IEC/IEEE 42010. A *view* represents the
architecture from a particular perspective; a *viewpoint* is the
conventions (notation, concerns) used to construct that view.

**Concern** — an interest of one or more stakeholders pertinent to the
system. Examples: performance, security, maintainability.

**Quality attribute / Non-functional requirement / "-ility"** — a
measurable property of a system characterizing how well it performs
rather than what it does. Canonical catalog: ISO/IEC 25010:2023. Use
"quality attribute" in architecture docs, "non-functional requirement"
in requirements docs.

---

## Requirements

**Need** — a stakeholder's statement of a capability they want; usually
imprecise. Not itself a requirement.

**Requirement** — a condition or capability the system must have,
stated testably. Must be unambiguous, verifiable, consistent, feasible,
and traceable. ISO/IEC/IEEE 29148:2018.

**Specification** — the engineered form of one or more requirements,
unambiguous and verifiable.

**Functional requirement** — what the system shall *do* (inputs →
outputs, behaviors, state changes).

**Non-functional requirement (NFR)** — a constraint on how well the
system performs. Synonym of quality attribute in requirements context.

**Constraint** — a limit imposed externally (regulatory, business,
technical) that the solution must respect. Non-negotiable; distinct
from a requirement.

**Acceptance criterion** — the specific condition the *customer* will
check to accept a requirement or user story. Scoped to one item.

**Definition of Ready (DoR)** — team-wide standard every work item
must meet before implementation starts.

**Definition of Done (DoD)** — team-wide standard every work item must
meet to be complete. Distinct from acceptance criteria: DoD applies to
*all* items; acceptance criteria are per-item.

**Traceability** — the ability to link a requirement to its sources,
design artifacts, implementation, tests, and delivered verification.

---

## Work decomposition

**Epic** — work too large to complete in one iteration; decomposed
into stories.

**Story (user story)** — a user-visible increment of value completable
in one iteration. Testable, independent, small. Form:
*As a [role], I want [capability], so that [benefit].*

**Task** — engineering work under a story, not user-visible on its own.
Sized in hours or ≤ 2 days of one person's work.

**Spike** — a time-boxed investigation to reduce uncertainty. Output
is a finding, not production code.

**Prototype** — an artifact built to explore design or validate a
hypothesis. May be thrown away.

**INVEST** — qualities of a good user story: **I**ndependent,
**N**egotiable, **V**aluable, **E**stimable, **S**mall, **T**estable.
Bill Wake, 2003.

**Work Breakdown Structure (WBS)** — hierarchical decomposition of
project scope into deliverable-oriented leaves that are single-owner
and estimable. PMBOK term.

---

## Life cycle

**Phase** — a defined portion of the life cycle with entry criteria,
exit criteria, deliverables, and a gate review. ISO/IEC/IEEE 12207:2017.
Distinct from *iteration*: a phase is a structural unit; an iteration
is a time-box.

**Iteration / Sprint** — a time-boxed period (typically 1–4 weeks)
during which one or more stories are completed.

**Milestone** — a point-in-time marker of progress. No duration.

**V-model** — a phase model pairing construction activities
(requirements → design → implementation) with verification activities
(unit → integration → system → acceptance). Widely used in regulated
contexts.

---

## Testing and quality

**Error** — a human action producing an incorrect result. ISTQB.

**Defect (fault, "bug")** — an imperfection in an artifact introduced
by an error. "Bug" is colloquial; prefer "defect" in formal contexts.

**Failure** — observable deviation of delivered behavior from required
behavior, caused by a defect being exercised.

**Verification** — are we building the system *right*? (Does the
artifact meet its specification?) ISO/IEC/IEEE 12207.

**Validation** — are we building the *right* system? (Does the
artifact meet stakeholder intent?)

**Regression** — a defect introduced (or reintroduced) by a change.

**Test level** — unit, integration, system, acceptance. ISTQB.

**Test type** — functional, non-functional, structural, change-related.

---

## Operations

**SLI (Service-Level Indicator)** — a quantitative measure of service
behavior (e.g., "fraction of successful requests over 4 weeks"). Google
SRE.

**SLO (Service-Level Objective)** — a target value or range for an SLI
(e.g., "≥ 99.9% successful over 30 days"). Internal. Google SRE.

**SLA (Service-Level Agreement)** — a contract with consequences if an
SLO is missed. External; legally binding.

**Error budget** — 1 − SLO. The tolerable amount of unavailability per
period. Exhausted error budget freezes risky changes.

**Toil** — manual, repetitive, automatable, tactical operational work.
Google SRE. Target is ≤ 50% of SRE time.

**Incident** — an unplanned disruption or degradation requiring
response. Distinct from a *defect*, which is the underlying cause.

---

## Roles and parties

This template uses **customer** as the umbrella term for the human
running the session, but PMBOK and the Scrum Guide draw finer
distinctions that matter as soon as the human wears more than one
hat. The four definitions below are explicit so a reader of the
template never has to guess which hat "customer" refers to in a
given passage. Binding across all template content.

**Customer** — in this template, the human running the session.
Defines requirements, prioritises scope, and provides acceptance.
Ruling authority on anything the agent team is building. Outside
the agent team. The label is retained for continuity even though
the human may, in PMBOK / Scrum terms, be one or more of the
narrower roles below simultaneously.

**Product owner** — the role, in Scrum and PMBOK terms, that
defines *what* to build and in what order: owns the product
backlog, prioritises scope, accepts done-ness. When this template
says "the customer made a ruling on scope", PMBOK/Scrum would
describe the acting role as *product owner*. In most downstream
projects the customer **is** the product owner; the terms coincide
for practical purposes and the template stays on "customer" to
avoid churn.

**End customer / end user** — the party who ultimately *receives*
or *uses* the delivered system. In PMBOK this is a stakeholder
distinct from the product owner; the product owner typically
speaks *for* the end customer to the team. In a B2B engagement
the end customer is the client buying the product; in an internal-
tools project the end customer is the team that will use the
tool. For the avoidance of doubt, when the template writes
"customer" it almost never means this narrower sense — it means
the session human (product owner). Use "end customer" or "end
user" explicitly when this narrower sense is intended.

**Sponsor** — in PMBOK, the party providing funding and executive
authority for the project. Distinct from product owner and end
customer. In solo / greenfield / internal-tool projects, the
customer often wears the sponsor hat as well, but the template
makes no assumption either way.

**SME (Subject-Matter Expert)** — a person with accumulated
expertise in a particular field or topic, reflected by degree,
licensure, or years of experience. `SW_DEV_ROLE_TAXONOMY.md`
§2.6a. The customer may *also* be an SME in one or more domains
(see `CLAUDE.md` § "The human is the customer (and may also be an
SME)"); in that case their answers in those domains are ground
truth and get recorded verbatim in `CUSTOMER_NOTES.md`. External
SMEs are brought onto the project through the customer and their
knowledge is cached via per-project `sme-<domain>.md` agents.

**Role-stacking in this template.** The session human can be any
combination of: product owner (almost always), end customer
(often), sponsor (often), and SME (sometimes, per domain). The
template does not require you to separate the hats. It does
require that when a ruling is being made, it is clear *which hat*
is speaking — product-owner rulings are binding on scope /
requirements / acceptance; SME rulings are binding on the
relevant domain; end-customer or sponsor input is stakeholder
context that informs product-owner rulings.

**User** — a person who uses the delivered system. Synonymous
with "end user" above; prefer "end customer" when contrasting
against the product-owner sense of "customer", and "user" when
talking about the system's human interface generically.

**Stakeholder** — anyone affected by the system or its delivery.
PMBOK superset. Includes product owner, end customers, sponsor,
SMEs, regulators, operations staff, etc.

**End-of-life terms from the role taxonomy** — see `SW_DEV_ROLE_TAXONOMY.md`
for canonical definitions of *Software Engineer, QA Engineer, SRE,
Architect, Tech Writer, Reviewer, Auditor, Release Engineer, Project
Manager, Product Manager*. Do not duplicate them here.

---

## Risk and uncertainty

**Risk** — a future event that may occur with an impact. Has
probability and impact; may be positive (opportunity) or negative.

**Issue** — a risk that has materialized. Present-tense problem
requiring action now.

**Assumption** — a belief held without proof that, if wrong, would
affect the plan. Must be flagged for review.

**Dependency** — a required condition, artifact, or decision controlled
outside the work item's scope.

---

## Intellectual property

**Project-created work** — anything authored inside this project by
contributors working under the project's license. Committable to the
project repository per that license.

**External material** — anything not authored inside the project.
**Assume external material is copyrighted** unless the customer
explicitly declares otherwise in `CUSTOMER_NOTES.md` (e.g., "this
standard library is MIT-licensed; include verbatim"). External
material is held locally and cited by reference — see
`docs/sme/INVENTORY-template.md` and CLAUDE.md § IP policy.

**Derivative work** — work produced by substantially transforming
external material (summarizing, paraphrasing, restructuring). May be
project-created if the transformation is substantive and the source is
cited; is external if it is merely reformatted.

**Citation** — the reference that allows a third party to independently
locate the external material (URL, ISBN, DOI, standard number, or
equivalent). Required in inventories for every external item.
