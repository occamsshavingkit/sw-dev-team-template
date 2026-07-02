# Multi-Harness Agent Instructions

This project is a multi-agent software-development template that must
run under Claude Code, OpenCode, Codex, and Gemini CLI. If a harness
cannot satisfy a binding instruction, record the incompatibility, stop
the affected work, and escalate instead of silently weakening the rule.

## Harness Entry Points

| Harness      | Entry Point |
|--------------|-------------|
| Claude Code  | `CLAUDE.md` |
| OpenCode     | `AGENTS.md` |
| Codex        | `AGENTS.md` |
| Gemini CLI   | `GEMINI.md` |

## Role Binding

The main session plays `tech-lead` directly. Do not spawn `tech-lead`
as a subagent. The top-level session is the sole human interface, owns
orchestration, and dispatches specialists.

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
contract.

## Framework / Project Boundary

In downstream repositories, distinguish product work from the
`sw-dev-team-template` framework embedded in the same tree. Before
a session reviews, stages, commits, or edits broad change sets,
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

## Specialist Role Mapping

Canonical role files in `.claude/agents/` map to agents across all
harnesses:

| Role                 | Canonical File                          |
|----------------------|----------------------------------------|
| `architect`          | `.claude/agents/architect.md`          |
| `software-engineer`  | `.claude/agents/software-engineer.md`  |
| `qa-engineer`        | `.claude/agents/qa-engineer.md`        |
| `code-reviewer`      | `.claude/agents/code-reviewer.md`      |
| `researcher`         | `.claude/agents/researcher.md`         |
| `librarian`          | `.claude/agents/librarian.md`          |
| `ui-ux-designer`     | `.claude/agents/ui-ux-designer.md`     |
| `mcp-liaison`        | `.claude/agents/mcp-liaison.md`        |
| `security-engineer`  | `.claude/agents/security-engineer.md`  |
| `sre`                | `.claude/agents/sre.md`                |
| `project-manager`    | `.claude/agents/project-manager.md`    |
| `release-engineer`   | `.claude/agents/release-engineer.md`   |
| `tech-writer`        | `.claude/agents/tech-writer.md`        |
| `onboarding-auditor` | `.claude/agents/onboarding-auditor.md` |
| `process-auditor`    | `.claude/agents/process-auditor.md`    |
| `sme-<domain>`       | `.claude/agents/sme-<domain>.md`       |

For each dispatch, tell the specialist to read its role file and any
matching `-local.md` supplement before acting. Keep write scopes
disjoint when parallelizing, and verify returned file changes before
accepting a write task.

Use `docs/AGENT_NAMES.md` as the public teammate-name map. Customer-
facing text, Turn Ledgers, queue entries, and handovers use the project
teammate name, or the canonical role when no teammate name is assigned.
