# Contract: Handoff Hook Events

## PreToolUse Gate

- **Input**: Hook event with tool name, command or write target, and active handoff context.
- **Output**: Allow/warn/block result according to gate mode.
- **Rules**: Resolve active handoff, validate schema, extract write targets, enforce forbidden-over-allowed path scope, and preserve framework/project boundary rules.

## TaskCompleted Gate

- **Input**: Completion event plus active handoff verification state.
- **Output**: Allow/warn/block result according to missing or accepted evidence.
- **Rules**: Worker reports may be recorded but do not satisfy required independent evidence gates.

## TaskCreated Gate

- **Input**: Specialist task creation event and active handoff context.
- **Output**: Allow/warn/block result based on owner role, path scope, and handoff citation.
- **Rules**: Specialist tasks that affect active scope must cite the active handoff and stay within declared role/path boundaries.

## SubagentStop Gate

- **Input**: Specialist stop event and required return/evidence obligations.
- **Output**: Allow/warn/block result based on whether required handoff return data is present.
- **Rules**: Stop cannot discard required evidence or unresolved blocker state.

## Top-Level Stop Gate

- **Input**: Stop event and active handoff consistency state.
- **Output**: Allow/warn/block result based on incomplete, inconsistent, or falsely completed handoff state.
- **Rules**: Stop is flagged when the active handoff contradicts recorded gate state or claims completion without required evidence.

## Bounded Codex Gate

- **Input**: Codex MCP/tool event plus active handoff bounded-Codex fields.
- **Output**: Allow/warn/block result based on explicit permission, path scope, context scope, and evidence requirements.
- **Rules**: Calls must not include full unrelated transcripts and must not exceed handoff-declared authority.
