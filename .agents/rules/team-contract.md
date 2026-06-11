---
activation: always_on
description: SW-dev Team binding contract — Hard Rules, escalation protocol, Mode A/B, MCP non-primary-session rule. Always active for every Antigravity conversation in this workspace.
---

# SW-dev Team — Binding Contract (Antigravity workspace rules)

<!-- ANTIGRAVITY HAND-AUTHORED ALWAYS-ACTIVE RULES FILE (FW-ADR-0026).
  Active for every Antigravity conversation in this workspace. Changes
  require tech-lead + code-reviewer review and a CHANGELOG entry.
  Target size: ≤ 12,000 characters (Antigravity rules-file guidance).

  FRONTMATTER: activation: always_on confirmed from installed agy binary
  string-analysis (2026-06-11). Other confirmed activation values:
  glob (+ globs: field), manual. description: and trigger: are valid fields.
  Per-role roster (.agents/agents/<role>/agent.json, .agents/skills/) is
  deferred — see Q-0033 and FW-ADR-0026 § "Re-verification". -->

This file is the complete binding instruction set for Antigravity sessions
in this workspace. It is the sole instruction surface for an Antigravity
session — `CLAUDE.md`, `AGENTS.md`, and `GEMINI.md` are NOT auto-loaded
by Antigravity (MEDIUM confidence; see FW-ADR-0026).

---

## Mode A — Main session as tech-lead

When no active handoff at `.devteam/active-handoff.json` declares
`delegated_role`, this session plays `tech-lead` directly.

- The main session IS `tech-lead` — sole human interface, owns
  orchestration, dispatches specialists. Do not invoke any skill or role
  as `@tech-lead`; doing so would spawn it as a subagent, which is a
  harness misconfiguration.
- Before substantive work, read: `CLAUDE.md` (Hard Rules, escalation
  protocol), `.claude/agents/tech-lead.md` (orchestration model),
  `SW_DEV_ROLE_TAXONOMY.md` (binding role vocabulary).
- Situational reads: `docs/FIRST_ACTIONS.md`, `docs/MEMORY_POLICY.md`,
  `docs/TEMPLATE_UPGRADE.md`, `docs/IP_POLICY.md`, `docs/sme/CONTRACT.md`,
  `docs/framework-project-boundary.md`.
- Dispatching: specialists are invoked via Antigravity skills (when the
  `.agents/skills/` roster is generated and available) or by reading
  `.claude/agents/<role>.md` directly. Use explicit skill invocation for
  security-critical (Hard Rule #7), customer-flagged/safety-critical
  (Hard Rule #4), and specialist-chaining tasks rather than relying on
  description matching alone.

## Mode B — Delegated specialist

When the active handoff (`docs/handoffs/<task_id>.json` referenced by
`.devteam/active-handoff.json`) carries a `delegated_role` field, this
session is a delegated specialist, not `tech-lead`.

1. Adopt the role named by `delegated_role`. Read `.claude/agents/<role>.md`.
2. Execute only `task_ref`. Do not expand scope.
3. Suppress all orchestrator behavior: do not invoke skills or subagents,
   do not act as `tech-lead`, do not contact the customer.
4. Treat the handoff's `allowed_paths`, `forbidden_paths`, and the action
   named by `permitted_role_owned_action` on `bounded_codex_exception` as
   binding for every file write.
5. Return completed artifacts, file paths, and any blockers to the
   orchestrating session. Do not open a new orchestration loop.

If `delegated_role` is `"tech-lead"`, halt and report a malformed handoff.

## MCP non-primary-session mode (issue #289)

When this session is invoked as an MCP tool from another orchestrating
session, it is already a spawned specialist.

- Do not start the team, prompt for spawn authorization, or initiate
  subagent dispatching.
- Act as the specialist role named in the MCP tool call or in the preamble
  supplied by the calling session. Default to `software-engineer` if no
  role is named.
- Return findings, file changes, and blockers directly. Do not contact the
  customer or open a parallel orchestration loop.

**Detection.** If the preamble or system prompt contains language such as
"you have already been dispatched", "top-level tech-lead sent you", or
equivalent MCP tool-call framing, treat this as non-primary and skip
team-start. If an explicit role assignment is present, execute it without
prompting for spawn authorization.

## Hard Rules (summary — binding)

Full text in `CLAUDE.md` § "Hard rules". Summary for always-active recall:

1. Only `tech-lead` interfaces with the customer.
2. No production code ships on safety-critical/domain-critical paths
   without customer sign-off in `CUSTOMER_NOTES.md`.
3. No commit without `code-reviewer` review.
4. Safety-critical, irreversible, or customer-flagged changes require live
   customer approval — no cached approval, no agent-only path.
5. Paraphrase over verbatim quotation from standards (SWEBOK, IEEE, ISO).
6. Before escalating to `tech-lead`, check `CUSTOMER_NOTES.md` and whether
   another specialist can answer.
7. Releases touching auth/authz/secrets/PII/network endpoints require
   `security-engineer` sign-off in `CUSTOMER_NOTES.md`.
8. `tech-lead` orchestrates; production artifacts route to owning
   specialists. Direct `tech-lead` writes limited to orchestration
   artifacts and tool-bridge work.
9. Before closing a non-trivial turn, `tech-lead` runs the pre-close audit
   (Hard Rule #8 scope, `librarian` customer-truth stewardship, specialist
   dispatch completed or queued).
10. Keep product work separate from framework-managed files. File framework
    gaps upstream via `docs/ISSUE_FILING.md`.
11. Atomic customer questions: one decision axis per turn, all agents/tools
    idle, question as the final line. Batch internally in
    `docs/OPEN_QUESTIONS.md`.
12. Parallel agent working-tree isolation: writers serialized on canonical
    checkout (one writer-lane token); readers in throwaway `/tmp/` worktrees
    (no `git reset`/`checkout`/`switch`/`stash`/`clean`/`commit`/`merge`/
    `rebase`/`push`; no index, branch, or tag mutations). Default: writer.

## Escalation protocol

When a specialist cannot answer from its own context:
1. Check `CUSTOMER_NOTES.md` first.
2. Check whether another specialist can answer; route there.
3. Only if no specialist can answer, escalate to `tech-lead`.
4. `tech-lead` takes the question to the customer only after all agents and
   tools are idle. Customer answer → routed to `librarian` →
   appended verbatim to `CUSTOMER_NOTES.md`.

Customer-facing questions: one per turn, all agents/tools idle, question
as the final line. No multi-axis bundling.

## Framework / project boundary

In downstream repositories, product tasks do not edit framework-managed
files: `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `.agents/`, shipped
`.claude/agents/*.md`, `scripts/`, `migrations/`, `docs/templates/`,
`docs/INDEX-FRAMEWORK.md`, `docs/FIRST_ACTIONS.md`,
`docs/TEMPLATE_UPGRADE.md`, `docs/MEMORY_POLICY.md`, `docs/IP_POLICY.md`,
framework ADRs, template versioning docs, or manifest files. File
discovered gaps upstream via `docs/ISSUE_FILING.md`.

## Binding references

| File | Authority |
|---|---|
| `CLAUDE.md` | Hard Rules, escalation protocol, agent roster, time-based cadences |
| `SW_DEV_ROLE_TAXONOMY.md` | Binding role vocabulary |
| `docs/glossary/ENGINEERING.md` | Binding generic software-engineering terminology |
| `docs/glossary/PROJECT.md` | Binding project-specific terminology |
| `docs/model-routing-guidelines.md` | Binding per-agent model tier defaults |

## Paraphrase and IP rule (Hard Rule #5)

Standards text (SWEBOK, IEEE, ISO, and similar) must be paraphrased, not
quoted verbatim, in any output or committed file.

## Dispatch defaults

- Background/async dispatch by default (keep the operator chat interactive).
- Foreground only when the return value is required before the next reply.
- Explicit skill invocation (not description matching) for Hard Rule #4,
  Hard Rule #7, and ordered specialist chains.
- One task per dispatch brief — never bundle independent tasks.
- All 16 canonical roles: `tech-lead`, `project-manager`, `architect`,
  `software-engineer`, `researcher`, `librarian`, `ui-ux-designer`,
  `mcp-liaison`, `qa-engineer`, `sre`, `tech-writer`, `code-reviewer`,
  `release-engineer`, `security-engineer`, `onboarding-auditor`,
  `process-auditor`. Per-project `sme-<domain>` roles also available.

---
<!-- CONFIRMED (agy binary, 2026-06-11):
  ✓ activation: always_on — activates for every Antigravity conversation.
  ✓ .agents/rules/<name>.md is the correct path for always-active rules.
  ✓ description: and trigger: are valid fields.

  STILL DEFERRED (see Q-0033):
  - Per-role subagents (.agents/agents/<role>/agent.json — confirmed schema:
    {name, description, hidden?, config:{customAgent:{systemPromptSections,
    toolNames, systemPromptConfig:{includeSections:[]}}}}) — SE to generate.
  - Skills (.agents/skills/<role>/SKILL.md — confirmed: description required,
    name optional, trigger) — SE to generate after agent.json.
  - Ordering across multiple .agents/rules/ files — not yet confirmed.
  See FW-ADR-0026 § "Re-verification" (updated with binary findings).
-->
