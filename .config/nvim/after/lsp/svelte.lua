---@type vim.lsp.Config
return {
  on_attach = function(client)
    vim.api.nvim_create_autocmd("BufWritePost", {
      group = vim.api.nvim_create_augroup("o9n_svelte_ts_notify", { clear = true }),
      pattern = { "*.js", "*.ts" },
      callback = function(ctx)
        client:notify("$/onDidChangeTsOrJsFile", { uri = ctx.match })
      end,
    })
  end,
}
