---
name: fw-adr-0031-opencode-hook-bridge
description: >
  Establishes the OpenCode enforcement-parity mechanism: a thin subprocess
  adapter that shells out to the existing, unchanged scripts/hooks/*.py
  guards from OpenCode plugin hook points, rather than a JS/TS
  reimplementation. Fixes the binding verdict-translation contract
  (deny-by-throw, ask-degrades-to-deny, warning-channel loss), the
  bridge's own fail-open/fail-closed posture, ownership of the
  tool/arg-key mapping as a checked-in derived artifact with its own
  release-gate parity check, and an honest per-hook portability inventory
  across the 14 Claude Code hook wirings.
status: accepted
date: 2026-07-24
---


# ADR fw-adr-0031: OpenCode enforcement hook bridge

**Status**: Accepted
**Date**: 2026-07-24
**Owner**: architect
**Reviewers**: code-reviewer, security-engineer, tech-lead
**Supersedes**: none
**Superseded by**: none

## Context

`.claude/settings.json` wires 14 hook invocations across `PreToolUse`,
`PostToolUse`, `TaskCreated`, `TaskCompleted`, `SubagentStop`, `Stop`,
and `SessionStart`. These hooks are the framework's mechanical
enforcement layer for CUSTOMER_NOTES.md stewardship
(`customer-notes-guard.py`), Hard Rule #8 authoring discipline
(`tech-lead-authoring-guard.py`, FW-ADR-0012), handoff path/framework
scope and lifecycle bookkeeping (the four `handoff-*-gate.py` +
`handoff-record-activity.py` scripts), subagent spawn-budget control
(`subcall-limit-guard.py` / `subcall-limit-reset.py`), and session-open
reminders for Hard Rules #8 and #11 plus template-version and
post-compaction refresh (`version-check.sh`,
`atomic-question-reminder.sh`, `role-routing-reminder.sh`,
`post-compact-refresh.sh`).

None of this is available under the OpenCode harness today. The
upstream scaffold ships `.opencode/agents/*.md` (15 thin role adapters,
classified as harness-adapter derived artifacts by FW-ADR-0009) but no
`opencode.json` and no plugin. OpenCode sessions get the Hard Rules as
*prose only*, via `opencode.json`'s eventual `instructions: [CLAUDE.md,
AGENTS.md]` wiring — there is no mechanical floor equivalent to the
Claude-Code PreToolUse deny-hooks. FW-ADR-0009 classified OpenCode as a
harness/provider adapter and settled the role roster, escalation chain,
and source-of-truth questions; it explicitly did not address
enforcement-mechanism parity, which is this ADR's scope.

The OpenCode plugin API (`@opencode-ai/plugin` v1.17.13, confirmed by
reading `dist/index.d.ts` directly) exposes a `Hooks` interface with no
built-in analog to Claude Code's PreToolUse `hookSpecificOutput.
permissionDecision` JSON protocol. The closest points are
`tool.execute.before` (input `{tool, sessionID, callID}`, output
`{args}` — the caller may mutate `args` or throw to abort the call) and
`tool.execute.after` (post-hoc, for logging/bookkeeping). **A runtime
spike against the live OpenCode 1.18.4 binary (2026-07-24; evidence
archived at spike time under `/tmp/ocspike/`) confirms this at the
subprocess-behavior level, not just the type-declaration level**:
throwing inside `tool.execute.before` aborts the call cleanly — the
tool never executes, `Error.message` surfaces verbatim as the tool
part's `state.error`, the model reads it and reacts — and
`tool.execute.after` is **not** invoked for a thrown call (which
mirrors Claude Code's own behavior, where a PreToolUse deny likewise
suppresses the paired PostToolUse firing — see the portability
inventory's `handoff-record-activity.py` row for the consequence). A
narrower `permission.ask` hook exists (input: `Permission`, output:
`{status: "ask"|"deny"|"allow"}`) and, per the SDK's own `Permission`
type (`sdk/dist/gen/types.gen.d.ts`), is keyed to OpenCode's *own*
permission taxonomy (`type`, `pattern`), firing only when OpenCode's
built-in permission system has already decided a category needs
confirmation. The same spike went further than type-reading alone can:
with `opencode.json` set to `permission.edit: "ask"`, the registered
`permission.ask` hook was **never invoked, not even once**, for an
edit call that should have triggered it, while `tool.execute.before`
fired normally for that same call. OpenCode's own permission layer
auto-rejected the call via internal `permission.asked`/
`permission.replied` events without ever consulting the plugin hook,
because the process has no TTY to prompt against. This upgrades the
finding from "not a universal interception point" to "does not fire at
all under the non-interactive operation this bridge always runs in" —
`permission.ask` is not merely out of scope for v1, it is confirmed
non-functional as a headless deny channel, which removes it as a
fallback should deny-by-throw's sufficiency ever be questioned. This
ADR treats `permission.ask` as out of scope for v1 (see Alternatives /
Decision) and revisits it only if OpenCode ships a way to invoke
plugin hooks under non-interactive operation, or if this bridge is
ever run with a TTY attached (not the case today).

**Build provenance note (revision 2, 2026-07-25):** the paragraph
above and every "2026-07-24 runtime spike" / "OpenCode 1.18.4"
citation elsewhere in this ADR reflect the **first** runtime spike,
run against OpenCode 1.18.4. The binary now on this project's PATH
reports **1.18.5**; a second runtime spike (2026-07-25) ran against
1.18.5 and its findings are folded into this revision, each labeled
with that build. Existing 1.18.4 citations are left unchanged — they
are an accurate record of what that build did, not a claim about the
binary running today — and this revision does not re-verify the first
spike's findings (deny-by-throw, the callable toolset, `permission.ask`
non-invocation, the full `event.type` catalog, plugin process
lifetime/discovery) against 1.18.5. Nothing in the second spike
contradicted them; they stand as 1.18.4-sourced evidence pending
contrary observation, consistent with this ADR's practice of citing
exactly what was run and on which build rather than extrapolating
across point releases.

`customer-notes-guard.py` and the other Python hooks read a JSON
payload from stdin (`{tool_name, tool_input: {...}}`) and write a JSON
verdict to stdout (`{"hookSpecificOutput": {"permissionDecision": ...,
"permissionDecisionReason": ...}}`). This stdin/stdout JSON contract is
harness-agnostic by construction — nothing about it depends on the
Claude Code process itself, only on the shape of the payload. That is
the load-bearing fact this ADR's decision rests on.

ADR triggers that fire: cross-cutting pattern change (a second
enforcement surface parallel to the Claude Code hook layer);
new-dependency addition (`opencode.json` + a plugin script are new
framework surface, not present today); and a choice (subprocess bridge
vs. reimplementation) that is expensive to reverse once specialist and
downstream-project expectations form around one shape.

## Decision

**The OpenCode enforcement bridge is a protocol-translation adapter
that shells out to the existing, unchanged `scripts/hooks/*.py`
scripts. It is not a port or reimplementation of guard logic in
JavaScript/TypeScript.** This extends the principle FW-ADR-0009 already
established for `.opencode/agents/*.md` (OpenCode-native files are
derived artifacts; canonical content lives in `.claude/agents/*.md`)
from the role-file surface to the hook surface: the Python scripts
under `scripts/hooks/` remain the single source of truth for every
guard's policy; the OpenCode plugin's job is exclusively to translate
OpenCode's tool-call shape into the JSON payload the Python hook
already expects, invoke it as a subprocess, and translate the JSON
verdict back into an OpenCode-native abort-or-proceed decision.
Constitution III's manual-mirror prohibition applies without
modification. See Alternatives considered for the full drift argument
against a JS port (Option C).

### Verdict-translation contract (binding)

The bridge constructs `{tool_name: <mapped>, tool_input: {<mapped
keys>}}`, pipes it to `python3 scripts/hooks/<hook>.py` on stdin,
parses the resulting JSON from stdout, and maps as follows:

| Claude-side verdict | OpenCode-side bridge behavior |
|---|---|
| No `hookSpecificOutput` / `permissionDecision` absent or `"allow"` with no reason | Return normally from `tool.execute.before` (tool call proceeds). |
| `permissionDecision: "allow"` **with** a `permissionDecisionReason` (Claude's "warn" mode — informational, non-blocking) | Return normally (tool call proceeds). **The reason text is dropped.** OpenCode's `tool.execute.before` output shape (`{args}`) has no side-channel for a non-blocking advisory message; the only two channels are "return" (silent) and "throw" (blocking, message surfaces to the model as the error content). Warn-mode is therefore **not preserved** under OpenCode — it silently degrades to allow. This is a named, accepted parity gap, not an oversight. |
| `permissionDecision: "deny"` | Throw an `Error` inside `tool.execute.before` with the `permissionDecisionReason` text as the error message. This is the binding mapping: OpenCode has no separate deny-channel distinct from aborting the call, so deny-by-throw is the entire mechanism. **Verified against the live 1.18.4 binary** (see Context) — the call aborts cleanly, `tool.execute.after` does not fire, and the thrown message surfaces to the model, which can read it and react (e.g., dispatch the named specialist) the same way a Claude Code session reads a deny reason today; this is no longer an inference from type declarations alone. |
| `permissionDecision: "ask"` (currently only `customer-notes-guard.py`, for CUSTOMER_NOTES.md edits by a non-steward role) | **Degrades to deny**, not to allow. OpenCode's plugin hooks have no interactive re-prompt channel equivalent to Claude Code's own UI-level "ask" pause — there is no mechanism inside `tool.execute.before` to suspend the call and wait for a human yes/no. Between the two available poles (proceed silently, or abort with an explanation), this ADR chooses fail-closed: an ask-turned-silent-allow would mean CUSTOMER_NOTES.md becomes editable by any role under OpenCode with zero gate, which is a strictly worse outcome than the mild friction of "ask" collapsing to "you must dispatch `librarian`, or set the escape hatch, and retry." The thrown message must say exactly that. |

The four `handoff-*-gate.py` hooks currently run with `SWDT_HANDOFF_GATES=warn`
(soft-launch, non-blocking) per `.claude/settings.json`. Under today's
configuration their Claude-side verdict is always in the
allow/warn band — the deny path is not yet engaged. Their OpenCode port
therefore inherits the "warning dropped, allow proceeds" row above with
no immediate loss of *effective* enforcement (there is none engaged yet
to lose). If/when the handoff gates are promoted out of warn mode, their
new deny outputs follow the deny-by-throw row like any other hook —
no separate handling is needed.

### Fail-open vs. fail-closed for bridge errors (binding)

Two distinct failure classes, two distinct postures:

1. **Hook-internal failure that the hook's own author already decided
   how to handle** — malformed JSON on stdin, an unexpected payload
   shape, or any condition the Python hook's own code path returns
   `0`/no-opinion for. `tech-lead-authoring-guard.py`'s own spec (FW-ADR-0012
   § Hook specification) states "Malformed JSON / unexpected payload
   shape → fail open ... mirroring `customer-notes-guard.py`'s issue
   #156 posture." **The bridge inherits this posture unchanged: whatever
   the hook itself decided, the bridge honors as-is (fail open when the
   hook fails open).** The bridge does not tighten a policy the hook's
   own maintainers already accepted as fail-open — doing so would be
   the bridge silently re-deciding policy, which is exactly the kind of
   drift the adapter-not-port decision above is meant to prevent. A
   guard's risk tolerance is the guard author's call, not the bridge's.
2. **Bridge-infrastructure absence** — `python3` is not on `PATH`, the
   target hook script is missing or not executable, the subprocess
   cannot be spawned, or the subprocess exits non-zero in a way that is
   not part of the hook's own documented JSON-output contract (a crash,
   not a decision). This is a failure mode the Python hooks never had
   to consider, because under Claude Code the interpreter running them
   is a given. **The bridge fails closed here**: throw, naming the
   broken hook and the underlying OS-level error, rather than silently
   running the tool call with zero enforcement for the remainder of the
   session. The alternative — silent fail-open on total infrastructure
   loss — means an operator could run an entire OpenCode session
   believing all 14 protections are active when none are, which is a
   materially worse and less discoverable failure than a loud,
   diagnosable block. This mirrors the residual-risk framing FW-ADR-0030
   already established for the Bash deny-list: coarse backstops are
   acceptable, *silent* total collapse of a backstop is not.

### Tool-name / arg-key mapping ownership (binding)

The Claude tool → OpenCode tool mapping and the per-tool arg-key
mapping are **derived artifacts**, checked into the repo as an explicit
table (not an inferred camelCase → snake_case transform — OpenCode's
own arg-key casing is not internally consistent: `filePath`,
`oldString`, `newString`, `replaceAll`, `content`, `command` are
camelCase, but `subagent_type` on the `task` tool is already
snake_case; a blanket regex transform would either mis-handle
`subagent_type` or require its own exception list, which is exactly
the kind of per-key special-casing that belongs in an explicit table,
not inferred code). **Correction (2026-07-24 runtime spike):** the full
callable OpenCode 1.18.4 toolset, enumerated live via the
`tool.definition` hook, is `bash, edit, glob, grep, invalid, question,
read, skill, task, todowrite, webfetch, websearch, write` — there is no
`patch` tool. (In the SDK types, `"patch"` is a message-*Part*
discriminator, `{hash, files}`, used for git-diff/snapshot tracking; it
is unrelated to file mutation and does not appear in the callable tool
list.) `write` and `edit` are the only file-mutation tools. This ADR's
original inventory claimed Claude's `MultiEdit` splits across `edit`
and a `patch` tool, and that the `MultiEdit`-matched hooks
(`customer-notes-guard.py`, `tech-lead-authoring-guard.py`,
`handoff-pre-tool-gate.py`) must be wired to both — that claim is
**wrong** and is struck. The corrected position: Claude's `MultiEdit`
has **no OpenCode counterpart at all**; there is simply no OpenCode
tool that produces a multi-hunk edit call, so nothing needs wiring for
it. A Claude-side `MultiEdit` of N hunks has no single-call OpenCode
analog — the nearest equivalent workflow is N sequential `edit` calls,
each independently gated by `tool.execute.before` on `edit`. This is a
call-granularity difference (the guard logic fires N times instead of
once per batch), not a coverage gap, and needs no additional wiring
beyond the existing `edit` entry.

Because this table is derived, it drifts silently if either harness
adds a tool or renames an arg key and the table isn't updated. Drift
detection is **not** the `canonical_sha` mechanism FW-ADR-0009 /
FR-021 use for role-adapter staleness (see next section for why) — it
is a dedicated release-gate sub-gate: a new script
(`scripts/verify-opencode-hook-parity.sh`) that (a) parses
`.claude/settings.json`'s `PreToolUse`/`Agent` matchers to enumerate
every Claude tool name any hook currently guards, (b) checks that the
mapping table has an entry for each, (c) fails the release gate if any
guarded Claude tool has no OpenCode counterpart in the table. This
catches "Claude side grew a new guarded tool and nobody updated the
map" as a release-blocking finding; it does not (and cannot, without an
OpenCode session to introspect) catch "OpenCode renamed a tool id
upstream" — that direction of drift is an upstream-dependency risk
named in Consequences, not something a static repo-local gate can
detect.

### `scripts/compile-runtime-agents.sh` scope (binding — explicitly excluded)

The hook bridge is **not** in scope for `scripts/compile-runtime-agents.sh`.
That script's `canonical_sha` mechanism solves a different problem: a
1:1 per-role content-provenance check (does `.opencode/agents/<role>.md`'s
body still match the `.claude/agents/<role>.md` it was compiled from).
The hook bridge is a single cross-cutting plugin wired once via
`opencode.json`'s `plugin` array, not a per-role generated file — there
is no per-role SHA to check, and forcing this into the
`compile-runtime-agents.sh` pipeline would conflate two structurally
different derived-artifact classes (role prose vs. tool-call protocol
translation) under one staleness mechanism that fits neither well. The
`verify-opencode-hook-parity.sh` sub-gate above is the bridge's own,
independently-scoped drift detector; it runs as part of the release
gate (`scripts/pre-release-gate.sh`) alongside, not inside,
`compile-runtime-agents.sh`.

### Plugin process lifetime and per-session work placement (binding)

**Confirmed by the 2026-07-24 runtime spike:** the plugin factory
function OpenCode calls to construct `Hooks` runs **once per process**,
not once per session and not once per message. A closure-scoped counter
incremented from inside the factory body was observed at exactly `1`
across an entire run containing four sequential tool calls
(`PLUGIN_FN_CALLED` fired once); a per-call counter incremented
correctly `1→4` across the same run, confirming the hooks themselves
fire per-call while the surrounding factory/closure does not re-run.
One `Hooks` instance therefore serves the **whole OpenCode process**,
and its `event` handler receives events from **every session in that
process**, including both a parent session and any `task`-spawned
child session — both were delivered to the same instance in the spike.
`PluginInput` (the factory's argument) has **no `sessionID` field** —
there is no way to scope work to "this session" from the factory body
itself.

**Binding consequence:** any SessionStart-equivalent work (the
`session.created`-mapped hooks and the `experimental.session.compacting`
hook, both in the inventory below) MUST live inside the `event` handler
(or the dedicated `experimental.session.compacting` hook), keyed on the
firing for that specific session, and MUST NOT be placed in the plugin
body / module scope. Code that prints a per-session banner from module
scope would fire it once per process — effectively once ever, for a
long-lived server, never again for the next hundred sessions that
process serves. This is an explicit implementation constraint for
`software-engineer`, not a stylistic preference.

### Session identity is mutable: `session.updated` follows, `session.created` retains (binding — 2026-07-25 spike, HIGH-severity finding, now fixed)

A second runtime spike (2026-07-25, against OpenCode 1.18.5) verified
a live privilege-escalation path in the plugin's per-session
agent-identity tracking, and the fix is now in commit `c4bc456` on
this branch. Findings:

- `session.created` never re-fires for an existing `sessionID` (this
  was already the first spike's basis for first-write-wins; retained
  here as finding **H-1(b)**, unchanged).
- `info.agent` for an existing `sessionID` **does** change — via a
  plain `session.updated` event, with no accompanying `session.created`
  — when the session is resumed with a different agent
  (`opencode run --session <id> --agent <other-role> ...`). Verified
  end to end on a child session originally spawned via `task` with a
  validated canonical role, then resumed under a different agent.
- Before the fix, the bridge cached only the spawn-time agent (from
  `session.created`) and never revisited it. Because
  `tech-lead-authoring-guard.py` grants an unconditional write bypass
  to *any* validated non-tech-lead role — the guard distinguishes
  tech-lead from not-tech-lead, not role-appropriate paths, so role
  identity functions as a binary privilege switch rather than a scoped
  grant — a session that had once been legitimately dispatched as a
  specialist kept asserting that specialist's write-bypass on every
  later guarded call, even after the session's real running agent
  (system prompt, tool set, permissions) had been repointed elsewhere
  by a plain resume. Any bash-capable session can enumerate sessions
  and resume one under a different agent, so the attack cost was
  trivial.

**Binding requirement:** the bridge MUST subscribe to `session.updated`
and follow the session's *current* `info.agent`, not the value
recorded at `session.created`. The two events carry deliberately
**opposite** policies over the same per-session state, and a future
reader must not "harmonise" them into one consistent rule — that would
reopen the hole this fix closes:

- `session.created`: **retain**, first-write-wins. A re-fire for an
  already-recorded `sessionID` is anomalous — there is no verified
  runtime trigger for it — so retaining the first-recorded role is the
  safe default (finding H-1(b)).
- `session.updated`: **follow**, not retain. This is the channel a
  genuine agent-identity change arrives on for an existing session;
  retaining a stale, already-privileged role here IS the escalation,
  not a defensive posture.

Escalation-vector check, recorded for a future reader who might worry
"follow" is itself a new hole: because `tech-lead-authoring-guard.py`'s
bypass is binary (any validated non-tech-lead role grants the full
bypass) and `_validate_role()` already rejects the literal string
`"tech-lead"`, a followed change can only move a session between "some
specialist" (already an equivalent bypass under the guard's current
model) and "tech-lead-or-unknown" (`None`, the safe/restrictive
outcome). There is no transition this handler produces that grants a
privilege tier the session could not already reach by being freshly
dispatched as that role. Every observed identity change is still
logged (`console.error`) regardless, because even a correctly-handled
change is security-relevant and should leave a trace.

**Also confirmed by the same spike:** top-level/primary sessions carry
**no** `info.agent` at `session.created` at all — it is not
present-with-an-invalid-value, it is simply absent, and arrives later
on that session's first `session.updated`. Because `opencode.json`
pins `default_agent: "tech-lead"`, that later value is the literal
string `"tech-lead"`, which `_validate_role()` rejects by name (its
explicit self-push guard). So top-level sessions correctly resolve to
`caller_role = None` — no specialist write-bypass — reached via the
guard's dedicated tech-lead rejection rather than by the earlier,
accidental omission of `info.agent`. Verified by the top-level-session
case in `tests/hooks/test-opencode-hook-bridge.sh` (case B13).

The requirement above describes behavior already implemented in
commit `c4bc456` on this branch; it is recorded here as binding text —
the durable source of the policy — even though the code shipped first.
No status change results; this ADR remains Accepted.

### Trust-boundary properties confirmed by the second spike (2026-07-25, OpenCode 1.18.5)

Two assumptions this ADR's guard-chain design depended on were tested
directly rather than left as inference from type declarations or from
the first spike's toolset enumeration:

**H-1(a) — `subagent_type` is validated, RESOLVED.** A `task` call
whose `subagent_type` names no agent OpenCode has defined is rejected
outright by OpenCode itself, surfacing
`Unknown agent type: <name> is not a valid agent type`, and **no child
session spawns at all** — there is no `session.created` for it, so
this bridge's guard chain and its `agent_type` forwarding are never
reached with an invalid role in the first place. Verified with a
bogus name and with a canonical-looking-but-locally-undefined name; a
positive control (a real, defined agent name) spawned correctly for
comparison. **Consequence for this ADR's trust model:** a caller
cannot mint an arbitrary guard-visible role string via `subagent_type`
— OpenCode's own dispatch layer is a verified trust boundary this
bridge can rely on for that specific input. This is distinct from, and
upstream of, the session-identity-mutability finding above, which is
about a *validly* dispatched role changing later, not about spoofing
an invalid one at spawn time.

**H-2 — the unguarded `skill` tool is not a gap, RESOLVED.** Two
independent findings close this:

  (a) Per-agent `permission:` frontmatter (e.g. `skill: deny`) is
  genuinely enforced by OpenCode itself, at the model's
  tool-list/dispatch layer, **before** `tool.execute.before` ever
  runs — an agent configured `skill: deny` never has `skill` on its
  available tool list at all, and an attempted call is rerouted to a
  synthetic `invalid` tool rather than reaching the plugin. A control
  case (an agent without the deny frontmatter) confirmed this is the
  frontmatter taking effect, not a subagent-wide default.

  (b) `skill` is read-only/informational, not an execution primitive:
  its arguments are `{name}`, and it returns the skill's markdown body
  plus a listing of bundled file paths — it does not execute anything.
  A skill with a bundled script that writes a marker file was invoked
  directly and the marker was never created. Actually running anything
  discovered via `skill` requires a separate `bash` call, which is
  already inside this bridge's guarded chain.

  **Consequence:** the bridge's silence on `skill` — it was never
  separately wired — is acceptable; there is no execution surface
  behind it that the guard chain needs to cover. The residual risk is
  named honestly rather than dismissed: skill-returned markdown
  content remains a prompt-injection vector against the model reading
  it (adversarial content inside a skill file could steer the model
  into requesting a dangerous follow-up tool call), which is a
  materially smaller and different concern than unguarded execution,
  and is not new to this ADR — it is the same class of risk any tool
  that returns untrusted text to the model carries.

### Security posture verdict (security-engineer assessment, Hard Rule #7, 2026-07-25)

The Hard Rule #7 security assessment for this bridge concluded — and
this ADR records that verdict rather than restating it as settled
architecture — that **the bridge is a discipline/compliance control,
not a hard security boundary.** The distinction matters for how a
downstream reader should rely on it:

- OpenCode plugins load additively and unordered from the operator's
  global configuration, not exclusively from this project's
  `opencode.json`. Nothing in the plugin API verifies or constrains
  the execution order of multiple co-loaded plugins' `tool.execute.
  before` hooks, and nothing prevents a co-loaded plugin from
  pre-empting or otherwise suppressing this bridge's throw.
- This is not hypothetical: a concrete instance of unrelated-plugin
  interference was already observed during this work — a third-party
  global plugin made `tech-lead` spawnable as a subagent (a state this
  framework treats as a defect, per the main-session-persona rule)
  until this branch's own `mode: primary` registration shadowed it.
- Consequently: this bridge is trustworthy as an honest-operator
  compliance mechanism — it reliably translates and enforces the
  Python guards' verdicts against a *cooperating* OpenCode installation
  with no other plugin actively working against it — but it is **not**
  a boundary this ADR can claim holds against an adversarial or
  misconfigured plugin environment. Any future claim that OpenCode-side
  enforcement matches Claude Code's hook layer in strength would
  overstate what this bridge provides; this ADR states the ceiling
  plainly rather than implying boundary-grade protection.

This verdict does not change any binding contract clause of this ADR
(adapter-not-port, deny-by-throw, ask-degrades-to-deny,
warn-degrades-to-silent-allow, the fail-open/fail-closed split, the
explicit mapping table, the parity sub-gate, the
`compile-runtime-agents.sh` exclusion). It reframes how much
protection the bridge as a whole should be understood to provide; see
the new Negative consequence below.

### Follow-up (named, not solved by this ADR): unguarded network egress on the ingestion path

The same security review surfaced a pre-existing, cross-harness gap
that is explicitly out of scope for this ADR and recorded here only as
a named follow-up: `researcher` holds `webfetch: allow` and
`websearch: allow` together with `edit: allow`, and its role is
specifically to ingest external documentation — the classic
prompt-injection intake path, where untrusted fetched content reaches
a role that can also write files. Neither Claude Code's 14-hook set
nor this bridge guards network egress at all; both are silent on
`webfetch`/`websearch` as a tool category. This is not a regression
introduced by this ADR — it predates the bridge and applies equally
under Claude Code — but this bridge's design work is what surfaced it
clearly enough to name. Tracked as follow-up scope for a future ADR
(role-permission scoping or an egress-aware guard); not addressed
here.

### Portability inventory (honest scope boundary)

| Claude hook | Event | OpenCode mapping | Confidence |
|---|---|---|---|
| `customer-notes-guard.py` | PreToolUse (Write/Edit/MultiEdit/Bash) | `tool.execute.before` on `write`/`edit`/`bash` | Portable. "ask" degrades to deny (see contract above). No `patch` tool exists (2026-07-24 spike); struck from this row. |
| `tech-lead-authoring-guard.py` | PreToolUse (Write/Edit/MultiEdit/Bash) | `tool.execute.before` on `write`/`edit`/`bash` | Portable. Escape-hatch env var (`SWDT_AGENT_PUSH`) and its inline-Bash-prefix form both require the bridge to forward the OpenCode session's environment and the raw `args.command` string unchanged into the payload the Python hook parses; no semantic change needed beyond that forwarding. No `patch` tool exists (2026-07-24 spike); struck from this row. |
| `handoff-pre-tool-gate.py` | PreToolUse (Write/Edit/MultiEdit/Bash) | `tool.execute.before` on `write`/`edit`/`bash` | Portable. Currently warn-mode; low risk either way. No `patch` tool exists (2026-07-24 spike); struck from this row. |
| `subcall-limit-guard.py` | PreToolUse (matcher `Agent`) | `tool.execute.before` on `task` | Portable. OpenCode's `task` tool is the structural analog of Claude's `Agent`/`Task` tool (subagent spawn). |
| `handoff-record-activity.py` | PostToolUse (unmatched — all tools) | `tool.execute.after` (unfiltered) | Portable. **Verified caveat (2026-07-24 spike):** when a call is denied via deny-by-throw, `tool.execute.after` does not fire for it, so this hook's bookkeeping is skipped for denied calls — confirmed parity with Claude Code, where a PreToolUse deny likewise suppresses the paired PostToolUse firing, not a new gap. |
| `handoff-task-created-gate.py` | TaskCreated | `tool.execute.before` on `task` | **Structurally narrowed.** OpenCode has no discrete "task created" lifecycle event distinct from the tool call itself; `tool.execute.before` on `task` is the closest available signal and fires at essentially the same point, but the semantic distinction Claude Code draws between "the tool call started" and "a task object was created" collapses to one event under OpenCode. |
| `handoff-task-completed-gate.py` | TaskCompleted | `tool.execute.after` on `task` | **Structurally narrowed**, same reasoning, mirrored on the after side. |
| `handoff-subagent-stop-gate.py` | SubagentStop | `event` on `session.idle` filtered to sessions **with** a `parentID` | **RESOLVED — genuine distinct mapping (2026-07-24 runtime spike).** The `task` tool spawns a genuinely new session with its own `session.created` (carrying `parentID` pointing at the caller, `agent` set, and title `"<description> (@<subagent_type> subagent)"`); that child session emits its own `session.idle` when it finishes, structurally distinct from the parent's later `session.idle`. This is no longer conflated with `TaskCompleted`'s `tool.execute.after` firing — it is a separately observable event on the child session. **Idempotency caveat:** the child `session.idle` was observed firing twice in one spike run; the bridge must be idempotent on this event (e.g. dedupe on `sessionID` plus a processed-marker) rather than assume exactly-once delivery. |
| `handoff-stop-gate.py` | Stop (end of the main session's turn) | `event` on `session.idle` filtered to sessions with **no** `parentID` | **RESOLVED — portable (2026-07-24 runtime spike).** `session.idle` is confirmed as the Stop-equivalent for the outer/parent session; filtering to sessions with no `parentID` distinguishes it from the child-session `session.idle` that now maps to `SubagentStop` (row above). No longer deferred. |
| `version-check.sh`, `atomic-question-reminder.sh`, `role-routing-reminder.sh`, `subcall-limit-reset.py` | SessionStart (unmatched) | `event` on `session.created` | **RESOLVED — portable (2026-07-24 runtime spike).** The full observed `event.type` catalog confirms `session.created` fires per new session (both the outer session and each `task`-spawned child session get their own `session.created`; one process-lifetime `Hooks` instance receives all of them — see the binding "Plugin process lifetime" note above). **Visibility caveat** for the three of these four that are reminder banners (`version-check.sh`, `atomic-question-reminder.sh`, `role-routing-reminder.sh` — not `subcall-limit-reset.py`'s silent counter reset): the plugin's `console.log`/`console.error` output reaches the invoking process's stdout/stderr, not the chat/TUI the user reads. "Wired and firing" is confirmed; "the operator actually reads it" is a separate, still-open concern — see Consequences. |
| `post-compact-refresh.sh` | SessionStart (matcher `compact`) | `experimental.session.compacting` | **Near-exact structural match.** This is the one hook in the inventory with a purpose-built OpenCode hook point (`experimental.session.compacting` fires before compaction starts, matching the semantic intent of "refresh directive after compaction"). **Same visibility caveat as the SessionStart reminder row above** — the refresh directive must reach the user via a conversation-touching channel, not `console.log`, or it goes unread. |

Summary (revised 2026-07-24 after a runtime spike against live
OpenCode 1.18.4): 5 of 14 map cleanly with no caveats beyond the
general verdict-translation contract; 2 map with a named structural
narrowing around the `task` tool (`TaskCreated`, `TaskCompleted` — no
longer 3, since `SubagentStop` is resolved below; OpenCode does expose
distinct subagent lifecycle after all, just via session events rather
than tool events); 2 (`handoff-stop-gate.py`, `handoff-subagent-
stop-gate.py`) are **newly resolved this revision** via `event` on
`session.idle`, filtered on `parentID` absence/presence respectively;
4 (the non-`compact` SessionStart hooks) are **newly resolved this
revision** via `event` on `session.created`; 1 (`post-compact-
refresh.sh`) remains a near-exact purpose-built match. That accounts
for all 14 — **none is unmapped as of this revision**, a change from
the original "1 (`Stop`) has no confirmed mapping" verdict. What
remains genuinely open is narrower than before: (a) whether
`console.log` output from three of the resolved SessionStart hooks
plus `post-compact-refresh.sh` is actually seen by the operator (it is
not, without an additional conversation-touching channel — see
Consequences), and (b) idempotency handling for the child-session
`session.idle` firing observed twice in one spike run. This ADR still
does not claim full behavioral parity — the verdict-translation
narrowings (warn-drop, ask-hardens-to-deny) stand unchanged — but the
structural event-mapping question this inventory exists to answer is
now closed for all 14 hooks.

**Revision-2 addendum (2026-07-25, OpenCode 1.18.5):** the second spike
did not revisit this event-mapping question — nothing above is
contingent on the 1.18.4-vs-1.18.5 point release, and this inventory's
14-of-14 mapping stands unchanged. The second spike instead closed a
HIGH-severity trust-boundary gap in the plugin's per-session
agent-identity tracking (see the binding session-identity subsection
above, fixed in commit `c4bc456`) and confirmed two threat-model
assumptions this ADR previously left as inference (H-1(a),
`subagent_type` validation; H-2, `skill`'s enforced deny + read-only
scope — both above). The accompanying security-engineer assessment
concluded the bridge overall is a discipline/compliance control, not a
hard security boundary (see Security posture verdict above); that
conclusion changes no binding contract clause of this ADR but does add
one new binding requirement (`session.updated`-follows) and reframes
the strength claim a reader should attach to the bridge as a whole.

## Consequences

### Positive

- Zero risk of policy drift between the two harnesses on any guard the
  bridge wires: `scripts/hooks/*.py` remains the single source of truth,
  exactly as `.claude/agents/*.md` remains the single source of truth
  for role prose under FW-ADR-0009. A future patch to
  `tech-lead-authoring-guard.py` (its six-times-patched
  redirect-scanning history — issues #175, #176, #179, #180, #184,
  plus the original implementation — is the concrete precedent
  motivating this) takes effect under OpenCode automatically, with no
  second file to remember to patch.
- The verdict-translation contract is fully specified before
  implementation starts: deny-by-throw, ask-degrades-to-deny,
  warn-degrades-to-silent-allow. No ambiguity for `software-engineer` to
  resolve unilaterally at implementation time.
- The fail-open/fail-closed split (inherit the hook's own posture;
  fail closed only on total infrastructure absence) avoids both of the
  two bad extremes: neither silently weakening enforcement below what
  each hook's author already accepted, nor silently losing all
  enforcement when the interpreter or scripts are unreachable.
- The mapping table and its parity sub-gate give the tool/arg-key
  correspondence the same "checked-in, mechanically verified" treatment
  FW-ADR-0009 gave role adapters, without forcing an ill-fitting reuse
  of `compile-runtime-agents.sh`'s per-role SHA mechanism.
- The portability inventory is honest about gaps rather than claiming
  full parity, which keeps the customer and `tech-lead` from operating
  OpenCode sessions under a false sense of equivalent protection.
- **New this revision (2026-07-25 spike):** two threat-model
  assumptions this ADR's guard-chain design depended on are now
  verified rather than inferred: OpenCode itself rejects an undefined
  `subagent_type` before any child session spawns (H-1(a)), and
  per-agent `permission: skill: deny` frontmatter is enforced by
  OpenCode's own dispatch layer before `tool.execute.before` runs,
  with `skill` itself confirmed read-only and non-executing (H-2).
  Neither required new bridge-side wiring; both are now confirmed
  trust-boundary properties this bridge can rely on rather than
  assumed ones.

### Negative

- Warn-mode (Claude's "allow with informational reason") and
  ask-mode are both narrowed under OpenCode — one loses its message
  entirely, the other loses its interactivity and hardens into deny.
  Operators running the same workflow under both harnesses will observe
  different behavior on the same guard for the same input in these two
  cases. This is a real, accepted UX asymmetry, not a bug to be fixed
  later without a protocol OpenCode does not currently offer.
- **Resolved this revision, new residual risk:** `handoff-subagent-
  stop-gate.py`'s `session.idle`-based mapping fired **twice** for the
  same child session in one spike run; the bridge implementation must
  be idempotent on this event (dedupe by `sessionID`), or a
  subagent-stop side effect that assumes exactly-once delivery (e.g.
  an activity-log append) will double-fire. This risk did not exist in
  the prior "deferred" framing only because nothing was wired yet to
  observe it.
- **New residual risk surfaced by this revision's spike:** the four
  SessionStart reminder hooks (`version-check.sh`,
  `atomic-question-reminder.sh`, `role-routing-reminder.sh`,
  `post-compact-refresh.sh`) are now confirmed to *fire* correctly, but
  firing does not mean the user sees them — `console.log`/`console.error`
  output from a plugin reaches the invoking process's stdout/stderr,
  not the chat/TUI. Actually surfacing a reminder to the user requires
  a conversation-touching hook (e.g. `experimental.chat.system.transform`)
  or the `client`. The event-mapping problem is solved; the
  delivery-channel problem for these four hooks is a separate, smaller
  open item tracked as follow-up scope for `software-engineer` or a
  future ADR revision if `console.log` proves insufficient in practice.
- The bridge adds subprocess-spawn overhead (Python interpreter
  startup, ~10-50ms) to every guarded OpenCode tool call, mirroring the
  cost FW-ADR-0012 already accepted for Claude Code and judged
  noise-level there.
- **Correction (2026-07-24 spike):** the previous bullet here claimed a
  `MultiEdit`-to-`{edit, patch}` cardinality mismatch requiring double
  wiring on the OpenCode side. There is no `patch` tool in OpenCode
  1.18.4; the correct fact is the opposite shape of problem: Claude's
  `MultiEdit` has no OpenCode counterpart at all, so a Claude-side
  batched multi-hunk edit becomes N independent OpenCode `edit` calls,
  each independently gated. The guard hooks therefore fire N times
  instead of once for what was a single Claude-side call — a
  call-granularity difference, not a coverage gap — and nothing needs
  double-wiring. This is strictly simpler than what the original
  inventory claimed, not a new risk.
- New framework surface: `opencode.json` (does not exist today) and a
  new plugin script are added to the scaffold. Downstream projects that
  have not yet adopted OpenCode inherit this surface on template
  upgrade with no functional effect (the plugin is inert without an
  active OpenCode session) but a larger file footprint.
- **New, now-fixed, HIGH-severity finding (2026-07-25 spike):** the
  bridge's per-session agent-identity cache was vulnerable to a live
  privilege-escalation path — a session resumed under a different
  agent via `session.updated` kept asserting its original, possibly
  more-privileged role to `tech-lead-authoring-guard.py`'s binary
  write-bypass. Fixed in commit `c4bc456` by the binding
  `session.updated`-follows requirement recorded above. Recorded here
  as a negative consequence of the class of state this bridge must
  maintain — a per-session identity cache is inherently a place a
  resume-based attack can target — not as an open risk; the specific
  instance found is closed.
- **Security posture ceiling (security-engineer assessment,
  2026-07-25):** this bridge is a discipline/compliance control, not a
  hard security boundary. OpenCode's additive, unordered global-plugin
  loading means there is no guarantee another co-loaded plugin cannot
  pre-empt or suppress this bridge's `tool.execute.before` throw; a
  concrete instance of unrelated-plugin interference (a global plugin
  making `tech-lead` subagent-spawnable) was already observed on this
  branch before its own `mode: primary` registration shadowed it. Any
  downstream expectation that OpenCode-side enforcement matches Claude
  Code's hook-layer guarantee in strength is not supported by this
  ADR.

### Neutral

- `permission.ask` is not used in v1. The 2026-07-24 runtime spike
  confirmed it is not merely narrower in scope than
  `tool.execute.before` but **does not fire at all** under the
  non-interactive operation this bridge always runs in (no TTY to
  prompt against; OpenCode's own permission layer auto-resolves
  without ever consulting the plugin hook). This removes it as a
  fallback deny channel — deny-by-throw is the only confirmed
  mechanism, full stop. `permission.ask` remains a candidate for a
  future ADR only if OpenCode ships a way to invoke plugin hooks under
  non-interactive operation, or a TTY-attached mode of this bridge is
  ever built; neither is true today.
- The bridge's escape-hatch behavior (forwarding `SWDT_AGENT_PUSH` /
  `SWDT_HANDOFF_GATES` unchanged) means the OpenCode session inherits
  exactly the same override vocabulary Claude Code sessions use — no
  new escape-hatch surface is introduced by this ADR.
- **Named follow-up, out of scope for this ADR:** the security review
  separately surfaced that `researcher`'s combined
  `webfetch`/`websearch`/`edit` permissions form an unguarded
  prompt-injection intake path, and that neither Claude Code's hooks
  nor this bridge guard network egress at all. Pre-existing,
  cross-harness, not a regression from this ADR; tracked as follow-up
  scope for a future ADR, not solved here.

## Alternatives considered

Three-Path Rule (binding per `architect.md` / `docs/templates/adr-template.md`).

### Option M — Minimalist: subprocess adapter, narrow scope

Wire only the unambiguously portable subset: the four PreToolUse
guards (`customer-notes-guard.py`, `tech-lead-authoring-guard.py`,
`handoff-pre-tool-gate.py`, `subcall-limit-guard.py`) and
`handoff-record-activity.py` (PostToolUse). Leave every SessionStart
hook, the three handoff lifecycle hooks (TaskCreated/TaskCompleted/
SubagentStop), and Stop entirely unported for v1, documented as
backlog rather than attempted.

- **Pros:** Smallest implementation surface; ships fastest; every
  wired hook has high mapping confidence, so there is no runtime-
  unverified behavior shipped as if it were settled.
- **Cons:** Leaves 9 of 14 hooks unaddressed, including reminders
  (Hard Rule #8, #11) that carry real governance weight and a
  near-exact match (`experimental.session.compacting`) that costs
  little to wire and is left on the table for no principled reason.
  Under-delivers relative to what the plugin API actually supports.
- **When M wins:** if implementation bandwidth were severely
  constrained and even the SessionStart/handoff-lifecycle mappings
  were judged too risky to ship provisionally. Not the case here — the
  inventory above shows every remaining hook has a clearly-labeled,
  and (per the 2026-07-24 spike) now largely runtime-verified, mapping.

### Option S — Scalable: subprocess adapter, full analyzed-portable scope + parity gate

Wire every hook this ADR's inventory judges portable, resolved, or
structurally-narrowed-but-portable — with this revision's spike
evidence, that is now all 14, including the `experimental.session.
compacting` near-exact match and the `session.created`/`session.idle`
event-filtered candidates (now runtime-verified, not merely flagged
for future verification) — plus the `verify-opencode-hook-parity.sh`
release-gate sub-gate so the tool/arg-key mapping does not silently
rot.

- **Pros:** Delivers everything that structurally maps today; is
  honest about the residual gaps (banner visibility, `session.idle`
  idempotency) rather than pretending they don't exist; ships the
  drift-detection mechanism alongside the mapping so the investment
  doesn't quietly decay.
- **Cons:** Larger implementation surface than M. At initial authoring
  time, four SessionStart hooks and the `Stop`/`SubagentStop` mappings
  carried runtime-unverified assumptions requiring a smoke test before
  the "portable" claim was trustworthy; the 2026-07-24 spike (this
  revision) closed that gap for event-firing, but surfaced a smaller
  residual one — three of the SessionStart reminder hooks plus
  `post-compact-refresh.sh` fire correctly but their `console.log`
  output is not chat-visible without an additional conversation-
  touching channel, and the new `session.idle` `SubagentStop` mapping
  requires idempotency handling (observed firing twice in one run).
- **When S wins:** here. Nothing about the additional scope over M
  requires guessing at policy — every additional hook wired under S
  reuses the same unchanged Python script and the same
  verdict-translation contract M already needs. The marginal
  implementation cost is mapping-table entries and event-hook
  wiring, not new policy logic, so the larger scope does not carry
  the risk profile a policy port would.

### Option C — Creative / experimental: native TypeScript reimplementation of guard logic

Reimplement the guard logic directly inside the OpenCode plugin in
TypeScript — no subprocess, no stdin/stdout JSON round-trip, natively
typed `args` access, zero cross-language arg-shape translation. To
avoid an outright duplicate-maintenance burden, this option could be
pushed further: extract each guard's decision logic into a
harness-neutral declarative rule format (e.g., YAML/JSON pattern
tables) with two thin compilers/interpreters, one Python and one
TypeScript, both reading the same declarative source.

- **Pros:** No subprocess-spawn overhead; no cross-language JSON
  contract to keep stable; natively typed tool-call access removes an
  entire class of arg-key-mapping bugs this ADR's Option S still has to
  guard against with the parity sub-gate.
- **Cons:** The bare reimplementation form is a direct violation of
  the drift principle this ADR opens with: `tech-lead-authoring-guard.py`
  alone is roughly 1160 lines with a six-times-patched redirect-scanning
  history (issues #175, #176, #179, #180, #184, plus the original
  implementation — verified against that file's own source comments;
  an earlier independent read of this citation substituted #182, which
  does not appear in `tech-lead-authoring-guard.py` at all and belongs
  instead to `customer-notes-guard.py`'s separate read-vs-write
  false-positive history, now corrected) — a hand-maintained TS mirror
  guarantees the
  first unmirrored patch produces divergent enforcement between
  harnesses, silently, with no mechanism to detect it. The
  declarative-rule-format elaboration avoids literal duplication but
  trades it for a different, larger cost: inventing and maintaining a
  new DSL, two compilers/interpreters for it, and a test suite for the
  DSL itself — a permanent piece of net-new infrastructure whose
  upkeep is disproportionate to the problem being solved (bridging an
  enforcement gap for a secondary harness). It also does not eliminate
  drift risk, it relocates it: the DSL's own expressiveness gaps become
  the new place policy silently diverges (a guard's Python-only escape
  hatch, e.g. the inline-Bash-prefix regex parsing, would either need
  to be expressible in the DSL — non-trivial — or would have to live
  outside it as harness-specific code, reintroducing exactly the kind
  of un-mirrored logic this option was meant to avoid).
- **When C wins:** if per-call latency from subprocess spawn became a
  measured, material problem (it hasn't — FW-ADR-0012 already accepted
  equivalent overhead as noise-level for Claude Code), or if a future
  cross-harness policy-authoring investment were independently
  justified by a third or fourth harness needing the same guards in a
  language neither Python nor the harness's native language covers. C
  is the option that names the constraint that rejects it here: the
  drift-prevention principle FW-ADR-0009 already ratified for role
  files generalizes directly to hooks, and no new information about
  OpenCode specifically changes that calculus. Naming C explicitly is
  what forces this conclusion rather than assuming it.

**Decision outcome: Option S.** M under-delivers with no principled
reason to leave the near-exact `experimental.session.compacting` match
and the SessionStart candidates (now runtime-verified per the
2026-07-24 spike) unwired. C is rejected on the
same drift-prevention principle FW-ADR-0009 already established for
`.opencode/agents/*.md`; nothing about hooks specifically weakens that
argument, and the declarative-DSL elaboration of C trades one drift
surface for a larger, novel one. S is the scope that delivers
everything the plugin API structurally supports today while keeping
the exact same "shell out to the unchanged Python hook" mechanism
Option M would have used for its narrower set — the mechanism decision
(adapter, not port) and the scope decision (how much of the 14-hook
inventory to wire) are independent axes, and this ADR settles both:
adapter (over C), full analyzed-portable scope (S over M).

## Enforcement

- New file: `.opencode/plugin/hook-bridge.js` (or `.ts`, per
  `software-engineer`'s implementation choice) — the plugin entry
  point, registered via a new `opencode.json`'s `plugin` array. Owns
  the `tool.execute.before` / `tool.execute.after` /
  `experimental.session.compacting` / `event` wiring described above.
  Does not contain guard policy logic; only payload construction,
  subprocess invocation, and verdict translation per the binding
  contract in this ADR. **Confirmed by the 2026-07-24 spike:** both
  `.opencode/plugin/` (singular) and `.opencode/plugins/` (plural) are
  auto-discovered, at project and global scope; both `.js` and `.ts`
  load; no `package.json` or `node_modules` is required for a plugin
  that imports only `node:*` builtins (the mapping table's subprocess
  invocation qualifies). `plugin/` (singular) is the chosen path per
  docs convention, as already named above. Separately, OpenCode itself
  auto-generates its own `.opencode/package.json` + `node_modules` on
  first run for its own type resolution — this is OpenCode's tooling,
  not a dependency of this plugin, and must be `.gitignore`d rather
  than checked in.
- New file: `scripts/opencode/tool-arg-map.json` (or equivalent) — the
  checked-in, explicit tool-id and per-tool arg-key mapping table
  described under "Tool-name / arg-key mapping ownership." Read by both
  the plugin (`hook-bridge.js`) and the parity sub-gate, so the two
  never see a different mapping.
- New file: `scripts/verify-opencode-hook-parity.sh` — release-gate
  sub-gate (wired into `scripts/pre-release-gate.sh`) asserting every
  Claude-guarded tool name in `.claude/settings.json`'s
  `PreToolUse`/`Agent` matchers has a corresponding OpenCode tool-id
  entry in the mapping table. This ADR's binding requirement; the
  script itself is `software-engineer`'s implementation handoff.
  Explicitly **not** part of `scripts/compile-runtime-agents.sh` — see
  Decision § "compile-runtime-agents.sh scope."
- `scripts/hooks/*.py` remain unchanged by this ADR. No guard script
  gains OpenCode-specific branches; the bridge is entirely responsible
  for making OpenCode look like Claude Code from the hook script's
  point of view (matching stdin JSON shape).
- This ADR is binding; a future OpenCode-related ADR (e.g., one that
  resolves the SessionStart-reminder banner-visibility gap, or promotes
  `permission.ask` into scope should OpenCode ever support non-
  interactive plugin-hook confirmation) amends or supersedes it
  explicitly rather than silently diverging.

## References

- `docs/adr/fw-adr-0009-opencode-harness-adapter.md` — the classification
  this ADR extends from role files to hooks; source of the "OpenCode-native
  files are derived artifacts" and "manual mirrors are prohibited"
  (Constitution III) principles this ADR applies.
- `docs/adr/fw-adr-0012-tech-lead-authoring-guard.md` — precedent for
  Claude-side PreToolUse hook shape, the stdin/stdout JSON contract this
  ADR's bridge reuses unchanged, and the accepted per-call subprocess-
  overhead cost baseline.
- `docs/adr/fw-adr-0030-subagent-bash-permission-posture.md` — precedent
  for "coarse backstop acceptable, silent total collapse is not," reused
  in this ADR's fail-open/fail-closed split.
- `.claude/settings.json` — the 14-hook Claude-side wiring this ADR's
  inventory is built against.
- `scripts/hooks/customer-notes-guard.py`,
  `scripts/hooks/tech-lead-authoring-guard.py` — read directly to
  confirm the stdin JSON payload shape (`{tool_name, tool_input}`) and
  the stdout verdict shape this ADR's contract depends on.
- `@opencode-ai/plugin` v1.17.13, `dist/index.d.ts` — `Hooks` interface,
  `PluginInput` shape, and the absence of a warning/ask side-channel on
  `tool.execute.before`.
- `@opencode-ai/sdk`, `dist/gen/types.gen.d.ts` — `Permission`,
  `EventSessionIdle`, `EventSessionCreated`, `EventSessionCompacted`
  type shapes originally used to ground the portability inventory's
  confidence levels before the runtime spike below superseded
  type-level inference with observed behavior for the rows it covers.
- **2026-07-24 runtime spike against the live OpenCode 1.18.4 binary**
  (`opencode run` sessions; evidence archived at spike time under
  `/tmp/ocspike/`) — the primary evidentiary basis for this revision.
  Verified: deny-by-throw end-to-end behavior (call abort,
  `tool.execute.after` skipped, error surfaces to the model); the full
  callable `tool.definition` toolset (`bash, edit, glob, grep, invalid,
  question, read, skill, task, todowrite, webfetch, websearch, write` —
  no `patch`); `permission.ask` non-invocation under a real ask-mode
  `opencode.json` configuration; the full `event.type` catalog
  (`session.created`, `session.updated`, `session.status`,
  `session.idle`, `session.diff`, `session.error`, `message.updated`,
  `message.part.updated`, `message.part.delta`, `permission.asked`,
  `permission.replied`, `file.edited`, `file.watcher.updated`,
  `plugin.added`, `catalog.updated`, `integration.updated`,
  `reference.updated`); child-session `parentID`/`session.idle`
  semantics for `task`-spawned subagent sessions (including the
  double-fire idempotency caveat); the plugin factory's once-per-process
  lifetime; and plugin directory/file-extension/`node_modules`
  discovery behavior. `/tmp/ocspike/` is a scratch location and is not
  expected to persist past the spike session; the findings summarized
  above and reflected throughout this ADR are the durable record.
- `scripts/hooks/tech-lead-authoring-guard.py` — re-read directly
  (2026-07-24) to correct the Option C redirect-scan issue citation;
  confirms issues #175, #176, #179, #180, #184 in its own source
  comments. `#182` does not appear in this file; it belongs to
  `scripts/hooks/customer-notes-guard.py`'s separate read-vs-write
  false-positive history (see that file's own comments and
  `CHANGELOG.md`).
- `scripts/reserve-number.sh` — confirmed `fw-adr-0031` as next-free
  before authoring (max existing ADR at authoring time: `fw-adr-0030`).
- **2026-07-25 second runtime spike against the live OpenCode 1.18.5
  binary** — the evidentiary basis for this revision's binding
  session-identity subsection and its H-1(a)/H-2 trust-boundary
  findings. Verified: `session.updated` changing an existing
  `sessionID`'s `info.agent` on a plain agent-resume with no
  accompanying `session.created`; `session.created`'s continued
  first-write-wins behavior (H-1(b), unchanged from the first spike);
  top-level/primary sessions carrying no `info.agent` at
  `session.created`, arriving only on a later `session.updated`
  carrying `opencode.json`'s pinned `default_agent: "tech-lead"`; a
  `task` call with an undefined `subagent_type` being rejected by
  OpenCode itself with no child session spawned (H-1(a), tested against
  a bogus name, a canonical-looking-but-locally-undefined name, and a
  real-agent positive control); per-agent `permission: skill: deny`
  frontmatter removing `skill` from that agent's tool list before
  `tool.execute.before` runs, with a non-deny control case for
  comparison; and `skill`'s read-only scope (returns markdown +
  bundled-file listing; a bundled marker-writing script was not
  executed when the skill was invoked) (H-2). Scratch evidence for this
  spike was not archived to a stable path; the findings summarized
  above and reflected throughout this revision are the durable record.
- `.opencode/plugin/hook-bridge.js` — read directly to confirm the
  shipped fix for the session-identity finding: the `sessionAgent` map,
  its first-write-wins `session.created` handler (H-1(b)), and its new
  follow-not-retain `session.updated` handler, all in commit `c4bc456`
  on this branch.
- `tests/hooks/test-opencode-hook-bridge.sh` — case B13
  ("top-level-session safety") exercises the
  `session.created`-then-`session.updated` sequence for a primary
  session and confirms no specialist write-bypass is granted.
- Security-engineer's Hard Rule #7 assessment of this bridge
  (2026-07-25) — the source of the "discipline/compliance control, not
  a hard security boundary" verdict and the `researcher`
  webfetch/websearch/edit follow-up, both recorded above. No separate
  persisted assessment artifact was found in-repo at the time this ADR
  revision was authored (see this response's escalations); this ADR
  cites the verdict as conveyed for this revision rather than citing a
  file path.

## Change log

- 2026-07-24 — Initial acceptance.
- 2026-07-24 — Revision following a runtime spike against the live
  OpenCode 1.18.4 binary. Summary of changes: (1) strengthened the
  deny-by-throw mapping from type-level inference to verified runtime
  behavior, including the newly observed fact that `tool.execute.after`
  does not fire for a thrown call; (2) struck the non-existent `patch`
  tool from the callable toolset, the tool-name/arg-key mapping
  ownership section, and three portability-inventory rows, and
  corrected the `MultiEdit` claim — there is no OpenCode counterpart
  for `MultiEdit` at all, so nothing needs double-wiring (the opposite
  of the original claim); (3) upgraded `permission.ask`'s exclusion
  rationale from "narrower in scope" to "confirmed non-functional under
  non-interactive operation," removing it as a fallback deny channel;
  (4) resolved `handoff-stop-gate.py` (`Stop`) and
  `handoff-subagent-stop-gate.py` (`SubagentStop`) via `event` on
  `session.idle`, filtered on `parentID` absence/presence respectively,
  correcting the prior "3 lifecycle points collapse onto 2 firings"
  narrowing claim and closing the one previously-deferred gap in the
  inventory; resolved the four non-`compact` SessionStart hooks via
  `event` on `session.created`; (5) added a new binding subsection on
  plugin process lifetime (the factory runs once per process; per-
  session work must live in the `event` handler, not module scope);
  (6) added a banner-visibility caveat for the four SessionStart
  reminder hooks (`console.log` output is not chat-visible without a
  conversation-touching channel); (7) noted plugin directory/extension
  auto-discovery behavior and the need to `.gitignore` OpenCode's own
  auto-generated `.opencode/package.json` + `node_modules`; (8)
  corrected the Option C redirect-scan issue citation from `#175, #176,
  #179, #180` to `#175, #176, #179, #180, #184`, verified against
  `tech-lead-authoring-guard.py`'s own source comments (`#182`, from an
  independent read, belongs to `customer-notes-guard.py`'s separate
  history and does not appear in this file). Status remains Accepted.
  No binding contract clause (adapter-not-port; deny-by-throw;
  ask-degrades-to-deny; warn-degrades-to-silent-allow; the fail-open/
  fail-closed split; the explicit checked-in mapping table; the parity
  sub-gate; the `compile-runtime-agents.sh` exclusion) changed.
- 2026-07-25 — Revision following a second runtime spike (against
  OpenCode 1.18.5 — the binary now on PATH; the first spike's findings
  remain attributed to 1.18.4 and are not re-asserted against 1.18.5,
  see the new Context build-provenance note) and the security-engineer's
  Hard Rule #7 assessment of this bridge. Summary of changes: (1) added
  a version-provenance note distinguishing which findings came from
  which OpenCode build; (2) added a new binding requirement — the
  bridge MUST subscribe to `session.updated` and follow the session's
  current `info.agent`, deliberately opposite to `session.created`'s
  first-write-wins retention — closing a HIGH-severity
  privilege-escalation finding in which a resumed session kept
  asserting its stale, spawn-time agent role to
  `tech-lead-authoring-guard.py`'s binary write-bypass; fixed in commit
  `c4bc456`; also recorded that top-level/primary sessions carry no
  `info.agent` at `session.created`, correctly resolving to no
  specialist bypass once `_validate_role()` rejects the later
  `session.updated`'s `"tech-lead"` value by name; (3) resolved finding
  H-1(a) — OpenCode rejects an undefined `subagent_type` outright, with
  no child session spawned, closing off the arbitrary-role-string
  concern at the `task`-dispatch boundary; (4) resolved finding H-2 —
  per-agent `permission: skill: deny` frontmatter is enforced by
  OpenCode's own dispatch layer before `tool.execute.before` runs, and
  `skill` itself is confirmed read-only/non-executing, so the bridge's
  silence on `skill` is not a gap (residual prompt-injection risk on
  skill-returned content named separately); (5) recorded the security
  assessment's verdict that this bridge is a discipline/compliance
  control, not a hard security boundary, citing OpenCode's additive
  unordered global-plugin loading and an observed instance of
  unrelated-plugin interference (a global plugin making `tech-lead`
  subagent-spawnable until this branch's `mode: primary` shadowed it);
  (6) named a new out-of-scope follow-up — `researcher`'s combined
  `webfetch`/`websearch`/`edit` permissions as an unguarded
  prompt-injection intake path, with no network-egress guard on either
  harness — for a future ADR, not solved here. Status remains
  Accepted. No existing binding contract clause (adapter-not-port;
  deny-by-throw; ask-degrades-to-deny; warn-degrades-to-silent-allow;
  the fail-open/fail-closed split; the explicit checked-in mapping
  table; the parity sub-gate; the `compile-runtime-agents.sh`
  exclusion) was weakened; one new binding requirement
  (`session.updated`-follows) was added.
