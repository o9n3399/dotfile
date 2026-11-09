local function open_peek(item)
  local buf = vim.fn.bufadd(item.filename)
  vim.fn.bufload(buf)

  local width = math.floor(vim.o.columns * 0.7)
  local height = math.floor(vim.o.lines * 0.5)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    border = "rounded",
    title = " " .. vim.fn.fnamemodify(item.filename, ":~:.") .. " ",
    title_pos = "center",
  })
  vim.api.nvim_win_set_cursor(win, { item.lnum, math.max(item.col - 1, 0) })
  vim.cmd("normal! zt")

  local function close()
    pcall(vim.api.nvim_win_close, win, true)
  end
  local close_keys = { "q", "<Esc>" }
  for _, key in ipairs(close_keys) do
    vim.keymap.set("n", key, close, { buffer = buf, nowait = true, desc = "Close peek" })
  end

  vim.api.nvim_create_autocmd("WinLeave", {
    buffer = buf,
    callback = function()
      if vim.api.nvim_get_current_win() == win then
        close()
        return true
      end
    end,
  })
  -- the peeked buffer is a real file buffer; drop the close keys so q/<Esc> work normally later
  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(win),
    once = true,
    callback = function()
      for _, key in ipairs(close_keys) do
        pcall(vim.keymap.del, "n", key, { buffer = buf })
      end
    end,
  })
end

local function peek_definition()
  vim.lsp.buf.definition({
    on_list = function(list)
      if list.items[1] then
        open_peek(list.items[1])
      end
    end,
  })
end

local function on_attach(args)
  local buf = args.buf
  local client = vim.lsp.get_client_by_id(args.data.client_id)

  -- nowait: built-in grn/grr/gra... would otherwise delay `gr` by 'timeoutlen'
  local function map(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc, nowait = true })
  end

  local list_only = { auto_confirm = false }

  map("n", "gd", function()
    Snacks.picker.lsp_definitions(list_only)
  end, "Go to definition")
  map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
  map("n", "gp", peek_definition, "Peek definition")
  map("n", "gR", function()
    Snacks.picker.lsp_references(list_only)
  end, "Show references")
  map("n", "gi", function()
    Snacks.picker.lsp_implementations(list_only)
  end, "Go to implementation")
  map("n", "gt", function()
    Snacks.picker.lsp_type_definitions(list_only)
  end, "Go to type definition")
  map("n", "gh", function()
    local view = require("trouble").open({ mode = "lsp_popup" })
    if view then
      -- start on the first location so the preview shows immediately, not on a group header
      view:wait(function()
        view:move({ idx = 1 })
      end)
    end
  end, "LSP locations (Trouble)")
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
    vim.diagnostic.jump({ count = -1 })
  end, "Prev diagnostic")
  map("n", "]e", function()
    vim.diagnostic.jump({ count = 1 })
  end, "Next diagnostic")
  map("n", "[E", function()
    vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR })
  end, "Prev error")
  map("n", "]E", function()
    vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR })
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
  local signs = { Error = "\u{f057} ", Warn = "\u{f071} ", Hint = "\u{f0820} ", Info = "\u{f05a} " }
  vim.diagnostic.config({
    underline = true,
    virtual_text = false,
    signs = {
      text = {
        [vim.diagnostic.severity.ERROR] = signs.Error,
        [vim.diagnostic.severity.WARN] = signs.Warn,
        [vim.diagnostic.severity.HINT] = signs.Hint,
        [vim.diagnostic.severity.INFO] = signs.Info,
      },
    },
    update_in_insert = false,
    severity_sort = true,
    float = { source = true, border = "rounded" },
    jump = {
      on_jump = function(diagnostic, bufnr)
        if diagnostic then
          vim.diagnostic.open_float({ bufnr = bufnr, scope = "cursor", focus = false })
        end
      end,
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
