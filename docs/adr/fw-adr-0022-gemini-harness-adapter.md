---
name: fw-adr-0022-gemini-harness-adapter
description: >
  Classify gemini-cli as a co-equal harness adapter; define GEMINI.md
  root adapter, .gemini/agents/ roster, routing model for
  description-driven dispatch, and drift-control strategy across the
  three-harness roster (Claude / OpenCode / Gemini).
status: accepted
date: 2026-06-02
---


# FW-ADR-0022 — Gemini harness adapter

<!-- TOC -->

- [Status](#status)
- [Context and problem statement](#context-and-problem-statement)
- [Decision drivers](#decision-drivers)
- [Considered options (Three-Path Rule, binding)](#considered-options-three-path-rule-binding)
  - [Option M — Minimalist](#option-m--minimalist)
  - [Option S — Scalable](#option-s--scalable)
  - [Option C — Creative (experimental)](#option-c--creative-experimental)
- [Decision outcome](#decision-outcome)
- [Design: Gemini harness adapter](#design-gemini-harness-adapter)
  - [1. GEMINI.md root adapter](#1-geminimd-root-adapter)
  - [2. .gemini/agents/ roster](#2-geminiagents-roster)
  - [3. Routing model under description-driven selection](#3-routing-model-under-description-driven-selection)
  - [4. Parity and drift control](#4-parity-and-drift-control)
  - [5. Version floor](#5-version-floor)
- [Consequences](#consequences)
  - [Positive](#positive)
  - [Negative / trade-offs accepted](#negative--trade-offs-accepted)
  - [Follow-up ADRs](#follow-up-adrs)
- [Customer rulings ratified 2026-06-02](#customer-rulings-ratified-2026-06-02)
- [Verification](#verification)
- [Links](#links)

<!-- /TOC -->

---

## Status

- **Accepted** — customer ratified both open rulings 2026-06-02
  (see `CUSTOMER_NOTES.md` entry recorded this turn)
- **Date:** 2026-06-02
- **Deciders:** `architect` (proposed); `tech-lead` + customer (accepted
  2026-06-02)
- **Consulted:** FW-ADR-0008, FW-ADR-0009, FW-ADR-0021;
  `.opencode/agents/` thin-adapter precedent;
  `docs/model-routing-guidelines.md` binding table;
  gemini-cli v0.38.1–v0.44.0 release notes (researcher-verified,
  Tier-1 source)

## Context and problem statement

The framework runs across three harness surfaces: Claude Code (native,
`.claude/agents/`), Codex (`AGENTS.md` adapter), and OpenCode
(`.opencode/agents/` thin adapters, FW-ADR-0009). gemini-cli v0.38.1
introduced native named subagents with independent context and parallel
spawn; v0.44.0 stabilised the surface. gemini-cli selects subagents by
matching task context against each agent's `description` field
(autonomous) or by explicit `@name` invocation — a structurally
different dispatch model from Claude Code's imperative `Agent` tool.

The framework currently has no Gemini adapter. The only `.gemini/`
artifact is the slash-command TOML set under `.gemini/commands/`. There
is no `GEMINI.md` (the auto-loaded context file), no `.gemini/agents/`
roster, and no specification of which session plays `tech-lead`, how
the "sole human interface" rule is enforced, or how the delegated-
specialist mode from FW-ADR-0021 maps onto gemini-cli's dispatch model.
This gap (P12 in the problem register) means a Gemini operator reaches
the canonical role contracts via nothing but repo exploration — the
same advisory-prose-only gap identified as the root of issue #292.

The ADR trigger is a new harness surface (cross-cutting pattern change:
orchestration model, dispatch model, escalation-protocol encoding) and
a new external dependency (gemini-cli). FW-ADR-0009 established the
binding classification: new harnesses are adapters, not peer
orchestrators. This ADR applies that classification to Gemini and
resolves the three structural gaps specific to gemini-cli's dispatch
model: (1) `GEMINI.md` auto-load, (2) description-quality as
load-bearing for autonomous selection, and (3) roster parity / drift
across three adapter surfaces.

## Decision drivers

- gemini-cli's dispatch model uses description-matching for autonomous
  agent selection. Description quality is load-bearing: a weak
  description silently selects the wrong agent. This is structurally
  different from Claude Code's imperative spawn and from Codex's
  subagent facility, and must be accounted for in the adapter design.
- The "sole human interface" and "do not spawn tech-lead as a subagent"
  rules (FW-ADR-0008, CLAUDE.md Hard Rule #1) must be encoded in
  `GEMINI.md` so a Gemini session self-orients correctly without
  operator intervention.
- FW-ADR-0021's delegated-specialist mode (P8: when invoked as a
  bounded specialist, adopt the handoff role, suppress orchestrator
  behavior) must be reachable from Gemini. The `delegated_role` field
  on the handoff contract is harness-agnostic; `GEMINI.md` must carry
  the same delegated-specialist prose `AGENTS.md` now carries.
- Three roster copies (`.claude/agents/`, `.opencode/agents/`,
  `.gemini/agents/`) plus two root adapters (`AGENTS.md`, `GEMINI.md`)
  create a drift surface. The existing `compile-runtime-agents.sh`
  + `canonical_sha` pattern (FW-ADR-0009) already solves the OpenCode
  case; Gemini must be added to the same generation path rather than
  maintained by hand.
- gemini-cli `model` frontmatter in `.gemini/agents/` maps to the
  binding per-agent default-class table in
  `docs/model-routing-guidelines.md`. The adapter must not introduce
  a parallel routing policy.
- Version floor required: gemini-cli < v0.38.1 has no named subagent
  surface; the adapter is meaningless below that version.

## Considered options (Three-Path Rule, binding)

### Option M — Minimalist

Ship a single `GEMINI.md` root file (the auto-loaded context file) that
instructs Gemini to read `CLAUDE.md` and `.claude/agents/tech-lead.md`,
plus a short note on each role available and how to call them via
`@name`. Do not create `.gemini/agents/` files. Roles are described in
prose inside `GEMINI.md` rather than as discrete agent definitions.

- **Sketch:** One new file, `GEMINI.md`, approximately 100 lines.
  Prose maps each role by name and notes the `@name` invocation syntax.
  Autonomous description-driven selection is not supported (no agent
  files to match against); all dispatch must be explicit `@name`. The
  delegated-specialist mode prose is copied from `AGENTS.md`. No
  changes to `compile-runtime-agents.sh` or `scripts/lint-agent-
  contracts.sh`.
- **Pros:** Lowest implementation cost; one file; no new schema fields;
  no generation script changes; works on any gemini-cli version that
  supports `GEMINI.md` auto-load.
- **Cons:** Autonomous agent selection — the feature that makes
  gemini-cli's subagent surface useful — is unavailable. Operators
  must explicitly `@name` every dispatch, which is functionally
  equivalent to Codex with none of the ergonomic benefit. Description
  text in `GEMINI.md` prose duplicates and will drift from canonical
  role descriptions. No `canonical_sha` protection; drift is
  undetected. Does not satisfy the "co-equal full-team harness" design
  requirement.
- **When M wins:** the team needs only light Gemini support as a
  fallback harness with manual dispatch; ergonomic feature parity is
  not required.

### Option S — Scalable

Ship `GEMINI.md` as the full root adapter (parallel to `AGENTS.md`)
plus 13 `.gemini/agents/<role>.md` thin-adapter files modelled on
`.opencode/agents/`. Each agent file carries a `name` slug, a
`description` strong enough to drive autonomous selection, a `model`
field resolved from the binding routing table, and a body pointing to
`.claude/agents/<role>.md`. Extend `scripts/compile-runtime-agents.sh`
to emit `.gemini/agents/` in the same generation pass that emits
`.opencode/agents/`. The generated files carry `canonical_sha`
frontmatter; lint rejects manual edits. `GEMINI.md` encodes the
two-mode contract (orchestrator as `tech-lead`; delegated-specialist
suppression), the `@name` override for deterministic dispatch, and the
version floor. The `description` field in each agent file is authored
once in the generation template, treated as load-bearing, and reviewed
alongside the canonical role contract when it changes.

- **Sketch:** `GEMINI.md` (~150 lines, parallel to `AGENTS.md`); 13
  `.gemini/agents/<role>.md` files (~15 lines each, generated);
  `compile-runtime-agents.sh` extended (~30 lines); lint extended to
  cover Gemini adapters. Total new surface: one root file, 13 generated
  adapters, one script extension. No new schema fields beyond what
  FW-ADR-0021 already added.
- **Pros:** Autonomous selection works and is reliable because
  descriptions are strong and lint-protected. Drift is machine-
  detected via `canonical_sha`. `GEMINI.md` is the single readable
  entry point for a Gemini operator — same ergonomic position as
  `AGENTS.md` for Codex. Delegated-specialist mode is available.
  Model routing stays in the binding table; no parallel policy.
  Implementation cost is low because the generation infrastructure
  already exists.
- **Cons:** The `description` field in each `.gemini/agents/` file is
  load-bearing and requires careful authoring at generation time; a
  weak description silently degrades autonomous selection. Generation
  adds a step to the release process. Requires gemini-cli >= v0.38.1.
- **When S wins:** Gemini is a peer harness with full specialist
  dispatch; autonomous selection is an expected workflow; drift
  control matters because the roster grows.

### Option C — Creative (experimental)

Replace the per-harness static adapter files with a single dynamic
`GEMINI.md` that is generated at session-start by a bootstrapper
script reading `.claude/agents/*.md`, extracting frontmatter, and
writing a fresh `GEMINI.md` with embedded agent stubs. gemini-cli's
`@path` import syntax is used to inline the canonical agent contracts
directly rather than pointing at file paths. No `.gemini/agents/`
directory is needed; `GEMINI.md` itself becomes the full session
context.

- **Sketch:** A `scripts/build-gemini-context.sh` runs before each
  Gemini session, reads all canonical agent files, extracts `name`
  and `description` fields, and writes `GEMINI.md` with `@path`
  imports resolved inline. The file is ephemeral (gitignored or
  regenerated each session). The bootstrapper itself is the single
  authoritative artifact.
- **Pros:** Zero drift by construction — every session reads current
  canonical files. No static adapter files to lint. `@path` import
  reuse avoids prose duplication. Removes the three-roster problem
  entirely for the Gemini surface.
- **Cons:** Requires a bootstrapper script that runs reliably before
  every Gemini session — a new runtime dependency the framework does
  not currently impose. If the script is not run (CI environment,
  new contributor), `GEMINI.md` is absent or stale and the session
  self-orients from nothing. gemini-cli's `@path` import behavior at
  session start is not verified to inline arbitrary agent system prompts
  at the depth needed for the full role contract; this is an
  untested assumption about a v0.44.0 feature surface. The ephemeral-
  file pattern conflicts with the repo-is-the-brief model. High risk
  from an unverified gemini-cli capability assumption.
- **When C wins:** the team controls the full bootstrapper invocation
  path (e.g., via a wrapper script checked into the repo that all
  operators are trained to run); the `@path` inline behavior is
  verified against a real gemini-cli session; and the framework is
  willing to add a mandatory pre-session step. None of these hold
  currently.

## Decision outcome

**Chosen option: S — Scalable**

Option M forfeits the autonomous selection feature that distinguishes
gemini-cli's subagent surface, forces all dispatch to be explicit, and
provides no drift protection — failing the "co-equal harness" design
requirement. Option C rests on an unverified `@path` inline behavior
assumption and introduces a mandatory pre-session bootstrapper that
creates a new failure mode (missing or stale `GEMINI.md`) with no
machine safeguard. Option S maps directly onto the OpenCode pattern
already proven in production (FW-ADR-0009): generated thin adapters,
`canonical_sha` protection, and a root adapter file. The only structural
addition over the OpenCode pattern is the load-bearing `description`
field and the explicit `@name`-override guidance in `GEMINI.md` to give
operators a deterministic dispatch path when autonomous selection would
be ambiguous.

---

## Design: Gemini harness adapter

### 1. GEMINI.md root adapter

`GEMINI.md` is placed at the repository root. gemini-cli auto-loads it
as the session context file (configurable via `settings.json`
`context.fileName`; `GEMINI.md` is the default). It is a root
canonical binding and follows SCREAMING\_SNAKE file-naming per
`docs/markdown-style.md`.

`GEMINI.md` encodes the following, in order:

**Role binding — two modes.**

*Mode A: main session as `tech-lead`.* When a Gemini session is opened
on this repository without an active handoff that declares
`delegated_role`, the session plays `tech-lead` directly. It is the
sole human interface, owns orchestration, and dispatches specialists.
Do not invoke the `tech-lead` agent file as a subagent (`@tech-lead`);
the main session IS `tech-lead`. This rule is identical to the
Claude Code and Codex constraints (CLAUDE.md § "Tech-lead is the main-
session persona"; FW-ADR-0008).

*Mode B: delegated-specialist mode.* If the active handoff
(`docs/handoffs/<task_id>.json` pointed to by `.devteam/active-
handoff.json`) declares `delegated_role`, adopt that role for the
duration of the session. Read `.claude/agents/<role>.md` as the role
contract. Execute the single task named in `task_ref`. Do not spawn
specialists, do not act as `tech-lead`, do not contact the customer.
Return completed artifacts and blockers to the orchestrating session.
This is the same delegated-specialist clause from `AGENTS.md`
(FW-ADR-0021); the prose is substantively identical, not copied
verbatim (IP / paraphrase rule, CLAUDE.md Hard Rule #5).

**Grounding reads.** Before substantive work in Mode A, read:

1. `CLAUDE.md`
2. `.claude/agents/tech-lead.md`
3. Any `docs/agents/manual/tech-lead-manual.md`, if present

Situational reads follow the same list as `AGENTS.md`: `docs/FIRST_
ACTIONS.md`, `docs/MEMORY_POLICY.md`, `docs/TEMPLATE_UPGRADE.md`,
`docs/IP_POLICY.md`, `docs/sme/CONTRACT.md`,
`docs/framework-project-boundary.md`.

**Dispatch guidance — `@name` override.**

gemini-cli selects subagents autonomously by matching task context
against each agent's `description` field. For routine work the
description-matching selection is expected to be correct. When
deterministic dispatch is required — specialist chaining, security-
critical work, customer-flagged critical paths, any Hard Rule #4 / #7
path — use explicit `@<role-slug>` invocation rather than relying on
autonomous selection. The 13 available role slugs are listed in
`GEMINI.md`'s agent roster table.

**Binding references.** `GEMINI.md` carries inline citations to:
`CLAUDE.md` (Hard Rules, escalation protocol, time-based cadences),
`SW_DEV_ROLE_TAXONOMY.md`, `docs/glossary/ENGINEERING.md`,
`docs/glossary/PROJECT.md`, and `docs/model-routing-guidelines.md`
(binding routing table). These are the same binding references that
`AGENTS.md` carries.

**Paraphrase / IP rule.** Standards text (SWEBOK, IEEE, ISO) must be
paraphrased, not quoted verbatim. This applies inside Gemini sessions
as it does on all other harnesses (CLAUDE.md Hard Rule #5).

**Version floor.** gemini-cli >= v0.38.1 required for named subagent
support. Sessions running on older versions will see no `.gemini/agents/`
files and should fall back to explicit `@path`-style guidance, with a
note that full specialist dispatch is unavailable.

### 2. .gemini/agents/ roster

Thirteen `.gemini/agents/<role>.md` files, one per canonical role.
Generated by `scripts/compile-runtime-agents.sh` in the same pass as
`.opencode/agents/`. Each file follows the OpenCode thin-adapter shape:

```yaml
---
name: <role-slug>
model: <gemini-equivalent class from routing table>
canonical_source: .claude/agents/<role>.md
canonical_sha: <sha of canonical file at generation time>
generator: scripts/compile-runtime-agents.sh
generator_version: <script version>
classification: generated
---
```

Body (two lines):

```text
Read `.claude/agents/<role>.md` (canonical role contract).
If `local_supplement` resolves to an existing file, read it after
the canonical file. Act only as that role. Return output in the
role's required format.
```

**`description` field — load-bearing, single source.**

Unlike OpenCode (where description quality is cosmetic because operators
dispatch imperatively), gemini-cli uses `description` for autonomous
agent selection. The canonical `.claude/agents/<role>.md` `description:`
frontmatter field is the single source of truth for this value.
`compile-runtime-agents.sh` reads that field and copies it verbatim into
the generated `.gemini/agents/<role>.md` frontmatter. No separate
Gemini-specific description template exists. If a description needs
sharpening to improve autonomous selection quality, sharpen the canonical
field — this benefits all harnesses and avoids a forked value. A
description that is too generic (e.g., "Software development agent")
will cause silent misrouting and is a `code-reviewer` finding.

Per-role `description` guidance (representative subset):

| Role | Description design intent |
|---|---|
| `tech-lead` | Orchestration, routing, customer interface, escalation — NOT selected autonomously; Mode A only |
| `architect` | ADR authoring, module-boundary decisions, cross-cutting design choices, technology selection |
| `software-engineer` | Implementation, construction, code authoring — single leaf task at a time |
| `code-reviewer` | IEEE 1028 audit, drift detection, pre-commit review |
| `security-engineer` | Auth, secrets, PII, network-exposed endpoints, Hard Rule #7 paths |
| `researcher` | Tier-1 source lookup, CUSTOMER\_NOTES stewardship, standards citations |
| `qa-engineer` | Test design, acceptance criteria, ISTQB-aligned validation |
| `release-engineer` | Build pipeline, IaC, deployment, rollback, release gating |
| `sre` | Operations planning, capacity, DR, incident posture, post-incident review |
| `project-manager` | PMBOK schedule/cost/risk/stakeholder/lessons artifacts |
| `tech-writer` | Documentation, user-facing prose, style-guide compliance |
| `onboarding-auditor` | Zero-context documentation audit — one-shot, milestone-close only |
| `process-auditor` | Cultural-disruptor process audit — one-shot, every 2–3 milestones |

**`model` field mapping.** Each adapter's `model` is set from the
`gemini_equivalent` column of the binding per-agent default-class table
in `docs/model-routing-guidelines.md`:

| Agent | `model` in adapter |
|---|---|
| `tech-lead`, `architect`, `code-reviewer`, `software-engineer`, `release-engineer`, `qa-engineer`, `tech-writer`, `security-engineer`, `sre`, `researcher`, `onboarding-auditor`, `process-auditor`, `sme-template` | `gemini-pro` |
| `project-manager` | `gemini-flash` |

Frontier escalation conditions in the routing table remain the
per-task override trigger; the adapter `model` field is the default.

### 3. Routing model under description-driven selection

gemini-cli's autonomous selection and imperative `@name` invocation are
both valid dispatch paths. The framework's "one role = one agent" and
WIP=1 constraints apply to both paths.

**Autonomous selection (routine work).** When `tech-lead` (the main
session) determines a task belongs to a specialist, it can describe the
task naturally; gemini-cli matches the description against the 13 agent
`description` fields and selects the appropriate specialist. This is the
ergonomic primary path.

**`@name` override (deterministic dispatch).** `tech-lead` MUST use
explicit `@<role-slug>` invocation for:

- Security-critical work (Hard Rule #7 path: `@security-engineer`).
- Customer-flagged critical paths (Hard Rule #4: `@security-engineer`,
  `@architect`, or the named specialist as required).
- Specialist chaining where the next specialist is determined by a
  routing table entry, not by task description alone (e.g., chaining
  `@architect` → `@code-reviewer` → `@release-engineer`).
- Any case where the task description is generic enough that
  description-matching might produce ambiguous or wrong selection.

**No implicit `tech-lead` spawn.** gemini-cli's autonomous selection
must never select the `tech-lead` agent file, because the main session
IS `tech-lead`. The `tech-lead` agent file body must include a guard:
if invoked as a subagent, halt and report a harness misconfiguration.
This mirrors the Codex `AGENTS.md` "do not spawn tech-lead as a
subagent" constraint.

**Hard Rule #1 and #8 encoding.** `GEMINI.md` carries binding prose
making explicit that the main Gemini session is `tech-lead`, not a
general-purpose orchestrator, and that production artifacts route to
owning specialists. The escalation protocol (check `CUSTOMER_NOTES.md`,
route through `tech-lead`, one question per turn) applies unchanged.

### 4. Parity and drift control

The roster now exists in three generated surfaces:

| Surface | Generator | Drift detection |
|---|---|---|
| `.claude/agents/` | Canonical (not generated) | `schemas/agent-contract.schema.json` + lint |
| `.opencode/agents/` | `compile-runtime-agents.sh` | `canonical_sha` mismatch |
| `.gemini/agents/` | `compile-runtime-agents.sh` (extended) | `canonical_sha` mismatch |

Root adapters (`AGENTS.md`, `GEMINI.md`) are hand-authored, not
generated, because they carry harness-specific orchestration prose
that cannot be mechanically derived from the canonical agent contracts.
They are treated as binding framework files; changes require
`tech-lead` + `code-reviewer` review and a CHANGELOG entry.

**Generation extension.** `scripts/compile-runtime-agents.sh` gains a
`--target gemini` path (or runs all targets by default) that:

1. Reads each `.claude/agents/<role>.md`.
2. Computes the `canonical_sha` (SHA-1 of the canonical file).
3. Resolves the `model` from `docs/model-routing-guidelines.md`'s
   Gemini-equivalent column.
4. Copies the `description:` frontmatter field verbatim from the
   canonical agent file into the generated adapter's frontmatter.
5. Emits `.gemini/agents/<role>.md` with the standard thin-adapter
   body.

The `description` field has one home: the canonical
`.claude/agents/<role>.md` frontmatter. No separate Gemini description
template is maintained. This is the same single-source pattern as the
OpenCode generation path.

**Lint extension.** The existing `scripts/lint-agent-contracts.sh`
(the same script that covers `.opencode/agents/`) is extended to cover
`.gemini/agents/`. No separate Gemini-only lint script is added. The
extended script checks:

- Each `.gemini/agents/<role>.md` `canonical_sha` matches the current
  SHA of the referenced `.claude/agents/<role>.md`. Mismatch is an
  error (regenerate required).
- `description` field is present and non-empty.
- `model` field is a valid class name from
  `schemas/model-routing.schema.json`.

**Three-surface sync procedure.** When a canonical agent contract
changes, the releasing agent runs `compile-runtime-agents.sh` (all
targets) before commit. CI runs lint on all three surfaces. A PR that
modifies `.claude/agents/<role>.md` without regenerating
`.opencode/agents/<role>.md` and `.gemini/agents/<role>.md` fails lint.

### 5. Version floor

gemini-cli >= v0.38.1 is required for named subagent support (stable
from v0.44.0). `GEMINI.md` carries a visible version-floor note at the
top of the file. The framework scaffold script (`scripts/scaffold.sh`
or equivalent) adds a gemini-cli version check at setup time.

The `TEMPLATE_UPGRADE.md` migration section for the release that ships
this ADR notes: "if using gemini-cli, upgrade to >= v0.38.1 before
running `compile-runtime-agents.sh` with `--target gemini`."

## Consequences

### Positive

- gemini-cli becomes a co-equal harness: full 13-role roster, autonomous
  dispatch, delegated-specialist mode, model routing, and Hard Rule
  enforcement, all consistent with Claude Code and Codex.
- Description-driven selection is reliable because descriptions are
  sourced from the canonical agent contracts (single source, no fork),
  copied verbatim by the generator, and lint-protected via
  `canonical_sha`.
- Drift across all three adapter surfaces is machine-detected via
  `canonical_sha`. A single `compile-runtime-agents.sh` run keeps all
  three surfaces in sync.
- `GEMINI.md` gives a Gemini operator a single readable entry point
  with the same ergonomic position as `AGENTS.md` for Codex operators.
- The delegated-specialist mode (FW-ADR-0021) is available on the
  Gemini path without any new schema changes.
- `project-manager` gets `gemini-flash` as its default, matching
  the routing table and avoiding frontier spend on PM artifact updates.

### Negative / trade-offs accepted

- `description` quality is load-bearing and must be maintained. A
  description that is too generic silently causes autonomous misrouting;
  this is a new failure mode with no equivalent in Claude Code or Codex.
  Mitigated by: the single-source rule (descriptions are in canonical
  files, not forked), lint checking for non-empty descriptions, and
  the fact that any improvement to a canonical `description:` field
  benefits all harnesses simultaneously.
- `compile-runtime-agents.sh` gains a third output target, which adds
  a step to the release process and a new CI lint surface. Marginal
  cost is low because the infrastructure already exists for OpenCode.
- `GEMINI.md` and `AGENTS.md` are hand-authored and not machine-
  generated; they can drift from each other in harness-specific
  sections. Mitigated by: code-reviewer review on all changes, CHANGELOG
  entry requirement, and cross-reference links in both files.
- gemini-cli's autonomous selection model means the "WIP=1 /
  one role = one agent" constraint is advisory on the autonomous path:
  nothing prevents a Gemini session from invoking two agents in parallel
  if the task description is ambiguous. `tech-lead` (main session) is
  responsible for preventing this via explicit `@name` discipline on
  ordered chains.
- Requires gemini-cli >= v0.38.1. Projects on older versions get no
  subagent support from this adapter.

### Follow-up ADRs

- A future ADR may address `token_budget_hint` → Gemini model tier
  mapping (parallel to the Codex follow-up noted in FW-ADR-0021).
- If gemini-cli exposes a `max_turns` or `timeout_mins` frontmatter
  field that maps to the framework's WIP=1 / slot-queue model, a
  follow-up ADR should pin the binding defaults.
- If description-matching quality proves insufficient for reliable
  autonomous selection across all 13 roles, a follow-up may mandate
  `@name` for all dispatch (reducing gemini-cli to the Codex ergonomic
  model while retaining the adapter shape).

## Customer rulings ratified 2026-06-02

Both open decision points were ratified by the customer 2026-06-02
with the directive "make it all match" (how Codex/OpenCode do it).
The backing customer-truth entry is recorded in `CUSTOMER_NOTES.md`
(researcher-stewarded, same turn).

**Ruling 1 — `description` source (ratified: canonical field, no fork).**
The canonical `.claude/agents/<role>.md` `description:` frontmatter
field is the single source. `compile-runtime-agents.sh` copies it
verbatim into the generated Gemini adapter. Option A (separate
`gemini-agent-descriptions.yaml`) and Option B (new `gemini_description`
frontmatter key on canonical files) are both rejected. If a description
needs sharpening for Gemini autonomous selection quality, sharpen the
canonical field — this benefits all harnesses. No Gemini-specific
description artifact is maintained.

**Ruling 2 — Lint placement (ratified: extend existing script, no new script).**
The existing `scripts/lint-agent-contracts.sh` — the same script that
covers `.opencode/agents/` — is extended to cover `.gemini/agents/`.
No dedicated `scripts/lint-gemini-adapters.sh` is added. The
downstream-toggle-ability argument for a separate script is set aside
per the customer's consistency directive.

## Verification

- **Success signal:** A Gemini session on a repo scaffolded from this
  template reads `GEMINI.md`, self-orients as `tech-lead`, dispatches a
  specialist via autonomous description-matching, and that specialist
  reads its canonical `.claude/agents/<role>.md` contract without
  operator intervention. A handoff with `delegated_role:
  "software-engineer"` causes a Gemini session to adopt
  `software-engineer` mode and suppress orchestrator behavior.
  `compile-runtime-agents.sh --target gemini` regenerates all 13
  adapter files with correct `canonical_sha` values. CI lint passes on
  all three adapter surfaces.
- **Failure signal:** A Gemini session with a correctly formed
  `GEMINI.md` and `.gemini/agents/` roster autonomously selects the
  wrong specialist on two or more documented test tasks, indicating that
  `description` quality is insufficient and the mandatory-`@name` path
  must be enforced for all dispatch (follow-up ADR). Alternatively, if
  gemini-cli changes the agent-definition file format or the context-
  file name in a future release, the adapter shape breaks — triggering
  a superseding ADR.
- **Review cadence:** Re-examine at the first MINOR-boundary release
  after Gemini harness support ships, or after three documented Gemini
  operator sessions in downstream projects, whichever comes first
  (session-anchored per CLAUDE.md § "Time-based cadences").

## Links

- FW-ADR-0008 — tech-lead orchestration boundary (orchestrator /
  specialist split this ADR extends to Gemini):
  `docs/adr/fw-adr-0008-tech-lead-orchestration-boundary.md`
- FW-ADR-0009 — OpenCode harness adapter (thin-adapter precedent and
  four prohibitions this ADR inherits):
  `docs/adr/fw-adr-0009-opencode-harness-adapter.md`
- FW-ADR-0021 — harness-agnostic leaf-task dispatch (delegated-
  specialist mode and `delegated_role` field this ADR adopts):
  `docs/adr/fw-adr-0021-harness-agnostic-leaf-task-dispatch.md`
- Upstream issue #293 — P8 delegated-specialist mode for Codex
  (the parallel P8 concern this ADR extends to Gemini)
- `.opencode/agents/` — thin-adapter precedent files
- `scripts/compile-runtime-agents.sh` — generation script to extend
- `docs/model-routing-guidelines.md` — binding per-agent routing table
  (Gemini-equivalent column)
- `AGENTS.md` — Codex root adapter (structural parallel to `GEMINI.md`)
- gemini-cli release notes v0.38.1 and v0.44.0 (Tier-1 source;
  verified by `researcher`)
