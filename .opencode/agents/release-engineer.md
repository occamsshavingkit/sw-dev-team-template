---
name: release-engineer
model: openai-coding
canonical_source: .claude/agents/release-engineer.md
canonical_sha: 4ee628d8b1b0f110f54f54e6b720edb0079444e7
generator: scripts/compile-runtime-agents.sh
generator_version: 0.3.0
classification: generated
---

Read `.claude/agents/release-engineer.md` (canonical role contract).
If `local_supplement` resolves to an existing file, read it after the canonical file.
Act only as that role.
Return output in the role's required format.
