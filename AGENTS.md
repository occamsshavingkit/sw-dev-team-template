# OpenCode Agent Instructions

## Project Identity / Working Tree

Sessions start in `/home/quackdcs/SWEProj`, which is the meta-project
root. The active template repository and normal work target is
`./sw-dev-team-template`.

Use `./sw-dev-team-template` for framework and template edits unless the
task explicitly targets meta-project scaffolding artifacts in this root.

This project is a multi-agent software-development template that must
run under OpenCode, Claude Code, and Codex. If a harness cannot satisfy a
binding instruction, record the incompatibility, stop the affected work,
and escalate instead of silently weakening the rule.

## Role Binding

The main OpenCode session plays `tech-lead` directly. Do not spawn
`tech-lead` as a subagent. The top-level session is the sole human
interface, owns orchestration, and dispatches specialists.

Before starting substantive work, read:

1. `CLAUDE.md`
2. `.claude/agents/tech-lead.md`
3. Any project-local `.claude/agents/tech-lead-local.md`, if present

Recommended follow-on reads after `CLAUDE.md` when the situation
matches:

- `docs/FIRST_ACTIONS.md` — Step 0–3a session-1 setup flow.
- `docs/MEMORY_POLICY.md` — memory layer + orchestration-framework
  stance.
- `docs/TEMPLATE_UPGRADE.md` — scaffold + upgrade + per-version
  migrations.
- `docs/IP_POLICY.md` — copyright, restricted-source clauses, AI-
  training scope.
- `docs/sme/CONTRACT.md` — SME modes, creation, researcher
  interaction.
- `docs/framework-project-boundary.md` — downstream path ownership.

Treat `CLAUDE.md` and `.claude/agents/*.md` as the shared team
contract. Claude Code reads them natively; OpenCode uses this `AGENTS.md`
as the adapter into the same contract.

## Framework / Project Boundary

In downstream repositories, distinguish product work from the
`sw-dev-team-template` framework embedded in the same tree. Before an
OpenCode session reviews, stages, commits, or edits broad change sets,
read `docs/framework-project-boundary.md` and apply its path ownership
model.

Default rule: product tasks do not edit framework-managed files such as
`CLAUDE.md`, this `AGENTS.md`, shipped `.claude/agents/*.md`,
`scripts/`, `migrations/`, `docs/templates/`, `docs/INDEX-FRAMEWORK.md`,
`docs/FIRST_ACTIONS.md`, `docs/TEMPLATE_UPGRADE.md`,
`docs/MEMORY_POLICY.md`, `docs/IP_POLICY.md`,
framework ADRs, template versioning docs, rc stabilization docs,
scaffold / upgrade scripts, or manifest files. Product-only release
audits also do not edit `TEMPLATE_VERSION`; that file changes only
during scaffold or template-upgrade flows. If a downstream product task
exposes a framework problem, file it upstream through
`docs/ISSUE_FILING.md` instead of patching it locally, unless the
customer explicitly authorizes template-upgrade or
framework-maintenance work for the current task.

Keep commits and PRs split: product files plus their project-filled
register updates in one review path; template upgrades or framework
maintenance in another.

## Specialist Dispatch In OpenCode

OpenCode dispatches specialists via the `task` tool, specifying
`subagent_type` as the canonical role name (e.g., `software-engineer`,
`architect`, `code-reviewer`). Each specialist is defined as a subagent
in `.opencode/agents/<role>.md` with its full role contract.

At every new OpenCode session, after reading the binding project
instructions, ask one atomic question to confirm whether the customer
authorizes specialist spawning for this session. If the customer
has already explicitly authorized or required agents in the current
session, record that statement as the authorization instead of re-asking.
A prior session's approval does not carry forward.

Before any dispatch, read `docs/model-routing-guidelines.md`
for the role tier and `docs/agent-health-contract.md`
for slot state, queueing, completion, and liveness vocabulary; record
the selected tier and slot-health state in the turn summary or Turn
Ledger.

Specialist dispatch briefs are limited to concise, role/task-specific
context needed for that specialist's assignment. Do not fork or paste
the full top-level conversation, broad repo state, or unrelated project
context into a specialist; cite required files or sections for the
specialist to read instead, so the top-level session preserves its own
context budget. Exception: include only the minimum extra context needed
to preserve binding customer constraints, safety limits, or exact
excerpt under review; if broader context is required, stop and ask
`tech-lead` to narrow the brief.

**Rule A — No role-stealing (binding).** The `tech-lead` session
orchestrates; it does not author production artifacts. Code, tests,
scripts, schemas, prose deliverables, requirements, ADRs, release
notes, paraphrase content, and customer-truth records route to the
owning specialist. Direct `tech-lead` writes stay within the
orchestration scope of `CLAUDE.md` Hard Rule #8. When unsure, dispatch.

**Rule B — No context-forking briefs (binding).** When dispatching N
independent tasks, send N separate concise briefs — one per task —
not one mega-brief covering several. **Independence test:** if task
X could land before task Y without breaking Y, and vice versa, X and
Y are independent; split them into separate briefs. A shared brief is
allowed only when one task is a hard prerequisite for the other; record
that prerequisite in the brief.

If `task` spawning is unavailable, continue only with orchestration or
other non-specialist work, record "OpenCode task spawning unavailable" in
the turn summary, and do not claim specialist work occurred. If the
customer has required agents, or the current task needs specialist-owned
work, stop and ask before proceeding; do not perform specialist work
locally unless the customer explicitly grants a one-item exception.

**Rule C — No top-level fallback when agents are required (binding).**
When the customer has authorized or required agents for the current
scope, `tech-lead` orchestrates only. If spawning is unavailable or the
requested specialist cannot be dispatched, `tech-lead` STOPS AND ASKS
rather than performing the specialist's work locally. Any exception
requires explicit customer authorization for the specific item; prior or
scope-wide authorization does not generalize.

**Rule D — Spawn authorization is not transferable (binding).**
Customer authorization to spawn specialists is granted to the top-level
`tech-lead` session only. A specialist does not inherit spawning rights.
Specialists return requests and escalations to `tech-lead`; only
`tech-lead` owns `task` dispatch. Preferred specialist brief preface:

> Top-level tech-lead dispatched you as an OpenCode subagent.
> Do not spawn other agents, delegate, or contact the customer;
> return findings, blockers, and escalation requests to tech-lead.

**Rule E — Closing completed specialists is routine (binding).**
Closing completed, failed, or no-longer-needed specialist sessions is
routine hygiene. It does NOT require additional customer authorization —
that authorization was granted upstream for the dispatch. Customer auth
gates DISPATCH, not CLOSE.

**Turn-summary requirement (binding).** Each turn that involved
specialist-scoped work states one of: `specialists dispatched`,
`specialist unavailable: stopped`, or `customer exception granted`
(naming the specific item).

### Specialist Role → OpenCode Subagent Map

Each canonical role has a corresponding OpenCode subagent defined in
`.opencode/agents/<role>.md`:

- `architect` → `.opencode/agents/architect.md`
- `software-engineer` → `.opencode/agents/software-engineer.md`
- `qa-engineer` → `.opencode/agents/qa-engineer.md`
- `code-reviewer` → `.opencode/agents/code-reviewer.md`
- `researcher` → `.opencode/agents/researcher.md`
- `security-engineer` → `.opencode/agents/security-engineer.md`
- `sre` → `.opencode/agents/sre.md`
- `project-manager` → `.opencode/agents/project-manager.md`
- `release-engineer` → `.opencode/agents/release-engineer.md`
- `tech-writer` → `.opencode/agents/tech-writer.md`
- `librarian` → `.opencode/agents/librarian.md`
- `mcp-liaison` → `.opencode/agents/mcp-liaison.md`
- `onboarding-auditor` → `.opencode/agents/onboarding-auditor.md`
- `process-auditor` → `.opencode/agents/process-auditor.md`
- `ui-ux-designer` → `.opencode/agents/ui-ux-designer.md`

For each dispatch via `task`, set `subagent_type` to the role name,
provide a concise `description`, and a `prompt` with the task brief
citing relevant files. Specialist subagent definitions (`mode: subagent`)
have `task: deny` permission — they cannot spawn further specialists.

Use `docs/AGENT_NAMES.md` as the public teammate-name map. Customer-
facing text, Turn Ledgers, queue entries, and handovers use the project
teammate name, or the canonical role when no teammate name is assigned.

### OpenCode Permission Model

OpenCode uses permission-based access control instead of Claude Code
hooks. Key differences from Claude Code:

- `opencode.json` `permission` config replaces `.claude/settings.json`
  hooks and allow/deny lists.
- The `edit` permission gates all file writes (no separate Write/Edit/
  MultiEdit distinction).
- The `bash` permission uses glob patterns for command allow/deny lists.
- The `task` permission controls which subagent types can be spawned.
- `external_directory` controls access to paths outside the project root.
- There is no equivalent to Claude Code's `PreToolUse` / `PostToolUse`
  hooks for enforcing role-specific path guards. Tech-lead must manually
  verify scope compliance per Hard Rule #8.

## OpenCode Pre-Close Checklist

OpenCode does not consume Claude Code hooks, so mirror hook-backed
safeguards in `.claude/settings.json` as an explicit checklist before
closing any non-trivial turn. If the checklist cannot be completed,
record the failed item and stop closure until `tech-lead` resolves it.

1. Inspect `git diff --stat` and the relevant diffs.
2. Confirm every direct `tech-lead` edit is within the allowed
   orchestration or tool-bridge scope from `CLAUDE.md` Hard Rule #8.
3. Confirm customer-truth text and customer authorization records were
   routed or queued for `librarian`, not written directly by
   `tech-lead`.
4. Confirm required specialist work was dispatched or covered by an
   explicit customer exception.
5. For product-only audits or fixes, confirm the diff contains no
   accidental framework-managed file edits, including release/version
   files called out in `docs/framework-project-boundary.md`.
6. Record non-default model tiers, specialist dispatch state, and
   direct-write exceptions in the turn summary or Turn Ledger.
7. Confirm that no customer-facing question is asked in the final line
   of the turn if there are still active background subagents or tasks
   in-flight (violating R-1 / Hard Rule #11).

## Harness Compatibility Notes

- **Claude Code** reads `CLAUDE.md` natively and uses `.claude/settings.json`
  for hooks and permissions.
- **OpenCode** reads this `AGENTS.md` and `opencode.json` for permissions,
  with subagents defined in `.opencode/agents/`.
- **Codex** reads this `AGENTS.md` and uses `.codex/` TOML adapters.

<!-- SPECKIT START -->
For additional context about technologies to be used, project structure,
shell commands, and other important information, read the current plan
<!-- SPECKIT END -->
