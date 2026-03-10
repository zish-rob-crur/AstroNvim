local function set_markdown_nav_keymaps(bufnr)
  local map = function(lhs, rhs, desc)
    vim.keymap.set("n", lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
  end

  map("<Leader>mp", function() require("render-markdown").preview() end, "Markdown 预览")
  map("<Leader>mb", "<Cmd>MarkdownPreview<CR>", "Markdown 浏览器预览（直接打开）")
  map("<Leader>mm", "<Cmd>MarkdownPreviewToggle<CR>", "Markdown 浏览器预览（Mermaid）")
  map("<Leader>mo", function() vim.cmd "AerialToggle! left" end, "Markdown 标题导航")
  map("]m", function() require("aerial").next() end, "下一个 Markdown 标题")
  map("[m", function() require("aerial").prev() end, "上一个 Markdown 标题")
end

---@type LazySpec
return {
  {
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

      local markdown_group = vim.api.nvim_create_augroup("UserMarkdownNavigation", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        group = markdown_group,
        pattern = "markdown",
        callback = function(args) set_markdown_nav_keymaps(args.buf) end,
      })

      if vim.bo.filetype == "markdown" then set_markdown_nav_keymaps(0) end

      apply_render_markdown_highlights()
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("UserRenderMarkdownHighlights", { clear = true }),
        callback = apply_render_markdown_highlights,
      })
    end,
  },
  {
    "iamcco/markdown-preview.nvim",
    ft = { "markdown" },
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    build = "cd app && npm install",
    init = function()
      vim.g.mkdp_filetypes = { "markdown" }
    end,
  },
  {
    "stevearc/aerial.nvim",
    optional = true,
    opts = function(_, opts)
      opts = opts or {}

      local backends = opts.backends
      if backends == nil then
        opts.backends = {
          _ = { "treesitter", "lsp", "markdown", "asciidoc", "man" },
          markdown = { "markdown", "treesitter" },
        }
      elseif vim.islist(backends) then
        opts.backends = {
          _ = backends,
          markdown = { "markdown", "treesitter" },
        }
      else
        backends.markdown = backends.markdown or { "markdown", "treesitter" }
        opts.backends = backends
      end

      return opts
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    optional = true,
    opts = function(_, opts)
      if opts.ensure_installed == "all" then return end

      opts.ensure_installed = opts.ensure_installed or {}
      for _, parser in ipairs { "markdown", "markdown_inline" } do
        if not vim.tbl_contains(opts.ensure_installed, parser) then table.insert(opts.ensure_installed, parser) end
      end
    end,
  },
  {
    "AstroNvim/astrocore",
    optional = true,
    opts = function(_, opts)
      opts.mappings = opts.mappings or {}
      opts.mappings.n = opts.mappings.n or {}
      opts.mappings.n["<Leader>m"] = { desc = "Markdown" }
      return opts
    end,
  },
}
