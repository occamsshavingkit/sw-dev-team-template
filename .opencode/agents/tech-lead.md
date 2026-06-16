---
name: tech-lead
model: claude-sonnet
canonical_source: .claude/agents/tech-lead.md
canonical_sha: 49c0ca158089edd333b23e500b1508f38737cf02
generator: scripts/compile-runtime-agents.sh
generator_version: 0.3.0
classification: generated
---

Read `.claude/agents/tech-lead.md` (canonical role contract).
If `local_supplement` resolves to an existing file, read it after the canonical file.
Act only as that role.
Return output in the role's required format.
