#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Antigravity delegate shim — stdio MCP server (Python 3 stdlib only, Unix only).

Implements JSON-RPC 2.0 over stdin/stdout (newline-delimited JSON framing).
Exposes one tool: antigravity_delegate(task, model?, timeout_s?).

argv ordering investigation (2026-06-11):
  Binary analysis of /home/quackdcs/.local/bin/agy confirmed:
  - agy uses google3/base/go/flag (Google's internal flag library built on
    Go stdlib flag).
  - --print is a *string flag*: the task value is the token immediately
    following --print in argv.  It is NOT a positional argument.
  - Confirmed invocation: ["agy", "--print", task, "--model", model]
    The task string is passed as the VALUE of the --print flag via the OS
    argv array.  No shell parser ever sees it.  Flag-injection (CWE-88) is
    structurally impossible in this shape: agy's own flag parser consumes
    task as a plain string value regardless of its content (quotes,
    semicolons, dashes, etc.).
  - The "--" end-of-options concern in security requirement R1 is addressed
    here: because task is a flag VALUE (not a positional), "--" is irrelevant
    to injection safety.  The model flag follows --model and also cannot be
    misread because it is validated against the allowlist before spawning.
  - ADR §3 pseudocode shows ["agy", "--print", task, "--model", model], which
    matches binary analysis.  This is the final adopted argv shape.

Security requirements implemented:
  R1  Flag-injection: task is argv[2] (value of --print), never shell-expanded.
  R2  Model allowlist: validated against ALLOWED_MODELS before spawn.
  R3  fd hygiene: child closes parent_fd; parent closes child_fd after fork.
  R4  Reap: os.waitpid() in all exit paths (normal, timeout-kill, byte-cap-kill).
  R5  ANSI strip: raw bytes capped in _spawn_and_capture; ANSI escape stripping
      applied in _handle_tools_call so the mock path in tests also exercises it.
"""

from __future__ import annotations

import fcntl
import json
import os
import re
import select
import signal
import sys
import termios
import time
from typing import Any

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

SERVER_NAME = "antigravity-delegate"
SERVER_VERSION = "1.0.0"
PROTOCOL_VERSION = "2024-11-05"

DEFAULT_MODEL = "Gemini 3.5 Flash (High)"
DEFAULT_TIMEOUT_S = 300
MAX_OUTPUT_BYTES = 512 * 1024  # 512 KiB raw-byte cap (R5: cap raw bytes first)

# R2 — model allowlist.  Extend this list as new model strings are confirmed
# working with agy.  Only the default has been confirmed via binary analysis
# (2026-06-11); add others once verified.
ALLOWED_MODELS: frozenset[str] = frozenset(
    [
        "Gemini 3.5 Flash (High)",
        # Add confirmed model strings here, e.g.:
        # "Gemini 2.5 Pro",
    ]
)

# R5 — ANSI escape sequence regex.
# Alternation order matters: OSC (ESC ]) MUST come before the Fe branch
# (ESC [@-Z\\-_]) because ] (U+005D) falls inside [@-Z\\-_] and would be
# consumed first, leaving the OSC payload ("0;title…\x07") in the output.
# Branch order: OSC first, then CSI (ESC [ …), then the remaining Fe codes.
# Note: 8-bit C1 codes (0x80–0x9F) are not covered; they are rare in
# modern terminal output and excluded to keep the regex simple (C1 gap,
# accepted per code-reviewer S3/S5/S6 waiver).
_ANSI_RE = re.compile(
    r"\x1b(?:\].*?(?:\x07|\x1b\\)|\[[0-?]*[ -/]*[@-~]|[@-Z\\-_])",
    re.DOTALL,
)

# ---------------------------------------------------------------------------
# Tool schema (ADR §1)
# ---------------------------------------------------------------------------

TOOL_SCHEMA: dict[str, Any] = {
    "name": "antigravity_delegate",
    "description": (
        "Delegate a task to Google Antigravity (agy) and return the response. "
        "Requires agy to be installed and authenticated."
    ),
    "inputSchema": {
        "type": "object",
        "properties": {
            "task": {
                "type": "string",
                "description": "The task or prompt to send to Antigravity.",
            },
            "model": {
                "type": "string",
                "description": (
                    "Antigravity model string. "
                    f"Defaults to '{DEFAULT_MODEL}'."
                ),
                "default": DEFAULT_MODEL,
            },
            "timeout_s": {
                "type": "integer",
                "description": (
                    "Seconds before the agy process is killed and an error "
                    "returned. Defaults to 300."
                ),
                "default": DEFAULT_TIMEOUT_S,
            },
        },
        "required": ["task"],
    },
}

# ---------------------------------------------------------------------------
# PTY spawn helpers
# ---------------------------------------------------------------------------


def _pty_child_exec(argv: list[str], child_fd: int, parent_fd: int) -> None:
    """Set up PTY in the child process and execvp argv.

    Called only in the child branch after os.fork().  Never returns on
    success; calls os._exit(127) on any failure so the parent does not hang.

    Security — R3: closes parent_fd before exec so the parent's read end is
    not inherited by the child.
    """
    try:
        os.setsid()
        fcntl.ioctl(child_fd, termios.TIOCSCTTY, 0)
        os.dup2(child_fd, 0)
        os.dup2(child_fd, 1)
        os.dup2(child_fd, 2)
        if child_fd > 2:
            os.close(child_fd)
        os.close(parent_fd)  # R3: close parent fd in child before exec
        # Intentional: no-shell argv-list invocation is the required injection-safe
        # spawn pattern (fw-adr-0027 §3 R1; CWE-88; security-engineer-approved).
        # B606/dangerous-subprocess-use-audit are false positives: no shell = no injection.
        # nosemgrep: python.lang.security.audit.dangerous-subprocess-use-audit
        os.execvp(argv[0], argv)  # nosec B606
    except Exception:  # pylint: disable=broad-exception-caught
        # Deliberate fail-safe: any error in child setup must not leave the
        # parent blocked waiting for a process that will never write output.
        os._exit(127)  # pylint: disable=protected-access
    os._exit(127)  # pylint: disable=protected-access  # unreachable; satisfies linters


def _append_chunk(
    chunk: bytes,
    raw_chunks: list[bytes],
    total_bytes: int,
) -> tuple[int, bool]:
    """Append chunk to raw_chunks respecting MAX_OUTPUT_BYTES cap (R5).

    Returns (new_total_bytes, truncated).  If the cap is reached the chunk
    is trimmed and truncated=True is returned; the caller should break its
    read loop.
    """
    space = MAX_OUTPUT_BYTES - total_bytes
    if len(chunk) > space:
        raw_chunks.append(chunk[:space])
        return total_bytes + space, True
    raw_chunks.append(chunk)
    return total_bytes + len(chunk), False


def _kill_and_close(pid: int, parent_fd: int) -> None:
    """Kill the child process group and close the PTY master fd.

    Called on timeout, byte-cap, or any early-exit path so the child
    cannot outlive the capture loop (R4).
    """
    try:
        os.killpg(os.getpgid(pid), signal.SIGKILL)
    except (ProcessLookupError, OSError):
        pass
    try:
        os.close(parent_fd)
    except OSError:
        pass


def _read_until_done(
    parent_fd: int,
    pid: int,
    timeout_s: int,
) -> tuple[list[bytes], bool, bool]:
    """Read from parent_fd until EOF, timeout, or byte cap.

    Returns (raw_chunks, timed_out, truncated).  Kills the child process
    group on timeout or byte-cap.  Closes parent_fd before returning.

    Security — R4: _kill_and_close ensures the child cannot outlive the
    capture loop.
    """
    raw_chunks: list[bytes] = []
    total_bytes = 0
    timed_out = False
    truncated = False
    deadline = time.monotonic() + timeout_s

    try:
        while True:
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                timed_out = True
                break

            try:
                ready, _, _ = select.select([parent_fd], [], [], min(remaining, 1.0))
            except (ValueError, select.error):
                # parent_fd closed; child has exited
                break

            if not ready:
                continue  # re-check deadline

            try:
                chunk = os.read(parent_fd, 4096)
            except OSError:
                # EIO when slave side closes — normal PTY EOF
                break

            if not chunk:
                break

            total_bytes, truncated = _append_chunk(chunk, raw_chunks, total_bytes)
            if truncated:
                break
    finally:
        _kill_and_close(pid, parent_fd)

    return raw_chunks, timed_out, truncated


def _reap_child(pid: int) -> int | None:
    """Wait for pid and return its exit code, or None on reap failure.

    Security — R4: called in ALL exit paths (normal, timeout-kill, byte-cap).
    """
    try:
        _, status = os.waitpid(pid, 0)
        if os.WIFEXITED(status):
            return os.WEXITSTATUS(status)
        if os.WIFSIGNALED(status):
            return -os.WTERMSIG(status)
    except (ChildProcessError, OSError):
        pass
    return None


# ---------------------------------------------------------------------------
# PTY spawn and capture (public injectable interface)
# ---------------------------------------------------------------------------


def _spawn_and_capture(
    argv: list[str],
    timeout_s: int,
) -> tuple[str, int | None, bool, bool]:
    """Spawn argv under a PTY, capture output, enforce timeout + byte cap.

    Returns (text, exit_code, timed_out, truncated).
    exit_code is None if the process was killed before it could be reaped
    cleanly (rare; treated as nonzero by callers).

    This function is the single injectable subprocess layer.  Tests replace it
    via monkeypatching (see test_antigravity_delegate.py).

    Security — R3 fd hygiene:
      Child branch: _pty_child_exec closes parent_fd before execvp.
      Parent branch: child_fd closed immediately after fork.
    Security — R4 reap: _reap_child called in ALL exit paths.
    """
    parent_fd, child_fd = os.openpty()
    pid = os.fork()

    if pid == 0:
        _pty_child_exec(argv, child_fd, parent_fd)
        # _pty_child_exec never returns; os._exit is called inside it.

    # ---- parent branch ----
    # R3: close child_fd in parent after fork so PTY EOF is detectable
    os.close(child_fd)

    raw_chunks, timed_out, truncated = _read_until_done(parent_fd, pid, timeout_s)
    exit_code = _reap_child(pid)

    # Decode; ANSI stripping is applied by the caller after this returns (R5).
    text = b"".join(raw_chunks).decode("utf-8", errors="replace")
    return text, exit_code, timed_out, truncated


# ---------------------------------------------------------------------------
# JSON-RPC 2.0 helpers
# ---------------------------------------------------------------------------


def _success(req_id: Any, result: Any) -> dict[str, Any]:
    """Return a JSON-RPC 2.0 success response dict."""
    return {"jsonrpc": "2.0", "id": req_id, "result": result}


def _error(req_id: Any, code: int, message: str, data: Any = None) -> dict[str, Any]:
    """Return a JSON-RPC 2.0 error response dict."""
    err: dict[str, Any] = {"code": code, "message": message}
    if data is not None:
        err["data"] = data
    return {"jsonrpc": "2.0", "id": req_id, "error": err}


def _write(obj: dict[str, Any]) -> None:
    """Serialise obj as newline-delimited JSON to stdout."""
    sys.stdout.write(json.dumps(obj) + "\n")
    sys.stdout.flush()


# ---------------------------------------------------------------------------
# Argument validation helper
# ---------------------------------------------------------------------------

# Sentinel returned by _validate_call_args when validation fails; the error
# response has already been written to stdout by the helper.
_INVALID = object()


def _validate_call_args(
    req_id: Any,
    args: dict[str, Any],
) -> tuple[str, str, int] | object:
    """Validate tools/call arguments; write an error and return _INVALID on failure.

    On success returns (task, model, timeout_s).
    """
    task = args.get("task")
    if not isinstance(task, str) or not task:
        _write(_error(req_id, -32602, "Invalid params: 'task' must be a non-empty string"))
        return _INVALID

    model = args.get("model", DEFAULT_MODEL)
    if not isinstance(model, str):
        _write(_error(req_id, -32602, "Invalid params: 'model' must be a string"))
        return _INVALID

    # R2 — model allowlist validation
    if model not in ALLOWED_MODELS:
        _write(
            _error(
                req_id,
                -32602,
                f"Invalid params: model {model!r} is not in the allowlist. "
                f"Allowed values: {sorted(ALLOWED_MODELS)}",
            )
        )
        return _INVALID

    timeout_s = args.get("timeout_s", DEFAULT_TIMEOUT_S)
    # S1: bool is an int subclass in Python; reject it explicitly.
    if isinstance(timeout_s, bool) or not isinstance(timeout_s, int) or timeout_s <= 0:
        _write(_error(req_id, -32602, "Invalid params: 'timeout_s' must be a positive integer"))
        return _INVALID

    return task, model, timeout_s


# ---------------------------------------------------------------------------
# Request handlers
# ---------------------------------------------------------------------------


def _handle_initialize(req: dict[str, Any]) -> None:
    """Respond to the MCP initialize handshake."""
    _write(
        _success(
            req.get("id"),
            {
                "protocolVersion": PROTOCOL_VERSION,
                "capabilities": {"tools": {}},
                "serverInfo": {"name": SERVER_NAME, "version": SERVER_VERSION},
            },
        )
    )


def _handle_tools_list(req: dict[str, Any]) -> None:
    """Return the list of tools this server exposes."""
    _write(_success(req.get("id"), {"tools": [TOOL_SCHEMA]}))


def _handle_tools_call(
    req: dict[str, Any],
    spawn_fn: Any,
) -> None:
    """Dispatch a tools/call request: validate args, spawn agy, return result."""
    req_id = req.get("id")
    tool_name = req.get("params", {}).get("name", "")

    if tool_name != "antigravity_delegate":
        _write(_error(req_id, -32601, f"Tool not found: {tool_name!r}"))
        return

    validated = _validate_call_args(req_id, req.get("params", {}).get("arguments", {}))
    if validated is _INVALID:
        return
    task, model, timeout_s = validated  # type: ignore[misc]

    # argv shape: ["agy", "--print", task, "--model", model]
    # task is the VALUE of --print (a string flag), not a positional argument.
    # No shell parser ever sees task or model; the OS argv array passes them
    # verbatim.  See module docstring for full argv investigation notes.
    argv = ["agy", "--print", task, "--model", model]

    try:
        text, exit_code, timed_out, truncated = spawn_fn(argv, timeout_s)
    except Exception as exc:  # pylint: disable=broad-exception-caught
        # Deliberate fail-safe: spawn failures must be returned as JSON-RPC
        # errors, never allowed to propagate and crash the dispatch loop.
        _write(_error(req_id, -32603, f"Internal error spawning agy: {exc}"))
        return

    # R5: strip ANSI escape sequences from the captured text.
    # Applied here (after spawn_fn returns) so the mock in tests also exercises
    # the stripping path — the real spawn_fn returns raw decoded text.
    # Main pass: full CSI / OSC / Fe sequences (see _ANSI_RE comment above).
    text = _ANSI_RE.sub("", text)
    # S2: strip any trailing partial escape sequence left at the byte-cap
    # boundary (e.g. "…\x1b[" where the sequence was cut mid-stream).
    text = re.sub(r"\x1b[^a-zA-Z]*$", "", text)

    if truncated:
        text += f"\n[antigravity_delegate: output truncated at {MAX_OUTPUT_BYTES} bytes]"

    if timed_out:
        result: dict[str, Any] = {
            "isError": True,
            "content": [
                {
                    "type": "text",
                    "text": (
                        f"antigravity_delegate: timeout after {timeout_s}s"
                        + (f"\n{text}" if text.strip() else "")
                    ),
                }
            ],
        }
    elif exit_code is not None and exit_code != 0:
        result = {
            "isError": True,
            "content": [
                {
                    "type": "text",
                    "text": f"antigravity_delegate: agy exited with code {exit_code}\n{text}",
                }
            ],
        }
    else:
        result = {
            "isError": False,
            "content": [{"type": "text", "text": text}],
        }

    _write(_success(req_id, result))


# ---------------------------------------------------------------------------
# Main dispatch loop
# ---------------------------------------------------------------------------


def run_loop(spawn_fn: Any = _spawn_and_capture) -> None:
    """Read newline-delimited JSON-RPC 2.0 requests from stdin until EOF."""
    for raw_line in sys.stdin:
        line = raw_line.strip()
        if not line:
            continue

        try:
            req = json.loads(line)
        except json.JSONDecodeError as exc:
            _write(_error(None, -32700, f"Parse error: {exc}"))
            continue

        if not isinstance(req, dict):
            _write(_error(None, -32600, "Invalid Request: expected JSON object"))
            continue

        method = req.get("method", "")
        req_id = req.get("id")  # None for notifications

        # Notifications (no "id" field) — respond with nothing, just continue
        if "id" not in req:
            continue

        try:
            if method == "initialize":
                _handle_initialize(req)
            elif method in ("initialized", "notifications/initialized"):
                # These can also arrive with an id in some clients; no response needed
                pass
            elif method == "tools/list":
                _handle_tools_list(req)
            elif method == "tools/call":
                _handle_tools_call(req, spawn_fn)
            else:
                _write(_error(req_id, -32601, f"Method not found: {method!r}"))
        except Exception as exc:  # pylint: disable=broad-exception-caught
            # Deliberate fail-safe: handler errors must be returned as JSON-RPC
            # errors, never allowed to propagate and terminate the server loop.
            _write(_error(req_id, -32603, f"Internal error: {exc}"))


if __name__ == "__main__":
    run_loop()
