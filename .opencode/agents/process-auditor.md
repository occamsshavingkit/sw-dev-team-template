---
name: process-auditor
model: claude-sonnet
canonical_source: .claude/agents/process-auditor.md
canonical_sha: aeb76aa02e9c97b07f353d462de4dc10087e36d1
generator: scripts/compile-runtime-agents.sh
generator_version: 0.3.0
classification: generated
---

Read `.claude/agents/process-auditor.md` (canonical role contract).
If `local_supplement` resolves to an existing file, read it after the canonical file.
Act only as that role.
Return output in the role's required format.
