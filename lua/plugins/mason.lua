-- Install language servers and formatter CLIs through Mason.

---@type LazySpec
return {
  {
    "mason-org/mason-lspconfig.nvim",
    opts = {
      automatic_enable = true,
    },
  },
  {
    "jay-babu/mason-null-ls.nvim",
    opts = {
      methods = {
        diagnostics = true,
        formatting = false,
        code_actions = false,
        completion = false,
        hover = false,
      },
      handlers = {
        function() end,
        markdownlint_cli2 = function(source_name, methods) require("mason-null-ls").default_setup(source_name, methods) end,
      },
    },
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      opts.integrations = vim.tbl_deep_extend("force", opts.integrations or {}, {
        ["mason-lspconfig"] = true,
      })

      vim.list_extend(opts.ensure_installed, {
        -- Lua config support
        "lua_ls",
        "stylua",

        -- Python
        "basedpyright",
        "ruff",
        "black",

        -- TypeScript / JavaScript
        "vtsls",
        "eslint",
        "prettierd",
        "prettier",

        -- Markdown
        "marksman",
        "markdownlint-cli2",
      })

      opts.run_on_start = true
      opts.start_delay = 3000
      opts.debounce_hours = 12
    end,
  },
}
