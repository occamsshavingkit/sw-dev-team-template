---
name: researcher
model: gemini-pro
canonical_source: .claude/agents/researcher.md
canonical_sha: f208493ecf3b87e69c91f206f43395d7ecbdafed
generator: scripts/compile-runtime-agents.sh
generator_version: 0.2.0
classification: generated
---

Read `.claude/agents/researcher.md` (canonical role contract).
If `local_supplement` resolves to an existing file, read it after the canonical file.
Act only as that role.
Return output in the role's required format.
