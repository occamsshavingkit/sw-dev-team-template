---
name: code-reviewer
model: claude-sonnet
canonical_source: .claude/agents/code-reviewer.md
canonical_sha: 576393d45b5919dec4cb3c1276d8531acb1205a0
generator: scripts/compile-runtime-agents.sh
generator_version: 0.3.0
classification: generated
---

Read `.claude/agents/code-reviewer.md` (canonical role contract).
If `local_supplement` resolves to an existing file, read it after the canonical file.
Act only as that role.
Return output in the role's required format.
