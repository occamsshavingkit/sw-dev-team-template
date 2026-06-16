---
name: tech-writer
model: claude-sonnet
canonical_source: .claude/agents/tech-writer.md
canonical_sha: 41e3e246a41388a6e1959f4812c348a80cc16b4d
generator: scripts/compile-runtime-agents.sh
generator_version: 0.3.0
classification: generated
---

Read `.claude/agents/tech-writer.md` (canonical role contract).
If `local_supplement` resolves to an existing file, read it after the canonical file.
Act only as that role.
Return output in the role's required format.
