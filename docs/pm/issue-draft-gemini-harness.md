# Issue draft — Implement fw-adr-0022 (Gemini full-team harness)

## Where

Template version: v1.1.1 (SHA `2984c6890046c48c577b7cd3ba3b4d344622b526`).

Affected paths:
- `.gemini/` — no `agents/` subdirectory exists; only `commands/`
  (Spec-Kit TOMLs) is present.
- Repo root — no `GEMINI.md` harness adapter file.
- `compile-runtime-agents.sh` — no Gemini output target.
- `lint-agent-contracts.sh` — no Gemini roster lint path.

## What happened

A Gemini session was given the repo as context. With no `GEMINI.md`
and no `.gemini/agents/` roster, the session read the Codex adapter
(`AGENTS.md`) and confabulated a non-existent `invoke_agent` tool,
attempting to use Codex-specific spawn vocabulary in a Gemini
context. Claude, Codex, and OpenCode all have co-equal full-team
adapters (`.claude/agents/`, `AGENTS.md`, `.opencode/agents/`
respectively); Gemini does not.

## Why this is a gap

The multi-harness design intent is that any supported harness can
run the full agent team. Gemini is a supported harness (gemini-cli
>= v0.38.1 ships native named subagents; definitions live in
`.gemini/agents/*.md`; context file is `GEMINI.md`) but the
template provides no adapter for it. The result is Gemini sessions
operating without role-binding, producing confabulation errors
(see problems P10 / P12 in the session problem register) and
making Gemini a second-class participant in the team model.

## Suggested fix

Design is already accepted as `fw-adr-0022` (2026-06-02).
Concrete artifacts to create or extend:

1. `GEMINI.md` — harness adapter (parallel to `AGENTS.md`):
   tech-lead persona declaration, role-binding table, routing
   defaults, Hard Rules reference, and delegated-specialist mode
   entry (pairs with #293).
2. `.gemini/agents/*.md` — one file per canonical role (13 roles),
   descriptions copied from `.claude/agents/` source-of-truth;
   no divergence from canonical contracts.
3. `compile-runtime-agents.sh` — add Gemini output target
   alongside existing Claude and OpenCode targets.
4. `lint-agent-contracts.sh` — add Gemini roster to canonical-SHA
   lint path so drift from `.claude/agents/` is CI-gated.
5. `docs/TEMPLATE_UPGRADE.md` — migration note: downstream projects
   on v1.1.1 or earlier must run `compile-runtime-agents.sh` after
   upgrading to generate `.gemini/agents/`.

Minimum gemini-cli version: v0.38.1 (named subagents GA in
v0.44.0 stable).

This issue tracks implementation of an accepted ADR, analogous to
how #296 and #297 track implementation of `fw-adr-0021`. It pairs
with #293 (shared delegated-specialist mode for AGENTS.md and
GEMINI.md).
