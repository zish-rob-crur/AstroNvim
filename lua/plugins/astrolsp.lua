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
  },
}
