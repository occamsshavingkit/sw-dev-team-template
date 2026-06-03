---
name: architect
model: claude-sonnet
canonical_source: .claude/agents/architect.md
canonical_sha: 14d62cd66bf0e345e395678de810887f236a0bbb
generator: scripts/compile-runtime-agents.sh
generator_version: 0.2.0
classification: generated
---

Read `.claude/agents/architect.md` (canonical role contract).
If `local_supplement` resolves to an existing file, read it after the canonical file.
Act only as that role.
Return output in the role's required format.
