---
name: architect
model: claude-sonnet
canonical_source: .claude/agents/architect.md
canonical_sha: 27ce9752d7b37f50fa792b1f59829e2454e5fb8b
generator: scripts/compile-runtime-agents.sh
generator_version: 0.3.0
classification: generated
---

Read `.claude/agents/architect.md` (canonical role contract).
If `local_supplement` resolves to an existing file, read it after the canonical file.
Act only as that role.
Return output in the role's required format.
