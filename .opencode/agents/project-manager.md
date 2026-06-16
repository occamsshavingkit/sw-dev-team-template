---
name: project-manager
model: gemini-flash
canonical_source: .claude/agents/project-manager.md
canonical_sha: da8dda49fd5c37bbd2d9b56103deebb5f830c155
generator: scripts/compile-runtime-agents.sh
generator_version: 0.3.0
classification: generated
---

Read `.claude/agents/project-manager.md` (canonical role contract).
If `local_supplement` resolves to an existing file, read it after the canonical file.
Act only as that role.
Return output in the role's required format.
