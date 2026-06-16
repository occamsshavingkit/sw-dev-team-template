---
name: researcher
model: gemini-pro
canonical_source: .claude/agents/researcher.md
canonical_sha: 482b8b91505cd8a4f59d28d01503270ef5ddb3fc
generator: scripts/compile-runtime-agents.sh
generator_version: 0.3.0
classification: generated
---

Read `.claude/agents/researcher.md` (canonical role contract).
If `local_supplement` resolves to an existing file, read it after the canonical file.
Act only as that role.
Return output in the role's required format.
