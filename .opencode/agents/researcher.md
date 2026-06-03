---
name: researcher
model: gemini-pro
canonical_source: .claude/agents/researcher.md
canonical_sha: c91273c08e551424c48bd3c13d3c551be3d233bb
generator: scripts/compile-runtime-agents.sh
generator_version: 0.2.0
classification: generated
---

Read `.claude/agents/researcher.md` (canonical role contract).
If `local_supplement` resolves to an existing file, read it after the canonical file.
Act only as that role.
Return output in the role's required format.
