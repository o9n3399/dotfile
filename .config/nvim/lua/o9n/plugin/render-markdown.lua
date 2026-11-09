local function config()
  local render_markdown = require("render-markdown")

  render_markdown.setup({
    overrides = {
      -- LSP hover floats are nofile markdown buffers; keep them transparent
      buftype = {
        nofile = {
          render_modes = true,
          sign = { enabled = false },
          code = { disable_background = true, border = "hide", language = false },
        },
      },
    },
  })

  vim.keymap.set("n", "<leader>mr", render_markdown.toggle, { desc = "Toggle markdown render" })
end

return {
  "MeanderingProgrammer/render-markdown.nvim",
  ft = { "markdown" },
  dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
  config = config,
}
