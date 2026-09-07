local jieba = require "user.jieba"

local function setup_word_motions()
  local mappings = {
    w = { modes = { "n", "x" }, begin = true, forward = true },
    b = { modes = { "n", "x" }, begin = true, forward = false },
    e = { modes = { "n", "x" }, begin = false, forward = true },
    ge = { modes = { "n", "x" }, begin = false, forward = false },
    iw = { modes = { "x" }, around = false },
    aw = { modes = { "x" }, around = true },
  }

  for lhs, mapping in pairs(mappings) do
    vim.keymap.set(mapping.modes, lhs, function()
      jieba.get()
      local begin_or_around = mapping.around
      if begin_or_around == nil then begin_or_around = mapping.begin end
      require("wordmotion.nvim.jieba").motion:keymap(begin_or_around, mapping.forward)
    end, { desc = "Jieba word motion " .. lhs })
  end

  -- Load the dictionary while idle so the first `w` or `s` does not stall.
  vim.defer_fn(function() pcall(jieba.get) end, 1000)
end

return {
  {
    "neo451/jieba.nvim",
    lazy = true,
    module = false,
    init = setup_word_motions,
  },
}
