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

local bailian_api_key_names = { "DASHSCOPE_API_KEY", "BAILIAN_API_KEY", "ALIYUN_BAILIAN_API_KEY" }

local provider_choices = { "qwen", "bailian", "deepseek" }

local provider_labels = {
  qwen = "Qwen 2.5 Coder 3B (local)",
  bailian = "Aliyun Bailian Qwen Coder",
  deepseek = "DeepSeek v4 Flash",
}

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

local function qwen_transform(data)
  data.headers = data.headers or {}
  data.headers["CF-Access-Client-Id"] = vim.env.QWEN25_CODER_CF_ACCESS_CLIENT_ID
  data.headers["CF-Access-Client-Secret"] = vim.env.QWEN25_CODER_CF_ACCESS_CLIENT_SECRET
  return data
end

local function bailian_api_key()
  for _, name in ipairs(bailian_api_key_names) do
    if vim.env[name] and vim.env[name] ~= "" then return vim.env[name] end
  end
end

local function bailian_endpoint()
  local endpoint = vim.env.BAILIAN_CODER_ENDPOINT or vim.env.BAILIAN_BASE_URL or vim.env.DASHSCOPE_BASE_URL
  endpoint = endpoint or "https://dashscope.aliyuncs.com/compatible-mode/v1/completions"
  endpoint = endpoint:gsub("/+$", "")

  if endpoint:match "/v1$" then return endpoint .. "/completions" end
  return endpoint
end

local function bailian_fim_prompt(context_before_cursor, context_after_cursor, _)
  return "<|fim_prefix|>"
    .. (context_before_cursor or "")
    .. "<|fim_suffix|>"
    .. (context_after_cursor or "")
    .. "<|fim_middle|>"
end

local function load_minuet_env()
  local has_deepseek_key = load_home_env "DEEPSEEK_API_KEY"
  local has_qwen_cf_id = load_home_env "QWEN25_CODER_CF_ACCESS_CLIENT_ID"
  local has_qwen_cf_secret = load_home_env "QWEN25_CODER_CF_ACCESS_CLIENT_SECRET"
  local has_bailian_key = false

  for _, name in ipairs(bailian_api_key_names) do
    if load_home_env(name) then has_bailian_key = true end
  end

  load_home_env "MINUET_PROVIDER"
  load_home_env "QWEN25_CODER_ENDPOINT"
  load_home_env "QWEN25_CODER_MODEL"
  load_home_env "QWEN25_CODER_API_KEY"
  load_home_env "BAILIAN_CODER_ENDPOINT"
  load_home_env "BAILIAN_BASE_URL"
  load_home_env "DASHSCOPE_BASE_URL"
  load_home_env "BAILIAN_CODER_MODEL"

  return {
    qwen = has_qwen_cf_id and has_qwen_cf_secret,
    bailian = has_bailian_key,
    deepseek = has_deepseek_key,
  }
end

local function normalize_provider(provider)
  provider = tostring(provider or ""):lower()
  if provider == "" then return nil end
  if provider_labels[provider] then return provider end
  if provider:match "^qwen" or provider == "local" then return "qwen" end
  if provider:match "^bailian" or provider == "aliyun" or provider == "dashscope" then return "bailian" end
  if provider:match "^deepseek" then return "deepseek" end
  return nil
end

local function resolve_provider(provider, availability, notify)
  local requested = provider or "qwen"
  if availability[requested] then return requested, true end

  for _, fallback in ipairs(provider_choices) do
    if fallback ~= requested and availability[fallback] then
      if notify then
        vim.notify(
          ("Minuet provider %s is missing credentials; using %s."):format(requested, fallback),
          vim.log.levels.WARN
        )
      end
      return fallback, true
    end
  end

  if notify then
    vim.notify(
      "No Minuet provider credentials found; inline AI completion auto trigger is disabled.",
      vim.log.levels.WARN
    )
  end
  return requested, false
end

local function provider_option(provider)
  if provider == "qwen" then
    return {
      api_key = function() return vim.env.QWEN25_CODER_API_KEY or "unused" end,
      name = "qwen25-coder-3b",
      end_point = vim.env.QWEN25_CODER_ENDPOINT or "https://qwen25-coder-3b.zish-rob-crur.com/v1/completions",
      model = vim.env.QWEN25_CODER_MODEL or "mlx-community/Qwen2.5-Coder-3B-Instruct-4bit",
      stream = true,
      transform = { qwen_transform },
      optional = {
        max_tokens = 96,
        stop = { "\n\n" },
        top_p = 0.9,
        temperature = 0,
      },
    }
  end

  if provider == "bailian" then
    return {
      api_key = bailian_api_key,
      name = "bailian-qwen-coder",
      end_point = bailian_endpoint(),
      model = vim.env.BAILIAN_CODER_MODEL or "qwen-coder-turbo",
      stream = false,
      template = {
        prompt = bailian_fim_prompt,
        suffix = false,
      },
      optional = {
        max_tokens = 96,
        stop = { "\n\n" },
        top_p = 0.9,
        temperature = 0,
      },
    }
  end

  return {
    api_key = "DEEPSEEK_API_KEY",
    name = "deepseek",
    end_point = "https://api.deepseek.com/beta/completions",
    model = "deepseek-v4-flash",
    stream = true,
    template = {
      prompt = function(...)
        return require("user.shell_context").fim_prompt(...)
      end,
      suffix = function(...)
        return require("user.shell_context").fim_suffix(...)
      end,
    },
    optional = {
      max_tokens = 128,
      top_p = 0.9,
      thinking = { type = "disabled" },
    },
  }
end

local function build_minuet_config(provider, enabled)
  local use_qwen = provider == "qwen"
  local use_bailian = provider == "bailian"

  return {
    provider = "openai_fim_compatible",

    -- Favor low-latency inline completion over broad context.
    request_timeout = use_qwen and 8 or use_bailian and 5 or 3,
    throttle = 300,
    debounce = 150,
    context_window = use_qwen and 2048 or 6000,
    n_completions = 1,

    provider_options = {
      openai_fim_compatible = provider_option(provider),
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

local function persist_minuet_provider(provider)
  local env_path = vim.fn.expand "~/.env"
  local lines = vim.fn.filereadable(env_path) == 1 and vim.fn.readfile(env_path) or {}
  local line = ("MINUET_PROVIDER='%s'"):format(provider)
  local updated = false

  for index, current in ipairs(lines) do
    if current:match "^%s*MINUET_PROVIDER%s*=" then
      lines[index] = line
      updated = true
      break
    end
  end

  if not updated then table.insert(lines, line) end

  local ok, result = pcall(vim.fn.writefile, lines, env_path)
  if not ok or result ~= 0 then return false end

  vim.fn.setfperm(env_path, "rw-------")
  return true
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

local function apply_runtime_provider_config(provider, enabled)
  local minuet = require "minuet"
  local default_config = require "minuet.config"
  local config = build_minuet_config(provider, enabled)
  local provider_config = vim.tbl_deep_extend(
    "force",
    vim.deepcopy(default_config.provider_options.openai_fim_compatible),
    config.provider_options.openai_fim_compatible
  )

  minuet.config.provider = config.provider
  minuet.config.request_timeout = config.request_timeout
  minuet.config.throttle = config.throttle
  minuet.config.debounce = config.debounce
  minuet.config.context_window = config.context_window
  minuet.config.n_completions = config.n_completions
  minuet.config.provider_options.openai_fim_compatible = provider_config
  minuet.config.virtualtext.auto_trigger_ft = config.virtualtext.auto_trigger_ft
  minuet.config.virtualtext.show_on_completion_menu = config.virtualtext.show_on_completion_menu

  vim.g.zish_minuet_provider = provider
  vim.env.MINUET_PROVIDER = provider

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then enable_auto_trigger_for_buffer(bufnr) end
  end
end

local function switch_minuet_provider(provider, opts)
  opts = opts or {}

  local normalized = normalize_provider(provider)
  if not normalized then
    vim.notify(("Invalid Minuet provider: %s"):format(provider), vim.log.levels.ERROR)
    return
  end

  local availability = load_minuet_env()
  local resolved, enabled = resolve_provider(normalized, availability, opts.notify)
  apply_runtime_provider_config(resolved, enabled)

  if opts.persist and not persist_minuet_provider(resolved) then
    vim.notify("Failed to persist MINUET_PROVIDER in ~/.env.", vim.log.levels.WARN)
  end

  if opts.notify then
    vim.notify(("Minuet provider: %s"):format(provider_labels[resolved]), vim.log.levels.INFO)
  end
end

local function select_minuet_provider()
  local current = vim.g.zish_minuet_provider or normalize_provider(vim.env.MINUET_PROVIDER) or "qwen"

  vim.ui.select(provider_choices, {
    prompt = "Select Minuet provider:",
    format_item = function(provider)
      local suffix = provider == current and " (current)" or ""
      return ("%s%s"):format(provider_labels[provider], suffix)
    end,
  }, function(choice)
    if choice then switch_minuet_provider(choice, { persist = true, notify = true }) end
  end)
end

local function complete_minuet_provider(arglead)
  return vim.tbl_filter(function(provider) return vim.startswith(provider, arglead) end, provider_choices)
end

return {
  {
    "milanglacier/minuet-ai.nvim",
    event = "VeryLazy",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = function()
      local availability = load_minuet_env()
      local requested_provider = normalize_provider(vim.env.MINUET_PROVIDER) or "qwen"
      local active_provider, provider_available = resolve_provider(requested_provider, availability, false)

      vim.g.zish_minuet_provider = active_provider
      vim.env.MINUET_PROVIDER = active_provider

      require("minuet").setup(build_minuet_config(active_provider, provider_available))

      vim.api.nvim_create_autocmd({ "BufEnter", "FileType" }, {
        group = vim.api.nvim_create_augroup("ZishMinuetAutoTrigger", { clear = true }),
        callback = function(args) enable_auto_trigger_for_buffer(args.buf) end,
        desc = "Enable Minuet virtual text auto trigger for configured filetypes",
      })

      for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(bufnr) then enable_auto_trigger_for_buffer(bufnr) end
      end

      vim.api.nvim_create_user_command("ZishMinuetProvider", function(args)
        if args.args == "" then
          select_minuet_provider()
        else
          switch_minuet_provider(args.args, { persist = true, notify = true })
        end
      end, {
        nargs = "?",
        complete = complete_minuet_provider,
        desc = "Select Minuet completion provider",
      })
    end,
  },
  {
    "AstroNvim/astrocore",
    opts = function(_, opts)
      opts.autocmds = opts.autocmds or {}
      opts.autocmds.zish_shell_context_cleanup = {
        {
          event = "VimLeavePre",
          desc = "Remove temporary shell context for agent editor",
          callback = function() require("user.shell_context").cleanup() end,
        },
      }

      opts.mappings = opts.mappings or {}
      opts.mappings.n = opts.mappings.n or {}
      opts.mappings.n["<Leader>ua"] = {
        "<Cmd>Minuet virtualtext toggle<CR>",
        desc = "Toggle AI inline completion",
      }
      opts.mappings.n["<Leader>uA"] = {
        "<Cmd>ZishMinuetProvider<CR>",
        desc = "Select AI completion provider",
      }
    end,
  },
}
