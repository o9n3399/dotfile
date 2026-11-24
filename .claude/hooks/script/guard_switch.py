import os
import sys

OFF_VALUES = {"off", "0", "false", "no"}


def exit_if_off(name):
    """Let a guard be disabled per session or per project, e.g. CLAUDE_GUARD_SECRETS=off in a test repo's settings env."""
    if os.environ.get(f"CLAUDE_GUARD_{name}", "").strip().lower() in OFF_VALUES:
        sys.exit(0)
