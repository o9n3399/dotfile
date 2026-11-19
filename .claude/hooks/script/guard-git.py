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
        block(f"{repo or 'repo'} is {n} commit(s) behind its upstream. Sync before committing (git-agent Step 2: "
              "`git stash push -u` if dirty, `git pull --ff-only` or `--rebase` if you have local commits, `git stash pop`); "
              "it is allowed even when the brief says \"Do NOT run git pull\". On a conflict, do not commit: report it.")


if commit and re.search(r"co-authored-by", cmd, re.I):
    block("Co-Authored-By lines are not allowed in commit messages")

if commit and git_out(commit_repo(), "rev-parse", "--abbrev-ref", "HEAD").stdout.strip() in ("main", "master"):
    block("committing on main/master is not allowed; run `git switch -c <type>/<slug>` first")

m = re.search(r"\bgit\s+(?:-C\s+(['\"]?)([^\s'\";&|]+)\1\s+)?push\b(.*)", cmd)
if m:
    if re.search(r"(\s--force(-with-lease)?\b|\s-f\b|\s\+\S)", cmd):
        block("force push is not allowed")
    push_repo = m.group(2) or cwd
    tokens = m.group(3).split()
    detached = git_out(push_repo, "rev-parse", "--abbrev-ref", "HEAD").stdout.strip() == "HEAD"
    for t in tokens:
        if detached and t == "HEAD:main":
            continue
        if t in ("main", "master") or t.endswith((":main", ":master")):
            block("pushing to main/master is not allowed (only `push origin HEAD:main` from a detached /dev-pick worktree)")
    branch = git_out(push_repo, "rev-parse", "--abbrev-ref", "HEAD").stdout.strip()
    if branch in ("main", "master"):
        block(f"current branch is {branch}; create a feature branch first")

if re.search(r"\bgit\s+(reset\s+--hard|clean\s+-\w*f|branch\s+-D)\b", cmd):
    block("destructive git command is not allowed")

sys.exit(0)
