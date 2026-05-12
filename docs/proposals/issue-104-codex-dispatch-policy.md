# Issue 104: Codex dispatch policy binding

Status: proposed.

## Compact proposal

Bind Codex dispatch docs to the existing routing and slot-health sources instead of relying on implicit knowledge.

## Scope

- Update `AGENTS.md` so Codex dispatches must read `docs/model-routing-guidelines.md` for role tier and `reasoning_effort`, and `docs/agent-health-contract.md` for slot state, queueing, and liveness vocabulary.
- Update `.claude/agents/tech-lead.md` with the same binding language so dispatch briefs and turn summaries record the selected effort and slot-health state.
- Remove the transient `<claude-mem-context>` block from `AGENTS.md`.

## Verification

- `rg -n "model-routing-guidelines.md|agent-health-contract.md|reasoning_effort|queued|running|completed|unknown/unreachable" AGENTS.md .claude/agents/tech-lead.md`
- `git diff --stat`
