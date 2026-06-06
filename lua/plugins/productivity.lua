return {
  {
    "stevearc/oil.nvim",
    cmd = "Oil",
    keys = {
      { "-", "<cmd>Oil<CR>", desc = "Open parent directory with Oil" },
      { "<Leader>fO", "<cmd>Oil<CR>", desc = "Edit current directory with Oil" },
    },
    opts = {
      default_file_explorer = false,
      skip_confirm_for_simple_edits = true,
      view_options = {
        show_hidden = true,
      },
    },
  },
  {
    "MagicDuck/grug-far.nvim",
    cmd = "GrugFar",
    keys = {
      { "<Leader>sr", "<cmd>GrugFar<CR>", desc = "Search and replace in project" },
      {
        "<Leader>sw",
        function()
          require("grug-far").open {
            prefills = {
              search = vim.fn.expand "<cword>",
            },
          }
        end,
        desc = "Search and replace word under cursor",
      },
    },
    opts = {},
  },
  {
    "stevearc/conform.nvim",
    cmd = "ConformInfo",
    keys = {
      {
        "<Leader>cf",
        function() require("conform").format { async = true, lsp_format = "fallback" } end,
        desc = "Format buffer",
      },
    },
    opts = {
      default_format_opts = {
        lsp_format = "fallback",
      },
      format_on_save = {
        lsp_format = "fallback",
        timeout_ms = 1000,
      },
      formatters_by_ft = {
        lua = { "stylua" },
        python = { "ruff_format", "black", stop_after_first = true },
        javascript = { "prettierd", "prettier", stop_after_first = true },
        typescript = { "prettierd", "prettier", stop_after_first = true },
        javascriptreact = { "prettierd", "prettier", stop_after_first = true },
        typescriptreact = { "prettierd", "prettier", stop_after_first = true },
        json = { "prettierd", "prettier", stop_after_first = true },
        yaml = { "prettierd", "prettier", stop_after_first = true },
        markdown = { "prettierd", "prettier", stop_after_first = true },
        go = { "goimports", "gofmt" },
        rust = { "rustfmt" },
        sh = { "shfmt" },
      },
    },
  },
  {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "LspAttach",
    priority = 1000,
    config = function()
      vim.diagnostic.config { virtual_text = false }
      require("tiny-inline-diagnostic").setup {
        preset = "modern",
      }
    end,
  },
  {
    "AstroNvim/astrocore",
    opts = function(_, opts)
      opts.diagnostics = opts.diagnostics or {}
      opts.diagnostics.virtual_text = false

      opts.mappings = opts.mappings or {}
      opts.mappings.n = opts.mappings.n or {}
      opts.mappings.n["<Leader>s"] = { desc = "Search/replace" }
      opts.mappings.n["<Leader>c"] = opts.mappings.n["<Leader>c"] or { desc = "Code" }

      return opts
    end,
  },
}
