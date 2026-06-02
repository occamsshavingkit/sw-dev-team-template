---
name: code-reviewer
model: claude-sonnet
canonical_source: .claude/agents/code-reviewer.md
canonical_sha: 5df8f8e58c909ba4615a2270633d6c2332334d54
generator: scripts/compile-runtime-agents.sh
generator_version: 0.2.0
classification: generated
---

Read `.claude/agents/code-reviewer.md` (canonical role contract).
If `local_supplement` resolves to an existing file, read it after the canonical file.
Act only as that role.
Return output in the role's required format.
