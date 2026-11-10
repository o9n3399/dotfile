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


def commit_repo():
    m = re.search(r"\bgit\s+-C\s+(['\"]?)([^\s'\";&|]+)\1\s+commit\b", cmd)
    if m:
        return m.group(2)
    m = re.search(r"\bcd\s+(['\"]?)([^\s'\";&|]+)\1[^\n]*?\bgit\s+commit\b", cmd)
    return m.group(2) if m else cwd


def git_out(repo, *args, timeout=10):
    return subprocess.run(["git", "-C", repo or ".", *args], capture_output=True, text=True, timeout=timeout)


def behind_upstream(repo):
    if git_out(repo, "rev-parse", "--abbrev-ref", "@{u}").returncode != 0:
        return 0
    try:
        if git_out(repo, "fetch", "-q", timeout=30).returncode != 0:
            return 0
    except subprocess.TimeoutExpired:
        return 0
    out = git_out(repo, "rev-list", "--count", "HEAD..@{u}").stdout.strip()
    return int(out) if out.isdigit() else 0


commit = re.search(r"\bgit\s+(-C\s+\S+\s+)?commit\b", cmd)
if commit and not re.search(r"\bgit\s+(-C\s+\S+\s+)?pull\s+--ff-only\b", cmd[:commit.start()]):
    repo = commit_repo()
    n = behind_upstream(repo)
    if n:
        block(f"{repo or 'repo'} is {n} commit(s) behind its upstream. Run `git pull --ff-only` before committing "
              "(git-agent Step 2); it is allowed even when the brief says \"Do NOT run git pull\". "
              "If --ff-only is refused, do not commit: report the error.")


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
