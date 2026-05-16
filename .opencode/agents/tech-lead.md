---
name: tech-lead
model: claude-sonnet
canonical_source: .claude/agents/tech-lead.md
canonical_sha: 7ebb0e4c78d272719b63ceccfdd48716f2ca6387
generator: scripts/compile-runtime-agents.sh
generator_version: 0.2.0
classification: generated
---

Read `.claude/agents/tech-lead.md` (canonical role contract).
If `local_supplement` resolves to an existing file, read it after the canonical file.
Act only as that role.
Return output in the role's required format.
