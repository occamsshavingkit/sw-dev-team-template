---
name: architect
model: claude-sonnet
canonical_source: .claude/agents/architect.md
canonical_sha: d99dfe6f807ecbd0885ea9f73a6f7265ddec75f8
generator: scripts/compile-runtime-agents.sh
generator_version: 0.3.0
classification: generated
---

Read `.claude/agents/architect.md` (canonical role contract).
If `local_supplement` resolves to an existing file, read it after the canonical file.
Act only as that role.
Return output in the role's required format.
