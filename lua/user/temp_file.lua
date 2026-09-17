local M = {}

local function normalize(path)
  if path == nil or path == "" then return "" end
  return vim.fs.normalize(path)
end

local function has_prefix(path, prefix)
  prefix = normalize(prefix)
  if prefix == "" then return false end
  if not vim.endswith(prefix, "/") then prefix = prefix .. "/" end
  return vim.startswith(path, prefix)
end

function M.is_path(path)
  path = normalize(path)
  if path == "" then return false end

  local basename = vim.fs.basename(path) or ""
  if basename:match "^%.tmp" or basename:match "%.tmp$" then return true end

  -- An unset variable would leave a hole that ipairs() stops at, so the list is
  -- built by appending. Codex composes prompts in an editor opened on a file
  -- under its editor directory; such a window is an input box, so it gets no
  -- file tree and no outline.
  local temp_dirs = { "/tmp", "/var/tmp", "/private/tmp" }
  table.insert(temp_dirs, vim.fs.joinpath(vim.env.CODEX_HOME or vim.fn.expand "~/.codex", "editor"))
  for _, name in ipairs { "TMPDIR", "TEMP", "TMP" } do
    if vim.env[name] then table.insert(temp_dirs, vim.env[name]) end
  end

  for _, dir in ipairs(temp_dirs) do
    if has_prefix(path, dir) then return true end
  end

  return false
end

function M.is_buffer(bufnr)
  bufnr = bufnr or 0
  if not vim.api.nvim_buf_is_valid(bufnr) then return false end
  return M.is_path(vim.api.nvim_buf_get_name(bufnr))
end

function M.close_sidebars_for_buffer(bufnr)
  if not M.is_buffer(bufnr) then return end

  vim.schedule(function()
    if not M.is_buffer(bufnr) then return end
    if vim.fn.exists ":AerialClose" > 0 then pcall(vim.cmd, "AerialClose") end
    if vim.fn.exists ":Neotree" > 0 then pcall(vim.cmd, "Neotree close") end
  end)
end

return M
