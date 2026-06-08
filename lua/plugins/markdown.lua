local function set_markdown_nav_keymaps(bufnr)
  local map = function(lhs, rhs, desc) vim.keymap.set("n", lhs, rhs, { buffer = bufnr, silent = true, desc = desc }) end

  map("<Leader>mp", function() require("render-markdown").preview() end, "Markdown preview")
  map("<Leader>mb", "<Cmd>LivePreview start<CR>", "Open Markdown live browser preview")
  map("<Leader>mc", "<Cmd>LivePreview close<CR>", "Close Markdown live browser preview")
  map("<Leader>mo", function() vim.cmd "AerialToggle! left" end, "Markdown heading outline")
  map("<Leader>mn", function() vim.cmd "AerialToggle! left" end, "Markdown section outline")
  map("]m", function() require("aerial").next() end, "Next Markdown heading")
  map("[m", function() require("aerial").prev() end, "Previous Markdown heading")
end

---@type LazySpec
return {
  {
    "joshuadanpeterson/typewriter.nvim",
    ft = { "markdown" },
    config = function()
      require("typewriter").setup {
        enable_notifications = false,
        enable_horizontal_scroll = false,
        start_enabled = false,
        always_center = true,
        always_center_filetypes = {
          markdown = true,
        },
      }

      local group = vim.api.nvim_create_augroup("UserMarkdownTypewriter", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = "markdown",
        callback = function() vim.cmd "TWEnable" end,
        desc = "Enable typewriter mode for Markdown",
      })

      if vim.bo.filetype == "markdown" then vim.cmd "TWEnable" end
    end,
  },
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
        -- Add a little padding around inline code like `'<Leader>ff'`.
        inline_pad = 1,
      },
    },
    config = function(_, opts)
      require("render-markdown").setup(opts)

      -- render-markdown links the default inline-code background to ColorColumn,
      -- while the foreground still comes from treesitter. In light themes, that
      -- can produce low contrast, so keep inline-code text on Normal.fg.
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
    "brianhuster/live-preview.nvim",
    ft = { "markdown", "html", "svg", "asciidoc" },
    cmd = { "LivePreview" },
    dependencies = { "folke/snacks.nvim" },
    config = function()
      require("livepreview.config").set {
        port = 5500,
        browser = "default",
        dynamic_root = false,
        sync_scroll = true,
        picker = "snacks.picker",
        address = "127.0.0.1",
      }
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
