# Codex Agent Instructions

This project is a multi-agent software-development template that must
run under both Codex and Claude Code.

## Role Binding

The main Codex session plays `tech-lead` directly. Do not spawn
`tech-lead` as a subagent. The top-level session is the sole human
interface, owns orchestration, and dispatches specialists.

Before starting substantive work, read:

1. `CLAUDE.md`
2. `.claude/agents/tech-lead.md`
3. Any project-local `.claude/agents/tech-lead-local.md`, if present

Treat `CLAUDE.md` and `.claude/agents/*.md` as the shared team
contract. Claude Code reads them natively; Codex uses this `AGENTS.md`
as the adapter into the same contract.

## Framework / Project Boundary

In downstream repositories, distinguish product work from the
`sw-dev-team-template` framework embedded in the same tree. Before a
Codex session reviews, stages, commits, or edits broad change sets,
read `docs/framework-project-boundary.md` and apply its path ownership
model.

Default rule: product tasks do not edit framework-managed files such as
`CLAUDE.md`, this `AGENTS.md`, shipped `.claude/agents/*.md`,
`scripts/`, `migrations/`, `docs/templates/`, `docs/INDEX-FRAMEWORK.md`,
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

## Specialist Dispatch In Codex

When the active Codex harness exposes subagent spawning, `tech-lead`
may dispatch specialists with Codex's native subagent facility only
after the customer authorizes multi-agent work for the current session.
Record the authorization in the turn summary or Turn Ledger. A prior
session's approval does not carry forward.

Before any Codex dispatch, read `docs/model-routing-guidelines.md`
for the role tier and `reasoning_effort`, and `docs/agent-health-contract.md`
for slot state, queueing, completion, and liveness vocabulary; record
the selected effort and slot-health state in the turn summary or Turn
Ledger.

Specialist dispatch briefs, whether sent through Claude Code `Agent` or
Codex `spawn_agent`, must be concise, role/task-specific, and limited to
the context needed for that specialist's assignment. Do not fork or paste
the full top-level conversation, broad repo state, or unrelated project
context into a specialist; cite required files or sections for the
specialist to read instead, so the top-level session preserves its own
context budget.

If spawning is unavailable, continue as a single top-level
`tech-lead` session, record "Codex spawning unavailable" in the turn
summary, and do not claim specialist work occurred. If spawning exists
but no slot is free, record "Codex specialist slot unavailable",
queue the specialist brief, and wait for a slot; do not implement the
queued specialist's work locally unless the customer explicitly grants
an exception for that item.

Map the canonical role files to Codex agent prompts:

- `architect` -> `.claude/agents/architect.md`
- `software-engineer` -> `.claude/agents/software-engineer.md`
- `qa-engineer` -> `.claude/agents/qa-engineer.md`
- `code-reviewer` -> `.claude/agents/code-reviewer.md`
- `researcher` -> `.claude/agents/researcher.md`
- `security-engineer` -> `.claude/agents/security-engineer.md`
- `sre` -> `.claude/agents/sre.md`
- `project-manager` -> `.claude/agents/project-manager.md`
- `release-engineer` -> `.claude/agents/release-engineer.md`
- `tech-writer` -> `.claude/agents/tech-writer.md`
- `onboarding-auditor` -> `.claude/agents/onboarding-auditor.md`
- `process-auditor` -> `.claude/agents/process-auditor.md`
- `sme-<domain>` -> `.claude/agents/sme-<domain>.md`

For each dispatch, tell the specialist to read its role file and any
matching `-local.md` supplement before acting. Keep write scopes
disjoint when parallelizing, and verify returned file changes before
accepting a write task.

Use `docs/AGENT_NAMES.md` as the public teammate-name map. If the
Codex harness returns arbitrary worker names or IDs, treat them as
internal handles only; customer-facing text, Turn Ledgers, queue
entries, and handovers use the project teammate name, or the canonical
role when no teammate name is assigned.

Close completed specialists promptly after their results are reviewed
and any durable output is verified. When queued work exists, free the
slot, dispatch the next queued specialist wave, and record the wave in
the Turn Ledger.

Codex specialist state vocabulary is binding: `queued`, `running`,
`completed`, `failed`, `closed`, and `unknown/unreachable`. A
`wait_agent` timeout, empty status, missing transcript, or absent
return payload is `unknown/unreachable`, not `completed`; it does not
authorize `tech-lead` to perform the specialist's work locally. Preserve
the issue #100 rule: silent workers do not collapse specialist work into
top-level implementation.

When status is ambiguous, send one direct status-check ping asking the
specialist to return completed findings, a stuck-state summary, or
confirmation that it has not started and remains queued. Give the ping a
bounded response window, normally 60 seconds unless the task brief set a
stricter liveness rule. After repeated timed-out waits or status pings,
close the silent or unknown specialist if the harness permits, record
the lost report, and re-dispatch the same canonical role with the prior
prompt and surviving context. If close is unavailable, record that
harness limitation and re-dispatch only when capacity permits.

Completed notifications and `wait_agent` results may diverge. Reconcile
channels conservatively: accept work only from durable returned results,
verified file changes, or an explicit completed notification with enough
content to review. If one channel says completed and another is empty or
timed out, treat the result as incomplete until durable evidence exists.

## Harness Vocabulary

Claude Code examples refer to the `Agent` tool with `subagent_type`
and `name`. In Codex, use the equivalent native subagent API exposed by
the harness. Preserve the role name and, where supported, the teammate
name from `docs/AGENT_NAMES.md`.

If the Codex harness does not expose spawning, continue as a single
top-level `tech-lead` session and record the limitation in the turn
summary. Do not pretend a specialist completed work that was never
dispatched.

## Codex Pre-Close Checklist

Codex does not consume Claude Code hooks, so hook-backed safeguards in
`.claude/settings.json` must be mirrored as an explicit checklist before
closing any non-trivial turn:

1. Inspect `git diff --stat` and the relevant diffs.
2. Confirm every direct `tech-lead` edit is within the allowed
   orchestration or tool-bridge scope from `CLAUDE.md` Hard Rule #8.
3. Confirm customer-truth text and customer authorization records were
   routed or queued for `researcher`, not written directly by
   `tech-lead`.
4. Confirm required specialist work was dispatched, queued for a free
   slot, or covered by an explicit customer exception.
5. For product-only audits or fixes, confirm the diff contains no
   accidental framework-managed file edits, including release/version
   files called out in `docs/framework-project-boundary.md`.
6. Record spawning limits, queued work, non-default
   `reasoning_effort`, slot-health state, and direct-write exceptions
   in the turn summary or Turn Ledger.
