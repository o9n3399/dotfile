#!/usr/bin/env python3
import glob
import os
import re
import sys
import time

days = float(sys.argv[1]) if len(sys.argv) > 1 and re.fullmatch(r"\d+(\.\d+)?", sys.argv[1]) else 3
cutoff = time.time() - days * 86400
plans = sorted((p for p in glob.glob(".dev-plan/*.md") if os.path.getmtime(p) >= cutoff), key=os.path.getmtime, reverse=True)
if not plans:
    print(f"No .dev-plan/*.md changed in the last {days:g} days under {os.getcwd()}")
    sys.exit(0)
for p in plans:
    text = open(p, errors="ignore").read()
    done = len(re.findall(r"^\s*- \[[xX]\]", text, re.M))
    todo = re.findall(r"^\s*- \[ \]\s*(.+)", text, re.M)
    status = re.search(r"^\s*[-*]?\s*\**Status\**:?\s*(.+)", text, re.M | re.I)
    age = (time.time() - os.path.getmtime(p)) / 3600
    print(f"{os.path.basename(p)} | {done}/{done + len(todo)} | {age:.0f}h ago"
          + (f" | status: {status.group(1)[:60]}" if status else "")
          + (f" | next: {todo[0][:90]}" if todo else " | all steps checked"))
