#!/usr/bin/env python3
# PreToolUse guard for read-only agents: block any git invocation that can change repo, working-tree or file state.
import json
import shlex
import sys

READONLY = {"diff", "log", "status", "show", "merge-base", "rev-parse", "ls-files", "blame", "grep", "branch", "cat-file"}
# --output writes the diff to any path; --ext-diff / grep -O run external programs.
BLOCKED_ARGS = ("--output", "--ext-diff", "--open-files-in-pager")
BRANCH_LISTING = {"--list", "-l", "--show-current"}
OPERATORS = {";", "&&", "||", "|", "&"}


def block(reason):
    print(f"Blocked by guard-readonly-git: {reason}", file=sys.stderr)
    sys.exit(2)


cmd = json.load(sys.stdin).get("tool_input", {}).get("command", "")

if "$(" in cmd or "`" in cmd:
    block("command substitution is not allowed for a read-only agent")

try:
    lexer = shlex.shlex(cmd, posix=True, punctuation_chars=True)
    lexer.whitespace_split = True
    tokens = list(lexer)
except ValueError:
    block("could not parse command")

i = 0
while i < len(tokens):
    if tokens[i] != "git" and not tokens[i].endswith("/git"):
        i += 1
        continue
    i += 1
    # Global options like -c / --git-dir / --exec-path can inject config that executes commands.
    while i < len(tokens) and tokens[i].startswith("-"):
        if tokens[i] != "-C":
            block(f"git global option `{tokens[i]}` is not allowed")
        i += 2
    if i >= len(tokens):
        break
    sub = tokens[i]
    if sub not in READONLY:
        block(f"`git {sub}` is not allowed for a read-only agent")
    i += 1
    args = []
    while i < len(tokens) and tokens[i] not in OPERATORS:
        args.append(tokens[i])
        i += 1
    for arg in args:
        if arg.startswith(BLOCKED_ARGS) or (sub == "grep" and arg.startswith("-O")):
            block(f"`git {sub} {arg}` is not allowed")
    if sub == "branch":
        positional = [a for a in args if not a.startswith("-")]
        flags = [a for a in args if a.startswith("-")]
        if any(f[:2] in ("-d", "-D", "-m", "-M", "-c", "-C", "-u", "-f") or f.startswith(("--delete", "--move", "--copy", "--set-upstream", "--unset-upstream", "--edit-description", "--force")) for f in flags):
            block("modifying branches is not allowed")
        if positional and not BRANCH_LISTING.intersection(flags):
            block("creating branches is not allowed")

sys.exit(0)
