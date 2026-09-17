local terminal = require "user.claude_terminal"
terminal.setup()

return {
  {
    "AstroNvim/astrocore",
    opts = function(_, opts)
      opts.mappings = opts.mappings or {}
      opts.mappings.n = opts.mappings.n or {}
      opts.mappings.n["<Leader>tC"] = {
        function() terminal.attach_current() end,
        desc = "Open Claude with current file",
      }
      return opts
    end,
  },
}
