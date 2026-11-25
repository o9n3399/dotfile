#!/usr/bin/env python3
# MCP health tracker (idea from ECC mcp-health-check). Usage by hook event:
#   PostToolUseFailure ^mcp__  -> `mcp-health.py fail`  records a failure for the server
#   PostToolUse        ^mcp__  -> `mcp-health.py ok`    clears the server
#   PreToolUse         ^mcp__  -> `mcp-health.py check` blocks calls to a server that keeps failing
import json
import os
import re
import sys
import time

from guard_switch import exit_if_off

exit_if_off("MCP")

STATE = os.path.expanduser("~/.cache/claude-mcp-health.json")
WINDOW_SECONDS = 180
FAIL_THRESHOLD = 2
# Only transport-level errors mean the server is down; a tool rejecting bad input (e.g. {"ok": false}) or a
# Playwright locator timeout is the caller's mistake and must not lock the server.
TRANSPORT_ERROR = re.compile(
    r"MCP error -3200[01]|connection closed|not connected|ECONNREFUSED|ECONNRESET|ENOTFOUND|EPIPE|"
    r"socket hang up|fetch failed|request timed out|server (?:has )?(?:disconnected|exited)",
    re.I,
)


def load():
    try:
        with open(STATE) as f:
            return json.load(f)
    except (OSError, json.JSONDecodeError):
        return {}


def save(state):
    os.makedirs(os.path.dirname(STATE), exist_ok=True)
    with open(STATE, "w") as f:
        json.dump(state, f)


mode = sys.argv[1] if len(sys.argv) > 1 else "check"
data = json.load(sys.stdin)
parts = data.get("tool_name", "").split("__")
if len(parts) < 3:
    sys.exit(0)
server = parts[1]
now = time.time()
state = load()
recent = [t for t in state.get(server, []) if now - t < WINDOW_SECONDS]

if mode == "fail":
    if not TRANSPORT_ERROR.search(str(data.get("error") or data.get("tool_response") or "")):
        sys.exit(0)
    state[server] = recent + [now]
    save(state)
elif mode == "ok":
    if server in state:
        del state[server]
        save(state)
elif len(recent) >= FAIL_THRESHOLD:
    wait = int(WINDOW_SECONDS - (now - recent[-1]))
    print(f"Blocked by mcp-health: MCP server '{server}' failed {len(recent)} times in the last {WINDOW_SECONDS}s. "
          f"Do not retry; tell the user it looks down (they can reconnect via /mcp). Calls unblock in ~{wait}s.",
          file=sys.stderr)
    sys.exit(2)

sys.exit(0)
