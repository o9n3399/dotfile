vim.g.mapleader = "\\"
vim.g.maplocalleader = "\\"

local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.cursorline = false
opt.signcolumn = "yes"
opt.wrap = false
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.termguicolors = true
opt.background = "dark"
opt.showmode = false
opt.laststatus = 3
opt.winborder = "rounded"
opt.pumheight = 10
opt.fillchars:append({ diff = "╱", eob = " " })

opt.tabstop = 2
opt.shiftwidth = 2
opt.softtabstop = 2
opt.expandtab = true
opt.autoindent = true
opt.smartindent = true

opt.ignorecase = true
opt.smartcase = true
opt.inccommand = "split"

opt.backspace = "indent,eol,start"
opt.clipboard:append("unnamedplus")
opt.splitright = true
opt.splitbelow = true
opt.confirm = true

opt.swapfile = false
opt.undofile = true
opt.updatetime = 250
opt.timeoutlen = 500

opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevel = 99

opt.wildignore:append({ "*/node_modules/*", "*/.git/*" })
