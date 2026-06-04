return {
  {
    "AstroNvim/astrocore",
    init = function() require("user.tmux_focus_dim").setup() end,
    opts = function(_, opts)
      opts.autocmds = opts.autocmds or {}
      opts.autocmds.tmux_focus_dim = {
        {
          event = "FocusLost",
          desc = "Dim Neovim when the tmux pane loses focus",
          callback = function() require("user.tmux_focus_dim").apply() end,
        },
        {
          event = "FocusGained",
          desc = "Restore Neovim when the tmux pane gains focus",
          callback = function() require("user.tmux_focus_dim").restore() end,
        },
        {
          event = "ColorScheme",
          desc = "Reapply tmux focus dimming after colorscheme changes",
          callback = function() require("user.tmux_focus_dim").refresh() end,
        },
      }
    end,
  },
}
