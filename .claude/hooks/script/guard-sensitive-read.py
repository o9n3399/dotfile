#!/usr/bin/env python3
# PreToolUse guard: block Read/Bash access to secret files (.env, private keys, certificates); .env.example and friends stay readable.
import json
import os
import re
import sys

SECRET_FILE = re.compile(r"(^|[\s/'\"=])(\.env(\.(?!example\b|sample\b|template\b)[\w.-]+)?|[\w.-]+\.(pem|key|p12|pfx|jks)|id_(rsa|ed25519|ecdsa))(?=$|[\s'\";|&)])")
# Exclusion flags name secret files only to skip them, e.g. grep --exclude=.env or rg -g '!*.pem'.
EXCLUDE_FLAG = re.compile(r"--exclude(-dir)?=\S+|--exclude(-dir)?\s+\S+|(-g|--glob)[=\s]+['\"]?!\S+")


def block(target):
    print(f"Blocked by guard-sensitive-read: {target} may hold secrets — read variable names from .env.example and code instead", file=sys.stderr)
    sys.exit(2)


data = json.load(sys.stdin)
tool_input = data.get("tool_input", {})

if data.get("tool_name") == "Read":
    path = tool_input.get("file_path", "")
    if SECRET_FILE.search(" " + os.path.basename(path)):
        block(path)
else:
    cmd = EXCLUDE_FLAG.sub(" ", tool_input.get("command", ""))
    match = SECRET_FILE.search(cmd)
    if match:
        block(match.group(2))

sys.exit(0)
