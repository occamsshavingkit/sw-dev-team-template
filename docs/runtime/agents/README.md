# Runtime Agent Candidates

This directory contains generated runtime-agent candidates for M0/M1 token-reduction work.

## Status

- Generated artifacts, not canonical policy.
- Subordinate to `CLAUDE.md`, `AGENTS.md`, `.claude/agents/*.md`, and any matching `.claude/agents/*-local.md` supplement.
- M0/M1 scope only; no Markdown compiler, schema, LLMD, or generation pipeline is implemented here.

## Canonical Inputs

Runtime candidates must be derived from:

- `CLAUDE.md`
- `AGENTS.md`
- `.claude/agents/*.md`
- `.claude/agents/*-local.md`, when present
- `specs/001-template-improvement-plan/` M0/M1 planning artifacts

## Edit Rule

Do not manually edit generated runtime candidate files as policy sources.

If a candidate is wrong, update the canonical input or record the generation defect, then regenerate or replace the candidate through the approved review path.

## Review Gate

Before any runtime candidate is used operationally, review must confirm that hard rules, role authority, local supplement checks, escalation behavior, and customer-interface ownership were preserved.
