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

## Specialist Dispatch In Codex

When the active Codex harness exposes subagent spawning and the user or
operator has authorized multi-agent work, `tech-lead` may dispatch
specialists with Codex's native subagent facility. Map the canonical
role files to Codex agent prompts:

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

## Harness Vocabulary

Claude Code examples refer to the `Agent` tool with `subagent_type`
and `name`. In Codex, use the equivalent native subagent API exposed by
the harness. Preserve the role name and, where supported, the teammate
name from `docs/AGENT_NAMES.md`.

If the Codex harness does not expose spawning, continue as a single
top-level `tech-lead` session and record the limitation in the turn
summary. Do not pretend a specialist completed work that was never
dispatched.
