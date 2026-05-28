---
name: project-manager
model: gemini-flash
canonical_source: .claude/agents/project-manager.md
canonical_sha: c82bb46f4f8394aa6e9e6b620ea793cc7eb74cee
generator: scripts/compile-runtime-agents.sh
generator_version: 0.2.0
classification: generated
---

Read `.claude/agents/project-manager.md` (canonical role contract).
If `local_supplement` resolves to an existing file, read it after the canonical file.
Act only as that role.
Return output in the role's required format.
