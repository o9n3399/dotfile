#!/usr/bin/env python3
# PreToolUse guard: only allow Write/Edit inside directories named by argv (e.g. .dev-plan agent-memory-local .dev-plan/research),
# or to files matching a basename pattern (e.g. '*.md').
import fnmatch
import json
import os
import sys

allowed = sys.argv[1:]
path = json.load(sys.stdin).get("tool_input", {}).get("file_path", "")

# Resolve ".." and symlinks so "/repo/.dev-plan/../src/x" can't slip through.
parts = os.path.realpath(path).split(os.sep)

def inside(scope):
    if "*" in scope:
        return fnmatch.fnmatch(parts[-1], scope)
    # A multi-segment scope like ".dev-plan/research" must appear as consecutive path components.
    seg = scope.split("/")
    dirs = parts[:-1]
    return any(dirs[i:i + len(seg)] == seg for i in range(len(dirs) - len(seg) + 1))


if not any(inside(d) for d in allowed):
    print(f"Blocked by guard-write-scope: writes are limited to {', '.join(allowed)}/ (got {path})", file=sys.stderr)
    sys.exit(2)

sys.exit(0)
