#!/usr/bin/env python3
# PreToolUse guard for Bash: block file writes that bypass Edit/Write (sed -i, perl -pi, redirects, tee, python writes).
# Temp files under /tmp or /dev stay allowed; project tools (prettier --write, eslint --fix) are not redirects and pass.
import json
import re
import sys

cmd = json.load(sys.stdin).get("tool_input", {}).get("command", "")

body = re.sub(r"<<-?\s*(['\"]?)(\w+)\1([^\n]*)\n.*?\n\s*\2\s*(\n|$)", r"<<HEREDOC\3\n", cmd, flags=re.S)
body = re.sub(r"(>{1,2}|\btee\s+(?:-a\s+)?)\s*([\"'])([^\"'\s]+)\2", r"\1 \3", body)
bare = re.sub(r"'[^']*'|\"(?:\\.|[^\"\\])*\"", "''", body)
in_tmp = re.match(r"\s*cd\s+[\"']?/tmp/", cmd) is not None

def temp(target):
    t = target.strip("\"'")
    return t.startswith(("/tmp/", "/dev/", "$", "${")) or (in_tmp and not t.startswith("/"))

reason = None
if re.search(r"\bsed\b[^|;&\n]*\s(-[a-zA-Z]*i|--in-place)|\bperl\s+-\w*[pi]\w*i|\bperl\s+-i", bare):
    reason = "in-place sed/perl"
else:
    for m in re.finditer(r"(?<![0-9&<>=-])>{1,2}\|?\s*([^\s;|&)<>]+)", bare):
        if not temp(m.group(1)):
            reason = f"redirect to {m.group(1)}"
            break
    if not reason:
        for m in re.finditer(r"\btee\s+(?:-a\s+)?([^\s;|&)]+)", bare):
            if not temp(m.group(1)):
                reason = f"tee to {m.group(1)}"
                break
    if not reason and re.search(r"\.write_text\(|open\([^)]*,\s*['\"][wa]b?\+?['\"]", cmd) and "/tmp/" not in cmd:
        reason = "python file write"

if reason:
    print(f"Blocked by guard-bash-write ({reason}): change repo files with Edit (after Read) or Write for a new file. "
          "Temp files under /tmp are fine; run formatters or generators directly.", file=sys.stderr)
    sys.exit(2)
sys.exit(0)
