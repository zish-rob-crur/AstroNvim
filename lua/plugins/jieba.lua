local jieba_filetypes = {
  markdown = true,
  text = true,
}

local jieba_modes = { "n", "x", "o" }

local jieba_motions = {
  w = "<Plug>(Jieba_w)",
  W = "<Plug>(Jieba_W)",
  b = "<Plug>(Jieba_b)",
  B = "<Plug>(Jieba_B)",
  e = "<Plug>(Jieba_e)",
  E = "<Plug>(Jieba_E)",
  ge = "<Plug>(Jieba_ge)",
  gE = "<Plug>(Jieba_gE)",
}

local python3_venv = vim.fn.stdpath "data" .. "/python3"
local python3_host = python3_venv .. "/bin/python3"

if vim.fn.executable(python3_host) == 1 then vim.g.python3_host_prog = python3_host end

local function run(cmd)
  local result = vim.system(cmd, { text = true }):wait()
  if result.code == 0 then return end

  error(
    ("command failed: %s\n%s%s"):format(table.concat(cmd, " "), result.stdout or "", result.stderr or "")
  )
end

local function can_import(python, module)
  if python == "" or vim.fn.executable(python) ~= 1 then return false end

  local result = vim.system({ python, "-c", ("import %s"):format(module) }, { text = true }):wait()
  return result.code == 0
end

local function ensure_python3_host()
  if vim.fn.executable(python3_host) ~= 1 then
    local python3 = vim.fn.exepath "python3"
    if python3 == "" then error "python3 is required by jieba.vim" end

    run { python3, "-m", "venv", python3_venv }
  end

  if not can_import(python3_host, "pynvim") then
    run { python3_host, "-m", "pip", "install", "--upgrade", "pip", "pynvim" }
  end
end

local function has_python3_provider()
  if vim.g.loaded_python3_provider == 0 then return false end

  local ok, err = pcall(ensure_python3_host)
  if not ok then
    vim.schedule(function()
      vim.notify(("jieba.vim disabled: %s"):format(err), vim.log.levels.WARN)
    end)
    return false
  end

  vim.g.python3_host_prog = python3_host
  return vim.fn.has "python3" == 1
end

local function is_jieba_filetype(bufnr)
  return jieba_filetypes[vim.bo[bufnr].filetype] == true
end

local function has_command(name)
  return vim.fn.exists(":" .. name) == 2
end

local function ensure_jieba_command()
  if has_command "JiebaInit" then return true end

  local ok_lazy, lazy = pcall(require, "lazy")
  if ok_lazy then pcall(lazy.load, { plugins = { "jieba.vim" } }) end
  if has_command "JiebaInit" then return true end

  vim.g.loaded_jieba_vim = nil
  pcall(vim.cmd.runtime, "plugin/jieba_vim.vim")
  return has_command "JiebaInit"
end

local function ensure_jieba_initialized()
  if vim.g.jieba_vim_initialized == 1 then return true end

  if not has_python3_provider() then return false end

  if not ensure_jieba_command() then
    vim.notify("jieba.vim disabled: JiebaInit command is unavailable", vim.log.levels.WARN)
    return false
  end

  local ok, err = pcall(vim.cmd.JiebaInit)
  if not ok then
    vim.notify(("jieba.vim disabled: %s"):format(err), vim.log.levels.WARN)
    return false
  end

  return true
end

local function set_jieba_keymaps(bufnr)
  for lhs, rhs in pairs(jieba_motions) do
    vim.keymap.set(jieba_modes, lhs, rhs, {
      buffer = bufnr,
      silent = true,
      remap = true,
      desc = "Jieba 中文跳词 " .. lhs,
    })
  end

  vim.b[bufnr].jieba_word_motion_enabled = true
end

local function unset_jieba_keymaps(bufnr)
  for lhs in pairs(jieba_motions) do
    for _, mode in ipairs(jieba_modes) do
      pcall(vim.keymap.del, mode, lhs, { buffer = bufnr })
    end
  end

  vim.b[bufnr].jieba_word_motion_enabled = false
end

local function toggle_jieba_word_motion(bufnr)
  bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or bufnr

  if not is_jieba_filetype(bufnr) then
    vim.notify("Jieba word motions are only available in Markdown/text buffers", vim.log.levels.WARN)
    return
  end

  if vim.b[bufnr].jieba_word_motion_enabled then
    unset_jieba_keymaps(bufnr)
    vim.notify("Jieba word motions disabled; restored native w/b/e", vim.log.levels.INFO)
  else
    if not ensure_jieba_initialized() then return end
    set_jieba_keymaps(bufnr)
    vim.notify("Jieba word motions enabled: w/b/e/ge now move by Chinese words", vim.log.levels.INFO)
  end
end

return {
  {
    "kkew3/jieba.vim",
    branch = "main",
    build = ensure_python3_host,
    cond = has_python3_provider,
    cmd = { "JiebaInit", "JiebaPreviewCancel", "JiebaToggle" },
    keys = {
      {
        "<Leader>jj",
        function() toggle_jieba_word_motion(0) end,
        ft = { "markdown", "text" },
        desc = "切换中文跳词模式",
      },
    },
    config = function()
      vim.api.nvim_create_user_command(
        "JiebaToggle",
        function() toggle_jieba_word_motion(0) end,
        { desc = "Toggle Jieba Chinese word motions in the current buffer" }
      )
    end,
  },
}
