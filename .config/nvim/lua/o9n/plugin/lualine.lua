local colors = {
  blue = "#65D1FF",
  green = "#3EFFDC",
  violet = "#FF61EF",
  yellow = "#FFDA7B",
  red = "#FF4A4A",
  fg = "#c3ccdc",
  bg = "NONE",
  dark = "#112638",
}

local function mode_theme(accent)
  return {
    a = { bg = accent, fg = colors.dark, gui = "bold" },
    b = { bg = colors.bg, fg = colors.fg },
    c = { bg = colors.bg, fg = colors.fg },
  }
end

local function config()
  local lazy_status = require("lazy.status")

  require("lualine").setup({
    options = {
      theme = {
        normal = mode_theme(colors.blue),
        insert = mode_theme(colors.green),
        visual = mode_theme(colors.violet),
        command = mode_theme(colors.yellow),
        replace = mode_theme(colors.red),
        inactive = mode_theme(colors.fg),
      },
      globalstatus = true,
      disabled_filetypes = { statusline = { "snacks_dashboard" } },
    },
    sections = {
      lualine_c = { { "filename", path = 1 } },
      lualine_x = {
        {
          function()
            return "recording @" .. vim.fn.reg_recording()
          end,
          cond = function()
            return vim.fn.reg_recording() ~= ""
          end,
          color = { fg = colors.red },
        },
        { lazy_status.updates, cond = lazy_status.has_updates, color = { fg = "#ff9e64" } },
        "encoding",
        "fileformat",
        "filetype",
      },
    },
  })
end

return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = config,
}
