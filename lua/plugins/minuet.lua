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
      local auto_trigger_filetypes = has_deepseek_key and {
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

      local function enable_auto_trigger_for_buffer(bufnr)
        if vim.b[bufnr].minuet_virtual_text_auto_trigger ~= nil then return end
        if vim.tbl_contains(auto_trigger_filetypes, vim.bo[bufnr].filetype) then
          vim.b[bufnr].minuet_virtual_text_auto_trigger = true
        end
      end

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
          auto_trigger_ft = auto_trigger_filetypes,
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
      opts.mappings = opts.mappings or {}
      opts.mappings.n = opts.mappings.n or {}
      opts.mappings.n["<Leader>ua"] = {
        "<Cmd>Minuet virtualtext toggle<CR>",
        desc = "Toggle AI inline completion",
      }
    end,
  },
}
