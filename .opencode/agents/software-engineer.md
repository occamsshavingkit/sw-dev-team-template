---
name: software-engineer
model: openai-coding
canonical_source: .claude/agents/software-engineer.md
canonical_sha: 5b5ab8945b8e5a74a7798d4760b7beedf09503e6
generator: scripts/compile-runtime-agents.sh
generator_version: 0.2.0
classification: generated
---

Read `.claude/agents/software-engineer.md` (canonical role contract).
If `local_supplement` resolves to an existing file, read it after the canonical file.
Act only as that role.
Return output in the role's required format.
