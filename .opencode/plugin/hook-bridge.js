// SPDX-License-Identifier: MIT
// Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
//
// .opencode/plugin/hook-bridge.js — OpenCode enforcement hook bridge.
//
// Protocol-translation adapter per FW-ADR-0031 (recorded in the
// meta-project, not shipped with the scaffold).
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
// handoff-task-created-gate.py -- deliberately NOT wired here. Recorded
// explicitly (not silently absent) so this is read as "investigated and
// rejected", not "forgotten alongside handoff-task-completed-gate.py".
//
// The hook's Check 1 (owner_role must be a canonical roster role) has an
// honest OpenCode source: the `task` tool's own `subagent_type` arg IS
// the role being dispatched, same value already forwarded elsewhere in
// this file as `agent_type` (see buildGuardPayload's docstring). Check 2
// (the event must cite the active handoff via `handoff_task_id` /
// `active_handoff_task_id`, matching the currently active handoff's
// `task_id`) has NO honest OpenCode source: the `task` tool's callable
// args are `{description, prompt, subagent_type}` only (see
// scripts/opencode/tool-arg-map.json's `task` entry) -- no field carries
// a handoff citation the CALLER supplied. Synthesizing that field from
// the active handoff this bridge would read to VALIDATE it (i.e.
// asserting handoff_task_id := the same active handoff's own task_id)
// makes Check 2 vacuous: it would always pass, by construction, testing
// nothing. That is explicitly out of bounds here, not a style choice.
//
// This is not a "wire it and accept some noise" case. The script's own
// Check 1 -> Check 2 sequencing (see handoff-task-created-gate.py's
// main()) means a call that CLEARS Check 1 (a genuinely valid
// subagent_type) always falls through into Check 2, which can never be
// satisfied under OpenCode -- so today, in SWDT_HANDOFF_GATES=warn, EVERY
// task dispatch would carry a citation violation. That violation happens
// to be invisible right now (this bridge's applyVerdict only throws on
// deny/ask; an allow-with-warning verdict -- exactly what warn mode
// produces for every one of these citation failures -- is dropped with
// no console.error at all, per the verdict-translation contract's named
// "warn-mode reason dropped" parity gap). But the moment
// SWDT_HANDOFF_GATES is promoted to "enforce" (the whole reason the deny
// path is honored ahead of that promotion elsewhere in this file, e.g.
// runLifecycleGateHook's own comment), Check 2's permissionDecision
// becomes "deny" unconditionally, and this bridge's tool.execute.before
// throws on every single `task` dispatch under OpenCode regardless of
// how valid the subagent_type is -- i.e. wiring this hook today would
// silently plant a landmine that detonates as "subagent dispatch is
// completely broken under OpenCode" on the day gates are promoted, with
// zero warning surfaced beforehand to reveal it coming. That is a worse
// outcome than the current, honest gap: an un-wired hook is visibly
// absent from GUARD_CHAIN_BY_TOOL (this comment IS that visibility); a
// wired-but-doomed-to-block hook looks like coverage right up until an
// operator flips one env var and loses task dispatch entirely.
//
// Getting a legitimate citation onto the wire would require inventing a
// NEW caller-side convention (e.g. requiring tech-lead to embed the
// active handoff's task_id as parseable text inside the `task` tool's
// free-form `prompt` field, then having this bridge parse it back out)
// that does not exist today under Claude Code either -- out of scope for
// a bridge whose whole contract is translating an EXISTING protocol, not
// authoring a new one. That is an architecture-level call for
// `architect`/`tech-lead`, not something to invent unilaterally inside
// this file.
//
// Net effect: this scaffold ships 13 of the 14 Claude Code hooks wired
// under OpenCode, not 14. Recorded here, and flagged for the FW-ADR-0031
// portability inventory (meta-project, not shipped with this scaffold)
// to carry the same "13 of 14, Check 2 structurally unportable without a
// new citation convention" accounting -- an accurate 13 beats a
// decorative, silently-doomed 14.
// -----------------------------------------------------------------------

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
      (toolId) => !TOOL_ARG_MAP.tools?.[toolId],
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
  "handoff-task-completed-gate.py": { SWDT_HANDOFF_GATES: "warn" },
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
 * Parse `text` (already known non-empty) as the guard hook's JSON stdout
 * and extract hookSpecificOutput, per the binding verdict-translation
 * contract's fail-open-on-malformed posture. Split out of applyVerdict
 * (below) purely to keep that function's CCN down; behavior -- including
 * the console.error on malformed JSON (finding M-2) -- is unchanged.
 * Returns the hookSpecificOutput object, or undefined when there is no
 * opinion to apply (malformed JSON, non-object payload, or no
 * hookSpecificOutput field).
 */
function parseGuardVerdictOutput(hookName, text) {
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
    return undefined;
  }

  const hso =
    parsed && typeof parsed === "object" ? parsed.hookSpecificOutput : undefined;
  return hso && typeof hso === "object" ? hso : undefined;
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

  const hso = parseGuardVerdictOutput(hookName, text);
  if (!hso) {
    return; // No opinion expressed in the expected shape (or malformed
    // JSON, already logged by parseGuardVerdictOutput). Proceed.
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
// handoff-task-completed-gate.py -- OpenCode's TaskCompleted-equivalent,
// fired from tool.execute.after for the `task` tool only (below). Unlike
// handoff-task-created-gate.py (deliberately NOT wired -- see the long
// comment above GUARD_CHAIN_BY_TOOL's declaration), this hook is fully
// portable: beyond the `hook_event_name` discriminator its main() reads
// nothing else from the event -- it loads the active handoff straight off
// disk and reports missing_evidence_gates() -- so the only payload this
// bridge needs to construct is `{hook_event_name: "TaskCompleted"}`, the
// exact field this hook's own early-return guards on. No `tool_name` /
// `tool_input` shape is needed here (this call does not go through
// buildGuardPayload / runGuardHook / GUARD_CHAIN_BY_TOOL at all -- it is
// its own dedicated call, parallel to how handoff-record-activity.py is
// invoked as its own dedicated call in tool.execute.after rather than
// through the tool.execute.before guard-chain machinery).
//
// Never fails closed, matching this file's binding tool.execute.after
// posture (see the "tool.execute.after: PostToolUse-equivalent activity
// bookkeeping" header comment on the returned hooks object below): the
// `task` call has already completed, so there is nothing left to block.
// Spawn failure, non-zero exit, and a hook that could not be read are all
// logged to stderr and swallowed, exactly like the handoff-record-
// activity.py call alongside it.
//
// Unlike handoff-record-activity.py (whose own contract is "does not
// produce a stdout JSON response" -- nothing to surface), this hook DOES
// emit a real hookSpecificOutput payload in "warn" mode when required
// completion evidence is missing, and this file's tool.execute.after
// handler never parses stdout at all (see the block below -- it only
// checks the exit code). Without an explicit surface step here, this
// hook would run for real (unlike the un-wired created-gate) but its one
// user-visible signal would still land nowhere an operator could see it
// -- the same "wired but inert" failure this whole task exists to close,
// one layer deeper. So: parse the stdout (reusing
// parseGuardVerdictOutput, already used for the verdict-bearing path
// above) and console.error a summary when present. This is NOT verdict
// application (no throw for deny/ask -- there is nothing left to deny),
// purely an echo, matching this file's own "silence is the failure mode
// this port has repeatedly been bitten by" precedent
// (CR-OPENCODE-HOOK-BRIDGE-0002's identical reasoning for session.idle
// dedup logging).
//
// No dedup is needed here the way session.idle needed handledIdleSessions:
// OpenCode's tool.execute.after fires once per completed tool CALL (there
// is no observed double-fire for a single call the way session.idle was
// observed double-firing for one session in the runtime spike), and each
// `task` dispatch is its own distinct call with its own callID -- there is
// no shared per-sessionID state this hook's repeated invocation could
// desynchronize the way handledIdleSessions guards against.
async function runTaskCompletedGate(projectDir) {
  const hookName = "handoff-task-completed-gate.py";
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
      stdinPayload: JSON.stringify({ hook_event_name: "TaskCompleted" }),
      timeoutMs: GUARD_HOOK_TIMEOUT_MS,
    });
    if (result.code !== 0) {
      console.error(
        `hook-bridge: ${hookName} exited ${result.code} (non-blocking, ` +
          `after-hook only). stderr: ${(result.stderr || "").slice(-2000)}`,
      );
      return;
    }
    const text = (result.stdout || "").trim();
    if (!text) return; // No opinion -- required evidence is present, or
    // the gate is off/not in warn-or-enforce mode. Nothing to surface.
    const hso = parseGuardVerdictOutput(hookName, text);
    if (!hso) return; // Malformed JSON already logged by
    // parseGuardVerdictOutput itself; nothing further to do here.
    console.error(
      `hook-bridge: ${hookName} reported ${hso.permissionDecision ?? "(no decision)"} ` +
        "(non-blocking, after-hook only -- the task call already completed): " +
        `${hso.warning || hso.permissionDecisionReason || "(no reason given)"}`,
    );
  } catch (err) {
    console.error(
      `hook-bridge: could not run ${hookName} (non-blocking, after-hook ` +
        `only): ${err.message}`,
    );
  }
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
  //     ALSO repaired from session.updated (finding CR-OPENCODE-HOOK-
  //     BRIDGE-0001, see the session.updated handler below) when this
  //     sessionID has NO recorded entry at all -- e.g. an S1/S2-evicted
  //     session (SESSION_STATE_CAP) that later resumes. The 2026-07-25
  //     runtime spike (/tmp/ocspike2/logs/events.jsonl) confirms
  //     session.updated's info object DOES carry parentID for a child
  //     session (present on every observed session.updated for a
  //     spawned subagent session, matching that session's own
  //     session.created value; absent, like session.created's, for a
  //     top-level session) -- this is a genuine repair from real data,
  //     not a guess. This is the SAME first-write-wins policy as
  //     session.created's, just sourced from a second event type:
  //     write only when absent, retain-and-log on a later disagreement.
  //     Unlike sessionAgent's FOLLOW policy below, parentID has no
  //     legitimate reason to change for a live session, so there is no
  //     privilege-relevant reason to prefer "follow" here -- see that
  //     policy's own escalation-vector analysis for why sessionAgent is
  //     different.
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
  //
  //   CR-OPENCODE-HOOK-BRIDGE-0001 fix (code-review finding,
  //   2026-07-25): the session.updated handler now ALSO calls
  //   trackSessionAndEvictIfOverCap for the sessionID it is about to
  //   write, before writing either sessionParent or sessionAgent. Before
  //   this fix, a sessionID already evicted by SESSION_STATE_CAP (an
  //   operator resume of a long-idle session -- exactly the threat model
  //   this FOLLOW fix targets) had its sessionAgent entry silently
  //   resurrected OUTSIDE sessionInsertOrder's accounting: permanently
  //   exempt from any future eviction, since a resumed session can never
  //   re-fire session.created to re-register normally. Now a resurrected
  //   entry re-enters the SAME shared ledger session.created uses, so it
  //   is bounded exactly like every other entry -- no permanent carve-
  //   out. This does not change WHAT gets forwarded (still the current,
  //   correct agent -- the FOLLOW policy and its escalation-vector
  //   analysis above are unchanged) -- only that the write now
  //   participates in the cap's bookkeeping like session.created's does.
  //   handledIdleSessions: sessionIDs whose session.idle has already been
  //     processed FOR THE CURRENT TURN. session.idle was observed firing
  //     twice in immediate succession for the same child session in one
  //     spike run; both handoff-stop-gate.py and handoff-subagent-stop-gate.py
  //     must run at most once per turn-end. Evicted on its OWN independent,
  //     much-larger FIFO cap (HANDLED_IDLE_SESSIONS_CAP below) rather than
  //     sharing sessionInsertOrder's clock with sessionParent/sessionAgent --
  //     S2 fix, 2026-07-25, a confirmed regression introduced by the
  //     original S1 fix (commit 1368fab). See HANDLED_IDLE_SESSIONS_CAP's
  //     declaration for why.
  //
  //     CR-OPENCODE-HOOK-BRIDGE-0002 fix (code-review finding, 2026-07-25):
  //     "already processed" above is scoped to a TURN, not to the
  //     sessionID's whole process lifetime -- session.idle is this
  //     bridge's own documented Stop-equivalent, i.e. "end of THIS turn,"
  //     not "this session will never be touched again" (see the S1/S2
  //     comment block below sessionAgent's declaration). Before this fix,
  //     a sessionID's FIRST session.idle marked it handled forever (barring
  //     HANDLED_IDLE_SESSIONS_CAP-scale eviction), so a session that
  //     legitimately resumed via session.updated (the exact threat model
  //     c4bc456/1368fab/ab1d952/f054c90 collectively exist to support) and
  //     then went idle a SECOND time for a genuinely new turn had that
  //     second, legitimate lifecycle event silently dropped -- neither gate
  //     ran, and nothing distinguished it from a correctly-deduped spurious
  //     double-fire. Fix: the session.updated handler clears a sessionID's
  //     handledIdleSessions membership (see resumeHandledIdleSession below)
  //     whenever it observes an update for a sessionID ALREADY marked
  //     handled -- i.e. only when the bridge has independent, wired
  //     evidence (a live session.updated) that OpenCode is touching this
  //     session again after it was believed done. This is deliberately NOT
  //     "clear on every session.updated": the 2026-07-24 spike log
  //     (/tmp/ocspike2/logs/events.jsonl) shows session.updated firing
  //     repeatedly (4 times in ~2.5s for one session, same unchanged agent
  //     each time) DURING an active, not-yet-idle turn -- routine chatter,
  //     not resume evidence. Gating the clear on "already in
  //     handledIdleSessions" means this new code path is a no-op for every
  //     one of those routine mid-turn updates (the overwhelming common
  //     case) and only fires for the narrow, security-relevant case this
  //     finding is about. It also does not touch the immediate,
  //     within-one-turn double-fire B16/B17 guard against: that double-fire
  //     is two session.idle events back-to-back with NO session.updated
  //     between them (confirmed against the fixture corpus and the spike
  //     log), so this scoping never runs during that sequence.
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
  // Fallback: bounded FIFO eviction, on TWO SEPARATE clocks, not one --
  // this is the S2 fix (2026-07-25, a confirmed regression introduced BY
  // the original S1 fix, commit 1368fab; reproduced by
  // tests/hooks/test-opencode-hook-bridge.sh's B16/B17). S1 originally
  // put all three structures on ONE shared ledger (sessionInsertOrder,
  // keyed on session.created order) reasoning that a single ledger keeps
  // them "from drifting out of sync with each other." That reasoning is
  // still correct FOR sessionParent and sessionAgent -- they answer the
  // same question (this session's recorded identity) and must expire
  // together, so they keep sharing sessionInsertOrder below, unchanged
  // from S1.
  //
  // It was WRONG to also put handledIdleSessions on that same clock.
  // handledIdleSessions answers a different question ("has this
  // session's Stop/SubagentStop gate already run"), and evicting it in
  // lockstep with the two identity maps reintroduces the exact
  // idempotency violation session.idle dedup exists to prevent: once a
  // sessionID ages off the shared clock, a LATER session.idle for that
  // SAME sessionID is no longer deduped, so handoff-stop-gate.py /
  // handoff-subagent-stop-gate.py can re-fire (confirmed reproducible,
  // B17); and because sessionParent evicts on the identical clock, a
  // re-fired CHILD session's idle additionally MISROUTES to
  // handoff-stop-gate.py instead of handoff-subagent-stop-gate.py (B16).
  // Both gates emit FALSELY_COMPLETED / INCOMPLETE verdicts a re-fire or
  // misroute corrupts -- trading lifecycle-gate correctness for a
  // memory bound is the wrong way round for a LOW-severity, session-
  // count-bounded concern (tech-lead's disposition on this fix).
  //
  // Fix: give handledIdleSessions its OWN independent ledger
  // (handledIdleInsertOrder, declared below) and its own, much larger
  // cap (HANDLED_IDLE_SESSIONS_CAP) instead of sharing
  // sessionInsertOrder/SESSION_STATE_CAP. This is sound BECAUSE the two
  // clocks retain fundamentally different-sized payloads per entry:
  // sessionParent/sessionAgent are Maps holding a parentID string and an
  // agent-name string per session (real per-session content this bridge
  // forwards on the wire); handledIdleSessions is a Set holding only the
  // bare sessionID string that was already the Map key -- no additional
  // payload at all. Retaining a bare ID for far longer than the identity
  // maps retain their content is cheap specifically because it is
  // marginal cost on top of a string OpenCode already handed this
  // process -- see HANDLED_IDLE_SESSIONS_CAP's declaration for the
  // memory-arithmetic bound this claim rests on.
  //
  // A genuinely UNBOUNDED handledIdleSessions was considered and
  // rejected, not reflexively -- it is still a Set that would grow
  // monotonically for the life of a long-lived server process with zero
  // eviction, which is exactly the growth shape S1 was raised against,
  // and bounding it costs nothing beyond the FIFO bookkeeping this file
  // already has a working pattern for. A bound deliberately set far
  // above SESSION_STATE_CAP gets the same "practically never fires"
  // property an unbounded structure would have, without actually being
  // unbounded. See HANDLED_IDLE_SESSIONS_CAP below for the arithmetic.
  //
  // subcall-limit-guard.py's DEFAULT_SUBCALL_BUDGET (100 subagent spawns
  // per top-level session, operator-raisable via SWDT_SUBCALL_BUDGET) is
  // still the closest existing bound on how many sessions one real
  // top-level session's lifetime can plausibly produce; SESSION_STATE_CAP
  // below is two orders of magnitude above that default, unchanged from
  // the original S1 fix -- at that point evicting the single
  // oldest-first-seen sessionParent/sessionAgent entry (by far the most
  // likely to be long finished) and logging it is the reasonable trade
  // for this low-severity issue. This does NOT eliminate the theoretical
  // risk of evicting a still-live session's identity on a sufficiently
  // long-lived/high-volume process; it bounds how implausible that has
  // to be before it can happen, and logs loudly if it ever does.
  const SESSION_STATE_CAP = 10000;
  const sessionInsertOrder = new Set(); // Insertion-ordered ledger of
  // every sessionID seen via session.created in this process; used only
  // to pick FIFO eviction order for sessionParent/sessionAgent below --
  // NOT handledIdleSessions, which has its own separate ledger (see
  // HANDLED_IDLE_SESSIONS_CAP just below). A JS Set iterates in
  // insertion order, so `.values().next().value` is always the oldest
  // entry.

  // handledIdleSessions' OWN cap, deliberately decoupled from
  // SESSION_STATE_CAP above -- S2 fix, see the "Fallback" discussion in
  // the S1/S2 comment block above sessionInsertOrder's declaration for
  // the full reasoning. Set to 100,000: one order of magnitude above
  // SESSION_STATE_CAP (10,000), itself two orders of magnitude above
  // subcall-limit-guard.py's DEFAULT_SUBCALL_BUDGET (100) -- three
  // orders of magnitude above the closest existing per-top-level-session
  // bound in this codebase. Chosen so that in any realistic-but-extreme
  // run, sessionParent/sessionAgent will always have already evicted
  // (and safely degraded to caller_role = None) a given old sessionID
  // LONG before handledIdleSessions would forget it -- which is exactly
  // what closes the B16/B17 regression: a genuine near-term duplicate
  // session.idle (the ADR's documented double-fire spike finding,
  // observed seconds apart in one spike run, not tens of thousands of
  // sessions apart) always finds its sessionID still present here.
  //
  // Memory arithmetic (worst case, cap fully populated): OpenCode
  // session IDs are short ASCII tokens (observed shape: `ses_<xid>`,
  // well under 40 characters); V8 stores an ASCII JS string as a
  // one-byte SeqOneByteString, roughly 16 bytes of object header plus 1
  // byte/char, so ~56 bytes for a 40-char ID. A JS Set's backing
  // OrderedHashSet adds roughly one more hash-bucket/iteration-order
  // slot per entry -- a commonly used working estimate for Set<primitive>
  // overhead is ~48-56 bytes/entry beyond the value itself. Rounding
  // both up generously: ~150 bytes/entry all-in. At the 100,000 cap:
  // 100,000 x 150 bytes = 15,000,000 bytes ~= 14.3 MiB worst case -- and
  // that ceiling is only reached after the process has taken 100,000
  // distinct sessions through session.idle, ten times the
  // already-implausible bar SESSION_STATE_CAP sets. Trivial and bounded;
  // not "unbounded, just with extra steps."
  const HANDLED_IDLE_SESSIONS_CAP = 100_000;
  const handledIdleInsertOrder = new Set(); // Insertion-ordered ledger
  // scoped ONLY to handledIdleSessions -- intentionally separate from
  // sessionInsertOrder above; see this constant's comment for why
  // sharing one ledger across all three structures (the original S1
  // shape) was the bug.

  // Called from BOTH the session.created handler (original S1 fix) AND
  // the session.updated handler (CR-OPENCODE-HOOK-BRIDGE-0001 fix, see
  // the sessionParent/sessionAgent declaration comment above) -- same
  // idempotent has()-guarded shape either way, so calling it from a
  // second event type that may fire for an already-tracked sessionID is
  // a cheap no-op, and calling it for an evicted-and-now-resurrected
  // sessionID re-enters that sessionID into the ledger at its current
  // (newest) position, same as if it were being tracked for the first
  // time.
  function trackSessionAndEvictIfOverCap(sessionID) {
    if (sessionInsertOrder.has(sessionID)) return;
    sessionInsertOrder.add(sessionID);
    if (sessionInsertOrder.size <= SESSION_STATE_CAP) return;

    const oldest = sessionInsertOrder.values().next().value;
    sessionInsertOrder.delete(oldest);
    sessionParent.delete(oldest);
    sessionAgent.delete(oldest);
    console.error(
      `hook-bridge: session-state cap (${SESSION_STATE_CAP} distinct ` +
        `sessions) exceeded; evicted oldest-tracked session '${oldest}' ` +
        "from sessionParent/sessionAgent (handledIdleSessions is on its " +
        "own separate, larger cap -- see HANDLED_IDLE_SESSIONS_CAP above " +
        "-- and is NOT evicted here). If that session is somehow still " +
        "live, its next guarded tool call will resolve caller_role = " +
        "None (fail-safe, but a functional regression). This should " +
        "only occur for a process that has served an implausible number " +
        "of distinct sessions -- see the S1/S2 bounded-eviction comment " +
        "above sessionInsertOrder's declaration.",
    );
  }

  // handledIdleSessions' own eviction, on handledIdleInsertOrder's
  // independent clock -- S2 fix. Called from the session.idle handler
  // right after a sessionID is newly added to handledIdleSessions;
  // mirrors trackSessionAndEvictIfOverCap's shape exactly, just scoped
  // to one Set instead of two Maps, and to HANDLED_IDLE_SESSIONS_CAP
  // instead of SESSION_STATE_CAP.
  function trackHandledIdleAndEvictIfOverCap(sessionID) {
    if (handledIdleInsertOrder.has(sessionID)) return;
    handledIdleInsertOrder.add(sessionID);
    if (handledIdleInsertOrder.size <= HANDLED_IDLE_SESSIONS_CAP) return;

    const oldest = handledIdleInsertOrder.values().next().value;
    handledIdleInsertOrder.delete(oldest);
    handledIdleSessions.delete(oldest);
    console.error(
      `hook-bridge: handled-idle-session cap (${HANDLED_IDLE_SESSIONS_CAP} ` +
        "distinct sessions) exceeded; evicted oldest-tracked session " +
        `'${oldest}' from handledIdleSessions. A LATER session.idle for ` +
        "that sessionID, if one somehow still arrives, would no longer " +
        "be deduped and could re-run its Stop/SubagentStop gate. This " +
        `should only occur for a process that has taken ` +
        `${HANDLED_IDLE_SESSIONS_CAP} distinct sessions through ` +
        "session.idle -- ten times the already-implausible bar " +
        "SESSION_STATE_CAP sets -- see this function's declaration " +
        "comment.",
    );
  }

  // CR-OPENCODE-HOOK-BRIDGE-0002 fix (code-review finding, 2026-07-25):
  // called from the session.updated handler, unconditionally, for every
  // session.updated with a resolvable sessionID -- same "always run,
  // cheap no-op in the common case" shape as trackSessionAndEvictIfOverCap
  // and the sessionParent repair it sits alongside. Scopes
  // handledIdleSessions' dedup to a TURN rather than to the sessionID's
  // whole process lifetime: see handledIdleSessions' own declaration
  // comment (top of this factory) for the full reasoning on why this is
  // gated on "already marked handled" rather than firing on every
  // session.updated.
  function resumeHandledIdleSession(sessionID) {
    if (!handledIdleSessions.has(sessionID)) return; // The common case --
    // this sessionID has not gone idle yet this process, or has already
    // been resumed once (see below); nothing to clear. Deliberately not
    // logged: logging every no-op call here would fire on the routine,
    // frequent session.updated traffic the 2026-07-24 spike log shows
    // arriving many times per turn, drowning the signal this function
    // exists to surface.
    handledIdleSessions.delete(sessionID);
    handledIdleInsertOrder.delete(sessionID);
    console.error(
      `hook-bridge: session '${sessionID}' received session.updated after ` +
        "its session.idle had already been handled -- treating this as a " +
        "legitimate resume (a genuinely new turn beginning) and clearing " +
        "its handledIdleSessions entry, so this session's NEXT session.idle " +
        "runs its Stop/SubagentStop gate again instead of being silently " +
        "deduped as a stale repeat. See CR-OPENCODE-HOOK-BRIDGE-0002.",
    );
  }

  // -----------------------------------------------------------------
  // event sub-handlers -- one per OpenCode event type the `event` hook
  // below dispatches to (session.created / session.updated /
  // session.idle). Split out of a single branch-per-`if` function (CCN
  // 31, 119 NLOC -- a Lizard/Codacy complexity finding) into named
  // per-event functions with NO BEHAVIOR CHANGE: each function's body is
  // exactly the code that used to live inside its `if (event.type ===
  // ...)` branch, including every early return and every console.error,
  // moved verbatim. They are declared here (inside the HookBridge
  // factory, same scope as `return {` below) specifically so they keep
  // closing over the SAME per-process sessionParent / sessionAgent /
  // handledIdleSessions state and the SAME eviction helpers
  // (trackSessionAndEvictIfOverCap, trackHandledIdleAndEvictIfOverCap,
  // resumeHandledIdleSession) declared just above -- splitting them out
  // to module scope would require threading that state through function
  // parameters and change nothing about behavior for real complexity.
  // -----------------------------------------------------------------

  // First-write-wins for sessionParent (finding H-1(b), half 1 of 2).
  // session.created re-firing for a sessionID already recorded (an
  // in-session agent switch, a resume, a re-attach -- whether OpenCode
  // actually does this is being spiked separately, but the fix does not
  // depend on the answer) must NOT silently change what this bridge
  // forwards: sessionParent drives Stop-vs-SubagentStop routing at
  // session.idle, and an overwrite here would silently flip which
  // lifecycle gate a session's idle event resolves to. Retain-and-log,
  // do not throw: this is an event handler, not a gate, and an uncaught
  // throw here has no defined abort semantics (see
  // runLifecycleGateHook's identical reasoning for session.idle). Split
  // out of handleSessionCreated (below) to keep that function's CCN
  // down; behavior is unchanged from the original inline block.
  function applySessionParentFirstWrite(sessionID, incomingParentID) {
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
      return;
    }
    sessionParent.set(sessionID, incomingParentID);
  }

  // First-write-wins for sessionAgent (finding H-1(b), half 2 of 2).
  // sessionAgent is what reaches guard payloads as `agent_type`, and
  // tech-lead-authoring-guard.py grants an unconditional write bypass
  // once any validated non-tech-lead role is present -- an overwrite
  // here would silently change the guard-visible role mid-conversation
  // with no re-dispatch through tech-lead. Same retain-and-log posture,
  // and same CCN-reduction motive, as applySessionParentFirstWrite
  // above. Only called when `agent` is truthy (see call site).
  function applySessionAgentFirstWrite(sessionID, agent) {
    if (sessionAgent.has(sessionID)) {
      const retainedAgent = sessionAgent.get(sessionID);
      if (agent !== retainedAgent) {
        console.error(
          `hook-bridge: session.created re-fired for session ` +
            `'${sessionID}' with a different agent ('${agent}' ` +
            `vs retained '${retainedAgent}'). Retaining the first-` +
            "recorded role; tech-lead-authoring-guard.py's write " +
            "bypass must not change mid-session without re-dispatch " +
            "through tech-lead.",
        );
      }
      return;
    }
    sessionAgent.set(sessionID, agent);
  }

  // Shared `{ info, sessionID }` extraction for session.created and
  // session.updated (both carry the same event.properties.info /
  // event.properties.sessionID shape; session.idle does not, and reads
  // its own sessionID directly). info defaults to {} and sessionID
  // falls back to info.id -- unchanged from the original inline
  // extraction in each branch, just deduplicated into one place so the
  // null-safety operators (`?.`, `??`) are only counted once by Lizard's
  // CCN instead of once per caller.
  function extractSessionInfo(event) {
    const info = event.properties?.info ?? {};
    const sessionID = event.properties?.sessionID ?? info.id;
    return { info, sessionID };
  }

  // session.created: SessionStart-equivalent. First-write-wins for both
  // sessionParent and sessionAgent (finding H-1(b), implemented by
  // applySessionParentFirstWrite / applySessionAgentFirstWrite above) --
  // see the declaration comments above sessionParent/sessionAgent (top
  // of this factory) for the full "why first-write-wins here but FOLLOW
  // in session.updated" analysis.
  async function handleSessionCreated(event) {
    const { info, sessionID } = extractSessionInfo(event);
    if (!sessionID) return;

    // S1/S2 bounded eviction: record this sessionID's first-seen
    // order and evict the oldest tracked sessionParent/sessionAgent
    // entry if SESSION_STATE_CAP is exceeded (handledIdleSessions is
    // evicted separately, on its own clock -- see
    // trackHandledIdleAndEvictIfOverCap). Must run before the
    // first-write-wins population below so a freshly-evicted-then-
    // immediately-reused sessionID (implausible, but the cap's
    // whole premise is "implausible things become possible at
    // extreme scale") is tracked fresh rather than silently
    // skipped as "already seen".
    trackSessionAndEvictIfOverCap(sessionID);

    applySessionParentFirstWrite(sessionID, info.parentID ?? null);
    if (info.agent) {
      applySessionAgentFirstWrite(sessionID, info.agent);
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
  }

  // sessionParent repair for session.updated (CR-OPENCODE-HOOK-BRIDGE-0001,
  // code-review finding, 2026-07-25). The 2026-07-25 runtime spike
  // (/tmp/ocspike2/logs/events.jsonl) confirms session.updated's info
  // object DOES carry parentID for a child session -- present on every
  // observed session.updated for a spawned subagent session, matching
  // that session's own session.created value; absent, like
  // session.created's, for a top-level session. Repair (write) ONLY
  // when this sessionID has NO sessionParent entry at all -- an
  // S1-evicted session, or one this process never saw session.created
  // for. This is what closes the actual misrouting half of the finding:
  // without it, an evicted session's first-ever session.idle after a
  // legitimate resume misroutes to handoff-stop-gate.py instead of
  // handoff-subagent-stop-gate.py, even though this very session.updated
  // just proved the session alive and handed this bridge its parentID
  // again. Retain-and-log (do not overwrite) when an entry already
  // exists -- same first-write-wins policy as session.created's, since
  // parentID has no legitimate reason to change for a live session and
  // there is no privilege-escalation reason (unlike sessionAgent) to
  // prefer "follow" here. Split out of handleSessionUpdated (below) to
  // keep that function's CCN down; behavior is unchanged from the
  // original inline block.
  function repairSessionParentIfMissing(sessionID, incomingParentID) {
    if (!sessionParent.has(sessionID)) {
      sessionParent.set(sessionID, incomingParentID);
      console.error(
        `hook-bridge: session.updated repaired sessionParent for ` +
          `session '${sessionID}' (parentID='${incomingParentID}') ` +
          "-- this sessionID had no recorded sessionParent entry, " +
          "either because SESSION_STATE_CAP evicted it and this " +
          "session has now resumed, or because this process never " +
          "observed a session.created for it. Without this repair, " +
          "this session's next session.idle would misroute to " +
          "handoff-stop-gate.py instead of handoff-subagent-stop-" +
          "gate.py (or vice versa), despite this session.updated " +
          "just proving the session alive. See " +
          "CR-OPENCODE-HOOK-BRIDGE-0001.",
      );
      return;
    }
    const retainedParentID = sessionParent.get(sessionID);
    if (incomingParentID !== retainedParentID) {
      console.error(
        `hook-bridge: session.updated observed session ` +
          `'${sessionID}' with a different parentID ` +
          `('${incomingParentID}' vs retained '${retainedParentID}'). ` +
          "Retaining the recorded parent -- parentID should not " +
          "change for a live session; same first-write-wins " +
          "reasoning as session.created's identical check above.",
      );
    }
  }

  // session.updated: agent-identity tracking (HIGH-severity
  // privilege-escalation fix) plus sessionParent/handledIdleSessions
  // repair (via repairSessionParentIfMissing above) for resumed
  // sessions. See the sessionAgent declaration comment (top of this
  // factory, above sessionParent's own declaration) for the full
  // FOLLOW-vs-RETAIN policy analysis this function implements.
  async function handleSessionUpdated(event) {
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
    // session.created's first-write-wins policy above.
    // See the sessionAgent declaration comment (top of this
    // factory) for the full "why the same map has two different
    // update policies" reasoning and the escalation-vector analysis
    // for why following the change cannot itself widen access.
    const { info, sessionID } = extractSessionInfo(event);
    if (!sessionID) return;

    // CR-OPENCODE-HOOK-BRIDGE-0001 fix (code-review finding,
    // 2026-07-25) and CR-OPENCODE-HOOK-BRIDGE-0002 fix (code-review
    // finding, 2026-07-25): ledger accounting, sessionParent repair,
    // and handledIdleSessions turn-scoping, ALL run unconditionally
    // for every session.updated with a resolvable sessionID --
    // independent of whether this particular update carries
    // info.agent -- before the agent-follow logic below. Three
    // distinct sub-fixes, kept together because each closes a
    // finding about the same underlying gap (state that stops being
    // maintained once a session goes quiet, even though the session
    // itself is still live):
    //
    // (1) Ledger accounting. Any write this handler is about to make
    //     (sessionParent repair just below, or sessionAgent's FOLLOW
    //     write further down) must re-enter sessionInsertOrder's
    //     ledger, the SAME ledger session.created uses. Without
    //     this, a sessionID already evicted by SESSION_STATE_CAP
    //     (S1) that resumes via session.updated gets its state
    //     silently resurrected OUTSIDE the ledger's accounting --
    //     permanently exempt from any future eviction, since a
    //     resumed session can never re-fire session.created to
    //     re-register normally. Idempotent (see
    //     trackSessionAndEvictIfOverCap's own comment): a no-op for
    //     a sessionID already tracked.
    //
    // (2) sessionParent repair. The 2026-07-25 runtime spike
    //     (/tmp/ocspike2/logs/events.jsonl) confirms session.updated's
    //     info object DOES carry parentID for a child session --
    //     present on every observed session.updated for a spawned
    //     subagent session, matching that session's own
    //     session.created value; absent, like session.created's, for
    //     a top-level session. Repair (write) ONLY when this
    //     sessionID has NO sessionParent entry at all -- an
    //     S1-evicted session, or one this process never saw
    //     session.created for. This is what closes the actual
    //     misrouting half of the finding: without it, an evicted
    //     session's first-ever session.idle after a legitimate
    //     resume misroutes to handoff-stop-gate.py instead of
    //     handoff-subagent-stop-gate.py, even though this very
    //     session.updated just proved the session alive and handed
    //     this bridge its parentID again. Retain-and-log (do not
    //     overwrite) when an entry already exists -- same
    //     first-write-wins policy as session.created's, since
    //     parentID has no legitimate reason to change for a live
    //     session and there is no privilege-escalation reason (unlike
    //     sessionAgent) to prefer "follow" here.
    //
    // (3) handledIdleSessions turn-scoping (CR-OPENCODE-HOOK-BRIDGE-0002).
    //     If this sessionID is already marked handled (its session.idle
    //     already ran the Stop/SubagentStop gate once), this
    //     session.updated is itself the bridge's only wired evidence
    //     that OpenCode is touching the session again -- i.e. a new
    //     turn has begun -- so the stale mark is cleared and the
    //     session's next session.idle is treated as a new turn-end,
    //     not a stale duplicate. No-op for the overwhelming common
    //     case (a session.updated for a session that has not gone
    //     idle yet this process). See resumeHandledIdleSession's own
    //     declaration comment and handledIdleSessions' declaration
    //     comment for the full reasoning and the spike-log evidence
    //     this scoping choice rests on.
    trackSessionAndEvictIfOverCap(sessionID);
    resumeHandledIdleSession(sessionID);
    repairSessionParentIfMissing(sessionID, info.parentID ?? null);

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
  }

  // session.idle: Stop / SubagentStop-equivalent, routed by whether
  // sessionParent recorded a parentID for this sessionID (at
  // session.created or session.updated-repair time).
  async function handleSessionIdle(event) {
    const sessionID = event.properties?.sessionID;
    if (!sessionID) return;
    if (handledIdleSessions.has(sessionID)) {
      // Idempotency: session.idle was observed firing twice in
      // immediate succession for one child session in the runtime
      // spike; run the Stop-equivalent gate at most once per turn.
      // CR-OPENCODE-HOOK-BRIDGE-0002 (code-review finding,
      // 2026-07-25): this suppression used to be completely silent --
      // "silence is the failure mode this whole port has repeatedly
      // been bitten by" -- so it is logged even though it is the
      // EXPECTED, correct outcome for a genuine duplicate. A
      // legitimate resumed session's later session.idle does NOT
      // reach this branch: resumeHandledIdleSession (called from the
      // session.updated handler) clears handledIdleSessions'
      // membership as soon as a session.updated is observed for an
      // already-handled sessionID, so this line firing for a given
      // sessionID means no session.updated was observed for it
      // between its two session.idle events -- the near-simultaneous
      // double-fire case, not a resume.
      console.error(
        `hook-bridge: session.idle suppressed as a duplicate for ` +
          `session '${sessionID}' -- its Stop/SubagentStop gate has ` +
          "already run and no intervening session.updated was " +
          "observed to indicate a new turn. Expected for the known " +
          "near-simultaneous double-fire case; see CR-OPENCODE-HOOK-" +
          "BRIDGE-0002 if this fires for a case that should have been " +
          "treated as a new turn.",
      );
      return;
    }
    handledIdleSessions.add(sessionID);
    trackHandledIdleAndEvictIfOverCap(sessionID); // S2 fix: bound
    // handledIdleSessions on its OWN independent, much larger cap --
    // see HANDLED_IDLE_SESSIONS_CAP's declaration comment.

    const parentID = sessionParent.get(sessionID);
    const hookName = parentID
      ? "handoff-subagent-stop-gate.py"
      : "handoff-stop-gate.py";
    await runLifecycleGateHook(hookName, projectDir);
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

      if (toolId === "task") {
        // TaskCompleted-equivalent -- fires as its own dedicated call
        // (not through GUARD_CHAIN_BY_TOOL) alongside the
        // handoff-record-activity.py call above, which runs for every
        // tool id. See runTaskCompletedGate's own declaration comment
        // for the payload shape, the never-fail-closed posture, and why
        // this needs no session-scoped dedup the way session.idle's
        // handledIdleSessions does.
        await runTaskCompletedGate(projectDir);
      }
    },

    // -------------------------------------------------------------
    // event: session.created (SessionStart-equivalent), session.updated
    // (agent-identity tracking -- HIGH-severity privilege-escalation
    // fix, see the sessionAgent declaration comment above for the
    // follow-vs-retain asymmetry with session.created), and session.idle
    // (Stop / SubagentStop-equivalent, distinguished by parentID
    // recorded at session.created time). Dispatches to one named helper
    // per event type -- handleSessionCreated / handleSessionUpdated /
    // handleSessionIdle, declared above in this same factory scope --
    // extracted from a single branch-per-`if` function (CCN 31, 119
    // NLOC, a Lizard/Codacy complexity finding) with NO BEHAVIOR CHANGE:
    // see each helper's own declaration comment.
    // -------------------------------------------------------------
    event: async ({ event }) => {
      if (event.type === "session.created") {
        await handleSessionCreated(event);
        return;
      }
      if (event.type === "session.updated") {
        await handleSessionUpdated(event);
        return;
      }
      if (event.type === "session.idle") {
        await handleSessionIdle(event);
      }
    },

    // -------------------------------------------------------------
    // experimental.session.compacting: near-exact structural match for
    // the Claude Code SessionStart(matcher: compact) hook. Runs
    // post-compact-refresh.sh and appends its banner text to
    // output.context so the directive reaches the session the same way
    // Claude Code's SessionStart(compact) stdout does.
    // -------------------------------------------------------------
    "experimental.session.compacting": async (_compactInput, output) => {
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
// Run one entry of runSessionStartSet's script list (below) and log its
// outcome. Split out of runSessionStartSet's loop body so the four
// scripts can run CONCURRENTLY via Promise.all instead of one `await`
// per loop iteration (Biome noAwaitInLoops finding) -- unlike the
// PreToolUse guard chain (tool.execute.before, above), which MUST stay
// sequential for first-deny-wins ordering, these four session-start
// scripts have no such invariant: three are independent informational
// banners and the fourth (subcall-limit-reset.py) writes only its own
// dedicated budget file, which none of the other three touch. No test
// in this suite asserts on their relative ordering (child sessions
// never reach this function at all -- see the `if (info.parentID)
// return;` early-out in handleSessionCreated above -- and every
// top-level-session scenario here only asserts session-start's total
// EFFECT, never inter-script order). Behavior per script (missing-file
// skip, stdout/stderr logging, spawn-failure logging) is otherwise
// unchanged from the original sequential loop body.
// version-check.sh lives at scripts/version-check.sh, not scripts/hooks/
// -- special-case its path to match .claude/settings.json's wiring.
// Split out of runOneSessionStartScript purely to keep that function's
// CCN down; same resolution, unchanged.
function resolveSessionStartScriptPath(name, projectDir) {
  if (name === "version-check.sh") {
    return path.join(projectDir, "scripts", name);
  }
  return path.join(projectDir, "scripts", "hooks", name);
}

// Spawn one session-start script per its `kind` (shell script executed
// directly, or a Python script run via `python3`). Split out of
// runOneSessionStartScript purely to keep that function's CCN down;
// same two spawn shapes, unchanged.
function spawnSessionStartScript(kind, resolvedPath, timeoutMs, projectDir) {
  const env = { ...process.env, CLAUDE_PROJECT_DIR: projectDir };
  if (kind === "sh") {
    return runSubprocess(resolvedPath, [], { cwd: projectDir, env, timeoutMs });
  }
  return runSubprocess("python3", [resolvedPath], { cwd: projectDir, env, timeoutMs });
}

async function runOneSessionStartScript({ name, kind, timeoutMs }, projectDir) {
  const resolvedPath = resolveSessionStartScriptPath(name, projectDir);

  try {
    accessSync(resolvedPath, kind === "sh" ? fsConstants.X_OK : fsConstants.R_OK);
  } catch {
    // SessionStart set is informational/best-effort (matches
    // .claude/settings.json's own `[ -x ... ] && ... || true` guards
    // for the three shell reminders). A missing script is silently
    // skipped, not fail-closed -- these are reminders, not guards.
    return;
  }

  try {
    const result = await spawnSessionStartScript(kind, resolvedPath, timeoutMs, projectDir);
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

  await Promise.all(scripts.map((script) => runOneSessionStartScript(script, projectDir)));
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
