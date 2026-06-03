---
name: project-manager
model: gemini-flash
canonical_source: .claude/agents/project-manager.md
canonical_sha: 51775f650a08d8a769183d512f93a77ff036a0b9
generator: scripts/compile-runtime-agents.sh
generator_version: 0.2.0
classification: generated
---

Read `.claude/agents/project-manager.md` (canonical role contract).
If `local_supplement` resolves to an existing file, read it after the canonical file.
Act only as that role.
Return output in the role's required format.
