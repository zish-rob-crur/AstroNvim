return {
  {
    "jake-stewart/multicursor.nvim",
    branch = "1.0",
    event = "VeryLazy",
    config = function()
      local mc = require "multicursor-nvim"
      mc.setup()

      local map = vim.keymap.set
      map({ "n", "x" }, "<Leader>vn", function() mc.matchAddCursor(1) end, { desc = "Add next matching cursor" })
      map({ "n", "x" }, "<Leader>vs", function() mc.matchSkipCursor(1) end, { desc = "Skip next cursor match" })
      map({ "n", "x" }, "<Leader>vk", function() mc.lineAddCursor(-1) end, { desc = "Add cursor above" })
      map({ "n", "x" }, "<Leader>vj", function() mc.lineAddCursor(1) end, { desc = "Add cursor below" })

      mc.addKeymapLayer(function(set)
        set("n", "<Esc>", mc.clearCursors, { desc = "Clear multiple cursors" })
      end)
    end,
  },
}
