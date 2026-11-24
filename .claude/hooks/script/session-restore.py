#!/usr/bin/env python3
# SessionStart(compact) hook: after auto-compact, re-state the branch, dirty files and the active .dev-plan
# so a long /dev pipeline resumes at the right step (idea from ECC pre-compact + session-start-bootstrap).
import glob
import json
import os
import subprocess
import sys

MAX_DIRTY = 20
MAX_OPEN_STEPS = 8


def git(cwd, *args):
    try:
        out = subprocess.run(["git", "-C", cwd, *args], capture_output=True, text=True, timeout=5)
    except (subprocess.TimeoutExpired, OSError):
        return ""
    return out.stdout.strip() if out.returncode == 0 else ""


cwd = json.load(sys.stdin).get("cwd") or os.getcwd()
root = git(cwd, "rev-parse", "--show-toplevel") or cwd
lines = []

branch = git(root, "rev-parse", "--abbrev-ref", "HEAD")
if branch:
    lines.append(f"Branch: {branch}")
    dirty = git(root, "status", "--short").splitlines()
    if dirty:
        lines.append(f"Uncommitted ({len(dirty)}):")
        lines += [f"  {d}" for d in dirty[:MAX_DIRTY]]

plans = glob.glob(os.path.join(root, ".dev-plan", "*.md"))
if plans:
    plan = max(plans, key=os.path.getmtime)
    with open(plan, errors="ignore") as f:
        open_steps = [l.strip() for l in f if l.lstrip().startswith("- [ ]")]
    lines.append(f"Active plan (latest edited): {os.path.relpath(plan, root)} — {len(open_steps)} unchecked step(s)")
    lines += [f"  {s}" for s in open_steps[:MAX_OPEN_STEPS]]

if lines:
    print("State restored after compaction (re-read the plan file before continuing):\n" + "\n".join(lines))
sys.exit(0)
