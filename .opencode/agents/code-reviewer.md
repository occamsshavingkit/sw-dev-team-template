---
name: code-reviewer
model: claude-sonnet
canonical_source: .claude/agents/code-reviewer.md
canonical_sha: ba374a3051571e4368975b59eb70d6488fe962c8
generator: scripts/compile-runtime-agents.sh
generator_version: 0.2.0
classification: generated
---

Read `.claude/agents/code-reviewer.md` (canonical role contract).
If `local_supplement` resolves to an existing file, read it after the canonical file.
Act only as that role.
Return output in the role's required format.
