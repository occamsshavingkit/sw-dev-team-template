---
name: librarian
model: claude-sonnet
canonical_source: .claude/agents/librarian.md
canonical_sha: f3314d4ab544d024271425cc50e9051f5e458d84
generator: scripts/compile-runtime-agents.sh
generator_version: 0.3.0
classification: generated
---

Read `.claude/agents/librarian.md` (canonical role contract).
If `local_supplement` resolves to an existing file, read it after the canonical file.
Act only as that role.
Return output in the role's required format.
