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
    config = function() require("github-theme").setup {} end,
  },
  {
    "AstroNvim/astroui",
    opts = function(_, opts) opts.colorscheme = "flexoki-light" end,
  },
}
