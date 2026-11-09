local prettier = { "prettierd", "prettier", stop_after_first = true }

return {
  "stevearc/conform.nvim",
  event = "BufWritePre",
  cmd = { "ConformInfo", "FormatToggle" },
  keys = {
    {
      "<leader>mp",
      function()
        require("conform").format({ async = false, timeout_ms = 1000 })
      end,
      mode = { "n", "x" },
      desc = "Format file or range",
    },
  },
  opts = {
    default_format_opts = { lsp_format = "fallback" },
    formatters_by_ft = {
      javascript = prettier,
      typescript = prettier,
      javascriptreact = prettier,
      typescriptreact = prettier,
      svelte = prettier,
      css = prettier,
      scss = prettier,
      html = prettier,
      json = prettier,
      jsonc = prettier,
      yaml = prettier,
      markdown = prettier,
      graphql = prettier,
      liquid = prettier,
      lua = { "stylua" },
      python = { "isort", "black" },
      rust = { "rustfmt" },
    },
    format_on_save = function(bufnr)
      if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
        return
      end
      return { timeout_ms = 1000 }
    end,
  },
  init = function()
    vim.api.nvim_create_user_command("FormatToggle", function(args)
      local scope = args.bang and vim.b or vim.g
      scope.disable_autoformat = not scope.disable_autoformat
      vim.notify("Format on save " .. (scope.disable_autoformat and "disabled" or "enabled"))
    end, { bang = true, desc = "Toggle format on save (! for current buffer only)" })
  end,
}
