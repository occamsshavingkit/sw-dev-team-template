# Feature Specification: sw-dev-team-template improvement program (M0–M9)

**Feature Branch**: `004-m8-m10-plan` (working branch; not derived from spec dir — per the speckit contract, branch name and spec-dir name are independent. The spec dir `006-template-improvement-program` and the branch `004-m8-m10-plan` are intentionally decoupled.)
**Created**: 2026-05-13
**Status**: Draft
**Input**: User description: "there is an 11-milestone sprint description in sw_dev_template_implementation_plan-2.md that is for updating the sub-repo in ./sw-dev-team-template . You are in the meta project that uses a scaffolded template of the sub-repo to improve the sub-repo while leaving it clean for others to use. we are planning and implementing the sprint."

**Source plan**: `sw_dev_template_implementation_plan-2.md` (2026-05-10) at the meta-project root.

**Working-tree boundary**: All code, doc, schema, script, and ADR edits in this program land in the sub-repo at `./sw-dev-team-template`. The enclosing meta-project (`/home/quackdcs/SWEProj`) is a scaffolded consumer of the template used as a workshop; it owns only the planning artifacts (this spec, downstream plan/tasks, intake, schedule entries). The four named reference downstream repos (`QuackDCS`, `QuackPLC`, `QuackS7`, `QuackSim`) are external repair targets at M8 and are not edited from this working tree.

## Clarifications

### Session 2026-05-13

- Q: What is the "live" cutoff for register files (OPEN_QUESTIONS, intake-log, RISKS, LESSONS, CUSTOMER_NOTES where safe)? → A: Time-based — a row is live if it is open, or it was answered after the most recent milestone close; otherwise it belongs in the paired archive. This is the single binding cutoff used by both `scripts/archive-registers.sh` and the live-size lint.
- Q: When does G9 require customer approval, and through what mechanism? → A: MINOR-boundary Release events require customer sign-off in `CUSTOMER_NOTES.md` (v1.0.0 final qualifies); rc iteration tags do not. This aligns with the existing template policy that GitHub Releases are minted only at MINOR boundaries.
- Q: When does the question linter switch from warning-only to hard-gate? → A: At the next MINOR-boundary Release after the warning-only PR ships. Subsequent rc-iteration tags within the same cycle stay warning-only; the next MINOR (which could be v1.0.0 final) is the cutover.
- Q: Is the meta-project at `/home/quackdcs/SWEProj` itself in scope for M8 repair? → A: Out of scope. Meta-project is workshop-only; any later template-upgrade against the meta-project is a separate ticket opened after the program closes, not part of this sprint.
- Q: Is the M5.2 per-agent default-model table binding policy or example? → A: Binding default for fresh scaffolds; downstream projects may override in a marked project-local model-routing supplement without requiring a superseding ADR. The supplement must be flagged as a project-local override so the canonical table remains identifiable.
- Q: What is the protected-files list the M7 self-improvement workflow may not edit? → A: Authority-anchored set: `CLAUDE.md`, `AGENTS.md`, `.claude/agents/*.md`, `docs/adr/*.md`, `docs/framework-project-boundary.md`, `docs/model-routing-guidelines.md`, `.github/workflows/*.yml`, `migrations/`, `VERSION`, `TEMPLATE_MANIFEST.lock`, and any file containing a Hard Rule. The AI loop may only propose changes to these via a paired Markdown proposal under `docs/proposals/`.
- Q: What is the customer-authorization mechanism for mixed product/framework PRs at downstream repos (FR-030)? → A: A `CUSTOMER_NOTES.md` entry under a stable header `## Mixed-PR authorizations` listing each authorized task ID. The M8 boundary-check script greps for the task ID under that header; absence fails the gate.
- Q: What triggers a model fallback, and which model becomes the substitute? → A: Trigger on credit exhaustion OR provider unavailability (5xx, timeout, rate-limit). Substitute to the closest peer in the same model class (e.g., Sonnet-class → Sonnet-equivalent); if no peer is available, substitute one tier down. Substitution MUST NOT change role authority or output format, and every event is logged per FR-020.
- Q: Which artifacts does SC-014's release-notes classification cover? → A: The ship-set — files in the template's downstream ship-set (the files copied into a fresh scaffold per `TEMPLATE_MANIFEST.lock` plus the upgrade script's ship-files list). Internal-only files (tests, dev scripts) are out of scope for SC-014.
- Q: How is "sensitive content" defined for the FR-026 framework-gap issue redaction-confirmation field? → A: Tiered. Mandatory enumerated set: (i) customer or vendor identities and brand names, (ii) downstream project names, (iii) any `CUSTOMER_NOTES.md` content (verbatim or paraphrased), (iv) credentials, secrets, tokens, hostnames, IPs. Downstream repos MAY extend the set in their local `docs/IP_POLICY.md`; the issue template's lint greps for known downstream project names from the mandatory set.
- Q: What is the M7 AI-improvement loop's edit scope on live registers? → A: Asymmetric. AI may directly edit `docs/pm/SCHEDULE.md`, `docs/pm/LESSONS.md`, and `docs/pm/RISKS.md` (non-customer-truth surfaces). `CUSTOMER_NOTES.md`, `docs/OPEN_QUESTIONS.md`, and `docs/intake-log.md` are read-only and proposal-only — changes route through a paired Markdown proposal under `docs/proposals/`.
- Q: What is the M8 per-repo waiver mechanism for deferred deliverables (FR-029)? → A: Downstream repos file a GitHub issue against the template repo (`sw-dev-team-template`) for each waived deliverable, using the framework-gap issue template (FR-026) and taxonomy labels (FR-025). The M8 boundary check passes if either the deliverable was completed or an open template-repo issue references the deliverable and the downstream repo.
- Q: How does the question linter grandfather legacy compound rows when it hard-gates? → A: Date-cutoff: rows committed before the lint's hard-gate commit SHA are grandfathered; the cutoff SHA is recorded once in the lint script (`HARDGATE_AFTER_SHA=...`). Rows committed after that SHA are enforced. No allowlist file; historical customer interactions are not rewritten.
- Q: Which of the six G9 audit roles gate the release? → A: The four canonical audit roles — `code-reviewer`, `qa-engineer`, `release-engineer`, `project-manager` — produce blocking sign-off or a blocking-issue list. The two advisory audit roles — `onboarding-auditor` and `process-auditor` — produce findings that `tech-lead` routes to the customer for decision; their findings do not gate G9 by themselves. This matches each role's documented charter.

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Token economy quick wins land first (Priority: P1)

The team measures current recurring context cost (M0), then compacts agent runtime contracts, archives live registers, refactors the token ledger, and splits PM schedule live/evidence/archive surfaces (M1). After this slice, every session starts and dispatches with materially less context, freeing capacity for later workstreams.

**Why this priority**: The plan's §1 is explicit — token/context cost reduction is the enabling work. Every later milestone reuses the saved capacity. Without this slice, the rest of the program is more expensive and less safe. M0 alone delivers the baseline measurement; M0+M1 together deliver the first measurable savings, which is the minimum viable shipment.

**Independent Test**: Run a baseline measurement pass (line/token counts on `.claude/agents/*.md`, live registers, `docs/pm/SCHEDULE.md`, downstream `TEMPLATE_VERSION`), apply M1 changes in the sub-repo, re-measure, and confirm the largest live context surfaces shrank or have an accepted-and-scheduled reduction path. Generated runtime-contract candidates exist for at least one core agent and `code-reviewer` confirms no hard rule was lost.

**Acceptance Scenarios**:

1. **Given** the sub-repo at its current state, **When** the team runs the baseline measurement script, **Then** `docs/pm/token-economy-baseline.md` is produced with per-agent line/token counts, live-register row counts, PM schedule length, downstream intake-log presence, and downstream `TEMPLATE_VERSION` values.
2. **Given** the baseline report exists, **When** the team generates compact runtime contracts for at least `tech-lead`, `researcher`, `code-reviewer`, and `qa-engineer`, **Then** prompt-regression tests against those compact contracts pass, no hard rule is lost, and a before/after token/line report is recorded.
3. **Given** large live registers exist (`docs/OPEN_QUESTIONS.md`, `docs/intake-log.md`, `docs/pm/RISKS.md`, `docs/pm/LESSONS.md`, and `CUSTOMER_NOTES.md` where safe), **When** `scripts/archive-registers.sh` runs against terminal rows older than one milestone close, **Then** stable rows move to append-only archive files, live files keep a compact tombstone summary, and traceability is preserved through archive pointers.
4. **Given** `TOKEN_LEDGER.md` currently stores verbatim prompts inline, **When** the new schema is adopted, **Then** the live ledger holds only `Date | Task ID | Agent | Prompt hash | Prompt class | Token budget | Token actual | Notes`, and full prompts (if retained) live under `docs/pm/token-ledger/prompts/<task-id>-<agent>.md`.
5. **Given** `docs/pm/SCHEDULE.md` mixes current plan with closure evidence, **When** the live/evidence/archive split is applied, **Then** `SCHEDULE.md` carries only the live plan and `SCHEDULE-EVIDENCE.md` plus `SCHEDULE-ARCHIVE.md` carry the rest.

---

### User Story 2 — Token operating model plus atomic-question and intake repair (Priority: P2)

The team makes token economy ongoing (task-template token budgets, PM delta passes, memory-first query patterns — M2) and repairs the customer-question protocol and intake logging (M3) so that the savings are durable and the most visible customer-facing defect — compound questions — is prevented in new work.

**Why this priority**: M2 turns the one-time M1 cleanup into a habit; M3 fixes a defect that has already harmed customer trust in active downstream repos. Both are cheap to ship after M1 and both must precede cross-AI routing (M5) because routing decisions and customer questions are intertwined with the question protocol.

**Independent Test**: After this slice, a fresh scaffold includes `docs/intake-log.md`, a sample task template carries `Token budget` / `JIT file list` / `Token actual` fields, the question linter flags known bad historical patterns (warning-only), `tech-lead.md` carries the Customer Question Gate, and `docs/MEMORY_POLICY.md` plus `tech-lead.md` and `researcher.md` carry concrete memory-first query patterns.

**Acceptance Scenarios**:

1. **Given** the current `docs/templates/task-template.md`, **When** M2.1 is applied, **Then** the template includes `Token budget` (tiny/small/medium/large/XL), `JIT file list`, and `Token actual` fields with budget-band guidance.
2. **Given** an existing PM session, **When** the PM delta pass procedure is invoked, **Then** the agent reads only changed files, merged PR titles, current milestone row, changed open-question rows, and risk/change deltas — and produces either a no-op confirmation or minimal edits, not a full reread.
3. **Given** binding docs (`docs/MEMORY_POLICY.md`, `tech-lead.md`, `researcher.md`), **When** M2.3 is applied, **Then** concrete memory-first query patterns are listed for the cases enumerated in the plan (customer-decision lookup, current-milestone blocker, similar prior answer, accepted ADR).
4. **Given** the current seed scoping questions, **When** M3.1 is applied, **Then** every seed row has exactly one decision axis and no compound asks remain.
5. **Given** `CLAUDE.md`, `FIRST_ACTIONS.md`, `tech-lead.md`, `OPEN_QUESTIONS.md`, and `intake-log-template.md`, **When** M3.2 is applied, **Then** all five carry the same atomic-question-batching rule verbatim (queue internally; ask one externally; final line; all idle).
6. **Given** `tech-lead.md`, **When** M3.3 is applied, **Then** the Customer Question Gate is present near the top with the four checks (customer-owned / atomic / all idle / final line) and a queue-if-fail action.
7. **Given** `scripts/lint-questions.sh`, **When** it runs against the repo, **Then** compound seed questions, customer questions with multiple numbered items, multiple independent option sets, non-empty `agents-running-at-ask`, and compound `OPEN_QUESTIONS.md` rows are flagged at warning level for one release cycle, then hard-gated.
8. **Given** a fresh scaffold or a retrofit pass, **When** M3.5 is applied, **Then** `docs/intake-log.md` is created if missing and a QA intake-conformance audit passes on the four reference downstream repos.

---

### User Story 3 — Documentation authority and drift control (Priority: P3)

The team adds a short Documentation Authority Policy, removes downstream roadmap leakage from upstream-template release planning, resolves the draft-vs-binding status of `docs/model-routing-guidelines.md`, and moves binding workflow-pipeline rules out of excluded proposal docs into a shipped canonical file (M4).

**Why this priority**: This slice is a prerequisite for safe cross-AI routing (M5) and Markdown compilation (M6) because both depend on a clear answer to "which file is the source of truth?". It is cheaper to ship before M5/M6 than to retrofit during them.

**Independent Test**: A fresh downstream scaffold does not expose upstream-template release planning as the project's root roadmap; `docs/model-routing-guidelines.md` is unambiguously binding or unambiguously not; no downstream-shipped file references an excluded proposal doc for binding rules.

**Acceptance Scenarios**:

1. **Given** `docs/framework-project-boundary.md`, **When** M4.1 is applied, **Then** the Documentation Authority Policy is present: every artifact is canonical/generated/ephemeral; manual mirrors are prohibited; shared content is generated, linked, or removed.
2. **Given** a downstream scaffold, **When** M4.2 is applied, **Then** either no root `ROADMAP.md` ships downstream, or the upstream-template roadmap lives at `docs/template/ROADMAP.md`, or a project-local roadmap stub replaces it — and retrofit guidance is documented.
3. **Given** the current `docs/model-routing-guidelines.md`, **When** M4.3 is applied, **Then** the file's binding status is explicit and exact model IDs carry a runtime-reverification marker.
4. **Given** binding rules currently referenced inside `docs/proposals/workflow-redesign-v0.12.md`, **When** M4.4 is applied, **Then** those rules live in `docs/workflow-pipeline.md` and no shipped file depends on the excluded proposal doc.

---

### User Story 4 — Cross-AI / OpenCode / Gemini routing as adapter (Priority: P4)

The team adds OpenCode harness support, Gemini and OpenAI model routing, and thin generated agent adapters — strictly as an adapter over the existing role roster, not as a parallel orchestrator (M5).

**Why this priority**: Adds capability without changing the agent contract surface. Must come after M4 (authority is clear) so the adapter has unambiguous canonical inputs. Must come before M6 because the Markdown compiler's first non-trivial generated target is the OpenCode adapter set.

**Independent Test**: ADR `fw-adr-0009-opencode-harness-adapter.md` exists and classifies OpenCode as adapter-only. `docs/model-routing-guidelines.md` lists OpenCode/Gemini conventions, fallback behavior, and frontier-escalation rules. Fallback log entries record `agent / requested_model / actual_model / fallback_reason / timestamp / task_id`. Generated thin adapters point to `.claude/agents/*.md` plus optional local supplements; no duplicated full role text exists.

**Acceptance Scenarios**:

1. **Given** no ADR exists yet for OpenCode, **When** M5.1 is applied, **Then** the ADR is accepted and explicitly states OpenCode is adapter-only, configures models/providers/commands/thin wrappers, and must not redefine roles, escalation, or the customer interface.
2. **Given** the current `docs/model-routing-guidelines.md`, **When** M5.2 is applied, **Then** the file carries the per-agent default-class table, OpenCode provider/model ID convention, Gemini model classes, fallback behavior, and frontier-only escalation rules.
3. **Given** any model fallback occurs, **When** the harness records it, **Then** the entry contains the six required fields and does not change role authority or output format.
4. **Given** thin OpenCode adapters are generated, **When** the generator runs, **Then** each adapter reads `.claude/agents/<role>.md` plus an optional local supplement, acts only as that role, and contains no duplicated full role text; manual edits to generated adapters fail lint.

---

### User Story 5 — Markdown compiler / runtime contract pipeline (Priority: P5)

The team defines JSON schemas for agent contracts, model routing, and generated artifacts; ships an agent-contract linter and a runtime-contract compiler; and adds prompt-regression tests for core agents (M6).

**Why this priority**: Locks in M1's compaction work as a reproducible pipeline rather than a one-time edit. Must come after M5 so the compiler's adapter target is well-defined. Must come before M7 because self-improvement automation depends on agent-contract lint as a gate.

**Independent Test**: `schemas/agent-contract.schema.json`, `schemas/model-routing.schema.json`, and `schemas/generated-artifact.schema.json` validate canonical inputs. `scripts/lint-agent-contracts.sh` flags out-of-band frontmatter, missing sections, malformed escalation/hard-block/local-supplement/customer-interface/output-format/allowed-tools rules. `scripts/compile-runtime-agents.sh` produces reproducible output; prompt-regression tests pass against both source and compiled runtime contracts.

**Acceptance Scenarios**:

1. **Given** an agent contract file with invalid frontmatter, **When** the linter runs, **Then** the file is rejected with a specific diagnostic.
2. **Given** the canonical agent contracts, **When** the compiler runs twice in succession, **Then** output is byte-identical and stable.
3. **Given** the prompt-regression cases listed in the plan (compound customer question, specialist-owned work, queued agent slot, ADR conflict, missing tests, traceability gap, missing regression test, acceptance ambiguity, restricted source, missing source, customer-note stewardship, stale schedule delta, no-op PM pass), **When** they run against the runtime contracts, **Then** all pass.
4. **Given** source canonical files, **When** the compiler runs, **Then** source remains authoritative — the compiler does not silently rewrite hard rules and does not hide harness differences.

---

### User Story 6 — Self-improvement loop and issue-driven evolution (Priority: P6)

The team adds an issue taxonomy, a framework-gap issue template, and an AI-improvement workflow that filters issues, clusters them, proposes one change, validates, and opens a PR — never pushing directly to `main` (M7).

**Why this priority**: Multiplies the value of every preceding milestone (issues become improvements), but is also the most dangerous if M0–M6 have not landed. Strictly gated behind G6.

**Independent Test**: GitHub issue labels for the listed taxonomy exist. A framework-gap issue template requires the listed fields. A workflow run with mock issues opens a single PR, runs contract checks before PR creation, does not edit protected files, and produces a no-op or new issue on failure rather than a broken commit.

**Acceptance Scenarios**:

1. **Given** the GitHub label set, **When** M7.1 is applied, **Then** all listed labels exist: `template-gap`, `template-friction`, `authority-drift`, `docs-drift`, `agent-contract`, `atomic-question`, `model-routing`, `token-economy`, `process-breakdown`, `traceability-gap`, `generalization-risk`, `ai-behavior`.
2. **Given** a new framework-gap issue, **When** the template is used, **Then** required fields are present: template version, downstream repo/project context, affected layer, observed behavior, expected behavior, redaction confirmation, proposed acceptance criteria.
3. **Given** the AI improvement workflow runs, **When** a batch of issues is processed, **Then** the workflow proposes exactly one improvement per run, opens a PR (never pushes to `main`), respects patch-size limits, runs generated-artifact drift checks, and routes failure modes to no-op or issue creation.
4. **Given** the four hardened GitHub Actions (`agent-contract-check.yml`, `question-lint.yml`, `template-contract-smoke.yml`, `improve-template.yml`), **When** a PR opens, **Then** the first three gate the PR and the fourth runs manually or on schedule only after G6.

---

### User Story 7 — Downstream rollout and retrofit repair (Priority: P7)

The team applies the improved template to `QuackDCS`, `QuackPLC`, `QuackS7`, and `QuackSim` one repo at a time, runs the per-repo repair sequence, and records each repair in the PM change log (M8).

**Why this priority**: This is where customers feel the program. All preceding milestones converge here, but rolling out earlier would either ship rough work or churn each downstream repo multiple times.

**Independent Test**: Each of the four reference repos either passes the rollout gate (no missing required framework files; live context surfaces respect the live-bound rule — open rows plus rows answered after the most recent milestone close — per spec Clarifications session 2026-05-13 bullet 1, or have a waiver; atomic-question lint warnings either fixed or documented as historical exceptions; product/framework boundary respected) or has a documented exception. Rollout lessons are captured upstream and the new-scaffold smoke test reflects what was learned.

**Acceptance Scenarios**:

1. **Given** each repo (`QuackDCS`, `QuackPLC`, `QuackS7`, `QuackSim`), **When** the repair sequence runs, **Then** scaffold/upgrade repair checks pass, `docs/intake-log.md` exists, large live registers are archived, root `ROADMAP.md` is fixed or quarantined if it carries upstream-template material, PM live/evidence split is applied if oversized, question lint runs, and the template upgrade is recorded in the repo's PM change log.
2. **Given** a downstream repo has product work in flight, **When** the rollout PR is prepared, **Then** product work and framework maintenance are not mixed in the same PR unless the customer explicitly authorized it.
3. **Given** all four repos have been processed, **When** the rollout retro runs, **Then** lessons learned are appended upstream and the scaffold smoke test reflects them.

---

### User Story 8 — v1.0 readiness and release gate (Priority: P8)

The team runs the full conformance audit (code-reviewer, qa-engineer, release-engineer, project-manager, onboarding-auditor, process-auditor) and meets the release criteria for tagging the template's v1.0 candidate (M9).

**Why this priority**: Final gate; nothing depends on it inside the program. The customer-facing payoff: an externally-usable template release where canonical/generated/ephemeral classification, agent contracts, question discipline, model routing, and downstream rollout are all in known-good states.

**Independent Test**: All listed release criteria are met (fresh-scaffold smoke, retrofit smoke on fixtures or downstream repos, agent-contract lint pass, question-lint pass on templates, generated artifacts up to date, no unresolved high-priority authority-drift issues, model-routing currentness, release notes that classify artifacts), and Gate G9 sign-offs are recorded from code-reviewer, qa-engineer, release-engineer, project-manager, plus the customer approval the template's release policy requires.

**Acceptance Scenarios**:

1. **Given** the template at G8 close, **When** the full conformance audit dispatches, **Then** the four canonical audit roles (`code-reviewer`, `qa-engineer`, `release-engineer`, `project-manager`) produce blocking sign-off or a blocking-issue list, and the two advisory audit roles (`onboarding-auditor`, `process-auditor`) produce findings that `tech-lead` routes to the customer for decision (their findings do not gate G9 by themselves).
2. **Given** every release criterion in §M9.2, **When** the release gate runs, **Then** each criterion is verified and recorded.
3. **Given** the release-gate sign-offs, **When** the customer approval condition is checked, **Then** approval is obtained per the template's release policy and recorded in `CUSTOMER_NOTES.md`.

---

### Edge Cases

- **Runtime compaction would drop a hard rule.** Schema check plus `code-reviewer` audit plus prompt regression tests must hold; revert/rework rather than ship. The compiler must not silently rewrite hard rules.
- **Archive script over-archives a still-open row.** Archives are append-only and live files keep a tombstone with an archive pointer; the row is recoverable.
- **The four reference downstream repos have product work that conflicts with framework upgrade.** Product/framework boundary check fails the PR; one-repo-at-a-time policy contains blast radius; mixing requires explicit customer authorization.
- **Gemini, OpenAI, or Claude model IDs change mid-sprint.** Routing guidelines use model classes; exact model IDs are runtime-reverifiable and re-verified before each release.
- **OpenCode tries to become a parallel orchestrator.** ADR classifies it as adapter-only; lint forbids manual edits to generated adapters; canonical role text is never duplicated into `.opencode` files.
- **Markdown compiler (LLMD or similar) changes semantics between versions.** Source files remain canonical; generated diff is reviewed; compiler is pinned per release.
- **Question linter produces false positives on legacy rows.** Warning-only for one release cycle (M3.4) before hard-gating; historical exceptions are documented rather than rewritten.
- **PM cadence pressure tempts a full reread instead of a delta pass.** PM docs explicitly prefer delta passes; cadence is session-anchored and run-once, not backlogged.
- **A downstream `OPEN_QUESTIONS.md` carries closed-but-unarchived rows that are needed for upcoming customer interaction.** Recent answered rows stay live; only terminal rows older than one milestone close move to archive.
- **The meta-project itself drifts because it is treated as a workshop, not a downstream consumer.** Scope is explicit: meta-project is workshop; it is not in the M8 reference-repo set; framework-managed files in the meta-project follow the same product/framework boundary rules during this program.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Every new or modified artifact in this program MUST be classified as canonical, generated, or ephemeral; manual mirrors of the same content across files are prohibited.
- **FR-002**: The program MUST produce a baseline token-economy report (`docs/pm/token-economy-baseline.md` in the sub-repo) measuring per-agent contract line/token count, live-register row count, answered-but-still-live row count, PM schedule length, downstream intake-log presence, broken internal references, and downstream `TEMPLATE_VERSION` values, before any compaction work begins.
- **FR-003**: The program MUST generate compact runtime contracts under `docs/runtime/agents/` separate from human-readable manuals under `docs/agents/manual/`, and MUST preserve every hard rule, escalation format, output format, and hard-block from the canonical contracts.
- **FR-004**: The program MUST ship `scripts/archive-registers.sh` and apply it so that `docs/OPEN_QUESTIONS.md`, `docs/intake-log.md`, `docs/pm/RISKS.md`, `docs/pm/LESSONS.md`, and `CUSTOMER_NOTES.md` (where safe) keep only open and recently-answered rows live, with terminal rows older than one milestone close moved to append-only archive files plus an archive pointer.
- **FR-005**: The program MUST replace the live `TOKEN_LEDGER.md` schema with `Date | Task ID | Agent | Prompt hash | Prompt class | Token budget | Token actual | Notes`, and MUST relocate verbatim prompts to optional archive files under `docs/pm/token-ledger/prompts/<task-id>-<agent>.md`.
- **FR-006**: The program MUST split `docs/pm/SCHEDULE.md` into live plan plus `SCHEDULE-EVIDENCE.md` plus `SCHEDULE-ARCHIVE.md`, with the live file carrying current plan only.
- **FR-007**: The program MUST add `Token budget`, `JIT file list`, and `Token actual` fields to `docs/templates/task-template.md` with documented band semantics (tiny / small / medium / large / XL).
- **FR-008**: The program MUST define a PM delta-pass procedure consuming changed files, merged PR titles, current milestone row, changed open-question rows, and risk/change deltas — producing either a no-op or minimal edits — and MUST document this preference over full rereads in `project-manager.md`.
- **FR-009**: The program MUST add concrete memory-first query patterns to `docs/MEMORY_POLICY.md`, `.claude/agents/tech-lead.md`, and `.claude/agents/researcher.md`, while keeping memory pointer-only (not authority).
- **FR-010**: The program MUST rewrite every seed scoping question so each row has exactly one decision axis, with internal queuing of multi-axis customer questions and external asking of exactly one atomic question per turn.
- **FR-011**: The program MUST add a Customer Question Gate near the top of `.claude/agents/tech-lead.md` enforcing four checks (customer-owned / atomic / all idle / final line) and a queue-if-fail action.
- **FR-012**: The program MUST ship `scripts/lint-questions.sh` flagging compound seed questions, customer questions with multiple numbered items, multiple independent option sets, non-empty `agents-running-at-ask`, and compound `OPEN_QUESTIONS.md` rows; warning-only on initial landing, hard-gated at the next MINOR-boundary Release after the warning-only PR ships (rc-iteration tags within that cycle remain warning-only). At hard-gate time, the lint MUST grandfather rows committed before a recorded `HARDGATE_AFTER_SHA` cutoff (set once in the lint script) and enforce only rows committed after that SHA; legacy customer interactions MUST NOT be rewritten.
- **FR-013**: The program MUST ensure every fresh scaffold and every retrofit pass creates `docs/intake-log.md` if missing, and MUST pass a QA intake-conformance audit on the four reference downstream repos.
- **FR-014**: The program MUST add a Documentation Authority Policy to `docs/framework-project-boundary.md` (canonical / generated / ephemeral; manual mirrors prohibited; shared content is generated, linked, or removed).
- **FR-015**: The program MUST prevent upstream-template release planning from appearing as the root `ROADMAP.md` of a fresh downstream scaffold, and MUST document retrofit guidance for repos that already carry such a file.
- **FR-016**: The program MUST mark `docs/model-routing-guidelines.md` unambiguously as binding or non-binding, and MUST flag exact model IDs as runtime-reverifiable before each release.
- **FR-017**: The program MUST move binding workflow-pipeline rules out of `docs/proposals/workflow-redesign-v0.12.md` into `docs/workflow-pipeline.md`, with no downstream-shipped file depending on the excluded proposal doc for binding rules.
- **FR-018**: The program MUST ship an OpenCode harness-adapter ADR at `docs/adr/fw-adr-0009-opencode-harness-adapter.md` declaring OpenCode adapter-only with no redefinition of role roster, escalation chain, or customer interface.
- **FR-019**: The program MUST extend `docs/model-routing-guidelines.md` with OpenCode provider/model ID convention, Gemini model classes, fallback behavior, frontier-escalation rules, and the per-agent default-class table; the table is the binding default for fresh scaffolds, and downstream projects MAY override it in a marked project-local model-routing supplement without requiring a superseding ADR, provided the supplement is flagged as a project-local override.
- **FR-020**: The program MUST log every model fallback with `agent`, `requested_model`, `actual_model`, `fallback_reason`, `timestamp` (ISO 8601), and `task_id`; fallback MUST NOT change role authority or output format. Fallback MUST trigger on credit exhaustion OR provider unavailability (5xx, timeout, rate-limit) and MUST substitute to the closest peer in the same model class; if no peer is available, the wrapper substitutes one tier down and records the downgrade in `fallback_reason`.
- **FR-021**: The program MUST generate thin OpenCode adapters that read `.claude/agents/<role>.md` plus an optional local supplement and contain no duplicated full role text; manual edits to generated adapters MUST fail lint.
- **FR-022**: The program MUST define `schemas/agent-contract.schema.json`, `schemas/model-routing.schema.json`, and `schemas/generated-artifact.schema.json`, validating frontmatter, required sections, escalation format, hard-block conditions, local-supplement rule, customer-interface rule, output format, and allowed tools.
- **FR-023**: The program MUST ship `scripts/lint-agent-contracts.sh` and `scripts/compile-runtime-agents.sh`; the compiler MUST be deterministic and reproducible, and MUST NOT become source of truth, silently rewrite hard rules, or hide harness differences.
- **FR-024**: The program MUST run prompt-regression tests on `tech-lead`, `code-reviewer`, `qa-engineer`, `researcher`, and `project-manager` against both canonical source and compiled runtime contracts.
- **FR-025**: The program MUST add the issue-taxonomy labels listed in the plan (`template-gap`, `template-friction`, `authority-drift`, `docs-drift`, `agent-contract`, `atomic-question`, `model-routing`, `token-economy`, `process-breakdown`, `traceability-gap`, `generalization-risk`, `ai-behavior`).
- **FR-026**: The program MUST add a framework-gap issue template requiring template version, downstream repo/project context, affected layer, observed behavior, expected behavior, redaction confirmation, and proposed acceptance criteria. "Sensitive content" requiring redaction is the mandatory enumerated set — (i) customer or vendor identities and brand names, (ii) downstream project names, (iii) any `CUSTOMER_NOTES.md` content (verbatim or paraphrased), (iv) credentials, secrets, tokens, hostnames, IPs — and downstream repos MAY extend the set in a local `docs/IP_POLICY.md`. The issue-template lint greps for known downstream project names from the mandatory set.
- **FR-027**: The program MUST implement the self-improvement workflow (issues → filter → cluster → propose one change → validate → PR) so that at most one improvement ships per run, no push targets `main`, the protected-files set is not edited directly, patch size is limited, generated-artifact drift checks run, and human PR review is required. The protected-files set is: `CLAUDE.md`, `AGENTS.md`, `.claude/agents/*.md`, `docs/adr/*.md`, `docs/framework-project-boundary.md`, `docs/model-routing-guidelines.md`, `.github/workflows/*.yml`, `migrations/`, `VERSION`, `TEMPLATE_MANIFEST.lock`, and any file containing a Hard Rule. The customer-truth set — `CUSTOMER_NOTES.md`, `docs/OPEN_QUESTIONS.md`, `docs/intake-log.md` — is also read-only to the AI loop. Changes to either set MUST take the form of a paired Markdown proposal under `docs/proposals/` (no direct edit by the AI loop). The AI loop MAY directly edit non-customer-truth live registers (`docs/pm/SCHEDULE.md`, `docs/pm/LESSONS.md`, `docs/pm/RISKS.md`) when fixing lint issues or closing stale rows.
- **FR-028**: The program MUST ship GitHub Actions `agent-contract-check.yml`, `question-lint.yml`, `template-contract-smoke.yml`, and `improve-template.yml` (manual or scheduled, post-G6).
- **FR-029**: The program MUST repair the four reference downstream repos (`QuackDCS`, `QuackPLC`, `QuackS7`, `QuackSim`) one repo at a time per the M8.2 sequence. For any deliverable that cannot be completed in this program, the downstream repo MUST file a GitHub issue against the template repo (`sw-dev-team-template`) using the framework-gap issue template (FR-026) and taxonomy labels (FR-025), naming both the deliverable and the downstream repo. The M8 boundary check passes for a deliverable if it was completed or if an open template-repo issue references both.
- **FR-030**: The program MUST keep product work and framework maintenance in separate PRs at each downstream repo unless the customer explicitly authorizes mixing for a given task. Authorization MUST be recorded as a task-ID entry under the stable header `## Mixed-PR authorizations` in the affected repo's `CUSTOMER_NOTES.md`; the M8 boundary-check script greps for the task ID under that header and fails the gate if absent.
- **FR-031**: The program MUST pass the M9 release criteria — fresh-scaffold smoke, retrofit smoke on reference repos or fixtures, agent-contract lint, question lint on templates, generated artifacts up-to-date, no unresolved high-priority authority-drift issues, model-routing currentness with runtime-verifiable model IDs, release notes that distinguish canonical / generated / ephemeral.
- **FR-032**: The program MUST obtain G9 sign-offs from `code-reviewer`, `qa-engineer`, `release-engineer`, `project-manager`, plus customer sign-off recorded in `CUSTOMER_NOTES.md` at the v1.0.0 final tag (a MINOR-boundary Release event); rc iteration tags between G9 acceptance and the final tag do not require additional customer approval.
- **FR-033**: The program MUST sequence PRs along the slicing in §5 of the plan (PR-1 through PR-16+), with no OpenCode, LLMD, or self-improvement automation work starting before Gate G1.

### Constitution Alignment *(mandatory)*

- **CA-001**: Source authority MUST be classified for affected artifacts as canonical, generated, or ephemeral. The plan's §2.2 makes this the program's central invariant; FR-001, FR-003, FR-014, and FR-021 carry it.
- **CA-002**: Customer-owned requirements MUST cite a recorded customer answer, a documented assumption, or one queued atomic question. The customer accepted this program by selecting `sw_dev_template_implementation_plan-2.md` as the active sprint; downstream customer-owned decisions (e.g., M5 fallback policy specifics, M8 per-repo exception waivers, M9 release-approval handling) route through `tech-lead` as atomic questions when not already in `CUSTOMER_NOTES.md`.
- **CA-003**: Framework-managed file edits MUST be marked as framework work and require explicit authorization unless this feature is a template-maintenance task. This program is a template-maintenance task; the customer has authorized framework edits in `./sw-dev-team-template`. The enclosing meta-project's framework files remain off-limits unless an explicit upgrade pass is opened separately.
- **CA-004**: Cross-AI or generated-output changes MUST preserve existing role authority and identify canonical inputs. FR-018, FR-021, FR-023, and FR-024 carry this for OpenCode adapters, compiled runtime contracts, and the prompt-regression set.

### Key Entities

- **Canonical artifact**: Human-maintained source of truth — `.claude/agents/*.md`, `CLAUDE.md`, `AGENTS.md`, ADRs under `docs/adr/`, `CUSTOMER_NOTES.md`, `docs/model-routing-guidelines.md`.
- **Generated artifact**: Derived from canonical sources, never manually edited — compact runtime prompts under `docs/runtime/agents/`, OpenCode adapters, generated `AGENTS` summaries, memory summaries.
- **Ephemeral artifact**: Temporary work product or transcript, not authoritative unless promoted — scratch audits, run logs, temporary handoff notes.
- **Live register**: Bounded current-state file kept short by archival — `OPEN_QUESTIONS.md`, `CUSTOMER_NOTES.md`, `intake-log.md`, `RISKS.md`, `LESSONS.md`, `SCHEDULE.md`. **Live-bound rule**: a row is live iff it is open, or it was answered after the most recent milestone close; otherwise it belongs in the paired archive.
- **Archive**: Append-only history file paired with a live register — `OPEN_QUESTIONS-ARCHIVE.md`, `customer-notes-archive.md`, `intake-log-ARCHIVE.md`, `RISKS-ARCHIVE.md`, `LESSONS-ARCHIVE.md`, `SCHEDULE-ARCHIVE.md`.
- **Token ledger entry**: Row with `Date | Task ID | Agent | Prompt hash | Prompt class | Token budget | Token actual | Notes`; verbatim prompt (if retained) lives under `docs/pm/token-ledger/prompts/<task-id>-<agent>.md`.
- **Agent contract**: Role-defining file carrying frontmatter, required sections, escalation format, hard rules, hard-block conditions, local-supplement rule, customer-interface rule, output format, and allowed-tools list.
- **OpenCode adapter**: Thin generated wrapper referencing `.claude/agents/<role>.md` plus optional local supplement; no duplicated role text.
- **Fallback log entry**: Record of a model substitution carrying `agent`, `requested_model`, `actual_model`, `fallback_reason`, `timestamp`, `task_id`.
- **Question lint rule**: Check against compound seed, multi-axis customer question, multi-option-set bundle, non-empty `agents-running-at-ask`, compound `OPEN_QUESTIONS.md` row.
- **Gate (G0–G9)**: Pass-criteria predicate over a milestone's deliverables; no later milestone starts until the prior gate passes.
- **Reference downstream repo**: One of `QuackDCS`, `QuackPLC`, `QuackS7`, `QuackSim` — the four targets of M8 retrofit repair.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `tech-lead` runtime-contract token count is reduced by at least 30% versus the M0 baseline (compact form).
- **SC-002**: Other core agent runtime-contract token counts (`architect`, `software-engineer`, `code-reviewer`, `qa-engineer`, `researcher`, `project-manager`, `tech-writer`, `release-engineer`, `security-engineer`, `sre`) are reduced by at least 20% versus the M0 baseline where safe; any exception is justified and recorded.
- **SC-003**: After G1, live `OPEN_QUESTIONS.md` files in the sub-repo and the four reference repos contain only open and recently-answered rows; no terminal row older than one milestone close remains live.
- **SC-004**: After G1, the live `docs/pm/SCHEDULE.md` contains the current plan only; closure evidence is relocated to `SCHEDULE-EVIDENCE.md` and `SCHEDULE-ARCHIVE.md`.
- **SC-005**: After G3, the count of new atomic-question violations (per the question linter's hard-gated rule set) in new customer-facing entries is zero.
- **SC-006**: After G8, the count of reference downstream repos missing `docs/intake-log.md` is zero. (G3 produces the scaffold/upgrade tooling that seeds `docs/intake-log.md`; the four named reference repos are repaired at M8, so the zero-count assertion holds after G8, not G3.)
- **SC-007**: After G6, the count of generated artifacts modified by manual edit (per lint) is zero.
- **SC-008**: After G5, the count of model-fallback events without a complete log entry is zero.
- **SC-009**: Across the program, the count of framework-managed files edited during product tasks without explicit authorization is zero in the four reference repos.
- **SC-010**: After G7, the count of self-improvement PRs that touch protected files unexpectedly is zero.
- **SC-011**: At G9, a fresh-scaffolded project passes the template smoke test on a clean machine without manual repair steps.
- **SC-012**: At G8, each of the four reference downstream repos is either fully repaired or has a documented exception that names the deferred deliverable and the reason.
- **SC-013**: After G6, both `scripts/lint-agent-contracts.sh` and the prompt-regression test set pass against canonical sources and compiled runtime contracts.
- **SC-014**: At G9, release notes classify every file in the template's downstream ship-set (per `TEMPLATE_MANIFEST.lock` plus the upgrade script's ship-files list) as canonical, generated, or ephemeral; internal-only files are out of scope for this classification.

## Assumptions

- The customer's "11-milestone" framing refers to the plan in `sw_dev_template_implementation_plan-2.md`, which formally defines 10 milestones (M0–M9) and 10 gates (G0–G9); the spec proceeds with those.
- Working-tree boundary: All implementation edits land in `./sw-dev-team-template`. The enclosing meta-project owns only planning artifacts (this spec, downstream `plan.md` / `tasks.md`, schedule entries, intake rows). The meta-project is itself a scaffolded consumer of the template, used as a workshop; it is explicitly out of scope for M8 repair and is not one of the four M8 reference repos. Any post-program template-upgrade pass against the meta-project is a separate ticket opened after this sprint closes.
- The four reference downstream repos (`QuackDCS`, `QuackPLC`, `QuackS7`, `QuackSim`) exist and are reachable from the framework workspace at M8 start; if any is unreachable, an explicit M8 exception is recorded rather than skipped silently.
- The customer is the human running this session; `tech-lead` is the sole customer interface; all other agents escalate through `tech-lead`. Customer questions are queued internally and asked one atomic question per turn.
- M0 is enabling work and ships first. No OpenCode, LLMD, or self-improvement automation work begins before Gate G1.
- The existing canonical role roster in `.claude/agents/*.md` plus `CLAUDE.md` / `AGENTS.md` is preserved as the source of truth. OpenCode, Gemini, OpenAI, and Markdown compilation adapt to it rather than replacing it.
- The memory layer (`claude-mem`) remains pointer-only, not authority — already accepted in framework ADR-0001. Memory hits are verified against the live repo before action.
- `code-reviewer` review is required before every commit and `qa-engineer` runs prompt-regression tests on the listed core agents at M1 and again at M6 against compiled output.
- Gemini, OpenAI, and Claude model identifiers may change during the program; routing guidelines use model classes and the exact IDs are runtime-reverifiable before each release.
- `LLMD` (or whichever Markdown compiler is selected) is treated as a linter/generator, not source of truth, and is pinned per release. Compiler-induced semantic changes are reviewed against canonical source.
- PR slicing follows the plan's §5 table (PR-1 through PR-16+); large multi-milestone PRs are avoided.
- Sign-offs at G9 from `code-reviewer`, `qa-engineer`, `release-engineer`, and `project-manager` are sequential; the customer approval condition follows the template's release policy and is obtained by `tech-lead`.
- Cadence terms ("first session of the calendar week", "milestone close") are session-anchored and run-once per `CLAUDE.md`'s time-based-cadence rule; missed cycles do not accumulate.
