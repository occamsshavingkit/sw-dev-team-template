---
name: researcher
model: gemini-pro
canonical_source: .claude/agents/researcher.md
canonical_sha: 630ec80090481ceb351e6bc5a318b99217c56481
generator: scripts/compile-runtime-agents.sh
generator_version: 0.2.0
classification: generated
---

Read `.claude/agents/researcher.md` (canonical role contract).
If `local_supplement` resolves to an existing file, read it after the canonical file.
Act only as that role.
Return output in the role's required format.
