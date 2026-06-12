#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Smoke test for antigravity_delegate MCP shim.

Runs without a live agy installation.  The spawn-and-capture function
(_spawn_and_capture) is replaced via monkeypatching in every test case,
so no subprocesses are forked.

IEEE 1008-1987 §3.2 features tested:
  1. initialize handshake — response shape (protocolVersion, capabilities, serverInfo)
  2. tools/list — returns antigravity_delegate tool with required 'task' field
  3. tools/call (success) — mock returns canned stdout; result is a text content block
  4. tools/call (timeout path) — spawn returns timed_out=True; isError + timeout message
  5. tools/call (nonzero exit) — spawn returns exit_code=1; isError + exit code in text
  6. tools/call (byte-cap / truncation) — spawn returns truncated=True; truncation note appended
  7. tools/call (model allowlist rejection, R2) — unknown model → JSON-RPC -32602
  8. ANSI stripping (R5) — escape sequences removed from returned text
"""

from __future__ import annotations

import io
import json
import sys
import unittest
from typing import Any
from unittest.mock import patch

# Ensure the scripts/mcp directory is on the path when run from repo root
import os

sys.path.insert(0, os.path.dirname(__file__))

# pylint: disable=wrong-import-position  # sys.path bootstrap must precede this import
import antigravity_delegate as shim  # noqa: E402


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _run(requests: list[dict[str, Any]], mock_spawn: Any = None) -> list[dict[str, Any]]:
    """Drive run_loop with a list of JSON-RPC request dicts.

    Replaces stdout with a StringIO, feeds requests to stdin, returns
    the list of parsed response dicts written to stdout.
    """
    input_lines = "\n".join(json.dumps(r) for r in requests) + "\n"
    fake_stdin = io.StringIO(input_lines)
    fake_stdout = io.StringIO()

    with patch.object(sys, "stdin", fake_stdin), patch.object(sys, "stdout", fake_stdout):
        if mock_spawn is not None:
            shim.run_loop(spawn_fn=mock_spawn)
        else:
            shim.run_loop()

    output = fake_stdout.getvalue()
    responses = []
    for line in output.splitlines():
        line = line.strip()
        if line:
            responses.append(json.loads(line))
    return responses


def _simple_spawn(
    text: str = "hello",
    exit_code: int = 0,
    timed_out: bool = False,
    truncated: bool = False,
) -> Any:
    """Return a mock spawn function that yields fixed values."""

    def _fn(  # pylint: disable=unused-argument
        argv: list[str], timeout_s: int  # mirrors real spawn signature; args unused in mock
    ) -> tuple[str, int | None, bool, bool]:
        return text, exit_code, timed_out, truncated

    return _fn


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------


class TestInitializeHandshake(unittest.TestCase):
    """IEEE 1008-1987 §3.2 feature 1: initialize response shape."""

    def test_initialize_response_shape(self) -> None:
        """Assert initialize response contains protocolVersion, capabilities, and serverInfo."""
        responses = _run([{"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {}}])
        self.assertEqual(len(responses), 1)
        r = responses[0]
        self.assertEqual(r["jsonrpc"], "2.0")
        self.assertEqual(r["id"], 1)
        result = r["result"]
        self.assertIn("protocolVersion", result)
        self.assertIn("capabilities", result)
        self.assertIn("tools", result["capabilities"])
        self.assertIn("serverInfo", result)
        self.assertIn("name", result["serverInfo"])
        self.assertIn("version", result["serverInfo"])

    def test_initialized_notification_no_response(self) -> None:
        """Notifications (no id) must produce no response."""
        responses = _run(
            [
                {"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {}},
                {"jsonrpc": "2.0", "method": "notifications/initialized"},
            ]
        )
        # Only the initialize response; notification gets no response
        self.assertEqual(len(responses), 1)
        self.assertEqual(responses[0]["id"], 1)


class TestToolsList(unittest.TestCase):
    """IEEE 1008-1987 §3.2 feature 2: tools/list returns the tool with required 'task'."""

    def test_tools_list_returns_antigravity_delegate(self) -> None:
        """Assert tools/list returns exactly one tool named antigravity_delegate."""
        responses = _run([{"jsonrpc": "2.0", "id": 2, "method": "tools/list", "params": {}}])
        self.assertEqual(len(responses), 1)
        r = responses[0]
        tools = r["result"]["tools"]
        self.assertEqual(len(tools), 1)
        tool = tools[0]
        self.assertEqual(tool["name"], "antigravity_delegate")

    def test_tools_list_task_is_required(self) -> None:
        """Assert inputSchema marks 'task' as a required property."""
        responses = _run([{"jsonrpc": "2.0", "id": 3, "method": "tools/list", "params": {}}])
        tool = responses[0]["result"]["tools"][0]
        schema = tool["inputSchema"]
        self.assertIn("task", schema["required"])
        self.assertIn("task", schema["properties"])

    def test_tools_list_has_model_and_timeout_properties(self) -> None:
        """Assert inputSchema exposes optional 'model' and 'timeout_s' properties."""
        responses = _run([{"jsonrpc": "2.0", "id": 4, "method": "tools/list", "params": {}}])
        schema = responses[0]["result"]["tools"][0]["inputSchema"]
        self.assertIn("model", schema["properties"])
        self.assertIn("timeout_s", schema["properties"])


class TestToolsCallSuccess(unittest.TestCase):
    """IEEE 1008-1987 §3.2 feature 3: successful tools/call yields a text content block."""

    def _call(self, task: str = "hello", model: str | None = None) -> dict[str, Any]:
        """Issue a tools/call with a mock spawn returning 'Antigravity says hello'."""
        args: dict[str, Any] = {"task": task}
        if model is not None:
            args["model"] = model
        req = {
            "jsonrpc": "2.0",
            "id": 10,
            "method": "tools/call",
            "params": {"name": "antigravity_delegate", "arguments": args},
        }
        responses = _run([req], mock_spawn=_simple_spawn("Antigravity says hello"))
        self.assertEqual(len(responses), 1)
        return responses[0]

    def test_success_is_not_error(self) -> None:
        """Assert a successful call returns isError: false."""
        r = self._call()
        self.assertFalse(r["result"]["isError"])

    def test_success_has_text_content_block(self) -> None:
        """Assert result contains a single text content block with the captured output."""
        r = self._call()
        content = r["result"]["content"]
        self.assertEqual(len(content), 1)
        self.assertEqual(content[0]["type"], "text")
        self.assertIn("Antigravity says hello", content[0]["text"])

    def test_explicit_allowed_model_accepted(self) -> None:
        """Assert the default model string passes allowlist validation."""
        r = self._call(model="Gemini 3.5 Flash (High)")
        self.assertNotIn("error", r)
        self.assertFalse(r["result"]["isError"])


class TestToolsCallTimeout(unittest.TestCase):
    """IEEE 1008-1987 §3.2 feature 4: timeout path returns isError + timeout message."""

    def test_timeout_is_error(self) -> None:
        """Assert a timed-out spawn sets isError: true in the result."""
        req = {
            "jsonrpc": "2.0",
            "id": 20,
            "method": "tools/call",
            "params": {
                "name": "antigravity_delegate",
                "arguments": {"task": "slow task", "timeout_s": 5},
            },
        }
        responses = _run(
            [req],
            mock_spawn=_simple_spawn("partial output", exit_code=None, timed_out=True),
        )
        self.assertEqual(len(responses), 1)
        result = responses[0]["result"]
        self.assertTrue(result["isError"])

    def test_timeout_message_contains_timeout(self) -> None:
        """Assert the timeout error text mentions 'timeout' and the configured seconds."""
        req = {
            "jsonrpc": "2.0",
            "id": 21,
            "method": "tools/call",
            "params": {
                "name": "antigravity_delegate",
                "arguments": {"task": "slow task", "timeout_s": 5},
            },
        }
        responses = _run([req], mock_spawn=_simple_spawn("", exit_code=None, timed_out=True))
        text = responses[0]["result"]["content"][0]["text"]
        self.assertIn("timeout", text.lower())
        self.assertIn("5", text)


class TestToolsCallNonzeroExit(unittest.TestCase):
    """IEEE 1008-1987 §3.2 feature 5: nonzero exit returns isError + exit code."""

    def test_nonzero_exit_is_error(self) -> None:
        """Assert a nonzero exit code sets isError: true in the result."""
        req = {
            "jsonrpc": "2.0",
            "id": 30,
            "method": "tools/call",
            "params": {
                "name": "antigravity_delegate",
                "arguments": {"task": "bad task"},
            },
        }
        responses = _run(
            [req], mock_spawn=_simple_spawn("error output", exit_code=1)
        )
        result = responses[0]["result"]
        self.assertTrue(result["isError"])

    def test_nonzero_exit_includes_exit_code_and_output(self) -> None:
        """Assert the error text includes the numeric exit code and captured output."""
        req = {
            "jsonrpc": "2.0",
            "id": 31,
            "method": "tools/call",
            "params": {
                "name": "antigravity_delegate",
                "arguments": {"task": "bad task"},
            },
        }
        responses = _run(
            [req], mock_spawn=_simple_spawn("diagnostic text", exit_code=2)
        )
        text = responses[0]["result"]["content"][0]["text"]
        self.assertIn("2", text)  # exit code
        self.assertIn("diagnostic text", text)


class TestToolsCallByteCap(unittest.TestCase):
    """IEEE 1008-1987 §3.2 feature 6: byte-cap path truncates and notes it."""

    def test_truncated_flag_appends_note(self) -> None:
        """Assert a truncated capture appends a '[…truncated…]' note to the output."""
        req = {
            "jsonrpc": "2.0",
            "id": 40,
            "method": "tools/call",
            "params": {
                "name": "antigravity_delegate",
                "arguments": {"task": "verbose task"},
            },
        }
        responses = _run(
            [req],
            mock_spawn=_simple_spawn("lots of output", exit_code=0, truncated=True),
        )
        text = responses[0]["result"]["content"][0]["text"]
        self.assertIn("truncated", text.lower())

    def test_truncated_with_success_exit_is_not_error(self) -> None:
        """Assert truncation with exit 0 does not set isError (output is still usable)."""
        req = {
            "jsonrpc": "2.0",
            "id": 41,
            "method": "tools/call",
            "params": {
                "name": "antigravity_delegate",
                "arguments": {"task": "verbose task"},
            },
        }
        responses = _run(
            [req],
            mock_spawn=_simple_spawn("lots of output", exit_code=0, truncated=True),
        )
        # truncated but exit=0 → not an error
        self.assertFalse(responses[0]["result"]["isError"])


class TestModelAllowlist(unittest.TestCase):
    """IEEE 1008-1987 §3.2 feature 7: model allowlist rejection (R2) → -32602."""

    def test_unknown_model_rejected_with_32602(self) -> None:
        """Assert a model not in ALLOWED_MODELS returns JSON-RPC error -32602."""
        req = {
            "jsonrpc": "2.0",
            "id": 50,
            "method": "tools/call",
            "params": {
                "name": "antigravity_delegate",
                "arguments": {"task": "hello", "model": "MaliciousModel; rm -rf /"},
            },
        }
        responses = _run([req], mock_spawn=_simple_spawn())
        r = responses[0]
        self.assertIn("error", r)
        self.assertEqual(r["error"]["code"], -32602)

    def test_unknown_model_does_not_spawn(self) -> None:
        """Assert spawn is never called when the model is rejected by the allowlist."""
        spawned: list[bool] = []

        def tracking_spawn(  # pylint: disable=unused-argument
            argv: list[str], timeout_s: int  # mirrors real spawn signature; unused in mock
        ) -> Any:
            spawned.append(True)
            return "output", 0, False, False

        req = {
            "jsonrpc": "2.0",
            "id": 51,
            "method": "tools/call",
            "params": {
                "name": "antigravity_delegate",
                "arguments": {"task": "hello", "model": "FakeModel"},
            },
        }
        _run([req], mock_spawn=tracking_spawn)
        self.assertEqual(spawned, [], "spawn must not be called for rejected model")

    def test_missing_task_rejected_with_32602(self) -> None:
        """Assert omitting 'task' returns JSON-RPC error -32602."""
        req = {
            "jsonrpc": "2.0",
            "id": 52,
            "method": "tools/call",
            "params": {
                "name": "antigravity_delegate",
                "arguments": {},
            },
        }
        responses = _run([req], mock_spawn=_simple_spawn())
        self.assertIn("error", responses[0])
        self.assertEqual(responses[0]["error"]["code"], -32602)


class TestAnsiStripping(unittest.TestCase):
    """IEEE 1008-1987 §3.2 feature 8: ANSI escape sequences are stripped (R5)."""

    def _call_with_text(self, raw_text: str) -> str:
        """Issue a tools/call whose mock spawn returns raw_text; return the result text."""
        req = {
            "jsonrpc": "2.0",
            "id": 60,
            "method": "tools/call",
            "params": {
                "name": "antigravity_delegate",
                "arguments": {"task": "colorful task"},
            },
        }
        responses = _run([req], mock_spawn=_simple_spawn(raw_text))
        return responses[0]["result"]["content"][0]["text"]

    def test_csi_color_codes_removed(self) -> None:
        """Assert CSI color sequences (ESC [ … m) are stripped, leaving plain text."""
        text = self._call_with_text("\x1b[32mGreen text\x1b[0m")
        self.assertNotIn("\x1b", text)
        self.assertIn("Green text", text)

    def test_osc_sequences_removed(self) -> None:
        """Assert OSC sequences (ESC ] … BEL) are stripped including their payload (W1/S4)."""
        # W1/S4: verify the OSC introducer, its payload, and the BEL terminator
        # are all removed — not just the ESC byte.
        text = self._call_with_text("\x1b]0;window title\x07plain text")
        self.assertNotIn("\x1b", text)
        self.assertNotIn("window title", text)
        self.assertNotIn("\x07", text)
        self.assertIn("plain text", text)

    def test_fe_sequence_removed(self) -> None:
        """Assert Fe sequences (e.g. ESC M reverse-index) are stripped entirely."""
        # ESC M (reverse index) is an Fe sequence
        text = self._call_with_text("before\x1bMafter")
        self.assertNotIn("\x1b", text)

    def test_plain_text_unchanged(self) -> None:
        """Assert text with no escape sequences passes through unchanged."""
        text = self._call_with_text("no escapes here")
        self.assertEqual(text.strip(), "no escapes here")

    def test_partial_escape_at_tail_stripped(self) -> None:
        """Assert a truncated escape at the end of output (S2) leaves no ESC byte."""
        # S2: a partial escape sequence at the byte-cap boundary (e.g. "…\x1b["
        # with the rest of the sequence missing) must leave no ESC in the output.
        text = self._call_with_text("good output\x1b[")
        self.assertNotIn("\x1b", text)
        self.assertIn("good output", text)

    def test_bool_timeout_rejected(self) -> None:
        """Assert bool values for timeout_s (int subclass) are rejected with -32602 (S1)."""
        # S1: bool is an int subclass; True/False must be rejected as timeout_s.
        req = {
            "jsonrpc": "2.0",
            "id": 61,
            "method": "tools/call",
            "params": {
                "name": "antigravity_delegate",
                "arguments": {"task": "hello", "timeout_s": True},
            },
        }
        responses = _run([req], mock_spawn=_simple_spawn())
        self.assertIn("error", responses[0])
        self.assertEqual(responses[0]["error"]["code"], -32602)


class TestDispatchEdgeCases(unittest.TestCase):
    """Miscellaneous dispatch-loop edge cases."""

    def test_unknown_method_returns_32601(self) -> None:
        """Assert an unrecognised method name returns JSON-RPC error -32601."""
        req = {"jsonrpc": "2.0", "id": 70, "method": "nonexistent/method", "params": {}}
        responses = _run([req])
        self.assertIn("error", responses[0])
        self.assertEqual(responses[0]["error"]["code"], -32601)

    def test_malformed_json_returns_32700(self) -> None:
        """Assert unparseable input returns JSON-RPC parse error -32700."""
        fake_stdin = io.StringIO("{ not valid json }\n")
        fake_stdout = io.StringIO()
        with patch.object(sys, "stdin", fake_stdin), patch.object(sys, "stdout", fake_stdout):
            shim.run_loop()
        output = fake_stdout.getvalue().strip()
        r = json.loads(output)
        self.assertIn("error", r)
        self.assertEqual(r["error"]["code"], -32700)

    def test_empty_lines_ignored(self) -> None:
        """Assert blank input lines produce no output and do not crash the loop."""
        fake_stdin = io.StringIO("\n\n\n")
        fake_stdout = io.StringIO()
        with patch.object(sys, "stdin", fake_stdin), patch.object(sys, "stdout", fake_stdout):
            shim.run_loop()
        self.assertEqual(fake_stdout.getvalue().strip(), "")

    def test_unknown_tool_name_returns_32601(self) -> None:
        """Assert tools/call with an unrecognised tool name returns -32601."""
        req = {
            "jsonrpc": "2.0",
            "id": 80,
            "method": "tools/call",
            "params": {"name": "no_such_tool", "arguments": {}},
        }
        responses = _run([req], mock_spawn=_simple_spawn())
        self.assertIn("error", responses[0])
        self.assertEqual(responses[0]["error"]["code"], -32601)

    def test_multiple_requests_in_sequence(self) -> None:
        """Loop must handle multiple requests without crashing."""
        reqs = [
            {"jsonrpc": "2.0", "id": 90, "method": "initialize", "params": {}},
            {"jsonrpc": "2.0", "id": 91, "method": "tools/list", "params": {}},
            {
                "jsonrpc": "2.0",
                "id": 92,
                "method": "tools/call",
                "params": {
                    "name": "antigravity_delegate",
                    "arguments": {"task": "hello"},
                },
            },
        ]
        responses = _run(reqs, mock_spawn=_simple_spawn("reply"))
        self.assertEqual(len(responses), 3)
        ids = [r["id"] for r in responses]
        self.assertEqual(ids, [90, 91, 92])


if __name__ == "__main__":
    unittest.main()
