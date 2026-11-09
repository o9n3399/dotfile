return {
  "mason-org/mason-lspconfig.nvim",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    { "mason-org/mason.nvim", cmd = "Mason", opts = {} },
    "neovim/nvim-lspconfig",
    {
      "WhoIsSethDaniel/mason-tool-installer.nvim",
      opts = {
        ensure_installed = {
          "prettierd",
          "prettier",
          "stylua",
          "isort",
          "black",
          "pylint",
          "eslint_d",
          "golangci-lint-langserver",
          "rustfmt",
          "tree-sitter-cli",
        },
      },
    },
  },
  opts = {
    ensure_installed = {
      "rust_analyzer",
      "html",
      "cssls",
      "lua_ls",
      "pyright",
      "bashls",
      "gopls",
      "ts_ls",
      "harper_ls",
    },
    -- stylua is a formatter run by conform; `stylua --lsp` must not be started
    automatic_enable = { exclude = { "stylua" } },
  },
}
