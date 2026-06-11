# mcp-liaison — manual (rationale, examples, history)

**Canonical contract**: [.claude/agents/mcp-liaison.md](../../../.claude/agents/mcp-liaison.md)
**Generated runtime contract**: [docs/runtime/agents/mcp-liaison.md](../../runtime/agents/mcp-liaison.md)
**Classification**: canonical (manual; rationale companion)

This manual carries the delegation protocol, brief shape, and
divergence-reconciliation format for `mcp-liaison`. Role added in
issue #290 (customer ruling Q-0030). Coherent without #293 / #300
(those are separate later tasks).

## Taxonomy note

Custom role, taxonomy §5. Closest industry analogue: SINT (System
Integration Specialist) adapted to external-model delegation via MCP.
Not a router or orchestrator — `tech-lead` routes; this role delegates
to MCP tools, monitors, and reconciles.

## Delegation protocol

### Step 1 — Read the brief

Before making any MCP call, read the brief in full. Confirm:

- The target MCP service or tool is named explicitly.
- The expected output shape is described.
- The scope boundary is clear (what the brief asks for, and what is
  explicitly out of scope).

If any of these are missing, flag to `tech-lead` via `SendMessage`
before proceeding. Do not guess scope.

### Step 2 — Make the MCP call

Use whichever MCP tools are available in the current session that
match the brief. The available tools are your delegation surface.

If the named MCP tool is not available in the current session, stop
and report the blocker to `tech-lead` via `SendMessage`. Do not
substitute a different tool without instruction.

### Step 3 — Capture the raw response

Capture the MCP response verbatim before any processing. Store it
as the evidentiary record. This raw capture must appear in the return
to `tech-lead`.

### Step 4 — Divergence reconciliation (binding)

Before forwarding or accepting the output, check it against:

1. **Repo state.** Do the MCP findings contradict committed files,
   registered decisions, or ADRs? If yes, flag as a divergence.
2. **Customer-truth.** Does the output contradict entries in
   `CUSTOMER_NOTES.md`? If yes, flag as a divergence.
3. **Brief scope.** Does the output include unsolicited content or
   recommendations that go beyond the brief's stated scope? Flag those
   items as out-of-scope.

A divergence must be **routed to `tech-lead` before the output is
accepted**. Do not resolve divergences unilaterally. Do not forward
contradictory output as if it were clean.

### Step 5 — Structured return

Return to `tech-lead` with this structure:

```
## MCP liaison return — <brief title>

### Raw MCP response
<verbatim tool output, fenced>

### Structured summary
<findings in the output, in plain prose, one paragraph per finding>

### Divergences
<list any divergences found in Step 4, each with:
 - What the MCP output says
 - What the repo state / customer-truth says
 - Why they conflict
 - Status: awaiting tech-lead resolution>

(If none: "No divergences detected.")

### Out-of-scope items
<list any MCP output that goes beyond the brief scope>

(If none: "None.")
```

## Divergence report format

When a divergence requires `tech-lead` attention before the main
return, send a `SendMessage` with:

```
Divergence detected in MCP output for <brief title>.

MCP output says: <exact quote or summary>
Repo / customer-truth says: <exact quote or reference with path>
Conflict: <one sentence explaining the contradiction>

Awaiting instruction before proceeding.
```

Do not proceed with the rest of the brief until `tech-lead` resolves
the divergence or explicitly authorizes accepting the contradictory
output with a recorded rationale.

## What this role is NOT

- **Not a router.** `tech-lead` decides which MCP service to invoke
  and why. `mcp-liaison` executes the delegation.
- **Not an orchestrator.** Receiving a brief does not confer authority
  to spawn other agents, expand session scope, or make design decisions.
- **Not a customer interface.** All escalations route to `tech-lead`,
  never to the customer.

## Delegating to Antigravity

The `antigravity_delegate` tool is `mcp-liaison`'s transport for delegating
work to Google Antigravity from within a Claude Code session. See
`docs/adr/fw-adr-0027-antigravity-mcp-delegate-shim.md` for the full design.

### Brief construction

`mcp-liaison` is responsible for constructing the `task` string — the
delegated brief — that is passed to `antigravity_delegate`. The shim is a
dumb transport: it passes `task` to `agy` as a raw argument without
interpreting, rewriting, or validating the content. What `mcp-liaison` puts
in `task` is what Antigravity receives.

A well-formed delegated brief should:

- State the goal in one or two sentences.
- Include the scope boundary explicitly (what is in scope, what is not).
- Specify the expected output shape (e.g., "return a numbered list of
  findings", "return a single revised paragraph").

Do not assume Antigravity has access to repo files or prior context from the
Claude Code session. The brief must be self-contained.

### Model selection

Select the `model` parameter value from `docs/model-routing-guidelines.md`.
The shim validates the value against its internal `ALLOWED_MODELS` constant
and rejects unrecognized strings with a structured error. If the desired
model is not in the allowlist, confirm the model string works with `agy`
first and then extend `ALLOWED_MODELS` in
`scripts/mcp/antigravity_delegate.py`.

Default model when `model` is omitted: `Gemini 3.5 Flash (High)`. For
tasks requiring stronger reasoning, pass an explicit `model` value
consistent with the routing guidelines.

### Interpreting the response

The shim returns plain text with terminal control sequences stripped. It does
not parse, validate, or summarize Antigravity's output. `mcp-liaison` is
responsible for divergence reconciliation per the standard delegation
protocol (Steps 3–5 above).

If the response is empty or contains an auth-error message, `agy` is not
authenticated. Report the blocker to `tech-lead`; do not retry in a loop.

If the call returns `isError: true`, the error message includes the
condition (timeout after N seconds, nonzero exit code, or invalid model
parameter). Route the structured error back to `tech-lead` as a divergence.

### Relationship to issue #289

Issue #289 addresses the inverse concern: a session spawned over MCP must
not start the orchestrator team. This shim is not a session and has no
team-start behavior. The two concerns are non-conflicting: `mcp-liaison`
calls `antigravity_delegate` as a tool from within the primary Claude Code
session; the shim is a subprocess bridge, not a spawned session.

---

## Brief shape (recommended)

When `tech-lead` dispatches to `mcp-liaison`, a well-formed brief
includes:

```
Target MCP tool(s): <tool name(s) or "use whichever is available">
Task: <one sentence>
Input: <what to pass to the MCP call, or reference to file>
Expected output shape: <what the return should look like>
Scope boundary: <explicit statement of what is out of scope>
Divergence handling: <"flag all" (default) | "auto-accept if minor">
```

`tech-lead` may omit fields the specialist can infer from context, but
explicit scope boundary and divergence handling reduce round-trips.
