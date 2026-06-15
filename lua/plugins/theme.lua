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

      opts.highlights = opts.highlights or {}
      opts.highlights.init = vim.tbl_deep_extend("force", opts.highlights.init or {}, {
        GitSignsCurrentLineBlame = { fg = "#0969da", bg = "#ddf4ff", italic = true },
      })

      opts.status = opts.status or {}
      opts.status.attributes = opts.status.attributes or {}
      opts.status.attributes.buffer_active = { bold = true, italic = false }

      opts.status.colors = vim.tbl_deep_extend("force", opts.status.colors or {}, {
        fg = "#24292f",
        bg = "#d0d7de",
        section_fg = "#24292f",
        section_bg = "#d0d7de",
        git_branch_fg = "#57606a",
        git_branch_bg = "#d0d7de",
        git_diff_bg = "#d0d7de",
        file_info_fg = "#24292f",
        file_info_bg = "#d0d7de",
        diagnostics_bg = "#d0d7de",
        completion_fg = "#57606a",
        completion_bg = "#d0d7de",
        lsp_bg = "#d0d7de",
        treesitter_bg = "#d0d7de",
        virtual_env_bg = "#d0d7de",
        nav_bg = "#d0d7de",
        mode_fg = "#ffffff",
        normal = "#0969da",
        insert = "#1a7f37",
        visual = "#8250df",
        replace = "#cf222e",
        command = "#bc4c00",
        terminal = "#1f6feb",
        inactive = "#6e7781",
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
