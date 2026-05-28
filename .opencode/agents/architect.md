---
name: architect
model: claude-sonnet
canonical_source: .claude/agents/architect.md
canonical_sha: d87e185f4b0687c0150814c1b5a13af301f53ae7
generator: scripts/compile-runtime-agents.sh
generator_version: 0.2.0
classification: generated
---

Read `.claude/agents/architect.md` (canonical role contract).
If `local_supplement` resolves to an existing file, read it after the canonical file.
Act only as that role.
Return output in the role's required format.
