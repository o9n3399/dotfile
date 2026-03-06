# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal Neovim configuration using **lazy.nvim** as the plugin manager. The config namespace is `o9n` (used throughout all module paths).

## Architecture

### Entry Point & Load Order
```
init.lua → require("o9n.core") → option.lua + keymap.lua
         → require("o9n.lazy") → lazy.nvim setup → require("o9n.snippet")
```

### Directory Structure
- `lua/o9n/core/` — Base vim options (`option.lua`) and global keymaps (`keymap.lua`)
- `lua/o9n/plugin/` — Plugin configs, each file returns a lazy.nvim plugin spec
- `lua/o9n/plugin/lsp/` — LSP-related plugins (mason, lspconfig, lspsaga)
- `lua/o9n/plugin/dap/` — Debug adapter configs
- `lua/o9n/plugin/ai/` — AI tool integrations (claudecode, codeium, augment-code)
- `after/queries/` — Custom treesitter queries

### Plugin Spec Convention
Every plugin file in `lua/o9n/plugin/` follows this pattern:
```lua
function config()
  -- plugin setup
end

return {
  "author/plugin-name",
  dependencies = { ... },
  config = config,  -- or config = true for defaults
}
```

The `lazy.lua` file imports all four plugin directories as separate lazy.nvim import groups.

## Formatting & Linting

**Lua files**: Formatted with `stylua` (2-space indent, spaces — see `.stylua.toml`)

**Format command**: `stylua lua/` or `:lua require("conform").format()` in Neovim

**Web/JS/TS**: `prettier` (auto on save via conform.nvim)
**Python**: `isort` + `black` (auto on save)
**JS/TS linting**: `eslint_d` (runs on BufEnter, BufWritePost, InsertLeave)

## LSP Servers (managed by Mason)

Auto-installed: `rust_analyzer`, `html`, `cssls`, `lua_ls`, `pyright`, `bashls`, `gopls`, `ts_ls`, `harper_ls`

`lua_ls` is configured to recognize the `vim` global for Neovim Lua development.

## Key Mappings Reference

**Leader**: `<Space>` (default lazy.nvim)

| Key | Action |
|-----|--------|
| `<leader>ff` | Telescope find files |
| `<leader>fs` | Telescope live grep |
| `<leader>mp` | Format file (conform) |
| `<leader>l` | Trigger linting |
| `sv` / `sh` | Split window vertical/horizontal |
| `sj/sk/sl/sh` | Navigate splits |
| `<leader>ac` | Toggle Claude Code |
| `<leader>ab` | Add current buffer to Claude |
| `<leader>aa` / `<leader>ad` | Accept/Deny Claude diff |

## Adding a New Plugin

Create a new file in `lua/o9n/plugin/` (or a subdirectory) returning a lazy.nvim spec. It will be auto-imported on next Neovim startup.

## Snippets

LuaSnip snippets live in `lua/o9n/snippet/`, loaded via `require("o9n.snippet")` at the end of `lazy.lua`.

| File | Filetypes | Triggers |
|------|-----------|---------|
| `typescript.lua` | typescript, javascript | `db`, `jlog`, `tlog` |
| `cpp.lua` | cpp | `db` |
| `ai.lua` | markdown | `ai-debug`, `ai-fix`, `ai-task`, `ai-refactor`, `ai-review`, `ai-explain`, `ai-optimize`, `ai-docs`, `ai-security`, `ai-design`, `ai-migrate` |

To add snippets for a new language, create `lua/o9n/snippet/<lang>.lua` and add a `require` line to `lua/o9n/snippet/init.lua`.
