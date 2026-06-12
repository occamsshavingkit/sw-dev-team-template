---
name: sre
model: claude-sonnet
canonical_source: .claude/agents/sre.md
canonical_sha: 5200a012925cd7e74f3095cd5622ee1e1839735f
generator: scripts/compile-runtime-agents.sh
generator_version: 0.3.0
classification: generated
---

Read `.claude/agents/sre.md` (canonical role contract).
If `local_supplement` resolves to an existing file, read it after the canonical file.
Act only as that role.
Return output in the role's required format.
