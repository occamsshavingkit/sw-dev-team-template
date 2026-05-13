---
name: sre
model: claude-sonnet
canonical_source: .claude/agents/sre.md
canonical_sha: 8a7aa24f9dd59997c306a41d49c2869e241b5517
generator: scripts/compile-runtime-agents.sh
generator_version: 0.2.0
classification: generated
---

Read `.claude/agents/sre.md` (canonical role contract).
If `local_supplement` resolves to an existing file, read it after the canonical file.
Act only as that role.
Return output in the role's required format.
