return {
  "MeanderingProgrammer/render-markdown.nvim",
  ft = { "markdown" },
  dependencies = { "nvim-treesitter/nvim-treesitter", "echasnovski/mini.nvim" }, -- if you use the mini.nvim suite
  -- dependencies = { "nvim-treesitter/nvim-treesitter", "echasnovski/mini.icons" }, -- if you use standalone mini plugins
  -- dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" }, -- if you prefer nvim-web-devicons
  ---@module "render-markdown"
  ---@type render.md.UserConfig
  opts = {
    code = {
      -- 给行内 code（例如 `'<Leader>ff'`）留一点左右空隙，更清晰
      inline_pad = 1,
    },
  },
  config = function(_, opts)
    require("render-markdown").setup(opts)

    -- render-markdown 的默认行内 code 背景会链接到 ColorColumn（只给背景），而前景色仍来自 treesitter
    -- 在浅色主题（例如 tokyonight-day）下容易出现“浅蓝字 + 浅蓝底”，导致可读性很差。
    -- 这里把 RenderMarkdownCodeInline 的前景色强制设为 Normal.fg，以保证对比度。
    local function apply_render_markdown_highlights()
      local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
      local color_column = vim.api.nvim_get_hl(0, { name = "ColorColumn", link = false })
      local code_inline = vim.api.nvim_get_hl(0, { name = "RenderMarkdownCodeInline", link = false })

      local fallback_fg = vim.o.background == "dark" and 0xC0CAF5 or 0x24292F
      local fallback_bg = vim.o.background == "dark" and 0x2A2E3E or 0xEEF1F5

      vim.api.nvim_set_hl(0, "RenderMarkdownCodeInline", {
        fg = normal.fg or code_inline.fg or fallback_fg,
        bg = code_inline.bg or color_column.bg or fallback_bg,
      })
    end

    apply_render_markdown_highlights()
    vim.api.nvim_create_autocmd("ColorScheme", {
      group = vim.api.nvim_create_augroup("UserRenderMarkdownHighlights", { clear = true }),
      callback = apply_render_markdown_highlights,
    })
  end,
}
