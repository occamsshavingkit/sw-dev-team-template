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

    child.stdout.on("data", (chunk) => {
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
    // call, not the bridge's to escalate.
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
  //     spike) decide Stop-vs-SubagentStop semantics.
  //   sessionAgent: sessionID -> OpenCode `agent` name (e.g.
  //     "software-engineer") captured from session.created's info.agent.
  //     Forwarded as `agent_type` in guard payloads so
  //     tech-lead-authoring-guard.py can resolve caller_role the same
  //     way it does from Claude Code's hook payload (see
  //     buildGuardPayload's docstring). The main/top-level session's
  //     agent is a mode name (e.g. "build"), not a canonical role, and
  //     correctly fails `_validate_role()` -- no special-casing needed.
  //   handledIdleSessions: sessionIDs whose session.idle has already been
  //     processed. session.idle was observed firing twice for the same
  //     child session in one spike run; both handoff-stop-gate.py and
  //     handoff-subagent-stop-gate.py must run at most once per session.
  const sessionParent = new Map();
  const sessionAgent = new Map();
  const handledIdleSessions = new Set();

  return {
    // -------------------------------------------------------------
    // tool.execute.before: PreToolUse-equivalent guard chain.
    // -------------------------------------------------------------
    "tool.execute.before": async (beforeInput, output) => {
      const toolId = beforeInput.tool;
      const chain = GUARD_CHAIN_BY_TOOL[toolId];
      if (!chain) return; // Not a guarded OpenCode tool.

      if (!TOOL_ARG_MAP) {
        // Bridge-infrastructure absence: the mapping table itself failed
        // to load. Fail closed on every guarded call rather than run
        // silently unenforced for the rest of the session.
        throw new Error(
          "hook-bridge: scripts/opencode/tool-arg-map.json failed to load " +
            `(${TOOL_ARG_MAP_LOAD_ERROR?.message ?? "unknown error"}). ` +
            "Refusing to proceed on a guarded tool call.",
        );
      }

      const payload = buildGuardPayload(
        toolId,
        output.args,
        sessionAgent.get(beforeInput.sessionID),
      );
      if (!payload) return; // No mapping entry for this tool id.

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
    // event: session.created (SessionStart-equivalent) and
    // session.idle (Stop / SubagentStop-equivalent, distinguished by
    // parentID recorded at session.created time).
    // -------------------------------------------------------------
    event: async ({ event }) => {
      if (event.type === "session.created") {
        const info = event.properties?.info ?? {};
        const sessionID = event.properties?.sessionID ?? info.id;
        if (!sessionID) return;
        sessionParent.set(sessionID, info.parentID ?? null);
        if (info.agent) sessionAgent.set(sessionID, info.agent);

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
