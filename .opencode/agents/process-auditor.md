---
name: process-auditor
model: claude-sonnet
canonical_source: .claude/agents/process-auditor.md
canonical_sha: b1909316a30dfa3fb0e7b0bde2faf0ba98a8b2ad
generator: scripts/compile-runtime-agents.sh
generator_version: 0.2.0
classification: generated
---

Read `.claude/agents/process-auditor.md` (canonical role contract).
If `local_supplement` resolves to an existing file, read it after the canonical file.
Act only as that role.
Return output in the role's required format.
