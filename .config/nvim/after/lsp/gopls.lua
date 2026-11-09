-- lspconfig default includes gotmpl, which Neovim has no filetype for
---@type vim.lsp.Config
return {
  filetypes = { "go", "gomod", "gowork" },
}
