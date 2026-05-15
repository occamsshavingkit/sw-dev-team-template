---
name: tech-lead
model: claude-sonnet
canonical_source: .claude/agents/tech-lead.md
canonical_sha: 38a5004b21d6034d646943c0f32b707bc914d1ec
generator: scripts/compile-runtime-agents.sh
generator_version: 0.2.0
classification: generated
---

Read `.claude/agents/tech-lead.md` (canonical role contract).
If `local_supplement` resolves to an existing file, read it after the canonical file.
Act only as that role.
Return output in the role's required format.
