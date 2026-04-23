local function config()
  require("nvim-treesitter-textobjects").setup({
    select = {
      lookahead = true,
    },
    move = {
      set_jumps = true,
    },
  })

  local select = require("nvim-treesitter-textobjects.select")
  local move = require("nvim-treesitter-textobjects.move")
  local swap = require("nvim-treesitter-textobjects.swap")
  local ts_repeat_move = require("nvim-treesitter-textobjects.repeatable_move")

  local function sel(query)
    return function()
      select.select_textobject(query, "textobjects")
    end
  end

  local select_maps = {
    ["a="] = { "@assignment.outer", "Select outer part of an assignment" },
    ["i="] = { "@assignment.inner", "Select inner part of an assignment" },
    ["l="] = { "@assignment.lhs", "Select left hand side of an assignment" },
    ["r="] = { "@assignment.rhs", "Select right hand side of an assignment" },

    ["a:"] = { "@property.outer", "Select outer part of an object property" },
    ["i:"] = { "@property.inner", "Select inner part of an object property" },
    ["l:"] = { "@property.lhs", "Select left part of an object property" },
    ["r:"] = { "@property.rhs", "Select right part of an object property" },

    ["aa"] = { "@parameter.outer", "Select outer part of a parameter/argument" },
    ["ia"] = { "@parameter.inner", "Select inner part of a parameter/argument" },

    ["ai"] = { "@conditional.outer", "Select outer part of a conditional" },
    ["ii"] = { "@conditional.inner", "Select inner part of a conditional" },

    ["al"] = { "@loop.outer", "Select outer part of a loop" },
    ["il"] = { "@loop.inner", "Select inner part of a loop" },

    ["af"] = { "@call.outer", "Select outer part of a function call" },
    ["if"] = { "@call.inner", "Select inner part of a function call" },

    ["am"] = { "@function.outer", "Select outer part of a method/function definition" },
    ["im"] = { "@function.inner", "Select inner part of a method/function definition" },

    ["ac"] = { "@class.outer", "Select outer part of a class" },
    ["ic"] = { "@class.inner", "Select inner part of a class" },
  }
  for lhs, spec in pairs(select_maps) do
    vim.keymap.set({ "x", "o" }, lhs, sel(spec[1]), { desc = spec[2] })
  end

  local swap_next = {
    ["<leader>na"] = "@parameter.inner",
    ["<leader>n:"] = "@property.outer",
    ["<leader>nm"] = "@function.outer",
  }
  for lhs, query in pairs(swap_next) do
    vim.keymap.set("n", lhs, function()
      swap.swap_next(query)
    end, { desc = "Swap next " .. query })
  end

  local swap_prev = {
    ["<leader>pa"] = "@parameter.inner",
    ["<leader>p:"] = "@property.outer",
    ["<leader>pm"] = "@function.outer",
  }
  for lhs, query in pairs(swap_prev) do
    vim.keymap.set("n", lhs, function()
      swap.swap_previous(query)
    end, { desc = "Swap previous " .. query })
  end

  local function goto_map(mode_fn, query, group, desc)
    return function()
      mode_fn(query, group or "textobjects")
    end
  end

  local moves = {
    -- goto_next_start
    { { "n", "x", "o" }, "]f", move.goto_next_start, "@call.outer", nil, "Next function call start" },
    { { "n", "x", "o" }, "]m", move.goto_next_start, "@function.outer", nil, "Next method/function def start" },
    { { "n", "x", "o" }, "]c", move.goto_next_start, "@class.outer", nil, "Next class start" },
    { { "n", "x", "o" }, "]i", move.goto_next_start, "@conditional.outer", nil, "Next conditional start" },
    { { "n", "x", "o" }, "]l", move.goto_next_start, "@loop.outer", nil, "Next loop start" },
    { { "n", "x", "o" }, "]s", move.goto_next_start, "@local.scope", "locals", "Next scope" },
    { { "n", "x", "o" }, "]z", move.goto_next_start, "@fold", "folds", "Next fold" },
    -- goto_next_end
    { { "n", "x", "o" }, "]F", move.goto_next_end, "@call.outer", nil, "Next function call end" },
    { { "n", "x", "o" }, "]M", move.goto_next_end, "@function.outer", nil, "Next method/function def end" },
    { { "n", "x", "o" }, "]C", move.goto_next_end, "@class.outer", nil, "Next class end" },
    { { "n", "x", "o" }, "]I", move.goto_next_end, "@conditional.outer", nil, "Next conditional end" },
    { { "n", "x", "o" }, "]L", move.goto_next_end, "@loop.outer", nil, "Next loop end" },
    -- goto_previous_start
    { { "n", "x", "o" }, "[f", move.goto_previous_start, "@call.outer", nil, "Prev function call start" },
    { { "n", "x", "o" }, "[m", move.goto_previous_start, "@function.outer", nil, "Prev method/function def start" },
    { { "n", "x", "o" }, "[c", move.goto_previous_start, "@class.outer", nil, "Prev class start" },
    { { "n", "x", "o" }, "[i", move.goto_previous_start, "@conditional.outer", nil, "Prev conditional start" },
    { { "n", "x", "o" }, "[l", move.goto_previous_start, "@loop.outer", nil, "Prev loop start" },
    -- goto_previous_end
    { { "n", "x", "o" }, "[F", move.goto_previous_end, "@call.outer", nil, "Prev function call end" },
    { { "n", "x", "o" }, "[M", move.goto_previous_end, "@function.outer", nil, "Prev method/function def end" },
    { { "n", "x", "o" }, "[C", move.goto_previous_end, "@class.outer", nil, "Prev class end" },
    { { "n", "x", "o" }, "[I", move.goto_previous_end, "@conditional.outer", nil, "Prev conditional end" },
    { { "n", "x", "o" }, "[L", move.goto_previous_end, "@loop.outer", nil, "Prev loop end" },
  }
  for _, m in ipairs(moves) do
    local modes, lhs, fn, query, group, desc = m[1], m[2], m[3], m[4], m[5], m[6]
    vim.keymap.set(modes, lhs, goto_map(fn, query, group), { desc = desc })
  end

  vim.keymap.set({ "n", "x", "o" }, ";", ts_repeat_move.repeat_last_move)
  vim.keymap.set({ "n", "x", "o" }, ",", ts_repeat_move.repeat_last_move_opposite)
  vim.keymap.set({ "n", "x", "o" }, "f", ts_repeat_move.builtin_f_expr, { expr = true })
  vim.keymap.set({ "n", "x", "o" }, "F", ts_repeat_move.builtin_F_expr, { expr = true })
  vim.keymap.set({ "n", "x", "o" }, "t", ts_repeat_move.builtin_t_expr, { expr = true })
  vim.keymap.set({ "n", "x", "o" }, "T", ts_repeat_move.builtin_T_expr, { expr = true })
end

return {
  "nvim-treesitter/nvim-treesitter-textobjects",
  branch = "main",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
  },
  config = config,
}
