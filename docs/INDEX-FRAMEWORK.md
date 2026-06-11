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
| `AGENTS.md` | Codex adapter for the same top-level `tech-lead` and specialist contracts that Claude Code consumes through `CLAUDE.md` and `.claude/agents/`. |
| `CLAUDE.md` | Claude Code entrypoint. Customer model, escalation protocol, agent roster, routing defaults, binding references, time-based cadences, hard rules, taxonomy discipline. Pointers out to `docs/FIRST_ACTIONS.md`, `docs/TEMPLATE_UPGRADE.md`, `docs/MEMORY_POLICY.md`, `docs/IP_POLICY.md`, `docs/framework-project-boundary.md`, `docs/sme/CONTRACT.md`. |
| `VERSION` | Current template version (SemVer). Downstream projects stamp `TEMPLATE_VERSION` from this. |
| `TEMPLATE_MANIFEST.lock` | Per-file SHA256 manifest of shipped files (per FW-ADR-0002, v0.14.0+). Written at scaffold; rewritten after every successful upgrade. Verified by `scripts/upgrade.sh --verify`. Files in `.template-customizations` are omitted. **Scaffolded into downstream projects, not present in the upstream template repo itself.** |
| `CHANGELOG.md` | Release history. MAJOR / MINOR / PATCH semantics. |
| `scripts/scaffold.sh` | Scaffolds a new downstream project from this template. Writes the initial `TEMPLATE_MANIFEST.lock` and self-verifies before exit. |
| `scripts/version-check.sh` | Session-start hook; compares `TEMPLATE_VERSION` against upstream and prints a banner if an upgrade is available. Pre-release tags filtered out for stable-track projects (issue #60). |
| `scripts/upgrade.sh` | Upgrades a scaffolded project to the selected template version. Respects user-added agents / SMEs; flags customized standard files for review. Subcommands: `--dry-run` (plan-only), `--verify` (offline drift + unresolved-conflict check against `TEMPLATE_MANIFEST.lock` and `.template-conflicts.json`), `--resolve` (prune resolved conflict records), `--target <ver>` (pin the upstream tag), `--self-test-semver` (template-maintenance SemVer-sort guard), `--help`. Accepted-local framework files may still need stale-reference review after upstream doc extraction. |
| `scripts/hooks/customer-notes-guard.py` | Claude Code PreToolUse hook that asks for confirmation before writes to `CUSTOMER_NOTES.md`, reinforcing librarian ownership of customer-answer entries. |
| `scripts/lib/manifest.sh` | Shared helpers for `TEMPLATE_MANIFEST.lock` (write / verify / ship-files enumeration / SHA256). Sourced by `upgrade.sh` and `scaffold.sh`. Per FW-ADR-0002. |
| `scripts/lib/first-actions.sh` | Shared FIRST ACTIONS detection helpers for session-start and upgrade warnings when Step-0 issue-feedback opt-in is missing. |
| `scripts/smoke-test.sh` | End-to-end sanity check on scaffold + version-check + upgrade + manifest verify contracts. Template-maintenance tool; not shipped to downstream projects. |
| `scripts/pre-release-gate.sh` | Pre-release upgrade-regression gate orchestrator (spec 007). Runs every registered sub-gate with fail-all semantics; precondition for tagging an annotated `v*` per FR-010. Pair with `.git-hooks/pre-push` for scoped-strict enforcement at push time. See `docs/pm/pre-release-gate-overrides.md` for the bypass audit log. |
| `scripts/agent-health.sh` | Assembles a health-check packet for a named teammate (ground-truth snapshot + fixed prompt). Per `docs/agent-health-contract.md` § 3. |
| `scripts/respawn.sh` | Stubs a handover-brief file and prints the respawn checklist. Per `docs/agent-health-contract.md` § 4. |
| `scripts/archive-registers.sh` | Rolls closed rows out of binding registers into per-quarter shard files (`<register>-YYYY-QN.md`). `--quarter-roll` triggers the date-quarter sharding model (FW-ADR-0025). `--include-customer-notes` required to archive customer-truth entries (safety opt-in). Owned by `librarian`. |
| `scripts/gen-register-index.sh` | (Re)generates `<register>-INDEX.md` — a cross-shard index of all entries across the active file and its quarter shards. Run after every `--quarter-roll`. Per FW-ADR-0025. |
| `docs/templates/handover-template.md` | Shape of a respawn handover brief. |
| `examples/README.md` | Catalog of filled-in reference projects (not shipped to downstream). |
| `migrations/README.md` | Per-version migration-script contract. Upstream-template file; stripped from scaffolded downstream projects. |
| `migrations/TEMPLATE.sh` | Scaffold for writing a new migration. Upstream-template file; stripped from scaffolded downstream projects. |
| `migrations/vX.Y.Z.sh` | Per-release migration (file moves / renames / shape changes); most releases do not ship one. Upstream-template files; stripped from scaffolded downstream projects. |
| `CONTRIBUTING.md` | How to propose changes to the template (template-repo-local; not carried to downstream projects). |
| `.github/ISSUE_TEMPLATE/framework-gap.yml` | GitHub issue form for framework-gap reports. |
| `CUSTOMER_NOTES.md` | Append-only log of customer answers, verbatim, stewarded by `librarian`. Active file (current quarter); older entries rolled to `CUSTOMER_NOTES-YYYY-QN.md` shards; `CUSTOMER_NOTES-INDEX.md` provides cross-shard lookup. Per FW-ADR-0025. |
| `README.md` | Human-facing overview of the template. |
| `SW_DEV_ROLE_TAXONOMY.md` | Binding role vocabulary (SWEBOK / ISO 12207 / IEEE 1028 / ISTQB / SFIA v9 / Google SRE / PMBOK). |

## `docs/`

| File | Purpose |
|---|---|
| `docs/INDEX.md` | This file. |
| `docs/AGENT_NAMES.md` | Canonical role → teammate name → pronouns mapping; rules for picking names and respecting pronouns. |
| `docs/FIRST_ACTIONS.md` | Session-1 setup flow (Steps 0–3a): issue-feedback opt-in, skill packs, scoping + SME discovery, agent naming. Extracted from `CLAUDE.md` per issue #120. |
| `docs/IP_POLICY.md` | Non-negotiable IP / copyright posture: external-material default, restricted-source clauses, AI-training narrow interpretation. Extracted from `CLAUDE.md` per issue #120. |
| `docs/MEMORY_POLICY.md` | Memory-layer + orchestration-framework stance (claude-mem default; orchestration frameworks require a superseding ADR). Extracted from `CLAUDE.md` per issue #120. |
| `docs/OPEN_QUESTIONS.md` | Register of open questions with ID / answerer / status / resolution. Stewarded by `librarian`. Active file (current quarter); older entries rolled to `docs/OPEN_QUESTIONS-YYYY-QN.md` shards; `docs/OPEN_QUESTIONS-INDEX.md` provides cross-shard lookup. Per FW-ADR-0025. |
| `docs/ISSUE_FILING.md` | Convention for filing framework gaps against the upstream template repo (includes template-version citation). |
| `docs/TEMPLATE_UPGRADE.md` | Scaffold + template version check + upgrade strategy + per-version migrations. Extracted from `CLAUDE.md` per issue #120. |
| `docs/agent-health-contract.md` | **Binding.** Failure modes, detection signals, health-check protocol, and respawn procedure for long-lived named teammates — including the triadic tech-lead self-diagnosis (project-manager / peer / customer backstop). |
| `docs/framework-project-boundary.md` | Practical downstream separation model: framework-managed paths, project-owned product paths, project-filled registers, and review / commit split guidance. |
| `docs/handovers/` | Respawn handover briefs (one per respawn, dated). Gitignored after 30 days by convention. |
| `docs/model-routing-guidelines.md` | Draft post-v1.0.0 guidance for agent model tier, effort, and plan-mode selection across OpenAI / ChatGPT and Claude / Claude Code. |
| `docs/RULE_AUTHORING_CHECKLIST.md` | Non-binding guidance checklist for anyone proposing a new hard rule or binding policy: enforcement design, testability, placement, mirrors, wording. Cross-references anti-proliferation concern from Q-0018. |

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
| `docs/adr/fw-adr-0001-context-memory-strategy.md` | Adopt `claude-mem` as the prior-session memory layer; orchestration frameworks require a superseding ADR per project. |
| `docs/adr/fw-adr-0002-upgrade-content-verification.md` | `TEMPLATE_MANIFEST.lock` per-file SHA256 manifest as primary trust anchor for `upgrade.sh --verify`; on-demand re-fetch as fallback. (v0.14.0.) |
| `docs/adr/fw-adr-0003-bare-template-variants.md` | Ship guided + bare template pair per template family so fluent authors can use the structure-only form. (v0.14.0.) |
| `docs/adr/fw-adr-0004-per-item-file-breakout.md` | Break requirements and architecture views into per-item files with a thin index; agents load only what's in scope. (v0.14.0.) |
| `docs/adr/fw-adr-0005-standards-paraphrase-cards.md` | Extract IEEE/ISO paraphrases into a single `docs/standards/paraphrase-cards.md` as the source for standards citations cited from agent contracts. (v0.14.0.) |
| `docs/adr/fw-adr-0006-madr-required-optional-split.md` | Split `adr-template.md` sections into MADR required, project required, and optional; small ADRs ~40 lines, full ADRs ~200+. (v0.14.0.) |
| `docs/adr/fw-adr-0007-external-reference-adoption.md` | Adopt LIB-0015..0018 (URL-only inventory rows); land "Inspire, don't paste" rule in glossary. **Note**: ADR-numbering split between framework (`FW-ADR-NNNN`) and project (`ADR-NNNN`) shipped in v0.15.0. |
| `docs/adr/fw-adr-0008-tech-lead-orchestration-boundary.md` | Tech-lead orchestrates; production artifacts and customer-truth records route to owning specialists (Hard Rule #8). |
| `docs/adr/fw-adr-0009-opencode-harness-adapter.md` | Classify OpenCode as a harness/provider adapter; it must not redefine roles, escalation, source-of-truth, or customer interface. |
| `docs/adr/fw-adr-0010-pre-bootstrap-local-edit-safety.md` | Pre-bootstrap uses a 3-SHA decision matrix with refuse-on-uncertain semantics and an explicit override env var. (Superseded by FW-ADR-0015/0019.) |
| `docs/adr/fw-adr-0011-routed-through-trailer.md` | `Routed-Through:` commit-trailer plus lint/hook/tool-bridge carve-out enforces Hard Rule #8; primary-enforcement framing superseded by FW-ADR-0012. |
| `docs/adr/fw-adr-0012-tech-lead-authoring-guard.md` | PreToolUse allow-list hook is the primary preventive enforcement for Hard Rule #8; supersedes FW-ADR-0011's primary-enforcement framing. |
| `docs/adr/fw-adr-0013-rc-to-rc-pre-bootstrap.md` | Add a versioned pre-bootstrap migration (`v1.0.0-rc13.sh`) cloned from `v0.14.0.sh` so rc-to-rc upgrades on pre-v0.15.0 drivers self-bootstrap safely. (Superseded by FW-ADR-0015/0019.) |
| `docs/adr/fw-adr-0014-preservation-vs-manifest.md` | Preservation honoured only on divergence-AND-non-manifest-fresh-write paths; upgrade tail emits a two-phase exit replacing single-line "Done." |
| `docs/adr/fw-adr-0015-upgrade-orchestrator-stub-model.md` | `scripts/upgrade.sh` becomes a stable sub-100-line stub; the real upgrade orchestrator is fetched fresh per invocation from upstream. Foundational ADR for the upgrade-flow rearchitecture; supersedes FW-ADR-0010 and FW-ADR-0013. |
| `docs/adr/fw-adr-0016-template-state-json-schema.md` | Defines `TEMPLATE_STATE.json` — the single project-owned state artefact consolidating version, manifest, customizations, and runner checksum into one declarative file. |
| `docs/adr/fw-adr-0017-file-keyed-migration-discovery.md` | Replaces tag-keyed migration enumeration with file-presence discovery in the runner's `migrations/` tree, semver-ordered against `TEMPLATE_STATE.json`. |
| `docs/adr/fw-adr-0018-transitional-rc-bridging.md` | One transitional in-tree rc bridges currently-deployed downstreams onto the FW-ADR-0015 stub model; consolidates legacy three-file project state into `TEMPLATE_STATE.json`. |
| `docs/adr/fw-adr-0019-pre-bootstrap-retirement.md` | Formally retires the pre-bootstrap class; marks FW-ADR-0010 and FW-ADR-0013 superseded; deprecates `SWDT_PREBOOTSTRAP_FORCE` env var and `.template-prebootstrap-blocked.json`. (Status: proposed.) |
| `docs/adr/fw-adr-0020-issues-based-coordination-model.md` | Replace GitHub Projects board with plain GitHub Issues (labels + milestones + optimistic-claim convention) as the v1.1.0 Half-B multi-machine coordination layer. |
| `docs/adr/fw-adr-0021-harness-agnostic-leaf-task-dispatch.md` | Single leaf T### task as the harness-agnostic dispatch unit; delegated-specialist mode added to `AGENTS.md`; machine-checked enforcement gate. Implemented: issue #293. |
| `docs/adr/fw-adr-0022-gemini-harness-adapter.md` | Classify gemini-cli as a co-equal harness adapter; `GEMINI.md` root adapter, `.gemini/agents/` generated roster, description-driven dispatch, three-surface drift control. Implemented: issue #300. |
| `docs/adr/fw-adr-0023-handoff-activity-array-growth.md` | Two coupled decisions on handoff JSON integrity: (1) deliberate hash-exclusion of the runtime-mutable `activity` array from manifest verification, and (2) disposition of unbounded growth via sidecar migration. |
| `docs/adr/fw-adr-0024-parallel-agent-working-tree-isolation.md` | Working-tree isolation strategy for parallel specialist agents: strict serialization (current interim), per-agent git worktrees, or read-only worktree for readers with a single canonical writer. |
| `docs/adr/fw-adr-0025-register-file-size-management.md` | Register file-size management: date-quarter sharding for binding registers that grow past the ~150 KB context limit; per-quarter shard files, a generated INDEX, and cross-shard ID-uniqueness tooling. Option S adopted. |

## `docs/glossary/`

| File | Purpose |
|---|---|
| `docs/glossary/ENGINEERING.md` | **Binding.** Generic software-engineering terminology. |
| `docs/glossary/PROJECT.md` | **Binding.** Project-specific terms (customer-domain, vendor, site, codenames). |

## `docs/sme/` (per domain)

| File | Purpose |
|---|---|
| `docs/sme/INVENTORY-template.md` | Template for the per-domain inventory. |
| `docs/sme/<domain>/INVENTORY.md` | External-material inventory for that domain. Stewarded by `librarian`. |
| `docs/sme/<domain>/local/` | Copyrighted external material; gitignored. |

## `docs/templates/` (standards-shaped document templates)

| File | Purpose |
|---|---|
| `docs/templates/adr-template.md` | MADR 3.0 + Three-Path Rule. ADRs filed under `docs/adr/`. |
| `docs/templates/architecture-template.md` | ISO/IEC/IEEE 42010:2022 + arc42 + C4. IEEE 1016-2009 viewpoint mapping with first-class sections for State dynamics (§9), Concurrency (§10), Information (§11), and Resource (§12). 42010 rationale chain in §1.1–§1.3. Guided variant. |
| `docs/templates/architecture-template-bare.md` | Bare variant of the above; structure only, no guidance prose. Heading set matches the guided variant (smoke-check enforced). (v0.14.0+ per FW-ADR-0003.) |
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
| `docs/templates/customer-note-entry-template.md` | Canonical shape for a single `CUSTOMER_NOTES.md` entry; enforced by `customer-notes-guard.py`. |
| `docs/templates/audit-brief-template.md` | Self-contained context bundle for milestone/release audits run by conversation-blind agents on any harness; ensures equivalent inputs across models for comparable, reconcilable findings. |
| `docs/templates/dispatch-template.md` | Structural aid for `tech-lead` dispatching a single task to a specialist; makes one-task-per-dispatch the default shape. Non-binding, no CI gate. |
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

## `.agents/` (Antigravity harness adapter — FW-ADR-0026)

| Path | Purpose |
|---|---|
| `.agents/agents.md` | Stub / redirect note. NOT loaded by Antigravity; real subagents live in `.agents/agents/<role>/agent.json`. |
| `.agents/rules/team-contract.md` | Always-active binding contract (`activation: always_on`). Contains Mode A, Mode B, MCP #289 rule, Hard Rules summary, escalation protocol, binding references. Hand-authored. |
| `.agents/agents/<role>/agent.json` | Per-role subagent (customAgent JSON schema confirmed from agy binary). **Deferred to SE follow-up — Q-0033.** |
| `.agents/skills/<role>/SKILL.md` | Per-role skill thin-adapter. **Schema disputed — Q-0033 (SKILL.md vs JSON path reference; two binary readings conflict).** |

## `.claude/agents/`

| File | Role (taxonomy §) |
|---|---|
| `tech-lead.md` | Tech Lead + sole human interface (§2.4b). |
| `project-manager.md` | PMBOK Project Manager (§2.9a). |
| `architect.md` | Software Architect (§2.4a). |
| `software-engineer.md` | Software Engineer / construction (§2.1). |
| `researcher.md` | Researcher — investigation, Tier-1 sourcing, prior-art scans, pronoun verification. |
| `librarian.md` | Librarian — record custodian: CUSTOMER_NOTES.md, OPEN_QUESTIONS.md, glossaries, SME inventories, archival. |
| `ui-ux-designer.md` | UX/UI Designer — interaction design, accessibility auditing (WCAG), accesslint integration (§2.10). |
| `mcp-liaison.md` | MCP Liaison — delegated MCP session construction + divergence reconciliation (custom, taxonomy §5). |
| `qa-engineer.md` | QA / Test Engineer (§2.2). |
| `sre.md` | SRE + Performance Engineer (§2.3). |
| `tech-writer.md` | Technical Writer (§2.5a). |
| `code-reviewer.md` | Code Reviewer + Auditor, IEEE 1028 (§2.7). |
| `release-engineer.md` | Build + Release Engineer (§2.8). |
| `security-engineer.md` | Security Engineer; SWEBOK V4 ch. 13 owner (§2.4c). |
| `onboarding-auditor.md` | Zero-context documentation auditor (one-shot, milestone-close). |
| `process-auditor.md` | Cultural-disruptor process auditor (one-shot, every 2–3 milestones). |
| `sme-template.md` | Scaffold for SME agents; copy to `sme-<domain>.md`. |

## `docs/agents/manual/` (canonical agent manuals)

| File | Role |
|---|---|
| `docs/agents/manual/librarian-manual.md` | `librarian` — CUSTOMER_NOTES entry format, archival mechanic, SME-inventory procedures, glossary amendment. |
| `docs/agents/manual/mcp-liaison-manual.md` | `mcp-liaison` — delegation protocol, brief shape, divergence-reconciliation format. |
| `docs/agents/manual/qa-engineer-manual.md` | `qa-engineer` — adversarial stance, Solution Duel, critical-path considerations. |
| `docs/agents/manual/release-engineer-manual.md` | `release-engineer` — release pipeline, dogfood sequencing. |
| `docs/agents/manual/researcher-manual.md` | `researcher` — restricted-source handling matrix, pronoun-verification procedure, archival sizing policy. |
| `docs/agents/manual/tech-lead-manual.md` | `tech-lead` — Customer Question Gate, Dispatch discipline, routing table, output discipline, agent health. |
| `docs/agents/manual/ui-ux-designer-manual.md` | `ui-ux-designer` — accesslint usage, WCAG citation format, design-feedback synthesis. |
