# CLAUDE.md

Personal Neovim (0.12+) config using **lazy.nvim**. Namespace: `o9n`.

## Load Order
```
init.lua → o9n.core (option → keymap → autocmd) → o9n.lazy (imports plugin/, plugin/lsp, plugin/dap)
```
`mapleader` is `\` and is set in `core/option.lua` before lazy.nvim loads.

## Layout
- `lua/o9n/core/` — options, global keymaps, autocmds
- `lua/o9n/plugin/` — one lazy.nvim spec per file (`return { "author/repo", opts = {...} }`); prefer `opts`/`keys` over a `config` function, and keep helpers `local`
- `lua/o9n/plugin/lsp/` — nvim-lspconfig (diagnostics + `LspAttach` keymaps), mason + mason-lspconfig (`automatic_enable`), lazydev
- `after/lsp/<server>.lua` — per-server overrides returning a `vim.lsp.Config` (native `vim.lsp.config` merges them)
- `lua/o9n/snippet/` — LuaSnip snippets, loaded from the LuaSnip spec in `plugin/blink-cmp.lua`
- `after/queries/` — custom treesitter queries

## Core Plugins
- **snacks.nvim** — picker, explorer, input, notifier, indent, lazygit, terminal, zoom, words
- **blink.cmp** — completion (sources: lazydev, lsp, LuaSnip, path, buffer)
- **conform.nvim** — format on save (`:FormatToggle`, `:FormatToggle!` for buffer); prettierd → prettier, stylua, isort+black, rustfmt
- **nvim-lint** — eslint_d, pylint
- Commenting is native `gc` with nvim-ts-context-commentstring

## Key Mappings
| Key | Action |
|-----|--------|
| `<leader>ff` / `fs` / `fr` / `fb` / `fc` | Files / grep / recent / buffers / grep word |
| `<leader>ee` / `ef` | Explorer toggle / reveal file |
| `<leader>lg` | Lazygit |
| `gd` `gR` `gi` `gt` `gI` | Definition / references / impl / type def / TS source def |
| `gr` `K` `<leader>ca` | Rename / hover / code action |
| `gp` | Peek definition in a float (q/Esc closes) |
| `gh` | All LSP locations (defs, refs, impls, types) in a Trouble popup (Esc closes) |
| `[e` `]e` `[E` `]E` | Diagnostics / errors |
| `<leader>sl` `sb` `sw` | Line / buffer / workspace diagnostics |
| `]h` `[h` `<leader>h*` | Git hunks (gitsigns) |
| `<leader>x*` | Trouble |
| `<leader>mp` | Format |
| `ss` / `sv`, `sh/sj/sk/sl` | Split / navigate windows |
| `<leader>sm` | Zoom split |
| `<F6>` | Floating terminal |
| `<C-/>` | Toggle comment |

## Formatting
Lua: `stylua lua after` (2 spaces, see `.stylua.toml`).
