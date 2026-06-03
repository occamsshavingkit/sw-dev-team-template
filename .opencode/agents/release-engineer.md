---
name: release-engineer
model: openai-coding
canonical_source: .claude/agents/release-engineer.md
canonical_sha: 05d066a65cf6c7035463a91956c16b44f56b58e2
generator: scripts/compile-runtime-agents.sh
generator_version: 0.2.0
classification: generated
---

Read `.claude/agents/release-engineer.md` (canonical role contract).
If `local_supplement` resolves to an existing file, read it after the canonical file.
Act only as that role.
Return output in the role's required format.
