# tmux

Config: [`.config/tmux/tmux.conf`](../.config/tmux/tmux.conf)

## Plugin manager

[TPM](https://github.com/tmux-plugins/tpm), cloned to `~/.tmux/plugins/tpm`. After cloning, install plugins from inside tmux with `prefix + I`.

## Plugins in use

- `tmux-sensible` — sane defaults
- `vim-tmux-navigator` — seamless pane navigation between vim and tmux
- `tmux-yank` — copy to system clipboard
- `tmux-powerline` — statusline
- `catppuccin-tmux` — present in the plugin list but commented out (disabled)

## Behavior

- Copy mode uses vi keys (`mode-keys vi`)
- Windows and panes are 1-indexed (`base-index 1`, `pane-base-index 1`), auto-renumbered
- Mouse support on
- Status bar background follows terminal default (`status-style bg=default`)

## Key bindings

| Key | Action |
|---|---|
| `M-h` / `M-j` / `M-k` / `M-l` | Switch pane (no prefix needed) |
| `prefix + H` / `J` / `K` / `L` | Resize pane (left/down/up/right) |
| `v` (copy-mode-vi) | Begin selection |
| `C-v` (copy-mode-vi) | Toggle rectangle selection |
| `y` (copy-mode-vi) | Copy selection and exit copy mode |
