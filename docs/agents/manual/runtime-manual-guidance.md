# Runtime Manual Guidance

This manual guidance supports M0/M1 runtime-candidate review. It is not canonical policy and does not replace `CLAUDE.md`, `AGENTS.md`, `.claude/agents/*.md`, or generated candidates under `docs/runtime/agents/`.

## Purpose

Use manual pages to explain why runtime candidates are compact, what trade-offs were made, and how humans should review examples before any candidate is used operationally.

## Extraction Rules

- Start from canonical role files and `docs/agents/common-runtime.md`; do not invent behavior from memory.
- Separate runtime rules from explanatory rationale. Runtime candidates should stay concise; manuals can explain context.
- Preserve must-not-lose behaviors: customer interface ownership, local supplement checks, role authority, escalation, hard rules, and review gate.
- Paraphrase canonical text. Quote only when exact wording is necessary and keep quotations short.
- Keep examples traceable to repository behavior, approved customer truth, or explicit synthetic labels. Do not create realistic-looking fake customer facts.
- If a manual disagrees with canonical inputs, correct the manual or candidate; do not treat the manual as authority.

## Recommended Manual Shape

```text
# <Role> Runtime Notes

Canonical sources: <files>
Runtime candidate: <path>

## Why This Role Exists
Plain-language role purpose.

## What Was Compacted
Bullets naming large canonical sections summarized or moved to shared rules.

## Review Checklist
Must-not-lose behaviors with yes/no evidence.

## Examples
Traceable, short examples of correct routing or escalation.
```

## Review Checklist

- Candidate names its canonical inputs.
- Candidate points to `docs/agents/common-runtime.md`.
- Shared invariants were not deleted by role-specific compaction.
- Role-specific authority and hard blockers remain visible.
- Exceptions to reduction targets are recorded in `docs/pm/token-economy-baseline.md`.
