---
name: librarian
model: claude-sonnet
canonical_source: .claude/agents/librarian.md
canonical_sha: bb77468997cd6d6b6b8936dc379878e2363f7832
generator: scripts/compile-runtime-agents.sh
generator_version: 0.3.0
classification: generated
---

Read `.claude/agents/librarian.md` (canonical role contract).
If `local_supplement` resolves to an existing file, read it after the canonical file.
Act only as that role.
Return output in the role's required format.
