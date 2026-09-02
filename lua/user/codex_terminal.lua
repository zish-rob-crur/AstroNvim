local M = {}

local instances = {}
local configured = false
local trust_profile = "edit-anywhere"

local defaults = {
  width = 0.45,
  minimum_width = 52,
  minimum_editor_width = 32,
  prefill_delay_ms = 700,
}

local directions = {
  h = { smart = "left", fallback = "h" },
  j = { smart = "down", fallback = "j" },
  k = { smart = "up", fallback = "k" },
  l = { smart = "right", fallback = "l" },
}

local function valid_buffer(bufnr) return bufnr and vim.api.nvim_buf_is_valid(bufnr) end

local function valid_window(winid) return winid and vim.api.nvim_win_is_valid(winid) end

local function running(job_id)
  return job_id and job_id > 0 and vim.fn.jobwait({ job_id }, 0)[1] == -1
end

local function current_root(bufnr)
  if vim.b[bufnr].zish_codex_root then return vim.b[bufnr].zish_codex_root end

  local path = vim.api.nvim_buf_get_name(bufnr)
  local start = path ~= "" and vim.fs.dirname(vim.fs.normalize(path)) or vim.fn.getcwd(0)
  return vim.fs.root(start, { ".git" }) or start
end

local function save_source_buffer(bufnr)
  if not valid_buffer(bufnr) or vim.bo[bufnr].buftype ~= "" or not vim.bo[bufnr].modified then return true end
  if vim.bo[bufnr].readonly or not vim.bo[bufnr].modifiable then return false end
  local ok = pcall(vim.api.nvim_buf_call, bufnr, function() vim.cmd "silent noautocmd update" end)
  return ok and not vim.bo[bufnr].modified
end

local function file_context(bufnr)
  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == "" or vim.bo[bufnr].buftype ~= "" then return nil end

  path = vim.fs.normalize(path)
  local root = current_root(bufnr)
  local relative = vim.fs.relpath(root, path) or path
  local line = vim.api.nvim_win_get_cursor(0)[1]
  return {
    root = root,
    path = path,
    relative = relative,
    line = line,
    prompt = ("current edit: %s:%d "):format(relative, line),
  }
end

local function move_from_terminal(direction)
  vim.cmd.stopinsert()
  local target = directions[direction]
  local ok, smart_splits = pcall(require, "smart-splits")
  if ok and type(smart_splits["move_cursor_" .. target.smart]) == "function" then
    smart_splits["move_cursor_" .. target.smart]()
  else
    vim.cmd("wincmd " .. target.fallback)
  end
end

local function configure_buffer(instance)
  local bufnr = instance.bufnr
  vim.bo[bufnr].buflisted = false
  vim.bo[bufnr].bufhidden = "hide"
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].filetype = "zish_codex_terminal"
  vim.b[bufnr].zish_codex_terminal = true
  vim.b[bufnr].zish_codex_root = instance.root

  for key in pairs(directions) do
    vim.keymap.set("t", "<M-" .. key .. ">", function() move_from_terminal(key) end, {
      buffer = bufnr,
      silent = true,
      desc = "Leave Codex terminal " .. directions[key].smart,
    })
  end
  vim.keymap.set("n", "q", function() M.hide(instance.root) end, {
    buffer = bufnr,
    silent = true,
    nowait = true,
    desc = "Hide Codex terminal",
  })

  vim.api.nvim_create_autocmd("BufEnter", {
    buffer = bufnr,
    callback = function()
      if vim.api.nvim_get_current_buf() == bufnr then pcall(vim.cmd.startinsert) end
    end,
    desc = "Enter Codex terminal input mode",
  })
end

local function configure_window(winid)
  local options = {
    colorcolumn = "",
    cursorcolumn = false,
    cursorline = false,
    foldcolumn = "0",
    list = false,
    number = false,
    relativenumber = false,
    signcolumn = "no",
    spell = false,
    statuscolumn = "",
    winbar = "",
    winfixwidth = true,
    winhighlight = "Normal:Normal,NormalNC:Normal,WinSeparator:Normal",
    wrap = false,
  }
  for name, value in pairs(options) do vim.wo[winid][name] = value end
end

local function split_width(options)
  local available = vim.o.columns
  local requested = math.max(options.minimum_width, math.floor(available * options.width))
  return math.min(requested, math.max(20, available - options.minimum_editor_width))
end

local function configured_mcp_servers(root)
  local codex_home = vim.env.CODEX_HOME or vim.fn.expand "~/.codex"
  local names = {}
  for _, path in ipairs {
    vim.fs.joinpath(codex_home, "config.toml"),
    vim.fs.joinpath(root, ".codex", "config.toml"),
  } do
    local ok, lines = pcall(vim.fn.readfile, path)
    if ok then
      for _, line in ipairs(lines) do
        local name = line:match "^%s*%[mcp_servers%.([%w_-]+)"
        if name then names[name] = true end
      end
    end
  end
  return vim.tbl_keys(names)
end

local function ensure_trust_profile(root, codex_home)
  codex_home = codex_home or vim.env.CODEX_HOME or vim.fn.expand "~/.codex"
  local path = vim.fs.joinpath(codex_home, trust_profile .. ".config.toml")
  local project_key = root:gsub("\\", "\\\\"):gsub('"', '\\"')
  local header = ('[projects."%s"]'):format(project_key)
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then lines = {} end
  if vim.tbl_contains(lines, header) then return true end

  if #lines > 0 and lines[#lines] ~= "" then table.insert(lines, "") end
  vim.list_extend(lines, { header, 'trust_level = "trusted"' })
  local written, err = pcall(vim.fn.writefile, lines, path)
  if not written then vim.notify("Could not update Codex trust profile: " .. err, vim.log.levels.ERROR) end
  return written
end

local function codex_command(root, mcp_servers)
  local command = {
    "codex",
    "-p",
    trust_profile,
    "--disable",
    "apps",
    "--disable",
    "plugins",
    "--disable",
    "remote_plugin",
    "-c",
    "check_for_update_on_startup=false",
  }
  table.sort(mcp_servers)
  for _, name in ipairs(mcp_servers) do
    vim.list_extend(command, { "-c", ("mcp_servers.%s.enabled=false"):format(name) })
  end
  vim.list_extend(command, { "-C", root })
  return command
end

local function open_window(instance, options)
  vim.cmd "botright vsplit"
  instance.winid = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(instance.winid, instance.bufnr)
  configure_window(instance.winid)
  pcall(vim.api.nvim_win_set_width, instance.winid, split_width(options))
  pcall(vim.cmd.startinsert)
end

local function new_instance(root, options)
  if vim.fn.executable(options.command[1]) ~= 1 then
    vim.notify(options.command[1] .. " is not installed", vim.log.levels.ERROR)
    return nil
  end

  local instance = {
    root = root,
    bufnr = vim.api.nvim_create_buf(false, true),
    winid = nil,
    job_id = nil,
    started_at = vim.uv.hrtime(),
    attached_context = nil,
  }
  instances[root] = instance
  open_window(instance, options)

  instance.job_id = vim.api.nvim_buf_call(instance.bufnr, function()
    return vim.fn.jobstart(options.command, {
      cwd = root,
      term = true,
      on_exit = function()
        instance.job_id = nil
      end,
    })
  end)
  if not instance.job_id or instance.job_id <= 0 then
    M.close(root)
    vim.notify("Could not start Codex terminal", vim.log.levels.ERROR)
    return nil
  end

  configure_buffer(instance)
  configure_window(instance.winid)
  return instance
end

local function merged_options(options)
  options = vim.tbl_deep_extend("force", {}, defaults, options or {})
  if not options.command then
    ensure_trust_profile(options.root)
    options.command = codex_command(options.root, configured_mcp_servers(options.root))
  end
  return options
end

local function inject_context(instance, context, options)
  local key = context.path .. ":" .. context.line
  if instance.attached_context == key then return end
  instance.attached_context = key

  local function send()
    if instances[instance.root] ~= instance or not running(instance.job_id) then return end
    vim.fn.chansend(instance.job_id, context.prompt)
  end

  local elapsed_ms = math.floor((vim.uv.hrtime() - instance.started_at) / 1000000)
  local delay = math.max(0, options.prefill_delay_ms - elapsed_ms)
  if delay == 0 then
    send()
  else
    vim.defer_fn(send, delay)
  end
end

function M.open(options)
  local source_bufnr = vim.api.nvim_get_current_buf()
  local root = options and options.root or current_root(source_bufnr)
  options = merged_options(vim.tbl_extend("force", options or {}, { root = root }))
  if not save_source_buffer(source_bufnr) then
    vim.notify("Could not save the current file; Codex was not opened with stale content", vim.log.levels.ERROR)
    return nil
  end

  local instance = instances[root]
  if instance and not running(instance.job_id) then
    M.close(root)
    instance = nil
  end
  if not instance then return new_instance(root, options) end

  if not valid_window(instance.winid) then open_window(instance, options) end
  vim.api.nvim_set_current_win(instance.winid)
  pcall(vim.cmd.startinsert)
  return instance
end

function M.attach_current()
  local source_bufnr = vim.api.nvim_get_current_buf()
  if not save_source_buffer(source_bufnr) then
    vim.notify("Could not save the current file; Codex context was not updated", vim.log.levels.ERROR)
    return nil
  end

  local context = file_context(source_bufnr)
  if not context then
    vim.notify("Current buffer has no file to attach", vim.log.levels.WARN)
    return M.toggle()
  end

  local options = merged_options { root = context.root }
  local instance = M.open(options)
  if not instance then return nil end
  inject_context(instance, context, options)
  return instance
end

function M.hide(root)
  local instance = instances[root]
  if not instance then return false end
  if valid_window(instance.winid) then vim.api.nvim_win_close(instance.winid, false) end
  instance.winid = nil
  return true
end

function M.close(root)
  local instance = instances[root]
  if not instance then return false end
  M.hide(root)
  if running(instance.job_id) then vim.fn.jobstop(instance.job_id) end
  if valid_buffer(instance.bufnr) then pcall(vim.api.nvim_buf_delete, instance.bufnr, { force = true }) end
  instances[root] = nil
  return true
end

function M.exit_current_editor()
  local bufnr = vim.api.nvim_get_current_buf()
  local root = current_root(bufnr)
  if vim.b[bufnr].zish_codex_terminal then return M.close(root) end

  local ok, err = pcall(vim.cmd, "update")
  if not ok then
    vim.notify(err, vim.log.levels.ERROR)
    return false
  end

  M.close(root)
  vim.cmd "quit"
  return true
end

function M.toggle()
  local bufnr = vim.api.nvim_get_current_buf()
  local root = current_root(bufnr)
  local instance = instances[root]
  if instance and valid_window(instance.winid) then
    if vim.api.nvim_get_current_win() == instance.winid then
      return M.hide(root)
    end
    vim.api.nvim_set_current_win(instance.winid)
    pcall(vim.cmd.startinsert)
    return instance
  end
  return M.open { root = root }
end

function M.setup()
  if configured then return end
  configured = true
  vim.api.nvim_create_user_command("CodexTerminal", function() M.toggle() end, {
    desc = "Toggle raw Codex terminal split",
  })
  vim.api.nvim_create_user_command("CodexTerminalClose", function() M.close(current_root(0)) end, {
    desc = "Stop the current project's Codex terminal",
  })
  vim.api.nvim_create_user_command("CodexAttach", function() M.attach_current() end, {
    desc = "Open Codex and attach the current file",
  })
  vim.keymap.set("n", "ZZ", M.exit_current_editor, {
    silent = true,
    desc = "Save and exit with the project Codex terminal",
  })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = vim.api.nvim_create_augroup("UserCodexTerminalLifecycle", { clear = true }),
    callback = function()
      for _, instance in pairs(instances) do
        if running(instance.job_id) then vim.fn.jobstop(instance.job_id) end
      end
      instances = {}
    end,
    desc = "Stop embedded Codex jobs before Neovim exits",
  })
end

function M._reset_for_test()
  local roots = vim.tbl_keys(instances)
  for _, root in ipairs(roots) do
    M.close(root)
  end
end

M._file_context_for_test = file_context
M._codex_command_for_test = codex_command
M._ensure_trust_profile_for_test = ensure_trust_profile

return M
