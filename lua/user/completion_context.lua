local M = {}

local last_trigger = {}

local function line_before_cursor()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1] or ""
  return line:sub(1, col), row, col
end

local function is_javascript_like(filetype)
  return vim.tbl_contains({
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
  }, filetype)
end

local function python_providers(before)
  if before:match "^%s*from$" or before:match "^%s*import$" then return { "python_imports", "snippets", "lsp" } end

  if before:match "^%s*from%s+$" or before:match "^%s*from%s+[%w_%.]+$" then return { "python_imports", "lsp" } end

  if before:match "^%s*import%s+$" or before:match "^%s*import%s+.*,%s*$" then return { "python_imports", "lsp" } end

  if before:match "^%s*from%s+[%w_%.]+%s+import%s*$" or before:match "^%s*from%s+[%w_%.]+%s+import%s+.*,%s*$" then
    return { "python_imports", "lsp" }
  end
end

local function javascript_providers(before)
  if before:match "^%s*import%s*$" or before:match "^%s*export%s*$" then return { "js_imports", "snippets" } end
  if before:match "^%s*import%s+{%s*$" then return { "snippets" } end
  if
    before:match [[from%s+["'][%w@%./_-]*$]]
    or before:match [[import%s*%(%s*["'][%w@%./_-]*$]]
    or before:match [[^%s*import%s+["'][%w@%./_-]*$]]
    or before:match [[export%s+.*from%s+["'][%w@%./_-]*$]]
  then
    return { "js_imports", "path", "lsp" }
  end
end

local function providers_for_context(filetype, before)
  if filetype == "python" then return python_providers(before) end
  if is_javascript_like(filetype) then return javascript_providers(before) end
end

function M.trigger(bufnr, opts)
  opts = opts or {}
  local mode = opts.mode or vim.api.nvim_get_mode().mode
  if vim.api.nvim_get_current_buf() ~= bufnr or mode ~= "i" then return end

  local before, row, col = line_before_cursor()
  local providers = providers_for_context(vim.bo[bufnr].filetype, before)
  if not providers then return end

  local key = ("%d:%d:%d:%s:%s"):format(bufnr, row, col, before, table.concat(providers, ","))
  if last_trigger[bufnr] == key then return end
  last_trigger[bufnr] = key

  local defer_fn = opts.defer_fn or vim.defer_fn
  defer_fn(function()
    if not vim.api.nvim_buf_is_valid(bufnr) or vim.api.nvim_get_current_buf() ~= bufnr then return end
    local current_mode = opts.mode or vim.api.nvim_get_mode().mode
    if current_mode ~= "i" then return end

    local current_before, current_row, current_col = line_before_cursor()
    if current_row ~= row or current_col ~= col or current_before ~= before then return end

    local cmp = opts.cmp
    if not cmp then
      local ok
      ok, cmp = pcall(require, "blink.cmp")
      if not ok then return end
    end
    cmp.show { providers = providers }
  end, opts.defer_ms or 10)
end

return M
