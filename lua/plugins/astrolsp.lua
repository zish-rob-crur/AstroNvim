-- Language server configuration.

---@type LazySpec
return {
  "AstroNvim/astrolsp",
  ---@type AstroLSPOpts
  opts = {
    features = {
      codelens = true,
      inlay_hints = false,
      semantic_tokens = true,
    },
    -- Formatting is owned by conform.nvim (see productivity.lua).
    formatting = { format_on_save = { enabled = false } },
    servers = {
      "basedpyright",
      "ruff",
      "vtsls",
      "eslint",
      "marksman",
    },
    ---@diagnostic disable: missing-fields
    config = {
      basedpyright = {
        settings = {
          basedpyright = {
            analysis = {
              autoImportCompletions = true,
              autoSearchPaths = true,
              diagnosticMode = "openFilesOnly",
              fileEnumerationTimeout = 5,
              typeCheckingMode = "standard",
              useLibraryCodeForTypes = true,
            },
          },
        },
      },
      ruff = {
        init_options = {
          settings = {
            lineLength = 88,
          },
        },
        on_attach = function(client)
          -- basedpyright owns hover/type docs; Ruff stays focused on lint/code actions.
          client.server_capabilities.hoverProvider = false
        end,
      },
      vtsls = {
        settings = {
          vtsls = {
            autoUseWorkspaceTsdk = true,
          },
          typescript = {
            preferences = {
              includePackageJsonAutoImports = "auto",
              importModuleSpecifier = "non-relative",
            },
            suggest = {
              autoImports = true,
              completeFunctionCalls = false,
              includeCompletionsForImportStatements = true,
              paths = true,
            },
            tsserver = {
              maxTsServerMemory = 4096,
            },
          },
          javascript = {
            preferences = {
              importModuleSpecifier = "non-relative",
            },
            suggest = {
              autoImports = true,
              completeFunctionCalls = false,
              includeCompletionsForImportStatements = true,
              paths = true,
            },
          },
        },
      },
      eslint = {
        settings = {
          format = false,
          workingDirectories = { mode = "auto" },
        },
      },
      marksman = {},
    },
    -- Definitions and references go through the snacks picker: a single result
    -- still jumps straight there, several show a list with a preview pane.
    mappings = {
      n = {
        gd = {
          function() require("snacks").picker.lsp_definitions() end,
          desc = "Definition of current symbol",
          cond = "textDocument/definition",
        },
        gy = {
          function() require("snacks").picker.lsp_type_definitions() end,
          desc = "Definition of current type",
          cond = "textDocument/typeDefinition",
        },
        gI = {
          function() require("snacks").picker.lsp_implementations() end,
          desc = "Implementation of current symbol",
          cond = "textDocument/implementation",
        },
        grr = {
          function() require("snacks").picker.lsp_references() end,
          desc = "References of current symbol",
          cond = "textDocument/references",
        },
        ["<Leader>lR"] = {
          function() require("snacks").picker.lsp_references() end,
          desc = "Search references",
          cond = "textDocument/references",
        },
      },
    },
  },
}
