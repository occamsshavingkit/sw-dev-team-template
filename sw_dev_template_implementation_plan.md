# sw-dev-team-template Implementation Plan

**Plan status:** Proposed implementation plan  
**Prepared for:** `sw-dev-team-template` team  
**Prepared on:** 2026-05-10  
**Planning posture:** Senior PM / delivery-governance plan  
**Primary objective:** Reduce token/context cost first, then use the saved capacity to fix authority drift, atomic-question failures, cross-AI routing, Markdown compilation, and self-improvement automation.

---

## 1. Executive summary

The template is not missing process. It is already a substantial multi-agent software operating model. The current risk is that the system is becoming expensive to run and difficult to keep synchronized.

The implementation sequence should therefore be:

1. **Reduce token/context cost.** Compact runtime agent contracts, archive live registers, shorten PM live surfaces, and stop storing huge prompts in live ledgers.
2. **Repair authority and question-flow defects.** Fix the atomic-question rule, downstream roadmap leakage, missing intake logs, and stale PM cadence.
3. **Integrate cross-AI routing safely.** Add OpenCode/Gemini/OpenAI/Claude support as an adapter over the existing role model, not as a new orchestration system.
4. **Introduce Markdown compilation only after source authority is clear.** Use LLMD or similar tooling as a linter/generator, not as the source of truth.
5. **Harden self-improvement automation.** Let issues drive PRs only after the template has strong gates, linting, and generated-artifact discipline.

The first two milestones should be treated as enabling work. Do not start large OpenCode or self-improvement automation before the token and authority issues are controlled.

---

## 2. Delivery principles

### 2.1 Token economy before feature expansion

Every new rule, agent, doc, or workflow must justify its recurring context cost.

A feature that saves 20% context in every session is higher priority than a feature that adds a new capability but increases startup or dispatch context.

### 2.2 Canonical, generated, or ephemeral

Every artifact must be classified as exactly one of:

| Class | Meaning | Examples |
|---|---|---|
| Canonical | Human-maintained source of truth | `CLAUDE.md`, `.claude/agents/*.md`, `CUSTOMER_NOTES.md`, `docs/model-routing-guidelines.md` |
| Generated | Derived from canonical sources; not manually edited | compact runtime prompts, OpenCode adapters, generated `AGENTS` summaries, memory summaries |
| Ephemeral | Temporary work product or transcript; not authoritative unless promoted | scratch audits, run logs, temporary handoff notes |

Manual mirrors are prohibited. If two files need the same content, one is canonical and the other is generated, linked, or removed.

### 2.3 Adapter, not parallel authority

OpenCode, Codex, Claude Code, Gemini, LLMD, and memory tooling must adapt to the existing role model. They must not introduce a competing role roster, escalation chain, or customer interface.

### 2.4 Ask fewer, sharper customer questions

Customer questions must be queued internally and asked externally one at a time. The question must be atomic, customer-owned, asked only when all agents/tools are idle, and the final line on screen.

### 2.5 Auditability through short live surfaces plus archives

Audit trails should exist, but not every audit detail belongs in live working files. Live files should be short and current. History belongs in archives or evidence files.

---

## 3. Workstreams

| Workstream | Name | Purpose | Primary owner |
|---|---|---|---|
| WS-TOK | Token economy | Reduce recurring context cost and dispatch cost | `project-manager` + `tech-lead` |
| WS-AUTH | Authority and documentation drift | Classify sources of truth; prevent stale/manual mirrors | `architect` + `tech-writer` |
| WS-QUEST | Atomic questions and intake | Make question protocol enforceable and auditable | `tech-lead` + `qa-engineer` |
| WS-PM | PM freshness | Keep schedule/roadmap/current-state docs useful without becoming token sinks | `project-manager` |
| WS-ROUTE | Cross-AI model routing | Add OpenCode/Gemini/Codex/Claude routing safely | `architect` + `release-engineer` |
| WS-COMP | Markdown compilation / LLMD | Generate compact runtime contracts and adapters | `software-engineer` + `code-reviewer` |
| WS-AUTO | Self-improvement loop | Use issues to propose safe PRs | `tech-lead` + `release-engineer` |
| WS-CI | Contract and quality gates | Enforce scaffolding, docs, agent, and question contracts | `qa-engineer` + `code-reviewer` |
| WS-ROLL | Downstream rollout | Repair and upgrade QuackDCS, QuackPLC, QuackS7, QuackSim | `project-manager` + `release-engineer` |

---

## 4. Milestone plan

## M0 — Mobilize and baseline

**Objective:** Establish current-state measurements before changing behavior.

**Scope:** Template repo plus the four downstream reference repos: `QuackDCS`, `QuackPLC`, `QuackS7`, and `QuackSim`.

### Deliverables

- `docs/pm/SCHEDULE.md` entry for this improvement program.
- `docs/pm/RISKS.md` entries for context bloat, authority drift, prompt compiler drift, and model-routing volatility.
- Baseline report: `docs/pm/token-economy-baseline.md`.
- Inventory of live context surfaces:
  - `.claude/agents/*.md`
  - `CLAUDE.md`
  - `AGENTS.md`
  - `docs/OPEN_QUESTIONS.md`
  - `CUSTOMER_NOTES.md`
  - `docs/intake-log.md`
  - `docs/pm/SCHEDULE.md`
  - `docs/pm/CHANGES.md`
  - `docs/pm/LESSONS.md`

### Measurements to capture

| Metric | Capture method |
|---|---|
| Agent contract line count | `wc -l .claude/agents/*.md` |
| Agent contract approximate token count | simple tokenizer or word-count proxy |
| Live register row count | grep/table parse |
| Answered rows still live | parse `OPEN_QUESTIONS.md` status column |
| PM schedule length | `wc -l docs/pm/SCHEDULE.md` |
| Intake-log presence downstream | file-existence check |
| Broken internal references | grep Markdown links / referenced paths |
| Current template version downstream | read `TEMPLATE_VERSION` |

### Gate G0 — Baseline accepted

Pass criteria:

- Baseline report exists.
- The team knows the largest recurring context surfaces.
- The first implementation PRs are sliced by workstream.
- No OpenCode, LLMD, or GitHub Actions automation work starts before G0.

---

## M1 — Token quick wins

**Objective:** Reduce recurring context cost before adding new cross-AI features.

### M1.1 Compact runtime agent contracts

Create a structure that separates human-readable agent manuals from compact runtime contracts.

Recommended structure:

```text
.claude/agents/                  # current canonical contracts for now
  tech-lead.md
  architect.md
  ...

docs/agents/manual/              # expanded rationale, examples, long guidance
  tech-lead-manual.md
  architect-manual.md
  ...

docs/agents/common-runtime.md    # shared runtime rules

docs/runtime/agents/             # generated compact contracts, later used by adapters
  tech-lead.md
  architect.md
  ...
```

Initial approach:

- Do **not** immediately replace `.claude/agents/*.md`.
- First generate compact runtime candidates and compare behavior.
- Preserve all hard rules, escalation formats, output formats, and hard-blocks.
- Move examples, rationale, historical context, and repeated prose into manuals.

Acceptance criteria:

- Token/line-count before/after report exists for every role.
- No hard rule is lost.
- `code-reviewer` signs off that runtime contracts preserve role authority.
- `qa-engineer` runs prompt-regression tests on at least `tech-lead`, `researcher`, `code-reviewer`, and `qa-engineer`.

### M1.2 Archive live registers

Implement:

```text
scripts/archive-registers.sh
```

Initial scope:

- `docs/OPEN_QUESTIONS.md`
- `CUSTOMER_NOTES.md` where safe
- `docs/intake-log.md`
- `docs/pm/RISKS.md`
- `docs/pm/LESSONS.md`

Archive pattern:

```text
docs/OPEN_QUESTIONS-ARCHIVE.md
docs/customer-notes-archive.md
docs/intake-log-ARCHIVE.md
docs/pm/RISKS-ARCHIVE.md
docs/pm/LESSONS-ARCHIVE.md
```

Rules:

- Keep open and recently answered rows live.
- Move stable terminal rows older than one milestone close to archive.
- Archive is append-only.
- Live file keeps a compact tombstone summary and archive pointer.

Acceptance criteria:

- Current large downstream `OPEN_QUESTIONS.md` files can be reduced without losing traceability.
- Fresh scaffold still starts with usable live registers.
- `researcher` contract points to the archival script instead of relying only on manual discipline.

### M1.3 Refactor token ledger

Current risk: `TOKEN_LEDGER.md` stores verbatim prompts inline, which can itself become a context sink.

Change live ledger schema to:

```text
Date | Task ID | Agent | Prompt hash | Prompt class | Token budget | Token actual | Notes
```

Move full prompts to optional archive files only when needed:

```text
docs/pm/token-ledger/prompts/<task-id>-<agent>.md
```

Acceptance criteria:

- Live token ledger is compact.
- Verbatim prompt archive remains available for calibration disputes.
- Task DoD is updated accordingly.

### M1.4 Split PM live plan from evidence

Introduce:

```text
docs/pm/SCHEDULE.md             # live current plan only
docs/pm/SCHEDULE-EVIDENCE.md    # closure evidence and raw references
docs/pm/SCHEDULE-ARCHIVE.md     # old closed rows / historical reconciliations
```

Acceptance criteria:

- `project-manager` can read `SCHEDULE.md` quickly every session.
- Evidence remains auditable but does not bloat live planning context.
- Downstream schedule format can migrate without losing prior evidence.

### Gate G1 — Token quick wins accepted

Pass criteria:

- Largest live context files have measured reductions or an accepted reduction path.
- Runtime-agent compaction prototype exists.
- Live register archival is scripted.
- PM schedule split is specified or implemented.
- No new cross-AI integration added yet.

---

## M2 — Token operating model

**Objective:** Make token economy an ongoing PM discipline, not a one-time cleanup.

### M2.1 Add token budgets to task planning

Update `docs/templates/task-template.md`:

```text
Token budget: tiny | small | medium | large | XL
JIT file list: <files the assignee should read first>
Token actual: <filled at closure if material>
```

Suggested budget bands:

| Band | Intended use |
|---|---|
| Tiny | one-file fix, no specialist chain |
| Small | one specialist, focused files |
| Medium | 2–3 specialists, limited docs |
| Large | triggered workflow, multiple artifacts |
| XL | should be split unless explicitly approved |

### M2.2 Add PM delta pass

Instead of having `project-manager` reread all PM artifacts, define a lightweight pass:

Input:

- changed files since last PM pass
- merged PR titles since last PM pass
- current milestone row
- changed open-question rows
- risk/change deltas

Output:

- no-op confirmation, or
- minimal edits to affected PM registers

Acceptance criteria:

- Issue #136 is addressed without making PM cadence expensive.
- `project-manager` docs explicitly prefer delta passes over full rereads.

### M2.3 Make memory use prescriptive

Update `docs/MEMORY_POLICY.md`, `tech-lead.md`, and `researcher.md` with query patterns:

```text
Before reading old CUSTOMER_NOTES.md entries:
  search memory for "<topic> customer decision"

Before reading old schedules:
  search memory for "current milestone blocker"

Before asking the customer:
  search memory + OPEN_QUESTIONS for similar prior answer

Before reopening an ADR topic:
  search memory for "<module> accepted ADR"
```

Acceptance criteria:

- Memory remains pointer-only, not authority.
- Agents have concrete memory-first behavior.

### Gate G2 — Token operating model accepted

Pass criteria:

- Task template includes token budget fields.
- PM delta pass is documented.
- Memory query patterns are in binding docs.
- Token budget becomes visible in planning and review.

---

## M3 — Atomic-question and intake repair

**Objective:** Fix the failure mode where agents ask compound questions mid-output or before all agents are idle.

### M3.1 Rewrite scoping seed questions into atomic rows

Current problem: seed questions contain multiple decision axes.

Example split:

From:

```text
What are we building, for whom, on what stack, and what counts as done for the first milestone?
```

To:

```text
What are we building?
Who is the intended user or customer?
What stack or platform constraints should the team assume?
What must be true for the first milestone to count as done?
```

Acceptance criteria:

- Every seed question has one decision axis.
- Seed questions no longer contain broad bundled asks.
- Follow-up guidance says to queue many questions internally but ask one externally.

### M3.2 Clarify batching language

Update `CLAUDE.md`, `FIRST_ACTIONS.md`, `tech-lead.md`, `OPEN_QUESTIONS.md`, and `intake-log-template.md` with one consistent rule:

```text
Batch questions internally in docs/OPEN_QUESTIONS.md.
Do not batch customer-facing questions.
Ask one queued customer question per turn, only when all agents and tools are idle, with the question as the final line.
```

### M3.3 Add Customer Question Gate

Add a prominent gate near the top of `tech-lead.md`:

```text
Before sending any message that contains a question to the customer:
1. Is this customer-owned? If another agent can answer, route there first.
2. Is it atomic? One decision axis only.
3. Are all agents and tools idle?
4. Is the question the final line?
If any check fails, queue the question and do not ask.
```

### M3.4 Add atomic-question lint

Create:

```text
scripts/lint-questions.sh
```

Checks:

- compound seed questions
- customer questions with multiple numbered items
- multiple independent option sets
- `agents-running-at-ask` not equal to `[]`
- `OPEN_QUESTIONS.md` rows that look compound

Initial behavior should be warning-only, then hard-gated after one release cycle.

### M3.5 Seed and repair intake logs

Ensure every scaffold and retrofit has:

```text
docs/intake-log.md
```

Acceptance criteria:

- Fresh scaffold includes `docs/intake-log.md`.
- Repair/upgrade creates it if missing.
- QA intake-conformance audit can run on all downstream repos.

### Gate G3 — Atomic-question system accepted

Pass criteria:

- Scoping seed questions are atomic.
- Customer Question Gate exists.
- `lint-questions.sh` flags known bad historical patterns.
- Fresh scaffold and repaired downstream repos include `docs/intake-log.md`.

---

## M4 — Documentation authority and drift control

**Objective:** Reduce stale documentation by removing manual mirrors and clarifying source authority.

### M4.1 Add Documentation Authority Policy

Add a short policy to `docs/framework-project-boundary.md` rather than creating a large new standalone doc.

Policy:

```text
Every artifact is canonical, generated, or ephemeral.
Manual mirrors are prohibited.
If two artifacts need the same content, one must be generated, linked, or removed.
```

### M4.2 Fix downstream root roadmap leakage

Issue: downstream projects can carry template `ROADMAP.md` and confuse agents.

Fix options:

- do not ship root `ROADMAP.md` downstream, or
- move upstream roadmap to `docs/template/ROADMAP.md`, or
- replace with project-local roadmap stub.

Acceptance criteria:

- Fresh scaffold does not expose upstream template release planning as root project roadmap.
- Retrofit guidance explains how to handle existing root `ROADMAP.md`.

### M4.3 Resolve draft-vs-binding model-routing status

`docs/model-routing-guidelines.md` is currently operationally referenced. Promote it to binding guidance or stop treating it as binding.

Recommended decision: promote to binding policy, but require exact model IDs to be reverified before each release.

### M4.4 Move binding workflow-pipeline rules out of excluded proposal docs

If binding rules reference `docs/proposals/workflow-redesign-v0.12.md`, move them to a shipped canonical file:

```text
docs/workflow-pipeline.md
```

Acceptance criteria:

- No downstream-shipped file depends on an excluded proposal doc.
- Trigger rules have one shipped canonical home.

### Gate G4 — Authority model accepted

Pass criteria:

- Documentation Authority Policy is in place.
- Roadmap leakage fixed.
- Model-routing status clarified.
- Workflow-pipeline binding rules live in shipped docs.

---

## M5 — Cross-AI / OpenCode / Gemini routing

**Objective:** Add OpenCode-based multi-provider support without creating a parallel agent system.

### M5.1 Add OpenCode adapter ADR

Create ADR:

```text
docs/adr/fw-adr-XXXX-opencode-harness-adapter.md
```

Decision:

- OpenCode is a harness/provider adapter.
- It may configure models, providers, commands, and thin agent wrappers.
- It must not redefine role roster, escalation chain, or customer interface.
- Canonical roles remain `.claude/agents/*.md` plus `CLAUDE.md` / `AGENTS.md`.

### M5.2 Extend model-routing guidelines

Update `docs/model-routing-guidelines.md` with:

- OpenCode provider/model ID convention.
- Gemini model classes.
- Fallback behavior.
- Frontier-model escalation rules.

Recommended model-class mapping:

| Agent | Default class | Frontier only when |
|---|---|---|
| `tech-lead` | Claude Sonnet / strong reasoning | unresolved conflict, safety/customer-critical routing |
| `architect` | Claude Sonnet / strong reasoning | ADR conflict, major boundary, safety/security architecture |
| `software-engineer` | Codex/OpenAI coding model | ambiguous design tradeoff |
| `release-engineer` | Codex/OpenAI coding model | release blocker or cross-harness failure |
| `code-reviewer` | Claude Sonnet / strong review | hard-block, ADR conflict, safety/security |
| `qa-engineer` | Claude Sonnet or Gemini Pro | safety/timing-critical validation |
| `researcher` | Gemini Pro/Flash or Claude | disputed source synthesis |
| `project-manager` | Gemini Flash / Haiku / mini | major scope/risk/stakeholder conflict |
| `tech-writer` | Claude Sonnet or Gemini Pro/Flash | release-critical public docs |

### M5.3 Fallback logging

Every fallback must record:

```yaml
agent: software-engineer
requested_model: openai/codex-class
actual_model: anthropic/sonnet-class
fallback_reason: credit_exhausted
timestamp: <iso8601>
task_id: <id>
```

Fallback must not change role authority or output format.

### M5.4 Generate thin OpenCode adapters

Generated adapter shape:

```md
---
name: code-reviewer
model: <configured model>
---

Read `.claude/agents/code-reviewer.md` and any matching local supplement.
Act only as that role.
Return output in the required role format.
```

Acceptance criteria:

- No duplicated full role text in OpenCode adapters.
- Adapters are generated or clearly marked as generated.
- Manual edits to generated adapters fail lint.

### Gate G5 — Cross-AI routing accepted

Pass criteria:

- ADR accepted.
- Gemini/OpenCode model routing is documented.
- Fallback logging format exists.
- Thin OpenCode adapters exist or generator exists.
- No parallel role model introduced.

---

## M6 — Markdown compiler / LLMD / runtime contract pipeline

**Objective:** Use Markdown compilation to standardize contracts and reduce context, not to create new source truth.

### M6.1 Define schemas

Create:

```text
schemas/agent-contract.schema.json
schemas/model-routing.schema.json
schemas/generated-artifact.schema.json
```

Validate:

- frontmatter
- required sections
- escalation format
- hard-block conditions
- local supplement rule
- customer-interface rule
- output format
- allowed tools

### M6.2 Add compiler/linter

Create:

```text
scripts/lint-agent-contracts.sh
scripts/compile-runtime-agents.sh
```

Compiler may:

- generate compact runtime contracts
- generate OpenCode adapters
- generate session-start summaries
- normalize frontmatter
- report token/line count

Compiler must not:

- become source of truth
- silently rewrite hard rules
- hide differences between harnesses

### M6.3 Prompt regression tests

Add test cases for core agents:

| Agent | Test cases |
|---|---|
| `tech-lead` | compound customer question; specialist-owned work; queued agent slot |
| `code-reviewer` | ADR conflict; missing tests; traceability gap |
| `qa-engineer` | missing regression test; acceptance ambiguity |
| `researcher` | restricted source; missing source; customer-note stewardship |
| `project-manager` | stale schedule delta; no-op PM pass |

Run tests against source and compiled runtime contracts.

### Gate G6 — Compiler accepted

Pass criteria:

- Schema validation passes.
- Generated files are stable and reproducible.
- Prompt-regression tests pass.
- Source files remain canonical.

---

## M7 — Self-improvement loop and issue-driven evolution

**Objective:** Let issues drive safe template improvements through controlled automation.

### M7.1 Issue taxonomy

Add labels:

```text
template-gap
template-friction
authority-drift
docs-drift
agent-contract
atomic-question
model-routing
token-economy
process-breakdown
traceability-gap
generalization-risk
ai-behavior
```

### M7.2 Framework-gap issue template

Required fields:

- template version
- downstream repo/project context
- affected layer
- observed behavior
- expected behavior
- whether sensitive excerpts were redacted
- proposed acceptance criteria

### M7.3 AI improvement workflow

Only after G6, add automation:

```text
issues -> filter -> cluster -> propose one change -> validate -> PR
```

Rules:

- one improvement per run
- no direct push to `main`
- no protected-file edits unless specifically allowed
- patch size limit
- generated-artifact drift checks
- human PR review required

### M7.4 GitHub Actions hardening

Actions:

```text
.github/workflows/agent-contract-check.yml
.github/workflows/question-lint.yml
.github/workflows/template-contract-smoke.yml
.github/workflows/improve-template.yml   # manual or scheduled, after gates
```

### Gate G7 — Self-improvement loop accepted

Pass criteria:

- Issue taxonomy in place.
- AI loop opens PRs only.
- Contract checks run before PR creation.
- Failure modes produce no-op or issue, not broken commits.

---

## M8 — Downstream rollout and retrofit repair

**Objective:** Apply the improved template safely to `QuackDCS`, `QuackPLC`, `QuackS7`, and `QuackSim`.

### M8.1 Downstream classification

Classify each repo:

| Repo | Scaffold mode | Known observations |
|---|---|---|
| `QuackDCS` | retrofitted | large `OPEN_QUESTIONS.md`; missing `docs/intake-log.md` observed |
| `QuackPLC` | retrofitted | roadmap/status staleness; missing `docs/intake-log.md` observed |
| `QuackS7` | retrofitted | has intake log; customer corrected PM-routing behavior |
| `QuackSim` | from-template | has intake log; shows atomic-question violations and growing live registers |

### M8.2 Repair sequence per downstream repo

For each repo:

1. Run scaffold/upgrade repair checks.
2. Ensure `docs/intake-log.md` exists.
3. Archive large live registers.
4. Fix or quarantine root `ROADMAP.md` if it is upstream-template roadmap material.
5. Split PM live/evidence surfaces if oversized.
6. Run question lint.
7. Record template upgrade / repair in PM change log.

### M8.3 Rollout gate per repo

Pass criteria:

- No missing required framework files.
- Live context surfaces are below agreed soft caps or have waiver.
- Atomic-question lint warnings are either fixed or documented as historical exceptions.
- Product/framework boundary respected.

### Gate G8 — Downstream rollout accepted

Pass criteria:

- All four reference repos repaired or have documented exceptions.
- Rollout lessons captured upstream.
- New scaffold smoke test reflects downstream repair lessons.

---

## M9 — v1.0 readiness and release gate

**Objective:** Prepare the template for a stable release candidate after token, authority, question, routing, compiler, and rollout work are complete.

### M9.1 Full conformance audit

Dispatch:

- `code-reviewer` for agent/ADR/template conformance.
- `qa-engineer` for scaffold/upgrade/retrofit test plan execution.
- `release-engineer` for packaging/versioning/release notes.
- `project-manager` for final risk/schedule/change/lessons update.
- `onboarding-auditor` for zero-context usability.
- `process-auditor` for process-debt retirement candidates.

### M9.2 Release criteria

- Fresh scaffold passes smoke tests.
- Retrofit repair passes on reference downstream repos or fixtures.
- Agent-contract lint passes.
- Question lint passes on templates.
- Generated artifacts are up to date.
- No unresolved high-priority authority-drift issues.
- Model-routing guidance is current and exact model IDs are marked runtime-verifiable.
- Release notes clearly distinguish canonical vs generated vs ephemeral artifacts.

### Gate G9 — Release candidate accepted

Pass criteria:

- `code-reviewer` approves.
- `qa-engineer` approves.
- `release-engineer` approves release mechanics.
- `project-manager` records no open release-blocking risk.
- Customer approval is obtained if required by the template’s release policy.

---

## 5. Recommended PR slicing

Do not implement this as one large PR.

| PR | Scope | Gate |
|---|---|---|
| PR-1 | Baseline report + token metrics tooling | G0 |
| PR-2 | Archive-register script + live register policy | G1 |
| PR-3 | Token ledger schema + task-template token fields | G1/G2 |
| PR-4 | PM schedule live/evidence/archive split | G1/G2 |
| PR-5 | Atomic scoping questions + batching wording cleanup | G3 |
| PR-6 | Customer Question Gate + question linter | G3 |
| PR-7 | Intake-log scaffold/repair support | G3 |
| PR-8 | Documentation Authority Policy + roadmap leakage fix | G4 |
| PR-9 | Workflow-pipeline canonical doc move | G4 |
| PR-10 | Model-routing Gemini/OpenCode update | G5 |
| PR-11 | OpenCode adapter ADR + generated thin adapters | G5 |
| PR-12 | Agent contract schemas + lint | G6 |
| PR-13 | Runtime contract compiler / LLMD pass | G6 |
| PR-14 | Issue taxonomy + framework-gap issue template | G7 |
| PR-15 | GitHub Actions self-improvement loop | G7 |
| PR-16+ | Downstream rollout PRs, one repo at a time | G8 |

---

## 6. Acceptance metrics

Track before and after.

| Metric | Target after first pass |
|---|---|
| `tech-lead` runtime contract size | reduce by at least 30% in generated runtime form |
| Other runtime agent contract size | reduce by at least 20% where safe |
| Live `OPEN_QUESTIONS.md` size | open + recent answered rows only |
| PM schedule live file | current plan only; closure evidence moved out |
| Atomic question violations in new entries | zero |
| Missing intake logs in reference downstream repos | zero after repair |
| Generated artifacts manually edited | zero |
| Fallback model events without log | zero |
| Framework-managed files edited during product tasks | zero unless explicitly authorized |
| Self-improvement PRs touching protected files unexpectedly | zero |

---

## 7. Risk register summary

| Risk | Probability | Impact | Mitigation |
|---|---:|---:|---|
| Runtime compaction drops a hard rule | Medium | High | Schema checks + code-reviewer audit + prompt regression tests |
| Archiving hides needed evidence | Medium | Medium | Archives remain append-only and cross-linked |
| PM cadence increases token load | Medium | Medium | Delta pass only; no full reread by default |
| Atomic-question lint creates false positives | High | Low | Warning-only first release cycle |
| OpenCode becomes parallel orchestrator | Medium | High | ADR classifies it as adapter only |
| Gemini/OpenAI/Claude model IDs change | High | Medium | Use model classes; verify exact IDs at release/runtime |
| LLMD changes semantics | Medium | High | Source remains canonical; generated diff reviewed |
| Self-improvement bot opens noisy PRs | Medium | Medium | One improvement per run; human review; patch limits |
| Downstream retrofit breaks product work | Medium | High | One repo at a time; product/framework boundary checks |

---

## 8. Agent dispatch guide for this program

Use the existing role model.

| Work item | Agent |
|---|---|
| This implementation plan ownership and sequencing | `project-manager` |
| Architecture of canonical/generated/runtime separation | `architect` |
| Shell scripts and schema implementation | `software-engineer` |
| Markdown docs and policy text | `tech-writer` |
| Agent-contract lint and conformance review | `code-reviewer` |
| Question lint and scaffold/repair test strategy | `qa-engineer` |
| GitHub Actions, release wiring, OpenCode adapter packaging | `release-engineer` |
| External/OpenCode/Gemini/LLMD source verification | `researcher` |
| Security implications of automation/secrets | `security-engineer` |
| Token/cost/resource tracking | `project-manager` |
| Final orchestration and customer interface | `tech-lead` |

---

## 9. Do-not-do list

Do not:

- start with OpenCode integration before token/authority fixes;
- duplicate full agent definitions into `.opencode` files;
- make LLMD output canonical;
- let memory summaries become a source of truth;
- keep resolved-history rows in live registers indefinitely;
- allow AI self-improvement to push directly to `main`;
- ask the customer compound scoping questions;
- treat frontier models as default for every agent;
- mix product work and framework maintenance in the same PR unless explicitly authorized.

---

## 10. Suggested kickoff instruction to the sw-dev team

Use this as the first task prompt:

```text
Use the `project-manager` subagent to turn `sw_dev_template_implementation_plan.md` into the active PM schedule for `sw-dev-team-template`.

Start with M0 and M1 only. Do not begin OpenCode, Gemini, LLMD, or self-improvement automation yet.

Required first outputs:
1. `docs/pm/token-economy-baseline.md`
2. Updated `docs/pm/SCHEDULE.md` entries for M0/M1
3. Initial `docs/pm/RISKS.md` entries for token economy and authority drift
4. A proposed PR split for M0/M1

Keep all customer questions queued in `docs/OPEN_QUESTIONS.md`; ask only one atomic question at the end of a turn, only if needed and all agents/tools are idle.
```

---

## 11. Program definition of done

The program is complete when:

- runtime context is smaller and measured;
- live registers are archived and bounded;
- atomic-question failures are linted and prevented in new work;
- documentation authority is explicit;
- downstream roadmap leakage is fixed;
- PM cadence keeps current state fresh with delta passes;
- OpenCode/Gemini/Codex/Claude routing works as an adapter over the existing role model;
- Markdown compilation generates runtime artifacts without changing source authority;
- self-improvement automation can open safe, reviewable PRs;
- the four reference downstream repos have been repaired or have explicit exceptions;
- release gates pass for scaffold, upgrade, agent contracts, question lint, generated artifacts, and downstream smoke tests.
