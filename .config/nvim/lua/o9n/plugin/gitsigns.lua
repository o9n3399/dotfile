local function on_attach(bufnr)
  local gs = require("gitsigns")

  local function map(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
  end

  map("n", "]h", function()
    gs.nav_hunk("next")
  end, "Next hunk")
  map("n", "[h", function()
    gs.nav_hunk("prev")
  end, "Prev hunk")

  map("n", "<leader>hs", gs.stage_hunk, "Stage/unstage hunk")
  map("n", "<leader>hr", gs.reset_hunk, "Reset hunk")
  map("x", "<leader>hs", function()
    gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
  end, "Stage/unstage selected lines")
  map("x", "<leader>hr", function()
    gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
  end, "Reset selected lines")
  map("n", "<leader>hS", gs.stage_buffer, "Stage buffer")
  map("n", "<leader>hR", gs.reset_buffer, "Reset buffer")
  map("n", "<leader>hp", gs.preview_hunk_inline, "Preview hunk inline")

  map("n", "<leader>hb", function()
    gs.blame_line({ full = true })
  end, "Blame line")
  map("n", "<leader>hB", gs.toggle_current_line_blame, "Toggle line blame")
  map("n", "<leader>hd", gs.diffthis, "Diff this")
  map("n", "<leader>hD", function()
    gs.diffthis("~")
  end, "Diff this ~")

  map({ "o", "x" }, "ih", gs.select_hunk, "Select hunk")
end

return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    signs = {
      add = { text = "+" },
      change = { text = "-" },
      delete = { text = "_" },
      topdelete = { text = "‾" },
      changedelete = { text = "~" },
      untracked = { text = "┆" },
    },
    numhl = true,
    attach_to_untracked = true,
    current_line_blame = true,
    current_line_blame_opts = { delay = 500, ignore_whitespace = true },
    current_line_blame_formatter = "<author>, <author_time:%Y-%m-%d> - <summary>",
    on_attach = on_attach,
  },
}
