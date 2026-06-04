local function truncate(value, width)
  if #value <= width then return value end
  return value:sub(1, width - 3) .. "..."
end

local function pick_git_branches()
  local snacks_avail, snacks = pcall(require, "snacks")
  if snacks_avail then snacks.picker.git_branches() end
end

local minuet_state = {
  processing = false,
  spinner_index = 1,
  n_requests = 1,
  n_finished_requests = 0,
  provider = "deepseek",
  model = nil,
}

local status_icons = {
  completion = "󰘦",
  completion_off = "󰅖",
  ai = "󰚩",
}

local minuet_spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

local function setup_minuet_status_events()
  if vim.g.zish_statusline_minuet_events then return end
  vim.g.zish_statusline_minuet_events = true

  local group = vim.api.nvim_create_augroup("ZishStatuslineMinuet", { clear = true })

  vim.api.nvim_create_autocmd("User", {
    pattern = "MinuetRequestStartedPre",
    group = group,
    callback = function(request)
      local data = request.data or {}
      minuet_state.processing = false
      minuet_state.n_requests = data.n_requests or 1
      minuet_state.n_finished_requests = 0
      minuet_state.provider = data.name or minuet_state.provider
      minuet_state.model = data.model
      vim.schedule(vim.cmd.redrawstatus)
    end,
  })

  vim.api.nvim_create_autocmd("User", {
    pattern = "MinuetRequestStarted",
    group = group,
    callback = function()
      minuet_state.processing = true
      vim.schedule(vim.cmd.redrawstatus)
    end,
  })

  vim.api.nvim_create_autocmd("User", {
    pattern = "MinuetRequestFinished",
    group = group,
    callback = function()
      minuet_state.n_finished_requests = minuet_state.n_finished_requests + 1
      if minuet_state.n_finished_requests >= minuet_state.n_requests then minuet_state.processing = false end
      vim.schedule(vim.cmd.redrawstatus)
    end,
  })

  vim.api.nvim_create_autocmd({ "BufEnter", "FileType", "InsertEnter", "InsertLeave" }, {
    group = group,
    callback = function() vim.schedule(vim.cmd.redrawstatus) end,
  })
end

local function blink_completion_status(bufnr)
  local astro_avail, astro = pcall(require, "astrocore")
  if not astro_avail then return end

  local dap_prompt = astro.is_available "cmp-dap"
    and vim.tbl_contains({ "dap-repl", "dapui_watches", "dapui_hover" }, vim.bo[bufnr].filetype)
  if vim.bo[bufnr].buftype == "prompt" and not dap_prompt then return end

  local enabled = vim.F.if_nil(vim.b[bufnr].completion, astro.config.features.cmp)
  if enabled then return status_icons.completion, false end
  return status_icons.completion_off, true
end

local function minuet_auto_trigger_enabled(bufnr)
  if not package.loaded["minuet"] then return false end

  if vim.b[bufnr].minuet_virtual_text_auto_trigger ~= nil then return vim.b[bufnr].minuet_virtual_text_auto_trigger end

  local minuet = require "minuet"
  local config = minuet.config and minuet.config.virtualtext
  if not config then return false end

  local filetype = vim.bo[bufnr].filetype
  return vim.tbl_contains(config.auto_trigger_ft or {}, filetype)
    and not vim.tbl_contains(config.auto_trigger_ignore_ft or {}, filetype)
end

local function completion_status(bufnr)
  local parts = {}
  local has_warning = false

  local blink_text, blink_warning = blink_completion_status(bufnr)
  if blink_text then
    table.insert(parts, blink_text)
    has_warning = has_warning or blink_warning
  end

  if minuet_state.processing then
    minuet_state.spinner_index = minuet_state.spinner_index % #minuet_spinner + 1
    table.insert(parts, status_icons.ai .. minuet_spinner[minuet_state.spinner_index])
  elseif minuet_auto_trigger_enabled(bufnr) then
    table.insert(parts, status_icons.ai)
  end

  return #parts > 0 and table.concat(parts, " ") or nil, has_warning
end

return {
  {
    "rebelot/heirline.nvim",
    opts = function(_, opts)
      local status = require "astroui.status"
      local status_utils = require "astroui.status.utils"
      setup_minuet_status_events()

      local git_branch = status.component.builder {
        {
          provider = function(self)
            local branch = vim.b[self and self.bufnr or 0].gitsigns_head or ""
            if branch == "" then return "" end
            return status_utils.stylize(truncate(branch, 24), {
              icon = { kind = "GitBranch", padding = { right = 1 } },
              padding = { left = 1, right = 1 },
            })
          end,
          hl = { fg = "git_branch_fg" },
          on_click = { name = "heirline_branch", callback = pick_git_branches },
          update = {
            "User",
            pattern = { "GitSignsUpdate", "GitSignsChanged" },
            callback = function() vim.schedule(vim.cmd.redrawstatus) end,
          },
          init = function(...) return require("astroui.status.init").update_events { "BufEnter" }(...) end,
        },
        surround = {
          separator = "left",
          color = "git_branch_bg",
          condition = function(self) return (vim.b[self and self.bufnr or 0].gitsigns_head or "") ~= "" end,
        },
      }

      local treesitter_warning = status.component.builder {
        {
          provider = function()
            return status_utils.stylize("TS off", {
              padding = { left = 1, right = 1 },
            })
          end,
          hl = { fg = "diag_WARN" },
        },
        surround = {
          separator = "right",
          color = "treesitter_bg",
          condition = function(self)
            return status.condition.has_filetype(self or {}) and not status.condition.treesitter_available(self or {})
          end,
          update = { "BufEnter", "OptionSet" },
        },
      }

      local completion = status.component.builder {
        {
          init = function(self)
            self.completion_text, self.completion_warning = completion_status(self and self.bufnr or 0)
          end,
          provider = function(self)
            return status_utils.stylize(self.completion_text, {
              padding = { left = 1, right = 1 },
            })
          end,
          hl = function(self) return { fg = self.completion_warning and "diag_WARN" or "completion_fg" } end,
        },
        surround = {
          separator = "right",
          color = "completion_bg",
          condition = function(self)
            local text = completion_status(self and self.bufnr or 0)
            return text ~= nil
          end,
        },
      }

      opts.statusline = {
        hl = { fg = "fg", bg = "bg" },
        status.component.mode(),
        git_branch,
        status.component.git_diff(),
        status.component.fill(),
        status.component.file_info {
          unique_path = { max_length = 18 },
          filename = { padding = { right = 1 } },
          filetype = { padding = { left = 0 } },
          surround = {
            separator = "center",
            color = "file_info_bg",
            condition = function(...) return status.condition.is_file(...) end,
          },
        },
        status.component.diagnostics(),
        status.component.cmd_info(),
        status.component.fill(),
        completion,
        status.component.lsp {
          lsp_client_names = { truncate = 0.18 },
        },
        status.component.virtual_env(),
        treesitter_warning,
        status.component.nav {
          ruler = { pad_ruler = { line = 1, char = 1 } },
          percentage = { padding = { left = 1 } },
        },
        status.component.mode { surround = { separator = "right" } },
      }
    end,
  },
}
