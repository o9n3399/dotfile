local function config()
  local render_markdown = require("render-markdown")

  render_markdown.setup({})

  vim.keymap.set("n", "<leader>mr", render_markdown.toggle, { desc = "Toggle markdown render" })
end

return {
  "MeanderingProgrammer/render-markdown.nvim",
  ft = { "markdown" },
  dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
  config = config,
}
