return {
  {
    "kepano/flexoki-neovim",
    name = "flexoki",
    lazy = false,
    priority = 1000,
  },
  {
    "folke/tokyonight.nvim",
    name = "tokyonight",
    lazy = false,
    priority = 1000,
    opts = {
      style = "day",
      day_brightness = 0.6,
      styles = {
        comments = { italic = false },
        keywords = { italic = false },
        sidebars = "normal",
        floats = "normal",
      },
      on_colors = function(colors)
        colors.fg = "#24292F"
        colors.fg_dark = "#57606A"
        colors.fg_float = colors.fg
        colors.fg_sidebar = colors.fg_dark

        colors.bg = "#FFFFFF"
        colors.bg_dark = "#F6F8FA"
        colors.bg_float = colors.bg_dark
        colors.bg_popup = colors.bg_dark
        colors.bg_sidebar = colors.bg_dark
        colors.bg_statusline = colors.bg_dark
        colors.border = "#D0D7DE"
        colors.fg_gutter = "#8C959F"
        colors.comment = "#6E7781"
      end,
    },
    config = function(_, opts) require("tokyonight").setup(opts) end,
  },
  {
    "AstroNvim/astroui",
    opts = function(_, opts) opts.colorscheme = "tokyonight-day" end,
  },
}
