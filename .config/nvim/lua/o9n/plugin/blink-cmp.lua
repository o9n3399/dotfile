return {
  "saghen/blink.cmp",
  version = "1.*",
  event = { "InsertEnter", "CmdlineEnter" },
  dependencies = {
    {
      "L3MON4D3/LuaSnip",
      version = "v2.*",
      build = "make install_jsregexp",
      dependencies = { "rafamadriz/friendly-snippets" },
      config = function()
        require("luasnip.loaders.from_vscode").lazy_load()
        require("o9n.snippet")
      end,
    },
  },
  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    snippets = { preset = "luasnip" },
    keymap = {
      preset = "none",
      ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
      ["<C-e>"] = { "hide", "fallback" },
      ["<CR>"] = { "accept", "fallback" },
      ["<C-j>"] = { "select_next", "fallback" },
      ["<C-k>"] = { "select_prev", "fallback" },
      ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
      ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
      ["<C-b>"] = { "scroll_documentation_up", "fallback" },
      ["<C-f>"] = { "scroll_documentation_down", "fallback" },
    },
    completion = {
      list = { selection = { preselect = false, auto_insert = false } },
      accept = { auto_brackets = { enabled = true } },
      documentation = { auto_show = true, auto_show_delay_ms = 200 },
      ghost_text = { enabled = true },
      menu = { draw = { treesitter = { "lsp" } } },
    },
    signature = { enabled = true },
    sources = {
      default = { "lazydev", "lsp", "snippets", "path", "buffer" },
      providers = {
        lazydev = { name = "LazyDev", module = "lazydev.integrations.blink", score_offset = 100 },
      },
    },
    cmdline = {
      keymap = { preset = "cmdline" },
      completion = { menu = { auto_show = true } },
    },
    fuzzy = { implementation = "prefer_rust_with_warning" },
  },
  opts_extend = { "sources.default" },
}
