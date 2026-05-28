---
name: software-engineer
model: openai-coding
canonical_source: .claude/agents/software-engineer.md
canonical_sha: 250bd983ee4b9a7dcf9099c094b2a342153ba936
generator: scripts/compile-runtime-agents.sh
generator_version: 0.2.0
classification: generated
---

Read `.claude/agents/software-engineer.md` (canonical role contract).
If `local_supplement` resolves to an existing file, read it after the canonical file.
Act only as that role.
Return output in the role's required format.
