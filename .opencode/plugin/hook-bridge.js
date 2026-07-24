// SPDX-License-Identifier: MIT
// Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
//
// .opencode/plugin/hook-bridge.js — OpenCode enforcement hook bridge.
//
// Protocol-translation adapter per docs/adr/fw-adr-0031-opencode-hook-bridge.md.
// This file owns ONLY payload construction, subprocess invocation, and
// verdict translation. It contains NO guard policy logic: every decision
// is made by the unchanged scripts under scripts/hooks/*.py, which this
// bridge shells out to with the same {tool_name, tool_input} JSON shape
// they already consume under Claude Code.
//
// Dependency-free ESM: only node:* builtins are imported so downstream
// projects need no `npm install` step for this plugin to load. Auto-
// discovered by OpenCode from .opencode/plugin/ (singular) -- verified
// at implementation time to work with no opencode.json `plugin` array
// entry required (see "Wiring" note in the implementation hand-off).
//
// -----------------------------------------------------------------------
// Verdict-translation contract (binding, fw-adr-0031 "Verdict-translation
// contract"):
//   permissionDecision absent, or "allow" (with or without a reason)
//     -> proceed. A "warn"-mode reason (allow + reason) has no side
//        channel on tool.execute.before ({args} in, throw-or-return out)
//        and is DROPPED. Named, accepted parity gap -- not a bug.
//   permissionDecision === "deny"
//     -> throw with the permissionDecisionReason as the message. Throwing
//        inside tool.execute.before aborts the call; the message surfaces
//        to the model as the tool part's state.error (verified at
//        implementation time).
//   permissionDecision === "ask" (currently only customer-notes-guard.py)
//     -> DEGRADES TO DENY. OpenCode's tool.execute.before has no
//        interactive re-prompt channel (permission.ask never fires in
//        non-interactive mode, per the runtime spike). Thrown message
//        names the librarian-dispatch-or-escape-hatch remedy verbatim,
//        per the ADR's binding wording.
//
// Fail-open vs fail-closed (binding, fw-adr-0031 "Fail-open vs.
// fail-closed for bridge errors"):
//   - Hook-internal failure the hook's own author already decided how to
//     handle (no stdout, or stdout that fails to parse as JSON) ->
//     inherit the hook's posture unchanged: proceed. The bridge does not
//     tighten a policy the guard's own maintainers already accepted.
//   - Bridge-infrastructure absence (python3 missing, hook script
//     missing/unreadable, subprocess cannot be spawned, subprocess times
//     out, or the subprocess exits non-zero -- every scripts/hooks/*.py
//     `main()` returns 0 on every documented code path, so a non-zero
//     exit is unambiguously a crash, not a decision) -> FAIL CLOSED:
//     throw, naming the broken hook and the underlying OS-level error.
//     Silent fail-open on total infrastructure loss would let an operator
//     run a whole session believing all guards are active when none are.

import { spawn } from "node:child_process";
import { accessSync, constants as fsConstants, readFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// -----------------------------------------------------------------------
// tool-arg-map.json — the checked-in derived mapping table. Loaded once
// per process (module scope); this is process-global static config, not
// per-session state, so loading it here (rather than per session.created)
// does not violate the "one Hooks instance per process, no sessionID at
// factory scope" constraint -- it is read-only and identical for every
// session in this process.
// -----------------------------------------------------------------------

const TOOL_ARG_MAP_PATH = path.join(
  __dirname,
  "..",
  "..",
  "scripts",
  "opencode",
  "tool-arg-map.json",
);

let TOOL_ARG_MAP = null;
let TOOL_ARG_MAP_LOAD_ERROR = null;
try {
  TOOL_ARG_MAP = JSON.parse(readFileSync(TOOL_ARG_MAP_PATH, "utf8"));
} catch (err) {
  // Deferred fail-closed: don't crash plugin load (which would take down
  // every tool in the session, guarded or not); throw only when a
  // guarded call actually needs the map, in tool.execute.before below.
  TOOL_ARG_MAP_LOAD_ERROR = err;
}

// -----------------------------------------------------------------------
// Guard chains. Order mirrors .claude/settings.json's PreToolUse matcher
// order EXACTLY -- this is a documented invariant (see the header comment
// of scripts/hooks/tech-lead-authoring-guard.py: "customer-notes-guard.py
// runs BEFORE this hook on the same matchers"). First deny/ask wins and
// short-circuits the remaining chain, so ordering changes behavior, not
// just cosmetics.
// -----------------------------------------------------------------------

const WRITE_EDIT_BASH_CHAIN = [
  "customer-notes-guard.py",
  "tech-lead-authoring-guard.py",
  "handoff-pre-tool-gate.py",
];

const GUARD_CHAIN_BY_TOOL = {
  write: WRITE_EDIT_BASH_CHAIN,
  edit: WRITE_EDIT_BASH_CHAIN,
  bash: WRITE_EDIT_BASH_CHAIN,
  task: ["subcall-limit-guard.py"],
};

// -----------------------------------------------------------------------
// Deferred fail-closed, part 2: TOOL_ARG_MAP loaded successfully but is
// missing an entry for one of the four GUARD_CHAIN_BY_TOOL keys (e.g. a
// future edit to scripts/opencode/tool-arg-map.json drops or typos
// "bash"). Computed once at module load, right next to the load
// try/catch above, so this failure mode is caught before any guarded
// call needs the map -- without this, buildGuardPayload would return
// null for that tool id, tool.execute.before's `if (!payload) return;`
// would exit, and the entire guard chain for that tool would stop
// running with no error and no log line (code review finding W2).
// -----------------------------------------------------------------------
const TOOL_ARG_MAP_MISSING_TOOL_IDS = TOOL_ARG_MAP
  ? Object.keys(GUARD_CHAIN_BY_TOOL).filter(
      (toolId) => !TOOL_ARG_MAP.tools || !TOOL_ARG_MAP.tools[toolId],
    )
  : [];

// Per-hook environment overrides. Mirrors the `SWDT_HANDOFF_GATES=warn`
// prefix .claude/settings.json applies to every handoff-*-gate.py /
// handoff-record-activity.py invocation (soft-launch, non-blocking today).
const HOOK_ENV_OVERRIDES = {
  "handoff-pre-tool-gate.py": { SWDT_HANDOFF_GATES: "warn" },
  "handoff-record-activity.py": { SWDT_HANDOFF_GATES: "warn" },
  "handoff-stop-gate.py": { SWDT_HANDOFF_GATES: "warn" },
  "handoff-subagent-stop-gate.py": { SWDT_HANDOFF_GATES: "warn" },
};

// Guard-hook subprocess timeout. Mirrors the 5s timeout every guard hook
// carries in .claude/settings.json's PreToolUse wiring. A hung guard must
// not hang the session forever; killing it and failing closed (bridge-
// infrastructure absence: "subprocess cannot be spawned/completed") is
// the safer failure than either an infinite hang or a silent fail-open.
const GUARD_HOOK_TIMEOUT_MS = 5000;

// SessionStart-set hooks get the longer of the two timeouts .claude/
// settings.json assigns them (version-check.sh alone is 10s there, to
// cover a possible network round-trip for the upstream-tag lookup).
const SESSION_START_TIMEOUT_MS = 10000;

// -----------------------------------------------------------------------
// Subprocess runner.
// -----------------------------------------------------------------------

/**
 * Run `python3 <hookPath>` (or a plain executable script for the
 * SessionStart .sh set) with `payload` (if any) piped to stdin as JSON.
 *
 * Resolves to {code, stdout, stderr} on any process exit (including
 * non-zero). Rejects only on bridge-infrastructure absence: spawn
 * failure (ENOENT / EACCES / etc.) or timeout.
 */
function runSubprocess(command, args, { cwd, env, stdinPayload, timeoutMs }) {
  return new Promise((resolve, reject) => {
    let child;
    try {
      child = spawn(command, args, {
        cwd,
        env,
        stdio: ["pipe", "pipe", "pipe"],
      });
    } catch (err) {
      reject(err);
      return;
    }

    let stdout = "";
    let stderr = "";
    let stdoutTruncated = false;
    let settled = false;
    let timedOut = false;

    const timer = setTimeout(() => {
      timedOut = true;
      child.kill("SIGKILL");
    }, timeoutMs);

    child.on("error", (err) => {
      // Spawn-time failure surfaces here too on some platforms (e.g. the
      // interpreter binary does not exist) even though the spawn() call
      // above did not throw synchronously.
      if (settled) return;
      settled = true;
      clearTimeout(timer);
      reject(err);
    });

    // MAX_STDOUT_BYTES caps accumulation (reviewer LOW note): every guard
    // hook's documented contract is a single small JSON verdict object, so
    // a runaway subprocess writing unbounded stdout is itself a symptom of
    // something wrong, not a case to support. Cap, log once, and keep
    // reading (still need the stream to drain so `close` fires) rather
    // than kill the process -- killing here would turn a merely-verbose
    // hook into a bridge-infrastructure failure it doesn't deserve.
    const MAX_STDOUT_BYTES = 1_000_000;
    child.stdout.on("data", (chunk) => {
      if (stdout.length >= MAX_STDOUT_BYTES) {
        if (!stdoutTruncated) {
          stdoutTruncated = true;
          console.error(
            `hook-bridge: stdout from '${command} ${args.join(" ")}' exceeded ` +
              `${MAX_STDOUT_BYTES} bytes; truncating further output (the ` +
              "verdict-parse step downstream will see a truncated -- likely " +
              "malformed -- payload and log accordingly).",
          );
        }
        return;
      }
      stdout += chunk;
    });
    child.stderr.on("data", (chunk) => {
      stderr += chunk;
    });

    child.on("close", (code) => {
      if (settled) return;
      settled = true;
      clearTimeout(timer);
      if (timedOut) {
        reject(
          new Error(
            `timed out after ${timeoutMs}ms and was killed`,
          ),
        );
        return;
      }
      resolve({ code, stdout, stderr });
    });

    if (stdinPayload !== undefined) {
      child.stdin.write(stdinPayload);
    }
    child.stdin.end();
  });
}

// -----------------------------------------------------------------------
// Guard-hook invocation + verdict application.
// -----------------------------------------------------------------------

/**
 * Assert `hookPath` exists and is readable, else throw a fail-closed
 * error naming the hook and the missing-file condition. Checked
 * synchronously and separately from spawn() so "hook script absent" is
 * diagnosed precisely rather than folded into a generic spawn-error
 * message.
 */
function assertHookReadable(hookName, hookPath) {
  try {
    accessSync(hookPath, fsConstants.R_OK);
  } catch (err) {
    throw new Error(
      `hook-bridge: guard hook '${hookName}' is missing or unreadable at ` +
        `${hookPath} (${err.code ?? err.message}). Failing closed rather ` +
        "than running this tool call with that guard silently disabled.",
    );
  }
}

/**
 * Parse a guard hook's stdout and apply the binding verdict-translation
 * contract. Throws on deny/ask. Returns (void) on allow / no-opinion /
 * malformed output (inherits the hook's own fail-open posture).
 */
function applyVerdict(hookName, stdout) {
  const text = stdout.trim();
  if (!text) {
    return; // No output -- hook has no opinion. Proceed.
  }

  let parsed;
  try {
    parsed = JSON.parse(text);
  } catch {
    // Malformed output -- inherit the hook's fail-open posture per the
    // ADR's binding fail-posture split. Not a bridge-infrastructure
    // failure: the process ran and exited 0; it is the hook's own
    // stdout contract that was not honored, which is the hook author's
    // call, not the bridge's to escalate. Still log loudly (finding
    // M-2): the fail-open *decision* is correct and unchanged, but an
    // accidental stray print() in a shared guard (tech-lead-authoring-
    // guard.py has a six-times-patched history) would otherwise defeat
    // that guard with zero operator-visible signal.
    console.error(
      `hook-bridge: guard hook '${hookName}' produced stdout that did not ` +
        "parse as JSON; inheriting the hook's fail-open posture (proceeding) " +
        `per fw-adr-0031, but this is a signal the hook itself is broken. ` +
        `stdout (truncated): ${text.slice(0, 500)}`,
    );
    return;
  }

  const hso =
    parsed && typeof parsed === "object" ? parsed.hookSpecificOutput : undefined;
  if (!hso || typeof hso !== "object") {
    return; // No opinion expressed in the expected shape. Proceed.
  }

  const decision = hso.permissionDecision;
  const reason = hso.permissionDecisionReason;

  if (decision === "deny") {
    throw new Error(
      `[${hookName}] ${reason || "denied (no reason given by the hook)"}`,
    );
  }

  if (decision === "ask") {
    // Degrade-to-deny per fw-adr-0031's binding verdict contract. Message
    // must say, verbatim, the librarian-dispatch-or-escape-hatch remedy.
    const remedy =
      "OpenCode has no interactive confirmation channel for this guard, " +
      "so 'ask' is treated as 'deny' here: you must dispatch librarian, " +
      "or set the escape hatch, and retry.";
    throw new Error(`[${hookName}] ${reason ? reason + " " : ""}${remedy}`);
  }

  // "allow" (with or without a reason) -- proceed. Any reason text on an
  // allow decision is Claude's "warn" mode; it is dropped here per the
  // named parity gap (no non-blocking side-channel on tool.execute.before).
}

/**
 * Build {tool_name, tool_input, agent_type?} from an OpenCode tool id +
 * args, using the checked-in mapping table. Returns null when the tool
 * id has no table entry (caller treats that as "nothing to translate").
 *
 * `agentType`, when provided, is placed at the payload's TOP LEVEL (a
 * sibling of tool_name/tool_input, not inside tool_input) because
 * scripts/hooks/tech-lead-authoring-guard.py's `_event_subagent_role()`
 * reads `event.get("agent_type")` from the top-level event dict. Without
 * this field every OpenCode session -- main or spawned specialist alike
 * -- resolves to `caller_role = None` and gets denied identically to the
 * un-dispatched tech-lead session on any off-allow-list write, which
 * would make the guard chain unusable for specialist sessions under
 * OpenCode. See the implementation hand-off escalations for why this
 * extra field is added beyond the ADR's literal {tool_name, tool_input}
 * wording.
 */
function buildGuardPayload(openCodeToolId, args, agentType) {
  const entry = TOOL_ARG_MAP.tools[openCodeToolId];
  if (!entry) return null;
  const toolInput = {};
  const source = args && typeof args === "object" ? args : {};
  for (const [openCodeKey, claudeKey] of Object.entries(entry.arg_map)) {
    if (Object.prototype.hasOwnProperty.call(source, openCodeKey)) {
      toolInput[claudeKey] = source[openCodeKey];
    }
  }
  const payload = { tool_name: entry.claude_tool_name, tool_input: toolInput };
  if (agentType) payload.agent_type = agentType;
  return payload;
}

/**
 * Run one guard hook against `payload`, apply the verdict contract.
 * Throws (fail-closed) on: hook missing/unreadable, spawn failure,
 * timeout, or non-zero exit (an uncaught crash -- every scripts/hooks/
 * *.py `main()` returns 0 on every documented path). Throws (by design,
 * per the verdict contract) on deny/ask. Returns normally otherwise.
 */
async function runGuardHook(hookName, payload, projectDir) {
  const hookPath = path.join(projectDir, "scripts", "hooks", hookName);
  assertHookReadable(hookName, hookPath);

  let result;
  try {
    result = await runSubprocess("python3", [hookPath], {
      cwd: projectDir,
      env: {
        ...process.env,
        CLAUDE_PROJECT_DIR: projectDir,
        ...(HOOK_ENV_OVERRIDES[hookName] ?? {}),
      },
      stdinPayload: JSON.stringify(payload),
      timeoutMs: GUARD_HOOK_TIMEOUT_MS,
    });
  } catch (err) {
    throw new Error(
      `hook-bridge: could not run guard hook '${hookName}' (${err.message}). ` +
        "Failing closed rather than running this tool call unenforced.",
    );
  }

  if (result.code !== 0) {
    const stderrTail = (result.stderr || "(empty)").slice(-2000);
    throw new Error(
      `hook-bridge: guard hook '${hookName}' exited ${result.code} ` +
        `(every scripts/hooks/*.py main() returns 0 on every documented ` +
        `path, so this is a crash, not a decision). stderr: ${stderrTail}. ` +
        "Failing closed.",
    );
  }

  applyVerdict(hookName, result.stdout);
}

// -----------------------------------------------------------------------
// Plugin entry point.
// -----------------------------------------------------------------------

export const HookBridge = async (input) => {
  // Process-global static config (NOT per-session state): the directory
  // this OpenCode process is running against. A single process serves
  // one project directory for its whole lifetime, so capturing this once
  // at factory scope is safe -- unlike per-session bookkeeping, which
  // must live inside the event handler below.
  const projectDir = input.directory;

  // Per-session state (populated in the `event` handler on
  // session.created; read everywhere else). Three maps/sets:
  //   sessionParent: sessionID -> parentID | null. Lets session.idle
  //     (which carries no parentID of its own, confirmed by the runtime
  //     spike) decide Stop-vs-SubagentStop semantics. First-write-wins
  //     (finding H-1(b), see the session.created handler below): a
  //     re-fire for an already-recorded sessionID cannot change it.
  //   sessionAgent: sessionID -> OpenCode `agent` name (e.g.
  //     "software-engineer") captured from session.created's and
  //     session.updated's info.agent. Forwarded as `agent_type` in guard
  //     payloads so tech-lead-authoring-guard.py can resolve caller_role
  //     the same way it does from Claude Code's hook payload (see
  //     buildGuardPayload's docstring).
  //
  //     Corrected comment (this line was WRONG -- HIGH-severity
  //     privilege-escalation finding, runtime spike against opencode
  //     1.18.5): for a top-level/primary session, `info.agent` is ABSENT
  //     ENTIRELY from session.created -- it is not present-with-an-
  //     invalid-value. It arrives later, on that session's first
  //     session.updated. This project's opencode.json pins
  //     `default_agent: "tech-lead"`, so that session.updated carries
  //     `info.agent === "tech-lead"` for a top-level session, which
  //     `_validate_role()` rejects BY NAME (see that function's explicit
  //     self-push guard) -- caller_role resolves to `None`, the safe/
  //     restrictive outcome, same as before this fix, just reached by the
  //     guard's dedicated tech-lead rejection instead of by omission.
  //     Verified by the "top-level session" test in
  //     tests/hooks/test-opencode-hook-bridge.sh.
  //
  //   TWO DIFFERENT UPDATE POLICIES for the same map, by design -- do
  //   not "fix" this into one consistent policy, they answer different
  //   questions:
  //     - session.created: FIRST-WRITE-WINS (finding H-1(b), retained
  //       below unchanged). A re-fire for an already-recorded sessionID
  //       is anomalous; there is no verified runtime meaning for it to
  //       attach to, so retaining the first-recorded role is the safe
  //       default.
  //     - session.updated: FOLLOW, NOT RETAIN (this fix). The runtime
  //       spike proved `info.agent` for an EXISTING sessionID changes via
  //       plain session.updated when the session is resumed with a
  //       different `--agent` -- session.created never re-fires for that
  //       path. Retaining the original role here would make this bridge
  //       assert a STALE, still-privileged role for a session whose real
  //       running identity (system prompt, tool set, permissions) has
  //       already moved on -- that mismatch IS the escalation. Tracking
  //       the truth removes it.
  //       Escalation-vector check ("can following itself widen access?"):
  //       tech-lead-authoring-guard.py grants the SAME unconditional
  //       write bypass to every validated non-tech-lead role (it
  //       distinguishes tech-lead from not-tech-lead, not role-
  //       appropriate paths), and `_validate_role()` rejects the literal
  //       string "tech-lead" outright. So a followed change can only move
  //       a session between "some specialist" (already an equivalent
  //       bypass under the guard's current model) and "tech-lead-or-
  //       unknown" (`None`, the safe/restrictive outcome) -- there is no
  //       transition this handler can produce that grants a tier the
  //       session could not already reach by being freshly dispatched as
  //       that role. Logged via console.error on every observed change
  //       regardless (see the session.updated handler below): even a
  //       correctly-handled identity change is security-relevant and
  //       should leave a trace.
  //   handledIdleSessions: sessionIDs whose session.idle has already been
  //     processed. session.idle was observed firing twice for the same
  //     child session in one spike run; both handoff-stop-gate.py and
  //     handoff-subagent-stop-gate.py must run at most once per session.
  const sessionParent = new Map();
  const sessionAgent = new Map();
  const handledIdleSessions = new Set();

  // -----------------------------------------------------------------
  // S1 -- bounded eviction (unbounded session-state growth). Analysis:
  //
  // These three structures are never explicitly deleted from and this
  // factory runs once per process (see "Plugin process lifetime" above),
  // so a long-lived OpenCode server accumulates one entry per session,
  // forever, across however many sessions it ever serves.
  //
  // Is there a safe LIFECYCLE signal to evict on? No. The bridge's wired
  // event surface (session.created, session.updated, session.idle,
  // experimental.session.compacting -- fw-adr-0031's "Portability
  // inventory", confirmed by the 2026-07-24 runtime spike) has no
  // session-ended / session-deleted event. `session.idle` is the
  // Stop-equivalent ("end of the main session's turn" per the ADR's own
  // mapping-table wording), not "this session will never be touched
  // again" -- nothing in the observed event catalog rules out more
  // tool.execute.before / session.updated calls arriving for the same
  // sessionID in a later turn. Evicting sessionParent/sessionAgent at
  // first idle would risk exactly the correctness regression this fix
  // must not introduce: the next guarded call on a still-live session
  // would silently lose its recorded parentID/agent and resolve
  // caller_role = None instead of the session's real role. Reusing "a
  // SECOND session.idle for this sessionID" as a stronger done-signal
  // does not work either -- that is precisely the case
  // handledIdleSessions exists to dedupe (the ADR's documented
  // double-fire spike finding); treating it as "now it's really over"
  // would misfire on both the legitimate every-turn case and the known
  // spurious double-fire case. So: no safe lifecycle-signal eviction
  // point exists with the event surface OpenCode currently exposes to
  // this bridge.
  //
  // Fallback: a single shared FIFO cap, keyed on first-seen order
  // across all three structures together (one ledger, so they can never
  // drift out of sync with each other -- an entry is evicted from all
  // three at once or none). subcall-limit-guard.py's
  // DEFAULT_SUBCALL_BUDGET (100 subagent spawns per top-level session,
  // operator-raisable via SWDT_SUBCALL_BUDGET) is the closest existing
  // bound on how many sessions one real top-level session's lifetime
  // can plausibly produce; SESSION_STATE_CAP below is two orders of
  // magnitude above that default specifically so this only fires for a
  // process that has served an implausible number of distinct sessions
  // -- at which point evicting the single oldest-first-seen entry (by
  // far the most likely to be long finished) and logging it is the
  // reasonable trade the fix's task brief authorizes for this
  // low-severity issue. This does NOT eliminate the theoretical risk of
  // evicting a still-live session's state on a sufficiently
  // long-lived/high-volume process; it bounds how implausible that has
  // to be before it can happen, and logs loudly if it ever does.
  const SESSION_STATE_CAP = 10000;
  const sessionInsertOrder = new Set(); // Insertion-ordered ledger of
  // every sessionID seen via session.created in this process; used only
  // to pick FIFO eviction order below. A JS Set iterates in insertion
  // order, so `.values().next().value` is always the oldest entry.

  function trackSessionAndEvictIfOverCap(sessionID) {
    if (sessionInsertOrder.has(sessionID)) return;
    sessionInsertOrder.add(sessionID);
    if (sessionInsertOrder.size <= SESSION_STATE_CAP) return;

    const oldest = sessionInsertOrder.values().next().value;
    sessionInsertOrder.delete(oldest);
    sessionParent.delete(oldest);
    sessionAgent.delete(oldest);
    handledIdleSessions.delete(oldest);
    console.error(
      `hook-bridge: session-state cap (${SESSION_STATE_CAP} distinct ` +
        `sessions) exceeded; evicted oldest-tracked session '${oldest}'. ` +
        "If that session is somehow still live, its next guarded tool " +
        "call will resolve caller_role = None (fail-safe, but a " +
        "functional regression) and a subsequent session.idle for it " +
        "could re-run its Stop/SubagentStop gate. This should only occur " +
        "for a process that has served an implausible number of distinct " +
        "sessions -- see the S1 bounded-eviction comment above " +
        "sessionInsertOrder's declaration.",
    );
  }

  return {
    // -------------------------------------------------------------
    // tool.execute.before: PreToolUse-equivalent guard chain.
    // -------------------------------------------------------------
    "tool.execute.before": async (beforeInput, output) => {
      const toolId = beforeInput.tool;
      const chain = GUARD_CHAIN_BY_TOOL[toolId];
      if (!chain) return; // Not a guarded OpenCode tool.

      if (!TOOL_ARG_MAP || TOOL_ARG_MAP_MISSING_TOOL_IDS.length > 0) {
        // Bridge-infrastructure absence, in either of two forms: the
        // mapping table itself failed to load, or it loaded but is
        // missing an entry for a tool id GUARD_CHAIN_BY_TOOL declares as
        // guarded (finding W2). Both are the same failure class -- the
        // bridge cannot trust the map -- so both fail closed on every
        // guarded call rather than run silently unenforced for the rest
        // of the session.
        throw new Error(
          TOOL_ARG_MAP_LOAD_ERROR
            ? "hook-bridge: scripts/opencode/tool-arg-map.json failed to " +
                `load (${TOOL_ARG_MAP_LOAD_ERROR.message}). Refusing to ` +
                "proceed on a guarded tool call."
            : "hook-bridge: scripts/opencode/tool-arg-map.json loaded but " +
                "has no entry for guarded tool id(s) " +
                `[${TOOL_ARG_MAP_MISSING_TOOL_IDS.join(", ")}] declared in ` +
                "GUARD_CHAIN_BY_TOOL. Refusing to proceed on a guarded " +
                "tool call.",
        );
      }

      const payload = buildGuardPayload(
        toolId,
        output.args,
        sessionAgent.get(beforeInput.sessionID),
      );
      if (!payload) {
        // Unreachable in normal operation: the module-load assertion
        // above guarantees every GUARD_CHAIN_BY_TOOL key has a
        // tool-arg-map.json entry, so buildGuardPayload cannot return
        // null for a toolId that reached this point. If it does, the
        // invariant was violated some other way -- fail loud rather than
        // silently skip the guard chain (finding W2's whole point).
        throw new Error(
          "hook-bridge: internal invariant violated -- buildGuardPayload " +
            `returned null for guarded tool id '${toolId}' despite passing ` +
            "the module-load tool-arg-map completeness assertion. Failing " +
            "closed rather than running this tool call unenforced.",
        );
      }

      for (const hookName of chain) {
        // eslint-disable-next-line no-await-in-loop -- ordering is the
        // whole point: first deny/ask wins and short-circuits (see the
        // header comment on GUARD_CHAIN_BY_TOOL).
        await runGuardHook(hookName, payload, projectDir);
      }
    },

    // -------------------------------------------------------------
    // tool.execute.after: PostToolUse-equivalent activity bookkeeping.
    // Unlike the before-chain, this NEVER fails closed: the tool call
    // has already completed, so there is nothing left to block, and
    // handoff-record-activity.py's own contract is "must never gate or
    // block a tool call" (see its module docstring). Infra failures here
    // are logged to the process's own stderr (visible to the operator
    // running OpenCode, per the runtime spike's console.error finding)
    // and otherwise swallowed.
    // -------------------------------------------------------------
    "tool.execute.after": async (afterInput) => {
      const toolId = afterInput.tool;
      const agentType = sessionAgent.get(afterInput.sessionID);
      const mapEntry = TOOL_ARG_MAP?.tools?.[toolId];
      const payload = mapEntry
        ? buildGuardPayload(toolId, afterInput.args, agentType)
        : {
            tool_name: toolId,
            tool_input: afterInput.args && typeof afterInput.args === "object"
              ? afterInput.args
              : {},
            ...(agentType ? { agent_type: agentType } : {}),
          };
      if (!payload) return;
      payload.hook_event_name = "PostToolUse";

      const hookName = "handoff-record-activity.py";
      const hookPath = path.join(projectDir, "scripts", "hooks", hookName);
      try {
        accessSync(hookPath, fsConstants.R_OK);
        const result = await runSubprocess("python3", [hookPath], {
          cwd: projectDir,
          env: {
            ...process.env,
            CLAUDE_PROJECT_DIR: projectDir,
            ...(HOOK_ENV_OVERRIDES[hookName] ?? {}),
          },
          stdinPayload: JSON.stringify(payload),
          timeoutMs: GUARD_HOOK_TIMEOUT_MS,
        });
        if (result.code !== 0) {
          console.error(
            `hook-bridge: ${hookName} exited ${result.code} (non-blocking, ` +
              `after-hook only). stderr: ${(result.stderr || "").slice(-2000)}`,
          );
        }
      } catch (err) {
        console.error(
          `hook-bridge: could not run ${hookName} (non-blocking, after-hook ` +
            `only): ${err.message}`,
        );
      }
    },

    // -------------------------------------------------------------
    // event: session.created (SessionStart-equivalent), session.updated
    // (agent-identity tracking -- HIGH-severity privilege-escalation
    // fix, see the sessionAgent declaration comment above for the
    // follow-vs-retain asymmetry with session.created), and session.idle
    // (Stop / SubagentStop-equivalent, distinguished by parentID
    // recorded at session.created time).
    // -------------------------------------------------------------
    event: async ({ event }) => {
      if (event.type === "session.created") {
        const info = event.properties?.info ?? {};
        const sessionID = event.properties?.sessionID ?? info.id;
        if (!sessionID) return;

        // S1 bounded eviction: record this sessionID's first-seen order
        // and evict the oldest tracked session's state if the shared cap
        // is exceeded. Must run before the first-write-wins population
        // below so a freshly-evicted-then-immediately-reused sessionID
        // (implausible, but the cap's whole premise is "implausible
        // things become possible at extreme scale") is tracked fresh
        // rather than silently skipped as "already seen".
        trackSessionAndEvictIfOverCap(sessionID);

        // First-write-wins for both maps (finding H-1(b)). session.created
        // re-firing for a sessionID already recorded (an in-session agent
        // switch, a resume, a re-attach -- whether OpenCode actually does
        // this is being spiked separately, but the fix does not depend on
        // the answer) must NOT silently change what this bridge forwards.
        //   - sessionAgent is what reaches guard payloads as `agent_type`,
        //     and tech-lead-authoring-guard.py grants an unconditional
        //     write bypass once any validated non-tech-lead role is
        //     present -- an overwrite here would silently change the
        //     guard-visible role mid-conversation with no re-dispatch
        //     through tech-lead.
        //   - sessionParent drives Stop-vs-SubagentStop routing at
        //     session.idle (below); an overwrite here would silently flip
        //     which lifecycle gate a session's idle event resolves to.
        // Retain-and-log, do not throw: this is an event handler, not a
        // gate, and an uncaught throw here has no defined abort semantics
        // (see runLifecycleGateHook's identical reasoning for session.idle).
        const incomingParentID = info.parentID ?? null;
        if (sessionParent.has(sessionID)) {
          const retainedParentID = sessionParent.get(sessionID);
          if (incomingParentID !== retainedParentID) {
            console.error(
              `hook-bridge: session.created re-fired for session ` +
                `'${sessionID}' with a different parentID ('${incomingParentID}' ` +
                `vs retained '${retainedParentID}'). Retaining the first-` +
                "recorded parent; a later change would silently flip Stop " +
                "vs SubagentStop routing at session.idle.",
            );
          }
        } else {
          sessionParent.set(sessionID, incomingParentID);
        }

        if (info.agent) {
          if (sessionAgent.has(sessionID)) {
            const retainedAgent = sessionAgent.get(sessionID);
            if (info.agent !== retainedAgent) {
              console.error(
                `hook-bridge: session.created re-fired for session ` +
                  `'${sessionID}' with a different agent ('${info.agent}' ` +
                  `vs retained '${retainedAgent}'). Retaining the first-` +
                  "recorded role; tech-lead-authoring-guard.py's write " +
                  "bypass must not change mid-session without re-dispatch " +
                  "through tech-lead.",
              );
            }
          } else {
            sessionAgent.set(sessionID, info.agent);
          }
        }

        if (info.parentID) {
          // Child (subagent-spawned) session: no SessionStart-equivalent
          // reminders fire for it, mirroring Claude Code (SessionStart
          // targets the main session; subagent lifecycle is handled by
          // the TaskCreated/TaskCompleted/SubagentStop hooks instead, out
          // of this bridge's wired scope). Critically, subcall-limit-
          // reset.py must NOT run here: it resets the shared, project-
          // level subcall budget file, and doing that on every subagent
          // spawn would hand each subagent a fresh full budget.
          return;
        }

        await runSessionStartSet(projectDir);
        return;
      }

      if (event.type === "session.updated") {
        // HIGH-severity privilege-escalation fix (runtime spike against
        // opencode 1.18.5): session.created never re-fires for an
        // existing sessionID, but `info.agent` for an existing sessionID
        // DOES change -- via plain session.updated -- when the session
        // is resumed with a different `--agent`. Without this branch,
        // sessionAgent kept forwarding the ORIGINAL agent forever, so a
        // session that once ran as (say) software-engineer kept getting
        // tech-lead-authoring-guard.py's write bypass on every later
        // call even after its real running agent -- system prompt, tool
        // set, permissions -- had been repointed elsewhere. Any
        // bash-capable session can enumerate sessions and resume one
        // with a different agent, so the attack cost is trivial.
        //
        // FOLLOW, NOT RETAIN here -- deliberately the opposite of
        // session.created's first-write-wins policy a few lines above.
        // See the sessionAgent declaration comment (top of this
        // factory) for the full "why the same map has two different
        // update policies" reasoning and the escalation-vector analysis
        // for why following the change cannot itself widen access.
        const info = event.properties?.info ?? {};
        const sessionID = event.properties?.sessionID ?? info.id;
        if (!sessionID) return;
        if (!info.agent) return; // No agent carried on this particular
        // update (e.g. an update unrelated to agent identity) -- nothing
        // to follow. Do NOT clear an existing entry on an agent-less
        // update; that would turn a routine session.updated into an
        // accidental privilege change (silently dropping to caller_role
        // = None is the SAFE direction, but still an unrequested change
        // with no verified runtime trigger to justify it).

        const previousAgent = sessionAgent.get(sessionID);
        if (info.agent === previousAgent) return; // No change.

        sessionAgent.set(sessionID, info.agent);
        // Security-relevant even when handled correctly (this branch IS
        // the fix, not a bug) -- leave a trace so an operator can spot an
        // unexpected mid-session agent swap.
        console.error(
          `hook-bridge: session '${sessionID}' agent identity changed ` +
            `via session.updated (was '${previousAgent ?? "<none recorded>"}', ` +
            `now '${info.agent}'). Forwarding the NEW agent as agent_type ` +
            "on this session's subsequent guard payloads -- following the " +
            "session's current real agent, per the HIGH-severity " +
            "privilege-escalation fix (see the sessionAgent declaration " +
            "comment for why this differs from session.created's first-" +
            "write-wins policy).",
        );
        return;
      }

      if (event.type === "session.idle") {
        const sessionID = event.properties?.sessionID;
        if (!sessionID) return;
        if (handledIdleSessions.has(sessionID)) return; // Idempotency:
        // session.idle was observed firing twice for one child session
        // in the runtime spike; run the Stop-equivalent gate at most once.
        handledIdleSessions.add(sessionID);

        const parentID = sessionParent.get(sessionID);
        const hookName = parentID
          ? "handoff-subagent-stop-gate.py"
          : "handoff-stop-gate.py";
        await runLifecycleGateHook(hookName, projectDir);
      }
    },

    // -------------------------------------------------------------
    // experimental.session.compacting: near-exact structural match for
    // the Claude Code SessionStart(matcher: compact) hook. Runs
    // post-compact-refresh.sh and appends its banner text to
    // output.context so the directive reaches the session the same way
    // Claude Code's SessionStart(compact) stdout does.
    // -------------------------------------------------------------
    "experimental.session.compacting": async (compactInput, output) => {
      const hookName = "post-compact-refresh.sh";
      const hookPath = path.join(projectDir, "scripts", "hooks", hookName);
      try {
        accessSync(hookPath, fsConstants.X_OK);
        const result = await runSubprocess(hookPath, [], {
          cwd: projectDir,
          env: { ...process.env, CLAUDE_PROJECT_DIR: projectDir },
          timeoutMs: SESSION_START_TIMEOUT_MS,
        });
        if (result.code === 0 && result.stdout) {
          output.context = (output.context ?? "") + result.stdout;
        } else if (result.code !== 0) {
          console.error(
            `hook-bridge: ${hookName} exited ${result.code}: ` +
              (result.stderr || "").slice(-2000),
          );
        }
      } catch (err) {
        // SessionStart-set reminders are informational (see
        // runSessionStartSet below for the same posture applied there);
        // a missing/broken reminder script degrades to "no banner", not
        // a blocked compaction.
        console.error(`hook-bridge: could not run ${hookName}: ${err.message}`);
      }
    },
  };
};

// -----------------------------------------------------------------------
// SessionStart-equivalent set (session.created, no parentID).
// -----------------------------------------------------------------------
//
// scripts/hooks/version-check.sh, atomic-question-reminder.sh, and
// role-routing-reminder.sh are informational banners (Claude Code prints
// their stdout into the session-start transcript). OpenCode's `event`
// hook has NO output-mutation channel for arbitrary event types (only
// experimental.session.compacting exposes output.context; confirmed by
// reading the plugin's Hooks shape at implementation time) -- so there is
// nowhere in-conversation to place this banner text. Best available
// channel: the process's own stderr, which the runtime spike confirmed
// is visible to the operator running the OpenCode process (not the chat
// transcript). This is a named, accepted degradation, not a silent drop:
// see the implementation hand-off's escalations for the open question
// this raises for a future ADR revision.
//
// subcall-limit-reset.py is NOT informational -- it resets the shared
// per-project subcall-budget state file scripts/hooks/subcall-limit-
// guard.py reads on every `task` tool call. It runs for real, unlike the
// three banner scripts, which run for their stderr side-effect only.
async function runSessionStartSet(projectDir) {
  // timeoutMs mirrors .claude/settings.json's per-hook SessionStart
  // timeout exactly (version-check.sh alone is given the longer budget
  // there, for its possible network round-trip; the rest get 5s).
  const scripts = [
    { name: "version-check.sh", kind: "sh", timeoutMs: SESSION_START_TIMEOUT_MS },
    { name: "atomic-question-reminder.sh", kind: "sh", timeoutMs: GUARD_HOOK_TIMEOUT_MS },
    { name: "role-routing-reminder.sh", kind: "sh", timeoutMs: GUARD_HOOK_TIMEOUT_MS },
    { name: "subcall-limit-reset.py", kind: "py", timeoutMs: GUARD_HOOK_TIMEOUT_MS },
  ];

  for (const { name, kind, timeoutMs } of scripts) {
    const scriptPath = path.join(projectDir, "scripts", "hooks", name);
    // version-check.sh lives at scripts/version-check.sh, not
    // scripts/hooks/ -- special-case its path to match
    // .claude/settings.json's wiring.
    const resolvedPath =
      name === "version-check.sh"
        ? path.join(projectDir, "scripts", name)
        : scriptPath;

    try {
      accessSync(resolvedPath, kind === "sh" ? fsConstants.X_OK : fsConstants.R_OK);
    } catch {
      // SessionStart set is informational/best-effort (matches
      // .claude/settings.json's own `[ -x ... ] && ... || true` guards
      // for the three shell reminders). A missing script is silently
      // skipped, not fail-closed -- these are reminders, not guards.
      continue;
    }

    try {
      const result =
        kind === "sh"
          ? await runSubprocess(resolvedPath, [], {
              cwd: projectDir,
              env: { ...process.env, CLAUDE_PROJECT_DIR: projectDir },
              timeoutMs,
            })
          : await runSubprocess("python3", [resolvedPath], {
              cwd: projectDir,
              env: { ...process.env, CLAUDE_PROJECT_DIR: projectDir },
              timeoutMs,
            });
      if (result.stdout) {
        console.error(`hook-bridge: [session-start] ${name}:\n${result.stdout}`);
      }
      if (result.code !== 0) {
        console.error(
          `hook-bridge: [session-start] ${name} exited ${result.code}: ` +
            (result.stderr || "").slice(-2000),
        );
      }
    } catch (err) {
      // Same posture as the missing-script case: informational-only, so
      // a spawn failure here is logged, not fatal.
      console.error(`hook-bridge: [session-start] could not run ${name}: ${err.message}`);
    }
  }
}

// -----------------------------------------------------------------------
// session.idle lifecycle gates (handoff-stop-gate.py /
// handoff-subagent-stop-gate.py). These are Stop/SubagentStop-equivalent:
// today they run in warn mode (SWDT_HANDOFF_GATES=warn), matching
// .claude/settings.json, so a deny is not yet reachable in practice, but
// the deny path is honored below on the same terms as the PreToolUse
// chain for forward compatibility with a future promotion out of warn
// mode.
// -----------------------------------------------------------------------
async function runLifecycleGateHook(hookName, projectDir) {
  const hookPath = path.join(projectDir, "scripts", "hooks", hookName);
  try {
    assertHookReadable(hookName, hookPath);
    const result = await runSubprocess("python3", [hookPath], {
      cwd: projectDir,
      env: {
        ...process.env,
        CLAUDE_PROJECT_DIR: projectDir,
        ...(HOOK_ENV_OVERRIDES[hookName] ?? {}),
      },
      // Neither hook needs a specific event payload beyond a JSON object
      // to parse (both fail open on JSONDecodeError, and neither reads
      // tool_name/tool_input); an empty object round-trips through their
      // `json.load(sys.stdin)` / `isinstance(event, dict)` checks cleanly.
      stdinPayload: "{}",
      timeoutMs: GUARD_HOOK_TIMEOUT_MS,
    });
    if (result.code !== 0) {
      throw new Error(
        `hook-bridge: lifecycle gate '${hookName}' exited ${result.code} ` +
          `(crash, not a decision). stderr: ${(result.stderr || "").slice(-2000)}`,
      );
    }
    applyVerdict(hookName, result.stdout);
  } catch (err) {
    // session.idle has no tool call to abort -- there is nothing for a
    // throw here to "deny". Log loudly (this is a real enforcement gap,
    // unlike the after-hook's non-blocking posture) so the operator sees
    // it, but do not throw: an uncaught throw from an `event` handler has
    // no defined abort semantics the way tool.execute.before's throw
    // does.
    console.error(`hook-bridge: ${hookName} did not complete cleanly: ${err.message}`);
  }
}
