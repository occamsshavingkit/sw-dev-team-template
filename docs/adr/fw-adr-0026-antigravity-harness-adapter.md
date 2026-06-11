---
name: fw-adr-0026-antigravity-harness-adapter
description: >
  Define the Google Antigravity harness adapter: .agents/ directory layout,
  agents.md personas file, rules/ workspace instructions, skills/ mapping,
  MCP non-primary-session rule parity across all root adapters, and drift
  control extending the compile-runtime-agents.sh / lint-agent-contracts.sh
  pipeline.
status: accepted
date: 2026-06-10
---


# FW-ADR-0026 — Antigravity harness adapter

<!-- TOC -->

- [Status](#status)
- [Scaffold placement note](#scaffold-placement-note)
- [Re-verification of the Antigravity surface (Deliverable A)](#re-verification-of-the-antigravity-surface-deliverable-a)
  - [Findings](#findings)
  - [Confidence and sources](#confidence-and-sources)
- [Context and problem statement](#context-and-problem-statement)
- [Decision drivers](#decision-drivers)
- [Considered options (Three-Path Rule, binding)](#considered-options-three-path-rule-binding)
  - [Option M — Minimalist](#option-m--minimalist)
  - [Option S — Scalable](#option-s--scalable)
  - [Option C — Creative (experimental)](#option-c--creative-experimental)
- [Decision outcome](#decision-outcome)
- [Design: Antigravity harness adapter](#design-antigravity-harness-adapter)
  - [1. .agents/ directory layout](#1-agents-directory-layout)
  - [2. .agents/agents.md — personas file](#2-agentsagentsmd--personas-file)
  - [3. .agents/rules/ — workspace instructions](#3-agentsrules--workspace-instructions)
  - [4. Roster mapping: skills vs. pointer agents](#4-roster-mapping-skills-vs-pointer-agents)
  - [5. MCP non-primary-session rule (#289) — cross-harness parity](#5-mcp-non-primary-session-rule-289--cross-harness-parity)
  - [6. Drift control and generation pipeline](#6-drift-control-and-generation-pipeline)
  - [7. What root-level files Antigravity does and does not auto-load](#7-what-root-level-files-antigravity-does-and-does-not-auto-load)
- [Implementation change-set grouped by owner (Deliverable C)](#implementation-change-set-grouped-by-owner-deliverable-c)
  - [tech-writer](#tech-writer)
  - [software-engineer](#software-engineer)
- [MCP non-primary-session parity wording (Deliverable D)](#mcp-non-primary-session-parity-wording-deliverable-d)
- [Consequences](#consequences)
  - [Positive](#positive)
  - [Negative / trade-offs accepted](#negative--trade-offs-accepted)
  - [Follow-up ADRs](#follow-up-adrs)
- [Verification](#verification)
- [Links](#links)

<!-- /TOC -->

---

## Status

- **Accepted**
- **Date:** 2026-06-10
- **Deciders:** `architect`; `tech-lead` + customer acceptance required
  before implementation begins
- **Consulted:** FW-ADR-0009, FW-ADR-0021, FW-ADR-0022;
  gh issue #338 (team not found in Antigravity);
  gh issue #339 (MCP calls spawn subagents instead of acting);
  Antigravity surface research gathered 2026-06-09 (thin/JS-rendered
  docs — re-verified in the body below; see § "Re-verification")

## Scaffold placement note

Authored in the meta-project (`docs/adr/`) per the PLAN/DO convention
(CLAUDE.md § "Project Identity / Working Tree"). Migrates into the
scaffold's `docs/adr/` with the implementation PR for this feature.
The meta-project draft copy is retained as the team's working reference;
the scaffold copy is canonical from the PR merge forward (pattern
established by FW-ADR-0022).

---

## Re-verification of the Antigravity surface (Deliverable A)

The surface description in the task brief was gathered 2026-06-09 from
thin/JS-rendered docs and the brief itself flagged it as needing
re-verification. The findings below reflect a second-pass reading of
the brief's source summary combined with structural inference from how
analogous harness surfaces (gemini-cli, OpenCode) behave. Direct
live-URL WebFetch/WebSearch against `antigravity.google/docs` and
`codelabs.developers.google.com` was attempted but the URLs were not
reachable in this session (JS-rendered or behind auth). Confidence
rating is therefore MEDIUM for the structural rules and LOW for any
specific YAML/frontmatter schema details. These items are flagged below
and require re-verification before the implementation PR is merged.

### Findings

**Updated 2026-06-11 — binary-confirmed from installed `agy` binary string-analysis.**
The initial surface description (MEDIUM/LOW confidence) has been superseded
by direct inspection of the installed `~/.local/bin/agy` binary. Confidence
for the items below is HIGH for the confirmed facts.

**Rules (`/agents/rules/`).**
Files in `.agents/rules/<name>.md` are workspace-always-active instructions.
Confirmed frontmatter fields:
- `activation: always_on` — active for every Antigravity conversation (no opt-in).
- `activation: glob` + `globs:` field — activated when file paths match.
- `activation: manual` — not activated automatically.
- `description:` — describes the rule file (shown in UI).
- `trigger:` — additional trigger specification.
Ordering across multiple rule files is not yet confirmed. Use a single file
to avoid undefined precedence. **Confidence: HIGH for activation key; LOW
for ordering.**

**Subagents (`/agents/agents/<name>/agent.json`).**
Per-role subagents live in `.agents/agents/<name>/agent.json` — a directory
of JSON files, NOT a single `agents.md`. Confirmed schema:
```json
{
  "name": "<role-slug>",
  "description": "<role description>",
  "hidden": false,
  "config": {
    "customAgent": {
      "systemPromptSections": [{"title": "<section>", "content": "<prose>"}],
      "toolNames": ["<tool>"],
      "systemPromptConfig": {"includeSections": []}
    }
  }
}
```
This is the correct mechanism for per-role roster entries. Generation of
these files is deferred to the follow-up (SE work; see Q-0033).
**Confidence: HIGH.**

**Skills (`/agents/skills/<name>/SKILL.md`).**
Confirmed frontmatter fields: `description` (required), `name` (optional),
`trigger`. Skills are description-matched and loaded when task context
matches. **Confidence: HIGH for confirmed fields.**

**`.agents/agents.md` — NOT the entry point.**
The initial design assumed `.agents/agents.md` was the personas entry point.
This is INCORRECT. The binary confirms per-role subagents live in
`.agents/agents/<name>/agent.json` directories, not in a flat `agents.md`.
A stub `agents.md` is retained in the repo with a redirect note; it is not
loaded by Antigravity. **Confidence: HIGH.**

**Root `AGENTS.md` and `GEMINI.md`.** The binary does reference both files,
consistent with Antigravity reading root adapter files when present.
**Confidence: MEDIUM.**

**Workflows (`.agents/workflows/`).** Custom slash commands. Not in scope
for this slice. **Confidence: LOW.**

**MCP config.** `~/.gemini/config/mcp_config.json` — user-level, not
repo-level. **Confidence: MEDIUM.**

### Confidence and sources

| Claim | Confidence | Source |
|---|---|---|
| `.agents/rules/<name>.md` always-active via `activation: always_on` | HIGH | agy binary string-analysis, 2026-06-11 |
| `description:` and `trigger:` valid fields in rules frontmatter | HIGH | agy binary string-analysis, 2026-06-11 |
| Per-role subagents: `.agents/agents/<name>/agent.json` | HIGH | agy binary string-analysis, 2026-06-11 |
| `agent.json` schema (customAgent, systemPromptSections, etc.) | HIGH | agy binary string-analysis, 2026-06-11 |
| `SKILL.md` fields: `description` required, `name` optional, `trigger` | HIGH | agy binary string-analysis, 2026-06-11 |
| `.agents/agents.md` is NOT the personas entry point | HIGH | agy binary string-analysis, 2026-06-11 |
| Root `GEMINI.md`/`AGENTS.md` referenced by binary | MEDIUM | agy binary string-analysis, 2026-06-11 |
| Ordering across multiple `.agents/rules/` files | LOW | not confirmed |

**Deferred (see Q-0033):** generation of `.agents/agents/<role>/agent.json`
(16 roles) and `.agents/skills/<role>/SKILL.md` (16 roles) by SE using the
confirmed schemas above. The hand-authored `.agents/rules/team-contract.md`
and the CLAUDE.md/#289 fix address both reported symptoms; the roster is the
enhancement.

---

## Context and problem statement

The framework already runs under four harness surfaces: Claude Code
(native, `.claude/agents/`), Codex (`AGENTS.md`), OpenCode
(`.opencode/agents/`, FW-ADR-0009), and gemini-cli (`GEMINI.md` +
`.gemini/agents/`, FW-ADR-0022). Two customer-reported defects (gh
issues #338 and #339) expose a fifth surface gap.

Issue #338 (team not found in Google Antigravity): fw-adr-0022 shipped
the gemini-cli surface under `.gemini/agents/`. Antigravity reads the
`.agents/` directory, not `.gemini/`. The scaffold has no `.agents/`
directory at all, so a Antigravity operator reaches no agent roster.

Issue #339 (MCP calls spawn subagents instead of acting): the MCP non-
primary-session rule (issue #289) was recorded only in `AGENTS.md`.
`GEMINI.md` and `CLAUDE.md` carry no equivalent. When an Antigravity
or gemini-cli session is invoked as an MCP tool from another session,
it has no instruction to suppress team-start and act as the dispatched
specialist — so it spawns subagents instead. This is a cross-provider
parity gap: all root adapters must carry the #289 rule.

The ADR trigger is a new harness surface (cross-cutting pattern change:
orchestration model, dispatch model, escalation-protocol encoding
specific to Antigravity) and a cross-cutting concern correction (#289
parity across all adapters). FW-ADR-0009's binding classification
applies: new harnesses are adapters, not peer orchestrators.

## Decision drivers

- Antigravity reads `.agents/`, not `.gemini/`. No `.agents/` directory
  means the team is invisible to Antigravity entirely.
- `.agents/agents.md` (personas) and `.agents/rules/` (always-active
  instructions) are structurally different from gemini-cli's
  `GEMINI.md` context file + `.gemini/agents/` roster. The adapter
  must use Antigravity-native constructs, not copies of gemini-cli
  constructs.
- The #289 MCP non-primary-session rule must appear in every root
  adapter consumed by every harness. Currently it is AGENTS.md-only:
  a gap on the GEMINI.md path and on the Antigravity path.
- The existing `canonical_sha` drift-control pattern (FW-ADR-0009,
  FW-ADR-0022) must be extended to `.agents/` so a three-surface sync
  procedure exists: a change to a canonical `.claude/agents/<role>.md`
  file triggers regeneration of `.opencode/agents/`, `.gemini/agents/`,
  and `.agents/` in one pass.
- The roster has grown from 13 roles (fw-adr-0022) to 16 (added
  `librarian`, `ui-ux-designer`, `mcp-liaison`). Any Antigravity
  adapter must cover all 16 canonical roles.
- Skills (`/agents/skills/`) frontmatter schema is LOW-confidence
  (see re-verification above). The design must not depend on skill
  invocation mechanics until those are confirmed.

## Considered options (Three-Path Rule, binding)

### Option M — Minimalist

Ship a single `.agents/agents.md` file and a single
`.agents/rules/team-contract.md` file. The personas file defines a
single "sw-dev-team" persona pointing Antigravity at the framework.
The rules file contains the core binding instructions (Mode A / Mode B,
#289 MCP rule, Hard Rule #1, escalation protocol). Do not create per-
role entries or skills. Do not extend `compile-runtime-agents.sh` or
lint. The `.agents/` directory is hand-authored and not generated.

- **Sketch:** Two new files total. `.agents/agents.md` is a short
  persona definition for the team as a whole. `.agents/rules/team-
  contract.md` is the binding instruction set (~150 lines, similar to
  `GEMINI.md` but stripped to Antigravity-native constructs). No per-
  role definitions; operators who need a specific role read it from
  `.claude/agents/<role>.md` via manual instruction. No drift control
  beyond `code-reviewer` review.
- **Pros:** Minimal new surface. No dependency on the unconfirmed
  skills schema. Works on any Antigravity version. Fast to ship and
  easy to correct.
- **Cons:** The team is visible to Antigravity (fixes #338) but no
  individual role personas are registered — autonomous role selection
  is unavailable. The #289 MCP rule is in the rules file but not in
  `GEMINI.md` or `CLAUDE.md`, so #339 remains partially open. No
  generation or drift control means `.agents/` can diverge silently
  from canonical role contracts as the roster evolves.
- **When M wins:** Antigravity is a low-priority harness; proving the
  team is visible is sufficient for the near term; the skills schema
  is confirmed to be incompatible with the pointer-to-canonical pattern.

### Option S — Scalable

Ship `.agents/agents.md` (team persona + Mode A / Mode B binding),
`.agents/rules/team-contract.md` (always-active binding instructions
including #289 MCP parity), and 16 `.agents/skills/<role>/SKILL.md`
thin-adapter files. Also add the #289 MCP non-primary-session rule to
`GEMINI.md` and `CLAUDE.md` (cross-harness parity). Extend
`compile-runtime-agents.sh` to emit `.agents/skills/<role>/SKILL.md`
alongside `.opencode/` and `.gemini/`. Extend `lint-agent-contracts.sh`
to cover `.agents/skills/`. Generation uses the same `canonical_sha`
pattern as OpenCode and gemini-cli adapters; skill files are generated,
not hand-authored.

If the LOW-confidence skills schema is confirmed before PR merge,
the `SKILL.md` frontmatter matches the confirmed schema. If it cannot
be confirmed before the PR, ship Option M instead and record an
upstream issue for the skills surface — do not speculate on schema.

- **Sketch:** `.agents/agents.md` (~80 lines); `.agents/rules/team-
  contract.md` (~120 lines); 16 `.agents/skills/<role>/SKILL.md`
  files (~12 lines each, generated); `compile-runtime-agents.sh`
  extended (~40 lines for `.agents/skills/` target); lint extended to
  cover skill files. MCP parity prose added to `GEMINI.md` and
  `CLAUDE.md` (one section each, ~20 lines). Total new surface:
  2 hand-authored files, 16 generated files, two script extensions,
  two root-adapter amendments.
- **Pros:** Full 16-role roster visible in Antigravity with autonomous
  description-matching; #339 fully closed across all adapters; drift
  machine-detected via `canonical_sha`; consistent with the established
  three-surface pattern. Skills schema gate ensures the design is
  confirmed before shipping the generated files.
- **Cons:** Depends on LOW-confidence skills schema being confirmed
  before PR; if schema confirmation fails, the skills surface must be
  deferred. `.agents/rules/` and `.agents/agents.md` are hand-authored
  and subject to the same manual-drift risk as `GEMINI.md` and
  `AGENTS.md`.
- **When S wins:** Antigravity is a peer harness; full role visibility
  and autonomous selection are required; skills schema is confirmable
  before PR merge.

### Option C — Creative (experimental)

Do not create a `.agents/` directory. Instead, add a pre-session
bootstrap script (`scripts/build-antigravity-context.sh`) that reads
`.claude/agents/*.md` and writes `.agents/` dynamically at session
start — generating `agents.md` from frontmatter `name` + `description`
fields and one rule file per role. Git-ignore `.agents/` entirely;
treat it as an ephemeral session artifact. The script is invoked by
a Makefile target or a `pre-session` hook if Antigravity exposes one.

- **Sketch:** One new script (~80 lines); `.agents/` is gitignored.
  No new static files checked into the repo. Every session auto-
  generates a fresh `.agents/` by reading canonical files. Zero drift
  by construction because canonical files are the source.
- **Pros:** No drift surface. No schema dependency for `SKILL.md`
  frontmatter. Every role's description and constraints are current.
- **Cons:** If the bootstrap script is not run (a new contributor, a
  CI environment, Antigravity invoked before the script runs), the
  `.agents/` directory is absent and the harness sees nothing. The
  ephemeral-file model is inconsistent with the repo-is-the-brief
  pattern used across all other harnesses. Antigravity's pre-session
  hook support is unconfirmed. This is the same failure mode identified
  as the rejection condition for Option C in FW-ADR-0022.
- **When C wins:** Antigravity exposes a confirmed, reliable pre-session
  hook; the team controls all invocation paths; and the bootstrap
  script is tested end-to-end. None of these hold currently.

## Decision outcome

**Chosen option: S — Scalable, gated on skills-schema confirmation.**

Option M fixes #338 but leaves no drift control and does not close #339
across all harnesses. Option C repeats the rejected FW-ADR-0022 Option C
failure mode: a missing bootstrap produces an invisible harness surface
with no machine safeguard. Option S extends the established
OpenCode/gemini-cli pattern uniformly, closes both issues, and adds the
same generation + lint protection already proven across two adapter
surfaces. The skills-schema gate (do not ship the generated skill files
until the schema is confirmed from a Tier-1 source) prevents speculative
implementation against LOW-confidence surface details. If the schema
cannot be confirmed before the implementation PR, ship the hand-authored
`.agents/agents.md` and `.agents/rules/team-contract.md` only (which
is Option M), record an upstream issue for the skills surface, and file
a superseding ADR for the skills generation when schema confirmation
arrives.

---

## Design: Antigravity harness adapter

### 1. .agents/ directory layout

**Binary-confirmed layout (agy, 2026-06-11):**

```
.agents/
  agents.md                    # STUB ONLY — not loaded by Antigravity;
                               #   redirect note pointing to rules/ and agents/
  rules/
    team-contract.md           # always-active binding instructions — hand-authored
                               #   frontmatter: activation: always_on
  agents/
    <role>/
      agent.json               # per-role subagent — generated (deferred, Q-0033)
  skills/
    <role>/
      SKILL.md                 # thin-adapter skill — generated (deferred, Q-0033)
```

`rules/team-contract.md` is the hand-authored binding file, treated
identically to `AGENTS.md` and `GEMINI.md`: changes require
`tech-lead` + `code-reviewer` review and a CHANGELOG entry.

`agents/<role>/agent.json` and `skills/<role>/SKILL.md` are generated
by `compile-runtime-agents.sh` (deferred to follow-up once SE implements
the generation target — see Q-0033).

### 2. .agents/agents.md — NOT the entry point (corrected)

**Corrected from initial design.** The initial design assumed
`.agents/agents.md` was the personas entry point. Binary analysis
confirms this is wrong: per-role subagents live in
`.agents/agents/<name>/agent.json` (directory of JSON files).

A stub `.agents/agents.md` exists in the repo with a redirect note
explaining the correct structure. It is not loaded by Antigravity.

The always-active team contract for Antigravity is
`.agents/rules/team-contract.md` (frontmatter: `activation: always_on`).
This is the sole instruction surface for an Antigravity session.

### 3. .agents/rules/ — workspace instructions

`.agents/rules/team-contract.md` is the always-active instruction file.
It is active for every Antigravity conversation in the workspace. Its
content mirrors the substantive sections of `GEMINI.md`, paraphrased
to Antigravity-native prose (not copied verbatim; IP rule applies).

Sections in `rules/team-contract.md`:

1. **Mode A — Main session as tech-lead.** Identical semantics to
   `GEMINI.md` § "Mode A". Grounding reads listed.
2. **Mode B — Delegated specialist.** Identical semantics to `GEMINI.md`
   § "Mode B". Path and action constraints from the handoff are binding.
3. **MCP non-primary-session mode (issue #289).** Detection heuristic
   and behavior for when the session is invoked as an MCP tool — same
   semantics as `AGENTS.md` § "MCP-connection / non-primary-session
   mode". See § "MCP non-primary-session parity wording" below for the
   exact prose.
4. **Framework / project boundary.** Same content as `GEMINI.md` §
   "Framework / Project Boundary".
5. **Dispatch guidance.** How to invoke skills or roles; `@name` override
   for deterministic dispatch; conditions that require explicit invocation.
6. **Binding references.** `CLAUDE.md`, `SW_DEV_ROLE_TAXONOMY.md`,
   `docs/glossary/ENGINEERING.md`, `docs/glossary/PROJECT.md`,
   `docs/model-routing-guidelines.md`.
7. **Paraphrase and IP rule.** Standards text must be paraphrased.
8. **Escalation and customer-truth custody.** One question per turn,
   idle agents/tools, final line; routes to `librarian`.

Only one rules file is shipped. Ordering across multiple rule files is
not guaranteed by Antigravity; a single file avoids undefined precedence.

### 4. Roster mapping: agent.json + skills (deferred, schema confirmed)

**Binary-confirmed (agy, 2026-06-11):**

**Per-role subagents (`.agents/agents/<role>/agent.json`).**
Each role gets a directory entry. Confirmed JSON schema:
```json
{
  "name": "<role-slug>",
  "description": "<verbatim from .claude/agents/<role>.md description: field>",
  "hidden": false,
  "config": {
    "customAgent": {
      "systemPromptSections": [
        {"title": "Role contract", "content": "Read .claude/agents/<role>.md and act as that role."}
      ],
      "toolNames": [],
      "systemPromptConfig": {"includeSections": []}
    }
  }
}
```
The `description` value sources from the canonical `.claude/agents/<role>.md`
`description:` frontmatter field. The `tech-lead` entry carries a guard in
its `systemPromptSections` content: if invoked as a subagent, halt and report
a harness misconfiguration.

**Skills (`.agents/skills/<role>/SKILL.md`).**
Confirmed frontmatter: `description` (required), `name` (optional),
`trigger`. Source: agy binary, 2026-06-11.

```yaml
---
name: <role-slug>
description: <verbatim from .claude/agents/<role>.md description: field>
trigger: <activation trigger phrase — TBD per role>
canonical_source: .claude/agents/<role>.md
canonical_sha: <SHA-1 of canonical file at generation time>
generator: scripts/compile-runtime-agents.sh
classification: generated
---
```

Body:
```text
Read `.claude/agents/<role>.md` (canonical role contract).
If `local_supplement` resolves to an existing file, read it after
the canonical file. Act only as that role. Return output in the
role's required format.
```

**Both surfaces are deferred** to the SE follow-up (Q-0033). The
generation target in `compile-runtime-agents.sh` and the lint extension
in `lint-agent-contracts.sh` are SE work. This slice ships the
hand-authored `rules/team-contract.md` only.

**Skills-format dispute (Q-0033).** Two binary readings conflict:
coordinator correction (2026-06-11) reports `.agents/skills/<role>/SKILL.md`
with `description`/`name`/`trigger` frontmatter; memory observation 12585
(2026-06-11) reports skills use JSON path references, not directory-based
SKILL.md files. Resolve against a live Antigravity session before SE
implements the skills generation target.

### 5. MCP non-primary-session rule (#289) — cross-harness parity

Issue #339 root cause: the #289 rule lives only in `AGENTS.md`. All
root adapters and rules files consumed by all harnesses must carry it.

Adapters that must be amended:

| File | Status |
|---|---|
| `AGENTS.md` | Already has the rule (issue #289 section) |
| `GEMINI.md` | Missing — must add |
| `CLAUDE.md` | Missing — must add (Hard Rule #12 is the parallel-agent rule; #289 is a separate MCP-mode rule) |
| `.agents/rules/team-contract.md` | New file — include at authoring time |

The exact wording to add to `GEMINI.md` and `CLAUDE.md` is in
§ "MCP non-primary-session parity wording" below.

### 6. Drift control and generation pipeline

The four-surface roster table becomes:

| Surface | Generator | Drift detection |
|---|---|---|
| `.claude/agents/` | Canonical (not generated) | `schemas/agent-contract.schema.json` + lint |
| `.opencode/agents/` | `compile-runtime-agents.sh` | `canonical_sha` mismatch |
| `.gemini/agents/` | `compile-runtime-agents.sh` | `canonical_sha` mismatch |
| `.agents/skills/` | `compile-runtime-agents.sh` (extended) | `canonical_sha` mismatch |

**Generation extension.** `scripts/compile-runtime-agents.sh` gains an
`.agents/skills/` target alongside the existing `--no-opencode-adapters`
and `--no-gemini-adapters` flags. A symmetric `--no-antigravity-skills`
flag skips the `.agents/skills/` output. Default behaviour generates
all four surfaces. The generator:

1. Reads each `.claude/agents/<role>.md`.
2. Computes `canonical_sha` (SHA-1 of the canonical file).
3. Copies the `description:` frontmatter field verbatim.
4. Emits `.agents/skills/<role>/SKILL.md` using the confirmed schema.

**Lint extension.** `scripts/lint-agent-contracts.sh` is extended to
cover `.agents/skills/`. The extended checks:

- `canonical_sha` in each `SKILL.md` matches the current SHA of the
  referenced `.claude/agents/<role>.md`. Mismatch is an error.
- `description` field is present and non-empty.
- Skill files are only in `.agents/skills/<role>/SKILL.md`; stray
  files in `.agents/` outside the generated paths are flagged.

**Four-surface sync procedure.** When a canonical agent contract changes,
the releasing agent runs `compile-runtime-agents.sh` (all targets) before
commit. CI runs lint on all four surfaces. A PR that modifies
`.claude/agents/<role>.md` without regenerating all four adapter surfaces
fails lint.

### 7. What root-level files Antigravity does and does not auto-load

Based on the re-verification findings (MEDIUM confidence):

- `GEMINI.md` — NOT auto-loaded by Antigravity (MEDIUM confidence; see § "Re-verification").
- `AGENTS.md` — NOT auto-loaded by Antigravity (MEDIUM confidence; see § "Re-verification").
- `CLAUDE.md` — NOT auto-loaded by Antigravity (MEDIUM confidence; see § "Re-verification").
- `.agents/agents.md` — **NOT loaded by Antigravity (HIGH confidence)**; retained as a stub/redirect note.
- `.agents/rules/team-contract.md` — active for every conversation.

This means all binding instructions that `GEMINI.md` and `AGENTS.md`
carry must be present in `.agents/rules/team-contract.md` for
Antigravity sessions to behave correctly. The rules file is the sole
instruction surface for an Antigravity session.

---

## Implementation change-set grouped by owner (Deliverable C)

### tech-writer

Files to author or amend. These are hand-authored binding files; no
generation script produces them.

| File | Action | Mirror regen required? |
|---|---|---|
| `.agents/agents.md` | Create new — Antigravity personas file per § 2 above | No (hand-authored) |
| `.agents/rules/team-contract.md` | Create new — always-active binding instructions per § 3 above | No (hand-authored) |
| `GEMINI.md` | Amend — add MCP non-primary-session section per § "MCP non-primary-session parity wording" | **Yes** — `GEMINI.md` is listed in compile-runtime-agents.sh as a framework-managed file; code-reviewer must confirm no `canonical_sha` applies here, but the change does require agent-contract CI re-run |
| `CLAUDE.md` (scaffold) | Amend — add MCP non-primary-session section per § "MCP non-primary-session parity wording" | **Yes** — editing `CLAUDE.md` triggers agent-contract CI |

Note on `CLAUDE.md`: the MCP #289 rule addition goes into the scaffold's
`CLAUDE.md` (at `/home/quackdcs/SWEProj/sw-dev-team-template/CLAUDE.md`),
not the meta-project's `CLAUDE.md`. This is a framework instruction file
(DO, not PLAN).

### software-engineer

Files to generate or extend via scripts.

| File | Action | Mirror regen required? |
|---|---|---|
| `scripts/compile-runtime-agents.sh` | Extend — add `.agents/skills/` output target and `--no-antigravity-skills` flag per § 6 above | **Yes — run `compile-runtime-agents.sh` (all targets) after extending; regenerates `.opencode/`, `.gemini/`, and `.agents/skills/` in one pass** |
| `scripts/lint-agent-contracts.sh` | Extend — add `.agents/skills/` lint coverage per § 6 above | **Yes — all four adapter surfaces must pass lint in the same PR** |
| `.agents/skills/<role>/SKILL.md` ×16 | Generate via extended script (schema-gated — do not generate until `SKILL.md` schema is confirmed by `researcher`) | This IS the mirror regen artifact |

**Schema gate.** `software-engineer` must not implement the
`.agents/skills/` generation target until `researcher` confirms the
`SKILL.md` frontmatter schema from a Tier-1 source (live WebFetch
against `antigravity.google/docs`). If schema confirmation is not
available before the PR deadline, ship the hand-authored files only
(Option M path) and file an upstream issue for the skills generation.

---

## MCP non-primary-session parity wording (Deliverable D)

The following section is to be added to `GEMINI.md` and to `CLAUDE.md`
(scaffold), paraphrased from `AGENTS.md` § "MCP-connection /
non-primary-session mode (issue #289)" per Hard Rule #5. It is NOT
copied verbatim.

**Section title:** `## MCP non-primary-session mode (issue #289)`

**Prose to add to `GEMINI.md` and `CLAUDE.md`:**

> When this session is invoked as an MCP tool — that is, it is a
> tool-bridge call from another orchestrating session rather than the
> primary operator-facing session — it is already operating as a
> spawned specialist. In that context:
>
> - Do not start the team, request spawn authorization, or prompt for
>   subagent dispatching. Those prompts fit a primary-session model and
>   will block the scoped task.
> - Act as the specialist role specified in the MCP tool call or in the
>   preamble provided by the calling session. If no role is named,
>   default to `software-engineer`.
> - Return findings, file changes, and any blockers directly in the
>   tool response. Do not attempt to contact the customer or open a
>   parallel orchestration loop.
>
> Detection: if the session preamble or system prompt indicates the
> session was dispatched by another session (for example, it contains
> language such as "you have already been dispatched", "top-level
> tech-lead sent you", or an equivalent MCP tool-call framing), treat
> this as non-primary and skip team-start. If an explicit role
> assignment is present in the opening context, execute that role
> without prompting for spawn authorization.

This wording is placed in `GEMINI.md` after the "Codex Pre-Close
Checklist Equivalent" section (line ~194 in the current file) and in
`CLAUDE.md` after Hard Rule #12.

---

## Consequences

### Positive

- Antigravity becomes a co-equal harness: the team is visible (fixes
  #338), the 16-role roster is accessible via skills (schema-gated),
  and the Mode A / Mode B / #289 rules are present in the always-active
  rules file.
- Issue #339 is fully closed: the MCP non-primary-session rule now
  lives in every root adapter and rules file across all four harnesses.
- The generation and drift-detection pipeline is extended uniformly to
  four surfaces. A single `compile-runtime-agents.sh` run keeps all
  four surfaces synchronized.
- The schema gate prevents speculative implementation: if the
  `SKILL.md` schema cannot be confirmed, the hand-authored Option M
  path ships instead, and the skills generation is deferred without
  blocking the #338 fix.

### Negative / trade-offs accepted

- `SKILL.md` schema confirmation is a hard dependency for the full
  skills generation surface. If `researcher` cannot reach the live
  docs before the PR deadline, the skills generation is deferred and
  only `.agents/agents.md` + `.agents/rules/team-contract.md` ship.
- `.agents/agents.md` and `.agents/rules/team-contract.md` are hand-
  authored and carry the same manual-drift risk as `GEMINI.md` and
  `AGENTS.md`. Mitigated by `code-reviewer` review on all changes and
  CHANGELOG entry requirement.
- The re-verification findings are MEDIUM/LOW confidence. If live-doc
  research reveals structural differences (e.g., rules file ordering
  matters, or `agents.md` is not the correct personas filename), the
  design requires a superseding amendment. The schema gate absorbs the
  highest-risk item (skills frontmatter).
- `compile-runtime-agents.sh` gains a fourth output target, marginally
  increasing the release-process step count. Marginal cost is low
  because the infrastructure already exists for three surfaces.

### Follow-up ADRs

- If the Antigravity skills schema confirms a `model` frontmatter field,
  a follow-up amendment to this ADR pins the model-class mapping from
  `docs/model-routing-guidelines.md` to the Antigravity-equivalent
  column (same pattern as the gemini-cli `model` field in FW-ADR-0022).
- If Antigravity exposes a `workflows/` slash-command surface that
  maps to framework automation (e.g., `compile-runtime-agents` as a
  slash command), a follow-up ADR should address that surface.

---

## Verification

- **Success signal:** A Antigravity session opened on a repo scaffolded
  from this template reads `.agents/agents.md` and `.agents/rules/
  team-contract.md`, self-orients as `tech-lead`, and can invoke a
  specialist via description-matched skill dispatch. An Antigravity or
  gemini-cli session invoked as an MCP tool suppresses team-start and
  acts as the specified specialist role without spawning subagents.
  `compile-runtime-agents.sh` (all targets) regenerates all four adapter
  surfaces with correct `canonical_sha` values. CI lint passes on all
  four surfaces.
- **Failure signal:** A Antigravity session correctly oriented via
  `.agents/` fails to match the correct specialist skill on documented
  test tasks (indicating description quality is insufficient — same
  follow-up path as FW-ADR-0022). Alternatively, the `SKILL.md` schema
  confirmed by live-doc research differs materially from the shape
  designed here — triggering a superseding amendment. If `AGENTS.md`'s
  #289 rule and the new `GEMINI.md` / `CLAUDE.md` sections fall out of
  sync on a future change, lint must detect it (see lint extension).
- **Review cadence:** Re-examine at the first session after the
  implementation PR merges, or after two documented Antigravity operator
  sessions in downstream projects, whichever comes first
  (session-anchored per CLAUDE.md § "Time-based cadences").

---

## Links

- FW-ADR-0009 — OpenCode harness adapter (thin-adapter pattern this
  ADR inherits): `docs/adr/fw-adr-0009-opencode-harness-adapter.md`
- FW-ADR-0021 — harness-agnostic leaf-task dispatch (delegated-
  specialist mode): `docs/adr/fw-adr-0021-harness-agnostic-leaf-task-dispatch.md`
- FW-ADR-0022 — Gemini harness adapter (co-equal harness precedent
  this ADR extends to Antigravity): `docs/adr/fw-adr-0022-gemini-harness-adapter.md`
- gh issue #338 — Team not found in Antigravity
- gh issue #339 — MCP calls spawn subagents instead of acting
- gh issue #289 — MCP non-primary-session rule (origin of the AGENTS.md section)
- `AGENTS.md` § "MCP-connection / non-primary-session mode" — binding
  source for the #289 rule being ported to other adapters
- `GEMINI.md` — Gemini root adapter (structural parallel, receives #289 amendment)
- `scripts/compile-runtime-agents.sh` — generation script to extend
- `scripts/lint-agent-contracts.sh` — lint script to extend
- `docs/model-routing-guidelines.md` — binding per-agent routing table
- `.gemini/agents/` — gemini-cli adapter precedent
- `.opencode/agents/` — OpenCode adapter precedent
