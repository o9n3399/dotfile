#!/usr/bin/env python3
# Global PreToolUse(Bash) guard: block `--no-verify` and force push for every session and agent.
# Checks each shell segment on its own so `git push && rm -f tmp` is not read as a force push.
import json
import re
import sys

from guard_switch import exit_if_off

exit_if_off("GIT")

SEGMENT_SPLIT = re.compile(r"&&|\|\||[;|\n]")
GIT_CMD = re.compile(r"\bgit\s+(?:-C\s+\S+\s+|-c\s+\S+\s+)*(commit|push|merge|rebase|cherry-pick|am)\b(.*)", re.S)
FORCE = re.compile(r"(?:^|\s)(--force(?:-with-lease|-if-includes)?(?:=\S*)?|-\w*f\w*|\+\S+)(?=\s|$)")


def block(reason):
    print(f"Blocked by guard-git-safety: {reason}. If the user really wants this, they can rerun with CLAUDE_GUARD_GIT=off.", file=sys.stderr)
    sys.exit(2)


cmd = json.load(sys.stdin).get("tool_input", {}).get("command", "")

for segment in SEGMENT_SPLIT.split(cmd):
    m = GIT_CMD.search(segment)
    if not m:
        continue
    sub, args = m.group(1), m.group(2)
    if re.search(r"(?:^|\s)--no-verify\b", args):
        block("--no-verify skips git hooks; report the failing hook instead")
    if sub == "push" and FORCE.search(args):
        block("force push rewrites remote history")

sys.exit(0)
