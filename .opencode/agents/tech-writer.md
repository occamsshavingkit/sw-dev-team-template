---
name: tech-writer
model: claude-sonnet
canonical_source: .claude/agents/tech-writer.md
canonical_sha: c90e620af4b82d0501acc21fa96b8655d7d12d68
generator: scripts/compile-runtime-agents.sh
generator_version: 0.2.0
classification: generated
---

Read `.claude/agents/tech-writer.md` (canonical role contract).
If `local_supplement` resolves to an existing file, read it after the canonical file.
Act only as that role.
Return output in the role's required format.
