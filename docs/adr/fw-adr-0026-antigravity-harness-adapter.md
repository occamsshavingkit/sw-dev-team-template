---
name: fw-adr-0026-antigravity-harness-adapter
description: >
  Classify Google Antigravity as a co-equal harness adapter; define the
  .agents/ surface layout (agents.md persona, rules/ always-active
  instructions, skills/<role>/SKILL.md generated roster), the roster
  option chosen, and the drift-control strategy across the four-harness
  roster. Also resolves the MCP non-primary session gap (issue #339).
status: accepted
date: 2026-06-10
---

# FW-ADR-0026 — Antigravity harness adapter

<!-- TOC -->

- [Status](#status)
- [Context and problem statement](#context-and-problem-statement)
- [Decision drivers](#decision-drivers)
- [Considered options (Three-Path Rule, binding)](#considered-options-three-path-rule-binding)
  - [Option M — Minimalist](#option-m--minimalist)
  - [Option S — Scalable](#option-s--scalable)
  - [Option C — Creative (experimental)](#option-c--creative-experimental)
- [Decision outcome](#decision-outcome)
- [Design: Antigravity harness adapter](#design-antigravity-harness-adapter)
  - [1. .agents/agents.md persona file](#1-agentsagentsmd-persona-file)
  - [2. .agents/rules/ always-active instructions](#2-agentsrules-always-active-instructions)
  - [3. .agents/skills/ generated roster](#3-agentsskills-generated-roster)
  - [4. MCP non-primary session parity](#4-mcp-non-primary-session-parity)
  - [5. Parity and drift control](#5-parity-and-drift-control)
  - [6. Surface verification caveat](#6-surface-verification-caveat)
- [Consequences](#consequences)
  - [Positive](#positive)
  - [Negative / trade-offs accepted](#negative--trade-offs-accepted)
  - [Follow-up ADRs](#follow-up-adrs)
- [Verification](#verification)
- [Links](#links)
- [Change log](#change-log)

<!-- /TOC -->

---

## Status

- **Accepted** — autonomous task run 2026-06-10; issues #338 and #339
- **Date:** 2026-06-10
- **Deciders:** `architect` (proposed); `tech-lead` (accepted, autonomous run)
- **Consulted:** FW-ADR-0009, FW-ADR-0022; `.opencode/agents/` and
  `.gemini/agents/` thin-adapter precedents; issue #338 (Antigravity
  surface research, 2026-06-09); issue #339 (MCP non-primary parity
  gap); Antigravity codelabs (accessed 2026-06-10):
  codelabs.developers.google.com/autonomous-ai-developer-pipelines-antigravity,
  codelabs.developers.google.com/getting-started-with-antigravity-skills.

**Supersedes / extends:** FW-ADR-0022 (Gemini harness adapter). This ADR
adds Antigravity as a fourth harness adapter and records the
Antigravity-surface differences from the gemini-cli surface.

---

## Context and problem statement

The framework supports four harness surfaces: Claude Code (native,
`.claude/agents/`), Codex (`AGENTS.md`), OpenCode (`.opencode/agents/`,
FW-ADR-0009), and gemini-cli (`.gemini/agents/`, FW-ADR-0022).

Google Antigravity is an agentic IDE that shares the Gemini model family
but uses a structurally distinct project surface. The fw-adr-0022 adapter
ships a root `GEMINI.md` and `.gemini/agents/` roster — the gemini-cli
surface. Antigravity does not auto-load those files. Instead, Antigravity
reads the `.agents/` directory:

- `.agents/agents.md` — workspace AI persona (Goals / Traits /
  Constraints shape); loaded for every conversation.
- `.agents/rules/` — always-active workspace instructions seen by every
  conversation regardless of skill activation.
- `.agents/skills/<skill-name>/SKILL.md` — modular skill packages with
  mandatory `description` frontmatter used for semantic activation.
  Global counterpart: `~/.gemini/skills/`.
- `.agents/workflows/` — custom slash commands (not used by this adapter).
- MCP config shared with gemini-cli: `~/.gemini/config/mcp_config.json`.

No root `AGENTS.md` or `GEMINI.md` is auto-loaded by Antigravity.

A companion defect (issue #339) identified that the MCP non-primary
session detection rule (issue #289, AGENTS.md § "MCP-connection /
non-primary-session mode") is absent from both `GEMINI.md` and `CLAUDE.md`.
MCP-invoked sessions fall through to Mode A and attempt subagent spawning
rather than executing the dispatched task directly. Both gaps are
resolved in this ADR.

---

## Decision drivers

- Antigravity's `.agents/` surface is structurally different from
  gemini-cli's: session context comes from the persona file and always-
  active rules, not a single root file. Skills are loaded on demand via
  description matching. A gemini-cli-style `GEMINI.md` is never read.
- The "sole human interface" and "do not spawn tech-lead as a subagent"
  rules must be encoded in `.agents/agents.md` so an Antigravity session
  self-orients without operator intervention.
- The MCP non-primary detection rule must be reachable from every harness
  surface. It is currently absent from `GEMINI.md` and `CLAUDE.md`
  (issue #339) causing incorrect orchestrator behaviour on MCP calls.
- Three existing generated adapter surfaces share a compile +
  `canonical_sha` drift-detection pattern. Adding Antigravity to the same
  generation path avoids a fourth manually-maintained roster.
- The Antigravity `description` field in SKILL.md is load-bearing for
  semantic skill activation (analogous to gemini-cli's description-driven
  autonomous selection). The same single-source principle applies: copy
  verbatim from the canonical `description:` frontmatter field.

---

## Considered options (Three-Path Rule, binding)

### Option M — Minimalist

Ship only `.agents/agents.md` (persona, Mode A/B/MCP rules) and
`.agents/rules/team-contract.md` (always-active Hard Rules). Do not
create `.agents/skills/` role adapters. Roles are described in prose.

- **Sketch:** Two hand-authored files (~200 lines total). No compile or
  lint script changes.
- **Pros:** Lowest cost. Always-active rules cover Hard Rules and
  escalation for every conversation. No new generated surface.
- **Cons:** Per-role skill activation is unavailable. No `canonical_sha`
  drift protection. Does not reach the "co-equal harness" target.
- **When M wins:** Only basic Antigravity orientation is needed; no
  per-role specialist skill dispatch; drift control is not required.

### Option S — Scalable

Ship `.agents/agents.md` and `.agents/rules/team-contract.md` as hand-
authored files, plus `.agents/skills/<role>/SKILL.md` generated thin
adapters for all canonical roles. SKILL.md files carry mandatory
`description` frontmatter for semantic activation and `canonical_sha`
for drift protection. Extend `scripts/compile-runtime-agents.sh` and
`scripts/lint-agent-contracts.sh` to cover the nested
`.agents/skills/<role>/SKILL.md` structure.

- **Sketch:** Two hand-authored files; generated SKILL.md files (~20
  lines each); compile script extended (~50 lines); lint script extended
  (~40 lines). GENERATOR_VERSION bumped to 0.3.0.
- **Pros:** Full skill activation, drift protection, single-pass compile
  across all four generated surfaces. Description sourced from canonical
  agent file — no fork.
- **Cons:** SKILL.md nested directory layout diverges from the flat
  OpenCode/Gemini structure; script walkers need targeted handling.
  Antigravity's `classification: generated` frontmatter field is a
  framework convention (Antigravity ignores unknown keys).
- **When S wins:** Antigravity is a peer harness with full specialist
  skill dispatch; drift control matters.

### Option C — Creative (experimental)

Instruct `.agents/agents.md` to read `.claude/agents/<role>.md` directly
via explicit path references; no `.agents/skills/` directory.

- **Sketch:** One hand-authored persona file; no generated artifacts; no
  compile or lint changes.
- **Pros:** Zero maintenance overhead; canonical files are the only copy.
- **Cons:** Relies on Antigravity supporting mid-conversation arbitrary
  file reads — unverified capability assumption. No description-matching
  entry point; no `canonical_sha` drift check.
- **When C wins:** The above capability is confirmed and automatic skill
  activation is not required.

---

## Decision outcome

**Chosen option: S — Scalable**

Option M forfeits per-role skill activation and drift protection. Option
C rests on an unverified Antigravity file-read assumption and provides no
drift protection. Option S maps directly onto the OpenCode and Gemini
patterns already proven in production (FW-ADR-0009, FW-ADR-0022):
generated thin adapters, `canonical_sha` protection, a single compile
pass, and lint coverage. The only structural difference from the Gemini
adapter is the nested SKILL.md directory layout, handled by targeted
walkers in both scripts.

---

## Design: Antigravity harness adapter

### 1. .agents/agents.md persona file

`.agents/agents.md` is a hand-authored Markdown persona definition placed
in the `.agents/` directory. Antigravity loads it for every conversation
as the workspace AI persona. It uses the Antigravity persona format:
`## <Persona Name>` sections, each with **Goal**, **Traits**, and
**Constraint** sub-items.

Three operational modes are encoded:

**Mode A — Main session as `tech-lead`.** When no active handoff declares
`delegated_role`, the session plays `tech-lead`. It is the sole human
interface, owns orchestration, and dispatches specialists via skill
invocation. Do not invoke the tech-lead persona as a sub-call; the session
IS tech-lead. This mirrors GEMINI.md Mode A and AGENTS.md Role Binding.
Grounding reads: `CLAUDE.md`, `.claude/agents/tech-lead.md`, and (if
present) `docs/agents/manual/tech-lead-manual.md`.

**Mode B — Delegated specialist.** When `.devteam/active-handoff.json`
points to a handoff that declares `delegated_role`, adopt that role.
Read `.claude/agents/<role>.md`. Execute only `task_ref`. Do not spawn,
contact the customer, or open an orchestration loop. Mirrors the
FW-ADR-0021 clause carried by AGENTS.md and GEMINI.md. Wording is
paraphrased per Hard Rule #5.

**MCP non-primary session (issues #289/#339).** When the session was
started as an MCP tool call from another session (detection: preamble
signals "Top-level tech-lead dispatched you", "You have already been
spawned", or equivalent MCP framing), suppress all orchestrator behaviour.
Act as the role named in the calling brief; default to `software-engineer`
if no role is specified. Return findings directly in the tool response
without prompting for spawn authorization.

All content is paraphrased per Hard Rule #5; not copied verbatim from
`AGENTS.md` or `GEMINI.md`.

### 2. .agents/rules/ always-active instructions

`.agents/rules/team-contract.md` is placed in `.agents/rules/`.
Antigravity loads every file in this directory for every conversation,
regardless of which skills are active. This makes it the correct home
for rules that must apply unconditionally.

Content (paraphrased per HR-5):

- Paraphrased summary of all binding Hard Rules (CLAUDE.md §
  "Hard rules"), including: sole-human-interface (#1), sign-off
  requirements (#2, #4, #7), code-reviewer gate (#3), no-verbatim-
  standards-text (#5), escalation before customer contact (#6),
  tech-lead-orchestrates-not-authors (#8), pre-close audit (#9),
  framework/product separation (#10), atomic customer questions (#11),
  parallel working-tree isolation (#12).
- Escalation protocol (check CUSTOMER_NOTES.md → route through
  tech-lead → one queued question per turn as the final line).
- Paraphrase / IP rule (HR-5 self-referential).
- Mode A grounding reads.

Additional `.agents/rules/` files may be added per-project without
modifying this framework-managed file.

### 3. .agents/skills/ generated roster

One `.agents/skills/<role>/SKILL.md` per canonical role, generated by
`scripts/compile-runtime-agents.sh` in the same pass as `.opencode/agents/`
and `.gemini/agents/`. The nested directory structure is the Antigravity
convention; the script creates the subdirectory as needed.

Each SKILL.md carries YAML frontmatter following the Antigravity skill
format:

```yaml
---
name: <role-slug>
description: <copied verbatim from canonical description:>
canonical_source: .claude/agents/<role>.md
canonical_sha: <sha of canonical at generation time>
generator: scripts/compile-runtime-agents.sh
generator_version: <script version>
classification: generated
---
```

Body:

```markdown
## Goal
Act as the `<role>` specialist on the sw-dev-team.

## Instructions
Read `.claude/agents/<role>.md` (canonical role contract).
If `.agents/skills/local/<role>/SKILL.md` exists, read it after the canonical file.
Act only as that role.
Return output in the role's required format.
```

**`description` field — load-bearing.** Antigravity uses this field for
semantic skill activation. Single source of truth: the canonical
`.claude/agents/<role>.md` `description:` frontmatter field, copied
verbatim by the generator. Sharpening a canonical description benefits
all four harnesses simultaneously.

**No `model` field.** Antigravity does not consume a per-skill `model`
field (model selection is workspace-global in Antigravity, not per-skill).
The field is intentionally omitted. The `generated-artifact.schema.json`
`model` property is optional, so no schema change is required.

**GENERATOR_VERSION bump.** Version advances from 0.2.0 to 0.3.0 to
mark the addition of the Antigravity output target.

### 4. MCP non-primary session parity

The MCP non-primary detection rule from `AGENTS.md` § "MCP-connection /
non-primary-session mode" (issue #289) is ported to `GEMINI.md` and
`CLAUDE.md` with consistent wording, paraphrased per Hard Rule #5.

In `GEMINI.md`: a new section "## MCP Non-Primary Session" is inserted
after Mode B. Includes: detection heuristic (preamble signals MCP origin),
suppression of orchestrator behaviour, role adoption from calling brief,
default to `software-engineer`, return via tool response.

In `CLAUDE.md`: the existing "Delegated-specialist carve-out" paragraph
is extended to also name the MCP-tool-invocation trigger path, not just
the handoff-file trigger path.

The same rule appears in `.agents/agents.md` as the "MCP Non-Primary
Session" persona section (see §1 above).

### 5. Parity and drift control

The roster now exists across four generated adapter surfaces:

| Surface | Generator | Drift detection |
|---|---|---|
| `.claude/agents/` | Canonical (not generated) | `agent-contract.schema.json` + lint |
| `docs/runtime/agents/` | `compile-runtime-agents.sh` | `canonical_sha` mismatch |
| `.opencode/agents/` | `compile-runtime-agents.sh` | `canonical_sha` mismatch |
| `.gemini/agents/` | `compile-runtime-agents.sh` | `canonical_sha` mismatch |
| `.agents/skills/<role>/` | `compile-runtime-agents.sh` | `canonical_sha` mismatch |

Hand-authored files (`.agents/agents.md`, `.agents/rules/team-contract.md`,
`AGENTS.md`, `GEMINI.md`) are not generated. Changes require `code-reviewer`
review and a CHANGELOG entry.

**Generation extension.** `compile-runtime-agents.sh` gains an Antigravity
output target writing to `.agents/skills/<role>/SKILL.md` (creating the
subdirectory). `--no-antigravity-adapters` suppresses generation. The
verify and reproducibility-check modes are extended to cover this surface.

**Lint extension.** `scripts/lint-agent-contracts.sh` gains a
`scan_antigravity()` function walking `.agents/skills/*/SKILL.md` (handling
the one-level of nesting) and validating each file against
`schemas/generated-artifact.schema.json`, plus an additional check that
`description` is present and non-empty.

**Four-surface sync procedure.** When a canonical agent contract changes,
run `compile-runtime-agents.sh` (all targets) before commit. CI runs
`lint-agent-contracts.sh` on all four generated surfaces. A PR modifying
`.claude/agents/<role>.md` without regenerating all four adapter surfaces
fails lint.

### 6. Surface verification caveat

Antigravity documentation was researched from JS-rendered codelabs (as of
2026-06-09/10). The SKILL.md frontmatter format and `.agents/` loading
semantics were confirmed from official codelabs. If Google changes the
Antigravity surface schema in a future release, the generated SKILL.md
files or `.agents/agents.md` may need updating and a superseding ADR.

---

## Consequences

### Positive

- Antigravity becomes a co-equal harness: always-active binding rules,
  persona-mode switching, and a full-roster skill set with description-
  driven activation — consistent with Claude Code, Codex, OpenCode,
  and gemini-cli.
- The MCP non-primary session rule is now present on all four harness
  surfaces (AGENTS.md, GEMINI.md, CLAUDE.md, .agents/agents.md), closing
  the cross-provider parity gap from issue #339.
- Drift across all four generated surfaces is machine-detected via
  `canonical_sha`. A single compile run keeps all four in sync.
- No new schema is needed; `generated-artifact.schema.json` already
  supports the SKILL.md frontmatter (model is optional).

### Negative / trade-offs accepted

- SKILL.md nested directory layout diverges from the flat OpenCode/Gemini
  adapter structure. Both scripts require targeted walkers — small but
  permanent complexity.
- Hand-authored `.agents/` files can drift from `AGENTS.md` and `GEMINI.md`
  in harness-specific wording. Mitigated by code-reviewer review and HR-5.
- Antigravity surface facts were drawn from codelabs/docs (2026-06-10).
  A future Antigravity version may change the surface schema.

### Follow-up ADRs

- If Antigravity exposes per-skill model tier selection, a follow-up ADR
  should add the `model` field to SKILL.md generation sourced from
  `docs/model-routing-guidelines.md`.
- If `.agents/workflows/` slash commands are needed, a follow-up should
  define the workflow format and generation strategy.

---

## Verification

- **Success signal:** An Antigravity session reads `.agents/agents.md`,
  self-orients as `tech-lead` (Mode A), activates a per-role SKILL.md via
  description matching, and the skill reads the canonical
  `.claude/agents/<role>.md` contract. An MCP tool-call preamble causes
  non-primary mode. `compile-runtime-agents.sh` regenerates all SKILL.md
  files with correct `canonical_sha` values.
  `lint-agent-contracts.sh` passes 0/0.
- **Failure signal:** Antigravity ignores `.agents/agents.md` or
  `.agents/rules/` (surface schema change), or skill activation fails
  consistently (description quality insufficient). Either triggers a
  superseding ADR.
- **Review cadence:** First session after a confirmed Antigravity operator
  run in a downstream project, or at the next MINOR-boundary release
  touching this surface.

---

## Links

- FW-ADR-0009 — OpenCode harness adapter:
  `docs/adr/fw-adr-0009-opencode-harness-adapter.md`
- FW-ADR-0021 — harness-agnostic leaf-task dispatch:
  `docs/adr/fw-adr-0021-harness-agnostic-leaf-task-dispatch.md`
- FW-ADR-0022 — Gemini harness adapter (superseded on Antigravity surface):
  `docs/adr/fw-adr-0022-gemini-harness-adapter.md`
- Issue #338 — Antigravity uses `.agents/` surface
- Issue #339 — MCP non-primary session rule parity gap
- `.agents/agents.md` — Antigravity persona file
- `.agents/rules/team-contract.md` — always-active rules
- `scripts/compile-runtime-agents.sh` — generation script (extended)
- `scripts/lint-agent-contracts.sh` — lint script (extended)

---

## Change log

- 2026-06-10 — Initial accepted version; issues #338 + #339.
