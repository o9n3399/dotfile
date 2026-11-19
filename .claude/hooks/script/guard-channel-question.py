#!/usr/bin/env python3
# PreToolUse(AskUserQuestion): in a `claude --channels` session the popup only shows in the
# terminal and blocks the turn, so Discord never sees it and Discord replies are not processed.
import json
import os
import re
import subprocess
import sys

CHAT_ID_RE = re.compile(r'source=\\?"(?:plugin:discord:)?discord\\?" chat_id=\\?"(\d+)')


def channel_session():
    pid = os.getppid()
    for _ in range(6):
        try:
            with open(f"/proc/{pid}/cmdline", "rb") as f:
                args = f.read().split(b"\0")
            if b"--channels" in args:
                return True
            with open(f"/proc/{pid}/stat") as f:
                pid = int(f.read().rsplit(")", 1)[1].split()[1])
        except (OSError, ValueError, IndexError):
            return False
        if pid <= 1:
            return False
    return False


def last_chat_id(paths):
    for path in paths:
        try:
            with open(path, errors="ignore") as f:
                ids = CHAT_ID_RE.findall(f.read())
        except OSError:
            continue
        if ids:
            return ids[-1]
    return None


data = json.load(sys.stdin)
if not channel_session():
    sys.exit(0)

CACHE = os.path.expanduser("~/.claude/channels/discord/last_chat_id")
chat_id = last_chat_id([data.get("transcript_path", "")])
if not chat_id:
    try:
        with open(CACHE) as f:
            chat_id = f.read().strip() or None
    except OSError:
        pass
if not chat_id:
    try:
        found = subprocess.run(
            ["grep", "-rlE", "--include=*.jsonl", r'source=\\"(plugin:discord:)?discord\\" chat_id=\\"[0-9]',
             os.path.expanduser("~/.claude/projects")],
            capture_output=True, text=True, timeout=8,
        ).stdout.split()
        chat_id = last_chat_id(sorted(found, key=os.path.getmtime, reverse=True))
    except (subprocess.TimeoutExpired, OSError):
        pass
if chat_id:
    try:
        with open(CACHE, "w") as f:
            f.write(chat_id)
    except OSError:
        pass
target = f"chat_id {chat_id}" if chat_id else "the chat_id of the user's latest Discord message"

print(
    "Blocked by guard-channel-question: this is a Discord channel session, so the AskUserQuestion popup never reaches "
    "the user and blocks Discord messages. Instead, send the same question with the discord `reply` tool to "
    f"{target}: the question, then every option numbered (1., 2., …) with its description, the Recommended one first, "
    "and the line \"Trả lời bằng số hoặc gõ câu trả lời khác.\" Send one reply per question. Then end your turn "
    "without doing the work that depends on the answer; the user's next Discord message is the answer.",
    file=sys.stderr,
)
sys.exit(2)
