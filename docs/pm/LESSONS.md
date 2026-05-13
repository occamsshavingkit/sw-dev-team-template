# Lessons Learned — SWEProj (template-as-project meta-workspace)

Process journal for the template's own development. Release-note
content lives in `sw-dev-team-template/CHANGELOG.md`; this file is
for *process* lessons that would otherwise rot.

Based on `docs/templates/pm/LESSONS-template.md` shape.

Archive pointer: historical snapshots live in `docs/pm/LESSONS-ARCHIVE.md`.
Keep current milestone lessons here; archive older milestone-safe lessons
append-only before any compact tombstone replaces live sections.

---

## 2026-04-21 — Sub-agent permission denials on `.claude/agents/**`

**Context.** Dispatching `tech-writer` and other sub-agents to edit
template files under `sw-dev-team-template/.claude/agents/`.

**Event.** Main agent Edits on those paths worked. Sub-agent Edits
on the same paths were denied three consecutive times, even after
adding an explicit `Edit(...sw-dev-team-template/.claude/agents/**)`
entry to `.claude/settings.local.json`.

**What went well.** The failure was fast and loud, not silent.
Switching to main-agent Edits immediately unblocked the work.

**What did not.** Two diagnosis attempts (first: wrong file path;
second: permission syntax) were wrong. The true cause appears to
be a harness-level protection on `.claude/` paths for sub-agents
that the user-facing settings cannot override.

**Contributing factors.** No documentation of this restriction in
the Claude Code settings reference we could find. Process gap, not
tooling gap per se.

**Recommendation.** When editing `.claude/agents/*.md`, default to
main-agent Edits. Do not attempt to delegate to sub-agents.
Document this in `tech-lead.md` § routing if it keeps biting.

**Category.** tooling / process.

**References.** Session transcript; `.claude/settings.local.json`.

---

## 2026-05-12 — M3 atomic customer-question guidance evidence

**Context.** `/speckit.implement` M3 documentation tasks T013-T016 and T019 required atomic scoping seeds, consistent internal-vs-customer-facing batching guidance, and an active Customer Question Gate before later lint and intake-log work.

**T013 seed-question rows.** `docs/FIRST_ACTIONS.md` now defines the Step 2 seed queue as one-decision-axis rows. Compound axes such as project summary, target user, stack, first milestone done criteria, deliverable kind, SME coverage, external SME availability, substitute criteria, and agent naming are split into separate customer-facing questions.

**Template seed-question repair.** `docs/templates/scoping-questions-template.md` now matches the Step 2 one-decision-axis seed rows, splits Step-1 follow-ups and SME/discovery axes, and explicitly instructs fresh scaffolds to copy one row per axis into `docs/OPEN_QUESTIONS.md` and ask one question per idle turn.

**T014-T016 batching guidance.** `CLAUDE.md`, `docs/FIRST_ACTIONS.md`, and `.claude/agents/tech-lead.md` now distinguish internal batching from customer-facing prompts: internal queues may hold multiple rows, but each prompt to the customer must be one decision axis, one question, asked only when tools and specialists are idle, with the question as the final line on screen.

**T019 Customer Question Gate.** `.claude/agents/tech-lead.md` now has a near-top `Customer Question Gate` requiring an `OPEN_QUESTIONS.md` row, prior-source/specialist checks, idleness or clean stop, exactly one customer-facing question, and final-line placement before asking the customer.

**T017-T018 researcher guidance.** `docs/OPEN_QUESTIONS.md` now requires one row per decision axis while allowing internal queues to hold multiple rows; customer-facing asks remain one question per idle turn. `docs/templates/intake-log-template.md` now requires each entry to record one atomic customer question/answer round, flags multi-axis asks as conformance failures, and states that `options-presented` cannot bundle independent decisions.

**T020-T021 implementation evidence.** `scripts/lint-questions.sh` now performs warning-only atomic-question checks over the canonical question surfaces, includes the active scaffold seed source `docs/templates/scoping-questions-template.md` as a required scan surface, treats wrapped continuation lines as part of the same numbered or bulleted question item, excludes the template's advisory follow-up catalog from bundled-prompt block checks, and visibly warns when optional scan surfaces such as `docs/intake-log.md` are absent. `scripts/scaffold.sh` now creates a live empty `docs/intake-log.md` before manifest generation and seeds exactly one `docs/intake-log.md` customization entry so future upgrades preserve intake history.

**T022 repair/upgrade guidance evidence.** `docs/TEMPLATE_UPGRADE.md` now documents the upgrade missing-file path and the destructive-repair operator step for absent `docs/intake-log.md`, preserves existing logs, rejects archive/template files as live-log substitutes, and requires `.template-customizations` preservation for project-owned intake history.

**T023 G3 validation evidence.** `qa-engineer` validation passed for G3. Command `bash -n scripts/lint-questions.sh scripts/scaffold.sh` produced no output. Command `scripts/lint-questions.sh` exited `0` with `2` warning(s), proving warning-only behavior: `docs/OPEN_QUESTIONS.md:29` and `docs/OPEN_QUESTIONS.md:30` may bundle independent decisions. Fresh scaffold smoke under `/tmp/opencode/g3-scaffold.J9UIFt/Fresh G3 Project` confirmed `docs/intake-log.md` exists and `.template-customizations` contains exactly one `docs/intake-log.md` entry. `docs/TEMPLATE_UPGRADE.md` documents missing live `docs/intake-log.md` creation through upgrade, destructive repair from `docs/templates/intake-log-template.md`, preservation of existing logs, rejection of archive/template substitutes, and `.template-customizations` preservation. Task state check confirmed T013-T023 complete and T024 still unchecked. Command `git diff --check` produced no output.

**G3 gate acceptance.** `tech-lead` acceptance authorized for G3 after passing `qa-engineer` validation and no blocking findings. Status: accepted; M4 may proceed subject to normal gate sequencing.

**Category.** planning / governance.

**References.** `specs/003-remaining-milestones/spec.md` FR-005, FR-006, FR-021; `specs/003-remaining-milestones/tasks.md` T013-T023; `docs/FIRST_ACTIONS.md` Step 2; `.claude/agents/tech-lead.md` Customer Question Gate; `docs/TEMPLATE_UPGRADE.md`; `scripts/lint-questions.sh`; `scripts/scaffold.sh`.

---

## 2026-05-12 — M4 documentation authority and drift-control evidence

**Context.** M4 tasks T024-T028 covered documentation authority,
downstream roadmap handling, model-routing binding status, and removing
binding workflow-pipeline dependency on excluded proposal material.

**T024 authority policy.** `docs/framework-project-boundary.md` now
defines `canonical`, `generated`, and `ephemeral`; requires ambiguous
artifact classification before editing; requires generated artifacts to
name canonical inputs and regeneration or freshness checks; and prohibits
manual mirrors in favor of generated output, links, or removal.

**T025/T026 roadmap handling.** `docs/framework-project-boundary.md`
documents root `ROADMAP.md` as upstream template release planning that is
excluded from downstream scaffold and upgrade shipping. `docs/TEMPLATE_UPGRADE.md`
adds retrofit handling: preserve intentional product roadmaps, remove or
replace only copied template release-plan leakage, list persistent product
roadmaps in `.template-customizations` when needed, and stop/preserve on
ambiguous ownership.

**T027 model routing status.** `docs/model-routing-guidelines.md` is now
binding for role tier, effort, and plan-mode selection while keeping
provider-specific mappings advisory until release verification. Release
readiness must verify exact provider model IDs and aliases, with evidence
in release notes, this lessons log, or a linked release-review artifact
that carries a `verified on` date.

**T028 workflow pipeline.** `docs/workflow-pipeline.md` now contains the
binding trigger clauses, stage order, artifact ownership, retention, and
escape hatches. `.claude/agents/tech-lead.md` now references that shipped
authority instead of the excluded workflow-redesign proposal. The remaining
binding role references in `.claude/agents/researcher.md`,
`.claude/agents/security-engineer.md`, `.claude/agents/software-engineer.md`,
`.claude/agents/architect.md`, `.claude/agents/qa-engineer.md`, and shipped
templates now point to `docs/workflow-pipeline.md`; validation found no
remaining active-rule references to
`docs/proposals/workflow-redesign-v0.12.md` in `.claude/agents/*.md`,
`CLAUDE.md`, `AGENTS.md`, or `docs/templates/*.md`.

**T029 G4 validation evidence.** Scoped command
`rg -n "docs/proposals/workflow-redesign-v0\.12\.md|workflow-redesign-v0\.12" CLAUDE.md AGENTS.md .claude/agents docs/templates docs/workflow-pipeline.md docs/framework-project-boundary.md docs/TEMPLATE_UPGRADE.md docs/model-routing-guidelines.md`
produced no output, proving downstream-shipped entrypoints, role files,
templates, and canonical M4 docs no longer depend on the excluded
workflow-redesign proposal. Command `git diff --check` produced no output.

**G4 gate acceptance.** `architect` M4 evidence and `code-reviewer`
validation accepted G4 after the scoped grep and whitespace checks passed
with no blocking findings. Status: accepted; M5 may proceed subject to
normal gate sequencing.

**Category.** planning / governance.

**References.** `specs/003-remaining-milestones/tasks.md` T024-T028;
`docs/framework-project-boundary.md`; `docs/TEMPLATE_UPGRADE.md`;
`docs/model-routing-guidelines.md`; `docs/workflow-pipeline.md`;
`.claude/agents/tech-lead.md`; `docs/proposals/T024.md` through
`docs/proposals/T028.md`.

---

## 2026-05-12 — M5 OpenCode/Gemini routing implementation evidence

**Context.** M5 tasks T030-T034 covered OpenCode as a harness adapter,
Gemini/OpenCode provider-class routing, frontier fallback behavior,
fallback logging, and thin generated-or-generator-backed OpenCode
adapter guidance.

**T030 adapter ADR.** `docs/adr/fw-adr-opencode-harness-adapter.md` now
accepts Option S: OpenCode is a harness/provider adapter over the
existing role model. It may configure providers, model classes,
commands, and thin wrappers, but it must not redefine the role roster,
escalation chain, customer interface, source hierarchy, specialist
ownership, required output formats, or review gates.

**T031 provider/model conventions.** `docs/model-routing-guidelines.md`
now documents `tier`, `effort`, and `<provider>/<model-or-class>` model
notation, adds Gemini Flash/Pro-class advisory mappings, and keeps exact
Gemini/OpenCode IDs release-verifiable rather than guessed.

**T032/T033 fallback behavior and evidence.** Model routing now requires
frontier/`xhigh` escalation for architecture, safety, security, privacy,
API, data-model, release-blocking, cross-harness failure, and unresolved
disagreement. Fallback changes execution provider/model only; the second
failed provider/model attempt stops and returns to `tech-lead`. Fallback
events record task ID, agent, requested tier, requested effort,
requested model, actual model, enumerated fallback reason, timestamp,
and an authority-preservation assertion.

**T034 thin adapter guidance.** `AGENTS.md` now states OpenCode adapters
are thin generated or generator-backed wrappers over `CLAUDE.md`,
`AGENTS.md`, `.claude/agents/*.md`, and matching local supplements. They
must not duplicate full role text, create replacement roles, introduce a
new escalation chain, or create another customer interface; they must
preserve role output format and review path.

**Proposal QA closure.** `docs/proposals/T030.md` through
`docs/proposals/T034.md` now close all duel findings with implementation
evidence and mark the round outcome closed on 2026-05-12.

**Release verification note.** Release readiness remains responsible for
checking exact provider model IDs and aliases against provider
documentation or a live provider catalog with a `verified on` date before
tagging; this implementation intentionally uses class labels where exact
IDs have not been release-verified.

**T035 G5 validation evidence.** `code-reviewer` validation found no
parallel role model introduced across `CLAUDE.md`, `AGENTS.md`, and
`.claude/agents/*.md`: `CLAUDE.md` keeps the canonical roster and sole
`tech-lead` customer interface, `AGENTS.md` remains an adapter to the same
role contract, and role files retain canonical ownership, handoff, and
output boundaries. `docs/adr/fw-adr-opencode-harness-adapter.md` and
`AGENTS.md` define OpenCode as a thin generated or generator-backed
harness/provider adapter over canonical inputs, not an OpenCode-native
replacement role system. `docs/model-routing-guidelines.md` documents
Gemini/OpenCode provider classes, fallback behavior, fallback logging,
authority preservation, and release-time exact model verification. Proposal
QA findings in `docs/proposals/T030.md` through `docs/proposals/T034.md`
are closed with implementation evidence. Command `git diff --check`
produced no output.

**G5 gate acceptance.** `architect`, `release-engineer`, and
`code-reviewer` evidence accepted G5 after adapter, routing, fallback,
authority-preservation, proposal-closure, and whitespace checks passed
with no blocking findings. Status: accepted; M6 may proceed subject to
normal gate sequencing.

**Category.** planning / governance / release.

**References.** `specs/003-remaining-milestones/tasks.md` T030-T034;
`docs/prior-art/T030.md` through `docs/prior-art/T034.md`;
`docs/proposals/T030.md` through `docs/proposals/T034.md`;
`docs/adr/fw-adr-opencode-harness-adapter.md`;
`docs/model-routing-guidelines.md`; `AGENTS.md`.

---

## 2026-05-12 — M6 runtime contract pipeline implementation evidence

**Context.** M6 tasks T036-T041 covered JSON schemas, strict agent
contract linting, deterministic runtime candidate generation, generated-
artifact provenance, and prompt-regression cases before the G6 validator.

**T036-T038 schemas.** Added draft 2020-12 schemas for normalized agent
contract projections, model-routing/fallback evidence, and generated-
artifact manifests. The schemas require canonical source paths, concrete
customer-interface/escalation/output evidence, supported tool enums,
release verification for exact model IDs, concrete fallback authority
preservation, sha256 checksums, non-canonical generated authority labels,
canonical inputs, review gates, and line/byte/token evidence shape.

**T039 contract linting.** `scripts/lint-agent-contracts.sh` validates all
three schemas with pinned runtime `npx --yes ajv-cli@5.0.0` and supports
`AJV_BIN` for preinstalled validator paths. It fails closed on missing
schemas, malformed agent frontmatter, empty or unknown tools, role filename
mismatches except the SME template case, invalid routing samples, and invalid
generated manifests.

**T040 runtime compilation.** `scripts/compile-runtime-agents.sh` writes
deterministic generated candidates to `docs/runtime/agents/generated/` and
`docs/runtime/agents/generated-artifacts.manifest.json`. Existing reviewed
M0/M1 runtime candidates outside the generated subdirectory are not
overwritten. The compiler now prefers `/usr/local/bin/llmdc` and
`/usr/local/bin/schema2llmd`, with `LLMDC_BIN` and `SCHEMA2LLMD_BIN`
overrides. In this environment both tools were used: `llmdc` compiled each
generated candidate as validation evidence, and `schema2llmd` converted
`schemas/generated-artifact.schema.json`; generated Markdown remains the
retained candidate authority. The manifest records canonical inputs,
generator command/version with LLMD tool paths, `generated_at: deterministic`,
review gate, retention, sha256 checksums, line counts, byte counts, and
`token_count.status: not-configured`.

**T041 prompt regression.** `docs/prompt-regression.md` defines invariant-
based cases for `tech-lead`, `researcher`, `software-engineer`,
`qa-engineer`, `code-reviewer`, and runtime generated artifacts. Cases name
expected invariants, forbidden behaviors, evidence paths, and pass/fail
criteria; canonical sources are the oracle, not previous generated output.

**Proposal QA closure.** `docs/proposals/T036.md` through
`docs/proposals/T041.md` now close all Duel findings with implementation
evidence and mark the round closed on 2026-05-12.

**Validation evidence.** Command `bash -n scripts/lint-agent-contracts.sh scripts/compile-runtime-agents.sh` produced no output. Command `node -e "for (const f of ['schemas/agent-contract.schema.json','schemas/model-routing.schema.json','schemas/generated-artifact.schema.json']) JSON.parse(require('fs').readFileSync(f, 'utf8')); console.log('schema-json-syntax: pass')"` produced `schema-json-syntax: pass`. Running `scripts/compile-runtime-agents.sh` twice and comparing `docs/runtime/agents/generated/` plus `docs/runtime/agents/generated-artifacts.manifest.json` produced `runtime-generation-stability: pass`; the manifest generator version includes `llmdc=used:/usr/local/bin/llmdc schema2llmd=used:/usr/local/bin/schema2llmd`. Command `scripts/lint-agent-contracts.sh` produced `lint-agent-contracts: schemas=3 agents=14 generated_manifest=present result=pass`. Command `git diff --check` produced no output. Task-state check produced `task-status: T036-T041 complete; T042 unchecked`.

**Category.** planning / governance / generated-artifacts.

**References.** `specs/003-remaining-milestones/tasks.md` T036-T041;
`schemas/agent-contract.schema.json`; `schemas/model-routing.schema.json`;
`schemas/generated-artifact.schema.json`; `scripts/lint-agent-contracts.sh`;
`scripts/compile-runtime-agents.sh`; `docs/prompt-regression.md`;
`docs/runtime/agents/generated-artifacts.manifest.json`.

---

## 2026-05-12 — G6 runtime generation acceptance

**Context.** T042 required independent G6 validation for M6 runtime generation,
contract validation, prompt regressions, and generated-artifact authority before
M7 may proceed.

**Validation evidence.** Command `node` JSON parsing over the three schema files
and `docs/runtime/agents/generated-artifacts.manifest.json` produced
`json-parse: pass files=4`. Command `bash -n scripts/lint-agent-contracts.sh
scripts/compile-runtime-agents.sh` produced no output. Command
`scripts/lint-agent-contracts.sh` produced `lint-agent-contracts: schemas=3
agents=14 generated_manifest=present result=pass`. Running
`scripts/compile-runtime-agents.sh` twice and hashing the manifest plus all
generated files produced `runtime-generation-stability: pass files=15
digest=49ea3eec6137a91c0041d81417ebcc12b60910f6af04535ba8ebaaa9db3ddd2c`.
The manifest provenance check produced `manifest-provenance: pass artifacts=14
tokens=not-configured`, confirming `/usr/local/bin/llmdc` and
`/usr/local/bin/schema2llmd` usage, generated-candidate authority, canonical
inputs, sha256 checksums, line counts, byte counts, and non-faked token status.
The prompt-regression coverage check produced `prompt-regression: pass cases=6
core_roles=6`. Command `git diff --check` produced no output.

**Authority result.** Generated files under `docs/runtime/agents/generated/`
state that they are generated candidates, not canonical policy, name canonical
inputs, and defer conflicts to canonical sources. `docs/prompt-regression.md`
uses canonical sources as the oracle for `tech-lead`, `researcher`,
`software-engineer`, `qa-engineer`, `code-reviewer`, and runtime generated
artifact behavior.

**G6 gate acceptance.** `qa-engineer` validation and code-reviewer acceptance
scope passed with no blocking findings. Status: accepted; M7 may proceed
subject to normal gate sequencing.

**Category.** planning / governance / generated-artifacts.

**References.** `specs/003-remaining-milestones/tasks.md` T036-T042;
`schemas/*.schema.json`; `scripts/lint-agent-contracts.sh`;
`scripts/compile-runtime-agents.sh`; `docs/prompt-regression.md`;
`docs/runtime/agents/generated-artifacts.manifest.json`;
`docs/runtime/agents/generated/*.md`.

---

## 2026-05-12 — M7 issue-driven self-improvement implementation evidence

**Context.** M7 tasks T043-T051 implemented framework-gap intake,
PR-only self-improvement automation, patch-size limits, and human review
policy. T052 remains the separate G7 acceptance validator.

**T043/T044 issue intake.** `docs/ISSUE_FILING.md` now defines the
repository-scoped framework labels `framework:agent-routing`,
`framework:rule-defect`, `framework:template-gap`,
`framework:standards-gap`, `framework:tooling-gap`,
`framework:downstream-leakage`, and `framework:release-policy`. Labels
complement the required filing fields and do not replace version,
location, observed outcome, gap rationale, redaction, or opt-in evidence.
`.github/ISSUE_TEMPLATE/framework-gap.yml` adds matching required form
fields and required redaction/opt-in confirmations without asking for
customer, project, repository, product, site, secret, or private
identifier values.

**T045/T050/T051 policy.** `docs/workflow-pipeline.md` now defines the
M7 self-improvement loop as exactly one selected issue/gap per run, at
most one branch, one proposal/update set, one bounded patch, and one PR.
It requires contract checks before branch/PR creation, PR-only output,
safe no-op/failure summaries, patch limits `M7_MAX_CHANGED_FILES=5` and
`M7_MAX_DIFF_LINES=400`, and the human review sequence: implementation
owner, `release-engineer`, conditional `security-engineer`, then final
`code-reviewer`. New commits after role approval require re-review.

**T046-T049 workflows.** Added read-only PR/manual checks for agent
contracts, question lint, and template contract smoke. Added
`.github/workflows/improve-template.yml` with manual dispatch and a
weekly scheduled trigger that no-ops unless explicitly enabled by
repository variables. The improvement workflow runs preflight checks in a
read-only job, enforces the M7 patch limits before PR creation, creates a
PR only from a separate write-scoped job, and reports no-op/failure
outcomes through the workflow summary. It does not use
`pull_request_target`, approve PRs, merge PRs, enable auto-merge, or push
to default/protected branches. The no-op/failure reporting job uses
`permissions: {}` because it only writes `$GITHUB_STEP_SUMMARY` and does
not create or update issues, comments, or PRs.

**Proposal QA closure.** `docs/proposals/T043.md` through
`docs/proposals/T051.md` close all round-1 duel findings with
implementation evidence and mark the outcome accepted on 2026-05-12.

**Validation evidence.** Command `python3` with PyYAML parsed
`.github/ISSUE_TEMPLATE/framework-gap.yml` and all four workflow files and
produced `yaml-syntax: pass files=5`. Command
`scripts/lint-agent-contracts.sh` produced
`lint-agent-contracts: schemas=3 agents=14 generated_manifest=present result=pass`.
Command `scripts/lint-questions.sh` exited 0 with its existing two
warning-only findings in `docs/OPEN_QUESTIONS.md` lines 29-30. Command
`scripts/compile-runtime-agents.sh && git diff --quiet -- docs/runtime/agents/generated docs/runtime/agents/generated-artifacts.manifest.json`
produced `runtime-generation-drift: none`. Structural scans confirmed the
workflow names, triggers, permissions, PR creation path, no unsafe
`pull_request_target`, no merge/review/approval command, no direct
protected-branch push, issue taxonomy labels, M7 patch constants, and M7
review-role markers. G7 follow-up confirmed no `issues: write` remains in
`.github/workflows/improve-template.yml`. Command `git diff --check`
produced no output.

**Task state.** T043-T051 are complete. T052 remains unchecked for the
separate G7 validation task. M8/M9 tasks remain untouched.

**Category.** planning / governance / release / security.

**References.** `specs/003-remaining-milestones/tasks.md` T043-T051;
`docs/ISSUE_FILING.md`; `.github/ISSUE_TEMPLATE/framework-gap.yml`;
`docs/workflow-pipeline.md`; `.github/workflows/agent-contract-check.yml`;
`.github/workflows/question-lint.yml`;
`.github/workflows/template-contract-smoke.yml`;
`.github/workflows/improve-template.yml`; `docs/proposals/T043.md`
through `docs/proposals/T051.md`.

---

## 2026-05-12 — G7 self-improvement automation acceptance

**Context.** T052 required release/security/code-reviewer validation of M7
self-improvement automation after the permission fix removed unnecessary issue
write scope from no-op reporting.

**Validation evidence.** `.github/workflows/improve-template.yml` is PR-only:
preflight runs with `contents: read`, scheduled runs no-op unless explicitly
enabled with one configured target, dry-run or no-change paths report through
`$GITHUB_STEP_SUMMARY`, and branch/PR creation is isolated to the later
`create-pr` job. The write-scoped job grants only `contents: write` and
`pull-requests: write`; the no-op reporting job uses `permissions: {}` and no
`issues: write` remains. The workflow contains no `pull_request_target`, no PR
approval/review command, no merge command, no auto-merge enablement, and no
default/protected branch push path.

**Control checks.** Contract checks run in preflight before generation and
before any PR job can start. Patch limits are enforced before PR creation and
re-enforced in the PR workspace with `M7_MAX_CHANGED_FILES=5` and
`M7_MAX_DIFF_LINES=400`. The PR body carries the required human review
sequence: implementation owner, `release-engineer`, conditional
`security-engineer`, then final `code-reviewer`. `docs/workflow-pipeline.md`
matches those controls and requires stale approvals to be repeated after new
commits.

**Proposal closure.** `docs/proposals/T043.md` through `docs/proposals/T051.md`
close all recorded Duel findings with implementation evidence. The permission
follow-up is addressed by the workflow's least-practical permissions: no issue
write permission is granted because no issue comments are implemented.

**Command evidence.** `python3` PyYAML parsing over the framework-gap issue form
and four workflow files produced `yaml-syntax: pass files=5`.
`scripts/lint-agent-contracts.sh` produced
`lint-agent-contracts: schemas=3 agents=14 generated_manifest=present result=pass`.
`scripts/lint-questions.sh` exited 0 with the existing two warning-only findings
in `docs/OPEN_QUESTIONS.md` lines 29-30. `scripts/compile-runtime-agents.sh &&
git diff --quiet -- docs/runtime/agents/generated
docs/runtime/agents/generated-artifacts.manifest.json` completed with no drift.
Structural workflow checks passed for PR-only/no-op behavior, pre-PR contract
checks, patch limits, human review checklist, least permissions, absence of
`pull_request_target`, absence of review/merge commands, and no `issues: write`.
Command `git diff --check` produced no output.

**G7 gate acceptance.** `release-engineer`, `security-engineer`, and
`code-reviewer` acceptance scope passed with no blocking findings. Status:
accepted; M8 may proceed subject to normal gate sequencing.

**Category.** planning / governance / release / security.

**References.** `specs/003-remaining-milestones/tasks.md` T043-T052;
`.github/workflows/improve-template.yml`; `docs/workflow-pipeline.md`;
`docs/proposals/T043.md` through `docs/proposals/T051.md`.

---

## 2026-05-12 — Phase 1 candidate-governance evidence for M3-M9 tasks

**Context.** `/speckit.implement` Phase 1 for `specs/003-remaining-milestones` required objective evidence before any M3-M9 implementation work proceeds.

**T001 coverage matrix.** Source checked: `sw_dev_template_implementation_plan-1.md` M3-M9. Candidate checked: `specs/003-remaining-milestones/spec.md`, `plan.md`, `research.md`, `data-model.md`, `quickstart.md`, and `tasks.md`.

| Milestone | Source scope | Candidate coverage | Gate preserved |
|---|---|---|---|
| M3 | Atomic seed questions, batching language, Customer Question Gate, warning lint, intake-log scaffold/repair | `spec.md` FR-005/FR-006; `tasks.md` T013-T023 | G3 separate; T023 validates acceptance |
| M4 | Documentation authority, roadmap leakage, model-routing status, workflow-pipeline authority | `spec.md` FR-007/FR-008; `tasks.md` T024-T029 | G4 separate; T029 validates acceptance |
| M5 | OpenCode/Gemini/Codex/Claude adapter routing, ADR, fallback logging, thin adapters, no parallel roles | `spec.md` FR-009/FR-010; `tasks.md` T030-T035 | G5 separate; T035 validates acceptance |
| M6 | Schemas, contract lint, runtime compiler, generated output discipline, prompt regression | `spec.md` FR-011/FR-012; `tasks.md` T036-T042 | G6 separate; T042 validates acceptance |
| M7 | Issue taxonomy, framework-gap template, PR-only self-improvement, patch limits, human review, CI hardening | `spec.md` FR-013/FR-014; `tasks.md` T043-T052 | G7 separate; T052 validates acceptance |
| M8 | Per-repo rollout for QuackDCS, QuackPLC, QuackS7, QuackSim; repaired-or-excepted status | `spec.md` FR-015/FR-016; `tasks.md` T053-T057 | G8 separate; T057 validates acceptance |
| M9 | Conformance, QA, release mechanics, PM risk, usability/process audits, release approval policy | `spec.md` FR-017/FR-018; `tasks.md` T058-T068 | G9 separate; T068 validates acceptance |

**T002 scope guard.** Current planning slice introduces only `specs/003-remaining-milestones/{spec.md,plan.md,research.md,data-model.md,quickstart.md,tasks.md,checklists/requirements.md}` as untracked candidate artifacts. `contracts/`, `src/`, generic `tests/`, and `.github/workflows/` are absent by glob check. Existing tracked changes shown by `git status --short` are `.gitignore`, `.specify/feature.json`, `AGENTS.md`, and `CLAUDE.md`; no downstream product paths, release execution artifacts, protected-branch automation, or M3-M9 implementation files were introduced by this Phase 1 evidence slice.

**T003 governance acceptance criteria.** Candidate artifacts remain subordinate to `tech-lead`; `plan.md` constraints exclude M3-M9 implementation, contracts, downstream product edits, direct release execution, protected-branch pushes, and product/framework mixing; `plan.md` Post-Design Constitution Check passes role routing, source authority, quality gates, framework/project boundary, and adapter discipline. Acceptance criteria for this slice: all Spec Kit outputs stay candidate until routed; later work uses owning specialists and gate evidence; generated outputs identify canonical inputs before promotion; customer-owned uncertainty is handled as an assumption or one queued atomic question.

**Validation note.** Spec Kit prerequisite check returned feature dir `/home/quackdcs/SWEProj/specs/003-remaining-milestones` with available docs `research.md`, `data-model.md`, `quickstart.md`, and `tasks.md`. Checklist `requirements.md` has 15/15 items complete. Optional `/speckit-git-commit` before/after implementation hooks are registered but not executed in this specialist slice.

**Category.** planning / governance.

**References.** `sw_dev_template_implementation_plan-1.md` §§ M3-M9; `specs/003-remaining-milestones/plan.md` §§ Technical Context, Constitution Check, Post-Design Constitution Check; `specs/003-remaining-milestones/tasks.md` T001-T003.

---

## 2026-05-12 — Phase 2 gate discipline for M3-M9 tasks

**Context.** `/speckit.implement` Phase 2 for `specs/003-remaining-milestones` required shared gate routing, boundary handling, and review criteria before any M3-M9 implementation task starts.

**T004/T005 schedule evidence.** `docs/pm/SCHEDULE.md` now records M3-M9 milestone rows, A-M3-1 through A-M9-1 owner routing from `quickstart.md`, the G3-G9 dependency chain, named gate accepters, and required evidence artifacts. The live schedule keeps all G3-G9 gates planned and blocks successor gates until acceptance evidence exists.

**T006 boundary evidence.** `docs/pm/CHANGES.md` C-14 records framework/project boundary handling: M3-M7 and M9 are framework/template-maintenance, M8 is downstream-reference rollout evidence, and downstream product edits must not be mixed with template changes unless explicitly authorized.

**T007 shared gate-review checklist.** Every G3-G9 review requires: named owner sign-off from the accepter roles in `docs/pm/SCHEDULE.md`; validation command output or explicit not-applicable rationale; scoped diff evidence proving only authorized framework, generated, candidate, or downstream-reference paths changed; evidence artifact links in `docs/pm/LESSONS.md`, `docs/pm/SCHEDULE.md`, `docs/pm/CHANGES.md`, or `docs/pm/RISKS.md` as assigned; and a next-gate release decision of `accepted`, `blocked`, or `deferred` before dependent work starts.

**Category.** planning / governance.

**References.** `specs/003-remaining-milestones/quickstart.md` § Later Implementation Readiness; `specs/003-remaining-milestones/tasks.md` T004-T007; `docs/pm/SCHEDULE.md` §§ Milestone list, Activities, Critical path, Gate checks; `docs/pm/CHANGES.md` C-14.

---

## 2026-05-12 — US1 candidate task-plan validation for M3-M9

**Context.** `/speckit.implement` US1 required validating the candidate task plan itself before later M3-M9 implementation or issue conversion begins.

**T008 phase-structure result.** `specs/003-remaining-milestones/tasks.md` preserves M3-M9 as seven separate phases: Phase 1 setup, Phase 2 foundational prerequisites, Phase 3 US1 task-artifact validation, Phase 4 US2 for M3-M5, Phase 5 US3 for M6-M7, Phase 6 US4 for M8-M9, and Phase 7 polish. M3, M4, M5, M6, M7, M8, and M9 each retain separate headings or validator tasks, so the plan does not collapse the remaining program into one implementation task.

**T009 task-count and gate-coverage result.** Parsed task totals match the declared counts: total 73; setup 3; foundational 4; US1 5; US2 23; US3 17; US4 16; polish 5. Gate coverage is complete for G3 through G9, with separate validator tasks T023/G3, T029/G4, T035/G5, T042/G6, T052/G7, T057/G8, and T068/G9. Milestone coverage is complete for M3 through M9, and the requirement coverage map covers FR-001 through FR-022, CA-001 through CA-004, and SC-001 through SC-008.

**T010 independent-test trace.** US1 traces to `spec.md` lines 10-23 and `tasks.md` lines 47-61: M3-M9/G3-G9 are represented, no all-in-one implementation task is introduced, and customer-owned uncertainty is handled by assumptions or queued atomic questions. US2 traces to `spec.md` lines 26-39 and `tasks.md` lines 65-103: M3, M4, and M5 have separate gated evidence paths and ordered dependencies. US3 traces to `spec.md` lines 42-55 and `tasks.md` lines 107-136: M6 reproducibility/source-authority checks and M7 PR-only automation controls are independently testable. US4 traces to `spec.md` lines 58-70 and `tasks.md` lines 140-168: M8 repaired-or-excepted rollout status and M9 release-readiness approvals/risk/customer-approval-policy status are independently testable.

**T011 strict checklist formatting output.** Command: `python3` strict task-line parser over `specs/003-remaining-milestones/tasks.md`, requiring `- [ ]` or `- [X]`, `TNNN`, optional `[P]`, optional `[USn]`, description text, and Owner/Scope/Authority/Evidence/Review/Trigger metadata. Output: `task_lines=73`; `format_failures=0`.

**T012 unresolved marker scan output.** Command: `python3` scan over `specs/003-remaining-milestones/tasks.md` using the `quickstart.md` marker list adapted to `tasks.md`: `NEEDS[[:space:]]CLARIFICATION`, `[FEATURE]`, `[###`, `ACTION[[:space:]]REQUIRED`, `REMOVE[[:space:]]IF UNUSED`, and `Option [123]`. Output: `marker_matches=0`.

**T011/T012 whitespace check.** Command: `git diff --check`. Output: no output.

**Validation note.** Spec Kit prerequisite check returned feature dir `/home/quackdcs/SWEProj/specs/003-remaining-milestones` with available docs `research.md`, `data-model.md`, `quickstart.md`, and `tasks.md`. Checklist `requirements.md` has 16/16 items complete. Optional `/speckit-git-commit` before/after implementation hooks are registered but not executed in this specialist slice.

**Category.** planning / governance.

**References.** `specs/003-remaining-milestones/spec.md` §§ User Story 1-4, Requirements, Success Criteria; `specs/003-remaining-milestones/tasks.md` T008-T010, Phase 1-7, Dependencies & Execution Order, Independent Test Criteria, Task Counts.

---

## 2026-04-21 — Issue-feedback opt-in must be asked first, not last

**Context.** Original FIRST ACTIONS had issue-feedback opt-in as
Step 4, *after* skills menu, scoping, and naming. On the Gate-3
engagement, the customer had to prompt `tech-lead` to ask Step 4 at
all (issue #7), and multiple framework gaps were hit in Steps 1–3
that could not be filed because opt-in was unresolved.

**Event.** Customer directive: *"issue feedback needs to be the
very first question so we can give feedback on the first steps."*
Promoted to Step 0.

**What went well.** The fix is one reorder + DoD backstop; no new
rule, just sequencing.

**What did not.** The original design rationale assumed opt-in was
"an administrative question" and put it last. That was wrong —
opt-in is the *permission gate* for everything that follows.

**Contributing factors.** Design error: confusing administrative
ordering with permission ordering.

**Recommendation.** When a step gates a downstream behaviour
(logging, filing, etc.), it must precede the thing it gates.
Rule-of-thumb for future FIRST ACTIONS additions: *"If Step N
depends on a permission answered in Step M, then M < N."*

**Category.** process / design.

**References.** Issue #7; `sw-dev-team-template/CLAUDE.md` §
"Step 0 — Issue-feedback opt-in (atomic, asked FIRST)".

---

## 2026-04-23 — SME contract: Fix-C hybrid (primary-source vs derivative)

**Context.** Issue #6 surfaced that the single-mode SME scope
(customer-specific or externally-held non-public knowledge only)
blocked the common mental model of "domain specialist that uses
any source." Gate 5 (no open contract-breaking themes) was held
open on this.

**Event.** Customer ruled Fix-C hybrid with a sharper formulation:
two modes decided at creation time. Primary-source SME has a
non-public source; derivative SME has no primary source and
consumes `researcher` output, existing for context segmentation.

**What went well.** The customer's reformulation was sharper than
any of the three candidate fixes the architect had drafted. The
"context segmentation" framing for derivative mode is a genuine
design insight — `researcher` doesn't have to hold every vendor
ecosystem in one window.

**What did not.** The original single-mode rule shipped for too
long before the gap was surfaced. Taxonomy had been finalized on
one-mode assumptions since before v0.7.

**Contributing factors.** Over-specification up front without a
real downstream engagement. Gate-3 engagement was required to
surface the failure.

**Recommendation.** Gate-3-style real engagement is non-negotiable
for contract-level rules. Rules that look clean in isolation may
fail under a project with five vendor ecosystems; only a real
project reveals which.

**Category.** design / customer / process.

**References.** Issue #6; `sw-dev-team-template/CLAUDE.md` § "SME
scope: what is and is not an SME (binding)";
`.claude/agents/sme-template.md` § "Mode"; `CUSTOMER_NOTES.md`
2026-04-19 entry.

---

## 2026-04-23 — PDFs in `docs/library/local/` cannot be read directly

**Context.** PMBOK 8 and SWEBOK V4 PDFs were placed in
`docs/library/local/` (2026-04-21) with read-restriction lifting
2026-04-23. Audits dispatched to `researcher` agents on that date
to compare our agent roster against the two standards.

**Event.** The Read tool's PDF pathway requires `pdftoppm` from
`poppler-utils`, which is not installed on this system. All PDF
reads failed immediately. The SWEBOK V4 audit fell back to
web-sourced KA summaries (IEEE CS landing page, SFIA v9 crosswalk,
Wikipedia); no pages of LIB-0002 were actually opened.

**What went well.** The researcher fell back gracefully and wrote
a useful report against web sources, calling out the limitation
explicitly in §4 of `docs/audits/swebok-v4-gap-analysis.md`.

**What did not.** The blocker was not detected until mid-audit.
Pre-flight check would have caught it in seconds.

**Contributing factors.** `researcher` agent description does not
require a PDF-read capability check when the inventory holds PDFs.
The library inventory template does not have a "verified readable
on this system" field.

**Recommendation.** Three actions:
1. Install `poppler-utils` (requires user approval: `sudo apt install
   poppler-utils`).
2. Add a one-line pre-flight check to `researcher.md`: when about
   to Read a PDF, verify the system has `pdftoppm` (or equivalent)
   first; fall back to web sources and FLAG the limitation in the
   report if not.
3. Add a "PDF readable on this host: yes/no" column to the
   library inventory template.

**Category.** tooling / process.

**References.** `docs/audits/swebok-v4-gap-analysis.md` §4;
`docs/library/INVENTORY.md` LIB-0001, LIB-0002.

---

## 2026-04-23 — Researcher silently substituted web sources for a PDF brief

**Context.** Two parallel gap audits were dispatched with briefs
that explicitly named the PDFs to read (LIB-0001, LIB-0002 under
`docs/library/local/`). Poppler was missing at dispatch time, so
the Read tool could not open PDFs.

**Event.** Both researchers fell back to web-sourced KA summaries
without reporting the blocker first. Audit-pass-1 reports were
written against IEEE CS landing pages, SFIA crosswalks, Wikipedia,
and Tier-3 practitioner blogs — none of which were the asked-for
source. The customer caught this after the fact:
*"neither researcher should have gone to the web when told
specifically to read a PDF."*

**What went well.** Each researcher did document the fallback in
the report body and in the return message, so the failure was
visible on read-through. Audit-pass-2 was dispatchable without
re-discovering the issue.

**What did not.** The researchers treated the brief's named
source as a preference rather than a requirement. Web-sourced
content is a *different* deliverable — delivering it under the
framing of "audit the book" is dishonest even when the fallback
is marked.

**Contributing factors.** `researcher.md` had a Tier-1/Tier-2/
Tier-3 ranking but no rule forbidding silent source substitution
when a specific source was named in the brief.

**Recommendation.**
1. **Binding rule added to `researcher.md`** (2026-04-23): "No
   silent source substitution. When a brief names a specific
   source, that source is mandatory; if unreachable, stop and
   report the blocker to the dispatcher, do not substitute."
2. The rule applies to PDFs (`LIB-NNNN`), SME inventory items,
   cited standards, and any source whose row ID appears in the
   brief.
3. Dispatchers (`tech-lead`) should phrase briefs to make the
   source requirement explicit, not an expectation.

**Category.** process / agent design.

**References.** `.claude/agents/researcher.md` § Job item 1
("No silent source substitution (binding)");
`docs/audits/swebok-v4-gap-analysis.md` (audit-pass-1 flagged
its own fallback in §4);
`docs/audits/pmbok-8-gap-analysis.md` (audit-pass-1 flagged its
own fallback in §0 method note).

---
