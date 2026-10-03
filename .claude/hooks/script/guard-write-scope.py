#!/usr/bin/env python3
# PreToolUse guard: only allow Write/Edit inside directories named by argv (e.g. .dev-plan agent-memory-local).
import json
import os
import sys

allowed = sys.argv[1:]
path = json.load(sys.stdin).get("tool_input", {}).get("file_path", "")

# Resolve ".." and symlinks so "/repo/.dev-plan/../src/x" can't slip through.
parts = os.path.realpath(path).split(os.sep)

if not any(d in parts[:-1] for d in allowed):
    print(f"Blocked by guard-write-scope: writes are limited to {', '.join(allowed)}/ (got {path})", file=sys.stderr)
    sys.exit(2)

sys.exit(0)
