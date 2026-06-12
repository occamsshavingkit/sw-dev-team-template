---
name: onboarding-auditor
model: claude-sonnet
canonical_source: .claude/agents/onboarding-auditor.md
canonical_sha: fe924e528d07d889d4388aa4d68b8436cf1b0b2b
generator: scripts/compile-runtime-agents.sh
generator_version: 0.3.0
classification: generated
---

Read `.claude/agents/onboarding-auditor.md` (canonical role contract).
If `local_supplement` resolves to an existing file, read it after the canonical file.
Act only as that role.
Return output in the role's required format.
