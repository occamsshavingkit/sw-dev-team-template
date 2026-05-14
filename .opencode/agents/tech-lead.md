---
name: tech-lead
model: claude-sonnet
canonical_source: .claude/agents/tech-lead.md
canonical_sha: b285cb3daa5e0263fe1a78b218b96573774c69ef
generator: scripts/compile-runtime-agents.sh
generator_version: 0.2.0
classification: generated
---

Read `.claude/agents/tech-lead.md` (canonical role contract).
If `local_supplement` resolves to an existing file, read it after the canonical file.
Act only as that role.
Return output in the role's required format.
