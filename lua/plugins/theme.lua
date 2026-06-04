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
      opts.colorscheme = "github_light_high_contrast"

      opts.status = opts.status or {}
      opts.status.attributes = opts.status.attributes or {}
      opts.status.attributes.buffer_active = { bold = true, italic = false }

      opts.status.colors = vim.tbl_deep_extend("force", opts.status.colors or {}, {
        tabline_bg = "#d0d7de",
        tabline_fg = "#d0d7de",
        buffer_bg = "#d0d7de",
        buffer_fg = "#57606a",
        buffer_path_fg = "#6e7781",
        buffer_close_fg = "#6e7781",
        buffer_visible_bg = "#f6f8fa",
        buffer_visible_fg = "#24292f",
        buffer_visible_path_fg = "#57606a",
        buffer_visible_close_fg = "#cf222e",
        buffer_active_bg = "#0969da",
        buffer_active_fg = "#ffffff",
        buffer_active_path_fg = "#ddf4ff",
        buffer_active_close_fg = "#ffffff",
        buffer_overflow_bg = "#d0d7de",
        tab_bg = "#d0d7de",
        tab_fg = "#57606a",
        tab_active_bg = "#0969da",
        tab_active_fg = "#ffffff",
        tab_close_bg = "#d0d7de",
      })
    end,
  },
}
