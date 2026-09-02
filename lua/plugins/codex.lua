local codex_terminal = require "user.codex_terminal"

codex_terminal.setup()

return {
  {
    "AstroNvim/astrocore",
    opts = function(_, opts)
      opts.mappings = opts.mappings or {}
      opts.mappings.n = opts.mappings.n or {}
      opts.mappings.n["<Leader>tc"] = {
        function() codex_terminal.attach_current() end,
        desc = "Open Codex with current file",
      }
      return opts
    end,
  },
}
