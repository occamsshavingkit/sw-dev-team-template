---
name: ai-use-policy-template
description: PMBOK 8 Appendix X3 AI-use-policy template; one per project, customer-ratified.
template_class: ai-use-policy
---


# AI Use Policy — <project name>

PMBOK 8 Initiating artifact (Appendix X3 — Artificial Intelligence in
Project Management). One document per project. Owned by
`project-manager`; ratified by the customer (sign-off recorded in
`CUSTOMER_NOTES.md`). Referenced from CHARTER §1.

## 1. Scope of AI use

Name every task class in this project that uses AI and which PMBOK 8
adoption strategy applies (§X3.1):

| Task class | Strategy | Rationale | Human sign-off required? |
|---|---|---|---|
| e.g., code authoring | Assistance | AI proposes, human reviews each diff | yes — code-reviewer |
| e.g., customer-domain research | Augmentation | AI + researcher iterate together | n/a (internal) |
| e.g., log triage | Automation | AI summarizes logs without per-item review | no |

Strategy definitions per PMBOK 8 §X3.1:
- **Automation** — AI acts end-to-end without a human review step.
- **Assistance** — AI produces, human reviews each output before use.
- **Augmentation** — AI and human iterate together; neither fully
  owns the output.

## 2. Ethical factors (PMBOK 8 §X3.3)

One subsection per factor. Each names the concrete policy for this
project plus the review cadence.

### 2.1 Bias

Known bias sources in the AI tools used and in the data fed to them.
Mitigation approach. Review cadence.

### 2.2 Privacy

Data classification policy: what data may / may not be sent to which
AI service. Pointer to `CUSTOMER_NOTES.md` for any customer-specific
rule. PII / PHI / regulated data handling explicitly stated.

### 2.3 Accountability

Named human sign-off per deliverable class. AI is never the final
authority. Ties to CLAUDE.md Hard Rule #4 (customer approval for
safety-critical / irreversible / customer-flagged-critical logic).

### 2.4 Reliability

Validation approach for AI output: who checks, against what, how
often, what failure rate is acceptable before the strategy for that
task class is revised.

### 2.5 Safety

For safety-critical work, AI is **Assistance-mode only** — never in
the decision loop. Ties to CLAUDE.md Hard Rule #2 (no production
code ships on safety-critical paths without explicit customer
sign-off).

### 2.6 Transparency

Log of AI-generated or AI-mediated artefacts: which deliverables were
AI-involved and which were not. Disclosed to the customer at
milestone close.

### 2.7 Copyright

Inbound rules: AI must not be fed training-prohibited sources in a
training, fine-tuning, or persistent-embedding capacity. Transient
in-context reading (paraphrase-and-cite within a single session, no
persistent storage) is permitted under the narrow interpretation
ratified in `docs/IP_POLICY.md` (customer ruling 2026-04-23).
The motivating example is PMBOK 8 itself (LIB-0001) which carries
an explicit "NO AI TRAINING" clause on its copyright page. If your
project has stricter restrictions than the default narrow
interpretation, state them here.

Outbound rules: AI-generated content ownership. Check the project
licence and the relevant jurisdiction — some jurisdictions do not
grant copyright to AI-generated content, which changes whether
output can be licensed at all.

### 2.8 Sustainability

Environmental cost of AI usage for this project: which model classes
are used, typical token spend per task class, preference for
smaller / local models where output quality permits. Ties to
CHARTER §11 (Sustainability considerations) and LESSONS.md
`sustainability` category.

## 3. Out-of-scope uses

Explicit list of uses the project does NOT permit, with reasoning.
Examples: "no AI involvement in safety interlock design"; "no AI
drafts of legal or regulatory submissions"; "no embedding of
customer PII into third-party vector stores."

## 4. Review cadence

`project-manager` reviews this document at every milestone close and
whenever a new task class is added to §1 or a customer rule in
`CUSTOMER_NOTES.md` changes. Revisions flow through `docs/pm/CHANGES.md`
with a row per material change.

## 5. References

- PMBOK 8 Guide, Appendix X3 — Artificial Intelligence in Project
  Management (library row LIB-0001, pp. 237–244).
- PMBOK 8 Guide, copyright page (LIB-0001, p. iv) — "NO AI TRAINING"
  clause.
- `docs/IP_POLICY.md` — restricted-source handling rule.
- SWEBOK V4 ch. 14 — Professional Practice (library row LIB-0002) if
  professional-ethics binding is referenced.
- Project-specific: `CUSTOMER_NOTES.md` for any customer overrides.
