---
name: audit-brief-template
description: Self-contained context bundle for milestone/release audits run by conversation-blind agents (any harness — Claude Code, Codex, Gemini). Ensures equivalent inputs across models so divergent findings are comparable and reconcilable.
template_class: audit-brief
---


# Audit brief — <audit-id> — <milestone or release ref>

<!-- TOC -->

- [Conversation-blindness note](#conversation-blindness-note)
- [Audit identification](#audit-identification)
- [Artifacts to read (canonical input set)](#artifacts-to-read-canonical-input-set)
- [Binding references](#binding-references)
- [Audit dimensions / checklist](#audit-dimensions--checklist)
- [Required finding-report format](#required-finding-report-format)
- [Return expectations](#return-expectations)

<!-- /TOC -->

<!-- PURPOSE. This template produces a SELF-CONTAINED audit brief. Every
field is filled before dispatch; the auditor reads ONLY what is listed
here. When multiple models (Claude/Codex/Gemini) run the same audit, all
receive the same filled copy of this template — same artifact list, same
binding references, same checklist, same output format. Divergent findings
are then comparable and reconcilable by tech-lead.

Multi-model reconciliation protocol:
  docs/agents/manual/tech-lead-manual.md § "Multi-model audit reconciliation"

Owned by: tech-lead (prepares the brief). Executed by: the named auditor
role (code-reviewer, onboarding-auditor, security-engineer, or qa-engineer
per the audit type). -->

Owned by `tech-lead`. One brief per audit run. When the same audit is
dispatched to multiple models, fill this template ONCE and send
identical copies — do not paraphrase per model.

---

## Conversation-blindness note

**You are conversation-blind.** You have no access to prior chat history,
prior session context, or any information not explicitly listed in this
brief. Everything you need to perform this audit is in this document.
If a required artifact is missing or unreadable, stop and return a
structured blocker — do not infer or hallucinate its contents.

---

## Audit identification

- **Audit ID:** A-<NNNN or timestamp>
- **Milestone / release ref:** <milestone name, sprint close, or `vX.Y.Z-rcN`>
- **Audit type:** milestone-close | release-candidate | ad-hoc | multi-model
- **Auditor role:** `code-reviewer` | `onboarding-auditor` | `security-engineer` | `qa-engineer`
- **Dispatched by:** `tech-lead`
- **Dispatched at:** YYYY-MM-DDThh:mmZ
- **Harness:** Claude Code | Codex | Gemini | <other>

---

## Artifacts to read (canonical input set)

List every file the auditor must read. No auditor may draw on artifacts
not listed here. This is the **identical input set** for all models.

### Required reads (mandatory before any finding)

| # | Path (absolute from repo root) | Purpose in this audit |
|---|---|---|
| 1 | `<path>` | <why it is relevant> |
| 2 | `<path>` | <why it is relevant> |

### Conditional reads (read if the required set triggers a finding in this area)

| Area | Path | Trigger condition |
|---|---|---|
| <area> | `<path>` | <condition that makes this read necessary> |

Do not read files outside these lists. If a finding requires evidence
from an unlisted file, note it in the blocker section of the report —
do not read it unilaterally.

---

## Binding references

The auditor must apply these references when evaluating findings.
They are listed here so all harnesses work from the same authority set.

- **`CLAUDE.md` § "Hard rules"** — the 12 project Hard Rules; violations
  are automatic Major findings.
- **`SW_DEV_ROLE_TAXONOMY.md`** — binding role vocabulary; use for role-
  ownership and boundary findings.
- **`docs/glossary/ENGINEERING.md`** and **`docs/glossary/PROJECT.md`** —
  binding terminology; flag term drift.
- **Relevant ADRs:** `<list specific ADR paths if scope-relevant>`
- **Acceptance criteria for this milestone:**
  `<path to CHARTER.md milestone section, task DoD, or inline list>`

---

## Audit dimensions / checklist

Check each dimension. A dimension with no finding is explicitly marked
"No finding." Do not omit dimensions; an omitted dimension is
indistinguishable from a missed finding in a multi-model reconciliation.

- [ ] **Hard-rule conformance.** Each of the 12 Hard Rules checked
      against the artifact set. Cite the rule number for any violation.
- [ ] **Acceptance-criteria coverage.** Every acceptance criterion
      for this milestone has observable evidence of satisfaction.
      Flag any criterion with no evidence.
- [ ] **Traceability.** Each requirement has a corresponding
      implementation artifact; each implementation artifact traces to
      a requirement. Flag gaps.
- [ ] **ADR conformance.** Relevant ADRs are respected in the
      artifact set. Flag any conflict between artifact and binding ADR.
- [ ] **Role-ownership conformance.** Artifacts are produced by the
      correct owning roles per `SW_DEV_ROLE_TAXONOMY.md`. Flag any
      role-boundary violation.
- [ ] **Customer-truth stewardship.** `CUSTOMER_NOTES.md` entries
      are structurally conformant (canonical shape, no inline `tech-lead`
      writes). `librarian` is the steward; flag violations.
- [ ] **Working-tree isolation.** No evidence of parallel-write
      conflicts, wrong-branch commits, or non-hermetic-test contamination
      in the git log (if log is in the artifact set).
- [ ] **Framework/product boundary.** No framework-managed files
      edited by product work without explicit customer authorization.
- [ ] <Add further project-specific dimensions here>

---

## Required finding-report format

Every finding uses this structure. Output findings as a numbered list.

```
### Finding <N> — <severity>: <short title>

**Severity:** Critical | Major | Minor | Observation
**Hard Rule / ADR / criterion:** <cite the binding reference, or "N/A">
**Location:** <file path + line range, or artifact name>
**Evidence:** <exact quote or git reference; do not paraphrase>
**Recommendation:** <one or two sentences — what change resolves it>
```

**Severity definitions:**

| Level | Meaning |
|---|---|
| Critical | Blocks release or milestone close; a Hard Rule violation, a security gate failure, or a missing customer-required approval |
| Major | Significant conformance gap; must be resolved before merge but does not block immediately |
| Minor | Should be fixed; does not block |
| Observation | No action required; noted for awareness or future reference |

If a dimension has no finding, output:
```
### <Dimension name> — No finding
```

---

## Return expectations

Return to `tech-lead` when the audit is complete:

- [ ] One finding per `### Finding N` block, per format above.
- [ ] All checklist dimensions explicitly covered (finding or "No finding").
- [ ] Any artifact that was unreadable or missing listed as a structured
      blocker:
      ```
      Blocker: <path> — <reason unreadable / missing>
      ```
- [ ] Auditor harness and model version recorded (for reconciliation
      traceability):
      ```
      Auditor: <role>, <harness>, <model version if known>
      ```
