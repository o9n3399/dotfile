local inlay_hints = {
  includeInlayParameterNameHints = "literals",
  includeInlayFunctionParameterTypeHints = true,
  includeInlayPropertyDeclarationTypeHints = true,
  includeInlayFunctionLikeReturnTypeHints = true,
  includeInlayEnumMemberValueHints = true,
}

---@type vim.lsp.Config
return {
  settings = {
    typescript = { inlayHints = inlay_hints, updateImportsOnFileMove = { enabled = "always" } },
    javascript = { inlayHints = inlay_hints, updateImportsOnFileMove = { enabled = "always" } },
  },
}
