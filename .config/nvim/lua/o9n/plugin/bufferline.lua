local keys = {
  {
    "<A-q>",
    function()
      Snacks.bufdelete()
    end,
    desc = "Close current buffer",
  },
}
for i = 1, 9 do
  table.insert(keys, { "<A-" .. i .. ">", "<cmd>BufferLineGoToBuffer " .. i .. "<CR>", desc = "Go to tab " .. i })
end

return {
  "akinsho/bufferline.nvim",
  version = "*",
  event = "VeryLazy",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  keys = keys,
  opts = {
    options = {
      mode = "tabs",
      separator_style = "slant",
      always_show_bufferline = false,
      diagnostics = "nvim_lsp",
    },
  },
}
