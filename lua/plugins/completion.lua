-- Completion ranking tuned for coding-first suggestions.

local function existing_dirs(paths)
  local dirs = {}
  for _, path in ipairs(paths) do
    local expanded = vim.fn.expand(path)
    if vim.fn.isdirectory(expanded) == 1 then table.insert(dirs, expanded) end
  end
  return dirs
end

local function dotagent_agent()
  local agent = vim.env.DOTAGENT_AGENT
  if agent == "claude-code" then return "claude" end
  return agent
end

local function dotagent_opts()
  local agent = dotagent_agent()
  local prefix = vim.env.DOTAGENT_PREFIX
  if prefix == nil or prefix == "" then prefix = agent == "codex" and "$" or "/" end

  local skill_dirs
  local command_dirs
  if agent == "claude" then
    skill_dirs = existing_dirs {
      "~/.claude/skills",
      "~/.agents/skills",
    }
    command_dirs = existing_dirs {
      "~/.claude/commands",
    }
  elseif agent == "codex" then
    skill_dirs = existing_dirs {
      "~/.agents/skills",
      "~/.codex/skills",
    }
    command_dirs = {}
  else
    skill_dirs = existing_dirs {
      "~/.claude/skills",
      "~/.agents/skills",
      "~/.codex/skills",
    }
    command_dirs = existing_dirs {
      "~/.claude/commands",
    }
  end

  return {
    prefixes = { prefix },
    activation = {
      mode = "contextual",
      env_var = "DOTAGENT_EDITOR_PROMPT",
    },
    command_dirs = command_dirs,
    skill_dirs = skill_dirs,
  }
end

local function dotagent_enabled()
  local ok, dotagent = pcall(require, "dotagent")
  return ok and dotagent.is_buffer_enabled(vim.api.nvim_get_current_buf())
end

local function prompt_sources(fallback)
  if dotagent_enabled() then return { "dotagent", "path", "cwd_paths", "buffer" } end
  return fallback
end

---@type LazySpec
return {
  {
    "0xble/dotagent.nvim",
    lazy = false,
    opts = dotagent_opts,
  },
  {
    "saghen/blink.cmp",
    opts = function(_, opts)
      opts.fuzzy = vim.tbl_deep_extend("force", opts.fuzzy or {}, {
        implementation = "prefer_rust",
        sorts = {
          "exact",
          "score",
          "sort_text",
          "kind",
          "label",
        },
      })

      opts.completion = vim.tbl_deep_extend("force", opts.completion or {}, {
        list = {
          selection = {
            preselect = true,
            auto_insert = false,
          },
        },
        menu = {
          auto_show = true,
          auto_show_delay_ms = 0,
        },
        keyword = {
          range = "prefix",
        },
        trigger = {
          prefetch_on_insert = true,
          show_on_keyword = true,
          show_on_trigger_character = true,
        },
        documentation = {
          auto_show = false,
          auto_show_delay_ms = 0,
          treesitter_highlighting = false,
        },
      })

      opts.sources = opts.sources or {}
      opts.sources.min_keyword_length = 0
      opts.sources.default = function()
        return prompt_sources {
          "lsp",
          "snippets",
          "path",
          "cwd_paths",
          "buffer",
        }
      end
      opts.sources.per_filetype = vim.tbl_deep_extend("force", opts.sources.per_filetype or {}, {
        python = function()
          return prompt_sources { "python_imports", "lsp", "snippets", "path", "cwd_paths", "buffer" }
        end,
        javascript = function()
          return prompt_sources { "js_imports", "lsp", "snippets", "path", "cwd_paths", "buffer" }
        end,
        javascriptreact = function()
          return prompt_sources { "js_imports", "lsp", "snippets", "path", "cwd_paths", "buffer" }
        end,
        typescript = function()
          return prompt_sources { "js_imports", "lsp", "snippets", "path", "cwd_paths", "buffer" }
        end,
        typescriptreact = function()
          return prompt_sources { "js_imports", "lsp", "snippets", "path", "cwd_paths", "buffer" }
        end,
        markdown = function()
          return prompt_sources { "lsp", "snippets", "path", "cwd_paths", "buffer" }
        end,
        text = function()
          return prompt_sources { "path", "cwd_paths", "buffer" }
        end,
      })
      opts.sources.providers = vim.tbl_deep_extend("force", opts.sources.providers or {}, {
        dotagent = {
          name = "Dotagent",
          module = "dotagent.completion.blink",
          enabled = dotagent_enabled,
          score_offset = 140,
          fallbacks = {},
          min_keyword_length = 0,
        },
        cwd_paths = {
          name = "CwdPath",
          module = "user.blink_cwd_paths",
          score_offset = 25,
          min_keyword_length = 1,
          max_items = 80,
        },
        python_imports = {
          name = "PyImport",
          module = "user.blink_python_imports",
          score_offset = 120,
          min_keyword_length = 0,
          max_items = 80,
        },
        js_imports = {
          name = "JSImport",
          module = "user.blink_js_imports",
          score_offset = 115,
          min_keyword_length = 0,
          max_items = 120,
        },
        lsp = {
          async = true,
          timeout_ms = 250,
          score_offset = 80,
          fallbacks = {},
        },
        snippets = {
          score_offset = 10,
          min_keyword_length = 2,
        },
        path = {
          score_offset = 5,
          min_keyword_length = 0,
          fallbacks = {},
          opts = {
            max_entries = 3000,
          },
        },
        buffer = {
          enabled = function()
            local ft = vim.bo.filetype
            local enabled_filetypes = {
              javascript = true,
              javascriptreact = true,
              lua = true,
              markdown = true,
              python = true,
              text = true,
              typescript = true,
              typescriptreact = true,
            }
            return enabled_filetypes[ft] and vim.api.nvim_buf_line_count(0) <= 8000
          end,
          score_offset = -60,
          min_keyword_length = 3,
          max_items = 8,
          opts = {
            get_bufnrs = function() return { vim.api.nvim_get_current_buf() } end,
            get_search_bufnrs = function() return { vim.api.nvim_get_current_buf() } end,
            max_sync_buffer_size = 20000,
            max_async_buffer_size = 120000,
            max_total_buffer_size = 150000,
            use_cache = true,
          },
        },
      })

      opts.cmdline = vim.tbl_deep_extend("force", opts.cmdline or {}, {
        enabled = true,
        sources = function()
          local cmdtype = vim.fn.getcmdtype()
          if cmdtype == "/" or cmdtype == "?" then return { "buffer" } end
          if cmdtype == ":" or cmdtype == "@" then return { "cmdline", "path", "buffer" } end
          return {}
        end,
        completion = {
          trigger = {
            show_on_blocked_trigger_characters = {},
            show_on_x_blocked_trigger_characters = {},
          },
        },
      })
    end,
  },
  {
    "AstroNvim/astrocore",
    opts = function(_, opts)
      opts.autocmds = opts.autocmds or {}
      opts.autocmds.zish_context_completion = {
        {
          event = "TextChangedI",
          desc = "Trigger completion in language import contexts",
          callback = function(args) require("user.completion_context").trigger(args.buf) end,
        },
      }
    end,
  },
}
