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

return {
  {
    "milanglacier/minuet-ai.nvim",
    event = "VeryLazy",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = function()
      local has_deepseek_key = load_home_env "DEEPSEEK_API_KEY"

      require("minuet").setup {
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
            optional = {
              max_tokens = 128,
              top_p = 0.9,
              thinking = { type = "disabled" },
            },
          },
        },

        virtualtext = {
          auto_trigger_ft = has_deepseek_key and {
            "lua",
            "python",
            "typescript",
            "javascript",
            "go",
            "rust",
            "markdown",
          } or {},
          keymap = {
            accept = "<M-l>",
            accept_line = "<M-a>",
            accept_n_lines = "<M-z>",
            prev = "<M-[>",
            next = "<M-]>",
            dismiss = "<C-]>",
          },
        },
      }
    end,
  },
}
