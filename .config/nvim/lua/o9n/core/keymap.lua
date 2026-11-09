local keymap = vim.keymap

keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlights" })
keymap.set("n", "<leader>nh", "<cmd>nohlsearch<CR>", { desc = "Clear search highlights" })

keymap.set("n", "x", '"_x', { desc = "Delete char without yanking" })
keymap.set("x", "<leader>p", '"_dP', { desc = "Paste without overwriting register" })

keymap.set("n", "<leader>+", "<C-a>", { desc = "Increment number" })
keymap.set("n", "<leader>-", "<C-x>", { desc = "Decrement number" })

keymap.set("x", "<", "<gv", { desc = "Indent left and keep selection" })
keymap.set("x", ">", ">gv", { desc = "Indent right and keep selection" })
keymap.set("x", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down", silent = true })
keymap.set("x", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up", silent = true })

-- `s` is used as the window prefix below, so its default (substitute char) is disabled
keymap.set("n", "s", "<Nop>")
keymap.set("n", "sv", "<C-w>v", { desc = "Split window vertically" })
keymap.set("n", "ss", "<C-w>s", { desc = "Split window horizontally" })
keymap.set("n", "sh", "<C-w>h", { desc = "Go to left window" })
keymap.set("n", "sj", "<C-w>j", { desc = "Go to lower window" })
keymap.set("n", "sk", "<C-w>k", { desc = "Go to upper window" })
keymap.set("n", "sl", "<C-w>l", { desc = "Go to right window" })
keymap.set("n", "se", "<C-w>=", { desc = "Make splits equal size" })
keymap.set("n", "sx", "<cmd>close<CR>", { desc = "Close current split" })

keymap.set("n", "to", "<cmd>tabnew<CR>", { desc = "Open new tab" })
keymap.set("n", "tx", "<cmd>tabclose<CR>", { desc = "Close current tab" })
keymap.set("n", "tn", "<cmd>tabn<CR>", { desc = "Go to next tab" })
keymap.set("n", "tp", "<cmd>tabp<CR>", { desc = "Go to previous tab" })
keymap.set("n", "tf", "<cmd>tabnew %<CR>", { desc = "Open current buffer in new tab" })

keymap.set("n", "<leader>jq", "<cmd>%!jq .<CR>", { desc = "Format buffer as JSON with jq" })

-- Terminals send either <C-/> or <C-_> for Ctrl+/
for _, lhs in ipairs({ "<C-/>", "<C-_>" }) do
  keymap.set("n", lhs, "gcc", { remap = true, desc = "Toggle comment" })
  keymap.set("x", lhs, "gc", { remap = true, desc = "Toggle comment" })
end

keymap.set("n", "<leader>yf", function()
  local path = vim.fn.expand("%:.") .. ":" .. vim.fn.line(".")
  vim.fn.setreg("+", path)
  vim.notify("Copied " .. path)
end, { desc = "Yank relative path with line number" })
