---
name: release-engineer
model: openai-coding
canonical_source: .claude/agents/release-engineer.md
canonical_sha: 8155155b2c80977be48c52e2baa7e78ad2e231ce
generator: scripts/compile-runtime-agents.sh
generator_version: 0.3.0
classification: generated
---

Read `.claude/agents/release-engineer.md` (canonical role contract).
If `local_supplement` resolves to an existing file, read it after the canonical file.
Act only as that role.
Return output in the role's required format.
