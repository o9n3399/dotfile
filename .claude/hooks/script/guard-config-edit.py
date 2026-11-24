#!/usr/bin/env python3
# PreToolUse(Write|Edit|MultiEdit) guard: editing an existing lint/format/type/test config asks the user first.
# Agents tend to loosen these configs to make checks pass instead of fixing the code (idea from ECC config-protection).
import json
import os
import re
import sys

from guard_switch import exit_if_off

exit_if_off("CONFIG")

PROTECTED = re.compile(
    r"^("
    r"\.eslintrc(\.(js|cjs|mjs|json|ya?ml))?|eslint\.config\.(js|cjs|mjs|ts|cts|mts)"
    r"|\.prettierrc(\.(js|cjs|mjs|json|json5|ya?ml|toml))?|prettier\.config\.(js|cjs|mjs|ts)"
    r"|biome\.jsonc?|\.stylelintrc(\.\w+)?|stylelint\.config\.(js|cjs|mjs)"
    r"|tsconfig(\.[\w-]+)?\.json"
    r"|jest\.config\.(js|cjs|mjs|ts|json)|vitest\.config\.(js|mjs|ts|mts)"
    r"|\.golangci\.ya?ml|ruff\.toml|\.ruff\.toml|\.flake8|mypy\.ini"
    r"|\.lintstagedrc(\.\w+)?|commitlint\.config\.(js|cjs|mjs|ts)"
    r")$"
)

path = json.load(sys.stdin).get("tool_input", {}).get("file_path", "")
if not path or not PROTECTED.match(os.path.basename(path)) or not os.path.exists(path):
    sys.exit(0)

print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "ask",
        "permissionDecisionReason": (
            f"guard-config-edit: {os.path.basename(path)} is a lint/format/type/test config. "
            "Approve only if this change was asked for; otherwise the code should be fixed instead of the config."
        ),
    }
}))
sys.exit(0)
