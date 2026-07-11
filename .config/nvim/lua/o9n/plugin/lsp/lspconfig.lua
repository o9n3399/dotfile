function config()
  -- import cmp-nvim-lsp plugin
  local cmp_nvim_lsp = require("cmp_nvim_lsp")

  -- local keymap = vim.keymap -- for conciseness
  -- vim.api.nvim_create_autocmd("LspAttach", {
  --   group = vim.api.nvim_create_augroup("UserLspConfig", {}),
  --   callback = function(ev)
  --     -- Buffer local mappings.
  --     -- See `:help vim.lsp.*` for documentation on any of the below functions
  --     local opts = { buffer = ev.buf, silent = true }
  --
  --     -- set keybinds
  --     opts.desc = "Show LSP references"
  --     keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts) -- show definition, references
  --
  --     opts.desc = "Go to declaration"
  --     keymap.set("n", "gD", vim.lsp.buf.declaration, opts) -- go to declaration
  --
  --     opts.desc = "Show LSP definitions"
  --     keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts) -- show lsp definitions
  --
  --     opts.desc = "Show LSP implementations"
  --     keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts) -- show lsp implementations
  --
  --     opts.desc = "Show LSP type definitions"
  --     keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts) -- show lsp type definitions
  --
  --     opts.desc = "See available code actions"
  --     keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts) -- see available code actions, in visual mode will apply to selection
  --
  --     opts.desc = "Smart rename"
  --     keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts) -- smart rename
  --
  --     opts.desc = "Show buffer diagnostics"
  --     keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts) -- show  diagnostics for file
  --
  --     opts.desc = "Show line diagnostics"
  --     keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts) -- show diagnostics for line
  --
  --     opts.desc = "Go to previous diagnostic"
  --     keymap.set("n", "[d", vim.diagnostic.goto_prev, opts) -- jump to previous diagnostic in buffer
  --
  --     opts.desc = "Go to next diagnostic"
  --     keymap.set("n", "]d", vim.diagnostic.goto_next, opts) -- jump to next diagnostic in buffer
  --
  --     opts.desc = "Show documentation for what is under cursor"
  --     keymap.set("n", "K", vim.lsp.buf.hover, opts) -- show documentation for what is under cursor
  --
  --     opts.desc = "Restart LSP"
  --     keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts) -- mapping to restart lsp if necessary
  --   end,
  -- })

  -- used to enable autocompletion (assign to every lsp server config)
  local capabilities = cmp_nvim_lsp.default_capabilities()

  -- Change the Diagnostic symbols in the sign column (gutter)
  local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
  vim.diagnostic.config({
    underline = false,
    update_in_insert = false,
    virtual_text = false,
    -- virtual_text = { spacing = 4, prefix = "●" },
    severity_sort = true,
    signs = {
      active = true,
      text = {
        [vim.diagnostic.severity.ERROR] = signs.Error,
        [vim.diagnostic.severity.WARN] = signs.Warn,
        [vim.diagnostic.severity.HINT] = signs.Hint,
        [vim.diagnostic.severity.INFO] = signs.Info,
      },
    },
  })

  -- Apply cmp capabilities to every server (merged into each config).
  vim.lsp.config("*", {
    capabilities = capabilities,
  })

  -- lua_ls: recognize the "vim" global for Neovim config editing.
  vim.lsp.config("lua_ls", {
    settings = {
      Lua = {
        diagnostics = {
          globals = { "vim" },
        },
        completion = {
          callSnippet = "Replace",
        },
      },
    },
  })

  vim.lsp.config("rust_analyzer", {
    filetypes = { "rust" },
  })

  vim.lsp.config("svelte", {
    on_attach = function(client, bufnr)
      vim.api.nvim_create_autocmd("BufWritePost", {
        pattern = { "*.js", "*.ts" },
        callback = function(ctx)
          client.notify("$/onDidChangeTsOrJsFile", { uri = ctx.match })
        end,
      })
    end,
  })

  vim.lsp.config("harper_ls", {
    settings = {
      ["harper-ls"] = {
        userDictPath = "",
        fileDictPath = "",
        filetypes = { "markdown", "typescriptreact" },
        linters = {
          SpellCheck = true,
          SpelledNumbers = false,
          AnA = true,
          SentenceCapitalization = true,
          UnclosedQuotes = true,
          WrongQuotes = false,
          LongSentences = true,
          RepeatedWords = true,
          Spaces = true,
          Matcher = true,
          CorrectNumberSuffix = true,
        },
        codeActions = {
          ForceStable = false,
        },
        markdown = {
          IgnoreLinkTitle = false,
        },
        diagnosticSeverity = "hint",
        isolateEnglish = false,
        dialect = "American",
      },
    },
  })
end

return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    { "antosha417/nvim-lsp-file-operations", config = true },
    { "folke/neodev.nvim", opts = {} },
  },
  config = config,
}
