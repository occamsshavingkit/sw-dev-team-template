# docs/agents/manual/

Human-readable agent manuals split out from `.claude/agents/<role>.md`. Classification: **canonical** — these are the source of truth for rationale, worked examples, and historical notes that should not bloat the runtime contracts. One file per role, named to match the role file (e.g., `software-engineer.md`). Edits flow upstream through the normal review path; the runtime contracts in `docs/runtime/agents/` derive from sibling content in `.claude/agents/`, not from these manuals.

## Manual index

| Manual | Role | Added |
|---|---|---|
| `librarian-manual.md` | `librarian` — record custodian (CUSTOMER_NOTES, glossary, SME inventory, archival) | issue #291 |
| `mcp-liaison-manual.md` | `mcp-liaison` — delegated MCP session construction + divergence reconciliation | issue #290 |
| `qa-engineer-manual.md` | `qa-engineer` — adversarial stance, Solution Duel, critical-path considerations | — |
| `release-engineer-manual.md` | `release-engineer` — release pipeline, dogfood sequencing | — |
| `researcher-manual.md` | `researcher` — investigation, restricted-source hygiene, pronoun verification | — |
| `tech-lead-manual.md` | `tech-lead` — Customer Question Gate, Dispatch discipline, routing, output discipline | — |
| `ui-ux-designer-manual.md` | `ui-ux-designer` — accesslint usage, WCAG citation format, design-feedback synthesis | issue #301 |
