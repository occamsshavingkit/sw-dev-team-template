---
name: software-engineer
model: openai-coding
canonical_source: .claude/agents/software-engineer.md
canonical_sha: 020f538d19e0ee2dade2962b66f9de1f5a66c34b
generator: scripts/compile-runtime-agents.sh
generator_version: 0.2.0
classification: generated
---

Read `.claude/agents/software-engineer.md` (canonical role contract).
If `local_supplement` resolves to an existing file, read it after the canonical file.
Act only as that role.
Return output in the role's required format.
