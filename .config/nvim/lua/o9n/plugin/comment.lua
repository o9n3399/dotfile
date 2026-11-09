-- Native `gc` commenting (nvim 0.10+) reads 'commentstring'; this makes it
-- context-aware for embedded languages like JSX, Svelte and Vue.
return {
  "JoosepAlviste/nvim-ts-context-commentstring",
  event = { "BufReadPre", "BufNewFile" },
  init = function()
    vim.g.skip_ts_context_commentstring_module = true
  end,
  config = function()
    require("ts_context_commentstring").setup({ enable_autocmd = false })
    local get_option = vim.filetype.get_option
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.filetype.get_option = function(filetype, option)
      if option == "commentstring" then
        return require("ts_context_commentstring.internal").calculate_commentstring() or get_option(filetype, option)
      end
      return get_option(filetype, option)
    end
  end,
}
