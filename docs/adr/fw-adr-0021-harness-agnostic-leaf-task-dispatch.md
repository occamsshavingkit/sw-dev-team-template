---
name: fw-adr-0021-harness-agnostic-leaf-task-dispatch
description: >
  Decision on dispatch-unit granularity (single leaf T### task,
  harness-agnostic), delegated-specialist role-binding in AGENTS.md,
  and machine-checked enforcement of those constraints.
status: accepted
date: 2026-06-02
---


# FW-ADR-0021 — Harness-agnostic single-task dispatch and delegated-specialist
role mode

<!-- TOC -->

- [Status](#status)
- [Context and problem statement](#context-and-problem-statement)
- [Decision drivers](#decision-drivers)
- [Considered options (Three-Path Rule, binding)](#considered-options-three-path-rule-binding)
  - [Option M — Minimalist](#option-m--minimalist)
  - [Option S — Scalable](#option-s--scalable)
  - [Option C — Creative (experimental)](#option-c--creative-experimental)
- [Decision outcome](#decision-outcome)
- [Design: harness-agnostic leaf-task dispatch](#design-harness-agnostic-leaf-task-dispatch)
  - [1. Dispatch unit — leaf T### task, harness-agnostic](#1-dispatch-unit--leaf-t-task-harness-agnostic)
  - [2. Delegated-specialist mode in AGENTS.md](#2-delegated-specialist-mode-in-agentsmd)
  - [3. Enforcement gate sketch](#3-enforcement-gate-sketch)
  - [4. Relationship to spec 016 and issue #292](#4-relationship-to-spec-016-and-issue-292)
- [Consequences](#consequences)
  - [Positive](#positive)
  - [Negative / trade-offs accepted](#negative--trade-offs-accepted)
  - [Follow-up ADRs](#follow-up-adrs)
- [Verification](#verification)
- [Links](#links)

<!-- /TOC -->

---

## Status

- **Accepted** — customer ratified both open rulings 2026-06-02
  (see `CUSTOMER_NOTES.md` entry recorded this turn)
- **Date:** 2026-06-02
- **Deciders:** `architect` (proposed); `tech-lead` + customer (accepted 2026-06-02)
- **Consulted:** `docs/v1.1-handoff-contracts.md`; `schemas/handoff.schema.json`
  (`bounded_codex_exception` shape); `AGENTS.md` (Codex adapter); `CLAUDE.md`
  Hard Rules #8, #11; `docs/agents/manual/tech-lead-manual.md` § "Dispatch
  discipline"; `docs/pm/findings-2026-06-02-customer-notes-drift.md` (issue
  #292 enforcement-vs-folklore root); `docs/templates/task-template.md` (JIT
  file list and token-budget fields); `docs/workflow-pipeline.md`

## Context and problem statement

The v1.1 handoff-contract spine (`docs/v1.1-handoff-contracts.md`,
`schemas/handoff.schema.json`) established machine-readable task contracts and
bounded-Codex mode. Three gaps surfaced when that infrastructure was used in
practice across both the Claude Code (`Agent` tool) and Codex MCP harnesses.

**P7 — Granularity.** Durable handoffs (`docs/handoffs/<task_id>.json`) are
scoped at feature altitude — an objective spanning a dozen T### leaf tasks, with
`allowed_paths` covering whole directories, and a `bounded_codex_exception`
block granting authority over all of them at once. The per-leaf decomposition
already exists one level down in `tasks.md`, and `docs/templates/task-template.md`
carries the right primitives (a JIT file list and a `tiny|small|medium|large|xl`
token budget hint). However, no binding prose or schema constraint makes a single
leaf task the unit of dispatch — a caller can still hand off a multi-task batch
in one contract and no gate rejects it.

**P8 — Role-binding for delegated-specialist mode.** `AGENTS.md` defines only
one invocation context for Codex: the main session acts as `tech-lead`,
orchestrates, and dispatches specialists. There is no "invoked as a delegated
specialist" mode. When Codex is invoked via the `codex` MCP from a Claude
orchestrator session with an active handoff, it defaults to orchestrator
behavior, reads `AGENTS.md`'s "ask to spawn" rule, and may attempt to spawn
sub-specialists rather than executing the assigned task directly. The
`bounded_codex_exception` schema fields (`codex_permission_flag`,
`permitted_role_owned_action`) exist but the role-binding prose — the instruction
that tells a delegated Codex to adopt the handoff's named role and suppress
orchestrator behavior — is absent from `AGENTS.md`.

**P9 — Enforcement.** Both P7 and P8 are governed by advisory prose, not by any
hook or linter. This is the same advisory-prose-not-gates pattern identified as
the root cause of the `CUSTOMER_NOTES.md` entry-drift problem (issue #292,
`docs/pm/findings-2026-06-02-customer-notes-drift.md`). Dispatch-brief
granularity is described in spec 016 as "folklore" being promoted to binding
prose for the Claude path; this ADR makes it harness-agnostic, extends it to the
Codex path, and pairs it with a machine-checkable gate.

ADR triggers: cross-cutting pattern change (dispatch-unit convention + new
`AGENTS.md` mode); public boundary change (new required field shape on the
handoff contract that hooks validate); enforcement-mechanism choice (same root
as #292).

## Decision drivers

- The repo IS the brief. Both Claude subagents and Codex self-orient from the
  repo via `AGENTS.md` / `CLAUDE.md`; no orientation blob needs to be packed
  into a dispatch contract. Handoff contracts carry task scope only.
- "One T### task per dispatch, never bundled" is already applied to Claude
  subagents by convention; it must be promoted to a machine-checked rule and
  extended to the Codex path.
- Delegated Codex defaults to orchestrator mode. Without an explicit mode signal
  in `AGENTS.md`, a bounded-Codex invocation will attempt to spawn rather than
  execute, defeating the handoff's `permitted_role_owned_action` field.
- The token-budget and JIT file list fields in `docs/templates/task-template.md`
  exist; the rule that makes them load-bearing belongs in the handoff contract
  and in `AGENTS.md`, not only in a template.
- Enforcement-via-prose has repeatedly failed (issue #292). A gate that rejects
  non-conforming contracts at commit time is the only durable fix.
- Changes to `AGENTS.md` affect both harnesses; prose must be unambiguous about
  which mode is active and who controls it.

## Considered options (Three-Path Rule, binding)

### Option M — Minimalist

Add a short binding paragraph to `AGENTS.md` and to `tech-lead-manual.md`'s
"Dispatch discipline" section stating (a) one leaf task per dispatch, (b) if a
handoff's `bounded_codex_exception.codex_permission_flag` is true and a
`permitted_role_owned_action` is set, adopt that role and do not spawn. No schema
change. No hook. The rule is advisory prose, promoted from folklore to a named
binding rule in two docs.

- **Sketch:** Two paragraph additions and an `AGENTS.md` mode table. No new
  schema fields. No gate script. Implementation cost: one PR touching
  `AGENTS.md` and `docs/agents/manual/tech-lead-manual.md`.
- **Pros:** Zero schema migration; lowest implementation cost; immediately
  deployable; no new failure mode from a flawed gate.
- **Cons:** Preserves the advisory-prose-not-gates pattern that produced issue
  #292 and is explicitly called out as the root gap by spec 016 and the
  findings doc. A delegated Codex that mis-reads mode signals (or runs a stale
  `AGENTS.md` snapshot) has no hook to catch it. Per-leaf granularity remains
  unenforced; a caller can still dispatch a multi-task batch without rejection.
- **When M wins:** the team accepts that operator discipline is the dominant
  control; automation cost is prohibitive; the enforcement gap is tolerable
  under the current project scale.

### Option S — Scalable

Promote the leaf-task dispatch unit to a **required schema field** on the
handoff contract (`dispatch_scope: "single_task"` + a `task_ref` field
pointing into `tasks.md`) alongside a `delegated_role` field used when the
harness is invoked as a specialist. A pre-commit hook (extending the existing
handoff-gate pattern in `scripts/hooks/`) validates: (a) when
`bounded_codex_exception.codex_permission_flag` is true, `delegated_role` must
be present and must not be `tech-lead`; (b) when `dispatch_scope` is
`single_task`, `task_ref` must be non-null and point to a recognized task ID.
`AGENTS.md` gains a "Delegated-specialist mode" section: "if the active handoff
declares `delegated_role`, adopt that role, execute the single named task, and
do not spawn specialists." Feature-scoped handoffs (the existing feature-altitude
contracts like `fw-012`) are grandfathered as `dispatch_scope: "feature"` and
are not dispatched directly to bounded Codex — they are orchestrator artifacts
only.

- **Sketch:** Schema adds two optional fields (`dispatch_scope` and
  `task_ref`; required only when `codex_permission_flag: true`). `AGENTS.md`
  gains a mode-selection table (one page). Hook adds one validation path (~30
  lines). Downstream handoffs continue to work without change unless they use
  bounded-Codex mode. Implementation cost: one PR touching schema, one hook
  extension, one `AGENTS.md` section, one `tech-lead-manual.md` paragraph.
- **Pros:** Machine-checked; closes the enforcement gap for both P7 and P8;
  gradual adoption (existing feature-scoped handoffs are unaffected); maps
  cleanly to the existing `bounded_codex_exception` structure; `delegated_role`
  also serves as the self-orientation signal for any future harness (not Codex-
  specific); eliminates the "defaulting to orchestrator" behavior by making
  role adoption the contract, not a per-call override.
- **Cons:** Schema version bump required; existing bounded-Codex test fixtures
  must be extended; slightly more author friction per leaf-task handoff
  (two new fields); gate adds a new failure mode if misimplemented.
- **When S wins:** enforcement is a named requirement (post-issue-#292); the
  team will author multiple bounded-Codex handoffs; the hook infrastructure
  already exists and extending it is low marginal cost.

### Option C — Creative (experimental)

Replace the JSON handoff contract with an executable dispatch manifest: a
YAML or TOML file that is simultaneously the task spec, the dispatch brief,
and a self-contained role-binding script. A thin harness shim reads the
manifest, sets `DELEGATED_ROLE` as an env var, and injects a preamble into
the agent's system prompt before the agent reads any repo file. The manifest
contains a `tasks:` array; each item is exactly one leaf task. The harness
shim rejects arrays with more than one item in the current active slot.
Schema validation collapses into shim validation; no separate hook.

- **Sketch:** Replace `docs/handoffs/*.json` + `schemas/handoff.schema.json`
  with a new manifest format. Write a small Python shim (`scripts/dispatch-
  shim.py`) that validates the manifest, injects the role preamble, and
  invokes the agent. All existing handoff JSON files are migrated or wrapped.
- **Pros:** Role injection is guaranteed by construction (the shim controls the
  prompt); single-task constraint is structurally enforced (array length 1);
  no separate hook needed; the manifest is self-documenting.
- **Cons:** Requires migrating all existing `docs/handoffs/*.json` files and
  retiring the current schema; adds a new runtime dependency (the shim) on every
  harness invocation path; breaks downstream projects that have adopted the v1.1
  JSON format; diverges from the repo-is-the-brief model by making the shim a
  mandatory intermediary; high implementation risk from shim bugs that silently
  corrupt the agent's role context. The migration cost alone rejects this given
  the current scale.
- **When C wins:** the team controls both sides of the harness boundary (i.e.,
  operates its own MCP server); the shim can be tested exhaustively; and the
  role-injection guarantee is a hard safety requirement that advisory prose
  cannot satisfy. None of these hold here.

## Decision outcome

**Chosen option: S — Scalable**

Option M preserves the advisory-prose pattern that produced issue #292 and is
explicitly insufficient per the findings doc and spec 016's own framing
("folklore"). Option C requires a migration that breaks downstream v1.1 adopters
and introduces a new runtime dependency with no benefit over a well-written hook.
Option S closes both gaps with minimal surface area: two new schema fields,
one `AGENTS.md` mode section, and one hook extension, all within the existing
handoff-gate pattern. The schema change is additive and conditional (fields are
required only when `codex_permission_flag: true`), so all existing feature-
scoped handoffs continue to pass validation without modification.

---

## Design: harness-agnostic leaf-task dispatch

### 1. Dispatch unit — leaf T### task, harness-agnostic

**The unit of dispatch is a single leaf T### task.** This applies to both Claude
(`Agent` tool) and Codex (MCP invocation) paths. A durable handoff at
feature altitude (`dispatch_scope: "feature"`) is an orchestrator artifact only;
it is never the direct input to a bounded-Codex or Agent-tool invocation.

A leaf-task handoff (`dispatch_scope: "single_task"`) carries:

| Field | Meaning |
|---|---|
| `dispatch_scope` | `"single_task"` — the gate rejects anything else for bounded-Codex |
| `task_ref` | Task ID pointer into `tasks.md` (e.g. `"T041"`) |
| `delegated_role` | Canonical role name the agent must adopt (e.g. `"software-engineer"`) |
| `allowed_paths` | JIT file list — only files needed for this task |
| `token_budget_hint` | `"tiny"` \| `"small"` \| `"medium"` \| `"large"` \| `"xl"` |
| `acceptance_criteria` | Copied or summarized from `tasks.md` T### entry |
| `verification.tests[].command` | Test command that must pass before done |

The `task_ref`, `delegated_role`, and `dispatch_scope` fields are added to
`schemas/handoff.schema.json` under `bounded_codex_exception` (when
`codex_permission_flag: true`, `delegated_role` and `dispatch_scope` become
required). The `token_budget_hint` is a top-level optional field (useful for
both harnesses, not only Codex).

The repo supplies orientation. The dispatch contract carries scope. No
orientation prose is repeated in the contract.

**Feature-altitude handoffs are grandfathered.** Existing contracts (e.g.
`docs/handoffs/fw-012-v1-1-handoff-contracts.json`) carry `dispatch_scope:
"feature"` (default when the field is absent) and are not affected by the new
gate. They remain valid orchestration artifacts for planning and audit; they
are not dispatch inputs.

### 2. Delegated-specialist mode in AGENTS.md

`AGENTS.md` gains a "Delegated-specialist mode" section immediately after "Role
Binding," with the following binding prose:

> If the active handoff (`docs/handoffs/<task_id>.json` pointed to by
> `.devteam/active-handoff.json`) declares `delegated_role`, this Codex session
> is operating as a delegated specialist, not as `tech-lead`.
>
> In delegated-specialist mode:
>
> - Adopt the role named in `delegated_role` for the duration of this session.
>   Read the corresponding `.claude/agents/<role>.md` as your role contract.
> - Execute the single task named in `task_ref`. Do not treat the feature-level
>   objective as your scope.
> - Do **not** spawn specialists. Do **not** act as `tech-lead`. Do **not**
>   contact the customer. Return completed artifacts and any blockers to the
>   orchestrating `tech-lead` session.
> - The `permitted_role_owned_action` field on `bounded_codex_exception` names
>   the specific action you are authorized to perform at the top level. Stay
>   within that action and the declared `allowed_paths`.
>
> Presence check: if `delegated_role` is set but is `"tech-lead"`, halt and
> report a malformed handoff — the gate should have rejected this, but if it
> reached you, do not proceed.

This makes role adoption the contract, not a per-call manual override. The
section is harness-agnostic prose; it also applies to any future harness that
reads `AGENTS.md`.

### 3. Enforcement gate sketch

The existing `scripts/hooks/handoff-pre-tool-gate.py` validates handoff
contracts on PreToolUse events. A new validation path is added — invocable
standalone as `scripts/validate-handoff.py --mode bounded-codex` and also
wired as a pre-commit check:

**Assertion A — delegated_role vs. dispatch_scope coherence.**
When `bounded_codex_exception.codex_permission_flag` is true:
- `delegated_role` must be present and must not equal `"tech-lead"`.
- `dispatch_scope` must equal `"single_task"`.
- `task_ref` must be non-null and non-empty.

**Assertion B — single-task scope.**
When `dispatch_scope` is `"single_task"`:
- `allowed_paths` must not overlap with more than one T### task's known
  file set (this check is advisory if `tasks.md` is absent; binding if present).

**Assertion C — feature-scope is not a dispatch input.**
When `dispatch_scope` is `"feature"` (or absent) and
`bounded_codex_exception.codex_permission_flag` is true — this is a
misconfiguration. The gate rejects and explains: feature-altitude handoffs
are orchestrator artifacts; create a leaf-task handoff for direct dispatch.

The gate follows the `lint-questions.sh` / handoff-gate pattern: warn mode
by default, enforce mode via `HANDOFF_GATE_MODE=enforce`. Pre-commit hooks
in `.claude/settings.json` run in enforce mode on bounded-Codex handoffs.

### 4. Relationship to spec 016 and issue #292

Spec 016 ("token economy design") is adding dispatch-granularity discipline as
binding prose in `tech-lead.md` for the Claude Code path. This ADR extends
that ruling to be harness-agnostic (covering Codex via `AGENTS.md`), adds
machine enforcement (the gate sketch above), and frames the `delegated_role`
/ `dispatch_scope` schema fields that make the prose checkable.

Issue #292 (`docs/pm/findings-2026-06-02-customer-notes-drift.md`) identified
that the `CUSTOMER_NOTES.md` entry-drift problem is rooted in advisory prose
with no machine check. This ADR applies the same diagnosis to dispatch
granularity and role-binding, and adopts the same remedy: a hook gate rather
than a prose rule alone. The two problems share a root; the fix pattern is
intentionally the same.

## Consequences

### Positive

- The dispatch unit is unambiguous and harness-agnostic. A reader of any
  handoff contract can determine in one field lookup whether it is an
  orchestrator artifact or a direct dispatch input.
- Delegated Codex no longer defaults to orchestrator behavior. Role adoption
  is the contract; `AGENTS.md` makes the mode explicit rather than relying on
  the caller to pass a manual override per invocation.
- The gate closes the same advisory-prose-not-gates gap identified in issue
  #292, applied to the dispatch path.
- Feature-altitude handoffs are explicitly classified and grandfathered;
  downstream projects already using them need no migration.
- `token_budget_hint` is available to both harnesses; orchestrators can use it
  to select model tier or set reasoning-effort per task.

### Customer rulings ratified 2026-06-02

Both open decision points from the proposed ADR were ratified by the customer
this turn. The backing customer-truth entry is recorded in `CUSTOMER_NOTES.md`
(researcher-stewarded, same turn).

**Ruling 1 — Schema version bump strategy (ratified: MINOR semver bump).**
The new `delegated_role`, `dispatch_scope`, and `task_ref` fields ship as a
MINOR semver bump to the handoff schema (`schemas/handoff.schema.json`). This
is not a v1.2 milestone marker; the bump is self-contained within the current
release line. Schema consumers that do not set `codex_permission_flag: true`
are unaffected (fields are conditionally required).

**Ruling 2 — Gate default mode (ratified: WARN default, ENFORCE opt-in).**
The new validation gate defaults to warn mode. Enforce mode is opt-in via
`HANDOFF_GATE_MODE=enforce`. Because warn is the default, migration of existing
`tests/hooks/fixtures/handoff/bounded-codex-*.json` fixtures is NOT a
prerequisite for shipping the gate — it is a prerequisite only for flipping
enforce on. Downstream projects adopting enforce mode must update their
bounded-Codex fixtures before enabling it.

### Negative / trade-offs accepted

- Schema receives a MINOR semver bump (ratified). Authors of leaf-task
  handoffs using bounded-Codex mode have two additional required fields
  (`delegated_role`, `dispatch_scope`). The overhead is small (~2 lines per
  handoff) but real.
- The gate ships in warn mode by default (ratified). Existing
  `bounded-codex-*.json` fixtures that lack the new fields will produce
  warnings, not failures, until `HANDOFF_GATE_MODE=enforce` is set. Teams
  that want hard enforcement must update those fixtures first — this is
  explicitly a prerequisite for enabling enforce, not for shipping the gate.
- The gate's Assertion B (single-task scope via `allowed_paths` overlap check)
  is advisory when `tasks.md` is absent. Projects that do not maintain a
  `tasks.md` get weaker enforcement.
- `AGENTS.md` prose changes affect both harnesses simultaneously. A Codex
  session running against a stale `AGENTS.md` snapshot will not see the
  delegated-specialist mode section until it re-reads the file.

### Follow-up ADRs

- A future ADR may address `token_budget_hint` → model-routing integration:
  mapping `tiny|small|...|xl` to specific model tiers in
  `docs/model-routing-guidelines.md`.
- If the Assertion B overlap check proves too expensive to maintain against
  `tasks.md`, a follow-up may relax it to a format check only.

## Verification

- **Success signal:** A bounded-Codex invocation against a leaf-task handoff
  with `delegated_role: "software-engineer"` adopts the software-engineer role,
  executes the single named task, and does not attempt to spawn specialists or
  contact the customer. The gate passes in enforce mode on that handoff. A
  feature-altitude handoff with `codex_permission_flag: true` (misconfiguration)
  is rejected by the gate before commit.
- **Failure signal:** A delegated Codex session with a correctly formed handoff
  still defaults to orchestrator behavior (asks to spawn), indicating `AGENTS.md`
  is not being read or the `delegated_role` field is being ignored — triggering
  a superseding ADR on runtime prompt injection (closer to Option C territory).
- **Review cadence:** Re-examine at v1.2.0 scoping or after three documented
  bounded-Codex invocations in downstream projects, whichever comes first.

## Links

- `docs/v1.1-handoff-contracts.md` § "Bounded Codex Mode"
- `schemas/handoff.schema.json` (`bounded_codex_exception` shape)
- `AGENTS.md` (Codex adapter — the file this ADR amends)
- `docs/agents/manual/tech-lead-manual.md` § "Dispatch discipline"
- `docs/pm/findings-2026-06-02-customer-notes-drift.md` (issue #292 root)
- `docs/templates/task-template.md` (JIT file list and token-budget fields)
- `docs/workflow-pipeline.md` § "Three-path design options"
- FW-ADR-0008 (`docs/adr/fw-adr-0008-tech-lead-orchestration-boundary.md`) —
  role-stealing / orchestration-boundary rules this ADR extends to Codex
- FW-ADR-0009 (`docs/adr/fw-adr-0009-opencode-harness-adapter.md`) —
  harness-adapter precedent
- FW-ADR-0020 (`docs/adr/fw-adr-0020-issues-based-coordination-model.md`) —
  handoff-contract authority model this ADR builds on
