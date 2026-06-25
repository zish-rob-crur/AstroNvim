return {
  {
    "kepano/flexoki-neovim",
    name = "flexoki",
    lazy = false,
    priority = 1000,
  },
  {
    "projekt0n/github-nvim-theme",
    name = "github-theme",
    lazy = false,
    priority = 1000,
    opts = {
      options = {
        dim_inactive = false,
        terminal_colors = true,
      },
    },
    config = function(_, opts) require("github-theme").setup(opts) end,
  },
  {
    "AstroNvim/astroui",
    opts = function(_, opts)
      local theme = require "user.theme"
      local mode = theme.mode()
      opts.colorscheme = theme.colorscheme(mode)

      opts.highlights = opts.highlights or {}
      local init_highlights = opts.highlights.init
      opts.highlights.init = function(colors_name)
        local highlights = {}
        if type(init_highlights) == "function" then
          highlights = init_highlights(colors_name) or {}
        elseif type(init_highlights) == "table" then
          highlights = vim.deepcopy(init_highlights)
        end
        return vim.tbl_deep_extend("force", highlights, theme.highlights(theme.mode()))
      end

      opts.status = opts.status or {}
      opts.status.attributes = opts.status.attributes or {}
      opts.status.attributes.buffer_active = { bold = true, italic = false }
      opts.status.colors = function(colors)
        local current_mode = theme.mode()
        return vim.tbl_deep_extend("force", colors, {
          completion_fg = current_mode == "dark" and "#bdc8d8" or "#57606a",
          completion_bg = current_mode == "dark" and "#3d444d" or "#d0d7de",
        })
      end

      theme.setup_auto_sync()
    end,
  },
}
