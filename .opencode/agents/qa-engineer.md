---
name: qa-engineer
model: claude-sonnet
canonical_source: .claude/agents/qa-engineer.md
canonical_sha: 17c6e7fddc643f8540f6e40d5a05c669b9f92d55
generator: scripts/compile-runtime-agents.sh
generator_version: 0.2.0
classification: generated
---

Read `.claude/agents/qa-engineer.md` (canonical role contract).
If `local_supplement` resolves to an existing file, read it after the canonical file.
Act only as that role.
Return output in the role's required format.
