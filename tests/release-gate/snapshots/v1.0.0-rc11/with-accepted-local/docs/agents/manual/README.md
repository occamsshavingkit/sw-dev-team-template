# docs/agents/manual/

Human-readable agent manuals split out from `.claude/agents/<role>.md`. Classification: **canonical** — these are the source of truth for rationale, worked examples, and historical notes that should not bloat the runtime contracts. One file per role, named to match the role file (e.g., `software-engineer.md`). Edits flow upstream through the normal review path; the runtime contracts in `docs/runtime/agents/` derive from sibling content in `.claude/agents/`, not from these manuals.
