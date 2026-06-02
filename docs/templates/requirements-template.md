---
name: requirements-template
description: Guided ISO/IEC/IEEE 29148:2018-shaped requirements template with per-requirement IDs, acceptance criteria, and traceability.
template_class: requirements
---


# Requirements — <project name>

<!-- TOC -->

- [1. Introduction](#1-introduction)
- [2. Stakeholders and their concerns](#2-stakeholders-and-their-concerns)
- [3. System context](#3-system-context)
  - [3.1 Requirements allocation](#31-requirements-allocation)
- [4. Functional requirements](#4-functional-requirements)
  - [FR-0001 — <one-line title>](#fr-0001--)
- [5. Non-functional requirements (quality attributes)](#5-non-functional-requirements-quality-attributes)
  - [NFR-0001 — <characteristic>: <one-line title>](#nfr-0001---)
  - [NFR-COMP-0001 — Compliance: <one-line title>](#nfr-comp-0001--compliance-)
- [6. AI/ML requirements](#6-aiml-requirements)
  - [6.1 Model specification](#61-model-specification)
  - [6.2 Data management](#62-data-management)
  - [6.3 Guardrails](#63-guardrails)
  - [6.4 Ethics, fairness, and bias](#64-ethics-fairness-and-bias)
  - [6.5 Human-in-the-loop](#65-human-in-the-loop)
  - [6.6 Model lifecycle and operations](#66-model-lifecycle-and-operations)
- [7. Constraints](#7-constraints)
- [8. Requirement ID prefixes](#8-requirement-id-prefixes)
- [9. Traceability matrix](#9-traceability-matrix)
- [10. Change log](#10-change-log)

<!-- /TOC -->

Shaped after ISO/IEC/IEEE 29148:2018. Terms are binding per
`docs/glossary/ENGINEERING.md` and `docs/glossary/PROJECT.md`. Each
requirement is uniquely identified, testable, traceable, and owns at
least one acceptance criterion.

Stewarded by `tech-lead` (intake) and `researcher` (numbering,
traceability). Technical decisions that flow *from* these requirements
live in architecture docs and ADRs, not here.

---

## 1. Introduction

**Purpose.** One paragraph: what this document specifies.

**Scope.** What is in, what is out. Cite the project charter in
`CUSTOMER_NOTES.md`.

**Definitions.** Project-specific terms. If a term is generic and
appears in `docs/glossary/ENGINEERING.md`, don't redefine it here; if
it's project-specific, add it to `docs/glossary/PROJECT.md` and cite
from here.

**References.** External documents this requires or implies. For any
copyrighted external material, cite per `docs/glossary/ENGINEERING.md`
§ IP.

---

## 2. Stakeholders and their concerns

| Stakeholder | Role | Primary concerns |
|---|---|---|
| <customer name> | Customer | <top 3 concerns> |
| <user persona> | End user | <top 3 concerns> |
| <other> | <role> | <concerns> |

---

## 3. System context

One paragraph narrative. Include a context diagram (C4 level 1) if
`architect` has produced one — link, don't duplicate.

**Assumptions.** List, each tagged with impact if wrong.
**Constraints.** Non-negotiable externally-imposed limits.
**Dependencies.** Required from outside this project.

### 3.1 Requirements allocation

<!-- Verification Method / allocation / compliance shaped after ISO/IEC/IEEE 29148:2018 (paraphrased). -->

Maps each requirement to the component or subsystem responsible for satisfying it, and to the planned release. `architect` fills the component column at architecture review; `project-manager` fills the release column at sprint planning. No row may remain blank past architecture review.

| Req ID | Title | Allocated-to component / subsystem | Allocated release | Notes |
|---|---|---|---|---|
| FR-0001 | <title> | <component / subsystem> | <release label> | |
| NFR-0001 | <title> | <component / subsystem> | <release label> | |

---

## 4. Functional requirements

<!-- Verification Method / allocation / compliance shaped after ISO/IEC/IEEE 29148:2018 (paraphrased). -->

ID format: `FR-NNNN`. Never reused, even after deletion (mark as
`SUPERSEDED BY FR-MMMM` or `WITHDRAWN`).

Per-area prefixes are an opt-in alternative (see §8). Projects already
using `FR-NNNN` / `NFR-NNNN` continue without change.

### FR-0001 — <one-line title>

**Statement.** The system shall <verb-phrase> <object> <condition>.

**Rationale.** Why this requirement exists. Cite `CUSTOMER_NOTES.md`
entry or standard if applicable.

**Acceptance criteria.**
- AC-0001.1: <observable, checkable condition>
- AC-0001.2: <…>

**Priority.** Must | Should | Could | Won't (MoSCoW).

**Verification Method.** Test | Analysis | Inspection | Demonstration | Other. (See §9 for definitions. `qa-engineer` owns populating this field; must not be blank before baseline.)

**Source.** `CUSTOMER_NOTES.md` YYYY-MM-DD entry / standard §X.Y /
regulatory reference.

**Traces to.** <design artifact / component / test cases, to be filled
by `architect` + `qa-engineer`>.

---

## 5. Non-functional requirements (quality attributes)

Organize by ISO/IEC 25010 quality characteristic. Use the same
ID-and-AC format as FRs, but prefix `NFR-NNNN`.

Mandatory categories to consider (omit with explicit rationale):
- Functional suitability
- Performance efficiency (response time, throughput, resource use)
- Compatibility
- Interaction capability (usability, accessibility)
- Reliability (availability, fault tolerance, recoverability)
- Security (confidentiality, integrity, authenticity, accountability)
- Maintainability
- Flexibility (portability, adaptability, scalability)
- Safety (where applicable)
- Compliance (law, regulation, contract, industry scheme, licence — use `NFR-COMP-NNNN`)

### NFR-0001 — <characteristic>: <one-line title>

**Statement.** Under <conditions>, the system shall <measurable
threshold with units>.

**Measurement method.** How `sre` or `qa-engineer` will verify.

**Acceptance criteria.** <observable, checkable>.

**Priority.** Must | Should | Could | Won't.

**Verification Method.** Test | Analysis | Inspection | Demonstration | Other.

**Source.** <reference>.

---

### NFR-COMP-0001 — Compliance: <one-line title>

<!-- Verification Method / allocation / compliance shaped after ISO/IEC/IEEE 29148:2018 (paraphrased). -->

Compliance requirements cover obligations imposed by law, regulation,
contract, industry scheme, or licence. Use the prefix `NFR-COMP-NNNN`.
`security-engineer` and `tech-lead` review all compliance rows at each
compliance milestone. The traceability matrix (§9) carries an `Audit evidence`
column for these rows; leave it blank or N/A for non-compliance requirements.

**Statement.** The system shall <comply with / implement / demonstrate> <obligation> <conditions or scope>.

*Example: The system shall respond to any verified data-subject access request within 30 calendar days, providing a complete record of personal data held, as required by applicable data-protection regulation.*

**Rationale.** Name the law, regulation, contract clause, scheme, or
licence that imposes the obligation. Cite the specific provision where
possible.

**Acceptance criteria.**
- AC-COMP-0001.1: <audit evidence type — e.g., exported report, signed
  confirmation, system log — produced within the required timeframe>
- AC-COMP-0001.2: <…>

**Priority.** Must (compliance requirements are almost always Must; document any exception with `tech-lead` and `security-engineer` approval).

**Verification Method.** Inspection | Demonstration | Analysis | Other. (Compliance rows rarely use Test alone; Inspection of audit evidence or Demonstration is typical.)

**Audit evidence.** <artefact name, location, or generation method that would satisfy an external auditor — e.g., "access-request log export from admin console">

**Source.** <regulation / contract / scheme reference, e.g. GDPR Art. 15>.

---

## 6. AI/ML requirements

<!-- AI/ML section inspired by MSRS (jam01/SRS-Template, CC0 1.0 Universal). -->

Omit this section entirely if the system has no ML model components.
If any subsystem relies on a trained model — whether hosted internally,
called via API, or embedded — complete all applicable subsections.
Use the per-area prefix `REQ-AIML-NNNN` for requirements in this section
(see §8), or continue with `FR-NNNN` / `NFR-NNNN` if the project has
not adopted per-area prefixes.

### 6.1 Model specification

Record the identity and provenance of every model the system depends on.
Pin model versions; floating references (e.g. "latest") are not
permitted on production paths without an explicit waiver recorded in
`CUSTOMER_NOTES.md`.

**REQ-AIML-0001 — Model version pinning**

**Statement.** The system shall reference each AI/ML model by an
immutable version identifier (model name, version string or hash, and
provider) so that the production artefact is fully reproducible.

**Rationale.** Floating model references cause silent behaviour changes
across deployments. Pinning is a prerequisite for incident diagnosis and
rollback.

**Acceptance criteria.**
- AC-AIML-0001.1: Every model reference in configuration and deployment
  manifests specifies a non-mutable version identifier; CI rejects any
  reference that resolves to "latest" or equivalent.
- AC-AIML-0001.2: The model registry entry for each production model
  records: name, version, provider/source, hosting mode (API / embedded
  / self-hosted), applicable licence, and any provider-imposed usage
  constraints.

**Priority.** Must.

**Verification Method.** Inspection (of deployment manifests and model registry).

**Source.** <CUSTOMER_NOTES.md entry or project decision>.

---

### 6.2 Data management

Document the origin, classification, and lifecycle of all data used to
train or validate the model, and of any runtime data the model processes.
Identify PII and regulated data classes explicitly; apply the project's
data-classification policy.

**REQ-AIML-0002 — Training data provenance**

**Statement.** The system's training and validation datasets shall each have a documented provenance record covering: data source, applicable licence, data-classification level (including PII status), retention schedule, annotation quality-assurance method, and a staleness threshold beyond which the dataset triggers a drift review.

**Rationale.** Undocumented data origin creates licence risk and makes
bias assessment impossible.

**Acceptance criteria.**
- AC-AIML-0002.1: A provenance record exists for each named dataset
  before that dataset is used in a training or evaluation run.
- AC-AIML-0002.2: Any dataset containing PII is tagged accordingly and
  handled under the applicable data-protection controls.

**Priority.** Must.

**Verification Method.** Inspection (of provenance records in the data catalogue).

**Source.** <CUSTOMER_NOTES.md entry or data-protection policy reference>.

---

### 6.3 Guardrails

Define the boundaries of acceptable model output. Specify what the model
must never produce, format and length limits, confidence thresholds below
which the system falls back to a safe default, and any content-safety
filter the model output passes through before reaching the user.

**REQ-AIML-0003 — Prohibited output and fallback behaviour**

**Statement.** The system shall block or suppress any model output that
falls into a defined set of prohibited categories (specified in the
project's content policy), and shall substitute a configured fallback
response whenever the model's confidence score falls below the project's
defined threshold.

**Rationale.** Without explicit output constraints and confidence-gated
fallback, the system may surface harmful, misleading, or incomplete
content to users.

**Acceptance criteria.**
- AC-AIML-0003.1: A content-policy document lists prohibited output
  categories; a content-safety filter is configured to intercept each
  category before output reaches the user.
- AC-AIML-0003.2: When model confidence is below the defined threshold,
  the system returns the designated fallback response and logs the event;
  no raw low-confidence output is surfaced.
- AC-AIML-0003.3: Output length and format constraints are enforced at
  the application layer independently of the model.

**Priority.** Must.

**Verification Method.** Test (automated adversarial and boundary-value test suite against the content filter and fallback path).

**Source.** <CUSTOMER_NOTES.md entry or content-policy reference>.

---

### 6.4 Ethics, fairness, and bias

Identify protected attributes relevant to the system's decisions. Specify
the fairness metric, acceptable disparity threshold, bias-assessment
dataset, and review cadence. Specify what level of explanation the system
must provide for consequential decisions.

**REQ-AIML-0004 — Fairness and bias assessment**

**Statement.** Before each production deployment, the system shall produce
a bias-assessment report against a designated evaluation dataset,
demonstrating that the chosen fairness metric does not exceed the defined
disparity threshold across each protected attribute.

**Rationale.** Model outputs that disadvantage protected groups create
legal and ethical exposure and erode user trust.

**Acceptance criteria.**
- AC-AIML-0004.1: The fairness metric, disparity threshold, and list of
  protected attributes are documented and approved before the first
  production deployment.
- AC-AIML-0004.2: Each deployment pipeline run produces a bias-assessment
  report; deployment is blocked if any threshold is exceeded.
- AC-AIML-0004.3: For decisions flagged as consequential, the system
  provides a human-readable explanation of the factors that led to the
  output.

**Priority.** Must.

**Verification Method.** Analysis (automated bias-assessment report reviewed by `qa-engineer` and `security-engineer`).

**Source.** <CUSTOMER_NOTES.md entry or ethics policy reference>.

---

### 6.5 Human-in-the-loop

List decision categories that require human confirmation before the
system acts. Specify the review timeout, escalation path, and how each
human intervention is recorded for audit.

**REQ-AIML-0005 — Human confirmation and audit logging**

**Statement.** For each decision category designated as requiring human
review, the system shall present the model output to a designated
reviewer, wait for explicit confirmation or rejection up to the defined
timeout, escalate automatically on timeout, and write an immutable audit
log entry for every intervention.

**Rationale.** Autonomous model action on high-stakes decisions without
human oversight increases error and accountability risk.

**Acceptance criteria.**
- AC-AIML-0005.1: A documented list of decision categories requiring
  human review is maintained and updated at each major release.
- AC-AIML-0005.2: The system enforces the configured timeout and
  escalation path; no designated decision is acted on without a logged
  human confirmation or a logged timeout-escalation record.
- AC-AIML-0005.3: Audit log entries are append-only and include:
  decision category, model output, reviewer identity, action taken,
  and timestamp.

**Priority.** Must.

**Verification Method.** Test (integration test covering the confirmation flow, timeout, escalation, and log output).

**Source.** <CUSTOMER_NOTES.md entry or governance policy reference>.

---

### 6.6 Model lifecycle and operations

Define the production quality baseline, the signal and threshold that
trigger a drift investigation, the condition that triggers retraining,
the deprecation notice period, and the maximum time to roll back to the
previous model version.

**REQ-AIML-0006 — Drift detection and rollback**

**Statement.** The system shall continuously evaluate a defined production
quality metric; when that metric degrades beyond the defined drift
threshold, the system shall generate an alert and, if the condition
persists beyond the defined window, trigger the retraining or rollback
procedure. Rollback to the previous approved model version shall complete
within the defined maximum rollback time.

**Rationale.** Model performance degrades silently in production as data
distributions shift. Explicit drift gates and fast rollback limit exposure.

**Acceptance criteria.**
- AC-AIML-0006.1: The production quality metric, drift threshold, alert
  mechanism, and maximum rollback time are documented and approved before
  the first production deployment.
- AC-AIML-0006.2: Monitoring produces alerts within the defined detection
  window when the drift threshold is crossed in a synthetic test.
- AC-AIML-0006.3: A rollback to the previous approved model version
  completes within the defined maximum rollback time in a staging
  exercise.
- AC-AIML-0006.4: The deprecation schedule for each model version is
  published with at least the defined minimum notice period before
  end-of-support.

**Priority.** Must.

**Verification Method.** Demonstration (staging rollback drill) and Inspection (drift-monitoring configuration and deprecation schedule).

**Source.** <CUSTOMER_NOTES.md entry or SRE operations plan reference>.

---

## 7. Constraints

Separate from requirements: these are non-negotiable. ID format: `C-NNNN`.

| ID | Constraint | Source |
|---|---|---|
| C-0001 | <description> | <regulatory / business / technical reference> |

---

## 8. Requirement ID prefixes

<!-- Verification Method / allocation / compliance shaped after ISO/IEC/IEEE 29148:2018 (paraphrased). -->

**Default (always valid).** `FR-NNNN` for functional requirements,
`NFR-NNNN` for non-functional requirements, `NFR-COMP-NNNN` for
compliance requirements. These prefixes remain fully valid for the life
of any project that adopts them. No migration is required.

**Per-area prefixes (opt-in).** Projects that benefit from grouping
requirements by concern area may adopt the pattern `REQ-<AREA>-NNNN`.
This is a supplement, not a replacement. A project may mix the two
styles if it migrates incrementally (see change-log migration note
below).

Illustrative area tokens:

| Token | Area |
|---|---|
| `FUNC` | Functional behaviour |
| `PERF` | Performance and efficiency |
| `SEC` | Security |
| `COMP` | Compliance |
| `AIML` | AI/ML model requirements (maps to §6) |
| `REL` | Reliability and availability |
| `SAFE` | Safety |
| `UX` | Interaction capability and accessibility |

**Migration note for projects on FR/NFR IDs.** If a project decides to
adopt per-area prefixes mid-life: record the decision in the Change log
(§10) with the date and the mapping from old IDs to new IDs; update the
Traceability matrix (§9) in the same commit; mark superseded IDs as
`SUPERSEDED BY REQ-<AREA>-NNNN` rather than deleting them.

---

## 9. Traceability matrix

<!-- Verification Method / allocation / compliance shaped after ISO/IEC/IEEE 29148:2018 (paraphrased). -->

Maintained by `researcher`. A row per requirement. `qa-engineer` owns
the Verification Method column; it must not be blank before baseline.
The Audit evidence column applies to compliance requirements
(`NFR-COMP-NNNN`); leave blank or N/A for all other rows.

**Verification Method definitions** (use exactly one per requirement):

| Method | When to use |
|---|---|
| Test | Verified by executing the system and observing output against defined pass/fail criteria. |
| Analysis | Verified by examining models, calculations, or simulations rather than the running system. |
| Inspection | Verified by reviewing artefacts (code, configuration, documentation) without execution. |
| Demonstration | Verified by operating the system in a representative scenario and observing behaviour. |
| Other | Any method not covered above; describe in the Notes column. |

| Req ID | Source | Design | Implementation | Verification Method | Test artefact | Audit evidence | Status |
|---|---|---|---|---|---|---|---|
| FR-0001 | CUSTOMER_NOTES 2026-MM-DD | FW-ADR-0003, §X of arch | module/path.ext | Test | T-0001 | N/A | verified |
| NFR-COMP-0001 | <regulation reference> | <design ref> | <impl ref> | Inspection | <audit log report> | access-request log export | verified |

Empty cells flag gaps. No row is "complete" until all cells are filled.

---

## 10. Change log

Append-only. Each change: date, requirement ID(s), change type (added /
withdrawn / superseded / reworded-without-scope-change), author, source
(`CUSTOMER_NOTES.md` entry or equivalent).
