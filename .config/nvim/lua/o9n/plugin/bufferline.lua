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
  table.insert(keys, { "<A-" .. i .. ">", "<cmd>BufferLineGoToBuffer " .. i .. "<CR>", desc = "Go to buffer " .. i })
end

return {
  "akinsho/bufferline.nvim",
  version = "*",
  event = "VeryLazy",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  keys = keys,
  opts = {
    options = {
      mode = "buffers",
      separator_style = "thin",
      diagnostics = "nvim_lsp",
    },
    highlights = function(defaults)
      local hl = vim.deepcopy(defaults.highlights)
      for _, group in pairs(hl) do
        group.bg = "NONE"
      end
      return hl
    end,
  },
}
