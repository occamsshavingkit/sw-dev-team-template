---
name: software-engineer
model: openai-coding
canonical_source: .claude/agents/software-engineer.md
canonical_sha: f3b59d0390cc3e350f70623c1e63d111aadf3f33
generator: scripts/compile-runtime-agents.sh
generator_version: 0.3.0
classification: generated
---

Read `.claude/agents/software-engineer.md` (canonical role contract).
If `local_supplement` resolves to an existing file, read it after the canonical file.
Act only as that role.
Return output in the role's required format.
