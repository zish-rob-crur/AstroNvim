return {
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      opts.image = { enabled = false }

      local keys = vim.tbl_get(opts, "dashboard", "preset", "keys")
      if type(keys) == "table" then
        for _, key in ipairs(keys) do
          if key.key == "o" and key.action == "<Leader>fo" then key.action = ":lua Snacks.picker.recent()" end
        end
      end

      return opts
    end,
  },
}
