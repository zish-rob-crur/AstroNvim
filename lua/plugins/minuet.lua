local function load_home_env(name)
  if vim.env[name] and vim.env[name] ~= "" then return true end

  local env_path = vim.fn.expand "~/.env"
  if vim.fn.filereadable(env_path) ~= 1 then return false end

  for _, line in ipairs(vim.fn.readfile(env_path)) do
    local key, value = line:match "^%s*([%w_]+)%s*=%s*(.-)%s*$"
    if key == name and value and value ~= "" then
      value = value:gsub("%s+#.*$", ""):gsub("^['\"]", ""):gsub("['\"]$", "")
      vim.env[name] = value
      return true
    end
  end

  return false
end

local function minuet_filetypes(enabled)
  return enabled and {
    "lua",
    "python",
    "typescript",
    "typescriptreact",
    "javascript",
    "javascriptreact",
    "go",
    "rust",
    "markdown",
  } or {}
end

local function context_fim_prompt(...)
  return require("user.external_context").fim_prompt(...)
end

local function context_fim_suffix(...)
  return require("user.external_context").fim_suffix(...)
end

local function build_minuet_config(enabled)
  return {
    provider = "openai_fim_compatible",

    -- Favor low-latency inline completion over broad context.
    request_timeout = 3,
    throttle = 300,
    debounce = 150,
    context_window = 6000,
    n_completions = 1,

    provider_options = {
      openai_fim_compatible = {
        api_key = "DEEPSEEK_API_KEY",
        name = "deepseek",
        end_point = "https://api.deepseek.com/beta/completions",
        model = "deepseek-v4-flash",
        stream = true,
        template = {
          prompt = context_fim_prompt,
          suffix = context_fim_suffix,
        },
        optional = {
          max_tokens = 128,
          top_p = 0.9,
          thinking = { type = "disabled" },
        },
      },
    },

    virtualtext = {
      auto_trigger_ft = minuet_filetypes(enabled),
      show_on_completion_menu = true,
      keymap = {
        accept = "<C-y>",
        accept_line = "<M-a>",
        accept_n_lines = "<M-z>",
        prev = "<M-[>",
        next = "<M-]>",
        dismiss = "<C-]>",
      },
    },
  }
end

local function current_auto_trigger_filetypes()
  local minuet = require "minuet"
  return minuet.config and minuet.config.virtualtext and minuet.config.virtualtext.auto_trigger_ft or {}
end

local function enable_auto_trigger_for_buffer(bufnr)
  if vim.b[bufnr].minuet_virtual_text_auto_trigger ~= nil then return end
  if vim.tbl_contains(current_auto_trigger_filetypes(), vim.bo[bufnr].filetype) then
    vim.b[bufnr].minuet_virtual_text_auto_trigger = true
  end
end

return {
  {
    "milanglacier/minuet-ai.nvim",
    event = "VeryLazy",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = function()
      local enabled = load_home_env "DEEPSEEK_API_KEY"

      vim.g.zish_minuet_provider = "deepseek"
      vim.env.MINUET_PROVIDER = "deepseek"

      require("minuet").setup(build_minuet_config(enabled))

      if not enabled then
        vim.notify(
          "DEEPSEEK_API_KEY is missing; inline AI completion auto trigger is disabled.",
          vim.log.levels.WARN
        )
      end

      vim.api.nvim_create_autocmd({ "BufEnter", "FileType" }, {
        group = vim.api.nvim_create_augroup("ZishMinuetAutoTrigger", { clear = true }),
        callback = function(args) enable_auto_trigger_for_buffer(args.buf) end,
        desc = "Enable Minuet virtual text auto trigger for configured filetypes",
      })

      for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(bufnr) then enable_auto_trigger_for_buffer(bufnr) end
      end
    end,
  },
  {
    "AstroNvim/astrocore",
    opts = function(_, opts)
      opts.autocmds = opts.autocmds or {}
      opts.autocmds.zish_external_context_cleanup = {
        {
          event = "VimLeavePre",
          desc = "Remove temporary external context for agent editor",
          callback = function() require("user.external_context").cleanup() end,
        },
      }

      opts.mappings = opts.mappings or {}
      opts.mappings.n = opts.mappings.n or {}
      opts.mappings.n["<Leader>ua"] = {
        "<Cmd>Minuet virtualtext toggle<CR>",
        desc = "Toggle AI inline completion",
      }
    end,
  },
}
