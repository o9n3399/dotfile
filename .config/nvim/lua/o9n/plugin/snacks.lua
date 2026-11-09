local function picker(name, opts)
  return function()
    Snacks.picker[name](opts)
  end
end

return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = {
    bigfile = { enabled = true },
    quickfile = { enabled = true },
    input = { enabled = true },
    notifier = { enabled = true },
    indent = { enabled = true, animate = { enabled = false } },
    words = { enabled = true },
    explorer = { enabled = true, replace_netrw = true },
    lazygit = { enabled = true },
    picker = {
      enabled = true,
      sources = {
        files = { hidden = true },
        grep = { hidden = true },
        explorer = { hidden = true, ignored = true, layout = { layout = { position = "right", width = 50 } } },
      },
      win = {
        input = {
          keys = {
            ["<C-j>"] = { "list_down", mode = { "i", "n" } },
            ["<C-k>"] = { "list_up", mode = { "i", "n" } },
          },
        },
      },
    },
  },
  keys = {
    { "<leader>ff", picker("files"), desc = "Find files" },
    { "<leader>fr", picker("recent", { filter = { cwd = true } }), desc = "Recent files" },
    { "<leader>fs", picker("grep"), desc = "Grep in cwd" },
    { "<leader>fc", picker("grep_word"), desc = "Grep word under cursor", mode = { "n", "x" } },
    { "<leader>fb", picker("buffers"), desc = "Buffers" },
    { "<leader>fh", picker("help"), desc = "Help pages" },
    { "<leader>fk", picker("keymaps"), desc = "Keymaps" },
    { "<leader>fd", picker("diagnostics"), desc = "Diagnostics" },
    { "<leader>fn", picker("notifications"), desc = "Notifications" },
    { "<leader>f;", picker("resume"), desc = "Resume last picker" },
    {
      "<leader>ft",
      function()
        Snacks.picker.todo_comments()
      end,
      desc = "Find todos",
    },

    {
      "<leader>ee",
      function()
        Snacks.explorer()
      end,
      desc = "Toggle file explorer",
    },
    {
      "<leader>ef",
      function()
        Snacks.explorer.reveal()
      end,
      desc = "Reveal current file in explorer",
    },

    {
      "<leader>lg",
      function()
        Snacks.lazygit()
      end,
      desc = "Lazygit",
    },
    {
      "<leader>gl",
      function()
        Snacks.lazygit.log_file()
      end,
      desc = "Lazygit log of current file",
    },
    {
      "<F6>",
      function()
        Snacks.terminal.toggle(nil, { win = { position = "float" } })
      end,
      desc = "Toggle floating terminal",
      mode = { "n", "t" },
    },
    {
      "<leader>sm",
      function()
        Snacks.zen.zoom()
      end,
      desc = "Maximize/restore split",
    },
    {
      "<leader>cR",
      function()
        Snacks.rename.rename_file()
      end,
      desc = "Rename file (updates imports)",
    },
    {
      "]]",
      function()
        Snacks.words.jump(vim.v.count1)
      end,
      desc = "Next reference",
    },
    {
      "[[",
      function()
        Snacks.words.jump(-vim.v.count1)
      end,
      desc = "Prev reference",
    },
  },
}
