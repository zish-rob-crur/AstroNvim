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

local function resolve_python3_host()
  local nvim_python = vim.fn.expand "~/.local/share/nvim/python3/bin/python3"
  if vim.fn.executable(nvim_python) == 1 then return nvim_python end

  return vim.fn.exepath "python3"
end

local function has_python3_provider()
  if vim.g.loaded_python3_provider == 0 then return false end

  if vim.g.python3_host_prog == nil then
    local python3 = resolve_python3_host()
    if python3 ~= "" then vim.g.python3_host_prog = python3 end
  end

  return vim.fn.has "python3" == 1
end

local function is_jieba_filetype(bufnr)
  return jieba_filetypes[vim.bo[bufnr].filetype] == true
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
    if vim.g.jieba_vim_initialized ~= 1 then vim.cmd.JiebaInit() end
    set_jieba_keymaps(bufnr)
    vim.notify("Jieba word motions enabled: w/b/e/ge now move by Chinese words", vim.log.levels.INFO)
  end
end

return {
  {
    "kkew3/jieba.vim",
    branch = "main",
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
