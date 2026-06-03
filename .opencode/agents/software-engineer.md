---
name: software-engineer
model: openai-coding
canonical_source: .claude/agents/software-engineer.md
canonical_sha: 2340d72f7e87f653ae657314f31ddbc095a00443
generator: scripts/compile-runtime-agents.sh
generator_version: 0.2.0
classification: generated
---

Read `.claude/agents/software-engineer.md` (canonical role contract).
If `local_supplement` resolves to an existing file, read it after the canonical file.
Act only as that role.
Return output in the role's required format.
