return {
  {
    "AstroNvim/astrocore",
    opts = function(_, opts)
      opts.options = opts.options or {}
      opts.options.opt = opts.options.opt or {}
      opts.options.opt.wrap = true
      opts.options.opt.linebreak = true
      opts.options.opt.autoread = true

      opts.autocmds = opts.autocmds or {}
      opts.autocmds.auto_reload_changed_files = {
        {
          event = { "VimEnter", "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" },
          desc = "Auto checktime for files changed on disk",
          callback = function()
            if vim.fn.mode() ~= "c" then vim.cmd "checktime" end
          end,
        },
      }

      opts.mappings = opts.mappings or {}
      opts.mappings.n = opts.mappings.n or {}

      opts.mappings.n["<C-p>"] = {
        function() require("telescope.builtin").find_files() end,
        desc = "Quick Open files (VSCode style)",
      }
      opts.mappings.n["<D-p>"] = {
        function() require("telescope.builtin").find_files() end,
        desc = "Quick Open files (VSCode style)",
      }
      opts.mappings.n["<C-S-p>"] = {
        function() require("telescope.builtin").commands() end,
        desc = "Command palette",
      }
      opts.mappings.n["<D-S-p>"] = {
        function() require("telescope.builtin").commands() end,
        desc = "Command palette",
      }
      opts.mappings.n["<Leader>fp"] = {
        function() require("telescope.builtin").buffers() end,
        desc = "Quick switch buffers",
      }
    end,
  },
}
