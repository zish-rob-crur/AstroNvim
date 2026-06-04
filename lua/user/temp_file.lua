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

  local temp_dirs = {
    vim.env.TMPDIR,
    vim.env.TEMP,
    vim.env.TMP,
    "/tmp",
    "/var/tmp",
    "/private/tmp",
  }

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
