return {
  "folke/trouble.nvim",
  cmd = "Trouble",
  dependencies = { "nvim-tree/nvim-web-devicons", "folke/todo-comments.nvim" },
  opts = {
    modes = {
      lsp_popup = {
        mode = "lsp",
        focus = true,
        win = {
          type = "float",
          relative = "editor",
          border = "rounded",
          title = " LSP ",
          title_pos = "center",
          size = { width = 0.35, height = 0.6 },
          -- position is a fraction of the free space: list spans 10%-45% of the editor, preview 46%-90%
          position = { 0.5, 0.15 },
        },
        preview = {
          type = "float",
          relative = "editor",
          border = "rounded",
          title = " Preview ",
          title_pos = "center",
          size = { width = 0.44, height = 0.6 },
          position = { 0.5, 0.82 },
          zindex = 200,
        },
        keys = { ["<esc>"] = "close", ["<cr>"] = "jump_close", j = "next", k = "prev" },
      },
    },
  },
  keys = {
    { "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>", desc = "Workspace diagnostics (Trouble)" },
    { "<leader>xw", "<cmd>Trouble diagnostics toggle<CR>", desc = "Workspace diagnostics (Trouble)" },
    { "<leader>xd", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", desc = "Buffer diagnostics (Trouble)" },
    { "<leader>xq", "<cmd>Trouble qflist toggle<CR>", desc = "Quickfix list (Trouble)" },
    { "<leader>xl", "<cmd>Trouble loclist toggle<CR>", desc = "Location list (Trouble)" },
    { "<leader>xs", "<cmd>Trouble symbols toggle focus=false<CR>", desc = "Symbols (Trouble)" },
    { "<leader>xt", "<cmd>Trouble todo toggle<CR>", desc = "Todos (Trouble)" },
  },
}
