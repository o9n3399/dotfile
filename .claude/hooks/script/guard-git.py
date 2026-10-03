#!/usr/bin/env python3
# PreToolUse guard for git-agent: exit 2 blocks the Bash call and feeds stderr back to the agent.
import json
import re
import subprocess
import sys

data = json.load(sys.stdin)
cmd = data.get("tool_input", {}).get("command", "")
cwd = data.get("cwd") or None


def block(reason):
    print(f"Blocked by guard-git: {reason}", file=sys.stderr)
    sys.exit(2)


if re.search(r"--no-verify\b", cmd):
    block("--no-verify is not allowed; report the failing hook instead")

def current_branch():
    return subprocess.run(
        ["git", "rev-parse", "--abbrev-ref", "HEAD"],
        cwd=cwd, capture_output=True, text=True,
    ).stdout.strip()


if re.search(r"\bgit\s+commit\b", cmd) and re.search(r"co-authored-by", cmd, re.I):
    block("Co-Authored-By lines are not allowed in commit messages")

if re.search(r"\bgit\s+commit\b", cmd) and current_branch() in ("main", "master"):
    block("committing on main/master is not allowed; run `git switch -c <type>/<slug>` first")

if re.search(r"\bgit\s+push\b", cmd):
    if re.search(r"(\s--force(-with-lease)?\b|\s-f\b|\s\+\S)", cmd):
        block("force push is not allowed")
    tokens = cmd.split("git push", 1)[1].split()
    if any(t in ("main", "master") or t.endswith((":main", ":master")) for t in tokens):
        block("pushing to main/master is not allowed")
    branch = current_branch()
    if branch in ("main", "master"):
        block(f"current branch is {branch}; create a feature branch first")

if re.search(r"\bgit\s+(reset\s+--hard|clean\s+-\w*f|branch\s+-D)\b", cmd):
    block("destructive git command is not allowed")

sys.exit(0)
