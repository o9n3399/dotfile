# dotfile

Personal dotfiles, tracked as the pieces of `~/.config` listed below.

## Contents

| Path | What it is | Status |
|---|---|---|
| [`.config/nvim`](.config/nvim) | Neovim config, [lazy.nvim](https://github.com/folke/lazy.nvim)-based, namespace `o9n` | Active — see [`.config/nvim/CLAUDE.md`](.config/nvim/CLAUDE.md) for architecture, keymaps, LSP setup |
| `.config/nvim.packer` | Older Neovim config, [packer.nvim](https://github.com/wbthomason/packer.nvim)-based | Legacy — unmaintained since the initial commit (Apr 2025), superseded by `.config/nvim`, kept for reference only |
| [`.config/tmux`](.config/tmux) | tmux config, [TPM](https://github.com/tmux-plugins/tpm)-based | Active — see [`docs/tmux.md`](docs/tmux.md) |

## docs/

Reference notes that don't have tracked config files in this repo (machine-level setup, not `.config/` pieces):

- [`docs/spotify.md`](docs/spotify.md) — Spotify + Spicetify theming setup on this machine

## Usage

Symlink the pieces you want into `~/.config`, e.g.:

```sh
ln -s ~/dotfile/.config/nvim ~/.config/nvim
ln -s ~/dotfile/.config/tmux ~/.config/tmux
```
