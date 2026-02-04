return {
  {
    "AstroNvim/astrocore",
    opts = function(_, opts)
      opts.options = opts.options or {}
      opts.options.opt = opts.options.opt or {}
      opts.options.opt.wrap = true
      opts.options.opt.linebreak = true
    end,
  },
}
