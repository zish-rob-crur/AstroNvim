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

local auto_enable = {
  delay_ms = 500,
  max_sample_bytes = 64 * 1024,
  sample_window_lines = 64,
  min_han_characters = 10,
  min_han_ratio = 0.3,
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

local function python3_provider_enabled()
  return vim.g.loaded_python3_provider ~= 0
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
      desc = "Jieba word motion " .. lhs,
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

local function is_han_codepoint(codepoint)
  return (codepoint >= 0x3400 and codepoint <= 0x4DBF)
    or (codepoint >= 0x4E00 and codepoint <= 0x9FFF)
    or (codepoint >= 0xF900 and codepoint <= 0xFAFF)
    or (codepoint >= 0x20000 and codepoint <= 0x2FA1F)
    or (codepoint >= 0x30000 and codepoint <= 0x323AF)
end

local function count_language_characters(text)
  local han, latin = 0, 0
  local index = 1

  while index <= #text do
    local first = text:byte(index)
    local codepoint, width

    if first < 0x80 then
      codepoint, width = first, 1
    elseif first >= 0xC2 and first <= 0xDF and index + 1 <= #text then
      local second = text:byte(index + 1)
      codepoint, width = (first - 0xC0) * 0x40 + (second - 0x80), 2
    elseif first >= 0xE0 and first <= 0xEF and index + 2 <= #text then
      local second, third = text:byte(index + 1, index + 2)
      codepoint = (first - 0xE0) * 0x1000 + (second - 0x80) * 0x40 + (third - 0x80)
      width = 3
    elseif first >= 0xF0 and first <= 0xF4 and index + 3 <= #text then
      local second, third, fourth = text:byte(index + 1, index + 3)
      codepoint = (first - 0xF0) * 0x40000
        + (second - 0x80) * 0x1000
        + (third - 0x80) * 0x40
        + (fourth - 0x80)
      width = 4
    else
      codepoint, width = first, 1
    end

    if is_han_codepoint(codepoint) then
      han = han + 1
    elseif (codepoint >= 0x41 and codepoint <= 0x5A) or (codepoint >= 0x61 and codepoint <= 0x7A) then
      latin = latin + 1
    end

    index = index + width
  end

  return han, latin
end

local function sample_language_characters(bufnr)
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  local window = auto_enable.sample_window_lines
  local ranges

  -- Sample the beginning, middle, and end instead of scanning a potentially huge file.
  if line_count <= window * 3 then
    ranges = { { 0, line_count } }
  else
    ranges = {
      { 0, window },
      { math.floor((line_count - window) / 2), math.floor((line_count - window) / 2) + window },
      { line_count - window, line_count },
    }
  end

  local han, latin, sampled_bytes = 0, 0, 0
  for _, range in ipairs(ranges) do
    for _, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, range[1], range[2], false)) do
      local remaining_bytes = auto_enable.max_sample_bytes - sampled_bytes
      if remaining_bytes <= 0 then return han, latin end

      local sample = line:sub(1, remaining_bytes)
      local line_han, line_latin = count_language_characters(sample)
      han = han + line_han
      latin = latin + line_latin
      sampled_bytes = sampled_bytes + #sample + 1
    end
  end

  return han, latin
end

local function should_auto_enable(bufnr)
  local han, latin = sample_language_characters(bufnr)
  local language_characters = han + latin
  return han >= auto_enable.min_han_characters
    and language_characters > 0
    and han / language_characters >= auto_enable.min_han_ratio
end

local function auto_enable_jieba(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) or not vim.api.nvim_buf_is_loaded(bufnr) then return end
  if vim.api.nvim_get_current_buf() ~= bufnr then return end
  if not is_jieba_filetype(bufnr) or vim.bo[bufnr].buftype ~= "" or vim.bo[bufnr].binary then return end
  if vim.b[bufnr].jieba_auto_check_done or vim.b[bufnr].jieba_word_motion_enabled then return end

  vim.b[bufnr].jieba_auto_check_done = true
  if should_auto_enable(bufnr) and ensure_jieba_initialized() then set_jieba_keymaps(bufnr) end
end

local function schedule_auto_enable(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then return end
  if vim.b[bufnr].jieba_auto_check_done or vim.b[bufnr].jieba_word_motion_enabled then return end
  if vim.b[bufnr].jieba_auto_check_scheduled then return end

  vim.b[bufnr].jieba_auto_check_scheduled = true
  vim.defer_fn(function()
    if not vim.api.nvim_buf_is_valid(bufnr) then return end
    vim.b[bufnr].jieba_auto_check_scheduled = false
    auto_enable_jieba(bufnr)
  end, auto_enable.delay_ms)
end

local function toggle_jieba_word_motion(bufnr)
  bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or bufnr

  if not is_jieba_filetype(bufnr) then
    vim.notify("Jieba word motions are only available in Markdown/text buffers", vim.log.levels.WARN)
    return
  end

  vim.b[bufnr].jieba_auto_check_done = true

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
    cond = python3_provider_enabled,
    cmd = { "JiebaInit", "JiebaPreviewCancel", "JiebaToggle" },
    keys = {
      {
        "<Leader>jj",
        function() toggle_jieba_word_motion(0) end,
        ft = { "markdown", "text" },
        desc = "Toggle Chinese word motions",
      },
    },
    init = function()
      vim.api.nvim_create_autocmd({ "BufEnter", "FileType" }, {
        callback = function(args)
          if is_jieba_filetype(args.buf) then schedule_auto_enable(args.buf) end
        end,
        desc = "Enable Jieba word motions for Chinese-heavy text buffers",
      })
    end,
    config = function()
      vim.api.nvim_create_user_command(
        "JiebaToggle",
        function() toggle_jieba_word_motion(0) end,
        { desc = "Toggle Jieba Chinese word motions in the current buffer" }
      )
    end,
  },
}
