---
name: dispatch-template
description: Structural aid for tech-lead dispatching a single task to a specialist. No CI enforcement — dispatch is ephemeral.
template_class: dispatch
---


# Dispatch — <Task ID> → <target role>

<!-- TOC -->

- [Dispatch identification](#dispatch-identification)
- [Task (one only)](#task-one-only)
- [Context and links](#context-and-links)
- [File boundary](#file-boundary)
- [Acceptance / Definition of Done](#acceptance--definition-of-done)
- [Routed-through class (multi-file batches)](#routed-through-class-multi-file-batches)
- [Report-back expectations](#report-back-expectations)

<!-- /TOC -->

<!-- NON-BINDING STRUCTURAL AID. This template has no CI gate; dispatch
records are ephemeral. Its purpose is to make the one-task-per-dispatch
rule the default shape: filling in singular fields makes bundling
two tasks into one dispatch structurally awkward. If you find yourself
writing a second task here, stop — open a second dispatch instead.

Canonical rule (binding, repeated verbatim across the framework):
  Tasks dispatch individually, never bundled — one task = one dispatch. -->

Owned by `tech-lead`. One file (or inline block) per dispatch.

---

## Dispatch identification

- **Dispatch ID:** D-<timestamp or sequence> (ephemeral; for log reference)
- **Dispatched by:** `tech-lead`
- **Target role:** `<software-engineer | qa-engineer | tech-writer | …>`
- **Dispatched at:** YYYY-MM-DDThh:mmZ

---

## Task (one only)

<!-- ONE task per dispatch. A second task requires a second dispatch. -->

- **Task ID:** T-NNNN (or issue URL)
- **Parent story:** S-NNNN (or "standalone" / "spike")
- **Statement:** One or two sentences. What changes, where.
- **Tier:** tiny | standard | regulated/safety | release
- **Trigger clauses (from task DoR):** `<clauses | none>`

> Do not add a second task here. Open a new dispatch for the next task.

---

## Context and links

Concise. Link; do not paste. The specialist reads these before starting.

- **Token budget:** `tiny` | `small` | `medium` | `large` | `xl`
- **JIT file list (with line ranges):** 
  - `<path>#L<start>-L<end>` (or "none")
- **Tech-lead Pre-Assembly File (for large/xl tasks):** `<path to .claude/tmp/T-NNNN-context.json | none>`
- Prior-art doc (if trigger fired): `docs/prior-art/<task-id>.md`
- ADR (if applicable): `docs/adr/<adr-id>.md`
- Proposal (if applicable): `docs/proposals/<task-id>.md`
- Relevant `CUSTOMER_NOTES.md` entries: <anchors>
- Other: <link>

---

## File boundary

Which paths are in scope for this dispatch. List them explicitly.
Framework-managed files are out of scope unless the task records explicit
customer authorization (see `docs/framework-project-boundary.md`).

In scope:
- `<path>`

Out of scope (explicit):
- `<path>` — reason

---

## Acceptance / Definition of Done

Copy the task's acceptance criteria here for the specialist's reference.
Full DoD lives in `docs/templates/task-template.md`.

- AC-1: <condition>
- AC-2: <condition>

Gate requirements for this dispatch:
- [ ] `code-reviewer` approval required before closure (Hard Rule #3)
- [ ] Customer sign-off required (if safety-critical or Hard Rule #4 path)
- [ ] `security-engineer` sign-off required (if Hard Rule #7 path)

---

## Routed-through class (multi-file batches)

Required when the specialist's output touches files owned by more than one
role (e.g., CI config → `release-engineer`; user-visible docs → `tech-writer`).
Per FW-ADR-0011 R3, state the class per file before the specialist starts.

| Path | Routed-through role | Notes |
|---|---|---|
| `<path>` | `<role>` | |

Omit this section entirely if all files are owned by the target role.

---

## Report-back expectations

What the specialist returns to `tech-lead` on completion:

- [ ] Paths of files created or modified (absolute)
- [ ] Test runner output (exit code, pass/fail counts, timestamp) if code changed
- [ ] Any discovered framework gaps to queue in `docs/ISSUE_FILING.md`
- [ ] Any open question that blocked or narrowed scope, for `docs/OPEN_QUESTIONS.md`
- [ ] Token budget band consumed (for PM ledger if threshold met)

---

## Agent-panel contact redirect (standing instruction — include verbatim in every dispatch)

If the user addresses you directly in the agent panel, reply with:
"Please send all input to the main Claude Code session (tech-lead), not
the agent panel." Then wait; do not act on agent-panel user input. Note
also: pasted content arriving in the agent panel appears as
`[Pasted text #N]` placeholders that this context cannot read — the
user must relay such content through the main session via SendMessage.
