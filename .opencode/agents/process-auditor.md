---
name: process-auditor
model: claude-sonnet
canonical_source: .claude/agents/process-auditor.md
canonical_sha: 48e7dbf2d442ca194910f295b7b12888fd1ea2db
generator: scripts/compile-runtime-agents.sh
generator_version: 0.3.0
classification: generated
---

Read `.claude/agents/process-auditor.md` (canonical role contract).
If `local_supplement` resolves to an existing file, read it after the canonical file.
Act only as that role.
Return output in the role's required format.
