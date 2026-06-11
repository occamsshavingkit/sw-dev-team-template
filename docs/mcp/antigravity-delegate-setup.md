# Antigravity delegate shim — registration

Setup guide for operators registering the `antigravity-delegate` MCP server
in a Claude Code session. This shim lets Claude Code (Claude as orchestrator)
delegate a unit of work to Google Antigravity inline and receive the result
back — the Claude-to-Antigravity direction. This is the complement to
FW-ADR-0026, which covers the inverse: Antigravity loading the team.

---

## Prerequisites

- **`agy` (Antigravity CLI)** installed and authenticated. The shim manages
  no credentials. Run `agy login` (or equivalent) before registering the
  shim. If `agy` is not authenticated, the tool returns the error text from
  Antigravity's output; no Claude Code session state is affected.
- **Python 3** (standard library only; no `pip install` step required).
- **Unix (Linux or macOS)**. The shim uses the `pty` module, which is
  Unix-only. Windows is not supported.

---

## Register the shim

Choose one registration method. Both are equivalent.

### Option A — `claude mcp add`

```sh
claude mcp add antigravity-delegate python3 \
  /abs/path/to/sw-dev-team-template/scripts/mcp/antigravity_delegate.py
```

Replace `/abs/path/to/sw-dev-team-template` with the absolute path to the
scaffold checkout on this machine.

### Option B — `.mcp.json` entry

Add the following block to `.mcp.json` at the project root (create the file
if absent):

```json
{
  "mcpServers": {
    "antigravity-delegate": {
      "command": "python3",
      "args": ["/abs/path/to/sw-dev-team-template/scripts/mcp/antigravity_delegate.py"]
    }
  }
}
```

Again, use the absolute path to the scaffold checkout.

The shim is **not** registered automatically by scaffold setup because `agy`
is not a universal prerequisite. Registration is a one-time manual step per
Claude Code profile.

---

## Verify registration

After registration, confirm the server appears:

```sh
claude mcp list
```

Expected output includes a line naming `antigravity-delegate`.

Within a Claude Code session, confirm the tool is discoverable by calling
`tools/list`. The `antigravity_delegate` tool should appear in the response.

---

## Tool reference

**Tool name:** `antigravity_delegate`

| Parameter | Type | Required | Default | Notes |
|---|---|---|---|---|
| `task` | string | yes | — | The task or prompt to send to Antigravity. Passed as a raw argument; no shell parsing occurs. |
| `model` | string | no | `Gemini 3.5 Flash (High)` | Must be a value in the shim's `ALLOWED_MODELS` constant or the call is rejected with error code `-32602` (Invalid params). |
| `timeout_s` | integer | no | `300` | Seconds before the `agy` process is killed. On timeout the tool returns a structured error, not a hang. |

**Output:** Plain text. Terminal control sequences (ANSI and OSC escape
sequences) are stripped before the result is returned.

**On success:** A `text` content block containing Antigravity's captured
output.

**On error:** A structured MCP error response (`isError: true`) with a
description. Claude Code receives a recoverable error, not a server crash.
Error conditions: timeout, nonzero `agy` exit, invalid `model` value.

Model selection for calls should follow `docs/model-routing-guidelines.md`.
The `mcp-liaison` role owns brief construction and model selection at call
time; see `docs/agents/manual/mcp-liaison-manual.md` § "Delegating to
Antigravity".

---

## Troubleshooting

**Empty output or auth-error text in the result:**
`agy` is not authenticated. Run `agy login` (or the appropriate
authentication command for your Antigravity installation) and retry.

**Call rejected with Invalid params (`-32602`) on the `model` parameter:**
The supplied model string is not in the shim's `ALLOWED_MODELS` constant.
Check the current allowlist in
`scripts/mcp/antigravity_delegate.py`. To add a new model string, confirm
it works with `agy` first, then extend `ALLOWED_MODELS` in that file.

**`antigravity-delegate` does not appear in `claude mcp list`:**
Confirm the absolute path in the registration command or `.mcp.json` entry
points to the actual file on disk. Python 3 must be on `PATH`.

---

## Reference

- Authoritative design: `docs/adr/fw-adr-0027-antigravity-mcp-delegate-shim.md`
- Complementary setup (Antigravity-as-orchestrator direction):
  `docs/adr/fw-adr-0026-antigravity-harness-adapter.md`
- Model selection: `docs/model-routing-guidelines.md`
- Brief construction and delegation: `docs/agents/manual/mcp-liaison-manual.md`
