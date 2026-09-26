local theme = require "user.theme"
local mode = theme.mode()

return {
  {
    "sainnhe/everforest",
    name = "everforest",
    lazy = mode ~= "dark",
    priority = 1000,
    config = function() theme.configure() end,
  },
  {
    "projekt0n/github-nvim-theme",
    name = "github-theme",
    lazy = mode ~= "light",
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
      theme.configure(mode)
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
      -- Close buffers with <Leader>c; per-tab close buttons only add clutter.
      opts.status.components = opts.status.components or {}
      opts.status.components.tabline_file_info = { close_button = false }
      -- Give the tabline three distinct backgrounds: the current buffer, buffers
      -- shown in other windows, and hidden buffers on the tabline strip.
      opts.status.colors = function(colors)
        local c
        if theme.mode() == "dark" then
          local p = theme.palette()
          c = {
            completion_fg = p.fg,
            completion_bg = p.bg1,
            strip_bg = p.bg_dim,
            hidden_fg = p.grey1,
            visible_bg = p.bg2,
            visible_fg = p.fg,
            active_bg = p.bg_green,
            active_fg = p.fg,
            path_fg = p.grey0,
          }
        else
          c = {
            completion_fg = "#57606a",
            completion_bg = "#d0d7de",
            strip_bg = "#eaeef2",
            hidden_fg = "#57606a",
            visible_bg = "#ffffff",
            visible_fg = "#24292f",
            active_bg = "#ddf4ff",
            active_fg = "#0550ae",
            path_fg = "#6e7781",
          }
        end
        return vim.tbl_deep_extend("force", colors, {
          completion_fg = c.completion_fg,
          completion_bg = c.completion_bg,
          tabline_bg = c.strip_bg,
          buffer_bg = c.strip_bg,
          buffer_fg = c.hidden_fg,
          buffer_path_fg = c.path_fg,
          buffer_overflow_bg = c.strip_bg,
          buffer_visible_bg = c.visible_bg,
          buffer_visible_fg = c.visible_fg,
          buffer_visible_path_fg = c.path_fg,
          buffer_active_bg = c.active_bg,
          buffer_active_fg = c.active_fg,
          buffer_active_path_fg = c.active_fg,
        })
      end

      theme.setup_auto_sync()
    end,
  },
}
