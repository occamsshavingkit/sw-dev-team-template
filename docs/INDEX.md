# Docs Index

Table of contents for everything under `docs/` (and the top-level
binding docs that sit at the repo root). One-line description each.
Keep alphabetized within each section.

## Repo root

| File | Purpose |
|---|---|
| `CLAUDE.md` | Project guide; Claude reads this every session. FIRST ACTIONS (skill packs → scoping → naming → issue-feedback opt-in), agent roster, hard rules. |
| `VERSION` | Current template version (SemVer). Downstream projects stamp `TEMPLATE_VERSION` from this. |
| `CHANGELOG.md` | Release history. MAJOR / MINOR / PATCH semantics. |
| `CUSTOMER_NOTES.md` | Append-only log of customer answers, verbatim, stewarded by `researcher`. |
| `README.md` | Human-facing overview of the template. |
| `SW_DEV_ROLE_TAXONOMY.md` | Binding role vocabulary (SWEBOK / ISO 12207 / IEEE 1028 / ISTQB / SFIA v9 / Google SRE / PMBOK). |

## `docs/`

| File | Purpose |
|---|---|
| `docs/INDEX.md` | This file. |
| `docs/AGENT_NAMES.md` | Canonical role → teammate name → pronouns mapping; rules for picking names and respecting pronouns. |
| `docs/OPEN_QUESTIONS.md` | Register of open questions with ID / answerer / status / resolution. Stewarded by `researcher`. |
| `docs/ISSUE_FILING.md` | Convention for filing framework gaps against the upstream template repo (includes template-version citation). |

## `docs/glossary/`

| File | Purpose |
|---|---|
| `docs/glossary/ENGINEERING.md` | **Binding.** Generic software-engineering terminology. |
| `docs/glossary/PROJECT.md` | **Binding.** Project-specific terms (customer-domain, vendor, site, codenames). |

## `docs/pm/` (owned by `project-manager`, created per project)

| File | Purpose |
|---|---|
| `docs/pm/CHARTER.md` | Project charter (PMBOK Initiating). |
| `docs/pm/STAKEHOLDERS.md` | Stakeholder register + engagement plan. |
| `docs/pm/SCHEDULE.md` | Schedule baseline + milestone list. |
| `docs/pm/COST.md` | Cost / effort baseline + variance. |
| `docs/pm/RISKS.md` | Risk register. |
| `docs/pm/CHANGES.md` | Change log. |
| `docs/pm/LESSONS.md` | Lessons learned / retrospective (continuous). |

## `docs/sme/` (per domain)

| File | Purpose |
|---|---|
| `docs/sme/INVENTORY-template.md` | Template for the per-domain inventory. |
| `docs/sme/<domain>/INVENTORY.md` | External-material inventory for that domain. Stewarded by `researcher`. |
| `docs/sme/<domain>/local/` | Copyrighted external material; gitignored. |

## `docs/templates/` (standards-shaped document templates)

| File | Purpose |
|---|---|
| `docs/templates/architecture-template.md` | ISO/IEC/IEEE 42010:2022 + arc42 + C4 architecture doc. |
| `docs/templates/phase-template.md` | ISO/IEC/IEEE 12207:2017 life-cycle phase with gate review. |
| `docs/templates/requirements-template.md` | ISO/IEC/IEEE 29148:2018 requirements doc. |
| `docs/templates/scoping-questions-template.md` | Seed queue of Step-2 scoping questions. |
| `docs/templates/task-template.md` | INVEST + DoR + DoD task spec. |

## `docs/templates/pm/` (PMBOK artifact templates, owned by `project-manager`)

| File | Purpose |
|---|---|
| `docs/templates/pm/CHARTER-template.md` | Project charter (PMBOK Initiating). |
| `docs/templates/pm/STAKEHOLDERS-template.md` | Stakeholder register + engagement plan. |
| `docs/templates/pm/SCHEDULE-template.md` | Schedule baseline + milestone list + variance log. |
| `docs/templates/pm/COST-template.md` | Cost / effort baseline + forecast + variance. |
| `docs/templates/pm/RISKS-template.md` | Risk register with scoring + response plans. |
| `docs/templates/pm/CHANGES-template.md` | Change log with thresholds + approvers. |
| `docs/templates/pm/LESSONS-template.md` | Lessons learned journal + milestone syntheses. |

## `.claude/agents/`

| File | Role (taxonomy §) |
|---|---|
| `tech-lead.md` | Tech Lead + sole human interface (§2.4b). |
| `project-manager.md` | PMBOK Project Manager (§2.9a). |
| `architect.md` | Software Architect (§2.4a). |
| `software-engineer.md` | Software Engineer / construction (§2.1). |
| `researcher.md` | Librarian / researcher + customer-notes + glossary + open-questions steward. |
| `qa-engineer.md` | QA / Test Engineer (§2.2). |
| `sre.md` | SRE + Performance Engineer (§2.3). |
| `tech-writer.md` | Technical Writer (§2.5a). |
| `code-reviewer.md` | Code Reviewer + Auditor, IEEE 1028 (§2.7). |
| `release-engineer.md` | Build + Release Engineer (§2.8). |
| `sme-template.md` | Scaffold for SME agents; copy to `sme-<domain>.md`. |
