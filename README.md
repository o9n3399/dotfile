# dotfile

Personal dotfiles, tracked as the pieces of `~/.config` and `~/.claude` listed below.

## Contents

| Path | What it is | Status |
|---|---|---|
| [`.config/nvim`](.config/nvim) | Neovim config, [lazy.nvim](https://github.com/folke/lazy.nvim)-based, namespace `o9n` | Active — see [`.config/nvim/CLAUDE.md`](.config/nvim/CLAUDE.md) for architecture, keymaps, LSP setup |
| `.config/nvim.packer` | Older Neovim config, [packer.nvim](https://github.com/wbthomason/packer.nvim)-based | Legacy — unmaintained since the initial commit (Apr 2025), superseded by `.config/nvim`, kept for reference only |
| [`.config/tmux`](.config/tmux) | tmux config, [TPM](https://github.com/tmux-plugins/tpm)-based | Active — see [`docs/tmux.md`](docs/tmux.md) |
| [`.claude`](.claude) | Claude Code global config — `CLAUDE.md`, `settings.json`, `/dev*` commands, 8 agents (planner, researcher, coder, test-runner, reviewer, ui-verifier, doc-writer, git-agent), their skills and guard hooks; `mcp.json` holds the user-scope MCP servers | Active — snapshot copy, see Usage |

## docs/

Reference notes that don't have tracked config files in this repo (machine-level setup, not `.config/` pieces):

- [`docs/spotify.md`](docs/spotify.md) — Spotify + Spicetify theming setup on this machine

## Usage

Symlink the pieces you want into `~/.config`, e.g.:

```sh
ln -s ~/dotfile/.config/nvim ~/.config/nvim
ln -s ~/dotfile/.config/tmux ~/.config/tmux
```

`.claude` is a snapshot, not a symlink target as a whole — `~/.claude` also holds credentials, history and session data. Restore the tracked pieces with:

```sh
rsync -a --exclude mcp.json ~/dotfile/.claude/ ~/.claude/
jq -c '.mcpServers | to_entries[]' ~/dotfile/.claude/mcp.json | while read -r e; do
  claude mcp add-json --scope user "$(jq -r .key <<<"$e")" "$(jq -c .value <<<"$e")"
done
jq -r '.extraKnownMarketplaces // {} | .[].source.repo' ~/.claude/settings.json | xargs -rn1 claude plugin marketplace add
jq -r '.enabledPlugins // {} | keys[]' ~/.claude/settings.json | xargs -rn1 claude plugin install
```

Refresh the snapshot after changing the live config:

```sh
rsync -a --delete --exclude 'synced/' --exclude '.trash/' --exclude '__pycache__/' --exclude 'skills/.archive/' \
  --exclude-from=<(find ~/.claude/skills -name .ledger.jsonl -printf '%h/\n' | sed "s|^$HOME/.claude/||") \
  ~/.claude/{CLAUDE.md,settings.json,commands,agents,skills,hooks} ~/dotfile/.claude/
jq '{mcpServers}' ~/.claude.json > ~/dotfile/.claude/mcp.json
```

Skills learned by the autoharness plugin (any skill dir holding a `.ledger.jsonl`, plus `skills/.archive/`) are machine-local and stay out of the snapshot.
