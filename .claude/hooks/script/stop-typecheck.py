#!/usr/bin/env python3
# Stop/SubagentStop hook: run tsc --noEmit for the TS projects touched in this turn and block only on errors in touched files.
# Turns CLAUDE.md's "typecheck before saying done" into a check (idea from ECC stop:format-typecheck).
import hashlib
import json
import os
import re
import subprocess
import sys

from guard_switch import exit_if_off

exit_if_off("TYPECHECK")

TS_FILE = re.compile(r"\.(ts|tsx|mts|cts)$")
EDIT_TOOLS = {"Edit", "Write", "MultiEdit"}
TSC_ERROR = re.compile(r"^(?P<file>[^\s(][^(]*)\((?P<line>\d+),(?P<col>\d+)\): error (?P<code>TS\d+): (?P<msg>.*)$")
CACHE_DIR = os.path.expanduser("~/.cache/claude-typecheck")
MAX_REPORTED = 30


def is_user_prompt(entry):
    if entry.get("type") != "user" or entry.get("isMeta"):
        return False
    content = entry.get("message", {}).get("content")
    if isinstance(content, str):
        return True
    return isinstance(content, list) and not any(isinstance(c, dict) and c.get("type") == "tool_result" for c in content)


def edited_files(transcript, whole_run):
    try:
        with open(transcript) as f:
            entries = [json.loads(line) for line in f if line.strip()]
    except (OSError, json.JSONDecodeError):
        return set()
    files = set()
    for entry in reversed(entries):
        if not whole_run and is_user_prompt(entry):
            break
        if entry.get("type") != "assistant":
            continue
        for block in entry.get("message", {}).get("content", []) or []:
            if isinstance(block, dict) and block.get("type") == "tool_use" and block.get("name") in EDIT_TOOLS:
                path = (block.get("input") or {}).get("file_path", "")
                if TS_FILE.search(path) and not path.endswith(".d.ts") and os.path.exists(path):
                    files.add(os.path.realpath(path))
    return files


def find_up(start, name, stop_at_git=True):
    d = start
    while True:
        candidate = os.path.join(d, name)
        if os.path.exists(candidate):
            return candidate
        if (stop_at_git and os.path.exists(os.path.join(d, ".git"))) or os.path.dirname(d) == d:
            return None
        d = os.path.dirname(d)


def run_tsc(tsconfig):
    root = os.path.dirname(tsconfig)
    tsc = find_up(root, "node_modules/.bin/tsc", stop_at_git=False)
    if not tsc:
        return None
    os.makedirs(CACHE_DIR, exist_ok=True)
    build_info = os.path.join(CACHE_DIR, hashlib.sha1(tsconfig.encode()).hexdigest() + ".tsbuildinfo")
    try:
        out = subprocess.run(
            [tsc, "--noEmit", "--pretty", "false", "--incremental", "--tsBuildInfoFile", build_info, "-p", tsconfig],
            cwd=root, capture_output=True, text=True, timeout=150,
        )
    except subprocess.TimeoutExpired:
        return None
    errors = []
    for line in out.stdout.splitlines():
        m = TSC_ERROR.match(line.strip())
        if m:
            errors.append((os.path.realpath(os.path.join(root, m["file"])), m["line"], m["col"], m["code"], m["msg"]))
    return errors


data = json.load(sys.stdin)
subagent = data.get("hook_event_name") == "SubagentStop"
transcript = data.get("agent_transcript_path") if subagent else data.get("transcript_path")
files = edited_files(transcript or "", whole_run=subagent)
if not files:
    sys.exit(0)

projects = {}
for path in files:
    tsconfig = find_up(os.path.dirname(path), "tsconfig.json")
    if tsconfig:
        projects.setdefault(tsconfig, set()).add(path)

found = []
for tsconfig, touched in projects.items():
    for err in run_tsc(tsconfig) or []:
        if err[0] in touched:
            found.append(err)
if not found:
    sys.exit(0)

# Re-blocking on the exact same errors means no progress; let the turn end instead of looping.
digest = hashlib.sha1(repr(sorted(found)).encode()).hexdigest()
state = os.path.join(CACHE_DIR, f"last-{data.get('session_id', 'none')}-{data.get('agent_id', 'main')}")
try:
    with open(state) as f:
        if data.get("stop_hook_active") and f.read() == digest:
            sys.exit(0)
except OSError:
    pass
with open(state, "w") as f:
    f.write(digest)

cwd = data.get("cwd") or os.getcwd()
lines = [f"{os.path.relpath(p, cwd)}:{ln}:{col} {code} {msg}" for p, ln, col, code, msg in sorted(found)[:MAX_REPORTED]]
more = f"\n… and {len(found) - MAX_REPORTED} more" if len(found) > MAX_REPORTED else ""
print("Blocked by stop-typecheck: tsc reports errors in files edited this turn. Fix them before finishing "
      "(or say why they are pre-existing):\n" + "\n".join(lines) + more, file=sys.stderr)
sys.exit(2)
