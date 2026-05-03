# Docs Index — Framework

Table of contents for **template-shipped** files only (scripts,
agent contracts, standard templates, framework ADRs, etc.). One-line
description each. Keep alphabetized within each section.

This file is replaced by upstream on every `scripts/upgrade.sh` run.
Project-authored content lives in
[`INDEX-PROJECT.md`](INDEX-PROJECT.md); top-level dispatcher at
[`INDEX.md`](INDEX.md). Per FW-ADR-0007 follow-up / issue #66.

## Repo root

| File | Purpose |
|---|---|
| `CLAUDE.md` | Project guide; Claude reads this every session. FIRST ACTIONS (skill packs → scoping → naming → issue-feedback opt-in), agent roster, hard rules. |
| `VERSION` | Current template version (SemVer). Downstream projects stamp `TEMPLATE_VERSION` from this. |
| `TEMPLATE_MANIFEST.lock` | Per-file SHA256 manifest of shipped files (per FW-ADR-0002, v0.14.0+). Written at scaffold; rewritten after every successful upgrade. Verified by `scripts/upgrade.sh --verify`. Files in `.template-customizations` are omitted. **Scaffolded into downstream projects, not present in the upstream template repo itself.** |
| `CHANGELOG.md` | Release history. MAJOR / MINOR / PATCH semantics. |
| `scripts/scaffold.sh` | Scaffolds a new downstream project from this template. Writes the initial `TEMPLATE_MANIFEST.lock` and self-verifies before exit. |
| `scripts/version-check.sh` | Session-start hook; compares `TEMPLATE_VERSION` against upstream and prints a banner if an upgrade is available. Pre-release tags filtered out for stable-track projects (issue #60). |
| `scripts/upgrade.sh` | Upgrades a scaffolded project to the latest template version. Respects user-added agents / SMEs; flags customized standard files for review. Subcommands: `--dry-run` (plan-only), `--verify` (offline drift check against `TEMPLATE_MANIFEST.lock`, FW-ADR-0002), `--help`. |
| `scripts/hooks/customer-notes-guard.py` | Claude Code PreToolUse hook that asks for confirmation before writes to `CUSTOMER_NOTES.md`, reinforcing researcher ownership of customer-answer entries. |
| `scripts/lib/manifest.sh` | Shared helpers for `TEMPLATE_MANIFEST.lock` (write / verify / ship-files enumeration / SHA256). Sourced by `upgrade.sh` and `scaffold.sh`. Per FW-ADR-0002. |
| `scripts/lib/first-actions.sh` | Shared FIRST ACTIONS detection helpers for session-start and upgrade warnings when Step-0 issue-feedback opt-in is missing. |
| `scripts/smoke-test.sh` | End-to-end sanity check on scaffold + version-check + upgrade + manifest verify contracts. Template-maintenance tool; not shipped to downstream projects. |
| `scripts/agent-health.sh` | Assembles a health-check packet for a named teammate (ground-truth snapshot + fixed prompt). Per `docs/agent-health-contract.md` § 3. |
| `scripts/respawn.sh` | Stubs a handover-brief file and prints the respawn checklist. Per `docs/agent-health-contract.md` § 4. |
| `docs/templates/handover-template.md` | Shape of a respawn handover brief. |
| `examples/README.md` | Catalog of filled-in reference projects (not shipped to downstream). |
| `migrations/README.md` | Per-version migration-script contract. |
| `migrations/TEMPLATE.sh` | Scaffold for writing a new migration. |
| `migrations/vX.Y.Z.sh` | Per-release migration (file moves / renames / shape changes); most releases do not ship one. |
| `CONTRIBUTING.md` | How to propose changes to the template (template-repo-local; not carried to downstream projects). |
| `.github/ISSUE_TEMPLATE/framework-gap.yml` | GitHub issue form for framework-gap reports. |
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
| `docs/agent-health-contract.md` | **Binding.** Failure modes, detection signals, health-check protocol, and respawn procedure for long-lived named teammates — including the triadic tech-lead self-diagnosis (project-manager / peer / customer backstop). |
| `docs/handovers/` | Respawn handover briefs (one per respawn, dated). Gitignored after 30 days by convention. |
| `docs/model-routing-guidelines.md` | Draft post-v1.0.0 guidance for agent model tier, effort, and plan-mode selection across OpenAI / ChatGPT and Claude / Claude Code. |
| `docs/v1.0-rc4-stabilization.md` | Triage and work-package plan for downstream issues #71-#83 before `v1.0.0` final. |

## `docs/adr/` (Framework Architecture Decision Records)

Framework ADRs use the `FW-ADR-NNNN` namespace and `fw-adr-NNNN-*.md`
filename prefix. Project ADRs use the bare `ADR-NNNN` namespace
(per FW-ADR-0007 / issue #67) and live alongside in `docs/adr/`,
indexed from `INDEX-PROJECT.md`.

ADRs follow MADR 3.0 + this template's binding Three-Path Rule
(Minimalist / Scalable / Creative) per
`docs/templates/adr-template.md`. Required sections in every ADR;
recommended sections may be omitted with a one-line rationale (per
FW-ADR-0006). Numbering is sequential within each namespace.

| File | Decision |
|---|---|
| `docs/adr/fw-adr-0001-context-memory-strategy.md` | Adopt `claude-mem`; orchestration frameworks require a superseding ADR per project. |
| `docs/adr/fw-adr-0002-upgrade-content-verification.md` | `TEMPLATE_MANIFEST.lock` per-file SHA256 manifest as primary trust anchor for `upgrade.sh --verify`; on-demand re-fetch as fallback. (v0.14.0.) |
| `docs/adr/fw-adr-0003-bare-template-variants.md` | Ship guided + bare template pair for `architecture-template` and `requirements-template`; bare ~50% smaller for fluent authors. (v0.14.0.) |
| `docs/adr/fw-adr-0004-per-item-file-breakout.md` | Per-FR / per-NFR / per-view files indexed from a thin top-level template; agents load only what's in scope. (v0.14.0.) |
| `docs/adr/fw-adr-0005-standards-paraphrase-cards.md` | Single `docs/standards/paraphrase-cards.md` file as the source for IEEE/ISO standards paraphrase content cited from agent contracts. (v0.14.0.) |
| `docs/adr/fw-adr-0006-madr-required-optional-split.md` | Adopt MADR's required / recommended / optional split in `adr-template.md`; small ADRs ~40 lines, full ADRs ~200+. (v0.14.0.) |
| `docs/adr/fw-adr-0007-external-reference-adoption.md` | Add LIB-0015..0018 (URL-only inventory rows for system-design-primer / jam01 templates / MADR); land "Inspire, don't paste" rule in glossary. **Note**: ADR-numbering split between framework (`FW-ADR-NNNN`, `fw-adr-NNNN-*.md`) and project (`ADR-NNNN`, plain `NNNN-*.md`) shipped in v0.15.0. |

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
| `docs/templates/adr-template.md` | MADR 3.0 + Three-Path Rule. ADRs filed under `docs/adr/`. |
| `docs/templates/architecture-template.md` | ISO/IEC/IEEE 42010:2022 + arc42 + C4 + IEEE 1016 viewpoint mapping. Guided variant. |
| `docs/templates/architecture-template-bare.md` | Bare variant of the above; structure only, no guidance prose. ~50% smaller. (v0.14.0+ per FW-ADR-0003.) |
| `docs/templates/architecture-view-template.md` | Per-view file template (one IEEE 1016 viewpoint per file under `docs/views/`). Guided. (v0.14.0+ per FW-ADR-0004.) |
| `docs/templates/architecture-view-template-bare.md` | Bare variant of the per-view template. (v0.14.0+.) |
| `docs/templates/handover-template.md` | Respawn handover brief. |
| `docs/templates/intake-log-template.md` | Customer-question intake log row. |
| `docs/templates/phase-template.md` | ISO/IEC/IEEE 12207:2017 life-cycle phase + IEEE 1012 V&V activity mapping. |
| `docs/templates/req-item-template.md` | Per-requirement file template (one FR/NFR per file under `docs/req/`). Guided. (v0.14.0+ per FW-ADR-0004.) |
| `docs/templates/req-item-template-bare.md` | Bare variant of the per-requirement template. (v0.14.0+.) |
| `docs/templates/requirements-template.md` | ISO/IEC/IEEE 29148:2018 requirements doc. Guided variant. |
| `docs/templates/requirements-template-bare.md` | Bare variant; structure only. ~50% smaller. (v0.14.0+ per FW-ADR-0003.) |
| `docs/templates/retrofit-playbook-template.md` | Migrating an existing codebase into a scaffolded project (v0.13.0+). |
| `docs/templates/scoping-questions-template.md` | Seed queue of Step-2 scoping questions. |
| `docs/templates/task-template.md` | INVEST + DoR + DoD + workflow-pipeline trigger annotation. |

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
| `security-engineer.md` | Security Engineer; SWEBOK V4 ch. 13 owner (§2.4c). |
| `onboarding-auditor.md` | Zero-context documentation auditor (one-shot, milestone-close). |
| `process-auditor.md` | Cultural-disruptor process auditor (one-shot, every 2–3 milestones). |
| `sme-template.md` | Scaffold for SME agents; copy to `sme-<domain>.md`. |
