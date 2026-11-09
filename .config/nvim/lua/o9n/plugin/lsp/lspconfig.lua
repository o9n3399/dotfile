local function on_attach(args)
  local buf = args.buf
  local client = vim.lsp.get_client_by_id(args.data.client_id)

  -- nowait: built-in grn/grr/gra... would otherwise delay `gr` by 'timeoutlen'
  local function map(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc, nowait = true })
  end

  map("n", "gd", function()
    Snacks.picker.lsp_definitions()
  end, "Go to definition")
  map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
  map("n", "gR", function()
    Snacks.picker.lsp_references()
  end, "Show references")
  map("n", "gi", function()
    Snacks.picker.lsp_implementations()
  end, "Go to implementation")
  map("n", "gt", function()
    Snacks.picker.lsp_type_definitions()
  end, "Go to type definition")
  map("n", "gh", function()
    Snacks.picker.lsp_references()
  end, "Show references")
  map("n", "gr", vim.lsp.buf.rename, "Rename symbol")
  map("n", "K", vim.lsp.buf.hover, "Hover documentation")
  map("i", "<C-s>", vim.lsp.buf.signature_help, "Signature help")
  map({ "n", "x" }, "<leader>ca", vim.lsp.buf.code_action, "Code action")
  map("n", "<leader>o", function()
    Snacks.picker.lsp_symbols()
  end, "Document symbols")
  map("n", "<leader>ci", function()
    Snacks.picker.lsp_incoming_calls()
  end, "Incoming calls")
  map("n", "<leader>co", function()
    Snacks.picker.lsp_outgoing_calls()
  end, "Outgoing calls")
  map("n", "<leader>rs", "<cmd>lsp restart<CR>", "Restart LSP")

  map("n", "<leader>sl", vim.diagnostic.open_float, "Line diagnostics")
  map("n", "<leader>sb", function()
    Snacks.picker.diagnostics_buffer()
  end, "Buffer diagnostics")
  map("n", "<leader>sw", function()
    Snacks.picker.diagnostics()
  end, "Workspace diagnostics")
  map("n", "[e", function()
    vim.diagnostic.jump({ count = -1, float = true })
  end, "Prev diagnostic")
  map("n", "]e", function()
    vim.diagnostic.jump({ count = 1, float = true })
  end, "Next diagnostic")
  map("n", "[E", function()
    vim.diagnostic.jump({ count = -1, float = true, severity = vim.diagnostic.severity.ERROR })
  end, "Prev error")
  map("n", "]E", function()
    vim.diagnostic.jump({ count = 1, float = true, severity = vim.diagnostic.severity.ERROR })
  end, "Next error")

  if client and client:supports_method("textDocument/inlayHint") then
    map("n", "<leader>ih", function()
      vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = buf }), { bufnr = buf })
    end, "Toggle inlay hints")
  end

  -- gI jumps to the .ts source instead of the .d.ts declaration
  if client and client.name == "ts_ls" then
    map("n", "gI", function()
      local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
      client:exec_cmd({
        title = "Go to source definition",
        command = "_typescript.goToSourceDefinition",
        arguments = { params.textDocument.uri, params.position },
      }, { bufnr = buf }, function(err, result)
        if err or not result or #result == 0 then
          vim.notify("No source definition found", vim.log.levels.INFO)
          return
        end
        vim.lsp.util.show_document(result[1], client.offset_encoding, { focus = true })
      end)
    end, "Go to source definition")
  end
end

local function config()
  local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
  vim.diagnostic.config({
    underline = true,
    update_in_insert = false,
    virtual_text = { spacing = 4, source = "if_many", prefix = "●" },
    severity_sort = true,
    float = { source = true },
    signs = {
      text = {
        [vim.diagnostic.severity.ERROR] = signs.Error,
        [vim.diagnostic.severity.WARN] = signs.Warn,
        [vim.diagnostic.severity.HINT] = signs.Hint,
        [vim.diagnostic.severity.INFO] = signs.Info,
      },
    },
  })

  vim.lsp.config("*", {
    capabilities = require("blink.cmp").get_lsp_capabilities({
      workspace = { fileOperations = { didRename = true, willRename = true } },
    }),
  })

  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("o9n_lsp_attach", { clear = true }),
    callback = on_attach,
  })
end

return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = { "saghen/blink.cmp" },
  config = config,
}
