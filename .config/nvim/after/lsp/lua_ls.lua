---@type vim.lsp.Config
return {
  settings = {
    Lua = {
      workspace = { checkThirdParty = false },
      completion = { callSnippet = "Replace" },
      hint = { enable = true, setType = false, paramName = "Disable", arrayIndex = "Disable" },
      diagnostics = { unusedLocalExclude = { "_*" } },
    },
  },
}
