---
name: fw-adr-0027-antigravity-mcp-delegate-shim
description: >
  Define the Antigravity delegate shim: a thin local stdio MCP server
  (Python 3 stdlib only) that Claude Code registers as an MCP server,
  exposing one tool — antigravity_delegate — so Claude can delegate a
  unit of work to Antigravity inline and receive the result back, with
  PTY spawning for agy, argv-list invocation to prevent shell injection,
  bounded output, and timeout control.
status: accepted
date: 2026-06-11
---


# FW-ADR-0027 — Antigravity MCP delegate shim

<!-- TOC -->

- [Status](#status)
- [Scaffold placement note](#scaffold-placement-note)
- [Background: binary analysis of agy (2026-06-11)](#background-binary-analysis-of-agy-2026-06-11)
- [Context and problem statement](#context-and-problem-statement)
- [Decision drivers](#decision-drivers)
- [Considered options (Three-Path Rule, binding)](#considered-options-three-path-rule-binding)
  - [Option M — Minimalist](#option-m--minimalist)
  - [Option S — Scalable](#option-s--scalable)
  - [Option C — Creative (experimental)](#option-c--creative-experimental)
- [Decision outcome](#decision-outcome)
- [Design: Antigravity delegate shim](#design-antigravity-delegate-shim)
  - [1. MCP tool surface](#1-mcp-tool-surface)
  - [2. Stdio MCP protocol (JSON-RPC 2.0 by hand)](#2-stdio-mcp-protocol-json-rpc-20-by-hand)
  - [3. PTY spawning and argv-list invocation](#3-pty-spawning-and-argv-list-invocation)
  - [3a. Security-engineer sign-off (2026-06-11): binding implementation requirements](#3a-security-engineer-sign-off-2026-06-11-binding-implementation-requirements)
  - [4. Timeout and bounded output](#4-timeout-and-bounded-output)
  - [5. Model default and override](#5-model-default-and-override)
  - [6. Auth assumption](#6-auth-assumption)
  - [7. Placement and registration](#7-placement-and-registration)
- [Implementation change-set grouped by owner](#implementation-change-set-grouped-by-owner)
  - [software-engineer](#software-engineer)
  - [tech-writer](#tech-writer)
- [Relationship to existing ADRs and roles](#relationship-to-existing-adrs-and-roles)
- [Consequences](#consequences)
  - [Positive](#positive)
  - [Negative / trade-offs accepted](#negative--trade-offs-accepted)
  - [Follow-up ADRs](#follow-up-adrs)
- [Verification](#verification)
- [Links](#links)

<!-- /TOC -->

---

## Status

- **Accepted**
- **Proposed:** 2026-06-11
- **Accepted:** 2026-06-11 — `security-engineer` sign-off on §3 recorded
  (2026-06-11); customer approved the shim concept ("thin MCP-server shim").
- **Deciders:** `architect`; `security-engineer` co-owns the argv-list /
  PTY spawning security constraint (Hard Rule #7 adjacency — the shim
  is not auth/secrets-handling but it executes attacker-influenced text
  as a subprocess argument); `tech-lead` + customer acceptance obtained
  2026-06-11
- **Consulted:** FW-ADR-0026 (Antigravity harness adapter — the other
  direction: Antigravity loading the team); binary analysis of installed
  `~/.local/bin/agy`, 2026-06-11; issue #289 (MCP non-primary-session
  rule); issue #338 / #339 context; `mcp-liaison` role contract
  (Q-0022 / gh issue #290)

## Scaffold placement note

This ADR is authored in the meta-project (`docs/adr/`) per the PLAN/DO
convention (CLAUDE.md § "Project Identity / Working Tree"). The
implementation artifacts (server script, smoke test) land in the scaffold
(`scripts/mcp/antigravity_delegate.py`). The ADR migrates into the
scaffold's `docs/adr/` with the implementation PR. Pattern established
by FW-ADR-0022 and FW-ADR-0026.

---

## Background: binary analysis of agy (2026-06-11)

Direct inspection of `~/.local/bin/agy` established two facts that
constrain the design:

1. **`agy` is an MCP client only.** It has no serve mode and cannot
   be registered directly as an MCP server. The option of using `agy`
   itself as an MCP server endpoint is structurally unavailable.

2. **`agy --print` requires a PTY.** Plain headless invocation
   (`agy --print '<task>' --model '<model>'`) emits nothing to stdout.
   The proven working invocation is
   `script -qec "agy --print '...' --model '...'" /dev/null`,
   which provides a PTY. This is the operational primitive the shim
   must replicate — via the stdlib `pty` module, not via `script`,
   to avoid shell injection (see § 3 below).

These two findings are HIGH confidence (direct binary inspection) and
are the foundation of the design. Any implementation that contradicts
either finding will not work.

---

## Context and problem statement

FW-ADR-0026 addressed the Antigravity-loads-the-team direction: making
the team roster visible to an Antigravity session that a human opens
directly. This ADR addresses the inverse direction: a Claude Code session
(Claude as orchestrator, `tech-lead` persona) that wants to delegate a
unit of work to Antigravity and receive the result inline — the same
first-class delegation pattern Claude uses for any other registered MCP
server.

The `mcp-liaison` role (Q-0022 / gh issue #290) owns delegated external-
model MCP sessions. The Antigravity case is the first concrete instance:
`tech-lead` constructs a delegated brief, hands it to `mcp-liaison`, and
`mcp-liaison` dispatches it via the `antigravity_delegate` tool. The
shim is `mcp-liaison`'s transport for Antigravity.

The ADR trigger is a new external dependency added to the scaffold
(the shim script itself and the `agy` CLI as a runtime prerequisite),
a new MCP tool surface, and a cross-cutting concern for subprocess
spawning with attacker-influenced input (shell-injection risk that
requires explicit `security-engineer` alignment).

## Decision drivers

- `agy` has no serve mode; a wrapper MCP server must be built
  to bridge Claude Code's MCP client to Antigravity's CLI.
- `agy --print` requires a PTY to produce output; the PTY must be
  provided programmatically, not via `script`, to avoid shell injection
  when `task` is attacker-influenced free text.
- The framework's zero-install philosophy: any new script must run on
  any machine where the scaffold runs, without requiring a separate
  `pip install` step. Python 3 stdlib is universally available on the
  supported platforms; third-party MCP SDKs are not.
- Claude Code registers MCP servers via `.mcp.json` / `claude mcp add`.
  The shim must implement the stdio MCP protocol (JSON-RPC 2.0 over
  stdin/stdout) directly, since no external MCP library is permitted.
- The `task` string is attacker-influenced: it originates from Claude's
  context, which includes user-provided content. Shell command
  construction from `task` is a code-injection surface and is
  prohibited by this ADR.
- Timeout and bounded output are operational requirements: Antigravity
  tasks can run indefinitely; Claude Code must not hang waiting for a
  response.

## Considered options (Three-Path Rule, binding)

### Option M — Minimalist

A thin wrapper shell script (Bash) that Claude Code calls via a Bash
tool call — not via MCP. Claude constructs a `bash` call to the wrapper
with the task as an argument; the wrapper invokes `script -qec
"agy --print '$TASK' --model '$MODEL'" /dev/null` and prints the result
to stdout for Claude to read.

- **Sketch:** One Bash script (`scripts/agy-delegate.sh`), ~30 lines.
  No protocol implementation. Claude calls it via the `Bash` tool, not
  as an MCP server. No registration in `.mcp.json`.
- **Pros:** Trivially simple. No Python required. No MCP protocol
  implementation. Ship-today viability.
- **Cons:** Not first-class MCP delegation — Claude calls it as a bash
  command, not as a registered tool with a typed schema. Shell-injection
  risk: constructing the `script -qec "agy --print '$TASK' ..."` command
  string from `task` is exploitable if `task` contains single-quote
  characters or shell metacharacters. The `task` value originates from
  attacker-influenced context; this is a real injection surface. Bash
  quoting of arbitrary text is notoriously fragile. Explicitly rejected
  on security grounds. `security-engineer` sign-off would be required
  and would likely not be granted for this shape.
- **When M wins:** `task` is always a fixed, trusted constant (never
  user-influenced); the project does not need first-class MCP tool
  schema; and the `security-engineer` explicitly accepts the injection
  surface. None of these hold.

### Option S — Scalable

A thin local stdio MCP server written in Python 3 (stdlib only) that
Claude Code registers as an MCP server. It implements the MCP stdio
protocol (JSON-RPC 2.0 over stdin/stdout: `initialize`, `tools/list`,
`tools/call` methods) by hand, without any third-party MCP SDK. It
exposes one tool, `antigravity_delegate(task, model?, timeout_s?)`,
which spawns `agy` via `pty.openpty()` / `os.fork()` / `os.execvp()`
with an argv list — never a shell command string. It captures output,
enforces a configurable timeout, caps captured bytes, and returns a
structured MCP result (or a structured MCP error on timeout / nonzero
exit). Auth relies on the user's existing `agy` login state.

- **Sketch:** One Python 3 script (`scripts/mcp/antigravity_delegate.py`),
  ~200–280 lines. JSON-RPC 2.0 request / response dispatch loop on
  stdin/stdout. PTY allocation via `os.openpty()` + `os.fork()` +
  `os.execvp(["agy", "--print", task, "--model", model])`. Output
  capture loop with `select`-based timeout and byte cap. Registration
  via `.mcp.json` entry or `claude mcp add` command. One smoke test
  (`scripts/mcp/test_antigravity_delegate.py`) that exercises the JSON-
  RPC layer with a mock subprocess (does not require live `agy`).
- **Pros:** First-class MCP tool with typed schema visible to Claude.
  Argv-list invocation eliminates shell injection as a class — task
  content never touches a shell parser. Python stdlib only: zero extra
  install. PTY via `pty` module replicates the proven `script -qec`
  primitive without shelling out. Timeout and byte-cap prevent hanging.
  Structured MCP error response lets Claude handle failure gracefully.
- **Cons:** ~200+ lines of hand-rolled JSON-RPC 2.0. More surface area
  than Option M. The `pty` module is Unix-only (Linux / macOS); Windows
  is not supported. Implementation must correctly implement the MCP
  handshake (`initialize` / `initialized`, capability negotiation) or
  Claude Code will not register the server.
- **When S wins:** `task` is attacker-influenced (always the case here);
  first-class MCP delegation is required for `mcp-liaison` dispatch;
  zero-install constraint rules out third-party SDKs. All three hold.

### Option C — Creative (experimental)

Use the `subprocess` module with `start_new_session=True` to allocate
a controlling terminal via `setsid()` + `TIOCSWINSZ` ioctl, bypassing
the `pty` module entirely. Alternatively, implement the entire shim as a
TypeScript/Node.js script (Node ships with macOS and is commonly
available on Linux) using the `@modelcontextprotocol/sdk` npm package —
which provides a complete MCP stdio server implementation — and Node's
`node-pty` package for PTY spawning. The Node approach trades stdlib
purity for dramatically less hand-rolled protocol code (~40 lines vs.
~270).

- **Sketch (Node variant):** `scripts/mcp/antigravity_delegate.js`,
  ~60 lines; `package.json` in `scripts/mcp/` pinning
  `@modelcontextprotocol/sdk` and `node-pty`. Registration identical
  to Option S. The MCP SDK handles all JSON-RPC dispatch; `node-pty`
  handles PTY allocation. Smoke test via Jest or `node --test`.
- **Pros:** Dramatically less hand-rolled code. `@modelcontextprotocol/sdk`
  is the reference implementation — protocol conformance is guaranteed.
  `node-pty` is the widely-used PTY library with prebuilt binaries.
- **Cons:** Adds two npm dependencies (violates the stdlib-only
  constraint). Requires Node.js and npm on the operator's machine.
  Requires a `package.json` and `node_modules/` or a bundling step.
  Prebuilt native binaries in `node-pty` are a supply-chain surface.
  Node is not universally available the way Python 3 is. This option
  is rejected by the zero-install / zero-extra-dependency constraint.
- **When C wins:** Node.js is a guaranteed ambient runtime in the
  target environment; the team is comfortable auditing a native npm
  dependency; and protocol conformance risk in hand-rolled JSON-RPC 2.0
  is judged higher than supply-chain risk from `node-pty`. None of
  these hold for a scaffold targeting diverse downstream projects.

## Decision outcome

**Chosen option: S — Scalable (Python 3 stdlib stdio MCP server).**

Option M is rejected on security grounds: constructing a shell command
string from attacker-influenced `task` content is an injection surface
that `security-engineer` alignment would not clear. Even with careful
Bash quoting, the fragility of quoting arbitrary Unicode text inside a
doubly-nested shell command string (`script -qec "agy --print '...' ..."`)
is not an acceptable risk when argv-list invocation is available.

Option C is rejected by the zero-install constraint. Adding npm
dependencies to the scaffold forces every downstream project operator to
run `npm install` and accept native prebuilt binaries in their environment.
The Python 3 stdlib provides all necessary primitives (`pty`, `os`,
`select`, `json`, `sys`) without any additional installs.

Option S satisfies all decision drivers: stdlib only, argv-list PTY
spawn eliminates injection, MCP protocol is first-class (typed schema,
structured errors), timeout and byte-cap prevent hangs, and the
implementation is auditable in a single ~270-line file.

---

## Design: Antigravity delegate shim

### 1. MCP tool surface

The shim registers one tool with the following JSON Schema:

```json
{
  "name": "antigravity_delegate",
  "description": "Delegate a task to Google Antigravity (agy) and return the response. Requires agy to be installed and authenticated.",
  "inputSchema": {
    "type": "object",
    "properties": {
      "task": {
        "type": "string",
        "description": "The task or prompt to send to Antigravity."
      },
      "model": {
        "type": "string",
        "description": "Antigravity model string. Defaults to 'Gemini 3.5 Flash (High)'.",
        "default": "Gemini 3.5 Flash (High)"
      },
      "timeout_s": {
        "type": "integer",
        "description": "Seconds before the agy process is killed and an error returned. Defaults to 300.",
        "default": 300
      }
    },
    "required": ["task"]
  }
}
```

On success, the tool returns a `text` content block containing
Antigravity's captured stdout. On timeout, nonzero exit, or internal
error, it returns a structured MCP error response (not a Python
exception; the shim must never crash the MCP server loop on a
subprocess failure).

### 2. Stdio MCP protocol (JSON-RPC 2.0 by hand)

The shim reads newline-delimited JSON-RPC 2.0 from stdin and writes
responses to stdout. The MCP handshake sequence is:

1. Client sends `initialize` — shim responds with `capabilities`
   (tools only; no resources, no prompts).
2. Client sends `initialized` notification — shim acknowledges (no
   response required for notifications).
3. Client sends `tools/list` — shim returns the `antigravity_delegate`
   tool schema.
4. Client sends `tools/call` with `name: "antigravity_delegate"` and
   `arguments` — shim spawns `agy`, captures output, returns result.

The dispatch loop runs until stdin closes (EOF). All JSON-RPC errors
(method not found, invalid params, internal error) are returned as
JSON-RPC error objects with appropriate error codes, not as process
crashes.

Implementation note: the MCP stdio protocol uses Content-Length framing
in some SDK versions but most Claude Code server registrations use
newline-delimited JSON. The implementation should be confirmed against
the Claude Code MCP stdio spec before the PR is merged. If Content-Length
framing is required, the protocol layer is the only affected section
(~15 lines).

### 3. PTY spawning and argv-list invocation

**This is the security-driving decision. `security-engineer` reviewed
this section on 2026-06-11 (APPROVED with binding requirements in §3a).**

The proven working invocation (from 2026-06-11 binary analysis) is:

```
script -qec "agy --print '<task>' --model '<model>'" /dev/null
```

This works because `script` allocates a PTY and `agy` detects the TTY
and enables output. The shim replicates this using the Python stdlib
`pty` module, **without shelling out to `script`**, as follows:

```
parent_fd, child_fd = os.openpty()
pid = os.fork()
if pid == 0:          # child
    os.setsid()
    fcntl.ioctl(child_fd, termios.TIOCSCTTY, 0)
    os.dup2(child_fd, 0)   # stdin
    os.dup2(child_fd, 1)   # stdout
    os.dup2(child_fd, 2)   # stderr
    os.close(parent_fd)
    os.execvp("agy", ["agy", "--print", task, "--model", model])
# parent: read from parent_fd with select-based timeout
```

The critical constraint is `os.execvp("agy", ["agy", "--print", task,
"--model", model])`. The `task` value is passed as a single element in
the argv list, not interpolated into any shell command string. The OS
passes it to `agy` as a raw argument; no shell parser ever sees it. This
eliminates shell-injection as a class, regardless of what characters
`task` contains (quotes, semicolons, backticks, dollar signs, newlines).

**Correction (R3 — fd hygiene):** The pseudocode above omits a required
step on the parent side: after `os.fork()` returns in the parent, the
parent must call `os.close(child_fd)` before entering the read loop.
Leaving the slave fd open in the parent prevents EOF detection and leaks
a file descriptor. See §3a R3 below.

**Rejected alternative within Option S:** using `subprocess.Popen` with
`shell=True` and f-string interpolation of `task`. Even with shlex
quoting, this is fragile with Unicode and ANSI escape sequences. The
`os.execvp` + argv-list pattern is the correct primitive.

**Rejected alternative within Option S:** using `pty.spawn()`. The
`pty.spawn()` call does not support output capture to a buffer — it
writes directly to the controlling TTY. The `os.openpty()` / `os.fork()`
/ `os.execvp()` pattern is required to capture output.

### 3a. Security-engineer sign-off (2026-06-11): binding implementation requirements

`security-engineer` reviewed §3 on 2026-06-11 and returned **APPROVED**,
subject to the following five requirements. These are binding: `software-
engineer` must satisfy all five before the implementation PR is opened.
They are ordered by the attack surface they close.

**R1 — Flag injection (CWE-88). Status: SATISFIED AS-BUILT; no `--`
separator required. Security-engineer concurred 2026-06-11.**

Argv-list invocation prevents the OS shell from parsing `task`. The
original R1 text additionally required passing `task` after a `--`
end-of-options separator to prevent `agy`'s own flag parser from
interpreting content in `task` as option flags (CWE-88: argument
injection).

Binary analysis of `agy` (stripped Go ELF, google3 gflag, 2026-06-11)
established that `--print` is a **string flag** — its value is consumed
as the immediately following argv element. The as-built argv shape is:

```
["agy", "--print", task, "--model", model]
```

Because gflag's parser expects a value at the position immediately after
`--print`, `task` is consumed as that flag's value and is never presented
to the positional-argument or remaining-flags parsing stage. A `task`
value that begins with `--` cannot be reinterpreted as a flag by gflag in
this position; CWE-88 flag-injection is structurally impossible without a
`--` separator under this parsing model. Additionally, google3 gflag does
not universally honor `--` as an end-of-options terminator, so the
previously specified argv shape would not reliably work anyway.

R1 is therefore satisfied by the as-built argv shape. No `--` separator
is used or required.

**Residual caveat (supply-chain drift — not a current risk).** This
safety property depends on `--print` remaining a *string* flag in future
`agy` releases. If a future `agy` version changes `--print` to a
*boolean* flag, `task` would fall through to positional or remaining-
argument parsing and CWE-88 would reopen. Therefore: any `agy` upgrade
in the scaffold MUST re-run binary analysis to confirm `--print`'s flag
type before the upgraded version ships. This check is the responsibility
of whoever performs the upgrade (typically `release-engineer` + `security-
engineer` co-sign). The check must be recorded in the upgrade PR.

**R2 — Model allowlist.** The `model` parameter must be validated against
an explicit allowlist of known-valid model strings before the subprocess is
spawned. A caller-supplied `model` value that does not appear in the
allowlist must be rejected with a JSON-RPC error response using error code
`-32602` (Invalid params). The allowlist is defined as a constant in the
shim source; it is updated when new model strings are confirmed working. The
default value (`"Gemini 3.5 Flash (High)"`) must be a member of the
allowlist.

**R3 — File-descriptor hygiene.** The parent process must close `child_fd`
(the slave end of the PTY pair) immediately after `os.fork()` returns in the
parent. Retaining the slave fd open in the parent prevents the child's exit
from delivering EOF to the parent's read loop, and leaks a file descriptor.
The child must close `parent_fd` (the master end) before calling `os.execvp`.
The pseudocode in §3 omitted the parent-side `os.close(child_fd)` call; the
implementation must include it.

**R4 — Child reap (ECHILD).** The parent must call `os.waitpid(pid, 0)` (or
equivalent) in all exit paths: normal completion, timeout, and byte-cap
truncation. Every exit path that calls `os.kill` or `os.killpg` must be
followed by a `waitpid`. The `waitpid` call must handle `ChildProcessError`
(errno `ECHILD`) gracefully — this can occur if the child has already exited
between the signal and the wait — and must not propagate that exception as an
MCP server crash.

**R5 — ANSI/OSC stripping and byte-cap ordering.** The byte cap (§4,
`MAX_OUTPUT_BYTES`) must be applied to the raw captured bytes before any
post-processing. After the cap is applied, ANSI escape sequences and OSC
(Operating System Command) sequences must be stripped from the output before
it is included in the MCP result. The correct order is: cap raw bytes first,
then strip. Stripping before capping opens a memory-safety issue (a
malicious or misbehaving `agy` could emit many escape sequences that expand
after stripping). Stripping before returning the result is required to
prevent terminal-control injection into the orchestrator's context and to
reduce noise in the returned text. A regex covering both standard ANSI CSI
sequences and OSC sequences (e.g., `\x1b[\x1b\x9b][^a-zA-Z]*[a-zA-Z]` and
`\x1b\][^\x07]*\x07`) is sufficient; the SE documents the chosen pattern and
its coverage in the implementation.

### 4. Timeout and bounded output

The parent process reads from `parent_fd` in a loop using `select.select`
with a wall-clock deadline computed from `time.monotonic()`. When the
deadline is reached, the parent sends `SIGKILL` to the child process
group (via `os.killpg(os.getpgid(pid), signal.SIGKILL)`) and returns a
structured MCP error:

```json
{
  "isError": true,
  "content": [{"type": "text", "text": "antigravity_delegate: timeout after <N>s"}]
}
```

Captured bytes are capped at a configurable `MAX_OUTPUT_BYTES` constant
(default: 512 KiB). If the cap is reached before the process exits, the
process is killed and the result is returned with a truncation note
appended. The cap prevents memory exhaustion from runaway Antigravity
sessions.

On nonzero exit code, the captured output is still returned (Antigravity
may write diagnostics to stdout before exiting), with `isError: true`
and the exit code included in the error message.

### 5. Model default and override

The default model string is `"Gemini 3.5 Flash (High)"` — the string
confirmed working in the 2026-06-11 binary analysis session. The `model`
parameter is optional; if omitted by the caller, the default is used.
The model string is passed as a single argv element; it is not
interpreted or modified by the shim.

If Antigravity adds or renames model strings in a future release, the
caller passes the updated string explicitly. No model-string mapping
table lives in the shim; that concern belongs in
`docs/model-routing-guidelines.md` and is `mcp-liaison`'s
responsibility at call construction time.

### 6. Auth assumption

The shim assumes the operator has already authenticated with
Antigravity via `agy login` (or equivalent). It does not manage, store,
refresh, or transmit credentials. If `agy` exits nonzero due to an
auth failure, the shim returns the error text from Antigravity's stdout
in the structured MCP error response and does nothing else.

This is an explicit design decision: the shim is a transparent subprocess
bridge, not a credential manager. It handles no secrets, PII, or
auth tokens. Hard Rule #7 (security sign-off for auth/secrets paths)
does not apply to the shim's own code, but `security-engineer` is
consulted on the subprocess spawn shape (§ 3 above) to confirm the
injection-prevention argument.

### 7. Placement and registration

**Server script:** `scripts/mcp/antigravity_delegate.py`

**Smoke test:** `scripts/mcp/test_antigravity_delegate.py`
(exercises the JSON-RPC layer with a mock subprocess; does not require
a live `agy` installation or Antigravity auth)

**Registration:** The operator registers the shim once per Claude Code
profile via:

```
claude mcp add antigravity-delegate python3 \
  /path/to/sw-dev-team-template/scripts/mcp/antigravity_delegate.py
```

or equivalently via a `.mcp.json` entry:

```json
{
  "mcpServers": {
    "antigravity-delegate": {
      "command": "python3",
      "args": ["/path/to/sw-dev-team-template/scripts/mcp/antigravity_delegate.py"]
    }
  }
}
```

The shim is not registered automatically by the scaffold setup (it
requires `agy` to be installed, which is not a universal prerequisite).
Documentation covers the registration step.

---

## Implementation change-set grouped by owner

### software-engineer

| Artifact | Action |
|---|---|
| `scripts/mcp/antigravity_delegate.py` | Create new — stdio MCP server per §§ 1–6 above. Python 3 stdlib only. Unix only (`pty`, `os.openpty`, `os.execvp`). |
| `scripts/mcp/test_antigravity_delegate.py` | Create new — smoke test. Mocks the subprocess layer; verifies JSON-RPC handshake, `tools/list` response, successful `tools/call` response, timeout path, nonzero-exit path, and byte-cap path. Does not require live `agy`. |

**Implementation gate (CLEARED):** `security-engineer` reviewed §3 on
2026-06-11 and returned APPROVED with five binding requirements recorded
in §3a. The implementation gate is cleared; `software-engineer` may begin
implementation, subject to satisfying R1–R5 before the PR is opened.

**MCP framing gate:** confirm whether Claude Code's MCP stdio protocol
uses newline-delimited JSON or Content-Length framing before
implementing the protocol layer. If Content-Length framing is required,
note it in the implementation; the design above handles both modes with
a ~15-line change to the read loop.

### tech-writer

| Artifact | Action |
|---|---|
| `docs/agents/manual/mcp-liaison-manual.md` (or equivalent per project) | Add a "Delegating to Antigravity" section: how `mcp-liaison` constructs a delegated brief for `antigravity_delegate`, what model strings are valid, and how to interpret structured error responses. |
| Scaffold onboarding / setup docs (path TBD by `tech-writer`) | Add a "Antigravity delegate shim — registration" section: prerequisites (`agy` installed and authenticated), `claude mcp add` command, verification step (call `tools/list` from Claude Code to confirm registration). |

---

## Relationship to existing ADRs and roles

**FW-ADR-0026 (Antigravity harness adapter):** The other direction.
FW-ADR-0026 addresses Antigravity-as-orchestrator loading the team.
This ADR addresses Claude-as-orchestrator delegating to Antigravity.
The two are complementary and non-conflicting; both may be active
simultaneously on a repo that has both `.agents/rules/team-contract.md`
and the `antigravity_delegate` MCP server registered.

**`mcp-liaison` role (Q-0022 / gh issue #290):** `mcp-liaison` owns
delegated external-model MCP sessions and brief construction. The
`antigravity_delegate` tool is `mcp-liaison`'s transport for the
Antigravity case. `mcp-liaison` is responsible for: constructing the
delegated brief (what task text to pass), selecting the model string
from `docs/model-routing-guidelines.md`, and reconciling any divergence
between the brief and Antigravity's response. The shim is a dumb
transport — it does not interpret, rewrite, or validate the `task`
content.

**Issue #289 (MCP non-primary-session mode):** The inverse concern:
a spawned-over-MCP session must not start the orchestrator team. This
ADR does not conflict with #289. The shim is a server that Claude Code
calls; it is not itself a Claude session and has no team-start behavior
to suppress.

**`security-engineer` co-ownership:** Per `architect.md`, structural
security decisions (trust boundaries, subprocess spawn surface with
attacker-influenced input) are made jointly with `security-engineer`.
The argv-list / PTY spawn design in § 3 is the primary joint-review
surface. `security-engineer` sign-off on that section is a gate for
implementation start.

---

## Consequences

### Positive

- Claude Code gains first-class, typed, inline delegation to
  Antigravity. `mcp-liaison` can construct a delegated brief and call
  `antigravity_delegate` as a tool — the same pattern used for any
  other MCP server — without leaving the Claude Code session.
- Shell injection from attacker-influenced `task` content is eliminated
  as a class by argv-list invocation. No quoting or escaping of `task`
  is required or performed; the OS handles argument passing directly.
- Zero new runtime dependencies. Python 3 stdlib is sufficient; no
  `pip install`, no npm, no system packages beyond `python3` (already
  required by other scaffold scripts).
- The shim is a standalone, auditable ~270-line file. The entire
  injection-prevention argument is visible in one function; no
  transitive dependencies to audit.
- Timeout and byte-cap prevent Claude Code from hanging on slow or
  runaway Antigravity sessions.
- The smoke test runs without live `agy`; CI can validate the
  JSON-RPC layer without an Antigravity installation.

### Negative / trade-offs accepted

- The `pty` module is Unix-only. Windows operators cannot use the
  shim. This is accepted: the scaffold's other PTY-dependent tooling
  and the `agy` CLI itself are Linux/macOS-only. A Windows path
  would require a separate design (e.g., ConPTY via ctypes or a WSL
  shim); that is deferred unless a Windows operator requirement appears.
- Hand-rolled JSON-RPC 2.0 is more implementation surface than using an
  SDK. Mitigated by: the protocol is a small subset (four methods:
  `initialize`, `initialized`, `tools/list`, `tools/call`); the smoke
  test validates the full handshake; and the protocol layer is
  self-contained and replaceable without changing the subprocess logic.
- The MCP stdio framing (newline-delimited vs. Content-Length) must be
  confirmed before implementation. This is a one-time verification step
  (~30 min); it does not block authoring the rest of the shim.
- Registration is a manual one-time operator step. The shim is not
  auto-registered by scaffold setup. Accepted: `agy` itself is not a
  universal prerequisite, so auto-registration would silently fail on
  machines without `agy`.
- The shim inherits the operator's `agy` auth state. If `agy` is not
  authenticated, the tool returns an error and the operator must run
  `agy login` out of band. This is intentional: the shim manages no
  credentials.

### Follow-up ADRs

- If the `mcp-liaison` brief-construction pattern for
  `antigravity_delegate` requires a formal protocol (e.g., structured
  task format, response parsing rules beyond raw text passthrough), a
  follow-up ADR should define that protocol. Currently `mcp-liaison`
  owns this informally via its role contract.
- If Windows support is required, a follow-up ADR addresses the ConPTY
  / WSL path.
- If multiple external-model delegates are added (e.g., a
  `codex_delegate` or `opencode_delegate`), a follow-up ADR should
  consider whether a generic `delegate` tool with a `harness` parameter
  is preferable to per-harness shims.

---

## Verification

- **Success signal:** After registration, `claude mcp list` shows
  `antigravity-delegate`. A `tools/list` call from Claude Code returns
  the `antigravity_delegate` schema. A `tools/call` with a simple task
  string (e.g., `"echo hello"`) and a live authenticated `agy`
  installation returns Antigravity's response text. The smoke test
  passes in CI without a live `agy`. `security-engineer` review of §3
  is recorded in §3a of this ADR (2026-06-11); no separate sign-off
  artifact required.
- **Failure signal:** `agy` with the PTY spawn pattern does not produce
  output (indicating the PTY allocation approach is wrong for a given
  platform or `agy` version), requiring a redesign of the spawn
  mechanism. Alternatively, the MCP framing confirmation reveals
  Content-Length is required and the handshake fails in newline-
  delimited mode — triggering a protocol layer amendment. Either
  condition requires a superseding or amending ADR.
- **Review cadence:** Re-examine at the first session after the
  implementation PR merges, or after the first live `mcp-liaison`
  Antigravity delegation in a downstream project, whichever comes first
  (session-anchored per CLAUDE.md § "Time-based cadences").

---

## Links

- FW-ADR-0026 — Antigravity harness adapter (complementary direction):
  `docs/adr/fw-adr-0026-antigravity-harness-adapter.md`
- FW-ADR-0009 — OpenCode harness adapter (thin-adapter pattern):
  `docs/adr/fw-adr-0009-opencode-harness-adapter.md`
- FW-ADR-0021 — harness-agnostic leaf-task dispatch (delegated-specialist
  mode): `docs/adr/fw-adr-0021-harness-agnostic-leaf-task-dispatch.md`
- FW-ADR-0022 — Gemini harness adapter (co-equal harness precedent):
  `docs/adr/fw-adr-0022-gemini-harness-adapter.md`
- gh issue #289 — MCP non-primary-session rule (inverse concern; does
  not conflict)
- gh issue #290 / Q-0022 — `mcp-liaison` role (owner of delegated
  external-model MCP sessions; the shim is its Antigravity transport)
- gh issue #338 — Team not found in Antigravity (FW-ADR-0026 concern)
- gh issue #339 — MCP calls spawn subagents instead of acting
  (FW-ADR-0026 concern)
- `docs/model-routing-guidelines.md` — binding per-agent routing table
  (source of model string choices for `mcp-liaison` at call time)
- `.claude/agents/mcp-liaison.md` — role contract for the agent that
  owns delegated brief construction
- `scripts/compile-runtime-agents.sh` — generation script (not modified
  by this ADR; listed for context on the four-surface pipeline)
