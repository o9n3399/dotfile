local ensure_installed = {
  "json",
  "javascript",
  "typescript",
  "tsx",
  "yaml",
  "html",
  "css",
  "prisma",
  "markdown",
  "markdown_inline",
  "svelte",
  "graphql",
  "bash",
  "lua",
  "vim",
  "dockerfile",
  "gitignore",
  "query",
  "vimdoc",
  "c",
  "http",
  "go",
  "rust",
}

local function config()
  require("nvim-treesitter").setup({})

  local installed = require("nvim-treesitter.config").get_installed("parsers")
  local installed_set = {}
  for _, p in ipairs(installed) do
    installed_set[p] = true
  end
  local missing = {}
  for _, p in ipairs(ensure_installed) do
    if not installed_set[p] then
      table.insert(missing, p)
    end
  end
  if #missing > 0 then
    require("nvim-treesitter").install(missing)
  end

  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("o9n_treesitter", { clear = true }),
    callback = function(args)
      pcall(vim.treesitter.start, args.buf)
      pcall(function()
        vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end)
    end,
  })
end

return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  event = { "BufReadPre", "BufNewFile" },
  build = function()
    require("nvim-treesitter").update()
  end,
  dependencies = {
    "windwp/nvim-ts-autotag",
  },
  config = config,
}
