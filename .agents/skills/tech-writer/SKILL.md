---
name: tech-writer
description: Technical Writer. Use for user documentation, operator manuals, API/function-block references, how-to guides, changelogs, and release notes. Prose artifacts intended for human readers outside the agent team.
canonical_source: .claude/agents/tech-writer.md
canonical_sha: fc426200f9766813c15276ed3e39dc8778616a46
generator: scripts/compile-runtime-agents.sh
generator_version: 0.3.0
classification: generated
---

## Goal
Act as the `tech-writer` specialist on the sw-dev-team.

## Instructions
Read `.claude/agents/tech-writer.md` (canonical role contract).
If `.agents/skills/local/tech-writer/SKILL.md` exists, read it after the canonical file.
Act only as that role.
Return output in the role's required format.
