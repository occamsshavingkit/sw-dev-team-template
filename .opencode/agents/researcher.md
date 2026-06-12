---
name: researcher
model: gemini-pro
canonical_source: .claude/agents/researcher.md
canonical_sha: fd225cdfb4bac818bed60b5fb0c2c0210b896008
generator: scripts/compile-runtime-agents.sh
generator_version: 0.3.0
classification: generated
---

Read `.claude/agents/researcher.md` (canonical role contract).
If `local_supplement` resolves to an existing file, read it after the canonical file.
Act only as that role.
Return output in the role's required format.
