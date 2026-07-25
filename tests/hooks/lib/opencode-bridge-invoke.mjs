#!/usr/bin/env node
// SPDX-License-Identifier: MIT
// Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
//
// tests/hooks/lib/opencode-bridge-invoke.mjs — best-effort live invoker
// for .opencode/plugin/hook-bridge.js (fw-adr-0031-opencode-hook-bridge.md).
//
// This is NOT a live OpenCode session. It dynamically imports the plugin
// module, constructs ONE Hooks instance (the same object a real OpenCode
// process would hold for the process's lifetime), and replays a SCRIPT of
// steps against it in order -- so per-session state the bridge keeps in
// closure (sessionParent / sessionAgent / handledIdleSessions Maps/Sets)
// behaves the same way it would across a real session's event sequence.
// This matters concretely: agent_type only reaches tool.execute.before
// after a prior session.created event populated sessionAgent for that
// sessionID, and idempotency (a session.idle firing twice for one
// sessionID) can only be observed across two steps against the SAME
// instance.
//
// EXPORT-SHAPE: this harness imports the module and calls the named
// export `HookBridge` (confirmed present in .opencode/plugin/hook-bridge.js
// at test-authoring time). Falls back to `hookBridge`, `default`, then the
// first function-typed export, so the harness keeps working if the export
// name is ever renamed.
//
// Usage:
//   node opencode-bridge-invoke.mjs run <plugin-path> < steps.json
//
// steps.json is a JSON array of step objects. Recognised `kind`s:
//   {"kind":"event", "event": {...}}
//     -> await hooks.event({event})
//   {"kind":"tool-before", "tool": "write", "sessionID": "s1", "args": {...}}
//     -> await hooks["tool.execute.before"]({tool, sessionID, callID}, {args})
//   {"kind":"tool-after", "tool": "write", "sessionID": "s1", "args": {...}}
//     -> await hooks["tool.execute.after"]({tool, sessionID, callID, args})
//   {"kind":"compacting", "sessionID": "s1"}
//     -> await hooks["experimental.session.compacting"]({sessionID}, output)
//
// Prints one JSON line to stdout PER STEP (not a single array), in order,
// each shaped:
//   tool-before/compacting : {"verdict":"proceed"|"throw"|"no-hook","message":str|null}
//   event                  : {"verdict":"handled"|"handled-threw"|"no-event-hook","message":str|null}
//   tool-after              : {"verdict":"handled","message":null}
//
// Exit codes:
//   0  ran to completion (individual steps may still report "throw")
//   2  argument or steps-JSON error
//   3  plugin file not found (skip — pre-implementation run)
//   4  plugin loaded but no recognisable Plugin-shaped export found (skip —
//      export-shape mismatch against this harness's assumption)
//   5  plugin threw while being constructed (its top-level Plugin(input) call)

import { existsSync, readFileSync } from "node:fs";
import { pathToFileURL } from "node:url";
import path from "node:path";

function fail(code, message) {
  process.stderr.write(`opencode-bridge-invoke: ${message}\n`);
  process.exit(code);
}

// Export names this harness will accept, in priority order (see the
// EXPORT-SHAPE header comment above). Shared between resolvePluginFunction
// and its own not-found error message so the two cannot drift apart.
const PLUGIN_EXPORT_CANDIDATES = ["HookBridge", "hookBridge", "default"];

// Find the plugin factory function on the imported module: try the
// named candidates first, then fall back to the first function-typed
// export. Split out of loadHooks (below) purely to keep that function's
// CCN down; behavior (including the "first function-typed export"
// fallback) is unchanged.
function resolvePluginFunction(mod) {
  for (const name of PLUGIN_EXPORT_CANDIDATES) {
    if (typeof mod[name] === "function") {
      return mod[name];
    }
  }
  for (const value of Object.values(mod)) {
    if (typeof value === "function") {
      return value;
    }
  }
  return null;
}

async function loadHooks(pluginPath, repoRoot) {
  if (!existsSync(pluginPath)) {
    fail(3, `plugin file not found: ${pluginPath} (SKIP — pre-implementation run)`);
  }
  let mod;
  try {
    mod = await import(pathToFileURL(path.resolve(pluginPath)).href);
  } catch (err) {
    fail(5, `failed to import plugin module: ${err?.stack ? err.stack : err}`);
  }

  const pluginFn = resolvePluginFunction(mod);
  if (!pluginFn) {
    fail(
      4,
      "plugin module loaded but no function-typed export found " +
        `(tried ${PLUGIN_EXPORT_CANDIDATES.join(", ")}, then all exports). SHAPE ` +
        "MISMATCH — update tests/hooks/lib/opencode-bridge-invoke.mjs's candidate " +
        "list or hook-bridge.js's export name."
    );
  }

  const pluginInput = {
    directory: repoRoot,
    worktree: repoRoot,
    project: { id: "test-project" },
    client: {},
    experimental_workspace: { register() {} },
    serverUrl: new URL("http://127.0.0.1:0"),
    $: async () => ({ stdout: "", stderr: "", exitCode: 0 }),
  };

  let hooks;
  try {
    hooks = await pluginFn(pluginInput);
  } catch (err) {
    fail(5, `plugin constructor threw: ${err?.stack ? err.stack : err}`);
  }
  return hooks;
}

let _callCounter = 0;
function nextCallID() {
  _callCounter += 1;
  return `test-call-${_callCounter}`;
}

// One runner per step.kind (see the "Recognised `kind`s" header comment
// above for each shape's contract). Split out of runStep (below) from a
// single 32-CCN/64-line branch-per-kind function (Lizard/Codacy
// complexity finding) into STEP_RUNNERS plus one small function per
// kind, with NO BEHAVIOR CHANGE: each runner's body is exactly the code
// that used to live inside its `if (step.kind === ...)` branch.

async function runEventStep(hooks, step) {
  const hookFn = hooks?.event;
  if (typeof hookFn !== "function") {
    return { verdict: "no-event-hook", message: null };
  }
  try {
    await hookFn({ event: step.event });
    return { verdict: "handled", message: null };
  } catch (err) {
    return { verdict: "handled-threw", message: err?.message ? err.message : String(err) };
  }
}

async function runToolBeforeStep(hooks, step) {
  const hookFn = hooks?.["tool.execute.before"];
  if (typeof hookFn !== "function") {
    return { verdict: "no-hook", message: null };
  }
  const inputMeta = {
    tool: step.tool,
    sessionID: step.sessionID || "test-session",
    callID: step.callID || nextCallID(),
  };
  const output = { args: step.args || {} };
  try {
    await hookFn(inputMeta, output);
    return { verdict: "proceed", message: null, args: output.args };
  } catch (err) {
    return { verdict: "throw", message: err?.message ? err.message : String(err) };
  }
}

async function runToolAfterStep(hooks, step) {
  const hookFn = hooks?.["tool.execute.after"];
  if (typeof hookFn !== "function") {
    return { verdict: "no-hook", message: null };
  }
  const inputMeta = {
    tool: step.tool,
    sessionID: step.sessionID || "test-session",
    callID: step.callID || nextCallID(),
    args: step.args || {},
  };
  try {
    await hookFn(inputMeta);
    return { verdict: "handled", message: null };
  } catch (err) {
    return { verdict: "handled-threw", message: err?.message ? err.message : String(err) };
  }
}

async function runCompactingStep(hooks, step) {
  const hookFn = hooks?.["experimental.session.compacting"];
  if (typeof hookFn !== "function") {
    return { verdict: "no-hook", message: null };
  }
  const output = { context: [] };
  try {
    await hookFn({ sessionID: step.sessionID || "test-session" }, output);
    return { verdict: "handled", message: null, context: output.context };
  } catch (err) {
    return { verdict: "handled-threw", message: err?.message ? err.message : String(err) };
  }
}

// Map, not a plain object: step.kind is data read straight off the
// steps-script JSON, and Map#get has no prototype-chain semantics --
// a step.kind of "constructor" or "__proto__" simply misses, the same
// as any other unrecognised kind, rather than resolving to something
// off Object.prototype (Opengrep
// javascript.lang.security.audit.unsafe-dynamic-method).
const STEP_RUNNERS = new Map([
  ["event", runEventStep],
  ["tool-before", runToolBeforeStep],
  ["tool-after", runToolAfterStep],
  ["compacting", runCompactingStep],
]);

async function runStep(hooks, step) {
  const runner = STEP_RUNNERS.get(step.kind);
  if (!runner) {
    return { verdict: "unknown-step-kind", message: `unrecognised step.kind: ${step.kind}` };
  }
  return runner(hooks, step);
}

async function main() {
  const [, , cmd, pluginPath] = process.argv;
  // OPENCODE_BRIDGE_TEST_DIRECTORY overrides the PluginInput.directory /
  // .worktree passed to HookBridge (default: the real repo root). Used by
  // tests/hooks/test-opencode-hook-bridge.sh's "hook script absent"
  // fail-closed scenario: point the bridge at a scratch directory tree
  // that has no scripts/hooks/<name>.py at all, without touching the
  // real repo's scripts/ tree (out of qa-engineer's scope here).
  const repoRoot =
    process.env.OPENCODE_BRIDGE_TEST_DIRECTORY ||
    path.resolve(path.dirname(new URL(import.meta.url).pathname), "..", "..", "..");
  if (cmd !== "run" || !pluginPath) {
    fail(2, "usage: opencode-bridge-invoke.mjs run <plugin-path> < steps.json");
  }

  let steps;
  try {
    const stdinText = readFileSync(0, "utf8");
    steps = JSON.parse(stdinText);
  } catch (err) {
    fail(2, `could not read/parse steps JSON from stdin: ${err.message}`);
  }
  if (!Array.isArray(steps)) {
    fail(2, "steps JSON must be an array");
  }

  const hooks = await loadHooks(pluginPath, repoRoot);
  for (const step of steps) {
    // eslint-disable-next-line no-await-in-loop -- steps are intentionally
    // sequential; this replays a session's real event ordering.
    const result = await runStep(hooks, step);
    console.log(JSON.stringify(result));
  }
}

main().catch((err) => fail(5, `unhandled error: ${err?.stack ? err.stack : err}`));
