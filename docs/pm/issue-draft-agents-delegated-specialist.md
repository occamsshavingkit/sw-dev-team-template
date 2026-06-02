# Issue draft — AGENTS.md delegated-specialist mode

**Template version:** v1.1.1
(SHA `2984c6890046c48c577b7cd3ba3b4d344622b526`)

**Title:** AGENTS.md lacks a delegated-specialist invocation mode;
tool-invoked Codex defaults to orchestrator and attempts to spawn agents

**Labels:** `template-gap`

## Where

`AGENTS.md` — the section documenting Codex invocation modes and
role binding. Also relevant: the handoff contract schema fields
`codex_allowed` and `bounded_codex_exception` (`schemas/handoff.schema.json`,
`docs/v1.1-handoff-contracts.md`).

## What happened

Codex was invoked as a delegated specialist via a handoff contract
(tool-invoked, not as the main Codex session). Because `AGENTS.md`
documents only two modes — (1) main Codex session playing `tech-lead`
as orchestrator, and (2) the bounded-Codex-exception path — the
tool-invoked instance had no documented role-binding path. It
defaulted to orchestrator behavior: it treated itself as `tech-lead`,
attempted to spawn specialist subagents, and did not execute the
single task specified in the handoff contract.

The handoff contract schema carries the fields `codex_allowed` and
`bounded_codex_exception`, which are the correct signal that a
delegated invocation is intended. However, `AGENTS.md` contains no
prose connecting those fields to a behavioral mode, so the connection
was not made at runtime.

## Why it is a gap

`AGENTS.md` is the Codex-side adapter for the full team model. Its
role-binding section governs how a Codex session decides what role to
assume and whether to spawn agents. For the main-session orchestrator
pattern this is well-specified (including the upstream issue #37 fix
in v0.12.1). For a tool-invoked delegated specialist — a Codex
instance receiving a bounded task from a handoff contract — the
specification is absent.

Without a delegated-specialist mode, the framework cannot safely use
Codex as a leaf-task executor in a mixed Claude-and-Codex pipeline.
Every tool-invoked Codex instance will either require manual
role-pinning per project (undocumented, error-prone) or default to the
orchestrator path and incur unauthorized spawning.

This gap pairs directly with the leaf-task handoff ADR (`fw-adr-0021`,
covering handoff-contract granularity): the ADR makes the leaf T### the
canonical dispatch unit, but that only works end-to-end if `AGENTS.md`
tells a delegated Codex what to do when it receives a single-task
handoff contract.

## Suggested fix

Add a **Delegated-specialist mode** section to `AGENTS.md` with the
following behavioral contract:

1. **Detection.** If the Codex session is invoked with a handoff
   contract in context (`codex_allowed: true`, or the session receives
   a bounded-task brief rather than a full-session prompt), treat the
   invocation as delegated-specialist mode, not orchestrator mode.
2. **Role assumption.** Adopt the role named in the handoff contract
   (e.g., `software-engineer`, `qa-engineer`). Do not assume
   `tech-lead`. Do not spawn specialist subagents unless the handoff
   contract explicitly grants spawning for that task.
3. **Task scope.** Execute the single leaf task specified in the
   contract. Do not pull adjacent tasks or self-extend scope.
4. **Spawning suppression.** Suppress agent spawning by default. The
   only exception is a handoff contract row that carries an explicit
   `bounded_codex_exception` authorizing a named sub-spawn for that
   task.
5. **Return.** Report back to the calling harness via the handoff
   return channel (structured result, not a new session).

Wire the detection logic to the existing `codex_allowed` and
`bounded_codex_exception` schema fields so contract authors do not need
to add new fields.

This fix is a documentation and schema-prose change to `AGENTS.md` and
the handoff contract spec. It does not require a new agent file. It
should ship in the same version bump that closes `fw-adr-0021`, so both
halves of the delegated-Codex story land together.
