---
name: architect
model: claude-sonnet
canonical_source: .claude/agents/architect.md
canonical_sha: cb2ccc9033ba2eda00e80565c68a63ea17c8c038
generator: scripts/compile-runtime-agents.sh
generator_version: 0.3.0
classification: generated
---

Read `.claude/agents/architect.md` (canonical role contract).
If `local_supplement` resolves to an existing file, read it after the canonical file.
Act only as that role.
Return output in the role's required format.
