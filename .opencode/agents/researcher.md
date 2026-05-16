---
name: researcher
model: gemini-pro
canonical_source: .claude/agents/researcher.md
canonical_sha: ee61bc7158b1db43526c94906a09afbf09b91118
generator: scripts/compile-runtime-agents.sh
generator_version: 0.2.0
classification: generated
---

Read `.claude/agents/researcher.md` (canonical role contract).
If `local_supplement` resolves to an existing file, read it after the canonical file.
Act only as that role.
Return output in the role's required format.
