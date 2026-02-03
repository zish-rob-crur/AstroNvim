return {
  {
    "kepano/flexoki-neovim",
    name = "flexoki",
    lazy = false,
    priority = 1000,
  },
  {
    "AstroNvim/astroui",
    opts = function(_, opts) opts.colorscheme = "flexoki-light" end,
  },
}
